#ifndef __MK_OnezeroUG_H___
#define __MK_OnezeroUG_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* 
	OnezeroUG.h 

	This class is part of the Music Kit UnitGenerator Library.
*/

#import <MusicKit/MKUnitGenerator.h>

@interface OnezeroUG : MKUnitGenerator
/* OnezeroUG  - from dsp macro /usr/lib/dsp/ugsrc/onezero.asm (see source for details).

   You instantiate a subclass of the form OnezeroUG<a><b>, where 
   <a> = space of output and <b> = space of input.

   The onezero unit-generator implements a one-zero
   filter section in direct form.  For best performance,
   the input and output signals should be in separate
   memory spaces x or y.
   
   */

-setInput:aPatchPoint;
/* Sets filter input. */

-setOutput:aPatchPoint;
/* Sets filter output. */

-setB0:(double)val;
/* Sets gain of filter. */

-setB1:(double)val;
/* Sets coefficient of once-delayed input sample. */

+(BOOL)shouldOptimize:(unsigned) arg;
/* Specifies that all arguments are to be optimized if possible except the
   filter state. */

-clear;
/* Clears filter's state variable. */

@end

#endif
