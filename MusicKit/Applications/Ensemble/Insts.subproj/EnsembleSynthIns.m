/* EnsembleSynthIns provides common functionality for all DSP instruments. */

#import "EnsembleSynthIns.h"
#import "EnsembleDoc.h"
#import "EnsembleApp.h"
#import "ParamInterface.h"
#import <musickit/SynthPatch.h>
#import <appkit/appkit.h>
#import <objc/HashTable.h>
#import <mididriver/midi_spec.h>

id sinePartials = nil;			/* A global sine wave Partials instance */
static id globalUpdateNote = nil;

@implementation EnsembleSynthIns:SynthInstrument
{
}

+ initialize
{
	double ars[1] = {1.0}, frs[1] = {1.0};

	sinePartials = [[Partials alloc] init];
	[sinePartials setPartialCount:1 freqRatios:frs ampRatios:ars
	 	phases:NULL orDefaultPhase:0];
	globalUpdateNote = [[[Note alloc] init] setNoteType:MK_noteUpdate];
	[EnsembleSynthIns setVersion:5];
	return self;
}

- loadNibFile
 /* load the interface file. */
{
	[self subclassResponsibility:_cmd];
	return self;
}

- setDefaults
{
	amp = 0.0;					/* That is, 0 dB "unity", actually -18 below
								 * maximum amplitude */
	bearing = 0.0;				/* Center */
	brightness = 0.75;
	patchAllocation = 3;
	testKey = 69;				/* A440 */
	velocitySensitivity = 0.5;	/* MIDI velocity sensitivity */
	aftertouchSensitivity = 0.0;/* MIDI after touch sensititvity */
	pitchbendSensitivity = 2.0;	/* MIDI pitch bend sensitivity */
	modwheelSensitivity = 1.0;	/* MIDI mod wheel sensitivity */
	breathSensitivity = 1.0;	/* MIDI breath sensitivity */
	panSensitivity = 1.0;		/* MIDI pan sensitivity */
	expressionSensitivity = 1.0;/* MIDI expression sensitivity */
	balanceSensitivity = 1.0;	/* MIDI balance sensitivity */
	MKSetNoteParToDouble(updates, MK_amp, MKdB(amp - 18.0));	/* "unity" == -18 dB */
	MKSetNoteParToDouble(updates, MK_bearing, bearing);
	MKSetNoteParToDouble(updates, MK_bright, brightness);
	MKSetNoteParToDouble(updates, MK_pitchBendSensitivity, pitchbendSensitivity);
	MKSetNoteParToDouble(updates, MK_velocitySensitivity, velocitySensitivity);
	MKSetNoteParToDouble(updates, MK_afterTouchSensitivity, aftertouchSensitivity);
	MKSetNoteParToDouble(updates, MK_modWheelSensitivity, modwheelSensitivity);
	MKSetNoteParToDouble(updates, MK_breathSensitivity, breathSensitivity);
	MKSetNoteParToDouble(updates, MK_panSensitivity, panSensitivity);
	MKSetNoteParToDouble(updates, MK_expressionSensitivity, expressionSensitivity);
	MKSetNoteParToDouble(updates, MK_balanceSensitivity, balanceSensitivity);
	return self;
}

- init
 /* Called automatically when an instance is created. */
{
	[super init];
	[self setRetainUpdates:YES];/* Don't clear updates after performances */
	/* The hashtable is used to store up noteoffs when damper pedal is on. */
	hashtable = [[HashTable alloc] initKeyDesc:"i" valueDesc:"@" capacity:128];
	[self setDefaults];
	[self loadNibFile];
	return self;
}

