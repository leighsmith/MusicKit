/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description:
    This is an abstract superclass from which particular MKUnitGenerators
    inherit. You never create instances of MKUnitGenerator or any 
    of its subclasses directly. They are created automatically by the 
    MKOrchestra object in response to messages such as allocUnitGenerator:
    The subclass needs to provide a number of methods. 
    In particular, he may want to override
      -runSelf
      -idleSelf
      -finishSelf
    and
      -init

    In addition to the subclass responsibility methods given below, the 
    subclass designer will probably want to provide methods for poking 
    values into the DSP (e.g. an oscillator would have a setFreq:
    method.) The utility dspwrap (not provided in release 0.9) 
    simplifies the task of writing MKUnitGenerator subclasses.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2004, The MusicKit Project.
*/
/* 
Modification history prior to commit to CVS:

  11/20/89/daj - Minor change for new lazy shared data garbage collection. 
  11/26/89/daj - Added _MKBeginUGBlock() and _MKEndUGBlock() to avoid calling
                 _MKCurSample more than needed.
  11/27/89/daj - Removed arg from _MKCurSample.
  01/10/90/daj - Made changes to accomodate new dspwrap.
  01/11/90/daj - Added setAddressArg:toInt:.
  02/26/90/jos - Deleted "_" from _DSPGetDSPCount().
  03/13/90/daj - Split private methods into catagories.
  03/24/90/daj - Added adjust time hack. 
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  04/27/90/daj - Changed _DSPSend* to DSPMKSend* 
                 (except for _DSPMKSendUnitGeneratorWithLooperTimed)
  05/01/90/jos - Removed "r" prefix from rData and rWordCount
  12/12/90/daj - Added NX_FREE call in _free to plug memory leak.
  11/17/92/daj - Minor change to fix compiler warnings.
  6/11/93/daj - Changed assignment to self in private +_new method (for NS486)
  11/6/94/daj - Changed error returns to notify orch on abort.
*/

// LMS: FIXME MKErrorCode use here is wrong, for now I'm continuing to make the earlier assumption that the second argument
// is somehow a cString.

#import "UnitGeneratorPrivate.h"
#import "_musickit.h"
#import <Foundation/NSException.h> /*sb: for assertions? */

#define INT(_x) ((int)_x)
 
#import "_error.h"
#import "OrchestraPrivate.h" // @requires
#import "_SharedSynthInfo.h"

@implementation MKUnitGenerator:NSObject

#define ISDATA NO /* Needed by synthElementMethod.m */

#import "synthElementMethods.m"

#import "synthElementCFuncs.m"

/* Functions for doing dynamic loading, fixups, etc. */

static NSString *argName(id self,int argNum)
{
    return [[self class] argName:argNum];
}

static void setLoadAddrs(loadAddresses,relocation)
    register DSPAddress *loadAddresses;
    register MKOrchMemStruct *relocation;
    /* Convert from musickit to libdsp data structure. */
{
    loadAddresses[(int)DSP_LC_X] = relocation->xArg;
    loadAddresses[(int)DSP_LC_Y] = relocation->yArg;
    loadAddresses[(int)DSP_LC_XH] = relocation->xData;
    loadAddresses[(int)DSP_LC_YH] = relocation->yData;
    loadAddresses[(int)DSP_LC_L] = relocation->lArg;
    loadAddresses[(int)DSP_LC_P] = relocation->pLoop;
    loadAddresses[(int)DSP_LC_PH] = relocation->pSubr;
    /*** FIXME Need lData here someday. ***/  
}

static int sendUGTimed(DSPFix48 *aTimeStamp,MKLeafUGStruct *classInfo,
		      MKOrchMemStruct *relocation,int looper)
    /* Fixup and load new unit generator. */
{
    register int i;
    DSPAddress loadAddresses[DSP_LC_NUM]; 
    DSPDataRecord **data,*d; 
    DSPFixup **fixups = classInfo->fixups; /* Array of ptrs */
    int *fixupCount = classInfo->master->fixupCount;
    setLoadAddrs(loadAddresses,relocation);     
    data = &classInfo->data[(int)DSP_LC_P];  
    for (i = 0; i < (int)DSP_LC_NUM_P; i++, data++) 
      if ((*data))       /* Do fix ups */
	DSP_UNTIL_ERROR(_DSPReloc(*data,fixups[i],fixupCount[i], loadAddresses));
    data = classInfo->data;        /* Now send code */
    if ((d = data[(int)DSP_LC_P])) { /* ploop */
	DSP_UNTIL_ERROR(_DSPMKSendUnitGeneratorWithLooperTimed(aTimeStamp,
						  DSPLCtoMS[(int)DSP_LC_P],
						  loadAddresses[(int)DSP_LC_P],
						  d->data,d->wordCount,
						  looper));
    }
#   define SENDDATA(_lc) if ((d = data[(int)_lc])) \
    DSP_UNTIL_ERROR(DSPMKSendArraySkipTimed(aTimeStamp,d->data, \
					    DSPLCtoMS[(int)_lc],\
					    loadAddresses[(int)_lc],\
					    1,d->wordCount))
    SENDDATA(DSP_LC_PH);/* pSubr */
    SENDDATA(DSP_LC_XH);/* xData */
    SENDDATA(DSP_LC_YH);/* yData */
    return 0;
}

id _MKFixupUG(MKUnitGenerator *self,DSPFix48 *ts)
    /* Just poke fixups. */
{
    int i,j;
    int ec;
    int reloc,word;
    DSPAddress loadAddresses[DSP_LC_NUM]; 
    DSPDataRecord **data; 
    DSPFixup **fixupsArr = self->_classInfo->fixups;   /* Array of arrays */
    DSPFixup *fixup;
    int *fixupCount = self->_classInfo->master->fixupCount;
    setLoadAddrs(loadAddresses,&(self->relocation));
    data = &self->_classInfo->data[(int)DSP_LC_P];
    for (i = 0; i < (int)DSP_LC_NUM_P; i++, data++) {
        if (*data) {
            reloc = loadAddresses[i + (int)DSP_LC_P];
            for (j = fixupCount[i], fixup = fixupsArr[i]; j--; fixup++) {
                word = loadAddresses[fixup->locationCounter] + fixup->relAddress;
                /* Set data->data[fixup->refOffset] if you want to set data */
                ec = DSPMKSendValueTimed(ts,
                                        /* What: */
                                        word,
                                        /* Where: */
                                        DSP_MS_P,fixup->refOffset + reloc);
                if (ec) {
                    if (ec == DSP_EABORT)
                            [self->orchestra _notifyAbort];
		    else {
			MKErrorCode(MK_ugLoadErr, NSStringFromClass([self class]));
			return nil;
		    }
                }
            }
        }
    }
    return self;
}

