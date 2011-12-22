#
# file::    character.rb
# author::  Jon A. Lambert
# version:: 2.10.0
# date::    06/25/2006
#
# This source code copyright (C) 2005, 2006 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
$:.unshift "lib" if !$:.include? "lib"

require 'core/gameobject'

# The Character class is the mother of all characters.
# Who's their daddy?
#
class Character < GameObject
  logger 'DEBUG'

  # The acctid object this character is associated with.
  property :acctid
  attr_accessor :account # The reference to the account object
                         # (nil if not logged in)

  # Create a new Character object
  # IMPORTANT :Character objects must be marked nonswappable while connected!!!
  #       Otherwise we risk losing the contants of @account
  # [+name+]    The displayed name of the character.
  # [+acctid+]  The account id this character belongs to.
  # [+return+]  A handle to the new Character.
  def initialize(name,acctid)
    super(name, nil, options['home'] || 1)
    self.acctid = acctid
    @account = nil              # reference to the Account.  If nil this
                                # character is not logged in.
                                # We could use get_object(acctid) but
                                # holding the reference is faster
  end

  # Sends a message to the character if they are connected.
  # [+s+]      The message string
  # [+return+] Undefined.
  def sendto(s)
    @account.sendmsg(s+"\n") if @account
  end

  # All command input routed through here and parsed.
  # [+m+]      The input message to be parsed
  # [+return+] Undefined.
  def parse(m)
    @account.prompt
    # handle edit mode
    if @mode == :edit
      edit_parser m
      return
    end

    # match legal command
    m=~/([A-Za-z0-9_@?"'#!\]\[]+)(.*)/
    cmd=$1
    arg=$2
    arg.strip! if arg
    if !cmd
      sendto("Huh?")
      return
    end

    # look for a command in our spanking new table
    c = world.cmds.find(cmd)


    # add any exits to our command list
    # escape certain characters in cmd
    check = cmd.gsub(/\?/,"\\?")
    check.gsub!(/\#/,"\\#")
    check.gsub!(/\[/,"\\[")
    check.gsub!(/\]/,"\\]")
    get_object(location).exits.each do |exid|
      ext = get_object(exid)
      ext.name.split(/;/).grep(/^#{check}/).each do |ex|
        c << Command.new(:cmd_go,"go #{ex}",nil)
        arg = ex
      end
    end
    log.debug "parse commands - '#{c.inspect}', arguments - '#{arg}', check - '#{check}'"

    # there are three possibilities here
    case c.size
    when 0   # no commands found
      sendto("Huh?")
    when 1   # command found
      self.send(c[0].cmd, arg)
    else     # ambiguous command - tell luser about them.
      ln = "Which did you mean, "
      c.each do |x|
        ln += "\'" + x.name + "\'"
        x.name == c.last.name ? ln += "?" : ln += " or "
      end
      sendto(ln)
    end
  rescue Exception
    # keep character alive after exceptions
    log.fatal $!
  end

  # Event :describe
  # [+e+]      The event
  # [+return+] Undefined
  def describe(e)
    msg = "[COLOR Cyan]#{name} is here.[/COLOR]"
    add_event(id,e.from,:show,msg)
  end

  # Event :show
  # [+e+]      The event
  # [+return+] Undefined
  def show(e)
    sendto(e.msg)
  end

end

