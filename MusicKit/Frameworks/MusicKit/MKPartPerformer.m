/*
 $Id$
 Defined In: The MusicKit
 HEADER FILES: MusicKit.h

 CF: MKScorePerformer, MKPart

 Original Author: David A. Jaffe

 Copyright (c) 1988-1992, NeXT Computer, Inc.
 Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
 Portions Copyright (c) 1994 Stanford University
 Portions Copyright (c) 1999-2000, The MusicKit Project.
 */
/* Modification history:

Pre CVS history:

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
06/19/98/sb  - Changed _loc and _endLoc to Array indices rather than addresses
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
  aPP->_scorePerformer = aSP;
}

#define VERSION2 2

+ (void)initialize
{
  if (self != [MKPartPerformer class])
    return;
  [MKPartPerformer setVersion:VERSION2];//sb: suggested by Stone conversion guide (replaced self)
    return;
}

static BOOL fastActivation = NO;

+setFastActivation:(BOOL)yesOrNo
{
  fastActivation = YES;
  return self;
}

+(BOOL)fastActivation
{
  return fastActivation;
}

-init
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

- (void)encodeWithCoder:(NSCoder *)aCoder
                /* TYPE: Archiving; Writes object.
  You never send this message directly.
  Should be invoked with NXWriteRootObject(). 
     Invokes superclass write: then archives firstTimeTag and lastTimeTag.
  Optionally archives part using NXWriteObjectReference().
  */
{
  [aCoder encodeConditionalObject: part];
  [aCoder encodeValuesOfObjCTypes: "dd", &firstTimeTag, &lastTimeTag];
  [aCoder encodeConditionalObject: _scorePerformer];
}

- (id)initWithCoder:(NSCoder *)aDecoder
  /* You never send this message directly.
  Should be invoked via NXReadObject().
          See write:. */
{
  if ([aDecoder versionForClassName: @"MKPartPerformer"] == VERSION2) {
    part = [[aDecoder decodeObject] retain];
    [aDecoder decodeValuesOfObjCTypes: "dd", &firstTimeTag, &lastTimeTag];
    _scorePerformer = [[aDecoder decodeObject] retain];
  }

  return self;
}

- (void)dealloc
  /* If receiver is a member of a MKScorePerformer or is active, returns self
  and does nothing. Otherwise frees the receiver. */
{
  /*sb: FIXME!!! This is not the right place to decide whether or not to dealloc.
  * maybe need to put self in a global list of non-dealloced objects for later cleanup */
  if ((status != MK_inactive) || _scorePerformer) {
    NSLog(@"MkPart::dealloc  dealloc aborted - in performance. Fix!");
    return;
  }
  if (part)
    [part release];
  [super dealloc];
}

- copyWithZone:(NSZone *)zone;
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
  newObj->_list = nil;
  newObj->_loc = -1; /* sb: was NULL */
  newObj->_endLoc = -1; /* sb: was NULL */
  newObj->_scorePerformer = nil;
  return newObj; 	//sb: do we need to retain and autorelease this? Or is this done
                  // as part of [super copyWithZone:zone] ?
}

- setPart: (MKPart*) aPart
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

- (MKPart*) part
  /* Gets MKPart over which we sequence. */
{
  return [[part retain] autorelease];
}

- activateSelf
  /* TYPE: Performing
  * Activates the receiver for a performance. The MKPart is snapshotted at
  * this time. Any subsequent changes to the MKPart will not affect the
  * current performance. Returns the receiver.
  */
     /*sb: I have had to change _loc and _endLoc to Array indices rather than addresses.
  * this is because we can't use NX_ADDRESS to step through the array contents any more.
  */
{
  id tmpNote;
  double tTag = 0;
  if (!part)
    return nil;
  [part _addPerformanceObj:self];
  if (!fastActivation)
    _list = [[part notes] retain];/*sb: "notes" used to return a new list. Now it's autoreleased and needs retaining */
  else {
    [part sort];
    _list = [part notesNoCopy]; /* this is autoreleased */
  }

  _loc = 0; //NX_ADDRESS(_list);
  _endLoc = [_list count]; // + _loc
  nextNote = nil;
  while (_loc != _endLoc) {
    tmpNote = [_list objectAtIndex:_loc++]; //*_loc++;
    tTag = [tmpNote timeTag];
    if (tTag >= firstTimeTag) {
      nextNote = tmpNote;
      break;
    }
  }
  if (!nextNote || tTag > lastTimeTag) {
    if (!fastActivation)
      [_list release];
    _list = nil;
    _loc = _endLoc = -1;//sb: was NULL;
      [part _removePerformanceObj:self];
      return nil;
  }
  //  nextPerform = tTag - firstTimeTag;
  nextPerform = tTag;
  return self;
}

- (void)deactivate
  /* TYPE: Performing
  * Finalization method sent when receiver is deactivated.
  * Returns the receiver.
  */
{
  [super deactivate];  // added by LMS - never stopped the performance.
  // TODO we have to do the casting since notesNoCopy returns an NSMutableArray
  // and _list is an NSArray, we should investigate why notesNoCopy returns a
  // mutable array, it should be the job of the method using the result to
  // reset it's mutability.
  if ((NSArray *) [part notesNoCopy] != _list) /* Was copied. */
    [_list release];
  _list = nil;
  _loc = _endLoc = -1;//sb: was NULL;
    [part _removePerformanceObj:self];
    [_scorePerformer _partPerformerDidDeactivate:self];
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
    int nt;
    NSEnumerator *enumerator = [_list objectEnumerator];
    MKNote *aNote;

    while ((aNote = [enumerator nextObject])) {
      if (aNote == nextNote)
        break;
      nt = [aNote noteType];
      if (nt == MK_noteUpdate || nt == MK_mute)
        [noteSender sendNote: aNote];
    }
  }
  [noteSender sendNote: nextNote];
  if ((_loc == _endLoc) || ((tNew = [(nextNote = [_list objectAtIndex:_loc++]) timeTag]) > lastTimeTag))
  [self deactivate];
  else
  nextPerform = tNew - t;
  return self;
}

@end

