#
# file::    cmd_shutdown.rb
# author::  Jon A. Lambert
# version:: 2.9.0
# date::    01/19/2006
#
# This source code copyright (C) 2005, 2006 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
module Cmd

  # The shutdown command
  def cmd_shutdown(args)
    if world.is_admin? id
      log.info "Shutdown by '#{name}'"
      Engine.instance.shutdown = true
    else
      sendto "You do not have the authority to shutdown the server."
    end
  end

end
