# Master Makefile for DSP software

NAME = dsp

include Makefile.config

MAKE_FILES = Makefile Makefile.config Makefile.asm

CCRMA_DIRS = drivers src tools smsrc ugsrc test
# CCRMA_DIRS = src tools smsrc ugsrc test

DIRS = $(CCRMA_DIRS)

first: all

installhdrs::
	(cd ./src/lib; make $(MAKE_FLAGS) $@) || exit $?

all local_install lean::
	@for i in $(DIRS); do \
	(cd ./$$i; echo "$$i:"; make $(MAKE_FLAGS) $@ ) || exit $? ; done

BOM_DIR=${DSTROOT}/usr/local/BOMs

MAKEDIR = $(OBJROOT)
DOT = .

INSTALLSRC_SRCS = $(MAKE_FILES) README DSP.rtf dsp.user_bom
INSTALLSRC_BINARIES = testinstall testinstallsrc

installsrc:: $(SOURCE_DIR)
	tar cf - $(INSTALLSRC_SRCS) | (cd $(SOURCE_DIR); tar xfp -)
	(cd $(SOURCE_DIR); chmod 644 $(INSTALLSRC_SRCS))
	tar cf - $(INSTALLSRC_BINARIES) | (cd $(SOURCE_DIR); tar xfp -)
	(cd $(SOURCE_DIR); chmod 755 $(INSTALLSRC_BINARIES))
	@for i in $(DIRS); do \
		(cd ./$$i; echo "$$i:"; \
		make $(MAKE_FLAGS) $@) || exit $? ; done
	(cd $(SOURCE_DIR); ls -algR > SOURCE_BOM)

install:: $(RELNOTES_DIR)
	install $(IFLAGS) -m 664 DSP.rtf $(RELNOTES_DIR)
	@for i in $(DIRS); do \
	(cd $(DOT)/$$i; echo "$$i:"; \
	make $(MAKE_FLAGS) install) || exit $? ; done

clean::
	@for i in $(DIRS); do \
		(cd ./$$i; echo "$$i:"; \
		make $(MAKE_FLAGS) $@) || exit $? ; done

