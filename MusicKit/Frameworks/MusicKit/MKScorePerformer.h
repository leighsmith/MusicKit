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
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
@class MKScore;
@class MKPartPerformer;

/*!
  @class MKScorePerformer
  @brief A MKScorePerformer performs a MKScore object by creating a group of
   MKPartPerformers, one for each MKPart in the MKScore, and controlling the
   group's performance.
 
MKScorePerformer itself isn't a MKPerformer but it does
define a number of methods, such as <b>activate</b>, <b>pause</b>, and
<b>resume</b>, that emulate MKPerformer methods.  When a MKScorePerformer
receives such a message, it forwards the message to each of its MKPartPerformer
objects, which are true MKPerformers.

MKScorePerformer also has a MKPerformer-like status; it can be active, inactive,
or paused.  The status of a MKScorePerformer is, in general, the same as the
status of all its MKPartPerformers.  For instance, when you send the
<b>activate</b> message to a MKScorePerformer, its status becomes MK_active as
does the status of all its MKPartPerformers.  However, you can access and
control a MKPartPerformer independent of the MKScorePerformer that created it. 
Thus, an individual MKPartPerformer's status can be different from that of the
MKScorePerformer.

A MKScorePerformer's MKScore is set and its MKPartPerformers are created when it
receives the <b>setScore:</b> message.  If you add MKParts to or remove MKParts
from the MKScore after sending the <b>setScore:</b> message, the changes will not
be seen by the MKScorePerformer.
*/
#ifndef __MK_ScorePerformer_H___
#define __MK_ScorePerformer_H___

#import <Foundation/NSObject.h>
#import "MKPerformer.h"

@interface MKScorePerformer : NSObject
{
    MKPerformerStatus status;       /*! The object's status. */
    NSMutableArray *partPerformers; /*! An array of the object's MKPartPerformer instances. */
    MKScore *score;                 /*! The MKScore with which this object is associated. */     
    double firstTimeTag;            /*! The smallest timeTag value considered for
                                       performance, as last broadcast to the MKPartPerformers. */
    double lastTimeTag;   /*! The greatest timeTag value considered for
                             performance, as last broadcast to the MKPartPerformers. */
    double timeShift;	  /*! The performance offset time for the object in beats, as last broadcast to the MKPartPerformers. */
    double duration;      /*! The maximum performance duration in beats, as last broadcast to the MKPartPerformers. */
    MKConductor *conductor; /*! The object's MKConductor (its MKPartPerformers' MKConductor) as last broadcast to MKPartPerformers.*/
    id delegate;            /*! The object's delegate. */
    Class partPerformerClass;  /*! The MKPartPerformer subclass used. */

@private
    MKMsgStruct * _deactivateMsgPtr;
}

/*!
  @brief Allocates, initialises and returns an autoreleased instance.
  @return Returns an MKScorePerformer.  
*/
+ (MKScorePerformer *) scorePerformer;

/*!
  @brief Initializes the receiver.

  A subclass implementation should send
  <b>[super init]</b> before performing its own initialization. 
  @return Returns an id.
 */
- init; 

/*!
  @brief If the receiver is in performance, does nothing and returns <b>nil</b>.

  Otherwise, removes and frees the receiver's
  MKPartPerformers, sets the receiver's MKScore to <b>nil</b> and
  returns the receiver.
  @return Returns an id.
*/
- releasePartPerformers;

/*!
  @brief Removes the receiver's MKPartPerformers (but doesn't free them) and
  sets the receiver's MKScore to <b>nil</b>.
  @return Returns the receiver.  
*/
- removePartPerformers; 

/*!
  @brief Sets the receiver's MKScore to <i>aScore</i> and creates a
  MKPartPerformer for each of the Score's MKParts.

  Subsequent changes
  to <i>aScore</i> (by adding or removing MKParts) won't be seen by
  the receiver.  The MKPartPerformers from a previously set MKScore (if
  any) are first removed and freed.  Returns the receiver.
  
  Note: The score can be set only when the receiver's performance status
  is MK_inactive.  If the receiver is not inactive, the <i>setScore:</i> message
  is ignored. Returns the receiver or nil if the score could not be set.
  @param  aScore is an id.
  @return Returns an id.
*/
- setScore: (MKScore *) aScore;

/*!
  @brief Returns the object's MKScore.
  @return Returns an MKScore.
*/
- (MKScore *) score;    

/*!
  @brief Sends <b>activateSelf</b> to the receiver and then sends the
  <b>activate</b> message to each of the receiver's MKPartPerformers.
  
  If <b>activateSelf</b> returns <b>nil</b>, the message isn't sent
  and <b>nil</b> is returned.  Otherwise sends
  [delegate hasActivated:self] and returns the receiver.
 @return Returns an id.
*/
- activate; 

/*!
  @brief You never invoke this method directly; it's invoked as part of the
  <b>activate</b> method.

  A subclass implementation should send
  <b>[super activateSelf]</b>.  If <b>activateSelf</b> returns
  <b>nil</b>, the receiver isn't activated.  The default
  implementation does nothing and returns the receiver.
  @return Returns an id.
*/
- activateSelf; 

/*!
  @brief Deactivates the receiver's MKPartPerformers.

  A subclass can implement this method to perform post-performance
  activites.  The default does nothing; the return value is ignored.
*/
- (void) deactivate; 

/*!
  @brief Suspends the receiver's performance by sending the <b>pause</b>
  message to each of its MKPartPerformers.

  Also sends <tt>[delegate hasPaused: self];</tt>.
  @return Returns the receiver.
*/
- pause; 

/*!
  @brief Resumes a previously paused performance by sending the <b>resume</b>
  message to each of the receiver's MKPartPerformers.

  Also sends <tt>[delegate hasResumed:self];</tt>.
  @return Returns the receiver.
*/
- resume; 

