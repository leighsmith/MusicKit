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
@class SndAudioBufferQueue;
@class SndStreamManager;
@class SndAudioProcessorChain;

/*!
    @class      SndStreamClientDelegate
    @abstract   Informal protocol for a SndStreamClient delegate
    @discussion To come
*/
@interface SndStreamClientDelegate

/*!
    @method   inputBufferSkipped
    @abstract   Message sent when the client was not ready to accept the next input buffer
*/
- inputBufferSkipped:  sender;

/*!
    @method   outputBufferSkipped
    @abstract   Message sent when the client was not ready to provide the next outputBuffer
*/
- outputBufferSkipped: sender;
@end


/*!
    @class      SndStreamClient
    @abstract   Audio streaming / signal processing / synthesis module 
    @discussion Provides basic streaming services such as double buffering, thread handling,
                automatic start up and and shut down of lower-level streaming services. 
*/
@interface SndStreamClient : NSObject
{
/*! @var             exposedOutputBuffer */
    SndAudioBuffer  *exposedOutputBuffer;
/*! @var             synthOutputBuffer */
    SndAudioBuffer  *synthOutputBuffer;
/*! @var             synthInputBuffer */
    SndAudioBuffer  *synthInputBuffer;

/*
    NSMutableArray  *pendingOutputBuffers;
    NSMutableArray  *processedOutputBuffers;
    NSConditionLock *pendingOutputBuffersLock;
    NSConditionLock *processedOutputBuffersLock;
    int              numOutputBuffers;

    NSMutableArray  *pendingInputBuffers;
    NSMutableArray  *processedInputBuffers;
    NSConditionLock *pendingInputBuffersLock;
    NSConditionLock *processedInputBuffersLock;
    int              numInputBuffers;
*/
    SndAudioBufferQueue *outputQueue;
    SndAudioBufferQueue *inputQueue;
    
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
    double     clientNowTime;
    
/*! @var       clientName */
    NSString  *clientName;
    
@private
/*! @var       bDelegateRespondsToOutputBufferSkipSelector */
    BOOL       bDelegateRespondsToOutputBufferSkipSelector;
/*! @var       bDelegateRespondsToInputBufferSkipSelector */
    BOOL       bDelegateRespondsToInputBufferSkipSelector;
/*! @var       bDisconnect */
    BOOL       bDisconnect;
}

/*!
    @method   streamClient
    @abstract   Factory method
    @discussion Creates and initializes an SndStreamObject
    @result     An autoreleased SndStreamClient object
*/
+ streamClient;

/*!
    @method     dealloc 
    @abstract   Destructor
    @discussion Releases SndAudioBuffers, NSLocks, and SndStreamManager
*/
- (void) dealloc;
/*!
    @method     freeBufferMem 
    @abstract   Frees buffer memory
    @discussion For internal use only.
*/
- freeBufferMem;

/*!
    @method   description
    @abstract   Describes SndStreamClient
    @discussion Describes SndStreamClient 
    @result     Returns an NSString describing the SndStreamClient.
*/
- (NSString*) description;

/*!
    @method   setProcessFinishedCallBack: 
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
    @abstract     Root method for the synthesis thread
*/
- (void) processingThread;

/*!
    @method   outputBuffer
    @abstract   Accessor for the currently exposed output buffer
    @discussion Don't store the object returned, as the output buffer swaps to the synthesis buffer each processing cycle.
    @result     Returns the outputBuffer member
*/
- (SndAudioBuffer*) outputBuffer;

/*!
    @method     synthOutputBuffer
    @abstract   Accessor for the current synthesis buffer
    @discussion 
    @result     Returns the synthBuffer member
*/
- (SndAudioBuffer*) synthOutputBuffer;

/*!
    @method     synthinputBuffer
    @abstract   Accessor for the current input buffer
    @discussion 
    @result     Returns the inputBuffer member
*/
- (SndAudioBuffer*) synthInputBuffer;

/*!
    @method   managerIsShuttingDown
    @abstract 
    @discussion Message sent by the manager to tell any clients still connected to it that it is about to disappear
    @result     Returns self
*/
- managerIsShuttingDown;

