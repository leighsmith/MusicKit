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

static SEL bpBeforeOrEqualSel;
static SEL bpAfterSel;
static SEL flagsForBpSel;
static SEL yForBpSel;
static SEL yForXSel;
static SEL xForBpSel;

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


@implementation SndAudioFader

/* forward decl */
float _lookupEnvForX(SndAudioFader *saf, id <SndEnveloping, NSObject> anEnvelope, double theX);

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
    bpBeforeOrEqual = (BpBeforeOrEqualIMP)[envClass instanceMethodFor:bpBeforeOrEqualSel];
    bpAfter = (BpAfterIMP)[envClass instanceMethodFor:bpAfterSel];
    flagsForBp = (FlagsForBpIMP)[envClass instanceMethodFor:flagsForBpSel];
    yForBp = (YForBpIMP)[envClass instanceMethodFor:yForBpSel];
    yForX = (YForXIMP)[envClass instanceMethodFor:yForXSel];
    xForBp = (XForBpIMP)[envClass instanceMethodFor:xForBpSel];
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

    bpBeforeOrEqualSel = @selector(breakpointIndexBeforeOrEqualToX:);
    bpAfterSel = @selector(breakpointIndexAfterX:);
    flagsForBpSel = @selector(lookupFlagsForBreakpoint:);
    yForBpSel = @selector(lookupYForBreakpoint:);
    yForXSel = @selector(lookupYForX:);
    xForBpSel = @selector(lookupXForBreakpoint:);
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
    [self setEnvelopeClass:ENVCLASS];
    uee = NULL;
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
    yVal = _lookupEnvForX(self,bearingEnv,nowTime);
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
    yVal = _lookupEnvForX(self,ampEnv,nowTime);
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
            endPrecedingRampLevel = _lookupEnvForX(self,theEnv,startRampTime);
        }
        if (dissectsAtEnd) {
            startSucceedingRampLevel = _lookupEnvForX(self,theEnv,endRampTime);
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
//    NSLog(@"newStartIndex %d, startramptime %f, startRampLevel %f\n",
//         newStartIndex,startRampTime,startRampLevel);
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
    yVal = _lookupEnvForX(self,bearingEnv, atTime);
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
    _lookupEnvForX(self,ampEnv, atTime);
    [ampEnvLock unlock];
    return yVal;
}

