/*
  $Id$

  Description:

  Original Author: SKoT McDonald, <skot@tomandandy.com>, tomandandy music inc.

  Sat 10-Feb-2001, Copyright (c) 2001 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/
#import "SndStreamClient.h"
#import "SndAudioBuffer.h"

enum {
    SC_processBuffer,
    SC_bufferReady
};

@implementation SndStreamClient

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

+ streamClient
{
    SndStreamClient *sc = [SndStreamClient alloc];
    
    sc->outputBufferLock = [[NSLock alloc] init];
    sc->outputBuffer     = nil;
    sc->synthBuffer      = nil;
    sc->synthThreadLock  = nil;
    sc->active           = FALSE;
    sc->needsInput       = FALSE;
    sc->nowTime          = 0.0;
    sc->processFinishedCallback = NULL;    
    return [sc autorelease];
}

////////////////////////////////////////////////////////////////////////////////
//
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
//
////////////////////////////////////////////////////////////////////////////////

- setNeedsInput: (BOOL) b
{
    needsInput = b;
    return self;
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
    [self freeBufferMem];
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- (NSString*) description
{
    return [NSString stringWithFormat: @"SndStreamClient object"];
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- (double) nowTime
{
    return nowTime;
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- welcomeClientWithBuffer: (SndAudioBuffer*) buff
{
    [self freeBufferMem];

    outputBuffer = buff;
    [outputBuffer retain];
    synthBuffer = [outputBuffer copy];
    [synthBuffer retain];
    inputBuffer = [outputBuffer copy];
    [inputBuffer retain];

    synthThreadLock = [[NSConditionLock alloc] initWithCondition: SC_processBuffer];
    [synthThreadLock retain];
    
    [NSThread detachNewThreadSelector: @selector(processingThread)
                             toTarget: self
                           withObject: nil];
    
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// startProcessingNextBufferWithInput:
//
// If input isn't needed, ignore!!! (ie, if this isn't an FX unit
////////////////////////////////////////////////////////////////////////////////

- startProcessingNextBufferWithInput: (SndAudioBuffer*) inB nowTime: (double) t 
{
    SndAudioBuffer *temp = nil;
        
    if ([synthThreadLock tryLockWhenCondition: SC_bufferReady]) {
        // swap the synth and output buffers, fire off next round of synthing
        temp            = synthBuffer;
        synthBuffer     = outputBuffer;
        outputBuffer    = temp;

        nowTime = t;
        
        if (needsInput)
            [inputBuffer copyData: inB];
        
        [synthThreadLock unlockWithCondition: SC_processBuffer];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// processingThread
////////////////////////////////////////////////////////////////////////////////

- (void) processingThread
{
    NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];
    active = TRUE;
    
    while (active) {
        [synthThreadLock lockWhenCondition: SC_processBuffer];

        [synthBuffer zero];
        [self processBuffers];

        if (processFinishedCallback != NULL)
            processFinishedCallback();

        [synthThreadLock unlockWithCondition: SC_bufferReady];
    }
    [synthThreadLock release];
    [localPool release];
    [NSThread exit];
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- setProcessFinishedCallBack: (void*)fn
{
    processFinishedCallback = fn;
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// fillSynthBuffer
////////////////////////////////////////////////////////////////////////////////

- (void) processBuffers
{
    // Nowt here. sub class should override with an audio buffer filling function.
}

////////////////////////////////////////////////////////////////////////////////
// outputBuffer
////////////////////////////////////////////////////////////////////////////////

- (SndAudioBuffer*) outputBuffer
{
    return outputBuffer;
}
- (SndAudioBuffer*) synthBuffer;
{
    return synthBuffer;
}

////////////////////////////////////////////////////////////////////////////////
// managerIsShuttingDown
////////////////////////////////////////////////////////////////////////////////

- managerIsShuttingDown
{
    active = FALSE;
    return self;
}

////////////////////////////////////////////////////////////////////////////////

@end
