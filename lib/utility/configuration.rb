#
# file::    config.rb
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

require 'singleton'
require 'yaml'

# The Config class is a singleton that allows class level configuration
#
class Configuration
  include Singleton
  attr_reader :options

  def initialize
    $cmdopts = get_options
    @options = YAML::load_file($cmdopts['configfile'] || 'config.yaml')
  rescue
    $stderr.puts "WARNING - configuration file not found"
    @options = {}
  end

  # only process configuration file option from command line
  def get_options
    myopts = {}
    ARGV.each_with_index do |arg,i|
      if (arg == '-c' || arg == '--config') && ARGV[i+1]
        myopts['configfile'] = ARGV[i+1]
        ARGV.delete_at(i+1)
        ARGV.delete_at(i)
      end
    end
    myopts
  end
end

class Module

# configure adds the options method to a class which allows it to access
# the global configuration hash.
#
# [+name+] an arrays of symbols representing the attributes on the object.
  def configuration()
    class_eval <<-EOD
      def options
        Configuration.instance.options
      end
    EOD
  end

end

