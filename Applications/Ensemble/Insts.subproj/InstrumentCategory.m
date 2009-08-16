#import "InstrumentCategory.h"

@implementation Instrument(InstrumentCategory)

/*  -------------  General methods for updating our own parameters  ----------------- */

static id globalUpdateNote = nil;

- updatePar:(MKPar)parNum asDouble:(double)val
{
	[Conductor lockPerformance];
	if (!globalUpdateNote)
		globalUpdateNote = [[[Note alloc] init] setNoteType:MK_noteUpdate];
	MKSetNoteParToDouble(globalUpdateNote, parNum, val);
	[self realizeNote:globalUpdateNote fromNoteReceiver:nil];
	MKSetNoteParToDouble(globalUpdateNote, parNum, MK_NODVAL);	/* same as -removePar: */
	[Conductor unlockPerformance];
	return self;
}

- updatePar:(MKPar)parNum asInt:(int)val
{
	[Conductor lockPerformance];
	if (!globalUpdateNote)
		globalUpdateNote = [[[Note alloc] init] setNoteType:MK_noteUpdate];
	MKSetNoteParToInt(globalUpdateNote, parNum, val);
	[self realizeNote:globalUpdateNote fromNoteReceiver:nil];
	MKSetNoteParToDouble(globalUpdateNote, parNum, MAXINT);	/* same as -removePar: */
	[Conductor unlockPerformance];
	return self;
}

- updatePar:(MKPar)parNum asString:(char *)val
{
	[Conductor lockPerformance];
	if (!globalUpdateNote)
		globalUpdateNote = [[[Note alloc] init] setNoteType:MK_noteUpdate];
	MKSetNoteParToString(globalUpdateNote, parNum, val);
	[self realizeNote:globalUpdateNote fromNoteReceiver:nil];
	MKSetNoteParToDouble(globalUpdateNote, parNum, MK_NODVAL);	/* same as -removePar: */
	[Conductor unlockPerformance];
	return self;
}

- updatePar:(MKPar)parNum asWave:(id)val
{
	[Conductor lockPerformance];
	if (!globalUpdateNote)
		globalUpdateNote = [[[Note alloc] init] setNoteType:MK_noteUpdate];
	MKSetNoteParToWaveTable(globalUpdateNote, parNum, val);
	[self realizeNote:globalUpdateNote fromNoteReceiver:nil];
	MKSetNoteParToWaveTable(globalUpdateNote, parNum, nil);	/* same as -removePar: */
	[Conductor unlockPerformance];
	return self;
}

- updateController:(int)controlChange toValue:(int)val
{
	[Conductor lockPerformance];
	if (!globalUpdateNote)
		globalUpdateNote = [[[Note alloc] init] setNoteType:MK_noteUpdate];
	MKSetNoteParToInt(globalUpdateNote, MK_controlChange, controlChange);
	MKSetNoteParToInt(globalUpdateNote, MK_controlVal, val);
	[self realizeNote:globalUpdateNote fromNoteReceiver:nil];
	MKSetNoteParToInt(globalUpdateNote, MK_controlChange, MAXINT);
	[Conductor unlockPerformance];
	return self;
}

@end
