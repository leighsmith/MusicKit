/*
  $Id$
  Defined In: The MusicKit

  Description:
    Full description is in the class description below.  

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2004, The MusicKit Project.
*/
/*!
  @class MKPerformer
  @brief MKPerformer is an abstract class that defines a mechanism for
performing MKNotes during a MusicKit performance.  
 
Each subclass of MKPerformer implements the <b>perform</b> method to define how it
obtains and performs MKNotes.

During a performance, a MKPerformer receives a series of
<b>perform</b> messages.  In its implementation of <b>perform</b>, a
MKPerformer subclass must set the <b>nextPerform</b> variable.
<b>nextPerform</b> indicates the number of beats to wait before the
next <b>perform</b> message is sent.  The messages are sent by the
MKPerformer's MKConductor.  Every MKPerformer is managed by a
MKConductor; unless you set its MKConductor explicitly, through the
<b>setConductor:</b> method, a MKPerformer is managed by the 
<i>defaultConductor</i>.

A MKPerformer contains a NSArray of MKNoteSenders, objects that send
MKNotes (to MKNoteReceivers) during a performance.  MKPerformer
subclasses should implement the <b>init</b> method to create and add
some number of MKNoteSenders to a newly created instance.  As part of
its <b>perform</b> method, a MKPerformer typically creates or
otherwise obtains a MKNote (for example, by reading it from a MKPart
or a scorefile) and sends it by invoking MKNoteSender's
<b>sendNote:</b> method.

To use a MKPerformer in a performance, you must first send it the
<b>activate</b> message.  <b>activate</b> invokes the
<b>activateSelf</b> method and then schedules the first <b>perform</b>
message request with the MKConductor.  <b>activateSelf</b> can be
overridden in a subclass to provide further initialization of the
MKPerformer.  The performance begins when the MKConductor class
receives the <b>startPerformance</b> message.  It's legal to activate
a MKPerformer after the performance has started.

Sending the <b>deactivate</b> message removes the MKPerformer from the
performance and invokes the <b>deactivateSelf</b> method.  This method
can be overridden to implement any necessary finalization, such as
freeing contained objects.

During a performance, a MKPerformer can be stopped and restarted by sending it
the <b>pause</b> and <b>resume</b> messages, respectively.  <b>perform</b>
messages destined for a paused MKPerformer are delayed until the object is
resumed.

You can shift a MKPerformer's performance timing by setting its
<b>timeShift</b> variable.  <b>timeShift</b>, measured in beats, is
added to the initial setting of <b>nextPerform</b>.  If the value of
<b>timeShift</b> is negative, the MKPerformer's MKNotes are sent
earlier than otherwise expected; this is particularly useful for a
MKPerformer that's performing MKNotes starting from the middle of a
MKPart or MKScore.  A positive <b>timeShift</b> delays the performance
of a MKNote.

You can also set a MKPerformer's maximum duration.  A MKPerformer is
automatically deactivated if its performance extends beyond <b>duration</b>
beats.

A MKPerformer has a status, represented as one of the following
<b>MKPerformerStatus</b> values:

<table border=1 cellspacing=2 cellpadding=0 align=center>
<tr>
<td align=left>Status</td>
<td align=left>Meaning</td>
</tr>
<tr>
<td align=left>MK_inactive</td>
<td align=left>A deactivated or not-yet-activated MKPerformer.</td>
</tr>
<tr>
<td align=left>MK_active</td>
<td align=left>An activated, unpaused MKPerformer.</td>
</tr>
<tr>
<td align=left>MK_paused</td>
<td align=left>The MKPerformer is activated but currently paused.</td>
</tr>
</table>

Some messages can only be sent to an inactive (MK_inactive) MKPerformer.  A
MKPerformer's status can be queried with the <b>status</b> message.

If you subclass MKPerformer, some care is required to make sure that
it synchronizes correctly to MIDI time code.  To make your own
MKPerformer subclass synchronize, you need to support a simple
informal protocol called <b>MKPerformer Time Code Protocol</b>, which
is described in the next section.

<h2>MKPerformer Time Code Protocol</h2>
  
This is an informal protocol, required if a
MKPerformer subclass is to synchronize correctly with incoming MIDI
time code.

There are three parts to this protocol.  	

<UL>
<LI>
A Time Code-conforming MKPerformer must implement a
method <b>setFirstTimeTag:</b>, which takes a <i>double</i>
argument, represnting the starting value of MIDI time code in
seconds.  A common implementation of this method stores the value it
is passed in an instance variable.  The MKPerformer class provides a
default implementation, which does nothing.	
</LI>
	
<LI>
A Time Code-conforming MKPerformer's
<b>activateSelf</b> method must position itself at the MKNote it
wants to send at  <i>firstTimeTag</i>.   If there is no MKNote for
that time, it should position itself at the first MKNote
<i>following</i> that time.<i>  </i>It then sets its
<i>nextPerform<b></b></i>instance variable<i> </i> to that MKNote's
time (which will be greater than or equal to <i>firstTimeTag.</i>)  
In other words, it sets <i>nextPerform</i> to the first time it
wants to run.  Finally, it returns <b>self</b>.   If there are no
MKNotes to send after the specified time,  it returns <b>nil</b>.  
</LI>
	
<LI>
The first invocation of a Time Code-conforming
MKPerformer's <b>perform</b> method should send the selected MKNote,
then choose the next MKNote and set <i>nextPerform</i> to the time
until that MKNote, as usual.  You can identify the first invocation
because the instance variable <i>performCount</i> will be set to 1. 
In the first invocation of <b>perform</b>, you may also want to send
any <b>noteUpdates</b> that preceed <i>firstTimeTag</i>.  This makes
sure that all MKSynthInstrument  and MIDI controllers are up to
date.  (This is sometimes called "chasing controller values" in MIDI
parlance.)	
</LI>
</UL>
 
Here is an example of a simple, but complete, Time
Code-conforming MKPerfomer.  This example is a simplified version of
the MusicKit MKPartPerformer:

<pre>
\#import &lt;MusicKit/MusicKit.h&gt;
\#import "MyPartPerformer.h"
\@implementation MyPartPerformer: MKPerformer
{
  id part;             // MKPart over which we're sequencing.
  double firstTimeTag; // Required by Time Code Protocol.
  int currentIndex;    // Index of nextNote
}
</pre>

  @see MKConductor, MKNoteSender 
*/
#ifndef __MK_Performer_H___
#define __MK_Performer_H___

