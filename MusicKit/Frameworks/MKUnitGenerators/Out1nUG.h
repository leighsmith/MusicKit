#ifndef __MK_Out1nUG_H___
#define __MK_Out1nUG_H___
/* Copyright 1993, Stanford University.  All rights reserved. */
/* 
	Out1nUG.h 

	This class is part of the Music Kit UnitGenerator Library.
*/

#import <MusicKit/MKUnitGenerator.h>

@interface Out1nUG : MKUnitGenerator
/* Out1nUG - from dsp macro /usr/lib/dsp/ugsrc/out1n.asm (see source for details).

   Out1n writes its input signal to the Nth channel of the output stream, which
   must be set up appropraitely.
   The stream is cleared before each DSP tick (each orchestra program 
   iteration). Out1n also provides a scaling on the output channel.

   You instantiate a subclass of the form 
   Out1nUG<a>, where <a> = space of input

   */
{
  BOOL _reservedOut1n1; 
  BOOL _reservedOut1n2; 
}

+(BOOL)shouldOptimize:(unsigned) arg;
/* Specifies that all arguments are to be optimized if possible. */

-setScale:(double)val;
/* Sets scaling. */ 

-setChannel:(int)chan;
/* Sets channel.  chan is 0-based. */ 

-runSelf;
/* If scaling has not been set, sets it to 1-e. */

-setInput:aPatchPoint;
/* Sets input patch point. */
@end

#endif
