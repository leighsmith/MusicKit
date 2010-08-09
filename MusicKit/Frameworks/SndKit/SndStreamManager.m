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

// TODO This is needed since we check for NSApp, but I don't think checking for NSApp is the correct way to
// check for an NSApplication generated run loop.
#import <AppKit/AppKit.h>
#import "SndAudioBuffer.h"
#import "SndStreamClient.h"
#import "SndStreamMixer.h"
#import "SndStreamManager.h"

////////////////////////////////////////////////////////////////////////////////
// Debug defines
////////////////////////////////////////////////////////////////////////////////

#define SNDSTREAMMANAGER_DEBUG                  0
#define SNDSTREAMMANAGER_STARTSTOP_DEBUG        0
#define SNDSTREAMMANAGER_DELEGATE_DEBUG         0
#define SNDSTREAMMANAGER_PROCESSING_DEBUG       0
#define SNDSTREAMMANAGER_SPIKE_AT_BUFFER_START  0

static void processAudio(double bufferTime, SNDStreamBuffer *streamInputBuffer, SNDStreamBuffer *streamOutputBuffer, void *obj);

////////////////////////////////////////////////////////////////////////////////
// The enums are dual purpose -- they serve as condition locks for
// bg_threadlock, and they also serve as the values held by
// bg_sem to tell the background streaming manager thread which activity to perform.
////////////////////////////////////////////////////////////////////////////////

enum {
  BG_ready,
  BG_hasFlag,
  BG_stopNow,
  BG_startNow,
  BG_abortNow,
  BG_hasStarted,
  BG_threadStopped
};

// States for the background delegate messaging thread
enum {
  BGDM_ready,
  BGDM_hasFlag,
  BGDM_abortNow,
  BGDM_delegateMessageReady,
  BGDM_threadStopped,
  BGDM_threadInactive
};

@implementation SndStreamManager

static SndStreamManager *defaultStreamManager = nil;

////////////////////////////////////////////////////////////////////////////////
// streamManager factory
////////////////////////////////////////////////////////////////////////////////

+ (void) initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
    if (SNDInit(TRUE)) {
	if (defaultStreamManager == nil) {
	    defaultStreamManager = [[SndStreamManager alloc] init];  // create our default SndStreamManager on default input and output devices.
	}
	if([defaults boolForKey: @"SndShowDriverSelected"]) {
            NSLog(@"SndStreamManager +initialise: default driver selected is %@\n", defaultStreamManager);
        }
	if([defaults boolForKey: @"SndShowSpeakerConfiguration"]) {
	    const char **speakerNames = SNDSpeakerConfiguration();

            NSLog(@"SndStreamManager +initialise: speaker configuration is %s %s\n", speakerNames[0], speakerNames[1]);
        }
    }
    else {
        NSLog(@"SndStreamManager +initialise: Error - Unable to initialise SNDInit()!\n");
    }
}

+ (NSArray *) driverNamesForOutput: (BOOL) outputDevices
{
    NSMutableArray *soundDriverNames = [NSMutableArray array];
    const char **driverNames = SNDGetAvailableDriverNames(outputDevices);
    unsigned int driverNameIndex;
    
    for(driverNameIndex = 0; driverNames[driverNameIndex] != NULL; driverNameIndex++) {
        [soundDriverNames addObject: [NSString stringWithUTF8String: driverNames[driverNameIndex]]];
    }
    // if([soundDriverNames count] == 0) {
    //    return nil;
    // }
    return [NSArray arrayWithArray: soundDriverNames];
}

////////////////////////////////////////////////////////////////////////////////
// defaultStreamManager
//
// Always return our initialized stream manager!
////////////////////////////////////////////////////////////////////////////////

+ (SndStreamManager *) defaultStreamManager
{
    return [[defaultStreamManager retain] autorelease];
}

