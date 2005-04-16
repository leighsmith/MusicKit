/*
 $Id$
 Defined In: The MusicKit
 HEADER FILES: MusicKit.h
 
 Description: 
 Each MKTuningSystem object manages a mapping from keynumbers to frequencies.
 There are MIDI_NUMKEYS individually tunable elements. The tuning system
 which is accessed by pitch variables is referred to as the "installed
 tuning system".
 
 TODO this should be restructured such that each instance is a tuning system that can be copied rather than
 installing an instance as the default. Then use +defaultTuningSystem or +twelveToneTempered to return an pristine instance.
 
 Original Author: David A. Jaffe
 
 Copyright (c) 1988-1992, NeXT Computer, Inc.
 Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
 Portions Copyright (c) 1994 Stanford University.
 Portions Copyright (c) 1999-2004 The MusicKit Project.
 */
/* 
Modification history prior to commit to CVS:
 
 09/22/89/daj - Removed addReadOnlyVar, which was never called.
 Changes corresponding to those in _MKNameTable.h.
 10/20/89/daj - Added binary scorefile support.
 11/27/89/daj - Optimized MKAdjustFreqWithPitchBend to check for
 no-bend case.
 01/02/90/daj - Deleted a comment.		      
 03/21/90/daj - Added archiving.
 04/21/90/daj - Small mods to get rid of -W compiler warnings.
 06/27/90/daj - Fix to setKeyNumAndOctaves:toFreq:.
 08/27/90/daj - Changed to zone API.
 09/02/90/daj - Changed MAXDOUBLE references to noDVal.h way of doing things
 10/09/90/daj - Changed [super new] to 
 [super allocFromZone:NXDefaultMallocZone()]
 10/09/90/daj - Added zone specification for installedTuningSystem.
 12/10/90/daj - Plugged memory leak in addAccidentalPitch
 05/31/92/daj - Changed "name" to "varName" to avoid conflict with Object.h
 9/08/92/daj - Fixed bug (!) in MKFreqToKeyNum's bend calculation.
 */

#import "_musickit.h"  
#import "_MKNameTable.h"
#import "_ScorefileVar.h"
#import "tokens.h"
#import "TuningSystemPrivate.h"
//sb: (for MIDI_NUMKEYS in equaltempered */
#import "midi_spec.h"

@implementation MKTuningSystem

#import "equalTempered.m" // for A=440Hz tunings in twelve tone equal temperament.

/* Mapping from keyNum to freq. Not necessarily monotonically increasing. */
static _ScorefileVar *pitchVars[MIDI_NUMKEYS] = { nil };   

typedef struct _freqMidiStruct {
    id freqId;
    int keyNum;
} freqMidiStruct;

/* Used for mapping freq to keyNum. This is kept sorted by frequency. */
static freqMidiStruct *freqToMidi[MIDI_NUMKEYS];  

/* Function used by qsort below to compare frequencies. */
static int freqCmp(const void *p1, const void *p2)
{
    double v1 = _MKParAsDouble(_MKSFVarGetParameter((*((freqMidiStruct **) p1))->freqId));
    double v2 = _MKParAsDouble(_MKSFVarGetParameter((*((freqMidiStruct **) p2))->freqId));
    if (v1 < v2) return(-1);
    if (v1 > v2) return(1);
    return(0);
}      

static BOOL dontSort = NO; /* Used to override sort daemon when setting all pitches at once. */

static void sortPitches(id obj)
{
    /* obj is a dummy argument needed by ScorefileVar class. Sorts pitches array. */
    if (dontSort) 
	return;
    qsort(freqToMidi, MIDI_NUMKEYS, sizeof(freqMidiStruct *), freqCmp);
}

