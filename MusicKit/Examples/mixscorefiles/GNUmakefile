#
#   $Id$
#   Defined In: The MusicKit
#
#  Description:
#    Makefile for GNUstep
#
#  Original Author: Stephen Brandon <stephen@pyrusmalus.com>
#
#  12 October 2001, Copyright (c) 2001 Stephen Brandon.
#
#  Permission is granted to use and modify this code for commercial and non-commercial
#  purposes so long as the author attribution and this copyright message remains intact
#  and accompanies all derived code.

# Install into the local root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

include $(GNUSTEP_MAKEFILES)/common.make

# The tools to be compiled
TOOL_NAME = \
	mixscorefiles

ADDITIONAL_LIB_DIRS = 

ADDITIONAL_TOOL_LIBS += -lMKPerformSndMIDI -lSndKit -lgnustep-base -lgnustep-gui \
						-lMusicKit -lMKDSP -lst -g -ljpeg

ADDITIONAL_FLAGS += -g

# The Objective-C source files to be compiled
$(TOOL_NAME)_OBJC_FILES = mixscorefiles_main.m

SRCS = $(TEST_TOOL_NAME:=.m)

HDRS =

DIST_FILES = $(SRCS) $(HDRS)

-include Makefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/tool.make

-include Makefile.postamble
