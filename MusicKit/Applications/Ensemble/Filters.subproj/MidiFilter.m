/* A NoteFilter subclass that thins the pitchbend, aftertouch, and
   controller updates. */

#import <appkit/appkit.h>
#import <mididriver/midi_spec.h>
// These are already included by musickit.h from EnsembleNoteFilter.h-DAJ
// #import <musickit/Note.h>
// #import <musickit/NoteSender.h>
// #import <musickit/params.h>
#import "MidiFilter.h"
#import "ParamInterface.h"

extern double MKGetTime(void);

typedef enum _actionType {
	STOP, THIN, PASS
}       actionType;

@implementation MidiFilter
{
}

+ initialize
 /* Set the version. This can be used in a later version to distinguish older
  * formats when unarchiving documents. 
  */
{
	[MidiFilter setVersion:3];
	return self;
}

- loadNibFile
{
	[NXApp loadNibSection:"MidiFilter.nib" owner:self];
	return self;
}

- setDefaults
{
	int i;
	[super setDefaults];

	/* Pass continuous controllers, but set up for thinning when enabled */
	for (i = 0; i < 67; i++) {
		lastVals[i] = 0;
		minVals[i] = 2;
		lastControlTimes[i] = -1000.0;
		minControlTimes[i] =.03;
		controlAction[i] = PASS;
	}
	/* Pass discrete controllers by default */
	for (i = 68; i < 131; i++) {
		lastVals[i] = 0;
		minVals[i] = 0;
		lastControlTimes[i] = -1000.0;
		minControlTimes[i] = 0.0;
		controlAction[i] = PASS;
	}
	minVals[MIDI_BALANCE] = 3;
	minVals[128] = 512;			/* pitch bend */
	minControlTimes[128] =.08;
	minVals[129] = 2;			/* aftertouch */
	minControlTimes[129] =.03;
	controller = 1;

	for (i = 0; i < 128; i++) {
		octaveShift[i] = 0;
		velocityScaler[i] = 1.0;
	}
	noteNum = 60;
	lastKeyNum = MAXINT;
	lastNoteTag = MAXINT;
	noteOffTag = MAXINT;
	harmonicThreshold = 32;
	doubleAttackTime =.060;

	thruState = 0;
	initialThruState = 0;
	thru = YES;
	thruControl = 68;
	return self;
}
	
- init
 /* Called automatically when an instance is created. */
{
	[super init];
	return self;
}

- updateThinningDisplay:(actionType) anAction
{
	static char tmpstr[8];

	if (anAction == THIN) {
		[minValField setEnabled:YES];
		[minTimeField setEnabled:YES];
		[minValButtons setEnabled:YES];
		[minTimeButtons setEnabled:YES];
		sprintf(tmpstr, "%3d", minVals[controller]);
		[minValField setStringValue:tmpstr];
		[minTimeField setIntValue:
		 	(int)(1000.0 * minControlTimes[controller] +.5)];
	} else {
		[minValField setIntValue:2];
		[minTimeField setIntValue:30];
		[minValField setEnabled:NO];
		[minTimeField setEnabled:NO];
		[minValButtons setEnabled:NO];
		[minTimeButtons setEnabled:NO];
	}

	return self;
}

- awakeFromNib
{
	[super awakeFromNib];
	[thruControlInterface setMode:CONTROLS];
	[thruControlInterface setIntValue:thruControl];
	[thruOnButtons selectCellWithTag:(thruState ? 1 : 0)];
	[thruStateButtons selectCellWithTag:(initialThruState ? 1 : 0)];
	[dataThruSwitch setState:thruEnabled];

	[thruControlInterface setMode:CONTROLS];
    [controllerInterface setIntValue:controller];
	[self updateThinningDisplay:controlAction[controller]];
    [actionButtons selectCellWithTag:controlAction[controller]];
	[controlFilterSwitch setState:filteringEnabled];

	[thruControlInterface setMode:KEYNUMS];
    [noteInterface setIntValue:noteNum];
    [velocityScalerField setIntValue:velocityScaler[noteNum]];
    [octaveShiftField setIntValue:octaveShift[noteNum]];
	[velocityAdjustSwitch setState:noteAdjustingEnabled];
	
    [attackTimeField setDoubleValue:(int)(doubleAttackTime*1000.0+0.5)];
    [thresholdField setIntValue:harmonicThreshold];
	[attackFilterSwitch setState:attackFilteringEnabled];
	return self;
}

