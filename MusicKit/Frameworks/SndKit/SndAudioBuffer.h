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

// Describes each speakerConfiguration index
typedef enum {
    SND_SPEAKER_UNUSED = -1,
    SND_SPEAKER_LEFT = 0,
    SND_SPEAKER_RIGHT = 1,
    SND_SPEAKER_LEFT_SURROUND = 2,
    SND_SPEAKER_RIGHT_SURROUND = 3,
    SND_SPEAKER_CENTRE = 4, 
    SND_SPEAKER_LFE = 5,
    SND_SPEAKER_CENTRE_REAR = 6,
    // (More To Be Determined)
    SND_SPEAKER_SIZE
} SndSpeakerPosition;

/*!
  @class SndAudioBuffer
  @abstract   An in-memory audio buffer
  @discussion A SndAudioBuffer represents sound data in contiguous memory. As distinct from a Snd class, it holds typically small
	      chunks of sound data ready for signal processing or performance. Using classes such as SndAudioBufferQueue
              enables a fragmented arrangement of buffers across memory, typically for processing constraints. SndAudioBuffers
              are the closest SndKit match to the underlying audio hardware buffer. In addition to holding the sample data,
              SndAudioBuffer encapsulates sampling rate, number of channels, number of frames and the format of the sample data.
	      A SndAudioBuffer is guaranteed to be uncompressed, therefore it can be processed as a linear buffer of memory.
*/
@interface SndAudioBuffer : NSObject
{
    /*! @var format Holds sound parameters (sample rate, data format, channel count, frame count). */
    SndFormat format;
    /*! @var data The audio sample data. */
    NSMutableData *data;
    /*! @var speakerConfiguration Holds the association of channels to speakers. 
        Each element holds a channel number (0 - format.channelCount), -1 for unused and silent. 
        Elements are arranged as described by SndSpeakerPosition above.
     */
    signed char *speakerConfiguration;
}

/*!
  @method     audioBufferWithDataFormat:channelCount:samplingRate:duration:
  @abstract   Factory method creating an instance from a set of parameters individually specified.
  @param      dataFormat A SndSampleFormat.
  @param      channelCount The number of sound channels per frame.
  @param      sampleRate The sampling rate specified in Hertz (Hz).
  @param      timeInSeconds Duration is specified in seconds.
  @result     Returns an autoreleased SndAudioBuffer instance.
*/
+ audioBufferWithDataFormat: (SndSampleFormat) dataFormat
	       channelCount: (int) channelCount
               samplingRate: (double) sampleRate
                   duration: (double) timeInSeconds;

/*!
  @method     audioBufferWithDataFormat:channelCount:samplingRate:frameCount:
  @abstract   Factory method creating an instance from a set of parameters individually specified.
  @param      newDataFormat A SndSampleFormat.
  @param      newChannelCount The number of sound channels per frame.
  @param      newSamplingRate The sampling rate specified in Hertz (Hz).
  @param      newFrameCount Duration is specified in frames.
  @result     Returns an autoreleased SndAudioBuffer instance.
 */
+ audioBufferWithDataFormat: (SndSampleFormat) newDataFormat
	       channelCount: (int) newChannelCount
               samplingRate: (double) newSamplingRate
		 frameCount: (long) newFrameCount;

/*!
  @method     audioBufferWithFormat:
  @abstract   Factory method creating a zeroed buffer of the given format and length.
  @param      format A SndFormat describing the format of the buffer to be created.
  @result     Returns an autoreleased SndAudioBuffer instance.
 */
+ audioBufferWithFormat: (SndFormat) format;

/*!
    @method     audioBufferWithFormat:data:
    @abstract   Factory method
    @discussion The frameCount member of format MUST match the length of d (in bytes)!
    @param      format A pointer to a SndFormat.
    @param      dataPointer
    @result     Returns an autoreleased SndAudioBuffer instance.
*/
+ audioBufferWithFormat: (SndFormat *) format data: (void *) dataPointer;

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
    @param      rangeInFrames An NSRange structure indicating the start and end of the region in samples.
    @result     Returns an autoreleased SndAudioBuffer instance.
