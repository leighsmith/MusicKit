/* Copyright 1993, CCRMA. Stanford University.  All rights reserved. */
#ifdef SHLIB
#include "shlib.h"
#endif
/* 
Modification history:

  1/25/93/daj - Created
*/
#import <MusicKit/MusicKit.h>
#import "_unitGeneratorInclude.h"
#import "_exportedPrivateMusickit.h"
#import <dsp/dsp_memory_map.h>
#import "In1bUG.h"
@implementation In1bUG:MKUnitGenerator
{ /* Instance variables go here */
  BOOL _reservedIn1b1;
}
#define _set _reservedIn1b1

enum args { sclA, oadr };

#import "in1bUGInclude.m"

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
    if (DSPMKSendValueTimed(_MKCurSample(orchestra),DSP_X_SSI_REP,
			    DSPLCtoMS[(int)DSP_LC_P],relocation.pLoop+2))
      return nil;
    if (DSPMKSendValueTimed(_MKCurSample(orchestra),DSP_X_I_CHAN_OFFSET,
			    DSPLCtoMS[(int)DSP_LC_P],relocation.pLoop+4))
      return nil;
    if (DSPMKSendValueTimed(_MKCurSample(orchestra),DSP_X_I_SFRAME_R,
			    DSPLCtoMS[(int)DSP_LC_P],relocation.pLoop+6))
      return nil;
    return self;
}

-idleSelf
{
    [self setAddressArgToSink:oadr];
    return self;
}

-runSelf
{
    if (!_set) [self setScale:0.999999];
    return self;
}

-setOutput:aPatchPoint
{
    return MKSetUGAddressArg(self,oadr,aPatchPoint);
}

-setScale:(double)val
{
    _set = YES;
    return MKSetUGDatumArg(self,sclA,DSPDoubleToFix24(val));
}

@end

