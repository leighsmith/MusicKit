/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    DelayqpUG  - from dsp macro /usr/lib/dsp/ugsrc/delayqp.asm (see source for details).

	You instantiate a subclass of the form 
	DelayqpUG<a><b>, where 
	<a> = space of output
	<b> = space of input

	DelayqpUG is useful for flanging, reverberation, plucked string 
	synthesis, etc.

  Original Author: David A. Jaffe

  Copyright (c) 1993, CCRMA, Stanford University.  All rights reserved.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Delays and Time-Modification Units
/*!
  @class DelayqpUG
  @brief <b>DelayqpUG</b> is similar to <b>DelayUG</b>, but it uses the
  Ariel QuintProcessor's DRAM memory to produce the delay. 

  @brief

DelayqpUG may only be used on the hub (master) DSP of the Ariel QuintProcessor. 
It delays its input signal by some number of samples, using the dynamic RAM
(DRAM), before producing it at its output.  Each DelayqpUG maintains a single
pointer into the delay memory.  When the object is run, a tick's worth of
samples are read and replaced with an equal number of samples from the input
signal.  The pointer is then incremented by a tick.  When the pointer reaches
the end of the delay memory, it automatically jumps back to the beginning, even
if it's in the middle of a tick - in other words, the length of the delay memory
<i>needn't</i> be a multiple of the tick size.  The rate at which the pointer is
incremented can't be modified, nor can you offset the beginning of the delay
memory.  However, you can reposition the pointer to any arbitrary sample in the
delay memory through the <b>setPointer:</b> method.

DRAM requires periodic refreshing.  You can control whether this is "implicit"
(done by the mere accessing of the memory) or "automatic" (done by the Quint
Processor refresh hardware.)  The ArielQP method <b>setDRAMAutoRefresh:</b>controls the refresh mode. 

Currently there is no support for automatic allocation of DRAM.  That is, there
is no parallel to the automatic system provided for DSP SRAM.  The application
must keep track of allocation itself.  By convention, location 1 is used as a
"sink" location (a place to write garbage) and location 0 is a "zero" location
(a place that is guaranteed to always hold a zero, assuming nobody overwrites
it.)

The MusicKit does not automatically clear DRAM, with the exception of the
"zero" location.  If you want to clear a segment of DRAM, use a DelayqpUG, set
the input location to <b>[orchestra segmentZero: MK_xPatch]</b> (or
<b>MK_yPatch</b>), and let the DelayqpUG run for a while.  

<h2>Memory Spaces</h2>

<b>DelayqpUG<i>ab</i></b>
<i>a</i> output
<i>b</i> input
*/
#ifndef __MK_DelayqpUG_H___
#define __MK_DelayqpUG_H___

#import <MusicKit/MKUnitGenerator.h>

@interface DelayqpUG : MKUnitGenerator	
{
    int memAddr;
    int len; 
}

/*!
  @brief Specifies that all arguments are to be optimized if possible except the delay pointer.
  @param arg is an unsigned.
  @return Returns an BOOL.
*/
+ (BOOL) shouldOptimize: (unsigned) arg;

/*!
  @brief Sets the input patchpoint to <i>aPatchPoint</i>.
  @param  aPatchPoint is an id.
  @return Returns <b>nil</b> if the argument isn't a patchpoint; otherwise returns <b>self</b>.
*/
- setInput: (id) aPatchPoint;

/*!
  @brief Sets the output patchpoint to <i>aPatchPoint</i>.
  @param  aPatchPoint is an id.
  @return Returns <b>nil</b> if the argument isn't a patchpoint; otherwise returns <b>self</b>.
*/
-setOutput: (id) aPatchPoint;

/*!
  @brief Sets the address and length of the DRAM segment used as delay memory.

  Also sets the pointer to the start of the DRAM segment.  
  @param  address is a DSPDatum.
  @param  length is a DSPDatum.
  @return Returns <b>self</b>.
 */
- setDelayAddress: (DSPDatum) address length: (DSPDatum) length;

/*!
  @brief Sets the number of delayed samples to <i>newDelayLength</i>.
  @param  newDelayLength is an int.
  @return Returns an id.
*/
- adjustLength: (int) newDelayLength;

/*!
  @brief Repositions the pointer to point to the <i>n</i>'th sample in the
  DRAM segment used as delay memory, counting from sample 0.
  @param  offset is an int.
  @return Returns <b>self</b>.
*/
- setPointer: (int) offset;

/*!
  @brief Resets the pointer to the beginning of the DRAM segment used as
  delay memory.
  @return Returns <b>self</b>.
*/
- resetPointer;

/*!
  @brief Returns the number of samples delay.
  @return Returns an int.
*/
- (int) length;

- runSelf;

/*!
  @brief You never send this message.

  It's invoked by sending the <b>idle</b>message to the object.  
  Sets the output patchpoint to <i>sink</i>, thus ensuring that the object does not
  produce any output. Also, sets the DRAM delay memory segment to DRAM's <i>sink</i>
  (location 0) and the length to 1, so that the object.  Note that you must send
  <b>setOutput:</b> and <b>run</b> again to use the MKUnitGenerator after sending
  <b>idle</b>.
  @return Returns an id.
*/
- idleSelf;
/* Patches output and delay memory to sink. */

@end

#endif
