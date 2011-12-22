#
# file::    reactor.rb
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

require 'utility/log'

require 'network/acceptor'
require 'network/connector'

#
# The Reactor class defines a representation of a multiplexer based on
# a non-blocking select() server.
#
# The network design is based on the Mesh project NetworkService code
# which was translated almost directly from C++, warts and all, which in
# turn is based on Schmidt's Acceptor/Connector/Reactor patterns which
# may be found at http://citeseer.ist.psu.edu/schmidt97acceptor.html
# for an idea of how all these classes are supposed to interelate.
class Reactor
  attr_reader :port, :service_type, :service_io, :service_negotiation,
    :service_filters

  logger 'DEBUG'

  # Constructor for Reactor
  # [+service_port+] The port the server will listen on or client will
  #                  connect to.
  # [+service_type+] The type of service (:server or :client)
  # [+service_io+] The service io handler (:sockio, :lineio, or :packetio)
  # [+service_negotiation+] An array of telnet options the service will try
  #                         to negotiate
  #   Valid options are
  #        :sga, :echo, :naws, :ttype, :zmp (negotiate default)
  #        :binary
  # [+service_filters+] An array of io filters the service will use.
  #   Valid options are
  #     :filter  - attach dummy filter
  #     :debugfilter - attach debug filter (default)
  #     :telnetfilter - attach telnet filter (default)
  #     :colorfilter - attach color filter (default)
  #     :terminalfilter - attach terminal filter
  # [+address+] Optional address for outgoing connection.
  #
  def initialize(service_port, service_type, service_io, service_negotiation,
                 service_filters, address=nil)
    @port = service_port      # port server will listen on
    @shutdown = false  # Flag to indicate that server is shutting down.
    @acceptor = nil    # Listening socket for incoming connections.
    @connector = nil   # Connecting socket for outgoing connections.
    @registry = []     # list of sessions
    @address = address # Address for Connector.

    @service_type = service_type
    @service_io = service_io
    @service_negotiation = service_negotiation
    @service_filters = service_filters
    log.debug self.inspect
  end

  # Start initializes the reactor and gets it ready to accept incoming
  # connections.
  # [+engine+] The client engine that will be observing the acceptor.
  # [+return+'] true if server boots correctly, false if an error occurs.
  def start(engine)
    # Create an acceptor to listen for this server.
    if @service_type == :client
      @connector = Connector.new(self, @address)
      @connector.subscribe(engine)
      return false if !@connector.init
    else
      @acceptor = Acceptor.new(self)
      return false if !@acceptor.init
      @acceptor.subscribe(engine)
    end
    true
  rescue
    log.error "Reactor#start"
    log.error $!
    false
  end

  # stop requests each of the connections to disconnect in the
  # server's user list, deletes the connections, and erases them from
  # the user list.  It then closes its own listening port.
  def stop
    @registry.each {|s| s.closing = true}
    @acceptor.unsubscribe_all if @acceptor
    @connector.unsubscribe_all if @connector
    log.info "Reactor#shutdown: Reactor shutting down"
#    log.close
  end

  # poll starts the Reactor running to process incoming connection, input and
  # output requests.  It also executes commands from input requests.
  # [+tm_out*] time to poll in seconds
  def poll(tm_out)
    # Reset our socket interest set
    infds = [];outfds = [];oobfds = []
    @registry.each do |s|
      if s.is_readable?
        infds << s.sock
        oobfds << s.sock
      end
      if s.is_writable?
        outfds << s.sock
      end
    end

    # Poll our socket interest set
    infds,outfds,oobfds = select(infds, outfds, oobfds, tm_out)

    # Dispatch events to handlers
    @registry.each do |s|
      s.handle_output if outfds && outfds.include?(s.sock)
      s.handle_oob if oobfds && oobfds.include?(s.sock)
      s.handle_input if infds && infds.include?(s.sock)
      s.handle_close if s.closing
      # special handling for Telnet initialization
      if @service_filters.include?(:telnetfilter) &&
            s.respond_to?(:initdone) && !s.initdone
        s.pstack.set(:init_subneg, true)
      end
    end
  rescue
    log.error "Reactor#poll"
    log.error $!
    raise
  end

  # register adds a session to the registry
  # [+session+]
  def register(session)
    @registry << session
  end

  # unregister removes a session from the registry
  # [+session+]
  def unregister(session)
    @registry.delete(session)
  end

end
