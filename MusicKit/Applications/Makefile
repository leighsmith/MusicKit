# modification history:
#   daj/aug 10 90/ changed ScorePlayer-11 to ScorePlayer-12 for musicdemos-6
#   mmm/aug 15 90/ added Ensemble-16
#
#   daj/aug 23 90/ changed ScorePlayer-13 to ScorePlayer-14 for musicdemos-6
#   daj/aug 23 90/ changed SoundPlayer-5 to SoundPlayer-6 for musicdemos-11
#   mtm/sep 19 90/ changed SoundPlayer-6 to SoundPlayer-7 for musicdemos-12
#   daj/sep 26 90/ Added BOMFILE
#   daj/Oct 11 90/ changed ScorePlayer-14 to ScorePlayer-15 for musicdemos-12
#   mmm/Oct 11 90/ replaced Ensemble-16 with Ensemble-18 for musicdemos-12
#   daj/Oct 15 90/ replaced Ensemble-18 with Ensemble-19 for musicdemos-13
#   mmm/Oct 22 90/ replaced Ensemble-19 with Ensemble-21 for musicdemos-14
#   mmm/Oct 22 90/ replaced SoundPlayer-7 with SoundPlayer-7.1 for musicdemos-14
#   mmm/Oct 22 90/ replaced Ensemble-21 with Ensemble-21.1 for musicdemos-14.1
#   mmm/Oct 29 90/ replaced Ensemble-21.1 with Ensemble-21.2 for musicdemos-14.2
#   daj/Jan 25 91/ replaced ScorePlayer-15-Interactive with ScorePlayer-16
#   for musicdemos-15
#   daj/Aug 30 91/ replaced ScorePlayer-16 with ScorePlayer-18
#   for musicdemos-16
#   jos/May 23 92/ replaced ScorePlayer-18 with ScorePlayer-19
#   		and incremented to SoundPlayer-7.3, Ensemble-23.1
#   for musicdemos-19
#   daj/Jun 2 92/ removed BOMFILE and SoundPlayer
#   daj/Jun 6 92/ changed name of project to musicapps
#   daj/Oct 3 92/ changed install dir to /LocalApps. Flushed README
#   daj/Oct 22 92/ changed ScorePlayer to SP to prevent name overflow (.pkg)
#   daj/Oct 22 92/ changed SP-19 to SP-20
#   daj/Oct 23 93/ Removed SRCROOT from install and clean.
#   jos/Oct 25 94/ Moved E to separate project

PROJECTS = MusicKitPrefs.bproj SP WE # E 

clean all:
	for i in `echo ${PROJECTS}`; \
	do \
	  echo ================= make $@ for $$i =================; \
	  (cd $$i; $(MAKE) $@ DSTROOT=$(DSTROOT) );  \
	done

INSTALL_DIR = $(DSTROOT)/LocalApps

install:
	mkdirs $(INSTALL_DIR)
	chmod 777 $(INSTALL_DIR)
	for i in `echo ${PROJECTS}`; \
	do \
	echo ================= make $@ for $$i =================; \
	(cd $$i; $(MAKE) $(MAKE_FLAGS) $@ DSTROOT=$(DSTROOT) "RC_CFLAGS= $(RC_CFLAGS)" );  \
	done
        
installsrc:
	for i in `echo ${PROJECTS}`; \
	do \
	echo ================= make $@ for $$i =================; \
	(cd $$i; $(MAKE) SRCROOT=$(SRCROOT)/$$i $@);  \
	done
	tar cf - Makefile | (cd $(SRCROOT); tar xfp -) 
	(cd $(SRCROOT); chmod 644 Makefile)


installhdrs:
	echo 'No headers to install for Music Apps' >/dev/null

ARCHS=m68k i386
ARCHIFY = /usr/lib/arch_tool -archify_list
arch_flags=`$(ARCHIFY) $(ARCHS)`

fat_install:
	make $(MF) install DSTROOT=$(DSTROOT) "RC_CFLAGS = $(arch_flags)"

fat_debug_install:
	make $(MF) debug_install DSTROOT=$(DSTROOT) "RC_CFLAGS = $(arch_flags)"
