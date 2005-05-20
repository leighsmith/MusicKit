/*
  $Id$
  Defined In: The MusicKit

  Description:
    This is the header for the MusicKit scheduler. See documentation below for details.

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2005 The MusicKit Project.
*/

#import <Foundation/Foundation.h>

@class MKMidi;
@class MKConductor;

/*!
  @class MKConductor
  @brief The MKConductor class defines the mechanism that controls the timing of a MusicKit performance. 
 
A MKConductor's most important tasks are
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

<ul>
<li> <b>MKNewMsgRequest()</b> creates and returns a new message
request structure.

<li> <b>MKScheduleMsgRequest()</b> places a previously created
message request (structure) in a specific MKConductor's message
request queue.

<li> <b>MKRepositionMsgRequest()</b> repositions a message request
within a MKConductor's queue.

<li> <b>MKCancelMsgRequest()</b> removes a message request.

<li> <b>MKRescheduleMsgRequest()</b> is a convenience function that
cancels a request and then creates a new one.
</ul>

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
<b>setFinishWhenEmpty:NO</b> to the MKConductor class.

You can pause and resume an entire performance through methods sent to
the MKConductor class:

<ul>
<li> <b>pausePerformance</b> causes all MKConductor instances to
stop processing their message request queues.

<li> <b>resumePerformance</b> resumes a paused performance.  
</ul>

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
<i>Time Map Protocol</i>. The <i>Tempo Protocol</i> consists of the
following two methods (you may use either):

<ul>
<li> <b>setTempo:</b> sets the rate as beats per minute.
<li> <b>setBeatSize:</b> sets the size of an individual beat, in seconds. 
</ul>
 
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
<b>[MKConductor unlockPerformance]</b>.  You should send these
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

  @see MKPerformer, MKOrchestra, MKMidi
*/
#ifndef __MK_Conductor_H___
#define __MK_Conductor_H___

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSThread.h>
#import <SndKit/SndKit.h>

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
    BOOL _retainArg1;
    BOOL _retainArg2;
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
/*!
  @brief Set and get Music Kit time values

  <b>MKGetTime()</b> returns the current time, in seconds, during a Music
  Kit performance.   In a conducted performance (the norm), this is the
  same as [MKConductor time]. 
   
   <b>MKSetDeltaT()</b> sets a performance's delta time in seconds.  The
  delta time value is used in one of two ways, depending on the delta time
  "mode", which is set with <b>MKSetDeltaTMode()</b>.  In
  MK_DELTAT_DEVICE_LAG mode, deltaT is added into the timestamps of DSP
  and MIDI messages, thus imposing a time lag between the Music Kit and
  these devices. If, on the other hand, the delta time mode is
  MK_DELTAT_SCHEDULER_ADVANCE, then deltaT is the amount by which the
  Music Kit MKConductor attempts to run ahead of the devices.  In either
  case, the lag is sometimes necessary to allow the Music Kit sufficient
  compute time while maintaining rhythmic integrity.  Effective delta time
  values can be quite small; for an application that requires real-time
  response, a delta time of as much as 10 milliseconds (0.01 seconds) is
  tolerable.  Delta time only affects devices that are timed.  In
  addition, in order for the delta time value to be valid, the performance
  and the devices must be started at (virtually) the same time.  That is,
  send <b>[orchestra run]</b> and <b>[midi run]</b> immediately before
  sending <b>[MKConductor startPerformance]</b>;
   
   <b>MKGetDeltaT()</b> returns the delta time value, in seconds. The
  meaning of delta time depends on whether the performance is clocked or
  unclocked.  In a clocked performance, the MKConductor tries to stay
  <i>approximately</i> delta time seconds ahead of the devices (e.g. DSP).
  In an unclocked performance, MKConductor tries to stay <i>at least</i>
  delta time seconds ahead of the devices. Delta time has an effect only
  if the device is in timed mode.
   
   <b>MKGetDeltaTTime()</b> returns the sum of the values returned by
  <b>MKGetTime()</b> and <b>MKGetDeltaT()</b>.  
   
   <b>MKSetTime()</b> and <b>MKFinishPerformance()</b> are provided to
  set the performance time and to end a performance, respectively, <i>but
  only in the case of a performance that doesn't use the MKConductor
  class.</i>  <i></i> During a conducted performance, <b>MKSetTime()</b>
  has no effect and <b>MKFinishPerformance()</b> is the same as sending
  <b>finishPerformance</b> to the MKConductor class.    Precisely,
  <b>MKFinishPerformance()</b> his the effect of evaluating the
  MKConductor's "after performance" queue of messages, which in turn tells
  the Performers and Instruments that the performance is finished. 
     
   <b>MKSetLowDeltaTThreshold()</b> and <b>MKSetHighDeltaTThreshold()</b> controls the high and low watermark for the delta time notification mechanism. For example, to receive a message when the MKConductor has fallen behind such that the effective delta time is less than 1/4 of the value of MKGetDeltaT(), you'd call <b>MKSetLowDeltaTThreshold(.25);</b>  Similarly, to receive a message when the MKConductor has recovered such that the effective delta time is more than 3/4 of the value of <b>MKGetDeltaT()</b>, you'd call <b>MKSetHighDeltaTThreshold(.75);  </b>This mechanism allows you to receive a warning when the MKConductor is about to fall out of real time, due to heavy computation.   For example, you might want to automatically reduce the tempo in this case.  The notification itself is sent to the MKConductor class' delegate object.  See MKConductor.h for further details.  
   
   <b>MKSetDeltaTMode();</b>  Sets the delta time mode to one of
  MK_DELTAT_DEVICE_LAG or MK_DELTAT_SCHEDULER_ADVANCE .    The default is
  MK_DELTAT_DEVICE_LAG.
   
   <b>MKGetDeltaTMode();</b>  Returns the delta time mode.
  @param  val is a double.
  @return Returns a double.
*/
extern double MKGetTime(void);           /* Returns the time in seconds. */

/*!
  @brief Set and get Music Kit time values

  <b>MKGetTime()</b> returns the current time, in seconds, during a Music
  Kit performance.   In a conducted performance (the norm), this is the
  same as [MKConductor time]. 
   
   <b>MKSetDeltaT()</b> sets a performance's delta time in seconds.  The
  delta time value is used in one of two ways, depending on the delta time
  "mode", which is set with <b>MKSetDeltaTMode()</b>.  In
  MK_DELTAT_DEVICE_LAG mode, deltaT is added into the timestamps of DSP
  and MIDI messages, thus imposing a time lag between the Music Kit and
  these devices. If, on the other hand, the delta time mode is
  MK_DELTAT_SCHEDULER_ADVANCE, then deltaT is the amount by which the
  Music Kit MKConductor attempts to run ahead of the devices.  In either
  case, the lag is sometimes necessary to allow the Music Kit sufficient
  compute time while maintaining rhythmic integrity.  Effective delta time
  values can be quite small; for an application that requires real-time
  response, a delta time of as much as 10 milliseconds (0.01 seconds) is
  tolerable.  Delta time only affects devices that are timed.  In
  addition, in order for the delta time value to be valid, the performance
  and the devices must be started at (virtually) the same time.  That is,
  send <b>[orchestra run]</b> and <b>[midi run]</b> immediately before
  sending <b>[MKConductor startPerformance]</b>;
   
   <b>MKGetDeltaT()</b> returns the delta time value, in seconds. The
  meaning of delta time depends on whether the performance is clocked or
  unclocked.  In a clocked performance, the MKConductor tries to stay
  <i>approximately</i> delta time seconds ahead of the devices (e.g. DSP).
  In an unclocked performance, MKConductor tries to stay <i>at least</i>
  delta time seconds ahead of the devices. Delta time has an effect only
  if the device is in timed mode.
   
   <b>MKGetDeltaTTime()</b> returns the sum of the values returned by
  <b>MKGetTime()</b> and <b>MKGetDeltaT()</b>.  
   
   <b>MKSetTime()</b> and <b>MKFinishPerformance()</b> are provided to
  set the performance time and to end a performance, respectively, <i>but
  only in the case of a performance that doesn't use the MKConductor
  class.</i>  <i></i> During a conducted performance, <b>MKSetTime()</b>
  has no effect and <b>MKFinishPerformance()</b> is the same as sending
  <b>finishPerformance</b> to the MKConductor class.    Precisely,
  <b>MKFinishPerformance()</b> his the effect of evaluating the
  MKConductor's "after performance" queue of messages, which in turn tells
  the Performers and Instruments that the performance is finished. 
     
   <b>MKSetLowDeltaTThreshold()</b> and <b>MKSetHighDeltaTThreshold()</b> controls the high and low watermark for the delta time notification mechanism. For example, to receive a message when the MKConductor has fallen behind such that the effective delta time is less than 1/4 of the value of MKGetDeltaT(), you'd call <b>MKSetLowDeltaTThreshold(.25);</b>  Similarly, to receive a message when the MKConductor has recovered such that the effective delta time is more than 3/4 of the value of <b>MKGetDeltaT()</b>, you'd call <b>MKSetHighDeltaTThreshold(.75);  </b>This mechanism allows you to receive a warning when the MKConductor is about to fall out of real time, due to heavy computation.   For example, you might want to automatically reduce the tempo in this case.  The notification itself is sent to the MKConductor class' delegate object.  See MKConductor.h for further details.  
   
   <b>MKSetDeltaTMode();</b>  Sets the delta time mode to one of
  MK_DELTAT_DEVICE_LAG or MK_DELTAT_SCHEDULER_ADVANCE .    The default is
  MK_DELTAT_DEVICE_LAG.
   
   <b>MKGetDeltaTMode();</b>  Returns the delta time mode.
  @param  val is a double.
  @return Returns a double.
*/
extern double MKGetDeltaT(void);         /* Returns deltaT, in seconds. */

