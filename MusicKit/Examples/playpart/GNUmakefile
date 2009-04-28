#
#   $Id: GNUmakefile 3459 2009-04-08 22:13:47Z leighsmith $
#   Defined In: The MusicKit
#
#  Description:
#    Makefile for GNUstep version of playpart
#
#  Original Author: Leigh M. Smith
#
#  25 April 2009, Copyright (c) 2009 Leigh M. Smith
#
#  Permission is granted to use and modify this code for commercial and non-commercial
#  purposes so long as the author attribution and this copyright message remains intact
#  and accompanies all derived code.

include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = playpart

$(TOOL_NAME)_OBJC_FILES = playpart_main.m playpart.m

ADDITIONAL_TOOL_LIBS += -lMusicKit

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/tool.make

-include GNUmakefile.postamble
