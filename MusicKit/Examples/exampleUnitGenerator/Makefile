#
# Application makefile. 
#
#
# Generated by the NeXT Interface Builder. 
#

#
# Name of the application. 
#
NAME = exampunitgenerator

#
# Source files for this application. 
#
MFILES = exampunitgenerator.m 
HFILES = 
DSPFILES = oscw.asm config_standalone.asm test.asm

DERIVED_MFILES = OscwUGx.m OscwUG.m
DERIVED_HFILES = OscwUGx.h OscwUG.h
#
# Libraries used by this application.
#
LIBS = -lunitgenerators -lmusickit -ldsp -lNeXT_s -lDriver

#
# Flags to pass on to the compiler and linker.
#
CFLAGS = -O -g -Wall

#
# Directory containing the DSP system macros
#
DSPDIR = /usr/local/lib/dsp

#
# Rules.
#
SRCFILES = $(MFILES) $(HFILES) $(DSPFILES) exampunitgenerator2.m
OBJFILES = $(MFILES:.m=.o) $(DERIVED_MFILES:.m=.o) 
DERIVED = oscwUGInclude.m OscwUG[xy].* oscw_*  *.lod *.lst
GARBAGE = $(DERIVED) core errs
INSTALLDIR = $(HOME)/Apps
INSTALLFLAGS = -c -s -m 755

$(NAME): OscwUGx.m $(OBJFILES) 
	$(CC) $(CFLAGS) $(LFLAGS) -o $@ $(OBJFILES) $(LIBS) 

OscwUGx.m: oscw.asm
	-/bin/rm oscw_*.lnk
	dspwrap -ug -noDoc -local $(DSPDIR)/smsrc oscw.asm

test.lod: oscw.asm test.asm config_standalone.asm
	./dspasm test

test: test.lod

all: $(NAME) test

clean: 
	-rm -f *.o $(NAME) $(DERIVED) $(GARBAGE) 

really_clean: clean
	-rm -f OscwUG*.[mh]

help: 
	@echo '  make installsrc SRCROOT=~/exampUG - to copy this example'
	@echo '  make test.lod - to make the stand-alone DSP test program'
	@echo '  make $(NAME) - to make the application'
	@echo '  make clean - to remove all files but the source'
	@echo '  make really_clean - also remove all OscwUG files'
	@echo '  make install [DSTROOT=somepath] - to make and install the application'

#Usage: "make installsrc SRCROOT=dir"
#        where dir is where you want the example installed.

installsrc: $(SRCROOT)
	cp $(SRCFILES) Makefile README $(SRCROOT)
	chmod 666 $(SRCROOT)/*

$(SRCROOT):
	mkdirs -m 775 $(SRCROOT)

install: $(DSTROOT)$(INSTALLDIR) all
	install $(INSTALLFLAGS) $(NAME) $(DSTROOT)$(INSTALLDIR)

$(DSTROOT)$(INSTALLDIR):
	mkdirs $(DSTROOT)$(INSTALLDIR)
