////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description: An object containing raw audio data, and doing audio 
//               operations on that data
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

#ifndef __SNDAUDIOBUFFER_H__
#define __SNDAUDIOBUFFER_H__

#import <Foundation/Foundation.h>
#import "Snd.h"
#import "SndFunctions.h"
#import "SndFormat.h"

/*!
  @class SndAudioBuffer
  @abstract   An in-memory audio buffer
  @discussion A SndAudioBuffer represents sound data in memory. As distinct from a Snd class, it may hold small
	      chunks of sound data ready for signal processing or performance. Using classes such as SndAudioBufferQueue
              enables a fragmented arrangement of buffers across memory, typically for processing constraints. SndAudioBuffers
              are the closest SndKit match to the underlying audio hardware buffer. In addition to holding the sample data,
              SndAudioBuffer encapsulates sampling rate, number of channels and the format of the sample data.
*/
@interface SndAudioBuffer : NSObject
{
/*! @var byteCount  */
  unsigned int byteCount;
/*! @var maxByteCount  */
  unsigned int maxByteCount;
/*! @var samplingRate  */
  double samplingRate;
/*! @var dataFormat */
  int    dataFormat;
/*! @var channelCount  */
  int    channelCount;
/*! @var format Will hold sound parameters and frame count rather than byteCount. Replaces samplingRate, dataFormat, channelCount */
  SndFormat format;
/*! @var data */
  NSMutableData *data;
}

/*!
  @method     audioBufferWithFormat:duration:
  @abstract   Factory method
  @discussion
  @param      format
  @param      timeInSec
  @result     An SndAudioBuffer
*/
// TODO + audioBufferWithFormat: (SndFormat *) format duration: (double) timeInSec;
+ audioBufferWithFormat: (SndSoundStruct*) format duration: (double) timeInSec;

/*!
  @method     audioBufferWithDataFormat:channelCount:samplingRate:duration:
  @abstract   Factory method
  @discussion
  @param      dataFormat
  @param      chanCount
  @param      samRate
  @param      duration
  @result     An SndAudioBuffer
*/
+ audioBufferWithDataFormat: (int) dataFormat
               channelCount: (int) chanCount
               samplingRate: (double) samRate
                   duration: (double) time;

/*!
    @method     audioBufferWithFormat:data:
    @abstract   Factory method
    @discussion The dataLength member of format MUST be set to the length of d (in bytes)!
    @param      format
    @param      d
    @result     An SndAudioBuffer
*/
+ audioBufferWithFormat: (SndFormat *) format data: (void *) d;

/*!
    @method     audioBufferWithSoundStruct:data:
    @abstract   Factory method
    @discussion The dataLength member of format MUST be set to the length of d (in bytes)!
    @param      format
    @param      d
    @result     An SndAudioBuffer
*/
+ audioBufferWithSoundStruct: (SndSoundStruct *) format data: (void *) d;

/*!
    @method     audioBufferWithSNDStreamBuffer:
    @abstract   Factory method creating an SndAudioBuffer instance from a SNDStreamBuffer.
    @discussion
    @param      streamBuffer A fully populated SNDStreamBuffer structure.
    @result     Returns an autoreleased SndAudioBuffer instance.
*/
+ audioBufferWithSNDStreamBuffer: (SNDStreamBuffer *) streamBuffer;

/*!
    @method     audioBufferWithSnd:inRange:
    @abstract   Factory method creating audioBuffers from a region of the given Snd.
    @discussion
    @param      snd 
    @param      r An NSRange structure indicating the start and end of the region in samples.
    @result     An SndAudioBuffer 
*/
+ audioBufferWithSnd: (Snd *) snd inRange: (NSRange) r;

/*!
  @method     initWithSoundStruct:data:
  @abstract   Initialization method from a SndSoundStruct.
  @discussion This used to be called initWithFormat:data: and is deprecated. 
              You should transition to using initWithFormat:data:
  @param      sndStruct A SndSoundStruct
  @param      sampleData A pointer to the memory holding the sample data in the format described by sndStruct.
  @result     self.
*/
- initWithSoundStruct: (SndSoundStruct *) sndStruct data: (void *) sampleData;

