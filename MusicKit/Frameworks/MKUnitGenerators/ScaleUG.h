#ifndef __MK_ScaleUG_H___
#define __MK_ScaleUG_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* 
	ScaleUG.h 

	This class is part of the Music Kit UnitGenerator Library.
*/
#import <MusicKit/MKUnitGenerator.h>
@interface ScaleUG:MKUnitGenerator
/* 
  ScaleUG - from dsp macro /usr/lib/dsp/ugsrc/scale.asm (see source for details).

  You instantiate a subclass of the form 
  ScaleUG<a><b>, where <a> = space of output and <b> = space of input.

  The scale unit-generator simply copies one signal vector over to
  another, multiplying by a scale factor.  The output patchpoint can 
  be the same as the input patchpoint.
*/

-setInput:aPatchPoint;
/* Sets input patchpoint. */

-setOutput:aPatchPoint;
/* Sets output patchpoint. */

-setScale:(double)val;
/* Sets scale factor. */

+(BOOL)shouldOptimize:(unsigned) arg;
/* Specifies that all arguments are to be optimized if possible. */

@end

#endif
