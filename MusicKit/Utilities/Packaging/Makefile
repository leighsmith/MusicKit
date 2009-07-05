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
VERSION=
# To allow passing SVNREV on the command line.
SVNREV=

DISTNAME=MusicKit
SOURCEFORGE_NAME=musickit
PACKAGENAME=MK
SITE_ADMIN=leighsmith
UPLOAD_SERVER=frs.sourceforge.net

SRCDISTNAME=$(DISTNAME)-$(VERSION)
PACKAGETITLE="$(DISTNAME) V$(VERSION) applications, frameworks, tools and documentation"
# This allows us to have a different default CVSROOT
SVNURL=https://$(SOURCEFORGE_NAME).svn.sourceforge.net/svnroot/$(SOURCEFORGE_NAME)
WORKINGDIR=/tmp
RELEASESRCDIR=$(WORKINGDIR)/$(PACKAGENAME)SRC/$(SRCDISTNAME)
CHANGELOG_FILE=/tmp/$(DISTNAME)_ChangeLog.txt
# tar or gnutar
TAR=gnutar
CHGLOGGEN=svn2cl.sh

# We can't generate the MusicKit_README.pdf from the Makefile in the checkout
# source directory, since we don't actually run configure. This is
# problematic however, since that then requires us to use another
# version in a different location which may have different source.
# So we compromise and make the creation and installation of
# documentation files a necessary prerequisite for the build process, rather
# than triggering it.
# We set where the Documentation makefile build will put the README
# in order to copy it from there into the source distribution directory.
README_PDF=$(WORKINGDIR)/MKDocumentation.build/PDF/$(DISTNAME)_README.pdf

# Where to install into, for now we assume the location on the
# development machine is the same as on the target installation machine.
INSTALL_FILE_DIR=$(WORKINGDIR)/$(PACKAGENAME)Install
INSTALLROOT=/

UNAME=`uname`
OS_ACRONYM=MOX

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

BINARY_PACKAGEFILE=$(WORKINGDIR)/$(PACKAGENAME).pkg
BINARY_TARBALL=$(WORKINGDIR)/$(PACKAGENAME)-$(VERSION).b.$(OS_ACRONYM).pkg.tar
SRC_TARBALL=$(WORKINGDIR)/$(PACKAGENAME)-$(VERSION).s.tar.gz

.PHONY: all ship clean packageSources packageBinaries tag check_version

all: check_version packageSources packageBinaries

check_version:
	@if [ x_$(VERSION) = x_ ]; then echo "Usage: make VERSION=V.R.P [SVNREV=XXXX tag]"; exit 1; fi

# Upload the files to the server
# should be doing: sudo $(MAKE) -C Documentation upload DSTROOT=$(INSTALL_FILE_DIR)
# TODO should generate a temporary file:
ship: packageBinaries packageSources $(CHANGELOG_FILE)
	@echo Do these commands in sftp:
	@echo cd uploads
	@echo put $(BINARY_TARBALL)
	@echo put $(SRC_TARBALL)
	@echo quit
	sftp $(SITE_ADMIN)@$(UPLOAD_SERVER) 

packageSources: $(SRC_TARBALL)

packageBinaries: $(BINARY_TARBALL)

# Clean out anything already there.
clean:
	rm Info.plist Description.plist
	rm -r -f $(BINARY_PACKAGEFILE)
	rm $(BINARY_TARBALL)
	rm $(SRC_TARBALL)
	rm $(RELEASESRCDIR)
	sudo /bin/rm -r -f $(INSTALL_FILE_DIR)

# Tag a particular Subversion revision in the repository as a tag for release. Must have defined SVNREV
# CVS tags couldn't use periods, so we had to use V-R-P for tag names:
# CVSTAG=$(DISTNAME)_`echo $(VERSION) | tr '.' '-'`
# Subversion doesn't have that restriction, so we make it the same as the source distribution name.
tag:
	svn copy -r $(SVNREV) $(SVNURL)/trunk $(SVNURL)/tags/$(SRCDISTNAME) -m "Tagged V$(VERSION) release of $(DISTNAME)"
	@echo "Tagged revision $(SVNREV) as $(SRCDISTNAME) release of $(DISTNAME) in Subversion repository"

# just tar the file ready for transmission, no point compressing.
$(BINARY_TARBALL): $(BINARY_PACKAGEFILE)
	cd $(WORKINGDIR); \
	$(TAR) cf $@ $(PACKAGENAME).pkg
	@echo "Finished. Final package is located at $@"

# Do the packaging.
# Copy in a readable PDF version of the MusicKit_README.sgml file.
$(SRC_TARBALL): $(RELEASESRCDIR)/configure $(CHANGELOG_FILE) $(README_PDF)
	cp $(README_PDF) $(RELEASESRCDIR)
	cp $(CHANGELOG_FILE) $(RELEASESRCDIR)/Documentation
	cd $(RELEASESRCDIR)/..; \
	$(TAR) czf $(SRC_TARBALL) $(SRCDISTNAME)
	@echo "Finished. Final source package is located at $@"

# Check out the source tree. Assumes the release is already checked into the Subversion
# tags. TODO Perhaps we should check that.
$(RELEASESRCDIR)/configure.ac:
	@echo Checking out V$(VERSION) of $(DISTNAME) to $(RELEASESRCDIR)
	svn export $(SVNURL)/tags/$(SRCDISTNAME) $(RELEASESRCDIR)

