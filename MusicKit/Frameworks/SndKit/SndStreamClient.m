/*
  $Id$

  Description:

  Original Author: SKoT McDonald, <skot@tomandandy.com>, tomandandy music inc.

  Sat 10-Feb-2001, Copyright (c) 2001 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/

#import <MKPerformSndMIDI/SndStruct.h>
#import "SndAudioBuffer.h"
#import "SndStreamManager.h"
#import "SndStreamClient.h" 

#define SNDSTREAMCLIENT_DEBUG 0

enum {
    SC_noData,
    SC_hasData
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

    numOutputBuffers = 4;
    numInputBuffers  = 4;
    
    if (pendingOutputBuffersLock == nil) {
      pendingOutputBuffersLock   = [[[NSConditionLock alloc] initWithCondition: SC_noData] retain];
      processedOutputBuffersLock = [[[NSConditionLock alloc] initWithCondition: SC_noData] retain];
      pendingOutputBuffers       = [[NSMutableArray arrayWithCapacity: numOutputBuffers] retain];
      processedOutputBuffers     = [[NSMutableArray arrayWithCapacity: numOutputBuffers] retain];
    }
    if (pendingInputBuffers == nil) {
      pendingInputBuffersLock    = [[[NSConditionLock alloc] initWithCondition: SC_noData] retain];
      processedInputBuffersLock  = [[[NSConditionLock alloc] initWithCondition: SC_noData] retain];
      pendingInputBuffers        = [[NSMutableArray arrayWithCapacity: numInputBuffers] retain];
      processedInputBuffers      = [[NSMutableArray arrayWithCapacity: numInputBuffers] retain];
    }

    if (synthThreadLock == nil)
      synthThreadLock = [[NSLock new] retain];    

    if (processorChain == nil)
      processorChain = [[SndAudioProcessorChain audioProcessorChain] retain];
      
    exposedOutputBuffer     = nil;
    synthOutputBuffer       = nil;
    active                  = FALSE;
    needsInput              = FALSE;
    generatesOutput         = TRUE;
    processFinishedCallback = NULL;
    manager                 = nil;
    clientName              = @"streamClient";
    
    bDelegateRespondsToOutputBufferSkipSelector = FALSE;
    bDelegateRespondsToInputBufferSkipSelector  = FALSE;
    
    [processedOutputBuffersLock lock];
    [processedOutputBuffersLock unlockWithCondition: SC_noData];
    
    return self;
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- (NSString*) clientName
{
  return clientName;
}

- setClientName: (NSString*) name
{
  if (clientName != nil)
    [clientName release];
  clientName = name;
  if (clientName != nil)
    [clientName retain];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
    [self freeBufferMem];

    if (pendingOutputBuffersLock) {
        [pendingOutputBuffersLock   release];
        [pendingOutputBuffers       release];
        [processedOutputBuffersLock release];
        [processedOutputBuffers     release];
    }
    if (pendingInputBuffersLock) {
        [pendingInputBuffersLock    release];
        [pendingInputBuffers        release];
        [processedInputBuffersLock  release];
        [processedInputBuffers      release];
    }
    
    if (processorChain)
        [processorChain release];
        
    if (synthThreadLock)
        [synthThreadLock release];    
    
//    if (manager)
//        [manager release];

    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// description
////////////////////////////////////////////////////////////////////////////////

- (NSString*) description
{
    return [NSString stringWithFormat: @"SndStreamClient %sactive, client nowTime %f, %s",
        active ? " " : "not ", [self synthesisTime], needsInput ? "needs input" : "doesn't need input"];
}

////////////////////////////////////////////////////////////////////////////////
// @freeBufferMem
////////////////////////////////////////////////////////////////////////////////

- freeBufferMem
{
    [pendingOutputBuffers removeAllObjects];
    [processedOutputBuffers removeAllObjects];
    if (synthOutputBuffer)
        [synthOutputBuffer release];
    
    [pendingInputBuffers removeAllObjects];
    [processedInputBuffers removeAllObjects];
    if (synthInputBuffer)
        [synthInputBuffer  release];
        
    exposedOutputBuffer = nil;
    synthOutputBuffer   = nil;
    synthInputBuffer    = nil;
    
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// basic mutators
////////////////////////////////////////////////////////////////////////////////

- setNeedsInput: (BOOL) b
{
    if (!active)
        needsInput = b;
    else
        NSLog(@"SndStreamClient::setNeedsInput - Warn: Can't change needsInput whilst streaming!");
    return self;
}

- setGeneratesOutput: (BOOL) b 
{
    if (!active)
        generatesOutput = b;
    else
        NSLog(@"SndStreamClient::setGeneratesOutput - Warn: Can't change needsInput whilst streaming!");
  return self; 
}

- setManager: (SndStreamManager*) m
{
    if (!active) {
//        if (manager)
//            [manager release];
        manager = m;
//        if (manager != nil)
//            [manager retain];
    }
    else
        NSLog(@"SndStreamClient::setManager - Warn: Can't setManager whilst streaming!");
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
// synthesisTime
// The client's sense of time, which may variably run ahead of the manager's
// sense of time depending on the number of buffers synth-ahead latency and 
// thread scheduling.
////////////////////////////////////////////////////////////////////////////////

- (double) synthesisTime
{
    return clientNowTime;
}

////////////////////////////////////////////////////////////////////////////////
// streamTime
// The manager's sense of time, defining a common clock among clients.
////////////////////////////////////////////////////////////////////////////////

- (double) streamTime
{
    return [manager nowTime];
}

////////////////////////////////////////////////////////////////////////////////
// @manager
////////////////////////////////////////////////////////////////////////////////

- (SndStreamManager*) manager
{
    return [[manager retain] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// welcomeClientWithBuffer:manager:
////////////////////////////////////////////////////////////////////////////////

- welcomeClientWithBuffer: (SndAudioBuffer*) buff manager: (SndStreamManager*) m
{
    // The client shouldn't be active when we are welcoming it with a new manager.
    if(!active) {
        exposedOutputBuffer = buff;
        [exposedOutputBuffer retain];

        if (needsInput) {
            int i;
            [pendingOutputBuffersLock lock];
            [pendingOutputBuffersLock unlockWithCondition: SC_noData];

            [processedInputBuffersLock lock];
            for (i = 0; i < numInputBuffers; i++) 
              [processedInputBuffers addObject: [buff copy]];
            [processedInputBuffersLock unlockWithCondition: SC_hasData];

#if SNDSTREAMCLIENT_DEBUG            
            NSLog(@"Allocated %i input buffers",[processedInputBuffers count]);
#endif            
        }

        if (generatesOutput) {
            int i;
            [pendingOutputBuffersLock lock];
            for (i = 0; i < numOutputBuffers - 1; i++)  
              [pendingOutputBuffers addObject: [buff copy]];
            [pendingOutputBuffersLock unlockWithCondition: SC_hasData];
            
        }
        
        [self prepareToStreamWithBuffer: buff];
        [self setManager: m];
        
        clientNowTime = [m nowTime]; // reset nowTime to the manager's sense of time

        [NSThread detachNewThreadSelector: @selector(processingThread)
                                 toTarget: self
                               withObject: nil];
        return self;
    }
    else {
        NSLog(@"SndStreamClient::welcomeClientWithBuffer - Warn: Couldn't welcome client with buffer since it's already active!\n");
        return nil;
    }
}

////////////////////////////////////////////////////////////////////////////////
// startProcessingNextBufferWithInput:
//
// If input isn't needed, ignore!!! (eg, if this isn't an FX unit)
//
// Note! we do NOT adjust the client time here, as this is called by the
// possibly behind-the-synthesis-time-front manager.
////////////////////////////////////////////////////////////////////////////////

- startProcessingNextBufferWithInput: (SndAudioBuffer*) inB nowTime: (double) t
{
    int ic = 0, oc = 0;
    // swap the synth and output buffers, fire off next round of synthing   
    
    if (generatesOutput)
    {
//        NSLog(@"startprocessing: stage1");
      [processedOutputBuffersLock lock];
      oc = [processedOutputBuffers count];
      [processedOutputBuffersLock unlock];
          
#if SNDSTREAMCLIENT_DEBUG            
      fprintf(stderr,"[%s] time: %f Processed: %i Pending: %i \n", [clientName cString], t, oc, [pendingOutputBuffers count]);
#endif          
      if (oc > 0) {
        [pendingOutputBuffersLock lock];
        [pendingOutputBuffers addObject: exposedOutputBuffer];            
        [exposedOutputBuffer release];
        [pendingOutputBuffersLock unlockWithCondition: SC_hasData];
              
        [processedOutputBuffersLock lock];
        exposedOutputBuffer = [[processedOutputBuffers objectAtIndex: 0] retain];
        [processedOutputBuffers removeObjectAtIndex: 0];
        [processedOutputBuffersLock unlock];
//              NSLog(@"swapped buffers");
      }
      else if (bDelegateRespondsToOutputBufferSkipSelector)
        [delegate outputBufferSkipped: self];
      else {
            NSLog(@"[%@] SndStreamClient::startProcessingNextBuffer - Error: Skipped output buffer - CPU choked?", clientName);
      }    
//          NSLog(@"startprocessing: stage2");
    }

    // printf("startProcessingNextBufferWithInput nowTime = %f\n", t);
    if (needsInput) {
      if (inB == nil)
        NSLog(@"SndStreamClient::startProcessingNextBuffer - Error: inBuffer is nil!\n");
      else {
        [processedInputBuffersLock lock];
        ic = [processedInputBuffers count];
        [processedInputBuffersLock unlock];
            
        if (ic) {
          SndAudioBuffer *inBloc = nil;
          [processedInputBuffersLock lock];
          inBloc = [[processedInputBuffers objectAtIndex: 0] retain];
          [processedInputBuffers removeObjectAtIndex: 0];
          [processedInputBuffersLock unlock];

          [inBloc copyData: inB];
                
          [pendingInputBuffersLock lock];
          [pendingInputBuffers addObject: inBloc];
          [inBloc release];
          [pendingInputBuffersLock unlockWithCondition: SC_hasData];
        }
        else if (bDelegateRespondsToInputBufferSkipSelector)
          [delegate inputBufferSkipped: self];
        else {
//              NSLog(@"[%@] SndStreamClient::startProcessingNextBuffer - Error: Skipped input buffer - CPU choked?", clientName);
        }
      }
    }
  
    if (bDisconnect) {
      if (ic == 0 && oc == 0) {
        [manager removeClient: self];
        [self setManager: nil];
        [self freeBufferMem];
        [self didFinishStreaming];
        bDisconnect = FALSE;
      }
    }
/*
    fprintf(stderr,"Input: pending:%i processed:%i  Output: pending:%i processed:%i\n",
            [pendingInputBuffers count],  [processedInputBuffers count],
            [pendingOutputBuffers count], [processedOutputBuffers count]);
*/
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

        [synthThreadLock lock];

        if (generatesOutput) {
          [pendingOutputBuffersLock lockWhenCondition: SC_hasData];
          synthOutputBuffer = [[[pendingOutputBuffers objectAtIndex: 0] retain] zero];
          [pendingOutputBuffers removeObjectAtIndex: 0];
          [pendingOutputBuffersLock unlockWithCondition: ([pendingOutputBuffers count] > 0 ? SC_hasData : SC_noData)];
        }
        if (needsInput) {
          [pendingInputBuffersLock lockWhenCondition: SC_hasData];
          synthInputBuffer = [[pendingInputBuffers objectAtIndex: 0] retain];
          [pendingInputBuffers removeObjectAtIndex: 0];
          [pendingInputBuffersLock unlockWithCondition: ([pendingInputBuffers count] > 0 ? SC_hasData : SC_noData)];
        }
