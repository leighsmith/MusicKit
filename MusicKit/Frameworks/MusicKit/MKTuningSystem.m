/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description: 
    Each TuningSystem object manages a mapping from keynumbers to frequencies.
    There are MIDI_NUMKEYS individually tunable elements. The tuning system
    which is accessed by pitch variables is referred to as the "installed
    tuning system".

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2000 The MusicKit Project.
*/
/* 
Modification history:

  $Log$
  Revision 1.8  2001/08/07 16:11:16  leighsmith
  Corrected class name during en/decode to match latest MK prefixed name

  Revision 1.7  2001/07/02 16:48:49  sbrandon
  - added (Class)_transpose:(double)semitones method, identical to (Class)transpose:(double)semitones
    This is because GNUStep does not like sending messages to class objects
    that have the same method signature as some other instance method.

  Revision 1.6  2000/10/25 18:07:51  leigh
  Added Stephen's check for at least one entry in the array

  Revision 1.5  2000/10/01 06:41:30  leigh
  Tightened function prototyping.

  Revision 1.4  2000/05/13 17:17:50  leigh
  Added MKPitchNameForKeyNum()

  Revision 1.3  2000/04/25 22:08:41  leigh
  Converted from Storage to NSArray operation

  Revision 1.2  1999/07/29 01:16:44  leigh
  Added Win32 compatibility, CVS logs, SBs changes

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

#define MK_INLINE 1
#import "_musickit.h"  
#import "_MKNameTable.h"
#import "_ScorefileVar.h"
#import "tokens.h"
#import "TuningSystemPrivate.h"
//sb: (for MIDI_NUMKEYS in equaltempered */
#import "midi_spec.h"

@implementation MKTuningSystem

#import "equalTempered.m"

static BOOL tuningInited = NO;


static id pitchVars[MIDI_NUMKEYS] = {nil};   /* Mapping from keyNum to freq. 
					  Not necessarily monotonically 
					  increasing. */
  
typedef struct _freqMidiStruct {
    id freqId;
    int keyNum;
} freqMidiStruct;
  
static freqMidiStruct * freqToMidi[MIDI_NUMKEYS];  
/* Used for mapping freq to keyNum. This is kept sorted by frequency. */
  
static int
  freqCmp(p1,p2)
freqMidiStruct **p1, **p2;
{
    /* Function used by qsort below to compare frequencies. */
    double v1,v2;
    v1 = _MKParAsDouble(_MKSFVarGetParameter((*p1)->freqId));
    v2 = _MKParAsDouble(_MKSFVarGetParameter((*p2)->freqId));
    if (v1 < v2) return(-1);
    if (v1 > v2) return(1);
    return(0);
}      

static BOOL dontSort = NO; /* Used to override sort daemon when setting all
			      pitches at once. */

static void
sortPitches(obj)
    id obj;
{
    /* obj is a dummy argument needed by ScorefileVar class. 
       Sorts pitches array. */
    if (dontSort) 
      return;
    qsort(freqToMidi, MIDI_NUMKEYS, sizeof(freqMidiStruct *),freqCmp);
}

MKKeyNum MKFreqToKeyNum(double freq,int *bendPtr,double sensitivity)	
    /* Returns keyNum (pitch index) of closest pitch variable to the specified
       frequency . If bendPtr is not NULL, *bendPtr
       is set to the bend needed to get freq, given the current value
       of the scorefile variable bendAmount.
     */
{	
    /* Do a binary search for target. If bendPtr is not NULL, *bendPtr
       is set to the bend needed to get freq.
     */
#   define PITCH(x) \
    (_MKParAsDouble(_MKSFVarGetParameter(freqToMidi[(x)]->freqId)))

    register int low = 0; 
    register int high = MIDI_MAXDATA;
    register int tmp = MIDI_MAXDATA/2;
    int hit;
    if (!tuningInited)
      _MKCheckInit();
    while (low+1 < high) {
	tmp = (int) floor((double) (low + (high-low)/2));
	if (freq > PITCH(tmp))
	  low = tmp;
	else high = tmp;
    }
    if ((low == MIDI_MAXDATA) || 
	((freq/PITCH(low)) < (PITCH(low+1)/freq)))
      /* See comment below */
      hit = low;
    else hit = (low+1);
    if (bendPtr) {
	double tuningError = 12 * log(freq/PITCH(hit))/log(2.0);
	  /* tuning error is in semitones */
	double bendRatio = tuningError/sensitivity;
	bendRatio = MAX(MIN(bendRatio,1.0),-1.0);
	*bendPtr = (int)MIDI_ZEROBEND + (bendRatio * (int)0x1fff);
    }
    return(hit);
}

