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
#define SNDSTREAMMANAGER_DELEGATE_DEBUG         0
#define SNDSTREAMMANAGER_SPIKE_AT_BUFFER_START  0

static void processAudio(double sampleCount, SNDStreamBuffer *streamInputBuffer, SNDStreamBuffer *streamOutputBuffer, void *obj);

////////////////////////////////////////////////////////////////////////////////
// The enums are dual purpose -- they serve as condition locks for
// bg_threadlock, and they also serve as the values held by
// bg_sem to tell the bg thread which activity to perform.
////////////////////////////////////////////////////////////////////////////////

enum {
  BG_ready,
  BG_hasFlag,
  BG_stopNow,
  BG_startNow,
  BG_abortNow,
  BG_hasStarted,
  BG_threadStopped,
  BG_threadInactive
};

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
        if([defaults boolForKey: @"SndShowDriverSelected"]) {
            const char **driverNames = SNDGetAvailableDriverNames();
            
            NSLog(@"SndStreamManager +initialise: driver selected is %s\n", driverNames[SNDGetAssignedDriverIndex()]);
        }
	if([defaults boolForKey: @"SndShowSpeakerConfiguration"]) {
	    const char **speakerNames = SNDSpeakerConfiguration();

            NSLog(@"SndStreamManager +initialise: speaker configuration is %s %s\n", speakerNames[0], speakerNames[1]);
        }
    }
    else {
        NSLog(@"SndStreamManager +initialise: Error - Unable to initialise SNDInit()!\n");
    }
    if (defaultStreamManager == nil)
        defaultStreamManager = [SndStreamManager new];  // create our default
}

+ (NSArray *) getDriverNames
{
    NSMutableArray *soundDriverNames = [NSMutableArray array];
    const char **driverNames = SNDGetAvailableDriverNames();
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

// TODO provide - initOnDevice: (NSString *) driverName

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
	NSLog(@"Native format of streaming audio buffer: %@\n", self);
    
    /* might as well set up the delegate background thread now too */
    
    if ([[NSRunLoop currentRunLoop] currentMode] != nil || NSApp) {
#if SNDSTREAMMANAGER_DELEGATE_DEBUG
	NSLog(@"[SndStreamManager::init] Run loop detected - delegate messaging enabled\n");
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
	NSLog(@"[SndStreamManager::init] No runloop or NSApp detected - delegate messaging disabled\n");
#endif
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
#if SNDSTREAMMANAGER_DEBUG
    NSLog(@"[manager] starting dealloc\n");
#endif
    
    if (active)
	NSLog(@"SndStreamManager::dealloc - Error: stream is still active!!!");
    
    [mixer release];
    
    [delegateMessageArray release];
    
    [delegateMessageArrayLock release];
    [bg_threadLock release];
    [bgdm_threadLock release];
    
#if SNDSTREAMMANAGER_DEBUG
    NSLog(@"[manager] ending dealloc\n");
#endif
    
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// description
////////////////////////////////////////////////////////////////////////////////

- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ (sample rate:%.1fKHz, channels:%i, length:%i frames)",
	[super description],
	format.sampleRate / 1000.0,
	format.channelCount,
	format.frameCount];
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
    
  // if all goes well with init,
  // active = TRUE
    
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
// delegate messages out of background threads into the foreground thread.
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

////////////////////////////////////////////////////////////////////////////////
// delegateMessageThread:
////////////////////////////////////////////////////////////////////////////////

- (void) delegateMessageThread: (NSArray *) ports
{
    NSAutoreleasePool *localPool = [NSAutoreleasePool new];
    id controllerProxy = nil;

    [self retain]; // TODO eeek, why is this necessary?

#if SNDSTREAMMANAGER_DEBUG
    NSLog(@"SndManager::entering delegate thread\n");
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
#if SNDSTREAMMANAGER_DEBUG
	    NSLog(@"SndManager::Killing delegate message thread.\n");
#endif
	    bgdm_sem = BGDM_threadStopped;
	    break;
	}
	else {
	    NSLog(@"Semaphore status: %i\n", bgdm_sem);
	    bgdm_sem = BGDM_ready;
	}
	[bgdm_threadLock unlockWithCondition: bgdm_sem];
    }
    [self release];  // TODO eeek, why is this necessary?
    [localPool release];
    /* even if there is a new thread is created between the following two
     * statements, that would be ok -- there would temporarily be one
     * extra thread but it won't cause a problem
     */
