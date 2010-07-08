#
#   $Id$
#   Defined In: The MusicKit
#
#  Description:
#    Makefile for GNUstep
#
#  Original Author: Stephen Brandon <stephen@brandonitconsulting.co.uk>
#
#  12 October 2001, Copyright (c) 2001 Stephen Brandon.
#
#  Permission is granted to use and modify this code for commercial and non-commercial
#  purposes so long as the author attribution and this copyright message remains intact
#  and accompanies all derived code.

include $(GNUSTEP_MAKEFILES)/common.make

# The tools to be compiled
TOOL_NAME = \
	recsnd

ADDITIONAL_LIB_DIRS =

ADDITIONAL_TOOL_LIBS += -lSndKit

ADDITIONAL_FLAGS += -g -O2
ADDITIONAL_LDFLAGS += -g

# The Objective-C source files to be compiled
$(TOOL_NAME)_OBJC_FILES = main.m

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/tool.make

-include GNUmakefile.postamble
