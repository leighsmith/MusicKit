/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:25:50  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_ScorePerformer_H___
#define __MK_ScorePerformer_H___

#import <Foundation/NSObject.h>
#import "MKPerformer.h"

@interface MKScorePerformer : NSObject
/* 
 * 
 * A ScorePerformer performs a Score object by creating a group of
 * PartPerformers, one for each Part in the Score, and controlling the
 * group's performance.  ScorePerformer itself isn't a Performer but it
 * does define a number of methods, such as activate, pause, and resume,
 * that resemble Performer methods.  When a ScorePerformer receives such
 * a message, it simply forwards it to each of its PartPerformer objects,
 * which are true Performers.
 * 
 * ScorePerformer also has a Performer-like status; it can be active,
 * inactive, or paused.  The status of a ScorePerformer is, in general,
 * the same as the status of all of its PartPerformers.  For instance,
 * when you send the activate message to a ScorePerformer, its status
 * becomes MK_active as does the status of all its PartPerformers.
 * However, you can access and control a PartPerformer independent of the
 * ScorePerformer that created it.  Thus, an individual PartPerformer's
 * status can be different from that of the ScorePerformer.
 * 
 * A ScorePerformer's score is set and its PartPerformers are created
 * when it receives the setScore: message.  If you add Parts to or remove
 * Parts from the Score after sending the setScore: message, the changes
 * will not be seen by the ScorePerformer.
 * 
 */ 
{
    MKPerformerStatus status; /* The object's status. */
    NSMutableArray *partPerformers; /* A List of the object's PartPerformer instances. */
    id score; /* The Score with which this object is associated. */     
    double firstTimeTag; /* Smallest timeTag considered for performance. */
    double lastTimeTag; /* Greatest timeTag considered for performance. */
    double timeShift; /* Performance time offset in beats. */
    double duration; /* Maximum performance duration in beats. */
    id conductor; /* The object's Conductor (its PartPerformers' Conductor).*/
    id delegate;  /* The object's delegate. */
    id partPerformerClass; /* The PartPerformer subclass used. */ 

    /* The following is for internal use only */
    BOOL _reservedScorePerformer1;     
    MKMsgStruct * _deactivateMsgPtr;
    void *_reservedScorePerformer3; 
}

- init; 
 /* 
  * Inits the receiver; you never invoke this method directly.
  * A subclass implementation
  * should send [super init] before performing its own initialization.
  * The return value is ignored.  
  */

- freePartPerformers;
 /* 
  * If the receiver is in performance, does nothing and returns nil.
  * Otherwise, removes and frees the receiver's PartPerformers and sets the 
  * receiver's Score to nil.  Returns the receiver.
  */
   
- removePartPerformers; 
 /* 
  * Removes the receiver's PartPerformers (but doesn't free them) and sets the
  * receiver's Score to nil.  Returns the receiver.  
  */

- setScore:aScore; 
 /* 
  * Sets the receiver's Score to aScore and creates a PartPerformer for
  * each of the Score's Parts.  Subsequent changes to aScore (by adding or
  * removing Parts) won't be seen by the receiver.  The PartPerformers
  * from a previously set Score (if any) are first removed and freed.
  * Note: The score can be set only when the receiver's performance status
  * is MK_inactive.  If the receiver is not inactive, the setScore: message
  * is ignored. Returns the receiver or nil if the score could not be set.
  */

- score; 
 /* Returns the object's Score. */
   
- activate; 
 /* 
  * Sends activateSelf to the receiver and then sends the activate message
  * to each of the receiver's PartPerformers.  If activateSelf returns
  * nil, the message isn't sent and nil is returned.  Otherwise sends
  * [delegate hasActivated:self] and returns the receiver.
  */

- activateSelf; 
 /* 
  * You never invoke this method directly; it's invoked as part of the
  * activate method.  A subclass implementation should send [super
  * activateSelf].  If activateSelf returns nil, the receiver isn't
  * activated.  The default implementation does nothing and returns the
  * receiver.
  */

- (void)deactivate; 
 /* 
  * A subclass can implement this method to perform post-performance
  * activites.  The default does nothing; the return value is ignored.
  * You never invoke this method directly; it's invoked by the deactivate
  * method.
  */

- pause; 
 /* 
  * Suspends the receiver's performance by sending the pause message to
  * each of its PartPerformers.  Also sends [delegate hasPaused:self];
  * Returns the receiver.
  */
   
- resume; 
 /* 
  * Resumes a previously paused performance by sending the resume message
  * to each of the receiver's PartPerformers.  Also sends [delegate
  * hasResumed:self]; Returns the receiver.
  */

