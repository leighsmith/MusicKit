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
#import <sndfile.h>

@class SndAudioBuffer;
@class SndAudioBufferQueue;

/*!
 @enum SndRecorderParam
 @abstract Parameter keys
 @constant recorder_kStartTriggerThreshold  Start trigger threshold
 @constant recorder_kRecordFile             Record filename              
 @constant recorder_kNumParams              Number of parameters
*/
enum SndRecorderParam {
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
    /*! @var writingQueue A queue of buffers copied from those received by processReplacingInputBuffer: */
    SndAudioBufferQueue *writingQueue;
    /*! @var fileFormat The format of the data to be stored in the file. */
    SndFormat fileFormat;
    /*! @var isRecording Indicates if recording is currently active. */
    BOOL            isRecording; 
    /*! @var framesRecorded Number of sample frames written */
    long            framesRecorded;  
    /*! @var recordFile */
    SNDFILE         *recordFile;
    /*! @var recordFileName */
    NSString       *recordFileName;
    /*! @var startedRecording Indicates if a minimum threshold or time trigger has passed and recording has begun. */
    BOOL            startedRecording;
    /*! @var startTriggerThreshold A floating point threshold to begin the recording of sound. */
    float           startTriggerThreshold;
    /*! @var stopSignal */
    BOOL            stopSignal;
}

/*!
    @method     isRecording    
    @abstract   Returns whether the receiver is currently recording.
    @discussion 
    @result     TRUE if currently recording
*/
- (BOOL) isRecording;

/*!
  @method prepareToRecordForDuration:
  @abstract Sets the buffer used for recording.
 */
- (BOOL) prepareToRecordForDuration: (double) recordDuration;

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
               withDataFormat: (SndSampleFormat) dataFormat
                 channelCount: (int) chanChan
                 samplingRate: (int) samRate;

/*!
    @method     stopRecording
    @abstract 
    @discussion 
    @result     self
*/
- stopRecording;

/*!
    @method     stopRecordingWait:
    @abstract 
    @discussion TODO remove this, redundant, always wait until the queue clears.
    @result     
*/
- stopRecordingWait: (BOOL) wait;

/*!
    @method     framesRecorded
    @abstract Returns the number of frames recorded.
    @discussion 
    @result     
*/
- (long) framesRecorded;

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

@end

////////////////////////////////////////////////////////////////////////////////

#endif
