////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    See the description in SndAudioProcessorRecorder.h 
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

#import "SndFunctions.h"
#import "SndAudioBuffer.h"
#import "SndAudioProcessorRecorder.h"
#import "SndStreamManager.h"

////////////////////////////////////////////////////////////////////////////////
// Debug defines
////////////////////////////////////////////////////////////////////////////////

#define SNDAUDIOPROCRECORDER_DEBUG 0
#define BUFFER_DURATION 2.0 // Number of seconds the buffer will hold before writing to disk

@implementation SndAudioProcessorRecorder

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
    self = [super initWithParamCount: recorder_kNumParams name: @"Recorder"];
    if(self != nil) {
	startTriggerThreshold = 0.002f;
	isRecording = NO;
	fileFormat.dataFormat = SND_FORMAT_LINEAR_16; // default format
	fileFormat.channelCount = 2;
	fileFormat.sampleRate = 44100.0;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
    if (recordBuffer != nil)
	[recordBuffer release];
    [super dealloc];
}

- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ %srecording, %ld frames recorded\n",
	[super description], isRecording ? "" : "not ", framesRecorded];
}

////////////////////////////////////////////////////////////////////////////////
// isRecording
////////////////////////////////////////////////////////////////////////////////

- (BOOL) isRecording
{
    return isRecording;
}

////////////////////////////////////////////////////////////////////////////////
// framesRecorded
////////////////////////////////////////////////////////////////////////////////

- (long) framesRecorded
{
    return framesRecorded;
}

////////////////////////////////////////////////////////////////////////////////
// prepareToRecordForDuration:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) prepareToRecordForDuration: (double) recordDuration
{
    if (!isRecording) {
	SndFormat managerFormat = [[SndStreamManager defaultStreamManager] format];

	// Make the buffer the same format as the SndStreamManager but longer.
	managerFormat.frameCount = managerFormat.sampleRate * recordDuration;
	[recordBuffer release];
	recordBuffer = [[SndAudioBuffer audioBufferWithFormat: managerFormat] retain];
#if SNDAUDIOPROCRECORDER_DEBUG  
	NSLog(@"recordBuffer %@\n", recordBuffer);
#endif
	return recordBuffer != nil;
    }
#if SNDAUDIOPROCRECORDER_DEBUG  
    NSLog(@"SndAudioProcessorRecorder::prepareToRecordForDuration - Error: already recording!\n");
#endif
    return NO;
}

////////////////////////////////////////////////////////////////////////////////
// writeFileHeaderWithFormat:toFileHandle:ofLength:
// Writes out the file format, we write out a minimal Microsoft RIFF (*.wav) file
// TODO This should be replaced with our modernised file writing routines if the underlying
// file I/O library is flexible enough to allow rewriting the size at the conclusion of the file.
////////////////////////////////////////////////////////////////////////////////

- (void) writeFileHeaderWithFormat: (SndFormat) format
		     toFileHandle: (FILE *) f
			 ofLength: (unsigned long) dataLengthInBytes
{
    unsigned long bytesPerSecond;
    unsigned short frameSize;
   // file format 1 = linear wav
   // format.dataFormat == SND_FORMAT_LINEAR_16 ? 1 : format == SND_FORMAT_FLOAT ? dunno : 1 
    unsigned short wavFormatCode = 1;
    
    fwrite("RIFF", 4, 1, f);  
    fwrite(SndSwap_Convert32BitNative2LittleEndian(dataLengthInBytes + 38), 4, 1, f); // file length
    fwrite("WAVE", 4, 1, f);  
    fwrite("fmt ", 4, 1, f);  
    fwrite(SndSwap_Convert32BitNative2LittleEndian(18), 4, 1, f);                    // chunk length
    fwrite(SndSwap_Convert16BitNative2LittleEndian(wavFormatCode),  2, 1, f);        // data format
    fwrite(SndSwap_Convert16BitNative2LittleEndian(format.channelCount),  2, 1, f);  // channels
    fwrite(SndSwap_Convert32BitNative2LittleEndian(format.sampleRate), 4, 1, f);     // chunk length
    bytesPerSecond = format.sampleRate * format.channelCount * sizeof(short);
    fwrite(SndSwap_Convert32BitNative2LittleEndian(bytesPerSecond), 4, 1, f);        // bytes per second
    frameSize = format.channelCount * sizeof(short);
    fwrite(SndSwap_Convert16BitNative2LittleEndian(frameSize),  2, 1, f);            // frame size
    fwrite(SndSwap_Convert16BitNative2LittleEndian(16),  2, 1, f);                   // bit resolution
    fwrite(SndSwap_Convert16BitNative2LittleEndian(0),  2, 1, f);                    // extra bytes
    fwrite("data", 4, 1, f);  
    fwrite(SndSwap_Convert32BitNative2LittleEndian(dataLengthInBytes), 4, 1, f);     // data chunk length
}

