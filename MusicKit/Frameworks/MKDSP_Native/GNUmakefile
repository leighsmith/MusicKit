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
# Revision 1.1  2001/05/12 09:05:25  sbrandon
# - basic makefile for GNUstep platforms. Note that framework.make in GNUstep
#   currently needs a small patch to allow the making of frameworks with no
#   ObjC classes - this should be fixed soon (e-mail me for patch if necessary)
#
#

# Install into the local root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

include $(GNUSTEP_MAKEFILES)/common.make

srcdir = .

# The framework to be compiled
FRAMEWORK_NAME = MKDSP

# The framework resource files and directories
$(FRAMEWORK_NAME)_RESOURCE_FILES = 

$(FRAMEWORK_NAME)_RESOURCE_DIRS = 

# The framework libraries to link against
#sb: not sure about this...
#$(FRAMEWORK_NAME)BUNDLE_LIBS = 


# The Bundle Objective-C source files to be compiled
$(FRAMEWORK_NAME)_OBJC_FILES = dsp_stubs.m

$(FRAMEWORK_NAME)_C_FILES =

# The framework installed header files
$(FRAMEWORK_NAME)_HEADER_FILES = dsp.h DSPControl.h DSPConversion.h dspdriver.h\
         dspdriverAccess.h dspdriver_types.h DSPError.h DSPMessage.h\
         DSPMessage.ReaderThreadForAll.h DSPObject.h\
         DSPObject.ReaderThreadForAll.h dspreg.h DSPStructMisc.h\
         DSPSymbols.h DSPTransfer.h dsp_errno.h dsp_memory_map.h\
         dsp_memory_map_ap.h dsp_memory_map_ap_1.0.h dsp_memory_map_mk.h\
         dsp_memory_map_mk_1.0.h dsp_messages.h dsp_messages_1.0.h\
         dsp_structs.h dsp_types.h libdsp.h monitor_independent.h\
         smsrc_dependencies.h snddriver.h _dsp.h _DSPMach.h\
         _DSPMachAccessMacros.h _DSPMessage.h _DSPObject.h\
         _DSPTransfer.h _dsp_message_names.h _libdsp.h _MachMessages.h


SRCS = $(LIBRARY_NAME:=.m)
HDRS = $(LIBRARY_NAME:=.h)


-include Makefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/framework.make

-include Makefile.postamble