/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    (See discussion below)

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*!
  @class MKEnvelope
  @brief The MKEnvelope class provides basic support for creating line segment functions. 
  
  

The MKEnvelope class provides basic support for creating line segment functions. 
An MKEnvelope consists of a series of <i>breakpoints</i> each consisting of three
values:  <i>x</i>, <i>y</i>, and <i>smoothing</i>.  The <i>x</i> and <i>y</i>
values locate a value <i>y</i> at a particular time <i>x</i>. There is also a
<i>smoothing</i> value associated with each breakpoint that is used primarily in
<b>AsympUG</b>, a MKUnitGenerator that creates asymptotic envelope functions on
the DSP.  <i>Smoothing</i> defines the shape of the curve between
breakpoints.

There are two ways to use an MKEnvelope: as a continuous function during DSP
synthesis or to return a discrete value <i>y</i> for a given <i>x</i>. 

To fill an MKEnvelope object with data, you invoke the method
	
<b>setPointCount:</b>	
<b>xArray:</b>	
<b>orSamplingPeriod:</b>	
<b>yArray:</b>	
<b>smoothingArray:</b>	
<b>orDefaultSmoothing:</b>

The argument to <b>setPointCount:</b> specifies the number of breakpoints in the
MKEnvelope; the arguments to <b>xArray:</b>, <b>yArray:</b>, and
<b>smoothingArray:</b> are pointers to arrays of <i>x</i>, <i>y</i>, and
<i>smoothing</i> values for the Envelope's breakpoints.  The range of musically
useful <i>y</i> values depends on the parameter that the MKEnvelope will affect.
For example, amplitude normally is between 0.0 and 1.0, while frequency is
expressed in Hz and assumes values over the range of human  hearing.  The
breakpoints in an MKEnvelope must succeed each other in time; thus, the values in
the <i>x</i> array must get successively larger.  By default, the <i>x</i>
values are taken as seconds, although this interpretation can be modified
through the use of auxilliary parameters, as explained below. 

While you must always supply an array of <i>y</i> values, the same isn't true
for <i>x</i> and <i>smoothing</i>.  Rather than provide an <i>x</i> array, you
can specify, as the argument to <b>orSamplingPeriod:</b>, a <i>sampling
period</i> that's used as an <i>x</i> increment:  The <i>x</i> value of the
first breakpoint is 0.0, successive <i>x</i> values are integer multiples of the
sampling period value.  Similarly, you can supply a constant <i>smoothing</i>
value, as the argument to <b>orDefaultSmoothing:</b>, rather than provide a
<i>smoothing</i> array.  In the presence of both an <i>x</i> array and a
sampling period, or both a <i>smoothing</i> array and a default
<i>smoothing</i>, the array takes precedence.

The shorthand method <b>setPointCount:xArray:yArray:</b> can also be used to
fill an MKEnvelope with data.

Envelopes are described as having three parts:  attack, sustain, and release. 
You can set the sustain portion of an MKEnvelope by designating one of its
breakpoints as the <i>stickpoint</i> through the <b>setStickPoint:</b> method. 
Everything up to the stickpoint is the Envelope's attack; everything after the
stickpoint is its release.  When the stickpoint is reached during DSP synthesis,
its y value is sustained until a <b>noteOff</b> arrives to signal the release
(keep in mind that a <b>noteDur</b> is split into a <b>noteOn</b>/<b>noteOff</b>
pair by MKSynthInstrument<b></b>objects).

An MKEnvelope object is set as the value of a Note's parameter through Note's
<b>setPar:toEnvelope:</b> method.  Parameters that accept MKEnvelope objects
usually have associated with them several other parameters that interpret the
MKEnvelope by scaling and offsetting the Envelope's <i>x</i> and <i>y</i> values. 

For example, the <b>MK_ampEnv</b> parameter takes an MKEnvelope as its value; <b>
MK_amp0</b>and<b> MK_amp1</b>  are constant-valued parameters that scale and
offset the y values in <b>MK_ampEnv</b> according to the formula
	
(<i>scale</i>* y) + <i>offset</i>

where <i>scale</i> is calculated as <b>MK_amp1</b> - <b>MK_amp0</b> and offset
is simply the value of <b>MK_amp0</b>.  In other words, <b>MK_amp0</b> defines
the interpreted value when <i>y</i> is 0.0 and <b>MK_amp1</b> is the interpreted
value when <i>y</i> is 1.0.  
While an Envelopes's x values are normally taken as an absolute time in seconds,
MKSynthPatches usually provide additional parameters that let you reset the attack
and release durations.  For example, the <b>MK_ampAtt</b> parameter  resets the
duration of the attack portion of a Note's amplitude MKEnvelope; similarly,
<b>MK_ampRel</b> resets the release duration. 

