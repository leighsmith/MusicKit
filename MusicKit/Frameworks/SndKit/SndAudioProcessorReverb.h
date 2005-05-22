////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    FreeVerb-based
//    FreeVerb originally written by Jezar at Dreampoint, June 2000
//    http://www.dreampoint.co.uk
//
//    TODO: make the ObjC to C++ bridge unnecessary!!
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDKIT_SNDAUDIOPROCESSORREVERB_H__
#define __SNDKIT_SNDAUDIOPROCESSORREVERB_H__

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"

/*!
 @brief SndReverbParam Parameter keys
 @constant rvrbRoomSize  Room size
 @constant rvrbDamp  Damping amount
 @constant rvrbWet  Wet level
 @constant rvrbDry  Dry level
 @constant rvrbWidth  Width
 @constant rvrbMode  Mode [1 = hold]
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
@brief A reverb processor

  To come.
*/
@interface SndAudioProcessorReverb : SndAudioProcessor {
@private  
/*! @var cppFreeReverbObj C++ object pointer for the FreeVerb model */
  void* cppFreeReverbObj; 
}

@end

////////////////////////////////////////////////////////////////////////////////

#endif
