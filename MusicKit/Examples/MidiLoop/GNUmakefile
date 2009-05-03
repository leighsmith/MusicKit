#
#   $Id: GNUmakefile 3459 2009-04-08 22:13:47Z leighsmith $
#   Defined In: The MusicKit
#
#  Description:
#    Makefile for GNUstep version of MidiLoop
#
#  Original Author: Leigh M. Smith
#
#  21 April 2009, Copyright (c) 2009 Leigh M. Smith
#
#  Permission is granted to use and modify this code for commercial and non-commercial
#  purposes so long as the author attribution and this copyright message remains intact
#  and accompanies all derived code.

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = MidiLoop

PACKAGE_NAME = MidiLoop

APPICON = MidiLoop.tiff

$(APP_NAME)_MAIN_MODEL_FILE = MidiLoop

LANGUAGES = English

$(APP_NAME)_RESOURCE_FILES = English.lproj

$(APP_NAME)_OBJC_FILES = MidiLoop_main.m MidiLoop.m

$(APP_NAME)_HEADER_FILES = MidiLoop.h

ADDITIONAL_TOOL_LIBS += -lMusicKit

-include GNUMakefile.preamble

include $(GNUSTEP_MAKEFILES)/application.make

-include GNUMakefile.postamble
