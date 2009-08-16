////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    FreeVerb-based
//    FreeVerb originally written by Jezar at Dreampoint, June 2000
//    http://www.dreampoint.co.uk
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//  Rewritten by: Leigh M. Smith <leigh@leighsmith.com>
//
//  Jezar's code described as "This code is public domain"
//
//  Copyright (c) 2001,2009 The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDKIT_SNDAUDIOPROCESSORREVERB_H__
#define __SNDKIT_SNDAUDIOPROCESSORREVERB_H__

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"

@class SndReverbCombFilter;
@class SndReverbAllpassFilter;

#define NUMCOMBS 8
#define NUMALLPASSES 4
#define NUMCHANNELS 2

/*!
 @brief SndReverbParam Parameter keys
 @constant rvrbRoomSize  Room size
 @constant rvrbDamp  Damping amount
 @constant rvrbWet  Wet level
 @constant rvrbDry  Dry level
 @constant rvrbWidth  Width
 @constant rvrbMode  Mode [1 = hold]
 @constant rvrbNumParams  Number of parameters
*/
enum {
    rvrbRoomSize  = 0,
    rvrbDamp      = 1,
    rvrbWet       = 2,
    rvrbDry       = 3,
    rvrbWidth     = 4,
    rvrbMode      = 5, 
    rvrbNumParams = 6
};

////////////////////////////////////////////////////////////////////////////////

/*!
  @class SndAudioProcessorReverb
  @brief A reverb processor

  A reverb based on FreeVerb originally written by Jezar at Dreampoint, June 2000
*/
@interface SndAudioProcessorReverb : SndAudioProcessor {
    float gain;
    float roomsize, roomsize1;
    float damp, damp1;
    float wet, wet1, wet2;
    float dry;
    float width;
    float mode;

    // The following are all declared statically allocated 
    // to speed up the traversal across the filters.

    /*! Comb filters */
    SndReverbCombFilter *comb[NUMCHANNELS][NUMCOMBS];

    /*! Allpass filters */
    SndReverbAllpassFilter *allpass[NUMCHANNELS][NUMALLPASSES];

    long   bufferLength;
    float *inputMix;
    float *outputAccumL;
    float *outputAccumR;
}

- init;

- (void) mute;

- (BOOL) processReplacingInputBuffer: (SndAudioBuffer *) inB 
                        outputBuffer: (SndAudioBuffer *) outB;

- (float) paramValue: (const int) index;

- (NSString *) paramName: (const int) index;

- (void) setParam: (const int) index toValue: (const float) v;

// Recalculate internal values after parameter change
- (void) update;

- (void) setRoomSize: (float) value;

- (float) getRoomSize;

- (void) setDamp: (float) value;

- (float) getDamp;

- (void) setWet: (float) value;

- (float) getWet;

- (void) setDry: (float) value;

- (float) getDry;

- (void) setWidth: (float) value;

- (float) getWidth;

- (void) setMode: (float) value;

- (float) getMode;

////////////////////////////////////////////////////////////////////////////////

@end

#endif
