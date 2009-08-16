//////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorDistortion.h
//  SndKit
//
//  Waveshaping Distortion / Limiter
//
//  Created by SKoT McDonald on Tue Dec 18 2001.
//
//  Based on the 1999 C++ Vellocet VFracDistort Cubase VST plugin by
//  Vellocet / SKoT McDonald <skot@vellocet.com>
//  http://www.vellocet.com
//  (c) All rights reserved.
//
//////////////////////////////////////////////////////////////////////////////

#ifndef __SNDKIT_SNDAUDIOPROCESSORDISTORTION_H__
#define __SNDKIT_SNDAUDIOPROCESSORDISTORTION_H__

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"

/*!
 @brief SndDistortionParam  Parameter keys
 @constant distort_kBoostAmount Pre amp boost amount
 @constant distort_kKnee  Knee level in range [0,1]
 @constant distort_kHardness  Degree of hard clipping
 @constant distort_kBoostRange  Pre amp boost range
 @constant distort_kNumParams  Number of parameters
 */
enum {
  distort_kBoostAmount = 0,
  distort_kKnee        = 1,
  distort_kHardness    = 2,
  distort_kBoostRange  = 3,
  distort_kNumParams   = 4
};

//////////////////////////////////////////////////////////////////////////////

/*!
@class SndAudioProcessorDistortion
@brief A distortion/limiter processor

  To come
*/
@interface SndAudioProcessorDistortion : SndAudioProcessor {
/*! m_fBoostRange */
  float   m_fBoostRange;  // in range [1..?]
/*! m_fBoostAmount */
  float   m_fBoostAmount;
/*! m_fBoost */
  float   m_fBoost;
/*! m_fKnee */
  float   m_fKnee;
/*! m_fHardness */
  float   m_fHardness;
}
/*!
  @brief
  
  
  @return
*/
- (void)  setToDefault;
/*!
  @brief
  
  
  @return
*/
- (void)  setBoostRange: (const float) fBoostRange;
/*!
  @brief
  
  
  @return
*/
- (void)  setBoostAmount: (const float) fBoostAmount;
/*!
  @brief
  
  
  @return
*/
- (void)  setKnee: (const float) fKnee;
/*!
  @brief
  
  
  @return
*/
- (void)  setHardness: (const float) fHard;
/*!
  @brief
  
  
  @return
*/
- (float) boostAmount;
/*!
  @brief
  
  
  @return
*/
- (float) boostRange;
/*!
  @brief
  
  
  @return
*/
- (float) knee;
/*!
  @brief
  
  
  @return
*/
- (float) hardness;

@end

//////////////////////////////////////////////////////////////////////////////

#endif
