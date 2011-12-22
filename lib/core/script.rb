#
# file::    script.rb
# author::  Jon A. Lambert
# version:: 2.8.0
# date::    02/19/2006
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
require 'core/root'
require 'farts/farts_parser'
require 'utility/boolexp'

# The Script class defines te characteristic of an executable program.
#
class Script < Root
  property :language, :src
  attr_accessor :prog
  logger 'DEBUG'

  # Create a new Script
  # [+name+]     The filename of the script
  # [+owner+]    The owner id of this script
  # [+language+] The language of the script
  # [+return+]   A handle to the new Object
  def initialize(name, owner, language)
    super(name, owner)
    self.language = language
    @prog = nil
  end

  # Load a program
  # [+return+]   success or failure
  def load(str=nil)
    case language
    when :boolexp
      self.src = str
      log.info "Load of BoolExp program - #{name}"
      true
    when :fart
      File.open("farts/#{name}.fart") {|f|
        self.src = f.read
      }
      log.info "Load of FART program - #{name}"
      true
    else
      false
    end
  end

  # Compile a program
  # [+return+]   success or failure
  def compile
    case language
    when :boolexp
      true
    when :fart
      @prog = Farts::Parser.new.parse(src)
      log.info "Compile of FART program - #{name}"
      true
    else
      false
    end
  rescue Exception
    log.error $!
    @prog = nil
    false
  end

  # Execute a program
  # [+return+]   success or failure
  def execute(ev)
    case language
    when :boolexp
      actor = get_object(ev.from)
      BoolExpParser.new(actor).parse(src)
    when :fart
      vars = {}
      vars['actor'] = get_object(ev.from)
      vars['this'] = get_object(ev.to)
      if ev.msg.kind_of?(GameObject)
        vars['args'] = get_object(ev.msg)
      else
        vars['args'] = ev.msg
      end
      load if !@prog
      compile if !@prog
      @prog ? @prog.execute(vars) : false
    else
      false
    end
  rescue Exception
    log.error $!
    false
  end

end

