#ifndef __MK_Out1aUG_H___
#define __MK_Out1aUG_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* 
	Out1aUG.h 

	This class is part of the Music Kit UnitGenerator Library.
*/

#import <MusicKit/MKUnitGenerator.h>

@interface Out1aUG : MKUnitGenerator
/* Out1aUG - from dsp macro /usr/lib/dsp/ugsrc/out1a.asm (see source for details).

   Out1a writes its input signal to the mono output stream, or channel 0 (left)
   of the stereo output sample stream of the DSP, adding into that stream.
   The stream is cleared before each DSP tick (each orchestra program 
   iteration). Out1a also provides a scaling on the output channel.

   You instantiate a subclass of the form 
   Out1aUG<a>, where <a> = space of input

   */
{
  BOOL _reservedOut1a1; 
}

+(BOOL)shouldOptimize:(unsigned) arg;
/* Specifies that all arguments are to be optimized if possible. */

-setScale:(double)val;
/* Sets scaling for left channel. */ 

-runSelf;
/* If scaling has not been set, sets it to 1-e. */

-setInput:aPatchPoint;
/* Sets input patch point. */
@end

#endif
