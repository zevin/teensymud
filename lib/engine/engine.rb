#
# file::    engine.rb
# author::  Jon A. Lambert
# version:: 2.10.0
# date::    06/25/2006
#
# This source code copyright (C) 2005, 2006 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
$:.unshift "lib" if !$:.include? "lib"
$:.unshift "vendor" if !$:.include? "vendor"

require 'singleton'

require 'utility/configuration'
require 'utility/log'
require 'network/reactor'
require 'core/world'
require 'engine/eventmanager'
require 'core/room'
require 'core/character'
require 'core/gameobject'
require 'core/account'
require 'core/exit'
require 'core/script'

# The Engine class sets up the server, polls it regularly and observes
# acceptor for incoming connections.
class Engine
  include Singleton
  configuration
  logger 'DEBUG'

  attr_accessor :shutdown
  attr_reader :world, :db, :eventmgr

  # Create the an engine.
  # [+return+] A handle to the engine.
  def initialize
    # Display options
    log.debug "Configuration: #{options.inspect}"
    @shutdown = false
    if options['trace']
      set_trace_func proc { |event, file, line, id, binding, classname|
        if file !~ /\/usr\/lib\/ruby/
          printf "%8s %s:%-2d %10s %8s\n", event, file, line, id, classname
        end
      }
    end
  end

  # main loop to run engine.
  # note:: @shutdown never set by anyone yet
  def run
    case options['dbtype']
    when :yaml
      require 'storage/yamlstore'
      @db = YamlStore.new(options['dbfile'])
    when :xml
      require 'storage/xmlstore'
      @db = XmlStore.new(options['dbfile'])
    when :gdbm
      require 'storage/gdbmstore'
      @db = GdbmStore.new(options['dbfile'])
    when :sdbm
      require 'storage/sdbmstore'
      @db = SdbmStore.new(options['dbfile'])
    when :dbm
      require 'storage/dbmstore'
      @db = DbmStore.new(options['dbfile'])
    when :sqlite
      require 'storage/sqlitestore'
      @db = SqliteStore.new(options['dbfile'])
    when :sqlite3
      require 'storage/sqlite3store'
      @db = Sqlite3Store.new(options['dbfile'])
    else
      log.fatal "Invalid 'dbtype' in Configuration"
      raise RunTimeError
    end

    # Get the world object
    @world = @db.get(0)
#    log.debug @world.inspect
    @db.makenoswap(0)
    @world.startup

    @eventmgr = EventManager.new
    log.info "Booting server on port #{options['server_port'] || 4000}"
    @server = Reactor.new(options['server_port'] || 4000,
      options['server_type'], options['server_io'],
      options['server_negotiation'], options['server_filters'],
      address=nil)

    raise "Unable to start server" unless @server.start(self)
    log.info "TMUD is ready"

    Signal.trap("INT", method(:handle_signal))
    Signal.trap("TERM", method(:handle_signal))
    Signal.trap("KILL", method(:handle_signal))
    until @shutdown
      @server.poll(0.3)
      @eventmgr.process_events
    end # until
    graceful_shutdown
  rescue
    log.fatal "Engine failed in run"
    log.fatal $!
  end

  # Update is called by an acceptor passing us a new session.  We create
  # an incoming object and set it and the connection to watch each other.
  def update(newconn)
    inc = Account.new(newconn)
    # Observe each other
    newconn.subscribe(inc)
    inc.subscribe(newconn)
  end

  # Setup traps - invoke one of these signals to shut down the mud
  def handle_signal(sig)
    log.warn "Signal caught request to shutdown."
    graceful_shutdown
  end

  def graceful_shutdown
    @world.shutdown
    @server.stop
    log.info "Saving world..."
    @db.save
    @db.close
    exit
  end
end