/*!
  @brief Set and get Music Kit time values

  <b>MKGetTime()</b> returns the current time, in seconds, during a Music
  Kit performance.   In a conducted performance (the norm), this is the
  same as [MKConductor time]. 
   
   <b>MKSetDeltaT()</b> sets a performance's delta time in seconds.  The
  delta time value is used in one of two ways, depending on the delta time
  "mode", which is set with <b>MKSetDeltaTMode()</b>.  In
  MK_DELTAT_DEVICE_LAG mode, deltaT is added into the timestamps of DSP
  and MIDI messages, thus imposing a time lag between the Music Kit and
  these devices. If, on the other hand, the delta time mode is
  MK_DELTAT_SCHEDULER_ADVANCE, then deltaT is the amount by which the
  Music Kit MKConductor attempts to run ahead of the devices.  In either
  case, the lag is sometimes necessary to allow the Music Kit sufficient
  compute time while maintaining rhythmic integrity.  Effective delta time
  values can be quite small; for an application that requires real-time
  response, a delta time of as much as 10 milliseconds (0.01 seconds) is
  tolerable.  Delta time only affects devices that are timed.  In
  addition, in order for the delta time value to be valid, the performance
  and the devices must be started at (virtually) the same time.  That is,
  send <b>[orchestra run]</b> and <b>[midi run]</b> immediately before
  sending <b>[MKConductor startPerformance]</b>;
   
   <b>MKGetDeltaT()</b> returns the delta time value, in seconds. The
  meaning of delta time depends on whether the performance is clocked or
  unclocked.  In a clocked performance, the MKConductor tries to stay
  <i>approximately</i> delta time seconds ahead of the devices (e.g. DSP).
  In an unclocked performance, MKConductor tries to stay <i>at least</i>
  delta time seconds ahead of the devices. Delta time has an effect only
  if the device is in timed mode.
   
   <b>MKGetDeltaTTime()</b> returns the sum of the values returned by
  <b>MKGetTime()</b> and <b>MKGetDeltaT()</b>.  
   
   <b>MKSetTime()</b> and <b>MKFinishPerformance()</b> are provided to
  set the performance time and to end a performance, respectively, <i>but
  only in the case of a performance that doesn't use the MKConductor
  class.</i>  <i></i> During a conducted performance, <b>MKSetTime()</b>
  has no effect and <b>MKFinishPerformance()</b> is the same as sending
  <b>finishPerformance</b> to the MKConductor class.    Precisely,
  <b>MKFinishPerformance()</b> his the effect of evaluating the
  MKConductor's "after performance" queue of messages, which in turn tells
  the Performers and Instruments that the performance is finished. 
     
   <b>MKSetLowDeltaTThreshold()</b> and <b>MKSetHighDeltaTThreshold()</b> controls the high and low watermark for the delta time notification mechanism. For example, to receive a message when the MKConductor has fallen behind such that the effective delta time is less than 1/4 of the value of MKGetDeltaT(), you'd call <b>MKSetLowDeltaTThreshold(.25);</b>  Similarly, to receive a message when the MKConductor has recovered such that the effective delta time is more than 3/4 of the value of <b>MKGetDeltaT()</b>, you'd call <b>MKSetHighDeltaTThreshold(.75);  </b>This mechanism allows you to receive a warning when the MKConductor is about to fall out of real time, due to heavy computation.   For example, you might want to automatically reduce the tempo in this case.  The notification itself is sent to the MKConductor class' delegate object.  See MKConductor.h for further details.  
   
   <b>MKSetDeltaTMode();</b>  Sets the delta time mode to one of
  MK_DELTAT_DEVICE_LAG or MK_DELTAT_SCHEDULER_ADVANCE .    The default is
  MK_DELTAT_DEVICE_LAG.
   
   <b>MKGetDeltaTMode();</b>  Returns the delta time mode.
  @param  val is a double.
  @return Returns a double.
*/
extern void MKSetDeltaT(double val);     /* Sets deltaT, in seconds. */

/*!
  @brief Set and get Music Kit time values

  <b>MKGetTime()</b> returns the current time, in seconds, during a Music
  Kit performance.   In a conducted performance (the norm), this is the
  same as [MKConductor time]. 
   
   <b>MKSetDeltaT()</b> sets a performance's delta time in seconds.  The
  delta time value is used in one of two ways, depending on the delta time
  "mode", which is set with <b>MKSetDeltaTMode()</b>.  In
  MK_DELTAT_DEVICE_LAG mode, deltaT is added into the timestamps of DSP
  and MIDI messages, thus imposing a time lag between the Music Kit and
  these devices. If, on the other hand, the delta time mode is
  MK_DELTAT_SCHEDULER_ADVANCE, then deltaT is the amount by which the
  Music Kit MKConductor attempts to run ahead of the devices.  In either
  case, the lag is sometimes necessary to allow the Music Kit sufficient
  compute time while maintaining rhythmic integrity.  Effective delta time
  values can be quite small; for an application that requires real-time
  response, a delta time of as much as 10 milliseconds (0.01 seconds) is
  tolerable.  Delta time only affects devices that are timed.  In
  addition, in order for the delta time value to be valid, the performance
  and the devices must be started at (virtually) the same time.  That is,
  send <b>[orchestra run]</b> and <b>[midi run]</b> immediately before
  sending <b>[MKConductor startPerformance]</b>;
   
   <b>MKGetDeltaT()</b> returns the delta time value, in seconds. The
  meaning of delta time depends on whether the performance is clocked or
  unclocked.  In a clocked performance, the MKConductor tries to stay
  <i>approximately</i> delta time seconds ahead of the devices (e.g. DSP).
  In an unclocked performance, MKConductor tries to stay <i>at least</i>
  delta time seconds ahead of the devices. Delta time has an effect only
  if the device is in timed mode.
   
   <b>MKGetDeltaTTime()</b> returns the sum of the values returned by
  <b>MKGetTime()</b> and <b>MKGetDeltaT()</b>.  
   
   <b>MKSetTime()</b> and <b>MKFinishPerformance()</b> are provided to
  set the performance time and to end a performance, respectively, <i>but
  only in the case of a performance that doesn't use the MKConductor
  class.</i>  <i></i> During a conducted performance, <b>MKSetTime()</b>
  has no effect and <b>MKFinishPerformance()</b> is the same as sending
  <b>finishPerformance</b> to the MKConductor class.    Precisely,
  <b>MKFinishPerformance()</b> his the effect of evaluating the
  MKConductor's "after performance" queue of messages, which in turn tells
  the Performers and Instruments that the performance is finished. 
     
   <b>MKSetLowDeltaTThreshold()</b> and <b>MKSetHighDeltaTThreshold()</b> controls the high and low watermark for the delta time notification mechanism. For example, to receive a message when the MKConductor has fallen behind such that the effective delta time is less than 1/4 of the value of MKGetDeltaT(), you'd call <b>MKSetLowDeltaTThreshold(.25);</b>  Similarly, to receive a message when the MKConductor has recovered such that the effective delta time is more than 3/4 of the value of <b>MKGetDeltaT()</b>, you'd call <b>MKSetHighDeltaTThreshold(.75);  </b>This mechanism allows you to receive a warning when the MKConductor is about to fall out of real time, due to heavy computation.   For example, you might want to automatically reduce the tempo in this case.  The notification itself is sent to the MKConductor class' delegate object.  See MKConductor.h for further details.  
   
   <b>MKSetDeltaTMode();</b>  Sets the delta time mode to one of
  MK_DELTAT_DEVICE_LAG or MK_DELTAT_SCHEDULER_ADVANCE .    The default is
  MK_DELTAT_DEVICE_LAG.
   
   <b>MKGetDeltaTMode();</b>  Returns the delta time mode.
  @param  newTime is a double.
  @return Returns a double.
*/
extern double MKGetDeltaTTime(void);     /* Returns deltaT + time, in seconds. */

