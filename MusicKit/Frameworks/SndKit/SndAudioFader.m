////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioFader.m
//  SndKit
//
//  Created by S Brandon on Mon Jun 23 2001. <stephen@brandonitconsulting.co.uk>
//  Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and non-
//  commercial purposes so long as the author attribution and copyright messages
//   remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import "SndStreamManager.h"
#import "SndAudioFader.h"
#ifndef M_PI
#define M_PI            3.14159265358979323846  /* pi */
#endif

static id ENVCLASS=nil;

@interface SndAudioFader (SKPrivate)

- (BOOL)_rampEnvelope:(id <SndEnveloping, NSObject>) theEnv
                 from:(float)startRampLevel
                   to:(float)endRampLevel
            startTime:(double)startRampTime
              endTime:(double)endRampTime;
- (void)_setStaticPointInEnvelope:(id <SndEnveloping, NSObject>) theEnv
                             yVal:(float)yVal
                             xVal:(double)atTime;
@end

@interface _SndFaderStorage : NSObject
{
@public
    double x1,x2;
    float l1,l2;
    float r1,r2;
}
+ (void) addToArray:(NSMutableArray *)store
                 x1:(double)newX1
                 x2:(double)newX2
                 l1:(float)newL1
                 l2:(float)newL2
                 r1:(float)newR1
                 r2:(float)newR2;
@end

@implementation _SndFaderStorage
+ (void) addToArray:(NSMutableArray *)store
                 x1:(double)newX1
                 x2:(double)newX2
                 l1:(float)newL1
                 l2:(float)newL2
                 r1:(float)newR1
                 r2:(float)newR2
{
    _SndFaderStorage *s = [[_SndFaderStorage alloc] init];
    s->x1=newX1;
    s->x2=newX2;
    s->l1=newL1;
    s->l2=newL2;
    s->r1=newR1;
    s->r2=newR2;
    [store addObject:s];
    [s release];
}

@end

@implementation SndAudioFader

+ (void)setEnvelopeClass:(id)aClass
{
    ENVCLASS = aClass;
}

+ (id)envelopeClass
{
    return ENVCLASS;
}

- (void)setEnvelopeClass:(id)aClass
{
    envClass = aClass;
}

- (id)envelopeClass
{
    return envClass;
}

+ (void)initialize
{
    if (self == [SndAudioFader class]) {
        [SndAudioFader setVersion:1];
    }
    ENVCLASS = [SndEnvelope class]; /* default envelope */
}

- init
{
    [super init];
    lock = [[NSLock alloc] init];
    bearingEnvLock = [[NSLock alloc] init];
    ampEnvLock = [[NSLock alloc] init];
    ampEnv = nil;
    staticAmp = 1;
    bearingEnv = nil;
    staticBearing = 0;
    envClass = ENVCLASS;
    return self;
}

/*
 * "instantaneous" getting and setting; applies from start of buffer
 */
- setBearing:(float)bearing clearingEnvelope:(BOOL)clear 
{
    double nowTime;
    if (clear) {
        if (bearingEnv) {
            [bearingEnvLock lock];
            [bearingEnv release];
            bearingEnv = nil;
            [bearingEnvLock unlock];
        }
        staticBearing = bearing;
        return self;
    }
    /* if there's an envelope there, keep it and insert new value */
    if (bearingEnv) {
        nowTime = [(SndStreamManager *) [SndStreamManager defaultStreamManager] nowTime];
        [self setBearing:bearing atTime:nowTime];
    }
    staticBearing = bearing;
    return self;
}

- (float)getBearing
{
    double nowTime;
    float yVal;
    if (bearingEnv == nil) {
        return staticBearing;
    }
    nowTime = [(SndStreamManager *)[SndStreamManager defaultStreamManager] nowTime];
    [bearingEnvLock lock];
    yVal = [bearingEnv lookupYForX:nowTime];
    [bearingEnvLock unlock];
    return yVal;
}

- setAmp:(float)amp clearingEnvelope:(BOOL)clear
{
    double nowTime;
    if (clear) {
        [ampEnvLock lock];
        if (ampEnv) {
            [ampEnv release];
            ampEnv = nil;
        }
        [ampEnvLock unlock];
        staticAmp = amp;
        return self;
    }
    /* if there's an envelope there, keep it and insert new value */
    if (ampEnv) {
        nowTime = [(SndStreamManager *)[SndStreamManager defaultStreamManager] nowTime];
        [self setAmp:amp atTime:nowTime];
    }
    staticAmp = amp;
    return self;
}

