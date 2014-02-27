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

#define SET_THREAD_PRIORITY 1

#if SET_THREAD_PRIORITY
 #if defined(__APPLE__)
  #include <mach/mach_init.h>
  #include <mach/task_policy.h>
  #include <mach/thread_act.h>
  #include <mach/thread_policy.h>
  #include <sys/sysctl.h>
 #else
  #include <sched.h>
 #endif
#endif

#include <sys/time.h>

#import <pthread.h>
#ifndef __MINGW32__
#include <sys/resource.h>
#endif

#import "SndAudioBuffer.h"
#import "SndStreamManager.h"
#import "SndStreamClient.h"
#import "SndAudioProcessorChain.h"
#import "SndAudioBufferQueue.h"

#define SNDSTREAMCLIENT_DEBUG 0
#define SNDSTREAMCLIENT_DEBUG_SYNTHTHREAD 0
#define SNDSTREAMCLIENT_DEBUG_DEALLOC 0
#define SNDSTREAMCLIENT_DEBUG_CONNECTION 0

// This works ok on 667Mhz G4 processors. Slower hardware should require more. YMMV. 
#define DEFAULT_NUMBER_OF_BUFFERS 8

enum {
    SC_connected,
    SC_disconnecting,
    SC_disconnected
};

@implementation SndStreamClient

////////////////////////////////////////////////////////////////////////////////
// streamClient
////////////////////////////////////////////////////////////////////////////////

