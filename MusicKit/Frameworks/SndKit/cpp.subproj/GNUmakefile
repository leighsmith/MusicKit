#
#   $Id$
#   Defined In: The MusicKit
#
#  Description:
#    Makefile for GNUstep, in subproject created for C++ files in the SndKit
#    Any other cpp files added to the SndKit should be mentioned in here
#    so that they can be compiled into it.
#
#  Original Author: Stephen Brandon <stephen@brandonitconsulting.co.uk>
#
#  11 September 2001, Copyright (c) 2001 Stephen Brandon.
#
#  Permission is granted to use and modify this code for commercial and non-commercial
#  purposes so long as the author attribution and this copyright message remains intact
#  and accompanies all derived code.

# Modification history:
# $Log$
# Revision 1.2  2001/09/11 20:04:39  sbrandon
# added header, tidied up code
#

%.o : ../%.cpp
	$(CC) -c $(ALL_CPPFLAGS) $(ALL_OBJCFLAGS) -o $(GNUSTEP_OBJ_DIR)/$@ $<


include $(GNUSTEP_MAKEFILES)/common.make

all: $(GNUSTEP_OBJ_DIR) $(GNUSTEP_OBJ_DIR)/subproject.o

build-headers:

clean:
	-rm -Rf $(GNUSTEP_OBJ_DIR) *.o

install:

OBJECTS = allpass.o comb.o \
              reverbBridge.o revmodel.o
CPP_OBJECTS = $(addprefix $(GNUSTEP_OBJ_DIR)/,$(OBJECTS))

$(GNUSTEP_OBJ_DIR):
	$(MKDIRS) $(GNUSTEP_OBJ_DIR)

$(GNUSTEP_OBJ_DIR)/subproject.o: $(OBJECTS)
	$(CC) -nostdlib -r -o $@ $(CPP_OBJECTS)