+ streamManagerOnDeviceForInput: (NSString *) inputDeviceName 
		deviceForOutput: (NSString *) outputDeviceName 
{
    return [[[SndStreamManager alloc] initOnDeviceForInput: inputDeviceName
					   deviceForOutput: outputDeviceName] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
    NSPort *managerReceivePort, *managerSendPort;
    
    self = [super init];
    if (!self)
	return nil;
    
    mixer           = [[SndStreamMixer mixer] retain];
    bg_threadLock   = [[NSConditionLock alloc] initWithCondition: BG_ready];
    bgdm_threadLock = [[NSConditionLock alloc] initWithCondition: BGDM_ready];
    delegateMessageArrayLock = [NSLock new];
    active        = FALSE;
    bg_active     = FALSE;
    nowTime       = 0.0;
    bDelegateMessagingEnabled = FALSE;
    format = [Snd nativeFormat];
    if([[NSUserDefaults standardUserDefaults] boolForKey: @"SndShowStreamingFormat"])
	NSLog(@"Native format of streaming audio buffer: %@\n", SndFormatDescription(format));
    
    /* might as well set up the delegate messaging thread now too */
    
    if ([[NSRunLoop currentRunLoop] currentMode] != nil || NSApp) {
#if SNDSTREAMMANAGER_DELEGATE_DEBUG
	NSLog(@"[SndStreamManager] -init Run loop detected - delegate messaging enabled\n");
#endif
	delegateMessageArray = [NSMutableArray new];
	managerReceivePort   = (NSPort *)[NSPort port]; /* we don't need to retain, the connection does that */
	managerSendPort      = (NSPort *)[NSPort port];
	
	threadConnection     = [[NSConnection alloc] initWithReceivePort: managerReceivePort
								sendPort: managerSendPort];
	[threadConnection setRootObject: self];
	
	[NSThread detachNewThreadSelector: @selector(delegateMessageThread:)
				 toTarget: self
			       withObject: [NSArray arrayWithObjects: managerSendPort, managerReceivePort, nil]];
	bDelegateMessagingEnabled = TRUE;
    }
    else {
#if SNDSTREAMMANAGER_DELEGATE_DEBUG
	NSLog(@"[SndStreamManager] -init No runloop or NSApp detected - delegate messaging disabled\n");
#endif
    }
    return self;
}

- initOnDeviceForInput: (NSString *) inputDeviceName deviceForOutput: (NSString *) outputDeviceName 
{
    if([self init]) {
	NSArray *outputNames  = [SndStreamManager driverNamesForOutput: YES];
	NSArray *inputNames = [SndStreamManager driverNamesForOutput: NO];

	// Find the device indices for input and output names.
	int outputDeviceIndex = [outputNames indexOfObject: outputDeviceName];
	int inputDeviceIndex = [inputNames indexOfObject: inputDeviceName];
	
	if(outputDeviceIndex != NSNotFound && inputDeviceIndex != NSNotFound) {
	    [self setAssignedDriverToIndex: outputDeviceIndex forOutput: YES];
	    [self setAssignedDriverToIndex: inputDeviceIndex forOutput: NO];
	}
	return self;
    }
    return nil;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
#if SNDSTREAMMANAGER_DEBUG
    NSLog(@"[SndStreamManager] starting dealloc\n");
#endif
    
    if (active)
	NSLog(@"SndStreamManager::dealloc - Error: stream is still active!!!");
    
    [mixer release];
    
    [delegateMessageArray release];
    
    [delegateMessageArrayLock release];
    [bg_threadLock release];
    [bgdm_threadLock release];
    
#if SNDSTREAMMANAGER_DEBUG
    NSLog(@"[SndStreamManager] ending dealloc\n");
#endif
    
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// description
////////////////////////////////////////////////////////////////////////////////

- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ (%sactive) input: %@ output: %@ (sample rate:%.1fKHz, channels:%i, length:%i frames)",
	    [super description],
	    [self isActive] ? "" : "in",
	    [self assignedDriverNameForOutput: NO],
	    [self assignedDriverNameForOutput: YES],
	    format.sampleRate / 1000.0,
	    format.channelCount,
	    format.frameCount];
}

- (int) assignedDriverIndexForOutput: (BOOL) outputDevices
{
    return SNDGetAssignedDriverIndex(outputDevices);
}

