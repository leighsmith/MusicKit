# Modifcation history
# DAJ/Oct 3, 93 - Added SCOREInspector

DIRS = . scorefiles inspector

all local_install clean lean debug installsrc install profile fat_install fat_debug_install:
	@for i in $(DIRS); do \
		(cd ./$$i; echo "$$i:"; \
		make -f Makefile $(MAKE_FLAGS) $@) || exit $? ; done
	
installhdrs:
	echo 'No headers to install for scorefiles project' >/dev/null

	


