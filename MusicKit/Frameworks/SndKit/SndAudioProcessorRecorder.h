////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorRecorder.h
//  SndKit
//
//  Created by skot on Wed Dec 05 2001. <skot@tomandandy.com>
//  Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and 
//  non-commercial purposes so long as the author attribution and copyright 
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"

@class SndAudioBuffer;

/*!
    @class      SndAudioProcessorRecorder
    @abstract   Records the FX audio stream to disk.
    @discussion To come
*/
@interface SndAudioProcessorRecorder : SndAudioProcessor {

@protected
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
/*! @var bStartTrigger */
  BOOL            bStartTrigger;
/*! @var fStartTriggerThreshold */
  float           fStartTriggerThreshold;
}

/*!
    @method     init   
    @abstract 
    @discussion 
    @result     self
*/
- init;
/*!
    @method     dealloc   
    @abstract 
    @discussion 
*/
- (void) dealloc;
/*!
    @method     isRecording    
    @abstract 
    @discussion 
    @result     TRUE if currently recording
*/
- (BOOL) isRecording;

/*!
    @method     processReplacingInputBuffer:outputBuffer:
    @abstract 
    @discussion 
    @result     See SndAudioProcessor.
*/
- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB
                        outputBuffer: (SndAudioBuffer*) outB;                        
/*!
    @method     prepareToRecordForDuration:withFormat:
    @abstract 
    @discussion 
    @result     
*/
- (BOOL) prepareToRecordForDuration: (double) time withFormat: (SndSoundStruct*) format;
/*!
    @method     startRecording
    @abstract 
    @discussion 
    @result     TRUE if recording started ok
*/
- (BOOL) startRecording;
/*!
    @method     startRecordingToFile:withFormat:
    @abstract 
    @discussion 
    @result     
*/
- (BOOL) startRecordingToFile: (NSString*) filename withFormat: (SndSoundStruct*) format;
/*!
    @method     closeRecordFile 
    @abstract 
    @discussion 
    @result     Boolean indicating success
*/
- (BOOL) closeRecordFile;
/*!
    @method     prepareToRecordForDuration: 
    @abstract 
    @discussion 
    @param      time
    @result     Boolean indicating success
*/
- (BOOL) prepareToRecordForDuration: (double) time withFormat: (SndSoundStruct*) format;
/*!
    @method     stopRecording
    @abstract 
    @discussion 
    @result     self
*/
- stopRecording;
/*!
    @method     stopRecordingWait:disconnectFromStream:
    @abstract 
    @discussion 
    @result     
*/
- stopRecordingWait: (BOOL) bWait disconnectFromStream: (BOOL) bDisconnectFromStream;
/*!
    @method     setRecordBuffer:
    @abstract 
    @discussion 
    @result     
*/
- setRecordBuffer: (SndAudioBuffer*) buffer;
/*!
    @method     bytesRecorded
    @abstract 
    @discussion 
    @result     
*/
- (long) bytesRecorded;
/*!
    @method     primeStartTrigger
    @abstract 
    @discussion 
    @result     
*/
- primeStartTrigger;
/*!
    @method     setStartTriggerThreshold:
    @abstract 
    @discussion 
    @result     
*/
- setStartTriggerThreshold: (float) f;
/*! 
    @method     streamToDiskData:length:
    @abstract    
    @discussion 
    @param      recData Raw bytes pointer to data to be written to disk.
    @param      bytesToRecord Count of bytes to write to disk
*/
- (void) streamToDiskData: (void*) recData length: (long) bytesToRecord;
/*! 
    @method     setUpRecordFile:withFormat:
    @abstract   Sets up the record file amd 
    @discussion For internal use - you shouldn't have to call this.
    @param      filename
    @param      format
    @result     Boolean indicating success
*/
- (BOOL) setUpRecordFile: (NSString*) filename withFormat: (SndSoundStruct*) format;

@end

////////////////////////////////////////////////////////////////////////////////

