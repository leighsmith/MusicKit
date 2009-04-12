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

APP_NAME = ScorePlayer

# This is now the ONLY lib you have to include when compiling a MusicKit program.
ADDITIONAL_TOOL_LIBS += -lMusicKit

ADDITIONAL_CFLAGS += -g
ADDITIONAL_LDFLAGS += -g

APPICON = ScorePlayerApp.tiff
DOCICONS = ScorePlayerDoc.tiff ScorePlayerDoc2.tiff

# The Objective-C source files to be compiled
ScorePlayer_OBJC_FILES = ScorePlayer_main.m Animator.m ErrorLog.m MKAlert.m ScorePlayerController.m

LANGUAGES = English

GLOBAL_RESOURCES = Midi.tiff play.tiff playH.tiff Sound.tiff stop.tiff \
                   ScorePlayerDoc.tiff ScorePlayerDoc2.tiff \
                   ScorePlayerApp.tiff help.rtfd ScorePlayer.strings

ScorePlayer_HEADER_FILES = Animator.h ErrorLog.h MKAlert.h ScorePlayerController.h

ScorePlayer_MAIN_MODEL_FILE = ScorePlayer
ScorePlayer_RESOURCE_FILES = $(LANGUAGES).lproj

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/application.make

-include GNUmakefile.postamble
