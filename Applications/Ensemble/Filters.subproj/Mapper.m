/* A NoteFilter subclass which maps MIDI data to other MIDI data */

#import "Mapper.h"
#import "ParamInterface.h"
#import "EnvelopeView.h"
#import <musickit/musickit.h>
#import <appkit/appkit.h>
#import <mididriver/midi_spec.h>

@implementation Mapper:EnsembleNoteFilter
{
}

+ initialize
 /* Set the version. This can be used in a later version to distinguish older
  * formats when unarchiving documents. 
  */
{
	[Mapper setVersion:7];
	return self;
}

- loadNibFile
{
	[NXApp loadNibSection:"Mapper.nib" owner:self];
	return self;
}

- setDefaults
{
	int i;
	[super setDefaults];

	for (i = 0; i < NUMMAPS; i++) {
		envelopes[i] = nil;
		map[i][0] = MIDI_MODWHEEL;
		map[i][1] = MIDI_BALANCE;
		enabled[i] = NO;
		mapThru[i] = NO;
		doubleClicks[i] = 0;
		clickCount[i] = 0;
		nextMap[i] = -1;
	}
	doubleClickTime = 0.3;
	return self;
}

- init
 /* Called automatically when an instance is created. */
{
	[super init];
	newNote = [[Note alloc] init];
	[newNote setNoteType:MK_noteUpdate];
	return self;
}

- free
{
	[newNote free];
	[[envelopeView window] close];
	[[envelopeView window] free];
	return [super free];
}

- awakeFromNib
{
	int i;
	id cell;
	[super awakeFromNib];
	[inputInterface setMode:CONTROLS];
	[outputInterface setMode:CONTROLS];
	for (i=0; i<NUMMAPS; i++) {
		[[enabledButtons cellAt:i:0] setState:enabled[i]];
		[[thruButtons cellAt:i:0] setState:mapThru[i]];
		cell = [clickButtons cellAt:i:0];
		switch (doubleClicks[i]) {
			case 2:
				[cell setState:1];
				[cell setTitle:"x2"];
				break;
			case 4:
				[cell setState:1];
				[cell setTitle:"x4"];
				break;
			case 0:
			default:
				[cell setState:0];
				[cell setTitle:"x2"];
				break;
		}
		[inputInterface setIntValueAt:i to:map[i][0]];
		[outputInterface setIntValueAt:i to:map[i][1]];
		[[functionButtons cellAt:i:0] setState:functionEnabled[i]];
		[[inspectButtons cellAt:i:0] setEnabled:functionEnabled[i]];
	}
	[doubleClickTimeField setDoubleValue:doubleClickTime];
	[sequentialSwitch setState:sequentialMapping];
	[envelopeView setStickPointEnabled:NO];
	return self;
}

- setupSequences
{
	int i, j;

	for (i=0; i<NUMMAPS; i++) {
		inSequence[i] = YES;
		nextMap[i] = -1;
	}

	if (sequentialMapping)
		for (i=0; i<NUMMAPS; i++) {
			if (enabled[i])
				for (j=i+1; j<NUMMAPS; j++)
					if (enabled[j] && (map[i][0] == map[j][0])) {
						inSequence[j] = NO;
						nextMap[j] =  (nextMap[i] >= 0) ? nextMap[i] : i;
						nextMap[i] = j;
						break;
					}
		}
	return self;
}

- enableMap:sender
{
	id cell = [sender selectedCell];
	int mapNum = [cell tag];
	enabled[mapNum] = [cell state] && (map[mapNum][0]>=0) && (map[mapNum][1]>=0);
	if (sequentialMapping) [self setupSequences];
	[document setEdited];
	return self;
}

- enableFunction:sender
{
	id cell = [sender selectedCell];
	int mapNum = [cell tag];
	functionEnabled[mapNum] = [cell state];
	[[inspectButtons cellAt:mapNum:0] setEnabled:functionEnabled[mapNum]];
	[document setEdited];
	return self;
}

