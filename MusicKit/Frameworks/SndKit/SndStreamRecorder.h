//
//  SndStreamRecorder.h
//  SndKit
//
//  Created by skot on Thu Apr 05 2001.
//  Copyright (c) 2001 __CompanyName__. All rights reserved.
//
#ifndef __SNDSTREAMRECORDER_H__
#define __SNDSTREAMRECORDER_H__

#import <Foundation/Foundation.h>

@class SndAudioBuffer;
@class SndStreamClient;

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

/*! @var recordBuffer */
  SndAudioBuffer *recordBuffer;
/*! @var conversionBuffer */
  short          *conversionBuffer;
/*! @var position */
  long            position;
/*! @var isRecording */
  BOOL            isRecording; 
/*! @var bytesrecorded */
  long            bytesRecorded;  
/*! @var recordFile */
  FILE           *recordFile;
/*! @var recordFileName */
  NSString       *recordFileName;
}

/*!
    @method   streamRecorder
    @abstract   Factory method
    @discussion 
    @result     An SndStreamRecorder
*/
+ streamRecorder;

/*!
    @method   init
    @abstract   Initializor
    @discussion 
    @result     self
*/
- init;

/*!
    @method   dealloc
    @abstract   Destructor
    @discussion 
*/
- (void) dealloc;

/*!
    @method   description
    @abstract 
    @result     NSString with description
*/
- (NSString*) description;

/*!
    @method   prepareToRecordForDuration: 
    @abstract 
    @discussion 
    @param      time
    @result     Boolean indicating success
*/
- (BOOL) prepareToRecordForDuration: (double) time;

/*!
    @method   startRecording 
    @abstract 
    @discussion 
    @param      time
    @result     Boolean indicating success
*/
- (BOOL) startRecording;

/*!
    @method   startRecordingToFile:
    @abstract 
    @discussion 
    @param      filename
    @result     Boolean indicating success
*/
- (BOOL) startRecordingToFile: (NSString*) filename;

/*!
    @method     setUpRecordFile:
    @abstract 
    @discussion 
    @param      filename
    @result     Boolean indicating success
*/
- (BOOL) setUpRecordFile: (NSString*) filename;

/*!
    @method   closeRecordFile 
    @abstract 
    @discussion 
    @result     Boolean indicating success
*/
- (BOOL) closeRecordFile;

/*!
    @method   stopRecording
    @abstract 
    @discussion 
    @result     self.
*/
- stopRecording;

@end

/*!
    @class      SndStreamRecorderDelegate
    @abstract   Informal protocol for an SndStreamRecorder delegate
    @discussion To come.
*/
@interface SndStreamRecorderDelegate : SndStreamClientDelegate

/*!
    @method   didStartRecording:sender
    @abstract   Message sent to delegate just before the recording thread enters its
                processBuffers loop, indicating it is waiting for the first buffer to
                arrive.
    @discussion Protocol method for SndStreamRecorderDelegate
    @result     self.
*/
- didStartRecording:  sender;

/*!
    @method   didFinishRecording:sender
    @abstract   Message sent to delegate when recording has completed. This is caused
                by either a user event stopping streaming to disk, or the recording
                thread reaching the limit of a record-to-memory buffer, and is sent 
                after the final bytes have been delivered to their destination.
    @discussion Protocol method for SndStreamRecorderDelegate
    @result     self
*/
- didFinishRecording: sender;
@end

#endif
