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
}

- (void) dealloc;
- (double) duration;
- (int) sampleCount;
- (int) channelCount;
- (double) samplingRate;
- (int) readSoundfile: (NSString*) filename;
- (void) fillAudioBuffer: (SndAudioBuffer*) anAudioBuffer withSamplesInRange: (NSRange) playRegion;

@end

////////////////////////////////////////////////////////////////////////////////