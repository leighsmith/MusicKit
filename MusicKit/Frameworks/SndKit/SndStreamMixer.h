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

#import <Foundation/Foundation.h>

#import "SndAudioBuffer.h"
#import "SndStreamClient.h"
#import "SndAudioProcessorChain.h"

@interface SndStreamMixer : NSObject {
    NSMutableArray         *streamClients;
    NSLock                 *streamClientsLock;
    SndAudioProcessorChain *processorChain;
}

+ sndStreamMixer;
- init;
- (void) dealloc;
- processInBuffer: (SndAudioBuffer*) inB 
        outBuffer: (SndAudioBuffer*) outB 
          nowTime: (double) t;

- (BOOL) removeClient: (SndStreamClient*) client;
- (int) addClient: (SndStreamClient*) client;
- managerIsShuttingDown;
- (int) clientCount;

@end
