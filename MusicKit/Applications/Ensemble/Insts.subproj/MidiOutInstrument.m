/* An Instrument for handling MIDI output, and adjusting some MIDI values
 * via a graphic interface.
 */
#import "MidiOutInstrument.h"
#import "ParamInterface.h"
#import <appkit/appkit.h>
#import <mididriver/midi_spec.h>

/* Add a method to the Midi object to return the device name */
@interface Midi(MoreMidi)
- (char *)midiDev;
@end

@implementation Midi(MoreMidi)
- (char *)midiDev
{
	return midiDev;
}
@end


@implementation MidiOutInstrument
{
}

+ initialize
{
	[MidiOutInstrument setVersion:2];
	return self;
}

- loadNibFile
{
    [NXApp loadNibSection:"MidiOutInstrument.nib" owner:self withNames:NO];
	return self;
}

- setDefaults
{
	[super setDefaults];
	velocityIncrement = 0;
	outChan = 1;
	controller = MIDI_MAINVOLUME;
	velocityAdjustMin = -36;
	velocityAdjustMax = 36;
	controlMin = 0;
	controlMax = 127;
	controlVal = controlMax;
	controlTmp = ((double)(controlMax - controlMin)) / 127.0;
	controlController = -1;
	velocityController = -1;
	channelController = -1;
	MKSetNoteParToInt(controlNote, MK_controlChange, controller);
	return self;
}
	
- init
 /* Called automatically when an instance is created. */
{
	int i;
	controlNote = [[Note alloc] init];
	[controlNote setNoteType:MK_noteUpdate];
	[super init];
	/* The note receiver for the default Midi channel */
	[self setMidi:[NXApp midi]];
	[self addNoteReceiver:[[NoteReceiver alloc] init]];
	for (i = 0; i < 16; i++)
		noteTags[i] = MAXINT;

	return self;
}

- awakeFromNib
{
	[super awakeFromNib];
    [channelField setIntValue:outChan];
    [velocityField setIntValue:velocityIncrement];
	[velocitySlider setMinValue:velocityAdjustMin];
	[velocitySlider setMaxValue:velocityAdjustMax];
    [velocitySlider setIntValue:velocityIncrement];
    [minVelField setIntValue:minVel];
    [minVelSlider setIntValue:minVel];
    [controlValField setIntValue:controlVal];
    [controlValSlider setIntValue:controlVal];
	[controlInterface setMode:CONTROLS];
	[controlInterface setIntValueAt:0 to:controller];
	[controlInterface setIntValueAt:1 to:controlController];
	[controlInterface setIntValueAt:2 to:velocityController];
	[controlInterface setIntValueAt:3 to:channelController];
    [[controlRangeFields cellAt:0:0] setIntValue:controlMin];
    [[controlRangeSliders cellAt:0:0] setIntValue:controlMin];
    [[controlRangeFields cellAt:1:0] setIntValue:controlMax];
    [[controlRangeSliders cellAt:1:0] setIntValue:controlMax];
    [[velocityRangeFields cellAt:0:0] setIntValue:velocityAdjustMin];
    [[velocityRangeSliders cellAt:0:0] setIntValue:velocityAdjustMin];
    [[velocityRangeFields cellAt:1:0] setIntValue:velocityAdjustMax];
    [[velocityRangeSliders cellAt:1:0] setIntValue:velocityAdjustMax];
	return self;
}

- free
{
	if (info) [info free];
	[controlNote free];
	[controlInterface free];
	return [super free];
}

- setMidi:newMidi
{
	midi = newMidi;
	midiNoteReceiver = [midi channelNoteReceiver:outChan];
	return self;
}

- takeVelocityFrom:sender
 /* Adjust the velocity increment */
{
	char   *ampstr;

	velocityIncrement = [sender intValue];
	if (velocityField) {
		NX_MALLOC(ampstr, char, 4);
		sprintf(ampstr, "%+2d", velocityIncrement);
		[velocityField setStringValue:ampstr];
		NX_FREE(ampstr);
	}
	[document setEdited];

	return self;
}

- (int)testKey
{
	return testKey;
}

- (unsigned int)outChan
{
	return outChan;
}

- takeChannelFrom:sender
 /* Change the output MIDI channel */
{
	outChan = MAX(MIN(outChan + [[sender selectedCell] tag], 16), 1);
	[Conductor lockPerformance];
	midiNoteReceiver = [midi channelNoteReceiver:outChan];
	[channelField setIntValue:outChan];
	[Conductor unlockPerformance];
	[document setEdited];

	return self;
}

#define PAN_FROM_BEARING(bearing) ((int)floor(127.0*((bearing+45.0)/90.0)+0.5))

- takeBearingFrom:sender
	/* Override to send MIDI pan values instead of MK_bearing */
{
	bearing = [sender doubleValue];
	bearing = MAX(MIN(bearing,45.0),-45.0);
	[self updateController:MIDI_PAN toValue:PAN_FROM_BEARING(bearing)];
	[bearingField setDoubleValue:bearing];
	if (sender == bearingField)
		[bearingSlider setDoubleValue:bearing];
    [document setEdited];
	return self;
}

