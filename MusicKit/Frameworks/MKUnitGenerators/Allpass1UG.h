/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    Allpass1UG  - from dsp macro /usr/lib/dsp/ugsrc/allpass1.asm. (see source for details)

   First order all pass filter.
	
   You allocate a subclass of the form Allpass1UG<a><b>, where 
   <a> = space of output and <b> = space of input.

   The allpass1 unit-generator implements a one-pole, one-zero
   allpass filter section in direct form. 

   The transfer function implemented is

		bb0 + 1/z
	H(z) =	---------
		1 + bb0/z

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Filters
/*!
  @class Allpass1UG
  @abstract <b>Allpass1UG</b> is a first-order all-pass filter, useful for phase
            modifications.
  @discussion

Allpass1UG is a one-pole, one-zero filter.  The value of the filter coefficient
is set directly.  The filter's transfer function is given as
	
                      bb0 + 1/z	
	      H(z) =  ---------	
	              1 + bb0/z

where bb0 is the filter coefficient.   Thus, the pole is at -bb0 and the zero is
at -1/bb0.  The difference equation used to implement the filter in the DSP
is
	
		y(n) = bb0 * x(n) + x(n-1) - bb0 * y(n-1); 

where x(n) denotes the input signal at time n, and y(n) is the output signal. 
This is the so-called &ldquo;direct-form-1&rdquo; digital filter structure.  It
has the property that the filter can only overflow if the output overflows.  (In
other words, <i>internal</i> overflow is not possible.)  For stability, bb0 must
lie between -1.0 and 1.0.

<h2>Optimization</h2>

Allpass1UG is fastest if the input memory space is x in which case three
inner-loop instructions are required.  Otherwise, four inner-loop instructions
are used.

<h2>Memory Spaces</h2>

<b>Allpass1UG<i>ab</i></b>
<i>a</i>	output
<i>b</i>	input 
*/
#ifndef __MK_Allpass1UG_H___
#define __MK_Allpass1UG_H___

#import <MusicKit/MKUnitGenerator.h>
@interface Allpass1UG: MKUnitGenerator

/*!
  @method shouldOptimize:
  @param arg is an unsigned.
  @result Returns an BOOL.
  @discussion Specifies that all arguments are to be optimized if possible except the
              state variable.
*/
+(BOOL)shouldOptimize:(unsigned) arg;

/*!
  @method setInput:
  @param  aPatchpoint is an id.
  @result Returns an id.
  @discussion Sets the input patchpoint to <i>aPatchpoint</i>.  Returns
              <b>self</b>, or <b>nil</b> if the argument isn't a
              patchpoint.
*/
-setInput:aPatchPoint;
/* Sets input of filter. */

/*!
  @method setOutput:
  @param  aPatchpoint is an id.
  @result Returns an id.
  @discussion Sets the output patchpoint to <i>aPatchpoint</i>.  Returns
              <b>self</b>, or <b>nil</b> if the argument isn't a
              patchpoint.
*/
-setOutput:aPatchPoint;
/* Sets output of filter. */

/*!
  @method setBB0:
  @param  (double)bb0 is an id.
  @result Returns <b>self</b>.
  @discussion Sets the filter coefficient to <i>bb0</i>.  For stability, the
              coefficient should be within the bounds
              	
              -1.0 &lt; <i>bb0</i> &lt; 1.0
*/
-setBB0:(double)val;
/* Sets BB0 coefficient in equation above. */

/*!
  @method clear
  @result Returns <b>self</b>.
  @discussion Clears filter memory, i.e., sets the value of the two state
              variables (used for x(n-1) and y(n-1)) to 0.0.  
*/
-clear;
/* Clears filter state variable. */

/*!
  @method delayAtFreq:
  @param  hzVal is a double.
  @result Returns a double.
  @discussion Returns filter delay at given frequency.
*/
-(double)delayAtFreq:(double)hzVal;

@end

#endif
