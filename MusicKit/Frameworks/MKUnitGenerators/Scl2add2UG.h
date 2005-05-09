/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    Scl2add2UG. From dsp macro /usr/lib/dsp/ugsrc/scl2add2.asm (see source for details).

	You instantiate a subclass of the form Scl2add2UG<a><b><c>, where 
	<a> = space of output
	<b> = space of input1
	<c> = space of input2

      The scl2add2 unit-generator multiplies two input signals
      times constant scalers then adds them together to produce a
      third.  The output vector can be the same as an input vector.
      Inner loop is two instructions if space of input1 is "x" and
      space of input2 is "y", otherwise three instructions.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Patchpoint Arithmetic
/*!
  @class Scl2add2UG
  @brief <b>Scale2add2</b> multiplies two input patchpoints times
  scalers then adds them together.
  
  

Scl2add2UG adds two input signals, both of which are scaled:
	
<i>output</i> = (<i>input1</i> * <i>scaler1</i>) + (<i>input2</i> * <i>scaler2</i>)

<h2>Memory Spaces</h2>

<b>Scl2add2UG<i>abc</i></b>
<i>a</i>	output 
<i>b</i>	input 1
<i>c</i>	input 2 
*/
#ifndef __MK_Scl2add2UG_H___
#define __MK_Scl2add2UG_H___

#import <MusicKit/MKUnitGenerator.h>
@interface Scl2add2UG:MKUnitGenerator


/*!
  @param  aPatchpoint is an id.
  @return Returns an id.
  @brief Sets the input 1 patchpoint to <i>aPatchpoint</i>.

  Returns
  <b>nil</b> if the argument isn't a patchpoint; otherwise returns
  <b>self</b>.
*/
-setInput1:aPatchPoint;
/* Sets input1. This is the input that is scaled. */


/*!
  @param  aPatchpoint is an id.
  @return Returns an id.
  @brief Sets the input 2 patchpoint to <i>aPatchpoint</i>.

  Returns
  <b>nil</b> if the argument isn't a patchpoint; otherwise returns
  <b>self</b>.
*/
-setInput2:aPatchPoint;
/* Sets input2. */


/*!
  @param  aPatchpoint is an id.
  @return Returns an id.
  @brief Sets the output patchpoint to <i>aPatchpoint</i>.

  Returns
  <b>nil</b> if the argument isn't a patchpoint; otherwise returns
  <b>self</b>.
*/
-setOutput:aPatchPoint;
/* Sets output. */


/*!
  @param  (double)value is an id.
  @return Returns <b>self</b>.
  @brief Sets the scaler on the first input.

  Effective values are between 0.0
  and 1.0 (a negative scaler is the same as its absolute value, but
  with a 180 degree phase shift).  
*/
-setScale1:(double)val;
/* Sets scaling on input1. */


/*!
  @param  (double)value is an id.
  @return Returns <b>self</b>.
  @brief Sets the scaler on the second input.

  Effective values are between
  0.0 and 1.0 (a negative scaler is the same as its absolute value,
  but with a 180 degree phase shift).  
*/
-setScale2:(double)val;
/* Sets scaling on input2. */

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
  Sets the output patchpoint to <i>sink</i>, thus ensuring that
  the object does not produce any output.  Note that you must send
  <b>setOutput:</b> and <b>run</b> again to use the MKUnitGenerator
  after sending <b>idle</b>.
*/
-idleSelf;
  /* Sets output to write to sink. */

@end

#endif
