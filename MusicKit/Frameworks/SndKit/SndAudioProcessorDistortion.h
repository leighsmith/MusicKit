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
 @enum SndDistortionParam
 @abstract Parameter keys
 @constant distort_kBoostAmount Pre amp boost amount
 @constant distort_kKnee        Knee level in range [0,1]
 @constant distort_kHardness    Degree of hard clipping
 @constant distort_kBoostRange  Pre amp boost range
 @constant distort_kNumParams   Number of parameters
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
@abstract A distortion/limiter processor
@discussion To come
*/
@interface SndAudioProcessorDistortion : SndAudioProcessor {
/*! @var  m_fBoostRange */
  float   m_fBoostRange;  // in range [1..?]
/*! @var  m_fBoostAmount */
  float   m_fBoostAmount;
/*! @var  m_fBoost */
  float   m_fBoost;
/*! @var  m_fKnee */
  float   m_fKnee;
/*! @var  m_fHardness */
  float   m_fHardness;
}
/*!
  @method     setToDefault
  @abstract
  @discussion
  @result
*/
- (void)  setToDefault;
/*!
  @method     setBoostRange:
  @abstract
  @discussion
  @result
*/
- (void)  setBoostRange: (const float) fBoostRange;
/*!
  @method     setBoostAmount:
  @abstract
  @discussion
  @result
*/
- (void)  setBoostAmount: (const float) fBoostAmount;
/*!
  @method     setKnee:
  @abstract
  @discussion
  @result
*/
- (void)  setKnee: (const float) fKnee;
/*!
  @method     setHardness:
  @abstract
  @discussion
  @result
*/
- (void)  setHardness: (const float) fHard;
/*!
  @method     boostAmount
  @abstract
  @discussion
  @result
*/
- (float) boostAmount;
/*!
  @method     boostRange
  @abstract
  @discussion
  @result
*/
- (float) boostRange;
/*!
  @method     knee
  @abstract
  @discussion
  @result
*/
- (float) knee;
/*!
  @method     hardness
  @abstract
  @discussion
  @result
*/
- (float) hardness;

@end

//////////////////////////////////////////////////////////////////////////////

#endif
