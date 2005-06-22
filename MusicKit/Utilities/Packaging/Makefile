#
# $Id$
#
# Makefile to automate the packaging of sources and binaries of the 
# MusicKit frameworks, applications, commands and libraries ready for
# user deployment and then automates the secure uploading of the
# package and README tarballs to the sourceforge website.
#
#
# Binary packaging originally taken from an article on Stepwise:
# http://www.stepwise.com/Articles/Technical/Packages/BuildingAPackage.html
#
# Leigh Smith <leigh@leighsmith.com> 1999/11/29
#

# The version number as V.R.P to release under.
RELEASE=
DISTNAME=MusicKit
PACKAGENAME=MK
PACKAGETITLE=$(DISTNAME) V$(RELEASE) applications, frameworks, tools and documentation
# This allows us to have a different default CVSROOT
PACKAGECVSROOT=:ext:leighsmith@cvs.sourceforge.net:/cvsroot/musickit
WORKINGDIR=/tmp
RELEASESRCDIR=$(WORKINGDIR)/MKSRC

# Where to install into, for now we assume the location on the
# development machine is the same as on the target installation machine.
INSTALL_FILE_DIR=$(WORKINGDIR)/$(PACKAGENAME)Install
INSTALLROOT=/

SITEUSER=leighsmith
UPLOAD_SERVER=upload.sourceforge.net
DOC_TARBALL_PATH=$(WORKINGDIR)/MKDocumentation.build/
DOC_TARBALL=MusicKitREADME.tar.bz2
DOC_SITE=musickit.sourceforge.net
DOC_SITEHTMLDIR=/home/groups/m/mu/musickit

# case `uname` in
#     "Darwin")
# 	OS_ACRONYM=MOX
# 	;;
#     "Rhapsody")
# 	OS_ACRONYM=MOXS
# 	;;
#     *)
# 	echo "Error: unsupported operating system `uname`"
# 	exit 1;
# 	;;
# esac

UNAME=`uname`
OS_ACRONYM=MOX

# if [ x_$(RELEASE) = x_ ]; then echo "Usage: make RELEASE=V.R.P"; exit 1; fi

PACKAGEFILE=$(WORKINGDIR)/$(PACKAGENAME).pkg
BINARY_TARBALL=$(PACKAGENAME)-$(RELEASE).b.$(OS_ACRONYM).pkg.tar
SRC_TARBALL=$(PACKAGENAME)-$(RELEASE).s.tar.gz
CVSTAG=$(DISTNAME)_`echo $(RELEASE) | tr '.' '-'`

all: packageBinaries packageSources

# Upload the files to the server
ship: packageBinaries packageSources
	scp $(DOC_TARBALL_PATH)/$(DOC_TARBALL) $(SITEUSER)@$(DOC_SITE):$(DOC_TARBALL)
	ssh -l $(SITEUSER) $(DOC_SITE) "cd $(DOC_SITEHTMLDIR); tar xjf ~/$(DOC_TARBALL)"
	ftp -u ftp://anonymous:$(SITEUSER)@$(UPLOAD_SERVER)/incoming/$(BINARY_TARBALL) $(WORKINGDIR)/$(BINARY_TARBALL)
	ftp -u ftp://anonymous:$(SITEUSER)@$(UPLOAD_SERVER)/incoming/$(SRC_TARBALL) $(SRC_TARBALL_PATH)/$(SRC_TARBALL)

packageSources:

packageBinaries: $(WORKINGDIR)/$(BINARY_TARBALL)

# Clean out anything already there.
clean:
	rm Info.plist Description.plist
	rm -r -f $(PACKAGEFILE)
	sudo /bin/rm -r -f $(INSTALL_FILE_DIR)

# just tar the file ready for transmission, no point compressing.
$(WORKINGDIR)/$(BINARY_TARBALL): $(PACKAGEFILE)
	cd $(WORKINGDIR); \
	tar cf $@ $(PACKAGENAME).pkg
	@echo "Finished. Final package is located at $@"

