#
# file::    cmd_gc.rb
# author::  Jon A. Lambert
# version:: 2.9.0
# date::    03/15/2006
#
# This source code copyright (C) 2005 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
module Cmd

  # This command runs garbage collection
  def cmd_gc(args)
    GC.start
    sendto("Garbage collector run")
  end

end
