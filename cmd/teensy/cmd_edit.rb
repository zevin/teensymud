#
# file::    cmd_edit.rb
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
module Cmd

  # @edits a string field on an object
  # Syntax:
  #   @edit #<id> <field>
  #   @edit sysmsg <field>
  # (ex. @edit #1 desc
  def cmd_edit(args)
    case args
    when nil, ""
      sendto("What??")
    when /sysmsg\s+(\w+)/
      @mode = :edit
      @editobj = world.msgs
      @editfield = $1.intern
      @editstr = world.msgs[$1.intern] || ''
      sendto(edit_display(@editstr))
    when /#(\d+)\s+(\w+)/
      o = get_object($1.to_i)
      case o
      when GameObject, Room, Character, Script, Exit
        if o.respond_to?($2) &&
           o.respond_to?("#$2=") &&
           o.send($2).class == String

          @mode = :edit
          @editobj = o
          @editfield = $2
          @editstr = o.send $2

          sendto(edit_display(@editstr))
        else
          sendto("Field #$2 not found on object.")
        end
      else
        sendto("No object.")
      end
    else
      sendto("What??")
    end
  end

  def edit_display(str)
    header =<<EOD
======== Teensy String Editor ========
   Type .h on a new line for help
 Terminate with a @ on a blank line.
======================================
EOD
    i = 0
    header + str.gsub(/^/){"#{i+=1}: "}
  end

  def word_wrap(s, len)
    str = s
    str.gsub!(/\n/,' ');str.squeeze!(' ')
    str.gsub!(/(\S{#{len}})(?=\S)/,'\1 ')
    str.scan(/(.{1,#{len}})(?:\s+|$)/).flatten.join("\n")
  end

  def edit_parser(args)
    case args
    when nil
      sendto("What??")
    when /^\.h/
      sendto <<EOD
@edit help (commands on blank line):
.r /old/new/     - replace a substring
.h               - get help (this info)
.s               - show string so far
.ww [width]      - word wrap string (width optional)
                   defaults to 76
.c               - clear string so far
.ld <num>        - delete line <num>
.li <num> <txt>  - insert <txt> before line <num>
.lr <num> <txt>  - replace line <num> with <txt>
@                - end string
EOD
    when /^\.c/
      @editstr = ""
    when /^\.s/
      sendto(edit_display(@editstr))
    when /^\.r\s+\/(.+)?\/(.+)?\//
      @editstr.gsub!($1, '\2')
    when /^\.ww\s+(\d+)/, /^\.ww/
      @editstr = word_wrap(@editstr, $1 && $1.to_i > 2 ? $1.to_i : 76 )
    when /^\.ld\s+(\d+)/
      idx = $1.to_i
      return if idx < 1
      idx -= 1
      lines = @editstr.split("\n")
      lines.delete_at(idx)
      @editstr = lines.join("\n")
    when /^\.li\s+(\d+)\s+(.*)?$/
      idx = $1.to_i
      return if idx < 1
      idx -= 1
      nl = $2
      lines = @editstr.split("\n")
      lines.insert(idx, nl + "\n")
      @editstr = lines.join("\n")
    when /^\.lr\s+(\d+)\s+(.*)?$/
      idx = $1.to_i
      return if idx < 1
      idx -= 1
      nl = $2
      lines = @editstr.split("\n")
      lines[idx] = nl + "\n"
      @editstr = lines.compact.join("\n")
    when /^@/
      @mode = nil
      if @editobj.object_id == world.msgs.object_id  # detect sysmsgs
        @editobj.send("[]=", @editfield, @editstr)
      else
        @editobj.send(@editfield+"=", @editstr)
      end
    when /^\./
      sendto "Invalid command."
    else
      @editstr << args << "\n"
    end
  end

end