/*!
  @method     initWithFormat:data:
  @abstract   Initialization method from a SndFormat and the data it describes.
  @discussion
  @param      format A SndFormat
  @param      sampleData A pointer to the memory holding the sample data in the format described by format.
  @result     self.
*/
- initWithFormat: (SndFormat *) format data: (void *) sampleData;

/*!
  @method     initWithBuffer:
  @abstract   Initialize a buffer with a matching format to the supplied buffer
  @discussion Creates a duplicated buffer (with a shallow copy, the data is referenced)
  @param      b is a SndAudioBuffer.
  @result     self.
*/
- initWithBuffer: (SndAudioBuffer*) b;

/*!
  @method     initWithBuffer:range:
  @abstract   Initialize a buffer with a matching format to the supplied buffer method
  @discussion
  @param      b
  @param      r
  @result     self.
*/
- initWithBuffer: (SndAudioBuffer*) b
           range: (NSRange) r;

/*!
  @method     initWithDataFormat:channelCount:samplingRate:duration:
  @abstract   Initialization method
  @discussion
  @param      dataFormat
  @param      channelCount
  @param      samplingRate
  @param      time
  @result     An SndAudioBuffer
*/
- initWithDataFormat: (int) dataFormat
        channelCount: (int) channelCount
        samplingRate: (double) samplingRate
            duration: (double) time;

/*!
  @method     mixWithBuffer:fromStart:toEnd:
  @abstract   Mixes supplied SndAudioBuffer instance with the receiving instance, modifying it.
  @discussion Mixes over the given range of the buffer.
  @param      buff The SndAudioBuffer instance to mix.
  @param      start The sample frame to begin mixing from.
  @param      end The sample frame to end mixing at.
  @param      exp If TRUE, receiver is allowed to expand <i>buff</i> in place
                  if required to change data format before mixing, (not sample rate).
  @result     Returns the number of frames mixed.
*/
- (long) mixWithBuffer: (SndAudioBuffer*) buff
	     fromStart: (unsigned long) start
		 toEnd: (unsigned long) end
	     canExpand: (BOOL) exp;

/*!
  @method   mixWithBuffer:
  @abstract Mixes supplied SndAudioBuffer instance with the receiving instance, modifying it.
  @discussion Mixes the entire buffer onto the original buffer.
  @param      buff The SndAudioBuffer instance to mix.
  @result     Returns the number of frames mixed.
*/
- (long) mixWithBuffer: (SndAudioBuffer *) buff;

/*!
  @method     copy
  @abstract
  @discussion
  @result     A duplicate SndAudioBuffer with its own, identical data.
*/
- copy;

/*!
  @method     copyData:
  @abstract
  @discussion
  @param      ab
  @result     self.
*/
- copyData: (SndAudioBuffer *) ab;

/*!
  @method     copyBytes:count:format:
  @abstract   copies bytes from the char* array given
  @discussion grows the internal NSMutableData object as necessary
  @param      bytes the char* array to copy from
  @param      count the number of bytes to copy from the array
  @param      format pointer to a SndSoundStruct containing valid channelCount,
              samplingRate and dataFormat variables.
  @result     self.
*/
- copyBytes: (char *) bytes count: (unsigned int) count format: (SndSoundStruct *) f;

/*!
  @method     copyBytes:intoRange:format:
  @abstract   copies bytes from the char* array given into a sub region of the buffer.
  @discussion grows the internal NSMutableData object as necessary
  @param      bytes The char* array to copy from.
  @param      range The start location and number of bytes to copy from the array.
  @param      format pointer to a SndSoundStruct containing valid channelCount,
              samplingRate and dataFormat variables.
  @result     self.
 */
- copyBytes: (char *) bytes intoRange: (NSRange) range format: (SndSoundStruct *) f;

/*!
  @method     copyFromBuffer:intoRange:
  @abstract   Copies from the start of the given buffer into a sub region of the receiving buffer.
  @discussion Grows the internal NSMutableData object as necessary
  @param      fromBuffer The audio buffer to copy from.
  @param      range The start location and number of samples to copy to the receiving buffer.
  @result     self.
 */
- copyFromBuffer: (SndAudioBuffer *) sourceBuffer intoRange: (NSRange) rangeInSamples;

