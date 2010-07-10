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

////////////////////////////////////////////////////////////////////////////////
// SndStreamClientDelegate
////////////////////////////////////////////////////////////////////////////////

/*!
  @brief Informal protocol for a SndStreamClient delegate

  To come
*/
@protocol SndStreamClientDelegate

/*!
  @brief Message sent when the client was not ready to accept the next input buffer.
  @param sender The instance of SndStreamClient sending the message.
*/
- inputBufferSkipped: (id) sender;

/*!
  @brief Message sent when the client was not ready to provide the next outputBuffer.
  @param sender The instance of SndStreamClient sending the message.
*/
- outputBufferSkipped: (id) sender;

/*!
  @brief Message sent after each buffer has been processed. This is expensive.
  @param sender The instance of SndStreamClient sending the message.
 */
- didProcessStreamBuffer: (id) sender;

@end

////////////////////////////////////////////////////////////////////////////////
// SndStreamClient
////////////////////////////////////////////////////////////////////////////////

/*!
  @class SndStreamClient
  @brief A stream client is responsible for audio streaming, signal processing and synthesis.

  A SndStreamClient provides basic streaming services such as double buffering, thread
  handling, automatic start up and and shut down of lower-level streaming services.  Each
  SndStreamClient instance has a SndAudioProcessorChain instance, so each client can be
  part of a signal processing chain.

  To interpret the operation and performance of the input and output queues, the output
  queue holds the empty (ready to be modified), buffers in the pending portion of the queue, and
  the synthesised (waiting to be played), buffers in the processed portion of the
  queue. Conversely, the input queue's processed portion holds those buffers which have
  been read and processed and are free to be overwritten with newly received data, while
  the pending portion of the queue holds recorded audio that is yet to be processed.
  Therefore, the [inputQueue pendingBuffersCount] indicates the amount of system input
  latency, [outputQueue processedBuffersCount] indicates the amount of system output
  latency.

  In the processing thread, the input operation is to retrieve ("pop")
  the next available pending buffer. Additionally, the output operation is to pop the next available
  pending buffer. The input synth buffer is then used to process and synthesise into the
  output synth buffer. That output synth buffer is then processed via an
  SndAudioProcessorChain and pushed onto the output buffer queue for retrieval by the
  playback engine.
 */
@interface SndStreamClient : NSObject
{
    /*! The buffer in the output queue retrieved by the SndStreamMixer (driven by the output thread). */
    SndAudioBuffer  *exposedOutputBuffer;
    /*! The buffer in the output queue modified by the synthesis thread. */
    SndAudioBuffer  *synthOutputBuffer;
    /*! The buffer in the input queue currently ready for retrieval. */
    SndAudioBuffer  *synthInputBuffer;
    /*! A FIFO queue of SndAudioBuffers holding those pending output and those processed. */
    SndAudioBufferQueue *outputQueue;
    /*!  A FIFO queue of SndAudioBuffers holding those pending input and those processed. */
    SndAudioBufferQueue *inputQueue;
    
    /*! */
    NSConditionLock *synthThreadLock;
    /*! Controls access to the output buffer, particularly when changing the exposedOutputBuffer. */
    NSConditionLock *outputBufferLock;

    /*! */
    BOOL       active;
    /*! Indicates this client processes audio data received from a SndStreamMixer instance by -startProcessingNextBufferWithInput:nowTime: */
    BOOL       needsInput;
    /*! Indicates this client generates audio output data, retrieved from this client using -? */
    BOOL       generatesOutput;
    /*! A chain of SndAudioProcessors processing this stream clients output. */
    SndAudioProcessorChain *processorChain;
    /*! The stream clients manager. */
    SndStreamManager *manager;
    /*! The delegate to receive messages from the client. */
    id         delegate;    
    /*! The clients sense of time as used by subclasses for synthesis. */
    double     clientNowTime;
    /*! The last time received from the calling SndStreamManager.
	When streaming to non-interleaved buffers time does not monotonically advance. We check that using this.
     */
    double     lastManagerTime;
    