- reset
{
	int     i;
	for (i = 0; i < 131; i++) {
		lastVals[i] = 0;
		lastControlTimes[i] = -1000.0;
	}
	lastKeyNum = MAXINT;
	lastNoteTag = MAXINT;
	noteOffTag = MAXINT;
	thru = (thruEnabled) ? (thruState == initialThruState) : YES;
	return self;
}

- takeControllerFrom:sender
{
	actionType act;
	controller = [sender intValue];
	[inspectorPanel disableFlushWindow];
	act = controlAction[controller];
	if ([[actionButtons selectedCell] tag] != act)
		[actionButtons selectCellAt:0 :2 - act];
	[self updateThinningDisplay:act];
	[[inspectorPanel reenableFlushWindow] flushWindow];

	return self;
}

- takeActionFrom:sender
{
	[document setEdited];
	return[self updateThinningDisplay:
		   controlAction[controller] = [[sender selectedCell] tag]];
}

- takeMinValFrom:sender
{
	static char tmpstr[] = "123";

	minVals[controller] = MIN(MAX(minVals[controller] +
								  [[sender selectedCell] tag], 0), 999);
	sprintf(tmpstr, "%3d", minVals[controller]);
	[minValField setStringValue:tmpstr];
	[document setEdited];

	return self;
}

- takeMinTimeFrom:sender
{
	double  increment = (double)[[sender selectedCell] tag] *.001;

	minControlTimes[controller] =
		MIN(MAX(minControlTimes[controller] + increment, 0.0),.9984);
	[minTimeField setIntValue:
	 (int)(1000.0 * minControlTimes[controller] +.5)];
	[document setEdited];

	return self;
}

- takeNoteNumberFrom:sender
{
	noteNum = [sender intValue];
	[octaveShiftField setDoubleValue:octaveShift[noteNum]];
	[velocityScalerField setDoubleValue:velocityScaler[noteNum]];

	return self;
}

- enableControlFilter:sender
{
	filteringEnabled = [sender state];
	return self;
}

- takeOctaveShiftFrom:sender
{
	int     inc = (double)[[sender selectedCell] tag] * 12;

	octaveShift[noteNum] = MIN(MAX(octaveShift[noteNum] + inc, -48), 48);
	[octaveShiftField setIntValue:octaveShift[noteNum]];
	return self;
}

- takeVelocityScalerFrom:sender
{
	double  inc = (double)[[sender selectedCell] tag] *.05;

	velocityScaler[noteNum] = MIN(MAX(velocityScaler[noteNum] + inc, 0.0), 9.9);
	if (velocityScaler[noteNum] <.01)
		velocityScaler[noteNum] = 0.0;
	[velocityScalerField setDoubleValue:velocityScaler[noteNum]];

	return self;
}

- enableNoteFilter:sender
{
	noteAdjustingEnabled = [sender state];
	return self;
}

- enableAttackFilter:sender
{
	attackFilteringEnabled = [sender state];
	return self;
}

- takeThresholdFrom:sender
{
	int     inc = [[sender selectedCell] tag];

	harmonicThreshold = MIN(MAX(harmonicThreshold + inc, 0), 99);
	[thresholdField setIntValue:harmonicThreshold];

	return self;
}

- takeAttackTimeFrom:sender
{
	double  inc = [[sender selectedCell] tag] *.001;

	doubleAttackTime = MIN(MAX(doubleAttackTime + inc, 0.0),.099);
	[attackTimeField setIntValue:(int)(doubleAttackTime * 1000.0 +.5)];

	return self;
}

- takeThruControllerFrom:sender
{
	thruControl = [sender intValue];
	return self;
}

- takeThruStateFrom:sender
{
	thruState = [[sender selectedCell] tag];
	if (thruEnabled)
		thru = (initialThruState == thruState);
	return self;
}

- takeInitialThruFrom:sender
{
	initialThruState = [[sender selectedCell] tag];
	if (thruEnabled)
		thru = (initialThruState == thruState);
	return self;
}

- enableThruSwitch:sender
{
	if (thruEnabled = [sender state])
		thru = (initialThruState == thruState);
	else
		thru = YES;
	return self;
}

- sendNoteOff:aNoteOff
{
	[noteSender sendAndFreeNote:aNoteOff];
	noteOffMsg = NULL;
	return self;
}

