/* A performer which generates melodies based on fractal functions */

/* Changed gravity variables and related compuations to floats for speed */

#import <appkit/appkit.h>
#import <musickit/musickit.h>
#import <mididriver/midi_spec.h>
#import <math.h>
#import "WmFractal.h"
#import "FractalPerformer.h"
#import "EnsembleDoc.h"
#import "ParamInterface.h"

static id allNotesOff = nil;

typedef struct {
	@defs (Note)
} NoteId;
/* This is used to avoid a message send, for speed */
#define NOTE_TIMETAG(x) (((NoteId *)(x))->timeTag)

/* used to sort dynamic note set */

static int keyCompare(const void *note1, const void *note2)
{
	return [*(id *)note1 keyNum] - [*(id *)note2 keyNum];
}

static int timeCompare(const void *note1, const void *note2)
{
	return NOTE_TIMETAG(*(id *)note1) - NOTE_TIMETAG(*(id *)note2);
}

@implementation FractalPerformer:Performer
{
}

+ initialize
 /*
  * Set the version. This can be used in a later version to distinguish older
  * formats when unarchiving documents. 
  */
{
	[FractalPerformer setVersion:4];
	return self;
}

- reset
 /* clears the dynamic buffer, or restarts a static progression */
{
	int     i;

	lastKey = -1;
	lastNoteOnTime = 0;
	startTime = [conductor time];
	numDynamicNotes = 0;
	numDynamicNoteOns = 0;
	minNoteOns = 1;
	maxNoteOns = 1;
	minVelocity = 127;
	maxVelocity = 0;
	velocityRange = 0;
	minDuration = MK_ENDOFTIME;
	maxDuration =.1;
	nextPerform = 0.0;
	for (i = 0; i < 128; i++) {
		dynamicCounts[i] = 0;
		offTimes[i] = -1.0;
	}
	if (useDurations) {
		currentSet = 0;
		nextSetTime = startTime + nextPerform + setDurations[0];
	}
	else
		nextSetTime = MK_ENDOFTIME;
	setChange = NO;
	dynamicMinKey = 128;
	dynamicMaxKey = 0;
	tagIndex = 0;
	intervalChanged = NO;
	return self;
}

- init
 /* Called automatically when an instance is created. */
{
	int i, j;

	[super init];
	noteSender = [self addNoteSender:[[NoteSender alloc] init]];

	keynumFractal = [[WmFractal allocFromZone:[self zone]] init];
	dynamicsFractal = [[WmFractal allocFromZone:[self zone]] init];
	phrasingFractal = [[WmFractal allocFromZone:[self zone]] init];
	controllerFractal = [[WmFractal allocFromZone:[self zone]] init];
	[keynumFractal setDelegate:self];
	[dynamicsFractal setDelegate:self];
	[phrasingFractal setDelegate:self];
	[controllerFractal setDelegate:self];

	/* static mode stuff */
	for (i = 0; i < NUMSETS; i++) {
		setDurations[i] = 8.0;
		for (j = 0; j < 128; j++)
			gravities[i][j] = 1.0;
		for (j = 0; j < 12; j++)
			noteGravities[i][j] = 1.0;
	}
	for (i = 0; i < 128; i++)
		noteTags[i] = MKNoteTag();
	numTags = 128;
	for (i = 0; i < 32; i++)
		dynamicNotes[i] = nil;
	pitchSorting = YES;
	velocityTracking = 1;
	dynamicSetSize = 8;
	velGravityScale = 1.0;
	durGravityScale = 1.0;
	repGravityScale = 1.0;
	minKey = a3k;
	maxKey = c6k;
	minVel = 20;
	maxVel = 100;
	minVal = 0;
	maxVal = 127;
	valDiff = 127.0;
	silence = 0.2;
	controller = -1;
	dynamicMode = NO;
	tieRepeats = YES;
	conductor = [Conductor defaultConductor];
	noteon = [[Note alloc] init];
	[noteon setNoteType:MK_noteOn];
	if (!allNotesOff) {
		allNotesOff = [[Note alloc] init];
		[allNotesOff setNoteType:MK_noteUpdate];
		[allNotesOff setPar:MK_chanMode toInt:MK_allNotesOff];
		[allNotesOff setPar:MK_controlChange toInt:MIDI_ALLNOTESOFF];
	}
	noteInterval = 0.25;
	noteDuration = 0.30;
	nextPerform = noteInterval;
	[self reset];
	
	return self;
}