+ (MKKeyNum) keyNumForFreq: (double) freq
	       pitchBentBy: (int *) bendPtr
	   bendSensitivity: (double) sensitivity
{	
#define PITCH(x) (_MKParAsDouble(_MKSFVarGetParameter(freqToMidi[(x)]->freqId)))
    register int low = 0; 
    register int high = MIDI_MAXDATA;
    register int tmp = MIDI_MAXDATA / 2;
    int hit;
    
    // Do a binary search for target. 
    while (low + 1 < high) {
	tmp = (int) floor((double) (low + (high - low) / 2));
	if (freq > PITCH(tmp))
	    low = tmp;
	else 
	    high = tmp;
    }
    if ((low == MIDI_MAXDATA) || ((freq / PITCH(low)) < (PITCH(low + 1) / freq)))
	/* See comment below */
	hit = low;
    else 
	hit = (low + 1);
    // If bendPtr is not NULL, *bendPtr is set to the bend needed to get freq.
    if (bendPtr) {
	double tuningError = 12 * log(freq / PITCH(hit)) / log(2.0);
	/* tuning error is in semitones */
	double bendRatio = tuningError / sensitivity;
	
	bendRatio = MAX(MIN(bendRatio, 1.0), -1.0);
	*bendPtr = (int) MIDI_ZEROBEND + (bendRatio * (int) 0x1fff);
    }
    return(hit);
}

/*
 Transpose a frequency up by the specified number of semitones of 12 tone equal temperament.
 A negative value will transpose the note down. */
double MKTranspose(double freq, double semiTonesUp)
{
    return (freq * (pow(2.0, (((double) semiTonesUp) / 12.0))));
}

double MKAdjustFreqWithPitchBend(double freq, int pitchBend, double sensitivity)
{
    double bendAmount;
    
    if ((pitchBend == MIDI_ZEROBEND) || (pitchBend == MAXINT))
	return freq;
    bendAmount = (pitchBend - (int) MIDI_ZEROBEND) * sensitivity * (1.0 / (double) MIDI_ZEROBEND);
    if (bendAmount)
	return MKTranspose(freq, (double) bendAmount);
    return freq;
}

static id keyNumToId[MIDI_NUMKEYS] = { nil }; /* mapping from keyNum to the id with its name. */

#define BINARY(_p) (_p && _p->_binary) 

static BOOL writeKeyNumNames = NO;

void MKWriteKeyNumNames(BOOL useKeyNumNames)
{
    writeKeyNumNames = useKeyNumNames;
}

+ (NSString *) pitchNameForKeyNum: (int) keyNum
{
    return [keyNumToId[keyNum] varName];
}

BOOL _MKKeyNumPrintfunc(_MKParameter *param, NSMutableData *aStream, _MKScoreOutStruct *p)
{
    /* Used to write keyNum parameters. */
    int i = _MKParAsInt(param);
    // NSString *pitchNameOrKeyNum;
    
    if ((param->_uType == MK_envelope) || !writeKeyNumNames)
        return NO;
    if (BINARY(p))
        _MKWriteIntPar(aStream, i);
    else if ((i < 0) || (i > MIDI_NUMKEYS))
        [aStream appendData: [[NSString stringWithFormat: @"%d", i] dataUsingEncoding: NSNEXTSTEPStringEncoding]];
    else
        [aStream appendData: [[NSString stringWithFormat: @"%@", [MKTuningSystem pitchNameForKeyNum: i]] dataUsingEncoding: NSNEXTSTEPStringEncoding]];
    // [aStream appendData: [pitchNameOrKeyNum dataUsingEncoding: NSNEXTSTEPStringEncoding]];
    return YES;
}    

static BOOL writePitches = NO;

void MKWritePitchNames(BOOL usePitchNames)
{
    writePitches = usePitchNames;
}

BOOL _MKFreqPrintfunc(_MKParameter *param, NSMutableData *aStream, _MKScoreOutStruct *p)
{
    /* Used to write keyNum parameters. */
    double frq;
    NSString *pitchName;
    int keyNum;
    
    if ((param->_uType == MK_envelope) || (!writePitches))
	return NO;
    frq = _MKParAsDouble(param);
    keyNum = [MKTuningSystem keyNumForFreq: frq pitchBentBy: NULL bendSensitivity: 0];
    pitchName = [pitchVars[keyNum] varName];
    if (BINARY(p))
	_MKWriteVarPar(aStream, pitchName);
    else 
	[aStream appendData: [pitchName dataUsingEncoding: NSNEXTSTEPStringEncoding]];
    return YES;
}    

