/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    Mul1add2UG  - from dsp macro /usr/lib/dsp/ugsrc/mul1add2.asm (see source for details).

   Outputs the sum of one input signal and the product of two others, i.e,

       out = input1 + (input2 * input3)
   
   You allocate one of the subclasses Mul1add2UG<a><b><c><d>, where <a> is the output 
   space, and <b>, <c>, and <d> are the spaces of the inputs.

	The number of inner loop instructions is:
		spaces:			# instructions:
	    out  in1  in2  in3
	     y    x    y    x		2
	     *    *    y    x		3
	     y    x    *    *		3
		all others 		4

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Patchpoint Arithmetic
/*!
  @class Mul1add2UG
  @brief <b>Mul1add2UG</b> adds two patchpoints and multiplies the result by a third.  
  
  

Mul1add2UG adds one signal to the product of two others:
	
<i>output</i> =<i> input1</i> + (<i>input2</i> * <i>input3</i>)

<h2>Memory Spaces</h2>

<b>Mul1add2UG<i>abcd</i></b>
<i>a</i>	output
<i>b</i>	input1
<i>c</i>	input2
<i>d</i>	input3 
*/
#ifndef __MK_Mul1add2UG_H___
#define __MK_Mul1add2UG_H___

#import <MusicKit/MKUnitGenerator.h>

@interface Mul1add2UG: MKUnitGenerator

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
/* Sets input1 of adder. */


/*!
  @param  aPatchpoint is an id.
  @return Returns an id.
  @brief Sets the input 2 patchpoint to <i>aPatchpoint</i>.

  Returns
  <b>nil</b> if the argument isn't a patchpoint; otherwise returns
  <b>self</b>.
*/
-setInput2:aPatchPoint;
/* Sets input2 of adder. */


/*!
  @param  aPatchpoint is an id.
  @return Returns an id.
  @brief Sets the input 3 patchpoint to <i>aPatchpoint</i>.

  Returns
  <b>nil</b> if the argument isn't a patchpoint; otherwise returns
  <b>self</b>.
*/
-setInput3:aPatchPoint;
/* Sets input3 of adder. */


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
