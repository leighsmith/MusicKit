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
#import "SndPlayer.h"
#import "SndStreamManager.h"
#import "SndPerformance.h"

////////////////////////////////////////////////////////////////////////////////
//  SndPlayer
////////////////////////////////////////////////////////////////////////////////

@implementation SndPlayer

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

+ player
{
    SndPlayer *sp = [[SndPlayer alloc] init];
    return [sp autorelease];
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- init
{
    [super init];
    if(toBePlayed == nil)
        toBePlayed = [[NSMutableArray arrayWithCapacity: 10] retain];
    if(playing == nil)
        playing    = [[NSMutableArray arrayWithCapacity: 10] retain];

    nowTime = 0;

    return self;
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
    if (toBePlayed != nil)
        [toBePlayed release];
    if (playing != nil)
        [playing release];
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- (NSString*) description
{
    return [NSString stringWithFormat: @"SndPlayer to be played %@, playing %@", toBePlayed, playing];
}

////////////////////////////////////////////////////////////////////////////////
// playSnd:
////////////////////////////////////////////////////////////////////////////////

- (SndPerformance *) playSnd: (Snd*) s
{
    SndPerformance *thisPerformance = [SndPerformance performanceOfSnd: s playTime: nowTime];
    [playing addObject: thisPerformance];
    return thisPerformance;
}

////////////////////////////////////////////////////////////////////////////////
// playSnd:withTimeOffset:
////////////////////////////////////////////////////////////////////////////////

- (SndPerformance *) playSnd: (Snd*) s withTimeOffset: (double) dt
{
    SndPerformance *thisPerformance;
    if(![self isActive]) {
        // NSLog(@"Added sndPlayer to defaultStreamManager\n");
        [[SndStreamManager defaultStreamManager] addClient: self];
    }

    if (dt == 0.0) {
        thisPerformance = [SndPerformance performanceOfSnd: s playTime: nowTime];
        [playing addObject: thisPerformance];    
    }		
    else {
        double playT = nowTime+dt;
        int i, c = [toBePlayed count];
        int insertIndex = c;
        thisPerformance = [SndPerformance performanceOfSnd: s playTime: playT];

        for (i = 0; i < c; i++) {
            SndPerformance *this = [toBePlayed objectAtIndex: i];
            if ([this playTime] > playT) {
                insertIndex = i;
                break;
            }
        }
        [toBePlayed insertObject: thisPerformance atIndex: i];
    }
    return thisPerformance;
}

// 
- stopSnd: (Snd*) s withTimeOffset: (double) inSeconds
{
    return self;
}

// Return an array of the performances of a given sound.
- (NSArray *) performancesOfSnd: (Snd *) snd
{
    NSMutableArray *performances = [NSArray array];
    // TODO, need to extract out from our playing/toBePlayed lists those with snds matching snd
    return performances;
}

////////////////////////////////////////////////////////////////////////////////
// processBuffers
////////////////////////////////////////////////////////////////////////////////
 
- (void) processBuffers  
{
    SndAudioBuffer* ab   = [super synthBuffer];
    double       bufferDur     = [ab duration];
//    double       sampleRate    = [ab samplingRate];
    double       bufferEndTime = [self nowTime] + bufferDur;
    int c;
    int buffLength = [ab lengthInSamples];
    int i;
    NSMutableArray *removalArray = [NSMutableArray arrayWithCapacity: 10];

    // Are any of the 'toBePlayed' samples gonna fire off during this buffer?
    // If so, add 'em to the play array
    c = [toBePlayed count];
    for (i = 0; i < c; i++) {
        SndPerformance *performance = [toBePlayed objectAtIndex: i];
        if ([performance playTime] < bufferEndTime) {
            [removalArray addObject: performance];
            [performance setPlayIndex: - [[performance snd] samplingRate] * ([performance playTime] - nowTime)];
            [playing addObject: performance];
            // The delay between receiving this delegate and when the audio is actually played 
            // is an extra buffer, therefore: delay = buffLength/sampleRate after the delegate 
            // message has been received.
            // NSLog(@"telling delegate willPlay:");
            [[performance snd] _setStatus:SND_SoundPlaying];
            [[performance snd] tellDelegate: @selector(willPlay:duringPerformance:)
                          duringPerformance: performance];
        }
    }
    [toBePlayed removeObjectsInArray: removalArray];
    [removalArray removeAllObjects];
    
    //*The plan*
    //
    // Create a temporary wrapper buffer around each audio segment we are mixing.

    c = [playing count];
    for (i = 0; i < c; i++) {
        SndPerformance *performance = [playing objectAtIndex: i];
        Snd    *snd        = [performance snd];
        long    startIndex = [performance playIndex];
        long    sndLength  = [snd sampleCount];
        SndAudioBuffer *temp = nil;
        NSRange r = {startIndex, buffLength};

        // NSLog(@"location = %d, length = %d\n", r.location, r.length);
        
        if (buffLength + startIndex > sndLength)
            buffLength = sndLength - startIndex;
        r.length = buffLength;

        if (startIndex < 0) {
            r.length += startIndex;
            r.location = 0;
        }
        
        temp = [SndAudioBuffer audioBufferWithSndSeg: snd range: r];

        {
            int start = 0, end = buffLength;
            if (startIndex < 0)
                start = -startIndex;
            if (end + startIndex > sndLength)
                end = sndLength - startIndex;

            // NSLog(@"calling mixWithBuffer from SndPlayer processBuffers\n");
            [ab mixWithBuffer: temp fromStart: start toEnd: end];
        }
        [performance setPlayIndex: startIndex + buffLength];
        // When at the end of sounds, signal the delegate and 
        if ([performance playIndex] >= sndLength) {
            [removalArray addObject: performance];
            [[performance snd] _setStatus: SND_SoundStopped];
            [[performance snd] tellDelegate: @selector(didPlay:duringPerformance:)
                          duringPerformance: performance];
        }
    }

    // NSLog(@"playing %d sounds", [playing count]);
    if ([removalArray count] == 1) {
        [playing removeObjectsInArray: removalArray];
        if([toBePlayed count] == 0 && [playing count] == 0) {
            active = FALSE;
            // NSLog(@"Setting active false\n");
        }
    }
}

@end
