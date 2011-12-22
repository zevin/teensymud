#
# file::    cmd_status.rb
# author::  Jon A. Lambert
# version:: 2.5.3
# date::    09/21/2005
#
# This source code copyright (C) 2005 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
module Cmd

  # displays session information
  def cmd_status(args)
    sendto @account.status_rept
  end

end
