#
# file::    eventmanager.rb
# author::  Jon A. Lambert
# version:: 2.6.0
# date::    10/28/2005
#
# This source code copyright (C) 2005 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
$:.unshift "lib" if !$:.include? "lib"
$:.unshift "vendor" if !$:.include? "vendor"

require 'engine/event'
require 'utility/log'
require 'core/character'

class EventManager
  logger 'DEBUG'

  def initialize
    @tits = []
    @bra = Mutex.new
    log.info "Event manager starting..."
  end

  # Add an Event to the TITS queue.
  # [+e+]      The event to be added.
  # [+return+] Undefined.
  def add_event(from,to,kind,msg=nil)
    @bra.synchronize do
      @tits.push(Event.new(from,to,kind,msg))
    end
  end

  # Get an Event from the TITS queue.
  # [+return+] The Event or nil
  def get_event
    @bra.synchronize do
      @tits.shift
    end
  end

  def contents
    @tits.inspect
  end

  # Process events
  # A false return in a PRE trigger will prevent execution of the event
  def process_events
    while e = get_event
      begin
        # pre triggers
        obj = Engine.instance.db.get(e.to)
        obj2 = Engine.instance.db.get(e.from)
        sid = obj.get_trigger("pre_"+e.kind.to_s)
        if sid
          script = Engine.instance.db.get(sid)
          if script
            if script.execute(e)
              # success
              if obj2.class == Character
                s,o = obj.msgsucc.split("|")
                obj2.sendto(s) if s && !s.empty?
                if o && !o.empty?
                  Engine.instance.db.get(obj2.location).characters(obj2.id).each do |p|
                    add_event(obj2.id,p.id,:show,"#{obj2.name} #{o}")
                  end
                end
              end
            else
              # failure
              if obj2.class == Character
                s,o = obj.msgfail.split("|")
                obj2.sendto(s) if s && !s.empty?
                if o && !o.empty?
                  Engine.instance.db.get(obj2.location).characters(obj2.id).each do |p|
                    add_event(obj2.id,p.id,:show,"#{obj2.name} #{o}")
                  end
                end
              end
              next
            end
          else
            log.error "Script not found: #{sid} for Event: #{e}"
            # We fail the action slently
            next
          end
        end

        # action receiver
        obj.send(e.kind,e)

        # post triggers
        sid = obj.get_trigger(e.kind)
        if sid
          script = Engine.instance.db.get(sid)
          if script
            if script.execute(e)
              # success
              if obj2.class == Character
                s,o = obj.msgsucc.split("|")
                obj2.sendto(s) if s && !s.empty?
                if o && !o.empty?
                  Engine.instance.db.get(obj2.location).characters(obj2.id).each do |p|
                    add_event(obj2.id,p.id,:show,"#{obj2.name} #{o}")
                  end
                end
              end
            else
              # failure
              if obj2.class == Character
                s,o = obj.msgfail.split("|")
                obj2.sendto(s) if s && !s.empty?
                if o && !o.empty?
                  Engine.instance.db.get(obj2.location).characters(obj2.id).each do |p|
                    add_event(obj2.id,p.id,:show,"#{obj2.name} #{o}")
                  end
                end
              end
            end
          else
            log.error "Script not found: #{sid} for Event: #{e.inspect}"
            # We fail the action slently
          end
        end
      rescue
        log.error "Event failed: #{e.inspect}"
        log.error $!
      end
    end
  end
end
