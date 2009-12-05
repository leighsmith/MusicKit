/* A NoteFilter subclass which controls a performer which generates
 * fractal melodies.
 */

#import <appkit/appkit.h>
#import <musickit/musickit.h>
#import <mididriver/midi_spec.h>
#import "FractalMelody.h"
#import "FractalPerformer.h"
#import "ParamInterface.h"
#import "WmFractal.h"

@implementation FractalMelody:EnsembleNoteFilter
{
}

+ initialize
 /*
  * Set the version. This can be used in a later version to distinguish older
  * formats when unarchiving documents. 
  */
{
	[FractalMelody setVersion:4];
	return self;
}

- loadNibFile
{
	[NXApp loadNibSection:"FractalMelody.nib" owner:self];
	return self;
}	

- setDefaults
{
	int i;
	[super setDefaults];

	thru = YES;
	listening = YES;
	for (i = 0; i < 16; i++)
		controllers[i] = -1;

	intervalIndex = beatIndexForTime([performer noteInterval]);
	durationIndex = beatIndexForTime([performer noteDuration]);
	return self;
}
	
- init
 /* Called automatically when an instance is created. */
{
	performer = [[FractalPerformer allocFromZone:[self zone]] init];
	[super init];
	return self;
}

- awakeFromNib
{
	int i;
	[super awakeFromNib];
	
	[thruButton setState:thru];
	[modeButtons selectCellWithTag:dynamicMode?1:0];;
	[delayField setDoubleValue:[performer delay]];;

    [setNumField setIntValue:displayedSet+1];
	[setDurationInterface setMode:BEATS];
    [setDurationInterface setDoubleValue:[performer noteSetDuration:displayedSet]];
	[durationSwitch setState:[performer useDurations]];

	for (i = 0; i < 12; i++) {
    	[[noteSetButtons cellAt:0 :i] setState:
			[performer noteState:displayedSet key:i]];
		[[gravityFields cellAt:0 :i] setFloatingPointFormat:NO left:1 right:2];
		[[gravityFields cellAt:0 :i] setFloatValue:
			[performer noteGravity:displayedSet key:i]];
	}

    [numNotesField setIntValue:[performer dynamicSetSize]];
	[[noteSetSwitches findCellWithTag:0] setState:[performer addOctaves]];
	[[noteSetSwitches findCellWithTag:1] setState:[performer pitchSorting]];
	[[noteSetSwitches findCellWithTag:2] setState:[performer uniqueNotes]];

	[dynamicGravityInterface setDoubleValueAt:0 to:[performer velGravityScale]];
	[dynamicGravityInterface setDoubleValueAt:1 to:[performer durGravityScale]];
	[dynamicGravityInterface setDoubleValueAt:2 to:[performer repGravityScale]];
	[velocityButtons selectCellWithTag:[performer velocityTracking]];
	[listeningButton setState:listening];

	[keyInterface setMode:KEYNUMS];
	[keyInterface setIntValueAt:0 to:[performer minKey]];
	[keyInterface setIntValueAt:1 to:[performer maxKey]];
	keyRange = [performer maxKey] - [performer minKey];

	[velocityInterface setIntValueAt:0 to:[performer minVelocity]];
	[velocityInterface setIntValueAt:1 to:[performer maxVelocity]];

	[phrasingInterface setMode:BEATS];
	[phrasingInterface setDoubleValueAt:0 to:[performer noteInterval]];
	[phrasingInterface setDoubleValueAt:1 to:[performer noteDuration]];

	[[phrasingSwitches findCellWithTag:0] setState:[performer tieRepeats]];
	[[phrasingSwitches findCellWithTag:1] setState:[performer noRepeats]];
	[[phrasingSwitches findCellWithTag:2] setState:triggering];

	[silenceButtons selectCellWithTag:[performer restMode]];
    [silenceField setFloatValue:[performer silence]];
    [silenceSlider setFloatValue:[performer silence]];

	[controlNumInterface setMode:CONTROLS];
    [controlNumInterface setIntValue:[performer controller]];
    [controlValInterface setIntValueAt:0 to:[performer minControlVal]];
    [controlValInterface setIntValueAt:1 to:[performer maxControlVal]];

	[controllersInterface setMode:CONTROLS];
	[controllersInterface setIntValues:controllers];

	[noteTagInterface setIntValue:i=[performer numTags]];
	if (i==0) [performer setNumTags:i=128];
	[tagTypeButtons selectCellWithTag: (i==128) ? 0 : 1];
	return self;
}