#define ADDRESSOFFSET(_sp)  _sp->value.i

static void
reRelocateArgs(MKUnitGenerator *self)
{
    int i;
    MKUGArgStruct *args = self->args;  
    register MKOrchAddrStruct *addr;
    register DSPSymbol *sp = self->_classInfo->master->argSymbols;
    MKOrchMemStruct *relocation = &(self->relocation);
    int argCount = [self argCount];
    for (i = 0; i < argCount; i++) {
	addr = &(args++->addrStruct);         /* Grab ptr to addr */
	switch ((int)sp->locationCounter) {   /* Set additonal data of addr */
	  case DSP_LC_X:
	    addr->address = relocation->xArg + ADDRESSOFFSET(sp) ;
	    break;
	  case DSP_LC_Y:
	    addr->address = relocation->yArg + ADDRESSOFFSET(sp) ;
	    break;
	  case DSP_LC_L:  
	    /* Offsets for L are negative. relocation->lArg is top of block. 
	       This works! */
	    addr->address = relocation->lArg + ADDRESSOFFSET(sp) ;
	    break;
	  default: /* Should never happen */
	    break;
	}
	sp++;
    }
}

void _MKRerelocUG(MKUnitGenerator *self,MKOrchMemStruct *newReloc)
  /* Moves unit generator for the purpose of compaction. 
     It moves the pLoop and arguments but changes neither the pSubr, 
     yData nor xData. */
{
    if (_MK_ORCHTRACE(self->orchestra,MK_TRACEORCHALLOC)) {
	_MKOrchTrace(self->orchestra,MK_TRACEORCHALLOC,
              @"Moving %s_%p.",NSStringFromClass([self class]),self);
	_MKOrchTrace(self->orchestra,MK_TRACEORCHALLOC,
		     @"NewReloc: pLoop %d, xArg %d, yArg %d, lArg %d.",
		     newReloc->pLoop,newReloc->xArg,newReloc->yArg,
		     newReloc->lArg);
      }
   /* For moving to lower addresses, need to BLT forwards (low addresses to
       high addresses. For moving from lower addresses, need to BLT backwards
       (high addresses to low addresses). We will always be
       BLTing to lower addresses so we always use DSPMKSendBLTTimed. */
    NSCAssert(((newReloc->pLoop <= self->relocation.pLoop) &&
	       (newReloc->xArg <= self->relocation.xArg) &&
	       (newReloc->yArg <= self->relocation.yArg) &&
	       (newReloc->lArg <= self->relocation.lArg)), @"BLT in wrong direction during compaction.");
    /* Save new relocation. */
    self->relocation.pLoop = newReloc->pLoop;
    self->relocation.xArg = newReloc->xArg;
    self->relocation.yArg = newReloc->yArg;
    self->relocation.lArg = newReloc->lArg;
    /* Change argument addresses. */
    reRelocateArgs(self);
}

#if 0
static MKOrchMemSegment orchMemSegmentToLC[(int)MK_numOrchMemSegments] = {
    DSP_LC_N /* MK_noSegment */,
    DSP_LC_P /* MK_pLoop */,
    DSP_LC_PH /* MK_pSubr */,
    DSP_LC_X /* MK_xArg */,
    DSP_LC_Y /* MK_yArg */,
    DSP_LC_L /* MK_lArg */,
    DSP_LC_XH /* MK_xData - shared with MK_xPatch */,
    DSP_LC_YH /* MK_yData - shared with MK_yPatch */,
    DSP_LC_LH /* MK_lData - shared with MK_lPatch UNUSED */,
    DSP_LC_XH /* MK_xPatch - shared with MK_xData, can also be onchip */,
    DSP_LC_YH /* MK_yPatch - shared with MK_yData, can also be onchip */
    DSP_LC_LH /* MK_lPatch - shared with MK_lData, UNUSED */};
#endif


static void
relocateArgs(MKUnitGenerator *self)
{
    int i;
    MKUGArgStruct *args = self->args;  
    register MKOrchAddrStruct *addr;
    register DSPSymbol *sp = self->_classInfo->master->argSymbols;
    DSPMemorySpace *argSpace = self->_classInfo->argSpaces;
    MKOrchMemStruct *relocation = &(self->relocation);
    unsigned short orchIndex = self->_orchIndex;
    int argCount = [self argCount];
    for (i = 0; i < argCount; i++) {
	addr = &(args->addrStruct);           /* Grab ptr to addr */
	args->initialized = NO;
	args++->addressMemSpace = *argSpace++;/* Set arg mem space */
	addr->orchIndex = orchIndex;          /* Set orchIndex of arg */
	switch ((int)sp->locationCounter) {   /* Set additonal data of addr */
	  case DSP_LC_X:
	    addr->memSegment = MK_xArg;
	    addr->memSpace = DSP_MS_X;
	    addr->address = relocation->xArg + ADDRESSOFFSET(sp) ;
	    break;
	  case DSP_LC_Y:
	    addr->memSegment = MK_yArg;
	    addr->memSpace = DSP_MS_Y;
	    addr->address = relocation->yArg + ADDRESSOFFSET(sp) ;
	    break;
	  case DSP_LC_L:  
	    addr->memSegment = MK_lArg;
	    addr->memSpace = DSP_MS_L;   
	    /* Offsets for L are negative. relocation->lArg is top of block. 
	       This works! */
	    addr->address = relocation->lArg + ADDRESSOFFSET(sp) ;
	    break;
	  default: /* Should never happen */
	    break;
	}
	sp++;
    }
}

void MKInitUnitGeneratorClass(MKLeafUGStruct *classInfo)
{
    classInfo->availLists = (id **)calloc(DSPGetDSPCount(),sizeof(id));
}

/* Allocation methods */

-freeSelf
  /* You can optionally implement this method. FreeSelf is sent to the object
     before it is freed. */
{
    return nil;
}