/* The following modes determine how deltaT is interpreted. */
#define MK_DELTAT_DEVICE_LAG 0
#define MK_DELTAT_SCHEDULER_ADVANCE 1
 
/*!
  @brief Set and get Music Kit time values

  <b>MKGetTime()</b> returns the current time, in seconds, during a Music
  Kit performance.   In a conducted performance (the norm), this is the
  same as [MKConductor time]. 
   
   <b>MKSetDeltaT()</b> sets a performance's delta time in seconds.  The
  delta time value is used in one of two ways, depending on the delta time
  "mode", which is set with <b>MKSetDeltaTMode()</b>.  In
  MK_DELTAT_DEVICE_LAG mode, deltaT is added into the timestamps of DSP
  and MIDI messages, thus imposing a time lag between the Music Kit and
  these devices. If, on the other hand, the delta time mode is
  MK_DELTAT_SCHEDULER_ADVANCE, then deltaT is the amount by which the
  Music Kit MKConductor attempts to run ahead of the devices.  In either
  case, the lag is sometimes necessary to allow the Music Kit sufficient
  compute time while maintaining rhythmic integrity.  Effective delta time
  values can be quite small; for an application that requires real-time
  response, a delta time of as much as 10 milliseconds (0.01 seconds) is
  tolerable.  Delta time only affects devices that are timed.  In
  addition, in order for the delta time value to be valid, the performance
  and the devices must be started at (virtually) the same time.  That is,
  send <b>[orchestra run]</b> and <b>[midi run]</b> immediately before
  sending <b>[MKConductor startPerformance]</b>;
   
   <b>MKGetDeltaT()</b> returns the delta time value, in seconds. The
  meaning of delta time depends on whether the performance is clocked or
  unclocked.  In a clocked performance, the MKConductor tries to stay
  <i>approximately</i> delta time seconds ahead of the devices (e.g. DSP).
  In an unclocked performance, MKConductor tries to stay <i>at least</i>
  delta time seconds ahead of the devices. Delta time has an effect only
  if the device is in timed mode.
   
   <b>MKGetDeltaTTime()</b> returns the sum of the values returned by
  <b>MKGetTime()</b> and <b>MKGetDeltaT()</b>.  
   
   <b>MKSetTime()</b> and <b>MKFinishPerformance()</b> are provided to
  set the performance time and to end a performance, respectively, <i>but
  only in the case of a performance that doesn't use the MKConductor
  class.</i>  <i></i> During a conducted performance, <b>MKSetTime()</b>
  has no effect and <b>MKFinishPerformance()</b> is the same as sending
  <b>finishPerformance</b> to the MKConductor class.    Precisely,
  <b>MKFinishPerformance()</b> his the effect of evaluating the
  MKConductor's "after performance" queue of messages, which in turn tells
  the Performers and Instruments that the performance is finished. 
     
   <b>MKSetLowDeltaTThreshold()</b> and <b>MKSetHighDeltaTThreshold()</b> controls the high and low watermark for the delta time notification mechanism. For example, to receive a message when the MKConductor has fallen behind such that the effective delta time is less than 1/4 of the value of MKGetDeltaT(), you'd call <b>MKSetLowDeltaTThreshold(.25);</b>  Similarly, to receive a message when the MKConductor has recovered such that the effective delta time is more than 3/4 of the value of <b>MKGetDeltaT()</b>, you'd call <b>MKSetHighDeltaTThreshold(.75);  </b>This mechanism allows you to receive a warning when the MKConductor is about to fall out of real time, due to heavy computation.   For example, you might want to automatically reduce the tempo in this case.  The notification itself is sent to the MKConductor class' delegate object.  See MKConductor.h for further details.  
   
   <b>MKSetDeltaTMode();</b>  Sets the delta time mode to one of
  MK_DELTAT_DEVICE_LAG or MK_DELTAT_SCHEDULER_ADVANCE .    The default is
  MK_DELTAT_DEVICE_LAG.
   
   <b>MKGetDeltaTMode();</b>  Returns the delta time mode.
  @param  newMode is an int.
  @return Returns an extern.
*/
extern void MKSetDeltaTMode(int newMode);

/*!
  @brief Set and get Music Kit time values

  <b>MKGetTime()</b> returns the current time, in seconds, during a Music
  Kit performance.   In a conducted performance (the norm), this is the
  same as [MKConductor time]. 
   
   <b>MKSetDeltaT()</b> sets a performance's delta time in seconds.  The
  delta time value is used in one of two ways, depending on the delta time
  "mode", which is set with <b>MKSetDeltaTMode()</b>.  In
  MK_DELTAT_DEVICE_LAG mode, deltaT is added into the timestamps of DSP
  and MIDI messages, thus imposing a time lag between the Music Kit and
  these devices. If, on the other hand, the delta time mode is
  MK_DELTAT_SCHEDULER_ADVANCE, then deltaT is the amount by which the
  Music Kit MKConductor attempts to run ahead of the devices.  In either
  case, the lag is sometimes necessary to allow the Music Kit sufficient
  compute time while maintaining rhythmic integrity.  Effective delta time
  values can be quite small; for an application that requires real-time
  response, a delta time of as much as 10 milliseconds (0.01 seconds) is
  tolerable.  Delta time only affects devices that are timed.  In
  addition, in order for the delta time value to be valid, the performance
  and the devices must be started at (virtually) the same time.  That is,
  send <b>[orchestra run]</b> and <b>[midi run]</b> immediately before
  sending <b>[MKConductor startPerformance]</b>;
   
   <b>MKGetDeltaT()</b> returns the delta time value, in seconds. The
  meaning of delta time depends on whether the performance is clocked or
  unclocked.  In a clocked performance, the MKConductor tries to stay
  <i>approximately</i> delta time seconds ahead of the devices (e.g. DSP).
  In an unclocked performance, MKConductor tries to stay <i>at least</i>
  delta time seconds ahead of the devices. Delta time has an effect only
  if the device is in timed mode.
   
   <b>MKGetDeltaTTime()</b> returns the sum of the values returned by
  <b>MKGetTime()</b> and <b>MKGetDeltaT()</b>.  
   
   <b>MKSetTime()</b> and <b>MKFinishPerformance()</b> are provided to
  set the performance time and to end a performance, respectively, <i>but
  only in the case of a performance that doesn't use the MKConductor
  class.</i>  <i></i> During a conducted performance, <b>MKSetTime()</b>
  has no effect and <b>MKFinishPerformance()</b> is the same as sending
  <b>finishPerformance</b> to the MKConductor class.    Precisely,
  <b>MKFinishPerformance()</b> his the effect of evaluating the
  MKConductor's "after performance" queue of messages, which in turn tells
  the Performers and Instruments that the performance is finished. 
     
   <b>MKSetLowDeltaTThreshold()</b> and <b>MKSetHighDeltaTThreshold()</b> controls the high and low watermark for the delta time notification mechanism. For example, to receive a message when the MKConductor has fallen behind such that the effective delta time is less than 1/4 of the value of MKGetDeltaT(), you'd call <b>MKSetLowDeltaTThreshold(.25);</b>  Similarly, to receive a message when the MKConductor has recovered such that the effective delta time is more than 3/4 of the value of <b>MKGetDeltaT()</b>, you'd call <b>MKSetHighDeltaTThreshold(.75);  </b>This mechanism allows you to receive a warning when the MKConductor is about to fall out of real time, due to heavy computation.   For example, you might want to automatically reduce the tempo in this case.  The notification itself is sent to the MKConductor class' delegate object.  See MKConductor.h for further details.  
   
   <b>MKSetDeltaTMode();</b>  Sets the delta time mode to one of
  MK_DELTAT_DEVICE_LAG or MK_DELTAT_SCHEDULER_ADVANCE .    The default is
  MK_DELTAT_DEVICE_LAG.
   
   <b>MKGetDeltaTMode();</b>  Returns the delta time mode.
  @param   is a void.
  @return Returns an extern.
*/
extern int MKGetDeltaTMode(void);