- free
{
	if (controllerPanel) {
		[controllerPanel close];
		[controllerPanel free];
	}
    [setDurationInterface free];
    [dynamicGravityInterface free];
    [keyInterface free];
    [velocityInterface free];
    [phrasingInterface free];
    [controlNumInterface free];
    [controlValInterface free];
    [controllersInterface free];

	return [super free];
}

- toggleThru:sender
{
	thru = [sender state];
	[document setEdited];
	return self;
}

- toggleListening:sender
{
	listening = [sender state];
	[document setEdited];
	return self;
}

- selectMode:sender
{
	[performer setDynamicMode:dynamicMode = [[sender selectedCell] tag]];
	[document setEdited];
	return self;
}

- takeDelayFrom:sender
{
	[performer setDelay:[sender doubleValue]];
	return self;
}


/* ***  Static Mode Interface Methods  *** */

- takeNoteSetFrom:sender
{
	[performer setStaticNote:displayedSet
	 	key:[[sender selectedCell] tag]
	 	enabled:[[sender selectedCell] state]];
	[document setEdited];

	return self;
}

- takeStaticGravitiesFrom:sender
{
	sender = [sender selectedCell];
	[performer setStaticGravity:displayedSet key:[sender tag]
	 gravity:[sender doubleValue]];
	[document setEdited];

	return self;
}

- incrementStaticGravity:sender
{
	double  inc;
	int     note;

	inc = (double)[[sender selectedCell] tag] * 0.2;
	note = [[gravityFields selectedCell] tag] % 12;
	[performer incrementStaticGravity:displayedSet key:note increment:inc];
	[[gravityFields cellAt:0 :note] setDoubleValue:
	 [performer noteGravity:displayedSet key:note]];
	[document setEdited];

	return self;
}

- takeKeyNumsFrom:sender
{
	if ([sender selectedIndex] == 0)
		[performer setMinKey:[sender intValue]];
	else
		[performer setMaxKey:[sender intValue]];
	keyRange = [performer maxKey] - [performer minKey];
	[document setEdited];
	return self;
}

- takeVelocitiesFrom:sender
{
	if ([sender selectedIndex] == 0)
		[performer setMinVelocity:[sender intValue]];
	else
		[performer setMaxVelocity:[sender intValue]];
	[document setEdited];
	return self;
}

- selectRepeatMode:sender
{
	sender = [sender selectedCell];
	switch ([sender tag]) {
	  case 0:
		[performer setTieRepeats:[sender state]];
		break;
	  case 1:
		[performer setNoRepeats:[sender state]];
		break;
	  case 2:
		triggering = [sender state];
		break;
	}
	[phrasingInterface setEnabled:!triggering];
	[document setEdited];
	return self;
}

- takeNoteIntervalFrom:sender
{
	if ([sender selectedIndex] == 0) {
		[performer setNoteInterval:[sender doubleValue]];
		intervalIndex = [sender intValue];
	}
	else {
		[performer setNoteDuration:[sender doubleValue]];
		durationIndex = [sender intValue];
	}
	[document setEdited];
	return self;
}

- selectRestMode:sender
{
	[performer setRestMode:[[sender selectedCell] tag]];
	[document setEdited];
	return self;
}

- takeSilenceFrom:sender
{
	double  silence = [sender doubleValue];
	[performer setSilence:silence];
	[silenceField setDoubleValue:silence];
	[document setEdited];
	return self;
}

- takeControlValsFrom:sender;
{
	if ([sender selectedIndex] == 0)
		[performer setMinControlVal:[sender intValue]];
	else
		[performer setMaxControlVal:[sender intValue]];
	[document setEdited];
	return self;
}

- takeControllerFrom:sender
{
	[performer setController:[sender intValue]];
	[document setEdited];
	return self;
}

- takeControllersFrom:sender
{
	controllers[[sender selectedIndex]] = [sender intValue];
	[document setEdited];
	return self;
}

- takeSetNumFrom:sender
 /* increment or decrement set by the sender's tag (-1 or 1) */
 /* sets are indexed from 0 but the interface names them from 1 */
{
	int     i, n;

	if ([sender isKindOf:[Matrix class]])
		n = displayedSet + [[sender selectedCell] tag];
	else
		n = [sender intValue];
	[performer selectStaticSet:MIN(MAX(n, 0),[performer maxSetNum] + 1)];
	displayedSet = [performer currentSet];
	[inspectorPanel disableFlushWindow];
	[setNumField setIntValue:displayedSet + 1];
	for (i = 0; i < 12; i++) {
		[noteSetButtons setState:
		 	[performer noteState:displayedSet key:i] at:0 :i];
		[[gravityFields cellAt:0 :i]
		 	setDoubleValue:[performer noteGravity:displayedSet key:i]];
	}
	[setDurationInterface setDoubleValue:[performer noteSetDuration:displayedSet]];

	[[inspectorPanel reenableFlushWindow] flushWindow];
	return self;
}

