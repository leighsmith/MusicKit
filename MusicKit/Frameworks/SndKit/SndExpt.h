////////////////////////////////////////////////////////////////////////////////
//
//  SndExpt.h
//  SndKit
//
//  Created by SKoT McDonald on Fri Jan 18 2002.
//  Copyright (c) 2002 tomandandy. All rights reserved.
//
//  This class is to be regarded as HIGHLY EXPERIMENTAL.
//  Don't use it for general Snd use!!!
//
//  Current experimental activity - stream from disk behaviour.
//  Should be safe to use for playback ONLY!!
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDKIT_

#import <Foundation/Foundation.h>

#import "Snd.h"

////////////////////////////////////////////////////////////////////////////////

/*!
@class SndExpt
@abstract Experimental Snd class. USE WITH EXTREME CAUTION.
 _ONLY_ use SndExpt for solo playback at present.
@discussion Experimental testing and development ground for disk-based Snds.
*/

@interface SndExpt : Snd {
  BOOL            bImageInMemory;
  NSString       *theFileName;
  SndAudioBuffer *cachedBuffer;
  NSRange         cachedBufferRange;
}

- init;
- (void) dealloc;
- (unsigned char*) data;
- (int) dataSize;
- (int)readSoundfile:(NSString *)filename startFrame: (int) startFrame frameCount: (int) frameCount;
- (int) readSoundfile: (NSString*) filename;
- (SndAudioBuffer*) audioBufferForSamplesInRange: (NSRange) playRegion;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
