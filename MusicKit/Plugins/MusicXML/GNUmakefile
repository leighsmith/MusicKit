#
#   $Id$
#   Defined In: The MusicKit
#
#  Description:
#    Makefile for GNUstep
#
#  Original Author: Stephen Brandon <stephen@brandonitconsulting.co.uk>
#
#  07 May 2002, Copyright (c) 2002 tomandandy inc.
#
#  Permission is granted to use and modify this code for commercial and non-
#  commercial purposes so long as the author attribution and this copyright
#  message remains intact and accompanies all derived code.

include $(GNUSTEP_MAKEFILES)/common.make


#
# Subprojects
#



#
# Main application
#

BUNDLE_NAME=MusicXML
BUNDLE_INSTALL_DIR=$(GNUSTEP_LOCAL_ROOT)/Library/MusicKitPlugins
BUNDLE_NAME = \
        MusicXML
BUNDLE_EXTENSION = .mkplugin


#
# Additional libraries
#

ADDITIONAL_GUI_LIBS += -lMKDSP -lMKPerformSndMIDI -lMusicKit -lSndKit -lvorbis -lvorbisenc -lvorbisfile 

#
# Resource files
#

MusicXML_RESOURCE_FILES= \
reve.xml \
reve-timewise.xml \
mut.xml 

#
# Header files
#

MusicXML_HEADERS= \
MKXMLAttributesParser.h \
MKXMLAttributeStack.h \
MKXMLClefParser.h \
MKXMLCounterAlterationParser.h \
MKXMLDirectionParser.h \
MKXMLEncodingParser.h \
MKXMLIdentificationParser.h \
MKXMLKeyParser.h \
MKXMLMeasureParser.h \
MKXMLMidiInstrumentParser.h \
MKXMLNoteParser.h \
MKXMLObjectContainerParser.h \
MKXMLParser.h \
MKXMLPartListParser.h \
MKXMLPartParser.h \
MKXMLPitchParser.h \
MKXMLSAXHandler.h \
MKXMLScoreInstrumentParser.h \
MKXMLScorePartParser.h \
MKXMLScorePartwiseParser.h \
MKXMLScoreTimewiseParser.h \
MKXMLSingleValueParser.h \
MKXMLSoundParser.h \
MKXMLTimeParser.h \
MKXMLWorkParser.h \
MusicXML.h

#
# Class files
#

MusicXML_OBJC_FILES= \
MKXMLAttributesParser.m \
MKXMLAttributeStack.m \
MKXMLClefParser.m \
MKXMLCounterAlterationParser.m \
MKXMLDirectionParser.m \
MKXMLEncodingParser.m \
MKXMLIdentificationParser.m \
MKXMLKeyParser.m \
MKXMLMeasureParser.m \
MKXMLMidiInstrumentParser.m \
MKXMLNoteParser.m \
MKXMLObjectContainerParser.m \
MKXMLParser.m \
MKXMLPartListParser.m \
MKXMLPartParser.m \
MKXMLPitchParser.m \
MKXMLSAXHandler.m \
MKXMLScoreInstrumentParser.m \
MKXMLScorePartParser.m \
MKXMLScorePartwiseParser.m \
MKXMLScoreTimewiseParser.m \
MKXMLSingleValueParser.m \
MKXMLSoundParser.m \
MKXMLTimeParser.m \
MKXMLWorkParser.m \
MusicXML.m

#
# C files
#

MusicXML_C_FILES= 

-include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
