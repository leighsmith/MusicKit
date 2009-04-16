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

APP_NAME = EnvelopeEd

APPICON = EnvelopeEd.tiff

LANGUAGES = English

English_RESOURCES = EnvelopeEd.nib Info.nib

GLOBAL_RESOURCES = above.tiff above_alt.tiff below.tiff below_alt.tiff\
                   cross.tiff crossfill.tiff EnvelopeEd.tiff

EnvelopeEd_OBJC_FILES = EnvelopeEd_main.m Controller.m EnvelopeView.m

EnvelopeEd_HEADER_FILES = Controller.h EnvelopeView.h

EnvelopeEd_MAIN_MODEL_FILE = ScorePlayer
EnvelopeEd_RESOURCE_FILES = $(LANGUAGES).lproj


# This is now the ONLY lib you have to include when compiling a MusicKit program.
ADDITIONAL_TOOL_LIBS += -lMusicKit

ADDITIONAL_CFLAGS += -g
ADDITIONAL_LDFLAGS += -g

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/application.make

-include GNUmakefile.postamble
