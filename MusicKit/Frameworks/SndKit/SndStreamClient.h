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

/*!
    @class      SndStreamClient
    @baseclass  NSObject
    @abstract   Audio streaming / signal processing / synthesis module 
    @discussion Provides basic streaming services such as double buffering, thread handling,
                automatic start up and and shut down of lower-level streaming services. 
    @var        outputBuffer
    @var        synthBuffer
    @var        inputBuffer
    @var        outputBufferLock
    @var        synthThreadLock
    @var        active
    @var        needsInput
    @var        generatesOutput
    @var        manager
    @var        processFinishedCallback C callback function - should be replaced with a delegate system
    @var        delegate;
*/
@interface SndStreamClient : NSObject
{
    SndAudioBuffer     *outputBuffer;
    SndAudioBuffer     *synthBuffer;
    SndAudioBuffer     *inputBuffer;
    NSLock             *outputBufferLock;
    NSLock             *inputBufferLock;
    NSConditionLock    *synthThreadLock;
    BOOL                active;
    BOOL                needsInput;
    BOOL                generatesOutput;

    SndStreamManager   *manager;
    
    void              (*processFinishedCallback)(void);
    
    id                  delegate;
    
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
    @method     setProcessFinishedCallBack: 
    @abstract 
    @discussion 
    @param      fn C callback function
    @result     self
*/
- setProcessFinishedCallBack: (void*) fn;

/*!
    @method     welcomeClientWithBuffer:manager:
    @abstract
    @discussion 
    @param      buff
    @param      m
    @result     self
*/
- welcomeClientWithBuffer: (SndAudioBuffer*) buff manager: (SndStreamManager*) m;

/*!
    @method     startProcessingNextBufferWithInput:nowTime:
    @abstract   Client welcomed with buffer showing manager format.
    @discussion Ignore input buffer if you don't want it.
    @param      inB
    @param      t
    @result     self
*/
- startProcessingNextBufferWithInput: (SndAudioBuffer*) inB nowTime: (double) t;

/*!
    @method     processingThread
    @abstract
    @discussion 
*/
- (void) processingThread;

/*!
    @method     outputBuffer
    @abstract   Accessor for the currently exposed output buffer
    @discussion Don't store the object returned, as the output buffer swaps to the synthesis buffer each processing cycle.
    @result     Returns the outputBuffer member
*/
- (SndAudioBuffer*) outputBuffer;

/*!
    @method     synthBuffer
    @abstract   Accessor for the current synthesis buffer
    @discussion 
    @result     Returns the synthBuffer member
*/
- (SndAudioBuffer*) synthBuffer;

/*!
    @method     inputBuffer
    @abstract   Accessor for the current input buffer
    @discussion 
    @result     Returns the inputBuffer member
*/
- (SndAudioBuffer*) inputBuffer;

/*!
    @method     managerIsShuttingDown
    @abstract 
    @discussion Message sent by the manager to tell any clients still connected to it that it is about to disappear
    @result     Returns self
*/
- managerIsShuttingDown;

/*!
    @method     processBuffers
    @abstract
    @discussion 
*/
- (void) processBuffers; 

/*!
    @method     nowTime
    @abstract   Return the client's current time.
    @discussion The clients sense of time is just the manager's sense of time, defining a common clock among clients.
    @result     Returns the time in seconds.
*/
- (double) nowTime;

/*!
    @method     isActive
    @abstract   Returns whether the client is active.
    @result     Returns a boolean indicating whether the client is active.
*/
- (BOOL) isActive;

/*!
    @method     setDetectPeaks: (BOOL) detectPeaks
    @abstract   enables / disables peak detection
    @discussion Not implemented yet - not convinced this should be here - maybe inside an SndAudioProcessor?
    @result     self.
*/
- setDetectPeaks: (BOOL) detectPeaks;

/*!
    @method     getPeakLeft:right:
    @abstract   Get the most recent peak values for the stereo stream
    @discussion Not implemented yet - not convinced this should be here - maybe inside an SndAudioProcessor?
    @param      leftPeak Left peak value
    @param      rightPeak Righ peak value
    @result     self.
*/
- getPeakLeft: (float *) leftPeak right: (float *) rightPeak;

/*!
    @method     generatesOutput
    @abstract   Returns whether the client is an audio-producer (synthesizer, FX)
    @result     Boolean indicating whether the client generates output
*/
- (BOOL) generatesOutput;

/*!
    @method     needsInput
    @abstract   Returns whether the client is an audio-consumer (recorder, FX, signal analyzer)
    @result     Boolean indicating whether the client requires an input stream.
*/
- (BOOL) needsInput;

/*!
    @method     setGeneratesOutput:
    @abstract   Determines whether the client's output buffer will be considered for 
                mixing downstream.
    @discussion Normally you should only need to call this when initializing a derived stream client
    @param      b Boolean switch 
    @result     self.
*/
- setGeneratesOutput: (BOOL) b;

/*!
    @method     setNeedsInput:
    @abstract   Sets whether the client requires an input uadio stream or not.
    @discussion Normally you should only need to call this when initializing a derived stream client.
                If true, the stream manager will copy the most recent input buffer
                into the client's input buffer each processing cycle provided the
                client hasn't choked the CPU. If the client is running in less than
                real time, the input buffer is not updated, since the manager must
                assume that the client's copy of the previous input buffer may still
                be in use.
    @param      b Boolean switch
    @result     self.
*/
- setNeedsInput: (BOOL) b;

/*!
    @method     setManager:
    @abstract   Sets the SndStreamManager for this client.
    @discussion Should never be called explicitly, it is invoked as part of the 
                process of a manager welcoming a client into the fray.
    @param      m
    @result     self.
*/
- setManager: (SndStreamManager*) m;

/*!
    @method     lockOutputBuffer
    @abstract   Blocks calling thread until outputBuffer is available for locking.  
    @discussion Lock the output buffer before doing anything with it, otherwise 
                the synthesis thread may swap the buffers on you!
    @result     self.
*/
- lockOutputBuffer;

/*!
    @method     unlockOutputBuffer
    @abstract   Releases lock on the outputBuffer.
    @result     self.
*/
- unlockOutputBuffer;

/*!
    @method     lockInputBuffer
    @abstract   Blocks calling thread until inputBuffer is available for locking.  
    @discussion Lock the input buffer before doing anything with it, otherwise 
                the synthesis thread may swap the buffers on you!
    @result     self.
*/
- lockInputBuffer;

/*!
    @method     unlockInputBuffer
    @abstract   Releases lock on the outputBuffer.
    @result     self.
*/
- unlockInputBuffer;


/*!
    @method     prepareToStreamWithBuffer: 
    @abstract   Prepare-to-stream-with-buffers-that-look-like-this message.
    @discussion Called before streaming commences to allow client an opportunity 
                to setup internal generation buffers.
    @param      buff
    @result     self.
*/
- prepareToStreamWithBuffer: (SndAudioBuffer*) buff;

/*!
    @method     didFinishStreaming
    @abstract   streaming thread is shutting down message.
    @discussion Called just before the streaming thread shuts down, giving a 
                derived client a chance to clean up after itself.
    @result     self.
*/
- didFinishStreaming;

/*!
    @method     setDelegate:
    @abstract
    @param      d
    @result     self
*/
- setDelegate: (id) d;

/*!
    @method     delegate
    @abstract   Accessor method to the delegate member.
    @result     The stream client's delegate object
*/
- (id) delegate;

@end

@interface SndStreamClientDelegate : NSObject

/*!
    @method     inputBufferSkipped
    @abstract 
    @result     
*/
- inputBufferSkipped:  sender;

/*!
    @method     outputBufferSkipped
    @abstract 
    @result     
*/
- outputBufferSkipped: sender;
@end

#endif