# Check out the source tree
$(RELEASESRCDIR)/$(DISTNAME)/configure.ac:
	@echo Checking out $(CVSTAG) to $(RELEASESRCDIR)
	mkdir -p $(RELEASESRCDIR)
	cd $(RELEASESRCDIR); \
	cvs -d $(PACKAGECVSROOT) -Q checkout -r $(CVSTAG) $(DISTNAME)

# Configure the system.
$(RELEASESRCDIR)/$(DISTNAME)/configure: $(RELEASESRCDIR)/$(DISTNAME)/configure.ac
	cd $(RELEASESRCDIR)/$(DISTNAME); \
	autoconf

# Configure the system.
$(RELEASESRCDIR)/$(DISTNAME)/Makefile: $(RELEASESRCDIR)/$(DISTNAME)/configure
	cd $(RELEASESRCDIR)/$(DISTNAME); \
	sh ./configure

$(INSTALL_FILE_DIR)/Library/Frameworks/MusicKit.framework: $(RELEASESRCDIR)/$(DISTNAME)/Makefile
	# Remove any dynamic libraries that the Frameworks will link to
	# so they link to the static libraries instead.
	# Eventually figure out how to force static linking of these.
	sudo rm -f /usr/local/lib/{libmp3hip,libsndfile,libmp3lame,libshout,libvorbis,libogg}.*dylib
	# Remove any existing frameworks in the temporary build area
	# which would have caused relative links (@executable_path paths).
	sudo $(MAKE) -C $(RELEASESRCDIR)/$(DISTNAME) clean DSTROOT=$(INSTALL_FILE_DIR)
	# build the system
	sudo $(MAKE) -C $(RELEASESRCDIR)/$(DISTNAME) install DSTROOT=$(INSTALL_FILE_DIR) VERSION=$(RELEASE)

# This is the point where you'll want to make sure that the
# permissions and ownership of the files and directories in your
# application are set to the appropriate values. The goal is to set
# all the files to the user-id that you'd expect when they are
# installed by the root user, in most cases you'll want to set the
# ownership to root. Installations by those other than root will
# correctly default to the installer's user-id. The situation with
# respect to permissions is much simpler, since they'll be consistent
# regardless of which user does the installation. To accomplish this,
# you'll need to be logged in as root.
#
# we make the INSTALL_FILE_DIR user writable otherwise the installer
# will set the parent directory the application is stored into read-only which
# stops a second reinstall.
#
# sudo /bin/chmod -R ugo+rX $INSTALL_FILE_DIR/
# sudo /bin/chmod -R u+w $INSTALL_FILE_DIR/
#
$(INSTALL_FILE_DIR):
	sudo /bin/chmod -R 750 $(INSTALL_FILE_DIR)/
	# Change ownership to root.wheel
	sudo /usr/sbin/chown -R root:wheel $(INSTALL_FILE_DIR)/

