////////////////////////////////////////////////////////////////////////////////
//
//  SndStreamMixer.h
//  SndKit
//
//  Created by skot on Tues Mar 27 2001. <skot@tomandandy.com>
//  Copyright (c) 2001 tomandandy music inc.
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
    @discussion To come
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
    @method   sndStreamMixer
    @abstract   Factory method
    @discussion
    @result     A freshly initialized and autoreleased SndStreamMixer object
*/
+ sndStreamMixer;
/*!
    @method   init
    @abstract   Initializer method
    @discussion
    @result     self.
*/
- init;
/*!
    @method   dealloc
    @abstract   Destructor method
    @discussion
*/
- (void) dealloc;

- (NSString*) description;

/*!
    @method   processInBuffer:outBuffer:nowTime:
    @abstract
    @discussion
    @param      inB
    @param      outB
    @param      t
    @result     self.
*/
- processInBuffer: (SndAudioBuffer*) inB
        outBuffer: (SndAudioBuffer*) outB
          nowTime: (double) t;
/*!
    @method   removeClient:
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
    @method clientCount
    @abstract
    @discussion
    @result     Number of stream clients currently connected to the mixer
*/
- (int) clientCount;
/*!
    @method   audioProcessorChain
    @abstract   Accessor
    @discussion
    @result     Reference to the data member audioprocessorChain
*/
- (SndAudioProcessorChain*) audioProcessorChain;
/*!
    @method resetTime:
    @abstract Resets the mixer's sense of time, and pro
    @param originTimeInSeconds
*/
- (void) resetTime: (double) originTimeInSeconds;

- (SndStreamClient*) clientAtIndex: (int) ndx;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
