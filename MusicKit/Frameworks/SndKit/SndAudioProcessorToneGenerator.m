//////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorToneGenerator.m
//  SndKit
//
//  Created by SKoT McDonald on Mon Dec 31 2001.
//  Copyright (c) 2001 tomandandy. All rights reserved.
//
//////////////////////////////////////////////////////////////////////////////

#import "SndAudioBuffer.h" 
#import "SndAudioProcessorToneGenerator.h"

#define ROOTFREQ 55.0

double freqparam2freq(float freq)
{
  return ROOTFREQ * pow(2.0, freq * 4.0);
}

@implementation SndAudioProcessorToneGenerator

//////////////////////////////////////////////////////////////////////////////
// init
//////////////////////////////////////////////////////////////////////////////

- init
{
  self     = [super initWithParamCount: toneGen_kNumParams name: @"ToneGenerator"];
  freq     = 1.0;
  amp      = 0.25;
  phase    = 0.0;
  waveform = 0;
  t        = 0.0;
  return self;
}

//////////////////////////////////////////////////////////////////////////////
// description
//////////////////////////////////////////////////////////////////////////////

- (NSString*) description
{
  return [NSString stringWithFormat: @"ToneGenerator freq:%.2fHz amp:%.3f phase:%.2frad wave:%i",
    freqparam2freq(freq), amp, phase, waveform];
}

//////////////////////////////////////////////////////////////////////////////
// processReplacingInputBuffer:outputBuffer:
//////////////////////////////////////////////////////////////////////////////

- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB
                        outputBuffer: (SndAudioBuffer*) outB
{
  float *inData      = [inB data];
  float *outData     = [outB data];
  long  sampleFrames = [inB lengthInSamples];
  int   step = 2, i;
  double dt = 2.0 * M_PI / [inB samplingRate], y;
  double theFreq = freqparam2freq(freq);

  // assume stereo...
  
  for (i = 0; i < sampleFrames*2; i += step) {
    y = amp * sin(theFreq * t + phase);
    outData[i]   = inData[i]   + y;
    outData[i+1] = inData[i+1] + y;
    t += dt;
  }
  return TRUE;  
}

//////////////////////////////////////////////////////////////////////////////
// setParam
//////////////////////////////////////////////////////////////////////////////

- (void)  setParam: (int) index toValue: (float) value
{
  switch (index) {
    case toneGen_kFreq:  freq     = value;
//      fprintf(stderr,"freq: %.3fHz\n",freqparam2freq(freq));
      break;
    case toneGen_kAmp:   amp      = value; break;
    case toneGen_kPhase: phase    = value * 2.0 *  M_PI; break;
    case toneGen_kWave:  waveform = value; break;
  }
}

//////////////////////////////////////////////////////////////////////////////
// paramValue
//////////////////////////////////////////////////////////////////////////////

- (float) paramValue: (int) index
{
  float r = 0.0;
  switch (index) {
    case toneGen_kFreq:  r = freq;     break;
    case toneGen_kAmp:   r = amp;      break;
    case toneGen_kPhase: r = phase;    break;
    case toneGen_kWave:  r = waveform; break;
  }
  return r;
}

//////////////////////////////////////////////////////////////////////////////
// paramName
//////////////////////////////////////////////////////////////////////////////

- (NSString*) paramName: (int) index
{
  NSString *r = nil;
  switch (index) {
    case toneGen_kFreq:  r = @"Frequency"; break;
    case toneGen_kAmp:   r = @"Amplitude"; break;
    case toneGen_kPhase: r = @"Phase";     break;
    case toneGen_kWave:  r = @"Waveform";  break;
  }
  return r;
}

//////////////////////////////////////////////////////////////////////////////

@end
