/*
  $Id$

  Description:

  Original Author: SKoT McDonald, <skot@tomandandy.com>, tomandandy music inc.

  Sat 10-Feb-2001, Copyright (c) 2001 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/

#import "SndAudioBuffer.h"
#import "SndStreamClient.h" 
#import "SndStreamMixer.h"
#import "SndStreamManager.h"

#define SNDSTREAMMANAGER_DEBUG                  0
#define SNDSTREAMMANAGER_SPIKE_AT_BUFFER_START  0

void processAudio(double sampleCount, SNDStreamBuffer* cInB, SNDStreamBuffer* cOutB, void* obj);

/* the enums are dual purpose -- they serve as condition locks for
 * bg_threadlock, and they also serve as the values held by
 * bg_sem to tell the bg thread which activity to perform.
 */
enum {
    BG_ready,
    BG_hasFlag,
    BG_stopNow,
    BG_startNow,
    BG_abortNow
};

@implementation SndStreamManager

static SndStreamManager *sm = nil;

////////////////////////////////////////////////////////////////////////////////
// streamManager factory
////////////////////////////////////////////////////////////////////////////////

+ (void) initialize
{
    sm = [[SndStreamManager new] retain];  // create our default
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
    [super init];

    mixer         = [SndStreamMixer sndStreamMixer];
    bg_threadLock = [[NSConditionLock alloc] initWithCondition: BG_ready];
    active        = FALSE;
    bg_active     = FALSE;
    nowTime       = 0;
    SNDStreamNativeFormat(&format);

    return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
#if SNDSTREAMMANAGER_DEBUG
    fprintf(stderr,"[manager] starting dealloc\n");
#endif

    if (active)
        NSLog(@"SndStreamManager::dealloc - Error: stream is still active!!!");

    [mixer release];
//    NSLog(@"Manager version: MIXER");

#if SNDSTREAMMANAGER_DEBUG
    fprintf(stderr,"[manager] ending dealloc\n");
#endif

    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// description
////////////////////////////////////////////////////////////////////////////////

- (NSString*) description
{
    return [NSString stringWithFormat: @"SndStreamManager object with %i clients",
        [mixer clientCount]];
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

    // Get the native hardware stream format....

    if (!bg_active) {
        [NSThread detachNewThreadSelector: @selector(streamStartStopThread)
                                 toTarget: self
                               withObject: nil];
    }
    [bg_threadLock lock];
    bg_sem = BG_startNow;
    [bg_threadLock unlockWithCondition:BG_hasFlag];
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
#if SNDSTREAMMANAGER_DEBUG
            NSLog(@"SndManager::startStreaming - Stream starting!\n");
#endif
        }
        else if (bg_sem == BG_stopNow) {
            SNDStreamStop();
#if SNDSTREAMMANAGER_DEBUG
            NSLog(@"SndManager::stopStreaming -  stream stopping");
#endif
            active = FALSE;
            nowTime = 0.0;
            bg_sem = 0;
            [bg_threadLock unlock];
            break;
        }
        else if (bg_sem == BG_abortNow) {
            [bg_threadLock unlock];
            break;
        }
        [bg_threadLock unlockWithCondition:BG_ready];
    }
#if SNDSTREAMMANAGER_DEBUG
    NSLog(@"SndManager::exiting bg thread\n");
#endif
    [self release];
    [localPool release];
    /* even if there is a new thread is created between the following two
     * statements, that would be ok -- there would temporarily be one
     * extra thread but it won't cause a problem
     */
    bg_active = FALSE;
    [NSThread exit];
}

////////////////////////////////////////////////////////////////////////////////
// stopStreaming: responsible for calling low-level C stuff to stop a stream,
// and unregister the processAudioAtTime: selector as the callback function.
////////////////////////////////////////////////////////////////////////////////

