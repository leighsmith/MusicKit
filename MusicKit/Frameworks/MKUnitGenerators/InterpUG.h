/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    InterpUG  - from dsp macro /usr/lib/dsp/ugsrc/interp.asm (see source for details).

   Outputs an interpolation of two input signals, with the blend controlled 
   by a third signal, i.e.,   

       out = input1 + (input2-input1) * control
   
   You allocate one of the subclasses InterpUG<a><b><c><d>, where <a> is the output 
   space, <b> and <c> are the input signal spaces, and <d> is the space of the 
   interpolation control signal.
   This unit generator is 25% faster if <b> is x and <c> is y.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Table Lookup
/*!
  @class InterpUG
  @brief <b>InterpUG</b> does linear interpolation between two patchpoints, based on the value
  of a third patchpoint.
  
  

InterpUG provides dynamic linear interpolation between two input signals, where
the interpolation is controlled by a third input signal:
	
<i>output</i> = <i>input1</i> + ((<i>input2</i> - <i>input1</i>) * <i>input3</i>)

When the value of <i>input3</i> is 0.0, the output of InterpUG is exactly the
signal found at <i>input1.</i>  When <i>input3</i> is 1.0, the output is
exactly<i> input2.</i>  An AsympUG is often used to produce the control signal.


<h2>Memory Spaces</h2>

<b>InterpUG<i>abcd</i></b>
<i>a</i>	output
<i>b</i>	input1
<i>c</i>	input2
<i>d</i>	input3 (interpolation control)
*/
#ifndef __MK_InterpUG_H___
#define __MK_InterpUG_H___

#import <MusicKit/MKUnitGenerator.h>
@interface InterpUG:MKUnitGenerator

/*!
  @param arg is an unsigned.
  @return Returns an BOOL.
  @brief Specifies that all arguments are to be optimized if possible.

  
*/
+(BOOL)shouldOptimize:(unsigned) arg;

/*!
  @param  aPatchpoint is an id.
  @return Returns an id.
  @brief Sets the input 1 patchpoint to <i>aPatchpoint</i>.

  Returns
  <b>nil</b> if the argument isn't a patchpoint; otherwise returns
  <b>self</b>.
*/
-setInput1:aPatchPoint;
/* Sets input1 of interpolator. */


/*!
  @param  aPatchpoint is an id.
  @return Returns an id.
  @brief Sets the input 2 patchpoint to <i>aPatchpoint</i>.

  Returns
  <b>nil</b> if the argument isn't a patchpoint; otherwise returns
  <b>self</b>.
*/
-setInput2:aPatchPoint;
/* Sets input2 of interpolator. */


/*!
  @param  aPatchpoint is an id.
  @return Returns an id.
  @brief Sets the interp input patchpoint to <i>aPatchpoint</i>.

  The signal
  from this input controls the interpolation between the other two
  input signals.  Returns <b>nil</b> if the argument isn't a
  patchpoint; otherwise returns <b>self</b>.
*/
-setInterpInput:aPatchPoint;
/* Sets interpolation signal of interpolator. */


/*!
  @param  aPatchpoint is an id.
  @return Returns an id.
  @brief Sets the output patchpoint to <i>aPatchpoint</i>.

  Returns
  <b>nil</b> if the argument isn't a patchpoint; otherwise returns
  <b>self</b>.
*/
-setOutput:aPatchPoint;
/* Sets output of adder. */

@end

#endif
