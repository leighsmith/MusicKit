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


  3/10/93/daj - Created
*/
#import <MusicKit/MusicKit.h>
#import "_unitGeneratorInclude.h"
#import "_exportedPrivateMusickit.h"
#import <MKDSP/dsp_memory_map.h>
#import "In1qpUG.h"

@implementation In1qpUG:MKUnitGenerator
{
    int qpSatellite;
    BOOL _set;
}

enum args { chan, scl, dspptr, oadr, skip };

#import "in1qpUGInclude.m"

- init {
    char version;
    int release;
    [super init];
    [orchestra getMonitorVersion:&version release:&release];
    if (version != 'A')
      MKErrorCode(MK_dspMonitorVersionError,[self class]);
    qpSatellite = 0;
    return [self setAddressArg:skip toInt:DSP_X_O_SFRAME_W];
}

- setChannel:(int)aChan {
    /* 0-based channel */
    /* First account for devices such as AD64x that have 
     * an extra zero between channels
     */
    aChan *= [orchestra outputChannelOffset];
    return [self setDatumArg:chan to:aChan];
}

- setScale:(double)val {
    _set = YES;
    return [self setDatumArg:scl to:DSPDoubleToFix24(val)];
}

- setSatellite:(char)sat {
    /* char is 'A','B','C' or 'D', regardless of the orchIndex */ 
    int num;
    DSPAddress addr;
    char s[20];
    if (!(sat >= 'A' && sat <= 'D'))
      return nil;
    qpSatellite = sat;
    num = sat - 'A' + 1;
    sprintf(s,"X_SAT%d_REP",num);
    addr = DSPGetSystemSymbolValueInLC(s, DSP_LC_X);
    if (!addr) {
	MKErrorCode(MK_dspMonitorVersionError,[self class]);
	return nil;
    }
    return [self setAddressArg:dspptr toInt:addr];
}

- setOutput:(id)aPatchPoint {
	return [self setAddressArg:oadr to:aPatchPoint];
}

- idleSelf {
    [self setAddressArgToSink:oadr];
    return self;
}

- runSelf {
    if (!_set) [self setScale:0.999999];
    if (!qpSatellite)
      [self setSatellite:qpSatellite = 'A'];
    return self;
}

@end
