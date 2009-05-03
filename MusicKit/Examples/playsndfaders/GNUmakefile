#
#   $Id$
#   Defined In: The MusicKit
#
#  Description:
#    Makefile for playsndfaders
#
#  Original Author: Leigh M. Smith
#
#  Permission is granted to use and modify this code for commercial and non-commercial
#  purposes so long as the author attribution and this copyright message remains intact
#  and accompanies all derived code.

include $(GNUSTEP_MAKEFILES)/common.make

# The tools to be compiled
TOOL_NAME = \
	playsndfaders

ADDITIONAL_TOOL_LIBS += -lSndKit

ifeq (mingw32, $(GNUSTEP_HOST_OS))
  CYG_DRIVE = $(shell cygpath -w '/' | tr '\\' '/' )
  ADDITIONAL_LIB_DIRS = -L$(CYG_DRIVE)/usr/local/lib
  ADDITIONAL_FLAGS += -I$(CYG_DRIVE)/usr/local/include
endif

# The Objective-C source files to be compiled
$(TOOL_NAME)_OBJC_FILES = main.m

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/tool.make

-include GNUmakefile.postamble
