////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
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

#ifndef __SNDKIT_SNDAUDIOPROCESSORRECORDER_H__
#define __SNDKIT_SNDAUDIOPROCESSORRECORDER_H__

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"

@class SndAudioBuffer;

/*!
 @enum SndRecorderParam
 @abstract Parameter keys
 @constant recorder_kStartTriggerThreshold  Start trigger threshold
 @constant recorder_kRecordFile             Record filename              
 @constant recorder_kNumParams              Number of parameters
*/
enum {
  recorder_kStartTriggerThreshold = 0,
  recorder_kRecordFile            = 1,
  recorder_kNumParams             = 2
};

//////////////////////////////////////////////////////////////////////////////

/*!
@class SndAudioProcessorRecorder
@abstract Records the FX audio stream to disk.
@discussion To come.
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
/*! @var stopSignal */
  BOOL            stopSignal;
}

/*!
    @method     isRecording    
    @abstract 
    @discussion 
    @result     TRUE if currently recording
*/
- (BOOL) isRecording;
/*!
    @method     prepareToRecordForDuration:withFormat:
    @abstract 
    @discussion 
    @result     BOOL indicating success when preparing for recording
*/
- (BOOL) prepareToRecordForDuration: (double) time
                     withDataFormat: (int) dataFormat
                       channelCount: (int) chanChan
                       samplingRate: (int) samRate;
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
- (BOOL) startRecordingToFile: (NSString*) filename
               withDataFormat: (int) dataFormat
                 channelCount: (int) chanChan
                 samplingRate: (int) samRate;
/*!
    @method     closeRecordFile 
    @abstract 
    @discussion 
    @result     Boolean indicating success
*/
- (BOOL) closeRecordFile;
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
- (BOOL) setUpRecordFile: (NSString*) filename
          withDataFormat: (int) dataFormat
            channelCount: (int) chanChan
            samplingRate: (int) samRate;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
