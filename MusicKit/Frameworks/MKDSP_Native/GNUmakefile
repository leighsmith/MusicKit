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

# Install into the local root by default
GNUSTEP_INSTALLATION_DOMAIN = LOCAL

#GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME = MKDSP
VERSION = 5.4.1

srcdir = .

# The framework to be compiled
ifneq (mingw32, $(GNUSTEP_TARGET_OS))
# The framework to be compiled
  FRAMEWORK_NAME = MKDSP
  MY_NAME = $(FRAMEWORK_NAME)
else
  LIBRARY_NAME = libMKDSP
  MY_NAME = $(LIBRARY_NAME)
endif

# The framework resource files and directories
$(MY_NAME)_RESOURCE_FILES = 

$(MY_NAME)_RESOURCE_DIRS = 

# The Bundle Objective-C source files to be compiled
$(MY_NAME)_OBJC_FILES = dsp_stubs.m DSPerror_gnustep.m

$(MY_NAME)_C_FILES = #_DSPUtilities.c _DSPCV.c _DSPString.c

# The framework installed header files
$(MY_NAME)_HEADER_FILES = dsp.h DSPControl.h DSPConversion.h dspdriver.h\
         dspdriverAccess.h dspdriver_types.h DSPError.h DSPMessage.h\
         DSPMessage.ReaderThreadForAll.h DSPObject.h\
         DSPObject.ReaderThreadForAll.h dspreg.h DSPStructMisc.h\
         DSPSymbols.h DSPTransfer.h dsp_errno.h dsp_memory_map.h\
         dsp_memory_map_ap.h dsp_memory_map_ap_1.0.h dsp_memory_map_mk.h\
         dsp_memory_map_mk_1.0.h dsp_messages.h dsp_messages_1.0.h\
         dsp_structs.h dsp_types.h libdsp.h monitor_independent.h\
         smsrc_dependencies.h snddriver.h _dsp.h _DSPMach.h\
         _DSPMachAccessMacros.h _DSPMessage.h _DSPObject.h\
         _DSPTransfer.h _dsp_message_names.h _libdsp.h _MachMessages.h \
         MKDSPDefines.h

$(MY_NAME)_HEADER_FILES_INSTALL_DIR = MKDSP

SRCS = $(LIBRARY_NAME:=.m)
HDRS = $(LIBRARY_NAME:=.h)


-include GNUmakefile.preamble

ifeq (mingw32, $(GNUSTEP_TARGET_OS))
  include $(GNUSTEP_MAKEFILES)/library.make
else
  include $(GNUSTEP_MAKEFILES)/framework.make
endif

-include Makefile.postamble
