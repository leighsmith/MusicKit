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

# Install into the local root by default
GNUSTEP_INSTALLATION_DOMAIN = LOCAL

include $(GNUSTEP_MAKEFILES)/common.make

# The tools to be compiled
TOOL_NAME = \
	sndinfo

ADDITIONAL_LIB_DIRS =

ADDITIONAL_TOOL_LIBS += -lSndKit

ADDITIONAL_FLAGS += -g -O2
ADDITIONAL_LDFLAGS += -g

ifeq (mingw32, $(GNUSTEP_HOST_OS))
  CYG_PATH = $(shell cygpath -w '/' | tr '\\' '/' )
  ADDITIONAL_FLAGS += -I$(CYG_PATH)/usr/local/include
  ADDITIONAL_LDFLAGS += -L$(CYG_PATH)/usr/local/lib
endif

# The Objective-C source files to be compiled
$(TOOL_NAME)_OBJC_FILES = main.m

SRCS = $(TEST_TOOL_NAME:=.m)

HDRS =

DIST_FILES = $(SRCS) $(HDRS)

-include Makefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/tool.make

-include Makefile.postamble
