////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioFader.h
//  SndKit
//
//  Created by Stephen Brandon on Mon Jun 23 2001. <stephen@brandonitconsulting.co.uk>
//  Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and non-commercial
//  purposes so long as the author attribution and copyright messages remain intact and
//  accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDAUDIOFADER_H__
#define __SNDAUDIOFADER_H__

#import <Foundation/Foundation.h>

#import "SndEnvelope.h"
#import "SndAudioProcessor.h"
@class SndStreamManager;
@class SndStreamMixer;
@class SndAudioProcessor;
@class SndAudioBuffer;

#define SND_FADER_ATTACH_RAMP_RIGHT 1
#define SND_FADER_ATTACH_RAMP_LEFT  2

/* this value limits the number of envelope points that can be held
 * in the unified (amp + bearing) envelope. Unless providing for almost
 * sample-level enveloping, the specified figure will be more than enough.
 */
#define MAX_ENV_POINTS_PER_BUFFER 256

/*!
@class      SndAudioFader
@abstract
@discussion
*/

typedef struct _UEE {
    double          xVal;
    int             ampFlags;
    int             balanceFlags;
    float           ampY;
    float           balanceY;
    float           balanceL;
    float           balanceR;
} SndUnifiedEnvelopeEntry;

/* Squeeze the last drop of performance out of this class by caching IMPs.
 * See also +initialize and -init for the initialization of selectors, which
 * are static "class" variables.
 * To use, cache the following:
 *  bpBeforeOrEqual = [ENVCLASS instanceMethodForSelector:bpBeforeOrAfterSel];
 * then use like this:
 *  y = bpbeforeOrEqual(myEnv,bpBeforeOrAfterSel,myX);
 */
typedef int (*BpBeforeOrEqualIMP)(id, SEL, double);
typedef int (*BpAfterIMP)(id, SEL, double);
typedef int (*FlagsForBpIMP)(id, SEL, int);
typedef float (*YForBpIMP)(id, SEL, int);
typedef float (*YForXIMP)(id, SEL, double);
typedef float (*XForBpIMP)(id, SEL, int);


@interface SndAudioFader : SndAudioProcessor
{
  id     envClass; /* Class object used in initialising new envelopes */
  id     <SndEnveloping, NSObject> ampEnv;
  float  staticAmp;
  id     <SndEnveloping,NSObject> balanceEnv;
  float  staticBalance;

  SndUnifiedEnvelopeEntry *uee;

  NSLock *lock; // locks changes to the envelope objects (?)
  NSLock *balanceEnvLock;
  NSLock *ampEnvLock;

@public
  BpBeforeOrEqualIMP  bpBeforeOrEqual;
  BpAfterIMP          bpAfter;
  FlagsForBpIMP       flagsForBp;
  YForBpIMP           yForBp;
  YForXIMP            yForX;
  XForBpIMP           xForBp;
}

+ (void)setEnvelopeClass:(id)aClass;
+ (id)envelopeClass;
- (void)setEnvelopeClass:(id)aClass;
- (id)envelopeClass;

/*
 * "instantaneous" getting and setting; applies from start of buffer
 */
- setBalance:(float)balance clearingEnvelope:(BOOL)clear;
- (float)getBalance;
- setAmp:(float)amp clearingEnvelope:(BOOL)clear;
- (float)getAmp;

/*
 * "future" getting and setting; transparently reads and writes
 * from/to the envelope object(s)
 */
- setBalance:(float)balance atTime:(double)atTime;
- (float)getBalanceAtTime:(double)atTime;
- setAmp:(float)amp atTime:(double)atTime;
- (float)getAmpAtTime:(double)atTime;

/* official API? */

- (BOOL) rampAmpFrom:(float)startRampLevel
                  to:(float)endRampLevel
           startTime:(double)startRampTime
             endTime:(double)endRampTime;

- (BOOL) rampBalanceFrom:(float)startRampLevel
                      to:(float)endRampLevel
               startTime:(double)startRampTime
                 endTime:(double)endRampTime;

- (void) dealloc;
- (int) paramCount;
- (float) paramValue: (int) index;
- (NSString*) paramName: (int) index;
- setParam: (int) index toValue: (float) v;

- (BOOL)processReplacingInputBuffer: (SndAudioBuffer*) inB
                       outputBuffer: (SndAudioBuffer*) outB;


@end

#endif