- takeSetDurationFrom:sender
{
	[performer setSetDuration:displayedSet :[sender doubleValue]];
	[document setEdited];
	return self;
}

- enableDurations:sender
{
	[performer setUseDurations:[sender state]];
	if (![sender state])
		[performer selectStaticSet:displayedSet];

	[document setEdited];
	return self;
}

/* *** Dynamic Note Set Interface Methods *** */

- takeNumNotesFrom:sender
{
	int     inc = [[sender selectedCell] tag];
	int     size;

	size = MAX(MIN([performer dynamicSetSize] + inc, 32), 0);
	[performer setDynamicSetSize:size];
	[numNotesField setIntValue:size];
	[document setEdited];

	return self;
}

- enableOctaves:sender
{
	[performer setAddOctaves:[[sender selectedCell] state]];
	[document setEdited];

	return self;
}

- enableUniqueNotes:sender
{
	[performer setUniqueNotes:[[sender selectedCell] state]];
	[document setEdited];

	return self;
}

- enablePitchSorting:sender
{
	[performer setPitchSorting:[[sender selectedCell] state]];
	[document setEdited];

	return self;
}

- takeVelocityTrackingFrom:sender
{
	int mode = [[sender selectedCell] tag];

	[performer setVelocityTracking:mode];
	[velocityInterface setEnabled:(mode == 0)];
	[document setEdited];

	return self;
}


- takeGravityScalingFrom:sender
{
	switch ([sender selectedIndex]) {
	  case 0:
		[performer setVelGravityScale:[sender doubleValue]];
		break;
	  case 1:
		[performer setDurGravityScale:[sender doubleValue]];
		break;
	  case 2:
		[performer setRepGravityScale:[sender doubleValue]];
		break;
	}
	[document setEdited];
	return self;
}

- enableVelocityTracking:sender
 /* For compatibility with old style FractalMelody instances */
{
	int mode = (int)[sender state];

	[performer setVelocityTracking:mode];
	[velocityInterface setEnabled:(mode == 0)];
	return self;
}

- inspectFractal:sender
{
	[performer inspectFractal:sender];
	return self;
}