- editEnvelope:sender
{
	int mapNum = [[sender selectedCell] tag];
	char s[64];
	if (!envelopes[mapNum]) {
		double x[2], y[2];
		envelopes[mapNum] = [[Envelope allocFromZone:[self zone]] init];
		x[0] = y[0] = 0.0;
		x[1] = y[1] = 127.0;
		[envelopes[mapNum] setPointCount:2 xArray:x yArray:y];
	}
	[envelopeView setEnvelope:envelopes[mapNum]];
	sprintf(s, "Input %d, Mapper %d, Function %d", 
			inputNum+1, (position<3)?1:2, mapNum+1);
	[[envelopeView window] setTitle:s];
	[[envelopeView window] orderFront:sender];
	return self;
}

- takeInputFrom:sender
{
	int mapNum = [sender selectedIndex];
	map[mapNum][0] = [sender intValue];
	enabled[mapNum] = [[enabledButtons cellAt:mapNum:0] state] && 
					(map[mapNum][0]>=0) && (map[mapNum][1]>=0);
	if (sequentialMapping) [self setupSequences];
	[document setEdited];
	return self;
}

- takeOutputFrom:sender
{
	int mapNum = [sender selectedIndex];
	map[mapNum][1] = [sender intValue];
	enabled[mapNum] = [[enabledButtons cellAt:mapNum:0] state] && 
					(map[mapNum][0]>=0) && (map[mapNum][1]>=0);
	[document setEdited];
	return self;
}

- enableThru:sender
{
	int i;
	id cell = [sender selectedCell];
	int mapNum = [cell tag];

	mapThru[mapNum] = [cell state];
	if (sequentialMapping) [self setupSequences];
	
	sendThru = NO;
	for (i=0; i<NUMMAPS; i++)
		if (mapThru[i]) {
			sendThru = YES;
			break;
		}

	[document setEdited];

	return self;
}

- enableSequentialMapping:sender
	/* If sequential mapping is enabled, controls which are mapped multiple times
	 * are mapped only once per note, cycling through the multiple mappings, instead
	 * of doing all the mappings for every note.
	 */
{
	sequentialMapping = [sender state];

	if (sequentialMapping) [self setupSequences];
	[document setEdited];

	return self;
}

- takeDoubleClickFrom:sender
{
	id cell = [sender selectedCell];
	int mapNum = [cell tag];
	char title1[3] = "x2";
	char title2[3] = "x4";

	if ([cell state])
		doubleClicks[mapNum] = 2;
	else if (doubleClicks[mapNum] == 2) {
		doubleClicks[mapNum] = 4;
		[cell setTitle:title2];
		[cell setState:1];
	} else {
		doubleClicks[mapNum] = 0;
		[cell setTitle:title1];
	}

	lastNoteTime[mapNum] = -1000.0;
	[document setEdited];

	return self;
}

- takeDoubleClickTimeFrom:sender
{
	double inc = (double)[[sender selectedCell] tag] *.1;

	doubleClickTime = MAX(MIN(doubleClickTime + inc, 2.0), 0);
	if (doubleClickTime <.05)
		doubleClickTime = 0.0;
	[doubleClickTimeField setDoubleValue:doubleClickTime];
	[document setEdited];

	return self;
}

