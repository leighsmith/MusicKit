/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    SnoiseUG - from dsp macro /usr/lib/dsp/ugsrc/snoise.asm (see source for details).

    You instantiate a subclass of the form SnoiseUG<a>, where 
    <a> = space of output.

    SnoiseUG computes uniform pseudo-white noise using the linear congruential 
    method for random number generation (reference: Knuth, volume II of The Art 
    of Computer Programming).   Whereas UnoiseUG computes a new random value
    every sample, SnoiseUG computes a new random value every tick (16 samples),
    and is 3 times faster.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Oscillators and Waveform Generators
/*!
  @class SnoiseUG
  @abstract <b>SnoiseUG</b> produces sample-and-hold noise at the tick rate.
  @discussion

SnoiseUG produces a series of random values within the range
	
-1.0 &lt;= <i>f</i> &lt; 1.0

A new random value is generated once per tick.  A similar class, UnoiseUG,
produces a new random value every sample.

<h2>Memory Spaces</h2>

<b>SnoiseUG<i>a</i></b>
<i>a</i>	output 
*/
#ifndef __MK_SnoiseUG_H___
#define __MK_SnoiseUG_H___

#import <MusicKit/MKUnitGenerator.h>

@interface SnoiseUG: MKUnitGenerator

/*!
  @method idleSelf
  @result Returns an id.
  @discussion You never send this message.  It's invoked by sending the
              <b>idle</b> message to the object.  
              Sets the output patchpoint to <i>sink</i>, thus ensuring that the
              object does not produce any output.  Note that you must send
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
  @discussion Sets the seed that's used to prime the random number generator.  If
              you want to create a unique series of random numbers, you should
              invoke the <b>anySeed</b> method instead of this one. 
              
*/
-setSeed:(DSPDatum)seedVal;
/* Sets seed of random sequence. This is the current value and thus is changed
   by the unit generator itself. */


/*!
  @method anySeed
  @result Returns an id.
  @discussion Sets the random number seed to a value that's guaranteed never to
              have been used in previous invocations of this method.  This is
              particularly useful if you're using more than one SnoiseUG and you
              want to ensure that they all produce different signals.
*/
-anySeed;
/* Sets seed of random sequence to a new seed, never before used by previous
   invocations of anySeed. Useful, for insuring that different
   noise generators generate different noise. */


/*!
  @method setOutput:
  @param  aPatchpoint is an id.
  @result Returns an id.
  @discussion Sets the output patchpoint to <i>aPatchpoint</i>.
*/
-setOutput:aPatchPoint;
/* Sets output as specified. */

@end

#endif
