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

#ifndef __MINGW32__
 #define SET_THREAD_PRIORITY 1
#endif

#if SET_THREAD_PRIORITY
 #include <sched.h>
 #if (defined(__ppc__) && defined(__APPLE__))
  #include <mach/mach_init.h>
  #include <mach/task_policy.h>
  #include <mach/thread_act.h>
  #include <mach/thread_policy.h>
  #include <sys/sysctl.h>
 #endif
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
#import "SndAudioProcessorChain.h"
#import "SndAudioBufferQueue.h"

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

    // Modern audio hardware can have quite small buffers (i.e 4096 bytes), yet we want to do
    // increasing more complex processing, so we settle for many small buffers, given we now have a preemption
    // mechanism.
    outputQueue = [[SndAudioBufferQueue audioBufferQueueWithLength: 8] retain];
    inputQueue  = [[SndAudioBufferQueue audioBufferQueueWithLength: 8] retain];

    if (synthThreadLock == nil) {
      synthThreadLock = [[NSConditionLock alloc] init];
    }
    if (outputBufferLock == nil) {
      outputBufferLock = [[NSConditionLock alloc] initWithCondition: OB_notInit];
    }
    if (processorChain == nil)
      processorChain = [[SndAudioProcessorChain audioProcessorChain] retain];
      
    exposedOutputBuffer     = nil;
    synthOutputBuffer       = nil;
    active                  = FALSE;
    needsInput              = FALSE;
    generatesOutput         = TRUE;
    manager                 = nil;
    clientName              = nil; 

    delegateRespondsToDidProcessBufferSelector = FALSE;
    delegateRespondsToOutputBufferSkipSelector = FALSE;
    delegateRespondsToInputBufferSkipSelector  = FALSE;

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
      NSLog(@"[%@] dealloc: 1\n", clientName);
#endif          

    [self freeBufferMem];
    
    [outputQueue release];
    [inputQueue  release];

#if SNDSTREAMCLIENT_DEBUG            
      NSLog(@"[%@] dealloc: 2\n", clientName);
#endif          

    if (processorChain)
        [processorChain release];
        
    if (synthThreadLock)
        [synthThreadLock release];    
        
    if (outputBufferLock)    
        [outputBufferLock release];    
    
#if SNDSTREAMCLIENT_DEBUG            
      NSLog(@"[%@] dealloc: 3\n", clientName);
#endif          
    [clientName release];

    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// description
////////////////////////////////////////////////////////////////////////////////

