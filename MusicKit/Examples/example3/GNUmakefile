#
#   $Id$
#   Defined In: The MusicKit
#
#  Description:
#    GNUstep Makefile for example3
#
#  Original Author: Leigh M. Smith
#
#  Permission is granted to use and modify this code for commercial and non-commercial
#  purposes so long as the author attribution and this copyright message remains intact
#  and accompanies all derived code.
#

APP_NAME = example3

PACKAGE_NAME = example3

LANGUAGES = English

$(APP_NAME)_RESOURCE_FILES = $(LANGUAGES).lproj

$(APP_NAME)_OBJC_FILES = example3_main.m MyObject.m

$(APP_NAME)_HEADER_FILES = MyObject.h

ADDITIONAL_TOOL_LIBS += -lMusicKit

-include GNUMakefile.preamble

include $(GNUSTEP_MAKEFILES)/application.make

-include GNUMakefile.postamble
