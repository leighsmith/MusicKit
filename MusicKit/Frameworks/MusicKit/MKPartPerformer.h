#ifndef __MK_PartPerformer_H___
#define __MK_PartPerformer_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  PartPerformer.h
  DEFINED IN: The Music Kit
*/

#import "MKPerformer.h"

@interface MKPartPerformer : MKPerformer
/* 
 * 
 * A PartPerformer object performs the Notes in a particular Part.  Every
 * PartPerformer has exactly one MKNoteSender.  A PartPerformer is
 * associated with a Part through its setPart: method.  While a single
 * PartPerformer can only be associated with one Part, any number of
 * PartPerformers can by associated with the same Part.  If you're
 * performing a Score, you can use ScorePerformer to create
 * PartPerformers for you (one for each Part in the Score).
 * 
 * When you activate a PartPerformer (through activateSelf) the object
 * copies its Part's List of Notes (it doesn't copy the Notes
 * themselves).  When it's performed, the PartPerformer sequences over
 * its copy of the List, allowing you to edit the Part (by adding or
 * removing Notes) without disturbing the performance -- changes made to
 * a Part during a performance are not seen by the PartPerformer.
 * However, since only the List of Notes is copied but not the Notes
 * themselves, you should neither alter nor free a Part's Notes during a
 * performance.
 * 
 * The timing variables firstTimeTag, lastTimeTag, beginTime,
 * and duration affect the timing and performance duration of a
 * PartPerformer.  Only the Notes with timeTag values between
 * firstTimeTag and lastTimeTag (inclusive) are performed.  Each of these 
 * notes performance times is computed as its timeTag plus timeShift.
 * If the newly computed performance time is greater than duration, the Note 
 * is suppressed and the PartPerformer is deactivated.
 * 
 * CF: ScorePerformer, Part
 * 
 */
{
    id nextNote;        /* The next note to perform. */ 
    id noteSender;      /* The object's only MKNoteSender. */
    id part;            /* The Part associated with this object. */
    double firstTimeTag;
    double lastTimeTag;

    /* The following are for internal use only */
    /*  id *_loc;
        id *_endLoc;
     */
    int _loc,_endLoc;
    id _list;
    id _scorePerformer;
}


+setFastActivation:(BOOL)yesOrNo;
 /* If you send [PartPerformer setFastActivation:YES], PartPerformers 
    activated from then on will NOT copy the Part's List of Notes.  
    That is, they will use [part notesNoCopy] instead of [part notes].
    If you use this mode, you may not modify the part while the PartPerformer
    is active. Default is NO.
  */

+(BOOL)fastActivation;
 /* Returns value set with setFastActivation:.  Default is NO. */

- init;
 /* 
  * Initializes the receiver by creating and adding its single MKNoteSender.  You
  * never invoke this method directly.  A subclass implementation should send
  * [super init] before performing its own initialization.  The return
  * value is ignored.  
  */

- setPart:aPart; 
 /* 
  * Associates the receiver with aPart.  If the receiver is active, this does
  * nothing and returns nil.  Otherwise returns the receiver.  
  */

- part; 
 /* Returns the receiver's Part object. */

- activateSelf; 
 /* Activates the receiver for a performance.  The receiver
  * creates a copy of its Part's List of Notes, sets nextNote to the first
  * Note in the List that is between firstTimeTag and lastTimeTag, and sets 
  * nextPerform (an instance variable inherited from Performer that defines 
  * the time to perform nextNote) to the Note's timeTag.

  * You never invoke this method directly; it's invoked as part of the
  * activate method inherited from Performer.  A subclass implementation
  * should send [super activateSelf].  If activateSelf returns nil, the
  * receiver isn't activated.  The default implementation returns nil if
  * there aren't any Notes in the receiver's Note List, otherwise it
  * returns the receiver.  The activate method performs further timing
  * checks.  */

- (void)deactivate; 
 /* 
  * Deactivates the receiver and frees its List of Notes.  You never
  * invoke this method directly; it's invoked as part of the deactivate
  * method inherited from Performer.  The return value is ignored.  */

- perform; 
 /* 
  * Performs nextNote (by sending it to its MKNoteSender's connections) and
  * then prepares the receiver for its next Note performance.  It does
  * this by seting nextNote to the next Note in its List and setting
  * nextPerform to that Note's timeTag. 
  * You never invoke this method directly; it's automatically invoked by
  * the receiver's Conductor during a performance.  A subclass
  * implementation should send [super perform].  The return value is
  * ignored.  */ 

- setFirstTimeTag:(double )aTimeTag; 
 /* Only Notes within the time span from firstTimeTag to lastTimeTag are
  * included in the performance.  
  */
- setLastTimeTag:(double )aTimeTag; 
 /* See setFirstTimeTag */
-(double ) firstTimeTag; 
 /* See setFirstTimeTag */
-(double )lastTimeTag; 
 /* See setFirstTimeTag */

- copyWithZone:(NSZone *)zone; 
 /* 
  * Creates and returns a new Instrument as a copy of the receiver.  The
  * new object has its own NoteReceiver collection that contains copies of
  * the receiver's NoteReceivers.  The new NoteReceivers' connections (see
  * the NoteReceiver class) are copied from the NoteReceivers in the
  * receiver. CF superclass copy. */

- (void)encodeWithCoder:(NSCoder *)aCoder;
  /* 
     You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Invokes superclass write: then archives firstTimeTag and lastTimeTag.
     Optionally archives part using NXWriteObjectReference().
     */
- (id)initWithCoder:(NSCoder *)aDecoder;
  /* 
     Should be invoked via NXReadObject(). 
     Note that -init is not sent to newly unarchived objects.
     See write:. */

//- awake;
 /* Gets object ready for use. */
@end



#endif
