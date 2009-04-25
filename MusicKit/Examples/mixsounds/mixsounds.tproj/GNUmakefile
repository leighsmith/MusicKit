#
#   $Id: GNUmakefile 3459 2009-04-08 22:13:47Z leighsmith $
#   Defined In: The MusicKit
#
#  Description:
#    Makefile for GNUstep version of mixsounds
#
#  Original Author: Leigh M. Smith
#
#  25 April 2009, Copyright (c) 2009 Leigh M. Smith
#
#  Permission is granted to use and modify this code for commercial and non-commercial
#  purposes so long as the author attribution and this copyright message remains intact
#  and accompanies all derived code.

include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = mixsounds

PROJECT_TYPE = Tool

$(TOOL_NAME)_OBJC_FILES = mixsounds_main.m

OTHERSRCS = README testMix.score testMix2.score\
            testMix3.score cm-part.lisp common-music-example.lisp

ADDITIONAL_TOOL_LIBS += -lMusicKit

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/tool.make

-include GNUmakefile.postamble

