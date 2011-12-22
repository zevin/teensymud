#
# file::    cmd_go.rb
# author::  Jon A. Lambert
# version:: 2.10.0
# date::    06/27/2006
#
# This source code copyright (C) 2005 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
module Cmd

  # sends <message> to all characters in the room
  def cmd_go(args)
    case args
    when nil, ""
      sendto("Where do you want to go?")
    else
      ex = []
      ext = nil
      get_object(location).exits.each do |exid|
        ext = get_object(exid)
        ex = ext.name.split(/;/).grep(/^#{args}/)
        break if !ex.empty?
      end
      if ex.empty?
        sendto("Can't find that place")
      elsif ex.size > 1
        ln = "Which did you mean, "
        ex.each {|x| ln << "\'" << x << "\' "}
        ln << "?"
        sendto(ln)
      else
        add_event(id,ext.id,:leave, args)
      end
    end
  end

end
