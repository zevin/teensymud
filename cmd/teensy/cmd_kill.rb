#
# file::    cmd_kill.rb
# author::  Jon A. Lambert
# version:: 2.3.0
# date::    08/31/2005
#
# This source code copyright (C) 2005 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
module Cmd

  # This kills a character anywhere - it's link death (30% chance)
  def cmd_kill(args)
    case args
    when nil, ""
      sendto("Who do you want to kill?")
    else
      d = world.all_characters.find {|pid| args == get_object(pid).name }
      if !d
        sendto("Can't find them.")
        return
      end
      d = get_object(d)  # get object
      if rand < 0.3
        sendto("You kill #{d.name}.")
        world.connected_characters.each {|pid|
          if pid != id
            add_event(id,pid,:show,"#{name} kills #{d.name}.")
          end
        }
        d.account.disconnect("You have been pwn3d!")
        # delete_object(d)  Dont delete character, it's annoying
      else
        sendto("You attacks and misses #{d.name}.")
        world.connected_characters.each {|pid|
          if pid != id
            add_event(id,pid,:show,"#{name} attacks and misses #{d.name}.")
          end
        }
      end
    end
  end

end
