## Makefile for MKPerformSndMIDI_Linux - this should become
## Makefile.in and be generated with configure

SRCFILES = PerformSound.c mididriverUser.c

HFILES = PerformSound.h	PerformSoundPrivate.h  midi_driver.h \
	mididriverUser.h mididriver_types.h sounderror.h soundstruct.h

MKPerformSndMIDI.lib: PerformSound.o mididriverUser.o
	ar MKPerformSndMIDI.lib a PerformSound.o mididriverUser.o
	ranlib 



