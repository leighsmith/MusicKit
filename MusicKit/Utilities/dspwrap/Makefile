#
#	Makefile - used to develop and maintain dspwrap
#	Copyright NeXT, Inc.  1989
#
# Modification History:
#	08/14/89/mtm - Revised, added header
#		       Install bins and dirs as 755.
#	02/08/92/jos - Revised for release 3.0.
#	09/07/94/daj - Added -lDriver

NAME= dspwrap
BINDIR= $(DSTROOT)/usr/local/bin
MAKEDIR = /tmp/dspwrap-s
PRODUCTS= dspwrap dsploadwrap
CFILES= dspwrap.c dsploadwrap.c DSPWriteC.c writeUG.c
OFILES = $(CFILES:.c=.o)
MANDIR = $(DSTROOT)/usr/local/man/man1/
MANPAGE1 = dspwrap.1
MANPAGE2 = dsploadwrap.1
MANPAGES = $(MANPAGE1) $(MANPAGE2)
SOURCE_FILES = $(CFILES) $(MANPAGES)
INSTALLSRC_FILES = $(SOURCE_FILES) Makefile README

# Install flags
IFLAGS = -q -c
BINIFLAGS = -s -c

# Compiler flags
BASE_CFLAGS = -Wimplicit -g $(RC_CFLAGS) #-arch m68k -arch i386
CFLAGS = $(BASE_CFLAGS) -O -F$(HOME)/Library/Frameworks -F/System/Library/PrivateFrameworks
#-L$(DSTROOT)/usr/local/lib #-I$(DSTROOT)$(LOCAL_DEVELOPER_DIR)/Headers
LIBS= -framework SndKit -framework MKDSP #-ldsp -lDriver
DEBUG_LIBS = -ldsp_g -lsys_s -lDriver
PROFILE_LIBS = -ldsp_p -lsys_s -lDriver
DSP_LIB_DIR = ../../dsp_proj/dsp/src/lib
DEBUG_CFLAGS = $(BASE_CFLAGS) -g -L$(DSP_LIB_DIR) -I$(DSP_LIB_DIR)
PROFILE_CFLAGS = $(BASE_CFLAGS) -pg -g -L$(DSP_LIB_DIR) -I$(DSP_LIB_DIR)

all: $(PRODUCTS) 

lean:
	/bin/rm -f $(OFILES) vers.o vers.c
	
clean: lean
	/bin/rm -f $(PRODUCTS) TAGS core

# Local install makes a debug version
local_install debug:
	$(MAKE) "CFLAGS = $(DEBUG_CFLAGS)" "LIBS = $(DEBUG_LIBS)"

profile:
	$(MAKE) "CFLAGS = $(PROFILE_CFLAGS)" "LIBS = $(PROFILE_LIBS)"

installsrc: SRCROOT
	/bin/rm -rf $(SRCROOT)
	mkdir -p -m 755 $(SRCROOT)
	tar chf - $(INSTALLSRC_FILES) | (cd $(SRCROOT); tar xfp -)
	(cd $(SRCROOT); chmod 644 $(INSTALLSRC_FILES))

next_install:
	mkdir -p -m 755 $(BINDIR)
	$(MAKE) installsrc SRCROOT=$(MAKEDIR)
	(cd $(MAKEDIR); $(MAKE) all; \
		install $(BINIFLAGS) -m 755 $(PRODUCTS) $(BINDIR))

install: all
	mkdir -p -m 755 $(BINDIR)
	install $(BINIFLAGS) -m 755 $(PRODUCTS) $(BINDIR)
	mkdir -p -m 755 $(MANDIR)
	install -c -m 644 $(MANPAGES) $(MANDIR)

installhdrs:
	echo 'No headers to install for dspwrap' >/dev/null

dspwrap: dspwrap.c vers.o
	$(CC) $(CFLAGS) -o dspwrap dspwrap.c vers.o $(LIBS)

dsploadwrap: dsploadwrap.c DSPWriteC.o vers.o writeUG.o
	$(CC) $(CFLAGS) -o dsploadwrap dsploadwrap.c \
		DSPWriteC.o writeUG.o vers.o $(LIBS)

vers.c:
	@/bin/rm -f $@
	-vers_string -c $(NAME) > $@

SRCROOT:
	@if [ -n "${$@}" ]; then exit 0; \
	else echo Must define $@; exit 1; fi

TAGS:
	etags $(CFILES)
