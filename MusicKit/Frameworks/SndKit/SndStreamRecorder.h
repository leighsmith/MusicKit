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

@interface SndStreamRecorder : SndStreamClient {

  SndAudioBuffer *recordBuffer;
  short          *conversionBuffer;
  long  position;
  BOOL  isRecording; 
  id    delegate;
  long bytesRecorded;
  
  FILE *recordFile;
  NSString *recordFileName;
}

/*!
    @method streamRecorder
    @abstract Factory method
    @discussion 
    @result An SndStreamRecorder
*/
+ streamRecorder;

/*!
    @method init
    @abstract Initializor
    @discussion 
    @result self
*/
- init;

/*!
    @method dealloc
    @abstract Destructor
    @discussion 
*/
- (void) dealloc;

/*!
    @method description
    @abstract 
    @discussion 
    @result NSString with description
*/
- (NSString*) description;

/*!
    @method prepareToRecordForDuration: 
    @abstract 
    @discussion 
    @param (double) time
    @result Boolean indicating success
*/
- (BOOL) prepareToRecordForDuration: (double) time;

/*!
    @method startRecording 
    @abstract 
    @discussion 
    @param (double) time
    @result Boolean indicating success
*/
- (BOOL) startRecording;

/*!
    @method startRecordingToFile:
    @abstract 
    @discussion 
    @param (NSString*) filename
    @result Boolean indicating success
*/
- (BOOL) startRecordingToFile: (NSString*) filename;

/*!
    @method setUpRecordFile:
    @abstract 
    @discussion 
    @param (NSString*) filename
    @result Boolean indicating success
*/
- (BOOL) setUpRecordFile: (NSString*) filename;

/*!
    @method closeRecordFile 
    @abstract 
    @discussion 
    @result Boolean indicating success
*/
- (BOOL) closeRecordFile;

/*!
    @method stopRecording
    @abstract 
    @discussion 
    @result self.
*/
- stopRecording;

@end

@interface SndStreamRecorderDelegate : NSObject

/*!
    @method didStartRecording:sender
    @abstract 
    @discussion Protocol method for SndStreamRecorderDelegate
    @result self.
*/
- didStartRecording:  sender;

/*!
    @method didFinishRecording:sender
    @abstract 
    @discussion Protocol method for SndStreamRecorderDelegate
    @result self
*/
- didFinishRecording: sender;
@end

#endif
