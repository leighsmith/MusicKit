////////////////////////////////////////////////////////////////////////////////
//
//  SndStreamRecorder.m
//  SndKit
//
//  Created by SKoT McDonald on Thu Apr 05 2001.
//  Copyright (c) 2001 tomandandy. All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and 
//  non-commercial purposes so long as the author attribution and copyright 
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import <MKPerformSndMIDI/SndStruct.h>
#import "SndAudioProcessorRecorder.h"
#import "SndAudioBuffer.h"
#import "SndStreamManager.h"
#import "SndStreamRecorder.h"
#import "SndEndianFunctions.h"
#include <unistd.h>

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

- (NSString*) description
{
  return @"SndStreamRecorder";
}

////////////////////////////////////////////////////////////////////////////////
// startRecording
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startRecording
{
  return [recorder startRecording];
}

////////////////////////////////////////////////////////////////////////////////
// stopRecording
////////////////////////////////////////////////////////////////////////////////

- stopRecording
{
  [recorder stopRecording];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// stopRecordingWait:disconnectFromStream:
////////////////////////////////////////////////////////////////////////////////

- stopRecordingWait: (BOOL) bWait disconnectFromStream: (BOOL) bDisconnectFromStream
{
  [recorder stopRecordingWait: bWait disconnectFromStream: bDisconnectFromStream];
  active = FALSE;

  return self;
}

////////////////////////////////////////////////////////////////////////////////
// processBuffers
////////////////////////////////////////////////////////////////////////////////

- (void) processBuffers
{  
  if ([recorder isRecording]) {
    SndAudioBuffer *inB       = [self synthInputBuffer];  
    if ([recorder bytesRecorded] == 0) {
      if (delegate != nil && [delegate respondsToSelector: @selector(didStartRecording)]) 
        [delegate didStartRecording: self];
    }
    [recorder processReplacingInputBuffer: inB outputBuffer: nil];
  }
}

////////////////////////////////////////////////////////////////////////////////
// prepareToRecordForDuration:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) prepareToRecordForDuration: (double) time
{
  BOOL r = FALSE;
  
  if ([recorder isRecording]) 
    NSLog(@"SndStreamRecorder::prepareToRecordForDuration - Error: already recording!\n");
  
  else {
    SndAudioBuffer *outB;
    [self lockOutputBuffer];
    outB = [self outputBuffer]; 
    r    = [recorder prepareToRecordForDuration: time withFormat: [outB format]];
    [self unlockOutputBuffer];
  }
  return r;
}      

////////////////////////////////////////////////////////////////////////////////
// startRecordingToFile:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startRecordingToFile: (NSString*) filename
{
  BOOL b = FALSE;
  
  if (![self isActive]) {
    [[SndStreamManager defaultStreamManager] addClient: self]; // hmm, should probably wait here for the welcomeClient to occur.

    [outputBufferLock lockWhenCondition: OB_isInit];
    [outputBufferLock unlockWithCondition: OB_isInit];
  }
  if ([recorder isRecording]) 
    NSLog(@"SndStreamRecorder::startRecordingToFile - Error: already recording!\n");

  b = [recorder startRecordingToFile: filename withFormat: [exposedOutputBuffer format]];
  
  return b;
}

////////////////////////////////////////////////////////////////////////////////

@end
