#ifndef __MK_Mul2UG_H___
#define __MK_Mul2UG_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* 
	Mul2UG.h 

	This class is part of the Music Kit UnitGenerator Library.
*/
#import <MusicKit/MKUnitGenerator.h>
@interface Mul2UG:MKUnitGenerator
/* Mul2UG  - from dsp macro /usr/lib/dsp/ugsrc/mul2.asm (see source for details).

   Outputs the product of two input signals. 
   
   You allocate one of the subclasses Mul2UG<a><b><c>, where <a> is the output 
   space, <b> is the space of the first input and <c> is the space of the
   second input. 

*/

+(BOOL)shouldOptimize:(unsigned) arg;
/* Specifies that all arguments are to be optimized if possible. */

-setInput1:aPatchPoint;
/* Sets input1 to specified patchPoint. */

-setInput2:aPatchPoint;
/* Sets input2 to specified patchPoint. */

-setOutput:aPatchPoint;
/* Sets output to specified patchPoint. */

-idleSelf;
/* Sets output to sink. */

@end

#endif
