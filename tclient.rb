#!/usr/bin/env ruby
#
# file::    tclient.rb
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

require 'pp'

require 'network/reactor'

Version = "0.2.0"
BANNER=<<-EOH

          This is TeensyClient version #{Version}

        Copyright (C) 2005, 2006 by Jon A. Lambert
 Released under the terms of the TeensyMUD Public License

EOH

#
# =Purpose
# TeensyClient is a really cheap mud client
#



#
class Client
  include Publisher

  def initialize(opts)
    @opts = opts
    @conn = nil
  end

  def update(msg)
    case msg
    when Connection
      @conn = msg
      unsubscribe_all
      msg.subscribe(self)
      self.subscribe(msg)
      if @opts.win32
        @conn.set(:terminal, "vt100")
      else
        @conn.set(:terminal, "xterm")
      end
    when :initdone
      @conn.set(:termsize, [80,43])
    end
  end

end

class CursesClient < Client
  def initialize(opts)
    super(opts)
    Curses.init_screen
    Curses.cbreak
    Curses.noecho if @opts.echo
    Curses.nl
    Curses.stdscr.scrollok(true)
    if !$opts.win32  # Need workaround for these
      Curses.stdscr.keypad(true)
      Curses.timeout = 0
    end
    Curses.start_color
  end

  def conmsg msg
    Curses.addstr(msg)
    Curses.refresh
  end

  def update(msg)
    case msg
    when Connection, :initdone
      super(msg)
    when :disconnected
      unsubscribe_all
      $shutdown = true
      Curses.addstr "Disconnected."
      exit
    when String
      Curses.addstr(msg)
      Curses.refresh
    else
      Curses.addstr "Unknown msg - #{msg.inspect}"
    end
  end

  def run
    shutdown = false
    connection = Reactor.new(@opts.port, $conntype, $connio, $connopts,
       $connfilters, @opts.address)
    raise "Unable to start TeensyClient" unless connection.start(self)
    conmsg "Connected to #{@opts.address}:#{@opts.port}.  Use F10 to QUIT"
    until shutdown
      connection.poll(0.1)
      Curses.refresh
      c = Curses.getch
      case c
      when 32..127
        publish(c.chr)
      when Curses::KEY_ENTER
        publish("\r\n")
      when 10
        publish("\n")
      when 4294967295 # Error Timeout. This is -1 in Bignum format
      when Curses::KEY_F10
        conmsg "Quitting..."
        shutdown = true
      else
        conmsg "Unknown key hit code - #{c.inspect}"
      end
    end # until
    connection.stop
  rescue SystemExit, Interrupt
    conmsg "\nConnection closed exiting"
  rescue Exception
    conmsg "\nException caught error in client: " + $!
    conmsg $@
  ensure
    Curses.close_screen
  end

end

class ConsoleClient < Client
  def initialize(opts)
    super(opts)
    system('stty cbreak -echo') if !@opts.win32 && @opts.echo
  end

  def conmsg msg
    puts msg
  end

  def update(msg)
    case msg
    when Connection, :initdone
      super(msg)
    when :disconnected
      unsubscribe_all
      $shutdown = true
      puts "Disconnected."
      exit
    when String
      print msg
    else
      puts "Unknown msg - #{msg.inspect}"
    end
  end

  def run
    shutdown = false
    connection = Reactor.new(@opts.port, $conntype, $connio, $connopts,
       $connfilters, @opts.address)
    raise "Unable to start TeensyClient" unless connection.start(self)
    conmsg "Connected to #{@opts.address}:#{@opts.port}.  Use CTL-C to QUIT"
    until shutdown
      connection.poll(0.1)
      c = getkey
      case c
      when nil
      when 32..127
        publish(c.chr)
      when 13
        publish("\n") if @opts.win32
      when 10
        publish("\n") if !@opts.win32
      when 315
        publish("\e[11~")
      when 316
        publish("\e[12~")
      when 317
        publish("\e[13~")
      when 318
        publish("\e[14~")
      when 319
        publish("\e[15~")
      when 320
        publish("\e[17~")
      when 321
        publish("\e[18~")
      when 322
        publish("\e[19~")
      when 323
        publish("\e[20~")
      when 324 # Windows F10
        conmsg "Quitting..."
        shutdown = true
