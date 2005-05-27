/* Modification history:
 *
 * 3/25/96/daj - created from AsympUG.m
 *
 * Current limitations:
 *
 * portamento not supported
 * no shared envelopes yet
 */

/* Examples:

   1. [(0,0)(1,1)|(0,0)]

   firstVal = 0;
   arr[0] - info for getting to (1,1)
   arr[1] - stick info
   arr[3] - info for getting to (0,0)
   arr[4] - stick info
   stickPoint = 1

   1. [(0,0)(1,1)|]

   firstVal = 0;
   arr[0] - info for getting to (1,1)
   arr[1] - stick info
   stickPoint = 1

   1. [(0,0)(1,1)(0,0)]

   firstVal = 0;
   arr[0] - info for getting to (1,1)
   arr[1] - info for getting to (0,0)
   arr[2] - stick info
   stickPoint = MAXINT
*/

#import <MusicKit/MusicKit.h>
#import <objc/List.h> /*sb: for List */
#import "_exportedPrivateMusickit.h"
#import "AsympenvUG.h"

#ifndef MAX
#define  MAX(A,B)	((A) > (B) ? (A) : (B))
#endif

#define EQU(_x,_y) ((_x>_y)?(_x-_y<.0001):(_y-_x<.0001))

@interface _EnvKey:List {
    double yScale;
    double yOffset;
    double timeScale;
    double releaseTimeScale;
    void *func;
    id env;
} 
-(void)_setVals:(double)ys :(double)yOff :(double)tScale 
  :(double)releaseTScale :(void *)fnc :e;
-(void)_getVals:(double *)ys :(double *)yOff :(double *)tScale 
  :(double *)releaseTScale :(void **)fnc :(id *)e;
-(id)_envelope;
-(unsigned)hash;
-(BOOL)isEqual:obj;
@end

@implementation _EnvKey 

-(void)_getVals:(double *)ys :(double *)yOff :(double *)tScale 
  :(double *)releaseTScale :(void **)fnc :(id *)e
{
    *ys = yScale;
    *yOff = yOffset;
    *tScale = timeScale;
    *releaseTScale = releaseTimeScale;
    *fnc = func;
    *e = env;
}

-_envelope {
    return env;
}

-(void)_setVals:(double)ys :(double)yOff :(double)tScale 
  :(double)releaseTScale :(void *)fnc :e
{
    yScale = ys;
    yOffset = yOff;
    timeScale = tScale;
    releaseTimeScale = releaseTScale;
    func = fnc;
    env = e;
}
  
-(unsigned)hash {
    return [env hash];
}

-(BOOL)isEqual:anotherObj {
    double ys,yOff,tScale,releaseTScale;
    void *fnc;
    id e;
    [anotherObj _getVals:&ys :&yOff :&tScale :&releaseTScale
     :&fnc :&e];
    return ((e == env) && EQU(ys,yScale) && EQU(yOff,yOffset) &&
	    EQU(tScale,timeScale) && EQU(releaseTScale,releaseTimeScale) &&
	    (fnc == func));
}

@end

static void memoryWarning(void) {
    if (MKIsTraced(MK_TRACEUNITGENERATOR))
      fprintf(stderr,"Insufficient envelope memory at time %.3f. \n",MKGetTime());
}


@implementation AsympenvUG

enum args { antrg, aout, rate, trg, andur, anrate, dur, val };

#import "asympenvUGInclude.m"

+(BOOL)shouldOptimize:(unsigned) arg
{
    return (arg == aout);
    /* All others are running terms! */
}

/* T48COEFF times the "time constant" gives time to decay 48dB exponentially */
// #define T48COEFF 5.25
/* JOS - I get 45.6 dB decay from the above constant, using the formula
   -20 Log[10,Exp[-5.25]] in Mathematica.  The formula for T48COEFF is
   -N[Log[10^(-48/20)]] = 5.52620422318571
*/
#define T48COEFF 5.52620422318571

