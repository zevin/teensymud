#
# file::    cmd_reload.rb
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

  # This reloads the commands
  def cmd_reload(args)
    world.cmds, world.ocmds = Command.load
    sendto("Command table reloaded.")
  end

end
