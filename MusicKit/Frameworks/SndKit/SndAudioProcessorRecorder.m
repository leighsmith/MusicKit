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
#import "SndAudioBufferQueue.h"
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

	// We create a queue to use to save buffers which are to be written to disk by a separate thread.
	// This is to keep the time spent in processReplacingInputBuffer:outputBuffer: to a minimum avoiding
	// file writing latencies interrupting the stream processing.
	writingQueue = [[SndAudioBufferQueue audioBufferQueueWithLength: 32] retain];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
    [self stopRecording];
    [writingQueue release];
    [recordFileName release];
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
	SndAudioBuffer *recordBuffer;
	
	// TODO could use recordDuration to determine number of buffers the queue should have
	// int numberOfBuffers = recordDuration * managerFormat.sampleRate / managerFormat.frameCount;
	
	recordBuffer = [[SndAudioBuffer audioBufferWithFormat: managerFormat] retain];
#if SNDAUDIOPROCRECORDER_DEBUG  
	NSLog(@"recordBuffer %@, should use %d buffers\n", recordBuffer, numberOfBuffers);
#endif
	[writingQueue prepareQueueAsType: audioBufferQueue_typeOutput withBufferPrototype: recordBuffer];
	[recordBuffer release];
	return YES;
    }
#if SNDAUDIOPROCRECORDER_DEBUG  
    NSLog(@"SndAudioProcessorRecorder::prepareToRecordForDuration - Error: already recording!\n");
#endif
    return NO;
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
    
    if (!sf_format_check(&sfinfo)) {
	NSLog(@"SndAudioProcessorRecorder -setupRecordFile: Bad output format 0x%x\n", sfinfo.format);
	return NO;
    }
    
    if((recordFile = sf_open([filename fileSystemRepresentation], SFM_WRITE, &sfinfo)) != NULL) {
	[recordFileName release];
	recordFileName = [filename copy];
	// TODO write a comment
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
    stopSignal = NO;
    isRecording = NO; // Since we've closed the file, we halt all recording.
    sf_close(recordFile);
    recordFile = NULL;
    framesRecorded = 0;
    
#if SNDAUDIOPROCRECORDER_DEBUG
    NSLog(@"SndAudioProcessor::closeRecordFile - closed\n");
#endif
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
// writeToFileBuffer
////////////////////////////////////////////////////////////////////////////////

- (void) writeToFileBuffer: (SndAudioBuffer *) saveBuffer
{
    SndAudioBuffer *bufferFormattedForFile = [saveBuffer audioBufferConvertedToFormat: fileFormat.dataFormat
									 channelCount: fileFormat.channelCount
									 samplingRate: fileFormat.sampleRate];
    SndFormat recordBufferFormat = [bufferFormattedForFile format];
    int error;
    
    // NSLog(@"bufferFormattedForFile: %@\n", bufferFormattedForFile);
    // TODO [bufferFormattedForFile writeToFile: recordFile];
    error = SndWriteSampleData(recordFile, [bufferFormattedForFile bytes], recordBufferFormat);
    if(error != SND_ERR_NONE)
	NSLog(@"SndAudioProcessorRecorder writeToFileBuffer problem writing buffer\n");
    framesRecorded += recordBufferFormat.frameCount;    
}

- (void) fileWritingThread: (id) emptyArgument
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // TODO we probably need to drain the queue first once we stop.
    while(!stopSignal) {
	SndAudioBuffer *bufferToWrite = [writingQueue popNextProcessedBuffer];
	[self writeToFileBuffer: bufferToWrite];
	[writingQueue addPendingBuffer: bufferToWrite];
    }
    // close the file after isRecording is reset.
    [self closeRecordFile];
    [pool release];
}

