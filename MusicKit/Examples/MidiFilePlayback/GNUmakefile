#
#   $Id$
#   Defined In: The MusicKit
#
#  Description:
#    Makefile for GNUstep version of MidiFilePlayback
#
#  Original Author: Leigh M. Smith
#
#  21 April 2009, Copyright (c) 2009 Leigh M. Smith
#
#  Permission is granted to use and modify this code for commercial and non-commercial
#  purposes so long as the author attribution and this copyright message remains intact
#  and accompanies all derived code.

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = MidiFilePlayback

PACKAGE_NAME = MidiFilePlayback

APPICON = midi.tiff

LANGUAGES = English

$(APP_NAME)_RESOURCE_FILES = $(LANGUAGES).lproj

GLOBAL_RESOURCES = midi.tiff

$(APP_NAME)_HEADER_FILES = MIDIFileController.h

$(APP_NAME)_OBJC_FILES = MIDIFilePlayback_main.m MIDIFileController.m

FRAMEWORK_PATHS = -F/Local/Library/Frameworks\
                  -F/System/Library/PrivateFrameworks\
                  -F$(LOCAL_DEVELOPER_DIR)/Frameworks
FRAMEWORKS = -framework AppKit -framework Foundation\
             -framework MKPerformSndMIDI -framework MusicKit



ADDITIONAL_TOOL_LIBS += -lMusicKit

-include GNUMakefile.preamble

include $(GNUSTEP_MAKEFILES)/application.make

-include GNUMakefile.postamble
