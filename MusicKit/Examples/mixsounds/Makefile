#
# Application makefile. 
#
#

#
# Name of the application. 
#
NAME = mixsounds

#
# Source files for this application. 
#
MFILES = mixsounds.m MixInstrument.m
HFILES = MixInstrument.h resample.h filterkit.h
CFILES = filterkit.c resamplesubs.c
NIBFILES =
TIFFFILES = 
PSWFILES = 
SNDFILES = 
SCOREFILES = testMix.score testMix2.score testMix3.score
#
# Libraries used by this application.
#
LIBS =  -lmusickit -lNeXT_s 

#
# Flags to pass on to the compiler and linker.
#
CFLAGS=	-O3 -fno-omit-frame-pointer -Wall -g -DDEBUG

LDFLAGS =

#
# Rules.
#
SRCFILES = $(MFILES) $(HFILES) $(CFILES) $(NIBFILES) $(TIFFFILES) $(PSWFILES) $(SCOREFILES)
OBJFILES = $(MFILES:.m=.o) $(CFILES:.c=.o) $(PSWFILES:.psw=.o) 
DERIVED = $(PSWFILES:.psw=.c) 
GARBAGE = $(DERIVED) core errs 
INSTALLDIR = $(HOME)/bin
INSTALLFLAGS = -c -s -m 755

$(NAME): $(OBJFILES) 
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJFILES) $(LIBS) 

all: $(NAME) extractchannel maxamp

clean: 
	-rm -f MixInstrument.o mixsounds.o $(NAME) $(DERIVED) $(GARBAGE)   extractchannel.o extractchannel maxamp.o maxamp Examp1.snd resamplesubs.o filterkit.o

help: 
	@echo '  make $(NAME) - to make the application'
	@echo '  make clean -    to remove all files but the source'
	@echo '  make install [DSTROOT=somepath] - to make and install the application'

installsrc:
	-rm -rf $(SRCROOT)
	mkdirs -m 755 $(SRCROOT)
	cp $(SRCFILES) Makefile README $(SRCROOT)
	chmod 444 $(SRCROOT)/*

install: $(DSTROOT)$(INSTALLDIR) all
	install $(INSTALLFLAGS) $(NAME) $(DSTROOT)$(INSTALLDIR)

$(DSTROOT)$(INSTALLDIR):
	mkdirs $(DSTROOT)$(INSTALLDIR)

CFILES2 = extractchannel.c
OBJFILES2 = $(CFILES2:.c=.o)
LIBS2 = -lNeXT_s

extractchannel: $(OBJFILES2)
	$(CC) $(CFLAGS) -o extractchannel $(OBJFILES2) $(LIBS2) 

CFILES3 = maxamp.c
OBJFILES3 = $(CFILES3:.c=.o)
LIBS3 = -lNeXT_s

maxamp: $(OBJFILES3)
	$(CC) $(CFLAGS) -o maxamp $(OBJFILES3) $(LIBS3) 

