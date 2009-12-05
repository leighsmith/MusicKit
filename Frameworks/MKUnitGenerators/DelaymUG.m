/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* 
Modification history:

  3/16/96/daj - Created by DAJ, based on DelayUG.m

*/
#import <MusicKit/MusicKit.h>

#import "DelaymUG.h"
@implementation DelaymUG:MKUnitGenerator
/* Delay line for modulus memory. 
	You instantiate a subclass of the form 
	DelaymUG<a><b><c>, where 
	<a> = space of output
	<b> = space of input
	<c> = space of delay line
*/	
{
    id memObj;      /* Delay memory */
    int len;        /* Length (LEQ length of memObj). */
}

enum args { aout, pdel, ainp, mod };

#import "delaymUGInclude.m"

+(BOOL)shouldOptimize:(unsigned) arg
{
    return (arg != pdel);
}

-idleSelf
  /* Patches output and delay memory to sink. */
{
    [self setAddressArgToSink:aout];
    [self setDelayMemory:nil];
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

-setDelayMemory:aDspMemoryObj
  /* 
   * aDspMemoryObj must be allocated as modulus memory 
   * It is up to the caller to insure the memory is cleared. 
   */
{
    int memObjAddr;
    BOOL isModulus = YES;
    if (!aDspMemoryObj || !(isModulus = [aDspMemoryObj isModulus])) {
	MKOrchMemSegment seg;
	DSPMemorySpace spc = [(id)self->isa argSpace:pdel];
	if (spc == DSP_MS_X)
	  seg = MK_xData;
	else seg = MK_yData;
	aDspMemoryObj = [orchestra segmentSinkModulus:seg];
    }
    memObj = aDspMemoryObj;
    len = [aDspMemoryObj length];
    [orchestra beginAtomicSection];
    MKSetUGAddressArg(self,pdel,aDspMemoryObj);
    MKSetUGDatumArg(self,mod,len - 1);
    [orchestra endAtomicSection];
    return (isModulus) ? self : nil;
}

-adjustLength:(int)newLength
  /* If no setDelayMemory: message has been received, returns nil.
     Otherwise, adjusts the delay length as indicated. newLength
     must be LEQ the length of the block of memory specified
     in setDelayMemory:. Otherwise, nil is returned. Note
     that the unused memory in the memory specified in 
     setDelayMemory: is not freed. Resetting the
     length of a running Delay may cause the pointer to go out-of-bounds.
     Therefore, it is prudent to send setPointer: or resetPointer after
     adjustLength:. Also note that when lengthening the delay, you 
     will be bringing in old delayed samples. Therefore, you may
     want to clear the new portion by sending the memory object the
     message -setToConstant:length:offset:. */
{
    if (!memObj || ([memObj length] < newLength))
      return nil;
    len = newLength; 
    MKSetUGDatumArg(self,mod,len - 1);
    return self;
}

-resetPointer
  /* If no setDelayMemory: message has been received, returns nil.
     Else sets pointer to start of memory. This is done automatically
     when setDelayMemory: is sent. */
{
    if (!memObj)
      return nil;
    MKSetUGAddressArg(self,pdel,memObj);
    return self;
}

-setPointer:(int)offset
  /* If no setDelayMemory: message has been received, returns nil.
     Else sets pointer to specified offset. E.g. if offset == 0,
     this is the same as resetPointer. If offset is GEQ the length
     of the memory block, returns nil. */
{
    if (!memObj || (len <= offset))
      return nil;
    MKSetUGAddressArgToInt(self,pdel,offset + [memObj address]);
    return self;
}

-(int)length
  /* Returns the length of the delay. This is always LEQ than the
     length of the memory object. */
{
    return len;
}

@end




