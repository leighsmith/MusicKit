/*
  $Id$
  Defined In: The MusicKit

  Description:

  Original Author: David A. Jaffe

  Copyright 1993, CCRMA. Stanford University.  All rights reserved.
*/
/*
Modification history:
  $Log$
  Revision 1.4  2005/05/27 04:28:33  leighsmith
  Renamed _MKErrorf() to the latest MKErrorCode() naming

  Revision 1.3  2000/06/13 19:25:01  leigh
  Now use SndKit and MKDSP frameworks, cleaned doco


  1/25/93/daj - Created
*/
#import <MusicKit/MusicKit.h>
#import "_unitGeneratorInclude.h"
#import "_exportedPrivateMusickit.h"
#import <MKDSP/dsp_memory_map.h>
#import "In1bUG.h"

@implementation In1bUG:MKUnitGenerator

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
      MKErrorCode(MK_dspMonitorVersionError,[self class]);
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