- free
{
	[self deactivate];
	[keynumFractal free];
	[dynamicsFractal free];
	[phrasingFractal free];
	[controllerFractal free];
	[noteon free];
	return [super free];
}

- setDynamicMode:(BOOL)state
{
	int     i;

	if (dynamicMode = state) {
		lastKey = -1;
		minVelocity = 128;
		maxVelocity = 0;
		velocityRange = 0;
		minDuration = MK_ENDOFTIME;
		maxDuration =.1;
		for (i = 0; i < 128; i++) {
			dynamicCounts[i] = 0;
			if (dynamicNotes[i])
				dynamicNotes[i] = [dynamicNotes[i] free];
		}
		numDynamicNotes = 0;
	}

	return self;
}

- (BOOL)dynamicMode
{
	return dynamicMode;
}

- setDelay:(double)delayTime
{
	delay = delayTime;
	return self;
}

- (double)delay
{
	return delay;
}

- recomputeStaticSets
{
	int     i, j, n, set;

	for (set = 0; set <= maxSetNum; set++) {
		n = 0;
		for (i = minKey; i <= maxKey; i++)
			if (noteSets[set][j = i % 12]) {
				notes[set][n] = i;
				gravities[set][n++] = noteGravities[set][j];
			}
		notesInSet[set] = n;
	}

	return self;
}

- (int)minKey
{
	return minKey;
}

- (int)maxKey
{
	return maxKey;
}

- setMinKey:(int)key
{
	minKey = key;
	if (!dynamicMode)
		[self recomputeStaticSets];
	return self;
}

- setMaxKey:(int)key
{
	maxKey = key;
	if (!dynamicMode)
		[self recomputeStaticSets];
	return self;
}

- setMinVelocity:(int)val
{
	minVel = val;
	return self;
}

- setMaxVelocity:(int)val
{
	maxVel = val;
	return self;
}

- (int)minVelocity
{
	return minVel;
}

- (int)maxVelocity
{
	return maxVel;
}

- setTieRepeats:(BOOL)state
{
	tieRepeats = state;
	return self;
}

- setNoRepeats:(BOOL)state
{
	noRepeats = state;
	return self;
}

- (BOOL)tieRepeats
{
	return tieRepeats;
}

- (BOOL)noRepeats
{
	return noRepeats;
}

- setNoteInterval:(double)interval
{
	noteInterval = interval;
	intervalChanged = YES;
	return self;
}

- (double)noteInterval
{
	return noteInterval;
}

- setNoteDuration:(double)aDuration
{
	noteDuration = aDuration;
	return self;
}

- (double)noteDuration
{
	return noteDuration;
}

- setRestMode:(int)mode
{
	restMode = mode;
	return self;
}

- (int)restMode
{
	return restMode;
}

- setSilence:(float)val
{
	silence = val;
	return self;
}

- (float)silence
{
	return silence;
}

- setMinControlVal:(int)val
{
	minVal = val;
	valDiff = (float)(maxVal - minVal) +.99;

	return self;
}

- setMaxControlVal:(int)val
{
	maxVal = val;
	valDiff = (float)(maxVal - minVal) +.99;

	return self;
}

- (int)minControlVal
{
	return minVal;
}

- (int)maxControlVal
{
	return maxVal;
}

- setController:(int)aController
{
	controller = aController;
	[Conductor lockPerformance];
	if (controller >= 0)
		[noteon setPar:MK_controlChange toInt:controller];
	else {
		[noteon removePar:MK_controlChange];
		[noteon removePar:MK_controlVal];
	}
	[Conductor unlockPerformance];

	return self;
}

- (int)controller
{
	return controller;
}

- setNumTags:(int)num
{
	numTags = num;
	return self;
}

- (int)numTags
{
	return numTags;
}

- setTransposition:(int)trans
{
	transposition = trans;
	return self;
}


/* ***  Static Mode Methods  *** */

- setStaticNote:(int)set key:(int)key enabled:(BOOL)flag
{
	int     i, j, n;
	BOOL   *noteSetPtr;
	int    *notePtr;
	float *noteGravPtr, *gravPtr;

	key %= 12;
	if (key >= 0) {
		if (flag && noteSets[set][key])
			noteGravities[set][key]++;
		noteSets[set][key] = flag;
	}
	n = 0;
	noteSetPtr = &noteSets[set][0];
	noteGravPtr = &noteGravities[set][0];
	notePtr = &notes[set][0];
	gravPtr = &gravities[set][0];
	for (i = minKey; i < maxKey; i++)
		if (*(noteSetPtr + (j = i % 12))) {
			*(notePtr + n) = i;
			*(gravPtr + (n++)) = *(noteGravPtr + j);
		}
	notesInSet[set] = n;
	if (n > 0)
		maxSetNum = MAX(set, maxSetNum);
	else if (set == maxSetNum)
		maxSetNum--;

	return self;
}

