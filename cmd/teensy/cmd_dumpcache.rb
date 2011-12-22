#
# file::    cmd_dumpcache.rb
# author::  Jon A. Lambert
# version:: 2.7.0
# date::    01/13/2005
#
# This source code copyright (C) 2005 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
module Cmd

  # Look command displays the contents of a room
  def cmd_dumpcache(args)
    sendto(Engine.instance.db.inspect)
  end

end
