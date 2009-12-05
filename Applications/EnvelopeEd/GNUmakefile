#
#   $Id$
#   Defined In: The MusicKit
#
#  Description:
#    Makefile for GNUstep version of EnvelopeEd
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

GLOBAL_RESOURCES = above.tiff above_alt.tiff below.tiff below_alt.tiff\
                   cross.tiff crossfill.tiff EnvelopeEd.tiff

$(APP_NAME)_OBJC_FILES = EnvelopeEd_main.m Controller.m EnvelopeView.m

$(APP_NAME)_HEADER_FILES = Controller.h EnvelopeView.h

$(APP_NAME)_MAIN_MODEL_FILE = EnvelopeEd

$(APP_NAME)_RESOURCE_FILES = $(LANGUAGES).lproj

# This is now the ONLY lib you have to include when compiling a MusicKit program.
ADDITIONAL_TOOL_LIBS += -lMusicKit

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/application.make

-include GNUmakefile.postamble
