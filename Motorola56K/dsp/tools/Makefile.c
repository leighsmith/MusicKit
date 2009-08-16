# Generic makefile for C tools.  A "tool" in this context is
# any program needed to build dsp/smsrc.
#
# To use this makefile, just create a makefile in a subdirectory of
# this one containing
#
# NAME = <progname>
# include <this makefile>
#
# There are various "OTHER_*" variables used below which can be
# used to extend the make possibilities.
#
PRODUCT = $(NAME)
MANPAGE = $(NAME).1
include ../../Makefile.config
LOCAL_BIN_DIR = ../../smsrc

# Note: The following could be a much smaller subset of libdsp.a.
# We only need _DSPUtilities.c, DSPReadFile.c, and a few giblets.
LIBDSPDIR = ../../src/lib
LIBDSP = $(LIBDSPDIR)/libdsp.a

CFILES = $(NAME).c $(OTHER_CFILES)
LOADLIBES = $(OTHER_LIBS) -ldsp -lsys_s -lDriver

CFLAGS = -g -O -I$(LIBDSPDIR) $(RC_CFLAGS) $(OTHER_CFLAGS)
LDFLAGS = -L$(LIBDSPDIR) $(OTHER_LDFLAGS)

OFILES = $(CFILES:.c=.o)

GARBAGE = $(BY_PRODUCTS) TAGS tags core $(OTHER_GARBAGE)

SRCS = $(HFILES) $(MFILES) $(CFILES)

INSTALLSRC_FILES = Makefile $(MANPAGE) $(MANPAGE).check $(OTHER_MANPAGES) $(SRCS) \
		$(OTHER_INSTALL_SOURCE)

all: $(PRODUCT)

$(OFILES): $(CFILES)
	$(CC) $(CFLAGS) -c $*.c

$(PRODUCT): $(OFILES) $(LIBDSP)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(PRODUCT) $(OFILES) \
		$(OTHER_OFILES) $(LOADLIBES) $(OTHER_LIBS)

local_install:: $(LOCAL_BIN_DIR)/$(PRODUCT)

$(LOCAL_BIN_DIR)/$(PRODUCT): $(LOCAL_BIN_DIR) $(PRODUCT)
	install $(IFLAGS) -m 755 $(PRODUCT) $(LOCAL_BIN_DIR)/$(PRODUCT)

$(LOCAL_BIN_DIR):
	mkdirs -m 755 $(LOCAL_BIN_DIR)

#
# To break the dependency loop on libdsp, we install tool binaries with the
# source.  The tools are built as part of the installsrc procedure.
# We thus assume that the install-target machine is binary compatible 
# with the installsrc source machine.
#
installsrc: $(TOOL_SOURCE_DIR)/$(NAME) $(PRODUCT)
	if cmp $(MANPAGE) $(MANPAGE).check; \
	then echo "$(MANPAGE) is in sync"; \
	else echo "*** $(MANPAGE) is out of sync"; exit -1; \
	fi
	tar chf - $(INSTALLSRC_FILES) $(PRODUCT) | \
		(cd $(TOOL_SOURCE_DIR)/$(NAME); tar xfp -)
	(cd $(TOOL_SOURCE_DIR)/$(NAME); chmod 644 $(INSTALLSRC_FILES))
	(cd $(TOOL_SOURCE_DIR)/$(NAME); chmod 755 $(PRODUCT))

#	install $(IFLAGS) -m 644 $(INSTALLSRC_FILES) $(TOOL_SOURCE_DIR)/$(NAME)

install:: $(BINDIR) $(PRODUCT)
	install $(IFLAGS) $(BINIFLAGS) -m 755 $(PRODUCT) $(OTHER_INSTALLS) \
		$(BINDIR)

#install: $(BINDIR) $(PRODUCT) $(MAN_DIR)
#	install $(IFLAGS) -m 644 $(MANPAGE) $(OTHER_MANPAGES) $(MAN_DIR)

clean:	lean
	-/bin/rm -f $(PRODUCT)

lean:	$(OTHER_LEANS)
	-/bin/rm -f $(OFILES) $(OTHER_OFILES) $(GARBAGE)

$(LIBDSP):
	(cd ../../src/lib; make local_install)

ARCHS=m68k i386
ARCHIFY = /usr/lib/arch_tool -archify_list
arch_flags=`$(ARCHIFY) $(ARCHS)`

fat_install:
	make $(MF) install DSTROOT=$(DSTROOT) "RC_CFLAGS = $(arch_flags)"

