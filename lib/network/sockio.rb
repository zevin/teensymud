#
# file::    sockio.rb
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

require 'socket'

# The SockIO class implements the low level interface for TCP sockets.
#
class SockIO

  # Creates a new SockIO object
  # [+sock+]    The socket which will be used
  # [+bufsize+] The size of the buffer to use (default is 8192)
  def initialize(sock, bufsize=8192)
    @sock,@bufsize=sock,bufsize
    @inbuffer = ""
    @outbuffer = ""
  end

  # read will receive a data from the socket.
  # [+return+] The data read
  #
  # [+IOError+]  A sockets error occurred.
  # [+EOFError+] The connection has closed normally.
  def read
    @sock.recv(@bufsize)
  end

  # write will transmit a message to the socket
  # [+msg+]    The message string to be sent.
  # [+return+] false if more data to be written, true if all data written
  #
  # [+IOError+]  A sockets error occurred.
  # [+EOFError+] The connection has closed normally.
  def write(msg)
    @outbuffer << msg
    n = @sock.send(@outbuffer, 0)
    # save unsent data for next call
    @outbuffer.slice!(0...n)
    @outbuffer.size == 0
  rescue Exception
    @outbuffer = ""  # Does it really matter?
    raise
  end

  # write_flush will kill the output buffer
  def write_flush
    @outbuffer = ""
  end

  # read_flush will kill the input buffer
  def read_flush
    @inbuffer = ""
  end

  # read_urgent will receive urgent data from the socket.
  # [+return+] The data read
  #
  # [+IOError+]  A sockets error occurred.
  # [+EOFError+] The connection has closed normally.
  def read_urgent
    @sock.recv(@bufsize, Socket::MSG_OOB)
  end

  # write_urgent will write urgent data to the socket.
  # [+msg+]    The message string to be sent.
  #
  # [+IOError+]  A sockets error occurred.
  # [+EOFError+] The connection has closed normally.
  def write_urgent(msg)
    @sock.send(msg, Socket::MSG_OOB)
  end

end

