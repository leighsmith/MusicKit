/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#ifdef SHLIB
#include "shlib.h"
#endif

/*
  $Id$
  Original Author: David A. Jaffe
  
  Defined In: The MusicKit
  HEADER FILES: musickit.h
*/
/* Modification History:

   $Log$
   Revision 1.2  1999/07/29 01:16:42  leigh
   Added Win32 compatibility, CVS logs, SBs changes

   03/13/90/daj - Minor changes for new private category scheme.
   03/17/90/daj - Added settable PartRecorderClass
   04/21/90/daj - Small mods to get rid of -W compiler warnings.
   08/27/90/daj - API changes to support zones
   06/06/92/daj - Changed -freePartRecorders to refuse to do so if the
                  ScoreRecorder is in performance.
   01/13/96/daj - Added init of partRecorders in copyFromZone: 

*/

#import "_musickit.h"

#import "ConductorPrivate.h"
#import "PartRecorderPrivate.h"
#import "ScoreRecorderPrivate.h"

@implementation MKScoreRecorder: NSObject
  /* A pseudo-recorder that does its work by managing a set of PartRecorders.
   */
{
    id partRecorders; /* A Set of PartRecorders */
    id score;         /* The Score to which we're assigned. */   
    MKTimeUnit timeUnit;
    id partRecorderClass;
    BOOL compensatesDeltaT;
    BOOL _noteSeen;
    BOOL _reservedScoreRecorder2;
    void *_reservedScoreRecorder3;
}

#define _archiveScore _reservedScoreRecorder1 /* Unused */

+new
{
    self = [super allocWithZone:NSDefaultMallocZone()];
    [self init];
//    [self initialize]; //sb: removed. Unnec.
    return self;
}

#if 0
- (void)initialize 
  /* For backwards compatibility */
{ 
    
} 
#endif

-init
{
    [super init];
    timeUnit = MK_second;
    partRecorders = [[NSMutableArray alloc] init];
    partRecorderClass = [MKPartRecorder class];
    return self;
}

#define VERSION2 2
#define VERSION3 3 /* Changed Nov 7, 1992 */

