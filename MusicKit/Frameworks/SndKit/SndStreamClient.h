////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and 
//  non-commercial purposes so long as the author attribution and copyright 
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDSTREAMCLIENT__
#define __SNDSTREAMCLIENT__

#import <Foundation/Foundation.h>

enum {
    OB_notInit,
    OB_isInit
};

@class SndAudioBuffer; 
@class SndAudioBufferQueue;
@class SndStreamManager;
@class SndAudioProcessorChain;

#ifdef __MINGW32__
# import "SndConditionLock.h"
# define NSConditionLock SndConditionLock
#endif

////////////////////////////////////////////////////////////////////////////////
// SndStreamClientDelegate
////////////////////////////////////////////////////////////////////////////////

/*!
@protocol SndStreamClientDelegate
@abstract Informal protocol for a SndStreamClient delegate
@discussion To come
*/
@protocol SndStreamClientDelegate

/*!
  @method     inputBufferSkipped:
  @param The instance of SndStreamClient sending the message.
  @abstract   Message sent when the client was not ready to accept the
 next input buffer
*/
- inputBufferSkipped:  sender;

/*!
  @method outputBufferSkipped:
  @param The instance of SndStreamClient sending the message.
  @abstract Message sent when the client was not ready to provide the
           next outputBuffer
*/
- outputBufferSkipped: sender;

/*!
  @method didProcessStreamBuffer:
  @param The instance of SndStreamClient sending the message.
  @abstract Message sent after each buffer has been processed. This is expensive.
 */
- didProcessStreamBuffer: sender;

@end

////////////////////////////////////////////////////////////////////////////////
// SndStreamClient
////////////////////////////////////////////////////////////////////////////////

