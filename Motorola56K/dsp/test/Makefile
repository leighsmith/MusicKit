NAME = test
default_make_target: all_examples
include ../Makefile.config

ASM_FILES = mk_ex1.asm mk_ex2.asm mk_ex3.asm config_standalone.asm
SHELL_SCRIPTS = dspasm dspasml

clean::  lean

lean:
	-/bin/rm -f *.lod *.lst *.lnk *.log
	-/bin/rm -f outy.io htx.io dspmsgs.io .tmpcor.tmp ts.cmd

all local_install::
	echo 'nothing to do (programming examples)' > /dev/null

all_examples:
	./dspasm mk_ex1
	./dspasm mk_ex2
	./dspasm mk_ex3

installhdrs::
	echo "No headers in test" > /dev/null

installsrc:: $(SOURCE_DIR)/$(NAME)
	tar cf - Makefile README $(ASM_FILES) $(SHELL_SCRIPTS) | \
		(cd $(SOURCE_DIR)/$(NAME); tar xfp -)

ccrma_install:: $(CCRMA_DSP_INSTALL_ROOT)/$(NAME)
	install $(IFLAGS) -m 644 README $(ASM_FILES) \
				$(CCRMA_DSP_INSTALL_ROOT)/$(NAME)
	install $(IFLAGS) -m 755 $(SHELL_SCRIPTS) $(CCRMA_DSP_INSTALL_ROOT)/$(NAME)

install:: $(DSP_INSTALL_ROOT)/$(NAME)
	install $(IFLAGS) -m 644 README $(ASM_FILES) \
				$(DSP_INSTALL_ROOT)/$(NAME)
	install $(IFLAGS) -m 755 $(SHELL_SCRIPTS) $(DSP_INSTALL_ROOT)/$(NAME)


