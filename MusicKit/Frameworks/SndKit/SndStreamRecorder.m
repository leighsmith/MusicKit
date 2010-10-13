////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
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

#import "SndAudioProcessorRecorder.h"
#import "SndAudioBuffer.h"
#import "SndStreamManager.h"
#import "SndStreamRecorder.h"
#import "SndEndianFunctions.h"

@implementation SndStreamRecorder

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
    self = [super init];
    if (self != nil) {
	if (recorder != nil)
	    [recorder release];
	recorder = [[SndAudioProcessorRecorder alloc] init];
	[self setNeedsInput: TRUE];
	[self setGeneratesOutput: FALSE];    
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
    if (recorder != nil)
	[recorder release];
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// description
////////////////////////////////////////////////////////////////////////////////

- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ recorder %@", [super description], recorder];
}

////////////////////////////////////////////////////////////////////////////////
// startRecording
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startRecording
{
    return [recorder startRecording];
}

////////////////////////////////////////////////////////////////////////////////
// stopRecordingAndDisconnectFromStream:
////////////////////////////////////////////////////////////////////////////////

- (void) stopRecordingAndDisconnectFromStream: (BOOL) bDisconnectFromStream
{
    [recorder stopRecording];
    active = !bDisconnectFromStream;
}

////////////////////////////////////////////////////////////////////////////////
// stopRecording
////////////////////////////////////////////////////////////////////////////////

- (void) stopRecording
{
    [self stopRecordingAndDisconnectFromStream: YES];
}

////////////////////////////////////////////////////////////////////////////////
// processBuffers
////////////////////////////////////////////////////////////////////////////////

- (void) processBuffers
{  
    if ([recorder isRecording]) {
	SndAudioBuffer *inBuffer = [self synthInputBuffer];  
	if ([recorder framesRecorded] == 0) {
	    if (delegate != nil && [delegate respondsToSelector: @selector(didStartRecording)]) 
		[delegate didStartRecording: self];
	}
	[recorder processReplacingInputBuffer: inBuffer outputBuffer: nil];
    }
}

////////////////////////////////////////////////////////////////////////////////
// prepareToRecordForDuration:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) prepareToRecordForDuration: (double) time
{
    BOOL r = FALSE;
    
    if ([recorder isRecording]) 
	NSLog(@"SndStreamRecorder -prepareToRecordForDuration: Error: already recording!\n");
    
    else {
#if 0
	SndAudioBuffer *outB;
	[self lockOutputBuffer];
	outB = [self outputBuffer]; 
	r    = [recorder prepareToRecordWithQueueDuration: time
						 ofFormat: [outB format]];
	[self unlockOutputBuffer];
#else
	r = [recorder prepareToRecordWithQueueDuration: time];
#endif
    }
    return r;
}      

////////////////////////////////////////////////////////////////////////////////
// startRecordingToFile:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startRecordingToFile: (NSString*) filename
{
    BOOL beganRecordingOK = FALSE;
    SndFormat inputFormat = [Snd nativeInputFormat];
    
    if (![self isActive]) {
	[[SndStreamManager defaultStreamManager] addClient: self]; // hmm, should probably wait here for the welcomeClient to occur.
	
	[outputBufferLock lockWhenCondition: OB_isInit];
	[outputBufferLock unlockWithCondition: OB_isInit];
    }
    if ([recorder isRecording]) 
	NSLog(@"SndStreamRecorder -startRecordingToFile: Error: already recording!\n");
    
    beganRecordingOK = [recorder startRecordingToFile: filename
				       withDataFormat: inputFormat.dataFormat
					 channelCount: inputFormat.channelCount
					 samplingRate: inputFormat.sampleRate];
//    beganRecordingOK = [recorder startRecordingToFile: filename
//					   withFormat: inputFormat];
    
    return beganRecordingOK;
}

////////////////////////////////////////////////////////////////////////////////

@end
