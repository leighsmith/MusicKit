/*
  $Id$

  Description:

  Original Author: SKoT McDonald, <skot@tomandandy.com>, tomandandy music inc.

  Sat 10-Feb-2001, Copyright (c) 2001 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/

#import <Foundation/Foundation.h>
#import <SndKit/SndKit.h>
#import "SndAudioBuffer.h"

@class SndStreamClient;

@interface SndStreamManager : NSObject
{
    NSMutableArray *streamClients;
    NSLock         *streamClientsLock;
    BOOL            active;
    SndSoundStruct  format; 
}

+ (void) initialize;
+ (SndStreamManager *) defaultStreamManager;

- (void) dealloc;
- (NSString*) description;

- (BOOL) startStreaming;
- (BOOL) stopStreaming;

- (BOOL) addClient: (SndStreamClient*) client;
- (BOOL) removeClient: (SndStreamClient*) client;
- (void) processStreamAtTime: (double) sampleCount
                       input: (SNDStreamBuffer*) inB
                      output: (SNDStreamBuffer*) outB;

- setFormat: (SndSoundStruct*) f;

@end
