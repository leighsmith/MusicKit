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
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

include $(GNUSTEP_MAKEFILES)/common.make

# The tools to be compiled
TOOL_NAME = \
	playsnd

ADDITIONAL_LIB_DIRS =

ADDITIONAL_TOOL_LIBS += -lMKPerformSndMIDI -lSndKit -lgnustep-base -lst
 
ADDITIONAL_CFLAGS += -g
 
playsnd_LIBRARIES_DEPEND_UPON += -lSndKit -lgnustep-base -lst -lobjc
 
ifneq (mingw32, $(GNUSTEP_HOST_OS))
  ADDITIONAL_TOOL_LIBS += -lgnustep-gui -lmp3lame -lshout
  playsnd_LIBRARIES_DEPEND_UPON +=  -lgnustep-gui
else
  ADDITIONAL_LIB_DIRS = -Ld:/cygwin/usr/local/lib
  ADDITIONAL_FLAGS += -Id:/cygwin/usr/local/include
  playsndfaders_LIBRARIES_DEPEND_UPON += -Ld:/cygwin/usr/local/lib
endif

ADDITIONAL_FLAGS += -g
ADDITIONAL_LDFLAGS += -g

# The Objective-C source files to be compiled
$(TOOL_NAME)_OBJC_FILES = main.m

SRCS = $(TEST_TOOL_NAME:=.m)

HDRS =

DIST_FILES = $(SRCS) $(HDRS)

-include Makefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/tool.make

-include Makefile.postamble