- realizeNote:aNote fromNoteReceiver:aNoteReceiver
 /*
  * Here's where the work is done. Assumes that a noteUpdate has one and only
  * one controller, aftertouch, or pitchbend parameter set and never a
  * combination. This is always the case for input direct from MIDI. 
  */
{
	MKNoteType type = [aNote noteType];
	int     oldVelocity = MAXINT;
	int     oldKey = MAXINT;

	if (type == MK_noteUpdate) {
		if (thruEnabled && MKIsNoteParPresent(aNote, MK_controlChange) &&
			(MKGetNoteParAsInt(aNote, MK_controlChange) == thruControl)) {
			thru = ((MKGetNoteParAsInt(aNote, MK_controlVal) > 63) == thruState);
			if (!thru)
				[noteSender sendNote:aNote];
		}
		if (!thru)
			return self;
		if (filteringEnabled) {
			static actionType act = PASS;
			static int control, value;

			if (MKIsNoteParPresent(aNote, MK_pitchBend)) {
				act = controlAction[control = 128];
				if (act == STOP)
					return self;
				else if (act == THIN) {
					value = MKGetNoteParAsInt(aNote, MK_pitchBend);
					if ((value == 0) || (value == 8192) ||
						(value == 16383))
						act = PASS;
				}
			} else if (MKIsNoteParPresent(aNote, MK_controlChange)) {
				act = controlAction[control =
								  MKGetNoteParAsInt(aNote, MK_controlChange)];
				if (act == STOP)
					return self;
				else if (act == THIN) {
					value = MKGetNoteParAsInt(aNote, MK_controlVal);
					if ((value == 0) || (value == 127))
						act = PASS;
				}
			} else if (MKIsNoteParPresent(aNote, MK_afterTouch)) {
				act = controlAction[control = 129];
				if (act == STOP)
					return self;
				else if (act == THIN) {
					value = MKGetNoteParAsInt(aNote, MK_afterTouch);
					if ((value == 0) || (value == 127))
						act = PASS;
				}
			} else if (MKIsNoteParPresent(aNote, MK_programChange)) {
				act = controlAction[control = 130];
				if (act == STOP)
					return self;
				else if (act == THIN) {
					value = MKGetNoteParAsInt(aNote, MK_programChange);
					if ((value == 0) || (value == 127))
						act = PASS;
				}
			}
			if (act == THIN) {
				double  time = MKGetTime();

				if ((abs(value - lastVals[control]) < minVals[control]) &&
					((time - lastControlTimes[control]) < minControlTimes[control]))
					return self;
				lastVals[control] = value;
				lastControlTimes[control] = time;
			}
		}
	} else if (type == MK_noteOn) {
		int     keyNum;
		int     velocity;

		if (!thru)
			return self;
		/*
		 * Double Attack filter. If we get a noteOn while a noteOff is still
		 * pending, and it is either the same key, or a 5th up below a certain
		 * velocity, kill the noteOff and the new noteOn. We could check for
		 * octaves, but it seems to be relatively rare. 
		 */
		keyNum = [aNote keyNum];
		velocity = MKGetNoteParAsInt(aNote, MK_velocity);
		if (attackFilteringEnabled) {
			if (noteOffMsg &&
				((keyNum == lastKeyNum) ||
			(((keyNum == (lastKeyNum + 7)) || (keyNum == (lastKeyNum + 12))) &&
			 (velocity <= harmonicThreshold)))) {
				[noteOffMsg->_arg1 free];
				MKCancelMsgRequest(noteOffMsg);
				noteOffMsg = NULL;
				noteOffTag = lastNoteTag;	/* Save for final noteOff */
				return self;
			}
			lastNoteTag = [aNote noteTag];
			noteOffTag = MAXINT;
			lastKeyNum = keyNum;
		}
		if (noteAdjustingEnabled) {
			if (octaveShift[keyNum] != 0) {
				oldKey = keyNum;
				MKSetNoteParToInt
					(aNote, MK_keyNum,
					 keyNum = MAX(MIN(keyNum + octaveShift[keyNum], 127), 0));
			}
			if ((velocityScaler[keyNum] > 1.0) || (velocityScaler[keyNum] < 1.0)) {
				oldVelocity = velocity;
				MKSetNoteParToInt
					(aNote, MK_velocity,
					 MAX(MIN((int)(((double)velocity)
								   * velocityScaler[keyNum] +.5), 127), 0));
			}
		}
	} else if (attackFilteringEnabled && (type == MK_noteOff)) {
		id      noteOff;

		if (!thru) return self;
		noteOff = [aNote copy];
		/*
		 * Delay noteOffs a bit in order to have time to check for double
		 * attacks.  See above. 
		 */
		if (noteOffTag != MAXINT)
			[noteOff setNoteTag:noteOffTag];
		noteOffMsg = MKNewMsgRequest(MKGetTime() + doubleAttackTime,
									 @selector(sendNoteOff:),
									 self, 1, noteOff);
		MKScheduleMsgRequest(noteOffMsg,[Conductor clockConductor]);
		return self;
	} else if ((type == MK_mute) &&
			   (MKGetNoteParAsInt(aNote, MK_sysRealTime) == MK_sysReset))
		[self reset];
	[noteSender sendNote:aNote];

	/* restore original velocity */
	if (oldVelocity != MAXINT)
		MKSetNoteParToInt(aNote, MK_velocity, oldVelocity);
	if (oldKey != MAXINT)
		MKSetNoteParToInt(aNote, MK_keyNum, oldKey);
	return self;
}

