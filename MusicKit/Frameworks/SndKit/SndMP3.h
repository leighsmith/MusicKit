////////////////////////////////////////////////////////////////////////////////
//
//  SndMP3.h
//  SndKit
//
//  Created by SKoT McDonald on Tue Apr 16 2002.
//  Copyright (c) 2002 SndKit. All rights reserved.
//
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import <SndKit/SndKit.h>

////////////////////////////////////////////////////////////////////////////////

@interface SndMP3 : Snd {
  NSData        *mp3Data;
  NSMutableData *pcmData;

  long          *frameLocations;
  long           frameLocationsCount;
  double         duration;
  long           sampleCount;
  long           decodedSampledCount;
  BOOL           bDecoding;

  NSLock        *pcmDataLock;
}

- (void) dealloc;
- (double) duration;
- (int) sampleCount;
- (int) channelCount;
- (double) samplingRate;
- (int) readSoundfile: (NSString*) filename;
- (void) fillAudioBuffer: (SndAudioBuffer*) anAudioBuffer withSamplesInRange: (NSRange) playRegion;

/*!
  @method soundFileExtensions
  @result Returns an array of file extensions available for reading and writing.
  @discussion Returns an array of file extensions indicating the file format (and file extension)
  that audio files may be read from or written to. Includes all of Snd's formats and "mp3".
 */
+ (NSArray *) soundFileExtensions;

@end

////////////////////////////////////////////////////////////////////////////////