#
#   $Id$
#   Defined In: The MusicKit
#
#  Description:
#    Makefile for GNUstep
#
#  Original Author: Stephen Brandon <stephen@brandonitconsulting.co.uk>
#
#  21 April 2001, Copyright (c) 2001 Stephen Brandon.
#
#  Permission is granted to use and modify this code for commercial and non-commercial
#  purposes so long as the author attribution and this copyright message remains intact
#  and accompanies all derived code.

# See the public CVS logs for the modification history via http://www.musickit.org

# Install into the local root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

include $(GNUSTEP_MAKEFILES)/common.make

# For use in rpm generation:
PACKAGE_NAME = SndKit
VERSION = 2.3.2

srcdir = .

ifeq (mingw32, $(GNUSTEP_TARGET_OS))
  SK_COMPILE_APPKIT_CLASSES = yes 
  SK_COMPILE_MP3_ENCODER = yes
else
  SK_COMPILE_APPKIT_CLASSES = yes
  SK_COMPILE_MP3_ENCODER = yes
endif

ifeq (mingw32, $(GNUSTEP_TARGET_OS))
  LIBRARY_NAME = libSndKit
  MY_NAME = $(LIBRARY_NAME)
else
# The framework to be compiled
  FRAMEWORK_NAME = SndKit
  MY_NAME=$(FRAMEWORK_NAME)
endif

# The framework resource files and directories
$(MY_NAME)_RESOURCE_FILES = 

$(MY_NAME)_RESOURCE_DIRS = 

# The Bundle Objective-C source files to be compiled
$(MY_NAME)_OBJC_FILES = \
         Snd.m \
         SndAudioBuffer.m \
         SndAudioBufferQueue.m \
         SndAudioFader.m \
         SndAudioProcessor.m \
         SndAudioProcessorChain.m \
         SndAudioProcessorDelay.m \
         SndAudioProcessorDistortion.m \
         SndAudioProcessorFlanger.m \
         SndAudioProcessorInspector.m \
         SndAudioProcessorNoiseGate.m \
         SndAudioProcessorRecorder.m \
         SndAudioProcessorReverb.m \
         SndAudioProcessorToneGenerator.m \
         SndBreakpoint.m \
         SndDisplayData.m \
         SndDisplayDataList.m \
         SndEnvelope.m \
         SndError.m \
         SndExpt.m \
         SndFunctions.m \
         SndFunctionsDiskIO.m \
         SndStreamArchitectureView.m \
         SndStreamClient.m \
         SndStreamManager.m \
         SndStreamMixer.m \
         SndStreamRecorder.m \
         SndPerformance.m \
         SndPlayer.m\
         SndTable.m \
         SndView.m \
         SndConvert.m \
         SndResample.m \
	 SndMuLaw.m \
         SndMeter.m

$(MY_NAME)_C_FILES = \
         SndEndianFunctions.c \
         _Sndfilterkit.c \

$(MY_NAME)_CC_FILES = \
         allpass.cpp \
         comb.cpp \
         reverbBridge.cpp \
         revmodel.cpp

# The framework installed header files
$(MY_NAME)_HEADER_FILES = \
         Snd.h \
         SndAudioBuffer.h \
         SndAudioBufferQueue.h \
         SndAudioFader.h \
         SndAudioProcessor.h \
         SndAudioProcessorChain.h \
         SndAudioProcessorDelay.h \
         SndAudioProcessorDistortion.h \
         SndAudioProcessorFlanger.h \
         SndAudioProcessorInspector.h \
         SndAudioProcessorNoiseGate.h \
         SndAudioProcessorRecorder.h \
         SndAudioProcessorReverb.h \
         SndAudioProcessorToneGenerator.h \
         SndBreakpoint.h \
         SndConditionLock.h \
         SndDisplayData.h \
         SndDisplayDataList.h \
         SndEndianFunctions.h \
         SndEnvelope.h \
         SndError.h \
         SndExpt.h \
         SndFormat.h \
         SndFunctions.h \
         SndKitDefines.h \
         SndKit.h \
         SndPerformance.h \
         SndPlayer.h \
         SndResample.h \
         SndStdefs.h \
         SndStreamArchitectureView.h \
         SndStreamClient.h \
         SndStreamManager.h \
         SndStreamMixer.h \
         SndStreamRecorder.h \
         SndTable.h \
         SndView.h\
         SndMuLaw.h \
         SndMeter.h \
         _Sndfilterkit.h \
         _Sndlargefilter.h \
         _Sndsmallfilter.h

$(MY_NAME)_HEADER_FILES_INSTALL_DIR = SndKit

# Extra DLL exports file
$(MY_NAME)_DLL_DEF = $(MY_NAME).def

ifeq ($(SK_COMPILE_MP3_ENCODER), yes)
  $(MY_NAME)_OBJC_FILES += SndAudioProcessorMP3Encoder.m SndMP3.m
  $(MY_NAME)_HEADER_FILES += SndAudioProcessorMP3Encoder.h SndMP3.h
else
  ADDITIONAL_FLAGS += -DSK_NO_MP3_ENCODER
endif

#ifeq (yes, $(SK_COMPILE_APPKIT_CLASSES))
#  $(MY_NAME)_OBJC_FILES += SndView.m
#  ADDITIONAL_FLAGS += -DSK_COMPILE_APPKIT_CLASSES
#endif

ifeq (mingw32, $(GNUSTEP_TARGET_OS))
  $(MY_NAME)_OBJC_FILES += SndConditionLock.m
endif

SRCS = $(LIBRARY_NAME:=.m)
HDRS = $(LIBRARY_NAME:=.h)

-include GNUmakefile.preamble

-include GNUmakefile.local

ifeq (mingw32, $(GNUSTEP_TARGET_OS))
  include $(GNUSTEP_MAKEFILES)/library.make
else
  include $(GNUSTEP_MAKEFILES)/framework.make
endif

-include Makefile.postamble
