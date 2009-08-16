# Makefile for dsp/tools software.
#
# 06/27/89/jos - created from dsp/src/bin files
#

NAME = tools
include ../Makefile.config

MAKE_FILES = Makefile Makefile.c

# PROG_DIRS = dspimg dspmsg dspasm
PROG_DIRS = dspimg dspmsg

all install local_install::
	@for i in $(PROG_DIRS); do \
		(cd ./$$i; echo "$$i:"; \
		make $(MAKE_FLAGS) $@ ) || exit $? ; done

clean lean:
	@for i in $(PROG_DIRS); do \
		(cd ./$$i; echo "$$i:"; \
		make $(MAKE_FLAGS) $@) || exit $? ; done

installsrc: $(TOOL_SOURCE_DIR)
	tar cf - $(MAKE_FILES) | (cd $(TOOL_SOURCE_DIR); tar xfp -)
	(cd $(TOOL_SOURCE_DIR); chmod 644 $(MAKE_FILES))
	@for i in $(PROG_DIRS); do \
		(cd ./$$i; echo "$$i:"; \
		make $(MAKE_FLAGS) installsrc) || exit $? ; done
