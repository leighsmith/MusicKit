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
/*
Modification history:
  $Log$
  Revision 1.9  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.8  2001/07/10 17:04:48  leighsmith
  Correctly typed partPerformerForPart:

  Revision 1.7  2000/11/25 22:59:47  leigh
  Enforced ivar privacy

  Revision 1.6  2000/10/01 06:55:01  leigh
  Typed noteSenders.

  Revision 1.5  2000/04/25 02:08:40  leigh
  Renamed free methods to release methods to reflect OpenStep behaviour

  Revision 1.4  2000/02/24 22:55:21  leigh
  Clean up of comments, parameter typing

  Revision 1.3  1999/09/04 22:44:52  leigh
  extra doco from implementation ivar descriptions

  Revision 1.2  1999/07/29 01:25:50  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
/*!
  @class MKScorePerformer
  @discussion

A MKScorePerformer performs a MKScore object by creating a group of
MKPartPerformers, one for each MKPart in the MKScore, and controlling the
group's performance.  MKScorePerformer itself isn't a MKPerformer but it does
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
    double timeShift;	  /* The performance offset time for the object in beats, as last broadcast to the MKPartPerformers. */
    double duration;      /* The maximum performance duration in beats, as last broadcast to the MKPartPerformers. */
    MKConductor *conductor; /* The object's MKConductor (its MKPartPerformers' MKConductor) as last broadcast to MKPartPerformers.*/
    id delegate;            /* The object's delegate. */
    id partPerformerClass;  /* The MKPartPerformer subclass used. */

@private
    MKMsgStruct * _deactivateMsgPtr;
}

/*!
  @method scorePerformer
  @result Returns an MKScorePerformer.
  @discussion Allocates, initialises and returns an autoreleased instance.
*/
+ (MKScorePerformer *) scorePerformer;

/*!
  @method init
  @result Returns an id.
  @discussion Initializes the receiver.  A subclass implementation should send
              <b>[super init]</b> before performing its own initialization. 
              
*/
- init; 

/*!
  @method releasePartPerformers
  @result Returns an id.
  @discussion If the receiver is in performance, does nothing and returns
              <b>nil</b>.  Otherwise, removes and frees the receiver's
              MKPartPerformers, sets the receiver's MKScore to <b>nil</b> and
              returns the receiver.
*/
- releasePartPerformers;

/*!
  @method removePartPerformers
  @result Returns an id.
  @discussion Removes the receiver's MKPartPerformers (but doesn't free them) and
              sets the receiver's MKScore to <b>nil</b>.  Returns the
              receiver.
*/
- removePartPerformers; 

/*!
  @method setScore:
  @param  aScore is an id.
  @result Returns an id.
  @discussion Sets the receiver's MKScore to <i>aScore</i> and creates a
              MKPartPerformer for each of the Score's MKParts.  Subsequent changes
              to <i>aScore</i> (by adding or removing MKParts) won't be seen by
              the receiver.  The MKPartPerformers from a previously set MKScore (if
              any) are first removed and freed.  Returns the receiver.
              
              Note: The score can be set only when the receiver's performance status
              is MK_inactive.  If the receiver is not inactive, the <i>setScore:</i> message
              is ignored. Returns the receiver or nil if the score could not be set.
*/
- setScore: (MKScore *) aScore;

/*!
  @method score
  @result Returns an MKScore.
  @discussion Returns the object's MKScore.
*/
- (MKScore *) score;    

/*!
  @method activate
  @result Returns an id.
  @discussion Sends <b>activateSelf</b> to the receiver and then sends the
              <b>activate</b> message to each of the receiver's MKPartPerformers. 
              If <b>activateSelf</b> returns <b>nil</b>, the message isn't sent
              and <b>nil</b> is returned.  Otherwise sends
              [delegate hasActivated:self] and returns the receiver.
*/
- activate; 

/*!
  @method activateSelf
  @result Returns an id.
  @discussion You never invoke this method directly; it's invoked as part of the
              <b>activate</b> method.  A subclass implementation should send
              <b>[super activateSelf]</b>.  If <b>activateSelf</b> returns
              <b>nil</b>, the receiver isn't activated.  The default
              implementation does nothing and returns the receiver.
*/
- activateSelf; 

/*!
  @method deactivate
  @discussion Deactivates the receiver's MKPartPerformers.
              A subclass can implement this method to perform post-performance
              activites.  The default does nothing; the return value is ignored.
*/
- (void)deactivate; 

/*!
  @method pause
  @result Returns an id.
  @discussion Suspends the receiver's performance by sending the <b>pause</b>
              message to each of its MKPartPerformers.  
              Also sends <tt>[delegate hasPaused:self];</tt>.
              Returns the receiver.
*/
- pause; 

/*!
  @method resume
  @result Returns an id.
  @discussion Resumes a previously paused performance by sending the <b>resume</b>
              message to each of the receiver's MKPartPerformers.
              Also sends <tt>[delegate hasResumed:self];</tt>.
              Returns the receiver.
*/
- resume; 

/*!
  @method setFirstTimeTag:
  @param  aTimeTag is a double.
  @result Returns an id.
  @discussion Sets the smallest timeTag value considered for performance by
              sending <b>setFirstTimeTag:</b><i>aTimeTag</i> to each of the
              receiver's MKPartPerformers.  Returns the receiver.  If the receiver
              is active, this does nothing and returns <b>nil</b>.
*/
- setFirstTimeTag:(double )aTimeTag; 

/*!
  @method setLastTimeTag:
  @param  aTimeTag is a double.
  @result Returns an id.
  @discussion Sets the greatest timeTag value considered for performance by
              sending <b>setLastTimeTag:</b><i>aTimeTag</i> to each of the
              receiver's MKPartPerformers.  Returns the receiver.  If the receiver
              is active, this does nothing and returns <b>nil</b>.
*/
- setLastTimeTag:(double) aTimeTag; 

