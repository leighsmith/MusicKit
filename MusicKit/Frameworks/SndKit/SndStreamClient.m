/*
  $Id$

  Description:

  Original Author: SKoT McDonald, <skot@tomandandy.com>, tomandandy music inc.

  Sat 10-Feb-2001, Copyright (c) 2001 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/
#import "SndStreamManager.h"
#import "SndStreamClient.h"
#import "SndAudioBuffer.h"

enum {
    SC_processBuffer,
    SC_bufferReady
};

@implementation SndStreamClient

////////////////////////////////////////////////////////////////////////////////
// streamClient
////////////////////////////////////////////////////////////////////////////////

+ streamClient
{
    SndStreamClient *sc = [[SndStreamClient alloc] init];
    
    return [sc autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
    [super init];
    outputBufferLock = [[NSLock alloc] init];
    synthThreadLock  = [[[NSConditionLock alloc] initWithCondition: SC_processBuffer] retain];    
    outputBuffer     = nil;
    synthBuffer      = nil;
    active           = FALSE;
    needsInput       = FALSE;
    generatesOutput  = TRUE;
    processFinishedCallback = NULL;
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// @freeBufferMem
////////////////////////////////////////////////////////////////////////////////

- freeBufferMem
{
    [outputBuffer release];
    [synthBuffer  release];
    [inputBuffer  release];
    outputBuffer = nil;
    synthBuffer  = nil;
    inputBuffer  = nil;
    
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// @setNeedsInput
////////////////////////////////////////////////////////////////////////////////

- setNeedsInput: (BOOL) b
{
    needsInput = b;
    return self;
}

- setGeneratesOutput: (BOOL) b 
{
  generatesOutput = b;
  return self; 
}

- (BOOL) needsInput
{
  return needsInput;
}

- (BOOL) generatesOutput
{
  return generatesOutput;
}

////////////////////////////////////////////////////////////////////////////////
// @dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
    [self freeBufferMem];
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// @description
////////////////////////////////////////////////////////////////////////////////

- (NSString*) description
{
    return [NSString stringWithFormat: @"SndStreamClient %sactive, now %f, %s",
        active ? " " : "not ", [self nowTime], needsInput ? "needs input" : "doesn't need input"];
}

////////////////////////////////////////////////////////////////////////////////
// The clients sense of time is just the manager's sense of time, defining a common clock among clients.
////////////////////////////////////////////////////////////////////////////////

- (double) nowTime
{
    return [manager nowTime];
}

////////////////////////////////////////////////////////////////////////////////
// @manager
////////////////////////////////////////////////////////////////////////////////

- (SndStreamManager*) manager
{
    return manager;
}

////////////////////////////////////////////////////////////////////////////////
// @welcomeClientWithBuffer:manager:
////////////////////////////////////////////////////////////////////////////////

- welcomeClientWithBuffer: (SndAudioBuffer*) buff manager: (SndStreamManager*) m
{
    // The client shouldn't be active when we are welcoming it with a new manager.
    if(!active) {
        outputBuffer = buff;
        [outputBuffer retain];
        
        if (needsInput) {
            inputBuffer = [buff copy];
            [inputBuffer retain];
        }
    
        if (generatesOutput) {
            synthBuffer = [buff copy];
            [synthBuffer retain];
        }
    
        // NSLog(@"assigning manager %@\n", m);
        manager = [m retain];
        
        [NSThread detachNewThreadSelector: @selector(processingThread)
                                 toTarget: self
                               withObject: nil];
        return self;
    }
    else {
        NSLog(@"Couldn't welcome client with buffer since it's already active!\n");
        return nil;
    }
}

////////////////////////////////////////////////////////////////////////////////
// startProcessingNextBufferWithInput:
//
// If input isn't needed, ignore!!! (ie, if this isn't an FX unit)
////////////////////////////////////////////////////////////////////////////////

- startProcessingNextBufferWithInput: (SndAudioBuffer*) inB nowTime: (double) t 
{
    SndAudioBuffer *temp = nil;
    BOOL gotLock = NO;
    
    NS_DURING
    gotLock = [synthThreadLock tryLockWhenCondition: SC_bufferReady];
    NS_HANDLER
    {
        NSLog(@"SndStreamClient: mutex bug workaround\n");
        gotLock = FALSE;
    }
    NS_ENDHANDLER
    
    if( gotLock ) {
        // swap the synth and output buffers, fire off next round of synthing

        [outputBufferLock lock];

        temp            = synthBuffer;
        synthBuffer     = outputBuffer;
        outputBuffer    = temp;

        // NSLog(@"Got SC_bufferReady: startProcessingNextBufferWithInput nowTime = %f\n", t);
        
        [outputBufferLock unlock];
	
        if (needsInput)
            [inputBuffer copyData: inB];
	    
        [synthThreadLock unlockWithCondition: SC_processBuffer];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// @processingThread
////////////////////////////////////////////////////////////////////////////////

- (void) processingThread
{
    NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];
    active = TRUE;
    // NSLog(@"SYNTH THREAD: starting processing thread (thread id %p)\n",objc_thread_id());
    while (active) {
        [synthThreadLock lockWhenCondition: SC_processBuffer];
        [synthBuffer zero];
        //NSLog(@"SYNTH THREAD: going to processBuffers\n");
        [self processBuffers];
        //NSLog(@"SYNTH THREAD: ... done processBuffers\n");

        if (processFinishedCallback != NULL)
            processFinishedCallback();
	    
        [synthThreadLock unlockWithCondition: SC_bufferReady];
    }
    [manager removeClient: self];
    [manager release];
    manager = nil; // avoids double release.
    [self freeBufferMem];
    // NSLog(@"SYNTH THREAD: EXITING\n");
    [localPool release];
    [NSThread exit];
}

////////////////////////////////////////////////////////////////////////////////
// @active
////////////////////////////////////////////////////////////////////////////////

- (BOOL) active
{
    return active;
}

////////////////////////////////////////////////////////////////////////////////
// @setProcessFinishedCallBack:
////////////////////////////////////////////////////////////////////////////////

- setProcessFinishedCallBack: (void*)fn
{
    processFinishedCallback = fn;
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// @processBuffers
////////////////////////////////////////////////////////////////////////////////

- (void) processBuffers
{
  // Nowt here. sub class should override with an audio buffer filling function.
  // 
  // along the lines of: (in pseudo code!!!)
  //
  // SndAudioBuffer *b = [self synthBuffer]; 
  // for i = 0 to b.length
  //   b.samples[i] = a_synth_sample();
}

////////////////////////////////////////////////////////////////////////////////
// outputBuffer
////////////////////////////////////////////////////////////////////////////////

- (SndAudioBuffer*) outputBuffer
{
  return outputBuffer;
}

////////////////////////////////////////////////////////////////////////////////
// @synthBuffer
////////////////////////////////////////////////////////////////////////////////

- (SndAudioBuffer*) synthBuffer
{
  return synthBuffer;
}

////////////////////////////////////////////////////////////////////////////////
// inputBuffer
////////////////////////////////////////////////////////////////////////////////

- (SndAudioBuffer*) inputBuffer
{
  return inputBuffer;
}

////////////////////////////////////////////////////////////////////////////////
// managerIsShuttingDown
////////////////////////////////////////////////////////////////////////////////

- managerIsShuttingDown
{
    // make sure the synthesis thread is paused
    [synthThreadLock lockWhenCondition:   SC_bufferReady ]; 
    active = FALSE;
    [synthThreadLock unlockWithCondition: SC_processBuffer];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// @isActive
////////////////////////////////////////////////////////////////////////////////

- (BOOL) isActive;
{
    return active;
}

////////////////////////////////////////////////////////////////////////////////
// @setDetectPeaks
////////////////////////////////////////////////////////////////////////////////

- setDetectPeaks: (BOOL) detectPeaks
{
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// getPeakLeft:right:
////////////////////////////////////////////////////////////////////////////////

- getPeakLeft: (float *) leftPeak right: (float *) rightPeak
{
    return self;
}

////////////////////////////////////////////////////////////////////////////////

- lockOutputBuffer
{
  [outputBufferLock lock];
  return self;
}

- unlockOutputBuffer
{
  [outputBufferLock unlock];
  return self;
}


@end
