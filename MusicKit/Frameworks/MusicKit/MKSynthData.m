/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description:
    Data memory object. Used to allocate DSP data memory. Also used
    to allocate patchpoints. You never create instances of MKSynthData or any
    of its subclasses directly. They are created automatically by the
    MKOrchestra object in response to messages such as allocSynthData:length:.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University  
*/
/* 
Modification history:

  $Log$
  Revision 1.5  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.4  2000/06/09 18:05:27  leigh
  Added braces to reduce finicky compiler warnings

  Revision 1.3  2000/03/29 03:35:41  leigh
  Cleaned up doco and ivar declarations

  Revision 1.2  1999/07/29 01:16:43  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  11/20/89/daj - Minor change for new lazy shared data garbage collection. 
  11/27/89/daj - Removed arg from _MKCurSample.
  01/31/90/daj - Added new method
               -setShortData:(short *)dataArray length:(int)len offset:(int)off
  03/31/90/daj - Moved private methods to category
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  04/27/90/daj - Changed _DSPSend* to DSPMKSend* 
                 (except for _DSPMKSendUnitGeneratorWithLooperTimed)
  11/17/92/daj - Minor change to shut up compiler warnings.
  11/6/94/daj - Changed error returns to notify orch on abort.
  06/29/98/sb - changed length to unsigned int. Hope compares still work.
*/
//#import <objc/objc-class.h>

#import "_musickit.h"
#import "_SharedSynthInfo.h"
#import "_error.h"
#import "UnitGeneratorPrivate.h"
#import "OrchestraPrivate.h"

#import "SynthDataPrivate.h"
@implementation MKSynthData

#define ISDATA (orchAddr.memSegment == MK_xData || \
		orchAddr.memSegment == MK_yData)
/* Needed by synthElementMethods.m. We suppress lazy garbage collection for
   patchpoints. The idea is to avoid fragmentation. 
   Note that Pluck depends on this. */

#import "synthElementMethods.m"

// Added by DAJ 10/8/93
#define ORCHABORT  ([self->orchestra deviceStatus] == MK_devClosed) 

-clear
    /* clears memory */
{
    int ec;
    if (ORCHABORT)
      return self;
    if (readOnly)
      return _MKErrorf(MK_synthDataReadonlyErr);
    if (_MK_ORCHTRACE(orchestra,MK_TRACEDSP))
	_MKOrchTrace(orchestra,MK_TRACEDSP,
		     "Clearing %s%d (addr 0x%x size:0x%x).",
		     [orchestra segmentName:orchAddr.memSegment],
		     self->_instanceNumber,
		     self->orchAddr.address,self->length);
    DSPSetCurrentDSP(_orchIndex);
    ec = DSPMKMemoryFillSkipTimed(_MKCurSample(orchestra),0,
				  orchAddr.memSpace,orchAddr.address,1,
				  length);
    if (ec) {
      if (ec == DSP_EABORT)
	[self->orchestra _notifyAbort];
      else
        return _MKErrorf(MK_synthDataCantClearErr);
    }
    return self;
}

- run
  /* Provided for compatability with MKUnitGenerator. Does nothing and returns
     self. */
{
    return self;
}

-idle
  /* Provided for compatability with MKUnitGenerator. Does nothing and returns
     self. */
{
    return self;
}

-(double)finish
  /* Provided for compatability with MKUnitGenerator. Does nothing and returns 0
     */
{
    return 0;
}

-(unsigned int)length
  /* Return size of memory block. */
{
    return length;
}

-(DSPAddress)address
  /* Returns address of memory block. */
{
    return orchAddr.address;
}

-(DSPMemorySpace)memorySpace
  /* Return memory space of this memory block. */
{
    return orchAddr.memSpace;
}

-(MKOrchAddrStruct *)orchAddrPtr
  /* Return addr struct ptr for this memory. The orchAddr is not copied. */
{
    return &orchAddr;
}

-(BOOL)isModulus
{
    unsigned i = orchAddr.address;
    if (isModulus)
      return YES;
    for (i=1; (orchAddr.address & i) == 0; i += i)
      ;
    return (isModulus = (i >= length));
}

#define CONSTANT ((void *)((unsigned)-1)) /* A non-0 impossible pointer */

