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

/*!
    @method audioBufferWithFormat:duration:
    @abstract Factory method
    @discussion
    @param (SndSoundStruct*) format
    @param (double) timeInSec
    @result An SndAudioBuffer
*/
+ audioBufferWithFormat: (SndSoundStruct*) format duration: (double) timeInSec;

/*!
    @method audioBufferWithFormat:data:
    @abstract Factory method
    @discussion The dataLength member of format MUST be set to the length of d (in bytes)!
    @param (SndSoundStruct*) format
    @param (void*) d
    @result An SndAudioBuffer
*/
+ audioBufferWithFormat: (SndSoundStruct*) format data: (void*) d;

/*!
    @method audioBufferWrapperAroundSNDStreamBuffer:
    @abstract Factory method
    @discussion
    @param (SNDStreamBuffer*) cBuff
    @result An SndAudioBuffer
*/
+ audioBufferWrapperAroundSNDStreamBuffer: (SNDStreamBuffer*) cBuff;

/*!
    @method audioBufferWithSndSeg:range:
    @abstract Factory method
    @discussion
    @param (Snd*) snd 
    @param (NSRange) r
    @result An SndAudioBuffer 
*/
+ audioBufferWithSndSeg: (Snd*) snd range: (NSRange) r;

/*!
    @method initWithFormat:data:
    @abstract Initialization method
    @discussion
    @param (SndSoundStruct*) f
    @param (void*) d
    @result self.
*/
- initWithFormat: (SndSoundStruct*) f data: (void*) d;

/*!
    @method mixWithBuffer:fromStart:toEnd:
    @abstract Initialization method
    @discussion
    @param (SndAudioBuffer*) buff
    @param (long) start
    @param (long) end
    @result self.
*/
- mixWithBuffer: (SndAudioBuffer*) buff fromStart: (long) start toEnd: (long) end;

/*!
    @method mixWithBuffer:
    @abstract
    @discussion
    @param (SndAudioBuffer*) buff
    @result self.
*/
- mixWithBuffer: (SndAudioBuffer*) buff;

/*!
    @method copy
    @abstract
    @discussion
    @result A duplicate SndAudioBuffer with its own, identical data.
*/
- copy;

/*!
    @method copyData:
    @abstract
    @discussion
    @param (SndAudioBuffer*) ab
    @result self.
*/
- copyData: (SndAudioBuffer*) ab;

/*!
    @method lengthInSamples
    @abstract
    @discussion
    @result (long) buffer length in sample frames
*/
- (long) lengthInSamples;

/*!
    @method lengthInBytes
    @abstract
    @discussion
    @result (long) buffer length in bytes
*/
- (long) lengthInBytes;

/*!
    @method duration
    @abstract
    @discussion
    @result Duration in seconds (as determined by format sampling rate)
*/
- (double) duration;

/*!
    @method samplingRate
    @abstract
    @discussion
    @result sampling rate
*/
- (double) samplingRate;

/*!
    @method channelCount
    @abstract
    @discussion
    @result Number of channels
*/
- (int) channelCount;

/*!
    @method dataFormat
    @abstract
    @discussion
    @result Data format identifier
*/
- (int) dataFormat;

/*!
    @method data
    @abstract
    @discussion
    @result pointer to raw data bytes
*/
- (void*) data;

/*!
    @method format
    @abstract
    @discussion
    @result Pointer to SndSoundStruct format description
*/
- (SndSoundStruct*) format;

/*!
    @method zero
    @abstract Sets data to zero
    @discussion
    @result self
*/
- zero;
- (void) zeroForeignBuffer;

/*!
    @method multiChannelSampleSizeInBytes
    @abstract
    @discussion
    @result Integer size of sample frame (channels * sample size in bytes)
*/
- (int) multiChannelSampleSizeInBytes;

@end

#endif
