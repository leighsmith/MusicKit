/*
  $Id$
  Defined In: The MusicKit

  Description:
    A MKPartPerformer object performs the MKNotes in a particular MKPart.  
    Every MKPartPerformer has exactly one MKNoteSender.  A MKPartPerformer is
    associated with a MKPart through its setPart: method.  While a single
    MKPartPerformer can only be associated with one MKPart, any number of
    MKPartPerformers can by associated with the same MKPart.  If you're
    performing a MKScore, you can use MKScorePerformer to create
    MKPartPerformers for you (one for each MKPart in the MKScore).

    When you activate a MKPartPerformer (through activateSelf) the object
    copies its MKPart's NSArray of MKNotes (it doesn't copy the MKNotes
    themselves).  When it's performed, the MKPartPerformer sequences over
    its copy of the NSArray, allowing you to edit the MKPart (by adding or
    removing MKNotes) without disturbing the performance -- changes made to
    a MKPart during a performance are not seen by the MKPartPerformer.
    However, since only the NSArray of MKNotes is copied but not the MKNotes
    themselves, you should neither alter nor free a MKPart's MKNotes during a
    performance.
   
    The timing variables firstTimeTag, lastTimeTag, beginTime,
    and duration affect the timing and performance duration of a
    MKPartPerformer.  Only the MKNotes with timeTag values between
    firstTimeTag and lastTimeTag (inclusive) are performed.  Each of these
    notes performance times is computed as its timeTag plus timeShift.
    If the newly computed performance time is greater than duration, the MKNote
    is suppressed and the MKPartPerformer is deactivated.
   
    CF: MKScorePerformer, MKPart

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
  $Log$
  Revision 1.3  2000/04/25 02:09:53  leigh
  Renamed free methods to release methods to reflect OpenStep behaviour

  Revision 1.2  1999/07/29 01:25:47  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_PartPerformer_H___
#define __MK_PartPerformer_H___

#import "MKPerformer.h"
#import "MKScorePerformer.h"

@interface MKPartPerformer : MKPerformer
{
    MKNote *nextNote;            /* The next note to perform. Updated in -perform. */ 
    MKNoteSender *noteSender;    /* The object's only MKNoteSender. */
    MKPart *part;                /* The MKPart associated with this object. */
    double firstTimeTag;         /* The smallest timeTag value considered for performance.  */
    double lastTimeTag;          /* The greatest timeTag value considered for performance.  */

    /* The following are for internal use only */
    /*  id *_loc;
        id *_endLoc;
     */
    int _loc,_endLoc;
    NSArray *_list;
    MKScorePerformer *_scorePerformer;
}

+setFastActivation:(BOOL)yesOrNo;
 /* If you send [MKPartPerformer setFastActivation:YES], MKPartPerformers 
    activated from then on will NOT copy the MKPart's NSArray of Notes.  
    That is, they will use [part notesNoCopy] instead of [part notes].
    If you use this mode, you may not modify the part while the MKPartPerformer
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
 /* Returns the receiver's MKPart object. */

- activateSelf; 
 /* Activates the receiver for a performance.  The receiver
  * creates a copy of its MKPart's NSArray of Notes, sets nextNote to the first
  * Note in the NSArray that is between firstTimeTag and lastTimeTag, and sets 
  * nextPerform (an instance variable inherited from Performer that defines 
  * the time to perform nextNote) to the Note's timeTag.

  * You never invoke this method directly; it's invoked as part of the
  * activate method inherited from Performer.  A subclass implementation
  * should send [super activateSelf].  If activateSelf returns nil, the
  * receiver isn't activated.  The default implementation returns nil if
  * there aren't any Notes in the receiver's Note NSArray, otherwise it
  * returns the receiver.  The activate method performs further timing
  * checks.  */

- (void)deactivate; 
 /* 
  * Deactivates the receiver and frees its NSArray of Notes.  You never
  * invoke this method directly; it's invoked as part of the deactivate
  * method inherited from Performer.  The return value is ignored.  */

- perform; 
 /* 
  * Performs nextNote (by sending it to its MKNoteSender's connections) and
  * then prepares the receiver for its next Note performance.  It does
  * this by seting nextNote to the next Note in its NSArray and setting
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