- (BOOL) setAssignedDriverToIndex: (unsigned int) driverIndex forOutput: (BOOL) forOutputDevices
{
    BOOL success;
//    BOOL wasActive = active;

    // Need to check we are already streaming before stopping and restarting.
    // enfore that changing the driver index will always cause streaming if the class is
    // initialised as such.
//  if(wasActive)
//	[self stopStreaming];
    success = SNDSetDriverIndex(driverIndex, forOutputDevices);
//  NSLog(@"set the driver wasActive = %d active = %d\n", wasActive, active);
//  if(wasActive)
//	[self startStreaming];
    return success;
}

- (NSString *) assignedDriverNameForOutput: (BOOL) outputDevices
{
    NSArray *outputDriverNames = [SndStreamManager driverNamesForOutput: outputDevices];
    
    return [outputDriverNames objectAtIndex: [self assignedDriverIndexForOutput: outputDevices]];
}

- (BOOL) setOutputBufferSize: (unsigned int) frames
{
    BOOL success = SNDSetBufferSizeInBytes(frames * SndFrameSize([Snd nativeFormat]), YES);

    format = [Snd nativeFormat];
    return success;
}

- (BOOL) setInputBufferSize: (unsigned int) frames
{
    return SNDSetBufferSizeInBytes(frames * SndFrameSize([Snd nativeInputFormat]), NO);
}

// We only export a single method to change both input and output buffers by the same amount since
// managing different sized input and output buffers is very difficult to avoid starvation and the SndStreamMixer 
// and SndAudioBuffer methods don't currently handle those cases anyway. We can always export the individual buffer
// changing methods in the future.
- (BOOL) setHardwareBufferSize: (unsigned int) frames
{
    return [self setOutputBufferSize: frames] && [self setInputBufferSize: frames];
}

////////////////////////////////////////////////////////////////////////////////
// startStreaming: responsible for calling low-level C stuff to get a stream
// happening, and register the processStreamAtTime: selector as the callback
// function.
////////////////////////////////////////////////////////////////////////////////

- (void) startStreaming
{
    // Tell MKPerformSndMidi to start sending us buffers, register the
    // processStreamAtTime: selector as the callback for it to use.
    // keep a copy of the format we decided to open to build the initial
    // buffers for each Client. (Recall: Buffers have format info, hence
    // we send a buffer to each client as a way of passing format as well
    // as giving them somethin' to write into. (though they will need two -
    // one to display as the current finished output, one to synth into)
    
    // if all goes well with the stream thread starting, active will be set TRUE.
    
    if (!bg_active) {
	[NSThread detachNewThreadSelector: @selector(streamStartStopThread)
				 toTarget: self
			       withObject: nil];
    }
    [bg_threadLock lock];
    bg_sem = BG_startNow;
    [bg_threadLock unlockWithCondition: BG_hasFlag];
    [bg_threadLock lockWhenCondition: BG_hasStarted];
    [bg_threadLock unlockWithCondition: BG_ready];
}

////////////////////////////////////////////////////////////////////////////////
// _sendDelegateInvocation:
//
// INTERNAL USE ONLY. Used as part of the delegate system for passing
// delegate messages out of managing threads into the foreground thread.
//
// We cast to unsigned long to prevent MacOSX (and maybe GNUstep) from interpreting
// the argument as an NSInvocation. When it does this, it tries to be too smart, and
// creates a connection to the object in the thread the NSInvocation was created in
// (which is what we're trying to avoid).
//
// This should only be called while in the main thread. Internal use only.
//
////////////////////////////////////////////////////////////////////////////////

- (void) _sendDelegateInvocation: (in unsigned long) mesg
{
    [(NSInvocation *) mesg invoke];
}