#import <Foundation/Foundation.h>
#import "MKNoteSender.h"
#import "MKConductor.h"

/*!
  @file MKPerformer.h
 */

/*!
  @brief This enumeration defines the state of a MKPerformer.  A MKPerformer may be
 in one of the following three states:
 */
typedef enum _MKPerformerStatus {
    /*! Not yet activated or already deactivated. */
    MK_inactive,
    /*! MKPerformer has been activated. MKPerformer is either performing
       (if [MKConductor startPerformance] has been invoked), or will start
       performing when the performance starts (as soon as 
       [MKConductor startPerformance] is invoked.) */
    MK_active,
    /*! MKPerformer was activated, then paused. */
    MK_paused
} MKPerformerStatus;

@interface MKPerformer : NSObject
{
    /*! The object's MKConductor. */
    MKConductor *conductor;
    /*! The object's status. */
    MKPerformerStatus status;
    /*! Number of times the object has received perform messages. */
    int performCount;
    /*! Performance offset time in beats. */
    double timeShift;
    /*! Maximum performance duration in beats. */
    double duration;
    /*! The object's notion of the current time.
	The time in beats of the current invocation of perform, if any, otherwise, the time in beats of the last invocation of perform. */
    double time;
    /*! The next time in beats until the object will send a MKNote by sending a perform message. */
    double nextPerform;
    /*! The object's collection of MKNoteSenders. */
    NSMutableArray *noteSenders;
    /*! The object's delegate, if any. */
    id delegate;

@private
    double _pauseOffset;          // Difference between the beat when a performer is paused and its time.
    double _endTime;              // End time for the object. Subclass should not set _endTime.
    MKMsgStruct *_performMsgPtr;
    MKMsgStruct *_deactivateMsgPtr;
    MKMsgStruct *_pauseForMsgPtr;
}

/*!
  @return Returns an NSArray.
  @brief Creates and returns a NSArray containing the receiver's
  MKNoteSenders.

  The NSArray is autoreleased.
*/
- (NSArray *) noteSenders; 

/*!
  @brief Returns YES if <i>aNoteSender</i> is a member of the receiver's MKNoteSender NSArray.
  @param  aNoteSender is an id.
  @return Returns a BOOL.
*/
- (BOOL) isNoteSenderPresent: (MKNoteSender *) aNoteSender; 

/*!
  @brief Sends -<b>disconnectAllReceivers</b> to each of the object's MKNoteSenders.
  @return Returns an id.
*/
- disconnectNoteSenders;

/*!
  @brief Disconnects and releases the receiver's MKNoteSenders.
  @return Returns the receiver.
*/
- releaseNoteSenders; 