////////////////////////////////////////////////////////////////////////////////
// startRecording
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startRecording
{
    if (isRecording) {  
#if SNDAUDIOPROCRECORDER_DEBUG  
	NSLog(@"SndAudioProcessorRecorder::startRecording - Error: already recording!\n");
#endif
    }
    else {
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
    fileFormat.dataFormat = dataFormat;
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
	framesRecorded = 0;
	stopSignal = NO;
	[self primeStartTrigger];
	isRecording = YES;
	[NSThread detachNewThreadSelector: @selector(fileWritingThread:) toTarget: self withObject: nil];
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

- stopRecordingWait: (BOOL) waitUntilSaved
{
    float timeWaiting = 0.0;
    stopSignal = YES; // signal to recording thread that we want to stop.
    
    if (waitUntilSaved) {
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

// There are two ways to do this, fill up a big buffer then put it on the queue (requires a big copy)
// or write many buffers to queue, each being a relatively small transfer. We need to watch out
// for the first buffer which will be less than the entire size. This then becomes a shorter
// copy and we load balance better.
- (BOOL) processReplacingInputBuffer: (SndAudioBuffer *) inB
                        outputBuffer: (SndAudioBuffer *) outB;
{
#if SNDAUDIOPROCRECORDER_DEBUG > 1
    NSLog(@"SndAudioProcessor::processReplacing: Entering...\n");
#endif
    if (stopSignal) {
#if SNDAUDIOPROCRECORDER_DEBUG > 1
	NSLog(@"SndAudioProcessor::processReplacing: Finished recording\n");        
#endif    
	if (framesRecorded == 0)
	    return NO;
    }
    if(isRecording) {
	float *inputData          = (float *) [inB bytes];          // TODO this assumes the data is always floats.
	long inBuffLengthInFrames = [inB lengthInSampleFrames];
	NSRange aboveThresholdRange = { 0, inBuffLengthInFrames };
	
	// Check if we haven't yet started recording, first buffer to save - search buffer for samples above threshold.
	if (!startedRecording) { 
	    int channelCount = [inB channelCount];
	    int channelIndex;
	    long frameIndex;
	    
	    for (frameIndex = 0; frameIndex < inBuffLengthInFrames; frameIndex++) {
		for (channelIndex = 0; channelIndex < channelCount; channelIndex++) {
		    long sampleIndex = (frameIndex * channelCount) + channelIndex;

		    if (fabs(inputData[sampleIndex]) > startTriggerThreshold) {
			startedRecording = YES; // to start the saving of buffers below.
			// Now determine which frame this sample is within in order to calculate sample to begin copying from.
			aboveThresholdRange.location = frameIndex;
			aboveThresholdRange.length = inBuffLengthInFrames - frameIndex;
			break;
		    }
		}
	    }
	}
	
	// do NOT make this an 'else' with the above 'if', allow it to drop through.
	if (startedRecording) {
	    NSRange shortenedBufferRange;
	    
	    // work out how much of the incoming buffer we can dump in the record buffer...

	    // NSLog(@"inB = %@, recordBuffer %@\n", inB, recordBuffer);
	    // NSLog(@"recordPosition %d remainder %d length %d\n", recordPosition, remainder, length);
	    SndAudioBuffer *bufferForWriting = [writingQueue popNextPendingBuffer];

	    shortenedBufferRange.location = 0;
	    shortenedBufferRange.length = aboveThresholdRange.length;
	    [bufferForWriting setLengthInSampleFrames: shortenedBufferRange.length];
	    // transfer the incoming data...
	    [bufferForWriting copyFromBuffer: inB 
			      intoFrameRange: shortenedBufferRange
			      fromFrameRange: aboveThresholdRange];
	    [writingQueue addProcessedBuffer: bufferForWriting];
#if SNDAUDIOPROCRECORDER_DEBUG
	    NSLog(@"SndAudioProcessor::processReplacing: framesRecorded: %li inB frames: %li bufferForWriting %@\n",
		  framesRecorded, [inB lengthInSampleFrames], bufferForWriting);
#endif	    	    
	}
    } // end of isRecording
#if SNDAUDIOPROCRECORDER_DEBUG > 1
    NSLog(@"SndAudioProcessor::processReplacing: Leaving...\n");
#endif
    return NO;
}

////////////////////////////////////////////////////////////////////////////////

@end
