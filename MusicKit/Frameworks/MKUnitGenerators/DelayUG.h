/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    DelayUG  - from dsp macro /usr/lib/dsp/ugsrc/delay.asm (see source for details).

	You instantiate a subclass of the form 
	DelayUG<a><b><c>, where 
	<a> = space of output
	<b> = space of input
	<c> = space of delay line

	DelayUG is useful for flanging, reverberation, plucked string 
	synthesis, etc.
 

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Delays and Time-Modification Units
/*!
  @class DelayUG
  @abstract <b>DelayUG</b> delays its input patchpoint signal by some
            amount, then writes it to its output patchpoint.  
  @discussion

DelayUG and DelaymUG both delay their input signal by some number of samples
before producing it at its output.  They require a SynthData object to store the
delayed signal.  They differ in that DelayUG will accept any SynthData object,
while DelaymUG requires a SynthData object allocated as "moduls", using the
Orchestra method <b>allocModulsSynthData:.</b> DelaymUG is much more
computationally efficient than DelaymUG.

Each DelayUG maintains a single pointer into the delay memory.  When the object
is run, a tick's worth of samples are read and replaced with an equal number of
samples from the input signal.  The pointer is then incremented by a tick.  When
the pointer reaches the end of the delay memory, it automatically jumps back to
the beginning, even if it's in the middle of a tick - in other words, the length
of the delay memory <i>needn't</i> be a multiple of the tick size.  The rate at
which the pointer is incremented can't be modified, nor can you offset the
beginning of the delay memory.  However, you can reposition the pointer to any
arbitrary sample in the delay memory through the <b>setPointer:</b>
method.

<h2>Memory Spaces</h2>

<b>DelayUG<i>abc</i></b>
<i>a</i>	output
<i>b</i>	input
<i>c</i>	delay memory
*/
#ifndef __MK_DelayUG_H___
#define __MK_DelayUG_H___

#import <MusicKit/MKUnitGenerator.h>

@interface DelayUG : MKUnitGenerator
{
    id memObj;      /* Delay memory */
    int len;        /* Currently used length (must be <= length of memObj) */
}

/*!
  @method shouldOptimize:
  @param arg is an unsigned.
  @result Returns an BOOL.
  @discussion Specifies that all arguments are to be optimized if possible except the
              delay pointer.
*/
+(BOOL)shouldOptimize:(unsigned) arg;
/* Specifies that all arguments are to be optimized if possible except the
   delay pointer. */


/*!
  @method setInput:
  @param  aPatchpoint is an id.
  @result Returns an id.
  @discussion Sets the input patchpoint to <i>aPatchpoint</i>.  Returns <b>nil</b>
              if the argument isn't a patchpoint; otherwise returns
              <b>self</b>.
*/
-setInput:aPatchPoint;
/* Sets input patchpoint as specified. */

/*!
  @method setOutput:
  @param  aPatchpoint is an id.
  @result Returns an id.
  @discussion Sets the output patchpoint to <i>aPatchpoint</i>.   Returns
              <b>nil</b> if the argument isn't a patchpoint; otherwise returns
              <b>self</b>.
*/
-setOutput:aPatchPoint;
/* Sets output patchpoint as specified. */


/*!
  @method setDelayMemory:
  @param  aSynthData is an id.
  @result Returns <b>self</b>.
  @discussion Sets the SynthData object used as the delay memory to
              <i>aSynthData</i>.  The length of the SynthData must be greater than
              or equal to the amount of delay (in samples) that's desired.  If
              <i>aSynthData</i> is <b>nil</b>, the delay memory is set to the sink
              location.  For DelaymUG, <i>aSynthData</i> must be allocated as
              "modulus" memory. 
*/
-setDelayMemory:aSynthData;
/* Sets the delay memory to aSynthData.
   If you pass nil, uses sink as the delay memory. It is up to the caller
   to insure the memory is cleared. */


/*!
  @method adjustLength:
  @param  (int)delayLength is an id.
  @result Returns an id.
  @discussion Sets the number of delayed samples to <i>delayLength</i>.  The
              argument must be no greater than the length of the SynthData object
              that's used as the delay memory.  Returns <b>nil
              </b>if<b></b><i>delayLength</i>  is too great or if the delay memory
              hasn't been set<b>;</b>otherwise returns<b> self</b>. 
              
*/
-adjustLength:(int)newLength;
/* If no setDelayMemory: message has been received, returns nil.
   Otherwise, adjusts the delay length as indicated. newLength
   must be <= the length of the block of memory specified
   in setDelayMemory:. Otherwise, nil is returned. Note
   that the unused memory in the memory specified in 
   setDelayMemory: is not freed. Resetting the
   length of a running Delay may cause the pointer to go out-of-bounds.
   Therefore, it is prudent to send setPointer: or resetPointer after
   adjustLength:. Also note that when lengthening the delay, you 
   will be bringing in old delayed samples. Therefore, you may
   want to clear the new portion by sending the memory object the
   message -setToConstant:length:offset:. */


/*!
  @method setPointer:
  @param  (int)n is an id.
  @result Returns an id.
  @discussion Repositions the pointer to point to the <i>n</i>'th sample in the
              delay memory, counting from sample 0.  Returns  <b>nil</b> if
              <i>n</i> is greater than the current length of the delay, or if the
              delay memory hasn't been set; otherwise returns <b>self</b>.
*/
-setPointer:(int)offset;
/* If no setDelayMemory: message has been received, returns nil.
   Else sets pointer to specified offset. E.g. if offset == 0,
   this is the same as resetPointer. If offset is GEQ the length
   of the memory block, returns nil. */


/*!
  @method resetPointer
  @result Returns an id.
  @discussion Resets the pointer to the beginning of the delay memory.   Returns
              <b>nil</b> if the SynthData hasn't been set; otherwise returns
              <b>self</b>.
*/
-resetPointer;
/* If no setDelayMemory: message has been received, returns nil.
   Else sets pointer to start of memory. This is done automatically
   when setDelayMemory: is sent. */


/*!
  @method length
  @result Returns an int.
  @discussion Returns the number of samples in the delay memory.  Note that this
              is the length that's currently being used; it isn't necessarily the
              same as the length of the SynthData that's being used as the delay
              memory.
*/
-(int)length;
/* Returns the length of the delay currently in use. This is always <= than the
   length of the memory object. */

-runSelf;
/* Does nothing. */

/*!
  @method idleSelf
  @result Returns an id.
  @discussion You never send this message.  It's invoked by sending the
              <b>idle</b> message to the object.  
              Sets the output patchpoint, as well as the delay memory, to <i>sink</i>,<i> </i>thus ensuring that the object does not produce any output.  Note that you must send <b>setOutput:</b> and <b>run</b> again to use the MKUnitGenerator after sending <b>idle</b>.
*/
-idleSelf;
/* Patches output and delay memory to sink. */


@end

#endif