+ streamClient
{
    return [[[SndStreamClient alloc] init] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
    self = [super init];
    if(self != nil) {
	// Modern audio hardware can have quite small buffers (i.e 4096 bytes), yet we want to do
	// increasingly more complex processing, so we settle for many small buffers, given we now have a preemption
	// mechanism.
	outputQueue = [[SndAudioBufferQueue audioBufferQueueWithLength: DEFAULT_NUMBER_OF_BUFFERS] retain];
	inputQueue  = [[SndAudioBufferQueue audioBufferQueueWithLength: DEFAULT_NUMBER_OF_BUFFERS] retain];
	
	if (synthThreadLock == nil) {
	    synthThreadLock = [[NSConditionLock alloc] init];
	}
	if (outputBufferLock == nil) {
	    outputBufferLock = [[NSConditionLock alloc] initWithCondition: OB_notInit];
	}
	if (managerConnectionLock == nil) {
	    managerConnectionLock = [[NSConditionLock alloc] initWithCondition: SC_disconnected];
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
	lastManagerTime         = -1.0; // So the first received manager time is always the same.
	
	delegateRespondsToDidProcessBufferSelector = FALSE;
	delegateRespondsToOutputBufferSkipSelector = FALSE;
	delegateRespondsToInputBufferSkipSelector  = FALSE;	
    }

    return self;
}

////////////////////////////////////////////////////////////////////////////////
// clientName
////////////////////////////////////////////////////////////////////////////////

- (NSString *) clientName
{
    return clientName;
}

- setClientName: (NSString *) name
{
    if (clientName != nil)
	[clientName release];
    clientName = [name retain];
    return self;
}

/* Frees buffer memory. For internal use only. */
- freeBufferMem
{
    [outputQueue freeBuffers];
    [synthOutputBuffer release];
    synthOutputBuffer = nil;
    
    [inputQueue freeBuffers];
    [synthInputBuffer release];
    synthInputBuffer = nil;
    
    return self;
}

#if SNDSTREAMCLIENT_DEBUG_DEALLOC
- (void) release
{
    NSLog(@"releasing %@ (Thread %@) retain count = %d\n", clientName, [NSThread currentThread], [self retainCount]);
    [super release];
}
#endif

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
#if SNDSTREAMCLIENT_DEBUG_DEALLOC
      NSLog(@"[%@] dealloc: 1, thread %@\n", clientName, [NSThread currentThread]);
#endif          

    [self freeBufferMem];
    
    [outputQueue release];
    outputQueue = nil;
    [inputQueue  release];
    inputQueue = nil;

#if SNDSTREAMCLIENT_DEBUG_DEALLOC
      NSLog(@"[%@] dealloc: 2\n", clientName);
#endif          

    if (processorChain) {
        [processorChain release];
	processorChain = nil;
    }
        
    if (synthThreadLock) {
        [synthThreadLock release];    
	synthThreadLock = nil;
    }
        
    if (outputBufferLock) {
        [outputBufferLock release];    
	outputBufferLock = nil;
    }
    
    if (managerConnectionLock) {
        [managerConnectionLock release];    
	managerConnectionLock = nil;
    }
    
#if SNDSTREAMCLIENT_DEBUG_DEALLOC
      NSLog(@"[%@] dealloc: 3\n", clientName);
#endif          
    [clientName release];
    clientName = nil;

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
// basic mutators
////////////////////////////////////////////////////////////////////////////////

- setNeedsInput: (BOOL) b
{
    if (!active)
        needsInput = b;
    else
        NSLog(@"SndStreamClient -setNeedsInput: Can't change needsInput whilst streaming!");
    return self;
}

- setGeneratesOutput: (BOOL) b 
{
    if (!active)
        generatesOutput = b;
    else
        NSLog(@"SndStreamClient -:setGeneratesOutput: Can't change generatesOutput whilst streaming!");
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
	NSLog(@"SndStreamClient -streamTime: Trying to access manager when not connected (nil)\n");
	return 0.0;
    }
    else
	return [manager nowTime];
}

/*
 Sets the SndStreamManager for this client.
 
 Should never be called from another class, it is invoked as part of the 
 process of a manager welcoming a client into the fray.
 */
- (void) setManager: (SndStreamManager *) newStreamManager
{
    if (!active) {
        manager = newStreamManager; // We don't retain since it would create a retain cycle.
    }
    else
        NSLog(@"SndStreamClient -setManager: Can't setManager whilst streaming!\n");
}

////////////////////////////////////////////////////////////////////////////////
// manager
////////////////////////////////////////////////////////////////////////////////

- (SndStreamManager *) manager
{
    if (manager == nil) {
	NSLog(@"SndStreamClient -manager: Trying to access manager when not connected (nil)\n");
	return nil;
    }
    else
	return [[manager retain] autorelease];  // TODO should we be retaining & autoreleasing here?
}

////////////////////////////////////////////////////////////////////////////////
// welcomeClientWithBuffer:manager:
////////////////////////////////////////////////////////////////////////////////

- welcomeClientWithInputBuffer: (SndAudioBuffer *) inputBuffer 
		  outputBuffer: (SndAudioBuffer *) outputBuffer
		       manager: (SndStreamManager *) streamManager
{
    // The client shouldn't be active when we are welcoming it with a new manager.
    if(!active) {
        [outputBufferLock lockWhenCondition: OB_notInit];
        exposedOutputBuffer = [outputBuffer retain];
        [outputBufferLock unlockWithCondition: OB_isInit];

        if (needsInput) {
            [inputQueue prepareQueueAsType: audioBufferQueue_typeInput withBufferPrototype: inputBuffer];
        }
        if (generatesOutput) {
            [outputQueue prepareQueueAsType: audioBufferQueue_typeOutput withBufferPrototype: outputBuffer];
        }        
        [self prepareToStreamWithBuffer: outputBuffer]; // TODO should separate by input and output buffers.
	[managerConnectionLock lockWhenCondition: SC_disconnected];
        [self setManager: streamManager];
	[managerConnectionLock unlockWithCondition: SC_connected];
	
        clientNowTime = [streamManager nowTime]; // reset nowTime to the manager's sense of time

        [NSThread detachNewThreadSelector: @selector(processingThread)
                                 toTarget: self
                               withObject: nil];
        return self;
    }
    else {
        NSLog(@"SndStreamClient -welcomeClientWithBuffer: Couldn't welcome client with buffer since it's already active!\n");
        return nil;
    }
}

- offlineProcessBuffer: (SndAudioBuffer *) anAudioBuffer nowTime: (double) t
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
	NSLog(@"clientNowTime was %lf, synthOutputBuffer duration %lf, exposedOutputBuffer duration %lf, outputQueue processed buffers count %d\n",
	      clientNowTime, [synthOutputBuffer duration], [exposedOutputBuffer duration], [outputQueue processedBuffersCount]);
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

- (void) disconnectFromManager
{
#if SNDSTREAMCLIENT_DEBUG_CONNECTION
    NSLog(@"%@ About to disconnect from manager, retain count %d\n", self, [self retainCount]);
#endif
    // We disconnect the client from the manager, regardless of how many buffers remain to be processed. These are discarded.
    [manager removeClient: self];
    [self setManager: nil];
    [self freeBufferMem];
    [self didFinishStreaming];
    [outputBufferLock lockWhenCondition: OB_isInit];
    [outputBufferLock unlockWithCondition: OB_notInit]; // declare the output buffer uninitialised in case it is re-welcomed.
#if SNDSTREAMCLIENT_DEBUG_CONNECTION
    NSLog(@"%@ retain count = %d\n", self, [self retainCount]);
    NSLog(@"[%@] disconnected from manager, while %d input, %d output buffers remained to process.\n", 
	  clientName, [inputQueue processedBuffersCount], [outputQueue processedBuffersCount]);
#endif    
}

////////////////////////////////////////////////////////////////////////////////
// startProcessingNextBufferWithInput:
// Swap the synth and output buffers, fire off next round of synthesis (in subclasses).  
//
// If input isn't needed, just ignore it (eg, if this isn't an FX unit).
//
// Note we do NOT adjust the client time here, as this is called by the
// possibly behind-the-synthesis-time-front SndStreamManager.
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startProcessingNextBufferWithInput: (SndAudioBuffer*) inB nowTime: (double) managerTime
{
    int processedInputBuffersCount = 0, processedOutputBuffersCount = 0;

    // If this client is to generate output then we rotate the next buffer ready for retrieval by the SndStreamMixer.
    if (generatesOutput) {
        processedOutputBuffersCount = [outputQueue processedBuffersCount];
#if SNDSTREAMCLIENT_DEBUG
	NSLog(@"[%@] time: %3.3f outputQueue %@\n", clientName, managerTime, outputQueue);
#endif

	if (processedOutputBuffersCount > 0) {
	    // Retire exposedOutputBuffer to the pending section of the queue, expose the next
	    // processed buffer to retrieval (using the method -outputBuffer).
#if SNDSTREAMCLIENT_DEBUG
	    NSLog(@"Rotating output buffer lastManagerTime %lf managerTime %lf\n", lastManagerTime, managerTime);
#endif
	    [self lockOutputBuffer];
	    [self rotateOutputBuffer];
	    [self unlockOutputBuffer];
	}
	else if (delegateRespondsToOutputBufferSkipSelector) {
#if SNDSTREAMCLIENT_DEBUG
	    NSLog(@"[%@] -startProcessingNextBuffer - Error: Skipped output buffer - CPU choked? delegating\n", clientName);
#endif
	    [delegate outputBufferSkipped: self];
	}
	else if (active) {
#if SNDSTREAMCLIENT_DEBUG
	    NSLog(@"[%@] -startProcessingNextBuffer - Error: Skipped output buffer - CPU choked?\n", clientName);
#endif
	}
	lastManagerTime = managerTime;
    }

#if SNDSTREAMCLIENT_DEBUG                  
    NSLog(@"[%@] startProcessingNextBufferWithInput nowTime = %f\n", clientName, managerTime);
#endif
    // If this client processes received input audio, copy the newly received audio buffer into the exposed buffer of the input queue.
    if (needsInput) {
	if (inB == nil)
	    NSLog(@"[%@] -startProcessingNextBuffer - Error: inBuffer is nil yet client needs input!\n", clientName);
	else {
	    processedInputBuffersCount = [inputQueue processedBuffersCount];

	    if (processedInputBuffersCount) {
		// TODO check why we need to retain it here and then release it at the end of the buffer, for copyDataFromBuffer: or addPendingBuffer:?
		SndAudioBuffer *exposedInputBuffer = [[inputQueue popNextProcessedBuffer] retain];

		// TODO perhaps we could eventually just add the inB into the inputQueue, rather than copying it.
		// This requires looking at the persistence of inB.
		// NSLog(@"startProcessingNextBuffer exposedInputBuffer %@ copied from inB %@\n", exposedInputBuffer, inB);
		[exposedInputBuffer copyDataFromBuffer: inB];
		// Add the exposed input buffer with the new audio data back into the queue.
		[inputQueue addPendingBuffer: exposedInputBuffer];
		[exposedInputBuffer autorelease];
	    }
	    else if (delegateRespondsToInputBufferSkipSelector)
		[delegate inputBufferSkipped: self];
	    else if (active) {
#if SNDSTREAMCLIENT_DEBUG
		NSLog(@"[%@] -startProcessingNextBuffer - Error: Skipped input buffer - CPU choked?", clientName);
#endif
	    }
	}
    }

    // NSLog(@"testing the lock for SC_disconnecting state\n");
    if ([managerConnectionLock tryLockWhenCondition: SC_disconnecting]) {
	[self disconnectFromManager];
	[managerConnectionLock unlockWithCondition: SC_disconnected];
	return NO;
    }
    else {
#if SNDSTREAMCLIENT_DEBUG
	NSLog(@"[%@] Input: %@ Output: %@\n", clientName, inputQueue, outputQueue);
#endif
	return YES;
    }
}

#ifdef SET_THREAD_PRIORITY
#if defined(__APPLE__)
int get_bus_speed()
{
    int managementInformationBase[2]; // Management Information Base
    unsigned int mibLength;
    int busSpeed;
    int retval;
    size_t busSpeedLength;

    managementInformationBase[0] = CTL_HW;
    managementInformationBase[1] = HW_BUS_FREQ;
    mibLength = 2;
    busSpeedLength = 4;
    retval = sysctl(managementInformationBase, mibLength, &busSpeed, &busSpeedLength, NULL, 0);

    /* check retval to ensure we got a valid bus speed, see man 3 sysctl for info */
    if(retval != 0 || busSpeedLength != sizeof(int)) {
	// Recent Mac's for some reason do not define their bus speed with HW_BUS_FREQ.
	// In that case, we retrieve the time base frequency "used by the OS and is the basis of all timing services".
#ifdef HW_TB_FREQ
	managementInformationBase[0] = CTL_HW;
	managementInformationBase[1] = HW_TB_FREQ;
	busSpeedLength = 4;
	retval = sysctl(managementInformationBase, mibLength, &busSpeed, &busSpeedLength, NULL, 0);
#endif	
	/* check retval to ensure we got a valid bus speed, see man 3 sysctl for info */
	if(retval != 0 || busSpeedLength != sizeof(int)) {
	    NSLog(@"get_bus_speed() Unable to obtain bus speed!\n");
	    return 0;
	}
    }
    //NSLog(@"get_bus_speed() bus speed %d\n", busSpeed);
    return busSpeed;
}

#endif

static void inline setThreadPriority()
{
#if defined(__APPLE__)
    struct thread_time_constraint_policy ttcpolicy;
    kern_return_t theError;
    int bus_speed = get_bus_speed();

    /* This is in AbsoluteTime units, which are equal to 1/4 the bus speed on most machines. */
    
    // hard-coded numbers are approximations for 100 MHz bus speed.
    // ttcpolicy.period=833333;
    // ttcpolicy.computation=60000;
    // ttcpolicy.constraint=120000;
    
    // assume that app deals in frame-sized chunks, e.g. 30 per second.
    // Unfortunately bus_speed seems no longer supported.
    ttcpolicy.period = (bus_speed / (30 * 4));
    ttcpolicy.computation = (bus_speed / (360 * 4));
    ttcpolicy.constraint = (bus_speed / (180 * 4));

    // assume that app deals in frame-sized chunks, e.g. 30 per second.
    // Doesn't seem to do any conversion from nanoseconds to absolute units.
    // ttcpolicy.period = UnsignedWideToUInt64(NanosecondsToAbsolute(UInt64ToUnsignedWide((UInt64) 1000000000)));
    // 360 per second
    // ttcpolicy.computation = UnsignedWideToUInt64(NanosecondsToAbsolute(UInt64ToUnsignedWide((UInt64) 83333333)));
    // 180 per second
    // ttcpolicy.constraint = UnsignedWideToUInt64(NanosecondsToAbsolute(UInt64ToUnsignedWide((UInt64) 166666666)));

    ttcpolicy.preemptible = 1;
    
    theError = thread_policy_set(mach_thread_self(),
				 THREAD_TIME_CONSTRAINT_POLICY, 
				 (thread_policy_t) &ttcpolicy,
				 THREAD_TIME_CONSTRAINT_POLICY_COUNT);

    if (theError != KERN_SUCCESS)
	NSLog(@"SndStreamClient setThreadPriority(): Can't do thread_policy_set, error %d\n", theError);
#if SNDSTREAMCLIENT_DEBUG
//    {
//	UInt64 nanoseconds = (UInt64) 1000000000;
//	AbsoluteTime abso = NanosecondsToAbsolute(UInt64ToUnsignedWide(nanoseconds));
//	UInt64 abso2 = UnsignedWideToUInt64(abso);
//	NSLog(@"SndStreamClient setThreadPriority(): cast absolute time period is %ld\n", (uint32_t) abso2);
//	NSLog(@"SndStreamClient setThreadPriority(): cast absolute time period is %ld\n", (uint32_t) UnsignedWideToUInt64(AbsoluteToNanoseconds(UInt64ToUnsignedWide((UInt64) 6666666))));
//    }
    NSLog(@"SndStreamClient setThreadPriority(): bus speed = %d, period = %d, computation = %d, constraint = %d\n",
	  bus_speed, ttcpolicy.period, ttcpolicy.computation, ttcpolicy.constraint);
#endif
#else  
/* POSIX_RT, must be running with root privileges, or with ulimit -r hard and soft limits set greater than zero. */
    struct sched_param sp;
    int theError;

#if 0 // Debugging scheduling.
    int policy;
    //struct rlimit rl;

    policy = sched_getscheduler(0); // policy of current process.
    NSLog(@"SndStreamClient setThreadPriority(): current process scheduler policy %d\n", policy);
//    if(getrlimit(RLIMIT_RTPRIO, &rl) != 0)
//	NSLog(@"SndStreamClient setThreadPriority(): Unable to getrlimit\n");
//    else
//	NSLog(@"SndStreamClient setThreadPriority(): rlimit cur %d max %d\n", rl.rlim_cur, rl.rlim_max);
#endif

    memset(&sp, 0, sizeof(struct sched_param));
    sp.sched_priority = sched_get_priority_max(SCHED_RR);
    // Attempt to get the highest priority. This is probably excessive, but for now we'll
    // do it like this. Probably we should set to half the priority range.
    // NSLog(@"SndStreamClient setThreadPriority(): Set thread real-time priority to max priority = %d\n", sp.sched_priority);
    theError = pthread_setschedparam(pthread_self(), SCHED_RR, &sp);
    if (theError == -1) {
	NSLog(@"SndStreamClient setThreadPriority(): Can't set thread real-time priority, errno = %d, max priority = %d\n",
	      errno, sp.sched_priority);
    }
#endif
}

#endif

////////////////////////////////////////////////////////////////////////////////
// processingThread - the synthesis thread. Actual synthesis is done by subclasses in -processBuffers
////////////////////////////////////////////////////////////////////////////////

- (void) processingThread
{
    NSAutoreleasePool *localPool = [NSAutoreleasePool new];

    //[self retain]; // Increase the retain count to avoid NSAutoreleasePool removing this while it's playing.

#ifdef SET_THREAD_PRIORITY
    // It isn't actually possible to escalate the thread priority, so we do so using sched_setscheduler.
    setThreadPriority();
#endif
    [[NSThread currentThread] setName: clientName]; // Just for debugging.
    active = TRUE;
    [managerConnectionLock lockWhenCondition: SC_connected];
#if SNDSTREAMCLIENT_DEBUG_SYNTHTHREAD                  
    NSLog(@"SYNTH THREAD: (%@) starting processing thread\n", [NSThread currentThread]);
#endif
    while (active) {
	NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
	
	if (generatesOutput) {
	    synthOutputBuffer = [[[outputQueue popNextPendingBuffer] retain] zero];
        }
        if (needsInput) {
	    synthInputBuffer = [[inputQueue popNextPendingBuffer] retain];
        }
#if SNDSTREAMCLIENT_DEBUG_SYNTHTHREAD
        NSLog(@"[%@] SYNTH THREAD: preparing to processBuffers\n", clientName);
#endif
        [synthThreadLock lock];
#if SNDSTREAMCLIENT_DEBUG_SYNTHTHREAD
        NSLog(@"[%@] SYNTH THREAD: ... LOCKED\n", clientName);
#endif
        {
	    NSAutoreleasePool *innerPool2 = [NSAutoreleasePool new];
	    
	    // processBuffers in the sub-class should fill or modify synthOutputBuffer and/or retrieve synthInputBuffer.
	    [self processBuffers];
	    [innerPool2 release];
        }
#if SNDSTREAMCLIENT_DEBUG_SYNTHTHREAD
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

#if SNDSTREAMCLIENT_DEBUG_SYNTHTHREAD
        NSLog(@"[%@] SYNTH THREAD: ... UNLOCKED\n", clientName);
#endif

        if (needsInput) {
	    [inputQueue addProcessedBuffer: synthInputBuffer];
	    [synthInputBuffer release];
        }
        [innerPool release];
    }
    [managerConnectionLock unlockWithCondition: SC_disconnecting];
    [managerConnectionLock lockWhenCondition: SC_disconnected];
    //[self release]; // Reduce the retain count now the thread is finishing.
    [localPool release];
    [managerConnectionLock unlockWithCondition: SC_disconnected];
#if SNDSTREAMCLIENT_DEBUG_SYNTHTHREAD
    NSLog(@"SYNTH THREAD: (%@ %@) processing thread ended\n", [NSThread currentThread], clientName);
#endif
    // TODO Exiting this method will exit the thread, but on GNUstep, perhaps we need to be explicit
    // about ending the thread?
    // [NSThread exit];
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

// Place synthOutputBuffer on the processed section of the queue, replace with the next pending buffer.
- (void) rotateSynthOutputBuffer
{
    // This should be locked by the synthThreadLock, but since we expect it to be run from within subclass -processBuffers
    // which will already be protected by a lock, we leave it unprotected.
    // [synthThreadLock lock];
    // TODO we could update the clientNowTime, but it is updated correctly in -processingThread.
    [outputQueue addProcessedBuffer: synthOutputBuffer];
    [synthOutputBuffer release];
    synthOutputBuffer = [[outputQueue popNextPendingBuffer] retain];
    // TODO Need to check if we exhaust those pending. We should manufacture them, but perhaps not on demand.
    // [synthThreadLock unlock];
}

////////////////////////////////////////////////////////////////////////////////
// synthOutputBuffer
////////////////////////////////////////////////////////////////////////////////

- (SndAudioBuffer *) synthOutputBuffer
{
  return [[synthOutputBuffer retain] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// synthInputBuffer
////////////////////////////////////////////////////////////////////////////////

- (SndAudioBuffer *) synthInputBuffer
{
  return [[synthInputBuffer retain] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// finishStreaming
////////////////////////////////////////////////////////////////////////////////

- (void) finishStreaming
{
    // Need lock to make sure the synthesis thread is paused before shutting down!
    [synthThreadLock lock];
    active = FALSE;
    [synthThreadLock unlock];
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
    // The condition guards against locking before the output buffer is initialised from the manager.
    [outputBufferLock lockWhenCondition: OB_isInit];
    return self;
}

- unlockOutputBuffer
{
    [outputBufferLock unlockWithCondition: OB_isInit];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// audioProcessorChain
////////////////////////////////////////////////////////////////////////////////

- (SndAudioProcessorChain *) audioProcessorChain
{
    return [[processorChain retain] autorelease];
}

- (void) setAudioProcessorChain: (SndAudioProcessorChain *) newAudioProcessorChain
{
    [processorChain release];
    processorChain = [newAudioProcessorChain retain];
}

////////////////////////////////////////////////////////////////////////////////
// delegate mutator/accessor methods
////////////////////////////////////////////////////////////////////////////////

- (void) setDelegate: (id) theNewDelegate
{
  delegate = theNewDelegate;
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

- (long) instantaneousInputLatencyInSamples
{
    if (synthInputBuffer != nil) {
	// This assumes all buffers in the queue are the same length...
	long latency = [synthInputBuffer lengthInSampleFrames] * [inputQueue pendingBuffersCount];
	return latency;
    }
    else
	return -1; // TODO to indicate the value is bogus.
}

- (long) instantaneousOutputLatencyInSamples
{
    if (exposedOutputBuffer != nil) {
	// This assumes all buffers in the queue are the same length...
	long latency = [exposedOutputBuffer lengthInSampleFrames] * [outputQueue processedBuffersCount];
	return latency;
    }
    else
	return -1;  // TODO to indicate the value is bogus.
}

////////////////////////////////////////////////////////////////////////////////

@end