- (void) stopStreaming
{
    if (active) {
#if SNDSTREAMMANAGER_DEBUG
    fprintf(stderr,"[manager] sending shutdown to mixer...\n");
#endif
        [mixer managerIsShuttingDown];
#if SNDSTREAMMANAGER_DEBUG
    fprintf(stderr,"[manager] about to send shutdown to stream...\n");
#endif
        [bg_threadLock lock];
        bg_sem = BG_stopNow;
        [bg_threadLock unlockWithCondition:BG_hasFlag];
#if SNDSTREAMMANAGER_DEBUG
    fprintf(stderr,"[manager] shutdown sent.\n");
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
        if (oldClientCount == 0) // There were no clients previously - better start the stream...
            [self startStreaming];
        [client welcomeClientWithBuffer: buff manager: self];
    }
    return active;
}

////////////////////////////////////////////////////////////////////////////////
//removeClient
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
// processAudioAtTime:input:output:
//
// Poll all the clients for their current output buffers, tell them to start
// processing
////////////////////////////////////////////////////////////////////////////////

void processAudio(double sampleCount, SNDStreamBuffer* cInB, SNDStreamBuffer* cOutB, void* obj)
{
#if SNDSTREAMMANAGER_DEBUG
      fprintf(stderr,"[Manager] --> processAudio sampleCount = %d\n", (int)sampleCount);
#endif
    [(SndStreamManager *) obj processStreamAtTime: sampleCount input: cInB output: cOutB];
#if SNDSTREAMMANAGER_DEBUG
      fprintf(stderr,"[Manager] <-- processAudio\n");
#endif
}



- (void) processStreamAtTime: (double) sampleCount 
                       input: (SNDStreamBuffer*) cInB
                      output: (SNDStreamBuffer*) cOutB
{
#if SNDSTREAMMANAGER_DEBUG
      fprintf(stderr,"[Manager] Entering...\n");
#endif
    if (active) {
      NSAutoreleasePool *localPool = [NSAutoreleasePool new];
      // Eventually these must be made instance variables which you just wrap
      // around each of the C-side buffers, to avoid allocation costs.
      SndAudioBuffer *inB  = nil;
      SndAudioBuffer *outB = nil;
      inB  = (cInB  == NULL) ? nil : [SndAudioBuffer audioBufferWrapperAroundSNDStreamBuffer: cInB ];
      outB = (cOutB == NULL) ? nil : [SndAudioBuffer audioBufferWrapperAroundSNDStreamBuffer: cOutB];
      
      // set our current notion of time.
      nowTime += [outB duration];
    
#if SNDSTREAMMANAGER_DEBUG
      fprintf(stderr,"[Manager] nowTime: %.3f sampleCount: %.3f\n",nowTime,sampleCount);
#endif
      [mixer processInBuffer: inB outBuffer: outB nowTime: nowTime];
#if SNDSTREAMMANAGER_DEBUG
      fprintf(stderr,"[Manager] post mixer\n");
#endif

      if ([mixer clientCount] == 0) {// Hmm, no clients hey? Shut down the Stream.
        [self stopStreaming]; 

#if SNDSTREAMMANAGER_DEBUG
      fprintf(stderr,"[Manager] signalling a stop stream...\n");
#endif
        
      }
#if SNDSTREAMMANAGER_SPIKE_AT_BUFFER_START 
      {
        float *pF =  [outB data];
        pF[0] = 1.0f;
        pF[1] = 1.0f;
      }
#endif

#if SNDSTREAMMANAGER_DEBUG
      fprintf(stderr,"[Manager] About to release pool...\n");
#endif
      [localPool release];
    }
    else
      NSLog(@"SndStreamManager::processStreamAtTime - called when not active...?");
#if SNDSTREAMMANAGER_DEBUG
      fprintf(stderr,"[Manager] Leaving...\n");
#endif
}

////////////////////////////////////////////////////////////////////////////////
// Return the managers sense of time.
////////////////////////////////////////////////////////////////////////////////

- (double) nowTime
{
    return nowTime;
}

- (SndStreamMixer*) mixer
{
    return mixer;
}

- (BOOL) isActive
{
  return active;
}

- (double) samplingRate
{
  return format.samplingRate;
}

- (void) resetTime: (double) originTimeInSeconds
{
  nowTime = originTimeInSeconds;
  [mixer resetTime: originTimeInSeconds];
}


////////////////////////////////////////////////////////////////////////////////

@end
