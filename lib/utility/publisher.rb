#!/usr/bin/env ruby
#
# file::    publisher.rb
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

#
# Publisher is a variation on Ruby's Observable.  We do not keep track
# of any changed state; instead we assume that by virtue of calling publish
# we have changed state.  We do not allow serialization of subscribers.
# We allow a Publisher to have multiple publications and maintain separate
# lists of subscribers for each one.
#
module Publisher

  #
  # Add +subscriber+ as an subscriber on this object. +subscriber+ will now receive
  # notifications.
  #
  def subscribe(subscriber)
    @subscribers ||= []
    if !subscriber.respond_to?(:to_int) && !subscriber.respond_to?(:update)
      raise NoMethodError, "subscriber needs to respond to 'update'"
    end
    @subscribers.push subscriber
  end

  #
  # Delete +subscriber+ as a subscriber on this object. It will no longer receive
  # notifications.
  #
  def unsubscribe(subscriber)
    @subscribers.delete subscriber if defined? @subscribers
  end

  #
  # Delete all subscribers associated with this object.
  #
  def unsubscribe_all
    @subscribers.clear if defined? @subscribers
  end

  #
  # Count of subscribers to this object.
  #
  def subscriber_count
    @subscribers ? @subscribers.size : 0
  end

  #
  # If this object's changed state is +true+, invoke the update method in each
  # currently associated subscriber in turn, passing it the given arguments. The
  # changed state is then set to +false+.
  #
  def publish(*arg)
    if defined? @subscribers
      @subscribers.dup.each do |s|
        if s.respond_to?(:to_int)
          Engine.instance.db.get(s).update(*arg)
        else
          s.update(*arg)
        end
      end
    end
  end

end
