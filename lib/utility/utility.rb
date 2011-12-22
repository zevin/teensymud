#
# file::    utility.rb
# author::  Jon A. Lambert
# version:: 2.9.0
# date::    03/12/2006
#
# This source code copyright (C) 2005, 2006 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
require 'base64'

class String

  # Checks if 'str' is a prefix of this string
  def is_prefix? str
    return false if self.empty? || str.nil? || str.empty?
    self.downcase == str.slice(0...self.size).downcase
  end

  # Takes a string containing a list of keywords, like 'hello world',
  # and checks if 'str' is a prefix of any of those words?
  # "hell" would be true
  def is_match? str
    return false if self.empty? || str.nil? || str.empty?
    lst = self.split(' ')
    lst.each do |s|
      return true if str.downcase == s.slice(0...str.size).downcase
    end
    false
  end

  # Compares the password with the string
  # [+pwd+] The encrypted password
  # [+return+] true if they are equal, false if not
  def is_passwd?(pwd)
    pwd == self.crypt(pwd)
  end

  # Encrypts a password
  # [+return+] The encrypted string
  def encrypt
    alphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789./'
    salt = "#{alphabet[rand(64)].chr}#{alphabet[rand(64)].chr}"
    self.crypt(salt)
  end

  # Make string into proper name
  # removes digits, downcases and then capitalizes words.
  # Sorry it doesn't like McManus but likes O'Mally
  def proper_name
    str = self.dup
    str.gsub!(/\d+/,'')
    str.gsub!(/\w+/) {|m|  m.downcase!; m[0] = m[0].chr.upcase; m}
    str
  end

end

module Utility

  def self.decode(str)
    Marshal.load(Base64.decode64(str))
  end

  def self.encode(obj)
    Base64.encode64(Marshal.dump(obj)).strip
  end

end

