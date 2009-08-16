#
#   $Id: GNUmakefile 3459 2009-04-08 22:13:47Z leighsmith $
#   Defined In: The MusicKit
#
#  Description:
#    Makefile for GNUstep version of MidiPlay
#
#  Original Author: Leigh M. Smith
#
#  25 April 2009, Copyright (c) 2009 Leigh M. Smith
#
#  Permission is granted to use and modify this code for commercial and non-commercial
#  purposes so long as the author attribution and this copyright message remains intact
#  and accompanies all derived code.

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = MidiPlay

PACKAGE_NAME = MidiPlay

MidiPlay_MAIN_MODEL_FILE = MidiPlay

LANGUAGES = English

MidiPlay_OBJC_FILES = MidiPlay_main.m MidiFilter.m MidiPlayController.m

MidiPlay_HEADER_FILES = MidiFilter.h MidiPlayController.h

ADDITIONAL_TOOL_LIBS += -lMusicKit

-include GNUMakefile.preamble

include $(GNUSTEP_MAKEFILES)/application.make

-include GNUMakefile.postamble