- awakeFromNib
 /* After the nib is loaded, initialize the various controls */
{
	char s[8];

	if (!view && window) {
		view = [window setContentView:nil];
		window = [window free];
	}
	[patchCountField setIntValue:patchAllocation];
	[sustainButton setState:damperButtonOn];
	[ampSlider setDoubleValue:amp];
	sprintf(s, "%+2ddB", (int)amp);
	[ampField setStringValue:s];
	[bearingField setDoubleValue:bearing];
	[bearingSlider setDoubleValue:bearing];
	[brightSlider setDoubleValue:brightness];
	[brightField setDoubleValue:brightness];
	[[brightField cell] setFloatingPointFormat:NO left:2 right:2];
	if (sensitivityInterface) {
		int n = [sensitivityInterface numValues];
		[sensitivityInterface setMode:DOUBLES];
		[sensitivityInterface setModeAt:0 to:INTS];
		if (n>0) [sensitivityInterface setDoubleValueAt:0 to:pitchbendSensitivity];
		if (n>1) [sensitivityInterface setDoubleValueAt:1 to:velocitySensitivity];
		if (n>2) [sensitivityInterface setDoubleValueAt:2 to:aftertouchSensitivity];
		if (n>3) [sensitivityInterface setDoubleValueAt:3 to:modwheelSensitivity];
		if (n>4) [sensitivityInterface setDoubleValueAt:4 to:breathSensitivity];
		if (n>5) [sensitivityInterface setDoubleValueAt:5 to:panSensitivity];
		if (n>6) [sensitivityInterface setDoubleValueAt:6 to:expressionSensitivity];
		if (n>7) [sensitivityInterface setDoubleValueAt:7 to:balanceSensitivity];
	}
	return self;
}

- free
{
	[Conductor lockPerformance];
	[self setSynthPatchCount:0];
	[Conductor unlockPerformance];
	if (inspector) {
		[inspector close];
		[inspector free];
	}
	if (hashtable)
		hashtable = [hashtable free];
	if (sensitivityInterface)
		[sensitivityInterface free];
	return [super free];
}

- addNoteReceiver:aNoteReceiver
	/* Override the Instrument method to add check for existance of the list */
{
	if (noteReceivers == nil) 
		noteReceivers = [[List allocFromZone:[self zone]] initCount:1];
	return [super addNoteReceiver:aNoteReceiver];
}

- getUpdates:(Note **) aNoteUpdate controllerValues:(HashTable **) controllers
{
	MKSetNoteParToString(updates, MK_synthPatch, (char *)[synthPatchClass name]);
	return [super getUpdates:aNoteUpdate controllerValues:controllers];
}

- setDocument:aDocument
{
	document = aDocument;
	orchestra = [Orchestra nthOrchestra:[document dspNum]];
	return self;
}

- showInspector:sender
 /* Display the parameter inspector window, if any. */
{
	if ([inspector windowNum] <= 0) {
		mouseDownSliders([inspector contentView]);
		[inspector center];
	}
	[inspector makeKeyAndOrderFront:self];
	return self;
}

- showParameters:sender
{
	return [self showInspector:sender];
}

- inspector
{
	return inspector;
}

- view
{
	return view;
}

- setPatchAllocation:(int)nPatches
{
	patchAllocation = nPatches;
	return self;
}

- (int)patchAllocation
{
	return patchAllocation;
}

- (int)synthPatchCount
 /* Return the synthpatch count for the current template. */
{
	return [self synthPatchCountForPatchTemplate:
		   [synthPatchClass patchTemplateFor:updates]];
}

- (int)setSynthPatchCount:(int)voices
 /* Set given number of synthpatches */
{
	return [self setSynthPatchCount:voices patchTemplate:
		   [[self synthPatchClass] patchTemplateFor:updates]];
}

- displayPatchCount
{
	if (patchAllocation != [patchCountField intValue])
		[patchCountField setIntValue:patchAllocation];
	return self;
}

- takePatchCountFrom:sender
 /*
  * Increment or decrement the patch count. re-synch the dsp and conductor. 
  */
{
	double dt = MKGetDeltaT();

	MKSetDeltaT(0);
	[Conductor lockPerformance];
	patchAllocation = [self setSynthPatchCount:
					   [self synthPatchCount] + [[sender selectedCell] tag]];
	[Conductor unlockPerformance];
	[self displayPatchCount];
	[document setEdited];
	NXPing();
	MKSetDeltaT(dt);
	[NXApp synchDSPDelayed:.5];
	return self;
}

- allocatePatches
{
	if ([orchestra deviceStatus] != MK_devClosed) {
		double dt = MKGetDeltaT();

		MKSetDeltaT(0);
		[Conductor lockPerformance];
		patchAllocation = [self setSynthPatchCount:patchAllocation];
		[Conductor unlockPerformance];
		MKSetDeltaT(dt);
	}
	return self;
}

/*  -------------------  GUI methods  -------------------------- */

- takeAmpFrom:sender
{
	char s[8];

	amp = [sender doubleValue];
	amp = MIN(amp, 18.0);
	[self updatePar:MK_amp asDouble:MKdB(amp - 18.0)];
	sprintf(s, "%+2ddB", (int)amp);
	[ampField setStringValue:s];
	if (sender == ampField)
		[ampSlider setDoubleValue:amp];
	[document setEdited];
	return self;
}

