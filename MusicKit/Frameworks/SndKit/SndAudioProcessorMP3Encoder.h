////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
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

#ifndef __SNDKIT_SNDAUDIOPROCESSORMP3ENCODER_H__
#define __SNDKIT_SNDAUDIOPROCESSORMP3ENCODER_H__

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"

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
 @brief SndMP3EncoderParam Parameter keys
 @constant mp3enc_kServerAddress  Server address (as ip or url)
 @constant mp3enc_kServerPort  Server port
 @constant mp3enc_kServerPassword  Server password
 @constant mp3enc_kNumParams  Number of parameters 
 */
enum {
  mp3enc_kServerAddress  = 0,
  mp3enc_kServerPort     = 1,
  mp3enc_kServerPassword = 2,
  mp3enc_kNumParams      = 3
};

////////////////////////////////////////////////////////////////////////////////

/*!
@class SndAudioProcessorMP3Encoder
@brief An MP3 encoding/streaming processor

  To come.
*/
@interface SndAudioProcessorMP3Encoder : SndAudioProcessor 
{
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
  /*! @var encodeNShoutcastLock Lock controlling access to icecasting code      */
  NSLock            *encodeNShoutcastLock;
  /*! @var lameGlobalFlags Data structure required for LAME encoding            */
  lame_global_flags *lameGlobalFlags;
  /*! @var conn icecast 'shout-cast' server connection data structure           */
  shout_t           *conn;
}
/*!
 @brief  Returns the default IP/URL address of the icecast server.
 @return  NSString with the default IP/URL address for the icecast server.
 */
+ (NSString*) defaultServerAddress;
/*!
 @brief  Returns icecast's default source/encoder connection port id.
 @return  An int which is the default mp3 source/encoder port id on the server.
 */
+ (int) defaultSourcePort;
/*!
 @brief  Returns the default password used to connect to the icecast server
 @return  An NSString with the default password for the icecast server.
 */
+ (NSString*) defaultSourcePassword;
/*!
 @brief  Returns the current IP/URL of the icecast server
 @return  NSString with the current IP/URL address of the icecast server.
 
  
 */
- (NSString*) serverAddress;
/*!
 @brief  Returns the current password being used to connect to the icecast
 server's MP3 source port.
 @return  NSString with the current MP3 source port password.
 */
- (NSString*) serverPassword;
/*!
 @brief  Returns the current MP3 source port being used to connect to the
 icecast server
 @return  The current MP3 source port number.
 */
- (int) serverPort;
/*!
 @brief  Sets the icecast server connection parameters.
 @param  address IP/URL address of icecast server.
 @param  port MP3 stream source connection port on the icecast server
 @param  password Password controlling access to MP3-source port on server
 @return  self
 */
- setShoutcastServerAddress: (NSString*) address
                       port: (int) port
                   password: (NSString*) password;
/*!
 @brief  Attempts to connect to the MP3 source port of an icecast server.
 @return  TRUE if a connection was established.
 */
- (BOOL) connectToShoutcastServer;
/*!
 @brief  Disconnects from the icecast server's MP3 source port.
 */
- disconnectFromShoutcastServer;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
