////////////////////////////////////////////////////////////////////////////////
//
//  SndMP3.h
//  SndKit
//
//  Created by SKoT McDonald on Tue Apr 16 2002.
//  Copyright (c) 2002 SndKit. All rights reserved.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SND_MP3_H__
#define __SND_MP3_H__

#import <Foundation/Foundation.h>
#import "Snd.h"

////////////////////////////////////////////////////////////////////////////////

#define SND_MPEGV1_SAMPLES_PER_FRAME 1152
#define SND_MPEGV2_SAMPLES_PER_FRAME 576

@interface SndMP3 : Snd {
    /*! @var mp3Data The MP3 bitstream data. */
    NSData *mp3Data;
    /*! @var encodedFrameLocations An array of longs which give the locations in the MP3 bitstream data of the start of each MP3 frame. */
    long *encodedFrameLocations;
    /*! @var encodedFrameLocationsCount The number of frame locations in encodedFrameLocations. */
    long encodedFrameLocationsCount;
    /*! @var currentMP3FrameID The most recently decoded bitstream frame index into encodedFrameLocations. */
    int currentMP3FrameID;
    /*! @var decodedLeftPCM The left channel of the most recently decoded bitstream data as 16 bit PCM data. */
    short decodedLeftPCM[SND_MPEGV1_SAMPLES_PER_FRAME]; // Largest number of samples per MPEG frame, regardless of version.
    /*! @var decodedRightPCM The right channel of the most recently decoded bitstream data as 16 bit PCM data. */
    short decodedRightPCM[SND_MPEGV1_SAMPLES_PER_FRAME];  // Largest number of samples per MPEG frame, regardless of version.

    double         duration;
    long           lengthInSampleFrames;

    // Variables used in separate threaded predecoding.
    NSMutableData *pcmData;
    long           decodedSampledCount;
    BOOL           bDecoding;    
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

/*!
  @method convertToNativeFormat
  @discussion Actually all this does is check the MP3 is the same as the native format, if not it flags an error.
 */
- (int) convertToNativeFormat;

/*!
  @method insertIntoAudioBuffer:intoFrameRange:samplesInRange:
  @abstract Copies samples from self into a sub region of the provided SndAudioBuffer.
  @discussion If the buffer and the Snd instance have different formats, a format
              conversion will be performed to the buffers format, including resampling
              if necessary. The Snd audio data will be read enough to fill the range of samples
              specified according to the sample rate of the buffer compared to the sample rate
              of the Snd instance. In the case where there are less than the needed number of
              samples left in the sndFrameRange to completely insert into the specified buffer region, the
              number of samples inserted will be returned less than bufferRange.length.
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

@end

////////////////////////////////////////////////////////////////////////////////

#endif
