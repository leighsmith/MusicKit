/* A NoteFilter subclass which schedules echos of notes */

#import <appkit/appkit.h>
#import <objc/List.h>
#import "Echo.h"
#import "ParamInterface.h"
#import <MusicKit/MusicKit.h>

extern long random();

#define MAXRAN 2147483647.0
#define DRANDOM ((double)random()/MAXRAN)

@implementation Echo:EnsembleNoteFilter
{
}

+ initialize
 /*
  * Set the version. This can be used in a later version to distinguish older
  * formats when unarchiving documents. 
  */
{
	[Echo setVersion:7];
	return self;
}

- setDefaults
{
	int i;
	[super setDefaults];
	delayTimes[0] = 1.0;
	delayTimes[1] = 1.00;
	delayTimes[2] = 1.0;
	delayTimes[3] = 1.0;
	attenuation[0] = -3;
	attenuation[1] = -6;
	attenuation[2] = -9;
	attenuation[3] = -12;
	numEchos[0] = 1;
	numEchos[1] = 0;
	numEchos[2] = 0;
	numEchos[3] = 0;
	curDelay = 0;
	thru = YES;
	tagMapIndex = 0;
	for (i = 0; i < MAXDELAYS; i++) {
		controllers[i][0] = MK_bearing+MK_PAR_START;
		controllers[i][1] = -1;
		controlVals[i][0] = 0;
		controlVals[i][1] = 0;
		ranVariation[i] = 0.0;
	}
	return self;
}

- loadNibFile
{
	[NXApp loadNibSection:"Echo.nib" owner:self];
	return self;
}

- init
 /* Called automatically when an instance is created. */
{
	[super init];
	hashTable = [[HashTable allocFromZone:[self zone]]
				 initKeyDesc:"i" valueDesc:"i" capacity:512];
	defaultConductor = [Conductor defaultConductor];
	status = MK_inactive;
	return self;
}

- updateDisplay
{
	[inspectorPanel disableFlushWindow];
    [curDelayField setDoubleValue:curDelay+1];
    [delayTimeInterface setDoubleValue:delayTimes[curDelay]];
	[paramInterface setIntValueAt:0 to:numEchos[curDelay]];
	[paramInterface setIntValueAt:1 to:attenuation[curDelay]];
	[paramInterface setIntValueAt:2 to:(int)(ranVariation[curDelay]*100.0+.5)];
	[controllerInterface setIntValueAt:0 to:controllers[curDelay][0]];
	[controllerInterface setIntValueAt:1 to:controllers[curDelay][1]];
	[controlValInterface setIntValueAt:0 to:controlVals[curDelay][0]];
	[controlValInterface setIntValueAt:1 to:controlVals[curDelay][1]];
	[[inspectorPanel reenableFlushWindow] flushWindow];
	return self;
}

- awakeFromNib
{
	[super awakeFromNib];
	[delaySwitch setState:delayUntaggedUpdates];
	[thruButton setState:thru];
	[delayTimeInterface setMode:BEATS];
	[controllerInterface setMode:CONTROLS];
	[self updateDisplay];
	return self;
}


- free
{
	[hashTable free];
    [delayTimeInterface free];
	[paramInterface free];
	[controllerInterface free];
	[controlValInterface free];
	return [super free];
}


- takeCurDelayFrom:sender
{
	int inc = [[sender selectedCell] tag];

	curDelay += inc;
	if (curDelay < 0)
		curDelay = MAXDELAYS - 1;
	if (curDelay == MAXDELAYS)
		curDelay = 0;
	[self updateDisplay];
	return self;
}

- takeParamFrom:sender
{
	int which = [sender selectedIndex];
	int val = [sender intValue];
	switch (which) {
		case 0: numEchos[curDelay] = val; break;
		case 1: attenuation[curDelay] = val; break;
		case 2: ranVariation[curDelay] = [sender doubleValue]*0.01; break;
	}
	[document setEdited];
	return self;
}

- takeDelayTimeFrom:sender
 /* Change the current delay time */
{
	delayTimes[curDelay] = [sender doubleValue];
	[document setEdited];
	return self;
}

- takeControllerFrom:sender
 /* Change a parameter number included in notes for the current delay */
{
	controllers[curDelay][[sender selectedIndex]] = [sender intValue];
	[document setEdited];
	return self;
}

