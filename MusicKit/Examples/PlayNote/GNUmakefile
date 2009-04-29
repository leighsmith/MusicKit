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

APP_NAME = PlayNote

$(APP_NAME)_MAIN_MODEL_FILE = PlayNote.nib

LANGUAGES = English

$(APP_NAME)_RESOURCE_FILES = $(LANGUAGES).lproj

# This is now the ONLY lib you have to include when compiling a MusicKit program.
ADDITIONAL_TOOL_LIBS += -lMusicKit

GLOBAL_RESOURCES = mkmon_A_32k.dsp mkmon_A_8k.dsp mkmon_A_192k.dsp\
                   mkmon_A_turtlebeachms.dsp mkmon_A_arielpc56d.dsp\
                   mkmon_A_ilinki56.dsp

$(APP_NAME)_OBJC_FILES = PlayNote_main.m ExampApp.m

$(APP_NAME)_HEADER_FILES = ExampApp.h

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/application.make

-include GNUmakefile.postamble



