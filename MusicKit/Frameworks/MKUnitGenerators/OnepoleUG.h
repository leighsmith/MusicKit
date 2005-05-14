/*
  $Id$
  Defined In: This class is part of the Music Kit UnitGenerator Library.

  Description:   
    OnepoleUG  - from dsp macro /usr/lib/dsp/ugsrc/onepole.asm (see source for details).

    The onepole unit-generator implements a one-pole
    filter section in direct form.

    You instantiate a subclass of the form
    OnepoleUG<a><b>, where <a> = space of output and <b> = space of input.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 2000 The MusicKit Project
*/
// classgroup Filters
/*!
  @class OnepoleUG
  @brief <b>OnepoleUG </b>is a simple one-pole (recursive) filter, useful for low and high-pass filter.  
  
  

OnepoleUG is a one-pole filter that's implemented by subtracting the previous
output sample (initialized as 0.0) from the current input sample:
	
<i>output</i>  = (<i>b0 * input</i>) - (<i>a1 * previousOutput</i>)

<i>previousOutput</i> = <i>output</i>

Note that the two samples have their own scalers:  

<ul>
<li><i>b0</i>, the filter's gain, scales the input sample.  Effective gain
values are between 0.0 and 1.0 (a negative gain is the same as its absolute
value, but with a 180 degree phase shift).
</li>

<li><i>a1</i>, the filter's coefficient<i>,</i> scales the previous output
sample.  If <i>a1</i> is less than 0.0, the OnepoleUG is a low-pass filter; if
it's greater than 0.0, the object is a high-pass filter.  For stability, the
value of <i>a1</i> should be between -1.0 and 1.0 (non-inclusive).
</li>
</ul>

Similar to the OnepoleUG is the OnezeroUG; it, too, is either a low-pass or a
high-pass filter, but the frequency roll-off is gentler than with a OnepoleUG.  
You should also note that the high-pass/low-pass determination with regard to
the sign of the coefficent is switched in the OnezeroUG.

<h2>Memory Spaces</h2>

<b>OnepoleUG<i>ab</i></b>
<i>a</i>	output
<i>b</i>	input 
*/
#ifndef __MK_OnepoleUG_H___
#define __MK_OnepoleUG_H___

#import <MusicKit/MKUnitGenerator.h>

@interface OnepoleUG : MKUnitGenerator

/*!
  @param  aPatchPoint is an id.
  @return Returns an id.
  @brief Sets the input patchpoint to <i>aPatchPoint</i>.

  Returns <b>nil</b>
  if the argument isn't a patchpoint; otherwise returns
  <b>self</b>.
*/
-setInput: (id) aPatchPoint;
/* Sets filter input. */


/*!
  @param  aPatchPoint is an id.
  @return Returns an id.
  @brief Sets the output patchpoint to <i>aPatchPoint</i>.

  Returns
  <b>nil</b> if the argument isn't a patchpoint; otherwise returns
  <b>self</b>.
*/
-setOutput: (id) aPatchPoint;
/* Sets filter output. */

/*!
  @param  value is a double.
  @return Returns <b>self</b>.
  @brief Sets the filter's gain.

  Effective gain values are between 0.0 and
  1.0 (a negative gain is the same as its absolute value, but with a
  180 degree phase shift).  
*/
-setB0:(double) value;
/* Sets gain of filter. */


/*!
  @param  value is a double.
  @return Returns <b>self</b>.
  @brief Sets the filter's coefficient.

  If <i>value</i> is less than 0.0,
  the OnepoleUG is a low-pass filter; if it's greater than 0.0, the
  object is a high-pass filter.  For stability, the <i>value</i>
  should be between -1.0 and 1.0.  
*/
-setA1:(double)value;
/* Sets gain of delayed output sample. */

/*!
  @param arg is an unsigned.
  @return Returns an BOOL.
  @brief Specifies that all arguments are to be optimized if possible
  except the filter state.

  
*/
+(BOOL)shouldOptimize:(unsigned) arg;

/*!
  @return Returns <b>self</b>.
  @brief Clears the filter by setting the delayed sample (the previous output
  sample) to 0.0.

  
*/
-clear;
/* Clears internal filter running term. */

/*!
  @param  val is a double.
  @return Returns an id.
  @brief Sets internal filter running term.

  
*/
-setState:(double)val;

/*!
  @brief This is a convenient method that adjusts the filter's gain and
  coefficient such that a constant <i>brightness</i> value produces
  the same number and relative amplitudes of a tone's harmonics
  regardless of the value of <i>frequency</i> as described
  in Jaffe/Smith, Computer Music Journal Vol. 7, No. 2, Summer 1983.
 
  For example, in a
  musical phrase during which the brightness of the synthesized notes
  shouldn't be perceived to change, you would invoke this method once
  per note passing a constant <i>brightness</i> value (the
  successive <i>frequency</i> values would, of course, be determined
  by the pitches of the notes).  
 @param  brightness is a double specifying the gain.
 @param  frequency is a double.
 @return Returns <b>self</b>.
 */
- setBrightness: (double) brightness forFreq: (double) frequency;
/* You specify the gain at the specified fundamental frequency and the 
   appropriate filter frequency response is selected for you. By keeping
   the gain constant and varying the frequency, you can have a uniform
   amplitude and brightness percept (i.e. a "dynamic level").  

   Note that setting the brightness does not clear the filter state variable.
   You may want to do this in some cases.
*/

@end

#endif
