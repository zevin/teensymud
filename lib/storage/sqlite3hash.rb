#
# file::    sqlite3hash.rb
# author::  Jon A. Lambert
# version:: 2.9.0
# date::    03/16/2006
#
# This source code copyright (C) 2005, 2006 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#

# Override class with our hash methods
module SQLite3
  class Database
    def [](idx)
      result = execute("select data from tmud where id = ?;", idx.to_i)
      result.first.first ? result.first.first : nil
    end
    def []=(idx, data)
      result = execute("insert into tmud values (?, ?);", idx.to_i, data)
    rescue Exception
      result = execute("update tmud set data = ? where id = ?;", data, idx.to_i)
    ensure
      data
    end
    def has_key?(idx)
      result = execute("select data from tmud where id = ?;", idx.to_i)
      result.first.first ? true : false
    end
    def delete(idx)
      result = execute("delete from tmud where id = ?;", idx.to_i)
    rescue Exception
    end
  end
end

