#
# Application makefile. 
#
#

#
# Name of the application. 
#
NAME = playscorefile2

#
# Source files for this application. 
#
# If you add your own SynthPatch, add it in 2 places:
#    in the MFILES list and the LDFLAGS list.
MFILES = playscorefile2.m 
HFILES =
CFILES = 
NIBFILES =
TIFFFILES = 
PSWFILES = 
SNDFILES = 

#
# Libraries used by this application.
#
LIBS =  -lsynthpatches -lunitgenerators -lmusickit -ldsp -lNeXT_s -lsys_s -lDriver

#
# Flags to pass on to the compiler and linker.
#
CFLAGS=	-g

# Here's where you put the list of SynthPatches to be pre-loaded.
# If we want to support dynamic loading, we should include the flags
#    -u lNeXT_s and -u libsys_s.
#    We should also include -u statements for all the UnitGenerators, since
#    we don't know what UnitGenerators the dynamically loaded class will
#    use.  An easier way to do this (at the expense of a bigger executable)
#    is to use the -ObjC flag.
LDFLAGS = -u .objc_class_name_Simp \
	-u .objc_class_name_Wave1 \
	-u .objc_class_name_Wave1v \
	-u .objc_class_name_DBWave1v \
	-u .objc_class_name_Wave1i \
	-u .objc_class_name_Wave1vi \
	-u .objc_class_name_DBWave1vi \
	-u .objc_class_name_DBWave2vi \
	-u .objc_class_name_Fm1 \
	-u .objc_class_name_Fm1v \
	-u .objc_class_name_Fm1i \
	-u .objc_class_name_Fm1vi \
	-u .objc_class_name_Fm2pvi \
	-u .objc_class_name_Fm2pnvi \
	-u .objc_class_name_Fm2cvi \
	-u .objc_class_name_Fm2cnvi \
	-u .objc_class_name_Shape \
	-u .objc_class_name_Shapev \
	-u .objc_class_name_DBFm1vi \
	-u .objc_class_name_Pluck

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