- takeBearingFrom:sender
{
	bearing = floor([sender doubleValue] +.5);
	bearing = MAX(MIN(bearing, 45.0), -45.0);
	[self updatePar:MK_bearing asDouble:bearing];
	[bearingField setDoubleValue:bearing];
	if (sender == bearingField)
		[bearingSlider setDoubleValue:bearing];
	[document setEdited];
	return self;
}

- takeBrightnessFrom:sender
{
	brightness = [sender doubleValue];
	[self updatePar:MK_bright asDouble:brightness];
	[brightField setDoubleValue:brightness];
	if (sender == brightField)
		[brightSlider setDoubleValue:brightness];
	[document setEdited];
	return self;
}

- takeSensitivityFrom:sender
 /*
  * Modify the velocity, aftertouch, pitchbend, and modwheel sensitivity.
  */
{
	double val = [sender doubleValue];
	MKPar parNum;

	switch ([sender selectedIndex]) {
		case 0:
			pitchbendSensitivity = val = floor(val +.5);
			parNum = MK_pitchBendSensitivity;
			break;
		case 1:
			velocitySensitivity = val;
			parNum = MK_velocitySensitivity;
			break;
		case 2:
			aftertouchSensitivity = val;
			parNum = MK_afterTouchSensitivity;
			break;
		case 3:
			modwheelSensitivity = val;
			parNum = MK_modWheelSensitivity;
			break;
		case 4:
			breathSensitivity = val;
			parNum = MK_modWheelSensitivity;
			break;
		case 5:
			panSensitivity = val;
			parNum = MK_panSensitivity;
			break;
		case 6:
			expressionSensitivity = val;
			parNum = MK_expressionSensitivity;
			break;
		case 7:
			balanceSensitivity = val;
			parNum = MK_balanceSensitivity;
			break;
		default:
			parNum = -1;
	}

	if (parNum >= MK_velocitySensitivity)
		[self updatePar:parNum asDouble:val];
	[document setEdited];
	return self;
}

- takeSustainFrom:sender
{
	damperButtonOn = (BOOL)[sender state];
	[self updateController:MIDI_DAMPER toValue:damperButtonOn ?  127 : 0];
	[document setEdited];
	return self;
}

- (int)testKey
{
	return testKey;
}

- allNotesOff
{
	BOOL damperWasOn = damperOn;

	[self updateController:MIDI_DAMPER toValue:0];
	if (taggedPatches) {
		const void *key;
		void *value;
		NXHashState state = [taggedPatches initState];
		id note = [updates copy];

		[Conductor lockPerformance];
		[note setTimeTag:[[Conductor defaultConductor] time]];
		[note setNoteType:MK_noteOff];
		while ([taggedPatches nextState:&state key:&key value:&value]) {
			[note setNoteTag:(int)key];
			[(SynthPatch *) value noteOff:note];

		}
		[Conductor unlockPerformance];
		if (hashtable) {
			/* it may have been freed in -free */
			[hashtable freeObjects];
			[hashtable empty];
		}
	}
	if (damperWasOn)
		[self updateController:MIDI_DAMPER toValue:127];
	return self;
}

- abort
{
	[super abort];
	if (hashtable) {
		/* it may have been freed in -free */
		[hashtable freeObjects];
		[hashtable empty];
	}
	return self;
}

- reset
{
	[self abort];
	if (damperOn != damperButtonOn)
		[self updateController:MIDI_DAMPER toValue:damperButtonOn ?  127 : 0];
	return self;
}