/* Querying the UG. */

+(MKMasterUGStruct *)masterUGPtr
    /* This method is a subclass responsibility. It is automatically
       provided by the MKUnitGenerator creation utility, dspwrap. */
{
    [NSException raise:NSInvalidArgumentException format:@"*** Subclass responsibility: %s", NSStringFromSelector(_cmd)];
    return NULL;
}

+(MKLeafUGStruct *)classInfo
    /* This method is a subclass responsibility. It is automatically
       provided by the MKUnitGenerator creation utility, dspwrap. */
{
    [NSException raise:NSInvalidArgumentException format:@"*** Subclass responsibility: %s", NSStringFromSelector(_cmd)];
    return NULL;
}

+(unsigned)argCount
    /* Returns the number of memory arguments instances of this class have. */
{
    return ([self masterUGPtr]->argCount);
}

-moved
  /* 
     The moved message is sent when the MKOrchestra moves a MKUnitGenerator
     during compaction.
     A subclass occasionally overrides this method.
     The default method does nothing. */
{
    return self;
}


-(BOOL)runsAfter:(MKUnitGenerator *)aUnitGenerator
  /* Returns YES if aUnitGenerator executes on the DSP after the receiver. 
     aUnitGenerator is assumed to be executing in the same MKOrchestra as
     the receiver. */
{
    if (![aUnitGenerator isKindOfClass:[MKUnitGenerator class]]) 
      return NO;
    return relocation.pLoop > aUnitGenerator->relocation.pLoop;
}

-(MKOrchMemStruct *) relocation     
  /* Returns relocation of the receiver. For example, if the receiver's
     pLoop code begins at location 0x100, 
     [theSynthElement relocation]->pLoop == 0x100. */
{
    return &relocation;
}

-(unsigned)argCount
    /* Returns the number of DSP memory arguments of the receiver.
       This returns the same value as the class method +argCount. */
{
    return _classInfo->master->argCount;
}

-(MKLeafUGStruct *)classInfo
    /* Returns struct containing DSP info for instances of this leaf class. 
       Returns the same value as the class method +classInfo. */
{
    return _classInfo;
}

-(MKOrchMemStruct *) resources     
  /* Return pointer to DSP memory requirements of the receiver.
     E.g. if the MKUnitGenerator uses 10 words of pLoop memory 
     [aUG resources]->pLoop will be equal to 10. */
{
    return &_classInfo->reso;
}


/* Status methods */

#if 0
- initialize 
  /* For backwards compatibility */
{
    return self;
} 
#endif

- init
  /* TYPE: Creating
   * Empty method that can be overridden by a subclass. Sent when an object
   * is created, after its code is loaded.
   * Returns self or nil if the creation is to be aborted. In the
   * latter case, the object is then freed automatically by the MKOrchestra.
   * Subclass should send [super init] before doing its own 
   * initialiazation and should return nil immediately if [super init]
   * returns nil. The default implementation returns self. 
   */
{
  self = [super init];
  return self;
}


-runSelf
/* TYPE: Modifying; Tells the receiver to start running.
 * Starts the receiver by sending [self\ runSelf]
 * and then sets its status to MK_running.  You never subclass 
 * this method. 
 */
{
    return self;
}

-(double)finishSelf
    /* Subclass may override this to implement noteOff release.
       Returns the amount of time needed. Default returns 0. */
{
    return 0;
}


-idleSelf
    /* The subclass designer overrides this method to provide idle
       behavior, if desired. The default method does nothing. */
{
    return self;
}

- run
    /* Sends [self runSelf] then sets status to MK_running. 
     This method should not be overridden by subclass. Instead, the
     subclass implements runSelf. Music Kit semantics require that run
     be sent to a MKUnitGenerator before it is used. */
{
    [self runSelf];
    status = MK_running;
    return self;
}

-(double)finish
    /* This message is received when "the end is coming".
       Subclasses which have their own
       releaseDur, such as signal envelope handlers, should implement
       finishSelf. After sending finishSelf,
       sets status to MK_finishing and returns delay.
       finish should not be implemented by a subclass (see
       finishSelf).
       */
{
    double rtnVal = [self finishSelf];
    status = MK_finishing;
    /* NOTE: Might eventually want to add in some time here to account for
       a delay introduced between the time used for the load and the time
       use for the run. I.e. we could 'pad' the allocation here. */
    return rtnVal;
}

-idle
    /* Sends [self idleSelf], then sets status to MK_idle.
       Idle should not be implemented by a subclass (see idleSelf). */
{
    [self idleSelf];
    status = MK_idle;
    return self;
}

-(int)status
    /* Returns the status of the receiver. One of 
       MK_initialized,
       MK_running,
       MK_finishing,
       MK_idle,
       */
{
    return (int)status;
}

/* Error checks and such. */

#define OUTOFBOUNDS(_self,_x)  (_x >= _self->_classInfo->master->argCount)

+ (NSString *)argName:(unsigned)argNum
  /* Returns the name of the argument, as specified in the DSP macro .asm
     file from which the class was created. The name is not copied. */
{
    return (argNum >= [self argCount]) ? @"invalidArgument" :
      [NSString stringWithCString:[self masterUGPtr]->argSymbols[argNum].name];
}  

static id argOutOfBoundsErr(unsigned argNum,MKUnitGenerator *self)
  /* Generates error message saying argument is out of bounds. */
{
    MKErrorCode(MK_ugBadArgErr, [NSString stringWithCString: (char *) argNum], NSStringFromClass([self class]));
    return nil;
}

static id addrSetErr(MKUnitGenerator *self,unsigned argNum)
  /* Generates error message saying that argNum should only be set to an 
     address. */
{
    if (OUTOFBOUNDS(self,argNum))
	argOutOfBoundsErr(argNum,self);
    MKErrorCode((self->args[argNum].addressMemSpace != DSP_MS_N) ?  MK_ugNonAddrErr : MK_ugNonDatumErr,
                     argName(self,argNum), NSStringFromClass([self class]));
    return nil;
}

static void reportOpt(MKUnitGenerator *self,unsigned argNum)
{
    if (_MK_ORCHTRACE(self->orchestra,MK_TRACEDSP))
      _MKOrchTrace(self->orchestra,MK_TRACEDSP,
		   @"Optimizing away poke of %@ of UG%d_%@.",
                   argName(self,argNum),self->_instanceNumber,NSStringFromClass([self class]));
}

