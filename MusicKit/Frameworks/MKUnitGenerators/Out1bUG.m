/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#ifdef SHLIB
#include "shlib.h"
#endif
/* 
Modification history:

  11/22/89/daj - Changed to use UnitGenerator C functions for speed.	 
  04/18/90/mmm - Added missing definition of +shouldOptimize
  07/23/91/daj - Added init method to fix up libdsp symbol. Hm.
*/
#import <MusicKit/MusicKit.h>
#import "_unitGeneratorInclude.h"
#import "_exportedPrivateMusickit.h"
#import <dsp/dsp_memory_map.h>
#import "Out1bUG.h"
@implementation Out1bUG:MKUnitGenerator
{ /* Instance variables go here */
  BOOL _reservedOut1b1;
}
#define _set _reservedOut1b1

enum args { sclB, iadr};

#import "out1bUGInclude.m"

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
      _MKErrorf(MK_dspMonitorVersionError,[self class]);
    if (DSPMKSendValueTimed(_MKCurSample(orchestra),DSP_X_DMA_WFP,
			    DSPLCtoMS[(int)DSP_LC_P],relocation.pLoop+2))
      return nil;
    if (DSPMKSendValueTimed(_MKCurSample(orchestra),DSP_X_O_CHAN_OFFSET,
			    DSPLCtoMS[(int)DSP_LC_P],relocation.pLoop+4))
      return nil;
    if (DSPMKSendValueTimed(_MKCurSample(orchestra),DSP_X_O_SFRAME_W,
			    DSPLCtoMS[(int)DSP_LC_P],relocation.pLoop+8))
      return nil;
    return self;
}

-idleSelf
{
    [self setAddressArgToZero:iadr];
    return self;
}

-runSelf
{
    if (!_set) [self setScale:0.999999];
    return self;
}

-setInput:aPatchPoint
{
    return MKSetUGAddressArg(self,iadr,aPatchPoint);
}

-setScale:(double)val
{
    _set = YES;
    return MKSetUGDatumArg(self,sclB,DSPDoubleToFix24(val));
}

@end