- (void) dealloc
{
    if (uee) free(uee);
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

float _lookupEnvForX(SndAudioFader *saf, id <SndEnveloping, NSObject> anEnvelope, double theX)
{
//    int prevBreakpoint = [anEnvelope breakpointIndexBeforeOrEqualToX:theX];
    int prevBreakpoint = saf->bpBeforeOrEqual(anEnvelope,bpBeforeOrEqualSel,theX);
    if (prevBreakpoint == -1) {
        return 0;
    }
    /* it was a static breakpoint: take last y val and don't interpolate */
//    if (!([anEnvelope lookupFlagsForBreakpoint:prevBreakpoint] & SND_FADER_ATTACH_RAMP_RIGHT))
    if (!(saf->flagsForBp(anEnvelope,flagsForBpSel,prevBreakpoint) &
         SND_FADER_ATTACH_RAMP_RIGHT)) {
//        return [anEnvelope lookupYForBreakpoint:prevBreakpoint];
        return saf->yForBp(anEnvelope,yForBpSel,prevBreakpoint);
    }
    /* let the envelope object do its interpolation */
//    return [anEnvelope lookupYForX:theX];
    return saf->yForX(anEnvelope,yForXSel,theX);

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
        double x = nowTime;
        double maxX = x + [outB duration];
        int xPtr = 0;
        int ampPtr = 0, bearingPtr = 0;
        double ampX = x, bearingX = x;
        double nextAmpX, nextBearingX;
        int nextAmpIndx, nextBearingIndx;
        int countAmp;
        int countBearing;
        int i,j;
        int nextAmpFlags = 0, nextBearingFlags = 0;
        int currentAmpFlags = 0, currentBearingFlags = 0;

        if (!bearingEnv && !ampEnv) {
            [lock unlock];
            return NO;
        }
        [ampEnvLock lock];
        [bearingEnvLock lock];
        if (!bearingEnv) bearingEnv = [[envClass alloc] init];
        else if (!ampEnv) ampEnv = [[envClass alloc] init];

        countAmp = [ampEnv breakpointCount];
        countBearing = [bearingEnv breakpointCount];

        if (!uee) uee = calloc(256,sizeof(SndUnifiedEnvelopeEntry));
        if (!uee) [[NSException exceptionWithName:NSMallocException
                                           reason:@"SndAudioFader envelope"
                                         userInfo:nil] raise];

        /* prime the loop */
        nextAmpIndx = [ampEnv breakpointIndexAfterX:nowTime];
        nextBearingIndx = [bearingEnv breakpointIndexAfterX:nowTime];
        if (nextAmpIndx != -1) {
//            nextAmpX = [ampEnv lookupXForBreakpoint:nextAmpIndx];
//            nextAmpFlags = [ampEnv lookupFlagsForBreakpoint:nextAmpIndx];
            nextAmpX = xForBp(ampEnv,xForBpSel,nextAmpIndx);
            nextAmpFlags = flagsForBp(ampEnv,flagsForBpSel,nextAmpIndx);
        }
        else {
            nextAmpX = maxX + 1;
        }
        if (nextBearingIndx != -1) {
//            nextBearingX = [bearingEnv lookupXForBreakpoint:nextBearingIndx];
//            nextBearingFlags = [bearingEnv lookupFlagsForBreakpoint:nextBearingIndx];
            nextBearingX = xForBp(bearingEnv,xForBpSel,nextBearingIndx);
            nextBearingFlags = flagsForBp(bearingEnv,flagsForBpSel,nextBearingIndx);
        }
        else {
            nextBearingX = maxX + 1;
        }

        /* last chance to bypass: if the first amp and bearing envelope points
         * are beyond the end of the buffer, we eject.
         */
        if ((!countBearing || (nextBearingIndx == 0 && (nextBearingX > maxX))) &&
            (!countAmp || (nextAmpIndx == 0 && (nextAmpX > maxX)))) {
            [bearingEnvLock unlock];
            [ampEnvLock unlock];
            [lock unlock];
            return NO;
        }
        /* always include start of buffer as 1st bp*/
        /* grab some values pertaining to start of envelope */
        {
//            int b4AmpIndx = [ampEnv breakpointIndexBeforeOrEqualToX:nowTime];
//            int b4BearingIndx = [bearingEnv breakpointIndexBeforeOrEqualToX:nowTime];
            int b4AmpIndx = bpBeforeOrEqual(ampEnv,bpBeforeOrEqualSel,nowTime);
            int b4BearingIndx = bpBeforeOrEqual(bearingEnv,bpBeforeOrEqualSel,nowTime);
            if (b4AmpIndx != -1) {
//                uee[xPtr].ampFlags = [ampEnv lookupFlagsForBreakpoint:b4AmpIndx];
                uee[xPtr].ampFlags = flagsForBp(ampEnv,flagsForBpSel,b4AmpIndx);
                uee[xPtr].ampY = _lookupEnvForX(self, ampEnv, ampX);
            } else {
                uee[xPtr].ampFlags = 0;
                uee[xPtr].ampY = 1; /* FIXME what about static amp??? */
            }
            if (b4BearingIndx != -1) {
//                uee[xPtr].bearingFlags = [bearingEnv lookupFlagsForBreakpoint:b4BearingIndx];
                uee[xPtr].bearingFlags = flagsForBp(bearingEnv,flagsForBpSel,b4BearingIndx);
                uee[xPtr].bearingY = _lookupEnvForX(self, bearingEnv, ampX);
            } else {
                uee[xPtr].bearingFlags = 0;
                uee[xPtr].bearingY = 0; /* FIXME what about static bearing??? */
            }
        }
        uee[xPtr].xVal = ampX;
        xPtr++;

        /* do the loop to get all relevant x values within our relevant
         * time period
         */
        while ((nextAmpX < maxX) || (nextBearingX < maxX)) {
            if (nextAmpX <= nextBearingX) {
                uee[xPtr].xVal = nextAmpX;
                uee[xPtr].ampFlags = nextAmpFlags;
//                uee[xPtr].ampY = [ampEnv lookupYForBreakpoint:nextAmpIndx];
                uee[xPtr].ampY = yForBp(ampEnv,yForBpSel,nextAmpIndx);
                uee[xPtr].bearingY = _lookupEnvForX(self, bearingEnv, nextAmpX);
                /* since we're slotting in an unexpected bp as far as the bearing env
                 * is concerned, make sure we tell the new bp to ramp on both sides,
                 * if it needs to
                 */
                if ((currentBearingFlags & SND_FADER_ATTACH_RAMP_RIGHT) ||
                    (nextBearingFlags & SND_FADER_ATTACH_RAMP_LEFT)) {
                    uee[xPtr].bearingFlags = SND_FADER_ATTACH_RAMP_RIGHT | SND_FADER_ATTACH_RAMP_LEFT;
                }
                else {
                    uee[xPtr].bearingFlags = 0;
                }
                xPtr++;
                nextAmpIndx++;
                if (nextAmpIndx < countAmp) {
//                    nextAmpX = [ampEnv lookupXForBreakpoint:nextAmpIndx];
                    nextAmpX = xForBp(ampEnv,xForBpSel,nextAmpIndx);
                    currentAmpFlags = nextAmpFlags;
//                    nextAmpFlags = [ampEnv lookupFlagsForBreakpoint:nextAmpIndx];
                    nextAmpFlags = flagsForBp(ampEnv,flagsForBpSel,nextAmpIndx);
                }
                else {
                    nextAmpX = maxX + 1;
                    currentAmpFlags = nextAmpFlags;
                    nextAmpFlags = 0;
                }
            }
            else {
                uee[xPtr].xVal = nextBearingX;
                uee[xPtr].bearingFlags = nextBearingFlags;
                uee[xPtr].ampY = _lookupEnvForX(self, ampEnv,nextBearingX);
//                uee[xPtr].bearingY = [bearingEnv lookupYForBreakpoint:nextBearingIndx];
                uee[xPtr].bearingY = yForBp(bearingEnv,yForBpSel,nextBearingIndx);
                /* since we're slotting in an unexpected bp as far as the amp env
                 * is concerned, make sure we tell the new bp to ramp on both sides,
                 * if it needs to
                 */
                if ((currentAmpFlags & SND_FADER_ATTACH_RAMP_RIGHT) ||
                    (nextAmpFlags & SND_FADER_ATTACH_RAMP_LEFT)) {
                    uee[xPtr].ampFlags = SND_FADER_ATTACH_RAMP_RIGHT | SND_FADER_ATTACH_RAMP_LEFT;
                }
                else {
                    uee[xPtr].ampFlags = 0;
                }
                xPtr++;
                nextBearingIndx++;
                if (nextBearingIndx < countBearing) {
//                    nextBearingX = [bearingEnv lookupXForBreakpoint:nextBearingIndx];
                    nextBearingX = xForBp(bearingEnv,xForBpSel,nextBearingIndx);
                    currentBearingFlags = nextBearingFlags;
//                    nextBearingFlags = [bearingEnv lookupFlagsForBreakpoint:nextBearingIndx];
                    nextBearingFlags = flagsForBp(bearingEnv,flagsForBpSel,nextBearingIndx);
                }
                else {
                    nextBearingX = maxX + 1;
                    currentBearingFlags = nextBearingFlags;
                    nextBearingFlags = 0;
                }
            }

        } /* end while */
        /* always include end of buffer as last bp*/
        uee[xPtr].xVal = maxX;
        uee[xPtr].ampFlags = nextAmpFlags;
        uee[xPtr].bearingFlags = nextBearingFlags;
        uee[xPtr].ampY = _lookupEnvForX(self, ampEnv, maxX);
        uee[xPtr].bearingY = _lookupEnvForX(self, bearingEnv,maxX);
        xPtr++;

        /* finished with ampEnv and bearingEnv now */
        [bearingEnvLock unlock];
        [ampEnvLock unlock];

        /* log 'em */
#if 0
        NSLog(@"number of points: %d\n",xPtr);
        for (i = 0 ; i < xPtr ; i++) {
            NSLog(@"xVal%f ampFlag %d, ampY %f, bearingFlag %d, bearingY %f\n",
            uee[i].xVal,
            uee[i].ampFlags,
            uee[i].ampY,
            uee[i].bearingFlags,
            uee[i].bearingY );
        }
#endif

        /* use 'em */
//  For R channel, scaler will go from rStartAmp to rEndAmp (at x1 the scaling
//  is rStartAmp; at x2, rEndAmp). Given iterator i (0 to x2-x1) the scaling
//  at each sample is (rStartAmp + i/(x2-x1) * (rEndAmp-rStartAmp))

        { /* new block so I can define variables */
        SndUnifiedEnvelopeEntry *startUee;
        SndUnifiedEnvelopeEntry *endUee;
        float *inD  = (float*) [inB data];
        int currSample,lastSample;
        int timeDiff;
        float lDiff,rDiff;
        float lEndAmp, rEndAmp, lStartAmp, rStartAmp;
        float lScaler, rScaler;
        float ampMult, bearingMult;
        float ll,rr;
        double srxchan = [outB samplingRate] * 2;

        for (i = 0 ; i < xPtr - 1 ; i++) {
            startUee = &(uee[i]);
            endUee = &(uee[i+1]);
            ampMult = ((startUee->ampFlags & SND_FADER_ATTACH_RAMP_RIGHT) ?
                    endUee->ampY : startUee->ampY);
            bearingMult = ((startUee->bearingFlags & SND_FADER_ATTACH_RAMP_RIGHT) ?
                    endUee->bearingY : startUee->bearingY);

            currSample = (startUee->xVal - nowTime) * srxchan;
            lastSample = (endUee->xVal - nowTime) * srxchan;
            timeDiff = lastSample - currSample;
            lStartAmp = startUee->ampY * (startUee->bearingY - 45.0) / -90.0;
            rStartAmp = startUee->ampY * (startUee->bearingY + 45.0) / 90.0;
            lEndAmp = ampMult * (bearingMult - 45.0) / -90.0;
            rEndAmp = ampMult * (bearingMult + 45.0) / 90.0;
            lDiff = lEndAmp - lStartAmp; /* how much we have to scale l from start to end */
            rDiff = rEndAmp - rStartAmp;
//printf("i %d, last sample %d\n",i,lastSample);
            for (j = currSample ; j < lastSample ; j+=2) {
                ll = inD[j];
                rr = inD[j+1];
                lScaler = lStartAmp + lDiff * j/timeDiff;
                rScaler = rStartAmp + rDiff * j/timeDiff;
                inD[j] *= lScaler;
                inD[j+1] *= rScaler;
            }
        }
        } /*end block */
      }
  }
  else
    NSLog(@"SndAudioFader::processreplacing: ERR: Buffers have different formats\n");

  [lock unlock];

  return NO; /* we've written the results in place */
}

@end

