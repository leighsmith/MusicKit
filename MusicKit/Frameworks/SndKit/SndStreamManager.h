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

/*!
    @class      SndStreamManager
    @abstract   Provides client connection and stream mixing services, and acts as 
                the gateway to the lowlevel MKPerformSndMIDI C functions
    @discussion To come
*/
@interface SndStreamManager : NSObject
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
    BOOL            bg_sem;
/*! @var            bg_threadLock used for signalling to background thread to start streaming,
                    stop streaming, or abort itself. */
#ifndef __MINGW32__
    NSConditionLock *bg_threadLock;
#else
    SndConditionLock *bg_threadLock;
#endif
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

@end

#endif
