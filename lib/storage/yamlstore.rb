#
# file::    yamlstore.rb
# author::  Jon A. Lambert
# version:: 2.8.0
# date::    01/19/2006
#
# This source code copyright (C) 2005, 2006 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
$:.unshift "lib" if !$:.include? "lib"
$:.unshift "vendor" if !$:.include? "vendor"

require 'yaml'
require 'utility/log'
require 'storage/store'

# The YamlStore class manages access to all object storage.
#
# [+db+] is a handle to the database implementation (in this iteration a hash).
# [+dbtop+] stores the highest id used in the database.
class YamlStore < Store
  logger 'DEBUG'

  def initialize(dbfile)
    super()
    @dbfile = "#{dbfile}.yaml"

    # check if database exists and build it if not
    build_database
    log.info "Loading world..."
    @db = {}

    # load the yaml database and sets @dbtop to highest object id
    YAML::load_file(@dbfile).each do |o|
      @dbtop = o.id if o.id > @dbtop
      @db[o.id]=o
    end

    log.info "Database '#{@dbfile}' loaded...highest id = #{@dbtop}."
#    log.debug @db.inspect
  rescue
    log.fatal "Error loading database"
    log.fatal $!
    raise
  end

  # Save the world
  # [+return+] Undefined.
  def save
    File.open(@dbfile,'w') do |f|
      YAML::dump(@db.values,f)
    end
  end

  # Adds a new object to the database.
  # [+obj+] is a reference to object to be added
  # [+return+] Undefined.
  def put(obj)
    @db[obj.id] = obj
    obj # return really ought not be checked
  end

  # Deletes an object from the database.
  # [+oid+] is the id to to be deleted.
  # [+return+] Undefined.
  def delete(oid)
    @db.delete(oid)
  end

  # Finds an object in the database by its id.
  # [+oid+] is the id to use in the search.
  # [+return+] Handle to the object or nil.
  def get(oid)
    @db[oid]
  end

  # Check if an object is in the database by its id.
  # [+oid+] is the id to use in the search.
  # [+return+] true or false
  def check(oid)
    @db.has_key? oid
  end

  # Iterate through all objects
  # [+yield+] Each object in database to block of caller.
  def each(&blk)
    @db.each_value &blk
  end

private

  # Checks that the database exists and builds one if not
  # Will raise an exception if something goes wrong.
  def build_database
    if !test(?e, @dbfile)
      log.info "Building minimal world database..."
      File.open(@dbfile,'w') do |f|
        f.write(MINIMAL_DB)
      end
    end
  rescue
    log.fatal "Unable to find or build database '#{@dbfile}'"
    log.fatal $!
    raise
  end

end
