#ifndef __MK_Performer_H___
#define __MK_Performer_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  MKPerformer.h
  DEFINED IN: The Music Kit
*/

#import <Foundation/NSObject.h>
#import "MKNoteSender.h"
#import "MKConductor.h"

typedef enum _MKPerformerStatus { /* Status for Performers. */
    MK_inactive,
    MK_active,
    MK_paused
  } MKPerformerStatus;

@interface MKPerformer : NSObject
/* 
 * 
 * Performer is an abstract class that defines the general mechanism for
 * performing Notes during a Music Kit performance.  Each subclass of
 * Performer implements the perform method to define how it obtains and
 * performs Notes.
 * 
 * During a performance, a Performer receives a series of perform
 * messages.  In its implementation of perform, a Performer subclass must
 * set the nextPerform variable.  nextPerform indicates the amount of
 * time (in beats) to wait before the next perform message arrives.  The
 * messages are sent by the Performer's Conductor.  Every Performer is
 * managed by a Conductor; unless you set its Conductor explicitly,
 * through the setConductor: method, a Performer is managed by the the
 * defaultConductor.
 * 
 * A Performer contains a List of NoteSenders, objects that send Notes
 * (to NoteReceivers) during a performance.  Performer subclasses should
 * implement the init method to create and add some number of
 * NoteSenders to a newly created instance.  As part of its perform
 * method, a Performer typically creates or othewise obtains a Note (for
 * example, by reading it from a Part or a scorefile) and sends it by
 * invoking MKNoteSender's sendNote: method.
 * 
 * To use a Performer in a performance, you must first send it the
 * activate message.  activate invokes the activateSelf method and then
 * schedules the first perform message request with the Conductor.
 * activateSelf can be overridden in a subclass to provide further
 * initialization of the Performer.  The performance begins when the
 * Conductor class receives the startPerformance message.  It's legal to
 * activate a Performer after the performance has started.
 * 
 * Sending the deactivate message removes the Performer from the
 * performance and invokes the deactivate method.  This method can be
 * overridden to implement any necessary finalization, such as freeing
 * contained objects.
 * 
 * During a performance, a Performer can be stopped and restarted by
 * sending it the pause and resume messages, respectively.  perform
 * messages destined for a paused Performer are delayed until the object
 * is resumed.
 * 
 * You can shift a Performer's performance timing by setting its
 * timeShift variable.  timeShift, measured in beats, is added to the
 * initial setting of nextPerform.  If the value of timeShift is
 * negative, the Performer's Notes are sent earlier than otherwise
 * expected; this is particularly useful for a Performer that's
 * performing Notes starting from the middle of a Part or Score.  A
 * positive timeShift delays the performance of a Note.
 * 
 * You can also set a Performer's maximum duration.  A Performer is
 * automatically deactivated if its performance extends beyond duration
 * beats.
 * 
 * A Performer has a status, represented as one of the following
 * MKPerformerStatus values:
 *  
 * 
 * * Status       Meaning
 * * MK_inactive  A deactivated or not-yet-activated Performer.
 * * MK_active    An activated, unpaused Performer.
 * * MK_paused    The Performer is activated but currently paused.
 * 
 * Some messages can only be sent to an inactive (MK_inactive) Performer.
 * A Performer's status can be queried with the status message.
 * 
 * CF: Conductor, MKNoteSender
 */
{
    id conductor;  /* The object's Conductor. */
    MKPerformerStatus status; /* The object's status. */
    int performCount;/* Number of perform messages the 
                    object has received. */
    double timeShift; /* Timing offset. */
    double duration; /* Maximum duration. */
    double time; /* The object's notion of the current time. */
    double nextPerform; /* The next time the object will send a Note. */
    NSMutableArray *noteSenders;  /* The object's collection of NoteSenders. */
    id delegate;     /* The object's delegate, if any. */

    /* The following for internal use only */
    double _pauseOffset;  
    double _endTime;
    MKMsgStruct *_performMsgPtr;
    MKMsgStruct *_deactivateMsgPtr;
    MKMsgStruct *_pauseForMsgPtr;
    void *_reservedPerformer6;
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

- freeNoteSenders; 
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
  * Sets the receiver's Conductor to aConductor.
  */

- conductor; 
  /* 
   * Returns the receiver's Conductor.
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
  * scheduling the first perform message request with the Conductor, and
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
     Conductor's time base. Returns nil and does nothing if the receiver 
     is not active. ATimeIncrement may be negative.
     */

-rescheduleAtTime:(double)aTime;
  /* Reschedules at aTime, which is in terms of the receiver's Conductor's time 
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
