////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorReverb.h
//  SndKit
//
//  Created by skot on Wed Mar 28 2001. <skot@tomandandy.com>
//  Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and 
//  non-commercial purposes so long as the author attribution and copyright 
//  messages remain intact and accompany all relevant code.
//
//  FreeVerb-based
//  FreeVerb originally written by Jezar at Dreampoint, June 2000
//  http://www.dreampoint.co.uk
//
//  TODO: make the ObjC to C++ bridge unnecessary!!
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDKIT_SNDAUDIOPROCESSORREVERB_H__
#define __SNDKIT_SNDAUDIOPROCESSORREVERB_H__

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"

/*!
 @enum SndReverbParam
 @abstract Parameter keys
 @constant rvrbRoomSize   Room size
 @constant rvrbDamp       Damping amount
 @constant rvrbWet        Wet level
 @constant rvrbDry        Dry level
 @constant rvrbWidth      Width
 @constant rvrbMode       Mode [1 = hold]
 @constant rvrbNumParams  Number of parameters
*/
enum {
  rvrbRoomSize  = 0,
  rvrbDamp      = 1,
  rvrbWet       = 2,
  rvrbDry       = 3,
  rvrbWidth     = 4,
  rvrbMode      = 5, 
  rvrbNumParams = 6
};

////////////////////////////////////////////////////////////////////////////////

/*!
@class SndAudioProcessorReverb
@abstract A reverb processor
@discussion To come.
*/
@interface SndAudioProcessorReverb : SndAudioProcessor {
@private  
/*! @var cppFreeReverbObj C++ object pointer for the FreeVerb model */
  void* cppFreeReverbObj; 
}

@end

////////////////////////////////////////////////////////////////////////////////

#endif
