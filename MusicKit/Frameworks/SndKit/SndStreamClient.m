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
    return [[SndStreamClient new] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
    [super init];
    outputBufferLock = [NSLock new];
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
    if (outputBuffer)
        [outputBuffer release];
    if (synthBuffer)
        [synthBuffer  release];
    if (inputBuffer)
        [inputBuffer  release];
        
    outputBuffer = nil;
    synthBuffer  = nil;
    inputBuffer  = nil;
    
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// basic mutators
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

- setManager: (SndStreamManager*) m
{
    if (manager)
        [manager release];
    manager = m;
    if (manager != nil)
        [manager retain];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// basic accessors
////////////////////////////////////////////////////////////////////////////////

- (BOOL) needsInput
{
  return needsInput;
}

- (BOOL) generatesOutput
{
  return generatesOutput;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
    [self freeBufferMem];
    
    if (outputBufferLock)
        [outputBufferLock release];
    if (synthThreadLock)  
        [synthThreadLock release];    

    if (manager)
        [manager release];
    
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// description
////////////////////////////////////////////////////////////////////////////////

- (NSString*) description
{
    return [NSString stringWithFormat: @"SndStreamClient %sactive, now %f, %s",
        active ? " " : "not ", [self nowTime], needsInput ? "needs input" : "doesn't need input"];
}

////////////////////////////////////////////////////////////////////////////////
// nowTime
// The client's sense of time is just the manager's sense of time, defining a 
// common clock among clients.
////////////////////////////////////////////////////////////////////////////////

- (double) nowTime
{
    return [manager nowTime];
}

////////////////////////////////////////////////////////////////////////////////
// manager
////////////////////////////////////////////////////////////////////////////////

- (SndStreamManager*) manager
{
    return manager;
}

////////////////////////////////////////////////////////////////////////////////
// welcomeClientWithBuffer:manager:
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
        [self prepareToStreamWithBuffer: buff];
        [self setManager: m];
                
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
// If input isn't needed, ignore!!! (eg, if this isn't an FX unit)
////////////////////////////////////////////////////////////////////////////////

- startProcessingNextBufferWithInput: (SndAudioBuffer*) inB nowTime: (double) t 
{
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
        {
            SndAudioBuffer *temp = synthBuffer;
            synthBuffer          = outputBuffer;
            outputBuffer         = temp;
        }
        [outputBufferLock unlock];

        // printf("startProcessingNextBufferWithInput nowTime = %f\n", t);

        if (needsInput) {
            if (inB) 
                [inputBuffer copyData: inB];
            else
                NSLog(@"SndStreamClient::startProcessingNextBuffer - Error: inBuffer is nil!\n");
        }
        [synthThreadLock unlockWithCondition: SC_processBuffer];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// processingThread
////////////////////////////////////////////////////////////////////////////////

- (void) processingThread
{
    NSAutoreleasePool *localPool = [NSAutoreleasePool new];
    active = TRUE;
    // NSLog(@"SYNTH THREAD: starting processing thread (thread id %p)\n",objc_thread_id());
    while (active) {
        [synthThreadLock lockWhenCondition: SC_processBuffer];

        [synthBuffer zero];
        //NSLog(@"SYNTH THREAD: going to processBuffers\n");
        [self processBuffers];
        //NSLog(@"SYNTH THREAD: ... done processBuffers\n");

        if (processFinishedCallback != NULL)
            processFinishedCallback(); // SKoT: should this be a selector, hmm hmm...?

        [synthThreadLock unlockWithCondition: SC_bufferReady];
    }
    [manager removeClient: self];
    [self setManager: nil];
    [self freeBufferMem];
    [self didFinishStreaming];
    [localPool release];
//    fprintf(stderr,"SndStreamClient: processing thread stopped\n");                       
    [NSThread exit];
}

////////////////////////////////////////////////////////////////////////////////
// prepareToStreamWithBuffer
//
// Note! Only use the buffer for getting the size + data format for your 
// sub-classed stream client's internal setup stuff. 
////////////////////////////////////////////////////////////////////////////////

- prepareToStreamWithBuffer: (SndAudioBuffer*) buff
{
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// didFinishStreaming
// 
// Override this to give a sub-classed client an opportunity to 'clean up'
////////////////////////////////////////////////////////////////////////////////

- didFinishStreaming
{
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// active
////////////////////////////////////////////////////////////////////////////////

- (BOOL) active
{
    return active;
}

////////////////////////////////////////////////////////////////////////////////
// setProcessFinishedCallBack:
////////////////////////////////////////////////////////////////////////////////

- setProcessFinishedCallBack: (void*) fn
{
    processFinishedCallback = fn;
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// processBuffers
//
// subclass: Override this with your buffer processing method
//
// This should be along the lines of: (in pseudo code!!!)
//
// SndAudioBuffer *b = [self synthBuffer]; 
// for i = 0 to b.length
//   b.sample[i] = a_synth_sample();
////////////////////////////////////////////////////////////////////////////////

- (void) processBuffers
{
  NSLog(@"SndStreamClient::processBuffers is being called - have you remembered to override this in your strem client?");
}

////////////////////////////////////////////////////////////////////////////////
// outputBuffer
////////////////////////////////////////////////////////////////////////////////

- (SndAudioBuffer*) outputBuffer
{
  return outputBuffer;
}

////////////////////////////////////////////////////////////////////////////////
// synthBuffer
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
    // Need lock to make sure the synthesis thread is paused before shutting down!
    [synthThreadLock lockWhenCondition:   SC_bufferReady ]; 
    active = FALSE;
    [synthThreadLock unlockWithCondition: SC_processBuffer];
    
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// isActive
////////////////////////////////////////////////////////////////////////////////

- (BOOL) isActive;
{
    return active;
}

////////////////////////////////////////////////////////////////////////////////
// setDetectPeaks
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
// Output buffer lock / unlock
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

////////////////////////////////////////////////////////////////////////////////

@end
