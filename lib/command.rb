#
# file::    command.rb
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

require 'yaml'
require 'utility/ternarytrie'
require 'utility/configuration'
require 'utility/log'


# The Command class encapsulates a TeensyMud command
class Command
  attr_reader :cmd, :name, :help
  logger
  configuration

  # Create a command
  def initialize(cmd, name, help)
    @cmd,@name,@help=cmd,name,help
  end

  # load builds a command lookup trie from the commands listed in a yaml
  # config file and in the and then defines/redefines them on the GameObject
  # classes.
  # [+return+] A trie of commands (see TernaryTrie class)
  def self.load
    @log.info "Loading commands..."

    # first load the commands for objects
    ocmdtable = TernaryTrie.new
    if options['object_interface'] && !options['object_interface'].empty?
      options['object_interface'].each do |i|
        cmds = YAML::load_file("cmd/#{i}.yaml")
        cmds.each do |c|
          Kernel::load("cmd/#{i}/#{c.cmd}.rb")
          ocmdtable.insert(c.name, c)
        end
        GameObject.send(:include,ObjCmd)
      end
    else
      @log.warn "No command interfaces for GameObject"
    end

    # now load the commands for characters
    cmdtable = TernaryTrie.new
    if options['character_interface'] && !options['character_interface'].empty?
      options['character_interface'].each do |i|
        cmds = YAML::load_file("cmd/#{i}.yaml")
        cmds.each do |c|
          Kernel::load("cmd/#{i}/#{c.cmd}.rb")
          cmdtable.insert(c.name, c)
        end
        Character.send(:include,Cmd)
      end
    else
      @log.error "No command interfaces for Character"
    end

    @log.info "Done."
    return cmdtable, ocmdtable
  rescue Exception
    @log.error $!
  end

  # We need options at class level
  def self.options
    Configuration.instance.options
  end

end

