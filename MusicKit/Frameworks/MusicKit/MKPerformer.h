/*
  $Id$
  Defined In: The MusicKit

  Description:
    MKPerformer is an abstract class that defines the general mechanism for
    performing MKNotes during a MusicKit performance.  Each subclass of
    MKPerformer implements the perform method to define how it obtains and
    performs MKNotes.
   
    During a performance, a MKPerformer receives a series of perform
    messages.  In its implementation of perform, a MKPerformer subclass must
    set the nextPerform variable.  nextPerform indicates the amount of
    time (in beats) to wait before the next perform message arrives.  The
    messages are sent by the MKPerformer's MKConductor.  Every MKPerformer is
    managed by a MKConductor; unless you set its MKConductor explicitly,
    through the setConductor: method, a MKPerformer is managed by the
    defaultConductor.
   
    A MKPerformer contains a List of MKNoteSenders, objects that send MKNotes
    (to MKNoteReceivers) during a performance.  MKPerformer subclasses should
    implement the init method to create and add some number of
    MKNoteSenders to a newly created instance.  As part of its perform
    method, a MKPerformer typically creates or othewise obtains a MKNote (for
    example, by reading it from a Part or a scorefile) and sends it by
    invoking MKNoteSender's sendNote: method.
   
    To use a MKPerformer in a performance, you must first send it the
    activate message.  activate invokes the activateSelf method and then
    schedules the first perform message request with the MKConductor.
    activateSelf can be overridden in a subclass to provide further
    initialization of the MKPerformer.  The performance begins when the
    MKConductor class receives the startPerformance message.  It's legal to
    activate a MKPerformer after the performance has started.
   
    Sending the deactivate message removes the MKPerformer from the
    performance and invokes the deactivate method.  This method can be
    overridden to implement any necessary finalization, such as freeing
    contained objects.
   
    During a performance, a MKPerformer can be stopped and restarted by
    sending it the pause and resume messages, respectively.  perform
    messages destined for a paused MKPerformer are delayed until the object
    is resumed.
   
    You can shift a MKPerformer's performance timing by setting its
    timeShift variable.  timeShift, measured in beats, is added to the
    initial setting of nextPerform.  If the value of timeShift is
    negative, the MKPerformer's MKNotes are sent earlier than otherwise
    expected; this is particularly useful for a MKPerformer that's
    performing MKNotes starting from the middle of a MKPart or MKScore.  A
    positive timeShift delays the performance of a MKNote.
   
    You can also set a MKPerformer's maximum duration.  A MKPerformer is
    automatically deactivated if its performance extends beyond duration
    beats.
   
    A MKPerformer has a status, represented as one of the following
    MKPerformerStatus values:
   
   
    * Status       Meaning
    * MK_inactive  A deactivated or not-yet-activated MKPerformer.
    * MK_active    An activated, unpaused MKPerformer.
    * MK_paused    The MKPerformer is activated but currently paused.
   
    Some messages can only be sent to an inactive (MK_inactive) MKPerformer.
    A MKPerformer's status can be queried with the status message.
   
    CF: MKConductor, MKNoteSender

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University  
*/
/*
  $Log$
  Revision 1.4  2000/04/25 02:09:53  leigh
  Renamed free methods to release methods to reflect OpenStep behaviour

  Revision 1.3  2000/03/29 03:17:07  leigh
  Cleaned up doco and ivar declarations

  Revision 1.2  1999/07/29 01:25:48  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_Performer_H___
#define __MK_Performer_H___

#import <Foundation/NSObject.h>
#import "MKNoteSender.h"
#import "MKConductor.h"

typedef enum _MKPerformerStatus { /* Status for Performers. */
    MK_inactive,
    MK_active,
    MK_paused
  } MKPerformerStatus;