//      NSLog(@"SYNTH THREAD: going to processBuffers\n");
                        
        [self processBuffers];

//        NSLog(@"SYNTH THREAD: ... done processBuffers\n");
        if (synthOutputBuffer != nil) {
          [processorChain processBuffer: synthOutputBuffer forTime: clientNowTime];
        }        
        if (processFinishedCallback != NULL)
            processFinishedCallback(); // SKoT: should this be a selector, hmm hmm...?
            
        if (generatesOutput) {
          [processedOutputBuffersLock lock];
          [processedOutputBuffers addObject: synthOutputBuffer];
          clientNowTime = [self streamTime]  + [synthOutputBuffer duration] * [processedOutputBuffers count];
          [synthOutputBuffer release];    
          [processedOutputBuffersLock unlockWithCondition: SC_hasData];
        }
        else
          clientNowTime += [synthOutputBuffer duration];
          
        if (needsInput) {
          [processedInputBuffersLock lock];
          [processedInputBuffers addObject: synthInputBuffer];
          [synthInputBuffer release];    
          [processedInputBuffersLock unlockWithCondition: SC_hasData];

//        fprintf(stderr,"[%s] time: %f Processed: %i Pending: %i \n", [clientName cString], clientNowTime, 
//                        [processedOutputBuffers count], [pendingOutputBuffers count]);

        }
        [synthThreadLock unlock];
    }
    bDisconnect = TRUE;
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
  NSLog(@"SndStreamClient::processBuffers - Warn: base class method is being called - have you remembered to override this in your stream client?");
}

