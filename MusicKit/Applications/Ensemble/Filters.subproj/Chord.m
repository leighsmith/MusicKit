/* A NoteFilter subclass which maps chords to single notes */

#import <AppKit/AppKit.h>
#import <MusicKit/MusicKit.h>
#import <objc/HashTable.h>
#import "Chord.h"
#import "EnsembleApp.h"
#import "Preferences.h"
#import "ParamInterface.h"

@implementation Chord
{
}

+ initialize
 /* Set the version. This can be used in a later version to distinguish older
  * formats when unarchiving documents. 
  */
{
	[Chord setVersion:5];
	return self;
}

- loadNibFile
{
	[NXApp loadNibSection:"Chord.nib" owner:self];
	return self;
}

- setDefaults
{
	int i, j, k;
	[super setDefaults];
	for (i = 0; i < MAXCHORDSIZE; i++) {
		for (j = 0; j < 12; j++) {
			for (k = 0; k < NUMMAPS; k++)
				chordMap[k][j][i] = MAXINT;
		}
		for (j = 0; j < 512; j++)
			tagMap[j][i] = MAXINT;
	}
	for (k = 0; k < NUMMAPS; k++)
		for (i = 0; i < MAXCHORDSIZE; i++)
			controlVals[k][i] = 0;
	midiNoteSelection = NO;
	tagMapIndex = 0;
	octave = 5;
	controller = -1;
	noteController = -1;
	damping = YES;

	return self;
}
		
- init
 /* Called automatically when an instance is created. */
{

	[super init];
	hashTable = [[HashTable allocFromZone:[self zone]]
				 initKeyDesc:"i" valueDesc:"i" capacity:512];
	return self;
}

- awakeFromNib
{
	int i, j, n;
	[super awakeFromNib];
	[mapNumField setIntValue:currentSet+1];
	[mapChangeButtons selectCellWithTag:incrementing?1:0];
	[dampSwitch setState:damping];
	[controllerInterface setMode:CONTROLS];
	[noteInterface setMode:KEYNUMS];

	for (i = 0; i < 12; i++) {
		for (j = 0; j < MAXCHORDSIZE; j++)
			if ((n = chordMap[displayedSet][i][j]) != MAXINT)
				[noteInterface setIntValueAt:j :i to:60 + i + n];
		if (i == relativeNote)
			[[noteButtons cellAt:0:i] setState:1];
	}
	for (i = 0; i < MAXCHORDSIZE; i++)
		[[controlValFields cellAt:i :0] setIntValue:controlVals[displayedSet][i]];
	[controllerInterface setIntValueAt:0 to:controller];
	[controllerInterface setIntValueAt:1 to:noteController];
	return self;
}

- free
{
	[hashTable free];
	if (midiNoteSelection && [[NXApp preferences] multiThreaded]) {
		multiThreaded = YES;
		[NXApp reset:self];
	}
    [controllerInterface free];
    [noteInterface free];
	return [super free];
}

- enableNoteSelection:sender
{
	midiNoteSelection = [sender state];
	/*
	 * Can't draw in appkit from separate Music Kit thread, i.e., displaying
	 * the names of the notes keyed in from MIDI 
	 */
	if ([[NXApp preferences] multiThreaded]) {
		multiThreaded = !midiNoteSelection;
		[NXApp reset:self];
	}
	return self;
}

- takeRelativeNoteFrom:sender
{
	relativeNote = [[sender selectedCell] tag];
	note = relativeNote;
	[document setEdited];

	return self;
}

- clearTagTable
{
	int i, j, tag;
	id noteOff = [[Note alloc] init];

	[noteOff setNoteType:MK_noteOff];
	for (i = 0; i < 512; i++)
		if ((tag = tagMap[i][MAXCHORDSIZE]) != MAXINT) {
			[hashTable removeKey:(const void *)tag];
			for (j = 0; j < MAXCHORDSIZE; j++) {
				if ((tag = tagMap[i][j]) == MAXINT)
					break;
				[noteOff setNoteTag:tag];
				[noteSender sendNote:noteOff];
				tagMap[i][j] = MAXINT;
			}
			tagMap[i][MAXCHORDSIZE] = MAXINT;
		}
	[noteOff free];
	return self;
}

- selectSet:(int)setNumber
{
	if (setNumber < 0)
		setNumber = maxSetNum;
	else
		setNumber %= (maxSetNum + 1);
	if (setNumber != currentSet) {
		currentSet = setNumber;
		if (damping)
			[self clearTagTable];
	}
	return self;
}