When used in DSP synthesis, MKEnvelope objects are applied by a MKUnitGenerator such
as <b>AsympUG</b>.  AsympUG creates asymptotic curves between breakpoints.  The
shape of a  segment going into a particular breakpoint is determined by that
breakpoint's <i>smoothing</i> value (the <i>smoothing</i> value of the first
breakpoint is ignored).  <i>Smoothing</i> values should be between 0.0 and 1.0
where 0.0 means no <i>smoothing</i> (a stairstep function), and 1.0 takes the
entire duration between points to arrive at (near) the <i>y</i> value.  More
precisely, a <i>smoothing</i> of 1.0 signifies that the AsympUG<b></b> will
reach within -48dB of the <i>y</i> value.  A smoothing in excess of 1.0 causes
the
AsympUG trajectory to fall short of the next point's <i>y</i> value.  See the
AsympUG class description for the formula used to compute the asymptotic
function.

Although MKEnvelope objects are most commonly used in  DSP synthesis, they can
also be used to return a discrete value of <i>y</i> for a given <i>x</i>, as
provided in the method <b>lookupYForX:</b>.  Discrete-value lookup is useful for
controlling the way a constant-valued parameter evolves over a <i>series</i> of
MKNotes.  If the <i>x</i> value doesn't correspond exactly to a breakpoint in the
MKEnvelope, the method does a linear interpolation between the immediately
surrounding breakpoints.  

Envelopes are automatically created by the Music Kit in a number of
circumstances, such as when reading a Scorefile.  The function
<b>MKSetEnvelopeClass()</b> allows you to specify that your own subclass of
MKEnvelope be used when Envelopes are automatically created.  

  @see  MKNote, AsympUG
*/
#ifndef __MK_Envelope_H___
#define __MK_Envelope_H___

#import <Foundation/Foundation.h>

/*!
  @file MKEnvelope.h
 */
/*!
  @brief This enumeration defines the return values of the MKEnvelope method
  <b>getNth:x:y:smoothing:</b>.
 */
typedef enum _MKEnvStatus { 
    /*! Attempt to read invalid point in envelope. */
    MK_noMorePoints = -1,
    /*! MKEnvelope has not been properly initialized. */
    MK_noEnvError = 0,
    /*! The requested point is the stick point of the MKEnvelope. */
    MK_stickPoint,
    /*! The requested point is the last point of the MKEnvelope. */
    MK_lastPoint
} MKEnvStatus;

@interface MKEnvelope : NSObject
{
    /*! If no Smoothing-array, this is time constant. */
    double defaultSmoothing;
    /*! If no X-array, this is abcissa scale */
    double samplingPeriod;
    /*! Array of x values, if any. */
    double *xArray;
    /*! Arrays of data values */
    double *yArray;
    /*! Array of time constants. */
    double *smoothingArray;
    /*! Index of "steady-state", if any */
    int stickPoint;
    /*! Number of points in envelope */
    int pointCount;
}

/*!
  @return Returns an id.
  @brief Initializes the object by setting its default smoothing to 1.0, its
  sampling period to 1.0, and its stickpoint to MAXINT.

  You invoke
  this method when a creating a new MKEnvelope.  A subclass
  implementation should send <b>[super init]</b> before performing its
  own initialization.  
*/
- init; 

/*!
  @return Returns an int.
  @brief Returns the number of breakpoints in the object.

  
*/
- (int) pointCount;

/*!
  @return Returns a double.
  @brief Returns the object's default smoothing value, or MK_NODVAL if
  there's a smoothing array.

  (Use <b>MKIsNoDVal()</b> to check for
  MK_NODVAL.)
*/
- (double) defaultSmoothing;

/*!
  @return Returns a double.
  @brief Returns the sampling period, or MK_NODVAL if there's an <i>x</i>
  array.

  (Use <b>MKIsNoDVal()</b> to check for MK_NODVAL.)
*/
- (double) samplingPeriod;

/*!
  @return Returns an int.
  @brief Returns the stickpoint, or MAXINT if none.

  
*/
- (int) stickPoint; 

/*!
  @brief Sets the object's stickpoint to the <i>stickPointIndex</i>'th breakpoint, counting from 0.

  Returns the object, or <b>nil</b> if <i>stickPointIndex</i>
  is out of bounds.  Setting the stickpoint to MAXINT removes it.
  @param  stickPointIndex is an int.
  @return Returns an id.
*/
- setStickPoint: (int) stickPointIndex; 

/*!
  @brief Fills the object with data by copying the values from <i>xPtr</i>,
  <i>yPtr</i>, and <i>smoothingPtr</i>.

  If <i>xPtr</i> is NULL, the
  object's sampling period is set to <i>period</i> (otherwise
  <i>period</i> is ignored).  Similarly, <i>smoothing</i> is used as
  the object's default smoothing in the absence of
  <i>smoothingPtr</i>.  If <i>yPtr</i> is NULL, the object's y array
  is unchanged. Returns the object.
 @param  n is an int.
 @param  xPtr is a double *.
 @param  period is a double.
 @param  yPtr is a double *.
 @param  smoothingPtr is a double *.
 @param  smoothing is a double.
 @return Returns an id.
 */
