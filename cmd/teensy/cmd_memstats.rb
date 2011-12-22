#
# file::    cmd_memstats.rb
# author::  Jon A. Lambert
# version:: 2.7.0
# date::    01/13/2006
#
# This source code copyright (C) 2005 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
module Cmd

  # The memory stats command
  def cmd_memstats(args)
    sendto(world.memstats)
  end

end