/*!
@class SndStreamClient
@abstract A stream client is responsible for audio streaming, signal processing and synthesis.
@discussion A SndStreamClient provides basic streaming services such as double buffering, thread handling,
automatic start up and and shut down of lower-level streaming services. Each SndStreamClient instance has a SndAudioProcessorChain instance, so each client can be part of a signal processing chain.
*/
@interface SndStreamClient : NSObject
{
/*! @var             exposedOutputBuffer The buffer in the output queue retrieved by the SndStreamMixer (driven by the output thread). */
    SndAudioBuffer  *exposedOutputBuffer;
/*! @var             synthOutputBuffer The buffer in the output queue modified by the synthesis thread. */
    SndAudioBuffer  *synthOutputBuffer;
/*! @var             synthInputBuffer */
    SndAudioBuffer  *synthInputBuffer;
/*! @var                 outputQueue A FIFO queue of SndAudioBuffers holding those pending output and those processed. */
    SndAudioBufferQueue *outputQueue;
/*! @var                 inputQueue */
    SndAudioBufferQueue *inputQueue;
    
/*! @var       synthThreadLock */
    NSConditionLock *synthThreadLock;
/*! @var       outputBufferLock Controls access to the output buffer, particularly when changing the exposedOutputBuffer. */
    NSConditionLock *outputBufferLock;

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
/*! @var       delegate; */
    id         delegate;    
/*! @var       clientNowTime */
    double     clientNowTime;
    
/*! @var       clientName */
    NSString  *clientName;
    
@private
/*! @var       delegateRespondsToOutputBufferSkipSelector Conditional speeding up delegation messaging. */
    BOOL       delegateRespondsToOutputBufferSkipSelector;
/*! @var       delegateRespondsToInputBufferSkipSelector Conditional speeding up delegation messaging.*/
    BOOL       delegateRespondsToInputBufferSkipSelector;
/*! @var       delegateRespondsToDidProcessBufferSelector Conditional speeding up delegation messaging.*/
    BOOL       delegateRespondsToDidProcessBufferSelector;
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
    @method     welcomeClientWithBuffer:manager:
    @abstract   Initialize the client with a buffer showing manager format and start its thread.
    @discussion Each SndStreamClient instance receives welcomeClientWithBuffer:manager: message
                from SndStreamManager when the client is first added to the manager. The receiving
                instance is supplied the first output buffer to use. This method prepares input
                and/or output queues as needed then initiates one thread per stream client.
                The SndStreamClient method processingThread is executed by that thread.
    @param      buff The buffer to use for output and as a prototype for I/O SndAudioBufferQueues.
    @param      m The SndStreamManager responsible for this client.
    @result     Returns self
*/
- welcomeClientWithBuffer: (SndAudioBuffer *) buff manager: (SndStreamManager *) m;

/*!
    @method     startProcessingNextBufferWithInput:nowTime:
    @abstract   Initiates the generation of the next buffer which will be retrieved by the
		SndStreamMixer in the next iteration.
    @discussion SndStreamMixer in the method processInBuffer:outBuffer:nowTime:
                iterates through all its SndStreamClients sending them the message
                startProcessingNextBufferWithInput:nowTime: after retrieving the
                SndStreamClient's outputBuffer. This method is responsible for placing
                the last exposedOutputBuffer onto the pending portion of the output queue
                (an instance of SndAudioBufferQueue). The exposedOutputBuffer is then
                retrieved as the next processed buffer using popNextProcessedBuffer.
    @param      inB The Input Buffer. Ignore input buffer if you don't want it.
    @param      t The current now time.
    @result     Returns self.
*/
- startProcessingNextBufferWithInput: (SndAudioBuffer*) inB nowTime: (double) t;

/*!
  @method     preemptQueuedStream
  @discussion Any audio buffers which have been processed and awaiting to be retrieved by the
              SndStreamMixer/SndStreamManager are preempted, clearing any sounds such that any
              new buffer processed will be mixed without waiting for earlier processed buffers
              to be mixed.
  @param      nowTime The new now time.
  @result     Returns the number of seconds that the stream has been preempted by.
 */
- (double) preemptQueuedStream;
 
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
- (double) synthesisTime;

/*!
    @method resetTime:
    @abstract Sets the clients sense of streamTime. Internal clientNowTime is recalculated relative to the new Time.
    @param originTimeInSeconds New now time.
*/
- (void) resetTime: (double) originTimeInSeconds;

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
    @result     Returns self.
*/
- setDetectPeaks: (BOOL) detectPeaks;

/*!
    @method   getPeakLeft:right:
    @abstract   Get the most recent peak values for the stereo stream
    @discussion Not implemented yet - not convinced this should be here - maybe inside an SndAudioProcessor?
    @param      leftPeak Left peak value
    @param      rightPeak Righ peak value
    @result     Returns self.
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
    @result     Returns self.
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
    @result     Returns self.
*/
- setNeedsInput: (BOOL) b;

/*!
    @method     setManager:
    @abstract   Sets the SndStreamManager for this client.
    @discussion Should never be called explicitly, it is invoked as part of the 
                process of a manager welcoming a client into the fray.
    @param      m
    @result     Returns self.
*/
- setManager: (SndStreamManager*) m;

/*!
    @method   lockOutputBuffer
    @abstract   Blocks calling thread until outputBuffer is available for locking.  
    @discussion Lock the output buffer before doing anything with it, otherwise 
                the synthesis thread may swap the buffers on you!
    @result     Returns self.
*/
- lockOutputBuffer;

/*!
    @method   unlockOutputBuffer
    @abstract   Releases lock on the outputBuffer.
    @result     Returns self.
*/
- unlockOutputBuffer;
/*!
    @method   prepareToStreamWithBuffer: 
    @abstract   Prepare to stream with buffers that look like the supplied buffer.
    @discussion Called before streaming commences to allow client an opportunity 
                to setup internal generation buffers.
    @param      buff
    @result     Returns self.
*/
- prepareToStreamWithBuffer: (SndAudioBuffer*) buff;

/*!
    @method     didFinishStreaming
    @abstract   streaming thread is shutting down message.
    @discussion Called just before the streaming thread shuts down, giving a 
                derived client a chance to clean up after itself.
    @result     Returns self.
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
    @result     Returns self.
*/
- (void) setDelegate: (id) d;

/*!
    @method    delegate
    @abstract   Accessor method to the delegate member.
    @result     The stream client's delegate object
*/
- (id) delegate;

/*!
    @method    inputBufferCount
    @result    Returns the number of buffers in the input queue.
*/
- (int) inputBufferCount;

/*!
    @method    outputBufferCount
    @result    Returns the number of buffers in the output queue.
*/
- (int) outputBufferCount;

/*!
    @method   setInputBufferCount: 
    @abstract Sets the input buffer queue length (only when client is NOT active)  
    @param    n Number of buffers
    @result   TRUE if all is well, FALSE if input buffer length could not be set. 
*/
- (BOOL) setInputBufferCount: (int) n;

/*!
    @method   setOutputBufferCount:   
    @abstract Sets the output buffer queue length (only when client is NOT active)  
    @param    n Number of buffers
    @result   TRUE if all is well, FALSE if output buffer length could not be set.  
*/
- (BOOL) setOutputBufferCount: (int) n;


/*!
    @method    outputLatencyInSeconds
    @abstract  Calculates the stream latency of the client 
    @discussion Number of buffers in queue times buffer duration.
    @result    Returns latency, in seconds. 
*/
- (double) outputLatencyInSeconds;

/*!
  @method    outputLatencyInSamples
  @abstract  Calculates the current stream latency of the client
  @discussion Number of buffers in queue times buffer duration.
  @result    Returns latency, in samples.
 */
- (long) outputLatencyInSamples;

/*!
    @method    clientName
    @abstract  Accessor to the client name 
    @result    Returns the NSString with the client's name.
*/
- (NSString*) clientName;

/*!
    @method    setClientName:
    @abstract  Sets the client's name
    @param     name The client's name.
    @discussion Useful for identifying clients, especially when debugging - several SndStreamClient 
                warning and error messages will display the name of the client reporting the error.
    @result    Returns self.
*/
- setClientName: (NSString*) name;

/*!
  @method offlineProcessBuffer:nowTime:
  @abstract To come
  @param anAudioBuffer the audio buffer to process
  @param t nowTime
 */
- offlineProcessBuffer: (SndAudioBuffer*) anAudioBuffer nowTime: (double) t;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
