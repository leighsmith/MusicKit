//
//  SndAudioProcessorRecorder.h
//  SndKit
//
//  Created by skot on Wed Dec 05 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"

@class SndAudioBuffer;

@interface SndAudioProcessorRecorder : SndAudioProcessor {
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
  
  BOOL            bStartTrigger;
  float           fStartTriggerThreshold;
}

- init;
- (void) dealloc;
- (BOOL) isRecording;

- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB
                        outputBuffer: (SndAudioBuffer*) outB;
                        
- (BOOL) prepareToRecordForDuration: (double) time withFormat: (SndSoundStruct*) format;
- (BOOL) startRecording;

- (BOOL) setUpRecordFile: (NSString*) filename withFormat: (SndSoundStruct*) format;
- (BOOL) startRecordingToFile: (NSString*) filename withFormat: (SndSoundStruct*) format;


/*!
    @method   closeRecordFile 
    @abstract 
    @discussion 
    @result     Boolean indicating success
*/
- (BOOL) closeRecordFile;

/*!
    @method   prepareToRecordForDuration: 
    @abstract 
    @discussion 
    @param      time
    @result     Boolean indicating success
*/
- (BOOL) prepareToRecordForDuration: (double) time withFormat: (SndSoundStruct*) format;

/*!
    @method   stopRecording
    @abstract 
    @discussion 
    @result     self.
*/
- stopRecording;
- stopRecordingWait: (BOOL) bWait disconnectFromStream: (BOOL) bDisconnectFromStream;

- (void) streamToDiskData: (void*) recData length: (long) bytesToRecord;

- setRecordBuffer: (SndAudioBuffer*) buffer;
- (long) bytesRecorded;

- primeStartTrigger;
- setStartTriggerThreshold: (float) f;

@end
