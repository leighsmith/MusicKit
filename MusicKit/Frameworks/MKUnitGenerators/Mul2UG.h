/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    Mul2UG  - from dsp macro /usr/lib/dsp/ugsrc/mul2.asm (see source for details).

   Outputs the product of two input signals. 
   
   You allocate one of the subclasses Mul2UG<a><b><c>, where <a> is the output 
   space, <b> is the space of the first input and <c> is the space of the
   second input. 

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Patchpoint Arithmetic
/*!
  @class Mul2UG
  @abstract <b>Mul2UG </b>multiplies two patchpoints.
  @discussion

Mul2UG multiplies two signals:
	
<i>output</i> = <i>input1</i> * <i>input2</i>

<h2>Memory Spaces</h2>

<b>Mul2UG<i>abc</i></b>
<i>a</i>	output
<i>b</i>	input1
<i>c</i>	input2
*/
#ifndef __MK_Mul2UG_H___
#define __MK_Mul2UG_H___

#import <MusicKit/MKUnitGenerator.h>
@interface Mul2UG:MKUnitGenerator

/*!
  @method shouldOptimize:
  @param arg is an unsigned.
  @result Returns an BOOL.
  @discussion Specifies that all arguments are to be optimized if possible.
*/
+(BOOL)shouldOptimize:(unsigned) arg;

/*!
  @method setInput1:
  @param  aPatchpoint is an id.
  @result Returns an id.
  @discussion Sets the input 1 patchpoint to <i>aPatchpoint</i>.  Returns
              <b>nil</b> if the argument isn't a patchpoint; otherwise returns
              <b>self</b>.
*/
-setInput1:aPatchPoint;
/* Sets input1 to specified patchPoint. */


/*!
  @method setInput2:
  @param  aPatchpoint is an id.
  @result Returns an id.
  @discussion Sets the input 2 patchpoint to <i>aPatchpoint</i>.  Returns
              <b>nil</b> if the argument isn't a patchpoint; otherwise returns
              <b>self</b>.
*/
-setInput2:aPatchPoint;
/* Sets input2 to specified patchPoint. */


/*!
  @method setOutput:
  @param  aPatchpoint is an id.
  @result Returns an id.
  @discussion Sets the output patchpoint to <i>aPatchpoint</i>.  Returns
              <b>nil</b> if the argument isn't a patchpoint; otherwise returns
              <b>self</b>.
*/
-setOutput:aPatchPoint;
/* Sets output to specified patchPoint. */


/*!
  @method idleSelf
  @result Returns an id.
  @discussion You never send this message.  It's invoked by sending the
              <b>idle</b> message to the object.  
              Sets the output patchpoint to <i>sink</i>, thus ensuring that
              the object does not produce any output.  Note that you must send
              <b>setOutput:</b> and <b>run</b> again to use the MKUnitGenerator after sending <b>idle</b>.
*/
-idleSelf;
/* Sets output to sink. */

@end

#endif
