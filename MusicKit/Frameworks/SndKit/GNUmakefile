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

# Modification history:
# $Log$
# Revision 1.15  2002/01/04 11:01:46  sbrandon
# added new file SndAudioProcessorToneGenerator.m to build
#
# Revision 1.14  2002/01/02 13:35:03  skotmcdonald
# Added new files to GNU makefile
#
# Revision 1.13  2001/11/27 17:41:01  sbrandon
# now do prelinking of libraries on all platforms, so SndKit projects don't
# need to know the ins and outs of which libraries are being used. They just
# have to say they're using SndKit and it looks after everything.
#
# Revision 1.12  2001/11/21 23:19:49  sbrandon
# made makefile distinguish between MinGW and 'other' targets when deciding
# whether or not to include the SndAudioProcessorMP3Encoder.h header (fix
# for non-Windows GNUstep targets).
#
# Revision 1.11  2001/11/07 12:38:18  sbrandon
# added SndKitDefines.h header which contains Win32-specific SNDKIT_API
# declarations.
#
# Revision 1.10  2001/10/31 16:16:35  sbrandon
# Major rehash of makefile to aid win32 compilation. For mingw32, now compiles as a library rather than a framework, until GNUstep frameworks are sorted out properly on Windows (they are ok on UNIX).
#
# Revision 1.9  2001/10/03 10:45:05  sbrandon
# added SndAudioProcessorMP3Encoder.h and SndAudioProcessorMP3Encoder.m
#
# Revision 1.8  2001/09/12 14:10:02  sbrandon
# changed my e-mail address, added additional LDFLAG
#
# Revision 1.7  2001/09/11 17:12:11  sbrandon
# added cpp.subproj subproject, for GNUstep only, as a way of incorporating
# C++ files into GNUstep framework
#
# Revision 1.6  2001/09/03 10:36:17  sbrandon
# fixed typo in last commit
#
# Revision 1.5  2001/09/03 09:37:43  sbrandon
# added new SndAudioBufferQueue class and header file
#
# Revision 1.4  2001/08/27 09:32:54  sbrandon
# added more stringent compiler warnings on GNUstep
#
# Revision 1.3  2001/08/08 19:29:19  sbrandon
# - added new classes SndAudioFader, SndEnvelope, SndBreakpoint
#
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

ifeq (mingw32, $(GNUSTEP_TARGET_OS))
  SK_COMPILE_APPKIT_CLASSES = no
  SK_COMPILE_MP3_ENCODER = no
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

ADDITIONAL_FLAGS += -g -Wall
ADDITIONAL_LDFLAGS += -g

# The Bundle Objective-C source files to be compiled
$(MY_NAME)_OBJC_FILES = \
          Snd.m SndAudioBuffer.m SndDisplayData.m SndDisplayDataList.m\
          SndStreamClient.m SndStreamManager.m sounderror.m\
          SndFunctions.m SndStreamRecorder.m SndStreamMixer.m SndPlayer.m\
          SndPerformance.m SndAudioProcessorChain.m\
          SndAudioProcessor.m  SndAudioProcessorDelay.m SndEnvelope.m\
          SndAudioFader.m SndBreakpoint.m\
          SndAudioBufferQueue.m SndAudioProcessorReverb.m \
	  SndAudioProcessorDistortion.m	SndAudioProcessorFlanger.m \
	  SndAudioProcessorRecorder.m SndAudioProcessorInspector.m \
          SndAudioProcessorToneGenerator.m
	  #SndMeter.m

$(MY_NAME)_C_FILES = \
         SndEndianFunctions.c _SndConvert.c _Sndfilterkit.c _Sndlibst.c\
         _Sndresamplesubs.c

# The framework installed header files
$(MY_NAME)_HEADER_FILES = \
         Snd.h SndAudioBuffer.h SndDisplayData.h SndDisplayDataList.h\
         SndEndianFunctions.h SndFunctions.h SndKit.h SndResample.h\
         SndStdefs.h SndStreamClient.h SndStreamManager.h SndView.h\
         Sound.h sounderror.h _Sndfilterkit.h\
         _Sndlargefilter.h _Sndlibst.h _Sndsmallfilter.h\
         SndStreamRecorder.h SndStreamMixer.h\
         SndPlayer.h SndPerformance.h\
         SndAudioProcessorChain.h SndAudioProcessor.h SndAudioProcessorDelay.h\
         SndAudioFader.h SndEnvelope.h SndBreakpoint.h SndAudioBufferQueue.h\
         SndAudioProcessorReverb.h SndKitDefines.h \
	 SndAudioProcessorDistortion.h SndAudioProcessorFlanger.h \
	 SndAudioProcessorRecorder.h SndAudioProcessorInspector.h \
         SndAudioProcessorToneGenerator.h

$(MY_NAME)_HEADER_FILES_INSTALL_DIR = SndKit

# Extra DLL exports file
$(MY_NAME)_DLL_DEF = $(MY_NAME).def

ifeq ($(SK_COMPILE_MP3_ENCODER), yes)
  $(MY_NAME)_OBJC_FILES += SndAudioProcessorMP3Encoder.m
  $(MY_NAME)_HEADER_FILES += SndAudioProcessorMP3Encoder.h
else
  ADDITIONAL_FLAGS += -DSK_NO_MP3_ENCODER
endif

ifeq (yes, $(SK_COMPILE_APPKIT_CLASSES))
  $(MY_NAME)_OBJC_FILES += SndView.m
  ADDITIONAL_FLAGS += -DSK_COMPILE_APPKIT_CLASSES
else
  $(MY_NAME)_OBJC_FILES += SndConditionLock.m
endif

$(MY_NAME)_SUBPROJECTS = cpp.subproj

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
