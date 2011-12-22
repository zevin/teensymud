#
# file::    cmd_room.rb
# author::  Jon A. Lambert
# version:: 2.10.0
# date::    06/25/2006
#
# This source code copyright (C) 2005 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
module Cmd

  # creates a new room and autolinks the exits using the exit names provided.
  # (ex. @room My Room north south)
  def cmd_room(args)
    case args
    when /(.*) (.*) (.*)/
      d=Room.new($1, id)
      if d.nil?
        log.error "Unable to create room."
        sendto "System error: unable to create room."
        return
      end
      put_object(d)
      curr = get_object(location)
      e1 = Exit.new($2, id, curr.id, d.id)
      curr.exits << e1.id
      put_object(e1)
      e2 = Exit.new($3, id, d.id, curr.id)
      d.exits << e2.id
      put_object(e2)
      sendto("Ok.")
    else
      sendto("say what??")
    end
  end

end