/*!
  @method     lengthInSampleFrames
  @abstract   Returns the number of sample frames in the audio buffer.
  @discussion A sample frame is a channel independent time position duration, it's duration is the reciprocal
              of the sample rate.
  @result     Returns the buffer length in sample frames.
*/
- (unsigned long) lengthInSampleFrames;

/*!
  @method     setLengthInSampleFrames
  @abstract   Changes the length of the buffer to <I>newSampleFrameCount</I> sample frames.
*/
- setLengthInSampleFrames: (unsigned long) newSampleFrameCount;

/*!
  @method     lengthInBytes
  @abstract
  @discussion
  @result     buffer length in bytes
*/
- (long) lengthInBytes;

/*!
  @method     duration
  @abstract
  @discussion
  @result     Duration in seconds (as determined by format sampling rate)
*/
- (double) duration;

/*!
  @method     samplingRate
  @abstract
  @discussion
  @result     sampling rate
*/
- (double) samplingRate;

/*!
  @method     channelCount
  @abstract
  @discussion
  @result     Number of channels
*/
- (int) channelCount;

/*!
  @method     dataFormat
  @abstract
  @discussion
  @result     Data format identifier
*/
- (int) dataFormat;

/*!
  @method     bytes
  @abstract
  @discussion
  @result     pointer to NSData object containing the audio data
*/
- (void*) bytes;

/*!
  @method     hasSameFormatAsBuffer:
  @abstract   compares the data format and length of this buffer to a second buffer
  @param      buff The SndAudioBuffer to compare to.
  @result     YES if the buffers have the same format and length, NO if there are
              any differences in format between buffers.
*/
- (BOOL) hasSameFormatAsBuffer: (SndAudioBuffer*) buff;

/*!
    @method     zero
    @abstract   Sets buffer data to zero.
    @discussion
    @result     self
*/
- zero;

/*!
  @method     zeroFrameRange:
  @abstract   Zeros a given range of frames.
  @discussion The range must be between 0 and the buffers frame length.
  @result     Returns self.
 */
- zeroFrameRange: (NSRange) frameRange;
 
/*!
    @method     frameSizeInBytes
    @abstract
    @discussion
    @result     Integer size of sample frame (channels * sample size in bytes)
*/
- (int) frameSizeInBytes;

/*!
    @method     description
    @abstract    
    @discussion 
    @result     NSString describing the audio buffer.
*/
- (NSString*) description;

/*!
  @method findMin:max:
  @abstract Finds the maximum and minimum sample values in the audio buffer and returns them as floats.
  @param pMin Points to a float to store the minimum sample value (between -1.0 and 1.0).
  @param pMax Points to a float to store the maximum sample value (between -1.0 and 1.0).
 */
- (void) findMin: (float *) pMin max: (float *) pMax;

/*!
  @method sampleAtFrameIndex:channel:
  @abstract Retrieves a normalized sample given the frame number (time position) and channel number.
  @param frameIndex The frame index, between 0 and the value returned by <B>lengthInSampleFrames</B>
                    less one, inclusive.
  @param channel The channel index, between 0 and the number of channels in the sound.
  @result Returns a normalized sample value as a float regardless of the data format.
 */
- (float) sampleAtFrameIndex: (unsigned long) frameIndex channel: (int) channel;

@end

////////////////////////////////////////////////////////////////////////////////

@interface SndAudioBuffer(SampleConversion)

/*!
  @method audioBufferConvertedToFormat:channelCount:samplingRate:
  @discussion Creates a new autoreleased buffer of the same number of samples as the receiver
              converted to the new format, sampling rate and channel count.
  @param toDataFormat A SndSampleFormat representing different sample data formats.
  @param toChannelCount The new number of channels in the raw sample data.
  @param toSamplingRate
  @result returns the new buffer instance.
 */
- (SndAudioBuffer *) audioBufferConvertedToFormat: (SndSampleFormat) toDataFormat
				     channelCount: (int) toChannelCount
				     samplingRate: (double) toSamplingRate;

/*!
  @method convertToFormat:
  @abstract Converts the sample data to the given format.
  @discussion Only the format is changed, the number of channels and sampling rate are preserved.
  @param  newDataFormat  A SndSampleFormat representing different sample data formats.
  @result Returns self if conversion was successful, nil if conversion was not possible, such as due to incompatible channel counts.
 */
