#
#   $Id$
#   Defined In: The MusicKit
#
#  Description:
#    Makefile for example1
#
#  Original Author: Leigh M. Smith
#
#  Permission is granted to use and modify this code for commercial and non-commercial
#  purposes so long as the author attribution and this copyright message remains intact
#  and accompanies all derived code.

# Install into the system root by default
GNUSTEP_INSTALLATION_DOMAIN = LOCAL

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

include $(GNUSTEP_MAKEFILES)/common.make

# The tools to be compiled
TOOL_NAME = \
	example1

ADDITIONAL_LIB_DIRS =  

ADDITIONAL_TOOL_LIBS += -lMKDSP -lMKPerformSndMIDI -lSndKit -lgnustep-base -lMusicKit

ADDITIONAL_FLAGS += -g

# The Objective-C source files to be compiled
example1_OBJC_FILES = example1.m

SRCS = $(TEST_TOOL_NAME:=.m)

HDRS =

DIST_FILES = $(SRCS) $(HDRS)

-include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/tool.make

-include Makefile.postamble