/*!
  @brief Removes the receiver's MKNoteSenders (but doesn't free them).
  @return Returns the receiver.
*/
- removeNoteSenders; 

/*!
  @return Returns an id.
  @brief Returns the first MKNoteSender in the receiver's NSArray.

  This is a
  convenience method provided for MKPerformers that create and add a
  single MKNoteSender.  If there are currently no MKNoteSenders, this
  method creates and adds a MKNoteSender.
*/
- (MKNoteSender *) noteSender; 

/*!
  @param  aNoteSender is an MKNoteSender instance.
  @return Returns an id.
  @brief Removes <i>aNoteSender</i> from the receiver.

  The receiver must be
  inactive.  If the receiver is currently in performance, or if
  <i>aNoteSender</i> wasn't part of its MKNoteSender NSArray, returns
  <b>nil</b>.  Otherwise returns <i>aNoteSender</i>.
	  For some subclasses, it is inappropriate for anyone other than the
  subclass instance itself to send this message. It is illegal to modify
  an active MKPerformer.
 */
- (MKNoteSender *) removeNoteSender: (MKNoteSender *) aNoteSender; 

/*!
  @param  aNoteSender is an MKNoteSender instance.
  @return Returns an id.
  @brief Adds <i>aNoteSender</i> to the recevier.

  The receiver must be
  inactive.  If the receiver is currently in performance, or if
  <i>aNoteSender</i> already belongs to the receiver, returns
  <b>nil</b>.  Otherwise returns the receiver.
*/
- (MKNoteSender *) addNoteSender: (MKNoteSender *) aNoteSender; 

/*!
  @brief Sets the receiver's MKConductor to <i>aConductor</i>. 
  
  The receiver must be inactive.
  @param  aConductor is an MKConductor instance.
  @return Returns an NO if receiver is active, YES if receiver is inactive and MKConductor properly set.
*/
- (BOOL) setConductor: (MKConductor *) aConductor;

/*!
  @brief Returns the receiver's MKConductor.
  @return Returns an MKConductor instance.
*/
- (MKConductor *) conductor; 

/*!
  @brief You never invoke this method directly; it's invoked automatically
  from the <b>activate</b> method.

  A subclass can implement this
  method to perform pre-performance activities.  In particular, if the
  subclass needs to alter the initial <b>nextPerform</b> value, it
  should be done here.  If <b>activateSelf</b> returns <b>nil</b>, the
  receiver is deactivated.  The default does nothing and returns the
  receiver.
  @return Returns an id.
*/
- activateSelf; 

/*!
  @return Returns an id.
  @brief This is a subclass responsibility expected to send a MKNote and then
  set the value of <b>nextPerform</b>.

  The return value is ignored.
*/
- perform; 

/*!
  @param  timeShift is a double.
  @return Returns an id.
  @brief Shifts the receiver's performance time by <i>timeShift</i> beats.

  The receiver must be inactive.  Returns <b>nil</b> if the receiver
  is currently in performance, otherwise returns the
  receiver.
*/
- setTimeShift: (double) timeShift;

/*!
  @param  dur is a double.
  @return Returns an id.
  @brief Sets the receiver's maximum performance duration to <i>dur</i> in
  beats.

  The receiver must be inactive.  Returns <b>nil</b> if the
  receiver is currently in performance, otherwise returns the
  receiver.
*/
- setDuration: (double) dur; 

/*!
  @return Returns a double.
  @brief Returns the receiver's time shift value.  
*/
- (double) timeShift;

/*!
  @return Returns a double.
  @brief Returns the receiver's duration value.
*/
- (double) duration; 

/*!
  @return Returns an int.
  @brief Returns the receiver's status.
*/
- (int) status; 

/*!
  @return Returns an int.
  @brief Returns the number of <b>perform</b> messages the receiver has
  recieved in the current performance.
*/
- (int) performCount; 

/*!
  @return Returns an id.
  @brief If the receiver isn't inactive, immediately returns the receiver; if
  its duration is less than or equal to 0.0, immediately returns
  <b>nil</b>.

  Otherwise prepares the receiver for a performance by
  setting <b>nextPerform</b> to 0.0, <b>performCount</b> to 0,
  invoking <b>activateSelf</b>, scheduling the first <b>perform</b>
  message request with the MKConductor, and setting the receiver's
  status to <b>MK_active</b>.  If a subclass needs to alter the
  initial value of <b>nextPerform</b>, it should do so in its
  implementation of the <b>activateSelf</b> method.  Returns the
  receiver.
*/
- activate; 