- convertToFormat: (SndSampleFormat) newDataFormat;

/*!
  @method convertBytes:intoFrameRange:fromFormat:channels:samplingRate:
  @abstract Converts from a data pointer described by the given data format, channel count and
            sampling rate to the current buffer format.
  @discussion Checks the range does not exceed the bounds of the buffer. The number of frames read during the
              conversion is returned. This may be larger or smaller than the bufferFrameRange.length specified
              number if sample rate conversion is performed. This allows the calling method to correctly update
              it's read pointer.
  @param fromDataPtr      A pointer to raw sample data.
  @param bufferFrameRange Indicates the region of the buffer which will be converted, specified
                          in channel independent samples.
  @param fromDataFormat   A SndSampleFormat representing different sample data formats.
  @param fromChannelCount The old number of channels in the raw sample data.
  @param fromSamplingRate The old sampling rate in the raw sample data.
  @result Returns the number of frames that were read if conversion was successful, 0 if conversion was not
	  possible, such as due to incompatible channel counts.
 */
- (long) convertBytes: (void *) fromDataPtr
       intoFrameRange: (NSRange) bufferFrameRange
           fromFormat: (SndSampleFormat) fromDataFormat
             channels: (int) fromChannelCount
         samplingRate: (double) fromSamplingRate;

/*!
  @method convertToFormat:channelCount:
  @abstract Converts the sample data to the given format and channel count.
  @discussion Reallocates sample data if necessary for channel count changes.
  @param toDataFormat   A SndSampleFormat representing different sample data formats.
  @param toChannelCount Number of channels for the new sound. If less than the current number, channels are averaged,
                        if more, channels are duplicated.
  @result Returns self if conversion was successful, nil if conversion was not possible, such as due to incompatible channel counts.
 */
- convertToFormat: (SndSampleFormat) toDataFormat
     channelCount: (int) toChannelCount;

/*!
  @method convertToFormat:channelCount:samplingRate:useLargeFilter:interpolateFilter:useLinearInterpolation:
  @abstract Converts the sample data to the given format, channel count and sampling rate.
  @discussion The parameter fields useLargeFilter: interpolateFilter:  and useLinearInterpolation: control the
              particular resampling methods used.
  @param toDataFormat    A SndSampleFormat representing different sample data formats.
  @param toChannelCount  The new number of channels. Reallocation occurs if expanding buffers.
  @param toSampleRate    The new sampling rate.
  @param largeFilter     TRUE means use 65tap FIR filter, with higher quality.
  @param interpolateFilter When not in "fast" mode, controls whether or not the
                          filter coefficients are interpolated (disregarded in fast mode).
  @param linearInterpolation If TRUE, linear interpolation uses a fast, noninterpolating resample routine but is relatively noisy.
  @result Returns self if conversion was successful, nil if conversion was not possible, such as due to incompatible channel counts.
 */
- convertToFormat: (SndSampleFormat) toDataFormat
     channelCount: (int) toChannelCount
     samplingRate: (double) toSampleRate
   useLargeFilter: (BOOL) largeFilter
interpolateFilter: (BOOL) interpolateFilter
useLinearInterpolation: (BOOL) linearInterpolation;

/*!
 @function SndConvertSound
 @abstract Convert from one sound struct format to another.
 @discussion <B>This is an obsolete function. Rewrite to use SndAudioBuffer instances and convertToFormat: methods!</B>
             Converts from one sound struct to another, where toSound defines the format the data is to be
             converted to and provides the location for the converted sound data.
 @param fromSound Defines the sound data to be converted.
 @param toSound Defines the format the data is to be converted to and provides the location
                for the converted sound data.
 @param allocate Allocate the memory to use for the resulting converted sound, freeing the toSound passed in.
 @param largeFilter Use a large filter for better quality resampling.
 @param interpFilter Use interpolated filter for conversion for better quality resampling.
 @param fast Do the conversion fast, without filtering, low quality resampling.
 @result Returns various SND_ERR constants, or SND_ERR_NONE if the conversion worked.
 */
SNDKIT_API int SndConvertSound(const SndSoundStruct *fromSound,
				    SndSoundStruct **toSound,
				BOOL allocate,
				BOOL largeFilter,
				BOOL interpFilter,
				BOOL fast);

