/* Copyright 1993, CCRMA, Stanford University.  All rights reserved. */
#ifdef SHLIB
#include "shlib.h"
#endif
/* 
Modification history:
  09/21/93/daj - Created from Out1aUG
*/
#import <MusicKit/MusicKit.h>
// #import "_unitGeneratorInclude.h"
// #import "_exportedPrivateMusickit.h"
#import <dsp/dsp_memory_map.h>
#import "Out1nUG.h"
@implementation Out1nUG:MKUnitGenerator
{ /* Instance variables go here */
  BOOL _reservedOut1n1;
  BOOL _reservedOut1n2;
}
#define _gainSet _reservedOut1n1
#define _chanSet _reservedOut1n2

enum args { chanoff, sclN, iadr };

#import "out1nUGInclude.m"

+(BOOL)shouldOptimize:(unsigned) arg
{
    return YES;
}

extern DSPFix48 *_MKCurSample(id orch);

-init
  /* Fix up system arguments! */
{
    char version;
    int release;
    [orchestra getMonitorVersion:&version release:&release];
    if (version != 'A')
      _MKErrorf(MK_dspMonitorVersionError,[self class]);
    if (DSPMKSendValueTimed(_MKCurSample(orchestra),DSP_X_DMA_WFP,
			    DSPLCtoMS[(int)DSP_LC_P],relocation.pLoop+2))
      return nil;
    if (DSPMKSendValueTimed(_MKCurSample(orchestra),DSP_X_O_SFRAME_W,
			    DSPLCtoMS[(int)DSP_LC_P],relocation.pLoop+7))
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
    if (!_gainSet) [self setScale:0.999999];
    if (!_chanSet) [self setChannel:0];
    return self;
}

-setInput:aPatchPoint
{
    return MKSetUGAddressArg(self,iadr,aPatchPoint);
}

-setChannel:(int)chan
  /* Sets the channel to which this UG writes.  chan is 0-based. */
{
    _chanSet = YES;
    return MKSetUGDatumArg(self,chanoff,chan);
}

-setScale:(double)val
{
    _gainSet = YES;
    return MKSetUGDatumArg(self,sclN,DSPDoubleToFix24(val));
}

@end

