//
//  SndAudioProcessorMP3Encoder.h
//  SndKit
//
//  Created by skot on Mon Oct 01 2001.
//  Copyright (c) 2001 __CompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"
#import "SndAudioBuffer.h"
#import <lame/lame.h>
#import <shout/shout.h>

@interface SndAudioProcessorMP3Encoder : SndAudioProcessor {
  float             *buffer_l;
  float             *buffer_r;
  long               bufferSizeInSamples; 
  unsigned char     *mp3buff;
  long               mp3BufferSizeInBytes;
  BOOL               bShoutcastActive;
  NSLock            *encodeNShoutcastLock;
  lame_global_flags *lameGlobalFlags;
  shout_conn_t       conn;
}

- init;

- setShoutcastServerAddress: (NSString*) address
                       port: (int) port
                   password: (NSString*) password;

- (BOOL) connectToShoutcastServer;
- disconnectFromShoutcastServer;

- (void) dealloc;

- processReplacingInputBuffer: (SndAudioBuffer*) inB 
                 outputBuffer: (SndAudioBuffer*) outB;
                 
@end