*/
+ audioBufferWithSnd: (Snd *) snd inRange: (NSRange) rangeInFrames;

/*!
  @method     initWithFormat:data:
  @abstract   Initialization method from a SndFormat and the data it describes.
  @discussion Can be used to initialize an instance with a buffer of data or with empty (i.e zeroed)
              data of the length given by format.frameCount if sampleData is NULL.
  @param      format A SndFormat. All fields must be valid before calling this method.
  @param      sampleData A pointer to the memory holding the sample data in the format described by format.
  @result     Returns self.
*/
- initWithFormat: (SndFormat *) format data: (void *) sampleData;

/*!
  @method     initWithBuffer:
  @abstract   Initialize a buffer with a matching format to the supplied buffer
  @discussion Creates a duplicated buffer (with a shallow copy, the data is referenced)
  @param      sndBuffer An existing initialised SndAudioBuffer.
  @result     Returns self.
*/
- initWithBuffer: (SndAudioBuffer *) sndBuffer;

/*!
  @method     initWithBuffer:range:
  @abstract   Initialize a buffer with a matching format to the supplied buffer, for a subset range of that sound.
  @discussion
  @param      sndBuffer An existing initialised SndAudioBuffer.
  @param      rangeInFrames
  @result     Returns self.
*/
- initWithBuffer: (SndAudioBuffer *) sndBuffer
           range: (NSRange) rangeInFrames;

/*!
  @method     initWithDataFormat:channelCount:samplingRate:frameCount:
  @abstract   Initializes the instance to the given format.
  @discussion Initializes the instance to the given sample data format,
              number of sound channels, sample rate, and frames (channel independent samples).
  @param      dataFormat A SndSampleFormat.
  @param      channelCount The number of sound channels.
  @param      samplingRate Sample rate in Hertz.
  @param      newFrameCount The number of frames, each frame consists of channelCount number of samples.
  @result     Returns self.
 */
- initWithDataFormat: (SndSampleFormat) dataFormat
	channelCount: (int) channelCount
        samplingRate: (double) samplingRate
          frameCount: (long) newFrameCount;

/*!
  @method     initWithDataFormat:channelCount:samplingRate:duration:
  @abstract   Initializes this audio buffer with sound data of the given format, channels, sample rate and duration.
  @discussion The samples are all silence.
  @param      dataFormat A SndSampleFormat.
  @param      channelCount Number of audio channels, 1 for mono, 2 for stereo, 4 for quad etc..
  @param      samplingRate Sample rate in Hertz.
  @param      timeInSeconds The size of the buffer in seconds.
  @result     Returns self.
*/
- initWithDataFormat: (SndSampleFormat) dataFormat
	channelCount: (int) channelCount
        samplingRate: (double) samplingRate
            duration: (double) timeInSeconds;

/*!
  @method     mixWithBuffer:fromStart:toEnd:
  @abstract   Mixes supplied SndAudioBuffer instance with the receiving instance, modifying it.
  @discussion Mixes over the given range of the buffer.
  @param      buff The SndAudioBuffer instance to mix.
  @param      start The sample frame to begin mixing from.
  @param      end The sample frame to end mixing at.
  @param      expand If TRUE, receiver is allowed to expand <i>buff</i> in place
                  if required to change data format before mixing, (not sample rate).
  @result     Returns the number of frames mixed.
*/
- (long) mixWithBuffer: (SndAudioBuffer *) buff
	     fromStart: (unsigned long) start
		 toEnd: (unsigned long) end
	     canExpand: (BOOL) expand;

/*!
  @method   mixWithBuffer:
  @abstract Mixes supplied SndAudioBuffer instance with the receiving instance, modifying it.
  @discussion Mixes the entire buffer onto the original buffer.
  @param      buff The SndAudioBuffer instance to mix.
  @result     Returns the number of frames mixed.
*/
- (long) mixWithBuffer: (SndAudioBuffer *) buff;

