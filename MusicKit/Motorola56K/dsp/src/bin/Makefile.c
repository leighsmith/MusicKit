# Copyright 1988-1992, NeXT Inc.  All rights reserved.
#
# Generic makefile for C programs
# To use this makefile, just create a makefile containing
#
# NAME = <progname>
# include <this makefile>
#
MFILES = $(OTHER_MFILES)
CFILES = $(NAME).c $(OTHER_CFILES)

LOADLIBES = $(OTHER_LIBS) -ldsp -lsys_s -lDriver 
DEBUG_LOADLIBES = $(OTHER_LIBS) -ldsp_g  -lsys_s -lDriver
PROFILE_LOADLIBES = $(OTHER_LIBS) -ldsp_p lsys_s -lDriver

# include ../Makefile.cm (now below)

PRODUCT = $(NAME)
MANDIR = ${DSTROOT}/usr/local/man/man1/
MANPAGE = $(NAME).1

HEADERDIR = /LocalDeveloper/Headers/dsp
LIBDSPDIR = ../../../src/lib
#LIBDSP = $(LIBDSPDIR)/libdsp_s.a
LIBDSP = $(LIBDSPDIR)/libdsp.a
DEBUG_LIBDSP = $(LIBDSPDIR)/libdsp_g.a
PROFILE_LIBDSP = $(LIBDSPDIR)/libdsp_p.a

# Makefile.config is actually obtained from the dir one up from here
include ../../../Makefile.config

# There was a cc1 bug that prevents using -O and -g together.  Fixed?
BASE_CFLAGS = -I. -I$(LIBDSPDIR) -L$(LIBDSPDIR) $(RC_CFLAGS) $(OTHER_CFLAGS) -Wall
CFLAGS = -O -g $(BASE_CFLAGS)
DEBUG_CFLAGS = -g $(BASE_CFLAGS)
# *** BUG *** I can't see out how to use the following. (OFILES made from rule)
PROFILE_CFLAGS = -pg $(BASE_CFLAGS)

LDFLAGS = $(OTHER_LDFLAGS)

PRINT = list

OFILES = $(MFILES:.m=.o) $(CFILES:.c=.o)

# files that will be removed on make clean, along with .o's
GARBAGE = $(BY_PRODUCTS) TAGS tags core $(OTHER_GARBAGE) $(NAME).io foo foo.snd

# all source code
SRCS = $(HFILES) $(MFILES) $(CFILES)

# all non-derived, non-garbage files.  This is the source, plus Makefiles,
# plus anything else that needs to be around for the products to be made.
INSTALLSRC_FILES = Makefile $(MANPAGE) $(OTHER_MANPAGES) \
		$(SRCS) $(M_AUX_FILES) $(OTHER_INSTALLSRC_SOURCE)

# an application is made by first making all its components, and then
# linking the whole thing together.

all: $(PRODUCT)

DEBUG_PRODUCT = d$(PRODUCT)

profile: $(PG_PRODUCT)

$(PRODUCT): $(OFILES) $(OTHER_DEP) $(LIBDSP)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(PRODUCT) $(OFILES) \
		$(OTHER_OFILES) $(LOADLIBES)
	$(OTHER_MAKE_PRODUCT_ACTIONS)
#	md -f -d $(OFILES:.o=.d)

$(DEBUG_PRODUCT): $(OFILES) $(OTHER_DEP) $(DEBUG_LIBDSP)
	$(CC) $(DEBUG_CFLAGS) $(LDFLAGS) -o $(DEBUG_PRODUCT) $(OFILES) \
		$(OTHER_OFILES) $(DEBUG_LOADLIBES)
	$(OTHER_MAKE_PRODUCT_ACTIONS)
#	md -f -d $(OFILES:.o=.d)

$(PG_PRODUCT): $(OFILES) $(OTHER_DEP) $(PROFILE_LIBDSP)
	$(CC) $(PROFILE_CFLAGS) $(LDFLAGS) -o $(PRODUCT) $(OFILES) \
		$(OTHER_OFILES) $(PROFILE_LOADLIBES)
	$(OTHER_MAKE_PRODUCT_ACTIONS)
#	md -f -d $(OFILES:.o=.d)

