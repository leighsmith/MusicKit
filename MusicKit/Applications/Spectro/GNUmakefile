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

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = \
	Spectro	
ADDITIONAL_LIB_DIRS =

PACKAGE_NAME=Spectro

# This is now the ONLY lib you have to include when compiling
# a SndKit program. If you want to compile a MusicKit program,
# use -lMusicKit instead. It doesn't matter if you do both.

ADDITIONAL_TOOL_LIBS += -lSndKit

ADDITIONAL_CFLAGS += -g

ifeq (mingw32, $(GNUSTEP_HOST_OS))
  CYG_DRIVE = $(shell cygpath -w '/' | tr '\\' '/' )
  ADDITIONAL_LIB_DIRS = -L$(CYG_DRIVE)/usr/local/lib
  ADDITIONAL_FLAGS += -I$(CYG_DRIVE)/usr/local/include
endif

ADDITIONAL_FLAGS += -g
ADDITIONAL_LDFLAGS += -g

# The Objective-C source files to be compiled
Spectro_OBJC_FILES = Spectro_main.m \
	PrefController.m     SignalProcessor.m  WaterfallView.m \
	SaveToController.m   SoundController.m  SpectrumDocument.m \
	ScrollingSound.m     SoundDocument.m    SpectrumView.m \
	ScrollingSpectrum.m  SoundInfo.m        


SRCS = $(TEST_APP_NAME:=.m)

HDRS =

DIST_FILES = $(SRCS) $(HDRS)

Spectro_MAIN_MODEL_FILE = Spectro 
Spectro_RESOURCE_FILES = English.lproj


-include Makefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/application.make

-include Makefile.postamble
