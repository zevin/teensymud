#
# file::    cmd_drop.rb
# author::  Jon A. Lambert
# version:: 2.2.0
# date::    08/29/2005
#
# This source code copyright (C) 2005 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
module Cmd

  # drops all objects in your inventory into the room
  def cmd_drop(args)
    objects.each do |q|
      add_event(id,q.id,:drop)
    end
  end

end
