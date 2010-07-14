//
//  $Id$
//
//  Created by Leigh Smith on Jul 9th 2010.
//  Copyright (c) 2010 Oz Music Code LLC. All rights reserved.
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
	[self setNeedsInput: YES];
	[self setGeneratesOutput: YES];
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

    if (![self isActive]) {
	// hmm, should probably wait here for the welcomeClient to occur.
	
	[outputBufferLock lockWhenCondition: OB_isInit];
	[outputBufferLock unlockWithCondition: OB_isInit];
    }

    active = YES;
    isReceivingInput = YES;
    
    return isReceivingInput;
}

////////////////////////////////////////////////////////////////////////////////
// stopReceivingInput
////////////////////////////////////////////////////////////////////////////////

- (void) stopReceivingInput
{
   // we need to disconnectFromStream;
    isReceivingInput = NO;
    active = NO;
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
    NSLog(@"summedLatency %f numberOfTimes = %d\n", summedLatency, numberOfTimes);
    return summedLatency / MAX(numberOfTimes, 1); // to prevent divide by zero.
}

////////////////////////////////////////////////////////////////////////////////
// processBuffers
////////////////////////////////////////////////////////////////////////////////

- (void) processBuffers
{  
    // TODO handle when the output stream is not the same as the input stream.
    SndAudioBuffer *currentSynthOutputBuffer = [self synthOutputBuffer];
    unsigned long outputBufferLength = [currentSynthOutputBuffer lengthInSampleFrames];
    
    if ([self isReceivingInput]) { // only playback input if recording is enabled.
	SndAudioBuffer *inBuffer = [self synthInputBuffer];
	// NSRange wholeInputBufferRange = { 0, [inBuffer lengthInSampleFrames] };

	// This probably is only ever true once, at the first run, not on each record.
	if ([self synthesisTime] == 0) {
	    if (delegate != nil && [delegate respondsToSelector: @selector(didStartReceivingInput)]) 
		[delegate didStartReceivingInput: self];
	}
	// Just make the output buffer be the input buffer
	// this will then process with the clients audio processor chain.
	// [currentSynthOutputBuffer copyFromBuffer: inBuffer intoRange: wholeInputBufferRange];
	[currentSynthOutputBuffer mixWithBuffer: inBuffer
				      fromStart: 0
					  toEnd: outputBufferLength
				      canExpand: YES];
	// NSLog(@"inBuffer %@\n", inBuffer);
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
