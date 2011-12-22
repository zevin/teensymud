#
# file::    fartlexer.rb
# author::  Jon A. Lambert
# version:: 2.4.0
# date::    09/09/2005
#
# This source code copyright (C) 2005 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
require 'strscan'

module Farts

# The Lexer class converts the text of a program to tokens
#
# [+token+] is the current token being assembled
class Lexer < StringScanner
  # Table of keywords and token type values
  Keywords = %w(if else endif and or end args actor this true false)

  def initialize(str)
    @token = [:UNKNOWN, nil]
    super(str)
  end

  def next_token
    @token = [:UNKNOWN, nil]
    scan(/\s+/)
    check_unary if @token[0] == :UNKNOWN
    check_binary if @token[0] == :UNKNOWN
    check_string if @token[0] == :UNKNOWN
    check_numeric if @token[0] == :UNKNOWN
    check_ident if @token[0] == :UNKNOWN
    if @token[0] == :COMMENT
      @token[1] += skip_line
    end
    if @token[0] == :UNKNOWN
      @token[1] = scan_until(/\s+/)
    end
    return [false,false] if eos?
    return @token
  end

  def tokenpos
    p = string[0,pos].rindex("\n")
    p = -1 if !p
    pos - p
  end

  def lineno
    string[0,pos].count("\n") + 1
  end

private

  def skip_line
    exist?(/\n/) ? scan_until(/\n/) : terminate
  end

  def skip_comment
    exist?(/\*\//) ? scan_until(/\*\//) : terminate
  end

  def check_unary
    case self.peek(1)
    when '+' then @token = [:ADD, '+']
    when '-' then @token = [:SUB, '-']
    when '*' then @token = [:MUL, '*']
    when '%' then @token = [:MOD, '%']
    when '/' then @token = [:DIV, '/']
    when '$' then @token = [:DOLLAR, '$']
    when '@' then @token = [:ATSIGN, '@']
    when '#' then @token = [:COMMENT, '#']
    when ',' then @token = [:COMMA, ',']
    when '.' then @token = [:SEND, '.']
    when ';' then @token = [:SEMI, ';']
    when ':' then @token = [:COLON, ':']
    when '(' then @token = [:LPAREN, '(']
    when ')' then @token = [:RPAREN, ')']
    when '{' then @token = [:LBRACE, '{']
    when '}' then @token = [:RBRACE, '}']
    when '[' then @token = [:LBRACKET, '[']
    when ']' then @token = [:RBRACKET, ']']
    end
    self.getch if @token[0] != :UNKNOWN
  end

  def check_binary
    case peek(1)
    when '!'
      @token = [:NOT, '!']; getch
      case peek(1)
      when '='
        @token = [:NE, '!=']; getch
      end
    when '='
      @token = [:ASSIGN, '=']; getch
      case peek(1)
      when '='
        @token = [:EQ, '==']; getch
      end
    when '>'
      @token = [:GT, '>']; getch
      case peek(1)
      when '='
        @token = [:GE, '>=']; getch
      end
    when '<'
      @token = [:LT, '<']; getch
      case peek(1)
      when '='
        @token = [:LE, '<=']; getch
      end
    when '&'
      @token = [:BITAND, '&']; getch
      case peek(1)
      when '&'
        @token = [:AND, '&&']; getch
      end
    when '|'
      @token = [:BITOR, '|']; getch
      case peek(1)
      when '|'
        @token = [:OR, '||']; getch
      end
    end
  end

  def check_string
    return if !scan(/"/)
    done = false
    str = ""

    while !done
      c = getch
      case c
      when '\\'
        c = getch
        case c
        when 't' then str += "\t"
        when 'f' then str += "\f"
        when 'r' then str += "\r"
        when 'n' then str += "\n"
        when '"' then str += "\""
        when '\\' then str += "\\"
        when '\'' then str += "\'"
        end
      when "\n", '"' then done = true
      else
        str += c
      end
    end
    @token = [:STRING,str]
  end

  def check_numeric
    num = scan(/\d+\.\d+/)
    if num
      @token = [:FLOAT,num.to_f]
      return
    end
    num = scan(/\d+/)
    if num
      @token = [:NUMBER,num.to_i]
      return
    end
  end

  def check_ident
    word = scan(/\w+/)
    return if !word

    @token = [:ID, word]

    i = Keywords.index(word)
    if i
      @token  = [Keywords[i].upcase.intern, word]
      return
    end

  end

end

end