help:
	if (test "$<");		\
	then echo 'ERROR: Unrecognized Makefile target "$<"';	\
	fi
	echo '  profile -  to make the program with profiling code in it';\
	echo '  debug -  to make the program with gdb symbols';\
	echo '  install-  to install the program';\
	echo "  $(NAME)-  to make the program in this directory";\
	echo '  lean-     to remove all unnecessary files';\
	echo '  clean-    to remove all files but the source';\
	echo '  print-    to print out all the source files';\
	echo '  wc-       to get the line, word, and byte cnt of the source';\
	echo '  size-     to get the size of all object files';\
	echo '  diff-     diffs current source against installed source';\
	echo '  tags-     to run ctags on the source';\
	echo '  TAGS-     to run etags on the source';\
	echo '  depend-   to update Makefile dependencies on include files';\

# removes all derived files
clean::	$(OTHER_CLEANS) lean
	-/bin/rm -f $(PRODUCT) d$(PRODUCT) $(LCLBINDIR)/$(PRODUCT)

# removes all derived files, leaving product
lean:	$(OTHER_LEANS)
	-/bin/rm -f $(OFILES) $(OTHER_OFILES) $(GARBAGE)

TAGS:
	etags $(CFILES)

#  The tags target creates an index on the source files' functions.
tags:: $(MFILES) $(CFILES) $(HFILES)
	ctags $(MFILES) $(CFILES) $(HFILES)

#  prints out all source files
print:: $(SRCS)
	$(PRINT) $(SRCS)

# shows object code size
size: $(OFILES)
	@/bin/size $(OFILES) | awk '{ print; for( i = 0; ++i <= 4;) \
	x[i] += $$i } END { print x[1] "\t" x[2] "\t" x[3] "\t" x[4] }'

# shows line count of source
wc: $(SRCS)
	wc $(SRCS)

# diffs the current sources with the installed sources
diff:
	for f in $(SRCS);				\
	    do (echo $$f;				\
	    csh -f -c "diff -c $(BIN_SOURCE_DIR)/$(NAME)/$$f $$f; exit 0")  \
	done

# creates products and installs them. Installs source also.
install:: $(BINDIR) $(PRODUCT)
	install $(IFLAGS) $(BINIFLAGS) -m 755 $(PRODUCT) $(OTHER_INSTALLS) \
                $(BINDIR)
	-mkdirs $(MANDIR)
	install -m 644 $(MANPAGE) $(MANDIR)
	$(OTHER_C_INSTALL_ACTIONS)
	
# 'make boot' installs an initial boot version
boot: $(BOOT_BIN_DIR_BIN)
	install $(IFLAGS) $(BINIFLAGS) -m 755 $(PRODUCT).boot \
		$(BOOT_BIN_DIR_BIN)
	/bin/mv -f $(BOOT_BIN_DIR_BIN)/$(PRODUCT).boot \
		   $(BOOT_BIN_DIR_BIN)/$(PRODUCT)

# creates debuggable product. Source not installed.

debug:: $(DEBUG_PRODUCT)

installhdrs::
	echo "No headers in src/bin" > /dev/null

# install the source
installsrc:: $(OTHER_INSTALLSRC_ACTIONS) $(BIN_SOURCE_DIR)/$(NAME)
	tar chf - $(INSTALLSRC_FILES) | (cd $(BIN_SOURCE_DIR)/$(NAME); tar xfp -)
#	/bin/cp -p $(INSTALLSRC_FILES) $(BIN_SOURCE_DIR)/$(NAME)
	(cd $(BIN_SOURCE_DIR)/$(NAME); chmod 644 $(INSTALLSRC_FILES))
#	install $(IFLAGS) -m 644 $(INSTALLSRC_FILES) $(BIN_SOURCE_DIR)/$(NAME)

$(LIBDSP):
	(cd ../../../src/lib ; $(MAKE) $(MAKE_FLAGS) lib)
#	(cd ../../../src/lib ; $(MAKE) $(MAKE_FLAGS) shlib)

$(DEBUG_LIBDSP):
	(cd ../../../src/lib ; $(MAKE) $(MAKE_FLAGS) debug)

.SUFFIXES: .o .c

.c.o:
	$(CC) $(CFLAGS) -c $*.c