/*!
  @function SndChangeSampleType
  @abstract Does an conversion from one sample type to another.
  @discussion If fromPtr and toPtr are the same it does the conversion inplace.
           The buffer must be long enough to hold the increased number
           of bytes if the conversion calls for it. Data must be in host
           endian order. Currently knows about ulaw, char, short, int,
           float and double data types, represented by the data format
           parameters (prefixed SND_FORMAT_).
  @param fromPtr Pointer to the byte buffer to read data from.
  @param toPtr Pointer to the byte buffer to write data to.
  @param dfFrom The data format to convert from.
  @param dfTo The data format to convert to.
  @param outCount Length in samples of the original buffer, counting number of channels, that is duration in samples * number of channels.
  @result Returns error code.
 */
SNDKIT_API int SndChangeSampleType (void *fromPtr, void *toPtr, SndSampleFormat dfFrom, SndSampleFormat dfTo, long outCount);

/*!
  @function SndChangeSampleRate
  @abstract Resamples an input buffer into an output buffer, effectively
            changing the sampling rate.
  @discussion Internal function which uses the "resample" routine to resample
           an input buffer into an output buffer. Various boolean flags
           control the speed and accuracy of the conversion. The output is
           always 16 bit, but the input routine can read ulaw, char, short,
           int, float and double types, of any number of channels. The old
           and new sample rates are determined by fromSound.samplingRate
           and toSound->samplingRate, respectively. Data must be in host
           endian order.
  @param fromSound Holds header information about the input sound.
  @param inputPtr Points to a contiguous buffer of input data to be used.
  @param toSound Holds header information about the target sound.
  @param outPtr Pointer to a buffer big enough to hold the output data.
  @param factor Ratio of new_sample_rate / old_sample_rate
  @param largeFilter TRUE means use 65tap FIR filter, with higher quality.
  @param interpFilter When not in "fast" mode, controls whether or not the
                     filter coefficients are interpolated (disregarded in fast mode).
  @param fast if TRUE, uses a fast, noninterpolating resample routine.
  @result void
 */
SNDKIT_API void SndChangeSampleRate(const SndFormat fromSound,
				    void *inputPtr,
				    SndFormat *toSound,
				    short *outPtr,
				    BOOL largeFilter, BOOL interpFilter, BOOL fast);

/*!
  @function   SndChannelMap
  @abstract   Maps old channels to the new number of channels in the buffer, in place.
  @discussion Endian-agnostic. Buffer must have enough memory allocated to hold the increased data.
              Remaps channels in an arbitary fashion, either increasing or decreasing the channels or rearranging them.
              The channel map determines which old channels are to be copied to the new channel arrangement. This is an
              array of newNumChannels length containing the indexes of the old channels.
              Channel indexes are zero based. If an index in the map is negative, that channel is zeroed in the output.
              For example, to map a stereo file to hexaphonic where the even numbered channels project to the left,
              odd numbered channels to the right, the map would be 0 1 0 1 0 1.
  @param inPtr
  @param outPtr
  @param frames
  @param oldNumChannels 
  @param newNumChannels
  @param df A SndSampleFormat giving the data format of buffer.
  @param map An array newNumChannels long indicating which oldNumChannel to use in the new channel. 
             A channel index of -1 indicates zeroing (silencing) that channel.
 */
SNDKIT_API void SndChannelMap (void *inPtr,
                               void *outPtr,
                               int frames,
                               int oldNumChannels,
                               int newNumChannels,
                               SndSampleFormat df,
                               short *map);


/*!
  @function SndChannelDecrease
  @abstract Decreases the number of channels in the buffer, in place.
  @discussion Because samples are read and averaged, must be hostendian. Only
           exact divisors are supported (anything to 1, even numbers to even numbers)
  @param inPtr
  @param outPtr
  @param frames
  @param oldNumChannels
  @param newNumChannels
  @param df data format of buffer
  @result does not return error code.
*/

SNDKIT_API void SndChannelDecrease (void *inPtr,
				    void *outPtr,
				    unsigned int frames,
				    int oldNumChannels,
				    int newNumChannels,
				    SndSampleFormat df);

@end

#endif