static void install(NSArray *arrOFreqs) 
{
    unsigned int i;
    register _ScorefileVar **idp = pitchVars;
    
    dontSort = YES;
    for(i = 0; i < MIDI_NUMKEYS; i++) {
        _MKSetDoubleSFVar(*idp++, [[arrOFreqs objectAtIndex: i] doubleValue]);
    }
    dontSort = NO;
    sortPitches(nil);
}

static void addPitch(int keyNumValue, NSString *name, NSString *oct)
{
    /* Add a pitch to the music kit table. */
    _ScorefileVar *obj;
    NSString *s1, *s2;
    
    if (keyNumValue >= MIDI_NUMKEYS)
	return;
    s1 = [name stringByAppendingString: oct];
    s2 = [s1 stringByAppendingString: @"k"];
    obj = _MKNewScorefileVar(_MKNewIntPar(keyNumValue, MK_noPar), s2, NO, YES);
    keyNumToId[keyNumValue] = obj;
    _MKNameGlobal(s2, obj, _MK_typedVar, YES, NO);
    obj = _MKNewScorefileVar(_MKNewDoublePar(0.0, MK_noPar), s1, NO, NO);
    _MKNameGlobal(s1, obj, _MK_typedVar, YES, NO);
    _MKSetScorefileVarPostDaemon(obj, sortPitches);
    pitchVars[keyNumValue] = obj;
}

static void addAccidentalPitch(int keyNumValue, NSString *name1, NSString *name2, NSString *oct1, NSString *oct2)
{
    /* Add an accidental pitch to the pitch table, including its enharmonic equivalent as well. */
    _ScorefileVar *obj1;
    _ScorefileVar *obj2;
    _MKParameter *tmp;
    NSString *sharpStr, *flatStr, *sharpKeyStr, *flatKeyStr;
    
    if (keyNumValue >= MIDI_NUMKEYS)
	return;
    sharpStr = [name1 stringByAppendingString: oct1];
    flatStr = [name2 stringByAppendingString: oct2];
    sharpKeyStr = [sharpStr stringByAppendingString: @"k"];
    obj1 = _MKNewScorefileVar(_MKNewIntPar(keyNumValue, MK_noPar), sharpKeyStr, NO, YES);
    keyNumToId[keyNumValue] = obj1; /* Only use one in x-ref array */
    flatKeyStr = [flatStr stringByAppendingString: @"k"];
    obj2 = _MKNewScorefileVar(_MKNewIntPar(keyNumValue, MK_noPar), flatKeyStr, NO, YES);
    _MKNameGlobal(sharpKeyStr, obj1, _MK_typedVar, YES, NO);
    _MKNameGlobal(flatKeyStr, obj2, _MK_typedVar, YES, NO);
    tmp = _MKNewDoublePar(0.0, MK_noPar);
    obj1 = _MKNewScorefileVar(tmp, sharpStr, NO, NO);
    obj2 = _MKNewScorefileVar(tmp, flatStr, NO, NO);
    _MKNameGlobal(sharpStr, obj1, _MK_typedVar, YES, NO);
    _MKNameGlobal(flatStr, obj2, _MK_typedVar, YES, NO);
    _MKSetScorefileVarPostDaemon(obj1, sortPitches);
    _MKSetScorefileVarPostDaemon(obj2, sortPitches);
    pitchVars[keyNumValue] = obj1;
}

#define VERSION2 2