/* Argument-setting methods. */

+(BOOL)shouldOptimize:(unsigned) arg
  /* You may override this method to specify optimization of the command 
     stream to the DSP on an argument-by-argument basis. Optimization of
     an argument means that if it is set to the same value twice, the second
     setting is supressed. Note that you should never optimize an argument
     that the unit generator DSP code changes itself, i.e. anything used 
     for running state. The reason is that the MKUnitGenerator bases its 
     decision on whether to optimize by storing the previous set value, not by
     reading back the current value from the DSP. 
     This method should return YES if arg should be optimized, NO otherwise. 
     The default is NO. The decision as to whether to optimize a given 
     argument is made on a class-wide basis and may not vary over the course
     of a performance. */
{
    return NO;
}

static BOOL optimize(self,arg,argP,highVal,lowVal)
    MKUnitGenerator *self;
    unsigned arg;
    MKUGArgStruct *argP;
    int highVal;
    int lowVal;
{
    if ([self->orchestra deviceStatus] == MK_devClosed) /* DAJ - 10/8/93 */
      return YES;
    if (![((id)self->isa) shouldOptimize:arg])
      return NO;
    if (!argP->initialized) {
	argP->initialized = YES;
	argP->curVal.high24 = highVal;
	argP->curVal.low24 = lowVal;
	return NO;
    }
    if (argP->addrStruct.memSpace == DSP_MS_L) {
	if ((argP->curVal.high24 != highVal) || (argP->curVal.low24 != lowVal))
	  {
	      argP->curVal.low24 = lowVal; /* Save new values */
	      argP->curVal.high24 = highVal;
	      return NO;
	  }
    }
    else  /* DSP_MS_X or DSP_MS_Y */
      if (argP->curVal.high24 != highVal) {
	  argP->curVal.high24 = highVal;
	  return NO;
      }
    reportOpt(self,arg);
    return YES;
}

static BOOL errorChecks = NO;

+enableErrorChecking:(BOOL)yesOrNo
{
    errorChecks = yesOrNo;
    return self;
}

/* The following is an optimziation to avoid calling _MKCurSample() more
   than necessary. Note that it is optimized for the single-MKOrchestra case. */
static id sameTimeOrch = nil;
static DSPFix48 *ts = NULL;
static BOOL adjustTimeNeeded = NO;

void _MKBeginUGBlock(id anOrch,BOOL adjustIt)
{
    if (sameTimeOrch != anOrch) {
	ts = _MKCurSample(sameTimeOrch = anOrch);
	adjustTimeNeeded = adjustIt;
    }
}

void _MKEndUGBlock(void)
{
    adjustTimeNeeded = NO;
    sameTimeOrch = nil;
}

static void adjustTimeStamp(void)
{
    [_MKClassConductor() adjustTime];
    adjustTimeNeeded = NO;
    ts = _MKCurSample(sameTimeOrch);
}

#define CHECKADJUSTTIME() \
  if (adjustTimeNeeded) adjustTimeStamp()

void _MKAdjustTimeIfNecessary(void)
{
  CHECKADJUSTTIME();
}

#define TIMESTAMP() \
  ((sameTimeOrch == self->orchestra) ? ts : _MKCurSample(self->orchestra))

id MKSetUGDatumArg(MKUnitGenerator *self,unsigned argNum,DSPDatum val)
  /* ArgNum must be a datum-valued arg. Use
     setAddressArg:to: to set an address-valued arg. 
     If argNum is an L-space argument, the high-order word is set to val and
     the low order word is cleared.
     Returns self. */
{
    DSPFix48 *aTimeStamp;
    int ec;
    register MKUGArgStruct *p = &self->args[argNum];
    if (errorChecks) {
	if (OUTOFBOUNDS(self,argNum))
	  return argOutOfBoundsErr(argNum,self);
	if (p->addressMemSpace != DSP_MS_N) 
	  return addrSetErr(self,argNum);
    }
    if (optimize(self,argNum,p,val,0))
      return self;
    DSPSetCurrentDSP(self->_orchIndex);
    CHECKADJUSTTIME();
    aTimeStamp = TIMESTAMP();
    if (p->addrStruct.memSpace == DSP_MS_L) {
	DSPFix48 value;
	value.high24 = val;
	value.low24 = 0;
	if (_MK_ORCHTRACE(self->orchestra,MK_TRACEDSP))
            _MKOrchTrace(self->orchestra,MK_TRACEDSP,
		       @"Setting (L-just, 0-filled) %@ of UG%d_%@ to datum 0x%x.",
                argName(self,argNum),self->_instanceNumber,NSStringFromClass([self class]),val);
	ec = DSPMKSendLongTimed(aTimeStamp,&value,p->addrStruct.address);
        if (ec) {
            if (ec == DSP_EABORT)
                [self->orchestra _notifyAbort];
            else {
                MKErrorCode(MK_ugBadDatumPokeErr, [NSString stringWithCString: (char *) val],
				   argName(self,argNum), NSStringFromClass([self class]));
		return nil;
	    }
        }
        return self;
    }
    if (_MK_ORCHTRACE(self->orchestra,MK_TRACEDSP))
	_MKOrchTrace(self->orchestra,MK_TRACEDSP,
		 @"Setting %@ of UG%d_%@ to datum 0x%x.",argName(self,argNum),
		 self->_instanceNumber,NSStringFromClass([self class]),val);
    ec = DSPMKSendValueTimed(aTimeStamp,val,
			    p->addrStruct.memSpace,
			    p->addrStruct.address);
    if (ec) {
        if (ec == DSP_EABORT)
            [self->orchestra _notifyAbort];
        else {
            MKErrorCode(MK_ugBadDatumPokeErr, [NSString stringWithCString: (char *) val],
			       argName(self,argNum),NSStringFromClass([self class]));
	    return nil;
	}
    }
    return self;
}

-setDatumArg:(unsigned)argNum to:(DSPDatum)val
{
    return MKSetUGDatumArg(self,argNum,val);
}

