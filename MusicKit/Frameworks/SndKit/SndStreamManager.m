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
#define SNDSTREAMMANAGER_SHOW_DRIVER_SELECTED   0

static void processAudio(double sampleCount, SNDStreamBuffer* cInB, SNDStreamBuffer* cOutB, void* obj);

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

static SndStreamManager *sm = nil;

////////////////////////////////////////////////////////////////////////////////
// streamManager factory
////////////////////////////////////////////////////////////////////////////////

+ (void) initialize
{
  if (SNDInit(TRUE)) {
#if SNDSTREAMMANAGER_SHOW_DRIVER_SELECTED
    char **driverNames = SNDGetAvailableDriverNames();
    sprintf(stderr, "SndStreamManager::initialise: driver selected is %s\n", driverNames[SNDGetAssignedDriverIndex()]);
#endif
  }
  else {
    NSLog(@"SndStreamManager::initialise: Error - Unable to initialise MKPerformSound!\n");
  }
  if (sm == nil)
    sm = [SndStreamManager new];  // create our default
}

////////////////////////////////////////////////////////////////////////////////
// defaultStreamManager
//
// Always return our initialized stream manager!
////////////////////////////////////////////////////////////////////////////////

+ (SndStreamManager *) defaultStreamManager
{
  return [[sm retain] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
  NSPort *managerReceivePort,*managerSendPort;

  self = [super init];
  if (!self)
    return nil;

  mixer           = [[SndStreamMixer sndStreamMixer] retain];
  bg_threadLock   = [[NSConditionLock alloc] initWithCondition: BG_ready];
  bgdm_threadLock = [[NSConditionLock alloc] initWithCondition: BGDM_ready];
  delegateMessageArrayLock = [NSLock new];
  active        = FALSE;
  bg_active     = FALSE;
  nowTime       = 0;
  bDelegateMessagingEnabled = FALSE;
  SNDStreamNativeFormat(&format);
  /* might as well set up the delegate background thread now too */

  if ([[NSRunLoop currentRunLoop] currentMode] || NSApp) {
#if SNDSTREAMMANAGER_DELEGATE_DEBUG
    NSLog(@"[SndStreamManager::init] Run loop detected - delegate messaging enabled\n");
#endif
    delegateMessageArray = [NSMutableArray new];
    managerReceivePort   = (NSPort *)[NSPort port]; /* we don't need to retain, the connection does that */
    managerSendPort      = (NSPort *)[NSPort port];

    threadConnection     = [[NSConnection alloc] initWithReceivePort: managerReceivePort
                                                                sendPort: managerSendPort];
    [threadConnection setRootObject:self];

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

- (NSString*) description
{
  return [NSString stringWithFormat: @"SndStreamManager [buffer samrate::%.1fkHz, chans:%i, length:%i]",
    format.samplingRate / 1000.0, format.channelCount,
    format.dataSize/(format.channelCount*sizeof(float))];
}

////////////////////////////////////////////////////////////////////////////////
// startStreaming: responsible for calling low-level C stuff to get a stream
// happening, and register the processAudioAtTime: selector as the callback
// function.
////////////////////////////////////////////////////////////////////////////////

- (void) startStreaming
{
  // Tell MKPerformSndMidi to start sending us buffers, register the
  // processAudioAtTime selector as the callback for it to use.
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
  [bg_threadLock unlockWithCondition:BG_hasFlag];
  [bg_threadLock lockWhenCondition:BG_hasStarted];
  [bg_threadLock unlockWithCondition:BG_ready];
}

////////////////////////////////////////////////////////////////////////////////
// delegateMessageThread:
////////////////////////////////////////////////////////////////////////////////

- (void) delegateMessageThread:(NSArray*) ports
{
  NSAutoreleasePool *localPool = [NSAutoreleasePool new];
  id controllerProxy = nil;

  [self retain];

#if SNDSTREAMMANAGER_DEBUG
  NSLog(@"SndManager::entering delegate thread\n");
#endif

  while (bgdm_sem != BGDM_threadStopped) {
    [bgdm_threadLock lockWhenCondition:BGDM_hasFlag];
    if (bgdm_sem == BGDM_delegateMessageReady)  {
      NSInvocation *delegateMessage = nil;
      int count;
      // quickly release the lock so we don't deadlock if the queued messages take
      // a while to go through.
      [bgdm_threadLock unlockWithCondition: bgdm_sem];
      while (1) {
        [delegateMessageArrayLock lock];
        count = [delegateMessageArray count];
        if (count) {
          delegateMessage = [[delegateMessageArray objectAtIndex:0] retain];
          [delegateMessageArray removeObjectAtIndex:0];
        }
        [delegateMessageArrayLock unlock];
        if (!count) break;
        if (!controllerProxy) {
          NSConnection *theConnection = [NSConnection connectionWithReceivePort:[ports objectAtIndex:0]
                                                                       sendPort:[ports objectAtIndex:1]];
          // Note: if there's a problem with the NSRunLoop not running or
          // responding here, the -rootProxy method will block. We could
          // set a timout here and catch the exception thrown as a result,
          // but there may be valid reasons why the NSRunLoop does not respond
          // (perhaps the main loop is busy doing other stuff?). THis could do
          // with some testing cos I think a timeout exception would be the
          // best way forward.

          //[theConnection setReplyTimeout:0.1];
          controllerProxy = [theConnection rootProxy];
          [controllerProxy setProtocolForProxy:@protocol(SndDelegateMessagePassing)];
        }
        /* cast to unsigned long to prevent compiler warnings */
        [controllerProxy _sendDelegateInvocation:(unsigned long)delegateMessage];
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
      NSLog(@"Semaphore status: %i\n",bgdm_sem);
      bgdm_sem = BGDM_ready;
    }
    [bgdm_threadLock unlockWithCondition: bgdm_sem];
  }
  [self release];
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

- (void)streamStartStopThread
{
  NSAutoreleasePool *localPool = [NSAutoreleasePool new];

  bg_active = TRUE;
  isStopping = FALSE;
  [self retain];

#if SNDSTREAMMANAGER_DEBUG
  NSLog(@"SndManager::entering bg thread\n");
#endif

  while (1) {
    [bg_threadLock lockWhenCondition:BG_hasFlag];
    if (bg_sem == BG_startNow) {
      active = SNDStreamStart(processAudio, (void*) self);
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

      if ([[NSRunLoop currentRunLoop] currentMode] || NSApp) {
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
  [self release];
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
// _sendDelegateInvocation:
//
// we cast to unsigned long to prevent MacOSX (and maybe GNUstep) from interpreting
// the argument as an NSInvocation. When it does this, it tries to be too smart, and
// creates a connection to the object in the thread the NSInvocation was created in
// (which is what we're trying to avoid).
//
////////////////////////////////////////////////////////////////////////////////

- (void) _sendDelegateInvocation:(in unsigned long) mesg
  /* this should only be called while in the main thread. Internal use only. */
{
  [(NSInvocation *)mesg invoke];
}

////////////////////////////////////////////////////////////////////////////////
// sendMessageInMainThreadToTarget:sel:arg1:arg2:
////////////////////////////////////////////////////////////////////////////////

- (void) sendMessageInMainThreadToTarget:(id)target sel:(SEL)sel arg1:(id)arg1 arg2:(id)arg2
{
  if (!bDelegateMessagingEnabled) {
    return;
  }
  else {
    NSMethodSignature *aSignature   = [[target class] instanceMethodSignatureForSelector:sel];
    NSInvocation      *anInvocation = [NSInvocation invocationWithMethodSignature:aSignature];

    [anInvocation setSelector:sel];
    [anInvocation setTarget:target];
    [anInvocation setArgument:&arg1 atIndex:2];
    [anInvocation setArgument:&arg2 atIndex:3];
    [anInvocation retainArguments];

    [delegateMessageArrayLock lock];
    [delegateMessageArray addObject: anInvocation];
    [delegateMessageArrayLock unlock];

    [bgdm_threadLock lock];
    bgdm_sem = BGDM_delegateMessageReady;
    [bgdm_threadLock unlockWithCondition:BGDM_hasFlag];
  }
}

////////////////////////////////////////////////////////////////////////////////
// stopStreaming
// Responsible for calling low-level C stuff to stop a stream,
// and unregister the processAudioAtTime: selector as the callback function.
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
    [mixer managerIsShuttingDown];
#if SNDSTREAMMANAGER_DEBUG
    NSLog(@"[manager] about to send shutdown to stream...\n");
#endif

    [bg_threadLock lock];
    bg_sem = BG_stopNow;
    [bg_threadLock unlockWithCondition:BG_hasFlag];

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

- (BOOL) addClient: (SndStreamClient*) client
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

- (BOOL) removeClient: (SndStreamClient*) client
{
  return [mixer removeClient: client];

}

////////////////////////////////////////////////////////////////////////////////
//  Don't call!!! only for setting format properties for testing.
////////////////////////////////////////////////////////////////////////////////

- setFormat: (SndSoundStruct*) f
{
  memcpy(&format, f, sizeof(SndSoundStruct));
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// processAudio
////////////////////////////////////////////////////////////////////////////////

static void processAudio(double sampleCount, SNDStreamBuffer* cInB, SNDStreamBuffer* cOutB, void* obj)
{
    // Eventually these must be made instance variables which you just wrap
    // around each of the SNDStreamBuffers, to avoid allocation costs.

    NSAutoreleasePool *localPool = [NSAutoreleasePool new];
    SndAudioBuffer *inB  = nil;
    SndAudioBuffer *outB = nil;
    inB  = (cInB  == NULL) ? nil : [SndAudioBuffer audioBufferWrapperAroundSNDStreamBuffer: cInB ];
    outB = (cOutB == NULL) ? nil : [SndAudioBuffer audioBufferWrapperAroundSNDStreamBuffer: cOutB];

#if SNDSTREAMMANAGER_DEBUG
    NSLog(@"[Manager] --> processAudio sampleCount = %d\n", (int)sampleCount);
#endif
    [(SndStreamManager *) obj processStreamAtTime: sampleCount input: inB output: outB];
#if SNDSTREAMMANAGER_DEBUG
    NSLog(@"[Manager] <-- processAudio\n");
#endif

#if SNDSTREAMMANAGER_DEBUG
    NSLog(@"[Manager] About to release pool...\n");
#endif

    memcpy(cOutB->streamData, [outB bytes], cOutB->streamFormat.dataSize);

    [localPool release];
#if SNDSTREAMMANAGER_DEBUG
    NSLog(@"[Manager] Released pool...\n");
#endif
}

////////////////////////////////////////////////////////////////////////////////
// processAudioAtTime:input:output:
//
// Poll all the clients for their current output buffers, tell them to start
// processing
////////////////////////////////////////////////////////////////////////////////

- (void) processStreamAtTime: (double) sampleCount
                       input: (SndAudioBuffer*) inB
                      output: (SndAudioBuffer*) outB
{
#if SNDSTREAMMANAGER_DEBUG
    NSLog(@"[Manager] Entering...\n");
#endif
    if (active) {
	// set our current notion of time.
	if (outB != nil)
	    nowTime += [outB duration];
	else if (inB != nil)
	    nowTime += [inB duration];

#if SNDSTREAMMANAGER_DEBUG
	NSLog(@"[Manager] nowTime: %.3f sampleCount: %.3f\n", nowTime, sampleCount);
#endif
	[mixer processInBuffer: inB outBuffer: outB nowTime: nowTime];
#if SNDSTREAMMANAGER_DEBUG
	NSLog(@"[Manager] post mixer\n");
#endif
	if ([mixer clientCount] == 0) {// Hmm, no clients hey? Shut down the Stream.
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
- (double) samplingRate    { return format.samplingRate; }
- (SndSoundStruct*) format { return &format; }

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
