////////////////////////////////////////////////////////////////////////////////
//
//  SndStreamRecorder.h
//  SndKit
//
//  Created by skot on Thu Apr 05 2001. <
//  Copyright (c) 2001 tomandandy.com All rights reserved.
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
    @abstract 
    @discussion
    
    ATTENTION!!!
      Presumptions made to get this class off the ground quickly: The incoming
      stream is made of 32-bit floats, and the saved file is made of 16-bit ints!

    BIG TODO: general purpose format stuff 

      Using the client currently requires an explicit connect-to-stream manager
      call:
 
    SndStreamRecorder *rec = [SndStreamrRecorder streamRecorder];
    [[SndStreamManager defaultStreamManager] addClient: rec];
 
    then either...
 
    [rec startRecordingToFile: "/tmp/incomingsound.snd"];
    (time passes)
    [rec stopRecording];
 
    or:

    [rec prepareForRecording: 10.5]; //record for 10.5 seonds
    [rec startrRecording];

    TODO:
    - Obviously the big todo here is to get general purpose stream and file
      or format conversion happening!
    - Also, output is currently buffered + written (in stream-to-file mode) in
      44100-frame chunks; this should be more general.
    - delegate call-backs to say recording has started / ended, what incoming
      levels are like, etc  
*/
@interface SndStreamRecorder : SndStreamClient {
/*! @var recorder A stream recording FX processor*/
  SndAudioProcessorRecorder *recorder;
}
/*! 
    @method     init
    @abstract   Initializor
    @discussion 
    @result     self
*/
- init;
/*! 
    @method     dealloc
    @abstract   Destructor
    @discussion 
*/
- (void) dealloc;
/*! 
    @method     description
    @abstract   
    @result     NSString with description
*/
- (NSString*) description;
/*! 
    @method     startRecording 
    @abstract 
    @discussion 
    @param      time
    @result     Boolean indicating success
*/
- (BOOL) startRecording;
/*! 
    @method     startRecordingToFile:
    @abstract   Starts the record-to-disk routines.
    @discussion 
    @param      filename
    @result     Boolean indicating success
*/
- (BOOL) startRecordingToFile: (NSString*) filename;
/*! 
    @method     stopRecording
    @abstract   Sets up the record file amd 
    @discussion For internal use - you shouldn't have to call this.
    @result     Boolean indicating success
*/
- stopRecording;
/*! 
    @method     stopRecordingWait:disconnectFromStream:
    @abstract   Sets up the record file amd 
    @discussion For internal use - you shouldn't have to call this.
    @param      bWait TRUE if the recorder should wait for intermediate buffers to 
                      be flushed to disk. FALSE if you want immediate cessation of 
                      recording.
    @param      bDisconnectFromStream TRUE if you want the client to disconnect
                      from the stream manager, FALSE otherwise. Leaving the client
                      connected ensures the audio streams stay open, and minimizes
                      start-recording set-up time. Downside is a slight CPU hit
                      from the background streaming going on. 
    @result     Boolean indicating success
*/
- stopRecordingWait: (BOOL) bWait disconnectFromStream: (BOOL) bDisconnectFromStream;

@end

/*! 
    @class      SndStreamRecorderDelegate
    @abstract   Informal protocol for an SndStreamRecorder delegate
    @discussion To come.
*/
@interface SndStreamRecorderDelegate : SndStreamClientDelegate
/*! 
    @method   didStartRecording:sender
    @abstract   Message sent to delegate just before the recording thread enters
                its processBuffers loop, indicating it is waiting for the first 
                buffer to arrive.
    @discussion Protocol method for SndStreamRecorderDelegate
    @result     self.
*/
- didStartRecording:  sender;
/*! 
    @method     didFinishRecording:sender
    @abstract   Message sent to delegate when recording has completed. This is 
                caused by either a user event stopping streaming to disk, or the 
                recording thread reaching the limit of a record-to-memory buffer, 
                and is sent after the final bytes have been delivered to their 
                destination.
    @discussion Protocol method for SndStreamRecorderDelegate
    @result     self
*/
- didFinishRecording: sender;

@end

////////////////////////////////////////////////////////////////////////////////


#endif
