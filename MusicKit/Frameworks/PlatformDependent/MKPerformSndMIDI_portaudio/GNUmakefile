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


#  Modification history:
#
#  $Log$
#  Revision 1.7  2002/01/09 12:14:39  sbrandon
#  updated portaudio from v15b to v17. This primarily fixes bugs in the linux
#  (now called the unix) implementation, but there are other changes which
#  may help the win_ds version too.
#
#  Revision 1.6  2001/11/21 23:08:45  sbrandon
#  added MKPerformSndMIDIDefines.h as an installed header (oops)
#
#  Revision 1.5  2001/11/07 14:49:25  sbrandon
#  removed unecessary lines
#
#  Revision 1.4  2001/10/31 17:34:11  sbrandon
#  Substantial changes which were required to get it to work under MinGW.
#
#  Revision 1.3  2001/09/03 17:12:45  sbrandon
#  put in extra compiler warnings
#
#  Revision 1.2  2001/07/18 12:49:38  sbrandon
#  - renamed PerformSound.c to PerformSound.m and included as ObjC source file.
#
#  Revision 1.1  2001/07/02 22:03:48  sbrandon
#  - initial revision. Still a work in progress, but does allow the MusicKit
#    and SndKit to compile on GNUstep.
#
#

# Install into the local root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

include $(GNUSTEP_MAKEFILES)/common.make

#include ../Version
#include ../config.mak

srcdir = .

ifneq (mingw32, $(GNUSTEP_TARGET_OS))
# The framework to be compiled
  FRAMEWORK_NAME = MKPerformSndMIDI
  MY_NAME = $(FRAMEWORK_NAME)
else
  LIBRARY_NAME = libMKPerformSndMIDI
  MY_NAME = $(LIBRARY_NAME)
endif

# The framework resource files and directories
$(MY_NAME)_RESOURCE_FILES = 

$(MY_NAME)_RESOURCE_DIRS = 

ADDITIONAL_CFLAGS += -g -Wall

# The Bundle Objective-C source files to be compiled
$(MY_NAME)_OBJC_FILES = PerformSound.m

ifeq (mingw32, $(GNUSTEP_TARGET_OS))
  $(MY_NAME)_C_FILES = PerformMIDI.c \
		portaudio/pa_common/pa_lib.c \
                portaudio/pa_win_ds/dsound_wrapper.c \
                portaudio/pa_win_ds/pa_dsound.c
else
  $(MY_NAME)_C_FILES = PerformMIDI.c \
                portaudio/pa_common/pa_lib.c \
                portaudio/pa_unix_oss/pa_unix_oss.c \
                portaudio/pa_common/pa_trace.c
endif
		
# The framework installed header files
$(MY_NAME)_HEADER_FILES = PerformSound.h PerformMIDI.h \
         mididriver_types.h PerformSoundPrivate.h sounderror.h \
         SndStruct.h mididriverUser.h SndFormats.h \
         MKPerformSndMIDIDefines.h

$(MY_NAME)_HEADER_FILES_INSTALL_DIR = MKPerformSndMIDI

SRCS = $(LIBRARY_NAME:=.m)
HDRS = $(LIBRARY_NAME:=.h)


-include GNUmakefile.preamble

-include GNUmakefile.local

ifeq (mingw32, $(GNUSTEP_TARGET_OS))
  include $(GNUSTEP_MAKEFILES)/library.make
else
  include $(GNUSTEP_MAKEFILES)/framework.make
endif

-include GNUmakefile.postamble