/*!
  @method     copyWithZone:
  @abstract   SndAudioBuffer object copying.
  @discussion
  @result     A duplicate SndAudioBuffer with its own, identical data.
*/
- (id) copyWithZone: (NSZone *) zone;

/*!
  @method     copyDataFromBuffer:
  @abstract
  @discussion
  @param      ab
  @result     self.
*/
- copyDataFromBuffer: (SndAudioBuffer *) ab;

/*!
  @method     copyBytes:count:format:
  @abstract   Copies bytes from the void * array given.
  @discussion Grows the internal NSMutableData object as necessary
  @param      bytes The void * array to copy from.
  @param      count The number of bytes to copy from the array.
  @param      format A SndFormat containing valid channelCount,
              samplingRate and dataFormat variables.
  @result     Returns self.
*/
- copyBytes: (void *) bytes count: (unsigned int) count format: (SndFormat) f;

/*!
  @method     copyBytes:intoRange:format:
  @abstract   Copies bytes from the void * array given into a sub region of the buffer.
  @discussion Grows the internal NSMutableData object as necessary
  @param      bytes The void * array to copy from.
  @param      range The start location and number of bytes to copy from the array.
  @param      format A SndFormat containing valid channelCount,
              samplingRate and dataFormat variables.
  @result     Returns self.
 */
- copyBytes: (void *) bytes intoRange: (NSRange) range format: (SndFormat) f;

/*!
  @method     copyFromBuffer:intoRange:
  @abstract   Copies from the start of the given buffer into a sub region of the receiving buffer.
  @discussion Grows the internal NSMutableData object as necessary
  @param      sourceBuffer The audio buffer to copy from.
  @param      rangeInSamples The start location and number of samples to copy to the receiving buffer.
  @result     Returns self.
 */
- copyFromBuffer: (SndAudioBuffer *) sourceBuffer intoRange: (NSRange) rangeInSamples;

/*!
  @method     copyFromBuffer:intoFrameRange:fromFrameRange:
  @abstract   Copies from the given region of the given buffer into a sub region of the receiving buffer.
  @discussion Grows the internal NSMutableData object as necessary
  @param      fromBuffer The audio buffer to copy from.
  @param      fromFrameRange The start location and number of samples to copy to the receiving buffer.
  @result     Returns the number of frames actually copied.
 */
- (long) copyFromBuffer: (SndAudioBuffer *) fromBuffer
	 intoFrameRange: (NSRange) bufferRange
	 fromFrameRange: (NSRange) fromFrameRange;

/*!
  @method fillSNDStreamBuffer:
  @abstract Fills the given stream buffer from the receiving audio buffer.
  @discussion Manages any conversion from interleaved SndAudioBuffer format to possibly non-interleaved SNDStreamBuffers.
  @param streamBuffer Pointer to the structure that describes the underlying audio API format.
 */
- (void) fillSNDStreamBuffer: (SNDStreamBuffer *) streamBuffer;

/*!
  @method audioBufferOfChannel:
  @abstract Returns a mono SndAudioBuffer instance extracting out the given audio channel of the receiving buffer.
  @discussion Use this to retrieve a single buffer from a multichannel buffer. Sending this to a mono buffer returns the
              buffer verbatim.
  @param channel The channel to extract. Must be in the range {0..[self channelCount] - 1}.
  @result Returns an autoreleased SndAudioBuffer instance.
 */
- (SndAudioBuffer *) audioBufferOfChannel: (int) channel;

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
  @discussion TODO Need to explain the consequences of setting the length longer or shorter than current. See the source code.
 */
- setLengthInSampleFrames: (unsigned long) newSampleFrameCount;

/*!
  @method     lengthInBytes
  @abstract   Returns the length of the buffer's sample data in bytes.
  @result     buffer length in bytes
*/
- (long) lengthInBytes;

