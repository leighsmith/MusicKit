#	Makefile for Music Kit programming examples.
#	Copyright NeXT, Inc., JOS
#
#	This project must FOLLOW musicapps because it pulls Ensemble from
#	that project.
#
#	You can copy all of the examples to your home directory by
#	cd'ing in a Shell or Terminal to this directory and typing
#
#	make installsrc SRCROOT=$HOME/mk_examples
#
#	where $HOME is assumed to expand to your home directory.
#	Then you can make them all by cd'ing to ~/mk_examples and typing
#
#	make all
#
INSTALL_DIR0 = $(DSTROOT)/LocalDeveloper/Examples
INSTALL_DIR = $(INSTALL_DIR0)/MusicKit

TAR_DIRS = \
	MidiEcho MidiLoop MidiPlay MidiRecord PerformerExample PlayNote \
	playpart playscorefile playscorefile2 playscorefilemidi \
	SineGen exampsynthpatch exampunitgenerator \
	mixscorefiles mixsounds process_soundfiles_dsp ResonSound \
	QP

SOURCES = Makefile README .dir.tiff $(TAR_DIRS)

all clean lean::
	-@for i in $(TAR_DIRS); do \
		(cd ./$$i; echo "$$i:"; \
		make $(MAKE_FLAGS) $@) || exit $? ; done

installsrc:: $(SRCROOT)
	tar cf - $(SOURCES) | (cd $(SRCROOT); tar xfp -)
	(cd $(SRCROOT); chmod -R 644 $(SOURCES))
	@for i in $(TAR_DIRS); do \
		(cd ./$$i; echo "$$i:"; \
		make $(MAKE_FLAGS) installsrc SRCROOT=$(SRCROOT)/$$i) \
			|| exit $? ; done

# install = installsrc with SRCROOT <- INSTALL_DIR:
install:: $(INSTALL_DIR)
	(cd ../synthpatches; \
		make installsrc SRCROOT=$(INSTALL_DIR)/libsynthpatches)
	tar cf - $(SOURCES) | (cd $(INSTALL_DIR); tar xfp -)
	-/bin/rm -f $(INSTALL_DIR)/Makefile
	-chmod -R go-w $(INSTALL_DIR)
	-chmod -R ugo+r $(INSTALL_DIR)
	/bin/cp .dir.tiff $(INSTALL_DIR0)

#	(cd ../apps/E; \
#		make installsrc SRCROOT=$(INSTALL_DIR)/Ensemble)
#	(cd $(INSTALL_DIR); \
#		tar -cf Ensemble.tar Ensemble; \
#		rm -Rf Ensemble)

installhdrs:
	echo 'No headers to install for Music Examples' >/dev/null

$(SRCROOT):
	-mkdirs $(SRCROOT)


$(INSTALL_DIR):
	-mkdirs $(INSTALL_DIR)
