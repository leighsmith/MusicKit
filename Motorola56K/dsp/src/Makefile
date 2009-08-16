# Makefile for DSP C software
#
# DEPENDENCIES
#
# lib   requires ../smsrc to have been made
# bin   requires lib to have been made
#
NAME = src
include ../Makefile.config

MAKE_FILES = Makefile

DIRS = lib bin

all debug install clean lean installhdrs::
	@for i in $(DIRS); do \
	(cd ./$$i; echo "$$i:"; \
	make $(MAKE_FLAGS) $@ ) || exit $? ; done

INSTALLSRC_SRCS = $(MAKE_FILES)

installsrc:: $(SOURCE_DIR)/$(NAME)
	tar cf - $(INSTALLSRC_SRCS) | (cd $(SOURCE_DIR)/$(NAME); tar xfp -)
	(cd $(SOURCE_DIR)/$(NAME); chmod 644 $(INSTALLSRC_SRCS))
	@for i in $(DIRS); do \
		(cd ./$$i; echo "$$i:"; \
		make $(MAKE_FLAGS) $@) || exit $? ; done


