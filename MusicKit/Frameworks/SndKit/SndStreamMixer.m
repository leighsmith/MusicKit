////////////////////////////////////////////////////////////////////////////////
//
//  SndStreamMixer.m
//  SndKit
//
//  Created by skot on Tues Mar 27 2001. <skot@tomandandy.com>
//  Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and non-commercial
//  purposes so long as the author attribution and copyright messages remain intact and
//  accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import <MKPerformSndMIDI/PerformSound.h>
#import "SndStreamMixer.h"
#import "SndAudioProcessor.h"

@implementation SndStreamMixer

////////////////////////////////////////////////////////////////////////////////
// sndStreamMixer
////////////////////////////////////////////////////////////////////////////////

+ sndStreamMixer
{
  SndStreamMixer* mixer = [[SndStreamMixer alloc] init];
  return [mixer autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
    if(streamClients == nil) {
      streamClients = [NSMutableArray arrayWithCapacity: 10];
      [streamClients retain]; 
    }
    if(streamClientsLock == nil) {
      streamClientsLock = [[NSLock alloc] init];
      [streamClientsLock retain];
    }    
    if (processorChain == nil) {
      processorChain = [SndAudioProcessorChain audioProcessorChain];
      [processorChain retain];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
  [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// processInBuffer:outBuffer:nowTime:
////////////////////////////////////////////////////////////////////////////////

- processInBuffer: (SndAudioBuffer*) inB 
        outBuffer: (SndAudioBuffer*) outB 
          nowTime: (double) t
{
    int clientCount, i;
    
    [streamClientsLock lock];
    clientCount = [streamClients count];

//    [outB mixWithBuffer: inB];
    [outB zeroForeignBuffer];
    if (clientCount > 0) {
        for (i = 0; i < clientCount; i++) {
        
            SndStreamClient *client = [streamClients objectAtIndex: i];
            if ([client generatesOutput]) {
              // Look at each client's currently exposed output buffer, and add  to mix.

              [client lockOutputBuffer];
              [outB mixWithBuffer: [client outputBuffer]];
              [client unlockOutputBuffer];
            }
            // Each client should have a second synthing buffer, and a synth thread
            [client startProcessingNextBufferWithInput: inB nowTime: t];
            
            // Do any audio processing on the mix
        }
    }
    [processorChain processBuffer: outB];
    [streamClientsLock unlock];
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
        [streamClientsLock unlock];
    }
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
// @managerIsShuttingDown
////////////////////////////////////////////////////////////////////////////////

- managerIsShuttingDown
{
    [streamClientsLock lock];    // wait for current processBuffers to finish.
    [streamClients makeObjectsPerformSelector: @selector(managerIsShuttingDown)];    
    [streamClientsLock unlock];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// @audioProcessorChain
////////////////////////////////////////////////////////////////////////////////

- (SndAudioProcessorChain*) audioProcessorChain
{
  return processorChain;
}

////////////////////////////////////////////////////////////////////////////////

@end
