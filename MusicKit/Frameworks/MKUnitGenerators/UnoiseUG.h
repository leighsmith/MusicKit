/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    UnoiseUG - from dsp macro /usr/lib/dsp/ugsrc/unoise.asm (see source for details).

  You instantiate a subclass of the form UnoiseUG<a>, where 
  <a> = space of output.

  UnoiseUG computes uniform pseudo-white noise using the linear congruential 
  method for random number generation (reference: Knuth, volume II of The Art 
  of Computer Programming).

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Oscillators and Waveform Generators
/*!
  @class UnoiseUG
  @abstract <b>UnoiseUG</b> produces white noise at the sampling rate.
  @discussion

UnoiseUG produces a series of random values within the range
	
0.0 &lt;= <i>f</i> &lt; 1.0

A new random value is generated every sample.  A similar class, SnoiseUG,
produce a new random value every tick.

<h2>Memory Spaces</h2>

<b>UnoiseUG<i>a</i></b>
<i>a</i>	output 
*/
#ifndef __MK_UnoiseUG_H___
#define __MK_UnoiseUG_H___

#import <MusicKit/MKUnitGenerator.h>

@interface UnoiseUG: MKUnitGenerator

/*!
  @method idleSelf
  @result Returns an id.
  @discussion You never send this message.  It's invoked by sending the
              <b>idle</b> message to the object.  
              Sets the output patchpoint to <i>sink</i>, thus ensuring that
              the object does not produce any output.  Note that you must send
              <b>setOutput:</b> and <b>run</b> again to use the MKUnitGenerator
              after sending <b>idle</b>.
*/
-idleSelf;
/* Sets output to sink. */

/*!
  @method shouldOptimize:
  @param arg is an unsigned.
  @result Returns an BOOL.
  @discussion Specifies that all arguments are to be optimized if possible except seed.
*/
+(BOOL)shouldOptimize:(unsigned) arg;

/*!
  @method setSeed:
  @param  (DSPDatum)seed is an id.
  @result Returns <b>self</b>.
  @discussion Sets the seed that's used to prime the random number generator.  To
              create a unique series of random numbers, you should set the seed
              itself to a randomly generated number.  
*/
-setSeed:(DSPDatum)seedVal;
/* Sets seed of random sequence. This is the current value and thus is changed
   by the unit generator itself. */


/*!
  @method setOutput:
  @param  aPatchpoint is an id.
  @result Returns an id.
  @discussion Sets the output patchpoint to <i>aPatchpoint</i>.  Returns
              <b>nil</b> if the argument isn't a patchpoint; otherwise returns
              <b>self</b>.
*/
-setOutput:aPatchPoint;
/* Sets output as specified. */

@end

#endif
