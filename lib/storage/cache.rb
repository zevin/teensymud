#
# file::    cache.rb
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

require 'utility/configuration'
require 'utility/log'
require 'utility/utility'

# The object cache is limited in size since the purpose is to control the
# number of objects present in storage and provide a reasonably efficient
# means of looking them up. I don't use the Ruby hash implementation since
# we do want key collisions.  Its purpose is to avoid collisions.  Instead
# I implement hash table with single link list chaining using a Ruby array
# of arrays, a Ruby array being the closet equivalent to a link list.
#
# The first dimension is fixed as the cache_width and keys are hashed by
# key modulus cache_width. The second dimension, the cache_depth is the
# limit on how big the second array can grow.
#
# Everytime an object is not found in the cache, we pop an entry from
# then end of the cache list chain, save it if dirty, copy our new
# object into it, and place it at the head of the list chain.


# This class stores the cache statistics.
class CacheStats
  def initialize
    @stats = {}
  end

  def inc(k)
    @stats[k] ||= 0
    @stats[k] += 1
  end

  def each(&blk)
    @stats.each &blk
  end

end

# This is a node in the cache and is a wrapper for the object and keeps
# flags on the status of the entry.
class CacheEntry
  attr_accessor :oid, :obj

  # perhaps add LRU counters as CacheEntry is pretty dumb
  def initialize(oid=nil,obj=nil,dirty=false,noswap=false)
    @oid, @obj, @dirty, @noswap = oid, obj, dirty, noswap
  end

  # dirty cache entries are those that probably differ from the database
  def dirty?
    @dirty
  end

  def dirty!
    @dirty = true
  end

  def clean!
    @dirty = false
  end

  # A dead cache entry is an object that has been deleted
  def dead?
    @obj == nil
  end

  def mark_dead
    @obj = nil
    @oid = nil
    @dirty = false
    @noswap = false
  end

  # Noswappable cache entries are objects that have non persistent
  # attributes.  *heavy sigh*
  # We can never remove these from the cache until specifically marked
  # See makenoswap and makeswap
  def noswap?
    @noswap
  end

  def noswap!
    @noswap = true
  end

  def swap!
    @noswap = false
  end

end

