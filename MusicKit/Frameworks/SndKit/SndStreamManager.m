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
    return sm;
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
    [super init];
    // How many clients? 10 for now - can always auto-grow...

    mixer = [SndStreamMixer sndStreamMixer];
    [mixer retain];

    active = FALSE;
    SNDStreamNativeFormat(&format);

    return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
    if (active)
        NSLog(@"SndStreamManager::dealloc - Error: stream is still active!!!");

    [mixer release];
//    NSLog(@"Manager version: MIXER");

    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
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

- (BOOL) startStreaming
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

    active = SNDStreamStart(processAudio, (void*) self);
    nowTime = 0.0;

#if SNDSTREAMMANAGER_DEBUG
    NSLog(@"SndManager::startStreaming - Stream starting!\n"); 
#endif        

    return active;
}

////////////////////////////////////////////////////////////////////////////////
// stopStreaming: responsible for calling low-level C stuff to stop a stream,
// and unregister the processAudioAtTime: selector as the callback function.
////////////////////////////////////////////////////////////////////////////////

- (BOOL) stopStreaming
{
    if (active) {
        [mixer managerIsShuttingDown];
        nowTime = 0.0;
        SNDStreamStop();
        active = FALSE;
#if SNDSTREAMMANAGER_DEBUG
        NSLog(@"SndManager::stopStreaming -  stream stopping");
#endif        
    }
    else {
        NSLog(@"SndManager::stopStreaming - Error: stopStreaming called when not streaming!\n");
    }
    return active;
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
    //NSLog(@"--> processAudio sampleCount = %d\n", (int)sampleCount);
    [(SndStreamManager *) obj processStreamAtTime: sampleCount input: cInB output: cOutB];
    //NSLog(@" <--processAudio\n");
}



- (void) processStreamAtTime: (double) sampleCount 
                       input: (SNDStreamBuffer*) cInB
                      output: (SNDStreamBuffer*) cOutB
{
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

      if ([mixer clientCount] == 0) // Hmm, no clients hey? Shut down the Stream.
        [self stopStreaming];

#if SNDSTREAMMANAGER_SPIKE_AT_BUFFER_START 
      {
        float *pF =  [outB data];
        pF[0] = 1.0f;
        pF[1] = 1.0f;
      }
#endif
      [localPool release];
    }
    else
      NSLog(@"SndStreamManager::processStreamAtTime - called when not active...?");
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
