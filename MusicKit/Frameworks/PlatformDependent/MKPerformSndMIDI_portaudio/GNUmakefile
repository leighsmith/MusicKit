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


#Modification history:
#
#  $Log$
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

# The framework to be compiled
FRAMEWORK_NAME = MKPerformSndMIDI

# The framework resource files and directories
MKPerformSndMIDI_RESOURCE_FILES = 

MKPerformSndMIDI_RESOURCE_DIRS = 

# The framework libraries to link against
#sb: not sure about this...
#MKPerformSndMIDIBUNDLE_LIBS = 

ADDITIONAL_CFLAGS += -g -Wall

# The Bundle Objective-C source files to be compiled
MKPerformSndMIDI_OBJC_FILES = PerformSound.m

MKPerformSndMIDI_C_FILES = PerformMIDI.c \
		portaudio/pa_common/pa_lib.c portaudio/pa_linux_oss/pa_linux_oss.c \
                portaudio/pa_common/pa_trace.c
		
# The framework installed header files
MKPerformSndMIDI_HEADER_FILES = PerformSound.h PerformMIDI.h \
         mididriver_types.h PerformSoundPrivate.h sounderror.h\
         SndStruct.h mididriverUser.h SndFormats.h


SRCS = $(LIBRARY_NAME:=.m)
HDRS = $(LIBRARY_NAME:=.h)


-include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/framework.make

-include GNUmakefile.postamble
