#
# file::    room.rb
# author::  Jon A. Lambert
# version:: 2.10.0
# date::    06/25/2006
#
# This source code copyright (C) 2005, 2006 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
$:.unshift "lib" if !$:.include? "lib"
$:.unshift "vendor" if !$:.include? "vendor"

require 'core/gameobject'

# The Room class is the mother of all rooms.
#
class Room < GameObject
  property :exits
  logger 'DEBUG'

  # Create a new Room object
  # [+name+]   The displayed name of the room
  # [+owner+]    The owner id of this room
  # [+return+] A handle to the new Room.
  def initialize(name, owner)
    super(name, owner)
    self.exits=[]               # The list of exits for this room.
  end

  # Event :describe
  # [+e+]      The event
  # [+return+] Undefined
  def describe(e)
    msg = "[COLOR Green](#{id.to_s}) #{name}[/COLOR]\n#{desc}\n"
    add_event(id,e.from,:show,msg)
  end

  # Event :describe_exits
  # [+e+]      The event
  # [+return+] Undefined
  def describe_exits(e)
    msg = "[COLOR Red]Exits:\n"
    s = exits.size
    if s == 0
      msg << "None.[/COLOR]"
    else
      i = 0
      exits.each do |exid|
        ex = get_object(exid)
        key = ex.name.split(/;/).first
        msg << key
        i += 1
        case s - i
        when 1 then s > 2 ? msg << ", and " : msg << " and "
        when 0 then msg << "."
        else
          msg << ", "
        end
      end
      msg << "[/COLOR]"
    end
    add_event(id,e.from,:show,msg)
  end

  # Event :arrive
  # [+e+]      The event
  # [+return+] Undefined
  def arrive(e)
    ch = get_object(e.msg)
    # add character
    add_contents(ch.id)
    ch.location = id
    characters(e.msg).each do |x|
      add_event(id,x.id,:show, ch.name+" has arrived.") if x.account
    end
    ch.parse('look')
  end

end

