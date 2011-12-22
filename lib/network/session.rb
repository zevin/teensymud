#
# file::    session.rb
# author::  Jon A. Lambert
# version:: 2.8.0
# date::    01/19/2006
#
# This source code copyright (C) 2005, 2006 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
$:.unshift "lib" if !$:.include? "lib"
$:.unshift "vendor" if !$:.include? "vendor"

require 'utility/publisher'

# The session class is a base class contains the minimum amount of
# attributes to reasonably maintain a socket session with a client.
#
class Session
  include Publisher

  attr_reader :sock
  attr_accessor :accepting, :connected, :closing, :write_blocked

  # Create a new session object
  # Used when opening both an acceptor or connection.
  # [+server+]  The reactor or connector this session is associated with.
  # [+sock+]    Nil for acceptors or the socket for connections.
  # [+returns+] A session object.
  def initialize(server, sock=nil)
    @server = server   # Reactor or connector associated with this session.
    @sock = sock       # File descriptor handle for this session.
    @addr = ""         # Network address of this socket.
    @accepting=@connected=@closing=@write_blocked=false
  end

  # init is called before using the session.
  # [+returns+] true is session object properly initialized
  def init
    true
  end

  # handle_input is called when an input event occurs for this session.
  def handle_input
  end

  # handle_output is called when an output event occurs for this session.
  def handle_output
  end

  # handle_close is called when a close event occurs for this session.
  def handle_close
  end

  # handle_oob is called when an out of band data event occurs for this
  # session.
  def handle_oob
  end

  # is_readable? tests if the socket is a candidate for select read
  # {+return+] true if so, false if not
  def is_readable?
    @connected || @accepting
  end

  # is_writable? tests if the socket is a candidate for select write
  # {+return+] true if so, false if not
  def is_writable?
    @write_blocked
  end

end