////////////////////////////////////////////////////////////////////////////////
// outputBuffer
////////////////////////////////////////////////////////////////////////////////

- (SndAudioBuffer*) outputBuffer
{
  return exposedOutputBuffer;
}

////////////////////////////////////////////////////////////////////////////////
// synthBuffer
////////////////////////////////////////////////////////////////////////////////

- (SndAudioBuffer*) synthOutputBuffer
{
  return synthOutputBuffer;
}

////////////////////////////////////////////////////////////////////////////////
// inputBuffer
////////////////////////////////////////////////////////////////////////////////

- (SndAudioBuffer*) synthInputBuffer
{
  return synthInputBuffer;
}

////////////////////////////////////////////////////////////////////////////////
// managerIsShuttingDown
////////////////////////////////////////////////////////////////////////////////

- managerIsShuttingDown
{
    // Need lock to make sure the synthesis thread is paused before shutting down!
    [synthThreadLock lock];
    active = FALSE;
    [synthThreadLock unlock];
    
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
  //[outputBufferLock lock];
  return self;
}

- unlockOutputBuffer
{
  //[outputBufferLock unlock];
  return self;
}

/////////////////////////////////////////////////////////////////////////////////
// Input buffer lock / unlock
////////////////////////////////////////////////////////////////////////////////