- setStaticGravity:(int)set key:(int)key gravity:(float)gravity
{
	int     i;

	noteGravities[set][key] = gravity;
	for (i = 0; i < notesInSet[set]; i++)
		gravities[set][i] =
			noteGravities[set][notes[set][i] % 12];

	return self;
}

- incrementStaticGravity:(int)set key:(int)key increment:(float)inc
{
	[self setStaticGravity:set key:key gravity:noteGravities[set][key] + inc];
	return self;
}

- (float)noteGravity:(int)set key:(int)aKey
{
	return noteGravities[set][aKey];
}

- selectStaticSet:(int)setNumber
{
	setNumber %= NUMSETS;
	if (currentSet != setNumber) {
		currentSet = setNumber;
		setChange = NO;
	}
	return self;
}

- (int)currentSet
{
	return currentSet;
}

- (int)maxSetNum
{
	return maxSetNum;
}

- (BOOL)noteState:(int)set key:(int)aKey
{
	return noteSets[set][aKey];
}

- (double)noteSetDuration:(int)set
{
	return setDurations[set];
}

- setSetDuration:(int)set :(double)aDuration
{
	if (useDurations && (!dynamicMode) && (set == currentSet))
		nextSetTime = nextSetTime - (setDurations[set] - aDuration);
	setDurations[set] = aDuration;

	return self;
}

- setUseDurations:(BOOL)state
{
	useDurations = state;
	if ((!dynamicMode) && useDurations) {
		nextSetTime = 0;
		currentSet -= 1;		/* "advance" to current set on next note */
	} else
		nextSetTime = MK_ENDOFTIME;

	return self;
}

- (BOOL)useDurations
{
	return useDurations;
}

- (int)staticIndexAtTime:(double)aTime
 /* return an index into the static note set for a given time */
{
	int     k;
	double  frac;
	int     n = notesInSet[currentSet];
	float  val;

	val = ((float)n -.001) * [keynumFractal generate:aTime] -.5;
	if (val <= 0.0)
		return 0;
	else if (val >= (float)(n - 1))
		return n - 1;
	k = (int)val;
	val -= k;
	frac = pow((double)val,
		(double)(gravities[currentSet][k] / gravities[currentSet][k + 1]));

	return (frac <.5) ? k : k + 1;
}

- advanceSet
 /* This happens one note in advance of when the set change takes effect */
{
	currentSet = ((currentSet >= maxSetNum) ? 0 : (currentSet + 1));
	nextSetTime = [conductor time] + nextPerform + setDurations[currentSet];
	setChange = YES;
	return self;
}

/* *** Dynamic Note Set Methods *** */

- setDynamicSetSize:(int)numNotes
{
	dynamicSetSize = numNotes;
	return self;
}

- (int)dynamicSetSize
{
	return dynamicSetSize;
}

- setAddOctaves:(BOOL)state
{
	addOctaves = state;
	return self;
}

- setUniqueNotes:(BOOL)state
{
	uniqueNotes = state;
	return self;
}

- setPitchSorting:(BOOL)state
{
	if (pitchSorting = state)
		qsort((void *)dynamicNotes, numDynamicNotes, sizeof(id), keyCompare);
	else
		qsort((void *)dynamicNotes, numDynamicNotes, sizeof(id), timeCompare);

	return self;
}

- setVelocityTracking:(char)mode
{
	velocityTracking = mode;
	return self;
}

- setVelGravityScale:(float)scale
{
	velGravityScale = scale;
	if (fabs(velGravityScale) < 0.01)
		velGravityScale = 0.0;
	return self;
}

- setDurGravityScale:(float)scale
{
	durGravityScale = scale;
	if (fabs(durGravityScale) < 0.01)
		durGravityScale = 0.0;
	return self;
}

- setRepGravityScale:(float)scale
{
	repGravityScale = scale;
	if (fabs(repGravityScale) < 0.01)
		repGravityScale = 0.0;
	return self;
}

- (float)velGravityScale
{
	return velGravityScale;
}

- (float)durGravityScale
{
	return durGravityScale;
}

- (float)repGravityScale
{
	return repGravityScale;
}

- keynumFractal
{
	return keynumFractal;
}

- dynamicsFractal
{
	return dynamicsFractal;
}

- phrasingFractal
{
	return phrasingFractal;
}

