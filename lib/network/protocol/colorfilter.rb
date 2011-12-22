#
# file::    colorfilter.rb
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

require 'network/protocol/filter'
require 'network/protocol/colorcodes'

# The ColorFilter class implements ANSI color (SGR) support.
#
# A Filter can keep state and partial data
class ColorFilter < Filter
  logger 'DEBUG'

  # The filter_out method filters output data
  # [+str+]    The string to be processed
  # [+return+] The filtered data
  def filter_out(str)
    return "" if str.nil? || str.empty?
    if @pstack.color_on
      str.gsub!(/\[COLOR\s+(\w+)\s+ON\s+(\w+)\]/mi) do |m|
        if ColorTable[$1] && ColorTable[$2]
          ColorTable[$1][2]+ColorTable[$2][3]
        else
          ''
        end
      end
      str.gsub!(/\[COLOR\s+(\w+)\]/mi) do |m|
        if ColorTable[$1]
          ColorTable[$1][2]
        else
          ''
        end
      end
      str.gsub!(/\[\/COLOR\]/mi) do |m|
        ANSICODE['reset']
      end
      str.gsub!(/\[[BI]\]/mi) do |m|
        ANSICODE['bold']
      end
      str.gsub!(/\[U\]/mi) do |m|
        ANSICODE['underline']
      end
      str.gsub!(/\[\/[BUI]\]/mi) do |m|
        ANSICODE['reset']
      end
    else
      str.gsub!(/\[COLOR\s+(\w+)\s+ON\s+(\w+)\]/mi,'')
      str.gsub!(/\[COLOR\s+(\w+)\]|\[\/COLOR\]/mi, '')
      str.gsub!(/\[SIZE .*?\]|\[\/SIZE\]/mi, '')
      str.gsub!(/\[FONT .*?\]|\[\/FONT\]/mi, '')
      str.gsub!(/\[[BUI]\]|\[\/[BUI]\]/mi, '')
    end
    str
  end

end

