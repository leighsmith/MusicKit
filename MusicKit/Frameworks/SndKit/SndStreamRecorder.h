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

#ifndef __SNDSTREAMRECORDER_H__
#define __SNDSTREAMRECORDER_H__

#import <Foundation/Foundation.h>
#import "SndStreamClient.h"

@class SndAudioBuffer;
@class SndAudioProcessorRecorder;

/*!
  @class SndStreamRecorder
  @brief Records incoming audio to a sound file.
    
    ATTENTION!!!
      Presumptions made to get this class off the ground quickly: The incoming
      stream is made of 32-bit floats, and the saved file is made of 16-bit ints!

    BIG TODO: general purpose format stuff 

      Using the client currently requires an explicit connect-to-stream manager
      call:
 
    SndStreamRecorder *rec = [SndStreamRecorder streamRecorder];
    [[SndStreamManager defaultStreamManager] addClient: rec];
 
    then either...
 
    [rec startRecordingToFile: "/tmp/incomingsound.snd"];
    (time passes...)
    [rec stopRecording];
 
    or:

    [rec prepareForRecording: 10.5]; //record for 10.5 seonds
    [rec startRecording];

    TODO:
    - Obviously the big todo here is to get general purpose stream and file
      or format conversion happening!
    - Also, output is currently buffered + written (in stream-to-file mode) in
      44100-frame chunks; this should be more general.
    - delegate call-backs to say recording has started / ended, what incoming
      levels are like, etc  
*/
@interface SndStreamRecorder : SndStreamClient 
{
    /*! A stream recording FX processor */
    SndAudioProcessorRecorder *recorder;
}

/*! 
  @brief   Initialiser
  @return     self
*/
- init;

/*! 
  @return     NSString with description
*/
- (NSString*) description;

/*! 
  @return     Boolean indicating success
*/
- (BOOL) startRecording;

/*! 
  @brief   Starts the record-to-disk routines.
  @param      filename
  @return     Boolean indicating success
*/
- (BOOL) startRecordingToFile: (NSString *) filename;

/*! 
  @brief   Stops the recording to file.

  The recorder instance will wait for intermediate buffers to 
  be flushed to disk. The recorder will then disconnect from the stream.
*/
- (void) stopRecording;

/*! 
  @brief   Stops the recording to file. Optionally stay connected to the stream.

  For internal use only.
  @param      bDisconnectFromStream TRUE if you want the client to disconnect
  from the stream manager, FALSE otherwise. Leaving the client
  connected ensures the audio streams stay open, and minimizes
  start-recording set-up time. Downside is a slight CPU hit
  from the background streaming going on. 
*/
- (void) stopRecordingAndDisconnectFromStream: (BOOL) bDisconnectFromStream;

@end

/*! 
 @brief Protocol for an SndStreamRecorder delegate.
*/
@protocol SndStreamRecorderDelegate <SndStreamClientDelegate>

/*! 
  @brief   Message sent to delegate just before the recording thread enters
  its processBuffers loop, indicating it is waiting for the first 
  buffer to arrive.
    
  Protocol method for SndStreamRecorderDelegate
  @return     self.
*/
- didStartRecording: sender;

/*! 
  @brief   Message sent to delegate when recording has completed. 
    
  This is caused by either a user event stopping streaming to disk, or the 
  recording thread reaching the limit of a record-to-memory buffer, 
  and is sent after the final bytes have been delivered to their 
  destination.
    
  Protocol method for SndStreamRecorderDelegate
  @return     self
*/
- didFinishRecording: sender;

@end

////////////////////////////////////////////////////////////////////////////////
#endif