/*
  A very lightweight thread used for sending delegate messages
  from the manager threads to the main thread.

  The parameter ports is a pair of NSPorts in an NSArray, used for setting up the
  distributed object between this thread and the main thread.
  
  The manager calls this method as it starts up (in -init) then the thread just sits there
  waiting for a signal to say that there's a delegate message sitting
  in an array, waiting to be sent. The delegate message should have
  been sent to -sendMessageInMainThreadToTarget:sel:arg1:arg2:. After arriving
  in the delegate message thread it is dispatched to the main thread
  via Distributed Objects, and will be sent on to the requested
  delegate at the next convenient time in the NSRunLoop.
*/
- (void) delegateMessageThread: (NSArray *) ports
{
    NSAutoreleasePool *localPool = [NSAutoreleasePool new];
    id controllerProxy = nil;

    // [self retain]; // TODO eeek, why is this necessary?

#if SNDSTREAMMANAGER_DELEGATE_DEBUG
    NSLog(@"[SndStreamManager] entering delegate thread\n");
#endif

    while (bgdm_sem != BGDM_threadStopped) {
	[bgdm_threadLock lockWhenCondition: BGDM_hasFlag];
	if (bgdm_sem == BGDM_delegateMessageReady)  {
	    NSInvocation *delegateMessage = nil;
	    int count;
	    
	    // quickly release the lock so we don't deadlock if the queued messages take
	    // a while to go through.
	    [bgdm_threadLock unlockWithCondition: bgdm_sem];
	    while (1) {
		[delegateMessageArrayLock lock];
		count = [delegateMessageArray count];
		if (count) { // Get the first message off the queue
		    // retain lest the delegateMessage disappear when we remove it from the array.
		    delegateMessage = [[delegateMessageArray objectAtIndex: 0] retain]; 
		    [delegateMessageArray removeObjectAtIndex: 0];
		}
		[delegateMessageArrayLock unlock];
		if (!count)
		    break;
		if (!controllerProxy) {
		    NSConnection *theConnection = [NSConnection connectionWithReceivePort: [ports objectAtIndex: 0]
										 sendPort: [ports objectAtIndex: 1]];
		    // Note: if there's a problem with the NSRunLoop not running or
		    // responding here, the -rootProxy method will block. We could
		    // set a timout here and catch the exception thrown as a result,
		    // but there may be valid reasons why the NSRunLoop does not respond
		    // (perhaps the main loop is busy doing other stuff?). THis could do
		    // with some testing cos I think a timeout exception would be the
		    // best way forward.
				
		    //[theConnection setReplyTimeout:0.1];
		    controllerProxy = [theConnection rootProxy];
		    [controllerProxy setProtocolForProxy: @protocol(SndDelegateMessagePassing)];
		}
		/* cast to unsigned long to prevent compiler warnings */
		[controllerProxy _sendDelegateInvocation: (unsigned long) delegateMessage];
		[delegateMessage release];
	    }
	    continue;
	}
	else if (bgdm_sem == BGDM_abortNow) {
#if SNDSTREAMMANAGER_DELEGATE_DEBUG
	    NSLog(@"[SndStreamManager] Killing delegate message thread.\n");
#endif
	    bgdm_sem = BGDM_threadStopped;
	    [bgdm_threadLock unlockWithCondition: bgdm_sem];
	    break;
	}
	else {
	    NSLog(@"Semaphore status: %i\n", bgdm_sem);
	    bgdm_sem = BGDM_ready;
	}
	[bgdm_threadLock unlockWithCondition: bgdm_sem];
    }
    // [self release];  // TODO eeek, why is this necessary?
    [localPool release];
    /* even if there is a new thread is created between the following two
     * statements, that would be ok -- there would temporarily be one
     * extra thread but it won't cause a problem
     */
#if SNDSTREAMMANAGER_DELEGATE_DEBUG
    NSLog(@"[SndStreamManager] exiting delegate thread\n");
#endif

    [NSThread exit];
}

