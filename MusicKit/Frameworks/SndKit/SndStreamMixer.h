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
@interface SndStreamMixer : NSObject
{
    /*! @var streamClients A modifiable array of SndStreamClients currently being mixed. */
    NSMutableArray *streamClients;
    /*! @var streamClientsLock Controls access to the clients preventing their addition or removal while being mixed. */
    NSLock *streamClientsLock;
    /*! @var processorChain A chain of SndAudioProcessors that is applied after mixing all the stream clients together. */
    SndAudioProcessorChain *processorChain;
    /*! @var nowTime The current time (in seconds) to mix up to, as updated from the SndStreamManager, passed into processInBuffer:outBuffer:nowTime. */
    double nowTime;
    /*! @var lastNowTime The previous time of last update from SndStreamManager. */
    double lastNowTime;
}

/*!
  @method     mixer
  @abstract   Factory method returning an initialized and autoreleased SndStreamMixer instance.
  @result     Returns an initialized and autoreleased SndStreamMixer instance.
*/
+ mixer;

/*!
  @method     init
  @abstract   Initializer method.
  @result     Returns self.
*/
- init;

- (void) dealloc;

- (NSString *) description;

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
- processInBuffer: (SndAudioBuffer *) inB
        outBuffer: (SndAudioBuffer *) outB
          nowTime: (double) t;

/*!
  @method     removeClient:
  @abstract   Removes the given SndStreamClient from mixing.
  @param      client The SndStreamClient instance to remove.
  @result     Returns YES if client was successfully removed, NO if it was not being mixed.
*/
- (BOOL) removeClient: (SndStreamClient *) client;

/*!
  @method     addClient:
  @abstract   Add a SndStreamClient to the mix.
  @discussion If the client is already being mixed, it will not be added again.
  @param      client A SndStreamClient instance.
  @result     Returns the new number of clients.
*/
- (int) addClient: (SndStreamClient *) client;

/*!
  @method finishMixing
  @abstract Informs the receiver that all mixing is to be completed, that mixing clients and buffers are to be updated.
  @discussion This should be sent when the manager is shutting down.
*/
- (void) finishMixing;

/*!
  @method     clientCount
  @abstract   Returns the number of stream clients currently connected to the mixer.
  @result     Returns the number of stream clients currently connected to the mixer.
*/
- (int) clientCount;

/*!
  @method     audioProcessorChain
  @abstract   Returns the SndAudioProcessorChain applied after mixing SndStreamClients.
  @result     Returns a reference to the audio processor chain.
*/
- (SndAudioProcessorChain *) audioProcessorChain;

/*!
  @method     resetTime:
  @abstract   Resets the mixer's sense of time, and pro
  @param      originTimeInSeconds
*/
- (void) resetTime: (double) originTimeInSeconds;

/*!
  @method     clientAtIndex:
  @abstract   Returns a given SndStreamClient being mixed, indexed by a numeric identifier.
  @param      clientIndex
*/
- (SndStreamClient *) clientAtIndex: (int) clientIndex;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