+ (void) initialize
{
    int keyNumber = 0;
    static const char *octaveNames[] = { "00", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" };
    NSString *oct = [NSString stringWithCString: octaveNames[0]]; /* Pointer to const char */
    NSString *nOct = [NSString stringWithCString: octaveNames[1]];
    NSMutableArray *equalTempered12Array;

    if (self != [MKTuningSystem class])
	return;

    addPitch(keyNumber++, @"c", oct);       /* No low Bs */
    while (keyNumber < MIDI_NUMKEYS) {
	addAccidentalPitch(keyNumber++, @"cs", @"df", oct, oct);  
	addPitch(keyNumber++, @"d", oct);
	addAccidentalPitch(keyNumber++, @"ds", @"ef", oct, oct);
	addAccidentalPitch(keyNumber++, @"e",  @"ff", oct, oct);
	addAccidentalPitch(keyNumber++, @"f",  @"es", oct, oct);
	addAccidentalPitch(keyNumber++, @"fs", @"gf", oct, oct);
	addPitch(keyNumber++, @"g", oct);           
	addAccidentalPitch(keyNumber++, @"gs", @"af",oct, oct);
	addPitch(keyNumber++, @"a", oct);
	addAccidentalPitch(keyNumber++, @"as", @"bf",oct, oct);
	addAccidentalPitch(keyNumber++, @"b",  @"cf",oct, nOct);
	addAccidentalPitch(keyNumber,   @"c",  @"bs", nOct, oct);  
	oct = nOct;
	if (keyNumber < MIDI_NUMKEYS)
	    nOct = [NSString stringWithCString: octaveNames[1 + keyNumber / 12]];
	keyNumber++;
    }
    for (keyNumber = 0; keyNumber < MIDI_NUMKEYS; keyNumber++) {  /* Init pitch x-ref. */
	_MK_MALLOC(freqToMidi[keyNumber], freqMidiStruct, 1);
	freqToMidi[keyNumber]->freqId = pitchVars[keyNumber];
	freqToMidi[keyNumber]->keyNum = keyNumber;
    }
    equalTempered12Array = [NSMutableArray arrayWithCapacity: MIDI_NUMKEYS];

    for(keyNumber = 0; keyNumber < MIDI_NUMKEYS; keyNumber++) {
	[equalTempered12Array insertObject: [NSNumber numberWithDouble: equalTempered12[keyNumber]] atIndex: keyNumber];
    }
    install(equalTempered12Array);
    [MKTuningSystem setVersion:VERSION2];//sb: suggested by Stone conversion guide (replaced self)
}

- init
    /* Returns a new tuning system initialized to 12-tone equal tempered. */
{
    self = [super init];
    if (self != nil) {
	frequencies = [[NSMutableArray alloc] initWithCapacity: MIDI_NUMKEYS];
	[self setTo12ToneTempered];
    }
    return self;
}

- (void) encodeWithCoder: (NSCoder *) aCoder
{
    // Check if decoding a newer keyed coding archive
    if([aCoder allowsKeyedCoding]) {
	[aCoder encodeObject: frequencies forKey: @"MKTuningSystem_frequencies"];
    }
    else {
	[aCoder encodeObject: frequencies];	
    }
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
    self = [self init];
    if (self != nil) {
	// Check if decoding a newer keyed coding archive
	if([aDecoder allowsKeyedCoding]) {
	    [frequencies release];
	    frequencies = [[aDecoder decodeObjectForKey: @"MKTuningSystem_frequencies"] retain];    
	}
	else {
	    if ([aDecoder versionForClassName: @"MKTuningSystem"] == VERSION2)
		frequencies = [[aDecoder decodeObject] retain];	    
	}
    }
    return self;
}

- (void) setTo12ToneTempered
    /* Sets receiver to 12-tone equal-tempered tuning. */
{
    unsigned int keyNumIndex;
    NSNumber *newNum;
    int fCount = [self keyCount];
    
    for(keyNumIndex = 0; keyNumIndex < MIDI_NUMKEYS; keyNumIndex++) {
        newNum = [NSNumber numberWithDouble: equalTempered12[keyNumIndex]];
        if (fCount == 0)
	    [frequencies addObject: newNum];
	else
	    [frequencies replaceObjectAtIndex: keyNumIndex withObject: newNum];
    }
}

- (int) keyCount
{
    return [frequencies count];
}

- install
    /* Installs the receiver as the current tuning system. Note, however,
    that any changes to the contents of the receiver are not automatically
    installed. You must send install again in this case. */
{
    install(frequencies);
    return self;
}

- (void) dealloc
{
    if (frequencies != nil) {
	[frequencies release];
	frequencies = nil;
    }
    [super dealloc];
}

- copyWithZone: (NSZone *) zone
    /* Returns a copy of receiver. */
{
//    MKTuningSystem *newObj = [super copyWithZone:zone];
    MKTuningSystem *newObj = NSCopyObject(self, 0, zone);//sb: must check for deep copying
    
    newObj->frequencies = [[NSMutableArray alloc] initWithArray: frequencies];
    return newObj;
}

- initFromInstalledTuningSystem
{
    register int i;
    register _ScorefileVar **pit;
    
    self = [super init];
    if (self != nil) {
	frequencies = [[NSMutableArray alloc] initWithCapacity: MIDI_NUMKEYS];
	for (i = 0, pit = pitchVars; i < MIDI_NUMKEYS; i++) {
	    double d = _MKParAsDouble(_MKSFVarGetParameter(*pit++));
	    [frequencies addObject: [NSNumber numberWithDouble: d]];
	}
    }
    return self;
}

/* Returns a new MKTuningSystem set to the values of the currently installed
tuning system. Note, however, that this is a copy of the current values.
Thus, altering the returned object does not alter the current values
unless the -install message is sent. */
+ (MKTuningSystem *) tuningSystem
{
    return [[[self alloc] initFromInstalledTuningSystem] autorelease];
}

+ (double) freqForKeyNum: (MKKeyNum) keyNumber
{
    // keyNum = MIDI_DATA(keyNum);

    if (keyNumber < 0 || keyNumber > MIDI_NUMKEYS)
	return MK_NODVAL;
    return _MKParAsDouble(_MKSFVarGetParameter(pitchVars[(int) keyNumber]));
}

/* Returns freq For specified keyNum in the receiver or MK_NODVAL if the keyNum is illegal. */ 
- (double) freqForKeyNum: (MKKeyNum) keyNumber
{
    if (keyNumber < 0 || keyNumber > MIDI_NUMKEYS)
	return MK_NODVAL;
    return [[frequencies objectAtIndex: keyNumber] doubleValue];
}

/* Sets frequency for specified keyNum in the receiver. Note that the change is not installed. */
- setKeyNum: (MKKeyNum) aKeyNum toFreq: (double) freq
{
    if (aKeyNum > MIDI_NUMKEYS)
	return nil;
    [frequencies insertObject: [NSNumber numberWithDouble: freq] atIndex: aKeyNum];
    return self;
}

/* Sets frequency for specified keyNum in the installed tuning system.
Note that if several changes are going to be made at once, it is more
efficient to make the changes in a MKTuningSystem instance and then send
the install message to that object. 
Returns self or nil if aKeyNum is out of bounds. */
+ setKeyNum: (MKKeyNum) aKeyNum toFreq: (double) freq
{
    if (aKeyNum > MIDI_NUMKEYS)
	return nil;
    _MKSetDoubleSFVar(pitchVars[(int)aKeyNum],freq);
    return self;
}

/* Sets frequency for specified keyNum and all its octaves in the receiver.
Returns self or nil if aKeyNum is out of bounds. */
- setKeyNumAndOctaves: (MKKeyNum) aKeyNum toFreq: (double) freq
{       
    register int i;
    register double fact;
    if (aKeyNum > MIDI_NUMKEYS)
	return nil;
    for (fact = 1.0, i = aKeyNum; i >= 0; i -= 12, fact *= .5)
        [frequencies replaceObjectAtIndex:i withObject: [NSNumber numberWithDouble: freq * fact]];
    for (fact = 2.0, i = aKeyNum + 12; i < MIDI_NUMKEYS; i += 12, fact *= 2.0)
        [frequencies replaceObjectAtIndex:i withObject: [NSNumber numberWithDouble: freq * fact]];
    return self;
}

/* Sets frequency for specified keyNum and all its octaves in the installed
tuning system.
Note that if several changes are going to be made at once, it is more
efficient to make the changes in a MKTuningSystem instance and then send
the install message to that object. 
Returns self or nil if aKeyNum is out of bounds. */
+ setKeyNumAndOctaves: (MKKeyNum) aKeyNum toFreq: (double) freq
{	
    register int i;
    register double fact;
    
    if (aKeyNum > MIDI_NUMKEYS)
	return nil;
    dontSort = YES;
    for (fact = 1.0, i = aKeyNum; i >= 0; i -= 12, fact *= .5)
	_MKSetDoubleSFVar(pitchVars[i],freq * fact);
    for (fact = 2.0, i = aKeyNum + 12; i < MIDI_NUMKEYS; i += 12, fact *= 2.0)
	_MKSetDoubleSFVar(pitchVars[i],freq * fact);
    dontSort = NO;
    sortPitches(nil);
    return self;
}

+ (int) findPitchVar: (id) aVar
{
    register int i;
    register _ScorefileVar **pitch = pitchVars;
    _MKParameter *aPar;
    
    if (!aVar) 
	return MAXINT;
    aPar = _MKSFVarGetParameter(aVar); 
    for (i = 0; i < MIDI_NUMKEYS; i++)
	if (aPar == _MKSFVarGetParameter(*pitch++)) 
	    return i; /* We must do it this way because of enharmonic equivalents*/
    return MAXINT;
}    

#ifdef GNUSTEP

+ (void) _transpose: (double) semitones
    /* this is an unfortunate duplicate of the method below, because of gcc silliness
    * on GNUSTEP
    */
{
#if 0
  [MKTuningSystem transpose: semitones];
#else
    register int keyNumIndex;
    register _ScorefileVar **p = pitchVars;
    double fact = pow(2.0, semitones / 12.0);
    
    dontSort = YES;
    for (keyNumIndex = 0; keyNumIndex < MIDI_NUMKEYS; keyNumIndex++, p++) 
	_MKSetDoubleSFVar(*p, _MKParAsDouble(_MKSFVarGetParameter(*p)) * fact);
    dontSort = NO;
    sortPitches(nil);
#endif
}

#endif

+ (void) transpose: (double) semitones
    /* Transposes the installed tuning system by the specified amount.
    If semitones is positive, the installed tuning system is transposed
    up. If semitones is negative, the installed tuning system is transposed
    down. Semitones may be fractional.
    */
{
    register int keyNumIndex;
    register _ScorefileVar **p = pitchVars;
    double fact = pow(2.0, semitones / 12.0);
    
    dontSort = YES;
    for (keyNumIndex = 0; keyNumIndex < MIDI_NUMKEYS; keyNumIndex++, p++) 
	_MKSetDoubleSFVar(*p, _MKParAsDouble(_MKSFVarGetParameter(*p)) * fact);
    dontSort = NO;
    sortPitches(nil);
}

- (void) transpose: (double) semitones
    /* Transposes the receiver by the specified amount.
    If semitones is positive, the receiver is transposed up.
    If semitones is negative, the receiver is transposed down.
    */
{
    unsigned int keyNumIndex;
    register double fact = pow(2.0, semitones / 12.0);
    for(keyNumIndex = 0; keyNumIndex < MIDI_NUMKEYS; keyNumIndex++) {
        [frequencies replaceObjectAtIndex: keyNumIndex withObject:
            [NSNumber numberWithDouble: [[frequencies objectAtIndex: keyNumIndex] doubleValue] * fact]];
    }
}

@end

