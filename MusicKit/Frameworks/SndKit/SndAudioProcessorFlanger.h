//////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorFlanger.h
//  SndKit
//
//  Flanger / bi-Choruser
//
//  Created by SKoT McDonald on Mon Dec 17 2001.
//
//  Based on the 1997 C++ Vellocet VFlanger Cubase VST plugin by
//  Vellocet / SKoT McDonald <skot@vellocet.com>
//  http://www.vellocet.com
//  (c) All rights reserved.
//
//////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

#ifndef __SNDKIT_SNDAUDIOPROCESSORFLANGER_H__
#define __SNDKIT_SNDAUDIOPROCESSORFLANGER_H__

#import "SndAudioProcessor.h"

/*!
 @enum SndFlangerParam
 @brief Parameter keys
 @constant flanger_kRate  Sweep rate
 @constant flanger_kMin  Minimum z buffer extent
 @constant flanger_kMax  Maximum z buffer extent
 @constant flanger_kSwap  Swap the z buffer feedback between left and right channels
 @constant flanger_kPhase  Phase difference between left and right channels
 @constant flanger_kFeedback  Feedback
 @constant flanger_kNumParams  Number of parameters
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
@class SndAudioProcessorFlanger
@brief A flanger/dual choruser processor

  To come
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
  @brief   private method called internally to do the Flanging
*/
- (void) processReplacing_core_inL: (float*) inL   inR: (float*) inR
                              outL: (float*) outL outR: (float*) outR
                       sampleCount: (long) sampleCount step: (int) step;
/*!
  @brief
  
  
  @return
*/
- (void) setToDefault;
/*!
  @brief
  
  
  @return
*/
- (void) setRate: (const float) f;
/*!
  @brief
  
  
  @return
*/
- (void) setMin: (const float) f;
/*!
  @brief
  
  
  @return
*/
- (void) setMax: (const float) f;
/*!
  @brief
  
  
  @return
*/
- (void) setSwap: (const float) f;
/*!
  @brief
  
  
  @return
*/
- (void) setPhase: (const float) f;
/*!
  @brief
  
  
  @return
*/
- (void) setFeedback: (const float) f;
/*!
  @brief
  
  
  @return
*/
- (float) rate;
/*!
  @brief
  
  
  @return
*/
- (float) min;
/*!
  @brief
  
  
  @return
*/
- (float) max;
/*!
  @brief
  
  
  @return
*/
- (float) swap;
/*!
  @brief
  
  
  @return
*/
- (float) phase;
/*!
  @brief
  
  
  @return
*/
- (float) feedback;

@end

//////////////////////////////////////////////////////////////////////////////

#endif
