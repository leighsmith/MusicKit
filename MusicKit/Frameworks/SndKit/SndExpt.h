////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    This class is to be regarded as HIGHLY EXPERIMENTAL.
//    Don't use it for general Snd use!!!
//
//    Current experimental activity - stream from disk behaviour.
//    Should be safe to use for playback ONLY!!
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//
//  Copyright (c) 2002, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
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
  BOOL             bImageInMemory;
  NSString        *theFileName;
  
  SndAudioBuffer  *cachedBuffer;
  NSRange          cachedBufferRange;
  NSLock          *cacheLock;

  NSConditionLock *readAheadLock;
  SndAudioBuffer  *readAheadBuffer;
  NSRange          readAheadRange;
}

- init;
- (void) dealloc;
- (unsigned char*) data;
- (int) dataSize;
- (int) readSoundfile:(NSString *)filename startFrame: (int) startFrame frameCount: (int) frameCount;
- (int) readSoundfile: (NSString*) filename;
- (SndAudioBuffer*) audioBufferForSamplesInRange: (NSRange) playRegion;
- (long) fillAudioBuffer: (SndAudioBuffer *) buff
	        toLength: (long) fillLength
          samplesInRange: (NSRange) sndSampleReadRange;

- (NSString*) filename;

- requestNextBufferWithRange: (NSRange) range;
- receiveRequestedBuffer: (SndAudioBuffer*) aBuffer;

@end

@interface SndExptAudioBufferServerJob : NSObject {
  SndExpt        *clientSndExpt;
  NSRange         audioBufferRange;
  SndAudioBuffer *audioBuffer;
}

- initWithSndExpt: (SndExpt*) sndExpt bufferRange: (NSRange) range;
- (SndExpt*) snd;
- (NSRange) range;
- (SndAudioBuffer*) buffer;

@end

@interface SndExptAudioBufferServer : NSObject {
  NSMutableArray  *pendingJobsArray;
  NSConditionLock *pendingJobsArrayLock;
  BOOL bGo;
  SndExptAudioBufferServerJob *activeJob;
}

+ (void) initialize;
+ defaultServer;
+ (SndAudioBuffer*) readRange: (NSRange) range ofSoundFile: (NSString*) theFileName;
- addJob: (SndExptAudioBufferServerJob*) aJob;
- (void) serverThread;
@end

////////////////////////////////////////////////////////////////////////////////

#endif
