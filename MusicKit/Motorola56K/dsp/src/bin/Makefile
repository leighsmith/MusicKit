# Makefile for dsp/src/bin software.

NAME = bin
include ../../Makefile.config

MAKE_FILES = Makefile Makefile.c

# utilities to install in final release
PROG_DIRS = dsptest

# utilities only necessary for the build
#BUILD_PROG_DIRS = $(PROG_DIRS) fft
BUILD_PROG_DIRS = $(PROG_DIRS)

all debug install installhdrs::
	@for i in $(PROG_DIRS); do \
	(cd ./$$i; echo "$$i:"; \
	make $(MAKE_FLAGS) $@ ) || exit $? ; done

clean lean:
	@for i in $(BUILD_PROG_DIRS); do \
		(cd ./$$i; echo "$$i:"; \
		make $(MAKE_FLAGS) $@) || exit $? ; done

installsrc:: $(BIN_SOURCE_DIR)
	tar cf - $(MAKE_FILES) | (cd $(BIN_SOURCE_DIR); tar xfp -)
	(cd $(BIN_SOURCE_DIR); chmod 644 $(MAKE_FILES))
	@for i in $(BUILD_PROG_DIRS); do \
		(cd ./$$i; echo "$$i:"; \
		make $(MAKE_FLAGS) installsrc) || exit $? ; done

../../src/lib/libdsp_g.a:
	(cd ../../src/lib ; echo "../../src/lib:"; make $(MAKE_FLAGS) debug)

# HISTORY
# 02/25/89/jos - DSPMusic taken out of release
# 02/26/89/jos - dspboot, dspping, and dsptestap taken out of release
# 03/25/89/jos - man pages now mandatory
# 03/25/89/jos - dsptmq, dspmsg, dspload dsptestap out.
# 05/12/89/jos - Removed dspwrap dsploadwrap
# 05/15/89/jos - dspasm added back in, but it only installs dspasm{a,r}l
# 06/27/89/jos - dspasm, dspimg, and dspmsg moved to new "dsp/tools" directory
# 09/08/91/jos - dspabort removed from release set
# 10/03/91/jos - install and ccrma_install modified for music divestiture
# 11/20/91/jos - added dspwrap subproject
#