/*
  We scale the time-constants along with the
  "interruption intervals".  Otherwise, as an envelope is shortened, for
  example, it may "melt down", i.e., there is no longer time for an envelope
  segment to reach its target.  If time is to be scaled by g, then we go from
  exp(-t/rate) to exp(-g*t/rate).  Thus, the time constant should be
  divided by the scale factor g. - Julius
*/

#define MAXINTRATE 0xfffff /* Can't let it get too big cause of bug in asymp */
#define MAXRATE .125
#define MINSMOOTH .0001 /* Otherwise exp() goes ape on 486 */

+orchestraWillCreate: (id) sender
{
#define TICK_DUR (DSP_CLOCK_PERIOD/DSPMK_I_NTICK)
    MKLeafUGStruct *p = [self classInfo];
    /* Without advance-to-next-breakpoint code, it's 100/150 so we 
     * add a bit of overhead for that.
     */
    p->computeTime = 120 * TICK_DUR;
    p->offChipComputeTime = 170 * TICK_DUR;
    return self;
}

static id clockConductor = nil;

-init
{
  char version;
  int release;
  [super init];
  [orchestra getMonitorVersion:&version release:&release];
  if (version != 'A')
    MKErrorCode(MK_dspMonitorVersionError,[self class]);
  _samplingRate = [orchestra samplingRate];
  _smoothConstant = -T48COEFF / _samplingRate;
  _tickRate = _samplingRate/DSPMK_NTICK + 0.5;
  return self;
}

-_deallocMem
{
    [durMem mkdealloc];
    durMem = nil;
    [targetMem mkdealloc];
    targetMem = nil;
    [rateMem mkdealloc];
    rateMem = nil;
    anEnv = nil;
    return self;
}

#define STICK_VALUE 0xFFFFFF  /* -1 as a DSP integer */

static double smoothingToRate(AsympenvUG *self,double smoothingVal)
{
    double d;
    if (smoothingVal > MINSMOOTH) {
	d = 1 - exp(self->_smoothConstant/smoothingVal);
    } else return MAXINTRATE;
    return (d >= MAXRATE) ? MAXINTRATE : _MKDoubleToFix24(d);
}

-runSelf
{
    if (!anEnv)
      return self;
    /* The "next" slope/dur is the first, since we start "paused" */
    MKSetUGAddressArg(self,andur,durMem);
    MKSetUGAddressArg(self,anrate,rateMem);
    MKSetUGAddressArg(self,antrg,targetMem);
    if (useInitialValue)
      MKSetUGDatumArg(self,val,firstVal);
    /* Poking a zero forces it to get next point from memory */
    MKSetUGDatumArg(self,dur,0); 
    envTriggerTime = MKGetTime();
    return self;
}

-(double)finishSelf
  /* Set envelope to final decay portion */
{
    if (!anEnv)
      return 0;
    if (stickPoint == MAXINT) {  /* No stick point, nothing to do */
	/* Guess on where we are and when we'll be done */
	return releaseTime - (MKGetTime() - envTriggerTime);  
    }
    else if (stickPoint + 1 == [anEnv pointCount]) {
	/* Stick point is at end of envelope */
	return 0;
    }
    MKSetUGAddressArgToInt(self,andur,[durMem address]+stickPoint+1);
    MKSetUGAddressArgToInt(self,antrg,[targetMem address]+stickPoint+1);
    MKSetUGAddressArgToInt(self,anrate,[rateMem address]+stickPoint+1);
    MKSetUGDatumArg(self,dur,0); /* Force it to get next point */
    return releaseTime;
}

static id keyHashTable = nil;
static id lookupObj = nil; /* Reusable lookup obj */