    /*! The descriptive name of the client. */
    NSString  *clientName;
    
@private
    /*! A conditional speeding up delegation messaging. */
    BOOL       delegateRespondsToOutputBufferSkipSelector;
    /*! A conditional speeding up delegation messaging.*/
    BOOL       delegateRespondsToInputBufferSkipSelector;
    /*! A conditional speeding up delegation messaging.*/
    BOOL       delegateRespondsToDidProcessBufferSelector;
    /*! */
    BOOL       bDisconnect;
}

/*!
  @brief Factory method to creates and initializes an autoreleased SndStreamClient instance.
  @return   An autoreleased SndStreamClient object.
*/
+ streamClient;

/*!
  @brief   Describes SndStreamClient
  
  Describes SndStreamClient 
  @return     Returns an NSString describing the SndStreamClient.
*/
- (NSString *) description;

/*!
  @brief   Initialize the client with a buffer showing manager format and start its thread.
  
  Each SndStreamClient instance receives welcomeClientWithBuffer:manager: message
  from SndStreamManager when the client is first added to the manager. The receiving
  instance is supplied the first output buffer to use. This method prepares input
  and/or output queues as needed then initiates one thread per stream client.
  The SndStreamClient method processingThread is executed by that thread.
  @param      buff The buffer to use for output and as a prototype for I/O SndAudioBufferQueues.
  @param      m The SndStreamManager responsible for this client.
  @return     Returns self
*/
- welcomeClientWithBuffer: (SndAudioBuffer *) buff manager: (SndStreamManager *) m;

/*!
  @brief   Initiates the generation of the next buffer which will be retrieved by the
		SndStreamMixer in the next iteration.
  
  SndStreamMixer in the method processInBuffer:outBuffer:nowTime:
  iterates through all its SndStreamClients sending them the message
  startProcessingNextBufferWithInput:nowTime: after retrieving the
  SndStreamClient's outputBuffer. This method is responsible for placing
  the last exposedOutputBuffer onto the pending portion of the output queue
  (an instance of SndAudioBufferQueue). The exposedOutputBuffer is then
  retrieved as the next processed buffer using popNextProcessedBuffer.
  @param      inB The Input Buffer. Ignore input buffer if you don't want it.
  @param      t The current now time.
  @return     Returns self.
*/
- startProcessingNextBufferWithInput: (SndAudioBuffer *) inB nowTime: (double) t;

/*!
  @brief Any audio buffers which have been processed and awaiting to be retrieved by the
  SndStreamMixer/SndStreamManager are preempted, clearing any sounds such that any
  new buffer processed will be mixed without waiting for earlier processed buffers
  to be mixed.
  @return     Returns the number of seconds that the stream has been preempted by.
 */
- (double) preemptQueuedStream;
 
/*!
  @brief   Root method for the synthesis thread.
*/
- (void) processingThread;

/*!
  @brief   Accessor for the currently exposed output buffer
  
  Don't store the object returned, as the output buffer swaps to the synthesis buffer each processing cycle.
  @return     Returns the output buffer as a SndAudioBuffer instance.
*/
- (SndAudioBuffer *) outputBuffer;

/*!
  @brief   Accessor for the current synthesis buffer
  
  This is typically used internally in a SndStreamClient subclass to retrieve the current buffer to be processed.
  @return     Returns the buffer to be synthesized as a SndAudioBuffer instance.
*/
- (SndAudioBuffer *) synthOutputBuffer;

/*!
  @brief   Accessor for the current input buffer
  
  
  @return     Returns the input buffer member
*/
- (SndAudioBuffer *) synthInputBuffer;

/*!
  @brief 
  
  Message sent by the manager to tell any clients still connected to it that it is about to disappear
  @return     Returns self
*/
- managerIsShuttingDown;

