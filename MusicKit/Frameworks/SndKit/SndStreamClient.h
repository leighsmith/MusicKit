/*
  $Id$

  Description:

  Original Author: SKoT McDonald, <skot@tomandandy.com>, tomandandy music inc.

  Sat 10-Feb-2001, Copyright (c) 2001 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/

#ifndef __SNDSTREAMCLIENT__
#define __SNDSTREAMCLIENT__

#import <Foundation/Foundation.h>
//#import <SndKit/SndKit.h>

@class SndStreamManager;
@class SndAudioBuffer;
@class SndStreamManager;

@interface SndStreamClient : NSObject
{
    NSLock             *outputBufferLock;
    SndAudioBuffer     *outputBuffer;
    SndAudioBuffer     *synthBuffer;
    SndAudioBuffer     *inputBuffer;
    NSConditionLock    *synthThreadLock;
    BOOL                active;
    BOOL                needsInput;
    BOOL                generatesOutput;

    SndStreamManager *manager;
    
    void             (*processFinishedCallback)(void);
}

+ streamClient;
- (void) dealloc;
- (NSString*) description;

- setProcessFinishedCallBack: (void*)fn;

- welcomeClientWithBuffer: (SndAudioBuffer*) buff manager: (SndStreamManager*) m;

/*!
    @method startProcessingNextBufferWithInput:nowTime:
    @abstract client welcomed with buffer showing manager format.
    @discussion ignore input buffer if you don't want it.
*/
- startProcessingNextBufferWithInput: (SndAudioBuffer*) inB nowTime: (double) t;
- (void) processingThread;
- (SndAudioBuffer*) outputBuffer;
- (SndAudioBuffer*) synthBuffer;
- (SndAudioBuffer*) inputBuffer;
- managerIsShuttingDown;

- (void) processBuffers; // The big one for the sub classes - override!.

/*!
    @method nowTime
    @abstract Return the client's current time.
    @discussion The clients sense of time is just the manager's sense of time, defining a common clock among clients.
    @result Returns the time in seconds.
*/
- (double) nowTime;
- (BOOL) isActive;
// Peak detection
- setDetectPeaks: (BOOL) detectPeaks;
- getPeakLeft: (float *) leftPeak right: (float *) rightPeak;

- (BOOL) generatesOutput;
- (BOOL) needsInput;
- setGeneratesOutput: (BOOL) b;
- setNeedsInput: (BOOL) b;

- lockOutputBuffer;
- unlockOutputBuffer;

@end

#endif
