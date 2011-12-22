#
# file::    boolexp_parser.y
# author::  Jon A. Lambert
# version:: 2.8.0
# date::    02/21/2006
#
# This source code copyright (C) 2005, 2006 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#

class BoolExpParser

  prechigh
    nonassoc '!'
    left '&'
    left '|'
  preclow

rule

  exp: exp '&' exp { result &&= val[2] }
     | exp '|' exp { result ||= val[2] }
     | '(' exp ')' { result = val[1] }
     | '!' NUMBER  { result = !@obj.contents.include?(val[1]) }
     | NUMBER      { result = @obj.contents.include?(val[0]) }
     ;

end

---- header ----

#
# file::    boolexp_parser.rb
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

if $0 == __FILE__
  Dir.chdir("../..")
  $:.unshift "../../lib"
  require 'pp'
end
require 'core/script'

---- inner ----

  def initialize(obj)
    @obj = obj
  end

  def parse(str)
    @q = []
    until str.empty?
      case str
      when /\A\s+/
      when /\A[#]?(\d+)/
        @q.push [:NUMBER, $1.to_i]
      when /\A.|\n/o
        s = $&
        @q.push [s, s]
      end
      str = $'
    end
    @q.push [false, '$end']
    do_parse
  end

  def next_token
    @q.shift
  end

---- footer ----


#
# BoolExp testing
#
if $0 == __FILE__
  class Obj
    attr_accessor :contents
  end

  actor = Obj.new
  actor.contents = [234]
  str ="((!#245)&#234)"

  begin
    x = BoolExpParser.new(actor).parse(str)
    pp str, actor.contents, x
    actor.contents = [234,245]
    x = BoolExpParser.new(actor).parse(str)
    pp str, actor.contents, x
    str ="((!#1)&#1)"
    x = BoolExpParser.new(actor).parse(str)
    pp str, actor.contents, x
    str ="234|1"
    x = BoolExpParser.new(actor).parse(str)
    pp str, actor.contents, x
    str ="xxxxxxxx"
    x = BoolExpParser.new(actor).parse(str)
    pp str, actor.contents, x

  rescue Racc::ParseError, Exception
    pp $!
    exit 
  end
end