static id findKeyObjFor(double yScale,double yOffset,double timeScale,
			double releaseTimeScale,void *func,id env)
{
    id valObj;
    if (!keyHashTable)
      keyHashTable = [[HashTable alloc] init];
    if (!lookupObj)
      lookupObj = [[_EnvKey alloc] init];
    [lookupObj _setVals:yScale :yOffset :timeScale :releaseTimeScale 
     :func :env];
    valObj = [keyHashTable valueForKey:lookupObj];
    if (valObj) 
      return valObj;
    valObj = lookupObj;
    lookupObj = nil;
    [keyHashTable insertKey:valObj value:valObj];
    [valObj addObject:[Object alloc]]; /* Just dummy unique objects */
    [valObj addObject:[Object alloc]];
    [valObj addObject:[Object alloc]];
    return valObj;
}

static id lostObjectList = nil;
/* 
 * We can't free the alloc objects because they are keys in
 * the shared object table
 */

+(void)envelopeHasChanged:(MKEnvelope *)env
  /* 
   * We replace the place-holder objects with new ones.
   * But we can't free them until the Orchestra is closed.
   */
{
//    unsigned int count = 0; 
    const   void  *key; 
    void  *value; 
    NXHashState  state = [keyHashTable initState]; 
    id valObj;
    if (!lostObjectList)
      lostObjectList = [[List alloc] init];
    while ([keyHashTable nextState: &state key: &key value: &value]) {
	valObj = (id)key;
	if ([valObj _envelope] == env) {
	    [lostObjectList addObject:[valObj objectAt:0]];
	    [lostObjectList addObject:[valObj objectAt:1]];
	    [lostObjectList addObject:[valObj objectAt:2]];
	    [valObj empty];
	    [valObj addObject:[Object alloc]]; 
	    [valObj addObject:[Object alloc]];
	    [valObj addObject:[Object alloc]];
	}
    }
}

+(void)freeKeyObjects {
    [lostObjectList freeObjects];
    [lostObjectList empty];
}

