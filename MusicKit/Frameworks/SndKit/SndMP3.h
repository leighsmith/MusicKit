////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//  SndKit
//
//  Description:
//    Snd subclass reading MP3 files. 
//
//  Original Author: SKoT McDonald <skot@tomandandy.com>
//
//  Copyright (c) 2002, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SND_MP3_H__
#define __SND_MP3_H__

#import <Foundation/Foundation.h>
#import "Snd.h"
#import <hip.h>

/*!
  @class SndMP3
  @abstract SndMP3 is a subclass of Snd for reading MP3 files.
  @discussion Decoding of MP3 sound files can be done in a background thread during reading (predecoding),
              or on-the-fly during playback, allowing selection of memory consumption versus processor load.
              Decoding on the fly has the advantage of memory conservation, but is more processor intensive.
              The factory methods +preDecode and +setPreDecode: are used to control the use of on-the-fly MP3
              sound file decoding or to use the pre-decoding approach.

              The current on-the-fly version has the limitation that it only works with CBR (constant bit rate) MP3 streams.
  
              Support is only for 44.1KHz stereo MP3s at the moment.
 */
 
////////////////////////////////////////////////////////////////////////////////

@interface SndMP3 : Snd {
    /*! @var mp3Data The MP3 bitstream (encoded) data. */
    NSData *mp3Data;
    /*! @var mp3DataDescription Preserves the state of the MP3 stream decoding. */
    HIP_File mp3DataDescription;
    /*! @var encodedFrameLocations An array of longs which give the locations in the MP3 bitstream data of the start of each MP3 frame. */
    long *encodedFrameLocations;
    /*! @var encodedFrameLocationsCount The number of frame locations in encodedFrameLocations. */
    long encodedFrameLocationsCount;
    /*! @var currentMP3FrameID The most recently decoded bitstream frame index into encodedFrameLocations. */
    int currentMP3FrameID;
    /*! @var decodedPCMBuffer Cached most recently decoded bitstream frame as a SndAudioBuffer. Held in 16 bit PCM data (left and right channels) format. */
    SndAudioBuffer *decodedPCMBuffer;
    // TODO There is scope to hold the last n frames, rather than just one, if we are simultaneously performing the same SndMP3.

    /*! @var pcmBufferToAccess */
    SndAudioBuffer *pcmBufferToAccess;
	
    /*! @var duration The duration of the sound (when decoded) in seconds. Necessary only as long as Snd uses SndSoundStructs. */
    double duration;

    // Variables used in separate threaded predecoding.
    NSMutableData *pcmData; // the decoded linear sample data.
    long           decodedSampleCount; // Number of samples decoded so far.
    BOOL           bDecoding;    // we are decoding.
    NSLock        *pcmDataLock;
}

/*!
  @method setPreDecode:
  @abstract Sets whether to do background predecoding when reading an MP3 file or whether decoding is done on the fly.
  @discussion When an MP3 file is read, <i>predecoding</i> of the MP3 bitstream to linear PCM can be done in the background.
              This is significantly more memory hungry than decoding the MP3 stream on the fly, but less processor intensive,
              moving the decoding processing before playback or other signal processing.
              
              Decoding on the fly currently has the limitation that only one MP3 stream can play at any time. This limitation
              is being worked on.
              
              The default is to decode on the fly.
              
  @param yesOrNo YES to enable background predecoding, NO to decode on the fly.
 */
+ (void) setPreDecode: (BOOL) yesOrNo;

/*!
  @method preDecode
  @abstract Returns the current state of background predecoding.
  @result Returns YES if background predecoding will occur on reading an MP3 file, NO if decoding will be done on the fly. 
 */
+ (BOOL) preDecode;

- (int) readSoundURL: (NSURL *) soundURL;
- initFromSoundURL: (NSURL *) url;
- (void) dealloc;
- (double) duration;
- (long) lengthInSampleFrames;
- (int) channelCount;
- (double) samplingRate;
- (SndSampleFormat) dataFormat;

/*!
  @method convertToFormat:samplingRate:channelCount:
  @discussion Actually all this does is check the MP3 is the same as the native format, if not it flags an error.
 */
- (int) convertToFormat: (SndSampleFormat) toFormat
	   samplingRate: (double) toRate
	   channelCount: (int) toChannelCount;

/*!
  @method convertToNativeFormat
  @discussion Actually all this does is check the MP3 is the same as the native format, if not it flags an error.
 */
- (int) convertToNativeFormat;

/*!
  @method insertIntoAudioBuffer:intoFrameRange:samplesInRange:
  @abstract Copies samples from self into a sub region of the provided SndAudioBuffer.
  @discussion If the buffer and the SndMP3 instance have different formats (after decoding the MP3 bitstream),
              a format conversion will be performed to the buffers format, including resampling
              if necessary. The SndMP3 audio data will be read enough to fill the range of samples
              specified according to the sample rate of the buffer compared to the sample rate
              of the SndMP3 instance. In the case where there are less than the needed number of
              samples left in the sndFrameRange to completely insert into the specified buffer region, the
              number of samples inserted will be returned less than bufferRange.length. 
 
              Caching is performed so repeatedly retrieving the same frame successively incurs no decoding overhead.
			
  @param buff The SndAudioBuffer object into which to copy the data.
  @param bufferRange An NSRange of sample frames (i.e channel independent time position specified in samples)
		     in the buffer to copy into.
  @param sndFrameRange An NSRange of sample frames (i.e channel independent time position specified in samples)
                       within the Snd to start reading data from and the last permissible index to read from.
  @result Returns the number of samples actually inserted. This may be less than the length specified
          in the bufferRange if sndStartIndex is less than the number samples needed to convert to
          insert in the specified buffer region.
 */
- (long) insertIntoAudioBuffer: (SndAudioBuffer *) anAudioBuffer
	        intoFrameRange: (NSRange) bufferRange
	        samplesInRange: (NSRange) sndReadingRange;

- (int) readSoundfile: (NSString*) filename;
- (int) readSoundURL: (NSURL*) soundURL
   startTimePosition: (double) segmentStartTime
            duration: (double) segmentDuration;

/*!
  @method soundFileExtensions
  @result Returns an array of file extensions available for reading and writing.
  @discussion Returns an array of file extensions indicating the file format (and file extension)
  that audio files may be read from or written to. Includes all of Snd's formats and "mp3".
 */
+ (NSArray *) soundFileExtensions;

/*!
  @method playInFuture:beginSample:sampleCount:
  @abstract Begin playback at some time in the future, over a region of the sound.
  @param inSeconds The number of seconds beyond the current time point to begin playback.
  @param begin The sample number to begin playing from. Use 0 to play from the start of the sound.
  @param count The number of samples to play. Use sampleCount to play the entire sound.
  @result Returns the performance that represents the sound playing.
 */
- (SndPerformance *) playInFuture: (double) inSeconds
		      beginSample: (unsigned long) begin
		      sampleCount: (unsigned long) count;

- (void *) fragmentOfFrame: (int) frame 
	   indexInFragment: (int *) currentFrame 
       lastFrameInFragment: (int *) lastFrameInBlock
		dataFormat: (SndSampleFormat *) dataFormat;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
