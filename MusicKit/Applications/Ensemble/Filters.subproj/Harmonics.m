/* A NoteFilter subclass which controls a performer which generates
 * dynamically-changing harmonics.
 */

#import <appkit/appkit.h>
#import <mididriver/midi_spec.h>
#import "Harmonics.h"
#import "HarmonicsPerformer.h"
#import "ParamInterface.h"

@implementation Harmonics
{
}

+ initialize
 /*
  * Set the version. This can be used in a later version to distinguish older
  * formats when unarchiving documents. 
  */
{
	[Harmonics setVersion:3];
	return self;
}

- loadNibFile
{
	[NXApp loadNibSection:"Harmonics.nib" owner:self];
	return self;
}

- setDefaults
{
	int i;
	[super setDefaults];
	for (i = 0; i < 8; i++)
		controllers[i] = -1;
	return self;
}

- init
 /* Called automatically when an instance is created. */
{
	performer = [[HarmonicsPerformer allocFromZone:[self zone]] init];
	[super init];
	return self;
}

- awakeFromNib
{
	int n;
	[super awakeFromNib];
	[noiseTypeButtons selectCellWithTag:[performer usingFractal] ? 1 : 0];
	[noRepeatsSwitch setState:[performer noRepeats]];

	[paramInterface setModeAt:0 to:BEATS];
	[paramInterface setModeAt:1 to:BEATS];
	[paramInterface setModeAt:2 to:INTS];
	[paramInterface setModeAt:3 to:INTS];
	[paramInterface setDoubleValueAt:0 to:[performer interval]];
	[paramInterface setDoubleValueAt:1 to:[performer noteDuration]];
	[paramInterface setIntValueAt:2 to:[performer firstHarmonic]];
	[paramInterface setIntValueAt:3 to:[performer numHarmonics]];
	[paramInterface setDoubleValueAt:4 to:([performer spectralPower] - 6.0) / -6.0];
	[paramInterface setIntValueAt:5 to:[performer bendSensitivity]];
	[thruButton setState:thru];
	[controlInterface setMode:CONTROLS];
	[controlInterface setIntValues:controllers];
	[noteTagInterface setIntValue:n=[performer numTags]];
	[tagTypeButtons selectCellWithTag: (n == NUMHARMS) ? 0 : 1];

	return self;
}

- free
{
	[controllerPanel close];
	[controllerPanel free];
	[paramInterface free];
	[controlInterface free];
	return [super free];
}

- takeParamFrom:sender
{
	int n;

	switch ([sender selectedIndex]) {
		case 0:
			[performer setInterval:[sender doubleValue]];
			break;
		case 1:
			[performer setDuration:[sender doubleValue]];
			break;
		case 2:
			n = [sender intValue];
			[performer setFirstHarmonic:MAX(MIN(NUMHARMS, n), 0)];
			break;
		case 3:
			n = [sender intValue];
			[performer setNumHarmonics:MAX(MIN(NUMHARMS, n), 0)];
			break;
		case 4:
			[performer setSpectralPower:6.0 - [sender doubleValue] * 6.0];
			break;
		case 5:
			[performer setBendSensitivity:[sender intValue]];
			break;
		default:
			break;
	}

	[document setEdited];

	return self;
}

- toggleRepeats:sender
{
	[performer setNoRepeats:[sender state]];
	[document setEdited];

	return self;
}

- toggleFractal:sender
{
	[performer setUseFractal:[[sender selectedCell] tag]];
	[document setEdited];

	return self;
}

- toggleThru:sender
{
	thru = [(thruButton = sender) state];
	[document setEdited];

	return self;
}

- inspectFractal:sender
{
	[performer inspectFractal:sender];
	return self;
}

- takeControllersFrom:sender
{
	controllers[[sender selectedIndex]] = [sender intValue];
	[document setEdited];
	return self;
}

- takeTagTypeFrom:sender
{
	if ([[sender selectedCell] tag] == 0) {
		[performer setNumTags:NUMHARMS];
		[noteTagInterface setIntValue:NUMHARMS];
	}
	else {
		BOOL *insMap = [document instrumentMap:inputNum];
		id *instruments = [document instruments];
		int i, n = 0;
		for (i=0; i< 4; i++)
			if (insMap[i] && [instruments[i] isKindOf:[SynthInstrument class]]) {
				n = [instruments[i] synthPatchCount];
				break;
			}
		if (n == 0) n = 2;
		[noteTagInterface setIntValue:n];
		[performer setNumTags:n];
	}
	return self;
}

