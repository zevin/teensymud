#
# file::    account.rb
# author::  Jon A. Lambert
# version:: 2.9.0
# date::    03/15/2006
#
# This source code copyright (C) 2005, 2006 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
$:.unshift "lib" if !$:.include? "lib"

require 'utility/utility'
require 'utility/log'
require 'utility/publisher'
require 'core/root'

# The Account class handles connection login and passes them to
# character.
class Account < Root
  include Publisher
  logger 'DEBUG'
  property :color, :passwd, :characters
  attr_accessor :mode, :echo, :termsize, :terminal, :conn, :character

  # Create an Account connection.  This is a temporary object that handles
  # login for character and gets them connected.
  # [+conn+]   The session associated with this Account connection.
  # [+return+] A handle to the Account object.
  def initialize(conn)
    super("",nil)
    self.passwd = nil
    self.color = false
    self.characters = []
    @conn = conn                # Reference to network session (connection)
    @mode = :initialize
    @echo = false
    @termsize = nil
    @terminal = nil
    @checked = 3                # Login retry counter - on 0 disconnect
    @account = nil              # used only during sign-in process
    @character = nil            # reference to the currently played Character.
  end

  # Receives messages from a Connection being observed and handles login
  # state.
  #
  # [+msg+]      The message string
  #
  # This supports the following:
  # [:disconnected] - This symbol from the server informs us that the
  #                 Connection has disconnected.
  # [:initdone] - This symbol from the server indicates that the Connection
  #               is done setting up and done negotiating an initial state.
  #               It triggers us to start sending output and parsing input.
  # [:termsize] - This is sent everytime the terminal size changes (NAWS)
  # [String] - A String is assumed to be input from the Session and we
  #            send it to parse_messages.
  #
  def update(msg)
    case msg
    # Handle disconnection from server
    # Note that publishing a :quit event (see #disconnect) will return a
    #  :disconnected event when server has closed the connection.
    # Guest accounts and characters are deleted here.
    when :disconnected
      @conn = nil
      unsubscribe_all
      Engine.instance.db.makeswap(id)
      if @character
        world.connected_characters.delete(@character.id)
        world.connected_characters.each do |pid|
          add_event(@character.id,pid,:show,"#{name} has disconnected.")
        end
        Engine.instance.db.makeswap(@character.id)
        @character.account = nil
        if @character.name =~ /Guest/i
          world.all_characters.delete(@character.id)
          delete_object(@character.id)
        end
        @character = nil
      end
      if name =~ /Guest/i
        world.all_accounts.delete(id)
        delete_object(id)
      end
    # Issued when a NAWS event occurs
    # Currently this clears and resets the screen.  Ideally it should attempt
    # to redraw it.
    when :termsize
      @termsize = @conn.query(:termsize)
      if vtsupport?
        publish("[home #{@termsize[1]},1][clearline][cursave]" +
          "[home 1,1][scrreset][clear][scrreg 1,#{@termsize[1]-3}][currest]")
      end
    # Negotiation with client done.  Start talking to it.
    when :initdone
      @echo = @conn.query(:echo)
      @termsize = @conn.query(:termsize)
      @terminal = @conn.query(:terminal)
      if vtsupport?
        publish("[home #{@termsize[1]},1][clearline][cursave]" +
          "[home 1,1][scrreset][clear][scrreg 1,#{@termsize[1]-3}][currest]")
        sendmsg(LOGO)
      end
      sendmsg(BANNER)
      sendmsg(append_echo("login> "))
      @mode = :name
    # This is a message from our user
    when String
      parse_messages(msg)
    else
      log.error "Account#update unknown message - #{msg.inspect}"
    end
  rescue
    # We squash and print out all exceptions here.  There is no reason to
    # throw these back at the Connection.
    log.error $!
  end


  # Handles String messages from Connection - called by update.
  # This was refactored out of Account#update for length reasons.
  #
  # [+msg+]      The message string
  #
  # @mode tracks the state changes,  The Account is created with the
  # initial state of :initialize.  The following state transition
  # diagram illustrates the possible transitions.
  #
  # :intialize -> :name         Set when Account:update receives :initdone msg
  # :name      -> :password     Sets @login_name and finds @account
  #               :playing      Creates a new character if Guest account
  # :password  -> :newacct      Sets @login_passwd
  #            -> :menu         Good passwd, switches account, if account_system
  #                             option on goes to menu
  #            -> :playing      Good passwd, switches account, loads character
  #            -> :name         Bad passwd
  #            -> disconnect    Bad passwd, exceeds @check attempts
  #                             (see Account#disconnect)
  # :newacct   -> :menu           If account_system option on goes to menu
  #            -> :playing        Creates new character, adds account
  # :menu      -> parse_menu    Redirect message (see Account#parse_menu)
  # :playing   -> @character    Redirect message (see Character#parse)
  #
  def parse_messages(msg)
    case @mode
    when :initialize
      # ignore everything until negotiation done
    when :name
      publish("[clearline]") if vtsupport?
      @login_name = msg.proper_name
      if options['guest_accounts'] && @login_name =~ /Guest/i
        self.name = "Guest#{id}"
        @character = new_char
        put_object(self)
        world.all_accounts << id
        # make the account non-swappable so we dont lose connection
        Engine.instance.db.makenoswap(id)
        @conn.set(:color, color)
        welcome
        @mode = :playing
      elsif @login_name.empty?
        sendmsg(append_echo("login> "))
        @mode = :name
      else
        acctid = world.all_accounts.find {|a|
          @login_name == get_object(a).name
        }
        @account = get_object(acctid)
        sendmsg(append_echo("password> "))
        @conn.set(:hide, true)
        @mode = :password
      end
    when :password
      @login_passwd = msg
      @conn.set(:hide, false)
      if @account.nil?  # new account
        sendmsg(append_echo("Create new user?\n'Y/y' to create, Hit enter to retry login> "))
        @mode = :newacct
      else
        if @login_passwd.is_passwd?(@account.passwd)  # good login
          # deregister all observers here and on connection
          unsubscribe_all
          @conn.unsubscribe_all
          # reregister all observers to @account
          @conn.subscribe(@account.id)
          # make the account non-swappable so we dont lose connection
          Engine.instance.db.makenoswap(@account.id)
          @conn.set(:color, @account.color)
          switch_acct(@account)
          # Check if this account already logged in
          reconnect = false
          if @account.subscriber_count > 0
            @account.publish(:reconnecting)
            @account.unsubscribe_all
            reconnect = true
          end
          @account.subscribe(@conn)
          if options['account_system']
            @account.sendmsg(append_echo(login_menu))
            @account.mode = :menu
          else
            @character = get_object(@account.characters.first)
            # make the character non-swappable so we dont lose references
            Engine.instance.db.makenoswap(@character.id)
            world.connected_characters << @character.id
            @character.account = @account
            @account.character = @character
            welcome(reconnect)
            @account.mode = :playing
          end
        else  # bad login
          @checked -= 1
          sendmsg(append_echo("Sorry wrong password."))
          if @checked < 1
            disconnect
          else
            @mode = :name
            sendmsg(append_echo("login> "))
          end
        end
      end
    when :newacct
      if msg =~ /^y/i
        self.name = @login_name
        self.passwd = @login_passwd.encrypt
        put_object(self)
        # make the account non-swappable so we dont lose connection
        Engine.instance.db.makenoswap(id)
        world.all_accounts << id
        @conn.set(:color, color)
        if options['account_system']
          sendmsg(append_echo(login_menu))
          @mode = :menu
        else
          @character = new_char
          welcome
          @mode = :playing
        end
      else
        @mode = :name
        sendmsg(append_echo("login> "))
      end
    when :menu, :menucr, :menupl
      parse_menu(msg)
    when :playing
      @character.parse(msg)
    else
      log.error "Account#parse_messages unknown :mode - #{@mode.inspect}"
    end
  end

  # Handles message while in the login menu - called by parse_messages.
  # This was refactored out of Account#parse_messages for length reasons.
  #
  # [+msg+]      The message string
  #
  # @mode tracks the state changes,  This routine is entered by any @modes
  # staring with :menu.
  #
  # The following state transition diagram illustrates the possible transitions.
  #
  # :menu      -> :menucr       Create a character
  #            -> :menupl       Play a character
  # :menucr    -> :playing      Get character name, create character and play
  #
  def parse_menu(msg)
    case @mode
    when :menu
      case msg
      when /^1/i
        sendmsg(append_echo("Enter character name> "))
        @mode = :menucr
      when /^2/i
        if characters.size == 0
          sendmsg(append_echo(login_menu))
          @mode = :menu
        else
          sendmsg(append_echo(character_menu))
          @mode = :menupl
        end
      when /^Q/i
        disconnect
      else                        # Any other key
        sendmsg(append_echo(login_menu))
        @mode = :menu
      end
    when :menucr
      if msg.proper_name.empty?
        sendmsg(append_echo(login_menu))
        @mode = :menu
      else
        @character = new_char(msg.proper_name)
        @conn.set(:color, color)
        welcome
        @mode = :playing
      end
    when :menupl
      case msg
      when /(\d+)/
        if $1.to_i >= characters.size
          sendmsg(append_echo(character_menu))
        else
          @character = get_object(characters[$1.to_i])
          # make the character non-swappable so we dont lose references
          Engine.instance.db.makenoswap(@character.id)
          world.connected_characters << @character.id
          @character.account = self
          welcome
          @mode = :playing
        end
      else
        sendmsg(append_echo(login_menu))
        @mode = :menu
      end
    else
      log.error "Account#parse_menu unknown :mode - #{@mode.inspect}"
    end
  end

  # If echo hasn't been negotiated, we want to leave the cursor after
  # the message prompt, so we prepend linefeeds in front of messages.
  # This is hackish.
  def append_echo(msg)
    @echo ? msg : "\n" + msg
  end

  def sendmsg(msg)
    publish("[cursave][home #{@termsize[1]-3},1]") if vtsupport?
    publish(msg)
    publish("[currest]") if vtsupport?
    prompt
  end

  def prompt
    if vtsupport?
