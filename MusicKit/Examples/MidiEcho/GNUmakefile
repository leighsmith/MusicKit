#
#   $Id: GNUmakefile 3459 2009-04-08 22:13:47Z leighsmith $
#   Defined In: The MusicKit
#
#  Description:
#    Makefile for GNUstep version of MidiEcho
#
#  Original Author: Leigh M. Smith
#
#  21 April 2009, Copyright (c) 2009 Leigh M. Smith
#
#  Permission is granted to use and modify this code for commercial and non-commercial
#  purposes so long as the author attribution and this copyright message remains intact
#  and accompanies all derived code.

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = MidiEcho

PACKAGE_NAME = MidiEcho

APPICON = MidiEcho.tiff

MidiEcho_MAIN_MODEL_FILE = MidiEcho

LANGUAGES = English

MidiEcho_RESOURCE_FILES = English.lproj

MidiEcho_OBJC_FILES = MidiEcho_main.m EchoFilter.m MidiEcho.m

MidiEcho_HEADER_FILES = EchoFilter.h MidiEcho.h

ADDITIONAL_TOOL_LIBS += -lMusicKit

-include GNUMakefile.preamble

include $(GNUSTEP_MAKEFILES)/application.make

-include GNUMakefile.postamble