- takeControlValFrom:sender
 /* Change a parameter value included in notes for the current delay */
{
	controlVals[curDelay][[sender selectedIndex]] = [sender intValue];
	[document setEdited];
	return self;
}


- toggleThru:sender
{
	thru = [sender state];
	[document setEdited];

	return self;
}

- takeDelayUntaggedFrom:sender
{
	delayUntaggedUpdates = [sender state];
	return self;
}

- sendAndFreeNote:aNote
{
	if ((status == MK_active) || ([aNote noteType] == MK_noteOff))
		[noteSender sendAndFreeNote:aNote];
	else
		[aNote free];
	return self;
}

- realizeNote:aNote fromNoteReceiver:aNoteReceiver
{
	id newNote;
	int delay, echo, n, curVel;
	int tagIndex = -1;
	double delayTime, curDelayTime, curAmp, ampScale;
	int noteType = [aNote noteType];
	int tag = [aNote noteTag];
	int velocity = -1;
	double amp = -1.0;
	static int lastTag = MAXINT;

	if (noteType == MK_mute) {
		[noteSender sendNote:aNote];	/* Just forward these */
		if (MKIsNoteParPresent(aNote, MK_sysRealTime) &&
			(MKGetNoteParAsInt(aNote, MK_sysRealTime) == MK_sysReset))
			status = MK_inactive;
		return self;
	} else if (noteType == MK_noteUpdate) {
		if ([aNote noteTag] == MAXINT) {
			if (delayUntaggedUpdates)
				tag = lastTag;
			else {
				[noteSender sendNote:aNote];	/* Just forward these */
				return self;
			}
		}
	} else
		status = MK_active;

	if (thru)
		[noteSender sendNote:aNote];

	if (MKIsNoteParPresent(aNote, MK_velocity))
		velocity = MKGetNoteParAsInt(aNote, MK_velocity);
	else if (MKIsNoteParPresent(aNote, MK_amp))
		amp = MKGetNoteParAsDouble(aNote, MK_amp);
	else
		velocity = MK_DEFAULTVELOCITY;

	if ([hashTable isKey:(const void *)tag])
		tagIndex = (int)[hashTable valueForKey:(const void *)tag];
	else if ((++tagMapIndex) == 512)
		tagMapIndex = 0;

	for (delay = 0; delay < MAXDELAYS; delay++) {
		if (n = numEchos[delay]) {
			delayTime = delayTimes[delay];
			curDelayTime = 0;
			curAmp = amp;
			curVel = velocity;
			ampScale = MKdB(attenuation[delay]);
			for (echo = 0; echo < n; echo++) {
				newNote = [aNote copy];	/* Need to copy notes here */
				curDelayTime += delayTime;
				if ((noteType == MK_noteOn) || (noteType == MK_noteDur)) {
					if (velocity >= 0)
						MKSetNoteParToInt(newNote, MK_velocity,
										  curVel *= ampScale);
					else
						MKSetNoteParToDouble(newNote, MK_amp, curAmp *= ampScale);
				}
				if (tagIndex >= 0)
					[newNote setNoteTag:tagMap[tagIndex][delay][echo]];
				else
					[newNote setNoteTag:tagMap[tagMapIndex][delay][echo] =
					 MKNoteTag()];
				if (controllers[delay][0] >= 0)
					/* Include an arbitrary parameter value if desired */
					setControlValToInt(newNote, controllers[delay][0], 
						controlVals[delay][0]);
				if (controllers[delay][1] >= 0)
					/* Include an arbitrary parameter value if desired */
					setControlValToInt(newNote, controllers[delay][1], 
						controlVals[delay][1]);
				/* Schedule it for later.  Note that the Midi object's
				 * conductor is now by default the defaultConductor. 
				 */
				if (ranVariation[delay])
					curDelayTime += ranVariation[delay] * delayTime * (DRANDOM -.5);
				[defaultConductor sel:@selector(sendAndFreeNote:) to :self
				 	withDelay:curDelayTime argCount:1, newNote];
			}
		}
	}
	if (tagIndex >= 0) {
		if (noteType == MK_noteOff)
			[hashTable removeKey:(const void *)tag];
	} else {
		[hashTable insertKey:(const void *)tag value:(void *)tagMapIndex];
		lastTag = tag;
	}
	return self;
}