- (float)getAmp
{
    double nowTime;
    float yVal;
    if (!ampEnv) {
        return staticAmp;
    }
    nowTime = [(SndStreamManager *)[SndStreamManager defaultStreamManager] nowTime];
    [ampEnvLock lock];
    yVal = [ampEnv lookupYForX:nowTime];
    [ampEnvLock unlock];
    return yVal;
}

BOOL middleOfMovement(double xVal, id <SndEnveloping,NSObject> anEnvelope)
{
//    BOOL afterRampStart,beforeRampEnd;
    int prevBreakpoint = [anEnvelope breakpointIndexBeforeOrEqualToX:xVal];
    if (prevBreakpoint == -1) {
        return NO;
    }
    if ([anEnvelope lookupFlagsForBreakpoint:prevBreakpoint] &
        SND_FADER_ATTACH_RAMP_RIGHT) {
        return YES;
    }
    return NO;
}

/* Official "future movement" API - moves faders about at arbitrary times in
 * the future.
 */
- (BOOL)_rampEnvelope:(id <SndEnveloping, NSObject>) theEnv
                 from:(float)startRampLevel
                   to:(float)endRampLevel
            startTime:(double)startRampTime
              endTime:(double)endRampTime
{
/* Need to watch for the following problems:
 * 1 locking
 * 2 sticking this movement in the middle of another movement, or spanning
 *   several other breakpoints
 *   - if our new ramp spans any breakpoints, then they will be deleted.
 *     However, any ramp leading into or out of our new ramp will be preserved
 *     by calculating the point where they would have bisected our new ramp,
 *     and inserting a new end point/start point as necessary.
 */
    BOOL dissectsAtStart,dissectsAtEnd;
    int newStartIndex;

    dissectsAtStart = middleOfMovement(startRampTime,theEnv);
    dissectsAtEnd = middleOfMovement(endRampTime,theEnv);

    if (dissectsAtStart || dissectsAtEnd) {
        float   endPrecedingRampLevel;
        float   startSucceedingRampLevel;
        int i;
    // do we span any breakpoints, which we will need to delete?
        int index1 = [theEnv breakpointIndexBeforeOrEqualToX:startRampTime];
        int index2 = [theEnv breakpointIndexAfterX:endRampTime];
    // If index1 == -1, that means that there must be an end dissection,
    // and bp[0] is definitely to be deleted
    // If index2 == -1, that means that our new end point lies beyond the
    // rightmost bp.
        if (index2 == -1) index2 = [theEnv breakpointCount];

    // calculate a new end point and/or start point for the enclosing
    // envelope(s). The flags for these will be SND_FADER_ATTACH_RAMP_LEFT
    // and SND_FADER_ATTACH_RAMP_RIGHT, respectively.

        if (dissectsAtStart) {
            endPrecedingRampLevel = [theEnv lookupYForX:startRampTime];
        }
        if (dissectsAtEnd) {
            startSucceedingRampLevel = [theEnv lookupYForX:endRampTime];
        }

    // do the deletion, backwards
        for (i = index2 - 1 ; i > index1 ; i-- ) {
            [theEnv removeBreakpoint:i];
        }
    // stick in our new preceding/succeeding ramps, if necessary
        if (dissectsAtStart) {
        // we know at which bp this should be inserted
            [theEnv insertXValue:startRampTime
                          yValue:endPrecedingRampLevel
                           flags:SND_FADER_ATTACH_RAMP_LEFT
                    atBreakpoint:index1 + 1];
        }
        if (dissectsAtEnd) {
            [theEnv insertXValue:endRampTime
                          yValue:endPrecedingRampLevel
                           flags:SND_FADER_ATTACH_RAMP_RIGHT
                    atBreakpoint:index1 + dissectsAtStart ? 2 : 1];
        }
    }
    // finally, put in new ramp.
    // Note that if there are already breakpoints at the same X value,
    // the new bp is inserted after the last one.
    newStartIndex = [theEnv insertXValue:startRampTime
                                  yValue:startRampLevel
                                   flags:SND_FADER_ATTACH_RAMP_RIGHT];
    NSLog(@"newStartIndex %d, startramptime %f, startRampLevel %f\n",
         newStartIndex,startRampTime,startRampLevel);
    [theEnv insertXValue:endRampTime
                  yValue:endRampLevel
                   flags:SND_FADER_ATTACH_RAMP_LEFT
            atBreakpoint:newStartIndex + 1];

    return YES;
}