- takeMinVelFrom:sender
 /* Notes with a velocity above this value will not be transmitted */
{
	minVel = [sender intValue];
	[minVelField setIntValue:minVel];
	[document setEdited];

	return self;
}

extern const char *midiNames[];

- takeControlValFrom:sender
 /* Adjust and send the MIDI controller value */
{
	controlVal = [sender intValue];
	if (controller >= 0)
		[self updateController:controller toValue:controlVal];
	[controlValField setIntValue:controlVal];
	[document setEdited];

	return self;
}

- takeControllerFrom:sender
{
	switch ([sender selectedIndex]) {
		case 0: 
			controller = [sender intValue];
			if (controller >= 0)
				MKSetNoteParToInt(controlNote, MK_controlChange, controller);
			else
				[controlNote removePar:MK_controlChange];
			break;
		case 1:
			controlController = [sender intValue];
			break;
		case 2:
			velocityController = [sender intValue];
			break;
		case 3:
			channelController = [sender intValue];
			break;
	}
			
	[document setEdited];
	return self;
}

- takeControlRangeFrom:sender
{
	int val = [sender intValue];
	int which = [[sender selectedCell] tag];
	if (which == 0) {
		[[controlRangeFields cellAt:0:0] setIntValue:controlMin=val];
		[controlValSlider setMinValue:val];
	}
	else {
		[[controlRangeFields cellAt:1:0] setIntValue:controlMax=val];
		[controlValSlider setMaxValue:val];
	}
	controlTmp = ((double)(controlMax - controlMin)) / 127.0;
	return self;
}

- takeVelocityRangeFrom:sender
{
	int val = [sender intValue];
	int which = [[sender selectedCell] tag];
	if (which == 0) {
		[[velocityRangeFields cellAt:0:0] setIntValue:velocityAdjustMin=val];
		[velocitySlider setMinValue:val];
	}
	else {
		[[velocityRangeFields cellAt:1:0] setIntValue:velocityAdjustMax=val];
		[velocitySlider setMaxValue:val];
	}
	return self;
}

- reset
 /*
  * Make our internal state and whatever is out there consistent with what is
  * shown by the interface. 
  */
{
	id note = [[Note alloc] init];

	[note setNoteType:MK_noteUpdate];
	outChan = [channelField intValue];
	[self setMidi:[NXApp midi]];
	MKSetNoteParToInt(note, MK_controlChange, MIDI_PAN);
	MKSetNoteParToInt(note, MK_controlVal, PAN_FROM_BEARING(bearing));
	[midiNoteReceiver receiveNote:note];
	if (controller >= 0) {
		MKSetNoteParToInt(note, MK_controlChange, controller);
		MKSetNoteParToInt(note, MK_controlVal,
						  controlVal = [controlValSlider intValue]);
		[midiNoteReceiver receiveNote:note];
	}
	velocityIncrement = [velocitySlider intValue];
	[note free];
	if (damperButtonOn)
		[self updateController:MIDI_DAMPER toValue:damperButtonOn ?  127 : 0];

	return self;
}

- realizeNote:aNote fromNoteReceiver:aNoteReceiver
{
	MKNoteType noteType = [aNote noteType];
	int vel;
	int chan = MAXINT;

	if (isControlPresent(aNote, controlController)) {
		MKSetNoteParToInt
			(controlNote, MK_controlVal, controlVal = controlMin +
			(int)(getControlValAsDouble(aNote, controlController) * controlTmp));
		[midiNoteReceiver receiveNote:controlNote];
	}
	if (isControlPresent(aNote, velocityController)) {
		velocityIncrement =
			velocityAdjustMin +
			(int)((double)(velocityAdjustMax - velocityAdjustMin) *
					getControlValAsDouble(aNote, velocityController) / 127.0);
	}
	if (isControlPresent(aNote, channelController)) {
		chan = getControlValAsInt(aNote, channelController) % 16;
		midiNoteReceiver = [midi channelNoteReceiver:chan];
	}
	else if (MKIsNoteParPresent(aNote, MK_midiChan)) {
		int chan = MKGetNoteParAsInt(aNote, MK_midiChan) % 16;
		midiNoteReceiver = [midi channelNoteReceiver:chan];
	}

	if (MKIsNoteParPresent(aNote, MK_controlChange)) {
		int controlChange = MKGetNoteParAsInt(aNote, MK_controlChange);
		if (controlChange == MIDI_DAMPER)
			damperOn = (MKGetNoteParAsInt(aNote, MK_controlVal) > 64);
		if (controlChange == MIDI_ALLNOTESOFF)
			[self abort];
	}

	if ((noteType == MK_noteDur) || (noteType == MK_noteOn)) {
		if ((velocityIncrement || minVel) &&
			((vel = MKGetNoteParAsInt(aNote, MK_velocity)) != MAXINT)) {
			if (vel < minVel)
				return self;
			if (velocityIncrement) {
				MKSetNoteParToInt(aNote, MK_velocity,
								  MAX(MIN(vel + velocityIncrement, 127), 0));
				[midiNoteReceiver receiveNote:aNote];
				MKSetNoteParToInt(aNote, MK_velocity, vel);
			} else
				[midiNoteReceiver receiveNote:aNote];
		} else
			[midiNoteReceiver receiveNote:aNote];
		noteTags[tagIndex++] = [aNote noteTag];
		if (tagIndex == 16)
			tagIndex = 0;
	} else if (noteType == MK_mute) {
		int val = MKGetNoteParAsInt(aNote, MK_sysRealTime);
		if ((val == MK_sysStart) && damperButtonOn)
			[self updateController:MIDI_DAMPER toValue:127];
		else if ((val == MK_sysReset) || (val == MK_sysStop))
			[self abort];
		if (val == MK_sysReset)
			[self reset];
		[midiNoteReceiver receiveNote:aNote];
	} else
		[midiNoteReceiver receiveNote:aNote];

	if (chan != MAXINT)
		midiNoteReceiver = [midi channelNoteReceiver:outChan];

	return self;
}