- setFirstTimeTag:(double )aTimeTag; 
 /* 
  * Sets the smallest timeTag value considered for performance by sending
  * setFirstTimeTag:aTimeTag to each of the receiver's PartPerformers.
  * Returns the receiver.  If the receiver is active, this does nothing and returns
  * nil.  
  */

- setLastTimeTag:(double )aTimeTag; 
 /* 
  * Sets the greatest timeTag value considered for performance by sending
  * setLastTimeTag:aTimeTag to each of the receiver's PartPerformers.
  * Returns the receiver.  If the receiver is active, this does nothing
  * and returns nil.
  */

-(double ) firstTimeTag; 
 /* Returns the smallest timeTag value considered for performance.*/
   
-(double ) lastTimeTag; 
 /* Returns the greatest timeTag value considered for performance.*/
   
- setTimeShift:(double )aTimeShift; 
 /* 
  * Sets the performance time offset by sending setTimeShift:aTimeShift to
  * each of the receiver's PartPerformers.  The offset is measured in
  * beats.  Returns the receiver.  If the receiver is active, this does
  * nothing and returns nil.
  */

- setDuration:(double )aDuration; 
 /* 
  * Sets the maximum performance duration by sending setDuration:aDuration
  * to each of the receiver's PartPerformers.  The duration is measured in
  * beats.  Returns the receiver.  If the receiver is active, this does
  * nothing and returns nil.
  */

-(double ) timeShift;
 /* Returns the receiver's performance time offset in beats. */
   
-(double ) duration; 
 /* Returns the receiver's maximum performance duration in beats.*/

- copyWithZone:(NSZone *)zone; 
 /* 
  * Creates and returns a new, inactive ScorePerformer that's a copy of
  * the receiver.  The new object is associated with the same Score as the
  * receiver, and has the same Conductor and timing window variables
  * (timeShift, duration, fromTimeTag, and toTimeTag).  New PartPerformers
  * are created for the new object.
  */

-copy;
 /* Same as [self copyFromZone:[self zone]]; */

- (void)dealloc; 
 /* Frees the receiver and its PartPerformers. */
   
- setConductor:aConductor; 
 /* 
  * Sends the message setConductor:aConductor to each of the receiver's
  * PartPerformers. 
  */

- partPerformerForPart:aPart; 
 /* 
  * Returns the receiver's PartPerformer that's associated with aPart,
  * where aPart is a Part in the receiver's Score.  Keep in mind that it's
  * possible for a Part to have more than one PartPerformer; this method
  * returns only the PartPerformer that was created by the receiver.
  */

- partPerformers; 
 /* 
  * Creates and returns a List containing the receiver's PartPerformers.
  * The sender is responsible for freeing the List.
  */
   
- noteSenders; 
 /* 
  * Creates and returns a List containing the MKNoteSender objects that
  * belong ot the receiver's PartPerformers.  (A PartPerformer contains at
  * most one MKNoteSender, created when the PartPerformer is initialized.)
  * The sender is responsible for freeing the List.
  */

-(int) status;

-setPartPerformerClass:aPartPerformerSubclass;
/* Normally, ScorePerformers create instances of the PartPerformer class.
   This method allows you to specify that instances of some PartPerformer
   subclass be created instead. If aPartPerformerSubclass is not 
   a subclass of PartPerformer (or PartPerformer itself), this method has 
   no effect and returns nil. Otherwise, it returns self.
  */
-partPerformerClass;
 /* Returns the class used for PartPerformers, as set by 
   setPartPerformerClass:. The default is PartPerformer itself. */

- (void)setDelegate:(id)object;
 /* Sets the receiver's delegate object. See MKPerformerDelegate.h */
- delegate;
 /* Returns the receiver's delegate object. See MKPerformerDelegate.h */

- (void)encodeWithCoder:(NSCoder *)aCoder;
  /* 
     You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Archives partPerformers,firstTimeTag,lastTimeTag,timeShift,
     duration, and partPerformerClass. Also optionally archives score
     conductor and delegate using NXWriteObjectReference().
     */
- (id)initWithCoder:(NSCoder *)aDecoder;
  /* 
     You never send this message directly.  
     Note that -init is not sent to newly unarchived objects.
     Should be invoked with NXReadObject(). 
     */
//- awake;
  /* 
     Sets conductor field to defaultConductor if it was nil. */

 /* Obsolete methods */
+ new; 
//- (void)initialize;
   
@end

/* Describes the protocol that may be implemented by the delegate: */
#import "MKPerformerDelegate.h"



#endif