/*!
  @brief Sets the smallest timeTag value considered for performance by
  sending <b>setFirstTimeTag:</b><i>aTimeTag</i> to each of the
  receiver's MKPartPerformers.

  If the receiver is active, this does nothing and returns <b>nil</b>.
  @param  aTimeTag is a double.
  @return Returns the receiver.
*/
- setFirstTimeTag: (double) aTimeTag; 

/*!
  @brief Sets the greatest timeTag value considered for performance by
  sending <b>setLastTimeTag:</b><i>aTimeTag</i> to each of the
  receiver's MKPartPerformers.

  If the receiver is active, this does nothing and returns <b>nil</b>.
  @param  aTimeTag is a double.
  @return Returns the receiver.
*/
- setLastTimeTag: (double) aTimeTag; 

/*!
  @brief Returns the smallest timeTag value considered for performance.
  @return Returns a double.
*/
- (double) firstTimeTag;    

/*!
  @brief Returns the greatest timeTag value considered for performance.
  @return Returns a double.
 */
- (double) lastTimeTag;    

/*!
  @brief Sets the performance time offset by sending
  <b>setTimeShift:</b><i>aTimeShift</i> to each of
  the receiver's MKPartPerformers.

  The offset is measured in beats. If the receiver is active, this does nothing
  and returns <b>nil</b>.
  @param  aTimeShift is a double.
  @return Returns the receiver.
*/
- setTimeShift: (double) aTimeShift; 

/*!
  @brief Sets the maximum performance duration by sending
  <b>setDuration:</b><i>aDuration</i> to each of the receiver's
  MKPartPerformers.

  The duration is measured in beats. If the receiver is active, this does nothing and returns <b>nil</b>.
  @param  aDuration is a double.
  @return Returns the receiver.
 */
- setDuration: (double) aDuration; 

/*!
  @brief Returns the receiver's performance time offset in beats.
  @return Returns a double.
*/
- (double) timeShift;

/*!
  @brief Returns the receiver's maximum performance duration in beats.
  @return Returns a double.
*/
- (double) duration; 

/*! 
  @brief Creates and returns a new, inactive MKScorePerformer that's a copy of the receiver.

  The new object is associated with the same MKScore as the
  receiver, and has the same MKConductor and timing window variables
  (<b>timeShift</b>, <b>duration</b>, <b>fromTimeTag</b>,
  and <b>toTimeTag</b>).  New MKPartPerformers
  are created for the new object.
  @return Returns an id.
 */
- copyWithZone: (NSZone *) zone;

 /* Frees the receiver and its MKPartPerformers. */
- (void) dealloc;

/*!
  @brief Sends the message <b>setConductor:</b><i>aConductor</i> to each of the receiver's MKPartPerformers.
  @param  aConductor is an id.
  @return Returns an id.
*/
- setConductor: (MKConductor *) aConductor; 

/*!
  @brief Returns the receiver's MKPartPerformer that's associated with
  <i>aPart</i>, where <i>aPart</i> is a MKPart in the receiver's
  MKScore.

  Keep in mind that it's possible for a MKPart to have more
  than one MKPartPerformer; this method returns only the
  MKPartPerformer that was created by the receiver.
  @param  aPart is an MKPart instance.
  @return Returns an MKPartPerformer instance.
*/
- (MKPartPerformer *) partPerformerForPart: (MKPart *) aPart;

/*!
  @brief Creates and returns a NSArray containing the receiver's MKPartPerformers.
  @return Returns an NSArray instance.
*/
- (NSArray *) partPerformers; 
   
/*!
  @return Returns an NSArray.
  @brief Creates and returns a NSMutableArray containing the MKNoteSender
  objects that belong to the receiver's MKPartPerformers  (A
  MKPartPerformer contains at most one MKNoteSender, created when the
  MKPartPerformer is initialized).

  The array is autoreleased.
*/
- (NSArray *) noteSenders; 

/*!
  @brief Returns the receiver's status.
  @return Returns an int.
*/
- (int) status;

/*!
  @brief Normally, MKScorePerformers create instances of the MKPartPerformer
  class.

  This method allows you to specify that instances of some
  MKPartPerformer subclass be created instead.  If
  <i>aPartPerformerSubclass</i> is not a subclass of MKPartPerformer
  (or MKPartPerformer itself), this method has no effect and returns
  nil.  Otherwise, it returns self.
  @param  aPartPerformerSubclass is a Class.
  @return Returns an id.
*/
- setPartPerformerClass: (Class) aPartPerformerSubclass;
  
/*!
  @brief Returns the class used for MKPartPerformers, as set by 
   setPartPerformerClass:.
 
  The default is MKPartPerformer itself. 
 */
- (Class) partPerformerClass;

/*!
  @brief Sets the delegate as indicated.
  @param  object is an id.  
  @see MKPerformerDelegate.h
*/
- (void) setDelegate: (id) object;

/*!
  @brief Returns the receiver's delegate object, if any.
  @return Returns an id.
  @see MKPerformerDelegate.h
*/
- delegate;

/*!
  @brief Archives partPerformers,firstTimeTag,lastTimeTag,timeShift,
 duration, and partPerformerClass.
 
 You never send this message directly. Also optionally archives score
 conductor and delegate.
 */
- (void) encodeWithCoder: (NSCoder *) aCoder;

/*!
  @brief initialises new object from the decoder.

  You never send this message directly.  
  Note that -init is not sent to newly unarchived objects.
 */
- (id) initWithCoder: (NSCoder *) aDecoder;

@end

/* Describes the protocol that may be implemented by the delegate: */
#import "MKPerformerDelegate.h"

#endif
