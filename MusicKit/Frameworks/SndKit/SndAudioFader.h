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
    int             bearingFlags;
    float           ampY;
    float           bearingY;
} SndUnifiedEnvelopeEntry;

@interface SndAudioFader : SndAudioProcessor
{
  id     envClass; /* Class object used in initialising new envelopes */
  id     <SndEnveloping, NSObject> ampEnv;
  float  staticAmp;
  id     <SndEnveloping,NSObject> bearingEnv;
  float  staticBearing;

  SndUnifiedEnvelopeEntry *uee;

  NSLock *lock; // locks changes to the envelope objects (?)
  NSLock *bearingEnvLock;
  NSLock *ampEnvLock;
}

/*
 * "instantaneous" getting and setting; applies from start of buffer
 */
- setBearing:(float)bearing clearingEnvelope:(BOOL)clear;
- (float)getBearing;
- setAmp:(float)amp clearingEnvelope:(BOOL)clear;
- (float)getAmp;

/*
 * "future" getting and setting; transparently reads and writes
 * from/to the envelope object(s)
 */
- setBearing:(float)bearing atTime:(double)atTime;
- (float)getBearingAtTime:(double)atTime;
- setAmp:(float)amp atTime:(double)atTime;
- (float)getAmpAtTime:(double)atTime;

/* official API? */

- (BOOL) rampAmpFrom:(float)startRampLevel
                  to:(float)endRampLevel
           startTime:(double)startRampTime
             endTime:(double)endRampTime;

- (BOOL) rampBearingFrom:(float)startRampLevel
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

