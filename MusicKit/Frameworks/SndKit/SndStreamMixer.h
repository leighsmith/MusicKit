////////////////////////////////////////////////////////////////////////////////
//
//  SndStreamMixer.h
//  SndKit
//
//  Created by skot on Tues Mar 27 2001. <skot@tomandandy.com>
//  Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and non-commercial
//  purposes so long as the author attribution and copyright messages remain intact and
//  accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SND_STREAM_MIXER_H__
#define __SND_STREAM_MIXER_H__

#import <Foundation/Foundation.h>

#import "SndAudioBuffer.h"
#import "SndStreamClient.h"
#import "SndAudioProcessorChain.h"

@interface SndStreamMixer : NSObject {
    NSMutableArray         *streamClients;
    NSLock                 *streamClientsLock;
    SndAudioProcessorChain *processorChain;
}

/*!
    @method sndStreamMixer
    @abstract Factory method
    @discussion
    @result A freshly initialized and autoreleased SndStreamMixer object
*/
+ sndStreamMixer;

/*!
    @method init
    @abstract Initializor
    @discussion
    @result self.
*/
- init;

/*!
    @method dealloc
    @abstract Destructor
    @discussion
*/
- (void) dealloc;

/*!
    @method processInBuffer:outBuffer:nowTime:
    @abstract
    @discussion
    @param (SndAudioBuffer*) inB
    @param (SndAudioBuffer*) outB
    @param (double) t
    @result self.
*/
- processInBuffer: (SndAudioBuffer*) inB 
        outBuffer: (SndAudioBuffer*) outB 
          nowTime: (double) t;

/*!
    @method removeClient:
    @abstract
    @discussion
    @param (SndStreamClient*) client
    @result Boolean indicating success
*/
- (BOOL) removeClient: (SndStreamClient*) client;

/*!
    @method addClient:
    @abstract
    @discussion
    @param (SndStreamClient*) client
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
    @result integer client count
*/
- (int) clientCount;

/*!
    @method audioProcessorChain
    @abstract Accessor
    @discussion
    @result Reference to the data member audioprocessorChain
*/
- (SndAudioProcessorChain*) audioProcessorChain;

@end

#endif
