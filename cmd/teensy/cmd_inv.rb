#
# file::    cmd_inv.rb
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

  # The inventory command
  def cmd_inv(args)
    sendto("=== Inventory ===")
    objects.each do |x|
      add_event(id,x.id,:describe)
    end
  end

end