-setEnvelope:anEnvelope yScale:(double)yScaleVal yOffset:(double)yOffsetVal
 xScale:(double)xScaleVal releaseXScale:(double)rXScaleVal 
 funcPtr:(double(*)())func 
  /* Inits envelope handler with the values specified. func is described above.
   */
{
    int i,arrCount,count,j,k;
    id keyObj;
    double *xArray;
    double *yArray;
    double *sArray;
    double samplingPeriod,defaultSmoothing;
    DSPDatum *targetVals,*durVals,*rateVals;
//    double duration;
    double *durations;
    BOOL doTargets,doRates,doDurs,validStickPoint;
    if (!anEnvelope)
      if (anEnv) {
	  [self abortEnvelope];
	  return nil;
      }

    [self _deallocMem];
    anEnv = anEnvelope;
    yScale = yScaleVal;
    yOffset = yOffsetVal;
    timeScale = xScaleVal;
    releaseTimeScale = rXScaleVal;
    scalingFunc = func;
    useInitialValue = YES;
    /* First see if it already exists on the DSP */
    keyObj = 
      findKeyObjFor(yScale,yOffset,timeScale,releaseTimeScale,scalingFunc,
		    anEnv);
    targetMem = [orchestra sharedObjectFor:[keyObj objectAt:0]]; 
    durMem = [orchestra sharedObjectFor:[keyObj objectAt:1]];
    rateMem = [orchestra sharedObjectFor:[keyObj objectAt:2]];
    if (targetMem && durMem && rateMem) {
	/* We lucked out. Just set up to go */
	/* Just need to set firstVal and releaseTime */
	yArray = [anEnv yArray];
	xArray = [anEnv xArray],
	stickPoint = [anEnv stickPoint];
	count = [anEnv pointCount];
	validStickPoint = (stickPoint < count);
	firstVal = DSPDoubleToFix24(yArray[0] * yScaleVal + yOffsetVal);
	if (xArray) {
	    releaseTime = 0;
	    if (validStickPoint) 
	      for (j = stickPoint+1, i=stickPoint; j<count; i++, j++)
		releaseTime += (xArray[j]-xArray[i]) * releaseTimeScale;
	    else /* releaseTime is whole env */
	      for (i=0, j=1; j<count; i++, j++) 
		releaseTime += (xArray[j]-xArray[i]) * timeScale;
	}
	else {
	    samplingPeriod = [anEnv samplingPeriod] * timeScale;
	    if (validStickPoint)
	      releaseTime = (count - stickPoint) * samplingPeriod;
	    else 
	      releaseTime = samplingPeriod * count;
	}
	releaseTime += MKGetPreemptDuration();
	MKSetUGDatumArg(self,dur,STICK_VALUE);
	return self;
    }

    /* Otherwise, it's a new envelope to this DSP. Need to
     * compute tables. 
     */
    /* But it could be just one table that needs to be recomputed
       (because of lazy garbage collection).
       So we optimize this case.
     */
    doTargets = !targetMem;
    doDurs = !durMem;
    doRates = !rateMem;
    xArray = [anEnv xArray],
    yArray = [anEnv yArray];
    sArray = [anEnv smoothingArray];
    stickPoint = [anEnv stickPoint];
    defaultSmoothing = [anEnv defaultSmoothing];
    count = [anEnv pointCount];
    arrCount = count;
    validStickPoint = (stickPoint < count);
    if (validStickPoint)
      arrCount++;
    if (doTargets) {
	targetMem = [orchestra allocSynthData:MK_xData length:arrCount];
	if (!targetMem) { /* Bad lossage */
	    memoryWarning();
	    return nil;
	}
	[orchestra installSharedObject:targetMem
         for:[keyObj objectAt:0]];
	firstVal = DSPDoubleToFix24(yArray[0] * yScaleVal + yOffsetVal);
	targetVals = malloc(sizeof(DSPDatum)*arrCount);
	if (validStickPoint) {
	    for (i=0, j=1; i<stickPoint; i++, j++) 
	      targetVals[i] = 
		DSPDoubleToFix24(yArray[j]*yScaleVal+yOffsetVal);
	    targetVals[stickPoint] = targetVals[stickPoint-1];
	    for (j = stickPoint+1, i=stickPoint; j<count; i++, j++) 
	      targetVals[j] = 
		DSPDoubleToFix24(yArray[j]*yScaleVal+yOffsetVal);
	}
	else 
	  for (i=0, j=1; j<count; i++, j++) 
	    targetVals[i] = 
	      DSPDoubleToFix24(yArray[j]*yScaleVal+yOffsetVal);
	targetVals[arrCount-1] = targetVals[arrCount-2];
	[targetMem setData:targetVals];
	free(targetVals);
    }
    if (doDurs || doRates) { /* Both need durations array */
	durations = malloc(sizeof(double)*(count-1));
	if (xArray) {
	    releaseTime = 0;
	    if (validStickPoint) {
		for (i=0, j=1; i<stickPoint; i++, j++) 
		  durations[i] = (xArray[j]-xArray[i]) * timeScale;
		for (j = stickPoint+1, i=stickPoint; j<count; i++, j++) {
		    durations[i] = (xArray[j]-xArray[i]) * releaseTimeScale;
		    releaseTime += durations[i];
		}
	    }
	    else /* releaseTime is whole env */
	      for (i=0, j=1; j<count; i++, j++) {
		  durations[i] = (xArray[j]-xArray[i]) * timeScale;
		  releaseTime += durations[i];
	      }
	}
	else {
	    samplingPeriod = [anEnv samplingPeriod] * timeScale;
	    if (validStickPoint)
	      releaseTime = (count - stickPoint) * samplingPeriod;
	    else 
	      releaseTime = samplingPeriod * count;
	    for (i=0; i<count; i++)
	      durations[i] = samplingPeriod;
	}
	releaseTime += MKGetPreemptDuration();
    }
    if (doDurs) {
	durMem = [orchestra allocSynthData:MK_yData length:arrCount];
	if (!durMem) {
	    [targetMem mkdealloc];
	    memoryWarning();
	    free(durations);
	    return nil;
	}
	[orchestra installSharedObject:durMem
         for:[keyObj objectAt:1]];
	durVals = malloc(sizeof(DSPDatum)*arrCount);
	if (validStickPoint) {
	    for (i=0, j=1; i<stickPoint; i++, j++) 
	      durVals[i] = durations[i]*_tickRate;
	    durVals[stickPoint] = STICK_VALUE;
	    for (j = stickPoint+1, i=stickPoint; j<count; i++, j++) 
	      durVals[j] = durations[i] * _tickRate;
	}
	else { /* releaseTime is whole env */
	    releaseTime = 0;
	    for (i=0, j=1; j<count; i++, j++) 
	      durVals[i] = durations[i] * _tickRate;
	}
	durVals[arrCount-1] = STICK_VALUE;
	[durMem setData:durVals];
	free(durVals);
    }
    if (doRates) {
	rateMem = [orchestra allocSynthData:MK_yData length:arrCount];
	if (!rateMem) {
	    [durMem mkdealloc];
	    [targetMem mkdealloc];
	    memoryWarning();
	    free(durations);
	    return nil;
	}
	[orchestra installSharedObject:rateMem
         for:[keyObj objectAt:2]];
	rateVals = malloc(sizeof(DSPDatum)*arrCount);
	if (validStickPoint) {
	    for (i=0, j=1; i<stickPoint; i++, j++) {
		if (sArray)
		  rateVals[i] = smoothingToRate(self,durations[i]*sArray[j]);
		else rateVals[i] = 
		  smoothingToRate(self,durations[i]*defaultSmoothing);
	    }
	    rateVals[stickPoint] = rateVals[stickPoint-1];
	    for (j = stickPoint+1, i=stickPoint; j<count; i++, j++) {
		if (sArray)
		  rateVals[j] = smoothingToRate(self,durations[i]*sArray[j]);
		else rateVals[j] = 
		  smoothingToRate(self,durations[i]*defaultSmoothing);
	    }
	}
	else { 
	    for (i=0, j=1; j<count; i++, j++) {
		if (sArray)
		  rateVals[i] = smoothingToRate(self,durations[i]*sArray[j]);
		else rateVals[i] = 
		  smoothingToRate(self,durations[i]*defaultSmoothing);
	    }
	}
	rateVals[arrCount-1] = rateVals[arrCount-2];
	[rateMem setData:rateVals];
	free(rateVals);
    }
    MKSetUGDatumArg(self,dur,STICK_VALUE);
    if (doDurs || doRates)
      free(durations);
    return self;
}

