/*
  $Id$
  Defined In: The MusicKit

  Description:
    You instantiate a subclass of the form
    Out2sumUG<a>, where <a> = space of input

  Copyright 1988-1992, NeXT Inc.  All rights reserved.
*/
/* 
Modification history:

  11/22/89/daj - Changed to use UnitGenerator C functions for speed.	 
                 Optimized setBearing: slightly.
  07/23/91/daj - Added init method to fix up libdsp symbol DMA_WFP
  07/23/91/daj - Added fix up of libdsp symbol OUT_SKIP2 (to support
                 skip factors)
*/
#import <MusicKit/MusicKit.h>
#import "_unitGeneratorInclude.h"
#import "_exportedPrivateMusickit.h"
#import <MKDSP/dsp_memory_map.h>
#import "Out2sumUG.h"

@implementation Out2sumUG:MKUnitGenerator

#define _set _reservedOut2sum1

enum _args { sclA, iadr, sclB};

#import "out2sumUGInclude.m"

#if _MK_UGOPTIMIZE 
+(BOOL)shouldOptimize:(unsigned) arg
{
    return YES;
}
#endif _MK_UGOPTIMIZE

extern DSPFix48 *_MKCurSample(id orch);

-init
  /* Fix up system argument! */
{
    char version;
    int release;
    [orchestra getMonitorVersion:&version release:&release];
    if (version != 'A')
      MKErrorCode(MK_dspMonitorVersionError,[self class]);
    if (DSPMKSendValueTimed(_MKCurSample(orchestra),DSP_X_DMA_WFP,
			    DSPLCtoMS[(int)DSP_LC_P],relocation.pLoop+2))
      return nil;
    if (DSPMKSendValueTimed(_MKCurSample(orchestra),DSP_X_O_CHAN_OFFSET,
			    DSPLCtoMS[(int)DSP_LC_P],relocation.pLoop+4))
      return nil;
    if (DSPMKSendValueTimed(_MKCurSample(orchestra),DSP_X_O_SFRAME_W,
			    DSPLCtoMS[(int)DSP_LC_P],relocation.pLoop+6))
      return nil;
    return self;
}

-idleSelf
{
    [self setAddressArgToZero:iadr];
    bearingScale = 1.0;
    return self;
}

-runSelf
{
  if (!_set)
    [self setBearing:MK_DEFAULTBEARING scale:1.0]; /* Sets bearing to 0 */
  return self;
}

-setInput:aPatchPoint
{
    return MKSetUGAddressArg(self,iadr,aPatchPoint);
}

-setLeftScale:(double)val
{
    _set = YES;
    return MKSetUGDatumArg(self,sclA,DSPDoubleToFix24(val));
}

-setRightScale:(double)val
{
    _set = YES;
    return MKSetUGDatumArg(self,sclB,DSPDoubleToFix24(val));
}

#define bearingFun1(theta)    fabs(cos(theta))
#define bearingFun2(theta)    fabs(sin(theta))

-setBearing:(double)val
  /* When val is -45, you get the left channel, +45 you get the right channel.
     Val = 90 is the same as val = 0. */  
{
    val = val * M_PI/180.0 + M_PI/4.0;
    MKSetUGDatumArg(self,sclA,DSPDoubleToFix24(bearingScale*bearingFun1(val)));
    MKSetUGDatumArg(self,sclB,DSPDoubleToFix24(bearingScale*bearingFun2(val)));
    _set = YES;
    return self;
}

-setBearing:(double)val scale:(double)aScale
{
  bearingScale = aScale;
  return [self setBearing:val];
}
@end

