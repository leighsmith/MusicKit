/*
  $Id$
  Defined In: The MusicKit

  Description:
    See discussion below.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 CCRMA, Stanford University.
  Portions (Time code extensions) Copyright (c) 1993 Pinnacle Research.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*!
  @class MKMTCPerformer
  @brief

MKMTCPerformer is used to generate MKNotes with MIDI time code parameters.  The main
use of this class is to send the MKNotes to a MKMidi object.  To use an
MKMTCPerformer, simply, instantiate the object, activate it, connect a MKMidi object
to its one NoteSender and start the performance.  This is done with the usual
MKPerformer methods:
	
<tt>
id myMTCPerformer =[[MKMTCPerformer alloc] init];	
id myMidi = [MKMidi newOnDevice:"midi0"];	
[[myMTCPerformer noteSender] connect:[myMidi noteReceiver]];

[myMTCPerformer activate];	
[myMidi run];	
[Conductor startPerformance];
</tt>

This will begin generating time code in a forward direction, beginning with the
value 0:0:0:0, using the default format (24 frames/second). 


You set the format of the time code to be generated with the method
<b>setFormat:</b>.  The argument should be one of the following constants,
defined in<b> &lt;MusicKit/MKMTCPerformer.h&gt;</b>:	

<UL>
<LI>MK_MTC_FORMAT_24
<LI>MK_MTC_FORMAT_25
<LI>MK_MTC_FORMAT_DROP_30
<LI>MK_MTC_FORMAT_30
</UL>

These are the standard MIDI time code formats.  For more information, see the
MIDI Time Code Specification (available from the MIDI Manufacturer's
Association).

You set the first and last MTC value using the methods <b>setFirstTimeTag:</b>,
<b>setLastTimeTag:</b> and <b>setTimeShift:</b>. To set the first value the
MKPerformer will generate, you use <b>setFirstTimetTag:</b>. Note that this
method also sets the time from activation at which the MKPerformer will start
sending time code.  For example, if (before the performance) you set a
MKPerformer's <i>firstTimeTag</i> to 10.0 seconds, then activate the MKPerformer and
start the performance, the MKPerformer will begin sending time code at time 10.0
seconds and the values will begin at the MTC time 0:0:10:0  (zero hours, zero
minutes, ten seconds, zero frames).  

You may want the time code to begin sending immediately, regardless of
<i>firstTimeTag</i>.  To do this, use the MKPerformer method <b>setTimeShift:</b>
and pass it an argument of <i>firstTimeTag</i>:

<tt>	
id myMTCPerformer =[[MKMTCPerformer alloc] init];	
[myMTCPerformer setFirstTimeTag:10.0];	
[myMTCPerformer setTimeShift:-10.0];	
[myMTCPerformer activate];	
[Conductor startPerformance];
</tt>

If you want to generate time code beginning with a value of 2.0 seconds and
start sending that time that time code at time 3.0 seconds, set
<i>firstTimeTag</i> to 2.0 and <i>timeShift</i> to 1.0.  In general, the formula
is:	
	
<i>start time = timeShift + firstTimeTag+ activation time</i>

The default value for both <i>timeShift</i> and <i>firstTimeTag</i> is 0.0. 
Keep in mind that the start time given in the formula above is relative to the
time of activation.  

By default, time code generation continues until you deactivate the MKPerformer or
finish the performance.  However, you can specify that the MKPerformer
automatically deactivate when it reaches a certain target MTC value by sending
it the <b> setLastTimeTag:</b>message.  Normally, <i>  lastTimeTag </i>should
be greater than <i>firstTimeTag</i>.  However, you can tell the MKPerformer to
send reverse time code as follows:
	
<tt>[myMTCPerformer setDirection:MK_MTC_REVERSE];</tt>

Then, <i>lastTimeTag</i> should be less than <i>firstTimeTag</i>.  Time code
values will count down from <i>firstTimeTag</i> until <i>lastTimeTag</i> is
reached.  You cancel generation of reverse time code by sending the
message:
	
<tt>[myMTCPerformer setDirection:MK_MTC_FORWARD];</tt>

As an alternative to using<b> setFirstTimeTag:</b>, <b>setLastTimeTag:</b> and
<b>setTimeShift:</b>, you can use methods that allow you to specify the time
directly in MTC units.  For example, to set <i>firstTimeTag</i> to a MTC value
of 0:21:59:5, you send the following mesage:
	
<tt>[myMTCPerformer setFirstTimeTagMTCHours:0 minutes:21 seconds:59 frames:5];</tt>

This sets the firstTimeTag value as specified, assuming the current MTC format. 
Analagous methods are provided for setting lastTimeTag and timeShift. 

To conveniently convert between seconds and MTC time formats, the Music Kit
provides two C functions:

<tt>
extern double  // Returns time in seconds
  MKConvertMTCToSeconds(	
	short format,	
	short hours,	
	short minutes,	
	short seconds,
  short frames);

extern void  // Returns (by reference) time in MTC units
  MKConvertSecondsToMTC(	
	double seconds,	
	short format,	
	short *hoursPtr,	
	short *minutesPtr,	
	short *secondsPtr,	
	short *framesPtr);
</tt>

These functions do straight translation.  They do not take into account any
DeltaTime value.  

You can pause time code generation using the standard MKPerformer <b>pause</b> 
method.  A paused MKPerformer stops sending MIDI time code until it is resumed
using the resume message.  When it is resumed, it sends a MTC Full Message, then
resumes time code generation where it left off. 

You can also freeze the advance of time, using the <b>freezeTimeCode</b> method.
An MKMTCPerformer that is frozen continues sending MTC messages, but the time
code values remain the same.  Time code can be made to advance again by sending
the <b>thawTimeCode</b> message.

A MTC Full Message is sent when the performer is resumed and the first time it
is activated.  Normally, this is sufficient.  However, you can send a Full
Message at any time, by sending  <b>sendFullMTCMessage</b>. 

User bits are part of the SMPTE specification.  They are not interpreted by the
Music Kit.  You can send user bits by sending <b>sendUserBits:groupFlagBits:</b>.
See the MIDI Time Code specification or the SMPTE specification for the meaning
of the arguments.

You can ask the MKMTCPerformer the current MTC time with the <b>timeTag</b> or
<b>getMTCHours:minutes:seconds:frames:</b> message, which return the time in
seconds and MTC units, respectively.  The time tag returned is in the clock
Conductor's time base.  

  @see  MKPerformer, MKMidi
*/
#ifndef __MK_MTCPerformer_H___
#define __MK_MTCPerformer_H___
#import "MKPerformer.h"