/*
  A very lightweight thread used for starting and stopping the audio streams.
  
  The manager can instruct the starting and stopping of streams by setting bg_sem to
  BG_startNow or BG_stopNow, and setting the bg_threadLock
  condition. The thread is created on this method when a stream
  is to begin, if it does not exist already.

  streamStartStopThread: watches for semaphore from processing thread that it
  should be stopped. Doing it from this thread means that the playback thread
  doesn't have to stop itself, which is a particular problem on portaudio
  implementations where a pthread_join is attempted on the playback thread from
  the thread telling it to stop (which until now was the same thread)
*/
- (void) streamStartStopThread
{
    NSAutoreleasePool *localPool = [NSAutoreleasePool new];
    
    bg_active = TRUE;
    isStopping = FALSE;
    //[self retain]; // I presume this is to register the retain on the local autorelease pool?
    
#if SNDSTREAMMANAGER_STARTSTOP_DEBUG
    NSLog(@"[SndStreamManager] streamStartStopThread - entering background streaming manager thread\n");
#endif
    
    while (1) {
	[bg_threadLock lockWhenCondition: BG_hasFlag];
	if (bg_sem == BG_startNow) {
	    active = SNDStreamStart(processAudio, (void *) self);
	    nowTime = 0.0;
	    bg_sem = 0;
	    isStopping = FALSE;
#if SNDSTREAMMANAGER_STARTSTOP_DEBUG
		NSLog(@"[SndStreamManager] streamStartStopThread - stream starting! active = %d\n", active);
#endif
	    [bg_threadLock unlockWithCondition: BG_hasStarted];
	    continue;
	}
	else if (bg_sem == BG_stopNow) {
#if SNDSTREAMMANAGER_STARTSTOP_DEBUG
	    NSLog(@"[SndStreamManager] streamStartStopThread -  stream stopping");
#endif
	    active  = FALSE;
	    nowTime = 0.0;
	    bg_sem  = 0;
	    SNDStreamStop();
	    
	    if ([[NSRunLoop currentRunLoop] currentMode] != nil || NSApp) {
#if SNDSTREAMMANAGER_DELEGATE_DEBUG
		NSLog(@"[SndStreamManager] streamStartStopThread - sending delegate message for stopping\n");
#endif
		[bgdm_threadLock lock];
		bgdm_sem = BGDM_abortNow;
		[bgdm_threadLock unlockWithCondition: BGDM_hasFlag];
		
		[bgdm_threadLock lockWhenCondition: BGDM_threadStopped];
		[bgdm_threadLock unlockWithCondition: BGDM_threadInactive];
	    }
	    
#if SNDSTREAMMANAGER_DELEGATE_DEBUG
	    NSLog(@"[SndStreamManager] streamStartStopThread - delegate message thread is inactive.\n");
#endif
	    
	    break;
	}
	else if (bg_sem == BG_abortNow) {
	    break;
	}
    }
    bg_active = FALSE;
    [bg_threadLock unlockWithCondition: BG_threadStopped];
    //[self release];
    [localPool release];
    
#if SNDSTREAMMANAGER_STARTSTOP_DEBUG
    NSLog(@"[SndStreamManager] exiting background streaming manager thread\n");
#endif
    /* even if there is a new thread which is created between the following two
     * statements, that would be ok -- there would temporarily be one
     * extra thread but it won't cause a problem
     */
    [NSThread exit];
}

////////////////////////////////////////////////////////////////////////////////
// sendMessageInMainThreadToTarget:sel:arg1:arg2:
////////////////////////////////////////////////////////////////////////////////

- (void) sendMessageInMainThreadToTarget: (id) target sel: (SEL) sel arg1: (id) arg1 arg2: (id) arg2
{
    if (!bDelegateMessagingEnabled) {
	return;
    }
    else {
	NSMethodSignature *aSignature   = [[target class] instanceMethodSignatureForSelector: sel];
	NSInvocation      *anInvocation = [NSInvocation invocationWithMethodSignature: aSignature];

	[anInvocation setSelector: sel];
	[anInvocation setTarget: target];
	[anInvocation setArgument: &arg1 atIndex: 2];
	[anInvocation setArgument: &arg2 atIndex: 3];
	[anInvocation retainArguments];

	[delegateMessageArrayLock lock];
	[delegateMessageArray addObject: anInvocation];
	[delegateMessageArrayLock unlock];

	[bgdm_threadLock lock];
	bgdm_sem = BGDM_delegateMessageReady;
	[bgdm_threadLock unlockWithCondition: BGDM_hasFlag];
    }
}

