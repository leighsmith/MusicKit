////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorNoiseGate.m
//  SndKit
//
//  Created by SKoT McDonald on Fri Jan 11 2002.
//  Copyright (c) 2001 tomandandy. All rights reserved.
//
//  Based on the 1999 C++ Vellocet VNoiseGate Cubase VST plugin by
//  Vellocet / SKoT McDonald <skot@vellocet.com>
//  http://www.vellocet.com
//
////////////////////////////////////////////////////////////////////////////////

#import "SndAudioProcessorNoiseGate.h"

#define timeDiv 44100  // Time divisor for hold times etc

@implementation SndAudioProcessorNoiseGate

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
  self = [super initWithParamCount: noisegate_kNumParams name: @"NoiseGate"];
  if (self) {
    fThreshold  = (float) 0.1;
    fHoldTime   = 0.050 * timeDiv;
    fAttackTime = 0.050 * timeDiv;
    fDecayTime  = 0.100 * timeDiv;
    iChanMode   = noisegate_cmodeLinked;
    m_iMode[0]  = noisegate_modeGate;
    m_iMode[1]  = noisegate_modeGate;
    m_g[0]      = 0;
    m_g[1]      = 0;
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// paramValue:
////////////////////////////////////////////////////////////////////////////////

- (float) paramValue: (const int) index;
{
  float r=0.0f;
  switch (index) {
    case noisegate_kThreshold:
      r = fThreshold;
      break;
    case noisegate_kHoldTime:
      r = (fHoldTime   - 10) / timeDiv;
      break;
    case noisegate_kAttackTime:
      r = (fAttackTime - 10) / timeDiv;
      break;
    case noisegate_kDecayTime:
      r = (fDecayTime  - 10) / timeDiv;
      break;
    case noisegate_kChanMode:
      r = (float) iChanMode / 2;
  }
  return r;
}

////////////////////////////////////////////////////////////////////////////////
// paramName:
////////////////////////////////////////////////////////////////////////////////

- (NSString*) paramName: (const int) index
{
  NSString *r = nil;

  switch (index) {
    case noisegate_kThreshold:  r = @"Threshold";   break;
    case noisegate_kHoldTime:   r = @"Hold time";   break;
    case noisegate_kAttackTime: r = @"Attack time"; break;
    case noisegate_kDecayTime:  r = @"Decay time";  break;
    case noisegate_kChanMode:   r = @"Gate mode";   break;
  }
  return r;
}

////////////////////////////////////////////////////////////////////////////////
// setParam:toValue:
////////////////////////////////////////////////////////////////////////////////

- setParam: (const int) index toValue: (const float) value
{
  switch (index) {
    case noisegate_kThreshold:
      fThreshold  = value;
      break;
    case noisegate_kHoldTime:
      fHoldTime   = 10 + value * timeDiv;
      break;
    case noisegate_kAttackTime:
      fAttackTime = 10 + value * timeDiv;
      break;
    case noisegate_kDecayTime:
      fDecayTime  = 10 + value * timeDiv;
      break;
    case noisegate_kChanMode:
      iChanMode   = (int)(2.0 * (value + (float)0.25));
      break;
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// paramLabel:
////////////////////////////////////////////////////////////////////////////////

- (NSString*) paramLabel: (const int) index
{
  NSString *r = nil;
  switch (index) {
    case noisegate_kThreshold:
      r = @"dB";
      break;
    case noisegate_kHoldTime:
      r = @"ms";
      break;
    case noisegate_kAttackTime:
      r = @"ms";
      break;
    case noisegate_kDecayTime:
      r = @"ms";
      break;
    case noisegate_kChanMode:
      r = @" ";
      break;
  }
  return r;
}

////////////////////////////////////////////////////////////////////////////////
// paramDisplay:
////////////////////////////////////////////////////////////////////////////////

- (NSString*) paramDisplay: (const int) index
{
  NSString *r = nil;
  switch (index) {
    case noisegate_kThreshold:
      r = [NSString stringWithFormat: @"%f", SndConvertLinearToDecibels(fThreshold)];
      break;
    case noisegate_kHoldTime:
      r = [NSString stringWithFormat: @"%f", 1000.0 * fHoldTime];   // milliseconds
      break;
    case noisegate_kAttackTime:
      r = [NSString stringWithFormat: @"%f", 1000.0 * fAttackTime]; // milliseconds
      break;
    case noisegate_kDecayTime:
      r = [NSString stringWithFormat: @"%f", 1000.0 * fDecayTime];  // milliseconds
      break;
    case noisegate_kChanMode:
      switch (iChanMode) {
        case noisegate_cmodeLinked: r = @"Linked";      break;
        case noisegate_cmodeIndep:  r = @"Independent"; break;
        case noisegate_cmodeCross:  r = @"Cross";       break;
      }
      break;
  }
  return r;
}

////////////////////////////////////////////////////////////////////////////////
// processReplacingInputBuffer:outputBuffer:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB
                        outputBuffer: (SndAudioBuffer*) outB
{
  float *inp  = (float*) [inB data];
  float *outp = (float*) [outB data];
  float input[2], c, d;
  int sampleFrames = [inB lengthInSamples];
  int i;
  float f;

  while(--sampleFrames >= 0) {
    input[0] = *inp++;		
    input[1] = *inp++;

    for (i = 0; i < 2; i++) {
      switch (m_iMode[i]) {
        case noisegate_modeGate:
          m_g[i] = 0;
          if (input[i] > fThreshold || input[i] < -fThreshold) {
            m_iMode[i] = noisegate_modeAttack;
            m_iAttackCount[i] = 0;
            m_g[i] = ((float) m_iAttackCount[i]) / fAttackTime;
          }
            break;
        case noisegate_modeAttack:
          m_iAttackCount[i]++;
          m_g[i] = ((float) m_iAttackCount[i]) / fAttackTime;
          if (m_iAttackCount[i] >= fAttackTime) {
            m_iMode[i] = noisegate_modeHold;
            m_iHoldCount[i] = 0;
            m_g[i] = 1.0;
          }
            break;
        case noisegate_modeHold:
          m_iHoldCount[i]++;
          if (input[i] > fThreshold || input[i] < -fThreshold) { // retrigger!
            m_iMode[i] = noisegate_modeHold;
            m_iHoldCount[i] = 0;
          }
            if (m_iHoldCount[i] >= fHoldTime) {
              m_iMode[i] = noisegate_modeDecay;
              m_iDecayCount[i] = 0;
              m_t[i] = m_g[i];
            }
            break;
        case noisegate_modeDecay:
          m_iDecayCount[i] ++;
          if (input[i] > fThreshold || input[i] < -fThreshold) {
            m_iMode[i] = noisegate_modeAttack;
            m_iAttackCount[i] = 0;
            m_g[i] = m_t[i] * ((float) m_iDecayCount[i]) / fDecayTime;
          }
            else if (m_iDecayCount[i] >= fDecayTime) {
              m_iMode[i] = noisegate_modeGate;
              m_g[i] = 0;
            }
            else {
              m_g[i] = m_t[i] * (1 - ((float)m_iDecayCount[i]) / fDecayTime);
            }
            break;
      }
    }
    switch (iChanMode) {
      case noisegate_cmodeLinked:
        if (m_g[0] > m_g[1])
          m_g[1] = m_g[0];
        else
          m_g[0] = m_g[1];
        break;
      case noisegate_cmodeIndep:
        break;
      case noisegate_cmodeCross:
        f = m_g[0];
        m_g[0] = m_g[1];
        m_g[1] = f;
        break;
    }
    c = input[0] * m_g[0];
    d = input[1] * m_g[1];
    *outp++ = c;
    *outp++ = d;
  }
  return TRUE;
}

////////////////////////////////////////////////////////////////////////////////

@end