- controllerFractal
{
	return controllerFractal;
}

- inspectFractal:sender
{
	switch ([sender tag]) {
		case 0: [keynumFractal show:sender]; break;
		case 1: [dynamicsFractal show:sender]; break;
		case 2: [phrasingFractal show:sender]; break;
		case 3: [controllerFractal show:sender]; break;
		default: break;
	}
	return self;
}

- (char)velocityTracking
{
	return velocityTracking;
}

- (BOOL)pitchSorting
{
	return pitchSorting;
}

- (BOOL)uniqueNotes
{
	return uniqueNotes;
}

- (BOOL)addOctaves
{
	return addOctaves;
}

- updateCounts:(int)oldKey :(int)newKey
{
	register int n;
	int     numNotes = MIN(numDynamicNotes, dynamicSetSize);
	id *notep, *end;

	if (repGravityScale == 0.0)
		return self;
	dynamicCounts[newKey]++;
	if (oldKey >= 0)
		dynamicCounts[oldKey] = (uniqueNotes) ? 0 : dynamicCounts[oldKey] - 1;
	else if (dynamicCounts[newKey] > maxNoteOns) {
		maxNoteOns++;
		return self;
	}
	minNoteOns = MAXINT;
	maxNoteOns = 0;
	notep = dynamicNotes;
	end = notep + numNotes;
	while (notep < end) {
		n = dynamicCounts[[*notep++ keyNum]];
		if (n < minNoteOns)
			minNoteOns = n;
		if (n > maxNoteOns)
			maxNoteOns = n;
	}
	return self;
}

- updateVelocities:(int)oldVel :(int)newVel
{
	register int     v;
	int     numNotes = MIN(numDynamicNotes, dynamicSetSize);
	id *notep, *end;

	if ((velGravityScale == 0.0) && (velocityTracking != 1))
		return self;
	if (newVel < minVelocity)
		minVelocity = newVel;
	else if (oldVel == minVelocity) {
		minVelocity = 128;
		notep = dynamicNotes;
		end = notep + numNotes;
		while (notep < end)
			if ((v = MKGetNoteParAsInt(*notep++, MK_velocity)) < minVelocity)
				minVelocity = v;
	}
	if (newVel > maxVelocity)
		maxVelocity = newVel;
	else if (oldVel == maxVelocity) {
		maxVelocity = 0;
		notep = dynamicNotes;
		end = notep + numNotes;
		while (notep < end)
			if ((v = MKGetNoteParAsInt(*notep++, MK_velocity)) > maxVelocity)
				maxVelocity = v;
	}
	velocityRange = (float)(maxVelocity - minVelocity);
	return self;
}

- updateDurations:(double)oldDur :(double)newDur
{
	double  d;
	BOOL    maxSet = NO, minSet = NO;
	int     numNotes = MIN(numDynamicNotes, dynamicSetSize);
	id *notep, *end;

	if (durGravityScale == 0.0)
		return self;
	if (!MKIsNoDVal(newDur)) {
		if (newDur < minDuration) {
			minDuration = newDur;
			minSet = YES;
		}
		if (newDur > maxDuration) {
			maxDuration = newDur;
			maxSet = YES;
		}
	}
	if (!MKIsNoDVal(oldDur)) {
		if (!minSet && (oldDur == minDuration)) {
			minDuration = MK_ENDOFTIME;
			notep = dynamicNotes;
			end = notep + numNotes;
			while (notep < end) {
				d = [*notep dur];
				if (MKIsNoDVal(d))
					d = [conductor time] - NOTE_TIMETAG(*notep);
				if (d < minDuration)
					minDuration = d;
				notep++;
			}
		} else if (!maxSet && (oldDur == maxDuration)) {
			maxDuration = 0;
			notep = dynamicNotes;
			end = notep + numNotes;
			while (notep < end) {
				d = [*notep dur];
				if (MKIsNoDVal(d))
					d = [conductor time] - NOTE_TIMETAG(*notep);
				if (d > maxDuration)
					maxDuration = d;
				notep++;
			}
		}
	}
	return self;
}