- (BOOL)rampAmpFrom:(float)startRampLevel
                 to:(float)endRampLevel
          startTime:(double)startRampTime
            endTime:(double)endRampTime
{
    BOOL ret;
    [ampEnvLock lock];
    if (!ampEnv) {
        ampEnv = [[envClass alloc] init];
    }
    ret = [self _rampEnvelope:ampEnv
                         from:startRampLevel
                           to:endRampLevel
                    startTime:startRampTime
                      endTime:endRampTime];
    [ampEnvLock unlock];
    return ret;
}

- (BOOL)rampBearingFrom:(float)startRampLevel
                     to:(float)endRampLevel
              startTime:(double)startRampTime
                endTime:(double)endRampTime;
{
    BOOL ret;
    [bearingEnvLock lock];
    if (!bearingEnv) {
        bearingEnv = [[envClass alloc] init];
    }
    ret = [self _rampEnvelope:bearingEnv
                         from:startRampLevel
                           to:endRampLevel
                    startTime:startRampTime
                      endTime:endRampTime];
    [bearingEnvLock unlock];
    return ret;
}

/*
 * "future" getting and setting; transparently reads and writes
 * from/to the envelope object(s)
 */
- (void)_setStaticPointInEnvelope:(id <SndEnveloping, NSObject>) theEnv
                             yVal:(float)yVal
                             xVal:(double)atTime
{
    BOOL isRamping;
    /* if there's a following ramp end, delete it.
     * also give the new point an end-of-ramp status
     */
    isRamping = middleOfMovement(atTime,theEnv);
    if (!isRamping) {
        [theEnv insertXValue:atTime yValue:yVal flags:0];
    }
    else {
        int endBp = [theEnv breakpointIndexAfterX:atTime];
        if (endBp == -1) {
            /* A ramp was started but not finished. Just set the
             * new bp, and change the status of the previous bp
             * to static (flag 0)
             */
            int precedingBpIndex =
                [theEnv breakpointIndexBeforeOrEqualToX:atTime];
            double newX  = [theEnv lookupXForBreakpoint:precedingBpIndex];
            float  newY  = [theEnv lookupYForBreakpoint:precedingBpIndex];
            int    flags = [theEnv lookupFlagsForBreakpoint:precedingBpIndex];
            flags = flags & SND_FADER_ATTACH_RAMP_LEFT;
            [theEnv replaceXValue:newX
                           yValue:newY
                            flags:flags
                     atBreakpoint:precedingBpIndex];
            [theEnv insertXValue:atTime yValue:yVal flags:0];
        }
        else {
        /* We need to create a new end-of-ramp along the same trajectory
         * as was there before, then switch immediately to the new static
         * bp
         */
            float newEndY = [theEnv lookupYForX:atTime];
            [theEnv removeBreakpoint:endBp];
            [theEnv insertXValue:atTime
                          yValue:yVal
                           flags:0
                    atBreakpoint:endBp];
            [theEnv insertXValue:atTime
                          yValue:newEndY
                           flags:SND_FADER_ATTACH_RAMP_LEFT
                    atBreakpoint:endBp];

        }
    }
}

- setBearing:(float)bearing atTime:(double)atTime
{
//    BOOL isRamping;
    [bearingEnvLock lock];
    if (!bearingEnv) {
        bearingEnv = [[envClass alloc] init];
    }

    [self _setStaticPointInEnvelope:bearingEnv
                               yVal:bearing
                               xVal:atTime];
    [bearingEnvLock unlock];
    return self;
}

- (float)getBearingAtTime:(double)atTime
{
    double yVal;
    if (!bearingEnv) return staticBearing;
    [bearingEnvLock lock];
    yVal = [bearingEnv lookupYForX:atTime];
    [bearingEnvLock unlock];
    return yVal;
}

- setAmp:(float)amp atTime:(double)atTime
{
    [ampEnvLock lock];
    if (!ampEnv) {
        ampEnv = [[envClass alloc] init];
    }
    [self _setStaticPointInEnvelope:ampEnv
                               yVal:amp
                               xVal:atTime];
    [ampEnvLock unlock];
    return self;
}

