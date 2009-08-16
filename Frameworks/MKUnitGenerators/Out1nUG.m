/*
  $Id$
  Defined In: The MusicKit

  Description:

  Original Author: David A. Jaffe

  Copyright 1993, CCRMA, Stanford University.  All rights reserved.
*/
/* 
Modification history:
  $Log$
  Revision 1.4  2005/05/27 04:28:33  leighsmith
  Renamed _MKErrorf() to the latest MKErrorCode() naming

  Revision 1.3  2000/06/13 19:25:02  leigh
  Now use SndKit and MKDSP frameworks, cleaned doco


  09/21/93/daj - Created from Out1aUG
*/
#import <MusicKit/MusicKit.h>
// #import "_unitGeneratorInclude.h"
// #import "_exportedPrivateMusickit.h"
#import <MKDSP/dsp_memory_map.h>
#import "Out1nUG.h"

@implementation Out1nUG:MKUnitGenerator

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
      MKErrorCode(MK_dspMonitorVersionError,[self class]);
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

