//////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorDistortion.m
//  SndKit
//
//  Created by SKoT McDonald on Tue Dec 18 2001.
//
//  Based on the 1999 C++ Vellocet VFracDistort Cubase VST plugin by
//  Vellocet / SKoT McDonald <skot@vellocet.com>
//  http://www.vellocet.com
//
//////////////////////////////////////////////////////////////////////////////

#import "SndAudioProcessorDistortion.h"

@implementation SndAudioProcessorDistortion

//////////////////////////////////////////////////////////////////////////////
// init
//////////////////////////////////////////////////////////////////////////////

- init 
{
  self = [super init];
  [self setToDefault];
  numParams = distort_kNumParams;
  return self;
}

//////////////////////////////////////////////////////////////////////////////
// dealloc
//////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
  [super dealloc];
}

//////////////////////////////////////////////////////////////////////////////
// processReplacing
//////////////////////////////////////////////////////////////////////////////

- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB
                        outputBuffer: (SndAudioBuffer*) outB
{
  int   ch, i;
  long  dwLen = [inB lengthInSamples];
  long  chans = [inB channelCount];
  int   skip  = 2; 
  float a, c, invKnee = 1.0f - m_fKnee, invHard = 1.0f - m_fHardness, d;

  for (ch = 0; ch < chans; ch++) {
    
    float *inp   = (float*) [inB data];
    float *outp  = (float*) [outB data];

    // take care of interleaving initial offsets...
    inp  += ch;
    outp += ch;

    for (i = 0; i < dwLen * skip; i+=skip)  {
      a = inp[i] * m_fBoost;

      c = a > 0.0f ? a : -a;

      if (c > m_fKnee) {
        a = a > 0.0f ? 1.0f : -1.0f;
        c -= m_fKnee;
        d = invKnee + invHard * c;
        if (d > 0.0f) {
          a *= 1.0f - invKnee * invKnee / d;
          a = a > 1.0f ? 1.0f : (a < -1.0f ? -1.0f : a);
        }
      }
      outp[i] = a;
    }
  }
  return TRUE;
}

//////////////////////////////////////////////////////////////////////////////
// getParamName
//////////////////////////////////////////////////////////////////////////////

- (NSString*) getParamName: (int) index
{
  NSString *r = nil;
  switch (index)  {
  case distort_kBoostAmount: r = @"BoostAmount"; break; 
  case distort_kKnee:        r = @"Knee";        break;
  case distort_kHardness:    r = @"Hardness";    break;
  case distort_kBoostRange:  r = @"BoostRange";  break;      
  }
  return r;
}

//////////////////////////////////////////////////////////////////////////////
// getParam
//////////////////////////////////////////////////////////////////////////////

- (float) getParam: (int) index
{
  float r = 0.0f;
  switch (index)  {
  case distort_kBoostAmount: r = m_fBoostAmount; break; 
  case distort_kKnee:        r = m_fKnee;        break;
  case distort_kHardness:    r = m_fHardness;    break;
  case distort_kBoostRange:  r = m_fBoostRange;  break;    
  }
  return r;
}

//////////////////////////////////////////////////////////////////////////////
// setParam
//////////////////////////////////////////////////////////////////////////////

- (void) setParam: (int) index toValue: (float) value
{
  switch (index) {
    case distort_kBoostAmount:
      m_fBoostAmount = value;
      m_fBoost      = 1.0f + m_fBoostRange*m_fBoostAmount;
      break;
    case distort_kBoostRange:
      m_fBoostRange = value;
      m_fBoost = 1.0f + m_fBoostRange*m_fBoostAmount;
      break;
    case distort_kKnee:
      m_fKnee = value;
      break;
    case distort_kHardness:
      m_fHardness = value;
      break;
  }
}

//////////////////////////////////////////////////////////////////////////////
// SetToDefault
//////////////////////////////////////////////////////////////////////////////

- (void) setToDefault
{
  m_fBoost         =  1.0f;
  m_fBoostRange    = 10.0f;
  m_fBoostAmount   =  0.0f;
  m_fKnee          =  0.5f;
  m_fHardness      =  0.2f; 
}

//////////////////////////////////////////////////////////////////////////////
// micro mutators
//////////////////////////////////////////////////////////////////////////////

- (void) setBoostRange: (float) fBoostRange
{
  m_fBoostRange = fBoostRange;
  m_fBoost = 1.0f + m_fBoostRange*m_fBoostAmount;
}

- (void) setBoostAmount: (float) fBoostAmount
{
  m_fBoostAmount = fBoostAmount;
  m_fBoost       = 1.0f + m_fBoostRange*m_fBoostAmount;
}

- (void) setKnee: (float) fKnee
{
  m_fKnee = fKnee;
}

- (void) setHardness: (float) fHard
{
  m_fHardness = fHard;
}

//////////////////////////////////////////////////////////////////////////////
// micro accessors
//////////////////////////////////////////////////////////////////////////////

- (float) getBoostAmount { return m_fBoostAmount; };
- (float) getBoostRange  { return m_fBoostRange;  };
- (float) getKnee        { return m_fKnee;        };
- (float) getHardness    { return m_fHardness;    };

//////////////////////////////////////////////////////////////////////////////

@end

