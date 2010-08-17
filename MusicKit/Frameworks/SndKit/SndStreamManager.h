////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    See headerdoc description below.
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

#ifndef __SNDSTREAMMANAGER_H__
#define __SNDSTREAMMANAGER_H__

#import <Foundation/Foundation.h>
#import "SndFormat.h"

@class SndAudioBuffer;
@class SndStreamClient;
@class SndStreamMixer;

/*!
  @protocol SndDelegateMessagePassing
 */
@protocol SndDelegateMessagePassing
/*!
  @param mesg
 */
- (void) _sendDelegateInvocation:(in unsigned long) mesg;
@end 

/*!
  @class SndStreamManager
  @brief SndStreamManager abstracts the playing of streams of audio. Provides streaming client connection and stream mixing services, and acts as 
  an abstraction of the sound playing hardware.
 
  In practice, the hardware is further abstracted by a platform specific interface that encapsulated by the lowlevel MKPerformSndMIDI C functions. 
  
  Each SndStreamManager has a SndStreamMixer which has a SndAudioProcessorChain which has a SndAudioFader.
  Adding clients to a manager adds them to the underlying mixer.
*/
@interface SndStreamManager : NSObject <SndDelegateMessagePassing>
{ 
    /*! mixer A stream client mixer. */
    SndStreamMixer *mixer;
    /*! active Stores the streaming state of the manager. */
    BOOL            active;
    /*! bg_active Whether or not the backgroup stream stopping/starting thread has been created. */
    BOOL            bg_active;
    /*! format SndFormat containing stream format information. */
    SndFormat       format;
    /*! nowTime Manager's conception of time, in seconds. */
    double          nowTime;
    /*! bg_sem Semaphore to the background thread to start/stop streaming. */
    char            bg_sem;
    /*! bgdm_sem Semaphore to the background delegate messaging thread to notify it of data being ready for it. */
    char            bgdm_sem;
    /*! bg_threadLock used for signalling to background thread to start streaming,
        stop streaming, or abort itself. */
    NSConditionLock *bg_threadLock;
    /*! bgdm_threadLock used for ? */
    NSConditionLock *bgdm_threadLock;
    NSLock          *delegateMessageArrayLock;
    NSMutableArray  *delegateMessageArray;
    NSConnection    *threadConnection;

    BOOL             bDelegateMessagingEnabled;
    /*! isStopping Indicates the SndStreamManager is in the process of stopping. */
    BOOL             isStopping;
}

/*!
  @brief Class initialization method
  
  Creates the default stream manager
  @return void.
*/
+ (void) initialize;

/*!
  @brief   Accessor to the default stream manager created upon class initialization.
  
  SndStreamClients will usually connect to the default stream manager, unless
  the user wishes to explicitly create their own manager.  
  @return     Returns the default manager
*/
+ (SndStreamManager *) defaultStreamManager;

/*!
  @brief Creates and returns an autoreleased instance with the specified devices for output and input.
 
  The input and output device names must match those in the arrays returned by
  +driverNamesForOutput:.
  @param inputDeviceName Name of the device to stream audio from.
  @param outputDeviceName Name of the device to stream audio to.
*/
+ streamManagerOnDeviceForInput: (NSString *) inputDeviceName 
		deviceForOutput: (NSString *) outputDeviceName;

/*!
  @brief Returns an NSArray of NSStrings listing the sound drivers available.
  
  @param forOutputDevices YES to retrieve only the output devices, NO to retrieve only the input devices.
  The format of the names is dependent on the underlying operating system.
*/
+ (NSArray *) driverNamesForOutput: (BOOL) forOutputDevices;

/*!
  @brief Initialise a SndStreamManager instance on the default input and output devices.

  The actual devices chosen are platform dependent.
 */
- init;

/*!
  @brief Initialise a SndStreamManager instance on the named input and output devices.

  The input and output device names must match those in the arrays returned by
  +driverNamesForOutput:.
  @param inputDeviceName Name of the device to stream audio from.
  @param outputDeviceName Name of the device to stream audio to.
 */
- initOnDeviceForInput: (NSString *) inputDeviceName deviceForOutput: (NSString *) outputDeviceName;

/*!
  @brief Returns the index into the NSArray returned by +driverNamesForOutput: for the current driver.
  @param forOutputDevices YES to retrieve the assigned output device number, NO to retrieve the assigned input device number.
 */
- (int) assignedDriverIndexForOutput: (BOOL) forOutputDevices;

/*!
  @brief Assigns the sound hardware to be the driver referenced by the driver index number.
 
  @param driverIndex Must be a number that corresponds to the list of driver names returned by +driverNamesForOutput:
  @param forOutputDevices YES to retrieve the assigned output device number, NO to retrieve the assigned input device number.
 */
- (BOOL) setAssignedDriverToIndex: (unsigned int) driverIndex forOutput: (BOOL) forOutputDevices;

