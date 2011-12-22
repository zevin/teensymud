#
# file::    cmd_chat.rb
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

  # sends <message> to all characters in the game
  def cmd_chat(args)
    case args
    when nil, ""
      sendto("What are you trying to tell everyone?")
    else
      sendto("[COLOR Magenta]You chat, \"#{args}\".[/COLOR]")
      world.connected_characters.each do |pid|
        if id != pid
          add_event(id,pid,:show,
            "[COLOR Magenta]#{name} chats, \"#{args}\".[/COLOR]")
        end
      end
    end
  end

end
