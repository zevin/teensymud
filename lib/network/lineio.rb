#
# file::    lineio.rb
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

require 'network/sockio'

# The LineIO class implements a line-orient interface for TCP sockets.
# It's a specialization of sockio.  This class is intended for line-oriented
# protocols.
#
class LineIO < SockIO

  # Creates a new LineIO object
  # [+sock+]    The socket which will be used
  # [+bufsize+] The size of the buffer to use (default is 8192)
  def initialize(sock, bufsize=8192)
    super(sock,bufsize)
  end

  # read will receive a set of lines from the socket.  A line may be
  # terminated by CRLF, CRNUL, LFCR, CR, or LF.  Not yet terminated lines
  # are left in the @inbuffer.
  # [+return+] One or more complete lines or nil.
  #
  # [+IOError+]  A sockets error occurred.
  # [+EOFError+] The connection has closed normally.
  def read
    @inbuffer << @sock.recv(@bufsize)
    @inbuffer.gsub!(/\r\n|\r\x00|\n\r|\r|\n/,"\n")
    pos = @inbuffer.rindex("\n")
    if pos
      ln = @inbuffer.slice!(0..pos)
      return ln
    end
    nil
  end

end

