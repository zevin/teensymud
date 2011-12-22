#
# file::    farts_lib.rb
# author::  Jon A. Lambert
# version:: 2.4.0
# date::    09/11/2005
#
# This source code copyright (C) 2005 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#

module Farts

# The Lib class implements all the functions available to Farts programs.
#
class Lib

  # Is random percentage less than or equal to num
  def rand(num)
    Kernel::rand(100) < num
  end

  # Is actor a Character
  def ischaracter(actor)
    actor.class == Character
  end

  # Is actor a Critter
  def iscritter(actor)
    false
  end

  # Is actor a Room
  def isroom(actor)
    actor.class == Room
  end

  # Get the level of actor
  def level(actor)
    99
  end

  # Get the sex of actor
  def sex(actor)
    :male
  end

end

end # module