/*!
    @method   processBuffers
    @abstract   The main synthesis/processing thread method 
    @discussion Override this in your derived client with your own buffer processing functionality.
*/
- (void) processBuffers; 

/*!
    @method     synthesisTime
    @abstract   Return the client's current SYNTHESIS time.
    @discussion The client synthesis thread's sense of time. Since the client's synthesis (processing)
                thread can process several buffers ahead of the manager, the client must maintain an 
                independent sense of time. This is the time your derived stream client class <B>MUST</B>
                use inside its processBuffers overridden method. 
                
                <B>NOTE</B> - This means all operations must be fed to a stream client thread with a 
                look-ahead delta time greater or equal to the process-ahead latency to ensure correct 
                timing.

                (See <tt>streamTime</tt>)

    @result     Returns the synthesis thread time, in seconds.
*/

- (void) resetTime: (double) originTimeInSeconds;

- (double) synthesisTime;
/*!
    @method     streamTime
    @abstract   Return the global (the MANAGER'S) current time.
    @discussion The manager's sense of time. For most time-operations outside of the synthesis thread,
                your stream client will probably want the "absolute" stream time as determined by the
                manager. For example, a client that it told to perform an operation 0.5 seconds in the
                future must compute the time-till-operation based on the global time; if it were to
                use the synthesis time, the operation would be performed 0.5 seconds PLUS the synth-ahead
                latency into the future.

                (See <tt>synthesisTime</tt>)
                              
    @result     Returns the global (manager) time, in seconds.
*/
- (double) streamTime;

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
    @method   getPeakLeft:right:
    @abstract   Get the most recent peak values for the stereo stream
    @discussion Not implemented yet - not convinced this should be here - maybe inside an SndAudioProcessor?
    @param      leftPeak Left peak value
    @param      rightPeak Righ peak value
    @result     self.
*/
- getPeakLeft: (float *) leftPeak right: (float *) rightPeak;

/*!
    @method   generatesOutput
    @abstract   Returns whether the client is an audio-producer (synthesizer, FX)
    @result     Returns TRUE if the client generates output
*/
- (BOOL) generatesOutput;

/*!
    @method   needsInput
    @abstract   Returns whether the client is an audio-consumer (recorder, FX, signal analyzer)
    @result     Returns TRUE if the client requires an input stream.
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
    @method   lockOutputBuffer
    @abstract   Blocks calling thread until outputBuffer is available for locking.  
    @discussion Lock the output buffer before doing anything with it, otherwise 
                the synthesis thread may swap the buffers on you!
    @result     self.
*/
- lockOutputBuffer;

/*!
    @method   unlockOutputBuffer
    @abstract   Releases lock on the outputBuffer.
    @result     self.
*/
- unlockOutputBuffer;

/*!
    @method   lockInputBuffer
    @abstract   Blocks calling thread until inputBuffer is available for locking.  
    @discussion Lock the input buffer before doing anything with it, otherwise 
                the synthesis thread may swap the buffers on you!
    @result     self.
*/
- lockInputBuffer;

/*!
    @method   unlockInputBuffer
    @abstract   Releases lock on the outputBuffer.
    @result     self.
*/
- unlockInputBuffer;


/*!
    @method   prepareToStreamWithBuffer: 
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
    @method   audioProcessorChain
    @abstract   Accessor
    @discussion
    @result     Reference to the data member audioProcessorChain
*/
- (SndAudioProcessorChain*) audioProcessorChain;

/*!
    @method   setDelegate:
    @abstract   Sets the client's delegate object
    @param      d
    @result     self
*/
- setDelegate: (id) d;

/*!
    @method    delegate
    @abstract   Accessor method to the delegate member.
    @result     The stream client's delegate object
*/
- (id) delegate;

- (int) inputBufferCount;
- (int) outputBufferCount;
- (BOOL) setInputBufferCount: (int) n;
- (BOOL) setOutputBufferCount: (int) n;

- (double) outputLatencyInSeconds;

- (NSString*) clientName;
- setClientName: (NSString*) name;

@end

#endif
