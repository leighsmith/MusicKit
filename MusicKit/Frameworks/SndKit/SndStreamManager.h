/*
  $Id$

  Description:

  Original Author: SKoT McDonald, <skot@tomandandy.com>, tomandandy music inc.

  Sat 10-Feb-2001, Copyright (c) 2001 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/
#ifndef __SNDSTREAMMANAGER_H__
#define __SNDSTREAMMANAGER_H__

#import <Foundation/Foundation.h>
#import "SndKit.h"

@class SndAudioBuffer;
@class SndStreamClient;
@class SndStreamMixer;

#ifdef __MINGW32__
@class SndConditionLock;
#endif

#define SSM_VERSION 1 

@protocol SndDelegateMessagePassing 
- (void) _sendDelegateInvocation:(in unsigned long) mesg;
@end 

/*!
    @class      SndStreamManager
    @abstract   Provides client connection and stream mixing services, and acts as 
                the gateway to the lowlevel MKPerformSndMIDI C functions
    @discussion To come
*/
@interface SndStreamManager : NSObject <SndDelegateMessagePassing>
{ 
/*! @var            mixer A stream client mixer*/
    SndStreamMixer *mixer;
/*! @var            active Stores the streaming state of the manager. */
    BOOL            active;
/*! @var            bg_active Whether or not the backgroup stream stopping/starting thread has been created. */
    BOOL            bg_active;
/*! @var            format SndSoundStruct containing stream format information. */
    SndSoundStruct  format;
/*! @var            nowTime Manager's conception of time, in seconds. */
    double          nowTime;
/*! @var            bg_sem Semaphore to background thread to start/stop streaming. */
    char            bg_sem;
/*! @var            bgdm_sem Semaphore to background delegate messaging thread to notify it of data
                             being ready for it. */
    char            bgdm_sem;
/*! @var            bg_threadLock used for signalling to background thread to start streaming,
                    stop streaming, or abort itself. */
#ifndef __MINGW32__
    NSConditionLock *bg_threadLock;
    NSConditionLock *bgdm_threadLock;
#else
    SndConditionLock *bg_threadLock;
    SndConditionLock *bgdm_threadLock;
#endif
    NSLock          *delegateMessageArrayLock;
    NSMutableArray  *delegateMessageArray;
    NSConnection    *threadConnection;
}

/*!
    @method initialize
    @abstract Class initialization method
    @discussion Creates the default stream manager
    @result void.
*/
+ (void) initialize;

/*!
    @method   defaultStreamManager
    @abstract   Accessor to the default stream manager created upon class initialization.
    @discussion SndStreamClients will usually connect to the default stream manager, unless
                the user wishes to explicitly create their own manager.  
    @result     Returns the default manager
*/
+ (SndStreamManager*) defaultStreamManager;

/*!
    @method   dealloc
    @abstract   Destructor
*/
- (void) dealloc;

/*!
    @method   description
    @abstract   Returns an NSString with description of SndStreamManager
    @discussion 
    @result     Returns an NSString with description of SndStreamManager
*/
- (NSString*) description;

/*!
    @method   startStreaming
    @abstract   Starts streaming.
    @discussion You should never need to call this. Streaming is started automatically
                when the first client connects to the manager.
*/
- (void) startStreaming;

/*!
    @method   stopStreaming
    @abstract   Stops streaming.
    @discussion You should never need to call this. Streaming is stopped automatically
                when the last client disconnects from the manager.
*/
- (void) stopStreaming;

/*!
    @method   streamStartStopThread
    @abstract   a very lightweight thread used for starting and stopping
                the audio streams
    @discussion You should never need to call this. The manager can instruct
                the starting and stopping of streams by setting bg_sem to
                BG_startNow or BG_stopNow, and setting the bg_threadLock
                condition. The thread is created on this method when a stream
                is to begin, if it does not exist already.
*/
- (void) streamStartStopThread;

/*!
    @method     delegateMessageThread
    @abstract   a very lightweight thread used for sending delegate messages
                from the background threads to the main thread.
    @param      ports a pair of NSPorts in an NSArray, used for setting up the
                DO between this thread and the main thread.
    @discussion You should never need to call this. The manager calls this method
                as it starts up (in <I>init</I>) then the thread just sits there
                waiting for a signal to say that there's a delegate message sitting
                in an array, waiting to be sent. The delegate message should have
                been sent to -sendMessageInMainThreadToTarget::::. After arriving
                in the delegate message thread it is dispatched to the main thread
                via Distributed Objects, and will be sent on to the requested
                delegate at the next convenient time in the NSRunLoop.
*/
- (void) delegateMessageThread:(NSArray*)ports;

