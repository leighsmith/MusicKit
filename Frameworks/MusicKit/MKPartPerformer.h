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
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*!
  @class MKPartPerformer
  @brief A MKPartPerformer object performs the MKNotes in a particular MKPart.
 
Every MKPartPerformer has exactly one MKNoteSender.  A MKPartPerformer is associated
with a MKPart through its <b>setPart:</b> method.  While a single
MKPartPerformer can only be associated with one MKPart, any number of
MKPartPerformers can by associated with the same MKPart.  If you're performing a
MKScore, you can use MKScorePerformer to create MKPartPerformers for you (one
for each MKPart in the MKScore).

When you activate a MKPartPerformer (through <b>activateSelf</b>) the object
copies its MKPart's NSMutableArray of MKNotes (it doesn't copy the MKNotes
themselves).  When the MKPartPerformer performs, it sequences over its copy of
the NSMutableArray, allowing you to edit the MKPart (by adding or removing
MKNotes) without disturbing the performance - changes made to a MKPart during a
performance are not seen by the MKPartPerformer.  However, since only the
NSMutableArray of MKNotes is copied but not the MKNotes themselves, you should
neither alter nor free a MKPart's MKNotes during a performance.

As an optimization for real time, you can enable a "Fast Activation mode", on a
class-wide basis.  Any MKPartPerformer activated  when this mode is in effect
does not retain its own copy of its MKPart's NSMutableArray.  In this mode, you
must not edit the MKPart while the MKPartPerformer is using it.

With the timing variables <b>firstTimeTag</b> and <b>lastTimeTag</b>, you can
specify the first and last timeTag values that are considered for performance. 
Keep in mind that you can offset the timing of a performance by setting the
<b>timeShift</b> variable defined in MKPerformer, and you can limit the duration
of the performance by setting the <b>duration</b> variable.

An example will clarify how <b>firstTimeTag</b>works.  If <b>firstTimeTag</b> 
is set to 3 and the MKPartPerformer is activated at time 0, then the first note
will sound at time 3.  If the MKPartPerformer is activated at time 1, the first
note will sound at time 4.  If <b>timeShift</b> is set to -1 and the
MKPartPerformer is activated at time 1, the first note will sound at time
3.

  @see  MKPerformer, MKScorePerformer, MKPart
*/
#ifndef __MK_PartPerformer_H___
#define __MK_PartPerformer_H___

#import "MKPerformer.h"
#import "MKScorePerformer.h"

@interface MKPartPerformer : MKPerformer
{
    MKNote *nextNote;            /* The next note to perform. Updated in -perform. */ 
    MKPart *part;                /* The MKPart associated with this object. */
    double firstTimeTag;         /* The smallest timeTag value considered for performance.  */
    double lastTimeTag;          /* The greatest timeTag value considered for performance.  */

@private
    int noteIndex;
    int noteCount;
    NSArray *noteArray;
    MKScorePerformer *scorePerformer;
}


/*!
  @param  yesOrNo is a BOOL.
  @return Returns an id.
  @brief If <i>yesOrNo</i> is YES, MKPartPerformers do <i>not</i> copy the
  MKPart's NSMutableArray of MKNotes when they activate.

  Fast
  Activation mode is provided for real-time situations where
  instantaneous activation is required, such as when triggering a
  sequence.  In this mode, MKNotes may not be added or removed from
  the MKPart while the MKPartPerformer is using it. 
  
*/
+setFastActivation:(BOOL)yesOrNo;
 /* If you send [MKPartPerformer setFastActivation:YES], MKPartPerformers 
    activated from then on will NOT copy the MKPart's NSArray of MKNotes.  
    That is, they will use [part notesNoCopy] instead of [part notes].
    If you use this mode, you may not modify the part while the MKPartPerformer
    is active. Default is NO.
  */

/*!
  @return Returns a BOOL.
  @brief Returns whether Fast Activation mode is enabled for the class.

  The
  default is NO.  See setFastActivation:.
*/
+(BOOL)fastActivation;

/*!
  @return Returns an id.
  @brief Initializes the receiver by creating and adding its single
  MKNoteSender.

  You must invoke this method after creating a new
  MKPartPerformer. A subclass implementation should send <b>[super
  init]</b> before performing its own initialization.  The return
  value is ignored.
*/
- init;
/*!
  @param  aPart is an id.
  @return Returns an id.
  @brief Associates the receiver with <i>aPart</i>.

  If the receiver is
  active, this does nothing and returns <b>nil</b>.  Otherwise returns
  the receiver.
*/
- setPart: (MKPart *) aPart; 

