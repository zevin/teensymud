#
# file::    ternarytrie.rb
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


# class TernaryTrie implements a ternary search trie.  The keys are
# are assumed to be strings, but the values can be any object.
# This is a very lightweight and useful object
class TernaryTrie

public
  # constructor simply ensures we have a root
  def initialize
    @root = nil
  end

  # Inserts a key/val pair - no duplicate keys (will replace key if found).
  # [+key+]   A string
  # [+value+] A value which ay be any object.
  def insert(key, val)
    @root = insert_r(@root, key, val, 0)
  end

  # Returns an exact match only of the key or nil if not found
  # [+key+]    A string
  # [+return+] A values or nil if nothing found
  def find_exact(key)
    return nil if !key.respond_to? :to_str
    key = key.to_str
    return find_exact_r(@root, key, 0)
  end

  # Returns array of values that are the shortest possible match of the
  # key.
  # [+key+]    A string
  # [+return+] An array of values or nil if nothing found
  def find(key)
    return [] if !key.respond_to? :to_str
    key = key.to_str
    match = []
    find_r(@root, key, match, 0)
    match
  end

  # Routine which converts the trie into a hash table
  # [+return+] hash table of key/value pairs
  def to_hash
    key = " " * 64  # max key length - raise if keys are enormeous
    hash = {}
    to_hash_r(@root, key, hash, 0)
    hash
  end

private
  # The trie node - not for public consumption
  class TNode
    attr_accessor :val, :keyc, :l, :m, :r
    def initialize(kc)
      @keyc = kc
    end
  end

  # recursive trie traversal routines follow
  def insert_r(node, key, val, idx)
    node = TNode.new(key[idx]) if node == nil
    if idx == key.size - 1 && key[idx] == node.keyc
      node.val = val
      return node
    end
    node.l = insert_r(node.l, key, val, idx) if key[idx] && key[idx] < node.keyc
    node.m = insert_r(node.m, key, val, idx+1) if key[idx] && key[idx] == node.keyc
    node.r = insert_r(node.r, key, val, idx) if key[idx] && key[idx] > node.keyc
    return node
  end

  def find_exact_r(node, key, idx)
    return nil if node == nil
    if idx == key.size - 1 && key[idx] == node.keyc
      return node.val if node.val
      return nil
    end
    return find_exact_r(node.l, key, idx) if key[idx] < node.keyc
    return find_exact_r(node.m, key, idx+1) if key[idx] == node.keyc
    return find_exact_r(node.r, key, idx) if key[idx] > node.keyc
  end

  def find_rest_r(node, match)
    return if node == nil
    if node.val
      match << node.val
    end
    find_rest_r(node.l, match)
    find_rest_r(node.m, match)
    find_rest_r(node.r, match)
  end

  def find_r(node, key, match, idx)
    return if node == nil
    if idx == key.size - 1 && key[idx] == node.keyc
      if node.val
        match << node.val
      end
      find_rest_r(node.m, match)
      return
    end
    return find_r(node.l, key, match, idx) if key[idx] && key[idx] < node.keyc
    return find_r(node.m, key, match, idx+1) if key[idx] && key[idx] == node.keyc
    return find_r(node.r, key, match, idx) if key[idx] && key[idx] > node.keyc
  end

  def to_hash_r(node, key, hash, idx)
    return if node == nil
    key[idx] = node.keyc
    hash[key.strip] = node.val if node.val
    to_hash_r(node.m, key, hash, idx+1)
    to_hash_r(node.l, key, hash, idx)
    to_hash_r(node.r, key, hash, idx)
  end
end