/*!
    @method   addClient: 
    @abstract   Adds an SndStreamClient to the manager's mixer
    @discussion If the SndStreamClient is already a client of the mixer, it 
                is NOT added again. If the client is the first connected to
                the manager, the manager will automatically start streaming.
    @param      client
    @result     TRUE if client was successfully added
*/
- (BOOL) addClient: (SndStreamClient*) client;

/*!
    @method   removeClient: 
    @abstract   Removes the SndStreamClient from the manager's mixer
    @discussion If the removed client was the last client connected to the
                manager, streaming will be automatically shut down.
    @param      client The client to be disconnected from the manager.
    @result     TRUE if the client was successfully removed.
*/
- (BOOL) removeClient: (SndStreamClient*) client;

/*!
    @method   processStreamAtTime:input:output:
    @abstract   Passes new input and output buffers from the underlaying API to the
                mixer.
    @discussion Do not call this method - it is part of the audio callback handler.
    @param      sampleCount Time in samples
    @param      inB inputBuffer
    @param      outB
*/
- (void) processStreamAtTime: (double) sampleCount
                       input: (SNDStreamBuffer*) inB
                      output: (SNDStreamBuffer*) outB;

/*!
    @method   setFormat:
    @abstract   Sets the format to be used during streaming
    @discussion Do not call this method - it is called as part of the start-streaming
                process. The stream format used is the native format coming up from 
                the devices below.
    @param      f
    @result     self
*/
- setFormat: (SndSoundStruct*) f;

/*!
    @method   nowTime
    @abstract   Return the current time as understood by the SndStreamManager
    @discussion 
    @result     nowTime as a double 
*/
- (double) nowTime;

/*!
    @method   mixer
    @abstract   Mixer member accessor method
    @result     The internal SndStreamMixer
*/
- (SndStreamMixer*) mixer;

/*!
    @method   isActive
    @abstract   indicates whether streaming is happening (active) 
    @discussion 
    @result     TRUE if streaming is active
*/
- (BOOL) isActive;

/*!
    @method samplingrate
    @result The streaming sampling rate.
*/
- (double) samplingRate;

/*!
    @method   resetTime:
    @abstract Resets the global stream time to originTimeInSeconds
    @param originTimeInSeconds New origin time, in seconds.
    @discussion The new origin time is propagated to the mixer, and thus to the stream clients.
*/
- (void) resetTime: (double) originTimeInSeconds;

/*!
    @method     sendMessageInMainThreadToTarget:sel:arg1:arg2:
    @abstract   Sends messages from any thread to any object in the main thread
    @discussion This method was introduced to allow easy delegate messaging from
                the underlying audio threads, but can be used by any object. The
                method creates an NSInvocation out of the parameters given, and
                adds it to an array of waiting messages. Then a background thread
                with an NSConnection to the main thread is notified, and the messages
                are passed up the connection one by one, and dispatched in the main
                thread. Note that the final dispatch is only done as part of the
                application's NSRunLoop, which means that if the main thread is busy
                doing anything, it can tke a little while for the delegate message to
                appear. Even if this is the case, this method should not block for long.
    @param      target id target object
    @param      sel SEL the selector to be sent, eg @selector(description:withObject:)
    @param      arg1 the first argument in the selector
    @param      arg2 the second argument in the selector
*/
- (void) sendMessageInMainThreadToTarget:(id)target sel:(SEL)sel arg1:(id)arg1 arg2:(id)arg2;

/*!
    @method   _sendDelegateInvocation:
    @abstract INTERNAL USE ONLY 
    @param    mesg an NSInvocation object containing the final delegate message,
              cast as an unsigned long to prevent interpretation by OpenStep.
    @discussion INTERNAL USE ONLY. Used as part of the delegate system for passing
              delegate messages out of background threads into the foreground thread
*/
- (void) _sendDelegateInvocation:(in unsigned long) mesg;

@end

#endif