-resetEnvelope:anEnvelope yScale:(double)yScaleVal yOffset:(double)yOffsetVal
    xScale:(double)xScaleVal releaseXScale:(double)rXScaleVal
    funcPtr:(double(*)())func  transitionTime:(double)transTime
  /* Like setEnvelope:yScaleVal:yOffset:xScale:releaseXScale:funcPtr:, but
     doesn't bind the first value of the envelope.  TransitionTime is the
     absolute time used to get to the second value of the envelope (xScale
     is not used here). If set to MK_NODVAL, the time will be the normal time 
     of the first envelope segment (after any scaling). */
{
    id rtnVal = [self setEnvelope:anEnvelope yScale:yScaleVal 
	       yOffset:yOffsetVal xScale:xScaleVal 
	       releaseXScale:(double)rXScaleVal funcPtr:func];
    useInitialValue = NO;
    _transitionTime = transTime;
    return rtnVal;
}

-setOutput:aPatchPoint
  /* Set output of ramper */
{
    return MKSetUGAddressArg(self,aout,aPatchPoint);
}

-setTargetVal:(double)aVal
  /* Sets the target of the exponential.
     If the receiver is already
     processing an envelope, that envelope is not interrupted. The new
     point is simply inserted. */
{
    return MKSetUGDatumArg(self,trg,_MKDoubleToFix24(aVal));
}

