/*
 $Id$
 Defined In: The MusicKit
 HEADER FILES: MusicKit.h

 CF: MKScorePerformer, MKPart

 Original Author: David A. Jaffe

 Copyright (c) 1988-1992, NeXT Computer, Inc.
 Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
 Portions Copyright (c) 1994 Stanford University
 Portions Copyright (c) 1999-2004, The MusicKit Project.
 */
/* Modification history before commital to the CVS repository:

04/21/90/daj - Small mods to get rid of -W compiler warnings.
08/23/90/daj - Changed to zone API.
12/04/90/daj - Fixed bug in copyFromZone: (thanks to lbj)
02/06/92/daj - Fixed bug in activate that could cause note before
firstTimeTag to play, if it's the last note.
06/29/93/daj - Fixed bug in activate that would cause the MKPerformer to
wait unnecessarily in the case where there are no notes
between firstTimeTag and lastTimeTag, but where there
is a note after lastTimeTag.
11/01/94/daj - Added argument to _partPerformerDidDeactivate:.
06/19/98/sb  - Changed noteIndex and noteCount to Array indices rather than addresses
this is because we can't use NX_ADDRESS to step through the
array contents any more. (OpenStep conversion)
*/

#import "_musickit.h"

#import "PartPrivate.h"
#import "ScorePerformerPrivate.h"
#import "MKPartPerformer.h"

@implementation MKPartPerformer

#import "timetagInclude.m"

void _MKSetScorePerformerOfPartPerformer(MKPartPerformer *aPP, id aSP)
{
  aPP->scorePerformer = aSP;
}

#define VERSION2 2

+ (void) initialize
{
    if (self == [MKPartPerformer class])
	[MKPartPerformer setVersion: VERSION2]; //sb: suggested by Stone conversion guide (replaced self)
}

static BOOL fastActivation = NO;

+ setFastActivation: (BOOL) yesOrNo
{
    fastActivation = YES;
    return self;
}

+ (BOOL) fastActivation
{
    return fastActivation;
}

- init
  /* You never send this message. Subclass may implement it but must
  send [super initialize] before doing its own initialization. Sent
  once when an instance is created. Creates the single noteSender
  and adds the noteSender to the superclass cltn. */
{
    self = [super init];
    if (self) {
	lastTimeTag = MK_ENDOFTIME;
	[self addNoteSender: [MKNoteSender new]];    /* The object's only MKNoteSender. */
    }
    return self;
}

- (void) encodeWithCoder: (NSCoder *) aCoder
/* TYPE: Archiving; Writes object.
  You never send this message directly.
  Should be invoked with NXWriteRootObject(). 
     Invokes superclass write: then archives firstTimeTag and lastTimeTag.
  Optionally archives part using NXWriteObjectReference().
  */
{
  [aCoder encodeConditionalObject: part];
  [aCoder encodeValuesOfObjCTypes: "dd", &firstTimeTag, &lastTimeTag];
  [aCoder encodeConditionalObject: scorePerformer];
}

- (id) initWithCoder: (NSCoder *) aDecoder
  /* You never send this message directly.
  Should be invoked via NXReadObject().
          See write:. */
{
  if ([aDecoder versionForClassName: @"MKPartPerformer"] == VERSION2) {
    part = [[aDecoder decodeObject] retain];
    [aDecoder decodeValuesOfObjCTypes: "dd", &firstTimeTag, &lastTimeTag];
    scorePerformer = [[aDecoder decodeObject] retain];
  }

  return self;
}

- (void) dealloc
  /* If receiver is a member of a MKScorePerformer or is active, returns self
  and does nothing. Otherwise frees the receiver. */
{
  /*sb: FIXME!!! This is not the right place to decide whether or not to dealloc.
  * maybe need to put self in a global list of non-dealloced objects for later cleanup */
  if ((status != MK_inactive) || scorePerformer) {
    NSLog(@"MkPart::dealloc  dealloc aborted - in performance. Fix!");
    return;
  }
  if (part)
    [part release];
  [super dealloc];
}

