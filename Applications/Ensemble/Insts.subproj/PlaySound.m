/* Obsolete.  See SamplerInstrument.m */

#import "SamplerInstrument.h"
#import "PlaySound.h"
#import <appkit/appkit.h>

@implementation PlaySound
{
}

- takeKeyFrom:sender {return self;}
- takeBearingFrom:sender {return self;}
- takeAmpFrom:sender {return self;}
- takePatchCountFrom:sender {return self;}
- takePitchBendFrom:sender {return self;}
- takeVelocityFrom:sender {return self;}
- takeDiatonicFrom:sender {return self;}
- takeTiesFrom:sender {return self;}
- addFile:sender {return self;}
- removeFile:sender {return self;}
- clearAll:sender {return self;}
- clearKey:sender {return self;}
- showParameters:sender {return self;}

- free
 /*
  * Free the sound structs, the filename strings, the hash tables, and the
  * window. 
  */
{
	int i;
	[soundTable freeObjects];
	[soundTable free];
	if (parametersWindow) {
		[parametersWindow close];
		[parametersWindow free];
	}
	if (window) {
		[window close];
		[window free];
	}
	for (i = 0; i < 128; i++)
		[performers[i] free];
	return [super free];
}

- read:(NXTypedStream *) stream
 /* Unarchive the instrument from a typed stream. */
{
	int version = NXTypedStreamClassVersion(stream, "PlaySound");

	[super read:stream];
	if (version <= 1)
		NXReadTypes(stream, "ii@@@@", &keyNum, &testKey, &fileTable,
					&view, &fileDisplayer, &keyDisplayer);
	else if (version <= 5) {
		double panLeft, panRight, oldAmp;
		NXReadTypes(stream, "ii@@@@@@ddd", &keyNum, &testKey, &fileTable,
					&view, &fileDisplayer, &keyDisplayer, &bearingDisplayer,
					&ampDisplayer, &panLeft, &panRight, &oldAmp);
	}
	else
		NXReadTypes(stream, "ii@@@@@@", &keyNum, &testKey, &fileTable,
					&view, &fileDisplayer, &keyDisplayer, &bearingDisplayer,
					&ampDisplayer);
	if (version > 2)
		NXReadTypes(stream, "@", &document);
	if (version > 3)
		NXReadTypes(stream, "d@@icc@", &pitchBendSensitivity,
					&pitchBendDisplayer, &voiceCountDisplayer,
					&voiceCount, &diatonic, &tieRepeats, &parametersWindow);
	if ((version > 4) && (version < 8)) {
		BOOL dummy;
		NXReadTypes(stream, "c", &dummy);
	}
	if (version > 6)
		NXReadTypes(stream, "@", &velocityDisplayer);
	if (version < 8) {
		int i;
		for (i=0; i<128; i++) performers[i] = nil;
	}
	if (version >= 9)
		NXReadArray(stream, "i", 128, keyMap);
	return self;
}

typedef struct {@defs (NoteReceiver)} nrId;
#define OWNER(noteRcvr) (((nrId *)(noteRcvr))->owner)

- finishUnarchiving
{
	id nr;
	SamplerInstrument *newself = [SamplerInstrument allocFromZone:[self zone]];
	newself->testKey = testKey;
	newself->keyNum = keyNum;
	newself->voiceCount = voiceCount;
	newself->bearing = [bearingDisplayer doubleValue];
	newself->amp = [ampDisplayer doubleValue];
	newself->pitchbendSensitivity = pitchBendSensitivity;
	newself->diatonic = diatonic;
	newself->tieRepeats = tieRepeats;
	if (velocityDisplayer)
		newself->velocitySensitivity = [velocityDisplayer floatValue];
	[newself->fileTable free];
	newself->fileTable = fileTable;
	fileTable = nil;
	[newself initSoundTable];
	[newself initPerformers];
	/* Connect whatever was connected to the old instrument to its successor  */
	nr = [self noteReceiver];
	OWNER(nr) = self;	/* For some reason this is nil sometimes and needs to be set */
	[newself addNoteReceiver:nr];
	[newself awake];
	[NXApp delayedFree:self];
	return newself;
}

@end
