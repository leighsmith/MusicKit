#ifndef __MK_DelayqpUG_H___
#define __MK_DelayqpUG_H___
/* Copyright 1993, CCRMA, Stanford.  All rights reserved. */
/* 
	DelayqpUG.h 

	This class is part of the Music Kit UnitGenerator Library.
*/

#import <MusicKit/MKUnitGenerator.h>

@interface DelayqpUG : MKUnitGenerator
/* DelayqpUG  - from dsp macro /usr/lib/dsp/ugsrc/delayqp.asm (see source for details).

	You instantiate a subclass of the form 
	DelayqpUG<a><b>, where 
	<a> = space of output
	<b> = space of input

	DelayqpUG is useful for flanging, reverberation, plucked string 
	synthesis, etc.
*/	
{
    int memAddr;
    int len; 
}
+(BOOL)shouldOptimize:(unsigned) arg;
/* Specifies that all arguments are to be optimized if possible except the
   delay pointer. */

-setInput:aPatchPoint;
/* Sets input patchpoint as specified. */
-setOutput:aPatchPoint;
/* Sets output patchpoint as specified. */

-setDelayAddress:(DSPDatum)address length:(DSPDatum)length;
-adjustLength:(int)newLength;
-setPointer:(int)offset;
-resetPointer;
-(int)length;

-runSelf;
-idleSelf;
/* Patches output and delay memory to sink. */


@end

#endif
