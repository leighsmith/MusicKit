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
#
#  Modification history is contained in the CVS log
#

# Disabled
# Install into the local root by default
# GNUSTEP_INSTALLATION_DOMAIN = LOCAL

include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME = MKPerformSndMIDI
VERSION = 5.6.0

srcdir = .

# The framework to be compiled
ifneq ($(GNUSTEP_TARGET_OS), mingw32)
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
$(MY_NAME)_OBJC_FILES = PerformSound.m PerformMIDI.m

# The framework installed header files
$(MY_NAME)_HEADER_FILES = PerformSound.h \
         PerformMIDI.h \
         mididriver_types.h \
         PerformSoundPrivate.h \
         SndStruct.h \
         SndFormats.h \
         MKPerformSndMIDIConfig.h

$(MY_NAME)_HEADER_FILES_INSTALL_DIR = MKPerformSndMIDI

# SRCS = $(LIBRARY_NAME:=.m)
# HDRS = $(LIBRARY_NAME:=.h)

-include GNUmakefile.preamble

-include GNUmakefile.local

ifeq (mingw32, $(GNUSTEP_TARGET_OS))
  include $(GNUSTEP_MAKEFILES)/library.make
else
  include $(GNUSTEP_MAKEFILES)/framework.make
endif

-include GNUmakefile.postamble