/* The following defines must agree with the MIDI time code spec. */
#define MK_MTC_FORMAT_24      0   
#define MK_MTC_FORMAT_25      1
#define MK_MTC_FORMAT_DROP_30 2
#define MK_MTC_FORMAT_30      3

#define MK_MTC_REVERSE (-1)
#define MK_MTC_FORWARD 1

/* These functions do not compensate for deltaT.  They're just straight
 * translation  
 */
extern double 
  MKConvertMTCToSeconds(short format,short hours,short minutes,short seconds,
			short frames);

extern void 
  MKConvertSecondsToMTC(double seconds,short format,short *hoursPtr,short *minutesPtr,
			short *secondsPtr,short *framesPtr);

@interface MKMTCPerformer:MKPerformer
{
    double firstTimeTag;   /* firstTimeTag, as specified by user. */
    double lastTimeTag;    /* lastTimeTag, as specified by user. */
    int direction;         /* 1 for forward, -1 for reverse */
    short format;          /* MTC format */
    id noteSender;
    id aNote;
    BOOL frozen;

@private
    int _cmpStat;
    /* This is the stopping point, in delta-t-adjusted time */
    short _lastHours;
    short _lastMinutes;
    short _lastSeconds;
    short _lastFrames;
    short _frameQuarter;     /* Which quarter-frame we're on */

    /* These are the time in delta-t adjusted units.  Use
     * the access methods to get their value in MKConductor's time
     * base.
     */
    short _hours;
    short _minutes;
    short _seconds;
    short _frames;
}


/*!
  @return Returns an id.
  @brief Initialize the receiver.

  Must be sent when a new object is
  allocated.  If you override this method, you must first send [super
  init] before doing your own initialization.
*/
- init;

/*!
  @param  firstTimeTag is a double.
  @return Returns an id.
  @brief Sets <i>firstTimeTag</i> as specified.

  This controls the time from
  activation at which the MKPerformer will begin sending time code.   It
  also controls the first time code value it will send.  You can
  decouple the time the performer runs from the time code it outputs
  by using Performer's <tt>setTimeShift:</tt>.  For example, to generate time
  code, beginning with time 2, and to start sending that time code at
  time 3, you'd send:
  	
  <tt>
  [perf setFirstTimeTag:2];
  [perf setTimeOffset:1];
  </tt>
*/
-setFirstTimeTag:(double)f;

/*!
  @param  lastTimeTag is a double.
  @return Returns an id.
  @brief Sets <i>lastTimetTag</i>, the last time code value that will be
  sent.

  The MKPerformer runs until lastTimeTag is sent.  If direction
  is <b>MK_MTC_REVERSE</b>, <i>lastTimeTag</i> should be less than
  <i>firstTimeTag</i>.  Otherwise, <i>lastTimeTag</i> should be
  greater than <i>firstTimeTag</i>.
*/
-setLastTimeTag:(double)l;