@interface MKPerformer : NSObject
{
    MKConductor *conductor;       /* The object's MKConductor. */
    MKPerformerStatus status;     /* The object's status. */
    int performCount;             /* Number of times the object has received perform messages. */
    double timeShift;             /* Performance offset time in beats. */
    double duration;              /* Maximum performance duration in beats. */
    double time;                  /* The object's notion of the current time.
                                     The time in beats of the current invocation of
                                     perform, if any, otherwise, the time in beats of the
                                     last invocation of perform. */
    double nextPerform;           // The next time in beats until the object will send a MKNote by sending a perform message.
    NSMutableArray *noteSenders;  /* The object's collection of MKNoteSenders. */
    id delegate;                  /* The object's delegate, if any. */

    /* The following for internal use only */
    double _pauseOffset;          // Difference between the beat when a performer is paused and its time.
    double _endTime;              // End time for the object. Subclass should not set _endTime.
    MKMsgStruct *_performMsgPtr;
    MKMsgStruct *_deactivateMsgPtr;
    MKMsgStruct *_pauseForMsgPtr;
}

- noteSenders; 
 /* 
  * Creates and returns a List containing the receiver's NoteSenders.
  * It's the sender's responsibility to free the List.  */

-(BOOL ) isNoteSenderPresent:aNoteSender; 
 /* 
  * Returns YES if aNoteSender is a member of the receiver's MKNoteSender
  * List.  */

-disconnectNoteSenders;
 /* 
  * Sends disconnect to each of the receiver's NoteSenders. 
  */

- releaseNoteSenders; 
 /* 
  * Disconnects and frees the receiver's NoteSenders.
  * Returns the receiver.
  */

- removeNoteSenders; 
 /* 
  * Removes the receiver's NoteSenders (but doesn't free them).
  * Returns the receiver.
  */

- noteSender; 
 /* 
  * Returns the first MKNoteSender in the receiver's List.  This is a convenience
  * method provided for Performers that create and add a single MKNoteSender.
  */

- removeNoteSender:aNoteSender; 
 /* 
  * Removes aNoteSender from the receiver.  The receiver must be inactive.
  * If the receiver is currently in performance, or if aNoteSender wasn't
  * part of its MKNoteSender List, returns nil.  Otherwise returns the
  * receiver.  */

- addNoteSender:aNoteSender; 
 /* 
  * Adds aNoteSender to the recevier.  The receiver must be inactive.  If
  * the receiver is currently in performance, or if aNoteSender already
  * belongs to the receiver, returns nil.  Otherwise returns the receiver.
  */

- setConductor:aConductor; 
 /* 
  * Sets the receiver's MKConductor to aConductor.
  */

- conductor; 
  /* 
   * Returns the receiver's MKConductor.
   */

- activateSelf; 
 /* 
  * You never invoke this method directly; it's invoked automatically from
  * the activate method.  A subclass can implement this method to perform
  * pre-performance activities.  In particular, if the subclass needs to
  * alter the initial nextPerform value, it should be done here.  If
  * activateSelf returns nil, the receiver is deactivated.  The default
  * does nothing and returns the receiver.  */

- perform; 
 /* 
  * This is a subclass responsibility expected to send a Note and then set the
  * value of nextPerform.  The return value is ignored.  
  */

- setTimeShift:(double )timeShift;
 /* 
  * Shifts the receiver's performance time by timeShift beats.  The
  * receiver must be inactive.  Returns nil if the receiver is currently
  * in performance, otherwise returns the receiver.  */

- setDuration:(double )dur; 
 /* 
  * Sets the receiver's maximum performance duration to dur in beats.  The
  * receiver must be inactive.  Returns nil if the receiver is currently
  * in performance, otherwise returns the receiver.  */

-(double ) timeShift;
 /* Returns the receiver's time shift value.
 */

-(double ) duration; 
 /* Returns the receiver's duration value.
 */

-(int ) status; 
 /* Returns the receiver's status.
 */

-(int ) performCount; 
 /* Returns the number of perform messages the receiver has 
    recieved in the current performance.
  */