/*!
  @brief Returns the receiver's MKPart object.
  @return Returns the MKPart instance over which we sequence.
*/
- (MKPart *) part;

/*!
  @return Returns an id.
  @brief Activates the receiver for a performance.

  The receiver creates a
  copy of its MKPart's NSMutableArray of MKNotes (unless Fast
  Activation mode is enabled), sets <b>nextNote</b> to the first
  MKNote in the NSMutableArray, and sets <b>nextPerform</b> (an
  instance variable inherited from MKPerformer that defines the time to
  pperform <b>nextNote</b>) to the MKNote's timeTag plus
  <b>timeShift</b>.
  
  You never invoke this method directly; it's invoked as part of the
  <b>activate</b> method inherited from MKPerformer.  A subclass implementation
  should send <b>[super activateSelf]</b>.  If <b>activateSelf</b> returns
  <b>nil</b>, the receiver isn't activated.  The default implementation
  returns <b>nil</b> if there aren't any MKNotes in the receiver's MKNote
  NSMutableArray, otherwise it returns the receiver.  The <b>activate</b>
  method performs further timing checks.
*/
- activateSelf; 

/*!
  @brief Deactivates the receiver and frees its NSMutableArray of MKNotes.

  
  You never invoke this method directly; it's invoked as part of the
  <b>deactivate</b> method inherited from MKPerformer.  The return
  value is ignored.
*/
- (void) deactivate; 

/*!
  @return Returns an id.
  @brief Performs <b>nextNote</b> (by sending it to its MKNoteSender's
  connections) and then prepares the receiver for its next MKNote
  performance.

  It does this by seting <b>nextNote</b> to the next
  MKNote in its NSMutableArray and setting <b>nextPerform</b> to that
  MKNote's timeTag minus the value of <b>firstTimeTag</b>.  You never
  invoke this method directly; it's automatically invoked by the
  receiver's MKConductor during a performance.  A subclass
  implementation should send <b>[super perform]</b>.  The return value
  is ignored. To help support MIDI time code,  <b>perform</b> sends
  all noteUpdates up to the current time when it is first invoked. 
  This makes sure that all MKSynthInstruments and MIDI controllers
  have the proper values. 
*/
- perform; 

/*!
  @param  aTimeTag is a double.
  @return Returns an id.
  @brief Sets the value of the receiver's <b>firstTimeTag</b> variable to
  <i>aTimeTag</i>.

  Only MKNotes within the time span from <b>firstTimeTag</b>
  to <b>lastTimeTag</b> are included in the performance.
*/
- setFirstTimeTag: (double) aTimeTag; 

/*!
  @param  aTimeTag is a double.
  @return Returns an id.
  @brief Sets the value of the receiver's <b>lasTimeTag</b> variable to
  <i>aTimeTag</i>.

  Only MKNotes within the time span from <b>firstTimeTag</b>
  to <b>lastTimeTag</b> are included in the performance.
*/
- setLastTimeTag: (double) aTimeTag; 

/*!
  @return Returns a double.
  @brief Returns the value of the receiver's <b>firstTimeTag</b>instance
  variable.

  
*/
- (double) firstTimeTag; 

/*!
  @return Returns a double.
  @brief Returns the value of the receiver's <b>lasTimeTag</b>instance
  variable.

  
*/
- (double) lastTimeTag; 

/*!
  @param  zone is an NSZone.
  @return Returns an id.
  @brief Creates and returns a new MKPartPerformer as a copy of the
  receiver.

  The new object has its own MKNoteReceiver collection
  that contains copies of the receiver's MKNoteReceivers.
  The new MKNoteReceivers' connections (see the MKNoteReceiver class)
  are copied from the MKNoteReceivers in the receiver.
*/
- copyWithZone: (NSZone *) zone; 

/* 
  You never send this message directly.  
  Invokes superclass write: then archives firstTimeTag and lastTimeTag.
  Optionally archives part using NXWriteObjectReference().
 */
- (void) encodeWithCoder: (NSCoder *) aCoder;

/* 
  Note that -init is not sent to newly unarchived objects.
 */
- (id) initWithCoder: (NSCoder *) aDecoder;

@end

#endif