////////////////////////////////////////////////////////////////////////////////
// stopStreaming
// Responsible for calling low-level C stuff to stop a stream,
// and unregister the processStreamAtTime: selector as the callback function.
////////////////////////////////////////////////////////////////////////////////
- (void) stopStreaming
{
    if (isStopping) {
	return;
    }
    if (active) {
	isStopping = TRUE;
#if SNDSTREAMMANAGER_STARTSTOP_DEBUG
	NSLog(@"[SndStreamManager] stopStreaming sending shutdown to mixer...\n");
#endif
	[mixer finishMixing];
#if SNDSTREAMMANAGER_STARTSTOP_DEBUG
	NSLog(@"[SndStreamManager] stopStreaming about to send shutdown to stream...\n");
#endif
	
	[bg_threadLock lock];
	bg_sem = BG_stopNow;
	[bg_threadLock unlockWithCondition: BG_hasFlag];
	
#if SNDSTREAMMANAGER_STARTSTOP_DEBUG
	NSLog(@"[SndStreamManager] stopStreaming shutdown sent.\n");
#endif
	[bg_threadLock lockWhenCondition: BG_threadStopped];
#if SNDSTREAMMANAGER_STARTSTOP_DEBUG
	NSLog(@"[SndStreamManager] stopStreaming streaming Thread has stopped, unlocking, mixer client count %d\n", [mixer clientCount]);
#endif
	[bg_threadLock unlockWithCondition: BG_threadStopped]; // unlock remaining in thread stopped state.
    }
    else {
	NSLog(@"[SndStreamManager] stopStreaming - Error: stopStreaming called when not streaming!\n");
    }
}

////////////////////////////////////////////////////////////////////////////////
// addClient:
//
// Returns false if the client is already registered, or the audio device
// couldn't start streaming... true if all is well.
////////////////////////////////////////////////////////////////////////////////

- (BOOL) addClient: (SndStreamClient *) client
{
    int  oldClientCount    = [mixer clientCount];
    int  clientCount       = [mixer addClient: client];
    BOOL alreadyRegistered = (oldClientCount == clientCount);
    
    if (!alreadyRegistered) {
	SndAudioBuffer *buff = [SndAudioBuffer audioBufferWithFormat: &format data: NULL];
	if (oldClientCount == 0 && !active) // There were no clients previously - better start the stream...
	    [self startStreaming];
	[client welcomeClientWithBuffer: buff manager: self];
    }
    return active;
}

////////////////////////////////////////////////////////////////////////////////
// removeClient
////////////////////////////////////////////////////////////////////////////////

- (BOOL) removeClient: (SndStreamClient *) client
{
    return [mixer removeClient: client];
}

////////////////////////////////////////////////////////////////////////////////
//  Don't call!!! only for setting format properties for testing.
////////////////////////////////////////////////////////////////////////////////

