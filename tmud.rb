#!/usr/bin/env ruby
#
# file::    tmud.rb
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

require 'optparse'

require 'utility/utility'
require 'utility/configuration'
require 'engine/engine'
require 'utility/version'

#
# Processes command line arguments
#
def get_options
  # parse options
  begin
    # The myopts specified on the command line will be collected in *myopts*.
    # We set default values here.
    myopts = {}

    opts = OptionParser.new do |opts|
      opts.banner = BANNER
      opts.separator ""
      opts.separator "Usage: ruby #{$0} [options]"
      opts.separator ""
      opts.on("-p", "--port PORT", Integer,
        "Select the port the mud will run on") {|myopts['server_port']|}
      opts.on("-d", "--dbfile DBFILE", String,
        "Select the name of the database file",
        "  (default is 'db/world.yaml')") {|myopts['dbfile']|}
      opts.on("-c", "--config CONFIGFILE", String,
        "Select the name of the configuration file",
        "  (default is 'config.yaml')") {|myopts['configfile']|}
      opts.on("-l", "--logfile LOGFILE", String,
        "Select the name of the log file",
        "  (default is 'logs/server.log')") {|myopts['logfile']|}
      opts.on("-h", "--home LOCATIONID", Integer,
        "Select the object id where new characters will start") {|myopts['home']|}
      opts.on("-t", "--[no-]trace", "Trace execution") {|myopts['trace']|}
      opts.on("-v", "--[no-]verbose", "Run verbosely") {|myopts['verbose']|}
      opts.on_tail("-h", "--help", "Show this message") do
        $stdout.puts opts.help
        exit
      end
      opts.on_tail("--version", "Show version") do
        $stdout.puts "TeensyMud #{Version}"
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


###########################################################################
# This is start of the main driver.
###########################################################################

if $0 == __FILE__
  begin
    $cmdopts = get_options
    $cmdopts.each do |key,val|
      Configuration.instance.options[key] = val
    end

    Engine.instance.run
  end
end

