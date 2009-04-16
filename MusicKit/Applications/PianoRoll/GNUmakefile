#
#   $Id$
#   Defined In: The MusicKit
#
#  Description:
#    Makefile for GNUstep
#
#  Original Author: Leigh M. Smith <leigh@leighsmith.com>
#
#  Copyright (c) 2009 Leigh M. Smith
#
#  Permission is granted to use and modify this code for commercial and non-commercial
#  purposes so long as the author attribution and this copyright message remains intact
#  and accompanies all derived code.

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = PianoRoll

# This is now the ONLY lib you have to include when compiling a MusicKit program.
ADDITIONAL_TOOL_LIBS += -lMusicKit

ADDITIONAL_CFLAGS += -g
ADDITIONAL_LDFLAGS += -g

APPICON = PianoRoll.tiff

LANGUAGES = English

PianoRoll_MAIN_MODEL_FILE = PianoRoll

PianoRoll_RESOURCE_FILES = $(LANGUAGES).lproj

PianoRoll_GLOBAL_RESOURCES = PianoRoll.tiff

PianoRoll_OBJC_FILES = PianoRoll_main.m Distributor.m Document.m PartView.m PlayScore.m TadPole.m

PianoRoll_HEADER_FILES = Distributor.h Document.h PartView.h PlayScore.h TadPole.h


-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/application.make

-include GNUmakefile.postamble
