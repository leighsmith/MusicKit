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
@class SndAudioProcessorChain;

/*!
    @class      SndStreamClient
    @abstract   Audio streaming / signal processing / synthesis module 
    @discussion Provides basic streaming services such as double buffering, thread handling,
                automatic start up and and shut down of lower-level streaming services. 
*/
@interface SndStreamClient : NSObject
{
/*! @var       outputBuffer */
    SndAudioBuffer *outputBuffer;
/*! @var       synthBuffer */
    SndAudioBuffer *synthBuffer;
/*! @var       inputBuffer */
    SndAudioBuffer *inputBuffer;
/*! @var       outputBufferLock */
    NSLock    *outputBufferLock;
/*! @var       inputBufferLock */
    NSLock    *inputBufferLock;
/*! @var       synthThreadLock */
    NSConditionLock *synthThreadLock;
/*! @var       active */
    BOOL       active;
/*! @var       needsInput */
    BOOL       needsInput;
/*! @var       generatesOutput */
    BOOL       generatesOutput;
/*! @var       processorChain */
    SndAudioProcessorChain *processorChain;
/*! @var       manager */
    SndStreamManager *manager;
/*! @var       processFinishedCallback C callback function - should be replaced with a delegate system */
    void     (*processFinishedCallback)(void);
/*! @var       delegate; */
    id         delegate;    
/*! @var       nowTime */
    double     nowTime;
}

/*!
    @function   streamClient
    @abstract   Factory method
    @discussion Creates and initializes an SndStreamObject
    @result     An autoreleased SndStreamClient object
*/
+ streamClient;

/*!
    @function   dealloc 
    @abstract   Destructor
    @discussion Releases SndAudioBuffers, NSLocks, and SndStreamManager
*/
- (void) dealloc;

/*!
    @function   description
    @abstract   Describes SndStreamClient
    @discussion Describes SndStreamClient 
    @result     Returns an NSString describing the SndStreamClient.
*/
- (NSString*) description;

/*!
    @function   setProcessFinishedCallBack: 
    @abstract 
    @discussion 
    @param      fn C callback function
    @result     self
*/
- setProcessFinishedCallBack: (void*) fn;

/*!
    @function     welcomeClientWithBuffer:manager:
    @abstract
    @discussion 
    @param      buff
    @param      m
    @result     self
*/
- welcomeClientWithBuffer: (SndAudioBuffer*) buff manager: (SndStreamManager*) m;

/*!
    @function     startProcessingNextBufferWithInput:nowTime:
    @abstract   Client welcomed with buffer showing manager format.
    @discussion Ignore input buffer if you don't want it.
    @param      inB
    @param      t
    @result     self
*/
- startProcessingNextBufferWithInput: (SndAudioBuffer*) inB nowTime: (double) t;

/*!
    @function     processingThread
    @abstract     Root method for the synthesis thread
*/
- (void) processingThread;

/*!
    @function   outputBuffer
    @abstract   Accessor for the currently exposed output buffer
    @discussion Don't store the object returned, as the output buffer swaps to the synthesis buffer each processing cycle.
    @result     Returns the outputBuffer member
*/
- (SndAudioBuffer*) outputBuffer;

/*!
    @function   synthBuffer
    @abstract   Accessor for the current synthesis buffer
    @discussion 
    @result     Returns the synthBuffer member
*/
- (SndAudioBuffer*) synthBuffer;

/*!
    @function   inputBuffer
    @abstract   Accessor for the current input buffer
    @discussion 
    @result     Returns the inputBuffer member
*/
- (SndAudioBuffer*) inputBuffer;

/*!
    @function   managerIsShuttingDown
    @abstract 
    @discussion Message sent by the manager to tell any clients still connected to it that it is about to disappear
    @result     Returns self
*/
- managerIsShuttingDown;

/*!
    @function   processBuffers
    @abstract   The main synthesis/processing thread method 
    @discussion Override this in your derived client with your own buffer processing functionality.
*/
- (void) processBuffers; 

/*!
    @function   nowTime
    @abstract   Return the client's current time.
    @discussion The clients sense of time is just the manager's sense of time, defining a common clock among clients.
    @result     Returns the time in seconds.
*/
- (double) nowTime;

/*!
    @function   isActive
    @abstract   Returns whether the client is active.
    @result     Returns a boolean indicating whether the client is active.
*/
- (BOOL) isActive;