- lockInputBuffer
{
//  [inputBufferLock lock];
  return self;
}

- unlockInputBuffer
{
//  [inputBufferLock unlock];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// @audioProcessorChain
////////////////////////////////////////////////////////////////////////////////

- (SndAudioProcessorChain*) audioProcessorChain
{
  return [[processorChain retain] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// delegate mutator/accessor methods
////////////////////////////////////////////////////////////////////////////////

- setDelegate: (id) d
{
  delegate = d;
  bDelegateRespondsToOutputBufferSkipSelector = ( delegate != nil && 
      [delegate respondsToSelector: @selector(outputBufferSkipped)] );
  bDelegateRespondsToInputBufferSkipSelector  = ( delegate != nil &&
      [delegate respondsToSelector: @selector(inputBufferSkipped)] );

  return self;
}

- (id) delegate
{
  return delegate;
}

////////////////////////////////////////////////////////////////////////////////

- (int) inputBufferCount
{
  return numInputBuffers;
}

- (int) outputBufferCount
{
  return numOutputBuffers;
}

- (BOOL) setInputBufferCount: (int) n
{
  if (active)
    return FALSE;
  if (n < 2)
    return FALSE;
  numInputBuffers = n;
  return TRUE;
}

- (BOOL) setOutputBufferCount: (int) n
{
  if (active)
    return FALSE;
  if (n < 2)
    return FALSE;
  numOutputBuffers = n;
  return TRUE;
}

- (void) resetTime: (double) originTimeInSeconds
{
//  [synthThreadLock lock];
//  clientNowTime = originTimeInSeconds + [synthOutputBuffer duration] * [processedOutputBuffers count];
//  [synthThreadLock unlock];
}


////////////////////////////////////////////////////////////////////////////////

@end
