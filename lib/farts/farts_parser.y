#
# file::    farts_parser.y
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

class Farts::Parser

prechigh
  nonassoc UMINUS NOT
  nonassoc GT GE LT LE
  nonassoc EQ NE 
  left     AND
  left     OR
preclow


rule

  program : stmts
            {  result = ProgramSyntaxNode.new( @sc.lineno, val[0] ) }

  stmts :
          { result = [] }
        | stmts stmt
          { result.push val[1] }
  
  stmt : expr
       | command
       | if
       | END { result = EndSyntaxNode.new( @sc.lineno, true) }
       | END TRUE { result = EndSyntaxNode.new( @sc.lineno, true) }
       | END FALSE { result = EndSyntaxNode.new( @sc.lineno, false) }
       | COMMENT { result = CommentSyntaxNode.new( @sc.lineno, val[0]) }
  
  if : IF expr stmts else ENDIF
       { result = IfSyntaxNode.new( @sc.lineno, val[1], val[2], val[3] ) }

  else : ELSE stmts { result = val[1] }
       | { result = nil }
       
  command : ID { result = CommandSyntaxNode.new( @sc.lineno, val[0] , nil ) }
          | ID STRING { result = CommandSyntaxNode.new( @sc.lineno, val[0], val[1] ) }
          
  expr : NOT expr { result = CallSyntaxNode.new( @sc.lineno, '!', [val[1]] ) }
       | expr EQ expr { result = CallSyntaxNode.new( @sc.lineno, '==', [val[0], val[2]] ) }
       | expr NE expr { result = CallSyntaxNode.new( @sc.lineno, '!=', [val[0], val[2]] ) }
       | expr GT expr { result = CallSyntaxNode.new( @sc.lineno, '>', [val[0], val[2]] ) }
       | expr GE expr { result = CallSyntaxNode.new( @sc.lineno, '>=', [val[0], val[2]] ) }
       | expr LT expr { result = CallSyntaxNode.new( @sc.lineno, '<', [val[0], val[2]] ) }
       | expr LE expr { result = CallSyntaxNode.new( @sc.lineno, '<=', [val[0], val[2]] ) }
       | expr AND expr { result = CallSyntaxNode.new( @sc.lineno, '&&', [val[0], val[2]] ) }
       | expr OR expr { result = CallSyntaxNode.new( @sc.lineno, '||', [val[0], val[2]] ) }
       | LPAREN expr RPAREN
       | SUB expr  =UMINUS
       | function
       | atom

  atom  : NUMBER   { result = LiteralSyntaxNode.new( @sc.lineno, val[0] ) }
        | FLOAT    { result = LiteralSyntaxNode.new( @sc.lineno, val[0] ) }
        | STRING   { result = LiteralSyntaxNode.new( @sc.lineno, val[0] ) }
        | ACTOR  { result = [LocalVarSyntaxNode.new( @sc.lineno, val[0] )] }
        | ACTOR SEND ID { result = [AttributeSyntaxNode.new( @sc.lineno, val[0], val[2])] }
        | THIS { result = LocalVarSyntaxNode.new( @sc.lineno, val[0] ) }
        | THIS SEND ID { result = AttributeSyntaxNode.new( @sc.lineno, val[0], val[2] ) }
        | ARGS { result = LocalVarSyntaxNode.new( @sc.lineno, val[0] ) }
        | ARGS SEND ID { result = AttributeSyntaxNode.new( @sc.lineno, val[0], val[2] ) }

  function : ID LPAREN args RPAREN
             { result = CallSyntaxNode.new( @sc.lineno, val[0], *val[2] ) }

  args  : 
        | expr  { result = [val] }
        | args COMMA expr  { result.push(val[2]) }
        
end

---- header
#
# file::    farts_parser.rb
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
end
require 'farts/farts_lexer'
require 'farts/farts_lib'

---- inner

  def initialize
    @scope = {}
  end

  def parse( str )
    @sc = Farts::Lexer.new(str)
    @yydebug = true if $DEBUG              
    do_parse
  end

  def next_token
    @sc.next_token
  end

  def on_error( t, val, values )
    raise Racc::ParseError, "Error: #{@sc.lineno}:#{@sc.tokenpos} syntax error at '#{val}'"
  end

---- footer


