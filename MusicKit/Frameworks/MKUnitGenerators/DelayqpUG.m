/* Copyright 1993, CCRMA, Stanford University.  All rights reserved. */

/*
Modification history:

  3/6/93/daj - Created

*/
#import <MusicKit/MusicKit.h>
#import <MusicKit/ArielQP.h>
#import "_unitGeneratorInclude.h"
#import "_exportedPrivateMusickit.h"

#import "DelayqpUG.h"
@implementation DelayqpUG:MKUnitGenerator
/* DRAM Delay line for Quint Processor 
	You instantiate a subclass of the form 
	DelayUG<a><b>, where 
	<a> = space of output
	<b> = space of input
*/	
{
    int memAddr; 
    int len;   
}

enum args { ainp, aout, pdel, adel, edel};

#import "delayqpUGInclude.m"

+(BOOL)shouldOptimize:(unsigned) arg
{
    return (arg != pdel);
}

-init
{
    char version;
    int release;
    [super init];
    [orchestra getMonitorVersion:&version release:&release];
    if (version != 'A')
      _MKErrorf(MK_dspMonitorVersionError,[self class]);
    return self;
}

-idleSelf
  /* Patches output and delay memory to sink. */
{
    [self setAddressArgToSink:aout];
    [self setDelayAddress:MK_DRAM_SINK length:1];
    return self;
}

-runSelf
  /* Does nothing. */
{
    return self;
}

-setInput:aPatchPoint
  /* Sets input as specified. */
{
    return MKSetUGAddressArg(self,ainp,aPatchPoint);
}

-setOutput:aPatchPoint
  /* Sets output as specified. */
{
    return MKSetUGAddressArg(self,aout,aPatchPoint);
}

-setDelayAddress:(DSPDatum)address length:(DSPDatum)length
{
//    int memObjAddr;
    memAddr = address;
    len = length;
    [orchestra beginAtomicSection];
    MKSetUGDatumArg(self,adel,memAddr);
    MKSetUGDatumArg(self,pdel,memAddr);
    MKSetUGDatumArg(self,edel,memAddr + len);
    [orchestra endAtomicSection];
    return self;
}

-adjustLength:(int)newLength
{
    len = newLength; 
    MKSetUGDatumArg(self,edel,newLength + memAddr);
    return self;
}

-resetPointer
{
    MKSetUGDatumArg(self,pdel,memAddr);
    return self;
}

-setPointer:(int)offset
{
    MKSetUGDatumArg(self,pdel,offset + memAddr);
    return self;
}

-(int)length
  /* Returns the length of the delay. This is always LEQ than the
     length of the memory object. */
{
    return len;
}

@end



