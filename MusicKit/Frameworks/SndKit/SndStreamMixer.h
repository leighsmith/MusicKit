////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Original Author: SKoT McDonald <skot@tomandandy.com>
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and 
//  non-commercial purposes so long as the author attribution and copyright 
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SND_STREAM_MIXER_H__
#define __SND_STREAM_MIXER_H__

#import <Foundation/Foundation.h>

#import "SndAudioBuffer.h"
#import "SndStreamClient.h"
#import "SndAudioProcessorChain.h"

/*!
@class SndStreamMixer
@abstract Stream mixer and effects processor
@discussion The SndStreamMixer class is responsible for managing the mixing of SndAudioBuffers from all
            current SndStreamClients. After mixing all buffers, it can apply any signal processing to the mixed
	    result by modifying it's SndAudioProcessorChain retrieved using audioProcessorChain.
*/
@interface SndStreamMixer : NSObject {
/*! @var streamClients */
    NSMutableArray         *streamClients;
/*! @var streamClientsLock */
    NSLock                 *streamClientsLock;
/*! @var processorChain */
    SndAudioProcessorChain *processorChain;
    double                 nowTime;
    double                 lastNowTime;
}
/*!
  @method     sndStreamMixer
  @abstract   Factory method
  @discussion
  @result     A freshly initialized and autoreleased SndStreamMixer object
*/
+ sndStreamMixer;
/*!
  @method     init
  @abstract   Initializer method
  @discussion
  @result     self.
*/
- init;
/*!
  @method     dealloc
  @abstract   Destructor method
  @discussion
*/
- (void) dealloc;

- (NSString*) description;

/*!
  @method     processInBuffer:outBuffer:nowTime:
  @abstract   Mixes together all clients currently exposed output buffers.
  @discussion After mixing all client exposed output buffers, processInBuffer:outBuffer:nowTime
              then applies any audio processing to the mix. Each client then receives the message
              startProcessingNextBufferWithInput:nowTime:, passing the input buffer, to generate
              the next buffer.
  @param      inB The input buffer filled with recorded audio.
  @param      outB The output buffer to fill for playback.
  @param      t The current now time.
  @result     Returns self.
*/
- processInBuffer: (SndAudioBuffer*) inB
        outBuffer: (SndAudioBuffer*) outB
          nowTime: (double) t;
/*!
  @method     removeClient:
  @abstract
  @discussion
  @param      client
  @result     TRUE if client was successfully removed
*/
- (BOOL) removeClient: (SndStreamClient*) client;
/*!
  @method   addClient:
  @abstract
  @discussion
  @param      client
  @result 
*/
- (int) addClient: (SndStreamClient*) client;
/*!
  @method managerIsShuttingDown
  @abstract
  @discussion
  @result self
*/
- managerIsShuttingDown;
/*!
  @method     clientCount
  @abstract
  @discussion
  @result     Number of stream clients currently connected to the mixer
*/
- (int) clientCount;
/*!
  @method     audioProcessorChain
  @abstract   Accessor
  @discussion
  @result     Reference to the data member audioprocessorChain
*/
- (SndAudioProcessorChain*) audioProcessorChain;
/*!
  @method     resetTime:
  @abstract   Resets the mixer's sense of time, and pro
  @param      originTimeInSeconds
*/
- (void) resetTime: (double) originTimeInSeconds;
/*!
  @method     resetTime:
  @abstract   Resets the mixer's sense of time, and pro
  @param      originTimeInSeconds
*/
- (SndStreamClient*) clientAtIndex: (int) ndx;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