- takeSetNumFrom:sender
 /* increment or decrement set by the sender's tag (-1 or 1) are indexed from
  * 0 but the interface names them from 1 
  */
{
	int i, j, n, set;

	set = MIN(MAX(displayedSet + [[sender selectedCell] tag], 0), 15);
	[mapNumField setIntValue:set + 1];
	if (set == displayedSet)
		return self;
	[inspectorPanel disableFlushWindow];
	for (i = 0; i < 12; i++)
		for (j = 0; j < MAXCHORDSIZE; j++)
			if ((n = chordMap[set][i][j]) != chordMap[displayedSet][i][j])
				[noteInterface setIntValueAt:j :i to:(n == MAXINT) ? -1 : 60 + i + n];
	for (j = 0; j < MAXCHORDSIZE; j++)
		[[controlValFields cellAt:j :0] setIntValue:controlVals[set][j]];
	[[inspectorPanel reenableFlushWindow] flushWindow];
	displayedSet = set;
	currentSet = displayedSet;
	if (damping)
		[self clearTagTable];

	return self;
}

- addNote:(int)n
{
	int i = 0;

	while ((i < MAXCHORDSIZE) &&
		   (chordMap[displayedSet][relativeNote][i] != MAXINT))
		i++;

	if (i < MAXCHORDSIZE) {
		chordMap[displayedSet][relativeNote][i] = n - (60 + relativeNote);
		[noteInterface setIntValueAt:i :relativeNote to:n];
		NXPing();
	}
	if (displayedSet > maxSetNum)
		maxSetNum = displayedSet;

	return self;
}

- takeKeyNumFrom:sender
{
	chordMap[displayedSet][[sender selectedCol]][[sender selectedRow]] = 
		[sender intValue];
	return self;
}

- clear:sender
{
	int i, j;

	[inspectorPanel disableFlushWindow];
	if ([[sender selectedCell] tag] == 0)
		for (i = 0; i < MAXCHORDSIZE; i++) {
			[noteInterface setIntValueAt:i :relativeNote to:-1];
			chordMap[displayedSet][relativeNote][i] = MAXINT;
		}
	else {
		for (j = 0; j < 12; j++)
			for (i = 0; i < MAXCHORDSIZE; i++) {
				[noteInterface setIntValueAt:i :j to:-1];
				chordMap[displayedSet][j][i] = MAXINT;
			}
		if (displayedSet == maxSetNum)
			maxSetNum = displayedSet - 1;
	}
	[[inspectorPanel reenableFlushWindow] flushWindow];

	[document setEdited];

	return self;
}

- takeProgramFrom:sender
 /* Obsolete */
{
	return self;
}

- takeControllerFrom:sender
 /* Change the MIDI controller adjustable from the interface object */
{
	switch ([sender selectedIndex]) {
		case 0: controller = [sender intValueAt:0]; break;
		case 1: noteController = [sender intValueAt:1]; break;
		default: break;
	}
	[document setEdited];
	return self;
}

- takeControlValFrom:sender
{
	id cell = [sender selectedCell];

	controlVals[currentSet][[cell tag]] = [cell doubleValue];
	return self;
}

- takeDampingFrom:sender
{
	damping = [sender state];
	return self;
}

- takeIncrementingFrom:sender
{
	incrementing = [[sender selectedCell] tag];
	return self;
}

- reset
{
	[super reset];
	if (inspectorPanel)
		[self selectSet:[mapNumField intValue] - 1];
	return self;
}

- realizeNote:aNote fromNoteReceiver:aNoteReceiver
 /* Here's where the work is done. */
{
	int key = MAXINT, relativeKey = MAXINT, tagIndex = MAXINT;
	int tag = [aNote noteTag];
	MKNoteType type = [aNote noteType];

	if (controller >= 0) {
		int val = getControlValAsInt(aNote, controller);
		if (val != MAXINT)
			[self selectSet:(incrementing) ? 
				((val > 0) ? currentSet + 1 : currentSet - 1) : val];
	}
	if (tag == MAXINT) {
		[noteSender sendNote:aNote];
		if ((type == MK_mute) &&
			(MKGetNoteParAsInt(aNote, MK_sysRealTime) == MK_sysReset))
			[self reset];
		return self;
	}
	if ((type == MK_noteOn) || (type == MK_noteDur)) {
		key = [aNote keyNum];
		if (midiNoteSelection) {
			[noteSender sendNote:aNote];
			[self addNote:key];
			return self;
		}
		relativeKey = key % 12;
	}
	if ([hashTable isKey:(const void *)tag])
		tagIndex = (int)[hashTable valueForKey:(const void *)tag];
	else if (key != MAXINT) {
		int *intervalptr = &chordMap[currentSet][relativeKey][0];

		if (*intervalptr != MAXINT) {
			int i;

			if ((++tagMapIndex) == 512)
				tagMapIndex = 0;
			/* If there's something there it must have been preempted by now. */
			if (((i = tagMap[tagMapIndex][MAXCHORDSIZE]) != MAXINT) &&
				[hashTable isKey:(const void *)i])
				[hashTable removeKey:(const void *)i];
			tagIndex = tagMapIndex;
			[hashTable insertKey:(const void *)tag value:(void *)tagIndex];
			i = 0;
			while (((*intervalptr++) != MAXINT) && (i < MAXCHORDSIZE))
				tagMap[tagIndex][i++] = MKNoteTag();
			tagMap[tagIndex][MAXCHORDSIZE] = tag;
		}
	}
	if (tagIndex != MAXINT) {
		id newNote = [aNote copy];
		int *tagptr = &tagMap[tagIndex][0];
		int i = 0;

		while ((*tagptr != MAXINT) && (i < MAXCHORDSIZE)) {
			if (noteController >= 0)
				setControlValToDouble(newNote, noteController, 
					controlVals[currentSet][i]);
			if (key != MAXINT)
				MKSetNoteParToInt(newNote, MK_keyNum,
								  key + chordMap[currentSet][relativeKey][i]);
			[newNote setNoteTag:*tagptr];
			[noteSender sendNote:newNote];
			if (type == MK_noteOff)
				*tagptr = MAXINT;
			tagptr++;
			i++;
		}
		[newNote free];
		if (type == MK_noteOff) {
			[hashTable removeKey:(const void *)tag];
			tagMap[tagIndex][MAXCHORDSIZE] = MAXINT;
		}
	} else
		[noteSender sendNote:aNote];

	return self;
}

