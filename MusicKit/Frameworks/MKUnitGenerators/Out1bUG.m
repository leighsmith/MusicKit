/*
  $Id$
  Defined In: The MusicKit

  Description:

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/* 
Modification history:
  $Log$
  Revision 1.4  2005/05/27 04:28:33  leighsmith
  Renamed _MKErrorf() to the latest MKErrorCode() naming

  Revision 1.3  2000/06/13 19:25:02  leigh
  Now use SndKit and MKDSP frameworks, cleaned doco


  11/22/89/daj - Changed to use UnitGenerator C functions for speed.	 
  04/18/90/mmm - Added missing definition of +shouldOptimize
  07/23/91/daj - Added init method to fix up libdsp symbol. Hm.
*/
#import <MusicKit/MusicKit.h>
#import "_unitGeneratorInclude.h"
#import "_exportedPrivateMusickit.h"
#import <MKDSP/dsp_memory_map.h>
#import "Out1bUG.h"

@implementation Out1bUG:MKUnitGenerator

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
      MKErrorCode(MK_dspMonitorVersionError,[self class]);
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

