////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Original Author: SKoT McDonald <skot@tomandandy.com>
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and 
//  non-commercial purposes so long as the author attribution and copyright 
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import <MKPerformSndMIDI/PerformSound.h>
#import "SndStreamMixer.h"
#import "SndAudioProcessor.h"

////////////////////////////////////////////////////////////////////////////////
// Debug defines
////////////////////////////////////////////////////////////////////////////////

#define SNDSTREAMMIXER_DEBUG 0

@implementation SndStreamMixer

////////////////////////////////////////////////////////////////////////////////
// sndStreamMixer
////////////////////////////////////////////////////////////////////////////////

+ sndStreamMixer
{
  return [SndStreamMixer new];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
    if(streamClients == nil) 
      streamClients = [[NSMutableArray arrayWithCapacity: 10] retain];
      
    if(streamClientsLock == nil) 
      streamClientsLock = [NSRecursiveLock new];
      
    if (processorChain == nil) 
      processorChain = [[SndAudioProcessorChain audioProcessorChain] retain];
      
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
  [processorChain release];
  [streamClients release];
  [streamClientsLock release];
  [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// description
////////////////////////////////////////////////////////////////////////////////

- (NSString*) description
{
  int c = [self clientCount];
  return [NSString stringWithFormat: @"%@ with %i client%s", [super description], c, c > 1 ? "s" : ""];
}

////////////////////////////////////////////////////////////////////////////////
// processInBuffer:outBuffer:nowTime:
////////////////////////////////////////////////////////////////////////////////

- processInBuffer: (SndAudioBuffer*) inB
        outBuffer: (SndAudioBuffer*) outB
          nowTime: (double) t
{
    int clientCount, clientIndex;

    lastNowTime = nowTime;
    nowTime = t;
    [streamClientsLock lock];

    clientCount = [streamClients count];
    
//    [outB mixWithBuffer: inB];

#if SNDSTREAMMIXER_DEBUG
    NSLog(@"[mixer] Entering processInBuffer at time: %f **********\n",t);
#endif

    [outB zero];

    for (clientIndex = 0; clientIndex < clientCount; clientIndex++) {
	SndStreamClient *client = [streamClients objectAtIndex: clientIndex];

	if ([client generatesOutput]) {
	    SndAudioBuffer *currentlyExposedOutputBuffer;
	    
	    // Look at each client's currently exposed output buffer, and add to mix.
	    [client lockOutputBuffer];
	    currentlyExposedOutputBuffer = [client outputBuffer];
#if SNDSTREAMMIXER_DEBUG
	    NSLog(@"[mixer] mixing buffer %@\n", currentlyExposedOutputBuffer);
#endif
	    if (currentlyExposedOutputBuffer != nil)
		[outB mixWithBuffer: currentlyExposedOutputBuffer];
	    else {
		NSLog(@"[mixer] ERROR - tried to mix a nil output buffer!\n");
	    }
	    [client unlockOutputBuffer];
	}
	
	// Each client should have a second synthing buffer, and a synth thread.
	[client startProcessingNextBufferWithInput: inB nowTime: nowTime];	
    }
    // Do any audio processing on the mix
    [processorChain processBuffer: outB forTime: lastNowTime];

    [streamClientsLock unlock];

#if SNDSTREAMMIXER_DEBUG
    fprintf(stderr, "[mixer] Leaving processInBuffer\n");
#endif
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// addClient:
//
// Returns false if the client is already registered, or the audio device 
// couldn't start streaming... true if all is well.
////////////////////////////////////////////////////////////////////////////////

- (int) addClient: (SndStreamClient*) client
{
    int  clientCount;
    BOOL clientPresent;    

    [streamClientsLock lock];
    
    clientPresent = [streamClients containsObject: client];
    if (!clientPresent) 
        [streamClients addObject: client];
    clientCount   = [streamClients count];

#if SNDSTREAMMIXER_DEBUG    
    fprintf(stderr, "[mixer] SndStreamManager::addClient - client added.");
#endif
    
    [streamClientsLock unlock];
    return clientCount;
}

////////////////////////////////////////////////////////////////////////////////
// removeClient:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) removeClient: (SndStreamClient*) client
{
    BOOL clientPresent = [streamClients containsObject: client];

    if (clientPresent) {
        [streamClientsLock lock];
        [streamClients removeObject: client];        
#if SNDSTREAMMIXER_DEBUG    
        fprintf(stderr, "[mixer] SndStreamManager::removeClient - Removing client");
#endif
        [streamClientsLock unlock];
    }
    else
        NSLog(@"[mixer] SndStreamManager::removeClient - Error: client was not present.");
    
    return clientPresent;
}

////////////////////////////////////////////////////////////////////////////////
// clientCount
////////////////////////////////////////////////////////////////////////////////

- (int) clientCount
{
  return [streamClients count];
}

////////////////////////////////////////////////////////////////////////////////
// managerIsShuttingDown
////////////////////////////////////////////////////////////////////////////////

- managerIsShuttingDown
{
    [streamClientsLock lock];    // wait for current processBuffers to finish.
    if ([streamClients count] > 0)
      [streamClients makeObjectsPerformSelector: @selector(managerIsShuttingDown)];    
    [streamClientsLock unlock];
    
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
// resetTime:
////////////////////////////////////////////////////////////////////////////////

- (void) resetTime: (double) originTimeInSeconds
{
    int clientCount, clientIndex;
    [streamClientsLock lock];   
    clientCount = [streamClients count];
    if (clientCount > 0) {
        for (clientIndex = 0; clientIndex < clientCount; clientIndex++) {
            SndStreamClient *client = [streamClients objectAtIndex: clientIndex];
            [client resetTime: originTimeInSeconds];
        }
    }
    [streamClientsLock unlock];
}

////////////////////////////////////////////////////////////////////////////////
// clientAtIndex:
////////////////////////////////////////////////////////////////////////////////

- (SndStreamClient*) clientAtIndex: (int) clientIndex
{
  SndStreamClient *client;
  [streamClientsLock lock];
  client = [[[streamClients objectAtIndex: clientIndex] retain] autorelease];
  [streamClientsLock unlock];
  return client;
}

////////////////////////////////////////////////////////////////////////////////

@end
