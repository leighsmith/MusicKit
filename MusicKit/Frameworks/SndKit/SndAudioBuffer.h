/*
  $Id$

  Description:

  Original Author: SKoT McDonald, <skot@tomandandy.com>, tomandandy music inc.

  Sat 10-Feb-2001, Copyright (c) 2001 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/

#ifndef __SNDAUDIOBUFFER_H__
#define __SNDAUDIOBUFFER_H__

#import <Foundation/Foundation.h>
#import <SndKit/SndKit.h>


@interface SndAudioBuffer : NSObject
{
    SndSoundStruct  formatSnd;
    void           *data;
    
@private
    BOOL            bOwnsData;
}

+ audioBufferWithFormat: (SndSoundStruct*) format duration: (double) timeInSec;
+ audioBufferWithFormat: (SndSoundStruct*) format data: (void*) d;
+ audioBufferWrapperAroundSNDStreamBuffer: (SNDStreamBuffer*) cBuff;
+ audioBufferWithSndSeg: (Snd*) snd range: (NSRange) r;

- initWithFormat: (SndSoundStruct*) f data: (void*) d;

- mixWithBuffer: (SndAudioBuffer*) buff fromStart: (long) start toEnd: (long) end;
- mixWithBuffer: (SndAudioBuffer*) buff;

- copy;
- copyData: (SndAudioBuffer*) ab;
- (long) lengthInSamples;
- (long) lengthInBytes;
- (double) duration;
- (double) samplingRate;
- (int) channelCount;
- (int) dataFormat;
- (void*) data;
- (SndSoundStruct*) format;

- zero;
- (void) zeroForeignBuffer;

- (int) multiChannelSampleSizeInBytes;

@end

#endif
