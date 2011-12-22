#
# file::    gameobject.rb
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
require 'core/root'

# The GameObject class is no longer the mother of all objects.
#
class GameObject < Root
  property :location, :contents, :triggers, :msgfail, :msgsucc
  logger 'DEBUG'

  # Create a new Object
  # [+name+]     Every object needs a name
  # [+owner+]    The owner id of this object
  # [+location+] The object id containing this object or nil.
  # [+return+]   A handle to the new Object
  def initialize(name, owner, location=nil)
    super(name, owner)
    self.location = location    # The location of this object or nil if none
    self.contents = []
    self.triggers = {}
    self.msgfail = ''
    self.msgsucc = ''
  end

  # Add an object to the contents of this object
  # [+oid+] The object id to add
  def add_contents(oid)
    if contents.include? oid
      log.error "Object #{oid} already in contents of #{id}"
    else
      contents << oid
    end
  end

  # Deletes an object from the contents of this object
  # [+oid+] The object id to delete
  def delete_contents(oid)
    d = contents.delete(oid)
    if d.nil?
      log.error "Object #{oid} not in contents of #{id}"
    end
    d
  end

  # Returns the contents of the object
  # [+return+] An array of object ids
  def get_contents
    contents || []
  end

  # Add a trigger script to this object
  # [+s+] The script to add
  def add_trigger(event, sid)
    event = event.intern if event.respond_to?(:to_str)
    triggers[event] = sid
  end

  # Deletes a trigger script from this object
  # [+event+] The trigger event type to delete
  def delete_trigger(event)
    event = event.intern if event.respond_to?(:to_str)
    triggers.delete(event)
  end

  # Returns a specific trigger script from the object
  # [+event+] The trigger event type to retrieve
  # [+return+] A trigger or nil
  def get_trigger(event)
    event = event.intern if event.respond_to?(:to_str)
    triggers[event]
  end

  # Returns the trigger scripts on the object
  # [+return+] An array of trigger scripts
  def get_triggers
    triggers.values
  end

  # Finds all objects contained in this object
  # [+return+] Handle to a array of the objects.
  def objects
    ary = contents.collect do |oid|
      o = get_object(oid)
      o.class == GameObject ? o : nil
    end
    ary.compact
  end

  # Finds all the characters contained in this object except the passed character.
  # [+exempt+]  The character id exempted from the list.
  # [+return+] Handle to a list of the Character objects.
  def characters(exempt=nil)
    ary = contents.collect do |oid|
      o = get_object(oid)
      (o.class == Character && oid != exempt && o.account) ? o : nil
    end
    ary.compact
  end

  # All command input routed through here and parsed.
  # [+m+]      The input message to be parsed
  # [+return+] false or true depending on whether command succeeded.
  def parse(m)
    # match legal command
    m=~/([A-Za-z0-9_@?"'#!]+)(.*)/
    cmd=$1
    arg=$2
    arg.strip! if arg

    # look for a command from our table for objects
    c = world.ocmds.find(cmd)

    # there are three possibilities here
    case c.size
    when 0   # no commands found
      false
    when 1   # command found
      return self.send(c[0].cmd, arg)
    else     # ambiguous command - tell luser about them.
      false
    end
  end

  # Event :describe
  # [+e+]      The event
  # [+return+] Undefined
  def describe(e)
    msg = "[COLOR Yellow]A #{name} is here[/COLOR]"
    add_event(id,e.from,:show,msg)
  end

  # Event :get
  # [+e+]      The event
  # [+return+] Undefined
  def get(e)
    plyr = get_object(e.from)
    place = get_object(location)
    # remove it
    place.delete_contents(id)
    # add it
    plyr.add_contents(id)
    self.location = plyr.id
    add_event(id,e.from,:show,"You get the #{name}")
  end

  # Event :drop
  # [+e+]      The event
  # [+return+] Undefined
  def drop(e)
    plyr = get_object(e.from)
    place = get_object(plyr.location)
    # remove it
    plyr.delete_contents(id)
    # add it
    place.add_contents(id)
    self.location = place.id
    add_event(id,e.from,:show,"You drop the #{name}")
  end

  # Event :timer
  # [+e+]      The event
  # [+return+] Undefined
  def timer(e)
  end
end