- performMap:(int)mapNum on:aNote
{
	int control, newControl;
	double newValue;
	id note = newNote;

	control = map[mapNum][0];
	newControl = map[mapNum][1];
	newValue = getControlValAsDouble(aNote, control);

	if (sendThru && !mapThru[mapNum]) removeControl(note, control);

	if (functionEnabled[mapNum] && envelopes[mapNum])
		newValue = [envelopes[mapNum] lookupYForX:newValue];
	
	if (newControl < MK_PAR_START) {
		int val = (int)newValue;
		if (val < 0) val = 0; else if (val > 127) val = 127;
		setControlValToInt(note, newControl, val);
	} else {
		newControl -= MK_PAR_START;	/* Convert to real MK param number */
		switch (newControl) {
			case MK_pitchBend:
				MKSetNoteParToInt(note, MK_pitchBend,
					((control == MK_pitchBend-MK_PAR_START) ? 
						newValue : ((int)newValue << 7)));
				break;
			case MK_velocity:
				note = [aNote copy];
				MKSetNoteParToInt(note, MK_velocity, (int)newValue);
				break;
			case MK_keyNum:
				if (note == newNote) note = [aNote copy];
				MKSetNoteParToInt(note, MK_keyNum, (int)newValue);
				break;
			case MK_tempo:
				if (newValue < 1) newValue = 1;
				[[Conductor defaultConductor] setTempo:(double)newValue];
				note = nil;
				break;
			default:
				MKSetNoteParToDouble(note, newControl, newValue);
				break;
		}
	}

	if (note) {
		[noteSender sendNote:note];
		if (note != newNote) [note free];
		else removeControl(note,newControl);
	}

	return self;
}

- realizeNote:aNote fromNoteReceiver:aNoteReceiver
{
	int i;
	double time = MKGetTime();
	BOOL mapped = NO;

	for (i=0; i<NUMMAPS; i++) {
		if (enabled[i] && isControlPresent(aNote, map[i][0]) &&
		    (!sequentialMapping || inSequence[i])) {
			if (doubleClicks[i]) {
				double lastTime = lastNoteTime[i];
				lastNoteTime[i] = time;
				if (lastTime > time) lastTime = -1000.0;
				if ((time - lastTime) > doubleClickTime) {
					clickCount[i] = 1;
					continue;
				}
				if (++clickCount[i] < doubleClicks[i]) continue;
			}
			[self performMap:i on:aNote];
			mapped = YES;
		}
	}
	
	if (!mapped || sendThru) [noteSender sendNote:aNote];

	if (sequentialMapping) {
		static BOOL tmp[NUMMAPS];
		memcpy(tmp,inSequence,sizeof(BOOL)*NUMMAPS);
		for (i=0; i<NUMMAPS; i++)
			if ((nextMap[i] >=0) && (tmp[i] == YES)) {
				inSequence[i] = NO;
				inSequence[nextMap[i]] = YES;
			}
	}

	return self;
}

- write:(NXTypedStream *) stream
 /* Archive the notefilter to a typed stream. */
{
	int n = NUMMAPS;

	[super write:stream];
	NXWriteTypes(stream, "cdi", &sequentialMapping, &doubleClickTime, &n);
	NXWriteArray(stream, "i", n*2, map);
	NXWriteArray(stream, "c", n, enabled);
	NXWriteArray(stream, "c", n, functionEnabled);
	NXWriteArray(stream, "@", n, envelopes);
	NXWriteArray(stream, "c", n, mapThru);
	NXWriteArray(stream, "i", n, doubleClicks);
	return self;
}