/*!
  @brief Returns an NSString of the current driver.
  @param forOutputDevices YES to retrieve the assigned output device name, NO to retrieve the assigned input device name.
 */
- (NSString *) assignedDriverNameForOutput: (BOOL) forOutputDevices;

/*!
  @brief Sets the number of sample frames used by the audio input and output hardware.
 
  The buffer size refers to the number of samples which are output to the DAC in one write operation 
  and input to the ADC in one read operation. Both input and output buffers are enforced to be the same.

  @param frames Sets the number of frames (channel independent) in the hardware buffer, if possible.
  @return Returns YES if able to change the hardware, NO if unable to change.
 */
- (BOOL) setHardwareBufferSize: (unsigned int) frames;

/*!
  @brief Returns the number of sample frames currently used by the audio input hardware.
  @return Returns 0 if unable to retrieve the size of the audio input buffer.
 */
- (long) inputBufferSize;

/*!
  @brief Returns the number of sample frames currently used by the audio output hardware.
  @return Returns 0 if unable to retrieve the size of the audio output buffer.
 */
- (long) outputBufferSize;

/*!
  @brief   Returns an NSString with description of SndStreamManager
  @return     Returns an NSString with description of SndStreamManager
 */
- (NSString *) description;

/*!
  @brief   Starts streaming.
  
  You should never need to call this. Streaming is started automatically
  when the first client connects to the manager.
*/
- (void) startStreaming;

/*!
  @brief   Stops streaming.
  
  You should never need to call this. Streaming is stopped automatically
  when the last client disconnects from the manager.
*/
- (void) stopStreaming;

/*!
  @brief   Adds an SndStreamClient to the manager's mixer.
  
  If the SndStreamClient is already a client of the mixer, it 
  is NOT added again. If the client is the first connected to
  the manager, the manager will automatically start streaming.
  @param      client The SndStreamClient instance to begin managing and mixing.
  @return     TRUE if client was successfully added, FALSE if the client is
  already registered, or the audio device couldn't start streaming.
*/
- (BOOL) addClient: (SndStreamClient *) client;

/*!
  @brief   Removes the SndStreamClient from the manager's mixer
  
  If the removed client was the last client connected to the
  manager, streaming will be automatically shut down.
  @param      client The client to be disconnected from the manager.
  @return     TRUE if the client was successfully removed.
*/
- (BOOL) removeClient: (SndStreamClient *) client;

/*!
  @brief Returns an NSArray of clients of the SndStreamManager instance.
  @return Return the clients in an immutable autoreleased array.
 */
- (NSArray *) clients;

/*!
  @brief   Passes new input and output buffers from the underlying API to the
  mixer.
  
  Do not call this method - it is part of the audio callback handler.
  @param      bufferTime Time in seconds when the buffer will play.
  @param      inB The input buffer holding samples recorded from the ADC.
  @param      outB The output buffer holding samples to be played.
*/
- (void) processStreamAtTime: (double) bufferTime
                       input: (SndAudioBuffer *) inB
                      output: (SndAudioBuffer *) outB;

/*!
  @brief   Sets the format to be used during streaming
  
  Do not call this method - it is called as part of the start-streaming
  process. The stream format used is the native format coming up from 
  the devices below.
  @param      newFormat A SndFormat structure.
  @return     Returns self.
*/
- setFormat: (SndFormat) newFormat;

/*!
  @brief Returns the format to be used during streaming.
  @return   Returns a SndFormat structure.
 */
- (SndFormat) format;

/*!
  @brief   Return the current time as understood by the SndStreamManager.
  
  The current time indicates the time at the start of the next buffer to be mixed and then played. 
  This is about as close to actual playing time as can be calculated. The actual time of play will 
  depend on the operating system dependent latency between receiving a buffer to play and actually
  sending it to the DAC.
  @return     nowTime as a double floating point value of time in seconds.
*/
- (double) nowTime;

/*!
  @brief   Mixer member accessor method
  @return     The internal SndStreamMixer
*/
- (SndStreamMixer *) mixer;

/*!
  @brief   indicates whether streaming is happening (active) 
  
  
  @return     TRUE if streaming is active
*/
- (BOOL) isActive;

/*!
  @return The streaming sampling rate.
*/
- (double) samplingRate;

/*!
  @brief Resets the global stream time to originTimeInSeconds
  @param originTimeInSeconds New origin time, in seconds.
  
  The new origin time is propagated to the mixer, and thus to the stream clients.
*/
- (void) resetTime: (double) originTimeInSeconds;

/*!
  @brief   Sends messages from any thread to any object in the main thread
  
  This method was introduced to allow easy delegate messaging from
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
  @param      sel SEL the selector to be sent, eg \@selector(description:withObject:)
  @param      arg1 the first argument in the selector
  @param      arg2 the second argument in the selector
*/
- (void) sendMessageInMainThreadToTarget: (id) target sel: (SEL) sel arg1: (id) arg1 arg2: (id) arg2;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
