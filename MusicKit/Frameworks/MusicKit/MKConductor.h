/*
  $Id$
  Defined In: The MusicKit

  Description:
    This is the header for the MusicKit scheduler. See documentation for details.

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.17  2002/03/20 17:05:11  sbrandon
  New delegate message passing system, between any thread and the
  appkit thread. This is basically the same as that in the SndKit
  for passing delegate messages back from background thread, so
  it works quite well.

  Revision 1.16  2001/09/07 18:44:12  leighsmith
  Moved @class before headerdoc declaration, corrected URL reference

  Revision 1.15  2001/09/07 00:14:46  leighsmith
  Corrected @discussion

  Revision 1.14  2001/09/06 21:27:47  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.13  2001/08/29 21:51:55  leighsmith
  Merged RTF Class Reference documentation into headerdoc comments

  Revision 1.12  2001/08/27 23:51:47  skotmcdonald
  deltaT fetched from conductor, took out accidently left behind debug messages (MKSampler). Conductor: renamed time methods to timeInBeat, timeInSamples to be more explicit

  Revision 1.11  2001/07/05 22:57:58  leighsmith
  Added useful status methods and removed _wakeUpMKThread

  Revision 1.10  2001/04/24 23:37:26  leighsmith
  Added _MKWakeThread prototype for separate threading

  Revision 1.9  2000/04/20 21:39:00  leigh
  Removed flakey longjmp for unclocked MKConductors, improved description

  Revision 1.8  2000/04/16 04:28:17  leigh
  Class typing and added description method

  Revision 1.7  2000/03/31 00:14:43  leigh
  typed defaultConductor

  Revision 1.6  2000/01/20 17:15:36  leigh
  Replaced sleepMs with OpenStep NSThread delay

  Revision 1.5  2000/01/13 06:53:17  leigh
  doco cleanup

  Revision 1.4  1999/09/04 22:02:17  leigh
  Removed mididriver source and header files as they now reside in the MKPerformMIDI framework

  Revision 1.3  1999/08/06 16:31:12  leigh
  Removed extraInstances and implementation ivar cruft

  Revision 1.2  1999/07/29 01:25:44  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
@class MKConductor;

/*!
  @class MKConductor
  @discussion

The MKConductor class defines the mechanism that controls the timing
of a MusicKit performance.  A MKConductor's most important tasks are
to schedule the sending of MKNotes by MKPerformers (and MKMidi), and
to control the timing of MKEnvelope objects during DSP synthesis.
Even in the absence of MKPerformers and MKEnvelopes, you may want to
use a MKConductor to take advantage of the convenient scheduling
mechanism that it provides.

Each instance of MKConductor contains a message request queue, a list
of messages that are to be sent to particular objects at specific
times.  To enqueue a message request with a MKConductor, you invoke
the <b>sel:to:atTime:argCount:</b> or
<b>sel:to:withDelay:argCount:</b> method.  The former sends a message
at a specific time measured in beats from the time the MKConductor
started performing, while the latter sends the message a specified
number of beats after the request is received.  Once you have made a
message request through these methods, you can't rescind the action;
if you need more control over message requests - for example, if you
need to be able to reschedule or remove a request - you should use the
following C functions:

&#183; <b>MKNewMsgRequest()</b> creates and returns a new message
request structure.

&#183; <b>MKScheduleMsgRequest()</b> places a previously created
message request (structure) in a specific MKConductor's message
request queue.

&#183; <b>MKRepositionMsgRequest()</b> repositions a message request
within a MKConductor's queue.

&#183; <b>MKCancelMsgRequest()</b> removes a message request.

&#183; <b>MKRescheduleMsgRequest()</b> is a convenience function that
cancels a request and then creates a new one.

For more information on these functions, see Chapter 3, "C Functions."

The MKConductor class provides two special message request queues, one
that contains messages that are sent at the beginning of a performance
and another for messages that are sent after a performance ends.  The
class methods <b>beforePerformanceSel:to:argCount:</b> and
<b>afterPerformanceSel:to:argCount: </b>enqueue message requests in
the before- and after-performance queues, respectively.

A MusicKit performance starts when the MKConductor class receives the
<b>startPerformance</b> message.  At that time, the MKConductor class
sends the messages in its before-performance queue and then the
MKConductor instances start processing their individual message
request queues.  As a message is sent, the request that prompted the
message is removed from its queue.  The performance ends when the
MKConductor class receives <b>finishPerformance</b>, at which time the
after-performance messages are sent. Any message requests that remain
in the individual MKConductors' message request queues are removed.
Note, however, that the before-performance queue isn't similarly
cleared.  If you invoke <b>beforePerformanceSel:to:argCount:
</b>during a performance, the message request will survive a
subsequent <b>finishPerformance</b> and will affect the next
performance.

By default, if all the MKConductors' queues become empty at the same
time (not including the before- and after-performance queues),
<b>finishPerformance</b> is invoked automatically.  This is convenient
if you're performing a MKPart or MKScore and you want the performance
to end when all the MKNotes have been played.  However, for many
applications, such as those that create and perform MKNotes in
response to a user's actions, universally empty queues isn't
necessarily an indication that the performance is over.  To allow a
performance to continue even if all the queues are empty, send
<b>setFinishWhenEmpty:NO </b>to the MKConductor class.

You can pause and resume an entire performance through methods sent to
the MKConductor class:

&#183; <b>pausePerformance</b> causes all MKConductor instances to
stop processing their message request queues.

&#183;	<b>resumePerformance</b> resumes a paused performance.  

These messages are ignored if a performance isn't in progress.

You can pause and resume individual MKConductor objects through the
<b>pause</b> and <b>resume</b> methods.  In addition, you can pause a
MKConductor object for a predetermined number of seconds (not beats)
through <b>pauseFor:</b>.  To offset the begin time of a
MKConductor<b></b> object before a performance starts, invoke
<b>setTimeOffset:</b>.  Here again, the arguments is taken as seconds.
You can also offset the begin time of a MKConductor object by an
indeterminate amount of time by sending it the <b>pause</b> message
before a performance begins and then sending it <b>resume</b> while
the performance is in progress.  After a performance has ended, all
currently paused MKConductor objects are (virtually) resumed.  Thus, a
MKConductor object is guaranteed not to be paused when a performance
starts (unless, of course, you have specifically sent it the
<b>pause</b> message since <b>finishPerformance</b> was last sent).

A MKConductor object can be given a delegate that's sent the
<b>hasPaused:</b> message when the MKConductor is paused and
<b>hasResumed:</b> when the MKConductor resumes.  As in the AppKit's
delegate paradigm, a delegate messages is sent only if the delegate
responds to it.

The rate at which a MKConductor object processes its message request
queue can be set through either the <i>Tempo Protocol</i> or the
<i>Time Map Protocol.</i> The <i>Tempo Protocol</i> consists of the
following two methods (you may use either):

&#183;	<b>setTempo:</b> sets the rate as beats per minute.
&#183;	<b>setBeatSize:</b> sets the size of an individual beat, in seconds. 

You can change a MKConductor's tempo anytime, even during a
performance.  If your application requires multiple simultaneous
tempi, you need to create more than one MKConductor, one for each
tempo.  A MKConductor's tempo is initialized to 60.0 beats per minute.

An alternative way to modify tempo is to use a tempo track or "Time
Map".  This protocol relies on the MKConductor's delegate to implement
two methods that specify the mapping between "beat time" and "clock
time."  If the delegate implements one of these methods, it must
implement both.  By implementing these methods, the delegate specifies
that it is using the <i>Time Map Protocol</i>.  The two methods are
<b>beatToClock:from:</b> and <b>clockToBeat:from:</b>.  These methods
map from pre-tempo to post-tempo time.  For details, see 
<a href=http://www.musickit.org/MusicKitConcepts/musicperformance.html>
the section entitled Music Performance
</a>

The responsiveness of a performance to the user's actions depends on
whether the MKConductor class is clocked and upon the value of the
performance's <i>delta time</i>.  By default, the MKConductor class is
clocked which means that message request queues are processed in a
timely fashion: If, for example, two requests are specified to be sent
one beat apart, then the message sending mechanism sends the first
message and then, one beat later, sends the second message.  When the
MKConductor class is clocked, a running NSApplication object is
assumed to be present.  If you don't need interactive control over a
performance, you may find it beneficial to have the messages in the
message request queues sent one after another as quickly as possible,
while depending on another device, such as the DSP or MIDI drivers, to
handle the timing of the actual realization (this is further explained
in the descriptions of the MKOrchestra and MKMidi classes).  To allow
the queues to be processed in this way, you set the MKConductor class
to be unclocked by sending it the <b>setClocked:NO</b> message.  If
you set the MKConductor class to be unclocked, be aware that the
<b>startPerformance</b> method doesn't return until the performance is
over.  (In this situation, sending <b>setFinishWhenEmpty:NO</b> to the
MKConductor class is ill-advised since <b>startPerformance</b> would
never return.)

Setting a performance's delta time further refines the responsiveness
of a performance. Delta time is set through the <b>setDeltaT:</b>
class method; the argument defines an imposed time lag, in seconds,
between the MKConductor's notion of time and that of the DSP and MIDI
device drivers.  It acts as a timing cushion that can help to maintain
rhythmic integrity by granting your application a sort of
computational head start: As you set the delta time to larger values,
your application has more time to process MKNotes before they are
realized.  However, this computational advantage is obtained at the
expense of degraded responsiveness.  Choosing the proper delta time
value depends on how responsive your application needs to be.  For
example, if you are driving DSP synthesis from MIDI input (in other
words, you have a MKMidi object connected to a MKSynthInstrument -
this is usually the most demanding scenario in terms of desired
real-time response), a delta time of as much as 10 milliseconds (0.01
seconds) is generally acceptable.  If you are adjusting MKNote
parameters by moving a NSSlider with the mouse, a delta time of 100
milliseconds or more can be tolerated.  Finding the right delta time
for your application is largely a matter of experimentation.

Every MKConductor instance has a notion of the current time measured
in its own tempo, as returned by sending it the <b>time</b> message.
The returned value is the number of beats the receiver has spent in
performance and doesn't include the receiver's time offset, any time
it has spent while paused, nor does it include the performance's delta
time.  The MKConductor class also responds to the <b>time</b> message;
it returns the current duration of the performance in seconds,
excluding any time that the entire performance has been paused (and
also excluding deltat time).  The value returned by the <b>time</b>
message, whether sent to the MKConductor class or to an instance, is
actually the time at which the last message from any of the
MKConductors' queues was sent.  This latency is present because the
MKConductor class updates its notion of time (from which all the
MKConductor instances compute their time) only when a message from one
of the request queues is sent.  If your application sends a message
(or calls a C function) in response to an asynchronous event, it must
first update the MKConductors' notions of time by bracketing the code
you invoke with <b>[MKConductor lockPerformance]</b> and
<b>[MKConductor unlockPerformance]</b> .  You should send these
messages before performing tasks such as pausing or resuming a
MKConductor - you should even send them immediately before sending
<b>finishPerformance</b>.  If, for yet another example, your
application sends MKNotes directly to MKInstruments, you should send
<b>lockPerformance</b> immediately before each MKNote is sent and
<b>unlockPerformance</b> afterwards.  (This API supercedes the older
<b>adjustTime</b>, which will still work only if the MusicKit is not
run in a separate thread.  See <b>+useSeparateThread:</b>.)

MKConductors and MKPerformers have a special relationship: Every
MKPerformer object is controlled by an instance of MKConductor, as set
through MKPerformer's <b>setConductor:</b> method.  While a
MKPerformer can be controlled by only one MKConductor, a single
MKConductor can control any number of MKPerformers.  As a MKPerformer
acquires successive MKNotes, it enqueues, with its associated
MKConductor, requests for the MKNotes to be sent to its connected
MKInstruments. This enqueuing is performed automatically through a
mechanism defined by the MKPerformer class. As a convenience, the
MusicKit automatically creates an instance of MKConductor called the
<i>defaultConductor</i>; if you don't set a MKPerformer's MKConductor
directly, it's controlled by the defaultConductor. You can retrieve the
defaultConductor (in order to set its tempo or to enqueue message
requests, for example) by sending the <b>defaultConductor</b> message
to the MKConductor class.

The MusicKit also creates an instance of MKConductor called the
<i>clockConductor</i>, which you can retrieve through the
<b>clockConductor</b> class method.  The clockConductor has an
unchangeable tempo of 60.0 beats per minute and can't be paused.
While the clockConductor can be used to control MKPerformers, its
most important task is to control the timing of MKEnvelope objects
during DSP synthesis.  All MKEnvelopes are controlled by the
clockConductor automatically.  The clockConductor also controls
the duration of any MKNoteDurs that you send directly to an
MKInstrument. In other words, the duration of such a MKNote is always
computed using the 60.0 beats-per-minute tempo of the clockConductor.  

The clockConductor's queue is treated like any other queue:
You can enqueue message requests with the clockConductor just as
you would with any other MKConductor. This also means that the
clockConductor's queue contributes to a determination of whether
all the queues are empty.

MKConductors can synchronize to incoming MIDI time code. This functionality is described in 
<a href=http://www.musickit.org/MusicKitConcepts/miditimecode.html>
Appendix B. entitled MIDI Time Code in the MusicKit</a>.

See also: MKPerformer, MKOrchestra, MKMidi */
#ifndef __MK_Conductor_H___
#define __MK_Conductor_H___

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSThread.h>
#import <SndKit/SndKit.h>