id MKSetUGDatumArgLong(MKUnitGenerator *self,unsigned argNum,DSPLongDatum *val)
  /* ArgNum must be a datum-valued arg. Use
     setAddressArg:to: to set an address-valued arg. 
     If arg is not in L-space, only the high 24 bits of val are used.
     Returns self. */
{
    register MKUGArgStruct *p = &self->args[argNum];
    DSPFix48 *aTimeStamp;
    int ec;
    if (errorChecks) {
	if (OUTOFBOUNDS(self,argNum))
	  return argOutOfBoundsErr(argNum,self);
	if (p->addressMemSpace != DSP_MS_N) 
	  return addrSetErr(self,argNum);
    }
    if (optimize(self,argNum,p,val->high24,val->low24))
      return self;
    DSPSetCurrentDSP(self->_orchIndex);
    CHECKADJUSTTIME();
    aTimeStamp = TIMESTAMP();
    if (p->addrStruct.memSpace == DSP_MS_L) {
	if (_MK_ORCHTRACE(self->orchestra,MK_TRACEDSP))
	  _MKOrchTrace(self->orchestra,MK_TRACEDSP,
		       @"Setting %@ of UG%d_%@ to long: {0x%x,0x%x}.",
		       argName(self,argNum),self->_instanceNumber,NSStringFromClass([self class]),
		       val->high24,val->low24);
	ec = DSPMKSendLongTimed(aTimeStamp,val,p->addrStruct.address);
        if (ec) {
            if (ec == DSP_EABORT)
                [self->orchestra _notifyAbort];
            else {
                MKErrorCode(MK_ugBadDatumPokeErr, [NSString stringWithCString: (char *) val],
				   argName(self,argNum), NSStringFromClass([self class]));
		return nil;
	    }
        }
    }
    else {
	if (_MK_ORCHTRACE(self->orchestra,MK_TRACEDSP))
	  _MKOrchTrace(self->orchestra,MK_TRACEDSP,
		       @"Setting %@ of UG%d_%s to: 0x%x",
		       argName(self,argNum),self->_instanceNumber,NSStringFromClass([self class]),
		       val->high24);
	ec = DSPMKSendValueTimed(aTimeStamp,val->high24,
				 p->addrStruct.memSpace,
				 p->addrStruct.address);
        if (ec) {
            if (ec == DSP_EABORT)
                [self->orchestra _notifyAbort];
            else {
                MKErrorCode(MK_ugBadDatumPokeErr, [NSString stringWithCString: (char *) val],
				   argName(self,argNum), NSStringFromClass([self class]));
		return nil;
	    }
        }
    }
    return self;
}

-setDatumArg:(unsigned)argNum toLong:(DSPLongDatum *)val
{
    return MKSetUGDatumArgLong(self,argNum,val);
}

id MKSetUGAddressArg(MKUnitGenerator *self,unsigned argNum,id memoryObj)
    /* ArgNum must be an address-valued arg. Use
       setDatumArg:to: to set a datum-valued arg. */
{
    MKOrchAddrStruct *memP;
    int ec;
    register MKUGArgStruct *argP = &self->args[argNum];
    if (!memoryObj) {
	if (errorChecks) 
	    MKErrorCode(MK_musicKitErr, @"nil argument passed to MKSetUGAddressArg().");
	return nil;
    }
    memP =  [memoryObj orchAddrPtr];
    if (errorChecks) {
	if (!memP)
	  return nil;
	if (OUTOFBOUNDS(self,argNum))                 /* Arg ok? */
	  return argOutOfBoundsErr(argNum,self);
	if (self->_orchIndex != memP->orchIndex) {    /* Right orch? */
	    MKErrorCode(MK_ugOrchMismatchErr, [NSString stringWithCString: (char *) memP->orchIndex],
			       argName(self,argNum), NSStringFromClass([self class]), self->_orchIndex);
	    return nil;
	}
	if (argP->addressMemSpace == DSP_MS_N)        /* Address valued arg? */
	  return addrSetErr(self,argNum);
	if (argP->addressMemSpace != memP->memSpace) {  /* space match? */ 
	    MKErrorCode(MK_ugArgSpaceMismatchErr,
			       [NSString stringWithCString: 
				   (((int)memP->memSpace < (int)DSP_MS_Num && (int)memP->memSpace > (int)DSP_MS_N) ? 
				    ((char *)memP->memSpace) : "invalid")],
			       DSPMemoryNames((int)argP->addressMemSpace),
			       argName(self,argNum), NSStringFromClass([self class]));
	    
	    return nil;
	}
    }
    if (optimize(self,argNum,argP,memP->address,0))
        return self;
    if (_MK_ORCHTRACE(self->orchestra,MK_TRACEDSP)) {
	_MKOrchTrace(self->orchestra,MK_TRACEDSP,
		     @"Setting %@ of UG%d_%@ to %@%d (0x%x).",argName(self,argNum),
		     self->_instanceNumber,NSStringFromClass([self class]),
		     [self->orchestra segmentName:memP->memSegment],
		     [memoryObj instanceNumber],memP->address);
    }
    DSPSetCurrentDSP(self->_orchIndex);
    CHECKADJUSTTIME();
    ec = DSPMKSendValueTimed(TIMESTAMP(),memP->address,
			     argP->addrStruct.memSpace,
			     argP->addrStruct.address);
    if (ec) {
        if (ec == DSP_EABORT)
            [self->orchestra _notifyAbort];
        else {
            MKErrorCode(MK_ugBadAddrPokeErr, [NSString stringWithCString: (char *) memP->address],
			       argName(self,argNum), NSStringFromClass([self class]));
	    return nil;
	}
    }
    return self;
}

-setAddressArg:(unsigned)argNum to:(id)memoryObj
{
    return MKSetUGAddressArg(self,argNum,memoryObj);
}

