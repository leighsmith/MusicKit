/*
  $Id$
  Defined In: The MusicKit

  Description:
    OscgafiUG - interpolating oscillator with amplitude and frequency envelopes.

    OscgafiUG<a><b><c><d>, where <a> is the output space, <b> is the amplitude
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
  Revision 1.3  2000/06/13 19:25:02  leigh
  Now use SndKit and MKDSP frameworks, cleaned doco


  11/13/89/daj - Simplified defaultTableLength:.
*/
#import <MusicKit/MusicKit.h>
#import "_exportedPrivateMusickit.h"
#import <SndKit/SndKit.h>
#import "OscgafiUG.h"

@implementation OscgafiUG:OscgafUGs

typedef enum _args { aina, atab, inc, ainf, aout, mtab, phs} args;
#import "oscgafiUGInclude.m"

#if 0
+(int)defaultTableLength:anObj
  /* Provides for a power-of-2 table length with a reasonable number of samples for
     the highest component. */
{
  if ([anObj isKindOfClass: [Samples class]])
    return [[anObj sound] sampleCount];
  else if ([anObj isKindOfClass: [Partials class]]) {
    switch ((int)ceil([anObj highestFreqRatio] * .0625)) { /* /16 */
      case 0: return 64;    /* no partials? */
      case 1: return 128;   /* 1 to 16 */
      case 2:               /* 17 to 32 */
      case 3:               /* 33 to 48 */
      case 4:               /* 48 to 64 */
	return 256;   
      default:
	return 512;
    }
  }
  else if ([anObj respondsTo:@selector(length)])
    return (int)[anObj length];
  else return 128;
}
#endif

+(int)defaultTableLength:anObj
  /* Provides for a power-of-2 table length */
{
  if ([anObj isKindOfClass: _MKClassPartials()])
    return 128;
  if ([anObj isKindOfClass: _MKClassSamples()])
    return [[anObj sound] sampleCount];
  else if ([anObj respondsTo:@selector(length)])
    return (int)[anObj length];
  else return 128;
}

@end

