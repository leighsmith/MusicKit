/*
  $Id$

  Description:

  Original Author: SKoT McDonald, <skot@tomandandy.com>, tomandandy music inc.

  Sat 10-Feb-2001, Copyright (c) 2001 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/
#import <MKPerformSndMIDI/PerformSound.h>
#import "SndStreamManager.h"
#import "SndAudioBuffer.h"
#import "SndStreamClient.h" 

void processAudio(double sampleCount, SNDStreamBuffer* cInB, SNDStreamBuffer* cOutB, void* obj);

@implementation SndStreamManager

static SndStreamManager *sm = nil;

////////////////////////////////////////////////////////////////////////////////
// streamManager factory
////////////////////////////////////////////////////////////////////////////////

+ (void) initialize
{
    sm = [[SndStreamManager alloc] init];  // create our default
}

// Always return our initialized stream manager.
+ (SndStreamManager *) defaultStreamManager
{
    return sm;
}

- init
{
    [super init];
    // How many clients? 10 for now - can always auto-grow...
    if(streamClients == nil)
        streamClients = [NSMutableArray arrayWithCapacity: 10];
    streamClientsLock = [[NSLock alloc] init];
    [streamClientsLock retain];
    [streamClients retain]; 
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
        NSLog(@"SndStreamManager::dealloc: ERR: stream is still active!!!");

    [streamClientsLock release];
    [streamClients release];
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (NSString*) description
{
    NSString *s = nil;
    
    [streamClientsLock lock];
    s = [NSString stringWithFormat: @"SndStreamManager object with %i clients",
        [streamClients count]];
    [streamClientsLock unlock];

    return s;
}

////////////////////////////////////////////////////////////////////////////////
// startStreaming: responsible for calling low-level C stuff to get a stream 
// happening, and register the processAudioAtTime: selector as the callback 
// function.
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startStreaming
{
    // TO DO:
    // Tell MKPerformSndAndMidi to start sending us buffers, register the
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
    
    return active;
}

////////////////////////////////////////////////////////////////////////////////
// startStreaming: responsible for calling low-level C stuff to stop a stream,
// and unregister the processAudioAtTime: selector as the callback function.
////////////////////////////////////////////////////////////////////////////////

- (BOOL) stopStreaming
{
    [streamClientsLock lock];    // wait for current processBuffers to finish.
    if(active) {
        [streamClients makeObjectsPerformSelector: @selector(managerIsShuttingDown)];
    
        // Tell MKPerformSndMidi to stop sending us buffers
        SNDStreamStop();
    
        active = FALSE;
    }
    [streamClientsLock unlock];
    
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
    int c;
    BOOL clientPresent;
    
    [streamClientsLock lock];
    c = [streamClients count];
    clientPresent = [streamClients containsObject: client];
    [streamClientsLock unlock];

    if (!clientPresent) {
        SndAudioBuffer *buff = [SndAudioBuffer audioBufferWithFormat: &format data: NULL];


        [streamClientsLock lock];
        [streamClients addObject: client];
        [streamClientsLock unlock];

        if (c == 0) // There were no clients - better start the stream...
            [self startStreaming];
            
        [client welcomeClientWithBuffer: buff manager: self];
    }
    
    
    return (clientPresent && active);
}

////////////////////////////////////////////////////////////////////////////////
//removeClient
////////////////////////////////////////////////////////////////////////////////

- (BOOL) removeClient: (SndStreamClient*) client
{
    BOOL b = [streamClients containsObject: client];

    if (b) {
        [streamClientsLock lock];
        [streamClients removeObject: client];
        
//        if ([streamClients count] == 0 && active)
//            [self stopStreaming];
        [streamClientsLock unlock];
    }
    return b;
}

//  Don't call!!! only for setting format properties for testing.

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
    objc_msgSend(obj,@selector(processStreamAtTime:input:output:), sampleCount, cInB, cOutB);
}

- (void) processStreamAtTime: (double) sampleCount
                       input: (SNDStreamBuffer*) cInB
                      output: (SNDStreamBuffer*) cOutB
{
    NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];
    // Eventually these must be made instance variables which you just wrap
    // around each of the C-side buffers, to avoid allocation costs.
    SndAudioBuffer *inB  = [SndAudioBuffer audioBufferWrapperAroundSNDStreamBuffer: cInB ];
    SndAudioBuffer *outB = [SndAudioBuffer audioBufferWrapperAroundSNDStreamBuffer: cOutB];
    int i = 0, clientCount = 0;
    double t = sampleCount / [outB samplingRate];

    [streamClientsLock lock];
    clientCount = [streamClients count];

    if (clientCount > 0) {
        for (i = 0; i < clientCount; i++) {
            SndStreamClient *client = [streamClients objectAtIndex: i];

            // Look at each client's currently exposed output buffer, and add to mix
            // NSLog(@"calling mixWithBuffer from processStreamAtTime\n");
            [outB mixWithBuffer: [client outputBuffer]];

            // Each client should have a second synthing buffer, and a synth thread
            [client startProcessingNextBufferWithInput: inB nowTime: t];
        }
    }
    [streamClientsLock unlock];

    if (clientCount == 0) // Hmm, no clients hey? Shut down the Stream.
        [self stopStreaming];
    [localPool release];
}

////////////////////////////////////////////////////////////////////////////////

@end
