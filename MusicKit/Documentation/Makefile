# Doc Makefile -- Just installs documentation

INSTALL_DIR = $(DSTROOT)/LocalLibrary/Documentation

installhdrs:
	echo 'No headers to install for Doc' >/dev/null

clean:
	echo 'Nothing to clean for Doc' >/dev/null

installsrc:: $(SRCROOT)
	tar cf - . | (cd $(SRCROOT); tar xfp -)
	-chmod -R go-w $(SRCROOT)
	-chmod -R ugo+r $(SRCROOT)

install::
	mkdirs $(INSTALL_DIR)
	tar cf - DSP | (cd $(INSTALL_DIR); tar xfp -)
	tar cf - MusicKit | (cd $(INSTALL_DIR); tar xfp -)
	cp DocIntroduction.rtf $(INSTALL_DIR)/MusicKit
	-chmod -R go-w $(INSTALL_DIR)
	-chmod -R ugo+r $(INSTALL_DIR)

$(SRCROOT):
	-mkdirs $(SRCROOT)
	chmod 755 $(SRCROOT)

framemif:
	echo 'Sorry.  This cannot be automated.'
	echo 'Each .frame document must be opened in FrameMaker and saved'
	echo 'as a .framemif file (maker interchange format).'

rtf: .ALWAYS
#	-csh make_rtf 2.0_SndMusicDSP
	mkdirs rtf
	(root=`pwd`; find . \( -name "*.rtfd" -o -name "*.rtf" \) \
		! -name "TXT.rtf" \
		-print -exec cp -r {} $$root/rtf \; )

.ALWAYS:
