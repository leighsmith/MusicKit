# Application makefile. 
#
#

#
# Name of the application. 
#
NAME = mixscorefiles

#
# Source files for this application. 
#
MFILES = mixscorefiles.m 
HFILES =
CFILES = 
NIBFILES =
TIFFFILES = 
PSWFILES = 
SNDFILES = 

#
# Libraries used by this application.
#
LIBS =  -lmusickit -lNeXT_s

#
# Flags to pass on to the compiler and linker.
#
CFLAGS=	-g
LDFLAGS = 

#
# Rules.
#
SRCFILES = $(MFILES) $(HFILES) $(CFILES) $(NIBFILES) $(TIFFFILES) $(PSWFILES) 
OBJFILES = $(MFILES:.m=.o) $(CFILES:.c=.o) $(PSWFILES:.psw=.o) 
DERIVED = $(PSWFILES:.psw=.c) 
GARBAGE = $(DERIVED) core errs 
INSTALLDIR = $(HOME)/Apps
INSTALLFLAGS = -c -s -m 755

$(NAME): $(OBJFILES) 
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJFILES) $(LIBS) 

all: $(NAME)

clean: 
	-rm -f *.o $(NAME) $(DERIVED) $(GARBAGE) 

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