module Farts

  class SyntaxNode
    attr :lineno

    def initialize( lineno )
      @lineno = lineno
    end

    def exec_list(intp, nodes)
      v = nil
      nodes.each do |i|
        v = i.execute(intp)
        break if intp.hitbreak == true
      end
      v
    end

    def fart_err(msg)
      raise "Error at #{lineno}: #{msg}"
    end
  end

  class ProgramSyntaxNode < SyntaxNode

    def initialize( lineno, tree )
      super lineno
      @tree = tree
    end

    def execute(vars)
      intp = Interpreter.new(vars)
      exec_list(intp, @tree)
    end
  end

  class EndSyntaxNode < SyntaxNode

    def initialize( lineno, val )
      super lineno
      @val = val
    end

    def execute(intp)
      intp.hitbreak = true
      intp.retval = val
    end
  end

  class CommentSyntaxNode < SyntaxNode

    def initialize( lineno, val )
      super lineno
      @val = val
    end

    def execute(intp)
    end
  end

  class CallSyntaxNode < SyntaxNode

    def initialize( lineno, func, args )
      super lineno
      @funcname = func
      @args = args
    end

    def execute(intp)
      arg = @args.collect {|i| i.execute(intp) }
      begin
        case @funcname
        when "||"
          arg[0] || arg[1]
        when "&&"
          arg[0] && arg[1]
        when "!="
          arg[0] != arg[1]
        when "!"
          !arg[0]
        else
          if arg.empty? || !arg[0].respond_to?(@funcname)
            intp.call_lib_function(@funcname, arg) do
              fart_err("undefined function '#{@funcname}'")
            end
          else
            recv = arg.shift
            recv.send(@funcname, *arg)
          end
        end
      rescue ArgumentError
        pp self
        pp arg
        fart_err($!.message)
      end
    end
  end

  class CommandSyntaxNode < SyntaxNode

    def initialize( lineno, cmd, args )
      super lineno
      @cmd = cmd
      @args = args
    end

    def execute(intp)
      begin
        if @args
          intp.vars["this"].parse(@cmd + " " + @args)
        else
          intp.vars["this"].parse(@cmd)
        end
      rescue Exception
        pp self
        fart_err($!.message)
      end
    end
  end

  class IfSyntaxNode < SyntaxNode

    def initialize( lineno, condition, stmts_true, stmts_false )
      super lineno
      @condition = condition
      @stmts_true = stmts_true
      @stmts_false = stmts_false
    end

    def execute(intp)
      if @condition.execute(intp)
        exec_list(intp, @stmts_true)
      else
        exec_list(intp, @stmts_false) if @stmts_false
      end
    end
  end

  class LocalVarSyntaxNode < SyntaxNode

    def initialize( lineno, vname )
      super lineno
      @vname = vname
    end

    def execute( intp )
      if intp.vars.has_key?(@vname)
        intp.vars[@vname]
      else
        fart_err("unknown local variable '#{@vname}'")
      end
    end
  end

  class AttributeSyntaxNode < SyntaxNode

    def initialize( lineno, vname, vattr )
      super lineno
      @vname = vname
      @vattr = vattr
    end

    def execute(intp)
      begin
      if intp.vars.has_key?(@vname)
          intp.vars[@vname].send(@vattr.intern)
        else
          fart_err("unknown local variable '#{@vname}'")
        end
      rescue NameError
        fart_err($!.message)
      end
    end
  end

  class LiteralSyntaxNode < SyntaxNode

    def initialize( lineno, val )
      super lineno
      @val = val
    end

    def execute( intp )
      @val.class == String ? @val.dup : @val
    end
  end

  # The Interpreter class is an instance of a machine to execute a program
  class Interpreter
    attr_accessor :hitbreak, :retval, :vars

    # Construct an interpreter machine
    # [+vars+] A hash table of attribute name/value pairs.
    #   Currently we support 'actor' and 'this', where they are the first
    #   two parameters of an event respectively.
    def initialize(vars)
      @vars = vars  # hash table of attribute_name/value pairs
      @hitbreak = false
      @retval = true
      @lib = Lib.new
    end

    def call_lib_function( fname, args )
      if @lib.respond_to?(fname)
        @lib.send(fname, *args)
      else
        yield
      end
    end

  end

end


#
# FARTS testing
#
if $0 == __FILE__
  require 'pp'
  begin
    fart = nil
    str =""
    File.open('farts/myprog.fart') {|f|
      str = f.read
    }
    fart = Farts::Parser.new.parse( str )
    pp fart
    vars = { "actor" => "foo", "this" => "bar"}
    fart.execute(vars)
    
  rescue Racc::ParseError, Exception
    log.error $!
    exit 
  end
end

