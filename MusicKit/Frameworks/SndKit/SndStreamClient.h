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

@class SndAudioBuffer;
@class SndStreamManager;

@interface SndStreamClient : NSObject
{
    SndAudioBuffer     *outputBuffer;
    SndAudioBuffer     *synthBuffer;
    SndAudioBuffer     *inputBuffer;
    NSLock             *outputBufferLock;
    NSConditionLock    *synthThreadLock;
    BOOL                active;
    BOOL                needsInput;
    BOOL                generatesOutput;

    SndStreamManager   *manager;
    
    void              (*processFinishedCallback)(void);
}

/*!
    @method streamClient
    @abstract Factory method
    @discussion Creates and initializes an SndStreamObject
    @result An autoreleased SndStreamClient object
*/
+ streamClient;

/*!
    @method dealloc 
    @abstract Destructor
    @discussion Releases SndAudioBuffers, NSLocks, and SndStreamManager
*/
- (void) dealloc;

/*!
    @method description
    @abstract Describes SndStreamClient
    @discussion Describes SndStreamClient 
    @result Returns an NSString describing the SndStreamClient.
*/
- (NSString*) description;

/*!
    @method setProcessFinishedCallBack: (void*) fn
    @abstract 
    @discussion 
    @result self
*/
- setProcessFinishedCallBack: (void*) fn;

/*!
    @method welcomeClientWithBuffer: (SndAudioBuffer*) buff manager:
    @param
    @abstract
    @discussion 
    @result self
*/
- welcomeClientWithBuffer: (SndAudioBuffer*) buff manager: (SndStreamManager*) m;

/*!
    @method startProcessingNextBufferWithInput: (SndAudioBuffer*) nowTime: (double) t
    @param
    @abstract Client welcomed with buffer showing manager format.
    @discussion Ignore input buffer if you don't want it.
    @result self
*/
- startProcessingNextBufferWithInput: (SndAudioBuffer*) inB nowTime: (double) t;

/*!
    @method processingThread
    @param
    @abstract
    @discussion 
*/
- (void) processingThread;

/*!
    @method outputBuffer
    @abstract Accessor for the currently exposed output buffer
    @discussion Don't store the object returned, as the output buffer swaps to the synthesis buffer each processing cycle.
    @result Returns the outputBuffer member
*/
- (SndAudioBuffer*) outputBuffer;

/*!
    @method synthBuffer
    @abstract Accessor for the current synthesis buffer
    @discussion 
    @result Returns the synthBuffer member
*/
- (SndAudioBuffer*) synthBuffer;

/*!
    @method inputBuffer
    @abstract Accessor for the current input buffer
    @discussion 
    @result Returns the inputBuffer member
*/
- (SndAudioBuffer*) inputBuffer;

/*!
    @method managerIsShuttingDown
    @abstract 
    @discussion Message sent by the manager to tell any clients still connected to it that it is about to disappear
    @result Returns self
*/
- managerIsShuttingDown;

/*!
    @method processBuffers
    @abstract
    @discussion 
*/
- (void) processBuffers; 

/*!
    @method nowTime
    @abstract Return the client's current time.
    @discussion The clients sense of time is just the manager's sense of time, defining a common clock among clients.
    @result Returns the time in seconds.
*/
- (double) nowTime;

/*!
    @method isActive
    @abstract Returns whether the client is active.
    @discussion Err... that's it, really! 
    @result Returns a boolean indicating whether the client is active.
*/
- (BOOL) isActive;

/*!
    @method setDetectPeaks: (BOOL) detectPeaks
    @abstract
    @discussion Not implemented yet.
    @result self.
*/
- setDetectPeaks: (BOOL) detectPeaks;

/*!
    @method getPeakLeft: (float *) leftPeak right: (float *) rightPeak
    @param
    @abstract
    @discussion Not implemented
    @result self.
*/
- getPeakLeft: (float *) leftPeak right: (float *) rightPeak;

/*!
    @method generatesOutput
    @param
    @abstract
    @discussion 
    @result Boolean indicating whether the client generates output
*/
- (BOOL) generatesOutput;

/*!
    @method needsInput
    @abstract
    @discussion 
    @result Boolean indicating whether the client requires an input stream.
*/
- (BOOL) needsInput;

/*!
    @method setGeneratesOutput:
    @param (BOOL) b   
    @abstract
    @discussion 
    @result self.
*/
- setGeneratesOutput: (BOOL) b;

/*!
    @method setNeedsInput:
    @param (BOOL) b
    @abstract
    @discussion 
    @result self.
*/
- setNeedsInput: (BOOL) b;

/*!
    @method setManager:
    @param (SndStreamManager*) m
    @abstract Sets the SndStreamManager for this client.
    @discussion Should never be called explicitly, it is invoked as part of the process of a manager welcoming a client into the fray.
    @result self.
*/
- setManager: (SndStreamManager*) m;

/*!
    @method lockOutputBuffer
    @param
    @abstract Blocks calling thread until outputBuffer is available for locking.  
    @discussion Lock the output buffer before doing anything with it, otherwise the synthesis thread may swap the buffers on you!
    @result self.
*/
- lockOutputBuffer;

/*!
    @method unlockOutputBuffer
    @abstract Releases lock on the outputBuffer.
    @discussion 
    @result self.
*/
- unlockOutputBuffer;

/*!
    @method prepareToStreamWithBuffer: 
    @param (SndAudioBuffer*) buff
    @abstract Prepare-to-stream-with-buffers-that-look-like-this message.
    @discussion Called before streaming commences to allow client an opportunity to setup internal generation buffers.
    @result self.
*/
- prepareToStreamWithBuffer: (SndAudioBuffer*) buff;

/*!
    @method didFinishStreaming
    @abstract streaming thread is shutting down message.
    @discussion Called just before the streaming thread shuts down, giving client a chance to clean up after itself.
    @result self.
*/
- didFinishStreaming;


@end

#endif