/*!
    @function     setDetectPeaks: (BOOL) detectPeaks
    @abstract   enables / disables peak detection
    @discussion Not implemented yet - not convinced this should be here - maybe inside an SndAudioProcessor?
    @result     self.
*/
- setDetectPeaks: (BOOL) detectPeaks;

/*!
    @function   getPeakLeft:right:
    @abstract   Get the most recent peak values for the stereo stream
    @discussion Not implemented yet - not convinced this should be here - maybe inside an SndAudioProcessor?
    @param      leftPeak Left peak value
    @param      rightPeak Righ peak value
    @result     self.
*/
- getPeakLeft: (float *) leftPeak right: (float *) rightPeak;

/*!
    @function   generatesOutput
    @abstract   Returns whether the client is an audio-producer (synthesizer, FX)
    @result     Returns TRUE if the client generates output
*/
- (BOOL) generatesOutput;

/*!
    @function   needsInput
    @abstract   Returns whether the client is an audio-consumer (recorder, FX, signal analyzer)
    @result     Returns TRUE if the client requires an input stream.
*/
- (BOOL) needsInput;

/*!
    @function     setGeneratesOutput:
    @abstract   Determines whether the client's output buffer will be considered for 
                mixing downstream.
    @discussion Normally you should only need to call this when initializing a derived stream client
    @param      b Boolean switch 
    @result     self.
*/
- setGeneratesOutput: (BOOL) b;

/*!
    @function     setNeedsInput:
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
    @function     setManager:
    @abstract   Sets the SndStreamManager for this client.
    @discussion Should never be called explicitly, it is invoked as part of the 
                process of a manager welcoming a client into the fray.
    @param      m
    @result     self.
*/
- setManager: (SndStreamManager*) m;

/*!
    @function   lockOutputBuffer
    @abstract   Blocks calling thread until outputBuffer is available for locking.  
    @discussion Lock the output buffer before doing anything with it, otherwise 
                the synthesis thread may swap the buffers on you!
    @result     self.
*/
- lockOutputBuffer;

/*!
    @function   unlockOutputBuffer
    @abstract   Releases lock on the outputBuffer.
    @result     self.
*/
- unlockOutputBuffer;

/*!
    @function   lockInputBuffer
    @abstract   Blocks calling thread until inputBuffer is available for locking.  
    @discussion Lock the input buffer before doing anything with it, otherwise 
                the synthesis thread may swap the buffers on you!
    @result     self.
*/
- lockInputBuffer;

/*!
    @function   unlockInputBuffer
    @abstract   Releases lock on the outputBuffer.
    @result     self.
*/
- unlockInputBuffer;


/*!
    @function   prepareToStreamWithBuffer: 
    @abstract   Prepare-to-stream-with-buffers-that-look-like-this message.
    @discussion Called before streaming commences to allow client an opportunity 
                to setup internal generation buffers.
    @param      buff
    @result     self.
*/
- prepareToStreamWithBuffer: (SndAudioBuffer*) buff;

/*!
    @function     didFinishStreaming
    @abstract   streaming thread is shutting down message.
    @discussion Called just before the streaming thread shuts down, giving a 
                derived client a chance to clean up after itself.
    @result     self.
*/
- didFinishStreaming;

/*!
    @function   audioProcessorChain
    @abstract   Accessor
    @discussion
    @result     Reference to the data member audioProcessorChain
*/
- (SndAudioProcessorChain*) audioProcessorChain;

/*!
    @function   setDelegate:
    @abstract   Sets the client's delegate object
    @param      d
    @result     self
*/
- setDelegate: (id) d;

/*!
    @function    delegate
    @abstract   Accessor method to the delegate member.
    @result     The stream client's delegate object
*/
- (id) delegate;

@end

/*!
    @class      SndStreamClientDelegate
    @abstract   Delegate protocol for the SndStreamClient 
    @discussion To come
*/
@interface SndStreamClientDelegate : NSObject
{
}

/*!
    @function   inputBufferSkipped
    @abstract   Message sent when the client was not ready to accept the next input buffer
*/
- inputBufferSkipped:  sender;

/*!
    @function   outputBufferSkipped
    @abstract   Message sent when the client was not ready to provide the next outputBuffer
*/
- outputBufferSkipped: sender;
@end

#endif