/*!
  @brief Set and get Music Kit time values

  <b>MKGetTime()</b> returns the current time, in seconds, during a Music
  Kit performance.   In a conducted performance (the norm), this is the
  same as [MKConductor time]. 
   
   <b>MKSetDeltaT()</b> sets a performance's delta time in seconds.  The
  delta time value is used in one of two ways, depending on the delta time
  "mode", which is set with <b>MKSetDeltaTMode()</b>.  In
  MK_DELTAT_DEVICE_LAG mode, deltaT is added into the timestamps of DSP
  and MIDI messages, thus imposing a time lag between the Music Kit and
  these devices. If, on the other hand, the delta time mode is
  MK_DELTAT_SCHEDULER_ADVANCE, then deltaT is the amount by which the
  Music Kit MKConductor attempts to run ahead of the devices.  In either
  case, the lag is sometimes necessary to allow the Music Kit sufficient
  compute time while maintaining rhythmic integrity.  Effective delta time
  values can be quite small; for an application that requires real-time
  response, a delta time of as much as 10 milliseconds (0.01 seconds) is
  tolerable.  Delta time only affects devices that are timed.  In
  addition, in order for the delta time value to be valid, the performance
  and the devices must be started at (virtually) the same time.  That is,
  send <b>[orchestra run]</b> and <b>[midi run]</b> immediately before
  sending <b>[MKConductor startPerformance]</b>;
   
   <b>MKGetDeltaT()</b> returns the delta time value, in seconds. The
  meaning of delta time depends on whether the performance is clocked or
  unclocked.  In a clocked performance, the MKConductor tries to stay
  <i>approximately</i> delta time seconds ahead of the devices (e.g. DSP).
  In an unclocked performance, MKConductor tries to stay <i>at least</i>
  delta time seconds ahead of the devices. Delta time has an effect only
  if the device is in timed mode.
   
   <b>MKGetDeltaTTime()</b> returns the sum of the values returned by
  <b>MKGetTime()</b> and <b>MKGetDeltaT()</b>.  
   
   <b>MKSetTime()</b> and <b>MKFinishPerformance()</b> are provided to
  set the performance time and to end a performance, respectively, <i>but
  only in the case of a performance that doesn't use the MKConductor
  class.</i>  <i></i> During a conducted performance, <b>MKSetTime()</b>
  has no effect and <b>MKFinishPerformance()</b> is the same as sending
  <b>finishPerformance</b> to the MKConductor class.    Precisely,
  <b>MKFinishPerformance()</b> his the effect of evaluating the
  MKConductor's "after performance" queue of messages, which in turn tells
  the Performers and Instruments that the performance is finished. 
     
   <b>MKSetLowDeltaTThreshold()</b> and <b>MKSetHighDeltaTThreshold()</b> controls the high and low watermark for the delta time notification mechanism. For example, to receive a message when the MKConductor has fallen behind such that the effective delta time is less than 1/4 of the value of MKGetDeltaT(), you'd call <b>MKSetLowDeltaTThreshold(.25);</b>  Similarly, to receive a message when the MKConductor has recovered such that the effective delta time is more than 3/4 of the value of <b>MKGetDeltaT()</b>, you'd call <b>MKSetHighDeltaTThreshold(.75);  </b>This mechanism allows you to receive a warning when the MKConductor is about to fall out of real time, due to heavy computation.   For example, you might want to automatically reduce the tempo in this case.  The notification itself is sent to the MKConductor class' delegate object.  See MKConductor.h for further details.  
   
   <b>MKSetDeltaTMode();</b>  Sets the delta time mode to one of
  MK_DELTAT_DEVICE_LAG or MK_DELTAT_SCHEDULER_ADVANCE .    The default is
  MK_DELTAT_DEVICE_LAG.
   
   <b>MKGetDeltaTMode();</b>  Returns the delta time mode.
  @param  newTime is a double.
  @return Returns a double.
*/
extern double MKSetTime(double newTime); /* Rarely used */

/*!
  @brief Create and manipulate MKConductor message requests

  These functions let you enqueue message requests with a MKConductor
  object.  The  MKMsgStruct structure encapulates a message request; it
  consists of a method selector and its arguments, the recipient of the
  message, and the time that the message should be sent.  A selector can
  take a maximum of two 4-byte arguments.  You should never modify the
  fields of a MKMsgStruct structure directly.  
   
   <b>MKNewMsgRequest()</b> creates and returns a new MKMsgStruct. 
  <i>timeOfMsg</i> is the time in beats from the beginning of the
  performance that the message will be sent, <i>whichSelector</i> is the
  selector, <i>destinationObject</i> is the recipient of the message, and
  <i>argCount</i> is the number of arguments to the selector followed by
  the arguments themselves separated by commas.   
   
   After you've created a message request structure, you schedule it
  with a MKConductor by calling<b> MKScheduleMsgRequest()</b><i>.</i>
     
   If you want to move a message request within a MKConductor's queue
  you call the <b>MKRepositionMsgRequest()</b> function.  The specified
  MKMsgStruct is moved to the time given by <i>newTimeOfMsg.</i>  You
  should note that the MKMsgStruct that you pass as the
  <i>aMsgStructPtr</i> argument may be replaced with a new structure
  that's returned by the function<i>.</i>  To make sure you don't keep
  around a pointer to an obsolete struct, call this function as follows:  
     
   <tt>	// Reposition and prime aMsgReq for additional functions calls.</tt>
   <tt>	aMsgReq = MKRepositionMsgRequest(aMsgReq, 3.0);</tt>
     
   <b>MKCancelMsgRequest()</b> cancels the given message request and
  frees the structure pointed to by <i>aMsgStructPtr.   </i>Be sure not to
  cancel an already-canceled request.  To make sure you don't do that, you
  should assign the returned value of the function (NULL) to the value you
  pass.  Example of use:
   
   <tt>	aMsgReq = MKCancelMsgRequest(aMsgReq);</tt>
   <tt>	// aMsgReq is now NULL</tt>
   
   <b>MKRescheduleMsgRequest()</b> is a convenience function that
  cancels the structure pointed to by <i>aMsgStructPtr</i>, and then
  creates and schedules a new request according to the arguments.  The new
  MKMsgStruct is returned.
  @param  timeOfMsg is a double.
  @param  whichSelector is a SEL.
  @param  destinationObject is an id.
  @param  argCount is an int.
  @return Return <i>NULL if argCount</i> is greater than 2.
*/
extern MKMsgStruct 
  *MKNewMsgRequest(double timeOfMsg, SEL whichSelector, id destinationObject, int argCount, ...);

extern MKMsgStruct 
  *MKNewMsgRequestWithObjectArgs(double timeOfMsg, SEL whichSelector, id destinationObject,
		   int argCount, id arg1, BOOL, id arg2, BOOL);

/*!
  @brief Create and manipulate MKConductor message requests

  These functions let you enqueue message requests with a MKConductor
  object.  The  MKMsgStruct structure encapulates a message request; it
  consists of a method selector and its arguments, the recipient of the
  message, and the time that the message should be sent.  A selector can
  take a maximum of two 4-byte arguments.  You should never modify the
  fields of a MKMsgStruct structure directly.  
   
  <b>MKNewMsgRequest()</b> creates and returns a new MKMsgStruct. 
  <i>timeOfMsg</i> is the time in beats from the beginning of the
  performance that the message will be sent, <i>whichSelector</i> is the
  selector, <i>destinationObject</i> is the recipient of the message, and
  <i>argCount</i> is the number of arguments to the selector followed by
  the arguments themselves separated by commas.   
   
   After you've created a message request structure, you schedule it
  with a MKConductor by calling <b>MKScheduleMsgRequest()</b><i>.</i>
     
  @param  aMsgStructPtr is a MKMsgStruct.
  @param  conductor is an id.
*/
extern void 
  MKScheduleMsgRequest(MKMsgStruct *aMsgStructPtr, id conductor);

