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
#
#  $Log$
#  Revision 1.1  2001/04/21 21:57:45  sbrandon
#  First commit of makefile for GNUstep systems. Note that you need a very recent
#  version of GNUstep (I use the CVS version) in order to get support for frameworks.
#  Also, I had to hand patch framework.make to allow it to build this framework, since
#  it has no ObjC classes in it (the author was notified - hopefully he'll build in the
#  fix into the next release of GNUstep).
#
#


# Install into the system root by default
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


# The Bundle Objective-C source files to be compiled
MKPerformSndMIDI_OBJC_FILES = 

MKPerformSndMIDI_C_FILES = PerformMIDI.c PerformSound.c

# The framework installed header files
MKPerformSndMIDI_HEADER_FILES = PerformSound.h PerformMIDI.h \
         mididriver_types.h PerformSoundPrivate.h sounderror.h\
         soundstruct.h mididriverUser.h


SRCS = $(LIBRARY_NAME:=.m)
HDRS = $(LIBRARY_NAME:=.h)


-include Makefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/framework.make

-include Makefile.postamble
