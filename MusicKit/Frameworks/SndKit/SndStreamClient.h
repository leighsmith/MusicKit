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

@class SndStreamManager;
@class SndAudioBuffer;
@class SndStreamManager;

@interface SndStreamClient : NSObject
{
    NSLock          *outputBufferLock;
    SndAudioBuffer     *outputBuffer;
    SndAudioBuffer     *synthBuffer;
    SndAudioBuffer     *inputBuffer;
    NSConditionLock *synthThreadLock;
    BOOL             active;
    BOOL             needsInput;
    double           nowTime;

    SndStreamManager *manager;
    
    void             (*processFinishedCallback)(void);
}

+ streamClient;
- (void) dealloc;
- (NSString*) description;

- setProcessFinishedCallBack: (void*)fn;

- welcomeClientWithBuffer: (SndAudioBuffer*) buff manager: (SndStreamManager*) m;
    // client welcomed with buffer showing manager format.
- startProcessingNextBufferWithInput: (SndAudioBuffer*) inB nowTime: (double) t;
                               // ignore input buffer if you don't want it.
- (void) processingThread;
- (SndAudioBuffer*) outputBuffer;
- (SndAudioBuffer*) synthBuffer;
- setNeedsInput: (BOOL) b;
- managerIsShuttingDown;

- (void) processBuffers; // The big one for the sub classes - override!.
- (double) nowTime;
- (SndStreamManager*) manager;
- (BOOL) active;
// Peak detection
- setDetectPeaks: (BOOL) detectPeaks;
- getPeakLeft: (float *) leftPeak right: (float *) rightPeak;

@end
