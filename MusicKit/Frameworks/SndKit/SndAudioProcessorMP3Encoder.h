////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorMP3Encoder.h
//  SndKit
//
//  Created by SKoT McDonald <skot@tomandandy.com> on Mon Oct 01 2001.
//  Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and 
//  non-commercial purposes so long as the author attribution and copyright 
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDKIT_SNDAUDIOPROCESSORMP3ENCODER_H__
#define __SNDKIT_SNDAUDIOPROCESSORMP3ENCODER_H__

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"
#import "SndAudioBuffer.h"

#import <lame/lame.h>
// Note:
// "lame" can be obtained via http://www.mp3dev.org and must be installed before
// the SndKit will compile. LAME encoder is LGPL
// License statement: http://www.sulaco.org/mp3/license.txt

#import <shout/shout.h>
// Note:
// The <shout/shout.h> header is NOT part of the shoutcast server, but part of
// the icecast project. Download and install the "libshout" package
// from http://www.icecast.org before compiling the SndKit. If you also want to
// run the icecast server from the same machine, also download the "icecast"
// package from the same location, and install.
// The "libshout" package provides the <shout/shout.h> header, and is the part of
// the mechanism for sending data to the icecast server itself.
//
// The icecast libshout library is under the Lesser GPL license, so before 
// using the SndKit with this facility enabled, please ensure that you 
// understand the implications of this. The license statement can be found
// in the README file in the libshout source directory.

/*!
 @enum     SndMP3EncoderParam
 @constant mp3enc_kServerAddress
 @constant mp3enc_kServerPort
 @constant mp3enc_kServerPassword
 @constant mp3enc_kNumParams
 */

enum {
  mp3enc_kServerAddress  = 0,
  mp3enc_kServerPort     = 1,
  mp3enc_kServerPassword = 2,
  mp3enc_kNumParams      = 3
};

////////////////////////////////////////////////////////////////////////////////

/*!
@class      SndAudioProcessorMP3Encoder
@abstract   An MP3 encoding/streaming processor
@discussion To come.
*/
@interface SndAudioProcessorMP3Encoder : SndAudioProcessor {
/*! @var buffer_l Left audio channel data (pre-encoding)                      */
  float             *buffer_l;
/*! @var buffer_r Right audio channel data (pre-encoding)                     */
  float             *buffer_r;
/*! @var bufferSizeInSamples Size of the audio buffers, in bytes.             */
  long               bufferSizeInSamples; 
/*! @var mp3buff MP3 bitstream buffer (post-encoding)                         */
  unsigned char     *mp3buff;
/*! @var mp3BufferSizeInBytes Size of the MP3 bitstream buffer, in bytes      */
  long               mp3BufferSizeInBytes;
/*! @var bShoutcastActive Flag determining whether streaming to an icecast 
                          server is active or not                             */
  BOOL               bShoutcastActive;
/*! @var encodeNShoutcastLock Lock controlling access to icecasting code      */
  NSLock            *encodeNShoutcastLock;
/*! @var lameGlobalFlags Data structure required for LAME encoding            */
  lame_global_flags *lameGlobalFlags;
/*! @var conn icecast 'shout-cast' server connection data structure           */
  shout_conn_t       conn;
}
/*! 
  @method     defaultSourcePort
  @abstract   Returns icecast's default source/encoder connection port id.
  @result     An int which is the default mp3 source/encoder port id on the server.
*/
+ (int) defaultSourcePort;
/*! 
  @method     defaultSourcePassword
  @abstract   Returns the default password used to connect to the icecast server
  @result     An NSString with the default password for the icecast server.
*/
+ (NSString*) defaultSourcePassword;
/*! 
  @method     defaultServerAddress
  @abstract   Returns the default IP/URL address of the icecast server.
  @result     NSString with the default IP/URL address for the icecast server.
*/
+ (NSString*) defaultServerAddress;
/*! 
  @method     serverAddress
  @abstract   Returns the current IP/URL of the icecast server
  @result     NSString with the current IP/URL address of the icecast server.
  @discussion
*/
- (NSString*) serverAddress;
/*! 
  @method     serverPassword
  @abstract   Returns the current password being used to connect to the icecast
              server's MP3 source port.
  @result     NSString with the current MP3 source port password.
*/
- (NSString*) serverPassword;
/*! 
  @method     serverPort
  @abstract   Returns the current MP3 source port being used to connect to the 
              icecast server
  @result     The current MP3 source port number.
*/
- (int) serverPort;
/*! 
  @method     init
  @abstract   Initializer
  @result     self
  @discussion Sets up the LAME and icecast data structures.
*/
- init;
/*! 
  @method     setShoutcastServerAddress:port:password:
  @abstract   Sets the icecast server connection parameters.
  @param      address IP/URL address of icecast server.
  @param      port MP3 stream source connection port on the icecast server   
  @param      password Password controlling access to MP3-source port on server
  @result     self
*/
- setShoutcastServerAddress: (NSString*) address
                       port: (int) port
                   password: (NSString*) password;
/*! 
  @method     connectToShoutcastServer
  @abstract   Attempts to connect to the MP3 source port of an icecast server.
  @result     TRUE if a connection was established.
*/
- (BOOL) connectToShoutcastServer;
/*! 
  @method     disconnectFromShoutcastServer
  @abstract   Disconnects from the icecast server's MP3 source port.
*/
- disconnectFromShoutcastServer;
/*! 
  @method     dealloc
  @abstract   Destructor
*/
- (void) dealloc;
/*! 
  @method     processReplacingInputBuffer:outputBuffer:
  @abstract
  @param      inB
  @param      outB
  @result     FALSE, since no output is produced. inB is unchanged. See discussion
              for this method in SndStreamClient.
  @discussion Packs audio data witin inB into the float* buffers, calls LAME to
              encode them into an MP3 bitstream. MP3 data is then broadcast to 
              the icecast server.
*/
- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB 
                        outputBuffer: (SndAudioBuffer*) outB;
/*!
 @method     paramName:
 @abstract
 @discussion
 @result
*/
- (NSString*) paramName: (const int) i;
/*!
 @method     paramObjectForIndex:
 @abstract
 @discussion
 @result
*/
- (id) paramObjectForIndex: (const int) i;
                 
@end

////////////////////////////////////////////////////////////////////////////////

#endif