- oldRead:(NXTypedStream *) stream
 /* Unarchive the notefilter from a typed stream. */
{
	int n, version;
	int i, j, numControls;
	int *activeMaps;
	id dummy;
	double x[9], y[9];
	BOOL exponential;
	double scale[6];
	int offset[6];

	version = NXTypedStreamClassVersion(stream, "Mapper");
	switch (version) {
		case 0:
			numControls = 133;
			break;
		case 1:
			numControls = 133;
			break;
		case 2:
			numControls = 136;
			break;
		case 3:
			numControls = 137;
			break;
		default:
			numControls = 138;
			break;
	}

	NXReadTypes(stream, "ci", &sequentialMapping, &n);
	NXReadArray(stream, "i", n * 2, map);
	activeMaps = malloc(sizeof(int)*n*numControls);
	NXReadArray(stream, "i", n * numControls, activeMaps);
	NXReadArray(stream, "i", numControls, activeMaps);
	free(activeMaps);
	NXReadArray(stream, "d", n, scale);
	NXReadArray(stream, "i", n, offset);
	NXReadArray(stream, "c", n, enabled);
	NXReadArray(stream, "c", n, mapThru);
	dummy = NXReadObject(stream);
	dummy = NXReadObject(stream);
	dummy = NXReadObject(stream);
	dummy = NXReadObject(stream);

	if (version > 1) {
		BOOL foo[n];
		NXReadTypes(stream, "d@", &doubleClickTime,
					&doubleClickTimeField);
		NXReadArray(stream, "c", n, foo);
		NXReadArray(stream, "i", n, doubleClicks);
		NXReadArray(stream, "i", n, clickCount);
		NXReadArray(stream, "d", n, lastNoteTime);
	}
	if (version > 5)
		NXReadTypes(stream, "c", &exponential);
		
	/* We've changed the ordering a bit in the controller name array */
	for (i=0; i<n; i++) {
		switch (map[0][i]) {
			case 132: map[0][i] = 129; break;	
			case 129:
			case 130:
			case 131: map[0][i]++; break;
			default: break;
		}
		switch (map[1][i]) {
			case 132: map[1][i] = 129; break;	
			case 129:
			case 130:
			case 131: map[1][i]++; break;
			default: break;
		}
	}

	for (i=0; i<n; i++) {
		if ((scale[i] != 1.0) || (offset[i] != 0)) {
			if ((i<5) || !exponential) {
				x[0] = 0.0;
				x[1] = 127.0;
				y[0] = offset[i];
				y[1] = offset[i] + 127.0*scale[i];
				j = 2;
			}
			else {
				for (j=0; j<8; j++) {
					x[j] = j*16;
					y[j] = offset[i] + (127.0 * pow((double)x[j] / 127.0, scale[i]));
				}
				x[8] = 127.0;
				y[8] = offset[i]+127.0;
				j = 9;
			}
			envelopes[i] = [[Envelope allocFromZone:[self zone]] init];
			[envelopes[i] setPointCount:j xArray:x yArray:y];
			functionEnabled[i] = YES;
		}
	}
	return self;
}

- read:(NXTypedStream *) stream
 /* Unarchive the notefilter from a typed stream. */
{
	int n, version;

	[super read:stream];
	version = NXTypedStreamClassVersion(stream, "Mapper");
	if (version < 7)
		return [self oldRead:stream];
	if (version == 7) {
		NXReadTypes(stream, "cdi", &sequentialMapping, &doubleClickTime, &n);
		NXReadArray(stream, "i", n * 2, map);
		NXReadArray(stream, "c", n, enabled);
		NXReadArray(stream, "c", n, functionEnabled);
		NXReadArray(stream, "@", n, envelopes);
		NXReadArray(stream, "c", n, mapThru);
		NXReadArray(stream, "i", n, doubleClicks);
	}
	return self;
}

- awake
 /* Initialize certain non-archived data */
{
	int i;
	[super awake];
	newNote = [[Note alloc] init];
	[newNote setNoteType:MK_noteUpdate];
	if (sequentialMapping) [self setupSequences];
	for (i=0; i<NUMMAPS; i++)
		if (mapThru[i]) {
			sendThru = YES;
			break;
		}
	return self;
}

- windowDidBecomeKey:sender
{
	if ((sender==inspectorPanel) && [[envelopeView window] isVisible]) 
		[[envelopeView window] orderWindow:NX_BELOW 
			relativeTo:[inspectorPanel windowNum]];
	else if ((sender==[envelopeView window]) && [inspectorPanel isVisible]) 
		[inspectorPanel orderWindow:NX_BELOW 
			relativeTo:[[envelopeView window] windowNum]];
	return self;
}

- envelopeModified:sender
{
	[document setEdited];
	return self;
}

/* The following are obsolete - defined for compatability with old archived documents */
- takeInputControllerFrom:sender {return self;}
- takeOutputControllerFrom:sender {return self;}
- takeScalingFrom:sender {return self;}
- takeOffsetFrom:sender {return self;}
- takeExponentialFrom:sender {return self;}

@end
