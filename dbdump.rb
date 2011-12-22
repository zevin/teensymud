#!/usr/bin/env ruby
#
# file::    dbdump.rb
# author::  Jon A. Lambert
# version:: 2.9.0
# date::    03/16/2006
#
# This source code copyright (C) 2005, 2006 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
$:.unshift "lib" if !$:.include? "lib"
$:.unshift "vendor" if !$:.include? "vendor"

require 'yaml'
require 'optparse'
require 'ostruct'
require 'pp'
require 'utility/utility'
require 'storage/properties'
require 'core/character'
require 'core/room'
require 'core/world'
require 'core/script'
require 'core/account'

# This utility program dumps a database to yaml
#
class Dumper
  VERSION = "0.2.0"

  attr_accessor :opts
  DATABASES = [:dbm, :gdbm, :sdbm, :sqlite, :sqlite3]

  def initialize
    @opts = get_options
    case @opts.dbtype
    when :dbm
      require 'dbm'
    when :gdbm
      require 'gdbm'
    when :sdbm
      require 'sdbm'
    when :sqlite
      require 'sqlite'
    when :sqlite3
      require 'sqlite3'
    end
    @dbtop = 0
    @db = {}
    @count = 0
  end

  #
  # Processes command line arguments
  #
  def get_options

    # The myopts specified on the command line will be collected in *myopts*.
    # We set default values here.
    myopts = OpenStruct.new
    myopts.ifile = nil
    myopts.ofile = nil
    myopts.dbtype = nil

    opts = OptionParser.new do |opts|
      opts.banner = "Database Dumper #{VERSION}"
      opts.separator ""
      opts.separator "Usage: ruby #{$0} [options]"
      opts.separator ""
      opts.separator "Options:"
      opts.on("-i", "--ifile FILE", String,
              "Select the database file to read",
              "  extension determined automatically") {|myopts.ifile|}
      opts.on("-o", "--ofile FILE", String,
              "Select the yaml file to write",
              "  defaults to same as database") {|myopts.ofile|}
      opts.on("-t", "--type DBTYPE", DATABASES,
              "Select the database type - required (no default)",
              "  One of: #{DATABASES.join(", ")}",
              "    Example: -t gdbm") {|myopts.dbtype|}
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts.help
        exit
      end
      opts.on_tail("-v", "--version", "Show version") do
        puts "Database Dumper #{VERSION}"
        exit
      end
    end

    opts.parse!(ARGV)
    raise(OptionParser::MissingArgument.new("-t")) if myopts.dbtype == nil
    raise(OptionParser::ParseError, "Must specify input file!") if myopts.ifile.nil?
    myopts.ofile = myopts.ifile.dup if myopts.ofile.nil?
    myopts.ifile << ".gdbm" if myopts.dbtype == :gdbm
    myopts.ifile << ".sqlite" if myopts.dbtype == :sqlite
    myopts.ifile << ".sqlite3" if myopts.dbtype == :sqlite3
    myopts.ofile << ".yaml"

    return myopts
  rescue OptionParser::ParseError
    puts "ERROR - #{$!}"
    puts "For help..."
    puts " ruby #{$0} --help"
    exit
  end

  def store(v)
    o = Utility.decode(v)
    @dbtop = o.id if o.id > @dbtop
    @db[o.id]=o
    @count += 1
  end

  #
  # Launches the dumper
  #
  def run
    case @opts.dbtype
    when :sdbm
      SDBM.open(@opts.ifile, 0666) do |db|
        db.each_value {|v| store v}
      end
    when :gdbm
      GDBM.open(@opts.ifile, 0666) do |db|
        db.each_value {|v| store v}
      end
    when :dbm
      DBM.open(@opts.ifile, 0666) do |db|
        db.each_value {|v| store v}
      end
    when :sqlite
      db = SQLite::Database.open(@opts.ifile)
      db.execute("select data from tmud;") do |v|
        store v.first
      end
      db.close
    when :sqlite3
      db = SQLite3::Database.open(@opts.ifile)
      db.execute("select data from tmud;") do |v|
        store v.first
      end
      db.close
    end

    File.open(@opts.ofile,'wb') do |f|
      YAML::dump(@db.values,f)
    end

    puts "Highest object in use   : #{@dbtop}"
    puts "Count of objects dumped : #{@count}"
  end

end

app = Dumper.new.run