/*!
  @brief Create and manipulate MKConductor message requests

  These functions let you enqueue message requests with a MKConductor
  object.  The  MKMsgStruct structure encapulates a message request; it
  consists of a method selector and its arguments, the recipient of the
  message, and the time that the message should be sent.  A selector can
  take a maximum of two 4-byte arguments.  You should never modify the
  fields of a MKMsgStruct structure directly.  
   
  <b>MKCancelMsgRequest()</b> cancels the given message request and
  frees the structure pointed to by <i>aMsgStructPtr.   </i>Be sure not to
  cancel an already-canceled request.  To make sure you don't do that, you
  should assign the returned value of the function (NULL) to the value you
  pass.  Example of use:
   
   <tt>	aMsgReq = MKCancelMsgRequest(aMsgReq);</tt>
   <tt>	// aMsgReq is now NULL</tt>
   
  @param  aMsgStructPtr is a MKMsgStruct *.
  @return Returns a MKMsgStruct *.
*/
extern MKMsgStruct *
  MKCancelMsgRequest(MKMsgStruct *aMsgStructPtr);

/*!
  @brief Create and manipulate MKConductor message requests

  These functions let you enqueue message requests with a MKConductor
  object.  The  MKMsgStruct structure encapulates a message request; it
  consists of a method selector and its arguments, the recipient of the
  message, and the time that the message should be sent.  A selector can
  take a maximum of two 4-byte arguments.  You should never modify the
  fields of a MKMsgStruct structure directly.  
   
  <b>MKRescheduleMsgRequest()</b> is a convenience function that
  cancels the structure pointed to by <i>aMsgStructPtr</i>, and then
  creates and schedules a new request according to the arguments.  The new
  MKMsgStruct is returned.
  @param  aMsgStructPtr, is a MKMsgStruct.
  @param  conductor is an id.
  @param  timeOfNewMsg is an id.
  @param  whichSelector is a double.
  @param  destinationObject is a SEL.
  @param  argCount is an int.
  @return Returns a MKMsgStruct *.
*/
extern MKMsgStruct *
  MKRescheduleMsgRequest(MKMsgStruct *aMsgStructPtr, id conductor,
			 double timeOfNewMsg, SEL whichSelector,
			 id destinationObject, int argCount, ...);

extern MKMsgStruct *
  MKRescheduleMsgRequestWithObjectArgs(MKMsgStruct *aMsgStructPtr, id conductor,
			 double timeOfNewMsg, SEL whichSelector,
			 id destinationObject, int argCount,
			 id arg1, BOOL retainArg1,
			 id arg2, BOOL retainArg2);

/*!
  @brief Create and manipulate MKConductor message requests

  These functions let you enqueue message requests with a MKConductor
  object.  The  MKMsgStruct structure encapulates a message request; it
  consists of a method selector and its arguments, the recipient of the
  message, and the time that the message should be sent.  A selector can
  take a maximum of two 4-byte arguments.  You should never modify the
  fields of a MKMsgStruct structure directly.  
   
  If you want to move a message request within a MKConductor's queue
  you call the <b>MKRepositionMsgRequest()</b> function.  The specified
  MKMsgStruct is moved to the time given by <i>newTimeOfMsg.</i>  You
  should note that the MKMsgStruct that you pass as the
  <i>aMsgStructPtr</i> argument may be replaced with a new structure
  that's returned by the function<i>.</i>  To make sure you don't keep
  around a pointer to an obsolete struct, call this function as follows:  
     
   <tt>	// Reposition and prime aMsgReq for additional functions calls.</tt>
   <tt>	aMsgReq = MKRepositionMsgRequest(aMsgReq, 3.0);</tt>
     
  @param  aMsgStructPtr is a MKMsgStruct *.
  @param  newTimeOfMsg is a double.
  @return Returns a MKMsgStruct *.
*/
extern MKMsgStruct *
  MKRepositionMsgRequest(MKMsgStruct *aMsgStructPtr, double newTimeOfMsg);

/*!
  @brief Set and get Music Kit time values

  <b>MKGetTime()</b> returns the current time, in seconds, during a Music
  Kit performance.   In a conducted performance (the norm), this is the
  same as [MKConductor time]. 
   
   <b>MKSetDeltaT()</b> sets a performance's delta time in seconds.  The
  delta time value is used in one of two ways, depending on the delta time
  "mode", which is set with <b>MKSetDeltaTMode()</b>.  In
  MK_DELTAT_DEVICE_LAG mode, deltaT is added into the timestamps of DSP
  and MIDI messages, thus imposing a time lag between the Music Kit and
  these devices. If, on the other hand, the delta time mode is
  MK_DELTAT_SCHEDULER_ADVANCE, then deltaT is the amount by which the
  Music Kit MKConductor attempts to run ahead of the devices.  In either
  case, the lag is sometimes necessary to allow the Music Kit sufficient
  compute time while maintaining rhythmic integrity.  Effective delta time
  values can be quite small; for an application that requires real-time
  response, a delta time of as much as 10 milliseconds (0.01 seconds) is
  tolerable.  Delta time only affects devices that are timed.  In
  addition, in order for the delta time value to be valid, the performance
  and the devices must be started at (virtually) the same time.  That is,
  send <b>[orchestra run]</b> and <b>[midi run]</b> immediately before
  sending <b>[MKConductor startPerformance]</b>;
   
   <b>MKGetDeltaT()</b> returns the delta time value, in seconds. The
  meaning of delta time depends on whether the performance is clocked or
  unclocked.  In a clocked performance, the MKConductor tries to stay
  <i>approximately</i> delta time seconds ahead of the devices (e.g. DSP).
  In an unclocked performance, MKConductor tries to stay <i>at least</i>
  delta time seconds ahead of the devices. Delta time has an effect only
  if the device is in timed mode.
   
   <b>MKGetDeltaTTime()</b> returns the sum of the values returned by
  <b>MKGetTime()</b> and <b>MKGetDeltaT()</b>.  
   
   <b>MKSetTime()</b> and <b>MKFinishPerformance()</b> are provided to
  set the performance time and to end a performance, respectively, <i>but
  only in the case of a performance that doesn't use the MKConductor
  class.</i>  <i></i> During a conducted performance, <b>MKSetTime()</b>
  has no effect and <b>MKFinishPerformance()</b> is the same as sending
  <b>finishPerformance</b> to the MKConductor class.    Precisely,
  <b>MKFinishPerformance()</b> his the effect of evaluating the
  MKConductor's "after performance" queue of messages, which in turn tells
  the Performers and Instruments that the performance is finished. 
     
   <b>MKSetLowDeltaTThreshold()</b> and <b>MKSetHighDeltaTThreshold()</b> controls the high and low watermark for the delta time notification mechanism. For example, to receive a message when the MKConductor has fallen behind such that the effective delta time is less than 1/4 of the value of MKGetDeltaT(), you'd call <b>MKSetLowDeltaTThreshold(.25);</b>  Similarly, to receive a message when the MKConductor has recovered such that the effective delta time is more than 3/4 of the value of <b>MKGetDeltaT()</b>, you'd call <b>MKSetHighDeltaTThreshold(.75);  </b>This mechanism allows you to receive a warning when the MKConductor is about to fall out of real time, due to heavy computation.   For example, you might want to automatically reduce the tempo in this case.  The notification itself is sent to the MKConductor class' delegate object.  See MKConductor.h for further details.  
   
   <b>MKSetDeltaTMode();</b>  Sets the delta time mode to one of
  MK_DELTAT_DEVICE_LAG or MK_DELTAT_SCHEDULER_ADVANCE .    The default is
  MK_DELTAT_DEVICE_LAG.
   
   <b>MKGetDeltaTMode();</b>  Returns the delta time mode.
  @param  percentageOfDeltaT is a double.
  @return Returns a void.
*/
extern void MKFinishPerformance(void);

