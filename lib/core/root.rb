#
# file::    root.rb
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

require 'utility/log'
require 'storage/properties'

# The Root class is the mother of all objects.
#
class Root
  configuration
  property :name, :owner, :desc, :created_on, :updated_on
  logger 'DEBUG'

  # Create a new Root
  # [+name+]     Every object needs a name
  # [+owner+]    The owner id of this object
  # [+return+]   A handle to the new Object
  def initialize(name, owner)
    self.id                     # The database id of the object
    self.name = name            # The displayed name of the object
    self.owner = owner || id    # The owner of the object or itself.
    self.desc = ""              # The description of the object
    self.created_on = Time.now
    self.updated_on = created_on.dup
  end

  # formatted dump of object properties
  # [+return+] a string
  def inspect
    s = ''
    @props.each do |key,val|
      s << sprintf("%20-20s : %40-40s\n", key.to_s, val.inspect)
    end
    s
  end


  # Clone an object
  # This does a deepcopy then assign a new database id
  #
  # [+return+]   A handle to the new Object
  def clone
    newobj = Marshal.load(Marshal.dump(self))
    props = newobj.instance_variable_get(:@props)
    props[:id] = Engine.instance.db.getid
    put_object(newobj)
    newobj
  rescue
    log.error "Clone failed"
    nil
  end

  # All command input routed through here and parsed.
  # [+m+]      The input message to be parsed
  # [+return+] false or true depending on whether command succeeded.
  def parse(m)
    false
  end

  def world
    Engine.instance.db.get(0)
  end

  def add_event(from,to,kind,msg=nil)
    Engine.instance.eventmgr.add_event(from,to,kind,msg)
  end

  def get_object(oid)
    Engine.instance.db.get(oid)
  end

  def put_object(obj)
    Engine.instance.db.put(obj)
  end

  def delete_object(oid)
    Engine.instance.db.delete(oid)
  end
end