- write:(NXTypedStream *) stream
 /* Archive the notefilter to a typed stream. */
{
	int nd = MAXDELAYS, ne = MAXECHOS;
	[super write:stream];
	NXWriteTypes(stream, "cciii",
			&thru,  &delayUntaggedUpdates, &curDelay, &nd, &ne);
	NXWriteArray(stream, "d", nd, delayTimes);
	NXWriteArray(stream, "i", nd, numEchos);
	NXWriteArray(stream, "i", nd, attenuation);
	NXWriteArray(stream, "i", nd*2, controllers);
	NXWriteArray(stream, "i", nd*2, controlVals);
	NXWriteArray(stream, "d", nd, ranVariation);
	return self;
}

- read:(NXTypedStream *) stream
 /* Unarchive the notefilter from a typed stream. */
{
	int nd, ne, version;

	[super read:stream];
	version = NXTypedStreamClassVersion(stream, "Echo");
	
	if (version < 7) {
		int i, controller, pan[MAXDELAYS], oldVals[MAXDELAYS], indexes[MAXDELAYS];
		BOOL sendBearing;
		id dummy;
		NXReadTypes(stream, "icii", &curDelay, &thru, &nd, &ne);
		NXReadArray(stream, "i", nd, indexes);
		NXReadArray(stream, "i", nd, numEchos);
		NXReadArray(stream, "i", nd, attenuation);
		NXReadArray(stream, "i", nd, &pan);
		if (version <= 1) {
			NXReadObject(stream);
			NXReadObject(stream);
			NXReadObject(stream);
			NXReadObject(stream);
			NXReadObject(stream);
			NXReadObject(stream);
			NXReadObject(stream);
			NXReadObject(stream);
			curDelayField = NXReadObject(stream);
		} else {
			NXReadTypes(stream, "@@@@@@@@@@@i",
						&dummy, &dummy,
						&dummy, &dummy, &dummy,
						&dummy, &dummy, &dummy,
						&curDelayField,
						&dummy, &dummy, &controller);
			NXReadArray(stream, "i", nd, oldVals);
		}
		if (version > 2)
			NXReadTypes(stream, "c", &delayUntaggedUpdates);
		if (version < 4) {
			/* compensate old objects for added 0-time delay */
			int i;
	
			for (i = 0; i < MAXDELAYS; i++)
				indexes[i]++;
		}
		if (version > 4)
			NXReadArray(stream, "d", nd, ranVariation);
		if (version > 5) {
			NXReadTypes(stream, "c", &sendBearing);
			NXReadTypes(stream, "@", &dummy);
		}
		for (i=0; i<MAXDELAYS; i++) {
			controllers[i][0] = sendBearing ? MK_bearing+MK_PAR_START : -1;
			controlVals[i][0] = sendBearing ? pan[i] : 0;
			controllers[i][1] = controller;
			controlVals[i][1] = oldVals[i];
			delayTimes[i] = timeForBeatIndex(indexes[i]);
		}
	}
	else if (version == 7) {
		NXReadTypes(stream, "cciii",
				&thru,  &delayUntaggedUpdates, &curDelay, &nd, &ne);
		NXReadArray(stream, "d", nd, delayTimes);
		NXReadArray(stream, "i", nd, numEchos);
		NXReadArray(stream, "i", nd, attenuation);
		NXReadArray(stream, "i", nd*2, controllers);
		NXReadArray(stream, "i", nd*2, controlVals);
		NXReadArray(stream, "d", nd, ranVariation);
	}
	return self;
}

- awake
 /* Initialize certain non-archived data */
{
	[super awake];
	hashTable = [[HashTable allocFromZone:[self zone]]
				 initKeyDesc:"i" valueDesc:"i" capacity:512];
	defaultConductor = [Conductor defaultConductor];
	status = MK_inactive;
	return self;
}

/* The following are obsolete - defined for compatability with old archived documents */
- takeNumEchosFrom:sender {return self;}
- takeAttenuationFrom:sender {return self;}
- takePanFrom:sender {return self;}
- takeControllerValueFrom:sender {return self;}
- takeEnableBearingFrom:sender {return self;}

@end
