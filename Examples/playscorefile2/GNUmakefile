#
#   $Id: GNUmakefile 3459 2009-04-08 22:13:47Z leighsmith $
#   Defined In: The MusicKit
#
#  Description:
#    Makefile for GNUstep version of playscorefile2
#
#  Original Author: Leigh M. Smith
#
#  25 April 2009, Copyright (c) 2009 Leigh M. Smith
#
#  Permission is granted to use and modify this code for commercial and non-commercial
#  purposes so long as the author attribution and this copyright message remains intact
#  and accompanies all derived code.

# If you add your own SynthPatch, add it in 2 places:
#    in the OBJC_FILES list and the LDFLAGS list.

include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = playscorefile2

$(TOOL_NAME)_OBJC_FILES = playscorefile2.m 

#
# Libraries used by this command line tool.
#
ADDITIONAL_TOOL_LIBS += -lMusicKit # -lsynthpatches -lunitgenerators 

# TODO this should probably be in the GNUmakefile.preamble file.
# Here's where you put the list of SynthPatches to be pre-loaded.
# If we want to support dynamic loading, we should include the flags:
#    -u lNeXT_s and -u libsys_s.
#    We should also include -u statements for all the UnitGenerators, since
#    we don't know what UnitGenerators the dynamically loaded class will
#    use.  An easier way to do this (at the expense of a bigger executable)
#    is to use the -ObjC flag.
# LDFLAGS = -u .objc_class_name_Simp \
# 	-u .objc_class_name_Wave1 \
# 	-u .objc_class_name_Wave1v \
# 	-u .objc_class_name_DBWave1v \
# 	-u .objc_class_name_Wave1i \
# 	-u .objc_class_name_Wave1vi \
# 	-u .objc_class_name_DBWave1vi \
# 	-u .objc_class_name_DBWave2vi \
# 	-u .objc_class_name_Fm1 \
# 	-u .objc_class_name_Fm1v \
# 	-u .objc_class_name_Fm1i \
# 	-u .objc_class_name_Fm1vi \
# 	-u .objc_class_name_Fm2pvi \
# 	-u .objc_class_name_Fm2pnvi \
# 	-u .objc_class_name_Fm2cvi \
# 	-u .objc_class_name_Fm2cnvi \
# 	-u .objc_class_name_Shape \
# 	-u .objc_class_name_Shapev \
# 	-u .objc_class_name_DBFm1vi \
# 	-u .objc_class_name_Pluck

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/tool.make

-include GNUmakefile.postamble