@class NSLock;
@class NSConditionLock;
@class NSConnection;

#ifdef __MINGW32__
  @class SndConditionLock;
#endif

// Enforce C name mangling to allow linking MusicKit functions to C++ code
#ifdef __cplusplus
extern "C" {
#endif

 /* The Conductor message structure.  All fields are private and
  * shouldn't be altered directly from an application.
  * LMS: should become an object named MKConductorMsg
  */
typedef struct _MKMsgStruct { 
    double _timeOfMsg;     
    SEL _aSelector;       
    id _toObject;	       
    int _argCount;             
    id _arg1;
    id _arg2;
    struct _MKMsgStruct *_next;	
    IMP _methodImp;        
    id *_otherArgs;
    BOOL _conductorFrees;  
    BOOL _onQueue;      
    struct _MKMsgStruct *_prev;
    MKConductor *_conductor;
} MKMsgStruct;

#define MK_ENDOFTIME (6000000000.0) /* A long time, but not as long as MK_FOREVER */

/* Time functions */
extern double MKGetTime(void);           /* Returns the time in seconds. */
extern double MKGetDeltaT(void);         /* Returns deltaT, in seconds. */
extern void MKSetDeltaT(double val);     /* Sets deltaT, in seconds. */
extern double MKGetDeltaTTime(void);     /* Returns deltaT + time, in seconds. */

/* The following modes determine how deltaT is interpreted. */
#define MK_DELTAT_DEVICE_LAG 0
#define MK_DELTAT_SCHEDULER_ADVANCE 1
 
extern void MKSetDeltaTMode(int newMode);
extern int MKGetDeltaTMode(void);
extern double MKSetTime(double newTime); /* Rarely used */

extern MKMsgStruct 
  *MKNewMsgRequest(double timeOfMsg,SEL whichSelector,id destinationObject,
		   int argCount,...);

extern void 
  MKScheduleMsgRequest(MKMsgStruct *aMsgStructPtr, id conductor);

extern MKMsgStruct *
  MKCancelMsgRequest(MKMsgStruct *aMsgStructPtr);

extern MKMsgStruct *
  MKRescheduleMsgRequest(MKMsgStruct *aMsgStructPtr,id conductor,
			 double timeOfNewMsg,SEL whichSelector,
			 id destinationObject,int argCount,...);

extern MKMsgStruct *
  MKRepositionMsgRequest(MKMsgStruct *aMsgStructPtr,double newTimeOfMsg);

extern void MKFinishPerformance(void);

@interface MKConductor : NSObject
/* nextMsgTime = (nextbeat - time) * beatSize */
{
  /*! @var time Current Time in beats, updated (for all instances) after timed entry fires off. */
    double time;       
  /*! @var nextMsgTime Time, in seconds, when next message is scheduled to be sent by this MKConductor. */
    double nextMsgTime;           // sb: relative to start of performance, I think.
  /*! @var beatSize The duration of a single beat in seconds. */
    double beatSize;    
  /*! @var timeOffset Performance timeOffset in seconds. */
    double timeOffset;
  /*! @var isPaused YES if this instance is paused. Note that pausing
    all MKConductors through the pause factory method doesn't set this
    to YES. */ 
    BOOL isPaused;      
  /*! @var delegate The object's delegate. */
    id delegate;
  /*! @var activePerformers NSMutableArray object of active performers
    using this conductor. Don't alter this NSMutableArray. */
    NSMutableArray *activePerformers;
  /*! @var MTCSync MIDI Time Code synchronization object, if any. */
    id MTCSynch;

    /* Internal use only */
@private
    MKMsgStruct *_msgQueue;
    MKConductor *_condNext;
    MKConductor *_condLast;
    double _pauseOffset;
    double inverseBeatSize;
    double oldAdjustedClockTime;
    MKMsgStruct *pauseFor;
    unsigned char archivingFlags;
    unsigned char delegateFlags;
}
 
+ allocWithZone:(NSZone *)zone;

/*!
  @method alloc
  @result Returns an id.
  @discussion Creates and returns a new MKConductor object with a tempo of 60.0
              beats per minute, allocated from the default zone.  You must send
              <b>init </b>to the new instance.  If a performance is currently in
              progress, this does nothing and returns <b>nil</b>.
*/
+ alloc;

/*!
  @method init
  @result Returns an id.
  @discussion Initializes a new MKConductor.  You must send this message after
              using <b>alloc</b> or <b>allocFromZone:</b> to create a
              MKConductor.
*/
- init;

/*!
  @method adjustTime
  @result Returns an id.
  @discussion <i>This method is superceded by <b>+lockPerformance </b>and
              <b>+unlockPerformance</b>.</i>  
              
              Updates every MKConductor's notion of time.  This method
              may be invoked just before you send a message or call a
              C function that affects the performance.  Typical
              examples include methods that are in response to the
              user's actions, methods that send MKNotes directly to
              MKInstruments, and methods, such as <b>pause</b> and
              <b>resume</b>, that are sent to a MKConductor object or
              to the MKConductor class.  You do not need to send this
              message if you are invoked in response to MKConductor or
              MKMidi messages.  Returns the receiver.
*/
+ adjustTime; 

/*!
  @method startPerformance
  @result Returns an id.
  @discussion Starts a performance.  All MKConductor objects begin at the same
              time.  If the performance is clocked and you don't have a running
              Application object (NSApplication), this does nothing and returns
              <b>nil</b>.  In all other cases, the receiver is returned; however,
              if the performance is unclocked, this method doesn't return until
              the performance is over.
*/
+ startPerformance;

/*!
  @method defaultConductor
  @result Returns an MKConductor.
  @discussion Returns the defaultConductor.
*/
+ (MKConductor *) defaultConductor; 

/*!
  @method inPerformance
  @result Returns a BOOL.
  @discussion Returns <b>YES</b> if a performance is currently taking place (even
              if it's paused), otherwise returns <b>NO</b>.
*/
+(BOOL) inPerformance; 

/*!
  @method finishPerformance
  @result Returns an id.
  @discussion Ends the performance.  All enqueued messages are removed (from
              MKConductor instances' message queues - not from the before- and
              after-performance queues) and the <b>after-performance</b> messages
              are sent<b>. </b>If<b> finishWhenEmpty</b> is <b>YES</b>, this
              message is automatically sent when all message queues are exhausted.
               Returns <b>nil</b>.
*/
+ finishPerformance; 

/*!
  @method pausePerformance
  @result Returns an id.
  @discussion Pauses the performance.  The performance is suspended until the
              MKConductor class receives the <b>resumePerformance</b> message. 
              You can't pause an unclocked performance; returns <b>nil</b> if the
              performance is unclocked.  Otherwise returns the receiver.  This
              message is ignore and the receiver is returned if a performance
              isn't in progress.  You cannot pause a performance in which a
              MKConductor is synchronizing to MIDI time code.   An attempt to do
              so will be ignored.     
*/
+ pausePerformance; 

/*!
  @method isPaused
  @result Returns a BOOL.
  @discussion Returns <b>YES</b> if the performance is paused, otherwise returns
              <b>NO</b>.
*/
+(BOOL) isPaused; 

/*!
  @method resumePerformance
  @result Returns an id.
  @discussion Resumes a  performance, allowing it to continue from where it was
              paused.  If the performance is unclocked, return <b>nil</b>,
              otherwise returns the receiver.
*/
+ resumePerformance; 

/*!
  @method currentConductor
  @result Returns an id.
  @discussion Returns the MKConductor instance that's currently sending a message,
              or <b>nil</b> if no message is being sent.
*/
+ currentConductor; 

/*!
  @method clockConductor
  @result Returns an id.
  @discussion Returns the clockConductor.
*/
+ clockConductor;

/*!
  @method setClocked:
  @param  yesOrNo is a BOOL.
  @result Returns an id.
  @discussion If <i>yesOrNo</i> is <b>YES</b> (the default), the MKConductors
              dispatches each message at the specified time, waiting if necessary.
               If <b>NO</b>, messages are sent as quickly as possible.  In an
              unclocked performance, a subsequent startPerformance message doesn't
              return until the performance is over, thus effectively disabling the
              user interface.  Does nothing and returns <b><i>nil</i></b><i></i>
              if a performance is in progress, otherwise returns the
              receiver.<i></i>   Unclocked performances involving MIDI time code
              conductors are not supported.   
*/
+ setClocked:(BOOL) yesOrNo; 

/*!
  @method isClocked
  @result Returns a BOOL.
  @discussion Returns <b>YES</b> if the performance is clocked, <b>NO</b> if it
              isn't.  By default, a performance is clocked.
*/
+(BOOL) isClocked; 

/*!
  @method setFinishWhenEmpty:
  @param  yesOrNo is a BOOL.
  @result Returns an id.
  @discussion If <i>yesOrNo</i> is <b>YES</b> (the default), the performance is
              terminated when all the MKConductors' message queues are empty.  If
              <b>NO</b>, the performance continues until the
	      <b>finishPerformance</b> message is sent to the MKConductor class.
*/
+ setFinishWhenEmpty:(BOOL) yesOrNo; 

/*!
  @method isEmpty
  @result Returns a BOOL.
  @discussion Returns <b>YES</b> if a performance is in progress and all the
              MKConductor instances' message request queues are are empty,
              otherwise returns <b>NO.</b>
*/
+(BOOL) isEmpty;

/*!
  @method finishWhenEmpty
  @result Returns a BOOL.
  @discussion Returns <b>YES</b> if the performance will finish when all
              MKConductors' message queues are empty, <b>otherwise returns
              NO</b>.
*/
+(BOOL) finishWhenEmpty;

/*!
  @method setDeltaT:
  @param  newDeltaT is a double.
  @discussion Set the delta time in seconds.
              See also: <b>MKSetDeltaT()</b>
*/
+(void) setDeltaT: (double) newDeltaT;

/*!
  @method deltaT
  @result Returns a double.
  @discussion Returns the delta time in seconds.
*/
+(double) deltaT;

/*!
  @method copy
  @result Returns an id.
  @discussion Returns a new MKConductor created through <b>[MKConductor
              new]</b>.
*/
- copy;
- copyWithZone:(NSZone *)zone;

/*!
  @method isPaused
  @result Returns a BOOL.
  @discussion Returns <b>YES</b> if the receiver is paused.
*/
-(BOOL) isPaused; 

/*!
  @method pause
  @result Returns an id.
  @discussion Pauses the performance of the receiver and sends <b>hasPaused:</b>
              to its delegate.  The effect is restricted to the present
              performance.  Invoke <b>resume</b> to unpause a MKConductor.  You
              can't pause the clockConductor; returns <b>nil</b> in this case (and
              the delegate message isn't sent).  Otherwise returns the receiver. 
              Note that you can pause a MKConductor object before a performance
              begins.  You cannot pause a MKConductor that is synchronizing to
              MIDI time code.  An attempt to do so is ignored.
*/
- pause; 

/*!
  @method pauseFor:
  @param  seconds is a double.
  @result Returns an id.
  @discussion A convenience method.  Pauses the performance of the receiver, sends
              <b>hasPaused:</b> to its delegate, and schedules a request for
              <b>resume</b> to be sent to the receiver in <i>seconds</i> seconds. 
              If the receiver is currently paused through a previous invocation of
              this method, the current <b>resume</b> request supercedes the
              previous one.  The effect is restricted to the present performance. 
              You can't pause the clockConductor; returns <b>nil</b> in this case
              (and the delegate message isn't sent).  Otherwise returns the
              receiver.  Note that you can invoke this method before a performance
              begins; the <b>resume</b> message is enqueued to be sent
              <i>seconds</i> seconds after the performance starts.
*/
- pauseFor:(double) seconds;

/*!
  @method resume
  @result Returns an id.
  @discussion Resumes the receiver's performance and returns the receiver.  If the
              receiver isn't currently paused, this has no effect.
*/
- resume; 

/*!
  @method setBeatSize:
  @param  newBeatSize is a double.
  @result Returns a double.
  @discussion Sets the tempo by changing the size of a beat to <i>newBeatSize</i>,
              measured in seconds.  The default beat size is 1.0 (one second). 
              Attempts to set the tempo of the clockConductor are ignored. 
              Returns the previous beat size.
*/
-(double) setBeatSize:(double) newBeatSize; 

/*!
  @method beatSize
  @result Returns a double.
  @discussion Returns the size of the receiver's beat in seconds.
*/
-(double) beatSize; 

/*!
  @method setTempo:
  @param  newTempo is a double.
  @result Returns a double.
  @discussion Sets the receiver's tempo to <i>newTempo</i>, measured in beats per
              minute.  Attempts to set the tempo of the clockConductor are
              ignored.  Returns the previous tempo.
*/
-(double) setTempo:(double) newTempo; 

/*!
  @method tempo
  @result Returns a double.
  @discussion Returns the receiver's tempo in beats per minute.
*/
-(double) tempo; 

/*!
  @method setTimeOffset:
  @param  newTimeOffset is a double.
  @result Returns a double.
  @discussion Sets the receiver's performance time offset to <i>newTimeOffset</i>
              seconds.  Keep in mind that since the offset is measured in seconds,
              it's not affected by the receiver's tempo.  Attempts to set the
              offset of the clockConductor are ignored. Returns the previous time
              offset.
*/
-(double) setTimeOffset:(double) newTimeOffset; 

/*!
  @method timeOffset
  @result Returns a double.
  @discussion Returns the receiver's performance time offset in
              seconds.
*/
-(double) timeOffset; 

/*!
  @method sel:to:withDelay:argCount:
  @param  aSelector is a SEL.
  @param  toObject is an id.
  @param  beats is a double.
  @param  argCount,... is an int counting variable arguments.
  @result Returns an id.
  @discussion Places, in the receiver's message request queue, a request for
              <i>aSelector</i> to be sent to <i>toObject</i> at time <i>beats</i>
              beats from the receiver's notion of the current time.  To ensure
              that the receiver's notion of time is up to date, you should send
              <b>lockPerformance</b> before invoking this method and
              <b>unlockPerformance</b>afterwards.   <i>argCount</i>  specifies the
              number of four-byte arguments to <i>aSelector</i> followed by the
              arguments themselves, seperated by commas (two arguments,
              maximum).
*/
- sel:(SEL) aSelector to: toObject withDelay:(double) beats argCount:(int) argCount, ...;

/*!
  @method sel:to:atTime:argCount:
  @param  aSelector is a SEL.
  @param  toObject is an id.
  @param  time is a double.
  @param  argCount,... is an int counting variable arguments.
  @result Returns an id.
  @discussion Places, in the receiver's message request queue, a request for
              <i>aSelector</i> to be sent to <i>toObject</i> at time <i>time</i>
              beats from the beginning of the receiver's performance. 
              <i>argCount</i> specifies the number of four-byte arguments to
              <i>aSelector</i> followed by the arguments themselves, seperated by
              commas (two arguments, maximum). 
*/
- sel:(SEL) aSelector to: toObject atTime:(double) time argCount:(int) argCount, ...;

/*!
  @method timeInSeconds
  @result Returns a double.
  @discussion Same as <tt>[[MKConductor clockConductor] time]</tt>.
              Returns the current performance time, in seconds.  This doesn't
              include time that the performance has been paused, nor does it
              include the performance's delta time.  If a performance isn't in
              progress, MK_NODVAL is returned .  Use <b>MKIsNoDVal()</b> to check
              for this return value.
*/
+(double) timeInSeconds; 

/*!
  @method time
  @result Returns a double.
  @discussion Returns the receiver's notion of the current time in
              beats.
*/
-(double) timeInBeats; 

/*!
  @method emptyQueue
  @result Returns an id.
  @discussion Removes all message requests from the receiver's message request
              queue and returns the receiver.    Doesn't send any of the
              messages.
*/
- emptyQueue; 

/*!
  @method isCurrentConductor
  @result Returns a BOOL.
  @discussion Returns <b>YES</b> if the receiver is currently sending a message
              from its message request queue.
*/
-(BOOL) isCurrentConductor;

/*!
  @method afterPerformanceSel:to:argCount:
  @param  aSelector is a SEL.
  @param  toObject is an id.
  @param  argCount,... is an int.
  @result Returns a MKMsgStruct *.
  @discussion Enqueues a request for <i>aSelector</i> to be sent to
              <i>toObject</i> immediately after the current (or next) performance
              ends.  <i>argCount</i> specifies the number of four-byte arguments
              to <i>aSelector</i> followed by the arguments themselves, separated
              by commas (two arguments, maximum).  You can enqueue as many of
              these requests as you want; they're sent in the order that they were
              enqueued.  Returns a pointer to a <i>message request structure that
              can be passed to</i><b> a C function such as MKCancelMsgRequest()</b>.
*/
+(MKMsgStruct *) afterPerformanceSel:(SEL) aSelector to: toObject argCount:(int) argCount, ...; 

/*!
  @method beforePerformanceSel:to:argCount:
  @param  aSelector is a SEL.
  @param  toObject is an id.
  @param  argCount,... is an int.
  @result Returns a MKMsgStruct *.
  @discussion Enqueues a request for <i>aSelector</i> to be sent to
              <i>toObject</i> at the beginning of the next performance. 
              <i>argCount</i> specifies the number of four-byte arguments to
              <i>aSelector</i> followed by the arguments themselves, separated by
              commas (two arguments, maximum).  You can enqueue as many of these
              requests as you want; they're sent in the order that they were
              enqueued.  Returns a pointer to a <i>message request structure that
              can be passed to</i><b> a C function such as MKCancelMsgRequest()</b>.
*/
+(MKMsgStruct *) beforePerformanceSel:(SEL) aSelector to: toObject argCount:(int) argCount, ...; 

/*!
  @method setDelegate:
  @param  delegate is an id.
  @result Returns an id.
  @discussion Sets the receiver's delegate object to <i>delegate</i> and returns
              the receiver.  The delegate is sent <b>hasPaused:</b> and
              <b>hasResumed:</b> as the receiver is paused and resumed,
              respectively. 
*/
-(void) setDelegate:(id) object;

/*!
  @method delegate
  @result Returns an id.
  @discussion Returns the receiver's delegate object, as set through the
              <b>setDelegate:</b> method.
*/
- delegate;

/*!
  @method setDelegate:
  @param  delegate is an id.
  @result Returns an id.
  @discussion Sets the receiver's delegate object to <i>delegate</i> and returns
              the receiver.  The delegate is sent <b>hasPaused:</b> and
              <b>hasResumed:</b> as the receiver is paused and resumed,
              respectively. 
*/
+(void) setDelegate: object;

/*!
  @method delegate
  @result Returns an id.
  @discussion Returns the receiver's delegate object, as set through the
              <b>setDelegate:</b> method.
*/
+ delegate;

/*!
  @method activePerformers
  @result Returns an id.
  @discussion Returns a List of currently active Performers that are assigned to
              this MKConductor.  The NSMutableArray is <i>not</i> copied and
              should not be freed or altered.
*/
- activePerformers;

-(void) encodeWithCoder:(NSCoder *) aCoder;
-(id) initWithCoder:(NSCoder *) aDecoder;
- awakeAfterUsingCoder:(NSCoder *) aDecoder;

/*!
  @method setMTCSynch:
  @param  aMidiObj is an id.
  @result Returns an id.
  @discussion Sets the MKConductor to synchronize to MIDI time code coming in on
              the specified MIDI object.  Keep in mind that only one MKConductor
              at a time may have an MTCSynch object.   Unclocked performances
              involving MIDI time code conductors are not
	      supported. Hence, <b>setMTCSynch:</b> sends
	      <tt>[MKConductor setClocked:YES];</tt>.  For
              details, see 
<a href=http://www.musickit.org/MusicKitConcepts/miditimecode.html>
Appendix B. entitled MIDI Time Code in the MusicKit
</a> mentioned above.
*/
- setMTCSynch:aMidiObj;

/*!
  @method MTCSynch
  @result Returns an id.
  @discussion Returns the MKMidi object previously set with <b>setMTCSynch:</b>, or
              <b>nil</b> if none.  Keep in mind that only one MKConductor at a
              time may have an MTCSynch object.
*/
- MTCSynch;

/*!
  @method clockTime
  @result Returns a double.
  @discussion A convenience method.  Returns the current clock time for the
              object.  If the object is synchronizing to MIDI time code, the value
              returned is the current MIDI time code time, the same value returned
              by MKMidi's <b>time</b> method.   If the object is not synchronizing
              to MIDI time code, the value returend is the same value as the value
              returned by  <tt>[[MKConductor clockConductor] time]</tt>.
*/
-(double) clockTime;

/* Obsolete methods */
+ new; 
-(double) predictTime:(double)beatTime; 

@end

@interface MKConductor(SeparateThread)  <SndDelegateMessagePassing>


/*!
  @method useSeparateThread:
  @param  yesOrNo is a BOOL.
  @result Returns an id.
  @discussion If invoked with an argument of YES, all following performances will
              be run in a separate Mach thread.  Some restrictions apply to
              separate-threaded performances as follows:  You may not do any
              drawing or appkit calls from the separate thread.  If you need to
              send a message to the appkit, use <b>+sendMsgToApplicationThreadSel:
               to:argCount:</b>.  
              
              Default is NO.  You should not send this message if any MKMidi objects are open (or running or stopped. ) 
               
*/
+ useSeparateThread:(BOOL) yesOrNo;

/*!
    @function separateThreaded
    @discussion Returns YES if the MKConductor is separate threaded, NO if it runs in the application thread.
*/
+ (BOOL) separateThreaded;

/*!
    @function separateThreadedAndInMusicKitThread
    @discussion Returns YES if the MKConductor is separate threaded and the calling code is running
        in the separate thread, NO if the code is running in the application thread.
*/
+ (BOOL) separateThreadedAndInMusicKitThread;

/*!
  @method lockPerformance
  @result Returns an id.
  @discussion In a separate-threaded performance, this method gets the MusicKit
              lock, then sends <b>[MKConductor adjustTime]</b>.
              <b>lockPerformance</b> may be called multiple times -- e.g. if you
              lock twice you must unlock twice to give up the lock.  In a
              performance that is not separate-threaded, this method is the same
              as <b>+adjustTime</b>. 
               
              <b>lockPerformanceNoBlock</b>
              <b>+ </b>(BOOL)<b>lockPerformanceNoBlock</b>
              
              Same as lockPerformance but does not wait and returns NO if the lock is  unavailable.  If the lock is successful, sends <b>[MKConductor adjustTime]</b> and returns YES. You rarely use this method.  It is provided for cases where you would prefer to give up than to wait (e.g. when simultaneously doing graphic animation.)
*/
+ lockPerformance;

/*!
  @method unlockPerformance
  @result Returns an id.
  @discussion Undoes lockPerformance.  In a separate-threaded performace, sends
              <b>[MKOrchestra flushTimedMessages]</b> and then gives up the
              MusicKit lock.  In a performance that is not separate-threaded, this
              method is the same as MKOrchestra's <b>flushTimedMessages</b>,
              except that the flush is done only when the last recursive lock is
              given up (See MKOrchestra.h.)
*/
+ unlockPerformance;

/*!
  @method lockPerformanceNoBlock
  @result Returns a BOOL.
  @discussion Same as lockPerformance but does not wait and returns NO if the lock
              is  unavailable.  If the lock is successful, sends <b>[MKConductor
              adjustTime]</b> and returns YES. You rarely use this method.  It is
              provided for cases where you would prefer to give up than to wait
              (e.g. when simultaneously doing graphic animation.)
*/
+ (BOOL) lockPerformanceNoBlock;

/*!
  @method setThreadPriority:
  @param  priorityFactor is a float.
  @result Returns an id.
  @discussion This method sets the thread priority of the following and all
              subsequent performances.  The priority change takes effect when the
              <b>startPerformance</b> method is invoked and is set back to its
              original value in the <b>finishPerformance</b> method.  In a
              separate-threaded performance, the thread that is affected is the
              performance thread.  In the case of a performance that is not
              separate-threaded, the thread affected is the one that invoked the
              <b>startPerformance</b> method.
              
              Priority is specified as a "priorityFactor" between
              0.0 and 1.0.  1.0 corresponds to the maximum priority of a user
              process, 0.0 corresponds to the base priority. The default value is
              0.0.
               
              In addition, if priorityFactor is greater than 0, the
              MusicKit uses Mach's "fixed priority thread scheduling policy". 
              (See the Mach documentation for details on thread scheduling
              policies. )  This scheduling policy is more advantageous for
              real-time processes than  the ordinary time sharing policy.
              
*/
+ setThreadPriority:(float) priorityFactor;

/*!
  @method performanceThread
  @result Returns an NSThread..
  @discussion In a separate-threaded MusicKit performance, returns the NSThread
              used in that performance.  When the thread has exited, returns
              nil. 
*/
+ (NSThread *) performanceThread;

/*!              
  @method sendMsgToApplicationThreadSel:to:argCount:
  @result returns an id.
  @param  aSelector is a SEL.
  @param  toObject is an id.
  @param  argCount is an integer.
  @param  variable arguments.
  @discussion If called from the MusicKit thread, sends an Objective-C
              message from the MusicKit thread to the Application's
              main thread.  This is the only safe way to invoke the
              Application Kit from within the MusicKit's thread.  The
              message will be run in the application as soon as the
              Application event loop threshold is NX_BASETHRESHOLD. To
              increase the priority of MusicKit-sent messages, use
              <b>+setInterThreadThreshold:</b>.  If called from the
              Application Kit thread, or there is no separate-threaded
              performance going on, this is the same as sending
              aSelector directly to toObject.
*/
+ sendMsgToApplicationThreadSel:(SEL) aSelector to:(id) toObject argCount:(int)argCount, ...;

/*!
  @method detachDelegateMessageThread
  @result
  @discussion Called by +initialize to detach a thread to handle messaging between
              any background thread and the application thread. It is imperative that
              +initialize is called from the application thread. In effect, this means
              that the very first use of [MKConductor ...] must be done in the
              application thread.
*/
+ (void)detachDelegateMessageThread;

/*!              
  @method sendMessageInMainThreadToTarget:sel:arg1:arg2:count:
  @result none
  @param  target is an id.
  @param  aSelector is a SEL.
  @param  arg1 is any 4-byte argument.
  @param  arg2 is any 4-byte argument.
  @param  count is an integer.
  @discussion This is the back end to sendMsgToApplicationThreadSel, above.
              It relies on the delegate message thread having been set up
              which is done from +initialize.
*/
+ (void) sendMessageInMainThreadToTarget:(id)target 
                                     sel:(SEL)aSelecto
                                    arg1:(id)arg1
                                    arg2:(id)arg2
                                   count:(int)count;

/*!
  @method setInterThreadThreshold:
  @param  newThreshold is an NSString.
  @result Returns an id.
  @discussion Resets the threshold used for interthread
              communication.  This message may only be sent from the Application
              thread.  Otherwise, it is ignored.
*/
+ setInterThreadThreshold:(NSString *) newThreshold;

/*!
  @method _sendDelegateInvocation:
  @param  mesg is an NSInvocation, but cast as an unsigned long so the runtime does
          not interpret it as an object, and mangle it (yes the casting has an
          effect at runtime in this situation!).
  @result void.
  @discussion This is the method called in the application thread to actually deliver
              the message sent through form the background thread (eg background
              MKConductor thread).
*/
+ (void) _sendDelegateInvocation:(in unsigned long) mesg;

@end

#import "MKConductorDelegate.h"

#ifdef __cplusplus
}
#endif

#endif