static id sendPreamble(self,dataArray,len,off,value)
    MKSynthData *self;
    void *dataArray; /* Or CONSTANT */
    int len;
    int off;
    DSPDatum value; /* Optional. Only supplied if CONSTANT */
{
    if ((!dataArray) || (len + off > self->length))
      return _MKErrorf(MK_synthDataLoadErr);
    if (self->readOnly)
      return _MKErrorf(MK_synthDataReadonlyErr);
    if (_MK_ORCHTRACE(self->orchestra,MK_TRACEDSP)) {
	if (len == self->length && off == 0) 
	  if (dataArray == CONSTANT)
	    _MKOrchTrace(self->orchestra,MK_TRACEDSP,
			 "Loading constant 0x%x into %s%d [0x%x-0x%x].",
			 value,
			 [self->orchestra segmentName:self->orchAddr.memSegment],
			 self->_instanceNumber,
			 self->orchAddr.address,
			 self->orchAddr.address-1+len);
	  else 
	    _MKOrchTrace(self->orchestra,MK_TRACEDSP,
			 "Loading array into %s%d [0x%x-0x%x].",
			 [self->orchestra segmentName:self->orchAddr.memSegment],
			 self->_instanceNumber,
			 self->orchAddr.address,
			 self->orchAddr.address-1+len);
	else 
	  if (dataArray == CONSTANT)
	    _MKOrchTrace(self->orchestra,MK_TRACEDSP,
			 "Loading constant 0x%x into %s%d sub-block [0x%x-0x%x].\n  Length = 0x%x offset = 0x%x.",
			 value,
			 [self->orchestra segmentName:self->orchAddr.memSegment],
			 self->_instanceNumber,
			 self->orchAddr.address+off,
			 self->orchAddr.address-1+off+len,
			 len,off);
	  else 
	    _MKOrchTrace(self->orchestra,MK_TRACEDSP,
			 "Loading array into %s%d sub-block [0x%x-0x%x].\n   Length = 0x%x offset = 0x%x.",
			 [self->orchestra segmentName:self->orchAddr.memSegment],
			 self->_instanceNumber,
			 self->orchAddr.address+off,
			 self->orchAddr.address-1+off+len,
			 len,off);
    }
    DSPSetCurrentDSP(self->_orchIndex);
    return self;
}

-setData:(DSPDatum *)dataArray length:(unsigned int)len offset:(int)off
    /* Load data and check size. Offset is shift from start of memory block. */
{
    int ec;
    if (ORCHABORT)
      return self;
    if (!sendPreamble(self,dataArray,len,off))
	return nil;
    if (_MK_ORCHTRACE(orchestra,MK_TRACEDSPARRAYS)) {
	int i;
	_MKOrchTrace(orchestra,MK_TRACEDSPARRAYS,"Setting array of %s%d.",
		     [orchestra segmentName:orchAddr.memSegment],
		     _instanceNumber);
	for (i=0; i<len; i++)
	  _MKOrchTrace(orchestra,MK_TRACEDSPARRAYS,"  0x%x",dataArray[i]);
    }
    ec = DSPMKSendArraySkipTimed(_MKCurSample(orchestra),dataArray,
				 orchAddr.memSpace,orchAddr.address + off,
				 1,len);
    if (ec) {
      if (ec == DSP_EABORT)
	[orchestra _notifyAbort];
      else 
        return _MKErrorf(MK_synthDataLoadErr);
    }
    return self;
}

-setData:(DSPDatum *)dataArray 
    /* Same as above, but uses our size as the array length. */
{
    return [self setData:dataArray length:length offset:0];
}

-setShortData:(short *)dataArray length:(unsigned int)len offset:(int)off
    /* Load data and check size. Offset is shift from start of memory block. */
{
    int ec;
    if (ORCHABORT)
      return self;
    if (!sendPreamble(self,dataArray,len,off))
	return nil;
    if (_MK_ORCHTRACE(orchestra,MK_TRACEDSPARRAYS)) {
	int i;
	_MKOrchTrace(orchestra,MK_TRACEDSPARRAYS,"Setting array of %s%d.",
		     [orchestra segmentName:orchAddr.memSegment],
		     _instanceNumber);
	for (i=0; i<len; i++)
	  _MKOrchTrace(orchestra,MK_TRACEDSPARRAYS,"  0x%x",dataArray[i]);
    }
    ec =  DSPMKSendShortArraySkipTimed(_MKCurSample(orchestra),dataArray,
				       orchAddr.memSpace,orchAddr.address + off,
				       1,len); 
    if (ec) {
      if (ec == DSP_EABORT)
	[orchestra _notifyAbort];
      else
        return _MKErrorf(MK_synthDataLoadErr);
    }
    return self;
}

-setShortData:(short *)dataArray 
{
    return [self setShortData:dataArray length:length offset:0];
}

-setToConstant:(DSPDatum)value length:(unsigned int)len offset:(int)off
    /* Load data and check size. Offset is shift from start of memory block. */
{
    int ec;
    if (ORCHABORT)
      return self;
    if (!sendPreamble(self,CONSTANT,len,off,value))
	return nil;
    ec = DSPMKMemoryFillSkipTimed(_MKCurSample(orchestra),value,
				  orchAddr.memSpace,orchAddr.address + off,
				  1,len); 
    if (ec) {
      if (ec == DSP_EABORT)
	[orchestra _notifyAbort];
      else
        return _MKErrorf(MK_synthDataLoadErr);
    }
    return self;
}

-setToConstant:(DSPDatum)value
  /* Same as above but sets entire memory block to specified value. */
{
    return [self setToConstant:value length:length offset:0];
}

-(BOOL)readOnly
  /* Returns YES if the receiver is read-only. */
{
    return readOnly;
}