- takeNumTagsFrom:sender
{
	int n = [sender intValue];
	[performer setNumTags:n];
	if ([[tagTypeButtons selectedCell] tag] != ((n == NUMHARMS) ? 0 : 1))
		[tagTypeButtons selectCellWithTag: (n == NUMHARMS) ? 0 : 1];
	return self;
}

- reset
{
	[performer setIntervalScale:1.0];
	[performer setHarmonicsScale:1.0];
	[performer setDurationScale:1.0];
	if (thruButton)
		thru = [thruButton state];
	currentTag = 0;
	return self;
}

- realizeNote:aNote fromNoteReceiver:aNoteReceiver
{
	MKNoteType type = [aNote noteType];

	if (thru || (type == MK_noteUpdate) || (type == MK_mute))
		[noteSender sendNote:aNote];
	if (type == MK_noteUpdate) {
		if (isControlPresent(aNote, controllers[0]))
			[performer setIntervalScale:
			 	1.0 + getControlValAsDouble(aNote, controllers[0]) / 127.0];
		if (isControlPresent(aNote, controllers[1]))
			[performer setDurationScale:
			 	1.0 + getControlValAsDouble(aNote, controllers[1]) / 42.33];
		if (isControlPresent(aNote, controllers[2]))
			[performer setHarmonicsScale:
			 	getControlValAsDouble(aNote, controllers[2]) / 127.0];
		if (isControlPresent(aNote, controllers[3]))
			thru = (getControlValAsInt(aNote, controllers[3]) > 63);
	} else if ((type == MK_mute) &&
			   MKIsNoteParPresent(aNote, MK_sysRealTime)) {
		switch (MKGetNoteParAsInt(aNote, MK_sysRealTime)) {
			case MK_sysStart:
				[(HarmonicsPerformer *) performer resume];
				break;
			case MK_sysContinue:
				[(HarmonicsPerformer *) performer resume];
				break;
			case MK_sysStop:
				[(HarmonicsPerformer *) performer pause];
				break;
			case MK_sysReset:
				[(HarmonicsPerformer *) performer deactivate];
				[self reset];
				break;
		}
	} else if ((type == MK_noteOn) || (type == MK_noteDur)) {
		if ([performer status] != MK_inactive)
			[(HarmonicsPerformer *) performer deactivate];
		[performer setFreq:[aNote freq]];
		if (MKIsNoteParPresent(aNote, MK_velocity))
			[performer setVelocity:MKGetNoteParAsDouble(aNote, MK_velocity)];
		if (MKIsNoteParPresent(aNote, MK_amp))
			[performer setAmp:MKGetNoteParAsDouble(aNote, MK_amp)];
		currentTag = [aNote noteTag];
		[(HarmonicsPerformer *) performer activate];
		if (type == MK_noteDur) {	/* Schedule a noteOff for each noteDur */
			id noteOff = [aNote copy];

			[noteOff setNoteType:MK_noteOff];
			[[Conductor defaultConductor]
			 sel:@selector(realizeNote:fromNoteReceiver:)
			 to :self atTime:[[Conductor defaultConductor] time] + [aNote dur]
			 argCount:2, noteOff, nil];
		}
	} else if (type == MK_noteOff)
		if ([aNote noteTag] == currentTag) {
			[(HarmonicsPerformer *) performer deactivate];
			currentTag = 0;
		}
	return self;
}

- write:(NXTypedStream *) stream
 /* Archive the notefilter to a typed stream. */
{
	[super write:stream];
	NXWriteTypes(stream, "c", &thru);
	NXWriteArray(stream, "i", 8, controllers);
	return self;
}

- read:(NXTypedStream *) stream
 /* Unarchive the notefilter from a typed stream. */
{
	int version;

	[super read:stream];
	version = NXTypedStreamClassVersion(stream, "Harmonics");

	if (version < 3) {
		id dummy;
		NXReadTypes(stream, "c@@@@@@", &thru, &dummy,
					&dummy, &dummy, &dummy, &dummy, &dummy);
		if (version > 1) {
			NXReadTypes(stream, "@@@",
						&controllerPanel, &dummy, &thruButton);
			NXReadArray(stream, "i", 8, controllers);
		}
	} else if (version == 3) {
		NXReadTypes(stream, "c", &thru);
		NXReadArray(stream, "i", 8, controllers);
	}
	return self;
}

/* The following are obsolete - defined for compatability with old archived documents */
- takeIntervalFrom:sender {return self;}
- takeDurationFrom:sender {return self;}
- takeFirstHarmonicFrom:sender {return self;}
- takeNumHarmonicsFrom:sender {return self;}
- takeBrightnessFrom:sender {return self;}
- takeBendFrom:sender {return self;}

@end