id MKSetUGAddressArgToInt(MKUnitGenerator *self,unsigned argNum,DSPAddress addr)
    /* ArgNum must be an address-valued arg. Use
       setDatumArg:to: to set a datum-valued arg. */
{
    register MKUGArgStruct *argP = &self->args[argNum];
    int ec;
    if (errorChecks) {
	if (OUTOFBOUNDS(self,argNum))                 /* Arg ok? */
	  return argOutOfBoundsErr(argNum,self);
	if (argP->addressMemSpace == DSP_MS_N)        /* Address valued arg? */
	  return addrSetErr(self,argNum);
    }
    if (optimize(self,argNum,argP,addr,0))
      return self;
    if (_MK_ORCHTRACE(self->orchestra,MK_TRACEDSP))
	_MKOrchTrace(self->orchestra,MK_TRACEDSP,
		     @"Setting %@ of UG%d_%@ to address 0x%x.",argName(self,argNum),
		     self->_instanceNumber,NSStringFromClass([self class]),addr);
    DSPSetCurrentDSP(self->_orchIndex);
    CHECKADJUSTTIME();
    ec = DSPMKSendValueTimed(TIMESTAMP(),addr,
			     argP->addrStruct.memSpace,
			     argP->addrStruct.address);
    if (ec) {
        if (ec == DSP_EABORT)
            [self->orchestra _notifyAbort];
        else {
            MKErrorCode(MK_ugBadAddrPokeErr, [NSString stringWithCString: (char *) addr],
			       argName(self,argNum),NSStringFromClass([self class]));
	    return nil;
	}
    }
    return self;
}

-setAddressArg:(unsigned)argNum toInt:(DSPAddress)address
{
    return MKSetUGAddressArgToInt(self,argNum,address);
}

static id specialAddressVal(MKUnitGenerator *self, unsigned int argNum, SEL orchSel)
{
#   define INTARG(_x) ((id)_x)
    int ec;
    id memObj;
    register MKUGArgStruct *argP = &self->args[argNum];
    MKOrchAddrStruct *memP;
    if (errorChecks) {
	if (argNum < 0 || argNum >= self->_classInfo->master->argCount)
	  return argOutOfBoundsErr(argNum,self);
	if (argP->addressMemSpace == DSP_MS_N)
	  return addrSetErr(self,argNum);
    }
    NSCAssert(sizeof(id)==sizeof(int), @"specialAddressVal() assumes sizeof(id) == sizeof(int).");
    memObj = [[self orchestra] performSelector:orchSel 
	    withObject:INTARG(((argP->addressMemSpace == DSP_MS_X) ? (int)MK_xPatch :
			 (int)MK_yPatch))];
    memP =  [memObj orchAddrPtr];
    if (optimize(self,argNum,argP,memP->address,0))
      return self;
    if (_MK_ORCHTRACE(self->orchestra,MK_TRACEDSP))
      _MKOrchTrace(self->orchestra,MK_TRACEDSP,
		   @"Setting %@ of UG%d_%@ to address 0x%x.",
		   argName(self,argNum),self->_instanceNumber,NSStringFromClass([self class]),
		   memP->address);
    DSPSetCurrentDSP(self->_orchIndex);
    CHECKADJUSTTIME();
    ec = DSPMKSendValueTimed(TIMESTAMP(),memP->address,
			     argP->addrStruct.memSpace,
			     argP->addrStruct.address);
    if (ec) {
        if (ec == DSP_EABORT)
            [self->orchestra _notifyAbort];
        else {
            MKErrorCode(MK_ugBadAddrPokeErr, [NSString stringWithCString: (char *) memP->address],
			       argName(self,argNum), NSStringFromClass([self class]));
	    return nil;
	}
    }
    return self;
}

-setAddressArgToSink:(unsigned)argNum
    /* ArgNum must be an address-valued arg. Sets the argument to the
       correct 'sink' patchpoint. Sink is a location to which, by
       convention, nobody reads. */
{
    return specialAddressVal(self,argNum,@selector(segmentSink:));
}

-setAddressArgToZero:(unsigned)argNum
    /* ArgNum must be an address-valued arg. Sets the argument to the
       correct 'zero' patchpoint. Zero is a location to which, by
       convention, nobody writes. */
{
    return specialAddressVal(self,argNum,@selector(segmentZero:));
}

+(DSPMemorySpace)argSpace:(unsigned)argNum
  /* Returns the space where that arg
     reads or writes. This is useful in some unusual situations. If argNum
     is not an address-valued arg, returns DSP_MS_N.
     */
{
    MKLeafUGStruct *theClassInfo = [self classInfo];
    if (errorChecks) {
	if (argNum >= theClassInfo->master->argCount) {
	    argOutOfBoundsErr(argNum,self);
	    return DSP_MS_N;
	}
    }
    return theClassInfo->argSpaces[argNum];
}

-(BOOL)isAllocated     
  /* Returns YES if the receiver has been allocated. Otherwise
       NO. */
{
    return isAllocated;
}

-(int)referenceCount
{
    if (_sharedKey)
      return _MKGetSharedSynthReferenceCount(_sharedKey);
    return (isAllocated) ? 1 : 0;
}

+orchestraWillCreate:anOrch
{
    return self;
}

extern int _MKOrchestraGetNoops(void);