/*!
  @brief   The main synthesis/processing thread method 
  
  A subclass should override this method with its buffer processing method.
  This should be along the lines of (in pseudo code):

 <pre>
 SndAudioBuffer *b = [self synthBuffer];
 
 for(i = 0; i < [b length]; i++)
  ([b sample])[i] = a_synth_sample();
 </pre>
 */
- (void) processBuffers; 

/*!
  @brief   Return the client's current SYNTHESIS time.
  
  The client synthesis thread's sense of time. Since the client's synthesis (processing)
  thread can process several buffers ahead of the manager, the client must maintain an 
  independent sense of time. This is the time your derived stream client class <B>MUST</B>
  use inside its processBuffers overridden method. 
  
  <B>NOTE</B> - This means all operations must be fed to a stream client thread with a 
  look-ahead delta time greater or equal to the process-ahead latency to ensure correct 
  timing.

  (See <tt>streamTime</tt>)

  @return     Returns the synthesis thread time, in seconds.
*/
- (double) synthesisTime;

/*!
  @brief Sets the clients sense of streamTime. Internal clientNowTime is recalculated relative to the new Time.
  @param originTimeInSeconds New now time.
*/
- (void) resetTime: (double) originTimeInSeconds;

/*!
  @brief   Return the global (the MANAGER'S) current time.
  
  The manager's sense of time. For most time-operations outside of the synthesis thread,
  your stream client will probably want the "absolute" stream time as determined by the
  manager. For example, a client that it told to perform an operation 0.5 seconds in the
  future must compute the time-till-operation based on the global time; if it were to
  use the synthesis time, the operation would be performed 0.5 seconds PLUS the synth-ahead
  latency into the future.

  (See <tt>synthesisTime</tt>)
  
  @return     Returns the global (manager) time, in seconds.
*/
- (double) streamTime;

/*!
  @brief   Returns whether the client is active.
  @return     Returns a boolean indicating whether the client is active.
*/
- (BOOL) isActive;

/*!
  @brief   enables / disables peak detection
  
  Not implemented yet - not convinced this should be here - maybe inside an SndAudioProcessor?
  @return     Returns self.
*/
- setDetectPeaks: (BOOL) detectPeaks;

/*!
  @brief   Get the most recent peak values for the stereo stream
  
  Not implemented yet - not convinced this should be here - maybe inside an SndAudioProcessor?
  @param      leftPeak Left peak value
  @param      rightPeak Righ peak value
  @return     Returns self.
*/
- getPeakLeft: (float *) leftPeak right: (float *) rightPeak;

/*!
  @brief   Returns whether the client is an audio-producer (synthesizer, FX)
  @return     Returns TRUE if the client generates output
*/
- (BOOL) generatesOutput;

/*!
  @brief   Returns whether the client is an audio-consumer (recorder, FX, signal analyzer)
  @return     Returns TRUE if the client requires an input stream.
*/
- (BOOL) needsInput;

/*!
  @brief   Determines whether the client's output buffer will be considered for 
  mixing downstream.
  
  Normally you should only need to call this when initializing a derived stream client
  @param      b Boolean switch 
  @return     Returns self.
*/
- setGeneratesOutput: (BOOL) b;

/*!
  @brief   Sets whether the client requires an input audio stream or not.
  
  Normally you should only need to call this when initializing a subclassed stream client.
  If true, the stream manager will copy the most recent input buffer
  into the client's input buffer each processing cycle provided the
  client hasn't choked the CPU. If the client is running in less than
  real time, the input buffer is not updated, since the manager must
  assume that the client's copy of the previous input buffer may still
  be in use.
  @param      yesOrNo YES copy the input buffer into the client.
  @return     Returns self.
*/
- setNeedsInput: (BOOL) yesOrNo;

/*!
  @brief   Sets the SndStreamManager for this client.
  
  Should never be called explicitly, it is invoked as part of the 
  process of a manager welcoming a client into the fray.
  @param      m The new SndStreamManager instance.
  @return     Returns self.
*/
- setManager: (SndStreamManager *) m;

