#
# file::    mocksocket.rb
# author::  Jon A. Lambert
# version:: 2.6.0
# date::    10/06/2005
#
# This source code copyright (C) 2005 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#

# A mocksocket spoofs the behavior of a TCPSocket for testing purposes
#
class MockSocket
  def initialize(data)
    @data = data
  end

  def recv(bufsize, flag=nil)
    @data.slice!(0...bufsize)
  end

  def send(msg, flag)
    msg.size
  end

  def close
    true
  end

  def peeraddr
    ["AF_INET", 8765, "users.house.net", "123.45.67.89"]
  end

  def addr
    ["AF_INET", 4000, "agamemnon", "10.0.0.2"]
  end

end