- write:(NXTypedStream *) stream
 /* Archive the notefilter to a typed stream. */
{
	int n1 = MAXCHORDSIZE, n2 = NUMMAPS;

	if (midiNoteSelection)
		[enableInputButton performClick:self];

	[super write:stream];
	NXWriteTypes(stream, "iiiiiiiiiicc", &note, &octave, &relativeNote,
				 &currentSet, &displayedSet, &maxSetNum, &controller,
				 &n1, &n2, &noteController, &damping, &incrementing);
	NXWriteArray(stream, "i", n1 * n2 * 12, chordMap);
	NXWriteArray(stream, "d", n1 * n2, controlVals);
	return self;
}

- read:(NXTypedStream *) stream
 /* Unarchive the notefilter from a typed stream. */
{
	int n1, n2, version;
	BOOL tmp;
	int *tmpArray;
	id dummy;

	[super read:stream];
	version = NXTypedStreamClassVersion(stream, "Chord");

	if (version < 5) {
		if (version <= 1) {
			NXReadTypes(stream, "iiiiiic@@@@ii", &note, &octave, &relativeNote,
						&currentSet, &displayedSet, &maxSetNum,
						&tmp,
						&dummy, &mapNumField,
						&dummy, &enableInputButton,
						&n1, &n2);
			NXReadArray(stream, "i", n1 * n2 * 12, chordMap);
			NXReadArray(stream, "i", 512 * (n1 + 1), tagMap);
			NX_MALLOC(tmpArray, int, n2);
			NXReadArray(stream, "i", n2, tmpArray);
			NX_FREE(tmpArray);
			NX_MALLOC(tmpArray, int, 128);
			NXReadArray(stream, "i", 128, tmpArray);
			NX_FREE(tmpArray);
		} else {
			int i, j;
			int oldVals[NUMMAPS][MAXCHORDSIZE];
			NXReadTypes(stream, "iiiiiii@@@@iii@@", &note, &octave, &relativeNote,
						&currentSet, &displayedSet, &maxSetNum, &controller,
						&dummy, &mapNumField,
						&dummy, &enableInputButton,
						&n1, &n2, &noteController,
						&controlValFields, &dummy);
			NXReadArray(stream, "i", n1 * n2 * 12, chordMap);
			NXReadArray(stream, "i", 512 * (n1 + 1), tagMap);
			NXReadArray(stream, "i", n1*n2, oldVals);
			for (i=0; i<n2; i++)
				for (j=0; j<n1; j++)
					controlVals[i][j] = oldVals[i][j];
			if (version >= 3)
				NXReadTypes(stream, "c", &damping);
			if (version >= 4)
				NXReadTypes(stream, "c", &incrementing);
		}
	}
	else if (version == 5) {
		NXReadTypes(stream, "iiiiiiiiiicc", &note, &octave, &relativeNote,
						&currentSet, &displayedSet, &maxSetNum, &controller,
						&n1, &n2, &noteController, &damping, &incrementing);
		NXReadArray(stream, "i", n1 * n2 * 12, chordMap);
		NXReadArray(stream, "d", n1 * n2, controlVals);
	}
	return self;
}

- awake
 /* Initialize certain non-archived data */
{
	int i, j;
	[super awake];
	hashTable = [[HashTable allocFromZone:[self zone]]
				 initKeyDesc:"i" valueDesc:"i" capacity:512];
	for (i = 0; i < MAXCHORDSIZE; i++) {
		for (j = 0; j < 512; j++)
			tagMap[j][i] = MAXINT;
	}
	return self;
}

/* The following are obsolete - defined for compatability with old archived documents */
- takeNoteControllerFrom:sender {return self;}

@end
