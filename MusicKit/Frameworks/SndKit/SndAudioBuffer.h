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
#import "SndKit.h"


/*!
    @class      SndAudioBuffer 
    @abstract   Audio Buffer
    @discussion To come
*/
@interface SndAudioBuffer : NSObject
{
/*! @var            formatSnd */
    SndSoundStruct  formatSnd;
/*! @var            data      */
    void           *data;
/*! @var            bOwnsData */    
    BOOL            bOwnsData;
}

/*!
    @method   audioBufferWithFormat:duration:
    @abstract   Factory method
    @discussion
    @param      format
    @param      timeInSec
    @result     An SndAudioBuffer
*/
+ audioBufferWithFormat: (SndSoundStruct*) format duration: (double) timeInSec;

/*!
    @method   audioBufferWithFormat:data:
    @abstract   Factory method
    @discussion The dataLength member of format MUST be set to the length of d (in bytes)!
    @param      format
    @param      d
    @result     An SndAudioBuffer
*/
+ audioBufferWithFormat: (SndSoundStruct*) format data: (void*) d;

/*!
    @method   audioBufferWrapperAroundSNDStreamBuffer:
    @abstract   Factory method
    @discussion
    @param      cBuff
    @result     An SndAudioBuffer
*/
+ audioBufferWrapperAroundSNDStreamBuffer: (SNDStreamBuffer*) cBuff;

/*!
    @method   audioBufferWithSndSeg:range:
    @abstract   Factory method
    @discussion
    @param      snd 
    @param      r
    @result     An SndAudioBuffer 
*/
+ audioBufferWithSndSeg: (Snd*) snd range: (NSRange) r;

/*!
    @method   initWithFormat:data:
    @abstract   Initialization method
    @discussion
    @param      f
    @param      d
    @result     self.
*/
- initWithFormat: (SndSoundStruct*) f data: (void*) d;

/*!
    @method   mixWithBuffer:fromStart:toEnd:
    @abstract   Initialization method
    @discussion
    @param      buff
    @param      start
    @param      end
    @result     self.
*/
- mixWithBuffer: (SndAudioBuffer*) buff fromStart: (long) start toEnd: (long) end;

/*!
    @method   mixWithBuffer:
    @abstract
    @discussion
    @param      buff
    @result     self.
*/
- mixWithBuffer: (SndAudioBuffer*) buff;

/*!
    @method   copy
    @abstract
    @discussion
    @result     A duplicate SndAudioBuffer with its own, identical data.
*/
- copy;

/*!
    @method   copyData:
    @abstract
    @discussion
    @param      ab
    @result     self.
*/
- copyData: (SndAudioBuffer*) ab;

/*!
    @method   lengthInSamples
    @abstract
    @discussion
    @result     buffer length in sample frames
*/
- (long) lengthInSamples;

/*!
    @method lengthInBytes
    @abstract
    @discussion
    @result     buffer length in bytes
*/
- (long) lengthInBytes;

/*!
    @method   duration
    @abstract
    @discussion
    @result     Duration in seconds (as determined by format sampling rate)
*/
- (double) duration;

/*!
    @method   samplingRate
    @abstract
    @discussion
    @result     sampling rate
*/
- (double) samplingRate;

/*!
    @method   channelCount
    @abstract
    @discussion
    @result     Number of channels
*/
- (int) channelCount;

/*!
    @method   dataFormat
    @abstract
    @discussion
    @result     Data format identifier
*/
- (int) dataFormat;

/*!
    @method   data
    @abstract
    @discussion
    @result     pointer to raw data bytes
*/
- (void*) data;

/*!
    @method   format
    @abstract
    @discussion
    @result     Pointer to SndSoundStruct format description
*/
- (SndSoundStruct*) format;

/*!
    @method     zero
    @abstract   Sets data to zero
    @discussion
    @result     self
*/
- zero;

/*!
    @method     zeroForeignBuffer
    @abstract   Sets buffer data to zero, regardless of whether the buffer is owned by the SndAudioBuffer or not.
    @discussion Same as zero, but skips a buffer ownership test.
    @result     self
*/
- (void) zeroForeignBuffer;

/*!
    @method   multiChannelSampleSizeInBytes
    @abstract
    @discussion
    @result     Integer size of sample frame (channels * sample size in bytes)
*/
- (int) multiChannelSampleSizeInBytes;

- (NSString*) description;

@end

#endif
