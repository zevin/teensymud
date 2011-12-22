#
# file::    cmd_trigger.rb
# author::  Jon A. Lambert
# version:: 2.8.0
# date::    02/21/2005
#
# This source code copyright (C) 2005, 2006 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
module Cmd

  # adds, deletes, or shows triggers on an object
  # Syntax:
  #   @trigger add #<id> #<scriptid> <eventtype>
  #   @trigger del #<id> <eventtype>
  #   @trigger show #<id>
  # (ex. @trigger add #1 myprog arrive)
  def cmd_trigger(args)
    case args
    when nil, ""
      sendto("What??")
    when /del\s+#(\d+)\s+(\w+)/
      o = get_object($1.to_i)
      case o
      when GameObject, Room, Character
        if o.get_trigger($2)
          o.delete_trigger($2)
          sendto("Object ##$1 trigger deleted.")
        else
          sendto("Trigger ##$2 not found on object.")
        end
      else
        sendto("No object.")
      end
    when /add\s+#(\d+)\s+#(\d+)\s+(\w+)/i
      o = get_object($1.to_i)
      case o
      when GameObject, Room, Character
        s = get_object($2.to_i)
        case s
        when Script
          o.add_trigger($3, s.id)
          sendto("Object ##$1 trigger added.")
        else
          sendto("No script.")
        end
      else
        sendto("No object.")
      end
    when /show\s+#(\d+)/
      o = get_object($1.to_i)
      case o
      when GameObject, Room, Character
        sendto("===========TRIGGERS============")
        sendto(sprintf("%-15s %-15s", "Event", "Program"))
        o.triggers.each do |e, t|
          sendto(sprintf("%-15s #%d", e.id2name, t))
        end
      else
        sendto("No object.")
      end
    else
      sendto("What??")
    end
  end

end
