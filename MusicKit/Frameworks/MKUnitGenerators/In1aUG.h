#ifndef __MK_In1aUG_H___
#define __MK_In1aUG_H___
#import <MusicKit/MKUnitGenerator.h>

@interface In1aUG : MKUnitGenerator
/* In1aUG - from dsp macro /usr/local/lib/dsp/ugsrc/in1a.asm (see source for details).

   In1a reads its input signal from channel 0 (left) of the stereo sound input sample 
   stream of the DSP, writing it to its output. 
   In1a also provides a scaling on its output.

   You instantiate a subclass of the form 
   In1aUG<a>, where <a> = space of input

   */
{
  BOOL _reservedIn1a1;
}

+(BOOL)shouldOptimize:(unsigned) arg;
/* Specifies that all arguments are to be optimized if possible. */

-setScale:(double)val;
/* Sets scaling for left channel. */ 

-runSelf;
/* If scaling has not been set, sets it to 1-e. */

-setOutput:aPatchPoint;
/* Sets input patch point. */
@end
#endif