=begin
      publish("[cursave][home #{@termsize[1]-2},1]" +
        "[color Yellow on Red]#{" "*@termsize[0]}[/color]" +
        "[home #{@termsize[1]-1},1][clearline][color Magenta](#{name})[#{@mode}][/color]" +
        "[currest][clearline]> ")
=end
      publish("[home #{@termsize[1]-2},1]" +
        "[color Yellow on Red]#{" "*@termsize[0]}[/color]" +
        "[home #{@termsize[1]-1},1][clearline][color Magenta](#{name})[#{@mode}][/color]" +
        "[home #{@termsize[1]},1][clearline]> ")
    else
#      publish("> ")
    end
  end

  def status_rept
    str = "Terminal: #{@terminal}\n"
    str << "Terminal size: #{@termsize[0]} X #{@termsize[1]}\n"
    str << "Colors toggled #{@color ? '[COLOR Magenta]ON[/COLOR]' : 'OFF' }\n"
    str << "Echo is #{@echo ? 'ON' : 'OFF' }\n"
    str << "ZMP is #{@conn.query(:zmp) ? 'ON' : 'OFF' }\n"
  end

  def toggle_color
    color ? self.color = false : self.color = true
    @conn.set(:color,color)
    "Colors toggled #{color ? '[COLOR Magenta]ON[/COLOR]' : 'OFF' }\n"
  end


  # Disconnects this account
  def disconnect(msg=nil)
    publish("[home 1,1][scrreset][clear]") if vtsupport?
    publish(msg + "\n") if msg
    publish("Bye!\n")
    publish(:quit)
    unsubscribe_all
  end

  def character_menu
    str = '[color Yellow]'
    characters.each_index do |i|
      str << "#{i}) #{get_object(characters[i]).name}\n"
    end
    str << "Pick a character>[/color] "
  end

  def login_menu
    "[color Yellow]1) Create a character\n2) Play\nQ) Quit\n>[/color] "
  end

  def vtsupport?
    @terminal =~ /^vt|xterm/
  end
private
  def new_char(nm=nil)
    if nm.nil?
      ch = Character.new(name,id)
    else
      ch = Character.new(nm,id)
    end
    self.characters << ch.id
    world.all_characters << ch.id
    ch.account = self
    get_object(options['home'] || 1).add_contents(ch.id)
    put_object(ch)
    Engine.instance.db.makenoswap(ch.id)
    world.connected_characters << ch.id
    ch
  end

  def switch_acct(acct)
    acct.conn = @conn
    acct.echo = @echo
    acct.termsize = @termsize
    acct.terminal = @terminal
    acct.character = @character
  end

  def welcome(reconnect=false)
    rstr = reconnect ? 'reconnected' : 'connected'
    @character.sendto(append_echo("Welcome #{@character.name}@#{@conn.query(:host)}!"))
    world.connected_characters.each do |pid|
      if pid != @character.id
        add_event(@character.id,pid,:show,"#{@character.name} has #{rstr}.")
      end
    end
    @character.parse('look')
  end

end

