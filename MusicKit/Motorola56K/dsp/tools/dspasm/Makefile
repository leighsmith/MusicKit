# 03/06/89/jos - Changed sim56000 install to INTERNAL_BIN_DIR (only if needed)
# 03/06/89/jos - Changed BOOT_BIN_DIR_BIN installs of asm56k to soft link
#		 since they are in the same directory subtree => same filesys.
# 03/11/89/jos - Added lnk56000, treated like sim56000
# 03/25/89/jos - Deleted sim56000
# 03/27/89/jos - Moved local versions from the release to boot bin dir
# 03/30/89/jos - added installing of atom version of lib56000 and lnk56000
# 04/06/89/jos - removed *56000 from INSTALL_FILES
# 06/17/89/jos - changed dspasm to mean dspasmr and flushed dspasmr and dspasma
#		 It's too easy to type "dspasm -a".
# 06/21/89/jos - removed lnk56000 from the installation
# 07/24/89/jos - removed dspasm.1 from install, added dspasm{a,r} to installsrc

# FIXME: Toss in lib56000 as asm or sim

NAME = dspasm
include ../../Makefile.config

MANPAGES = asm56000.1 lnk56000.1 lib56000.1
LOCAL_INSTALL_FILES = dspasmal dspasmrl dspasma dspasmr

install: $(MAN_DIR) $(BINDIR)
#	install $(IFLAGS) -m 644 $(MANPAGES) $(MAN_DIR)
#	install $(IFLAGS) -m 775 dspasmr $(BINDIR)/dspasm

installsrc: $(TOOL_SOURCE_DIR)/$(NAME)
	install $(IFLAGS) -m 664 Makefile $(MANPAGES) dspasma dspasmr \
		$(TOOL_SOURCE_DIR)/$(NAME)
	install $(IFLAGS) -m 775 dspasmr $(TOOL_SOURCE_DIR)/$(NAME)

all:
	echo "Make all is nop here" >/dev/null

clean lean:
	-/bin/rm -f dspasmal.local dspasmrl.local dspasmug.local

local_install: $(LCLBINDIR)
	install $(IFLAGS) -m 775 dspasma dspasmr $(LCLBINDIR)
	install $(IFLAGS) -m 775 dspasmr $(LCLBINDIR)/dspasm
	echo '#/bin/sh : For assembling relocatable unit-generator wrappers' \
			>dspasmug.local
	 	echo 'echo asm56000 $$2 $$3 $$4 $$5 -A -B -L \\' \
			>>dspasmug.local
		echo "    -I$(LOCAL_SMSRC_DIR) \\" >> dspasmug.local
		echo '     $$1' >> dspasmug.local
		echo 'asm56000 $$2 $$3 $$4 $$5 -A -B -L \\' >> dspasmug.local
		echo "    -I$(LOCAL_SMSRC_DIR) \\" >> dspasmug.local
		echo '     $$1' >> dspasmug.local
		install $(IFLAGS) -m 775 dspasmug.local $(LCLBINDIR)/dspasmug
	echo 'echo asm56000 $$2 $$3 $$4 $$5 -A -B -L -OS,SO \\' >dspasmal.local
		echo "    -I$(LOCAL_SMSRC_DIR) \\" >> dspasmal.local
		echo '     $$1' >> dspasmal.local
		echo 'asm56000 $$2 $$3 $$4 $$5 -A -B -L -OS,SO \\' \
			>> dspasmal.local
		echo "    -I$(LOCAL_SMSRC_DIR) \\" >> dspasmal.local
		echo '     $$1' >> dspasmal.local
		install $(IFLAGS) -m 775 dspasmal.local $(LCLBINDIR)/dspasmal
	echo 'echo asm56000 $$2 $$3 $$4 $$5 -B -L \\' > dspasmrl.local
		echo "    -I$(LOCAL_SMSRC_DIR) \\" >> dspasmrl.local
		echo '     $$1' >> dspasmrl.local
		echo 'asm56000 $$2 $$3 $$4 $$5 -b -l \\' >> dspasmrl.local
		echo "    -I$(LOCAL_SMSRC_DIR) \\" >> dspasmrl.local
		echo '     $$1' >> dspasmrl.local
	install $(IFLAGS) -m 775 dspasmrl.local $(LCLBINDIR)/dspasmrl
	install $(IFLAGS) -m 775 dspasmrl.local $(LCLBINDIR)/dspasml