////////////////////////////////////////////////////////////////////////////////
// setUpRecordFile:withFormat:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) setUpRecordFile: (NSString *) filename
	      withFormat: (SndFormat) format
{
    SF_INFO sfinfo;
    
    sfinfo.samplerate = (int) format.sampleRate;
    sfinfo.channels = format.channelCount;
    sfinfo.format = SndDataFormatToSndFileEncoding([[filename pathExtension] cString], format.dataFormat);
    // comment       = sound->info;
    
    if (!sf_format_check(&sfinfo)) {
	NSLog(@"SndAudioProcessorRecorder -setupRecordFile: Bad output format 0x%x\n", sfinfo.format);
	return NO;
    }
    
    if((recordFile = sf_open([filename fileSystemRepresentation], SFM_WRITE, &sfinfo)) != NULL) {
	[recordFileName release];
	recordFileName = [filename copy];
	return YES;
    }
    else {
	NSLog(@"SndAudioProcessorRecorder -setupRecordFile Error opening file '%@' for recording.\n", filename);
	return NO;
    }
}

////////////////////////////////////////////////////////////////////////////////
// closeRecordFile:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) closeRecordFile
{
    sf_close(recordFile);
    recordFile = NULL;
    framesRecorded = 0;
    stopSignal = NO;
    isRecording = NO; // Since we've closed the file, we halt all recording.
    // [fileWriteLock unlock];
    
#if SNDAUDIOPROCRECORDER_DEBUG
    NSLog(@"SndAudioProcessor::closeRecordFile - closed\n");
#endif
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
// startRecording
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startRecording
{  
    if (recordBuffer == nil) {
#if SNDAUDIOPROCRECORDER_DEBUG  
	NSLog(@"SndAudioProcessorRecorder::startRecording - Error: recordBuffer is nil.\n");
#endif
    }
    else if (isRecording) {  
#if SNDAUDIOPROCRECORDER_DEBUG  
	NSLog(@"SndAudioProcessorRecorder::startRecording - Error: already recording!\n");
#endif
    }
    else {
	recordPosition = 0;
	isRecording = YES;	
    }
    return isRecording;
}

////////////////////////////////////////////////////////////////////////////////
// startRecordingToFile:
//
// Set up an snd file for storage.
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startRecordingToFile: (NSString *) filename
               withDataFormat: (SndSampleFormat) dataFormat
                 channelCount: (int) channelCount
                 samplingRate: (int) samplingRate
{
    // fileFormat.dataFormat = dataFormat; // TODO disabled
    fileFormat.channelCount = channelCount;
    fileFormat.sampleRate = samplingRate;
    
    // Create a temporary buffer of 1 second duration for buffering before writing to disk.
    if (![self prepareToRecordForDuration: BUFFER_DURATION]) {
	NSLog(@"SndAudioProcessorRecorder::startRecordingToFile - Error in prepareToRecordForDuration.\n");
    }
    else if (![self setUpRecordFile: filename withFormat: fileFormat]) {
	NSLog(@"SndAudioProcessorRecorder::startRecordingToFile - Error in setUpRecordFile\n");
    }
    else {
	// [fileWriteLock lock]
	recordPosition = 0;
	framesRecorded = 0;
	stopSignal = NO;
	[self primeStartTrigger];
	isRecording = YES;
	// [fileWriteLock unlock];
    }
    return isRecording;
}

////////////////////////////////////////////////////////////////////////////////
// stopRecording
////////////////////////////////////////////////////////////////////////////////

- stopRecording
{
    stopSignal = YES; // signal to recording thread that we wanna stop.
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// stopRecordingWait:
////////////////////////////////////////////////////////////////////////////////

- stopRecordingWait: (BOOL) bWait disconnectFromStream: (BOOL) bDisconnectFromStream
{
    float timeWaiting = 0.0;
    stopSignal = YES; // signal to recording thread that we want to stop.
    
    if (bWait) {
	while (recordFile != NULL && timeWaiting < 3.0) {
	    [NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.1]];
	    timeWaiting += 0.1;
	}
    }
#if SNDAUDIOPROCRECORDER_DEBUG
    NSLog(@"SndAudioProcessor::stopRecordingWait:disconnectFromStream: \n");
#endif
    
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// writeToFileBuffer
////////////////////////////////////////////////////////////////////////////////

- (void) writeToFileBuffer: (SndAudioBuffer *) saveBuffer length: (long) bytesToRecord
{
    int error;
    SndFormat recordBufferFormat = [saveBuffer format];
    long framesToSave = SndBytesToFrames(bytesToRecord, recordBufferFormat.channelCount, recordBufferFormat.dataFormat);
    
    // if bytesToRecord is less than the buffer length, we modify the frameCount.
    recordBufferFormat.frameCount = framesToSave;
    
    error = SndWriteSampleData(recordFile, [saveBuffer bytes], recordBufferFormat);
    if(error != SND_ERR_NONE)
	NSLog(@"Problem writing buffer\n");
    framesRecorded += framesToSave;    
}

////////////////////////////////////////////////////////////////////////////////
// primeStartTrigger
////////////////////////////////////////////////////////////////////////////////

- primeStartTrigger
{
    startedRecording = NO;
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// setStartTriggerThreshold:
////////////////////////////////////////////////////////////////////////////////

- setStartTriggerThreshold: (float) f
{
    startTriggerThreshold = f;
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// paramObjectForIndex:
////////////////////////////////////////////////////////////////////////////////

- (id) paramObjectForIndex: (const int) i
{
    id obj;
    
    switch (i) {
	case recorder_kRecordFile:
	    obj = (recordFileName != nil) ? recordFileName : @"";
	    break;
	default:
	    obj = [super paramObjectForIndex: i];
    }
    return obj;
}

////////////////////////////////////////////////////////////////////////////////
// paramValue:
////////////////////////////////////////////////////////////////////////////////

- (float) paramValue: (const int) index
{
    float f = 0.0f;
    switch (index) {
	case recorder_kStartTriggerThreshold: 
	    f = startTriggerThreshold; 
	    break;
    }
    return f;
}

////////////////////////////////////////////////////////////////////////////////
// paramValue:
////////////////////////////////////////////////////////////////////////////////

- (NSString*) paramName: (const int) index
{
    NSString *r = nil;
    switch (index) {
	case recorder_kStartTriggerThreshold: 
	    r = @"StartTriggerThreshold"; 
	    break;
	case recorder_kRecordFile:            
	    r = @"RecordFileName";        
	    break;
    }
    return r;
}

////////////////////////////////////////////////////////////////////////////////
// processReplacingInputBuffer:outputBuffer:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) processReplacingInputBuffer: (SndAudioBuffer *) inB
                        outputBuffer: (SndAudioBuffer *) outB;
{
#if SNDAUDIOPROCRECORDER_DEBUG > 1
    NSLog(@"SndAudioProcessor::processReplacing: Entering...\n");
#endif
    if (stopSignal) {
#if SNDAUDIOPROCRECORDER_DEBUG > 1
	NSLog(@"SndAudioProcessor::processReplacing: Finished recording BBB\n");        
#endif    
	if (framesRecorded == 0 && recordPosition == 0)
	    return NO;
    }
    if(isRecording) {
	float *recData            = (float *) [recordBuffer bytes]; // TODO this assumes the data is always floats.
	float *inputData          = (float *) [inB bytes];          // TODO this assumes the data is always floats.
	long inBuffLengthInBytes  = [inB lengthInBytes];
	long inBuffLengthInFrames = [inB lengthInSampleFrames];
	long recBuffLengthInBytes = [recordBuffer lengthInBytes];
	long remainder            = 0;
	long length               = 0;
	
	if (!startedRecording) { // whoop! haven't yet started recording - look thru buffer
	    // float *finB = (float *) [inB bytes];
	    long channelCount = [inB channelCount];
	    long bufferLengthInSamples = inBuffLengthInFrames * channelCount;
	    long sampleIndex;
	    
	    for (sampleIndex = 0; sampleIndex < bufferLengthInSamples; sampleIndex++) {
		if (fabs(inputData[sampleIndex]) > startTriggerThreshold) {
		    long samplesToSkip = (sampleIndex / channelCount) * channelCount;
		    startedRecording = YES; // to execute the saving below.
		    // Now determine which frame this sample is within in order to calculate sample to begin copying from.
		    inputData           += samplesToSkip;
		    inBuffLengthInBytes -= samplesToSkip * sizeof(float); // TODO this assumes floats for samples.
		    break;
		}
	    }
	}
	
	// do NOT make this an 'else' with the above 'if', allow it to drop through.
	if (startedRecording) {
	    // NSLog(@"inB = %@, recordBuffer %@\n", inB, recordBuffer);
	    // work out how much of the incoming buffer we can dump in the record buffer...
	    if (inBuffLengthInBytes + recordPosition > recBuffLengthInBytes) {
		remainder = (inBuffLengthInBytes + recordPosition) - recBuffLengthInBytes;
		length    = recBuffLengthInBytes - recordPosition;
	    }
	    else {
		length = inBuffLengthInBytes;
	    }
	    // NSLog(@"recordPosition %d remainder %d length %d\n", recordPosition, remainder, length);
	    // transfer the incoming data...
	    memcpy(((void*) recData) + recordPosition, inputData, length);
	    // [recordBuffer insertBuffer: inB inRange: aboveThresholdRange];
	    recordPosition += length;    
	    
	    // have we filled a record buffer?
	    if (recordPosition == recBuffLengthInBytes) {
		if (recordFile != NULL) { // we are streaming to a file, and need to write to disk!
		    [self writeToFileBuffer: recordBuffer length: recBuffLengthInBytes];
#if SNDAUDIOPROCRECORDER_DEBUG
		    NSLog(@"SndAudioProcessor::processReplacing: Processing... (pos: %li / %li  length: %li inlength: %li)\n",recordPosition,recBuffLengthInBytes,framesRecorded,[inB lengthInBytes]);
		    NSLog(@"recordBuffer %@\n", recordBuffer);
#endif
		}
		else {
		    framesRecorded += length;
		    isRecording = NO;
		}
		recordPosition = 0;
	    }        
	    if (remainder) {
#if SNDAUDIOPROCRECORDER_DEBUG
		NSLog(@"SndAudioProcessor::processReplacing: memcpy... (recordPosition: %li length: %li remainder: %li recData: %p inputData:%p inLength:%li)\n",
		      recordPosition, length, remainder, recData, inputData, [inB lengthInBytes]);
#endif
		memcpy(recData, ((void*)inputData) + length, remainder);
		// [recordBuffer insertBuffer: inB inRange: remainingFramesRange];
		recordPosition += remainder;
	    }    
	    
	    if (stopSignal) { // If we are in the process of stopping, shut down stuff.
		if (recordFile != NULL) {
		    if (recordPosition > 0)  // flush out partial record buffer to disk
			[self writeToFileBuffer: recordBuffer length: recordPosition];
		    
		    [self closeRecordFile];
#if SNDAUDIOPROCRECORDER_DEBUG  
		    NSLog(@"SndAudioProcessor::processReplacing: closed record file\n");
#endif
		}
		else {
		    isRecording = NO;
		}
	    }
	}
    } // end of isRecording
#if SNDAUDIOPROCRECORDER_DEBUG > 1
    NSLog(@"SndAudioProcessor::processReplacing: Leaving...\n");
#endif
    return NO;
}

////////////////////////////////////////////////////////////////////////////////

@end
