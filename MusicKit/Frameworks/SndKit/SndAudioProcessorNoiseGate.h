////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorNoiseGate.h
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

#ifndef __SNDKIT_SNDAUDIOPROCESSORNOISEGATE_H__
#define __SNDKIT_SNDAUDIOPROCESSORNOISEGATE_H__

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"

////////////////////////////////////////////////////////////////////////////////

enum noisegate_eKeys
{
  noisegate_kThreshold  = 0,
  noisegate_kHoldTime   = 1,
  noisegate_kAttackTime = 2,
  noisegate_kDecayTime  = 3,
  noisegate_kChanMode   = 4,
  noisegate_kNumParams  = 5
};

enum noisegate_eMode
{
  noisegate_modeGate = 0,
  noisegate_modeHold = 1,
  noisegate_modeAttack = 2,
  noisegate_modeDecay = 3
};

enum noisegate_eChanMode
{
  noisegate_cmodeLinked = 0,
  noisegate_cmodeIndep  = 1,
  noisegate_cmodeCross  = 2
};

////////////////////////////////////////////////////////////////////////////////

@interface SndAudioProcessorNoiseGate : SndAudioProcessor {
  float fThreshold;
  float fHoldTime;
  float fAttackTime;
  float fDecayTime;
  float m_g[2];
  float m_t[2];
  int   m_iMode[2];
  int   m_iAttackCount[2];
  int   m_iDecayCount[2];
  int   m_iHoldCount[2];
  int   iChanMode;
}

@end

////////////////////////////////////////////////////////////////////////////////

#endif