#if SNDSTREAMMANAGER_DEBUG
    NSLog(@"SndManager::exiting delegate thread\n");
#endif

    [NSThread exit];
}

////////////////////////////////////////////////////////////////////////////////
// streamStartStopThread: watches for semaphore from processing thread that it
// should be stopped. Doing it from this thread means that the playback thread
// doesn't have to stop itself, which is a particular problem on portaudio
// implementations where a pthread_join is attempted on the playback thread from
// the thread telling it to stop (which until now was the same thread)
////////////////////////////////////////////////////////////////////////////////

- (void) streamStartStopThread
{
    NSAutoreleasePool *localPool = [NSAutoreleasePool new];
    
    bg_active = TRUE;
    isStopping = FALSE;
    //[self retain]; // I presume this is to register the retain on the local autorelease pool?
    
#if SNDSTREAMMANAGER_DEBUG
    NSLog(@"SndManager::entering bg thread\n");
#endif
    
    while (1) {
	[bg_threadLock lockWhenCondition: BG_hasFlag];
	if (bg_sem == BG_startNow) {
	    active = SNDStreamStart(processAudio, (void *) self);
	    nowTime = 0.0;
	    bg_sem = 0;
	    isStopping = FALSE;
#if SNDSTREAMMANAGER_DEBUG
	    NSLog(@"SndManager::startStreaming - Stream starting!\n");
#endif
	    [bg_threadLock unlockWithCondition:BG_hasStarted];
	    continue;
	}
	else if (bg_sem == BG_stopNow) {
	    SNDStreamStop();
#if SNDSTREAMMANAGER_DEBUG
	    NSLog(@"SndManager::stopStreaming -  stream stopping");
#endif
	    active  = FALSE;
	    nowTime = 0.0;
	    bg_sem  = 0;
	    
	    if ([[NSRunLoop currentRunLoop] currentMode] != nil || NSApp) {
		[bgdm_threadLock lock];
		bgdm_sem = BGDM_abortNow;
		[bgdm_threadLock unlockWithCondition: BGDM_hasFlag];
		
		[bgdm_threadLock lockWhenCondition: BGDM_threadStopped];
		[bgdm_threadLock unlockWithCondition: BGDM_threadInactive];
	    }
	    
#if SNDSTREAMMANAGER_DEBUG
	    NSLog(@"[manager] delegete message thread is inactive.\n");
#endif
	    
	    break;
	}
	else if (bg_sem == BG_abortNow) {
	    break;
	}
    }
    bg_active = FALSE;
    [bg_threadLock unlockWithCondition:BG_threadStopped];
    //[self release];
    [localPool release];
    
#if SNDSTREAMMANAGER_DEBUG
    NSLog(@"SndManager::exiting bg thread\n");
#endif
    /* even if there is a new thread is created between the following two
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
#if SNDSTREAMMANAGER_DEBUG
	NSLog(@"[manager] sending shutdown to mixer...\n");
#endif
	[mixer finishMixing];
#if SNDSTREAMMANAGER_DEBUG
	NSLog(@"[manager] about to send shutdown to stream...\n");
#endif
	
	[bg_threadLock lock];
	bg_sem = BG_stopNow;
	[bg_threadLock unlockWithCondition: BG_hasFlag];
	
#if SNDSTREAMMANAGER_DEBUG
	NSLog(@"[manager] shutdown sent.\n");
#endif
    }
    else {
	NSLog(@"SndManager::stopStreaming - Error: stopStreaming called when not streaming!\n");
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

static void processAudio(double sampleCount, SNDStreamBuffer *streamInputBuffer, SNDStreamBuffer *streamOutputBuffer, void *manager)
{
    // These could be made instance variables which are just wrapped
    // around each of the SNDStreamBuffers, to avoid allocation costs. 
    // However if the underlying streamBuffers are non-interleaved, there is a conversion
    // process required, hence the need for full allocation and initialisation. If SndAudioBuffers
    // themselves can be non-interleaved, we then _really_ need to hide all this within the class.

    NSAutoreleasePool *localPool = [NSAutoreleasePool new];
    SndAudioBuffer *inB  = (streamInputBuffer  == NULL) ? nil : [SndAudioBuffer audioBufferWithSNDStreamBuffer: streamInputBuffer ];
    SndAudioBuffer *outB = (streamOutputBuffer == NULL) ? nil : [SndAudioBuffer audioBufferWithSNDStreamBuffer: streamOutputBuffer];

#if SNDSTREAMMANAGER_DEBUG
    NSLog(@"[Manager] --> processAudio sampleCount = %ld, streamOutputBuffer = %p, streamOutputBuffer->streamData = %p\n", 
        (long) sampleCount, streamOutputBuffer, streamOutputBuffer->streamData);
    // NSLog(@"[Manager] --> processAudio outB = %@\n", outB);
#endif
    
    [(SndStreamManager *) manager processStreamAtTime: sampleCount input: inB output: outB];
    [outB fillSNDStreamBuffer: streamOutputBuffer];

#if SNDSTREAMMANAGER_DEBUG
    NSLog(@"[Manager] About to release pool...\n");
#endif
    [localPool release];
#if SNDSTREAMMANAGER_DEBUG
    NSLog(@"[Manager] Released pool...\n");
#endif
}

////////////////////////////////////////////////////////////////////////////////
// processStreamAtTime:input:output:
//
// Poll all the clients for their current output buffers, tell them to start
// processing
////////////////////////////////////////////////////////////////////////////////

- (void) processStreamAtTime: (double) sampleCount
                       input: (SndAudioBuffer *) inB
                      output: (SndAudioBuffer *) outB
{
#if SNDSTREAMMANAGER_DEBUG
    NSLog(@"[Manager] Entering processStreamAtTime %lf inB %@, outB %@\n", sampleCount, inB, outB);
#endif
    if (active) {
	// Set our current notion of time.
	if (outB != nil) {
	    // Calculate nowTime from sampleCount. This guards against deinterleaved streams repeatedly
	    // requesting processing at the same sampleCount value causing nowTime to over-increment.
	    nowTime = sampleCount / [outB samplingRate];
	    // TODO Earlier versions calculated nowTime by preincrementing by the buffer duration. 
	    // This put nowTime at the end of the buffer, not at the start. 
	    // I don't think it matters but that needs checking and setting a policy. 
	    // Here's what we would need to do to recreate those semantics:
	    // nowTime = (sampleCount + [outB duration]) / [outB samplingRate];
	}
	else if (inB != nil) {
	    nowTime = sampleCount / [inB samplingRate];
	}

#if SNDSTREAMMANAGER_DEBUG
	NSLog(@"[Manager] nowTime: %.3f sampleCount: %.3f\n", nowTime, sampleCount);
#endif
	[mixer processInBuffer: inB outBuffer: outB nowTime: nowTime];
#if SNDSTREAMMANAGER_DEBUG
	NSLog(@"[Manager] post mixer\n");
#endif
	if ([mixer clientCount] == 0) { // Shut down the Stream if there are no clients.
	    [self stopStreaming];
#if SNDSTREAMMANAGER_DEBUG
	    NSLog(@"[Manager] signalling a stop stream...\n");
#endif
	}
#if SNDSTREAMMANAGER_SPIKE_AT_BUFFER_START
	{
	    float *pF =  [outB data];
	    pF[0] = 1.0f;
	    pF[1] = 1.0f;
	}
#endif
    }
    else {
	// This can happen quite benignly when we first call SNDStreamStart, we literally can get callbacks
	// after AudioDeviceStart() is called, before SNDStartStream has returned to set the active ivar.
#if SNDSTREAMMANAGER_DEBUG
	NSLog(@"SndStreamManager::processStreamAtTime - called when not active...?");
#endif
    }
#if SNDSTREAMMANAGER_DEBUG
    NSLog(@"[Manager] Leaving...\n");
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
