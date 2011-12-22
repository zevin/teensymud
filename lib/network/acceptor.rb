#
# file::    acceptor.rb
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

require 'fcntl'

require 'network/session'
require 'network/connection'

# The acceptor class handles client connection requests for a reactor
#
class Acceptor < Session
  logger 'DEBUG'

  # Create a new acceptor object
  # [+server+]  The reactor this acceptor is associated with.
  # [+returns+] An acceptor object
  def initialize(server)
    super(server)
  end

  # init is called before using the acceptor
  # [+returns+] true is acceptor is properly initialized
  def init
    # Open a socket for the server to listen on.
    @sock = TCPServer.new('0.0.0.0', @server.port)
    @sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
    @sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_LINGER, false)
    unless RUBY_PLATFORM =~ /win32/
      @sock.fcntl(Fcntl::F_SETFL, Fcntl::O_NONBLOCK)
    end
    @accepting = true
    @server.register(self)
    true
  rescue Exception
    log.fatal $!
    false
  end

  # handle_input is called when an pending connection occurs on the
  # listening socket's port.  This function creates a Connection object
  # and calls it's init routine.
  def handle_input
    sckt = @sock.accept
    if sckt
      unless RUBY_PLATFORM =~ /win32/
        sckt.fcntl(Fcntl::F_SETFL, Fcntl::O_NONBLOCK)
      end
      c = Connection.new(@server, sckt)
      if c.init
        log.info "(#{c.object_id}) Connection accepted."
        publish(c)
      end
    else
      raise "Error in accepting connection."
    end
  rescue Exception
    log.error $!
  end

  # handle_close is called when a close event occurs for this acceptor.
  def handle_close
    @accepting = false
    @server.unregister(self)
    @sock.close
  rescue Exception
    log.error $!
  end

end