- computeDynamicGravities
{
	register int i;
	id      note;
	double  dur;
	float  repeatScale;
	float  velocityScale;
	float  durationScale;
	double  now = [conductor time];
	int     numNotes = MIN(numDynamicNotes, dynamicSetSize);

	repeatScale = (!repGravityScale || (maxNoteOns == minNoteOns)) ? 0.0 :
		repGravityScale / (float)(maxNoteOns - minNoteOns);
	velocityScale = (!velGravityScale || (maxVelocity == minVelocity)) ? 0.0 :
		velGravityScale / velocityRange;
	durationScale = (!durGravityScale || (maxDuration == minDuration)) ? 0.0 :
		durGravityScale / (float)(maxDuration - minDuration);

	for (i = 0; i < numNotes; i++) {
		note = dynamicNotes[i];
		if (durationScale > 0.0) {
			dur = [note dur];
			if (MKIsNoDVal(dur))
				dur = MIN(now - NOTE_TIMETAG(note), maxDuration);
		} else
			dur = 0.0;
		dynamicGravities[i] = 1.0 +
			velocityScale * (float)(MKGetNoteParAsInt(note, MK_velocity) - minVelocity) +
			repeatScale * (float)(dynamicCounts[[note keyNum]] - minNoteOns) +
			durationScale * (float)(dur - minDuration);
	}

	return self;
}

- addNoteTimeSorted:note
{
	id      oldNote = nil;
	int     k = [note keyNum];

	if (numDynamicNotes == 32)
		/* remove oldest note (the last one) */
		oldNote = dynamicNotes[31];
	else
		numDynamicNotes++;

	memmove(dynamicNotes + 1, dynamicNotes, sizeof(id) * 31);
	*dynamicNotes = note;
	dynamicMinKey = MIN(dynamicMinKey, k);
	dynamicMaxKey = MAX(dynamicMaxKey, k);

	[self updateCounts:((oldNote) ?[oldNote keyNum] : -1) :[note keyNum]];
	[self updateVelocities:((oldNote) ? MKGetNoteParAsInt(oldNote, MK_velocity) : -1)
	  :MKGetNoteParAsInt(note, MK_velocity)];
	[self updateDurations:((oldNote) ?[oldNote dur] : -1) :[note dur]];
	[oldNote free];
	return self;
}

- addNotePitchSorted:note
{
	register int i = 0, n = 0;
	int     k = [note keyNum];
	id      oldNote = nil;

	while (numDynamicNotes >= dynamicSetSize) {
		/* remove oldest note (we have to look for it) */
		double  t;
		double  noteTime = MK_ENDOFTIME;
		id *notep = dynamicNotes;
		id *end = notep + numDynamicNotes;

		while (notep < end) {
			if ((t = NOTE_TIMETAG(*notep++)) < noteTime) {
				noteTime = t;
				n = i;
			}
			i++;
		}
		oldNote = dynamicNotes[n];
		if (n < (numDynamicNotes - 1)) {
			memmove(dynamicNotes + n, dynamicNotes + n + 1,
					sizeof(id) * (numDynamicNotes - (n + 1)));
		}
		numDynamicNotes--;
	}
	n = 0;
	while ((n < numDynamicNotes) && ([dynamicNotes[n] keyNum] < k))
		n++;
	memmove(dynamicNotes + n + 1, dynamicNotes + n, sizeof(id) * (numDynamicNotes - n));
	dynamicNotes[n] = note;
	numDynamicNotes++;
	dynamicMinKey = MIN(dynamicMinKey, k);
	dynamicMaxKey = MAX(dynamicMaxKey, k);
	[self updateCounts:((oldNote) ?[oldNote keyNum] : -1) :[note keyNum]];
	[self updateVelocities:((oldNote) ? MKGetNoteParAsInt(oldNote, MK_velocity) : -1)
	  :MKGetNoteParAsInt(note, MK_velocity)];
	[self updateDurations:((oldNote) ?[oldNote dur] : -1) :[note dur]];
	[oldNote free];

	return self;
}

