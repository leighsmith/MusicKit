#
#   $Id$
#   Defined In: The MusicKit
#
#  Description:
#    Makefile for GNUstep
#
#  Original Author: Stephen Brandon <stephen@pyrusmalus.com>
#
#  21 April 2001, Copyright (c) 2001 Stephen Brandon.
#
#  Permission is granted to use and modify this code for commercial and non-commercial
#  purposes so long as the author attribution and this copyright message remains intact
#  and accompanies all derived code.

#Modification history:
# $Log$
# Revision 1.2  2001/07/02 20:03:29  sbrandon
# - added -g flag for debugging
#
# Revision 1.1  2001/05/12 16:59:25  sbrandon
# - inclusion of GNUmakefile should allow the use of "make" on GNUstep platforms
#   (certainly does for me!)
#
#

# Install into the local root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

include $(GNUSTEP_MAKEFILES)/common.make

srcdir = .

# The framework to be compiled
FRAMEWORK_NAME = SndKit

# The framework resource files and directories
$(FRAMEWORK_NAME)_RESOURCE_FILES = 

$(FRAMEWORK_NAME)_RESOURCE_DIRS = 

# The framework libraries to link against
#sb: not sure about this...
#$(FRAMEWORK_NAME)BUNDLE_LIBS = 

ADDITIONAL_FLAGS += -g

# The Bundle Objective-C source files to be compiled
$(FRAMEWORK_NAME)_OBJC_FILES = \
          Snd.m SndAudioBuffer.m SndDisplayData.m SndDisplayDataList.m\
          SndStreamClient.m SndStreamManager.m SndView.m sounderror.m\
          SndFunctions.m SndStreamRecorder.m SndStreamMixer.m SndPlayer.m\
		  SndPerformance.m SndAudioProcessorChain.m\
		  SndAudioProcessor.m  SndAudioProcessorDelay.m #SndMeter.m 

$(FRAMEWORK_NAME)_C_FILES = \
         SndEndianFunctions.c _SndConvert.c _Sndfilterkit.c _Sndlibst.c\
         _Sndresamplesubs.c

# The framework installed header files
$(FRAMEWORK_NAME)_HEADER_FILES = \
         Snd.h SndAudioBuffer.h SndDisplayData.h SndDisplayDataList.h\
         SndEndianFunctions.h SndFunctions.h SndKit.h SndResample.h\
         SndStdefs.h SndStreamClient.h SndStreamManager.h SndView.h\
         Sound.h sounderror.h _Sndfilterkit.h\
         _Sndlargefilter.h _Sndlibst.h _Sndsmallfilter.h\
		 SndStreamRecorder.h SndStreamMixer.h\
		 SndPlayer.h SndPerformance.h\
		 SndAudioProcessorChain.h SndAudioProcessor.h SndAudioProcessorDelay.h


SRCS = $(LIBRARY_NAME:=.m)
HDRS = $(LIBRARY_NAME:=.h)


-include Makefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/framework.make

-include Makefile.postamble
