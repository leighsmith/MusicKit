/*
  $Id$
  Defined In: The MusicKit

  Description:
    OscgafUG - non-interpolating oscillator with amplitude and frequency envelopes.

    OscgafUG<a><b><c><d>, where <a> is the output space, <b> is the amplitude
    input space, <c> is the increment input space, and <b> is the table space.

    See documentation for OscgafUGs.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/* 
Modification history:
  $Log$
  Revision 1.3  2000/06/13 19:25:01  leigh
  Now use SndKit and MKDSP frameworks, cleaned doco


  11/13/89/daj - Simplified defaultTableLength:.
  11/21/89/daj - Fixed bug in shared data mechanism: changed table space to
                 table segment.

*/
#import <MusicKit/MusicKit.h>
#import "_exportedPrivateMusickit.h"
#import <SndKit/SndKit.h>
#import "OscgafUG.h"

@implementation OscgafUG:OscgafUGs

typedef enum _args { aina, atab, inc, ainf, aout, mtab, phs} args;
#import "oscgafUGInclude.m"


#if 0
+(int)defaultTableLength:anObj
  /* Provides for a power-of-2 table length with a reasonable number of samples for
     the highest component. */
{
  if ([anObj isKindOf:[Samples class]])
    return [[anObj sound] sampleCount];
  else if ([anObj isKindOf:[Partials class]]) {
    switch ((int)ceil([anObj highestFreqRatio]/16)) {
      case 0: return 64;    /* no partials? */
      case 1: return 256;   /* 1 to 16  */
    }
    return 512;             /* 16 < */
  }
  else if ([anObj respondsTo:@selector(length)])
    return (int)[anObj length];
  else return 256;
}
#endif

+(int)defaultTableLength:anObj
  /* Provides for a power-of-2 table length with a reasonable number 
     of samples for the highest component. */
{
  if ([anObj isKindOf:_MKClassPartials()]) 
    return 256;
  else if ([anObj isKindOf:_MKClassSamples()])
    return [[anObj sound] sampleCount];
  else if ([anObj respondsTo:@selector(length)])
    return (int)[anObj length];
  else return 256;
}
@end

