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
//
//////////////////////////////////////////////////////////////////////////////

#ifndef __SNDKIT_SNDAUDIOPROCESSORDISTORTION_H__
#define __SNDKIT_SNDAUDIOPROCESSORDISTORTION_H__

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"

/*!
 @enum     SndDistortionParam
 @constant distort_kBoostAmount
 @constant distort_kKnee
 @constant distort_kHardness
 @constant distort_kBoostRange
 @constant distort_kNumParams
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
@class      SndAudioProcessorDistortion
@abstract   A distortion/limiter processor
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
  @method     init
  @abstract
  @discussion
  @result
*/
- init;
/*!
  @method     dealloc
  @abstract
  @discussion
  @result
*/
- (void)  dealloc;
/*!
  @method     setToDefault
  @abstract
  @discussion
  @result
*/
- (void)  setToDefault;
/*!
  @method     processReplacingInputBuffer:outputBuffer:
  @abstract
  @discussion
  @result
*/
- (BOOL)  processReplacingInputBuffer: (SndAudioBuffer*) inB outputBuffer: (SndAudioBuffer*) outB;
/*!
  @method     setParam:toValue:
  @abstract
  @discussion
  @result
*/
- setParam: (const int) index toValue: (const float) value;
/*!
  @method     paramName:
  @abstract
  @discussion
  @result
*/
- (NSString*) paramName: (const int) index;
/*!
  @method     param:
  @abstract
  @discussion
  @result
*/
- (float) param: (const int) index;
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