- addDynamicNote:aNote
 /*
  * Add a note to the dynamic mode note set (if it's a noteOn), and update some
  * statistics on the set's durations, repetitions, and velocities.  Then
  * update the dynamic note gravities. 
  */
{
	int     i;
	double  now = [conductor time];
	MKNoteType type = [aNote noteType];
	int     tag = [aNote noteTag];
	id      noteOn;
	int     numNotes = MIN(numDynamicNotes, dynamicSetSize);

	if (type == MK_noteOn) {
		BOOL    newNote = YES;
		int     key = [aNote keyNum];

		if (uniqueNotes) {
			int     k;

			/* See if note is already part of the set. */
			for (i = 0; i < numNotes; i++) {
				k = [dynamicNotes[i] keyNum];
				if ((k == key) || (addOctaves && !((k - key) % 12))) {
					newNote = NO;
					break;
				}
			}
		}
		if (newNote) {
			[aNote setTimeTag:now];
			if (!addOctaves) {
				if (pitchSorting)
					[self addNotePitchSorted:[aNote copy]];
				else
					[self addNoteTimeSorted:[aNote copy]];
			} else {
				id      note;
				int     k = key % 12;

				for (k = key % 12; k < 128; k += 12) {
					if ((minKey <= k) && (k <= maxKey)) {
						note = [aNote copy];
						MKSetNoteParToInt(note, MK_keyNum, k);
						if (pitchSorting)
							[self addNotePitchSorted:note];
						else
							[self addNoteTimeSorted:note];
					}
				}
			}
		} else {
			int     oldVel = -1;
			int     newVel = MKGetNoteParAsInt(aNote, MK_velocity);

			i = 0;
			while (i < numNotes) {
				noteOn = dynamicNotes[i++];
				if (addOctaves && !((key - [noteOn keyNum]) % 12))
					[noteOn setNoteTag:tag];
				if (tag == [noteOn noteTag]) {
					[noteOn setTimeTag:now];
					oldVel = MKGetNoteParAsInt(noteOn, MK_velocity);
					MKSetNoteParToInt(noteOn, MK_velocity, newVel);
					[self updateCounts:-1:[noteOn keyNum]];
				}
			}
			[self updateVelocities:oldVel :newVel];
			lastNoteOnTime = now;
		}
	} else if (type == MK_noteOff) {
		i = 0;
		while (i < numNotes)
			if (tag == [noteOn = dynamicNotes[i++] noteTag]) {
				double  oldDur = [noteOn dur];
				double  dur = now - NOTE_TIMETAG(noteOn);

				[noteOn setDur:dur];
				[self updateDurations:oldDur :dur];
				break;
			}
	}
	[self computeDynamicGravities];
	return self;
}

- (int)dynamicIndexAtTime:(double)aTime
 /* return an index into the dynamic note set for a given time */
{
	int     k;
	double  frac;
	float val;
	float  numNotes = (float)MIN(numDynamicNotes, dynamicSetSize);

	val = numNotes * [keynumFractal generate:aTime] -.5;
	if (val <= 0.0)
		return 0;
	else if (val >= (numNotes - 1.0))
		return ((int)numNotes) - 1;
	k = val;
	val -= k;
	frac = pow((double)val, (double)(dynamicGravities[k] / dynamicGravities[k + 1]));

	return (frac <.5) ? k : k + 1;
}

- sendAndFreeNote:aNote
{
	if ((status == MK_active) || ([aNote noteType] == MK_noteOff))
		[noteSender sendAndFreeNote:aNote];
	else
		[aNote free];
	return self;
}

extern long random();

#define MAXRAN 2147483647.0
#define DRANDOM ((double)random()/MAXRAN)

