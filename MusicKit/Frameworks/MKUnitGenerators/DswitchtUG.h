/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    DswitchtUG  - from dsp macro /usr/lib/dsp/ugsrc/dswitcht.asm (see source for details).

  The DswitchtUG switches from input1 (scaled by scale1) to a 
  input2 (scaled by scale2) after a delay specified in samples.  The delay
  can be interpreted as the number of samples input1 is passed to 
  the output.  On each output sample, the delay is decremented by 1.
  Input1 times the scale factor scale1 is passed to the output as long 
  as delay remains nonnegative. Afterwards, input2 is passed 
  to the output with its own scaling.

  You instantiate a subclass of the form 
  DswitchtUG<a><b>, where 
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
  @class DswitchtUG
  @brief <b>DswitchtUG</b> is similar to <b>DswitchUG</b>, but its time is
  constrained to be a multiple of the tick size.
  
  

DswitchtUG reads a specified number of ticks from its first input signal and
then switches to read the its second input signal.  You can cause a DswitchtUG
to switch between its two inputs any number of times while its running.  The
input signals can be independently scaled.  The input patchpoints must be
allocated in the same memory space.  

A similar class, DswitchUG, switches on a sample boundary and doesn't allow
scaling on the second input.

<h2>Memory Spaces</h2>

<b>DswitchtUG<i>ab</i></b>
<i>a</i>	output
<i>b</i>	input1 and input2
*/
#ifndef __MK_DswitchtUG_H___
#define __MK_DswitchtUG_H___

#import <MusicKit/MKUnitGenerator.h>

@interface DswitchtUG : MKUnitGenerator

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
- setOutput: (id) aPatchPoint;

/*!
  @brief Sets the factor by which first input signal is scaled.
  @param  scale is a double.
  @return Returns <b>self</b>.
*/
- setScale1: (double) scale;

/*!
  @brief Sets the factor by which second input signal is scaled.
  @param  scale is a double.
  @return Returns <b>self</b>.
*/
- setScale2: (double) scale;

/*!
  @brief Immediately switches the DswitchtUG to its first input and causes it
  to switch to its second input after <i>count</i> ticks have been
  read.

  If <i>count</i> is less than or equal to zero, the switch to
  the second input is performed immediately.  If the object is
  currently reading from its first input because of a previous
  invocation of this method, the old <i>count</i> is superceded by the
  new one.
 @param  count is an int.
 @return Returns <b>self</b>.
*/
- setDelayTicks: (int) count;
/* Sets delay in ticks (units of DSPMK_NTICK). 
   A negative value will switch immediately to input2. */


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
/* Patches output to sink. */

@end

#endif
