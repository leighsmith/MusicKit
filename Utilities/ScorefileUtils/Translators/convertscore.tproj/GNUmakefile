#
#   $Id$
#   Defined In: The MusicKit
#
#  Description:
#    Makefile for GNUstep version of convertscore
#
#  Original Author: Leigh M. Smith
#
#  25 April 2009, Copyright (c) 2009 Leigh M. Smith
#
#  Permission is granted to use and modify this code for commercial and non-commercial
#  purposes so long as the author attribution and this copyright message remains intact
#  and accompanies all derived code.

include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = convertscore
DOCUMENT_TEXT_NAME = convertscore

$(DOCUMENT_TEXT_NAME)_INSTALL_FILES = convertscore.1

$(TOOL_NAME)_OBJC_FILES = convertscore_main.m

#
# Libraries used by this command line tool.
#
ADDITIONAL_TOOL_LIBS += -lMusicKit

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/tool.make
# include $(GNUSTEP_MAKEFILES)/documentation.make

-include GNUmakefile.postamble