- realizeNote:aNote fromNoteReceiver:aNoteReceiver
 /*
  * While the damper pedal is down, intercept noteOffs and store copies of
  * them in a hashtable, keyed by note tag.  If a noteOn comes in with the
  * same tag as a noteOff already in the table, delete the noteOff. When the
  * pedal comes up, realize all the noteoffs in the hash table, free them, and
  * clear the table. 
  *
  * Also respond to allNotesOff and sysStop. 
  */
{
	MKNoteType type = [aNote noteType];
	int tag;

	if (type == MK_mute) {
		if (MKGetNoteParAsInt(aNote, MK_sysRealTime) == MK_sysReset)
			return [self reset];
		if (MKGetNoteParAsInt(aNote, MK_sysRealTime) == MK_sysStop)
			return [self allNotesOff];
	}
	/* Realize the note first if at all possible */
	if ((!damperOn) || (type != MK_noteOff))
		[super realizeNote:aNote fromNoteReceiver:aNoteReceiver];
	if (type == MK_noteUpdate) {
		if (MKIsNoteParPresent(aNote, MK_controlChange)) {
			int control = MKGetNoteParAsInt(aNote, MK_controlChange);
			int value = MKGetNoteParAsInt(aNote, MK_controlVal);

			if (control == MIDI_DAMPER) {
				damperOn = (value >= 64);
				/* Realize all the stored noteOffs if the pedal has come up */
				if (!damperOn) {
					int key;
					id note;
					NXHashState state = [hashtable initState];

					while ([hashtable nextState:&state key:(const void **)&key
							value:(void **)&note])
						[super realizeNote:note fromNoteReceiver:aNoteReceiver];
					[hashtable freeObjects];
					[hashtable empty];
				}
			} else if (control == MIDI_ALLNOTESOFF)
				[self allNotesOff];
		}
	} else if (damperOn) {
		/*
		 * Store copies of new noteOffs, and clear stored noteOffs for
		 * rearticulations 
		 */
		if (type == MK_noteOff)
			[hashtable insertKey:(const void *)[aNote noteTag]
			 value:(void *)[aNote copy]];
		else if ((type == MK_noteOn) &&
				 [hashtable isKey:(const void *)(tag = [aNote noteTag])]) {
			[(id)[hashtable valueForKey:(const void *)tag] free];
			[hashtable removeKey:(const void *)tag];
		}
	}
	return self;
}

- write:(NXTypedStream *) stream
 /* Archive the instrument to a typed stream. */
{
	[super write:stream];
	NXWriteTypes(stream, "iidddcddddddddc",
		  &testKey, &patchAllocation, &amp, &bearing, &brightness, &damperOn,
				 &velocitySensitivity, &aftertouchSensitivity,
				 &pitchbendSensitivity, &modwheelSensitivity,
				 &breathSensitivity, &panSensitivity,
				 &expressionSensitivity, &balanceSensitivity,
				 &damperButtonOn);
	return self;
}

- read:(NXTypedStream *) stream
 /* Unarchive the instrument from a typed stream. */
{
	int version;

	[super read:stream];
	version = NXTypedStreamClassVersion(stream, "EnsembleSynthIns");
	if (version <= 3) {
		id sensitivityFields;
		NXReadTypes(stream, "iddd@@@@@@@", &testKey,
					&velocitySensitivity, &aftertouchSensitivity,
					&pitchbendSensitivity, &inspector,
					&document, &view, &patchCountField,
					&ampField, &bearingField, &sensitivityFields);
		if (version > 1)
			NXReadTypes(stream, "i", &patchAllocation);
		if (version > 2)
			NXReadTypes(stream, "@", &sustainButton);
		amp = [ampField doubleValue];
		bearing = [bearingField doubleValue];
		pitchbendSensitivity = [[sensitivityFields cellAt:0 :0] doubleValue];
		velocitySensitivity = [[sensitivityFields cellAt:1 :0] doubleValue];
		aftertouchSensitivity = [[sensitivityFields cellAt:2 :0] doubleValue];
		damperOn = [sustainButton state];
		view = [view free];
	} else if (version == 4)
		NXReadTypes(stream, "iidddcdddddddd",
		  &testKey, &patchAllocation, &amp, &bearing, &brightness, &damperOn,
					&velocitySensitivity, &aftertouchSensitivity,
					&pitchbendSensitivity, &modwheelSensitivity,
					&breathSensitivity, &panSensitivity,
					&expressionSensitivity, &balanceSensitivity);
	else if (version == 5)
		NXReadTypes(stream, "iidddcddddddddc",
		  &testKey, &patchAllocation, &amp, &bearing, &brightness, &damperOn,
					&velocitySensitivity, &aftertouchSensitivity,
					&pitchbendSensitivity, &modwheelSensitivity,
					&breathSensitivity, &panSensitivity,
					&expressionSensitivity, &balanceSensitivity,
					&damperButtonOn);

	return self;
}

- awake
 /*
  * Initialize certain non-archived data. The subclass should load its nib
  * file here as well. 
  */
{
	[super awake];
	[self loadNibFile];
	hashtable = [[HashTable alloc] initKeyDesc:"i" valueDesc:"@" capacity:128];
	return self;
}

/* The following are obsolete - defined for compatability with old archived documents */
- takePedalFrom:sender {return self;}

@end
