#
# file::    vt100codes.rb
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
module VT100Codes

  CSI = "\e["

  SGR2CODE = { "0", "[RESET]", "1", "[B]", "2", "[D]", "4", "[U]",
               "5", "[BLINK]", "7", "[I]", "8", "[HIDDEN]",
               "30", "[COLOR Black]", "31", "[COLOR Red]",
               "32", "[COLOR Green]", "33", "[COLOR Yellow]",
               "34", "[COLOR Blue]",  "35", "[COLOR Magenta]",
               "36", "[COLOR Cyan]",  "37", "[COLOR White]",
               "40", "[COLOR=bgblack]", "41", "[COLOR=bgred]",
               "42", "[COLOR=bggreen]", "43", "[COLOR=bgyellow]",
               "44", "[COLOR=bgblue]",  "45", "[COLOR=bgmagenta]",
               "46", "[COLOR=bgcyan]",  "47", "[COLOR=bgwhite]" }


  VTKeys = { /\[SCROLLDOWN\]/mi, "\eD",
             /\[SCROLLUP\]/mi, "\eM",
             /\[UP (\d+)?\]/mi, "\e$A", /\[DOWN (\d+)?\]/mi, "\e$B",
             /\[RIGHT (\d+)?\]/mi, "\e$C", /\[LEFT (\d+)?\]/mi, "\e$D",
             /\[CURSAVE\]/mi, "\e7", /\[CURREST\]/mi, "\e8",
             /\[RESET\]/mi, "\ec",
             /\[TAB\]/mi, "\t", /\[BELL\]/mi, "\a", /\[BS\]/mi, "\b",
             /\[POS (\d+)\]/mi, CSI+"$G",
             /\[HOME (\d+)?,(\d+)?\]/mi, CSI+"$;$H",
             /\[CURSOR (\d+)?,(\d+)?\]/mi, CSI+"$;$R",
             /\[SCRREG (\d+)?,(\d+)?\]/mi, CSI+"$;$r",
             /\[SCRRESET\]/mi, CSI+"r",
             /\[CLEAR\]/mi, CSI+"2J", /\[CURREPT\]/mi, CSI+"6n",
             /\[CLEARLINE\]/mi, CSI+"2K",
             /\[INSERT\]/mi, CSI+"2~", /\[END\]/mi, CSI+"8~",
             /\[PAGEUP\]/mi, CSI+"5~", /\[PAGEDOWN\]/mi, CSI+"6~",
             /\[F1\]/mi, CSI+"11~", /\[F2\]/mi, CSI+"12~",
             /\[F3\]/mi, CSI+"13~", /\[F4\]/mi, CSI+"14~",
             /\[F5\]/mi, CSI+"15~", /\[F6\]/mi, CSI+"17~",
             /\[F7\]/mi, CSI+"18~", /\[F8\]/mi, CSI+"19~",
             /\[F9\]/mi, CSI+"20~", /\[F10\]/mi, CSI+"21~" }

end