# Configure the system.
$(RELEASESRCDIR)/configure: $(RELEASESRCDIR)/configure.ac
	cd $(RELEASESRCDIR); \
	autoconf

# Configure the system.
$(RELEASESRCDIR)/Makefile: $(RELEASESRCDIR)/configure
	cd $(RELEASESRCDIR); \
	sh ./configure

# Determine the previous revision of the last release automatically from the tags directory.
$(CHANGLOG_FILE): export PREVREV = `svn log --limit 1 --quiet $(SVNURL)/tags | sed -n -e 'n;s/r\([0-9]*\) .*/\1/p;q'`

# Generate a changelog file from the previous version.
$(CHANGELOG_FILE):
	# svn log -r HEAD:$(PREVREV) $(SVNURL)/trunk | sed -e '/^r/d;/^---/d' > $(CHANGELOG_FILE)
	$(CHGLOGGEN) --revision HEAD:$(PREVREV) --group-by-day --output=$(CHANGELOG_FILE)
	@echo "Change Log since $(PREVREV) generated at $(CHANGELOG_FILE)"

$(INSTALL_FILE_DIR)/Library/Frameworks/MusicKit.framework: $(RELEASESRCDIR)/Makefile
	# Remove any dynamic libraries that the Frameworks will link to
	# so they link to the static libraries instead.
	# Eventually figure out how to force static linking of these.
	sudo rm -f /usr/local/lib/{libmp3hip,libsndfile,libmp3lame,libshout,libvorbis,libogg}.*dylib
	# Remove any existing frameworks in the temporary build area
	# which would have caused relative links (@executable_path paths).
	sudo $(MAKE) -C $(RELEASESRCDIR) clean DSTROOT=$(INSTALL_FILE_DIR)
	# build the system
	sudo $(MAKE) -C $(RELEASESRCDIR) install DSTROOT=$(INSTALL_FILE_DIR) VERSION=$(VERSION)

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
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > $@
	@echo '<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $@
	@echo '<plist version="1.0">' >> $@
	@echo '<dict>' >> $@
	@echo '    <key>CFBundleGetInfoString</key>' >> $@
	@echo '    <string>$(PACKAGETITLE)</string>' >> $@
	@echo '    <key>CFBundleName</key>' >> $@
	@echo '    <string>$(PACKAGETITLE)</string>' >> $@
	@echo '    <key>CFBundleIdentifier</key>' >> $@
	@echo '    <string>org.musickit.MusicKit</string>' >> $@
	@echo '    <key>CFBundleShortVersion</key>' >> $@
	@echo '    <string>$(VERSION)</string>' >> $@
	@echo '    <key>IFMajorVersion</key>' >> $@
	@echo '    <integer>0</integer>' >> $@
	@echo '    <key>IFMinorVersion</key>' >> $@
	@echo '    <integer>0</integer>' >> $@
	@echo '    <key>IFPkgFlagAllowBackRev</key>' >> $@
	@echo '    <false/>' >> $@
	@echo '    <key>IFPkgFlagAuthorizationAction</key>' >> $@
	@echo '    <string>AdminAuthorization</string>' >> $@
	@echo '    <key>IFPkgFlagDefaultLocation</key>' >> $@
	@echo '    <string>$(INSTALLROOT)</string>' >> $@
	@echo '    <key>IFPkgFlagInstallFat</key>' >> $@
	@echo '    <false/>' >> $@
	@echo '    <key>IFPkgFlagIsRequired</key>' >> $@
	@echo '    <false/>' >> $@
	@echo '    <key>IFPkgFlagOverwritePermissions</key>' >> $@
	@echo '    <true/>' >> $@
	@echo '    <key>IFPkgFlagRelocatable</key>' >> $@
	@echo '    <true/>' >> $@
	@echo '    <key>IFPkgFlagRestartAction</key>' >> $@
	@echo '    <string>NoRestart</string>' >> $@
	@echo '    <key>IFPkgFlagRootVolumeOnly</key>' >> $@
	@echo '    <false/>' >> $@
	@echo '    <key>IFPkgFlagUpdateInstalledLanguages</key>' >> $@
	@echo '    <false/>' >> $@
	@echo '    <key>IFPkgFlagUseUserMask</key>' >> $@
	@echo '    <false/>' >> $@
	@echo '    <key>IFPkgFormatVersion</key>' >> $@
	@echo '    <real>0.10000000149011612</real>' >> $@
	@echo '</dict>' >> $@
	@echo '</plist>' >> $@

# Recent versions of installer now expect the description in a
# separate file so it can be localized.
Description.plist:
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > $@
	@echo '<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $@
	@echo '<plist version="1.0">' >> $@
	@echo '<dict>' >> $@
	@echo '    <key>IFPkgDescriptionTitle</key>' >> $@
	@echo '    <string>$(PACKAGETITLE)</string>' >> $@
	@echo '    <key>IFPkgDescriptionVersion</key>' >> $@
	@echo '    <string>$(VERSION)</string>' >> $@
	@echo '</dict>' >> $@
	@echo '</plist>' >> $@

# Now build the package
# TODO If we want the old fashioned (and safer!) way.
# PackageMaker $INSTALL_FILE_DIR Info.plist -gnutar
$(BINARY_PACKAGEFILE): $(INSTALL_FILE_DIR)/Library/Frameworks/MusicKit.framework Info.plist Description.plist
	/Developer/Tools/packagemaker -build -ds -p $@ -f $(INSTALL_FILE_DIR) -i Info.plist -d Description.plist
