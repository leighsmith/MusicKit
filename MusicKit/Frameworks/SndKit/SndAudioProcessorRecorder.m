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

// Only compile this class if the libsndfile library has been installed.
#if HAVE_CONFIG_H
# import "SndKitConfig.h"
#endif

#if HAVE_LIBSNDFILE

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
    self = [super initWithParamCount: recorder_NumParams name: @"Recorder"];
    if(self != nil) {
	startTriggerThreshold = 0.002f;
	isRecording = NO;
	fileFormat.dataFormat = SND_FORMAT_LINEAR_16; // default format
	fileFormat.channelCount = 2; // Stereo 
	fileFormat.sampleRate = 44100.0; // CD audio.

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
    writingQueue = nil;
    [recordFileName release];
    recordFileName = nil;
    [super dealloc];
}

- copyWithZone: (NSZone *) zone
{
    SndAudioProcessorRecorder *newRecorder = [[[self class] allocWithZone: zone] init];
    
    newRecorder->writingQueue = [writingQueue copy]; // This allows the copy to be independent.
    newRecorder->fileFormat = fileFormat;
    newRecorder->isRecording = isRecording; 
    newRecorder->framesRecorded = framesRecorded;  
    /* The libsndfile handle referring to the open file. We are still referring to the same open file. */
    newRecorder->recordFile = recordFile;
    newRecorder->recordFileName = [recordFileName copy];
    newRecorder->startedRecording = startedRecording;
    newRecorder->startTriggerThreshold = startTriggerThreshold;
    newRecorder->stopSignal = stopSignal;
    
    return newRecorder; // no need to autorelease (by definition, "copy" is retained)
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
    NSLog(@"SndAudioProcessorRecorder -prepareToRecordForDuration - Error: already recording!\n");
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
    NSFileHandle *writingFileHandle;
    
    sfinfo.samplerate = (int) format.sampleRate;
    sfinfo.channels = format.channelCount;
    sfinfo.format = [Snd fileFormatForEncoding: [filename pathExtension] dataFormat: format.dataFormat];
    
    if (!sf_format_check(&sfinfo)) {
	NSLog(@"SndAudioProcessorRecorder -setupRecordFile: Bad output format 0x%x\n", sfinfo.format);
	return NO;
    }
    
    writingFileHandle = [NSFileHandle fileHandleForWritingAtPath: filename]; 
    if((recordFile = sf_open_fd([writingFileHandle fileDescriptor], SFM_WRITE, &sfinfo, TRUE)) == NULL) {
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
    stopSignal = NO;
    isRecording = NO; // Halt all recording then close the file.
    sf_close(recordFile);
    recordFile = NULL;
    framesRecorded = 0;
    
#if SNDAUDIOPROCRECORDER_DEBUG
    NSLog(@"SndAudioProcessor -closeRecordFile - closed\n");
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
    
    // NSLog(@"saveBuffer length: %ld recordBufferFormat.frameCount %ld\n", [saveBuffer lengthInSampleFrames], recordBufferFormat.frameCount);
    // NSLog(@"saveBuffer: %@ bufferFormattedForFile: %@\n", saveBuffer, bufferFormattedForFile);
    // TODO make SndWriteSampleData a SndAudioBuffer method? [bufferFormattedForFile writeToFile: recordFile];
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
	// We create an inner autorelease pool since this thread can run a long time writing many buffers which otherwise are not released.
	NSAutoreleasePool *bufferPool = [[NSAutoreleasePool alloc] init];

	// This will sleep waiting for an available buffer on the queue.
	// We have to inject a final empty buffer on the queue to finally retrieve the buffer and exit the loop.
	SndAudioBuffer *bufferToWrite = [writingQueue popNextProcessedBuffer];
	[self writeToFileBuffer: bufferToWrite];
	[writingQueue addPendingBuffer: bufferToWrite];
	[bufferPool release];
    }
    // close the file after stopSignal is set.
    [self closeRecordFile];
    [pool release];
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
// startRecording
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startRecording
{
    if (isRecording) {  
#if SNDAUDIOPROCRECORDER_DEBUG  
	NSLog(@"SndAudioProcessorRecorder -startRecording - Error: already recording!\n");
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
	NSLog(@"SndAudioProcessorRecorder -startRecordingToFile - Error in prepareToRecordForDuration.\n");
    }
    else if (![self setUpRecordFile: filename withFormat: fileFormat]) {
	NSLog(@"SndAudioProcessorRecorder -startRecordingToFile - Error in setUpRecordFile\n");
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
    NSLog(@"SndAudioProcessor -stopRecordingWait:disconnectFromStream: \n");
#endif
    
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// setStartTriggerThreshold:
////////////////////////////////////////////////////////////////////////////////

- (void) setStartTriggerThreshold: (float) f
{
    startTriggerThreshold = f;
}

////////////////////////////////////////////////////////////////////////////////
// paramObjectForIndex:
////////////////////////////////////////////////////////////////////////////////

- (id) paramObjectForIndex: (const int) i
{
    id obj;
    
    switch (i) {
	case recorder_RecordFile:
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
	case recorder_StartTriggerThreshold: 
	    f = startTriggerThreshold; 
	    break;
    }
    return f;
}

- (NSString *) paramName: (const int) index
{
    NSString *r = nil;
    
    switch (index) {
    case recorder_StartTriggerThreshold: 
	r = @"StartTriggerThreshold"; 
	break;
    case recorder_RecordFile:            
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
    NSLog(@"SndAudioProcessorRecorder -processReplacing: Entering...\n");
#endif
    if([inB dataFormat] != SND_FORMAT_FLOAT)
	NSLog(@"SndAudioProcessorRecorder -processReplacing: unimplemented format %d!\n", [inB dataFormat]);
    if (stopSignal) {
#if SNDAUDIOPROCRECORDER_DEBUG > 1
	NSLog(@"SndAudioProcessorRecorder -processReplacing: Finished recording\n");        
#endif    
	if (framesRecorded == 0)
	    return NO;
	else { 
	    // Write a single empty buffer to allow the file writing thread to exit, 
	    // otherwise it will sleep waiting on a processed buffer.
	    SndAudioBuffer *bufferForWriting = [writingQueue popNextPendingBuffer];

	    [bufferForWriting setLengthInSampleFrames: 0];
	    [writingQueue addProcessedBuffer: bufferForWriting];
	    return NO;
	}	    
    }
    if(isRecording) {
	float *inputData = (float *) [inB bytes];          // TODO this assumes the data is always floats.
	unsigned long inBuffLengthInFrames = [inB lengthInSampleFrames];
	NSRange aboveThresholdRange = { 0, inBuffLengthInFrames };
	int channelCount = [inB channelCount];
	unsigned long sampleCount = inBuffLengthInFrames * channelCount;
	unsigned long sampleIndex;
	
	for (sampleIndex = 0; sampleIndex < sampleCount; sampleIndex++) {
	    float sampleMagnitude = fabs(inputData[sampleIndex]);

	    // Check if we haven't yet started recording, first buffer to save - search buffer for samples above threshold.
	    if (!startedRecording && sampleMagnitude > startTriggerThreshold) {
		unsigned long frameIndex = sampleIndex / channelCount;
		
		startedRecording = YES; // to start the saving of buffers below.
		// Now determine which frame this sample is within in order to calculate sample to begin copying from.
		aboveThresholdRange.location = frameIndex;
		aboveThresholdRange.length = inBuffLengthInFrames - frameIndex;
		// NSLog(@"aboveThresholdRange %ld, %ld\n", aboveThresholdRange.location, aboveThresholdRange.length);
				
		break;  // Once we found the first frame above the threshold, we can start the copy.
	    }
	}
	
	// do NOT make this an 'else' with the above 'if', allow it to drop through.
	if (startedRecording) {
	    NSRange shortenedBufferRange;
	    SndAudioBuffer *bufferForWriting = [writingQueue popNextPendingBuffer];

	    // NSLog(@"processReplacingInputBuffer: bufferForWriting retainCount %d\n", [bufferForWriting retainCount]);
	    // work out how much of the incoming buffer we can dump in the record buffer...
	    shortenedBufferRange.location = 0;
	    shortenedBufferRange.length = aboveThresholdRange.length;
	    [bufferForWriting setLengthInSampleFrames: shortenedBufferRange.length];

	    // NSLog(@"aboveThresholdRange %ld, %ld shortenedBufferRange %ld, %ld\n",
	    //  aboveThresholdRange.location, aboveThresholdRange.length, shortenedBufferRange.location, shortenedBufferRange.length);

	    // transfer the incoming data...
	    [bufferForWriting copyFromBuffer: inB 
			      intoFrameRange: shortenedBufferRange
			      fromFrameRange: aboveThresholdRange];
	    // NSLog(@"inB = %@, bufferForWriting %@\n", inB, bufferForWriting);
	    [writingQueue addProcessedBuffer: bufferForWriting];
	    
#if SNDAUDIOPROCRECORDER_DEBUG
	    NSLog(@"SndAudioProcessor -processReplacing: framesRecorded: %li inB frames: %li bufferForWriting %@\n",
		  framesRecorded, [inB lengthInSampleFrames], bufferForWriting);
#endif	    	    
	}
    } // end of isRecording
#if SNDAUDIOPROCRECORDER_DEBUG > 1
    NSLog(@"SndAudioProcessor -processReplacing: Leaving...\n");
#endif
    return NO;
}

////////////////////////////////////////////////////////////////////////////////

@end

#else
#warning Did not compile SndAudioProcessorRecorder class since libsndfile library was not installed.
#endif