@interface MKConductor: NSObject
{
  /*! @var time Current Time in beats, updated (for all instances) after timed entry fires off. */
    double time;       
  /*! @var nextMsgTime Time, in seconds, when next message is scheduled to be sent by this MKConductor. */
    double nextMsgTime;           // sb: relative to start of performance, I think.
    /* nextMsgTime = (nextbeat - time) * beatSize */
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
 
+ allocWithZone: (NSZone *) zone;

/*!
  @return Returns an id.
  @brief Creates and returns a new MKConductor object with a tempo of 60.0
  beats per minute, allocated from the default zone.

  You must send
  <b>init </b>to the new instance.  If a performance is currently in
  progress, this does nothing and returns <b>nil</b>.
*/
+ alloc;

/*!
  @return Returns an id.
  @brief Initializes a new MKConductor.

  You must send this message after
  using <b>alloc</b> or <b>allocFromZone:</b> to create a
  MKConductor.
*/
- init;

/*!
  @return Returns an id.
  @brief <i>This method is superceded by <b>+lockPerformance </b>and
  <b>+unlockPerformance</b>.</i>  
  
  Updates every MKConductor's notion of time.

  This method
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
  @brief Starts a performance.
  @return Returns an id.
  
  All MKConductor objects begin at the same
  time.  If the performance is clocked and you don't have a running
  NSRunLoop, this does nothing and returns <b>nil</b>.
			  In all other cases, the receiver is returned; however,
  if the performance is unclocked, this method doesn't return until
  the performance is over.
*/
+ startPerformance;

/*!
  @return Returns an MKConductor.
  @brief Returns the defaultConductor.

  
*/
+ (MKConductor *) defaultConductor; 

/*!
  @return Returns a BOOL.
  @brief Returns <b>YES</b> if a performance is currently taking place (even
  if it's paused), otherwise returns <b>NO</b>.

  
*/
+(BOOL) inPerformance; 

/*!
  @return Returns an id.
  @brief Ends the performance.

  All enqueued messages are removed (from
  MKConductor instances' message queues - not from the before- and
  after-performance queues) and the <b>after-performance</b> messages
  are sent<b>. </b>If<b> finishWhenEmpty</b> is <b>YES</b>, this
  message is automatically sent when all message queues are exhausted.
  Returns <b>nil</b>.
*/
+ finishPerformance; 

/*!
  @return Returns an id.
  @brief Pauses the performance.

  The performance is suspended until the
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
  @return Returns a BOOL.
  @brief Returns <b>YES</b> if the performance is paused, otherwise returns
  <b>NO</b>.

  
*/
+ (BOOL) isPaused; 

/*!
  @return Returns an id.
  @brief Resumes a  performance, allowing it to continue from where it was
  paused.

  If the performance is unclocked, return <b>nil</b>,
  otherwise returns the receiver.
*/
+ resumePerformance; 

/*!
  @return Returns an id.
  @brief Returns the MKConductor instance that's currently sending a message,
  or <b>nil</b> if no message is being sent.

  
*/
+ currentConductor; 

/*!
  @return Returns an id.
  @brief Returns the clockConductor.

  
*/
+ clockConductor;

/*!
  @param  yesOrNo is a BOOL.
  @return Returns an id.
  @brief If <i>yesOrNo</i> is <b>YES</b> (the default), the MKConductors
  dispatches each message at the specified time, waiting if necessary.

  
  If <b>NO</b>, messages are sent as quickly as possible.  In an
  unclocked performance, a subsequent startPerformance message doesn't
  return until the performance is over, thus effectively disabling the
  user interface.  Does nothing and returns <b><i>nil</i></b><i></i>
  if a performance is in progress, otherwise returns the
  receiver.<i></i>   Unclocked performances involving MIDI time code
  conductors are not supported.   
*/
+ setClocked: (BOOL) yesOrNo; 

/*!
  @return Returns a BOOL.
  @brief Returns <b>YES</b> if the performance is clocked, <b>NO</b> if it
  isn't.

  By default, a performance is clocked.
*/
+ (BOOL) isClocked; 

/*!
  @param  yesOrNo is a BOOL.
  @return Returns an id.
  @brief If <i>yesOrNo</i> is <b>YES</b> (the default), the performance is
  terminated when all the MKConductors' message queues are empty.

  If
  <b>NO</b>, the performance continues until the
	  <b>finishPerformance</b> message is sent to the MKConductor class.
*/
+ setFinishWhenEmpty: (BOOL) yesOrNo; 

/*!
  @return Returns a BOOL.
  @brief Returns <b>YES</b> if a performance is in progress and all the
  MKConductor instances' message request queues are are empty,
  otherwise returns <b>NO.</b>
*/
+ (BOOL) isEmpty;

/*!
  @return Returns a BOOL.
  @brief Returns <b>YES</b> if the performance will finish when all
  MKConductors' message queues are empty, <b>otherwise returns
  NO</b>.

  
*/
+ (BOOL) finishWhenEmpty;

/*!
  @param  newDeltaT is a double.
  @brief Set the delta time in seconds.

  
  @see <b>MKSetDeltaT()</b>
*/
+ (void) setDeltaT: (double) newDeltaT;

/*!
  @return Returns a double.
  @brief Returns the delta time in seconds.

  
*/
+ (double) deltaT;

/*!
  @return Returns an id.
  @brief Returns a new MKConductor created through <b>[MKConductor new]</b>.

  
*/
- copyWithZone: (NSZone *) zone;

/*!
  @return Returns a BOOL.
  @brief Returns <b>YES</b> if the receiver is paused.

  
*/
- (BOOL) isPaused; 

/*!
  @return Returns an id.
  @brief Pauses the performance of the receiver and sends <b>hasPaused:</b>
  to its delegate.

  The effect is restricted to the present
  performance.  Invoke <b>resume</b> to unpause a MKConductor.  You
  can't pause the clockConductor; returns <b>nil</b> in this case (and
  the delegate message isn't sent).  Otherwise returns the receiver. 
  Note that you can pause a MKConductor object before a performance
  begins.  You cannot pause a MKConductor that is synchronizing to
  MIDI time code.  An attempt to do so is ignored.
*/
- pause; 

/*!
  @param  seconds is a double.
  @return Returns an id.
  @brief A convenience method.

  Pauses the performance of the receiver, sends
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
- pauseFor: (double) seconds;

/*!
  @return Returns an id.
  @brief Resumes the receiver's performance and returns the receiver.

  If the
  receiver isn't currently paused, this has no effect.
*/
- resume; 

/*!
  @param  newBeatSize is a double.
  @return Returns a double.
  @brief Sets the tempo by changing the size of a beat to <i>newBeatSize</i>,
  measured in seconds.

  The default beat size is 1.0 (one second). 
  Attempts to set the tempo of the clockConductor are ignored. 
  Returns the previous beat size.
*/
- (double) setBeatSize: (double) newBeatSize; 

/*!
  @return Returns a double.
  @brief Returns the size of the receiver's beat in seconds.

  
*/
- (double) beatSize; 

/*!
  @param  newTempo is a double.
  @return Returns a double.
  @brief Sets the receiver's tempo to <i>newTempo</i>, measured in beats per
  minute.

  Attempts to set the tempo of the clockConductor are
  ignored.  Returns the previous tempo.
*/
-(double) setTempo: (double) newTempo; 

/*!
  @return Returns a double.
  @brief Returns the receiver's tempo in beats per minute.

  
*/
- (double) tempo; 

/*!
  @brief Sets the receiver's performance time offset to <i>newTimeOffset</i>
  seconds.

  Keep in mind that since the offset is measured in seconds,
  it's not affected by the receiver's tempo.  Attempts to set the
  offset of the clockConductor are ignored. Returns the previous time
  offset.
 @param  newTimeOffset is a double.
 @return Returns a double.
*/
- (double) setTimeOffset: (double) newTimeOffset; 

/*!
  @return Returns a double.
  @brief Returns the receiver's performance time offset in seconds.
*/
- (double) timeOffset; 

/*!
  @brief Places, in the receiver's message request queue, a request for
  <i>aSelector</i> to be sent to <i>toObject</i> at time <i>beats</i>
  beats from the receiver's notion of the current time.

  To ensure
  that the receiver's notion of time is up to date, you should send
  <b>lockPerformance</b> before invoking this method and
  <b>unlockPerformance</b>afterwards.   <i>argCount</i>  specifies the
  number of four-byte arguments to <i>aSelector</i> followed by the
  arguments themselves, seperated by commas (two arguments,
  maximum).
 @param  aSelector is a SEL.
 @param  toObject is an id.
 @param  beats is a double.
 @param  argCount,... is an int counting variable arguments.
 @return Returns an id.
 */
- sel: (SEL) aSelector to: toObject withDelay: (double) beats argCount: (int) argCount, ...;

/*!
  @brief Places, in the receiver's message request queue, a request for
  <i>aSelector</i> to be sent to <i>toObject</i> at time <i>beats</i>
  beats from the receiver's notion of the current time.

  To ensure that the receiver's notion of time is up to date, you should send
  <b>lockPerformance</b> before invoking this method and
  <b>unlockPerformance</b>afterwards.   <i>argCount</i>  specifies the
  number of four-byte arguments to <i>aSelector</i>. If arg1 or arg2 are
  objects, set the retain: argument following them to TRUE to prevent
  the object from any chance of deallocation between this method being
  called, and the message being dispatched.
  @param  aSelector is a SEL.
  @param  toObject is an id.
  @param  beats is a double.
  @param  argCount is an int
  @param  arg1 is an id or any 4-byte data type
  @param  retainArg1 is a BOOL
  @param  arg2 is an id or any 4-byte data type
  @param  retainArg2 is a BOOL
  @return Returns an id.
 */
- (id) sel: (SEL) aSelector
	to: (id) toObject
 withDelay: (double) beats
  argCount: (int) argCount
      arg1: (id) arg1 
    retain: (BOOL) retainArg1
      arg2: (id) arg2 
    retain: (BOOL) retainArg2;

/*!
  @brief Places, in the receiver's message request queue, a request for
  <i>aSelector</i> to be sent to <i>toObject</i> at time <i>time</i>
  beats from the beginning of the receiver's performance.

  <i>argCount</i> specifies the number of four-byte arguments to
  <i>aSelector</i> followed by the arguments themselves, seperated by
  commas (two arguments, maximum). 
 @param  aSelector is a SEL.
 @param  toObject is an id.
 @param  time is a double.
 @param  argCount,... is an int counting variable arguments.
 @return Returns an id.
 */
- sel: (SEL) aSelector to: toObject atTime: (double) time argCount: (int) argCount, ...;

/*!
  @brief Places, in the receiver's message request queue, a request for
  <i>aSelector</i> to be sent to <i>toObject</i> at time <i>time</i>
  beats from the beginning of the receiver's performance.

  <i>argCount</i> specifies the number of four-byte arguments to
  <i>aSelector</i>. If arg1 or arg2 are
	  objects, set the retain: argument following them to TRUE to prevent
	  the object from any chance of deallocation between this method being
	  called, and the message being dispatched.
 @param  aSelector is a SEL.
 @param  toObject is an id.
 @param  time is a double.
 @param  argCount,... is an int
 @param  arg1 is an object or any 4-byte type
 @param  retainArg1 is a BOOL
 @param  arg2 is an object or any 4-byte type
 @param  retainArg2 is a BOOL
 @return Returns an id.
 
 */
-    sel: (SEL) aSelector 
      to: (id) toObject 
  atTime: (double) time
argCount: (int) argCount
    arg1: (id) arg1 
  retain: (BOOL) retainArg1
    arg2: (id) arg2 
  retain: (BOOL) retainArg2;
/*!
  @brief Same as <tt>[[MKConductor clockConductor] time]</tt>.
  
  Returns the current performance time, in seconds.  This doesn't
  include time that the performance has been paused, nor does it
  include the performance's delta time.  If a performance isn't in
  progress, MK_NODVAL is returned .  Use <b>MKIsNoDVal()</b> to check
  for this return value.
 @return Returns a double.
*/
+ (double) timeInSeconds; 

/*!
  @brief Returns the receiver's notion of the current time in
  beats.
  @return Returns a double.
*/
- (double) timeInBeats; 

/*!
  @brief Removes all message requests from the receiver's message request
  queue and returns the receiver.

  Doesn't send any of the messages.
 @return Returns an id.
*/
- emptyQueue; 

/*!
  @brief Returns <b>YES</b> if the receiver is currently sending a message
  from its message request queue.
 @return Returns a BOOL.
*/
- (BOOL) isCurrentConductor;

/*!
  @param  aSelector is a SEL.
  @param  toObject is an id.
  @param  argCount,... is an int.
  @return Returns a MKMsgStruct *.
  @brief Enqueues a request for <i>aSelector</i> to be sent to
  <i>toObject</i> immediately after the current (or next) performance
  ends.

  <i>argCount</i> specifies the number of four-byte arguments
  to <i>aSelector</i> followed by the arguments themselves, separated
  by commas (two arguments, maximum).  You can enqueue as many of
  these requests as you want; they're sent in the order that they were
  enqueued.  Returns a pointer to a <i>message request structure that
  can be passed to</i><b> a C function such as MKCancelMsgRequest()</b>.
*/
+ (MKMsgStruct *) afterPerformanceSel: (SEL) aSelector
				   to: (id) toObject
			     argCount: (int) argCount, ...; 

/*!
  @brief Enqueues a request for <i>aSelector</i> to be sent to
  <i>toObject</i> immediately after the current (or next) performance
  ends.

  <i>argCount</i> specifies the number of four-byte arguments
  to <i>aSelector</i>. arg1 and arg2 can be objects or other 4-byte
  object types (eg int). If either is an object, specify retain:TRUE
  for that object, and it will receive retain and release messages, meaning
  that they should not become accidentally deallocated before the message
  containing them as arguments is dispatched.
  You can enqueue as many of
  these requests as you want; they're sent in the order that they were
  enqueued.  Returns a pointer to a <i>message request structure that
  can be passed to</i><b> a C function such as MKCancelMsgRequest()</b>.
 @param  aSelector is a SEL.
 @param  toObject is an id.
 @param  argCount is an int.
 @param  arg1 is an id or any 4-byte type.
 @param  retainArg1 is a BOOL.
 @param  arg2 is an id or any 4-byte type.
 @param  retainArg2 is a BOOL.
 @return Returns a MKMsgStruct *.
 */
+ (MKMsgStruct *) afterPerformanceSel: (SEL) aSelector 
				   to: (id) toObject 
			     argCount: (int) argCount
				 arg1: (id) arg1 
			       retain: (BOOL) retainArg1
				 arg2: (id) arg2
			       retain: (BOOL) retainArg2;

/*!
  @param  aSelector is a SEL.
  @param  toObject is an id.
  @param  argCount,... is an int.
  @return Returns a MKMsgStruct *.
  @brief Enqueues a request for <i>aSelector</i> to be sent to
  <i>toObject</i> at the beginning of the next performance.

  
  <i>argCount</i> specifies the number of four-byte arguments to
  <i>aSelector</i> followed by the arguments themselves, separated by
  commas (two arguments, maximum).  You can enqueue as many of these
  requests as you want; they're sent in the order that they were
  enqueued.  Returns a pointer to a <i>message request structure that
  can be passed to</i><b> a C function such as MKCancelMsgRequest()</b>.
*/
+ (MKMsgStruct *) beforePerformanceSel: (SEL) aSelector to: toObject argCount: (int) argCount, ...; 

/*!
  @brief Enqueues a request for <i>aSelector</i> to be sent to
  <i>toObject</i> at the beginning of the next performance.
  
  <i>argCount</i> specifies the number of four-byte arguments
  to <i>aSelector</i>. arg1 and arg2 can be objects or other 4-byte
  object types (eg int). If either is an object, specify retain:TRUE
  for that object, and it will receive retain and release messages, meaning
  that they should not become accidentally deallocated before the message
  containing them as arguments is dispatched.
  You can enqueue as many of these
  requests as you want; they're sent in the order that they were
  enqueued.  Returns a pointer to a <i>message request structure that
  can be passed to</i><b> a C function such as MKCancelMsgRequest()</b>.
  @param  aSelector is a SEL.
  @param  toObject is an id.
  @param  argCount is an int.
  @param  arg1 is an id or any 4-byte type.
  @param  retainArg1 is a BOOL.
  @param  arg2 is an id or any 4-byte type.
  @param  retainArg2 is a BOOL.
  @return Returns a MKMsgStruct *.
 */
+ (MKMsgStruct *) beforePerformanceSel: (SEL) aSelector
				    to: (id) toObject 
			      argCount: (int) argCount
				  arg1: (id) arg1
				retain: (BOOL) retainArg1
				  arg2: (id) arg2
				retain: (BOOL) retainArg2;

/*!
  @brief Sets the receiver's delegate object to <i>delegate</i> and returns
  the receiver.

  The delegate is sent <b>hasPaused:</b> and
  <b>hasResumed:</b> as the receiver is paused and resumed,
  respectively. 
 @param  delegate is an id.
 @return Returns an id.
*/
- (void) setDelegate: (id) delegate;

/*!
  @brief Returns the receiver's delegate object, as set through the <b>setDelegate:</b> method.
  @return Returns an id.
*/
- delegate;

/*!
  @brief Sets the receiver's delegate object to <i>delegate</i> and returns
  the receiver.

  The delegate is sent <b>hasPaused:</b> and
  <b>hasResumed:</b> as the receiver is paused and resumed,
  respectively. 
  @param  delegate is an id.
  @return Returns an id.
*/
+ (void) setDelegate: (id) delegate;

/*!
  @brief Returns the receiver's delegate object, as set through the
  <b>setDelegate:</b> method.
 @return Returns an id.
*/
+ delegate;

/*!
  @brief Returns a List of currently active Performers that are assigned to
  this MKConductor.

  The NSMutableArray is <i>not</i> copied and
  should not be freed or altered.
 @return Returns an id.
*/
- activePerformers;

- (void) encodeWithCoder: (NSCoder *) aCoder;
- (id) initWithCoder: (NSCoder *) aDecoder;
- awakeAfterUsingCoder: (NSCoder *) aDecoder;

/* Obsolete methods */
- (double) predictTime:(double)beatTime; 

@end

@interface MKConductor(MTC)

/*!
  @param  aMidiObj is an id.
  @return Returns an id.
  @brief Sets the MKConductor to synchronize to MIDI time code coming in on
  the specified MIDI object.

  Keep in mind that only one MKConductor
  at a time may have an MTCSynch object.   Unclocked performances
  involving MIDI time code conductors are not
	  supported. Hence, <b>setMTCSynch:</b> sends
	  <tt>[MKConductor setClocked:YES];</tt>.  For
  details, see 
<a href=http://www.musickit.org/MusicKitConcepts/miditimecode.html>
Appendix entitled MIDI Time Code in the MusicKit
</a> mentioned above.
*/
- setMTCSynch: (MKMidi *) aMidiObj;

/*!
  @return Returns an id.
  @brief Returns the MKMidi object previously set with <b>setMTCSynch:</b>, or
  <b>nil</b> if none.

  Keep in mind that only one MKConductor at a
  time may have an MTCSynch object.
*/
- (MKMidi *) MTCSynch;

/*!
  @return Returns a double.
  @brief A convenience method.

  Returns the current clock time for the
  object.  If the object is synchronizing to MIDI time code, the value
  returned is the current MIDI time code time, the same value returned
  by MKMidi's <b>time</b> method.   If the object is not synchronizing
  to MIDI time code, the value returend is the same value as the value
  returned by  <tt>[[MKConductor clockConductor] time]</tt>.
*/
- (double) clockTime;

@end

@interface MKConductor(SeparateThread)  <SndDelegateMessagePassing>

/*!
  @param  yesOrNo is a BOOL.
  @return Returns an id.
  @brief If invoked with an argument of YES, all following performances will
  be run in a separate Mach thread.

  Some restrictions apply to
  separate-threaded performances as follows:  You may not do any
  drawing or appkit calls from the separate thread.  If you need to
  send a message to the appkit, use <b>+sendMsgToApplicationThreadSel:
  to:argCount:</b>.  
  
  Default is NO.  You should not send this message if any MKMidi objects are open (or running or stopped. ) 
  
*/
+ useSeparateThread: (BOOL) yesOrNo;

/*!
  @function separateThreaded
  @brief Returns YES if the MKConductor is separate threaded, NO if it runs in the application thread.

  
*/
+ (BOOL) separateThreaded;

/*!
  @brief Returns YES if the MKConductor is separate threaded and the calling code is running
  in the separate thread, NO if the code is running in the application thread.

  
*/
+ (BOOL) separateThreadedAndInMusicKitThread;

/*!
  @return Returns an id.
  @brief In a separate-threaded performance, this method gets the MusicKit
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
  @return Returns an id.
  @brief Undoes lockPerformance.

  In a separate-threaded performace, sends
  <b>[MKOrchestra flushTimedMessages]</b> and then gives up the
  MusicKit lock.  In a performance that is not separate-threaded, this
  method is the same as MKOrchestra's <b>flushTimedMessages</b>,
  except that the flush is done only when the last recursive lock is
  given up (See MKOrchestra.h.)
*/
+ unlockPerformance;

/*!
  @return Returns a BOOL.
  @brief Same as lockPerformance but does not wait and returns NO if the lock
  is  unavailable.

  If the lock is successful, sends <b>[MKConductor
  adjustTime]</b> and returns YES. You rarely use this method.  It is
  provided for cases where you would prefer to give up than to wait
  (e.g. when simultaneously doing graphic animation.)
*/
+ (BOOL) lockPerformanceNoBlock;

/*!
  @param  priorityFactor is a float.
  @return Returns an id.
  @brief This method sets the thread priority of the following and all
  subsequent performances.

  The priority change takes effect when the
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
+ setThreadPriority: (float) priorityFactor;

/*!
  @return Returns an NSThread..
  @brief In a separate-threaded MusicKit performance, returns the NSThread
  used in that performance.

  When the thread has exited, returns
  nil. 
*/
+ (NSThread *) performanceThread;

/*!  
  @return returns an id.
  @param  aSelector is a SEL.
  @param  toObject is an id.
  @param  argCount is an integer.
  @param  variable arguments.
  @brief If called from the MusicKit thread, sends an Objective-C
  message from the MusicKit thread to the Application's
  main thread.

  This is the only safe way to invoke the
  Application Kit from within the MusicKit's thread.  The
  message will be run in the application as soon as the
  Application event loop threshold is NX_BASETHRESHOLD. To
  increase the priority of MusicKit-sent messages, use
  <b>+setInterThreadThreshold:</b>.  If called from the
  Application Kit thread, or there is no separate-threaded
  performance going on, this is the same as sending
  aSelector directly to toObject.
*/
+ sendMsgToApplicationThreadSel: (SEL) aSelector to: (id) toObject argCount: (int) argCount, ...;

/*!
  @return
  @brief Called by +initialize to detach a thread to handle messaging between
  any background thread and the application thread.

  It is imperative that
  +initialize is called from the application thread. In effect, this means
  that the very first use of [MKConductor ...] must be done in the
  application thread.
*/
+ (void) detachDelegateMessageThread;

/*!  
  @return none
  @param  target is an id.
  @param  aSelector is a SEL.
  @param  arg1 is any 4-byte argument.
  @param  arg2 is any 4-byte argument.
  @param  count is an integer.
  @brief This is the back end to sendMsgToApplicationThreadSel, above.

  
  It relies on the delegate message thread having been set up
  which is done from +initialize.
*/
+ (void) sendMessageInMainThreadToTarget: (id) target 
                                     sel: (SEL) aSelector
                                    arg1: (id) arg1
                                    arg2: (id) arg2
                                   count: (int) count;

/*!
  @param  newThreshold is an NSString.
  @return Returns an id.
  @brief Resets the threshold used for interthread
  communication.

  This message may only be sent from the Application
  thread.  Otherwise, it is ignored.
*/
+ setInterThreadThreshold: (NSString *) newThreshold;

/*!
  @param  mesg is an NSInvocation, but cast as an unsigned long so the runtime does
  not interpret it as an object, and mangle it (yes the casting has an
  effect at runtime in this situation!).
  @return void.
  @brief This is the method called in the application thread to actually deliver
  the message sent through form the background thread (eg background
  MKConductor thread).

  
*/
+ (void) _sendDelegateInvocation: (in unsigned long) mesg;

@end

#import "MKConductorDelegate.h"

#ifdef __cplusplus
}
#endif

#endif