- abort
 /*
  * Most synthesizers fail to implement AllNotesOff.  We will simulate it by
  * sending a noteOff for the last 16 noteTags. 
  */
{
	int     i;
	id      note = [[Note alloc] init];

	if (damperOn) {
		[note setNoteType:MK_noteUpdate];
		[note setPar:MK_controlChange toInt:MIDI_DAMPER];
		[note setPar:MK_controlVal toInt:0];
		[midiNoteReceiver receiveNote:note];
	}
	[note removePar:MK_controlChange];
	[note setNoteType:MK_noteOff];
	for (i = 0; i < 16; i++) {
		if (noteTags[i] != MAXINT) {
			[note setNoteTag:noteTags[i]];
			[midiNoteReceiver receiveNote:note];
			noteTags[i] = MAXINT;
		}
	}

	if (damperOn) {
		[note setNoteType:MK_noteUpdate];
		[note setNoteTag:MAXINT];
		[note setPar:MK_controlChange toInt:MIDI_DAMPER];
		[note setPar:MK_controlVal toInt:127];
		[midiNoteReceiver receiveAndFreeNote:note withDelay:.1];
	} else
		[note free];

	return self;
}

- getUpdates:(Note **) aNoteUpdate controllerValues:(HashTable **) controllers
 /* For compatibility with SynthInstrument method */
{
	if (!info) {
		info = [[Note alloc] init];
		[info setNoteType:MK_noteUpdate];
	}
	MKSetNoteParToString(info, MK_synthPatch, [midi midiDev]);
	MKSetNoteParToInt(info, MK_midiChan, outChan);
	*aNoteUpdate = info;
	*controllers = nil;
	return self;
}

- write:(NXTypedStream *) stream
 /* Archive the instrument to a typed stream. */
{
	[super write:stream];
	NXWriteTypes(stream, "iiiiiiiiiiiii",
				 &testKey, &velocityIncrement,
				 &outChan, &minVel, &controller, &controlVal,
				 &velocityAdjustMin, &velocityAdjustMax,
				 &controlMin, &controlMax, &controlController,
				 &channelController, &velocityController);
	return self;
}

- read:(NXTypedStream *) stream
 /* Unarchive the instrument from a typed stream. */
{
	int version;

	[super read:stream];
	version = NXTypedStreamClassVersion(stream, "MidiOutInstrument");

	if (version == 1)
		NXReadTypes(stream, "iiiiiiiiii",
				 &testKey, &velocityIncrement,
				 &outChan, &minVel, &controller, &controlVal,
				 &velocityAdjustMin, &velocityAdjustMax,
				 &controlMin, &controlMax);
	else if (version == 2)
		NXReadTypes(stream, "iiiiiiiiiiiii",
				 &testKey, &velocityIncrement,
				 &outChan, &minVel, &controller, &controlVal,
				 &velocityAdjustMin, &velocityAdjustMax,
				 &controlMin, &controlMax, &controlController,
				 &channelController, &velocityController);
	return self;
}

- awake
 /* Initialize certain non-archived data */
{
	int     i;

	[super awake];

	controlTmp = ((double)(controlMax - controlMin)) / 127.0;
	controlNote = [[Note alloc] init];
	[controlNote setNoteType:MK_noteUpdate];
	if (controller >= 0)
		MKSetNoteParToInt(controlNote, MK_controlChange, controller);
	[self reset];
	for (i = 0; i < 16; i++)
		noteTags[i] = MAXINT;

	return self;
}

- takeAfterTouchFrom:sender
 /* Obsolete - remains for compatibility with old documents */
{
	return self;
}

@end
