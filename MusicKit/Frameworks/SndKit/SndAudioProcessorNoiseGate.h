////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorNoiseGate.h
//  SndKit
//
//  Created by SKoT McDonald on Fri Jan 11 2002.
//  Copyright (c) 2001 tomandandy. All rights reserved.
//
//  Based on the 1997 C++ Vellocet VNoiseGate Cubase VST plugin by
//  Vellocet / SKoT McDonald <skot@vellocet.com>
//  http://www.vellocet.com
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDKIT_SNDAUDIOPROCESSORNOISEGATE_H__
#define __SNDKIT_SNDAUDIOPROCESSORNOISEGATE_H__

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"

////////////////////////////////////////////////////////////////////////////////

/*!
  @enum  noisegate_eKeys
  @const noisegate_kThreshold 
  @const noisegate_kHoldTime   
  @const noisegate_kAttackTime 
  @const noisegate_kDecayTime  
  @const noisegate_kChanMode   
  @const noisegate_kNumParams  
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
  @const noisegate_kThreshold
  @const noisegate_modeGate 
  @const noisegate_modeHold 
  @const noisegate_modeAttack
  @const noisegate_modeDecay 
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
  @const noisegate_cmodeLinked
  @const noisegate_cmodeIndep
  @const noisegate_cmodeCross
*/
enum noisegate_eChanMode
{
  noisegate_cmodeLinked = 0,
  noisegate_cmodeIndep  = 1,
  noisegate_cmodeCross  = 2
};

////////////////////////////////////////////////////////////////////////////////

/*!
@class      SndAudioProcessorNoiseGate
@abstract   A Noisegate processor
@discussion To come 
*/
@interface SndAudioProcessorNoiseGate : SndAudioProcessor {
/*! @var fThreshold  */
  float fThreshold;
/*! @var fHoldTime   */
  float fHoldTime;
/*! @var fAttackTime */
  float fAttackTime;
/*! @var fDecayTime  */
  float fDecayTime;
/*! @var iChanMode   */
  int   iChanMode;
@private
/*! @var m_g */
  float m_g[2];
/*! @var m_t */
  float m_t[2];
/*! @var m_iMode */
  int   m_iMode[2];
/*! @var m_iAttackCount */
  int   m_iAttackCount[2];
/*! @var m_iDecayCount */
  int   m_iDecayCount[2];
/*! @var m_iHoldCount */
  int   m_iHoldCount[2];
}

@end

////////////////////////////////////////////////////////////////////////////////

#endif
