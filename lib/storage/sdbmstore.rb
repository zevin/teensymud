#
# file::    sdbmstore.rb
# author::  Jon A. Lambert
# version:: 2.9.0
# date::    03/16/2006
#
# This source code copyright (C) 2005, 2006 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
$:.unshift "lib" if !$:.include? "lib"
$:.unshift "vendor" if !$:.include? "vendor"

require 'sdbm'
require 'utility/log'
require 'storage/store'
require 'storage/cache'

# The SdbmStore class manages access to all object storage.
#
# [+db+] is a handle to the database.
# [+dbtop+] stores the highest id used in the database.
# [+cache+] is a handle to the cache
class SdbmStore < Store
  logger 'DEBUG'

  def initialize(dbfile)
    super()
    @dbfile = "#{dbfile}"

    # check if database exists and build it if not
    build_database
    log.info "Loading world..."

    # open database and sets @dbtop to highest object id
    @db = SDBM.open(@dbfile, 0666)
    @db.each_key do |o|
      @dbtop = o.to_i if o.to_i > @dbtop
    end

    @cache = CacheManager.new(@db)
    log.info "Database '#{@dbfile}' loaded...highest id = #{@dbtop}."
#    log.debug @db.inspect
  rescue
    log.fatal $!
    raise
  end

  # Save the world
  # [+return+] Undefined.
  def save
    @cache.sync
  end

  # Close the database
  # [+return+] Undefined.
  def close
    @db.close
  end

  # inspect the store cache (only for caches)
  # [+return+] string
  def inspect
    @cache.inspect
  end

  # Adds a new object to the database.
  # [+obj+] is a reference to object to be added
  # [+return+] Undefined.
  def put(obj)
    @cache.put(obj)
    obj # return really should not be checked
  end

  # Deletes an object from the database.
  # [+oid+] is the id to to be deleted.
  # [+return+] Undefined.
  def delete(oid)
    @cache.delete(oid)
  end

  # Finds an object in the database by its id.
  # [+oid+] is the id to use in the search.
  # [+return+] Handle to the object or nil.
  def get(oid)
    @cache.get(oid)
  end

  # Check if an object is in the database by its id.
  # [+oid+] is the id to use in the search.
  # [+return+] true or false
  def check(oid)
    @db.has_key? oid.to_s
  end

  # Marks an object dirty
  # [+oid+] is the id to use in the search.
  # [+return+] undefined
  def mark(oid)
    @cache.mark(oid)
  end

  # Marks an object nonswappable
  # [+oid+] is the object id
  # [+return+] undefined
  def makenoswap(oid)
    @cache.makenoswap(oid)
  end

  # Marks an object swappable
  # [+oid+] is the object id
  # [+return+] undefined
  def makeswap(oid)
    @cache.makeswap(oid)
  end

  # Iterate through all objects
  # This needs to have all the possible keys first.
  # So we need to fetch them from the cache and from the database and
  # and produce a list of unique keys.
  # [+yield+] Each object in database to block of caller.
  def each
    kys = @cache.keys
    @db.each_key {|k| kys << k.to_i}
    kys.uniq!
    kys.each {|k| yield @cache.get(k)}
  end

  # produces a statistical report of the database
  # [+return+] a string containing the report
  def stats
    stats = super
    stats << @cache.stats
  end

private

  # Checks that the database exists and builds one if not
  # Will raise an exception if something goes wrong.
  def build_database
    if !test(?e, "#{@dbfile}.pag")
      log.info "Building minimal world database..."
      SDBM.open(@dbfile, 0666) do |db|
        YAML::load(MINIMAL_DB).each do |o|
          db[o.id.to_s] = Utility.encode(o)
        end
      end
    end
  rescue
    log.fatal "Unable to find or build database - '#{@dbfile}'"
    log.fatal $!
    raise
  end

end
