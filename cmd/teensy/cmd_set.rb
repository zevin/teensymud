#
# file::    cmd_set.rb
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

  # sets the description or timer for an object
  # Syntax:
  #   @set desc #<id> <description>
  #   @set key #<id> <description>
  #   @set timer #<id> <on|off>
  # (ex. @set desc #1 A beautiful rose.)
  def cmd_set(args)
    case args
    when nil, ""
      sendto("What??")
    when /desc\s+#(\d+)\s+(.*)/
      o = get_object($1.to_i)
      case o
      when nil, 0
        sendto("No object.")
      else
        o.desc = $2
        sendto("Object #" + $1 + " description set.")
      end
    when /key\s+#(\d+)\s+(.*)/
      o = get_object($1.to_i)
      case o
      when nil, 0
        sendto("No object.")
      else
        o.key = $2
        sendto("Object #" + $1 + " key set.")
      end
    when /timer\s+#(\d+)\s+(on|off)\s+(.*)/
      o = get_object($1.to_i)
      case o
      when nil
        sendto("No object.")
      else
        if $2 == 'on'
          if $3 =~ /(\w+)\s+(\d+)/
            world.set_timer(o.id, $1.to_sym, $2.to_i)
            sendto("Object ##{o.id} registered with timer.")
          else
            sendto("Bad symbol or missing time")
          end
        else
          if $3 =~ /(\w+)/
            world.unset_timer(o.id, $1.to_sym)
            sendto("Object ##{o.id} unregistered with timer.")
          else
            sendto("Bad symbol")
          end
        end
      end
    else
      sendto("What??")
    end
  end

end