- setFormat: (SndFormat) newFormat
{
    format = newFormat;
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// processAudio
////////////////////////////////////////////////////////////////////////////////

static void processAudio(double bufferTime, SNDStreamBuffer *streamInputBuffer, SNDStreamBuffer *streamOutputBuffer, void *manager)
{
    // These could be made instance variables which are just wrapped
    // around each of the SNDStreamBuffers, to avoid allocation costs. 
    // However if the underlying streamBuffers are non-interleaved, there is a conversion
    // process required, hence the need for full allocation and initialisation. If SndAudioBuffers
    // themselves can be non-interleaved, we then _really_ need to hide all this within the class.

    NSAutoreleasePool *localPool = [NSAutoreleasePool new];
    SndAudioBuffer *inB  = (streamInputBuffer  == NULL) ? nil : [SndAudioBuffer audioBufferWithSNDStreamBuffer: streamInputBuffer ];
    SndAudioBuffer *outB = (streamOutputBuffer == NULL) ? nil : [SndAudioBuffer audioBufferWithSNDStreamBuffer: streamOutputBuffer];

#if SNDSTREAMMANAGER_PROCESSING_DEBUG
    NSLog(@"[SndStreamManager] --> processAudio bufferTime = %lf, streamOutputBuffer = %p, streamOutputBuffer->streamData = %p\n", 
	  bufferTime, streamOutputBuffer, streamOutputBuffer->streamData);
    NSLog(@"[SndStreamManager] --> processAudio bufferTime = %lf, streamInputBuffer = %p, streamInputBuffer->streamData = %p\n", 
	  bufferTime, streamInputBuffer, streamInputBuffer->streamData);
    // NSLog(@"[SndStreamManager] --> processAudio outB = %@\n", outB);
#endif
    
    [(SndStreamManager *) manager processStreamAtTime: bufferTime input: inB output: outB];
    [outB fillSNDStreamBuffer: streamOutputBuffer];

#if SNDSTREAMMANAGER_PROCESSING_DEBUG
    NSLog(@"[SndStreamManager] About to release pool...\n");
#endif
    [localPool release];
#if SNDSTREAMMANAGER_PROCESSING_DEBUG
    NSLog(@"[SndStreamManager] Released pool...\n");
#endif
}

////////////////////////////////////////////////////////////////////////////////
// processStreamAtTime:input:output:
//
// Poll all the clients for their current output buffers, tell them to start
// processing
////////////////////////////////////////////////////////////////////////////////

- (void) processStreamAtTime: (double) bufferTime
                       input: (SndAudioBuffer *) inB
                      output: (SndAudioBuffer *) outB
{
#if SNDSTREAMMANAGER_PROCESSING_DEBUG
    NSLog(@"[SndStreamManager] Entering processStreamAtTime %lf seconds inB %@, outB %@\n", bufferTime, inB, outB);
#endif
    if (active) {
	// Set our current notion of time from bufferTime. This guards against deinterleaved streams repeatedly
	// requesting processing at the same bufferTime value causing nowTime to over-increment.
	nowTime = bufferTime;

	[mixer processInBuffer: inB outBuffer: outB nowTime: nowTime];
#if SNDSTREAMMANAGER_PROCESSING_DEBUG
	NSLog(@"[SndStreamManager] post mixer\n");
#endif
	// NSLog(@"processStreamAtTime: mixer client count %d\n", [mixer clientCount]);
	if ([mixer clientCount] == 0) { // Shut down the Stream if there are no clients.
#if SNDSTREAMMANAGER_STARTSTOP_DEBUG
	    NSLog(@"[SndStreamManager] signalling a stop stream...\n");
#endif
	    [self stopStreaming];
	}
#if SNDSTREAMMANAGER_SPIKE_AT_BUFFER_START
	{
	    float *outgoingSamples =  [outB data];
	    int channelIndex;

	    for(channelIndex = 0; channelIndex < [outb channelCount]; channelIndex++) {
		outgoingSamples[channelIndex] = 1.0f;
	    }
	}
#endif
    }
    else {
	// This can happen quite benignly when we first call SNDStreamStart, we literally can get callbacks
	// after AudioDeviceStart() is called, before SNDStartStream has returned to set the active ivar.
	// Currently we rely on the sound hardware interface to ensure that playing the output buffer that 
	// has not been filled will play ok. Otherwise we could zero (silence) the buffer.
#if SNDSTREAMMANAGER_PROCESSING_DEBUG
	NSLog(@"[SndStreamManager] processStreamAtTime - called when not active...?");
#endif
    }
#if SNDSTREAMMANAGER_PROCESSING_DEBUG
    NSLog(@"[SndStreamManager] Leaving...\n");
#endif
}

////////////////////////////////////////////////////////////////////////////////
// Micro accessors
////////////////////////////////////////////////////////////////////////////////

- (double) nowTime         { return nowTime; }
- (SndStreamMixer*) mixer  { return mixer;   }
- (BOOL)   isActive        { return active;  }
- (double) samplingRate    { return format.sampleRate; }

- (SndFormat) format
{
    return format;
}

////////////////////////////////////////////////////////////////////////////////
// resetTime:
////////////////////////////////////////////////////////////////////////////////

- (void) resetTime: (double) originTimeInSeconds
{
    nowTime = originTimeInSeconds;
    [mixer resetTime: originTimeInSeconds];
}

////////////////////////////////////////////////////////////////////////////////

@end
