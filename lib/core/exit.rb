#
# file::    exit.rb
# author::  Jon A. Lambert
# version:: 2.10.0
# date::    06/27/2006
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

# The Exit class is the mother of all exits.
#
class Exit < GameObject
  property :to_room

  # Create a new Exit object
  # [+name+]   The displayed name of the room
  # [+owner+]    The owner id of this room
  # [+return+] A handle to the new Room.
  def initialize(name, owner, location, to_room)
    super(name, owner, location)
    self.to_room=to_room    # The room the exit leads to
                            # location is the room the exit starts in
  end

  # Event :leave
  # [+e+]      The event
  # [+return+] Undefined
  def leave(e)
    ch = get_object(e.from)
    characters(e.from).each do |x|
      add_event(location, x.id,:show, ch.name + " has left #{e.msg}.") if x.account
    end
    # remove character
    get_object(location).delete_contents(ch.id)
    ch.location = nil
    add_event(id, to_room, :arrive, ch.id)
  end


end