- perform
{
	double  tmp;
	int     velocity, i, j;
	int     n = 1;
	int     key = lastKey;
	BOOL    rest = NO;
	double  currentTime = [conductor time];
	double  now = currentTime - startTime;
	int     numNotes = 0;
	id      note = (delay) ? [noteon copy] : noteon;

	if (!intervalChanged)
		nextPerform = noteInterval;
	else {
		float nextNoteTime;
		if (noteInterval > nextPerform)
			nextNoteTime = noteInterval * floor((now + nextPerform) / noteInterval + .5);
		else
			nextNoteTime = noteInterval * floor((now + noteInterval) / noteInterval +.5);
		nextPerform = nextNoteTime - now;
		intervalChanged = NO;
	}

	if (setChange) {
//		[noteSender sendNote:allNotesOff];
		setChange = NO;
	}
	if (silence > 0.0) {
		float  val = [phrasingFractal generate:now];
		rest = (restMode) ? (DRANDOM > (1.0 - val * silence)) : (val < silence);
	}
	if (!rest) {
		if (dynamicMode) {
			if (numNotes = MIN(numDynamicNotes, dynamicSetSize)) {
				i = [self dynamicIndexAtTime:now];
				key = [dynamicNotes[i] keyNum];
				if (numNotes > 1) {
					if (noRepeats && (key == lastKey)) {
						if (i == 0)
							j = 1;
						else if (i == (numNotes - 1))
							j = numNotes - 2;
						else if (([keynumFractal currentValue] -
							  [keynumFractal generate:now + nextPerform]) > 0)
							j = i - 1;
						else
							j = i + 1;
						key = [dynamicNotes[j] keyNum];
					} else if (tieRepeats && (key != lastKey)) {
						/* Compute duration by looking ahead for next note */
						tmp = now;
						j = i;
						while
							(i == (j = [self dynamicIndexAtTime:tmp += nextPerform]))
							n++;
					}
				}
			}
		} else if (notesInSet[currentSet]) {
			i = [self staticIndexAtTime:now];
			key = notes[currentSet][i];
			n = 1;
			/* look ahead if necessary */
			if (((tieRepeats && (key != lastKey)) ||
				 (noRepeats && (key == lastKey))) &&
				(notesInSet[currentSet] > 1)) {
				tmp = now;
				j = i;
				while ((tmp < nextSetTime) &&
					 (i == (j = [self staticIndexAtTime:tmp += nextPerform])))
					n++;
				if (noRepeats && (key == lastKey)) {
					key = notes[currentSet][j];
					n = 1;
				}
			}
			else if (tieRepeats && (notesInSet[currentSet]==1))
				n = floor((nextSetTime-currentTime)/nextPerform+.5);
		}
		else key = -1;
		if ((key >= 0) && ((key != lastKey) || !tieRepeats)) {
			float  val = [dynamicsFractal generate:now];

			if (dynamicMode && (velocityTracking == 1))
				velocity = minVelocity + (int)(velocityRange * val);
			else if (dynamicMode && (velocityTracking == 2)) {
				float  d = val * ((float)numNotes - 1.0001);
				int i, v1, v2;
				if (d < 0.0) d = 0.0;
				i = (int)d;

				v1 = MKGetNoteParAsInt(dynamicNotes[i], MK_velocity);
				if (numNotes > 1) {
					v2 = MKGetNoteParAsInt(dynamicNotes[i + 1], MK_velocity);
					velocity = v1 + (int)((float)(v2 - v1) * (d - (float)i));
				} else
					velocity = v1;
			} else
				velocity = minVel + (int)((float)(maxVel - minVel) * val);
			MKSetNoteParToInt(note, MK_keyNum, key+transposition);
			MKSetNoteParToInt(note, MK_velocity, velocity);
			if (noteDuration > 0.0) {
				tmp = ((double)(n-1)) * nextPerform + noteDuration;
				tmp = MIN(tmp, nextSetTime - currentTime);
				[note setDur:tmp];
			}
			else {
				[note setNoteType:MK_noteOn];
				tmp = 99999999.9;
			}
			if (numTags==128)
				[note setNoteTag:noteTags[key]];
			else {
				[note setNoteTag:noteTags[tagIndex++]];
				if (tagIndex == numTags) tagIndex = 0;
			}
			if (controller >= 0)
				setControlValToInt(note, controller,
					minVal + (int)(valDiff * [controllerFractal generate:now]));
			if (note == noteon)
				[noteSender sendNote:note];
			else
				[conductor sel:@selector(sendAndFreeNote:) to :self
				 	withDelay:delay argCount:1, note];
			offTimes[key] = currentTime + tmp;
			lastKey = key;
		}
	}
	if ((!dynamicMode) && useDurations &&
		((currentTime + nextPerform) >= nextSetTime -.001)) {
		[self advanceSet];
	}
	return self;
}

- notesOff
{
	int     key;
	double  currentTime = [conductor time];
	int     mink = (dynamicMode) ? dynamicMinKey : minKey;
	int     maxk = (dynamicMode) ? dynamicMaxKey : maxKey;
	id      note = [[[Note alloc] init] setNoteType:MK_noteOff];
	
	for (key = mink; key < maxk; key++)
		if (currentTime < offTimes[key]) {
			[note setNoteTag:noteTags[key]];
			[note setPar:MK_keyNum toInt:key];
			[noteSender sendNote:note];
		}
	[note free];

	return self;
}

- pause
{
	[self notesOff];
	return [super pause];
}

- activateSelf
 /*
  * Note that midi sysRealTime Start message can be used to start a group of
  * these things together. 
  */
{
	return [self reset];
}

/*
- deactivateSelf;
{
    return [self notesOff];
}
*/

- write:(NXTypedStream *) stream
 /* Archive the performer to a typed stream. */
{
	int n = NUMSETS;

	[super write:stream];
	NXWriteTypes(stream, "@@@@iiiciccccfffiiiicccddfiiidi", &keynumFractal,
				 &dynamicsFractal, &phrasingFractal, &controllerFractal,
				 &currentSet, &maxSetNum,
				 &restMode, &useDurations, &dynamicSetSize,
				 &addOctaves, &pitchSorting, &uniqueNotes, &velocityTracking,
				 &velGravityScale, &durGravityScale, &repGravityScale,
				 &minKey, &maxKey, &minVel, &maxVel,
				 &dynamicMode, &tieRepeats, &noRepeats,
				 &noteInterval, &noteDuration, &silence, 
				 &controller, &minVal, &maxVal, &delay, &n);
	NXWriteArray(stream, "c", n * 12, noteSets);
	NXWriteArray(stream, "f", n * 12, noteGravities);
	NXWriteArray(stream, "d", n, setDurations);
	NXWriteTypes(stream, "i", &numTags);
	return self;
}

