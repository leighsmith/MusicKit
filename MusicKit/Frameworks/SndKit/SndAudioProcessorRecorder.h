////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    See the headerdoc below.
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
 @constant recorder_StartTriggerThreshold  Start trigger threshold
 @constant recorder_RecordFile             Record filename
 @constant recorder_NumParams              Number of parameters
*/
enum SndRecorderParam {
    recorder_StartTriggerThreshold = 0,
    recorder_RecordFile            = 1,
    recorder_NumParams             = 2
};

//////////////////////////////////////////////////////////////////////////////

/*!
  @class SndAudioProcessorRecorder
  @abstract Records the FX audio stream to disk.
  @discussion A threshold can be set to prevent silence being recorded prior to the sound. An automatic shutoff
              after a specifiable period of silence is also possible.
*/
@interface SndAudioProcessorRecorder : SndAudioProcessor {

@protected
    /*! @var writingQueue A queue of buffers copied from those received by processReplacingInputBuffer: ready for writing. */
    SndAudioBufferQueue *writingQueue;
    /*! @var fileFormat The format of the data to be stored in the file. */
    SndFormat fileFormat;
    /*! @var isRecording Indicates if recording is currently active. */
    BOOL isRecording; 
    /*! @var framesRecorded Number of sample frames written */
    unsigned long framesRecorded;  
    /*! @var recordFile The libsndfile handle referring to the open file. NULL if not open. */
    SNDFILE *recordFile;
    /*! @var recordFileName Full pathname of the file being or about to be written. */
    NSString *recordFileName;
    /*! @var startedRecording Indicates if a minimum threshold or time trigger has passed and recording has begun. */
    BOOL startedRecording;
    /*! @var startTriggerThreshold A normalised absolute value threshold to begin the recording of sound. */
    float startTriggerThreshold;
    /*! @var stopSignal A boolean variable to indicate that recording should stop and the file should be closed. */
    BOOL stopSignal;
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
  @method setUpRecordFile:withFormat:
  @abstract Sets up recording of the file in the given format.
  @discussion This method is not normally called, use startRecordingToFile:withDataFormat:channelCount:samplingRate:
	      instead. This method, setUpRecordFile:withFormat: is defined here in order to facilitate overriding
              in subclasses.
  @result     Returns YES if able to open the file for writing, NO if there is an error.
 */
- (BOOL) setUpRecordFile: (NSString *) filename
	      withFormat: (SndFormat) format;

/*!
    @method     startRecordingToFile:withDataFormat:channelCount:samplingRate:
    @abstract   Begins recording to the given format in the given format.
    @discussion 
    @result     Returns YES if able to open the file for writing, NO if there is an error.
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
    @method     setStartTriggerThreshold:
    @abstract 
    @discussion 
*/
- (void) setStartTriggerThreshold: (float) f;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
