# Dsp driver Makefile

NAME=DSPMKDriver

# Files
CFILES= dspdriverAccess.c
HFILES= dspdriverAccess.h
SOURCEFILES= Makefile $(CFILES) ${HFILES}

all install: exports

installhdrs:
	@echo No headers to install

installsrc: SRCROOT $(SRCROOT) 
	tar cf - $(SOURCEFILES) | (cd $(SRCROOT); tar xpf -)

clean:
	-rm -rf *.o dspdriverUser.c dspdriverServer.c dspdriver.h dspdriverdebug
	
dspdriverAccess.c: dspdriverUser.c

dspdriverServer.c dspdriverUser.c dspdriver.h:  dspdriver.defs
	mig $(MIGFLAGS) -server dspdriverServer.c \
		-header dspdriver.h\
		-user dspdriverUser.c dspdriver.defs
	sed '/msg_send/s/MSG_OPTION_NONE/SEND_SWITCH/' dspdriverUser.c > dd_user.c
	rm -f dspdriverUser.c
	sed '/msg_rpc/s/RCV_TIMEOUT/RCV_TIMEOUT|SEND_SWITCH/' dd_user.c > dspdriverUser.c
	rm -f dd_user.c

dspdriverAccess.o: dspdriverAccess.c
	$(CC) -g $(CFLAGS) $(RC_CFLAGS) -c dspdriverAccess.c -O -o dspdriverAccess.o

exports: dspdriverAccess.o 

dspdriverdebug:
	$(CC) -g $(CFLAGS) $(RC_CFLAGS) dspdriverdebug.c -o dspdriverdebug -Wall -I.
