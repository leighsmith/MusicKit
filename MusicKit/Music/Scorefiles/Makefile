# daj - apr 21,90 - Added Examp8.score
# DAJ - Aug 9 90 - Note: If you add a .playscore, you must also add it to 
#             ../scorefiles_user.bom. It would be better if the .bom file 
#              could be generated automatically here, but I don't have time 
#              to mess with it. 
# DAJ - Aug 20, 89 - Removed BachFugue from the release because of driver bug
#              Also removed it from user.bom.  
# DAJ - Aug 23, 89 - Added BachFugue again
#              Also added it to user.bom.  
# JOS - Jul 29, 92 - Changed installation directory to LocalLibrary/CCRMA
#		     This is to avoid clobbering net-shared 2.1 versions.
#		     Note that 3.0 .playscore files do not play under 2.1.
# DAJ - Oct 19, 92 - Changed installation dir back to LocalLibrary.
#                    Added Examp9 and Examp10.  Changed to only install 
#                    BachFugue.playscore
# DAJ - Sept. 25, 93 - Added Examp11.
NAME = score

SCORE_DIR = ${DSTROOT}/LocalLibrary/Music/Scores
SCORE_SRC_DIR = ${SRCROOT}/scorefiles

IFLAGS = -q -c

all:
	echo 'nothing to be remade' >/dev/null

SCORE_FILES = BachFugue.score
SCOREONLY_FILES = Examp1.score Examp2.score Examp3.score Examp4.score\
	Examp5.score \
	Examp6.score Examp7.score Emma.score Gamelan.score \
	Jungle.score Twilight.score Suntan.score \
	BeadGame.score Throb.score WTC1.score Examp8.score Examp9.score Examp10.score \
	Examp11.score
PLAYSCORE_FILES = $(SCORE_FILES:.score=.playscore)

INSTALL_FILES = $(SCORE_FILES) $(PLAYSCORE_FILES) $(SCOREONLY_FILES)

$(SCORE_DIR): foobarFOOBARfoobar
	mkdirs -m 755 $@

$(SCORE_SRC_DIR): foobarFOOBARfoobarFOOBAR
	mkdirs -m 755 $@

install: $(SCORE_DIR)
	install $(IFLAGS) -m 644 $(INSTALL_FILES) $(SCORE_DIR)

installsrc: $(SCORE_SRC_DIR)
	tar cf - Makefile $(INSTALL_FILES) | (cd $(SCORE_SRC_DIR); tar xf -)
	chmod 644 $(SCORE_SRC_DIR)/*

clean:
	echo 'nothing to be cleaned' >/dev/null


foobarFOOBARfoobar:

foobarFOOBARfoobarFOOBAR:

ARCHS=m68k i386
ARCHIFY = /usr/lib/arch_tool -archify_list
arch_flags=`$(ARCHIFY) $(ARCHS)`

fat_install:
	make $(MF) install DSTROOT=$(DSTROOT) "RC_CFLAGS = $(arch_flags)"

fat_debug_install:
	make $(MF) debug_install DSTROOT=$(DSTROOT) "RC_CFLAGS = $(arch_flags)"
