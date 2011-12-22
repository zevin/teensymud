#!/usr/bin/env ruby
#
# file::    dbload.rb
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

# This utility program loads a yaml file to a database
#
class Loader
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
      require 'storage/sqlitehash'
    when :sqlite3
      require 'sqlite3'
      require 'storage/sqlite3hash'
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
      opts.banner = "Database Loader #{VERSION}"
      opts.separator ""
      opts.separator "Usage: ruby #{$0} [options]"
      opts.separator ""
      opts.separator "Options:"
      opts.on("-i", "--ifile FILE", String,
              "Select the yaml file to read",
              "  defaults to same as database") {|myopts.ifile|}
      opts.on("-o", "--ofile FILE", String,
              "Select the database file to write",
              "  extension determined automatically") {|myopts.ofile|}
      opts.on("-t", "--type DBTYPE", DATABASES,
              "Select the database type - required (no default)",
              "  One of: #{DATABASES.join(", ")}",
              "    Example: -t gdbm") {|myopts.dbtype|}
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts.help
        exit
      end
      opts.on_tail("-v", "--version", "Show version") do
        puts "Database Loader #{VERSION}"
        exit
      end
    end

    opts.parse!(ARGV)
    raise(OptionParser::MissingArgument.new("-t")) if myopts.dbtype == nil
    raise(OptionParser::ParseError, "Must specify input file!") if myopts.ifile.nil?
    myopts.ofile = myopts.ifile.dup if myopts.ofile.nil?
    myopts.ofile << ".gdbm" if myopts.dbtype == :gdbm
    myopts.ofile << ".sqlite" if myopts.dbtype == :sqlite
    myopts.ofile << ".sqlite3" if myopts.dbtype == :sqlite3
    myopts.ifile << ".yaml"

    return myopts
  rescue OptionParser::ParseError
    puts "ERROR - #{$!}"
    puts "For help..."
    puts " ruby #{$0} --help"
    exit
  end

  #
  # Launches the loader
  #
  def run

    YAML::load_file(@opts.ifile).each do |o|
      @dbtop = o.id if o.id > @dbtop
      @db[o.id]=o
      @count += 1
    end

    case @opts.dbtype
    when :sdbm
      SDBM.open(@opts.ofile, 0666) do |db|
        @db.each {|k,v| db[k.to_s] = Utility.encode(v)}
      end
    when :gdbm
      GDBM.open(@opts.ofile, 0666) do |db|
        @db.each {|k,v| db[k.to_s] = Utility.encode(v)}
      end
    when :dbm
      DBM.open(@opts.ofile, 0666) do |db|
        @db.each {|k,v| db[k.to_s] = Utility.encode(v)}
      end
    when :sqlite
      db = SQLite::Database.open(@opts.ofile)
      begin
        db.execute("drop table tmud;")
      rescue
      end
      db.execute("create table tmud (id integer primary key, data text);")
      @db.each {|k,v| db[k] = Utility.encode(v)}
      db.close
    when :sqlite3
      db = SQLite3::Database.open(@opts.ofile)
      begin
        db.execute("drop table tmud;")
      rescue Exception
      end
      db.execute("create table tmud (id integer primary key, data text);")
      @db.each {|k,v| db[k] = Utility.encode(v)}
      db.close
    end

    puts "Highest object in use   : #{@dbtop}"
    puts "Count of objects dumped : #{@count}"
  end

end

app = Loader.new.run