- activate; 
 /* 
  * If the receiver isn't inactive, immediately returns the receiver; if
  * its duration is less than or equal to 0, immediately returns nil.
  * Otherwise prepares the receiver for a performance by setting
  * nextPerform to 0.0, performCount to 0, invoking activateSelf,
  * scheduling the first perform message request with the MKConductor, and
  * setting the receiver's status to MK_active.  If a subclass needs to
  * alter the initial value of nextPerform, it should do so in its
  * implementation of the activateSelf method.  Also sends [delegate
  * hasActivated:self]; Returns the receiver.  */

- (void)deactivate; 
 /* 
  * If the receiver's status is inactive, this does nothing and
  * immediately returns the receiver.  Otherwise removes the receiver from
  * the performance, and sets the receiver's
  * status to MK_inactive.  Also sends [delegate hasDeactivated:self];
  * Returns the receiver.  */

- init; 
 /* 
  * Initializes the receiver.  You never invoke this method directly.  A
  * subclass implementation should send [super init] before
  * performing its own initialization.  The return value is ignored.  */

- pause; 
 /* 
  * Suspends the receiver's performance and returns the receiver.  To free
  * a paused Performer during a performance, you should first send it the
  * deactivate message.  Also sends [delegate hasPaused:self]; */

-pauseFor:(double)beats;
 /* 
  * Like pause, but also enqueues a resume message to be sent the specified
  * number of beats into the future. */

- resume; 
 /* 
  * Resumes the receiver's performance and returns the receiver.  Also
  * sends [delegate hasResumed:self]; */

- copyWithZone:(NSZone *)zone; ;
 /* 
  * Creates and returns a new, inactive Performer as a copy of the
  * receiver.  The new object has the same time shift and duration as the
  * reciever.  Its time and nextPerform variables are set to 0.0.  The new
  * object's NoteSenders are copied from the receiver.  
  * Note that you shouldn't send init to the new object. */

- copy; 
 /* 
    Same as [self copyFromZone:[self zone]] 
  */

- (void)dealloc; 
 /* 
  * Frees the receiver and its NoteSenders. The receiver must be inactive.
  * Does nothing and returns nil if the receiver is currently in
  * performance.  */

-(double ) time; 
 /* 
  * Returns the time, in beats, that the receiver last received the
  * perform message.  If the receiver is inactive, returns MK_ENDOFTIME.
  * The return value is measured from the beginning of the performance and
  * doesn't include any time that the receiver has been paused.  */

/* Implement an informal protocol for firstTimeTag/lastTimeTag. */
-setFirstTimeTag:(double)v; /* Does nothing */
-setLastTimeTag:(double)v;  /* Does nothing */
-(double)firstTimeTag;      /* Returns 0 */
-(double)lastTimeTag;       /* Returns MK_ENDOFTIME */

- (void)setDelegate:(id)object;
- delegate;

-rescheduleBy:(double)aTimeIncrement;
  /* Reschedules by aTimeIncrement, which is in terms of the receiver's 
     MKConductor's time base. Returns nil and does nothing if the receiver 
     is not active. ATimeIncrement may be negative.
     */

-rescheduleAtTime:(double)aTime;
  /* Reschedules at aTime, which is in terms of the receiver's MKConductor's time 
     base. Returns nil and does nothing if the receiver is not active. aTime
     may be less than the current scheduled time. 
     */

- (void)encodeWithCoder:(NSCoder *)aCoder;
  /* 
     You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Archives noteSender List, timeShift, and duration. Also optionally 
     archives conductor and delegate using NXWriteObjectReference().
     */
- (id)initWithCoder:(NSCoder *)aDecoder;
  /* 
     You never send this message directly.  
     Should be invoked via NXReadObject(). 
     Note that the status of an unarchived Performer is always MK_inactive.
     Note also that -init is not sent to newly unarchived objects.
     See write:. */
//- awake;
 /* Gets newly unarchived object ready for use. 
   */

-(BOOL)inPerformance;
 /* Returns YES if receiver's status is not MK_inactive  */

 /* Obsolete */
+ new; 
//- (void)initialize;

@end

/* Describes the protocol that may be implemented by the delegate: */
#import "MKPerformerDelegate.h"



#endif