/*!
  @method firstTimeTag
  @result Returns a double.
  @discussion Returns the smallest timeTag value considered for
              performance.
*/
- (double) firstTimeTag;    

/*!
  @method lastTimeTag
  @result Returns a double.
  @discussion Returns the greatest timeTag value considered for
              performance.
*/
- (double) lastTimeTag;    

/*!
  @method setTimeShift:
  @param  aTimeShift is a double.
  @result Returns an id.
  @discussion Sets the performance time offset by sending
              <b>setTimeShift:</b><i>aTimeShift</i> to each of
              the receiver's MKPartPerformers.  The offset is measured in beats.
              Returns the receiver.  If the receiver is active, this does nothing
              and returns <b>nil</b>.
*/
- setTimeShift:(double) aTimeShift; 

/*!
  @method setDuration:
  @param  aDuration is a double.
  @result Returns an id.
  @discussion Sets the maximum performance duration by sending
              <b>setDuration:</b><i>aDuration</i> to each of the receiver's
              MKPartPerformers.  The duration is measured in beats.  Returns the
              receiver.  If the receiver is active, this does nothing and returns
              <b>nil</b>.
*/
- setDuration:(double) aDuration; 

/*!
  @method timeShift
  @result Returns a double.
  @discussion Returns the receiver's performance time offset in beats.
*/
- (double) timeShift;

/*!
  @method duration
  @result Returns a double.
  @discussion Returns the receiver's maximum performance duration in
              beats.
*/
- (double ) duration; 

 /* 
  * Creates and returns a new, inactive MKScorePerformer that's a copy of
  * the receiver.  The new object is associated with the same MKScore as the
  * receiver, and has the same MKConductor and timing window variables
  * (timeShift, duration, fromTimeTag, and toTimeTag).  New MKPartPerformers
  * are created for the new object.
  */
- copyWithZone:(NSZone *) zone;

/*!
  @method copy
  @result Returns an id.
  @discussion Creates and returns a new, inactive MKScorePerformer that's a copy
              of the receiver.  The new object is associated with the same MKScore
              as the receiver, and has the same MKConductor and timing window
              variables (<b>timeShift</b>, <b>duration</b>, <b>fromTimeTag</b>,
              and <b>toTimeTag</b>).  New MKPartPerformers are created for the new
              object.
*/
- copy;
 /* Same as [self copyFromZone:[self zone]]; */

 /* Frees the receiver and its MKPartPerformers. */
- (void) dealloc; 
   

/*!
  @method setConductor:
  @param  aConductor is an id.
  @result Returns an id.
  @discussion Sends the message <b>setConductor:</b><i>aConductor</i> to each of
              the receiver's MKPartPerformers.
*/
- setConductor: (MKConductor *) aConductor; 

/*!
  @method partPerformerForPart:
  @param  aPart is an id.
  @result Returns an id.
  @discussion Returns the receiver's MKPartPerformer that's associated with
              <i>aPart</i>, where <i>aPart</i> is a MKPart in the receiver's
              MKScore.  Keep in mind that it's possible for a MKPart to have more
              than one MKPartPerformer; this method returns only the
              MKPartPerformer that was created by the receiver.
*/
- partPerformerForPart: (MKPart *) aPart;

/*!
  @method partPerformers
  @result Returns an id.
  @discussion Creates and returns a NSMutableArray containing the receiver's
              MKPartPerformers. 
*/
- partPerformers; 
   
/*!
  @method noteSenders
  @result Returns an NSArray.
  @discussion Creates and returns a NSMutableArray containing the MKNoteSender
              objects that belong to the receiver's MKPartPerformers  (A
              MKPartPerformer contains at most one MKNoteSender, created when the
              MKPartPerformer is initialized). The array is autoreleased.
*/
- (NSArray *) noteSenders; 

/*!
  @method status
  @result Returns an int.
  @discussion Returns the receiver's status.
*/
-(int) status;

/*!
  @method setPartPerformerClass:
  @param  aPartPerformerSubclass is an id.
  @result Returns an id.
  @discussion Normally, MKScorePerformers create instances of the MKPartPerformer
              class.  This method allows you to specify that instances of some
              MKPartPerformer subclass be created instead.  If
              <i>aPartPerformerSubclass</i> is not a subclass of MKPartPerformer
              (or MKPartPerformer itself), this method has no effect and returns
              nil.  Otherwise, it returns self.
*/
-setPartPerformerClass:aPartPerformerSubclass;
  
 /* Returns the class used for PartPerformers, as set by 
   setPartPerformerClass:. The default is MKPartPerformer itself. */
-partPerformerClass;

/*!
  @method setDelegate:
  @param  obj is an id.
  @discussion Sets the delegate as indicated.
  
              See MKPerformerDelegate.h
*/
- (void)setDelegate:(id)object;

/*!
  @method delegate
  @result Returns an id.
  @discussion Returns the receiver's delegate object, if any.
  
              See MKPerformerDelegate.h
*/
- delegate;

  /* 
     You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Archives partPerformers,firstTimeTag,lastTimeTag,timeShift,
     duration, and partPerformerClass. Also optionally archives score
     conductor and delegate using NXWriteObjectReference().
     */
- (void)encodeWithCoder:(NSCoder *)aCoder;
  /* 
     You never send this message directly.  
     Note that -init is not sent to newly unarchived objects.
     Should be invoked with NXReadObject(). 
     */
- (id)initWithCoder:(NSCoder *)aDecoder;

@end

/* Describes the protocol that may be implemented by the delegate: */
#import "MKPerformerDelegate.h"

#endif
