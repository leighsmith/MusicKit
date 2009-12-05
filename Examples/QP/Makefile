QP_DIRS = QuintClusters playscorefile-qp

SOURCES = Makefile README $(QP_DIRS)

clean::
	-@for i in $(QP_DIRS); do \
		(cd ./$$i; echo "$$i:"; \
		make $(MAKE_FLAGS) $@) || exit $? ; done

installsrc:: $(SRCROOT)
	tar cf - $(SOURCES) | (cd $(SRCROOT); tar xfp -)
	(cd $(SRCROOT); chmod -R 644 $(SOURCES))
	@for i in $(TAR_DIRS); do \
		(cd ./$$i; echo "$$i:"; \
		make $(MAKE_FLAGS) installsrc SRCROOT=$(SRCROOT)/$$i) \
			|| exit $? ; done

install:: $(INSTALL_DIR)
	tar cf - $(SOURCES) | (cd $(INSTALL_DIR); tar xfp -)
	-/bin/rm -f $(INSTALL_DIR)/Makefile
	-chmod -R go-w $(INSTALL_DIR)
	-chmod -R ugo+r $(INSTALL_DIR)

$(SRCROOT):
	-mkdirs $(SRCROOT)


$(INSTALL_DIR):
	-mkdirs $(INSTALL_DIR)

