//
//  SndAudioProcessorMP3Encoder.h
//  SndKit
//
//  Created by SKoT McDonald <skot@tomandandy.com> on Mon Oct 01 2001.
//

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"
#import "SndAudioBuffer.h"

// "lame" can be obtained via http://www.mp3dev.org and must be installed before
// the SndKit will compile.
//
// The <shout/shout.h> header is NOT part of the shoutcast server, but part of
// the icecast project. Download and install the "iceS" package
// from http://www.icecast.org before compiling the SndKit. If you also want to
// run the icecast server from the same machine, also download the "icecast"
// package from the same location, and install.
// The "iceS" package provides the <shout/shout.h> header, and is the part of
// the mechanism for sending data to the icecast server itself.

// the iceS library is under the GPL license, so before using the SndKit with
// this facility enabled, please ensure that you understand the implications
// of this.

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
