# Copyright CCRMA, 1992.  All rights reserved.

# process_sounds_dsp make rules:

MFILES = ReadsoundUG.m EnvelopeSound.m writeScorefileToSoundfile.m ResonSound.m
HFILES = ReadsoundUG.h EnvelopeSound.h
DERIVEDMFILES = ReadsoundUGxx.m
DERIVEDHFILES = ReadsoundUGxx.h
DERIVEDFILES = $(DERIVEDMFILES) $(DERIVEDHFILES) 

LIBS = -lsynthpatches -lunitgenerators -lmusickit -ldsp -lNeXT_s -lsys_s -lDriver
CFLAGS = -O -g 

# Put any classes you want linked in this list
LFLAGS = -u .objc_class_name_EnvelopeSound -u .objc_class_name_Pluck -u .objc_class_name_ResonSound 

OBJFILES = $(MFILES:.m=.o) $(DERIVEDMFILES:.m=.o)
GARBAGE = core errs *.lnk *_[xy][xy].asm $(DERIVEDFILES) readsoundUGInclude.m ReadsoundUG[xy][xy].* *~

process_sounds_dsp: $(DERIVEDFILES) $(OBJFILES) 
	$(CC) $(CFLAGS) $(LFLAGS) -o process_sounds_dsp $(OBJFILES) $(LIBS) 

$(DERIVEDMFILES): readsound.asm
	-/bin/rm readsound_*.lnk
	dspwrap -xonly -noDoc -ug readsound.asm




# extractchannel make rules:

CFILES = extractchannel.c
OBJFILES2 = $(CFILES:.c=.o)
LIBS2 = -lNeXT_s -lsys_s

extractchannel: $(OBJFILES2)
	$(CC) $(CFLAGS) -o extractchannel $(OBJFILES2) $(LIBS2) 

all: process_sounds_dsp extractchannel

clean: 
	-rm -f *.o process_sounds_dsp extractchannel $(GARBAGE) 

