#
# file::    ocmd_echoat.rb
# author::  Jon A. Lambert
# version:: 2.4.0
# date::    09/12/2005
#
# This source code copyright (C) 2005 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
module ObjCmd

  # This command echos input to location
  def ocmd_echoat(args)
    case args
    when nil, ""
      false
    when /(\d+) (.*)/
      get_object($1.to_i).characters(id).each do |p|
        add_event(id,p.id,:show,$2)
      end
      true
    else
      false
    end
  end

end