-setReadOnly:(BOOL)readOnlyFlag
  /* Sets whether the receiver is read-only. Default is no. Anyone can
     change a readOnly object to read-write by first calling setReadOnly:.
     Thus readOnly is more of a "curtesy flag".
     The exception is the Sine ROM, the MuLaw ROM and the "zero" patchpoints.
     These are protected. An attempt to make them read-write is ignored.*/
{
    if (_protected)
      return self;
    readOnly = readOnlyFlag;
    return self;
}

-(BOOL)isAllocated     
  /* Returns YES */
{
    return YES;
}

-(int)referenceCount
{
    if (_sharedKey)
      return _MKGetSharedSynthReferenceCount(_sharedKey);
    return 1;
}

extern int DSPReadValue(DSPMemorySpace space,
			DSPAddress address,
			DSPFix24 *value);

-readShortDataUntimed:(short *)dataArray length:(unsigned int)len offset:(int)off
/* This returns a valid value by reference only when one of the following
   is true:
   the data was allocated before the MKOrchestra started running
   the data was allocated more than deltaT in the past
   delta-t is 0
   there is no Conductor performing
 */
{
    int ec;
    int i,cnt = len-off;
    DSPDatum value;
    if (ORCHABORT)
      return self;
    for (i=0; i<cnt; i++) {
	ec = DSPReadValue(orchAddr.memSpace,orchAddr.address+off+i,&value);
	if (ec) {
	  if (ec == DSP_EABORT) {
	      [orchestra _notifyAbort];
	      return nil;
	  }
	  else
              return _MKErrorf(MK_synthDataCantReadDSPErr);
        }
	dataArray[i] = value;
    }
    return self;
}

-readDataUntimed:(DSPDatum *)dataArray length:(unsigned int )len offset:(int )off
/* This returns a valid value by reference only when one of the following
   is true:
   the data was allocated before the MKOrchestra started running
   the data was allocated more than deltaT in the past
   delta-t is 0
   there is no Conductor performing
 */
{
    int ec;
    int i,cnt = len-off;
    if (ORCHABORT)
      return self;
    for (i=0; i<cnt; i++) {
	ec = DSPReadValue(orchAddr.memSpace,orchAddr.address+off+i,dataArray++);
	if (ec) {
	  if (ec == DSP_EABORT) {
	      [orchestra _notifyAbort];
	      return nil;
	  }
	  else
              return _MKErrorf(MK_synthDataCantReadDSPErr);
        }
    }
    return self;
}

@end

@implementation MKSynthData(Private)

-(MKOrchMemStruct *) _resources     
  /* return pointer to memory requirements of this unit generator. */
{
    return &_reso;
}
-_deallocAndAddToList
    /* For memory, we do not keep a class-wide free list. Instead, we
       give the contained memory back to the Orchestra's free list. */
{
    _MKFreeMem(orchestra,&orchAddr);
//    [super dealloc];
    /*sb: in original, was [super free]. Normally, conversion would change this to [super release]
     *    but in this case, -_deallocAndAddToList is sent as part of the NSObject -dealloc method.
     *    Thus we do a [super dealloc].
     * Hmmm... yes, sometimes this method is called as part of -dealloc, but not always. What do we do?
     * ...so I have decided to remove the deallocation from here. When synthdata is deallocated 
     * in the MKSynthPatch class, it is via the release of the MutableArray that holds it. Therefore
     * there is no point in deallocing it here -- the array will complete the release.
     * I need to check for the other times this method is called, though, to check whether it is released
     * in all circumstances.
     */
    return nil;
}

+(id)_newInOrch:(id)anOrch index:(unsigned short)whichDSP 
 length:(unsigned int)size segment:(MKOrchMemSegment)whichSegment 
 baseAddr:(DSPAddress)addr isModulus:(BOOL)yesOrNo;
{
    static int instanceCount[MK_numOrchMemSegments-MK_xData] = {0}; 
    /* Just counts up forever (for debugging) */
//    MKSynthData *newObj = [super new]; //sb: this fails, saying that MKSynthData doesn't respond to alloc
    MKSynthData *newObj = [[super allocWithZone:NSDefaultMallocZone()] init];
    newObj->_instanceNumber = instanceCount[whichSegment-MK_xData]++;
    newObj->orchestra = anOrch;
    newObj->_orchIndex = whichDSP;
    newObj->_reso.pLoop = newObj->_reso.pSubr = 
      newObj->_reso.xArg = newObj->_reso.lArg = 
	newObj->_reso.yArg = 0;
    newObj->length = size;
    switch (whichSegment) {
      case MK_xData:
      case MK_xPatch:
	newObj->_reso.xData = size;
        newObj->_reso.yData = 0;	
	newObj->orchAddr.memSpace = DSP_MS_X;
	break;
      case MK_yData:
      case MK_yPatch:   /* We use this class for patchpoint also. */
        newObj->_reso.xData = 0;	
	newObj->_reso.yData = size;
	newObj->orchAddr.memSpace = DSP_MS_Y;
	break;    
      default:
	break;
    }
    newObj->orchAddr.memSegment = whichSegment;  
    newObj->orchAddr.address = addr;      
    newObj->orchAddr.orchIndex = whichDSP;
    newObj->isModulus = yesOrNo;
    return newObj;
}

#import "_synthElementMethods.m"

@end