/*!
  @brief If the receiver's status is inactive, this does nothing and
  immediately returns the receiver.

  Otherwise removes the receiver
  from the performance, invokes <b>deactivateSelf</b>, and sets the
  receiver's status to <b>MK_inactive</b>.  Also sends <tt>[delegate hasDeactivated:self];</tt>
  Returns the receiver.
*/
- (void) deactivate;

/*!
  @return Returns an id.
  @brief Initializes the receiver.

  You invoke this method when creating a
  new instance of MKPerformer.  A subclass implementation should send
  <b>[super init]</b> before performing its own initialization. 
  
*/
- init; 

/*!
  @return Returns an id.
  @brief Suspends the receiver's performance and returns the receiver.

  To free a paused MKPerformer during a performance, you should first
  send it the <b>deactivate</b> message.  Also sends [delegate hasPaused:self];
*/
- pause; 

/*!
  @param  beats is a double.
  @return Returns an id.
  @brief Like pause, but also enqueues a resume message to be sent the specified
  number of beats into the future.
*/
-pauseFor: (double) beats;

/*!
  @return Returns an id.
  @brief Resumes the receiver's performance and returns the
  receiver.

  Also sends [delegate hasResumed:self];
*/
- resume; 

/*!
  @return Returns an MKPerformer instance.
  @brief Creates and returns an initialised, inactive MKPerformer as a copy of the
  receiver.

  The new object has the same time shift and duration as
  the reciever.  Its <b>time</b> and <b>nextPerform</b> variables are
  set to 0.0.  The new object's MKNoteSenders are copied from the
  receiver.
*/
- copyWithZone: (NSZone *) zone;

/*!
  @return Returns a double.
  @brief Returns the time, in beats, that the receiver last received the
  <b>perform</b> message.

  If the receiver is inactive, returns
  MK_ENDOFTIME.  The return value is measured from the beginning of
  the performance and doesn't include any time that the receiver has
  been paused.
*/
- (double) time; 

/*!
  @brief Implements an informal protocol for firstTimeTag/lastTimeTag.
  
  Does nothing in this abstract class.
 */
- setFirstTimeTag: (double) v;

/*!
  @brief Implements an informal protocol for firstTimeTag/lastTimeTag.
  
  Does nothing in this abstract class.
 */
- setLastTimeTag: (double) v;

/*!
  @brief  Returns the first time tag in beats.
  Returns 0.
  @return Returns the first time tag in beats.
 */
- (double) firstTimeTag;

/*!
  @brief  Returns the last time tag in beats.

  Returns MK_ENDOFTIME.
  @return  Returns the last time tag in beats.
 */
- (double) lastTimeTag;

/*!
  @brief Assigns a delegate to receive messages described in MKPerformerDelegate.h. 
 
  The object is not retained.
  @param object The receiving delegate object. 
 */
- (void) setDelegate: (id) object;

/*!
  @brief Returns the receiver's delegate, if any.
  @return Returns an id.
*/
- delegate;

/*!
  @param  aTimeIncrement is a double.
  @return Returns an id.
  @brief Shifts the MKPerformer's next scheduled invocation of <b>perform</b>
  by <i>aTimeIncrement</i>.

  Positive values make the next invocation later,
  negative values make it earlier.  If <i>aTimeIncrement</i> is negative and of a
  magnitude large enough to shift the MKPerformer into the past,
  reschedules the MKPerformer to invoke <b>perform </b>immediately.
*/
- rescheduleBy: (double) aTimeIncrement;

/*!
  @param  aTime is a double.
  @return Returns an id.
  @brief Shifts the MKPerformer's next scheduled invocation of <b>perform</b>
  to <i>time</i>, which is in the receiver's MKConductor's time base.

  If <i>time</i> is in the past, reschedules the MKPerformer to invoke
  <b>perform</b>immediately.
*/
- rescheduleAtTime: (double) aTime;

/*!
  @brief  You never send this message directly.

 Archives noteSender array, timeShift, and duration. Also optionally 
 archives conductor and delegate.
 */
- (void) encodeWithCoder: (NSCoder *) aCoder;

/*! 
  @brief You never send this message directly.

  Note that the status of an unarchived MKPerformer is always MK_inactive.
 */
- (id) initWithCoder: (NSCoder *) aDecoder;

/*!
  @brief Returns YES if receiver's status is not MK_inactive.  
  @return Returns a BOOL.
*/
- (BOOL) inPerformance;

@end

/* Describes the protocol that may be implemented by the delegate: */
#import "MKPerformerDelegate.h"

#endif
