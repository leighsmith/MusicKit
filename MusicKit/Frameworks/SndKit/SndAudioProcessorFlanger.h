//////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorFlanger.h
//  SndKit
//
//  Created by SKoT McDonald on Mon Dec 17 2001.
//
//  Based on the C++ Vellocet VFlanger Cubase VST plugin by
//  Vellocet / SKoT McDonald <skot@vellocet.com>
//  http://www.vellocet.com
//
//////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

#ifndef __SNDKIT_SNDAUDIOPROCESSORFLANGER_H__
#define __SNDKIT_SNDAUDIOPROCESSORFLANGER_H__

@class SndAudioBuffer;
#import "SndAudioProcessor.h"

/*!
 @enum     SndFlangerParam
 @constant flanger_kRate
 @constant flanger_kMin
 @constant flanger_kMax
 @constant flanger_kSwap
 @constant flanger_kPhase
 @constant flanger_kFeedback
 @constant flanger_kNumParams
 */
enum
{
  flanger_kRate      = 0,
  flanger_kMin       = 1,
  flanger_kMax       = 2,
  flanger_kSwap      = 3,
  flanger_kPhase     = 4,
  flanger_kFeedback  = 5,
  flanger_kNumParams = 6
};

////////////////////////////////////////////////////////////////////////////////

/*!
@class      SndAudioProcessorFlanger
@abstract   A flanger/dual choruser processor
@discussion To come
*/
@interface SndAudioProcessorFlanger : SndAudioProcessor {
/*! @var fRate */  
  float  fRate;
/*! @var fMax */  
  float  fMax;
/*! @var fMin */  
  float  fMin;
/*! @var fSwapStereo */  
  float  fSwapStereo;
/*! @var fPhaseDiff */  
  float  fPhaseDiff;
/*! @var fFeedback */  
  float  fFeedback;

  @private
/*! @var m_pfBuff */  
  float* m_pfBuff[2];
/*! @var m_liBuffSize */  
  long   m_liBuffSize;
/*! @var m_liPtr */  
  long   m_liPtr;
/*! @var m_fOsc */  
  float  m_fOsc[2];
/*! @var m_oscSign */  
  float  m_oscSign[2];
/*! @var m_fOscStep */  
  float  m_fOscStep;
/*! @var m_fTargetMax */  
  float  m_fTargetMax;
/*! @var m_fTargetMin */  
  float  m_fTargetMin;
/*! @var m_fParamChangeRate */  
  float  m_fParamChangeRate;  
}

/*!
  @method init
  @abstract
  @discussion
  @result
*/
- init;
/*!
  @method dealloc
  @abstract
  @discussion
*/
- (void) dealloc;
/*!
  @method     processReplacingInputBuffer:outputBuffer:
  @abstract
  @discussion
  @result
*/
- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB
                        outputBuffer: (SndAudioBuffer*) outB;
/*!
  @method     processReplacing_core_inL:inR:outL:outR:sampleCount:step:
  @abstract
  @discussion
  @result
*/
- (void) processReplacing_core_inL: (float*) inL   inR: (float*) inR
                              outL: (float*) outL outR: (float*) outR
                       sampleCount: (long) sampleCount step: (int) step;
/*!
  @method     setParam:toValue:
  @abstract
  @discussion
  @result
*/
- setParam: (const int) index toValue: (const float) value;
/*!
  @method     paramValue:
  @abstract
  @discussion
  @result
*/
- (float) paramValue: (const int) index;
/*!
  @method     paramName:
  @abstract
  @discussion
  @result
*/
- (NSString*) paramName: (const int) index;
/*!
  @method     paramLabel:
  @abstract
  @discussion
  @result
*/
- (NSString*) paramLabel: (const int) index;
/*!
  @method     paramDisplay:
  @abstract
  @discussion
  @result
*/
- (NSString*) paramDisplay: (const int) index;
/*!
  @method     setActive:
  @abstract
  @discussion
  @result
*/
- setActive: (const BOOL) b;
/*!
  @method     setToDefault
  @abstract
  @discussion
  @result
*/
- (void) setToDefault;
/*!
  @method     setRate:
  @abstract
  @discussion
  @result
*/
- (void) setRate: (const float) f;
/*!
  @method     setMin:
  @abstract
  @discussion
  @result
*/
- (void) setMin: (const float) f;
/*!
  @method     setMax:
  @abstract
  @discussion
  @result
*/
- (void) setMax: (const float) f;
/*!
  @method     setSwap:
  @abstract
  @discussion
  @result
*/
- (void) setSwap: (const float) f;
/*!
  @method     setPhase:
  @abstract
  @discussion
  @result
*/
- (void) setPhase: (const float) f;
/*!
  @method     setFeedback:
  @abstract
  @discussion
  @result
*/
- (void) setFeedback: (const float) f;
/*!
  @method     rate
  @abstract
  @discussion
  @result
*/
- (float) rate;
/*!
  @method     min
  @abstract
  @discussion
  @result
*/
- (float) min;
/*!
  @method     max
  @abstract
  @discussion
  @result
*/
- (float) max;
/*!
  @method     swap
  @abstract
  @discussion
  @result
*/
- (float) swap;
/*!
  @method     phase
  @abstract
  @discussion
  @result
*/
- (float) phase;
/*!
  @method     feedback
  @abstract
  @discussion
  @result
*/
- (float) feedback;

@end

//////////////////////////////////////////////////////////////////////////////

#endif