#if 0
static id addReadOnlyVar(NSString * name,int val)
{
    /* Add a read-only variable to the global parse table. */
    _ScorefileVar *rtnVal;
    _MKNameGlobal(name,rtnVal = 
		  _MKNewScorefileVar(_MKNewIntPar(val,MK_noPar),name,NO,YES),
		  _MK_typedVar,YES,YES);
    return rtnVal;
}
#endif


double
MKTranspose(double freq,double semiTonesUp)
    /* Transpose a frequency up by the specified number of semitones. 
       A negative value will transpose the note down. */
{
    return (freq*(pow(2.0, (((double) semiTonesUp) / 12.0))));
}

double 
MKKeyNumToFreq(MKKeyNum keyNum)
    /* Convert keyNum to frequency using the installed tuning system.
       Returns MK_NODVAL if keyNum is out of bounds. */
{
    if (keyNum > MIDI_NUMKEYS)
      return MK_NODVAL;
    keyNum = MIDI_DATA(keyNum);
    if (!tuningInited)
      _MKCheckInit();
    return _MKParAsDouble(_MKSFVarGetParameter(pitchVars[(int)keyNum]));
}

double 
MKAdjustFreqWithPitchBend(double freq,int pitchBend,double sensitivity)
    /* Return the result of adjusting freq by the amount specified in
       pitchBend. Sensitivity is in semitones. */
{
#   define SCL ((1.0/(double)MIDI_ZEROBEND))
    double bendAmount;
    if ((pitchBend == MIDI_ZEROBEND) || (pitchBend == MAXINT))
      return freq;
    bendAmount = (pitchBend - (int)MIDI_ZEROBEND) * sensitivity * SCL;
    if (bendAmount)
      return MKTranspose(freq,(double) bendAmount);
    return freq;
}

static id keyNumToId[MIDI_NUMKEYS] = {nil}; /* mapping from keyNum to the id
					  with its name. */

#define BINARY(_p) (_p && _p->_binary) 

static BOOL writeKeyNumNames = NO;

void MKWriteKeyNumNames(BOOL useKeyNumNames)
{
    writeKeyNumNames = useKeyNumNames;
}

NSString *MKPitchNameForKeyNum(int i)
{
    return [keyNumToId[i] varName];
}

