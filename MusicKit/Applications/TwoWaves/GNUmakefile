#
#   $Id$
#   Defined In: The MusicKit
#
#  Description:
#    Makefile for GNUstep
#
#  Original Author: Leigh M. Smith
#
#  12 October 2001, Copyright (c) 2003 Leigh M. Smith
#
#  Permission is granted to use and modify this code for commercial and non-commercial
#  purposes so long as the author attribution and this copyright message remains intact
#  and accompanies all derived code.

# Install into the local root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = \
	TwoWaves	
ADDITIONAL_LIB_DIRS =

PACKAGE_NAME=TwoWaves

# This is now the ONLY lib you have to include when compiling
# a SndKit program. If you want to compile a MusicKit program,
# use -lMusicKit instead. It doesn't matter if you do both.

ADDITIONAL_TOOL_LIBS += -lSndKit

ADDITIONAL_CFLAGS += -g

ifeq (mingw32, $(GNUSTEP_HOST_OS))
  ADDITIONAL_LIB_DIRS = -L/usr/local/lib
  ADDITIONAL_FLAGS += -I/usr/local/include
endif

ADDITIONAL_FLAGS += -g
ADDITIONAL_LDFLAGS += -g

# The Objective-C source files to be compiled
TwoWaves_OBJC_FILES = TwoWaves_main.m \
	Controller.m

SRCS = $(TEST_APP_NAME:=.m)

HDRS = Controller.h

DIST_FILES = $(SRCS) $(HDRS)

TwoWaves_MAIN_MODEL_FILE = TwoWaves
TwoWaves_RESOURCE_FILES = English.lproj


-include Makefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/application.make

-include Makefile.postamble
