/*
  $Id$
  Defined In: The MusicKit

  Description:
    A MKScorePerformer performs a MKScore object by creating a group of
    MKPartPerformers, one for each MKPart in the MKScore, and controlling the
    group's performance.  MKScorePerformer itself isn't a MKPerformer but it
    does define a number of methods, such as activate, pause, and resume,
    that resemble MKPerformer methods.  When a MKScorePerformer receives such
    a message, it simply forwards it to each of its MKPartPerformer objects,
    which are true MKPerformers.
   
    MKScorePerformer also has a MKPerformer-like status; it can be active,
    inactive, or paused.  The status of a MKScorePerformer is, in general,
    the same as the status of all of its MKPartPerformers.  For instance,
    when you send the activate message to a MKScorePerformer, its status
    becomes MK_active as does the status of all its MKPartPerformers.
    However, you can access and control a MKPartPerformer independent of the
    MKScorePerformer that created it.  Thus, an individual MKPartPerformer's
    status can be different from that of the MKScorePerformer.
   
    A MKScorePerformer's score is set and its MKPartPerformers are created
    when it receives the setScore: message.  If you add MKParts to or remove
    MKParts from the MKScore after sending the setScore: message, the changes
    will not be seen by the MKScorePerformer.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:
  $Log$
  Revision 1.4  2000/02/24 22:55:21  leigh
  Clean up of comments, parameter typing

  Revision 1.3  1999/09/04 22:44:52  leigh
  extra doco from implementation ivar descriptions

  Revision 1.2  1999/07/29 01:25:50  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_ScorePerformer_H___
#define __MK_ScorePerformer_H___

#import <Foundation/NSObject.h>
#import "MKPerformer.h"

@class MKScore;

@interface MKScorePerformer : NSObject
{
    MKPerformerStatus status;       /* The object's status. */
    NSMutableArray *partPerformers; /* An array of the object's MKPartPerformer instances. */
    MKScore *score;                 /* The MKScore with which this object is associated. */     
    double firstTimeTag;            /* The smallest timeTag value considered for
                                       performance, as last broadcast to the MKPartPerformers. */
    double lastTimeTag;   /* The greatest timeTag value considered for
                             performance, as last broadcast to the MKPartPerformers. */
    double timeShift;	  /* The Performance offset time for the object in beats, as last broadcast to the MKPartPerformers. */
    double duration;      /* The Maximum performance duration in beats, as last broadcast to the MKPartPerformers. */
    MKConductor *conductor; /* The object's MKConductor (its MKPartPerformers' MKConductor) as last broadcast to MKPartPerformers.*/
    id delegate;            /* The object's delegate. */
    id partPerformerClass;  /* The PartPerformer subclass used. */
    /* The following is for internal use only */
    MKMsgStruct * _deactivateMsgPtr;
}

+ (MKScorePerformer *) scorePerformer;
   /* allocates, initialises and returns an autoreleased instance */

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

- setScore: (MKScore *) aScore;
 /* 
  * Sets the receiver's Score to aScore and creates a PartPerformer for
  * each of the Score's Parts.  Subsequent changes to aScore (by adding or
  * removing Parts) won't be seen by the receiver.  The PartPerformers
  * from a previously set Score (if any) are first removed and freed.
  * Note: The score can be set only when the receiver's performance status
  * is MK_inactive.  If the receiver is not inactive, the setScore: message
  * is ignored. Returns the receiver or nil if the score could not be set.
  */

- (MKScore *) score; 
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

- setLastTimeTag:(double) aTimeTag; 
 /* 
  * Sets the greatest timeTag value considered for performance by sending
  * setLastTimeTag:aTimeTag to each of the receiver's PartPerformers.
  * Returns the receiver.  If the receiver is active, this does nothing
  * and returns nil.
  */

- (double) firstTimeTag; 
 /* Returns the smallest timeTag value considered for performance.*/
   
- (double) lastTimeTag; 
 /* Returns the greatest timeTag value considered for performance.*/
   
- setTimeShift:(double) aTimeShift; 
 /* 
  * Sets the performance time offset by sending setTimeShift:aTimeShift to
  * each of the receiver's PartPerformers.  The offset is measured in
  * beats.  Returns the receiver.  If the receiver is active, this does
  * nothing and returns nil.
  */

- setDuration:(double) aDuration; 
 /* 
  * Sets the maximum performance duration by sending setDuration:aDuration
  * to each of the receiver's PartPerformers.  The duration is measured in
  * beats.  Returns the receiver.  If the receiver is active, this does
  * nothing and returns nil.
  */

- (double) timeShift;
 /* Returns the receiver's performance time offset in beats. */
   
- (double ) duration; 
 /* Returns the receiver's maximum performance duration in beats.*/

- copyWithZone:(NSZone *) zone;
 /* 
  * Creates and returns a new, inactive ScorePerformer that's a copy of
  * the receiver.  The new object is associated with the same Score as the
  * receiver, and has the same Conductor and timing window variables
  * (timeShift, duration, fromTimeTag, and toTimeTag).  New PartPerformers
  * are created for the new object.
  */

- copy;
 /* Same as [self copyFromZone:[self zone]]; */

- (void) dealloc; 
 /* Frees the receiver and its PartPerformers. */
   
- setConductor: (MKConductor *) aConductor; 
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

@end

/* Describes the protocol that may be implemented by the delegate: */
#import "MKPerformerDelegate.h"



#endif