#      when 27 # xterm F10
#        if getkey == 91 && getkey == 50 && getkey == 49 && getkey == 126
#          conmsg "Quitting..."
#          shutdown = true
#        end

      when 338  # INS
        publish("\e[2~")
      when 339  # DEL
        publish("\010")
      when 327  # HOME
        publish("\e[7~")
      when 335  # END
        publish("\e[8~")
      when 329  # PAGEUP
        publish("\e[5~")
      when 337  # PAGEDOWN
        publish("\e[6~")
      when 328  # UP
        publish("\e[A")
      when 336  # DOWN
        publish("\e[B")
      when 333  # RIGHT
        publish("\e[C")
      when 331  # LEFT
        publish("\e[D")


      when 256..512
        conmsg "Unknown key hit code - #{c.inspect}"
      else
        publish(c.chr)
#        conmsg "Unknown key hit code - #{c.inspect}"
      end
    end # until
    connection.stop
  rescue SystemExit, Interrupt
    conmsg "\nConnection closed exiting"
  rescue Exception
    conmsg "\nException caught error in client: " + $!
    conmsg $@
  ensure
    system('stty -cbreak echo') if !@opts.win32 && @opts.echo
  end

end

#
# Processes command line arguments
#
require 'optparse'
require 'ostruct'
def get_options
  # parse options
  begin
    # The myopts specified on the command line will be collected in *myopts*.
    # We set default values here.
    myopts = OpenStruct.new
    myopts.port = 4000
    myopts.address = 'localhost'
    myopts.curses = false
    myopts.echo = false
    myopts.verbose = false
    myopts.trace = false
    RUBY_PLATFORM =~ /win32/ ? myopts.win32 = true : myopts.win32 = false

    opts = OptionParser.new do |opts|
      opts.banner = BANNER
      opts.separator ""
      opts.separator "Usage: ruby #{$0} [options]"
      opts.separator ""
      opts.on("-p", "--port PORT", Integer,
        "Select the port of the mud",
        "  (defaults to 4000)") {|myopts.port|}
      opts.on("-a", "--address URL", String,
        "Select the address of the mud",
        "  (defaults to \'localhost\')") {|myopts.address|}
      opts.on("-e", "--[no-]echo", "Run in server echo mode") {|myopts.echo|}
      opts.on("-t", "--[no-]trace", "Trace execution") {|myopts.trace|}
      opts.on("-c", "--[no-]curses", "Run with curses support") {|myopts.curses|}
      opts.on("-v", "--[no-]verbose", "Run verbosely") {|myopts.verbose|}
      opts.on_tail("-h", "--help", "Show this message") do
        $stdout.puts opts.help
        exit
      end
      opts.on_tail("--version", "Show version") do
        $stdout.puts "TeensyClient #{Version}"
        exit
      end
    end

    opts.parse!(ARGV)

    return myopts
  rescue OptionParser::ParseError
    $stderr.puts "ERROR - #{$!}"
    $stderr.puts "For help..."
    $stderr.puts " ruby #{$0} --help"
    exit
  end
end


if $0 == __FILE__

  $conntype = :client
  $connio = :sockio
  $connopts = [:zmp, :ttype, :naws]
  $connfilters = [:telnetfilter, :debugfilter] #, :terminalfilter]
  $opts = get_options

  if $opts.echo
    $connopts << :echo << :sga
  end

  if $opts.curses
    require 'curses'
  end

  if $opts.win32
    require 'Win32API'
    Kbhit = Win32API.new("msvcrt", "_kbhit", [], 'I')
    Getch = Win32API.new("msvcrt", "_getch", [], 'I')
    def getkey
      sleep 0.01
      return nil if Kbhit.call.zero?
      c = Getch.call
      c = Getch.call + 256 if c.zero? || c == 0xE0
      c
    end
  else
    def getkey
      select( [$stdin], nil, nil, 0.01 ) ?  c = $stdin.getc : c = nil
    end
  end

  if $opts.trace
    $tf = File.open("trace.log","w")
    set_trace_func proc { |event, file, line, id, binding, classname|
      $tf.printf "%8s %s:%-2d %10s %8s\n", event, file, line, id, classname
    }
  end

  $stdin.sync = true
  $stdout.sync = true

  if $opts.curses
    client = CursesClient.new($opts)
  else
    client = ConsoleClient.new($opts)
  end
  client.run
  $tf.close if $opts.trace
  exit

end