/*!
  @param  firstTimeTag is a double.
  @return Returns an id.
  @brief Same as <tt>setFirstTimeTag:</tt>, except that the time is specified in Midi time
  code units.

  Assumes the current format. (See <tt>setFormat:</tt>)
*/
-setFirstTimeTagMTCHours:(short)h minutes:(short)m seconds:(short)s frames:(short)f;

/*!
  @param  h is a short.
  @param  m is a short.
  @param  s is a short.
  @param  f is a short.
  @return Returns an id.
  @brief Same as setLastTimeTag:, except that the time is specified in Midi time
  code units.

  Assumes the current format. (See <tt>setFormat:</tt>)
*/
-setLastTimeTagMTCHours:(short)h minutes:(short)m seconds:(short)s frames:(short)f;

/*!
  @param  h is a short.
  @param  m is a short.
  @param  s is a short.
  @param  f is a short.
  @return Returns an id.
  @brief Same as setTimeShift:, except that the time is specified in Midi
  time code units.

  Assumes the current format. (See
  <b>setFormat:</b>)
*/
-setTimeShiftMTCHours:(short)h minutes:(short)m seconds:(short)s frames:(short)f;

/*!
  @return Returns a double.
  @brief Returns <i>firstTimeTag</i>, as previously set with
  <b>setLastTimeTag:</b> or <b>setFirstTimeTagMTCHours:minutes:seconds:frames:</b>.

  
*/
-(double)firstTimeTag;

/*!
  @return Returns a double.
  @brief Returns <i>lastTimeTag</i>, as previously set with
  <b>setLastTimeTag:</b> or <b>setLastTimeTagMTCHours:minutes:seconds:frames:</b>.

  
*/
-(double)lastTimeTag;

/*!
  @param  fmt is an int.
  @return Returns an id.
  @brief Sets format of the timecode to one of the following:
  	
  MK_MTC_FORMAT_24  (24 frames/second)
  MK_MTC_FORMAT_25  (25 frames/second)
  MK_MTC_FORMAT_DROP_30  (30 frames/second, drop-frame)
  MK_MTC_FORMAT_30 (30 frames/second, no drop-frame)
*/
-setFormat:(int)fmt;

/*!
  @return Returns a double.
  @brief Returns the time code value most recently sent.

  
*/
-(double)timeTag;

/*!
  @param  h is a short *.
  @param  m is a short *.
  @param  s is a short *.
  @param  f is a short *.
  @return Returns an id.
  @brief Same as timeTag, except that the time is returned in MIDI time code
  units.

  Assumes the current format.
*/
-getMTCHours:(short *)h minutes:(short *)m seconds:(short *)s frames:(short *)f;

/*!
  @param  newDirection is an int.
  @return Returns an id.
  @brief Sets direction of time code to be generated.

  If
  <i>newDirection</i> is 1, forward time code is generated.  If
  <i>newDirectino</i> is 0, backward time code is generated.
*/
-setDirection:(int)newDirection;

/*!
  @param  userBits is an unsigned int.
  @param  groupFlagBits is an unsigned char.
  @return Returns an id.
  @brief Sends SMPTE user bits as indicated.

  These are defined by the SMPTE
  specification. The MusicKit ignores their content.
*/
-sendUserBits:(unsigned int)userBits groupFlagBits:(unsigned char)groupFlagBits;

/*!
  @return Returns an id.
  @brief Stops the advance of time code, but doesn't pause performer.

  Time
  code will continue to be generated, but the same value will be sent
  over and over.
*/
-freezeTimeCode;  

/*!
  @return Returns an id.
  @brief Undoes the effect of <b>freezeTimeCode</b>.

  
*/
-thawTimeCode;

/*!
  @return Returns an id.
  @brief Sends the current time as a MIDI time code Full Message.

  See the
  MIDI Time Code Specification for details.
*/
-sendFullMTCMessage; 

/*!
  @return returns <b>self</b>
  @brief Prepares the object for performance
*/
-activateSelf;    

/*!
  @return Returns an id.
  @brief Sends a MIDI system exclusive "NAK" message to signal that time code
  has stopped.

  
*/
- (void)deactivate;

/*!
  @return Returns an id.
  @brief Sends a MIDI system exclusive "NAK" message to signal that time code
  has stopped.

  Then invokes superclass version of method to pause
  the MKMTCPerformer.
*/
-pause;           /* Sends NAK SYSEX, then pauses.  */

/*!
  @return Returns an id.
  @brief Sends a MIDI time code Full Message.

  Then invokes superclass
  version of method to resume the MKMTCPerformer.
*/
-resume;          /* Resumes time code. Sends a Full message */

-perform;

@end

#endif
