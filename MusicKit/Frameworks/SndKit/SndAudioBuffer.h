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
    @function   audioBufferWithFormat:duration:
    @abstract   Factory method
    @discussion
    @param      format
    @param      timeInSec
    @result     An SndAudioBuffer
*/
+ audioBufferWithFormat: (SndSoundStruct*) format duration: (double) timeInSec;

/*!
    @function   audioBufferWithFormat:data:
    @abstract   Factory method
    @discussion The dataLength member of format MUST be set to the length of d (in bytes)!
    @param      format
    @param      d
    @result     An SndAudioBuffer
*/
+ audioBufferWithFormat: (SndSoundStruct*) format data: (void*) d;

/*!
    @function   audioBufferWrapperAroundSNDStreamBuffer:
    @abstract   Factory method
    @discussion
    @param      cBuff
    @result     An SndAudioBuffer
*/
+ audioBufferWrapperAroundSNDStreamBuffer: (SNDStreamBuffer*) cBuff;

/*!
    @function   audioBufferWithSndSeg:range:
    @abstract   Factory method
    @discussion
    @param      snd 
    @param      r
    @result     An SndAudioBuffer 
*/
+ audioBufferWithSndSeg: (Snd*) snd range: (NSRange) r;

/*!
    @function   initWithFormat:data:
    @abstract   Initialization method
    @discussion
    @param      f
    @param      d
    @result     self.
*/
- initWithFormat: (SndSoundStruct*) f data: (void*) d;

/*!
    @function   mixWithBuffer:fromStart:toEnd:
    @abstract   Initialization method
    @discussion
    @param      buff
    @param      start
    @param      end
    @result     self.
*/
- mixWithBuffer: (SndAudioBuffer*) buff fromStart: (long) start toEnd: (long) end;

/*!
    @function   mixWithBuffer:
    @abstract
    @discussion
    @param      buff
    @result     self.
*/
- mixWithBuffer: (SndAudioBuffer*) buff;

/*!
    @function   copy
    @abstract
    @discussion
    @result     A duplicate SndAudioBuffer with its own, identical data.
*/
- copy;

/*!
    @function   copyData:
    @abstract
    @discussion
    @param      ab
    @result     self.
*/
- copyData: (SndAudioBuffer*) ab;

/*!
    @function   lengthInSamples
    @abstract
    @discussion
    @result     buffer length in sample frames
*/
- (long) lengthInSamples;

/*!
    @function lengthInBytes
    @abstract
    @discussion
    @result     buffer length in bytes
*/
- (long) lengthInBytes;

/*!
    @function   duration
    @abstract
    @discussion
    @result     Duration in seconds (as determined by format sampling rate)
*/
- (double) duration;

/*!
    @function   samplingRate
    @abstract
    @discussion
    @result     sampling rate
*/
- (double) samplingRate;

/*!
    @function   channelCount
    @abstract
    @discussion
    @result     Number of channels
*/
- (int) channelCount;

/*!
    @function   dataFormat
    @abstract
    @discussion
    @result     Data format identifier
*/
- (int) dataFormat;

/*!
    @function   data
    @abstract
    @discussion
    @result     pointer to raw data bytes
*/
- (void*) data;

/*!
    @function   format
    @abstract
    @discussion
    @result     Pointer to SndSoundStruct format description
*/
- (SndSoundStruct*) format;

/*!
    @function   zero
    @abstract   Sets data to zero
    @discussion
    @result     self
*/
- zero;
- (void) zeroForeignBuffer;

/*!
    @function   multiChannelSampleSizeInBytes
    @abstract
    @discussion
    @result     Integer size of sample frame (channels * sample size in bytes)
*/
- (int) multiChannelSampleSizeInBytes;

@end

#endif
