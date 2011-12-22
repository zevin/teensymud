#
# file::    cmd_script.rb
# author::  Jon A. Lambert
# version:: 2.8.0
# date::    02/21/2005
#
# This source code copyright (C) 2005, 2006 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
module Cmd

  # adds, deletes, lists, or  a script
  # Syntax:
  #   @script add <lang> <progname>|<code>
  #   @script del #<scriptid>
  #   @script show #<scriptid>
  # (ex. @script add fart myprog)
  # (ex. @script add boolexp #234|#42&#34 )
  def cmd_script(args)
    case args
    when /del\s+#(\d+)/
      s = get_object($1.to_i)
      case s
      when Script
        delete_object(s.id)
        sendto("Script #$1 deleted.")
      else
        sendto("No script.")
      end
    when /add\s+(\w+)\s+(.*)/
      case $1.intern
      when :fart
        s = Script.new($2.strip, id, $1.intern)
        put_object(s)
        sendto("Script #{s.id} added.")
      when :boolexp
        s = Script.new(nil, id, $1.intern)
        s.load($2.strip)
        put_object(s)
        sendto("Script #{s.id} added.")
      else
        sendto("No language.")
      end
    when /show\s+#(\d+)/
      s = get_object($1.to_i)
      case s
      when Script
        s.load if !s.src
        sendto(s.src)
      else
        sendto("No script.")
      end
    else
      sendto("What??")
    end
  end

end
