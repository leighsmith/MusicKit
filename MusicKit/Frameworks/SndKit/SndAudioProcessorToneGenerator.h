//////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorToneGenerator.h
//  SndKit
//
//  Created by SKoT McDonald on Mon Dec 31 2001.
//  Copyright (c) 2001 tomandandy. All rights reserved.
//
//////////////////////////////////////////////////////////////////////////////

#ifndef __SNDKIT_SNDAUDIOPROCESSORTONEGENERATOR_H_
#define __SNDKIT_SNDAUDIOPROCESSORTONEGENERATOR_H_

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"

enum {
  toneGen_kFreq      = 0,
  toneGen_kAmp       = 1,
  toneGen_kPhase     = 2,
  toneGen_kWave      = 3,
  toneGen_kNumParams = 4
};

@class SndAudioBuffer;

//////////////////////////////////////////////////////////////////////////////

@interface SndAudioProcessorToneGenerator : SndAudioProcessor {
  float freq;
  float amp;
  float phase;
  int   waveform;
  double t;
}

- init;
- (NSString*) description;
- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB
                        outputBuffer: (SndAudioBuffer*) outB;

- (void)  setParam: (int) index toValue: (float) value;
- (float) paramValue: (int) index;
- (NSString*) paramName: (int) index;

@end

//////////////////////////////////////////////////////////////////////////////

#endif