# This class manages the cache.  It is initialized by the Store and front ends
# the database behind the Store.
class CacheManager
  configuration
  logger

  def initialize(db)
    @cwidth = options['cache_width']
    @cdepth = options['cache_depth']

    @db =  db
    @st = CacheStats.new

    @cache = Array.new(@cwidth) {Array.new}
    @cwidth.times do |i|
      @cdepth.times do |j|
        @cache[i] << CacheEntry.new
        @st.inc(:cache_size)
      end
    end

  end

  # report on the cache map  see cmd_dumpcache
  def inspect
    str = "cache width:#{@cwidth} cache depth:#{@cdepth}\n"
    @cwidth.times do |i|
      @cache[i].each_with_index do |ce,j|
        next if ce.dead?
        str << "cache map [#{i}][#{j}] => "
        str << "oid #{ce.oid} object_id #{ce.obj.object_id} dirty? #{ce.dirty?}  noswap? #{ce.noswap?}\n"
      end
    end
    str
  end

  # Our simple hash algoritm.  Our database keys are sequentially
  # assigned integers, so... I don't know what would be better.
  def hash(oid)
    oid % @cwidth
  end

  # gets an object
  # [+oid+] - integer object id to retrieve
  # [+return+] - a reference to the object or nil if none exists
  def get(oid)
    return nil if oid.nil?
    @st.inc(:reads)
    hv = hash(oid)

    # search the cache
    @cache[hv].each do |ce|
      if ce.oid == oid
        @st.inc(:cache_read_hits)
        # need to try putting hot hit to the head of the list?
        return ce.obj
      end
    end

    # cache miss - search the database
    if @db.has_key? oid.to_s
      ret = Utility.decode(@db[oid.to_s])
    else
      @st.inc(:database_read_fails)
      return nil
    end
    @st.inc(:database_reads)

    # get and remove the last entry off this list
    ch = @cache[hv].pop
    # if its dirty we write it to the database
    if ch.dirty? && !ch.dead?
      @db[ch.oid.to_s] = Utility.encode(ch.obj)
      @st.inc(:database_writes)
      if ch.noswap?  # here we have a problem we can't use this
        # first push it back onto the list
        @cache[hv].unshift ch
        # get ourselves a brand new
        ch = CacheEntry.new
        # problem solved
        # the depth of any list chains will be cache_depth + # noswap entries
      end
    end

    # assign our new object to the cache entry
    ch.obj = ret
    ch.oid = oid
    ch.clean!
    # push it to the head of the list
    @cache[hv].unshift ch

    ret
  end

  # puts an object
  # [+obj+] - The integer object id to retrieve
  # [+return+] - undefined
  def put(obj)
    return nil if obj.nil?
    @st.inc(:writes)
    hv = hash(obj.id)

    # search the cache
    @cache[hv].each do |ce|
      next if ce.oid != obj.id
      @st.inc(:cache_write_hits) if ce.dirty?
      if obj.object_id != ce.obj.object_id  # be safe
        # Be extra careful here.  It's possible we could have two objects
        # with the same object id but with different Ruby object_ids.
        # Most likely this is a bug, but we should handle it here..
        ce.obj = obj
        log.warn "Duplicate object id's in cache!"
        log.warn "insert - #{obj.inspect}"
        log.warn "cache - #{obj.inspect}"
      end
      # need to try putting hot hit to the head of the list?
      ce.dirty!
      return
    end

    # get and remove the last entry off this list
    ch = @cache[hv].pop
    # if its dirty we write it to the database
    if ch.dirty? && !ch.dead?
      # errors possible - check in store module
      @db[ch.oid.to_s] = Utility.encode(ch.obj)
      @st.inc(:database_writes)
      if ch.noswap?  # here we have a problem we can't use this
        # first push it back onto the list
        @cache[hv].unshift ch
        # get ourselves a brand new
        ch = CacheEntry.new
        # problem solved
        # the depth of any list chains will be cache_depth + # noswap entries
      end
    end

    # assign our new object to the cache entry
    ch.obj = obj
    ch.oid = obj.id
    ch.dirty!
    # push it to the head of the list
    @cache[hv].unshift ch

    return
  end

  # delete an object
  def delete(oid)
    return nil if oid.nil?
    @st.inc(:deletes)
    hv = hash(oid)

    # mark dead in cache
    @cache[hv].each do |ce|
      next if ce.oid != oid
      ce.mark_dead
      break
    end
    # delete it from the database
    @db.delete(oid.to_s)
  end

  # deliberately mark an object in the cache as dirty
  # see properties.
  def mark(oid)
    return nil if oid.nil?
    @st.inc(:cache_marks)
    hv = hash(oid)

    @cache[hv].each do |ce|
      next if ce.oid != oid
      ce.dirty!
      return
    end

    # this would indicate we've tried marking it dirty before we did a put.
    @st.inc(:cache_mark_misses)
    log.debug "Marking object dirty before put - #{oid}"
  end

  # syncronize the entire cache with the database
  # called by save.
  def sync
    @st.inc(:cache_syncs)
    # search the list chains for dirty objects and write them out.
    @cwidth.times do |i|
      @cache[i].each do |ce|
        if ce.dirty?
          @db[ce.oid.to_s] = Utility.encode(ce.obj)
          @st.inc(:database_writes)
          ce.clean!
        end
      end
    end
  end

  # syncronize a specific list chain
  # not yet called but included for possible performance enhancement
  def sync_chain(i)
    @st.inc(:chain_syncs)
    @cache[i].each do |ce|
      if ce.dirty?
        @db[ce.oid.to_s] = Utility.encode(ce.obj)
        @st.inc(:database_writes)
        ce.clean!
      end
    end
  end

  # Mark an object in the cache as nonswappable
  # [+oid+] is the object id
  # [+return+] undefined
  def makenoswap(oid)
    return nil if oid.nil?
    @st.inc(:cache_noswap)
    hv = hash(oid)

    @cache[hv].each do |ce|
      next if ce.oid != oid
      ce.noswap!
      return
    end

    # This would indicate we've tried marking it noswap before we did a put.
    # A logic error
    @st.inc(:cache_noswap_misses)
    log.debug "Marking object nonswappable before put - #{oid}"
  end

  # Mark an object in the cache as swappable
  # [+oid+] is the object id
  # [+return+] undefined
  def makeswap(oid)
    return nil if oid.nil?
    @st.inc(:cache_swap)
    hv = hash(oid)

    @cache[hv].each do |ce|
      next if ce.oid != oid
      ce.swap!
      return
    end

    # This would indicate we've tried marking it swap before we did a put.
    # A logic error
    @st.inc(:cache_swap_misses)
    log.debug "Marking object swappable before put - #{oid}"
  end

  # This is provided to traverse the entire object chain.
  # This thrashes the cache violently.  See Store#each.
  # One needs to question the design of routines that use Store#each above.
  def keys
    kys = []
    @cwidth.times do |i|
      @cache[i].each {|ce| kys << ce.oid if !ce.oid.nil? }
    end
    kys
  end

  # produce a report - see cmd_stats
  def stats
    str =  "----------* Cache Statistics *----------\n"
    @st.each do |k,v|
      str << sprintf("%25-25s : %d\n",k.to_s.gsub(/_/,' '),v)
    end
    str << "----------*                  *----------\n"
  end

end