#  The .info file is in a basic key/value format. The keys that are
#  commonly used are defined below, a more complete list of keys is
#  available in the Yellow Box release notes
#  (file:/System/Documentation/Developer/YellowBox/ReleaseNotes/CreatingPackages.html).
#
#  The Title, Version and Description keys are the values displayed in
#  the Installer.app user interface. All are single line strings,
#  including Description.
#
#  The DefaultLocation key is the destination directory where the
#  contents of the package will be installed. This can be changed by
#  the user if the Relocatable key is set to YES.
#
#  Some packages should only be installed as root, and those packages
#  will have NeedsAuthorization set to YES. If there is no requirement
#  to be root, you can set this key to NO.
#
#  If the package is an application, set the Application key to YES,
#  otherwise to No. If you do not want your package contents to be
#  deletable from Installer.app, set InstallOnly to YES. Finally, in
#  most cases, you will want to allow the installation of a package to
#  be stopped during the process. There are cases where that may not
#  be wise (if your application has a packageName.pre_install script
#  for example), and in those cases you'll want to set the DisableStop
#  to YES, otherwise it should be set to NO.
#
Info.plist:
	echo '<?xml version="1.0" encoding="UTF-8"?>' > $@
	echo '<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $@
	echo '<plist version="1.0">' >> $@
	echo '<dict>' >> $@
	echo '    <key>CFBundleGetInfoString</key>' >> $@
	echo '    <string>$(PACKAGETITLE)</string>' >> $@
	echo '    <key>CFBundleName</key>' >> $@
	echo '    <string>$(PACKAGETITLE)</string>' >> $@
	echo '    <key>CFBundleIdentifier</key>' >> $@
	echo '    <string>org.musickit.MusicKit</string>' >> $@
	echo '    <key>CFBundleShortVersion</key>' >> $@
	echo '    <string>$(RELEASE)</string>' >> $@
	echo '    <key>IFMajorVersion</key>' >> $@
	echo '    <integer>0</integer>' >> $@
	echo '    <key>IFMinorVersion</key>' >> $@
	echo '    <integer>0</integer>' >> $@
	echo '    <key>IFPkgFlagAllowBackRev</key>' >> $@
	echo '    <false/>' >> $@
	echo '    <key>IFPkgFlagAuthorizationAction</key>' >> $@
	echo '    <string>AdminAuthorization</string>' >> $@
	echo '    <key>IFPkgFlagDefaultLocation</key>' >> $@
	echo '    <string>$(INSTALLROOT)</string>' >> $@
	echo '    <key>IFPkgFlagInstallFat</key>' >> $@
	echo '    <false/>' >> $@
	echo '    <key>IFPkgFlagIsRequired</key>' >> $@
	echo '    <false/>' >> $@
	echo '    <key>IFPkgFlagOverwritePermissions</key>' >> $@
	echo '    <true/>' >> $@
	echo '    <key>IFPkgFlagRelocatable</key>' >> $@
	echo '    <true/>' >> $@
	echo '    <key>IFPkgFlagRestartAction</key>' >> $@
	echo '    <string>NoRestart</string>' >> $@
	echo '    <key>IFPkgFlagRootVolumeOnly</key>' >> $@
	echo '    <false/>' >> $@
	echo '    <key>IFPkgFlagUpdateInstalledLanguages</key>' >> $@
	echo '    <false/>' >> $@
	echo '    <key>IFPkgFlagUseUserMask</key>' >> $@
	echo '    <false/>' >> $@
	echo '    <key>IFPkgFormatVersion</key>' >> $@
	echo '    <real>0.10000000149011612</real>' >> $@
	echo '</dict>' >> $@
	echo '</plist>' >> $@

# Recent versions of installer now expect the description in a
# separate file so it can be localized.
Description.plist:
	echo '<?xml version="1.0" encoding="UTF-8"?>' > $@
	echo '<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $@
	echo '<plist version="1.0">' >> $@
	echo '<dict>' >> $@
	echo '    <key>IFPkgDescriptionTitle</key>' >> $@
	echo '    <string>$(PACKAGETITLE)</string>' >> $@
	echo '    <key>IFPkgDescriptionVersion</key>' >> $@
	echo '    <string>$(RELEASE)</string>' >> $@
	echo '</dict>' >> $@
	echo '</plist>' >> $@

# Now build the package
# TODO If we want the old fashioned (and safer!) way.
# PackageMaker $INSTALL_FILE_DIR Info.plist -gnutar
$(PACKAGEFILE): $(INSTALL_FILE_DIR)/Library/Frameworks/MusicKit.framework Info.plist Description.plist
	/Developer/Tools/packagemaker -build -ds -p $@ -f $(INSTALL_FILE_DIR) -i Info.plist -d Description.plist
