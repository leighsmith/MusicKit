/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    Scl1add2UG. From dsp macro /usr/lib/dsp/ugsrc/scl1add2.asm (see source for details)

	You instantiate a subclass of the form Scl1add2UG<a><b><c>, where 
	<a> = space of output
	<b> = space of input1
	<c> = space of input2

      The scl1add2 unit-generator multiplies the first input by a
      scale factor, and adds it to the second input signal to produce a
      third.  The output vector can be the same as an input vector.
      Faster if space of input1 is not the same as the space of input2.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Patchpoint Arithmetic
/*!
  @class Scl1add2UG
  @brief <b>Scl1add2UG</b> multiplies the first input by a scale factor, and adds
  it to the second input patchpoint to produce a third.
  
  

Scl1add2UG adds two input signals, the first of which is scaled:
	
<i>output</i> = (<i>input1</i> * <i>scaler</i>) + <i>input2</i>

<h2>Memory Spaces</h2>

<b>Scl1add2UG<i>abc</i></b>
<i>a</i>	output 
<i>b</i>	input 1 (scaled input)
<i>c</i>	input 2 (unscaled input)
*/
#ifndef __MK_Scl1add2UG_H___
#define __MK_Scl1add2UG_H___

#import <MusicKit/MKUnitGenerator.h>
@interface Scl1add2UG:MKUnitGenerator

/*!
  @param  aPatchPoint is an id.
  @return Returns an id.
  @brief Sets the input 1 patchpoint to <i>aPatchPoint</i>.

  Returns
  <b>nil</b> if the argument isn't a patchpoint; otherwise returns
  <b>self</b>.
*/
-setInput1: (id) aPatchPoint;
/* Sets input1. This is the input that is scaled. */


/*!
  @param  aPatchPoint is an id.
  @return Returns an id.
  @brief Sets the input 2 patchpoint to <i>aPatchPoint</i>.

  Returns
  <b>nil</b> if the argument isn't a patchpoint; otherwise returns
  <b>self</b>.
*/
-setInput2: (id) aPatchPoint;
/* Sets input2. */


/*!
  @param  aPatchPoint is an id.
  @return Returns an id.
  @brief Sets the output patchpoint to <i>aPatchPoint</i>.

  Returns
  <b>nil</b> if the argument isn't a patchpoint; otherwise returns
  <b>self</b>.
*/
-setOutput: (id) aPatchPoint;
/* Sets output. */


/*!
  @brief Sets the constant scaler.

  Effective values are between 0.0 and 1.0
  (a negative scaler is the same as its absolute value, but with a 180
  degree phase shift).  
  @param  value is a double.
  @return Returns <b>self</b>.
*/
- setScale: (double) value;

/*!
  @param arg is an unsigned.
  @return Returns an BOOL.
  @brief Specifies that all arguments are to be optimized if possible.

  
*/
+(BOOL)shouldOptimize:(unsigned) arg;

/*!
  @return Returns an id.
  @brief You never send this message.

  It's invoked by sending the
  <b>idle</b> message to the object.  
  Sets the output patchpoint to <i>sink</i>,<i></i> thus ensuring that
  the object does not produce any output.  Note that you must send
  <b>setOutput:</b> and <b>run</b> again to use the MKUnitGenerator after sending <b>idle</b>.
*/
-idleSelf;
  /* Sets output to write to sink. */

@end

#endif
