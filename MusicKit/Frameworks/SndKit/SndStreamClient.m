////////////////////////////////////////////////////////////////////////////////
//
//  $Id$ 
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>, tomandandy music inc.
//
//  Sat 10-Feb-2001, Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and non-commercial
//  purposes so long as the author attribution and copyright messages remain intact and
//  accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#define SET_MACH_THREAD_PRIORITY 0

#if SET_MACH_THREAD_PRIORITY
#import <mach/mach_init.h>
#import <mach/thread_act.h>
#endif

#include <sys/time.h>

#ifndef __MINGW32__
#import <pthread.h>
#include <sys/resource.h>
#endif

#import <MKPerformSndMIDI/SndStruct.h>
#import "SndAudioBuffer.h"
#import "SndStreamManager.h"
#import "SndStreamClient.h" 
#import "SndAudioBufferQueue.h"

#define SNDSTREAMCLIENT_DEBUG 0

#ifdef __MINGW32__
# import "SndConditionLock.h"
# define NSConditionLock SndConditionLock
#endif

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
    return [SndStreamClient new];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
    Snd *s = [Snd new];
    [s release];

    [super init];
    
    outputQueue = [[SndAudioBufferQueue audioBufferQueueWithLength: 4] retain];
    inputQueue  = [[SndAudioBufferQueue audioBufferQueueWithLength: 4] retain];

    if (synthThreadLock == nil) {
#ifndef __MINGW32__
      synthThreadLock = [[NSConditionLock  alloc] init];
#else
      synthThreadLock = [[SndConditionLock alloc] init];
#endif
    }
    if (outputBufferLock == nil) {
#ifndef __MINGW32__
      outputBufferLock = [[NSConditionLock  alloc] initWithCondition: OB_notInit];
#else
      outputBufferLock = [[SndConditionLock alloc] initWithCondition: OB_notInit];
#endif    
    }
    if (processorChain == nil)
      processorChain = [[SndAudioProcessorChain audioProcessorChain] retain];
      
    exposedOutputBuffer     = nil;
    synthOutputBuffer       = nil;
    active                  = FALSE;
    needsInput              = FALSE;
    generatesOutput         = TRUE;
    processFinishedCallback = NULL;
    manager                 = nil;
    clientName              = nil; 
    
    bDelegateRespondsToOutputBufferSkipSelector = FALSE;
    bDelegateRespondsToInputBufferSkipSelector  = FALSE;

    return self;
}

////////////////////////////////////////////////////////////////////////////////
// clientName
////////////////////////////////////////////////////////////////////////////////

- (NSString*) clientName
{
  return clientName;
}

