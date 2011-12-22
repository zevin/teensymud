#
# file::    world.rb
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

require 'thread'
require 'utility/log'
require 'command'
require 'core/root'
require 'engine/timer'


# The World class is the mother of all worlds.
#
# It contains world state information, the world timer, utility functions,
# and delegates to the Engine.
#
# [+cmds+] is a handle to the character commands table.
# [+ocmds+] is a handle to the object commands table.
# [+timer_list+] is a list of all installed timer objects (persistent)
# [+all_characters+] is a list of all characters (persistent)
# [+timer_list+] is a list of all connected characters
class World < Root
  logger 'DEBUG'
  property :timer_list, :all_characters, :all_accounts, :builders, :admins, :msgs
  attr_accessor :cmds, :ocmds, :connected_characters

  # Create the World.  This loads or creates the database depending on
  # whether it finds it.
  # [+return+] A handle to the World object.
  def initialize
    self.timer_list = []
    self.all_characters = []
    self.all_accounts = []
    self.admins = []
    self.builders = []
    self.msgs = {}
    @connected_characters = []
  end

  def startup
    @connected_characters = []
    @cmds, @ocmds = Command.load
    log.info "Starting Timer..."
    @timer_list_mutex = Mutex.new
    @timer = Thread.new do
      begin
        while true
          sleep 1.0
          @timer_list_mutex.synchronize do
            timer_list.each do |ti|
              if ti.fire?
                add_event(0, ti.id, :timer, ti.name)
                ti.reset
              end
            end
          end
        end
      rescue Exception
        log.fatal "Timer thread blew up"
        log.fatal $!
      end
    end
    log.info "World initialized."
  end

  def shutdown
    connected_characters.each{|pid| get_object(pid).account.disconnect("Shutdown.")}
    Thread.kill(@timer)
  end

  # Set/add a timer for an object
  # [+id+] The id of the object that wants to get a timer event
  # [+name+] The symbolic name of the timer event
  # [+time+] The interval time in seconds of the timer event
  def set_timer(id, name, time)
    @timer_list_mutex.synchronize do
      timer_list << Timer.new(id, name, time)
    end
  end

  # Unset/remove a timer for an object
  # [+id+] The id of the object to remove a timer event
  # [+name+] The symbolic name of the timer event to remove (or nil for all events)
  def unset_timer(id, name=nil)
    @timer_list_mutex.synchronize do
      if name.nil?
        timer_list.delete_if {|ti| ti.id == id }
      else
        timer_list.delete_if {|ti| ti.id == id && ti.name == name }
      end
    end
  end

  # Is character a builder?
  # [+oid+] character object id
  # [+return+] true or false
  def is_builder? oid
    builders.include? oid
  end

  # Is character an admin?
  # [+oid+] character object id
  # [+return+] true or false
  def is_admin? oid
    admins.include? oid
  end

  # Make the character an admin
  # [+oid+] character object id
  # [+return+] undefined
  def add_admin oid
    self.admins << oid if Character && !admin?(oid)
  end

  # Remove admin priviledges from character
  # [+oid+] character object id
  # [+return+] undefined
  def rem_admin oid
    self.admins.delete oid
  end

  # Make the character a builder
  # [+oid+] character object id
  # [+return+] undefined
  def add_builder oid
    self.builders << oid if Character && !builder?(oid)
  end

  # Remove admin priviledges from character
  # [+oid+] character object id
  # [+return+] undefined
  def rem_builder oid
    self.builders.delete oid
  end

  # Does character own the object?
  # [+pid+] character object id
  # [+oid+] object id
  # [+return+] true or false
  def is_owner?(pid, oid)
    oid.owner == get_object(pid).owner
  end

  # memstats scans all objects in memory and produces a report
  # [+return+] a string
  def memstats
    # initialize all counters
    rooms = objs = chars = accounts = scripts = strcount = strsize = ocount = 0

    # scan the ObjectSpace counting things
    ObjectSpace.each_object do |x|
      case x
      when String
        strcount += 1
        strsize += x.size
      when Character
        chars += 1
      when Account
        accounts += 1
      when Room
        rooms += 1
      when GameObject
        objs += 1
      when Script
        scripts += 1
      else
        ocount += 1
      end
    end

    # our report  :
    # :NOTE: sprintf would be better
    memstats=<<EOD
[COLOR Cyan]
----* Memory Statistics *----
  Rooms      - #{rooms}
  Objects    - #{objs}
  Scripts    - #{scripts}
  Accounts   - #{accounts}
  Characters - #{chars}
-----------------------------
  Strings - #{strcount}
     size - #{strsize} bytes
  Other   - #{ocount}
-----------------------------
  Total Objects - #{rooms+objs+chars+accounts+scripts+strcount+ocount}
----*                   *----
[/COLOR]
EOD
  end

end