- copyWithZone: (NSZone *) zone;
       /* TYPE: Copying: Returns a copy of the receiver.
  * Creates and returns a new inactive MKPerformer as
  * a copy of the receiver.
  * The new object has the same timeShift and
  * duration values as the reciever. Its
  * time and nextPerform variables
  * are set to 0.0. It has its own noteSenders which contains
  * copies of the values in the receiver's collection. The copies are
* added to the collection by addNoteSender:.
  */
{
    MKPartPerformer *newObj = [super copyWithZone:zone];
    newObj->noteArray = nil;
    newObj->noteIndex = -1; /* sb: was NULL */
    newObj->noteCount = -1; /* sb: was NULL */
    newObj->scorePerformer = nil;
    //sb: do we need to retain and autorelease this? Or is this done
    // as part of [super copyWithZone:zone] ?
    return newObj;
}

- setPart: (MKPart *) aPart
    /* Sets MKPart over which we sequence.
    If the receiver is active, does nothing and returns nil. Otherwise
    returns self. */
{
    if (status != MK_inactive)
	return nil;
    [part release];
    part = [aPart retain];
    return self;
}

- (MKPart *) part
{
    return [[part retain] autorelease];
}

- activateSelf
  /* TYPE: Performing
  * Activates the receiver for a performance. The MKPart is snapshotted at
  * this time. Any subsequent changes to the MKPart will not affect the
  * current performance. Returns the receiver.
  */
     /*sb: I have had to change noteIndex and noteCount to Array indices rather than addresses.
  * this is because we can't use NX_ADDRESS to step through the array contents any more.
  */
{
    MKNote *tmpNote;
    double tTag = 0;
    
    if (!part)
	return nil;
    [part _addPerformanceObj: self];
    if (!fastActivation)
	noteArray = [[part notes] retain]; // notes returns an autoreleased array of new notes and needs retaining */
    else {
	[part sort];
	noteArray = [part notesNoCopy]; // this is autoreleased
    }
    
    noteIndex = 0;
    noteCount = [noteArray count];
    nextNote = nil;
    while (noteIndex != noteCount) {
	tmpNote = [noteArray objectAtIndex: noteIndex++];
	tTag = [tmpNote timeTag];
	if (tTag >= firstTimeTag) {
	    nextNote = tmpNote;
	    break;
	}
    }
    if (!nextNote || tTag > lastTimeTag) {
	if (!fastActivation)
	    [noteArray release];
	noteArray = nil;
	noteIndex = -1;
	noteCount = -1;
	[part _removePerformanceObj: self];
	return nil;
    }
    nextPerform = tTag;
    return self;
}

- (void) deactivate
  /* TYPE: Performing
    * Finalization method sent when receiver is deactivated.
    */
{
    [super deactivate];  // need to stop the performance.
    // TODO we have to do the casting since notesNoCopy returns an NSMutableArray
    // and noteArray is an NSArray, we should investigate why notesNoCopy returns a
    // mutable array, it should be the job of the method using the result to
    // reset it's mutability.
    if ((NSArray *) [part notesNoCopy] != noteArray) /* Was copied. */
	[noteArray release];
    noteArray = nil;
    noteIndex = noteCount = -1;
    [part _removePerformanceObj: self];
    [scorePerformer _partPerformerDidDeactivate: self];
}

-perform
  /* TYPE: Performing
    * Sends nextNote and specifies the next time to perform.
    * Returns the receiver. You never send this message directly to an instance.
    * Rather, it is invoked by the MKConductor.
    * You may override this method, e.g. to modify the note before it is
    * performed or to modify nextPerform,
    * but you must send [super perform] to perform the note.
    */
{
    double t = [nextNote timeTag];
    double tNew;
    MKNoteSender *noteSender = [self noteSender];
    
    if (performCount == 1 && (firstTimeTag > 0)) {  /* Send all noteUpdates up to now */
	int noteType;
	NSEnumerator *enumerator = [noteArray objectEnumerator];
	MKNote *aNote;
	
	while ((aNote = [enumerator nextObject])) {
	    if (aNote == nextNote)
		break;
	    noteType = [aNote noteType];
	    if (noteType == MK_noteUpdate || noteType == MK_mute)
		[noteSender sendNote: aNote];
	}
    }
    [noteSender sendNote: nextNote];
    if (noteIndex < noteCount) {
	nextNote = [noteArray objectAtIndex: noteIndex++];
	tNew = [nextNote timeTag];	
	nextPerform = tNew - t;
	if (tNew > lastTimeTag) {
	    [self deactivate];	
	}
    }
    else
	[self deactivate];	

    return self;
}

@end

