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

#import <Foundation/Foundation.h>
#import "SndAudioBuffer.h"
#import "SndAudioProcessor.h"

#ifndef __SNDKIT_SNDAUDIOPROCESSORDISTORTION_H_
#define __SNDKIT_SNDAUDIOPROCESSORDISTORTION_H_

enum {
  distort_kBoostAmount = 0,
  distort_kKnee        = 1,
  distort_kHardness    = 2,
  distort_kBoostRange  = 3,
  distort_kNumParams   = 5
};

@interface SndAudioProcessorDistortion : SndAudioProcessor {
  float   m_fBoostRange;  // in range [1..?]
  float   m_fBoostAmount;
  float   m_fBoost;
  float   m_fKnee;
  float   m_fHardness;
}

- init;
- (void) dealloc;

- (void)  setToDefault;
- (BOOL)  processReplacingInputBuffer: (SndAudioBuffer*) inB outputBuffer: (SndAudioBuffer*) outB;

- (void)  setParam: (int) index toValue: (float) value;
- (NSString*) getParamName: (int) index;
- (float) getParam: (int) index;

- (void)  setBoostRange: (float) fBoostRange;
- (void)  setBoostAmount: (float) fBoostAmount;
- (void)  setKnee: (float) fKnee;
- (void)  setHardness: (float) fHard;

- (float) getBoostAmount;
- (float) getBoostRange;
- (float) getKnee;
- (float) getHardness;

@end

//////////////////////////////////////////////////////////////////////////////

#endif
