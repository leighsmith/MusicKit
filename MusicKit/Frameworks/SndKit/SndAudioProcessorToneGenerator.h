//////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorToneGenerator.h
//  SndKit
//
//  Created by SKoT McDonald on Mon Dec 31 2001.
//  Copyright (c) 2001 tomandandy. All rights reserved.
//
//////////////////////////////////////////////////////////////////////////////

#ifndef __SNDKIT_SNDAUDIOPROCESSORTONEGENERATOR_H__
#define __SNDKIT_SNDAUDIOPROCESSORTONEGENERATOR_H__

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"

/*!
 @enum     SndToneGenParam
 @constant toneGen_kFreq
 @constant toneGen_kAmp
 @constant toneGen_kPhase
 @constant toneGen_kWave
 @constant toneGen_kNumParams
 */
enum {
  toneGen_kFreq      = 0,
  toneGen_kAmp       = 1,
  toneGen_kPhase     = 2,
  toneGen_kWave      = 3,
  toneGen_kNumParams = 4
};

@class SndAudioBuffer;

//////////////////////////////////////////////////////////////////////////////

/*!
@class      SndAudioProcessorToneGenerator
@abstract   A tone generator processor
@discussion To come
*/
@interface SndAudioProcessorToneGenerator : SndAudioProcessor {
/*! @var   freq This is a dodgey one at the moment - range [0,1] logarithmically maps to [55,880] Hz*/
  float freq;
/*! @var   amp  Yuckky linear scale [0,1] for the moment - be nice to have in dB */
  float amp;
/*! @var   phase */
  float phase;
/*! @var   waveform */
  int   waveform;
  
@private
/*! @var   t */
  double t;
}

/*!
  @method     init 
  @abstract
  @discussion
  @result     
*/
- init;
/*!
  @method     description
  @abstract
  @discussion
  @result
*/
- (NSString*) description;
/*!
  @method     processReplacingInputBuffer:outputBuffer:
  @abstract   See baseclass SndAudioProcessor
  @discussion
  @result
*/
- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB
                        outputBuffer: (SndAudioBuffer*) outB;
/*!
  @method     setParam:toValue:
  @abstract   See baseclass SndAudioProcessor
  @discussion
  @result
*/
- setParam: (const int) index toValue: (const float) value;
/*!
  @method     paramValue:
  @abstract   See baseclass SndAudioProcessor
  @discussion
  @result
*/
- (float) paramValue: (const int) index;
/*!
  @method     paramName:
  @abstract   See baseclass SndAudioProcessor
  @discussion 
  @result
*/
- (NSString*) paramName: (const int) index;

@end

//////////////////////////////////////////////////////////////////////////////

#endif
