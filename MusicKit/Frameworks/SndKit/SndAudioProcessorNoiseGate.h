////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorNoiseGate.h
//  SndKit
//
//  Noisegate
//
//  Created by SKoT McDonald on Fri Jan 11 2002.
//
//  Based on the 1997 C++ Vellocet VNoiseGate Cubase VST plugin by
//  Vellocet / SKoT McDonald <skot@vellocet.com>.
//  http://www.vellocet.com
//  (c) All rights reserved.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDKIT_SNDAUDIOPROCESSORNOISEGATE_H__
#define __SNDKIT_SNDAUDIOPROCESSORNOISEGATE_H__

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"

////////////////////////////////////////////////////////////////////////////////

/*!
  @enum noisegate_eKeys
  @brief Parameter keys
  @constant noisegate_kThreshold  Threshold
  @constant noisegate_kHoldTime   Hold time    
  @constant noisegate_kAttackTime Attack time
  @constant noisegate_kDecayTime  Decay time
  @constant noisegate_kChanMode   Channel mode
  @constant noisegate_kNumParams  Number of parameters
*/
enum noisegate_eKeys
{
  noisegate_kThreshold  = 0,
  noisegate_kHoldTime   = 1,
  noisegate_kAttackTime = 2,
  noisegate_kDecayTime  = 3,
  noisegate_kChanMode   = 4,
  noisegate_kNumParams  = 5
};

/*!
  @enum  noisegate_eMode
  @brief Gate modes
  @constant noisegate_modeGate    Simple gate
  @constant noisegate_modeHold    Gate-n-hold
  @constant noisegate_modeAttack  Attack mode
  @constant noisegate_modeDecay   Decay mode
*/
enum noisegate_eMode
{
  noisegate_modeGate = 0,
  noisegate_modeHold = 1,
  noisegate_modeAttack = 2,
  noisegate_modeDecay = 3
};

/*!
@enum  noisegate_eChanMode
 @brief Channel modes
 @constant noisegate_cmodeLinked  Linked gating (Either channel can trigger a dual gate)
 @constant noisegate_cmodeIndep  Independant channel gating 
 @constant noisegate_cmodeCross  Cross-linked independant gating (Left gates right, etc)
*/
enum noisegate_eChanMode
{
  noisegate_cmodeLinked = 0,
  noisegate_cmodeIndep  = 1,
  noisegate_cmodeCross  = 2
};

////////////////////////////////////////////////////////////////////////////////

/*!
@class SndAudioProcessorNoiseGate
@brief A Noisegate processor

  To come 
*/
@interface SndAudioProcessorNoiseGate : SndAudioProcessor {
/*!  */
  float fThreshold;
/*!  */
  float fHoldTime;
/*! */
  float fAttackTime;
/*!  */
  float fDecayTime;
/*!  */
  int   iChanMode;
@private
/*! */
  float m_g[2];
/*! */
  float m_t[2];
/*! */
  int   m_iMode[2];
/*! */
  int   m_iAttackCount[2];
/*! */
  int   m_iDecayCount[2];
/*! */
  int   m_iHoldCount[2];
}

@end

////////////////////////////////////////////////////////////////////////////////

#endif