- setClientName: (NSString*) name
{
  if (clientName != nil)
    [clientName release];
  clientName = [name retain];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
#if SNDSTREAMCLIENT_DEBUG            
      fprintf(stderr,"[%s] dealloc: 1\n", [clientName cString]);
#endif          

    [self freeBufferMem];
    
    [outputQueue release];
    [inputQueue  release];

#if SNDSTREAMCLIENT_DEBUG            
      fprintf(stderr,"[%s] dealloc: 2\n", [clientName cString]);
#endif          

    if (processorChain)
        [processorChain release];
        
    if (synthThreadLock)
        [synthThreadLock release];    
        
    if (outputBufferLock)    
        [outputBufferLock release];    
    
#if SNDSTREAMCLIENT_DEBUG            
      fprintf(stderr,"[%s] dealloc: 3\n", [clientName cString]);
#endif          
    [clientName release];

    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// description
////////////////////////////////////////////////////////////////////////////////

- (NSString*) description
{
  return [NSString stringWithFormat: @"%s: %sactive, nowTime: %.3f, input: %s output: %s",
    (clientName == nil ? "SndStreamClient" : [clientName cString]),
    (active ? "" : "in"),
    [self synthesisTime], needsInput ? "YES" : "NO", generatesOutput ? "YES" : "NO"];
}

////////////////////////////////////////////////////////////////////////////////
// @freeBufferMem
////////////////////////////////////////////////////////////////////////////////

- freeBufferMem
{
    [outputQueue freeBuffers];
    if (synthOutputBuffer)
        [synthOutputBuffer release];
    synthOutputBuffer   = nil;

    [inputQueue freeBuffers];
    if (synthInputBuffer)
        [synthInputBuffer  release];
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
        manager = m;
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
    if (manager == nil) {
      NSLog(@"SndStreamClient::streamTime - ERROR: Trying to access manager when not connected (nil)\n");
      return 0.0;
    }
    else
      return [manager nowTime];
}

////////////////////////////////////////////////////////////////////////////////
// manager
////////////////////////////////////////////////////////////////////////////////

- (SndStreamManager*) manager
{
    if (manager == nil) {
      NSLog(@"SndStreamClient::manager - WARNING: Trying to access manager when not connected (nil)\n");
      return nil;
    }
    else
      return [[manager retain] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// welcomeClientWithBuffer:manager:
////////////////////////////////////////////////////////////////////////////////

- welcomeClientWithBuffer: (SndAudioBuffer*) buff manager: (SndStreamManager*) m
{
    // The client shouldn't be active when we are welcoming it with a new manager.
    if(!active) {
        [outputBufferLock lockWhenCondition: OB_notInit];
        exposedOutputBuffer = buff;
        [exposedOutputBuffer retain];
        [outputBufferLock unlockWithCondition: OB_isInit];

        if (needsInput) {
            [inputQueue prepareQueueAsType: audioBufferQueue_typeInput withBufferPrototype: buff];
        }
        if (generatesOutput) {
            [outputQueue prepareQueueAsType: audioBufferQueue_typeOutput withBufferPrototype: buff];
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
        oc = [outputQueue processedBuffersCount];
#if SNDSTREAMCLIENT_DEBUG            
      fprintf(stderr,"[%s] time: %3.3f [output] Processed: %i Pending: %i \n", [clientName cString], t, oc, [outputQueue pendingBuffersCount]);
#endif          

      if (oc > 0) {
        [outputQueue addPendingBuffer: exposedOutputBuffer];
        [exposedOutputBuffer autorelease];        
        exposedOutputBuffer = [[outputQueue popNextProcessedBuffer] retain];
      }
      else if (bDelegateRespondsToOutputBufferSkipSelector) {
        [delegate outputBufferSkipped: self];
      }
      else if (active) {
#if SNDSTREAMCLIENT_DEBUG            
        fprintf(stderr,"[%s] SndStreamClient::startProcessingNextBuffer - Error: Skipped output buffer - CPU choked? \n", [clientName cString]);
#endif
      }    
#if SNDSTREAMCLIENT_DEBUG                  
      fprintf(stderr,"startprocessing: stage2\n");
#endif
    }
       
#if SNDSTREAMCLIENT_DEBUG                  
    // printf("startProcessingNextBufferWithInput nowTime = %f\n", t);
#endif
    if (needsInput) {
      if (inB == nil)
        fprintf(stderr,"[%s] SndStreamClient::startProcessingNextBuffer - Error: inBuffer is nil!\n", [clientName cString]);
      else {
        ic = [inputQueue processedBuffersCount];
        
        if (ic) {
          SndAudioBuffer *inBloc = [[inputQueue popNextProcessedBuffer] retain];
          [inBloc copyData: inB];
          [inputQueue addPendingBuffer: inBloc];                      
          [inBloc autorelease];
        }
        else if (bDelegateRespondsToInputBufferSkipSelector)
          [delegate inputBufferSkipped: self];
        else if (active) {
#if SNDSTREAMCLIENT_DEBUG                  
          fprintf(stderr,"[%s] SndStreamClient::startProcessingNextBuffer - Error: Skipped input buffer - CPU choked?", [clientName cString]);
#endif
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
#if SNDSTREAMCLIENT_DEBUG            
    fprintf(stderr,"[%s] SndStreamClient: disconnected\n", [clientName cString]);                       
#endif        
      }
    }
#if SNDSTREAMCLIENT_DEBUG                  
    fprintf(stderr,"[%s] Input: pending:%i processed:%i  Output: pending:%i processed:%i\n", [clientName cString],
            [inputQueue pendingBuffersCount],  [inputQueue processedBuffersCount],
            [outputQueue pendingBuffersCount], [outputQueue processedBuffersCount]);
#endif        

    return self;
}

////////////////////////////////////////////////////////////////////////////////
// processingThread
////////////////////////////////////////////////////////////////////////////////

- (void) processingThread
{
    NSAutoreleasePool *localPool = [NSAutoreleasePool new];
    NSAutoreleasePool *innerPool;
    
    [self retain];

    {
      /*
      int r;
      pthread_t threadID = pthread_self();
      struct sched_param param;
      param.sched_priority = 90;
      r = pthread_setschedparam(threadID, SCHED_OTHER, &param);
      fprintf(stderr,"Thread priority change returned: %i\n",r);

      */
/*
#if SET_MACH_THREAD_PRIORITY
      thread_precedence_policy_data_t policy_data;
      policy_data.importance = 71;

      thread_policy_set(  mach_thread_self(),
                          THREAD_PRECEDENCE_POLICY,
                          (thread_policy_t) &policy_data ,
                          THREAD_PRECEDENCE_POLICY_COUNT );
      
      setpriority(0, 0, 70);
#endif
 */
    }
    active = TRUE;
#if SNDSTREAMCLIENT_DEBUG                  
//    NSLog(@"SYNTH THREAD: starting processing thread (thread id %p)\n",objc_thread_id());
#endif        
    while (active) {
      innerPool = [NSAutoreleasePool new];
      if (generatesOutput) {
          synthOutputBuffer = [[[outputQueue popNextPendingBuffer] retain] zero];
        }
        if (needsInput) {
          synthInputBuffer = [[inputQueue popNextPendingBuffer] retain];
        }
#if SNDSTREAMCLIENT_DEBUG                  
        fprintf(stderr,"[%s] SYNTH THREAD: going to processBuffers\n", [clientName cString]);
#endif                        
        [synthThreadLock lock];
#if SNDSTREAMCLIENT_DEBUG
        fprintf(stderr,"[%s] SYNTH THREAD: ... LOCKED\n", [clientName cString]);
#endif
        {
          NSAutoreleasePool *innerPool2 = [[NSAutoreleasePool alloc] init];
          [self processBuffers];
          [innerPool2 release];
        }
#if SNDSTREAMCLIENT_DEBUG                  
        fprintf(stderr,"[%s] SYNTH THREAD: ... done processBuffers\n", [clientName cString]);
#endif
        if (synthOutputBuffer != nil) {
          [processorChain processBuffer: synthOutputBuffer forTime: clientNowTime];
        }        
        if (processFinishedCallback != NULL)
            processFinishedCallback(); // SKoT: should this be a selector, hmm hmm...?
            
        if (generatesOutput) {
          clientNowTime = [self streamTime]  + [synthOutputBuffer duration] * [outputQueue processedBuffersCount];
          [outputQueue addProcessedBuffer: synthOutputBuffer];
          [synthOutputBuffer release];    
        }
        else {
          clientNowTime += [synthOutputBuffer duration];
        }

        [synthThreadLock unlock];

#if SNDSTREAMCLIENT_DEBUG
        fprintf(stderr,"[%s] SYNTH THREAD: ... UNLOCKED\n", [clientName cString]);
#endif
        
        if (needsInput) {
          [inputQueue addProcessedBuffer: synthInputBuffer];
          [synthInputBuffer release];    
        }
        [innerPool release];
    }
    bDisconnect = TRUE;
    [self autorelease];
    [localPool release];
#if SNDSTREAMCLIENT_DEBUG            
    fprintf(stderr,"[%s] SndStreamClient: processing thread stopped\n", [clientName cString]);                       
#endif
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
  return [[exposedOutputBuffer retain] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// synthBuffer
////////////////////////////////////////////////////////////////////////////////

- (SndAudioBuffer*) synthOutputBuffer
{
  return [[synthOutputBuffer retain] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// inputBuffer
////////////////////////////////////////////////////////////////////////////////

- (SndAudioBuffer*) synthInputBuffer
{
  return [[synthInputBuffer retain] autorelease];
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
// audioProcessorChain
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
// input/output buffer queue length accessors
////////////////////////////////////////////////////////////////////////////////

- (int) inputBufferCount
{
  return [inputQueue bufferCount];
}

- (int) outputBufferCount
{
  return [outputQueue bufferCount];
}
 
////////////////////////////////////////////////////////////////////////////////
// input/output buffer queue length mutators
////////////////////////////////////////////////////////////////////////////////

- (BOOL) setInputBufferCount: (int) n
{
  if (active)
    return FALSE;
  if (n < 2)
    return FALSE;
  [inputQueue initQueueWithLength: n];
  return TRUE;
}

- (BOOL) setOutputBufferCount: (int) n
{
  if (active)
    return FALSE;
  if (n < 2)
    return FALSE;
  [outputQueue initQueueWithLength: n];
  return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
// resetTime:
////////////////////////////////////////////////////////////////////////////////

- (void) resetTime: (double) originTimeInSeconds
{
  [synthThreadLock lock];
  clientNowTime = originTimeInSeconds + [synthOutputBuffer duration] * [outputQueue processedBuffersCount];
  [synthThreadLock unlock];
}

////////////////////////////////////////////////////////////////////////////////
// outputLatencyInSeconds
////////////////////////////////////////////////////////////////////////////////

- (double) outputLatencyInSeconds
{
  if (exposedOutputBuffer != nil) {
      double latency = [outputQueue bufferCount] * [exposedOutputBuffer duration];
      return latency;
  }
  else
      return 0.0f;
}

////////////////////////////////////////////////////////////////////////////////

@end