BOOL _MKKeyNumPrintfunc(_MKParameter *param, NSMutableData *aStream, _MKScoreOutStruct *p)
{
    /* Used to write keyNum parameters. */
    int i = _MKParAsInt(param);
    if (!tuningInited)
        _MKCheckInit();
    if ((param->_uType == MK_envelope) || !writeKeyNumNames)
        return NO;
    if (BINARY(p))
        _MKWriteIntPar(aStream,i);
    else if ((i < 0) || (i > MIDI_NUMKEYS))
        [aStream appendData:[[NSString stringWithFormat:@"%d", i] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
    else
        [aStream appendData: [[NSString stringWithFormat:@"%@", MKPitchNameForKeyNum(i)] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
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
    if (!tuningInited)
      _MKCheckInit();
    frq = _MKParAsDouble(param);
    keyNum = MKFreqToKeyNum(frq,NULL,0);
    pitchName = [pitchVars[keyNum] varName];
    if (BINARY(p))
      _MKWriteVarPar(aStream,pitchName);
    else [aStream appendData:[pitchName dataUsingEncoding:NSNEXTSTEPStringEncoding]];
    return YES;
}    

static void install(NSArray *arrOFreqs) 
{
    unsigned int i;
    register id *idp = pitchVars;

    dontSort = YES;
    for(i = 0; i < MIDI_NUMKEYS; i++) {
        _MKSetDoubleSFVar(*idp++, [[arrOFreqs objectAtIndex: i] doubleValue]);
    }
    dontSort = NO;
    sortPitches(nil);
}

static void
addPitch(int keyNumValue, NSString *name, NSString *oct)
{
    /* Add a pitch to the music kit table. */
    _ScorefileVar *obj;
    NSString *s1, *s2;
    if (keyNumValue>=MIDI_NUMKEYS)
      return;
    s1 = [name stringByAppendingString:oct];//sb: was _MKMakeStrcat(name,oct);
    obj = _MKNewScorefileVar(_MKNewIntPar(keyNumValue,MK_noPar),
                             s2 = [s1 stringByAppendingString:@"k"],NO,YES); //s2 = _MKMakeStrcat(s1,"k")
    keyNumToId[keyNumValue] = obj;
    _MKNameGlobal(s2,obj,_MK_typedVar,YES,NO);
    obj = _MKNewScorefileVar(_MKNewDoublePar(0.0,MK_noPar),s1,NO,NO);
    _MKNameGlobal(s1,obj,_MK_typedVar,YES,NO);
    _MKSetScorefileVarPostDaemon(obj,sortPitches);
    pitchVars[keyNumValue] = obj;
}

static void
addAccidentalPitch(keyNumValue,name1,name2,oct1,oct2)
    int keyNumValue;
//  char * name1,*name2,*oct1,*oct2;
    NSString *name1,*name2,*oct1,*oct2;
{
    /* Add an accidental pitch to the musickit table, including
       its enharmonic equivalent as well. */
    _ScorefileVar *obj1;
    _ScorefileVar *obj2;
    _MKParameter *tmp;
//    char * sharpStr,*flatStr,*sharpKeyStr,*flatKeyStr;
    NSString * sharpStr,*flatStr,*sharpKeyStr,*flatKeyStr;
    if (keyNumValue>=MIDI_NUMKEYS)
      return;
    sharpStr = [name1 stringByAppendingString:oct1];//sb: was _MKMakeStrcat(name1,oct1);
    flatStr = [name2 stringByAppendingString:oct2];//sb: was _MKMakeStrcat(name2,oct2);
    obj1 = _MKNewScorefileVar(_MKNewIntPar(keyNumValue,MK_noPar),
                              sharpKeyStr = [sharpStr stringByAppendingString:@"k"],NO,YES);//sharpKeyStr = _MKMakeStrcat(sharpStr,"k")
    keyNumToId[keyNumValue] = obj1; /* Only use one in x-ref array */
    obj2 = _MKNewScorefileVar(_MKNewIntPar(keyNumValue,MK_noPar),
                              flatKeyStr = [flatStr stringByAppendingString:@"k"],NO,YES);
    _MKNameGlobal(sharpKeyStr,obj1,_MK_typedVar,YES,NO);
    _MKNameGlobal(flatKeyStr,obj2,_MK_typedVar,YES,NO);
    obj1 = _MKNewScorefileVar(tmp = _MKNewDoublePar(0.0,MK_noPar),sharpStr,
			      NO,NO);
    obj2 = _MKNewScorefileVar(tmp,flatStr,NO,NO);
    _MKNameGlobal(sharpStr,obj1,_MK_typedVar,YES,NO);
    _MKNameGlobal(flatStr,obj2,_MK_typedVar,YES,NO);
    _MKSetScorefileVarPostDaemon(obj1,sortPitches);
    _MKSetScorefileVarPostDaemon(obj2,sortPitches);
    pitchVars[keyNumValue] = obj1;
}

void _MKTuningSystemInit(void)
    /* Sent by MKInit1() */
{
    int i;
    static const char * octaveNames[] = {"00","0","1","2","3","4","5","6","7",
					   "8","9","10"};
    NSString * oct = [NSString stringWithCString:octaveNames[0]]; /* Pointer to const char */
    NSString * nOct = [NSString stringWithCString:octaveNames[1]];
    NSMutableArray *equalTempered12Array;

    if (tuningInited)
      return; 
    tuningInited = YES;
    i = 0;
    addPitch(i++,@"c",oct);       /* No low Bs */
    while (i<MIDI_NUMKEYS) {
	addAccidentalPitch(i++,@"cs",@"df",oct,oct);  
	addPitch(i++,@"d",oct); 	          
	addAccidentalPitch(i++,@"ds",@"ef",oct,oct);  
	addAccidentalPitch(i++,@"e",@"ff",oct,oct);  
	addAccidentalPitch(i++,@"f",@"es",oct,oct);  
	addAccidentalPitch(i++,@"fs",@"gf",oct,oct);  
	addPitch(i++,@"g",oct);            
	addAccidentalPitch(i++,@"gs",@"af",oct,oct);
	addPitch(i++,@"a",oct);
	addAccidentalPitch(i++,@"as",@"bf",oct,oct);
	addAccidentalPitch(i++,@"b",@"cf",oct,nOct);
	addAccidentalPitch(i,@"c",@"bs",nOct,oct);  
	oct = nOct;
	if (i < MIDI_NUMKEYS) nOct = [NSString stringWithCString:octaveNames[1 + i/12]];
	i++;
    }
    for (i=0; i<MIDI_NUMKEYS; i++) {  /* Init pitch x-ref. */
	_MK_MALLOC(freqToMidi[i], freqMidiStruct, 1);
	freqToMidi[i]->freqId = pitchVars[i];
	freqToMidi[i]->keyNum = i;
    }
    equalTempered12Array = [NSMutableArray arrayWithCapacity: MIDI_NUMKEYS];

    for(i=0; i < MIDI_NUMKEYS; i++) {
        [equalTempered12Array insertObject: [NSNumber numberWithDouble: equalTempered12[i]] atIndex: i];
    }
    install(equalTempered12Array);
}

#define VERSION2 2

+ (void)initialize
{
    if (self != [MKTuningSystem class])
      return;
    if (!tuningInited)
      _MKCheckInit();
    [MKTuningSystem setVersion:VERSION2];//sb: suggested by Stone conversion guide (replaced self)
    return;
}

+new
{
    self = [super allocWithZone:NSDefaultMallocZone()];
    [self init];
    return self;
}

-init
  /* Returns a new tuning system initialized to 12-tone equal tempered. */
{
    [super init];
    if (!tuningInited)
      _MKCheckInit();
    frequencies = [NSMutableArray arrayWithCapacity: MIDI_NUMKEYS];
    [frequencies retain];
    [self setTo12ToneTempered];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:frequencies];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ([aDecoder versionForClassName: @"MKTuningSystem"] == VERSION2) 
        frequencies = [[aDecoder decodeObject] retain];
    return self;
}

-setTo12ToneTempered
  /* Sets receiver to 12-tone equal-tempered tuning. */
{
    unsigned int i;
    NSNumber *newNum;
    int fCount = [frequencies count];

    for(i = 0; i < MIDI_NUMKEYS; i++) {
        newNum = [NSNumber numberWithDouble: equalTempered12[i]];
        if (fCount == 0) [frequencies addObject: newNum];
            else [frequencies replaceObjectAtIndex: i withObject: newNum];
    }
    /* Copy from equalTempered12 to us. */
    return self;
}

-install
  /* Installs the receiver as the current tuning system. Note, however,
     that any changes to the contents of the receiver are not automatically
     installed. You must send install again in this case. */
{
    install(frequencies);
    return self;
}

- (void)dealloc
{
    [frequencies release];
    [super dealloc];
}

- copyWithZone:(NSZone *)zone
  /* Returns a copy of receiver. */
{
//    TuningSystem *newObj = [super copyWithZone:zone];
    MKTuningSystem *newObj = NSCopyObject(self, 0, zone);//sb: must check for deep copying
    
    newObj->frequencies = [[NSMutableArray arrayWithArray: frequencies] retain];
    return newObj;
}

-copy
{
    return [self copyWithZone:[self zone]];
}

+installedTuningSystem
  /* Returns a new TuningSystem set to the values of the currently installed
     tuning system. Note, however, that this is a copy of the current values.
     Thus, altering the returned object does not alter the current values
     unless the -install message is sent. */
{
    return [[super allocWithZone:NSDefaultMallocZone()] initFromInstalledTuningSystem];
}

-initFromInstalledTuningSystem
{
    register int i;
    register id *pit;

    [super init];
    if (!tuningInited)
      _MKCheckInit();
    frequencies = [[NSMutableArray arrayWithCapacity: MIDI_NUMKEYS] retain];
    for (i=0, pit = pitchVars; i<MIDI_NUMKEYS; i++)
        [frequencies insertObject: [NSNumber numberWithDouble: _MKParAsDouble(_MKSFVarGetParameter(*pit++))] atIndex: i];
    return self;
}

+(double)freqForKeyNum:(MKKeyNum)aKeyNum
  /* Returns freq For specified keyNum in the installed tuning system.
     or MK_NODVAL if keyNum is illegal . */ 
{
    if (!tuningInited)
      _MKCheckInit();
    if (aKeyNum > MIDI_NUMKEYS)
      return MK_NODVAL;
    return _MKParAsDouble(_MKSFVarGetParameter(pitchVars[(int)aKeyNum]));
}

-(double)freqForKeyNum:(MKKeyNum)aKeyNum
  /* Returns freq For specified keyNum in the receiver or MK_NODVAL if the
     keyNum is illegal . */ 
{
    if (aKeyNum < 0 || aKeyNum > MIDI_NUMKEYS)
      return MK_NODVAL;
    return [[frequencies objectAtIndex: aKeyNum] doubleValue];
}

-setKeyNum:(MKKeyNum)aKeyNum toFreq:(double)freq
  /* Sets frequency for specified keyNum in the receiver. Note that the 
     change is not installed. */
{
    if (aKeyNum > MIDI_NUMKEYS)
      return nil;
    [frequencies insertObject: [NSNumber numberWithDouble: freq] atIndex: aKeyNum];
    return self;
}

+setKeyNum:(MKKeyNum)aKeyNum toFreq:(double)freq
  /* Sets frequency for specified keyNum in the installed tuning system.
     Note that if several changes are going to be made at once, it is more
     efficient to make the changes in a TuningSystem instance and then send
     the install message to that object. 
     Returns self or nil if aKeyNum is out of bounds. */
{
    if (!tuningInited)
      _MKCheckInit();
    if (aKeyNum > MIDI_NUMKEYS)
      return nil;
    _MKSetDoubleSFVar(pitchVars[(int)aKeyNum],freq);
    return self;
}

-setKeyNumAndOctaves:(MKKeyNum)aKeyNum toFreq:(double)freq
  /* Sets frequency for specified keyNum and all its octaves in the receiver.
     Returns self or nil if aKeyNum is out of bounds. */
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

+setKeyNumAndOctaves:(MKKeyNum)aKeyNum toFreq:(double)freq
  /* Sets frequency for specified keyNum and all its octaves in the installed
     tuning system.
     Note that if several changes are going to be made at once, it is more
     efficient to make the changes in a TuningSystem instance and then send
     the install message to that object. 
     Returns self or nil if aKeyNum is out of bounds. */
{	
    register int i;
    register double fact;
    if (aKeyNum > MIDI_NUMKEYS)
      return nil;
    if (!tuningInited)
      _MKCheckInit();
    dontSort = YES;
    for (fact = 1.0, i = aKeyNum; i >= 0; i -= 12, fact *= .5)
	_MKSetDoubleSFVar(pitchVars[i],freq * fact);
    for (fact = 2.0, i = aKeyNum + 12; i < MIDI_NUMKEYS; i += 12, fact *= 2.0)
	_MKSetDoubleSFVar(pitchVars[i],freq * fact);
    dontSort = NO;
    sortPitches(nil);
    return self;
}

int _MKFindPitchVar(id aVar)
    /* Returns keyNum corresponding to the specified pitch variable or
       MAXINT if none. */
{
    register int i;
    register id *pitch = pitchVars;
    _MKParameter *aPar;
    if (!aVar) 
      return MAXINT;
    aPar = _MKSFVarGetParameter(aVar); 
    for (i = 0; i < MIDI_NUMKEYS; i++)
      if (aPar == _MKSFVarGetParameter(*pitch++)) 
	return i; /* We must do it this way because of enharmonic equivalents*/
    return MAXINT;
}    

+(Class)_transpose:(double)semitones
  /* this is an unfortunate duplicate of the method below, because of gcc silliness
   * on GNUSTEP
   */
{
    register int i;
    register id *p = pitchVars;
    double fact = pow(2.0,semitones/12.0);
    dontSort = YES;
    if (!tuningInited)
      _MKCheckInit();
    for (i=0; i<MIDI_NUMKEYS; i++, p++)
      _MKSetDoubleSFVar(*p,_MKParAsDouble(_MKSFVarGetParameter(*p)) * fact);
    dontSort = NO;
    sortPitches(nil);
    return self;                                                                                                     }

+(Class)transpose:(double)semitones
  /* Transposes the installed tuning system by the specified amount.
     If semitones is positive, the installed tuning system is transposed
     up. If semitones is negative, the installed tuning system is transposed
     down. Semitones may be fractional.
     */
{
    register int i;
    register id *p = pitchVars;
    double fact = pow(2.0,semitones/12.0);
    dontSort = YES;
    if (!tuningInited)
      _MKCheckInit();
    for (i=0; i<MIDI_NUMKEYS; i++, p++) 
      _MKSetDoubleSFVar(*p,_MKParAsDouble(_MKSFVarGetParameter(*p)) * fact);
    dontSort = NO;
    sortPitches(nil);
    return self;
}

-transpose:(double)semitones
  /* Transposes the receiver by the specified amount.
     If semitones is positive, the receiver is transposed up.
     If semitones is negative, the receiver is transposed down.
     */
{
    unsigned int i;
    register double fact = pow(2.0,semitones/12.0);
    for(i = 0; i < MIDI_NUMKEYS; i++) {
        [frequencies replaceObjectAtIndex:i withObject:
            [NSNumber numberWithDouble: [[frequencies objectAtIndex: i] doubleValue] * fact]];
    }
    return self;
}

@end