/*!
  @method     duration
  @abstract   Returns the length of the audio buffer in seconds.
  @discussion
  @result     Duration in seconds (as determined by format sampling rate).
*/
- (double) duration;

/*!
  @method     samplingRate
  @abstract   Returns the sampling rate of the audio buffer in Hertz.
  @discussion
  @result     sampling rate
*/
- (double) samplingRate;

/*!
  @method     channelCount
  @abstract   Returns the number of channels in the audio buffer.
  @discussion
  @result     Number of channels
*/
- (int) channelCount;

/*!
  @method     dataFormat
  @abstract   Returns the format of the sample data as a SndSampleFormat enumerated type.
  @discussion
  @result     Data format enumerated type.
*/
- (SndSampleFormat) dataFormat;

/*!
  @method     format
  @abstract   Returns the format (number of frames, channels, dataFormat) of the audio buffer as a SndFormat structure.
  @discussion
  @result     Returns a SndFormat.
 */
- (SndFormat) format;

/*!
  @method     bytes
  @abstract   Returns a C pointer to the sample data.
  @discussion The user of this method will need to have determined the format of the data in order to correctly traverse it.
  @result     Pointer to the audio data.
*/
- (void *) bytes;

/*!
  @method     hasSameFormatAsBuffer:
  @abstract   compares the data format and length of this buffer to a second buffer.
  @discussion The number of frames (frameCount) <B>are</B> compared.
  @param      buff The SndAudioBuffer to compare to.
  @result     YES if the buffers have the same format and length, NO if there are
              any differences in format between buffers.
*/
- (BOOL) hasSameFormatAsBuffer: (SndAudioBuffer*) buff;

/*!
    @method     zero
    @abstract   Sets buffer data to zero. Silence.
    @result     Returns self.
*/
- zero;

/*!
  @method     zeroFrameRange:
  @abstract   Zeros (silences) a given range of frames.
  @discussion The range must be between 0 and the buffers frame length.
  @result     Returns self.
 */
- zeroFrameRange: (NSRange) frameRange;
 
/*!
    @method     frameSizeInBytes
    @abstract   Returns the size of a sample frame in bytes.
    @result     Integer size of sample frame (channels * sample size in bytes)
*/
- (int) frameSizeInBytes;

/*!
    @method     description
    @abstract   Returns a description of the instance as an NSString. 
    @result     NSString describing the audio buffer.
*/
- (NSString *) description;

/*!
  @method findMin:max:
  @abstract Finds the maximum and minimum sample values in the audio buffer and returns them as floats.
  @param pMin Points to a float to store the minimum sample value (between -1.0 and 1.0).
  @param pMax Points to a float to store the maximum sample value (between -1.0 and 1.0).
 */
- (void) findMin: (float *) pMin max: (float *) pMax;

/*!
  @method maximumAmplitude
  @abstract Returns the maximum amplitude of the format, that is, the maximum positive value of a sample.
  @result Returns the maximum value of a sample.
 */
- (double) maximumAmplitude;

/*!
    @method normalise
    @abstract Scale signal to maximum dynamic range of data format.
    @discussion Manages both signals below the dynamic range and in the case of floating point format,
                exceeding the normalised dynamic range (-1.0 to 1.0). Scales such that no D.C shift occurs
                across all channels.
 */
- (void) normalise;

/*!
  @method sampleAtFrameIndex:channel:
  @abstract Retrieves a normalised sample given the frame number (time position) and channel number.
  @param frameIndex The frame index, between 0 and the value returned by <B>lengthInSampleFrames</B>
                    less one, inclusive.
  @param channel The channel index, between 0 and the number of channels in the buffer (channelCount - 1)
                 to retrieve a single channel, channelCount to average all channels to a single value.
  @result Returns a normalised sample value as a float regardless of the data format.
 */
- (float) sampleAtFrameIndex: (unsigned long) frameIndex channel: (int) channel;

