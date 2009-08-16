/*
  $Id$  
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description:
    A simple class which records MKNotes to a MKPart. That is, it acts as
    an MKInstrument that realizes MKNotes by adding them to its MKPart.
 
  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University  
  Portions Copyright (c) 1999-2005, The MusicKit Project.
*/
/* Modification History prior to commit to CVS repository:

   03/13/90/daj - Minor changes for new private category scheme.
   04/21/90/daj - Small mods to get rid of -W compiler warnings.
   08/27/90/daj - Changed to zone API.
*/

#import "_musickit.h"
#import "_noteRecorder.h"
#import "ConductorPrivate.h"
#import "InstrumentPrivate.h"
#import "PartPrivate.h"
#import "ScoreRecorderPrivate.h"

#import "MKPartRecorder.h"

@implementation MKPartRecorder

#import "noteRecorderMethods.m"

#define VERSION2 2
#define VERSION3 3 /* Changed Nov 7, 1992 */

+ (void) initialize
{
    if (self != [MKPartRecorder class])
      return;
    [MKPartRecorder setVersion: VERSION3]; //sb: suggested by Stone conversion guide (replaced self)
    return;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
  /* TYPE: Archiving; Writes object.
     You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Invokes superclass write: then archives timeUnit. 
     Optionally archives part using NXWriteObjectReference().
     */
{
    [super encodeWithCoder:aCoder];
    NSAssert((sizeof(MKTimeUnit) == sizeof(int)), @"write: method error.");
    [aCoder encodeValueOfObjCType:"i" at:&timeUnit];
    [aCoder encodeConditionalObject:part];
    [aCoder encodeConditionalObject:_scoreRecorder];
    [aCoder encodeValuesOfObjCTypes:"c",&compensatesDeltaT];
}

- (id)initWithCoder:(NSCoder *)aDecoder
  /* You never send this message directly.  
     Should be invoked via NXReadObject(). 
     See write:. */
{
    int version;
    [super initWithCoder:aDecoder];
    version = [aDecoder versionForClassName: @"MKPartRecorder"];
    if (version >= VERSION2) {
	[aDecoder decodeValueOfObjCType:"i" at:&timeUnit];
	part = [[aDecoder decodeObject] retain];
	_scoreRecorder = [[aDecoder decodeObject] retain];
    }
    if (version >= VERSION3) {
	[aDecoder decodeValuesOfObjCTypes:"c",&compensatesDeltaT];
    }
    /* from awake (sb) */
    noteReceiver = [self noteReceiver];
    
    return self;
}

- copyWithZone: (NSZone *) zone
{
    MKPartRecorder *newObj = [super copyWithZone:zone];
    newObj->noteReceiver = [newObj noteReceiver];
    return newObj;
}

/* If receiver is a member of a MKScoreRecorder or is in performance, 
     returns self and does nothing. Otherwise frees the receiver. */
- (void) dealloc
{
    if ([self inPerformance] || _scoreRecorder) {
	NSLog(@"Assertion failure, attempting deallocation of MKPartRecorder %p while still in performance\n", self);
    }
    [noteReceiver release];
    noteReceiver = nil;
    [super dealloc];
}

- init
  /* TYPE: Creating
   * This message is sent to when a new instance is created.
   * The default implementation returns the receiver and creates a single
   * NoteReceiver.
   * A subclass
   * implementation should first send [super init].
   */
{
    self = [super init];
    if(self != nil) {
	[self addNoteReceiver: noteReceiver = [MKNoteReceiver new]];
	timeUnit = MK_second;    
    }
    return self;
}

void _MKSetScoreRecorderOfPartRecorder(MKPartRecorder *aPR, id aSR)
{
    aPR->_scoreRecorder = aSR;
}

- (void) setPart: (MKPart *) aPart
  /* Sets MKPart to which notes are sent. */
{
    part = aPart;
}

- (MKPart *) part
{
    return part;
}

- _realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver
{
    if (!noteSeen) {
	[MKConductor _afterPerformanceSel: @selector(_afterPerformance) to: self argCount: 0];
	[_scoreRecorder _firstNote: aNote];
	// [part _addPerformanceObj: self];  // We used to do this, but it doesn't actually do anything and isn't correct wrt types.
	[self firstNote: aNote];
	noteSeen = YES;
    }
    return [self realizeNote: aNote fromNoteReceiver: aNoteReceiver];
}

/* Sent by conductor at end of performance. Private */
- _afterPerformance
{
    // [part _removePerformanceObj: self]; // We used to do this, but it doesn't actually do anything and isn't correct wrt types.
    [self afterPerformance];
    noteSeen = NO;
    return self;
}

/* Copies the note, adjusting its timetag and possibly adjusting its 
 duration according to tempo, then sends addNote: to the MKPart. 
*/
- realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver
{
    aNote = [aNote copyWithZone: NSDefaultMallocZone()];
    [aNote setTimeTag: _MKTimeTagForTimeUnit(aNote, timeUnit, compensatesDeltaT)];
    if ([aNote noteType] == MK_noteDur) 
        [aNote setDur: _MKDurForTimeUnit(aNote, timeUnit)];
    [part addNote: aNote];
    return self;
}

@end

