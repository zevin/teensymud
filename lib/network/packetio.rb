#
# file::    packetio.rb
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
require 'utility/log'

# The PacketIO class implements a mechanism to send and recv packets
# delimited by a length prefix which is assumed to be a 4 bytes integer
# in network byte order.
#
class PacketIO < SockIO
  logger

  # Creates a new PackIO object
  # [+sock+]    The socket which will be used
  # [+bufsize+] The size of the buffer to use (default is 16K)
  def initialize(sock, bufsize=16380)
    @sock = sock
    @bufsize = bufsize + 4 # round out with prefix bytes
    @inbuffer = ""
    @outbuffer = ""
    @packet_size = 0
    @prefix_found = false
  end

  # read will receive a data from the socket.
  # [+return+] The data read
  #
  # [+IOError+]  A sockets error occurred.
  # [+EOFError+] The connection has closed normally.
  def read
    @inbuffer << @sock.recv(@bufsize)
    if !@prefix_found
      # start of packet
      if @inbuffer.size >= 4
        sizest = @inbuffer.slice!(0..3)
        @packet_size = sizest.unpack("N")[0]
        @prefix_found = true
        if @packet_size > @bufsize
          @inbuffer = ""
          @packet_size = 0
          @prefix_found = false
          log.warn "Discarding packet: Buffer size exceeded (PACKETSIZE=#{@packet_size} STRING='#{sizest}')"
          return nil
        end
      else
        return nil # not enough data yet
      end
    end

    if @prefix_found
      if @inbuffer.size >= @packet_size
        # We have it
        @prefix_found = false
        ps = @packet_size
        @packet_size = 0
        return @inbuffer.slice!(0...ps).chop  # chop off NUL
      else
        # Dont have it all yet.
        return nil
      end
    end
  end

  # write will transmit a packet to the socket, we calculated the size here
  # [+msg+]    The message string to be sent.
  # [+return+] false if more data to be written, true if all data written
  #
  # [+IOError+]  A sockets error occurred.
  # [+EOFError+] The connection has closed normally.
  def write(msg)
    if !msg.nil? && !msg.empty?
      @outbuffer << [msg.length].pack("N") << msg
    end
    n = @sock.send(@outbuffer, 0)
    # save unsent data for next call
    @outbuffer.slice!(0...n)
    @outbuffer.size == 0
  rescue Exception
    @outbuffer = ""  # Does it really matter?
    raise
  end

end