- (float)getAmpAtTime:(double)atTime
{
    double yVal;
    if (!ampEnv) return staticAmp;
    [ampEnvLock lock];
    yVal = [ampEnv lookupYForX:atTime];
    [ampEnvLock unlock];
    return yVal;
}

- (void) dealloc
{
    [ampEnvLock release];
    [bearingEnvLock release];
    [ampEnv release];
    [bearingEnv release];
    [super dealloc];
}

- (int) paramCount
{
    return 0;
}

- (float) paramValue: (int) index
{
    return 0;
}

- (NSString*) paramName: (int) index
{
    return nil;
}

- setParam: (int) index toValue: (float) v
{
    return self;
}

- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB
                        outputBuffer: (SndAudioBuffer*) outB
{
  double nowTime;
  /* bypass if possible */
  if (!ampEnv && staticAmp == 1 && !bearingEnv && staticBearing == 0) {
      return FALSE;
  }

  nowTime = [[self audioProcessorChain] nowTime];

#define bearingFun1(theta)    fabs(cos(theta))
#define bearingFun2(theta)    fabs(sin(theta))
  return NO;

  [lock lock];

  if ([outB lengthInSamples] == [inB lengthInSamples] &&
      [outB channelCount]    == [inB channelCount]    &&
      [outB dataFormat]      == [inB dataFormat]      &&
      [inB dataFormat]       == SND_FORMAT_FLOAT      &&
      [inB channelCount]     == 2) {
      
      float *inD  = (float*) [inB  data];
      float *outD = (float*) [outB data];
      long   len  = [inB  lengthInSamples], i;
      
      if (!ampEnv && !bearingEnv) {
        if (staticBearing == 0) {
          for (i=0;i<len*2;i+=2) {
            outD[i]   = inD[i] * staticAmp;
            outD[i+1] = inD[i+1] * staticAmp;
          }
        }
        else {
          double bearingD = staticBearing * M_PI/180.0 + M_PI/4.0;
          double leftAmpD = staticAmp * bearingFun1(bearingD);
          double rightAmpD = staticAmp * bearingFun2(bearingD);
          for (i=0;i<len*2;i+=2) {
            outD[i]   = inD[i] * leftAmpD;
            outD[i+1] = inD[i+1] * rightAmpD;
          }
        }
      }
      else {
        //here's where the interesting bit goes...
       /* tasks:
        (1) make a copy of the relevant parts of the envelopes so we can
            unlock it as soon as possible
        (2) take account of bearing AND amp envs
        (3) calc offsets within the buffer of any breakpoints that are hit
            in either bearing or amp envelopes.
        (4) make series of loops over the various segments.
           - each loop from x1 to x2
           - the scaling will be different for each channel, but will be
             confined to the same set of segments.
           - for R channel, scaler will go from r1 to r2 (at x1 the scaling
             is r1; at x2, r2). Given iterator i (0 to x2-x1) the scaling
             at each sample is (r1 + i/(x2-x1) * (r2-r1))
        */
        /* assume just for now that we have valid bearing and amp envs. */
            /* these are our new derived envelopes for each channel */
            NSMutableArray *store = [[NSMutableArray alloc] initWithCapacity:10];
            int i,count;
 //           int lindx, rindx;
            int ampIndx,bearingIndx;
            int nextAmpIndx,nextBearingIndx;
//            float tempL,tempR;
            int tempAmpFlags,tempBearingFlags;
//            double tempAmpX,tempBearingX;
            float tempAmpY,tempBearingY;
            BOOL hasAmp=NO,hasBearing=NO;
            double x=nowTime;
            double maxX = x + [outB duration];
            /* Find the relevant bps in each envelope.
             * We only need to take things from the last bp before the buffer
             * begins.
             */

            /************************************************************/
            #define AMP_FIRST 1
            #define BEARING_FIRST 2

//            float amp,bearing;
            int maxAmpBps;
            int maxBearingBps;

            int lowest = 0;
            double nextAmpX, nextBearingX, nextX;
            float nextAmpY, nextBearingY;
            float ampMult;
            float bearingMult;

            NSLog(@"x %f, maxX %f\n",x,maxX);
            if (!bearingEnv) bearingEnv = [[envClass alloc] init];
            if (!ampEnv) ampEnv = [[envClass alloc] init];

            maxAmpBps = [ampEnv breakpointCount] - 1;
            maxBearingBps = [bearingEnv breakpointCount] - 1;
            do {
                if (!lowest) { /* first time around */
                    tempAmpY     = [ampEnv lookupYForX:x];
                    tempBearingY = [bearingEnv lookupYForX:x];
                    ampIndx      = [ampEnv breakpointIndexBeforeOrEqualToX:x];
                    bearingIndx  = [bearingEnv breakpointIndexBeforeOrEqualToX:x];
                }
                else {
                    tempAmpY = nextAmpY;
                    tempBearingY = nextBearingY;
                    if (lowest == AMP_FIRST) {
                    /* last time thru, an amp bp came before the next bearing bp */
                        if (nextAmpIndx > maxAmpBps) ampIndx = -1;
                        else ampIndx = nextAmpIndx;
                        /* bearingIndx stays where it was: we still need to refer
                         * to it for its flags
                         */
                    }
                    else {
                        if (nextBearingIndx > maxBearingBps) bearingIndx = -1;
                        else bearingIndx = nextBearingIndx;
                    }
                }

                nextAmpIndx = ampIndx + 1;
                nextBearingIndx = bearingIndx + 1;

                /* immediate termination if we have no enveloping yet */
                NSLog(@"ampIndx (previous point) %d, bearingindx %d\n",ampIndx,bearingIndx);
                if ((ampIndx == -1) && (bearingIndx == -1)) break;

                if (ampIndx != -1) {
                    tempAmpFlags = [ampEnv lookupFlagsForBreakpoint:ampIndx];
                    hasAmp = YES;
                }
                else hasAmp = NO;

                if (bearingIndx != -1) {
                    tempBearingFlags = [bearingEnv lookupFlagsForBreakpoint:ampIndx];
                    hasBearing = YES;
                }
                else hasBearing = NO;

                /* So that's the "from" -- what is the "to"?
                 * Better check to see whether the next amp, or the next bearing
                 * segment comes next
                 */
                /* FIXME: need to check properly for max breakpoints */
                /* what is happening here is that if the lookup for previous bp
                   comes back with -1, we are still assuming that there is a valid one
                   there, and looking for that one + 1 (==0)
                 */
                //if (!hasAmp && )
                if ((nextAmpX=[ampEnv lookupXForBreakpoint:nextAmpIndx]) <=
                    (nextBearingX=[bearingEnv lookupXForBreakpoint:nextBearingIndx])
                    && nextAmpIndx <= maxAmpBps ) {
                    lowest = AMP_FIRST;
                }
                else {
                    lowest = BEARING_FIRST;
                }
                NSLog(@"NextAmpX %f\n",nextAmpX);
                nextX = (lowest == AMP_FIRST) ? nextAmpX : nextBearingX;
                nextAmpY = [ampEnv lookupYForX:nextX];
                nextBearingY = [bearingEnv lookupYForX:nextX];


                /* at this point I have a complete segment with x1, x2 etc and
                * I want to insert it into array
                */
                ampMult = ((tempAmpFlags & SND_FADER_ATTACH_RAMP_RIGHT) ?
                    nextAmpY : tempAmpY);
                bearingMult = ((tempBearingFlags & SND_FADER_ATTACH_RAMP_RIGHT) ?
                    nextBearingY : tempBearingY);
                    
                [_SndFaderStorage addToArray:store
                    x1:x
                    x2:nextX
                    l1:tempAmpY * (tempBearingY - 45 ) / -90
                    l2:tempAmpY * (tempBearingY + 45 ) / 90
                    r1:ampMult * (bearingMult - 45) / -90
                    r2:ampMult * (bearingMult + 45) / 90
                    ];
                
                x = nextX;


            } while (x <= maxX);

            /* go and do loop again */

            /* now do the processing based on the line segs in store */
            /* bla bla bla */
            count = [store count];
            NSLog(@"Fader Storage listing (%d points)\n",count);
            for (i = 0 ; i < count ; i++) {
                _SndFaderStorage *t = [store objectAtIndex:i];
                NSLog(@"From x:%f To x: %f L1:%f L2:%f R1:%f R2:%f\n",
                t->x1,t->x2,t->l1,t->l2,t->r1,t->r2);
            }


            [store release];
      }
  }
  else
    NSLog(@"SndAudioFader::processreplacing: ERR: Buffers have different formats\n");

  [lock unlock];

  return NO; /* change to YES when I actually write the changes */
}

@end

