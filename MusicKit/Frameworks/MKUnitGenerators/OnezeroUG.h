/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    OnezeroUG  - from dsp macro /usr/lib/dsp/ugsrc/onezero.asm (see source for details).

   You instantiate a subclass of the form OnezeroUG<a><b>, where 
   <a> = space of output and <b> = space of input.

   The onezero unit-generator implements a one-zero
   filter section in direct form.  For best performance,
   the input and output signals should be in separate
   memory spaces x or y.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Filters
/*!
  @class OnezeroUG
  @brief <b>OnezeroUG</b> is a one-zero (FIR) fiter useful for mild low and high-pass filtering.
  
  

OnezeroUG is a one-zero filter that's implemented by adding the previous input
sample (initialized as 0.0) to the current input sample:
	
<i>output</i>  = (<i>b0 * input</i>) + (<i>b1 * previousInput</i>)

<i>previousInput</i> = <i>input</i>

Note that the two samples have their own scalers:  

<ul>
<li><i>b0</i> scales the input sample; this is the gain of the filter. 
Effective gain values are between 0.0 and 1.0 (a negative gain is the same as
its absolute value, but with a 180 degree phase shift).
</li>

<li><i>b1</i> scales the previous input sample.  This is the filter's
coefficient:  If <i>b1</i> is less than 0.0, the OnezeroUG is a high-pass
filter; if it's greater than 0.0, the object is a low-pass filter.  For
stability, the value of <i>b1</i> should be between -1.0 and 1.0
(non-inclusive).
</li>
</ul>

Similar to the OnezeroUG is the OnepoleUG; it, too, is either a low-pass or a
high-pass filter, but the frequency roll-off is steeper than with a OnezeroUG. 
You should also note that the high-pass/low-pass determination with regard to
the sign of the coefficent is switched in the OnepoleUG.

<h2>Memory Spaces</h2>

<b>OnezeroUG<i>ab</i></b>
<i>a</i>	output
<i>b</i>	input 
*/
#ifndef __MK_OnezeroUG_H___
#define __MK_OnezeroUG_H___

#import <MusicKit/MKUnitGenerator.h>

@interface OnezeroUG: MKUnitGenerator

/*!
  @param  aPatchpoint is an id.
  @return Returns an id.
  @brief Sets the input patchpoint to <i>aPatchpoint</i>.

  Returns <b>nil</b>
  if the argument isn't a patchpoint; otherwise returns
  <b>self</b>.
*/
-setInput:aPatchPoint;
/* Sets filter input. */


/*!
  @param  aPatchpoint is an id.
  @return Returns an id.
  @brief Sets the output patchpoint to <i>aPatchpoint</i>.

  Returns
  <b>nil</b> if the argument isn't a patchpoint; otherwise returns
  <b>self</b>.
*/
-setOutput:aPatchPoint;
/* Sets filter output. */


/*!
  @param  value is a double.
  @return Returns <b>self</b>.
  @brief Sets the filter's gain.

  Effective gain values are between 0.0 and
  1.0 (a negative gain is the same as its absolute value, but with a
  180 degree phase shift).  
*/
-setB0:(double)value;
/* Sets gain of filter. */


/*!
  @param  value is a double.
  @return Returns <b>self</b>.
  @brief Sets the filter's coefficient.

  If <i>value</i> is less than 0.0,
  the OnezeroUG is a high-pass filter; if it's greater than 0.0, the
  object is a low-pass filter. For stability, the <i>value</i> should
  be between -1.0 and 1.0.  
*/
-setB1:(double)value;
/* Sets coefficient of once-delayed input sample. */

/*!
  @param arg is an unsigned.
  @return Returns an BOOL.
  @brief Specifies that all arguments are to be optimized if possible
  except the filter state.

  
*/
+(BOOL)shouldOptimize:(unsigned) arg;

/*!
  @return Returns <b>self</b>.
  @brief Clears the filter by setting the delayed sample (the previous input
  sample) to 0.0.

  
*/
-clear;
/* Clears filter's state variable. */

@end

#endif
