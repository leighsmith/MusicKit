//
//  $Id: SndStreamInput.m 3729 2010-10-06 20:11:30Z leighsmith $
//
//  Created by: Leigh Smith <leigh@leighsmith.com> on Jul 9th 2010.
//  Copyright (c) 2010, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//

#import "SndStreamInput.h"

@implementation SndStreamInput

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
    self = [super init];
    if (self != nil) {
	latencyIndex = 0;
	[self setNeedsInput: YES];
	[self setGeneratesOutput: YES];
	[self setClientName: @"SndStreamInput"];
	isReceivingInput = NO;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// description
////////////////////////////////////////////////////////////////////////////////

- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ receivingInput %ld",
	[super description], (long) isReceivingInput];
}

////////////////////////////////////////////////////////////////////////////////
// startReceivingInput
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startReceivingInput
{
    latencyIndex = 0;
    isReceivingInput = YES;
    
    return isReceivingInput;
}

////////////////////////////////////////////////////////////////////////////////
// stopReceivingInput
////////////////////////////////////////////////////////////////////////////////

- (void) stopReceivingInput
{
    isReceivingInput = NO;
}

- (BOOL) isReceivingInput
{
    return isReceivingInput; // return [self isActive]; // is another var necessary?
}

- (float) averageLatencyForOutput: (BOOL) forOutput
{
    float summedLatency = 0.0;
    long *latency = forOutput ? outputLatencyTimes : inputLatencyTimes;
    int timeIndex;
    int numberOfTimes = MIN(MAX_LATENCY_TIMES, latencyIndex);

    for(timeIndex = 0; timeIndex < numberOfTimes; timeIndex++)
	summedLatency += latency[timeIndex];
    // NSLog(@"summedLatency %f numberOfTimes = %d\n", summedLatency, numberOfTimes);
    return summedLatency / MAX(numberOfTimes, 1); // to prevent divide by zero.
}

////////////////////////////////////////////////////////////////////////////////
// processBuffers
////////////////////////////////////////////////////////////////////////////////

- (void) processBuffers
{  
    // TODO handle when the output stream is not the same as the input stream.
    SndAudioBuffer *currentSynthOutputBuffer = [self synthOutputBuffer];
    NSRange outputBufferRange = { 0, [currentSynthOutputBuffer lengthInSampleFrames] };
    
    if ([self isReceivingInput]) { // only playback input if recording is enabled.
	SndAudioBuffer *inBuffer = [self synthInputBuffer];
	NSRange wholeInputBufferRange = { 0, [inBuffer lengthInSampleFrames] };

	// NSLog(@"output buffer length %ld input buffer length %ld\n", outputBufferRange.length, wholeInputBufferRange.length);

	// This probably is only ever true once, at the first run, not on each record.
	if ([self synthesisTime] == 0) {
	    if (delegate != nil && [delegate respondsToSelector: @selector(didStartReceivingInput)]) 
		[delegate didStartReceivingInput: self];
	}
	if(wholeInputBufferRange.length > outputBufferRange.length) {
	    NSRange fillFromInputRange = { 0, outputBufferRange.length }; // Should be an ivar
	    
	    while(NSMaxRange(fillFromInputRange) < wholeInputBufferRange.length) {
		// TODO copy a partial length buffer into synthOutputBuffer
		[currentSynthOutputBuffer copyFromBuffer: inBuffer 
					  intoFrameRange: outputBufferRange
					  fromFrameRange: fillFromInputRange];
		// Since we will be rotating the buffer, process it with the audioProcessorChain.
		[processorChain processBuffer: synthOutputBuffer forTime: clientNowTime];
		// Retire the synth output buffer so we can work on the next.
		[self rotateSynthOutputBuffer];
		currentSynthOutputBuffer = [self synthOutputBuffer];
		fillFromInputRange.location += fillFromInputRange.length;
		fillFromInputRange.length = MIN(fillFromInputRange.length - 0, outputBufferRange.length);
	    }
	}
	else if(wholeInputBufferRange.length < outputBufferRange.length) {
	    NSLog(@"output buffer larger than input buffer"); 
	    // TODO copy a partial length buffer into synthOutputBuffer
	    [currentSynthOutputBuffer copyFromBuffer: inBuffer 
				      intoFrameRange: outputBufferRange // change to be a portion of the buffer.
				      fromFrameRange: wholeInputBufferRange];
	}
	else {
	    // Just make the output buffer be the input buffer
	    // this will then process with the clients audio processor chain.
	    if([inBuffer hasSameFormatAsBuffer: currentSynthOutputBuffer]) 
		[currentSynthOutputBuffer copyFromBuffer: inBuffer intoRange: outputBufferRange];
	    else {
		// NSLog(@"mixing currentSynthOutputBuffer %@ with inBuffer %@\n", currentSynthOutputBuffer, inBuffer);
		[currentSynthOutputBuffer mixWithBuffer: inBuffer
					      fromStart: 0
						  toEnd: outputBufferRange.length
					      canExpand: YES];
#if 0
		if(0) {
		    unsigned long maxFrame;
		    unsigned int maxChannel;

		    float rmsAmpPerChannel[10] = { 0.0,  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
		    float maxMagnitude = [inBuffer findMaximumMagnitudeAt: &maxFrame channel: &maxChannel];

		    //[inBuffer amplitudeRMSOfChannels: rmsAmpPerChannel];
		    //printf("inBuffer RMS amp of %f, %f\n", rmsAmpPerChannel[0], rmsAmpPerChannel[1]);
		    printf("inBuffer                 max magnitude %f at frame %ld channel %u\n", maxMagnitude, maxFrame, maxChannel);
		    maxMagnitude = [currentSynthOutputBuffer findMaximumMagnitudeAt: &maxFrame channel: &maxChannel];
		    printf("currentSynthOutputBuffer max magnitude %f at frame %ld channel %u\n", maxMagnitude, maxFrame, maxChannel);
		}
#endif
	    }
	}
	//if([inBuffer maximumAmplitude] > 0.0) {
	    // NSLog(@"inBuffer %@\n", inBuffer);
	//}
	
	// NSLog(@"input queue %@\n", inputQueue);
	// NSLog(@"currentSynthOutputBuffer %@\n", currentSynthOutputBuffer);
	// NSLog(@"output queue %@\n", outputQueue);
	// NSLog(@"Remaining to process for input: %d, output: %d\n", [inputQueue pendingBuffersCount], [outputQueue processedBuffersCount]);
	inputLatencyTimes[latencyIndex % MAX_LATENCY_TIMES] = [self instantaneousInputLatencyInSamples];
	outputLatencyTimes[latencyIndex % MAX_LATENCY_TIMES] = [self instantaneousOutputLatencyInSamples];
        // We allow this to increment beyond MAX_LATENCY_TIMES so we can get an accurate average measurement.
	latencyIndex++; 
    }
    else {
	[currentSynthOutputBuffer zero];
    }
}

@end