- takeTagTypeFrom:sender
{
	if ([[sender selectedCell] tag] == 0) {
		[performer setNumTags:128];
		[noteTagInterface setIntValue:128];
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
	if ([[tagTypeButtons selectedCell] tag] != ((n == 128) ? 0 : 1))
		[tagTypeButtons selectCellWithTag: (n == 128) ? 0 : 1];
	return self;
}

- reset
{
	[super reset];
	if (inspectorPanel) {
		[performer setMinKey:[keyInterface intValueAt:0]];
		[performer setMaxKey:[keyInterface intValueAt:1]];
		[performer setDynamicSetSize:[numNotesField intValue]];
		[performer selectStaticSet:[setNumField intValue] - 1];
		listening = [listeningButton state];
		thru = [thruButton state];
		triggering = [[phrasingSwitches cellAt:2:0] state];
	}
	keyRange = [performer maxKey] - [performer minKey];
	[performer setNoteInterval:timeForBeatIndex(intervalIndex)];
	[performer setNoteDuration:timeForBeatIndex(durationIndex)];
	[performer reset];
	return self;
}

- reset:sender
{
	return [self reset];
}

#define ON(midi_val) (midi_val>=64)

- realizeNote:aNote fromNoteReceiver:aNoteReceiver
{
	MKNoteType type = [aNote noteType];

	if (triggering && (type == MK_noteOn))
		[performer perform];

	if (thru || (type == MK_noteUpdate) || (type == MK_mute))
		[noteSender sendNote:aNote];

	if (isControlPresent(aNote, controllers[0]))
		[performer selectStaticSet:
			getControlValAsInt(aNote, controllers[0]) % ([performer maxSetNum] + 1)];
	if (isControlPresent(aNote, controllers[1]))
		[performer setDynamicSetSize:getControlValAsInt(aNote, controllers[1])];
	if (isControlPresent(aNote, controllers[2])) {
		int val = getControlValAsInt(aNote, controllers[2]);
		[performer setMinKey:val];
		[performer setMaxKey:MIN(val + keyRange, 127)];
	}
	if (isControlPresent(aNote, controllers[3])) {
		keyRange = getControlValAsInt(aNote, controllers[3]);
		[performer setMaxKey:MIN([performer minKey] + keyRange, 127)];
	}
	if (isControlPresent(aNote, controllers[4])) {
		int offset = getControlValAsInt(aNote, controllers[4]);
		[performer setNoteInterval:timeForBeatIndex(intervalIndex+offset)];
		[performer setNoteDuration:timeForBeatIndex(durationIndex+offset)];
	}
	if (isControlPresent(aNote, controllers[5]))
		listening = ON(getControlValAsInt(aNote, controllers[5]));
	if (isControlPresent(aNote, controllers[6]))
		thru = ON(getControlValAsInt(aNote, controllers[6]));
	if (isControlPresent(aNote, controllers[7]))
		[performer setTransposition:getControlValAsInt(aNote, controllers[7])-64];
	if (isControlPresent(aNote, controllers[8])) {
		float density = (float)getControlValAsDouble(aNote, controllers[8])/100.0;
		[performer setSilence:1.0-MIN(density,1.0)];
	}

	if (MKIsNoteParPresent(aNote, MK_sysRealTime)) {
		switch (MKGetNoteParAsInt(aNote, MK_sysRealTime)) {
		  case MK_sysStart:
			if ([performer status] == MK_paused)
				[(FractalPerformer *) performer deactivate];
			if ([performer status] != MK_active)
				[(FractalPerformer *) performer activate];
			else if ([performer status] == MK_active)
				[performer reset];
			break;
		  case MK_sysContinue:
			[(FractalPerformer *) performer resume];
			break;
		  case MK_sysStop:
			[(FractalPerformer *) performer pause];
			break;
		  case MK_sysReset:
			[(FractalPerformer *) performer pause];
			[self reset:self];
			break;
		}
	}
	if (dynamicMode && listening &&
		((type == MK_noteOn) || (type == MK_noteOff) || (type == MK_noteDur)))
		[performer addDynamicNote:aNote];

	return self;
}

- write:(NXTypedStream *) stream
 /* Archive the notefilter to a typed stream. */
{
	[self reset:self];
	[super write:stream];
	NXWriteTypes(stream, "cccci",
				 &thru, &listening, &dynamicMode, &triggering, &displayedSet);
	NXWriteArray(stream, "i", 16, controllers);
	return self;
}

- read:(NXTypedStream *) stream
 /* Unarchive the notefilter from a typed stream. */
{
	int n, version;

	[super read:stream];
	version = NXTypedStreamClassVersion(stream, "FractalMelody");

	if (version < 4) {
		int controller; id dummyId; int i, dummy[32];
		NXReadTypes(stream, "cciii@@@@@@@@@@@@@@@i",
					&thru, &listening, &i,
					&displayedSet, &controller,
					&dummyId, &dummyId, &dummyId, &dummyId,
					&dummyId, &dummyId, &dummyId, &dummyId,
					&dummyId, &dummyId, &dummyId, &dummyId,
					&dummyId, &dummyId, &dummyId, &n);
		NXReadArray(stream, "i", n, dummy);
		if (version <= 1) {
			int    *tmp;
	
			NX_MALLOC(tmp, int, n);
			NXReadArray(stream, "i", n, tmp);
			NX_FREE(tmp);
		} else
			NXReadArray(stream, "i", 16, controllers);
		if (version >= 3)
			NXReadTypes(stream, "@@@", &controllerPanel, &dummyId, &dummyId);
		if (version < 3) {
			/* In earlier versions these were hard-wired controller numbers */
			controllers[0] = 24;
			controllers[1] = 21;
			controllers[2] = 19;
			controllers[3] = 20;
			controllers[4] = 18;
			controllers[5] = 22;
			controllers[6] = 23;
		}
	}
	else if (version == 4) {
		NXReadTypes(stream, "cccci",
				 &thru, &listening, &dynamicMode, &triggering, &displayedSet);
		NXReadArray(stream, "i", 16, controllers);
	}
	return self;
}

- awake
{
	[super awake];
	intervalIndex = beatIndexForTime([performer noteInterval]);
	durationIndex = beatIndexForTime([performer noteDuration]);
	return self;
}

/* The following is obsolete - defined for compatability with old archived documents */
- takeNoteDurationFrom:sender {return self;}

@end