-    setPointCount: (int) n
            xArray: (double *) xPtr
  orSamplingPeriod: (double) period
            yArray: (double *) yPtr
    smoothingArray: (double *) smoothingPtr
orDefaultSmoothing: (double) smoothing;

/*!
  @param  n is an int.
  @param  xPtr is a double *.
  @param  yPtr is a double *.
  @return Returns an id.
  @brief This is a cover for the more complete <b>setPointCount:xArray:orSamplingPeriod:</b>...

  method.
  The object's smoothing specification is unchanged (keep in mind that smoothing is initialized
  to a constant 1.0).  If <i>xPtr</i> or <i>yPtr</i> is NULL, the object's <i>x</i> or <i>y</i>
  array is unchanged, respectively.  In either of these cases, it is the sender's responsibility
  to insure that the new value of <i>n</i> is the same as the <i>pointCount</i> of the old array. 
  Returns the object.
*/
- setPointCount: (int) n
         xArray: (double *) xPtr
         yArray: (double *) yPtr;
         
/*!
  @return Returns a double *.
  @brief Returns a pointer to the object's <i>y</i> array, or
  NULL if none.

  
*/
- (double *) yArray;

/*!
  @return Returns a double *.
  @brief Returns a pointer to the object's <i>x</i> array, or NULL if
  none.

  
*/
- (double *) xArray;

/*!
  @return Returns a double *.
  @brief Returns a pointer to the object's smoothing array, or NULL if
  none.

  
*/
- (double *) smoothingArray;

/*!
  @param  n is an int.
  @param  xPtr is a double *.
  @param  yPtr is a double *.
  @param  smoothingPtr is a double *.
  @return Returns a MKEnvStatus.
  @brief Returns, by reference, the <i>x</i>, <i>y</i>, and smoothing values
  for the <i>n</i>'th breakpoint in the object counting from
  breakpoint 0.

  The method's return value is a constant that
  describes the position of the <i>n</i>'th breakpoint:
  
  <b>Position	Constant</b>
  last point in the object	MK_lastPoint 
  stickpoint	MK_stickPoint 
  point out of bounds	MK_noMorePoints 
  any other point	MK_noEnvError
  
  If the object's y array is <b>NULL,</b>or its <i>x</i> array is NULL
  and its sampling period is 0.0, <b>MK_noMorePoints</b> is returned.
*/
- (MKEnvStatus) getNth: (int) n
                     x: (double *) xPtr
                     y: (double *) yPtr
             smoothing: (double *) smoothingPtr; 

/*!
  @param  aStream is a NSMutableData instance.
  @return Returns an id.
  @brief Writes the object to the stream <i>aStream</i> in scorefile format.

  
  The stream must already be open.  The object's breakpoints are
  written, in order, as <b>(</b>x<b>,</b> y<b>,</b> smoothing<b>)</b>
  with the stickpoint followed by a vertical bar.  For example, a
  simple three-breakpoint MKEnvelope describing an arch might look like
  this (the second breakpoint is the stickpoint):
  
  <tt>(0.0, 0.0, 0.0) (0.3, 1.0, 0.05) | (0.5, 0.0, 0.2)</tt>
  
  Returns <b>nil</b> if the object's y array is NULL.  Otherwise returns the object.
*/
- writeScorefileStream: (NSMutableData *) aStream; 

/*!
  @param  xVal is a double.
  @return Returns a double.
  @brief Returns the y value that corresponds to <i>xVal</i>.

  If <i>xVal</i>
  doesn't fall exactly on one of the object's breakpoints, the return
  value is computed as a linear interpolation between the y values of
  the nearest breakpoints on either side of <i>xVal</i>.  If
  <i>xVal</i> is out of bounds, this returns the first or last y
  value, depending on which boundary was exceeded.  If the object's y
  array is NULL, this returns MK_NODVAL.  (Use <b>MKIsNoDVal()</b> to
  check for MK_NODVAL.)
*/
- (double) lookupYForX: (double) xVal;

/*!
  @param  xVal is a double.
  @return Returns a double.
  @brief Same as <b>lookupYForX</b>, but assumes an asymptotic envelope, such
  as is produced by the AsympUG MKUnitGenerator.

  
*/
- (double) lookupYForXAsymptotic: (double) xVal;

/*!
  @return Returns a double.
  @brief Returns the duration of the release portion of the object.

  This is
  the difference between the <i>x</i> value of the stickpoint and the
  <i>x</i> value of the final breakpoint.  Returns 0.0 if the object
  doesn't have a stickpoint, or if the stickpoint is out of
  bounds.
*/
- (double) releaseDur;

/*!
  @return Returns a double.
  @brief Returns the duration of the attack portion of the object.

  This is
  the difference between the <i>x</i> value of the first breakpoint
  and the <i>x</i> value of the stickpoint.  If the object doesn't
  have a stickpoint (or if the stickpoint is out of bounds), the
  duration of the entire MKEnvelope is returned.
*/
- (double) attackDur;

@end

#endif
