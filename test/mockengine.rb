#
# file::    mockengine.rb
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

# A mockengine spoofs the behavior of a Engine for testing purposes
#


class Engine
  @@mock = FlexMock.new
  $db = @@mock
  @@mock.mock_handle(:db) {$db}
  @@mock.mock_handle(:getid) {$id += 1}
  @@mock.mock_handle(:mark) {}
#  @@mock.mock_handle(:get) {|oid| oid == 0 ? 1 : 2}
  @@mock.mock_handle(:get) do |oid|
    case oid
    when 0 then @@mock
    when 1 then $r
    when 2 then $p
    when 3 then $o
    when 99 then 2
    end
  end
  @@mock.mock_handle(:put) {true}
  @@mock.mock_handle(:delete) {true}
  @@mock.mock_handle(:eventmgr) {@@mock}
  @@mock.mock_handle(:add_event) {true}
  @@mock.mock_handle(:ocmds) {@@mock}
  @@mock.mock_handle(:cmds) {@@mock}
  @@mock.mock_handle(:find) {[]}
  def self.instance
    @@mock
  end
end
