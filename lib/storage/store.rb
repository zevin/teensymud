#
# file::    store.rb
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

# The minimal database will be used in the absence of detecting one.
MINIMAL_DB=<<EOH
---
- !ruby/object:World
  props:
    :owner: 0
    :id: 0
    :desc: "This is the World object."
    :name: World
    :msgs: {}
    :all_characters: []
    :all_accounts: []
    :builders: []
    :admins: []
    :timer_list: []
    :created_on: 2006-03-09 22:45:33.695862 -05:00
    :updated_on: 2006-03-09 22:45:33.695862 -05:00
- !ruby/object:Room
  props:
    :location:
    :owner: 0
    :id: 1
    :desc: "This is home."
    :contents: []
    :exits: []
    :triggers: {}
    :name: Home
    :created_on: 2006-03-09 22:45:33.695862 -05:00
    :updated_on: 2006-03-09 22:45:33.695862 -05:00
    :msgfail: ""
    :msgsucc: ""
EOH


# The Store class is an abstract class defining the methods
# needed to access a data store
#
class Store

  # Construct store
  #
  # [+return+] Handle to the store
  def initialize
    @dbtop = 0
  end

  # Close the store
  # [+return+] Undefined.
  def close
  end

  # inspect the store cache (only for caches)
  # [+return+] Undefined.
  def inspect
    ""
  end

  # Save or flush the store to disk
  # [+return+] Undefined.
  def save
  end

  # Fetch the next available id.
  # [+return+] An id.
  def getid
    @dbtop+=1
  end

  # Finds an object in the database by its id.
  # [+oid+] is the id to use in the search.
  # [+return+] Handle to the object or nil.
  def get(oid)
    nil
  end

  # Check if an object is in the database by its id.
  # [+oid+] is the id to use in the search.
  # [+return+] true or false
  def check(oid)
    false
  end

  # Marks an object dirty
  # [+oid+] is the id to use in the search.
  # [+return+] undefined
  def mark(oid)
  end

  # Adds a new object to the database.
  # [+obj+] is a reference to object to be added
  # [+return+] Undefined.
  def put(obj)
  end

  # Deletes an object from the database.
  # [+oid+] is the id to to be deleted.
  # [+return+] Undefined.
  def delete(oid)
  end

  # Iterate through all objects
  # [+yield+] Each object in database to block of caller.
  def each
  end

  # Marks an object nonswappable
  # [+oid+] is the object id
  # [+return+] undefined
  def makenoswap(oid)
  end

  # Marks an object swappable
  # [+oid+] is the object id
  # [+return+] undefined
  def makeswap(oid)
  end

  # produces a statistical report of the database
  # [+return+] a string containing the report
  def stats
    rooms = objs = scripts = characters = accounts = 0
    self.each do |val|
      case val
      when Room
        rooms += 1
      when Character
        characters += 1
      when GameObject
        objs += 1
      when Script
        scripts += 1
      when Account
        accounts += 1
      end
    end
    stats=<<EOD
[COLOR Cyan]
---* Database Statistics *---
  Rooms      - #{rooms}
  Objects    - #{objs}
  Scripts    - #{scripts}
  Accounts   - #{accounts}
  Characters - #{characters}
  Total Objects - #{rooms+objs+characters+accounts+scripts}
  Highest OID in use - #{@dbtop}
---*                     *---
[/COLOR]
EOD
  end

end