- write:(NXTypedStream *) stream
 /* Archive the notefilter to a typed stream. */
{
	[super write:stream];
	NXWriteTypes(stream, "iicccciidcc", &controller, &thruControl, 
				&filteringEnabled, &noteAdjustingEnabled,
				&attackFilteringEnabled, &thruEnabled,
				&noteNum, &harmonicThreshold,
				&doubleAttackTime, &initialThruState, &thruState);
	NXWriteArray(stream, "i", 131, minVals);
	NXWriteArray(stream, "d", 131, minControlTimes);
	NXWriteArray(stream, "i", 131, controlAction);
	NXWriteArray(stream, "i", 128, octaveShift);
	NXWriteArray(stream, "d", 128, velocityScaler);
	return self;
}

- read:(NXTypedStream *) stream
 /* Unarchive the notefilter from a typed stream. */
{
	int version;
	id controllerField, noteField, thruControlField;
	[super read:stream];
	version = NXTypedStreamClassVersion(stream, "MidiFilter");
	
	if (version < 3) {
		NXReadType(stream, "i", &controller);
		NXReadArray(stream, "i", 131, minVals);
		NXReadArray(stream, "d", 131, minControlTimes);
		NXReadArray(stream, "i", 131, controlAction);
	
		if (version <= 1) {
			controllerField = NXReadObject(stream);
			minValField = NXReadObject(stream);
			minTimeField = NXReadObject(stream);
			minValButtons = NXReadObject(stream);
			minTimeButtons = NXReadObject(stream);
			actionButtons = NXReadObject(stream);
		}
		else if (version == 2) {
			NXReadTypes(stream, "@@@@@@",
						&controllerField, &minValField, &minTimeField,
						&minValButtons, &minTimeButtons, &actionButtons);
			NXReadTypes(stream, "ccciidccic", &filteringEnabled, &noteAdjustingEnabled,
						&attackFilteringEnabled, &noteNum, &harmonicThreshold,
						&doubleAttackTime, &initialThruState, &thruState,
						&thruControl, &thruEnabled);
			NXReadArray(stream, "i", 128, octaveShift);
			NXReadArray(stream, "d", 128, velocityScaler);
			NXReadTypes(stream, "@@@@@@",
						&noteField, &octaveShiftField,
						&velocityScalerField, &thresholdField,
						&attackTimeField, &thruControlField);
		}
	}
	else if (version == 3) {
		NXReadTypes(stream, "iicccciidcc", &controller, &thruControl, 
					&filteringEnabled, &noteAdjustingEnabled,
					&attackFilteringEnabled, &thruEnabled,
					&noteNum, &harmonicThreshold,
					&doubleAttackTime, &initialThruState, &thruState);
		NXReadArray(stream, "i", 131, minVals);
		NXReadArray(stream, "d", 131, minControlTimes);
		NXReadArray(stream, "i", 131, controlAction);
		NXReadArray(stream, "i", 128, octaveShift);
		NXReadArray(stream, "d", 128, velocityScaler);
	}
	return self;
}

- awake
 /* Initialize certain non-archived data */
{
	[super awake];
	[self reset];
	return self;
}

@end
