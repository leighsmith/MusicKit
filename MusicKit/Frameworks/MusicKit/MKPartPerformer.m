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

/* Modification history:

  $Log$
  Revision 1.3  2000/04/16 04:21:33  leigh
  Comment cleanup

  Revision 1.2  1999/07/29 01:16:39  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  08/23/90/daj - Changed to zone API.
  12/04/90/daj - Fixed bug in copyFromZone: (thanks to lbj)
  02/06/92/daj - Fixed bug in activate that could cause note before
                 firstTimeTag to play, if it's the last note.
  06/29/93/daj - Fixed bug in activate that would cause the Performer to
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

@implementation MKPartPerformer: MKPerformer
/* The simplest Performer, PartPerformer performs a Part. */
{
    id nextNote; /* The next note, updated in -perform. */
    id noteSender;/* The one-and-only MKNoteSender. */
    id part;     /* Part over which we're sequencing. */
    double firstTimeTag; /* The smallest timeTag value considered for performance.  */
    double lastTimeTag;   /* The greatest timeTag value considered for performance.  */
/*  id *_loc;
    id *_endLoc;
 */
    int _loc,_endLoc;
    id _list;
    id _scorePerformer;
}

#import "timetagInclude.m"

void _MKSetScorePerformerOfPartPerformer(aPP,aSP)
    MKPartPerformer *aPP;
    id aSP;
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
    [super init];
    lastTimeTag = MK_ENDOFTIME;
    [self addNoteSender:noteSender = [MKNoteSender new]];
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
    [super encodeWithCoder:aCoder];
    [aCoder encodeConditionalObject:part];
    [aCoder encodeValuesOfObjCTypes:"dd",&firstTimeTag,&lastTimeTag];
    [aCoder encodeConditionalObject:_scorePerformer];
}

- (id)initWithCoder:(NSCoder *)aDecoder
  /* You never send this message directly.  
     Should be invoked via NXReadObject(). 
     See write:. */
{
    [super initWithCoder:aDecoder];
    if ([aDecoder versionForClassName:@"PartPerformer"] == VERSION2) {
	part = [[aDecoder decodeObject] retain];
	[aDecoder decodeValuesOfObjCTypes:"dd",&firstTimeTag,&lastTimeTag];
	_scorePerformer = [[aDecoder decodeObject] retain];
    }
    /* from awake (sb) */
    noteSender = [self noteSender];

    return self;
}

//- awake
  /* Initializes noteSender instance variable. */
//{
//#warning DONE ArchiverConversion: put the contents of your 'awake' method at the end of your 'initWithCoder:' method instead
//    [super awake];
/*
    noteSender = [self noteSender];
 */
//    return self;
//}

- (void)dealloc
  /* If receiver is a member of a ScorePerformer or is active, returns self
     and does nothing. Otherwise frees the receiver. */
{
    /*sb: FIXME!!! This is not the right place to decide whether or not to dealloc.
     * maybe need to put self in a global list of non-dealloced objects for later cleanup */
    if ((status != MK_inactive) || _scorePerformer) 
      return;
    [noteSender release]; /* sb */
    [super dealloc];
}

- copyWithZone:(NSZone *)zone;
  /* TYPE: Copying: Returns a copy of the receiver.
   * Creates and returns a new inactive Performer as
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
    newObj->noteSender = [newObj noteSender];
    return newObj; 	//sb: do we need to retain and autorelease this? Or is this done
    			// as part of [super copyWithZone:zone] ?
}

-setPart:aPart
  /* Sets Part over which we sequence. 
     If the receiver is active, does nothing and returns nil. Otherwise
     returns self. */
{
    if (status != MK_inactive)
      return nil;
    part = aPart;
    return self;
}

-part
  /* Gets Part over which we sequence. */
{
    return [[part retain] autorelease];
}

-activateSelf
  /* TYPE: Performing
   * Activates the receiver for a performance. The Part is snapshotted at  
   * this time. Any subsequent changes to the Part will not affect the
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
    if ([part notesNoCopy] != _list) /* Was copied. */
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
   * Rather, it is invoked by the Conductor.
   * You may override this method, e.g. to modify the note before it is 
   * performed or to modify nextPerform, 
   * but you must send [super perform] to perform the note. 
   */
{
    double t = [nextNote timeTag];
    double tNew;
    if (performCount == 1 && (firstTimeTag > 0)) {  /* Send all noteUpdates up to now */
	int nt;

        NSEnumerator *enumerator = [_list objectEnumerator];
        id aNote;

        while ((aNote = [enumerator nextObject])) {
            if (aNote == nextNote) break;
            nt = [aNote noteType];
            if (nt == MK_noteUpdate || nt == MK_mute)
              [noteSender sendNote:aNote];
        }
/*
	for (aNote = NX_ADDRESS(_list); *aNote != nextNote; aNote++) {
	    nt = [*aNote noteType];
	    if (nt == MK_noteUpdate || nt == MK_mute) 
	      [noteSender sendNote:*aNote];
	}
 */
    }
    [noteSender sendNote:nextNote];
    if ((_loc == _endLoc) ||
        ((tNew = [(nextNote = [_list objectAtIndex:_loc++]) timeTag]) > lastTimeTag)) //sb: was *_loc++
      [self deactivate];
    else nextPerform = tNew - t;
    return self;
}

@end