/*!
  @brief   Blocks calling thread until outputBuffer is available for locking.  
  
  Lock the output buffer before doing anything with it, otherwise 
  the synthesis thread may swap the buffers on you!
  @return     Returns self.
*/
- lockOutputBuffer;

/*!
  @brief   Releases lock on the outputBuffer.
  @return  Returns self.
*/
- unlockOutputBuffer;

/*!
  @brief   Prepare to stream with buffers that look like the supplied buffer.
  
  Called before streaming commences to allow client an opportunity 
  to setup internal generation buffers.
  @param      buff
  @return     Returns self.
*/
- prepareToStreamWithBuffer: (SndAudioBuffer *) buff;

/*!
  @brief   streaming thread is shutting down message.
  
  Called just before the streaming thread shuts down, giving a 
  derived client a chance to clean up after itself.
  @return     Returns self.
*/
- didFinishStreaming;

/*!
  @brief   Returns the client's SndAudioProcessorChain.  
  @return     Reference to the data member audioProcessorChain
*/
- (SndAudioProcessorChain *) audioProcessorChain;

/*!
  @brief Assigns a replacement audio processor chain.
  @param newAudioProcessorChain A SndAudioProcessorChain instance.
 */
- (void) setAudioProcessorChain: (SndAudioProcessorChain *) newAudioProcessorChain;

/*!
  @brief   Sets the client's delegate object
  @param      d
  @return     Returns self.
*/
- (void) setDelegate: (id) d;

/*!
  @brief   Accessor method to the delegate member.
  @return     The stream client's delegate object
*/
- (id) delegate;

/*!
  @return    Returns the number of buffers in the input queue.
*/
- (int) inputBufferCount;

/*!
  @return    Returns the number of buffers in the output queue.
*/
- (int) outputBufferCount;

/*!
  @brief Sets the input buffer queue length (only when client is NOT active)  
  @param    n Number of buffers
  @return   TRUE if all is well, FALSE if input buffer length could not be set. 
*/
- (BOOL) setInputBufferCount: (int) n;

/*!
  @brief Sets the output buffer queue length (only when client is NOT active)  
  @param    n Number of buffers
  @return   TRUE if all is well, FALSE if output buffer length could not be set.  
*/
- (BOOL) setOutputBufferCount: (int) n;

/*!
  @brief  Calculates the stream latency of the client 
  
  Number of buffers in queue times buffer duration.
  @return    Returns latency, in seconds. 
*/
- (double) outputLatencyInSeconds;

/*!
  @brief  Calculates the stream latency of the client
  
  The calculation is determined as the total number of buffers in the queue times the buffer duration.
  @return    Returns latency, in samples.
 */
- (long) outputLatencyInSamples;

/*!
  @brief  Calculates the current output stream latency of the client
  
  The calculation is determined as the number of buffers processed in the queue waiting to
  be played times the buffer duration.
  @return    Returns latency, in samples.
 */
- (long) instantaneousOutputLatencyInSamples;

/*!
  @brief  Calculates the current input stream latency of the client
  
  The calculation is determined as the number of buffers pending in the queue waiting to
  be processed times the buffer duration.
  @return    Returns latency, in samples.
 */
- (long) instantaneousInputLatencyInSamples;

/*!
  @brief  Accessor to the client name 
  @return    Returns the NSString with the client's name.
*/
- (NSString *) clientName;

/*!
  @brief  Sets the client's name
  
  Useful for identifying clients, especially when debugging - several SndStreamClient 
  warning and error messages will display the name of the client reporting the error.
  @param     name The client's name.
  @return    Returns self.
*/
- setClientName: (NSString *) name;

/*!
  @brief To come
  @param anAudioBuffer the audio buffer to process
  @param t nowTime
 */
- offlineProcessBuffer: (SndAudioBuffer *) anAudioBuffer nowTime: (double) t;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