/*!
  @method stereoChannels:
  @abstract Retrieve the channels used for stereo presentation (left and right).
  @discussion This allows multichannel sound buffers to have a stereo version.
  @param leftAndRightChannels An array of at least two integers which will be assigned
         the channel number of the left speaker in the zeroth element of the array,
         the channel number of the right speaker in the first element of the array.
 */
- (void) stereoChannels: (int *) leftAndRightChannels;

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
  @abstract Converts the buffer to the sample format, sample rate and channel count described by SndFormat.
  @discussion The SndFormat field frameCount is ignored.
  @param newFormat The SndFormat giving the new format to convert the SndAudioBuffer instance to.
*/
- convertToFormat: (SndFormat) newFormat;

/*!
  @method convertToSampleFormat:
  @abstract Converts the sample data to the given format.
  @discussion Only the format is changed, the number of channels and sampling rate are preserved.
  @param  newDataFormat  A SndSampleFormat representing different sample data formats.
  @result Returns self if conversion was successful, nil if conversion was not possible, such as due to incompatible channel counts.
 */
- convertToSampleFormat: (SndSampleFormat) newDataFormat;

/*!
  @method convertBytes:intoFrameRange:fromFormat:channelCount:samplingRate:
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
	 channelCount: (int) fromChannelCount
         samplingRate: (double) fromSamplingRate;

/*!
  @method convertToSampleFormat:channelCount:
  @abstract Converts the sample data to the given format and channel count.
  @discussion Reallocates sample data if necessary for channel count changes.
  @param toDataFormat   A SndSampleFormat representing different sample data formats.
  @param toChannelCount Number of channels for the new sound. If less than the current number, channels are averaged,
                        if more, channels are duplicated.
  @result Returns self if conversion was successful, nil if conversion was not possible, such as due to incompatible channel counts.
 */
- convertToSampleFormat: (SndSampleFormat) toDataFormat
	   channelCount: (int) toChannelCount;

/*!
  @method convertToSampleFormat:channelCount:samplingRate:useLargeFilter:interpolateFilter:useLinearInterpolation:
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
- convertToSampleFormat: (SndSampleFormat) toDataFormat
	   channelCount: (int) toChannelCount
	   samplingRate: (double) toSampleRate
	 useLargeFilter: (BOOL) largeFilter
      interpolateFilter: (BOOL) interpolateFilter
 useLinearInterpolation: (BOOL) linearInterpolation;

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
SNDKIT_API int SndChangeSampleType(void *fromPtr, void *toPtr, SndSampleFormat dfFrom, SndSampleFormat dfTo, long outCount);

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
SNDKIT_API void SndChannelMap(void *inPtr,
                              void *outPtr,
                              long frames,
                              int oldNumChannels,
                              int newNumChannels,
                              SndSampleFormat df,
                              short *map);


/*!
  @function SndChannelDecrease
  @abstract Decreases the number of channels in the buffer, in place.
  @discussion Because samples are read and averaged, must be hostendian. 
	      Remaps channels in an arbitary fashion, decreasing the channels by mixing them.
              The channel map determines which old channels are to be mixed to the new channel arrangement. 
              This is an array of oldNumChannels length containing the indexes of the new channels.
              Channel indexes are zero based. If an index in the map is negative, that channel is zeroed in the output.
              For example, to map a quadraphonic file to stereo where the even numbered channels project to the left,
              odd numbered channels to the right, the map would be 0 1 0 1.
  @param inPtr
  @param outPtr
  @param frames
  @param oldNumChannels
  @param newNumChannels
  @param df data format of buffer
  @param map An array oldNumChannels long indicating which oldNumChannel to use in the new channel. 
             Not yet implemented: A channel index of -1 indicates zeroing (silencing) that channel.
*/

SNDKIT_API void SndChannelDecrease(void *inPtr,
				   void *outPtr,
				   unsigned long frames,
				   int oldNumChannels,
				   int newNumChannels,
				   SndSampleFormat df,
				   short *map);

@end

#endif
