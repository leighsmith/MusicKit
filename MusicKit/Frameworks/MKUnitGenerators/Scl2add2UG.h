#ifndef __MK_Scl2add2UG_H___
#define __MK_Scl2add2UG_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* 
	Scl2add2UG.h 

	This class is part of the Music Kit UnitGenerator Library.
*/
#import <MusicKit/MKUnitGenerator.h>
@interface Scl2add2UG:MKUnitGenerator
  /*    Scl2add2UG. From dsp macro /usr/lib/dsp/ugsrc/scl2add2.asm (see source for details).

	You instantiate a subclass of the form Scl2add2UG<a><b><c>, where 
	<a> = space of output
	<b> = space of input1
	<c> = space of input2

      The scl2add2 unit-generator multiplies two input signals
      times constant scalers then adds them together to produce a
      third.  The output vector can be the same as an input vector.
      Inner loop is two instructions if space of input1 is "x" and
      space of input2 is "y", otherwise three instructions.

*/

-setInput1:aPatchPoint;
/* Sets input1. This is the input that is scaled. */

-setInput2:aPatchPoint;
/* Sets input2. */

-setOutput:aPatchPoint;
/* Sets output. */

-setScale1:(double)val;
/* Sets scaling on input1. */

-setScale2:(double)val;
/* Sets scaling on input2. */

+(BOOL)shouldOptimize:(unsigned) arg;
/* Specifies that all arguments are to be optimized if possible. */

-idleSelf;
  /* Sets output to write to sink. */

@end

#endif
