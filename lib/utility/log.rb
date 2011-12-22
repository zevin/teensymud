#
# file::    log.rb
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

require 'singleton'
require 'log4r'
require 'utility/configuration'

# The Log class is a singleton that handles logging at the class level
#
class Log
  include Singleton
  include Log4r
  configuration

  # Load logger configuration
  def initialize
    Logger['global'].level = DEBUG
    fmt = PatternFormatter.new(:pattern => "%d [%5l] (%c) %M",
                               :date_pattern => "%y-%m-%d %H:%M:%S")
    StderrOutputter.new('stderr', :level => INFO, :formatter => fmt)
    FileOutputter.new('server', :level => DEBUG, :formatter => fmt,
         :filename => options['logfile'] || 'logs/server.log' ,
         :trunc => 'false')
  end

  # Access a logger class
  # [+logname+]  The name of the logger
  # [+loglevel+] the level of logging to do
  def loginit(logname, loglevel, logto)
    Logger.new(logname, Log4r.const_get(loglevel)).outputters = logto
    Logger[logname]
  end

end

class Module

# logger defines a named log and log method for the class
#
# [+loglevel+] the level of logging to do
  def logger(loglevel='DEBUG', logto=['stderr','server'])
    class_eval <<-EOD
      @log = Log.instance.loginit(self.name, "#{loglevel}", #{logto.inspect})
      def log
        self.class.instance_variable_get :@log
      end
    EOD
  end
end

