/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    DswitchUG  - from dsp macro /usr/lib/dsp/ugsrc/dswitch.asm (see source for details).

  The DswitchUG switches from input1 (scaled) to a 
  input2 (unscaled) after a delay specified in samples.  The delay
  can be interpreted as the number of samples input1 is passed to 
  the output.  On each output sample, the delay is decremented by 1.
  Input1 times the scale factor scale1 is passed to the output as long 
  as delay remains nonnegative. Afterwards, input2 is passed 
  to the output with no scaling.

  You instantiate a subclass of the form 
  DswitchUG<a><b>, where 
	<a> = space of output	
	<b> = space of inputs 

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Delays and Time-Modification Units
/*!
  @class DswitchUG
  @brief <b>DswitchUG</b> switches between two inputs after a certain amount of time.
  
  

DswitchUG reads a specified number of samples from its first input signal and
then switches to read its second input signal.  You can cause a DswitchUG to
switch between its two inputs any number of times while its running.  A scaler
on the first input signal is provided.  The input patchpoints must be allocated
in the same memory space.  

A similar class, DswitchtUG, allows scaling on both signals but restricts the
timing of the switch to a tick boundary.

<h2>Memory Spaces</h2>

<b>DswitchUG<i>ab</i></b>
<i>a</i>	output
<i>b</i>	input1 and input2
*/
#ifndef __MK_DswitchUG_H___
#define __MK_DswitchUG_H___

#import <MusicKit/MKUnitGenerator.h>

@interface DswitchUG : MKUnitGenerator

/*!
  @param arg is an unsigned.
  @return Returns an BOOL.
  @brief Specifies that all arguments are to be optimized if possible except the
  delay counter.

  
*/
+(BOOL)shouldOptimize:(unsigned) arg;
/* Specifies that all arguments are to be optimized if possible except the
   delay counter. */

/*!
  @param  aPatchPoint is an id.
  @return Returns an id.
  @brief Sets the input 1 patchpoint to <i>aPatchPoint</i>.

  Returns
  <b>nil</b> if the argument isn't a patchpoint; otherwise returns
  <b>self</b>.
*/
-setInput1: (id) aPatchPoint;
/* Sets input1 to specified patchPoint. */


/*!
  @param  aPatchPoint is an id.
  @return Returns an id.
  @brief Sets the input 2 patchpoint to <i>aPatchPoint</i>.

  Returns
  <b>nil</b> if the argument isn't a patchpoint; otherwise returns
  <b>self</b>.
*/
-setInput2: (id) aPatchPoint;
/* Sets input2 to specified patchPoint. */


/*!
  @param  aPatchPoint is an id.
  @return Returns an id.
  @brief Sets the output patchpoint to <i>aPatchPoint</i>.

  Returns
  <b>nil</b> if the argument isn't a patchpoint; otherwise returns
  <b>self</b>.
*/
-setOutput: (id) aPatchPoint;
/* Sets output to specified patchPoint. */


/*!
  @brief Sets the factor by which first input signal is scaled.
  @param scale is a double.
  @return Returns <b>self</b>.
*/
- setScale1: (double) scale;

/*!
  @brief Immediately switches the DswitchUG to its first input and causes it
  to switch to its second input after <i>count</i> samples have been
  read.

  If <i>count</i> is less than or equal to zero, the switch to
  the second input is performed immediately.  If the object is
  currently reading from its first input because of a previous
  invocation of this method, the old <i>count</i> is superceded by the
  new one.
  @param count is an int. A negative value will switch immediately to input2.
  @return Returns <b>self</b>.
*/
- setDelaySamples: (int) count;

/*!
  @return Returns an id.
  @brief You never send this message.

  It's invoked by sending the
  <b>idle</b> message to the object.  
  Sets the output patchpoint to <i>sink</i>, thus ensuring that the object
  does not produce any output.  Note that you must send <b>setOutput:</b>
  and <b>run</b> again to use the MKUnitGenerator after sending <b>idle</b>.
*/
-idleSelf;
/* Patches output to sink. */

@end

#endif
