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

#ifndef __SNDKIT_SNDAUDIOPROCESSORFLANGER_H_
#define __SNDKIT_SNDAUDIOPROCESSORFLANGER_H_

@class SndAudioBuffer;
#import "SndAudioProcessor.h"

enum
{
  flanger_kRate,
  flanger_kMin,
  flanger_kMax,
  flanger_kSwap,
  flanger_kPhase,
  flanger_kFeedback,
  flanger_kNumParams
};

@interface SndAudioProcessorFlanger : SndAudioProcessor {

  // members
  float  fRate;
  float  fMax;
  float  fMin;
  float  fSwapStereo;
  float  fPhaseDiff;
  float  fFeedback;

  float* m_pfBuff[2];
  long   m_liBuffSize;
  long   m_liPtr;
  float  m_fOsc[2];
  float  m_oscSign[2];
  float  m_fOscStep;
  float  m_fTargetMax;
  float  m_fTargetMin;
  float  m_fParamChangeRate;  
}

- init;
- (void) dealloc;
- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB
                        outputBuffer: (SndAudioBuffer*) outB;

- (void) processReplacing_core_inL: (float*) inL   inR: (float*) inR
                              outL: (float*) outL outR: (float*) outR
                       sampleCount: (long) sampleCount step: (int) step;

- (void)  setParameter: (long) index toValue: (float) value;
- (float) getParameter: (long) index;

- (NSString*) getParameterLabel:   (long) index;
- (NSString*) getParameterDisplay: (long) index;
- (NSString*) getParameterName:    (long) index;

- setActive: (BOOL) b;
- (void)  setToDefault;

- (void)  setRate:     (float) f;
- (void)  setMin:      (float) f;
- (void)  setMax:      (float) f;
- (void)  setSwap:     (float) f;
- (void)  setPhase:    (float) f;
- (void)  setFeedback: (float) f;

- (float) getRate;
- (float) getMin;
- (float) getMax;
- (float) getSwap;
- (float) getPhase;
- (float) getFeedback;

@end

//////////////////////////////////////////////////////////////////////////////

#endif
