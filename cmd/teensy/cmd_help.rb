#
# file::    cmd_help.rb
# author::  Jon A. Lambert
# version:: 2.4.0
# date::    09/12/2005
#
# This source code copyright (C) 2005 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
module Cmd

  # The help command
  def cmd_help(args)
    case args
    when nil, ""
      sendto("====================HELP=======================")
      world.cmds.to_hash.values.each do |h|
        sendto(sprintf("%-10s - %s", h.name, h.help))
      end
    else
      q = world.cmds.find(args)
      if q
        sendto("====================HELP=======================")
        q.each do |h|
          sendto(sprintf("%-10s - %s", h.name, h.help))
        end
      else
        sendto "No help on that."
      end
    end
  end

end