+ (void)initialize
{
    if (self != [MKScoreRecorder class])
      return;
    [MKScoreRecorder setVersion:VERSION3];//sb: suggested by Stone conversion guide (replaced self)
    return;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
  /* TYPE: Archiving; Writes object.
     You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Archives partRecorders, timeUnit and partRecorderClass.
     Also optionally archives score using NXWriteObjectReference().
     */
{
    /*[super encodeWithCoder:aCoder];*/ /*sb: unnec */
    NSAssert((sizeof(MKTimeUnit) == sizeof(int)), @"write: method error.");
    [aCoder encodeObject:partRecorders];
    [aCoder encodeConditionalObject:score];
    [aCoder encodeValuesOfObjCTypes:"i#",&timeUnit,&partRecorderClass];
    [aCoder encodeValuesOfObjCTypes:"c",&compensatesDeltaT];
}

- (id)initWithCoder:(NSCoder *)aDecoder
  /* TYPE: Archiving; Reads object.
     You never send this message directly.  
     Should be invoked with NXReadObject(). 
     */
{
    int version; 
    /* [super initWithCoder:aDecoder];*/ /*sb: unnec */
    version = [aDecoder versionForClassName:@"ScoreRecorder"];
    if (version >= VERSION2) {
	partRecorders = [[aDecoder decodeObject] retain];
	score = [[aDecoder decodeObject] retain];
	[aDecoder decodeValuesOfObjCTypes:"i#",&timeUnit,&partRecorderClass];
    }
    if (version >= VERSION3) {
	[aDecoder decodeValuesOfObjCTypes:"c",&compensatesDeltaT];
    }
    return self;
}

-setScore:aScore
  /* Sets score over which we will sequence and creates PartRecorders for
     each Part in the Score. Note that any Parts added to aScore after
     the setScore call will not appear in the performance. */
{
    id aList;
    id el,newEl;
    unsigned n,i;
    if (aScore == score)
      return self;
    if ([self inPerformance])
      return nil;
    [self freePartRecorders];
    score = aScore;
    if (!aScore)
      return self;
    aList = [aScore parts];
    n = [aList count];
    for (i = 0; i < n; i++) {
        el = [aList objectAtIndex:i];
       	[partRecorders addObject:newEl = [partRecorderClass new]];
	[newEl setPart:el];
	_MKSetScoreRecorderOfPartRecorder(newEl,self);
        [newEl release]; /*sb */
    }
    return self;
}

-score
  /* Returns current score. */
{
    return score;
}

- copyWithZone:(NSZone *)zone
  /* Copies object. This involves copying firstTimeTag and lastTimeTag. 
     The score of the new object is set with setScore:, creating a new set 
     of partRecorders.
     */
{
//    ScoreRecorder *newObj = [super copyWithZone:zone];
    MKScoreRecorder *newObj = [[MKScoreRecorder allocWithZone:[self zone]] init];
    newObj->timeUnit = timeUnit;/* sb */
    newObj->partRecorderClass = partRecorderClass;
    [newObj->partRecorders autorelease]; /* sb: unfortunate duplication of array creation must be undone */
    newObj->partRecorders = [[NSMutableArray alloc] init]; /* 1/13/96 DAJ */
    [newObj setScore:score];
    return newObj;
}

-copy
{
    return [self copyWithZone:[self zone]];
}

static void unsetPartRecorders(MKScoreRecorder *self)
{
    unsigned n = [self->partRecorders count],i;
    for (i = 0; i < n; i++)
        _MKSetScoreRecorderOfPartRecorder([self->partRecorders objectAtIndex:i],nil);
    self->score = nil;
}

-freePartRecorders
  /* Frees all PartRecorders. */
{
    if ([self inPerformance])
      return nil;
    unsetPartRecorders(self);
    [partRecorders removeAllObjects];
    return self;
}

//#define FOREACH() for (el = NX_ADDRESS(partRecorders), n = [partRecorders count]; n--; el++)


-removePartRecorders
  /* Sets score to nil and removes all PartRecorders, but doesn't free them.
     Returns self.
     */
{
    unsetPartRecorders(self);
    [partRecorders removeAllObjects];
    return self;
}

- (void)dealloc
  /* Frees contained PartRecorders and self. */
{
    /*sb: FIXME!!! This is not the right place to decide whether or not to dealloc.
     * maybe need to put self in a global list of non-dealloced objects for later cleanup */
    if ([self inPerformance])
      return;
    [self freePartRecorders];
    [partRecorders release];
    [super dealloc];
}

- setDeltaTCompensation:(BOOL)yesOrNo /* default is NO */
{
    unsigned n,i;
    if ([self inPerformance] && (yesOrNo  != compensatesDeltaT))
      return nil;
    n = [partRecorders count];
    for (i = 0; i < n; i++)
        [[partRecorders objectAtIndex:i] setDeltaTCompensation:yesOrNo];

    compensatesDeltaT = yesOrNo;
    return self;
}

- (BOOL)compensatesDeltaT
{
    return compensatesDeltaT;
}

-(MKTimeUnit)timeUnit
  /* TYPE: Querying; Returns the receiver's recording mode.
   * Returns YES if the receiver is set to do post-tempo recording.
   */
{
    return timeUnit;
}

-setTimeUnit:(MKTimeUnit)aTimeUnit
{
    unsigned n = [partRecorders count],i;
    if ([self inPerformance] && (timeUnit != aTimeUnit))
      return nil;
    for (i = 0; i < n; i++)
        [[partRecorders objectAtIndex:i] setTimeUnit:aTimeUnit];
    timeUnit = aTimeUnit;
    return self;
}

-partRecorders
  /* TYPE: Processing
   * Returns a copy of the Array of the receiver's PartRecorder collection.
   * The PartRecorders themselves are not copied. It is the sender's
   * responsibility to free the Array.
   */
{
    return _MKLightweightArrayCopy(partRecorders);
}

-(BOOL)inPerformance
  /* YES if the receiver has received notes for realization during
     the current performance. */
{
    return (_noteSeen);
}    

-firstNote:aNote
  /* You receive this message when the first note is received in a given
     performance session, before the realizeNote:fromNoteReceiver: 
     message is sent. You may override this method to do whatever
     you like, but you should send [super firstNote:aNote]. 
     The default implementation returns self. */
{
    return self;
}
-afterPerformance 
  /* You may implement this to do any cleanup behavior, but you should
     send [super afterPerformance]. Default implementation
     does nothing. It is sent once after the performance. */
{
    return self;
}


-noteReceivers
 /* Creates and returns a List of the PartRecorders' NoteReceivers. The 
    NoteReceivers themselves are not copied. It is the sender's 
    responsibility to free the List. */
{
/*sb: the following is unbelievable! Why is this so convoluted?! */
/*    id *el;
    unsigned n;
    id aList = [[NSMutableArray alloc] init];
    IMP addImp = [aList methodForSelector:@selector(addObject:)];
    for (el = NX_ADDRESS(partRecorders), n = [partRecorders count]; n--; el++)
      (*addImp)(aList,@selector(addObject:),[*el noteReceiver]);
    return aList;
 */
    // this functionality is now embodied in _MKLightweigthArrayCopy()
    // return [[NSMutableArray arrayWithArray:partRecorders] retain];
    return _MKLightweightArrayCopy(partRecorders);
}

#if 0
-setArchiveScore:(BOOL)yesOrNo
 /* Archive part when the receiver or any object pointing to the receiver
    is archived. */  
{
    archiveScore = yesOrNo;
}

-(BOOL)archiveScore
  /* Returns whether part is archived whne the receiver or any object 
   pointing to the receiver is archived. */
{
    return archiveScore;
}
#endif

-partRecorderForPart:aPart
  /* Returns the PartRecorder for aPart, if found. */
{
    id el;
    unsigned n = [partRecorders count], i;
    for (i = 0; i < n; i++)
        if ((el = [[partRecorders objectAtIndex:i] part]) == aPart) return el;
    return nil;
}

-setPartRecorderClass:aPartRecorderSubclass
{
    if (!_MKInheritsFrom(aPartRecorderSubclass,[MKPartRecorder class]))
      return nil;
    partRecorderClass = aPartRecorderSubclass;
    return self;
}

-partRecorderClass
{
    return partRecorderClass;
}

@end


@implementation MKScoreRecorder(Private)

-(void)_firstNote:aNote
{
    if (!_noteSeen) {
	[MKConductor _afterPerformanceSel:@selector(_afterPerformance) 
       to:self argCount:0];
	[self firstNote:aNote];
	_noteSeen = YES;
    }
}

-_afterPerformance
  /* Sent by conductor at end of performance. Private */
{
    [self afterPerformance];
    _noteSeen = NO;
    return self;
}

@end

