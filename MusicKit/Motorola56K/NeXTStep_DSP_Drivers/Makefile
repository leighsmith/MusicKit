# Makefile for DSP Drivers
#
NAME = drivers
INSTALLSRC_SRCS = Makefile
# DSPMKDriver must be first in list
DIRS = DSPMKDriver TurtleBeachFiji TurtleBeachMS ArielPC56D Ilinki56


all debug install clean lean installhdrs::
	@for i in $(DIRS); do \
	(cd ./$$i; echo "$$i:"; \
	echo "/bin/make $(MAKE_FLAGS) $@ " ; \
	/bin/make $(MAKE_FLAGS) $@ ) || exit $? ; done

installsrc:: $(SOURCE_DIR)/$(NAME)
	tar cf - $(INSTALLSRC_SRCS) | (cd $(SOURCE_DIR)/$(NAME); tar xfp -)
	(cd $(SOURCE_DIR)/$(NAME); chmod 644 $(INSTALLSRC_SRCS))
	@for i in $(DIRS); do \
		(cd ./$$i; echo "$$i:"; \
		/bin/make $(MAKE_FLAGS) $@) || exit $? ; done