- (NSString *) description
{
    return [NSString stringWithFormat: @"%@:%@ %sactive, nowTime: %.3f, input: %s output: %s",
	[super description],
	(clientName != nil ? clientName : @""),
	(active ? "" : "in"),
	[self synthesisTime],
	needsInput ? "YES" : "NO",
	generatesOutput ? "YES" : "NO"];
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
        NSLog(@"SndStreamClient::setGeneratesOutput - Warn: Can't change generatesOutput whilst streaming!");
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
        exposedOutputBuffer = [buff retain];
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

- offlineProcessBuffer: (SndAudioBuffer*) anAudioBuffer nowTime: (double) t
{
  SndAudioBuffer *tempBuffer = synthOutputBuffer;
  clientNowTime = t;
  synthOutputBuffer = anAudioBuffer;
  [self processBuffers];
  [processorChain processBuffer: anAudioBuffer forTime: clientNowTime];
  synthOutputBuffer = tempBuffer;
  return self;
}

// Retire exposedOutputBuffer to the pending section of the queue, expose the next processed buffer.
- (void) rotateOutputBuffer
{
    [outputQueue addPendingBuffer: exposedOutputBuffer];
    [exposedOutputBuffer release];
    exposedOutputBuffer = [[outputQueue popNextProcessedBuffer] retain];
}

// Any audio buffers which have been processed and awaiting to be retrieved by the
// SndStreamMixer/SndStreamManager are preempted, forcing new buffers then created to be retrieved sooner.
- (double) preemptQueuedStream
{
    double processedBufferDuration = 0.0;

    if (generatesOutput) {
	// Update clientNowTime backwards, as we are throwing away the number of processed buffers each time we preempt
	// since the buffer retrieval is determined from the clientNowTime.
	processedBufferDuration = [self outputLatencyInSeconds];

	[synthThreadLock lock];
#if SNDSTREAMCLIENT_DEBUG
	NSLog(@"clientNowTime was %lf, synthOutputBuffer duration %lf, exposedOutputBuffer duration %lf, outputQueue processed buffers count %d\n", clientNowTime, [synthOutputBuffer duration], [exposedOutputBuffer duration], [outputQueue processedBuffersCount]);
#endif
	clientNowTime -= processedBufferDuration;

#if SNDSTREAMCLIENT_DEBUG
	NSLog(@"processedBufferDuration = %lf, clientNowTime is %lf\n", processedBufferDuration, clientNowTime);
#endif
	[synthThreadLock unlock];
	
	[self lockOutputBuffer];
	[outputQueue cancelProcessedBuffers];
	// Retire exposedOutputBuffer to the pending section of the queue, so we get the new processed buffer.
	// Retrieve the new processed buffer, which may be new if the synthesis thread has kicked in, or just the same one as before.
	[self rotateOutputBuffer];
	[self unlockOutputBuffer];
#if SNDSTREAMCLIENT_DEBUG
	NSLog(@"New exposed output buffer = %@\n", exposedOutputBuffer);
#endif
    }
    if (needsInput) {
	// TODO Need to check this is even meaningful...
	NSLog(@"SndStreamClient::preemptQueuedStream need to implement preemption of queued input streams.\n");
	// [inputQueue cancelProcessedBuffers];
    }
#if SNDSTREAMCLIENT_DEBUG
    NSLog(@"[%@] preemptQueuedStream outputQueue %@, by %lf seconds\n", clientName, outputQueue, processedBufferDuration);
#endif
    return processedBufferDuration;
}

////////////////////////////////////////////////////////////////////////////////
// startProcessingNextBufferWithInput:
// Swap the synth and output buffers, fire off next round of synthing.  
//
// If input isn't needed, just ignore it (eg, if this isn't an FX unit).
//
// Note we do NOT adjust the client time here, as this is called by the
// possibly behind-the-synthesis-time-front manager.
////////////////////////////////////////////////////////////////////////////////

- startProcessingNextBufferWithInput: (SndAudioBuffer*) inB nowTime: (double) t
{
    int processedInputBuffersCount = 0, processedOutputBuffersCount = 0;

    // If this client is to generate output then we rotate the next buffer ready for retrieval by the SndStreamMixer.
    if (generatesOutput) {
        processedOutputBuffersCount = [outputQueue processedBuffersCount];
#if SNDSTREAMCLIENT_DEBUG
	NSLog(@"[%@] time: %3.3f outputQueue %@\n", clientName, t, outputQueue);
#endif

	if (processedOutputBuffersCount > 0) {
	    // Retire exposedOutputBuffer to the pending section of the queue, expose the next
	    // processed buffer to retrieval (using the method outputBuffer).
	    [self lockOutputBuffer];
	    [self rotateOutputBuffer];
	    [self unlockOutputBuffer];
	}
	else if (delegateRespondsToOutputBufferSkipSelector) {
#if SNDSTREAMCLIENT_DEBUG
	    NSLog(@"[%@] SndStreamClient::startProcessingNextBuffer - Error: Skipped output buffer - CPU choked? delegating\n", clientName);
#endif
	    [delegate outputBufferSkipped: self];
	}
	else if (active) {
#if SNDSTREAMCLIENT_DEBUG
	    NSLog(@"[%@] SndStreamClient::startProcessingNextBuffer - Error: Skipped output buffer - CPU choked?\n", clientName);
#endif
	}
    }

#if SNDSTREAMCLIENT_DEBUG                  
    NSLog(@"startProcessingNextBufferWithInput nowTime = %f\n", t);
#endif
    // If this client processes received input audio, copy the newly received audio buffer into the exposed buffer of the input queue.
    if (needsInput) {
	if (inB == nil)
	    NSLog(@"[%@] SndStreamClient::startProcessingNextBuffer - Error: inBuffer is nil yet client needs input!\n", clientName);
	else {
	    processedInputBuffersCount = [inputQueue processedBuffersCount];

	    if (processedInputBuffersCount) {
		// TODO check why we need to retain it here and then release it at the end of the buffer, for copyData: or addPendingBuffer:?
		SndAudioBuffer *exposedInputBuffer = [[inputQueue popNextProcessedBuffer] retain];

		// TODO perhaps we could eventually just add the inB into the inputQueue, rather than copying it.
		[exposedInputBuffer copyData: inB];
		// Add the exposed input buffer with the new audio data back into the queue.
		[inputQueue addPendingBuffer: exposedInputBuffer];
		[exposedInputBuffer autorelease];
	    }
	    else if (delegateRespondsToInputBufferSkipSelector)
		[delegate inputBufferSkipped: self];
	    else if (active) {
#if SNDSTREAMCLIENT_DEBUG
		NSLog(@"[%@] SndStreamClient::startProcessingNextBuffer - Error: Skipped input buffer - CPU choked?", clientName);
#endif
	    }
	}
    }

    if (bDisconnect) {
	if (processedInputBuffersCount == 0 && processedOutputBuffersCount == 0) {
	    [manager removeClient: self];
	    [self setManager: nil];
	    [self freeBufferMem];
	    [self didFinishStreaming];
	    bDisconnect = FALSE;
#if SNDSTREAMCLIENT_DEBUG
	    NSLog(@"[%@] SndStreamClient: disconnected\n", clientName);
#endif
	}
    }
#if SNDSTREAMCLIENT_DEBUG
    NSLog(@"[%@] Input: %@ Output: %@\n", clientName, inputQueue, outputQueue);
#endif

    return self;
}

#ifdef SET_THREAD_PRIORITY
#if (defined(__ppc__) && defined(__APPLE__))
int get_bus_speed()
{
    int mib[2]; // Management Information Base
    unsigned int miblen;
    int busSpeed;
    int retval;
    size_t len;

    mib[0] = CTL_HW;
    mib[1] = HW_BUS_FREQ;
    miblen = 2;
    len = 4;
    retval = sysctl(mib, miblen, &busSpeed, &len, NULL, 0);

    /* check retval to ensure we got a valid bus speed, see man 3 sysctl for info */
    if(retval != 0) {
	NSLog(@"Unable to obtain bus speed!\n");
	return 0;
    }
    else {
	//NSLog(@"bus speed %d\n", busSpeed);
	return busSpeed;
    }
}

#endif

static void inline setThreadPriority()
{
#if (defined(__ppc__) && defined(__APPLE__))
    struct thread_time_constraint_policy ttcpolicy;
    kern_return_t theError;

    /* This is in AbsoluteTime units, which are equal to
	1/4 the bus speed on most machines. */
    
    // hard-coded numbers are approximations for 100 MHz bus speed.
    // assume that app deals in frame-sized chunks, e.g. 30 per second.
    // ttcpolicy.period=833333;
    ttcpolicy.period = (get_bus_speed() / 30 * 4);
    // ttcpolicy.period = (get_bus_speed() / (60 * 4));
    // ttcpolicy.computation=60000;
    ttcpolicy.computation = (get_bus_speed() / (360 * 4));
    // ttcpolicy.computation = (get_bus_speed() / (720 * 4));
    // ttcpolicy.constraint=120000;
    ttcpolicy.constraint = (get_bus_speed() / (180 * 4));
    // ttcpolicy.constraint = (get_bus_speed() / (360 * 4));
    ttcpolicy.preemptible = 1;

    theError = thread_policy_set(mach_thread_self(),
				 THREAD_TIME_CONSTRAINT_POLICY, (int *)&ttcpolicy,
				 THREAD_TIME_CONSTRAINT_POLICY_COUNT);

    if (theError != KERN_SUCCESS)
	NSLog(@"Can't do thread_policy_set\n");
#if SNDSTREAMCLIENT_DEBUG
    {
	UInt64 nanoseconds = (UInt64) 33333333;
	AbsoluteTime abso = NanosecondsToAbsolute(UInt64ToUnsignedWide(nanoseconds));
	UInt64 abso2 = UnsignedWideToUInt64(abso);
	NSLog(@"cast absolute time period is %ld\n", (uint32_t) abso2);
    }
    NSLog(@"bus speed = %d, period = %d, computation = %d, constraint = %d\n",
	  get_bus_speed(), ttcpolicy.period, ttcpolicy.computation, ttcpolicy.constraint);
#endif
#else  /* POSIX_RT, must be running with root privileges */
#ifndef __MINGW32__
    struct sched_param sp;
    int theError;

    memset(&sp, 0, sizeof(struct sched_param));
    sp.sched_priority = sched_get_priority_min(SCHED_FIFO);
    theError = sched_setscheduler(0, SCHED_RR, &sp);
    if (theError == -1)
	NSLog(@"Can't get real-time priority, errno = %d, min priority = %d\n",errno,sp.sched_priority);
#else
    int theError = sched_setscheduler(getpid(), SCHED_RR);
    if (theError == -1)
	NSLog(@"Can't get real-time priority, errno = %d, min priority = %d\n",errno,sp.sched_priority);
#endif
#endif
}

#endif

////////////////////////////////////////////////////////////////////////////////
// processingThread
////////////////////////////////////////////////////////////////////////////////

- (void) processingThread
{
    NSAutoreleasePool *localPool = [NSAutoreleasePool new];
    NSAutoreleasePool *innerPool;

    [self retain];

#ifdef SET_THREAD_PRIORITY
    setThreadPriority();
#endif
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
        NSLog(@"[%@] SYNTH THREAD: going to processBuffers\n", clientName);
#endif
        [synthThreadLock lock];
#if SNDSTREAMCLIENT_DEBUG
        NSLog(@"[%@] SYNTH THREAD: ... LOCKED\n", clientName);
#endif
        {
	    NSAutoreleasePool *innerPool2 = [NSAutoreleasePool new];
	    // processBuffers in the sub-class should fill or modify synthOutputBuffer and/or retrieve synthInputBuffer.
	    [self processBuffers];
	    [innerPool2 release];
        }
#if SNDSTREAMCLIENT_DEBUG
        NSLog(@"[%@] SYNTH THREAD: ... done processBuffers\n", clientName);
#endif
        if (synthOutputBuffer != nil) {
	    [processorChain processBuffer: synthOutputBuffer forTime: clientNowTime];
        }
	if (delegateRespondsToDidProcessBufferSelector) {
	    [delegate didProcessStreamBuffer: self];
	}

        if (generatesOutput) {
	    clientNowTime = [self streamTime] + [synthOutputBuffer duration] * [outputQueue processedBuffersCount];
	    [outputQueue addProcessedBuffer: synthOutputBuffer];
	    [synthOutputBuffer release];
	    synthOutputBuffer = nil;
        }
        else {
	    clientNowTime += [synthOutputBuffer duration];
        }

        [synthThreadLock unlock];

#if SNDSTREAMCLIENT_DEBUG
        NSLog(@"[%@] SYNTH THREAD: ... UNLOCKED\n", clientName);
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
    NSLog(@"[%@] SndStreamClient: processing thread stopped\n", clientName);
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
    if(exposedOutputBuffer == nil) {
	// In the case that exposedOutputBuffer is nil, this forces an immediate update from the output queue.
	exposedOutputBuffer = [[outputQueue popNextProcessedBuffer] retain];
    }
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

- (void) setDelegate: (id) d
{
  delegate = d;
  delegateRespondsToOutputBufferSkipSelector = ( delegate != nil && 
      [delegate respondsToSelector: @selector(outputBufferSkipped)] );
  delegateRespondsToInputBufferSkipSelector  = ( delegate != nil &&
      [delegate respondsToSelector: @selector(inputBufferSkipped)] );
  delegateRespondsToDidProcessBufferSelector  = ( delegate != nil &&
	[delegate respondsToSelector: @selector(didProcessStreamBuffer)] );
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
  // This assumes all buffers in the queue are the same length...
  clientNowTime = originTimeInSeconds + [synthOutputBuffer duration] * [outputQueue processedBuffersCount];
  [synthThreadLock unlock];
}

////////////////////////////////////////////////////////////////////////////////
// outputLatencyInSeconds
////////////////////////////////////////////////////////////////////////////////

- (double) outputLatencyInSeconds
{
    if (exposedOutputBuffer != nil) {
        // This assumes all buffers in the queue are the same length...
	double latency = [outputQueue bufferCount] * [exposedOutputBuffer duration];
	return latency;
    }
    else
	return 0.0f;
}

- (long) outputLatencyInSamples
{
    if (exposedOutputBuffer != nil) {
	// This assumes all buffers in the queue are the same length...
	long latency = [exposedOutputBuffer lengthInSampleFrames] * [outputQueue bufferCount];
	return latency;
    }
    else
	return 0;
}


////////////////////////////////////////////////////////////////////////////////

@end