-writeSymbolsToStream:(NSMutableData *)s
{
    int i;
    [s appendData:[[NSString stringWithFormat:@"_COMMENT\nUG%d: %@",
        _instanceNumber,
        NSStringFromClass([self class])] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
    if (synthPatch)
        [s appendData:[[NSString stringWithFormat:@" in %s_0x%x\n",
            [NSStringFromClass([synthPatch class]) cString],
            synthPatch] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
    else [s appendBytes:"\n" length:1];
    [s appendData:[[NSString stringWithFormat:@"_SYMBOL P\nUG%d_%@ I %06X\n",
        _instanceNumber,
        NSStringFromClass([self class]),
        relocation.pLoop] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
    {   /* Write argument blocks */
	/* FIXME Assumes args count up. */
	int lowestX = MAXINT,lowestY = MAXINT,lowestL = MAXINT;
	int argCount = [self argCount];
	MKOrchAddrStruct *addrP;
	MKUGArgStruct *argP = self->args;
	for (i = 0; i < argCount; i++) {
	    addrP = &(argP++->addrStruct);
	    switch (addrP->memSpace) {
	      case DSP_MS_X:
		if (addrP->address < lowestX)
		  lowestX = addrP->address;
		break;
	      case DSP_MS_Y:
		if (addrP->address < lowestY)
		  lowestY = addrP->address;
		break;
	      case DSP_MS_L:
		if (addrP->address < lowestL)
		  lowestL = addrP->address;
		break;
	      default:
		break;
	    }
	}
	if (lowestX != MAXINT)
	  [s appendData:[[NSString stringWithFormat:@"_SYMBOL X\nUG%d_%@_XARGS I %06X\n",
              _instanceNumber,
              NSStringFromClass([self class]),
              lowestX] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
	if (lowestY != MAXINT)
	  [s appendData:[[NSString stringWithFormat:@"_SYMBOL Y\nUG%d_%@_YARGS I %06X\n",
              _instanceNumber,
              NSStringFromClass([self class]),
              lowestY] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
	if (lowestL != MAXINT)
	  [s appendData:[[NSString stringWithFormat:@"_SYMBOL L\nUG%d_%@_LARGS I %06X\n",
              _instanceNumber,
              NSStringFromClass([self class]),
              lowestL] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
    }
    {   /* Write arguments */
	DSPSymbol *sp = self->_classInfo->master->argSymbols;
	int argCount = [self argCount];
	MKOrchAddrStruct *addrP;
	MKUGArgStruct *argP = self->args;
	for (i = 0; i < argCount; i++) {
	    addrP = &(argP->addrStruct);
	    [s appendData:[[NSString stringWithFormat:@"_SYMBOL %s\n",
                DSPMemoryNames(addrP->memSpace)] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
	    [s appendData:[[NSString stringWithFormat:@"UG%d_%s I %06X\n",
                _instanceNumber,
                sp->name,
                addrP->address] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
	    argP++;
	    sp++;
	}
    }
    {   /* Write relocatable addresses */
	int i,j;
	int reloc,addr;	
	DSPAddress loadAddresses[DSP_LC_NUM]; 
	DSPFixup **fixupsArr = self->_classInfo->fixups;   /* Array of arrays */
	DSPFixup *fixup;
	int *fixupCount = self->_classInfo->master->fixupCount;
	DSPDataRecord **data; 
	int loc;
	BOOL nopsBetweenUGs = _MKOrchestraGetNoops();
	int relAddrNum = 0;
	data = &self->_classInfo->data[(int)DSP_LC_P];
	setLoadAddrs(loadAddresses,&(self->relocation));
	for (i = 0; i < (int)DSP_LC_NUM_P; i++, data++) {
	    reloc = loadAddresses[i + (int)DSP_LC_P];
	    for (j = fixupCount[i], fixup = fixupsArr[i]; j--; fixup++) {
		addr = loadAddresses[fixup->locationCounter] + fixup->relAddress;
		if (fixup->refOffset > 0) { /* If refOffset is 0, DO is impossible */
		    /* This is because the "expr" which is the end of the DO loop
		     * is actually one less than we want.  So we have to figure out
		     * if we have a do loop.
		     * 
		     * DO is a 2-word instruction, so we look one word earlier to
		     * see if we have a DO.  Then, if we do, we add one to addr
		     * to compensate for the subtraction performed by the assembler.
		     */
		    loc = (*data)->data[fixup->refOffset-1];
		    if ((loc & 0xff0000) == 0x060000) { /* Possibly DO */
			int k = (loc & 0xc0bf);  /* 4 different kinds of DO1 */
			int l = (loc & 0x00f0);
			int m = (loc & 0xc0ff);
			if ((k == 0x4000) || /* DO [XY]:ea,expr */
			    (k == 0x0000) || /* DO [XY]:aa,expr */
			    (l == 0x80)   || /* DO #xxx,expr    */  
			    (m == 0xc000))   /* DO S,expr       */
			  addr++;
		    }
		}
		if (!nopsBetweenUGs && 
		    (addr==(loadAddresses[fixup->locationCounter]+
			    (*data)->wordCount)))
		  continue;  /* If it's a label to the next UG, let that UG give label */
		[s appendData:[[NSString stringWithFormat:@"_SYMBOL %s\n", DSPMemoryNames(DSPLCtoMS[i+DSP_LC_P])] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
		[s appendData:[[NSString stringWithFormat:@"UG%d_RelAddr%d I %06X\n", _instanceNumber,++relAddrNum,
			 addr] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
	    }
	}
    }
    return self;
}

@end


@implementation MKUnitGenerator(Private)

-(MKOrchMemStruct *) _getRelocAndClassInfo:(MKLeafUGStruct **)classInfoPtr
  /* Returns pointer to DSP memory requirements of the receiver */
{
    *classInfoPtr = _classInfo;
    return &relocation;
}
-(MKOrchMemStruct *) _resources     
  /* Return pointer to DSP memory requirements of this unit generator. 
     E.g. if the MKUnitGenerator uses 10 words of pLoop memory 
     [aUG resources]->pLoop will be equal to 10. */
{
    return &_classInfo->reso;
}

#define AVAIL(_fact,__orchIndex) \
((id *)(([_fact classInfo])->availLists)+__orchIndex)

+_allocFromList:(unsigned short)index
    /* Remove and return the head of availList. */
{
    MKUnitGenerator **listP = (AVAIL(self,index)); 
    MKUnitGenerator *tmp = *listP;
    if (!tmp)
      return nil;
    *listP = (*listP)->_next;
    tmp->isAllocated = YES;
    tmp->_next = nil;
    return tmp;
}

#define PLOOP(_obj) (((MKUnitGenerator *)_obj)->relocation.pLoop)

+_allocFirstAfter:(MKUnitGenerator *)anObj list:(unsigned short)index
    /* Find, remove from availList and return the first instance with
       relocation constant after anObj. */
{
    MKUnitGenerator **listP = (AVAIL(self,index));
    register MKUnitGenerator *tmp = *listP;
    MKUnitGenerator *rtnVal;
    unsigned int r;
    if (!tmp) 
      return nil;
    r = PLOOP(anObj);
    if (PLOOP(tmp) > r) {   /* It's the first one */
	*listP = tmp->_next;
	tmp->isAllocated = YES;
	tmp->_next = nil;
	return tmp;
    }
    while (tmp->_next) 
      if (PLOOP(tmp->_next) > r) {
	  rtnVal = tmp->_next;
	  tmp->_next = ((MKUnitGenerator *)(tmp->_next))->_next;
	  rtnVal->_next = nil;
	  rtnVal->isAllocated = YES;
	  return rtnVal;
      } else tmp = tmp->_next;
    return nil;
}

+_allocFirstBefore:(MKUnitGenerator *)anObj list:(unsigned short)index 
    /* Find, remove from availList and return the first instance with
       relocation constant before anObj. */
{
    MKUnitGenerator **listP = (AVAIL(self,index));
    register MKUnitGenerator *tmp = *listP;
    MKUnitGenerator *rtnVal;
    register unsigned int r;
    if (!tmp) 
      return nil;
    r = PLOOP(anObj);
    if (PLOOP(tmp) < r) {   /* It's the first one */
	*listP = tmp->_next;
	tmp->isAllocated = YES;
	tmp->_next = nil;
	return tmp;
    }
    while (tmp->_next) 
      if (PLOOP(tmp->_next) < r) {
	  rtnVal = tmp->_next;
	  tmp->_next = ((MKUnitGenerator *)(tmp->_next))->_next;
	  rtnVal->_next = nil;	  
	  rtnVal->isAllocated = YES;
	  return rtnVal;
      } else tmp = tmp->_next;
    return nil;
}

+_allocFirstAfter:(MKUnitGenerator *)anObj before:(MKUnitGenerator *)anObj2 
  list:(unsigned short)index
    /* Find, remove from availList and return the first instance with
       relocation constant before anObj2 and after anObj. */
{
    MKUnitGenerator **listP = (AVAIL(self,index));
    register MKUnitGenerator *tmp = *listP;
    MKUnitGenerator *rtnVal;
    register unsigned int r2, r1;
    if (!tmp) 
      return nil;
    r1 = PLOOP(anObj);
    r2 = PLOOP(anObj2);
    if ((PLOOP(tmp) < r2) && (PLOOP(tmp) > r1)) { /* It's the first one. */
	*listP = tmp->_next;
	tmp->isAllocated = YES;
	tmp->_next = nil;
	return tmp;
    }
    while (tmp->_next) 
      if (PLOOP(tmp->_next) < r2 && PLOOP(tmp) > r1) {
	  rtnVal = tmp->_next;
	  tmp->_next = ((MKUnitGenerator *)(tmp->_next))->_next;
	  rtnVal->_next = nil;	  
	  rtnVal->isAllocated = YES;
	  return rtnVal;
      } else tmp = tmp->_next;
    return nil;
}


+(id)_newInOrch:(id)anOrch index:(unsigned short)whichDSP 
 reloc:(MKOrchMemStruct *)reloc looper:(unsigned int)looper
    /* Called by orchestra to instantiate a new copy of a MKUnitGenerator. 
       */
{
    static int UGInstanceCount = 0; /* Just counts up forever (for debugging) */
    int ec;
    MKUnitGenerator *aUG = [[self superclass] allocWithZone:NSDefaultMallocZone()];
    /* Must send to super here because self version is overridden. */
    aUG->_instanceNumber = UGInstanceCount++;
    aUG->_classInfo = [[aUG class] classInfo];
    aUG->relocation = *reloc;  /* Copy relocation. */
    aUG->isAllocated = YES;
    aUG->orchestra = anOrch;
    aUG->_orchIndex = whichDSP;
    /* Send relocated unit generator code to dsp. */
    if (_MK_ORCHTRACE(aUG->orchestra,MK_TRACEDSP))
	_MKOrchTrace(aUG->orchestra,MK_TRACEDSP,
              @"Loading %@_%p as UG%d. ",
              NSStringFromClass([aUG class]),
              aUG,aUG->_instanceNumber);
    DSPSetCurrentDSP(aUG->_orchIndex);
    [aUG->orchestra beginAtomicSection];
    ec = sendUGTimed(_MKCurSample(anOrch),
		     aUG->_classInfo,&aUG->relocation,looper);
    if (ec) {
        if (ec == DSP_EABORT)
            [aUG->orchestra _notifyAbort];
        else {
            MKErrorCode(MK_ugLoadErr, NSStringFromClass([aUG class]));
	    return nil;
	}
    }
    /* Relocate arguments. */
    if (aUG->_classInfo->master->argCount > 0) { 
	/* Allocate a block of args and relocate args. */
	_MK_MALLOC(aUG->args, MKUGArgStruct, 
		   aUG->_classInfo->master->argCount);
	relocateArgs(aUG);
    }
    if (![aUG init] /*|| ![aUG initialize] */) { //sb: initialize is obselete
	[aUG->orchestra endAtomicSection];
	return nil;
    }
    [aUG idle];
    [aUG->orchestra endAtomicSection];
    return aUG;
}

#define IAVAIL(__orchIndex) ((id *)(_classInfo->availLists + __orchIndex))

-_free
  /* Frees object and removes corresponding DSP code from the DSP. 
     You never call this method directly. 
     You may override it to do any clean-up needed before free. 
     Note the distinction between deallocating a MKUnitGenerator and freeing
     it. */
{
    MKUnitGenerator **listP = IAVAIL(_orchIndex);
    register MKUnitGenerator *tmp = *listP;
    [self freeSelf];
    if (!tmp)
      return nil;      /* Should never happen. */
    if (tmp == self)   /* Get self out of the avail list before freeing it. */
      *listP = tmp->_next;
    else while (tmp->_next) 
      if ((tmp->_next) == self) 
	tmp->_next = ((MKUnitGenerator *)(tmp->_next))->_next;
      else tmp = tmp->_next;
    free(args);
    args = NULL;
//    [super release];
    if (_MK_ORCHTRACE(orchestra,MK_TRACEORCHALLOC))
        _MKOrchTrace(orchestra,MK_TRACEORCHALLOC,@"Freeing %@_%p",NSStringFromClass([self class]),
                     self);
    return nil; /*sb: to maintain compatibility with return of old [super free] method */
}


-_deallocAndAddToList
    /* Unit generators are stored in free lists by the MKOrchestra.
       This method adds the receiver to the specified list. The 
       list is sorted by reloc. */
{
    MKUnitGenerator **listP = (IAVAIL(_orchIndex));
    unsigned int myAddr = relocation.pLoop;
    register MKUnitGenerator *tmp = *listP;
    isAllocated = NO;
    if (!tmp) 
      return *listP = self;
    if (myAddr < PLOOP(tmp)) { /* New head-of-list */
	_next = *listP;
	*listP = self;
	return self;
    }
    while (tmp->_next && PLOOP(tmp->_next) < myAddr)
      tmp = tmp->_next;
    _next = tmp->_next;          /* Add after tmp. */
    tmp->_next = self;
    return self;
}


#import "_synthElementMethods.m"

@end