-setCurVal:(double)aVal
  /* Sets the current value of the exponential.
     If the receiver is already
     processing an envelope, that envelope is not interrupted. The new
     point is simply inserted. */
{
    DSPFix48 aFix48;
    DSPDoubleToFix48UseArg(aVal,&aFix48);
    return MKSetUGDatumArgLong(self,val,&aFix48);
}

static id setRate(AsympenvUG *self,double aVal)
{
    DSPDatum r = (aVal >= MAXRATE) ? MAXINTRATE : _MKDoubleToFix24(aVal);
    return MKSetUGDatumArg(self,rate,r);
}

-setRate:(double)aVal
  /* Sets the rate of the exponential. (1-e^T/tau), where T is sampling
     period and tau is the time constant.
     If the receiver is already
     processing an envelope, that envelope is not interrupted. The new
     point is simply inserted. */
{
    return setRate(self,aVal);
}

static id setT60(AsympenvUG *self,double seconds)
    /* This uses the approximation 1-exp(x) = -x, which is close as long
     * as x doesn't approach 0.
     * The truly correct value here would be 1-exp(-7.0/seconds*samplingRate)
     */
{
    return setRate(self,7.0/(seconds * self->_samplingRate));
}

-setT60:(double)seconds
  /* Sets the time constant of the exponential. Same as
     [self setRate:7.0/(seconds*srate)]. */
{
    return setT60(self,seconds);
}

-setT48:(double)seconds
  /* Sets the time constant of the exponential. Same as
     [self setRate:5.52/(seconds*srate)]. */
{
    return setRate(self,T48COEFF/(seconds * self->_samplingRate));
}

-preemptEnvelope
  /* Head to last point of envelope in time specified by
     MKSetPreemptDuration(). */
{
    int nPts,endOffset;
    double lastVal,dummy1,dummy2;
    if (!anEnv || status == MK_idle)
      return self;
    nPts = [anEnv pointCount];
    MKSetUGDatumArg(self,trg,DSPDoubleToFix24(lastVal));
    setT60(self,MKGetPreemptDuration());
    MKSetUGDatumArg(self,dur,DSPDoubleToFix24(MKGetPreemptDuration()));
    if (stickPoint != MAXINT && stickPoint < nPts) 
      endOffset = nPts;
    else 
      endOffset = nPts-1;
    MKSetUGAddressArgToInt(self,antrg,[targetMem address]+endOffset);
    MKSetUGAddressArgToInt(self,anrate,[rateMem address]+endOffset);
    MKSetUGAddressArgToInt(self,andur,[durMem address]+endOffset);
    return self;
}

-useInitialValue:(BOOL)yesOrNo
{
    useInitialValue = yesOrNo;
    return self;
}

-setYScale:(double)yScaleVal yOffset:(double)yOffsetVal
{
    return self; /* FIXME. Not implemented */
}

-setReleaseXScale:(double)rXScaleVal
{
    return self; /* FIXME. Not implemented */
}

-envelope
  /* Returns envelope or nil if none. */
{
    return anEnv;
}

-abortEnvelope
  /* Use to terminate an envelope before it has completed. */
{
    [self _deallocMem];
    MKSetUGDatumArg(self,dur,STICK_VALUE);
    anEnv = nil;
    return self;
}

-idleSelf
{
    [self setAddressArgToSink:aout]; /* Patch output to sink. */
    [self abortEnvelope];
    return self;
}

-abortSelf
{
    return [self abortEnvelope];
}

-freeSelf
{
    [self _deallocMem];
    return self;
}

-setConstant:(double)aVal
  /* Abort any existing envelope and set both amp and target to the same value. */
{
    DSPFix48 aFix48;
    [self abortEnvelope];
    DSPDoubleToFix48UseArg(aVal,&aFix48);
    MKSetUGDatumArgLong(self,val,&aFix48);
    return self;
}

@end /*added by sb */