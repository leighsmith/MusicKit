//
//  SndAudioProcessorMP3Encoder.h
//  SndKit
//
//  Created by SKoT McDonald <skot@tomandandy.com> on Mon Oct 01 2001.
//

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"
#import "SndAudioBuffer.h"

#import <lame/lame.h>
// "lame" can be obtained via http://www.mp3dev.org and must be installed before
// the SndKit will compile. LAME encoder is LGPL
// License statement: http://www.sulaco.org/mp3/license.txt

#import <shout/shout.h>
// The <shout/shout.h> header is NOT part of the shoutcast server, but part of
// the icecast project. Download and install the "libshout" package
// from http://www.icecast.org before compiling the SndKit. If you also want to
// run the icecast server from the same machine, also download the "icecast"
// package from the same location, and install.
// The "libshout" package provides the <shout/shout.h> header, and is the part of
// the mechanism for sending data to the icecast server itself.

// The icecast libshout library is under the Lesser GPL license, so before 
// using the SndKit with this facility enabled, please ensure that you 
// understand the implications of this. The license statement can be found
// in the README file in the libshout source directory.


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

+ (int) defaultSourcePort;
+ (NSString*) defaultSourcePassword;
+ (NSString*) defaultServerAddress;

- (NSString*) serverAddress;
- (NSString*) serverPassword;
- (int) serverPort;

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