- read:(NXTypedStream *) stream
 /* Unarchive the performer from a typed stream. */
{
	int n, version;
	id dummy;

	[super read:stream];
	version = NXTypedStreamClassVersion(stream, "FractalPerformer");
	if (version <= 2) {
		double dVGS, dDGS, dRGS, dSilence;
		NXReadTypes(stream, "@@@@@iiiciccccdddiiiicccdddiiidi", &keynumFractal,
				&dynamicsFractal, &phrasingFractal, &controllerFractal,
				&dummy, &currentSet, &maxSetNum,
				&restMode, &useDurations, &dynamicSetSize,
				&addOctaves, &pitchSorting, &uniqueNotes, &velocityTracking,
				&dVGS, &dDGS, &dRGS,
				&minKey, &maxKey, &minVel, &maxVel,
				&dynamicMode, &tieRepeats, &noRepeats,
				&noteInterval, &noteDuration,
				&dSilence, &controller, &minVal, &maxVal, &delay, &n);
		velGravityScale = dVGS;
		durGravityScale = dDGS;
		repGravityScale = dRGS;
		silence = dSilence;
	}
	else if (version == 3)
		NXReadTypes(stream, "@@@@@iiiciccccfffiiiicccddfiiidi", &keynumFractal,
				&dynamicsFractal, &phrasingFractal, &controllerFractal,
				&dummy, &currentSet, &maxSetNum,
				&restMode, &useDurations, &dynamicSetSize,
				&addOctaves, &pitchSorting, &uniqueNotes, &velocityTracking,
				&velGravityScale, &durGravityScale, &repGravityScale,
				&minKey, &maxKey, &minVel, &maxVel,
				&dynamicMode, &tieRepeats, &noRepeats,
				&noteInterval, &noteDuration,
				&silence, &controller, &minVal, &maxVal, &delay, &n);
	else
		NXReadTypes(stream, "@@@@iiiciccccfffiiiicccddfiiidi", &keynumFractal,
				&dynamicsFractal, &phrasingFractal, &controllerFractal,
				&currentSet, &maxSetNum,
				&restMode, &useDurations, &dynamicSetSize,
				&addOctaves, &pitchSorting, &uniqueNotes, &velocityTracking,
				&velGravityScale, &durGravityScale, &repGravityScale,
				&minKey, &maxKey, &minVel, &maxVel,
				&dynamicMode, &tieRepeats, &noRepeats,
				&noteInterval, &noteDuration,
				&silence, &controller, &minVal, &maxVal, &delay, &n);
	NXReadArray(stream, "c", n * 12, noteSets);
	if (version <= 2) {
    	double dNoteGravities[16][12];
		int i, j;
		NXReadArray(stream, "d", 16*12, dNoteGravities);
		for (i=0; i<16; i++)
			for (j=0; j<12; j++)
				noteGravities[i][j] = (float)dNoteGravities[i][j];
	}
	else
		NXReadArray(stream, "f", n * 12, noteGravities);
	NXReadArray(stream, "d", n, setDurations);
	if (version <= 1)
		delay = 0.0;
	if (version >= 4)
		NXReadTypes(stream, "i", &numTags);
	else numTags = 128;
	return self;
}

- awake
 /* Initialize certain non-archived data */
{
	int     i;
	[super awake];
	nextSetTime = MK_ENDOFTIME;
	noteSender = [self noteSender];
	conductor = [Conductor defaultConductor];
	
	[self reset];
	[self recomputeStaticSets];
	for (i = 0; i < 128; i++)
		noteTags[i] = MKNoteTag();
	noteon = [[Note alloc] init];
	[noteon setNoteType:MK_noteOn];
	if (!allNotesOff) {
		allNotesOff = [[Note alloc] init];
		[allNotesOff setNoteType:MK_noteUpdate];
		[allNotesOff setPar:MK_chanMode toInt:MK_allNotesOff];
	}
	if (controller >= 0)
		[self setController:controller];
	valDiff = (float)(maxVal - minVal) +.99;
	nextPerform = noteInterval;

	return self;
}

@end
