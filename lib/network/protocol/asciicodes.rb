#
# file::    asciicodes.rb
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

# This module contains the contants used for Telnet
module ASCIICodes

  NUL = 0x00  # NUL character
  SOH = 0x01  # Start of heading
  STX = 0x02  # Start of text
  ETX = 0x03  # End og text
  EOT = 0x04  # End of transmission
  ENQ = 0x05  # Enquiry
  ACK = 0x06  # Acknowledge
  BEL = 0x07  # Bell
  BS  = 0x08  # Backspace
  TAB = 0x09  # Horizontal tab
  HT  = 0x09  # Horizontal tab
  LF  = 0x0a  # Linefeed
  VT  = 0x0b  # Vertical tab
  FF  = 0x0c  # Form feed
  CR  = 0x0d  # Carriage return
  SO  = 0x0e  # Shift out
  SI  = 0x0f  # Shift in
  DLE = 0x10  # Data link escape
  DC1 = 0x11  # Device control 1
  DC2 = 0x12  # Device control 2
  DC3 = 0x13  # Device control 3
  DC4 = 0x14  # Device control 4
  NAK = 0x15  # negative acknowledgement
  SYN = 0x16  # Synchronous idle
  ETB = 0x17  # End of transmission block
  CAN = 0x18  # Cancel
  EM  = 0x19  # End of medium
  SUB = 0x1a  # Substitute
  ESC = 0x1b  # Escape
  FS  = 0x1c  # File separator
  GS  = 0x1d  # Group separator
  RS  = 0x1e  # Record separator
  US  = 0x1f  # Unit separator
  DEL = 0x7f  # Delete

end

