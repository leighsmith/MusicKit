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
    playingLock = [[NSLock alloc] init];  // controls adding and removing sounds from the playing list.
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
    NSString *description;
    [playingLock lock];
    description = [NSString stringWithFormat: @"SndPlayer to be played %@, playing %@", toBePlayed, playing];
    [playingLock unlock];
    return description;
}

// Start the given performance immediately by adding it to the playing list and firing off the delegate.
// We assume that any method calling this is doing the locking itself, hence this should not be used
// outside this class.
- _startPerformance: (SndPerformance *) performance
{
    [playing addObject: performance];
    // The delay between receiving this delegate and when the audio is actually played 
    // is an extra buffer, therefore: delay == buffLength/sampleRate after the delegate 
    // message has been received.
    [[performance snd] _setStatus:SND_SoundPlaying];
    [[performance snd] tellDelegate: @selector(willPlay:duringPerformance:)
                  duringPerformance: performance];
    return self;
}

// stop the given performance at some time in the future by adjusting it's playback ending
// (i.e sample accurate stopping for those into buzz-words). When the playback reaches the
// new endAtTime, the stop delegate message will be fired off then and the performance removed from
// the playing queue. If the request to stop precedes the start time, the performance is removed
// from the toBePlayed queue.
- stopPerformance: (SndPerformance *) performance inFuture: (double) inSeconds
{
    double whenToStop;
    double beginPlayTime;
    long stopAtSample;

    [playingLock lock];
    whenToStop = [self nowTime] + inSeconds;
    beginPlayTime = [performance playTime]; // in seconds
    if(whenToStop < beginPlayTime) {
        // stop before we even begin, delete the performance from the toBePlayed queue
        [toBePlayed removeObject: performance];
    }
    else {
        stopAtSample = (whenToStop - beginPlayTime) * [[performance snd] samplingRate];
        // NSLog(@"stopping at sample %ld\n", stopAtSample);
        // check stopAtSample since it could be beyond the length of the sound. 
        // If so, leave it stop at the end of the sound.
        if(stopAtSample < [[performance snd] sampleCount])
            [performance setEndAtIndex: stopAtSample];
    }
    [playingLock unlock];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// playSnd:withTimeOffset:
////////////////////////////////////////////////////////////////////////////////

- (SndPerformance *) playSnd: (Snd *) s withTimeOffset: (double) dt
{
    if(![self isActive]) {
        // NSLog(@"Added sndPlayer to defaultStreamManager\n");
        [[SndStreamManager defaultStreamManager] addClient: self];
    }

    if (dt == 0.0) {  // play now!
        SndPerformance *nowPerformance = [SndPerformance performanceOfSnd: s playingAtTime: [self nowTime]];
        [playingLock lock];
        [self _startPerformance: nowPerformance];    
        [playingLock unlock];
        return nowPerformance;
    }		
    else {            // play later!
        double playT = [self nowTime] + dt;
        int i;
        int numToBePlayed;
        int insertIndex;
        SndPerformance *laterPerformance = [SndPerformance performanceOfSnd: s playingAtTime: playT];
        
        // printf("playT = %f, nowTime = %f, dt = %f\n", playT, [self nowTime], dt);        
        [playingLock lock];
        numToBePlayed = [toBePlayed count];
        insertIndex = numToBePlayed;
        for (i = 0; i < numToBePlayed; i++) {
            SndPerformance *this = [toBePlayed objectAtIndex: i];
            if ([this playTime] > playT) {
                insertIndex = i;
                break;
            }
        }
        [toBePlayed insertObject: laterPerformance atIndex: i];
        [playingLock unlock];
        return laterPerformance;
    }
}

////////////////////////////////////////////////////////////////////////////////
// playSnd:
////////////////////////////////////////////////////////////////////////////////

- (SndPerformance *) playSnd: (Snd *) s
{
    return [self playSnd: s withTimeOffset: 0.0];
}

// stop all performances of the sound, at some point in the future.
- stopSnd: (Snd *) s withTimeOffset: (double) inSeconds
{
    NSArray *performancesToStop = [self performancesOfSnd: s];
    int performanceIndex;

    for(performanceIndex = 0; performanceIndex < [performancesToStop count]; performanceIndex++) {
        [self stopPerformance: [performancesToStop objectAtIndex: performanceIndex] inFuture: inSeconds];
    }
    return self;
}

// stop all performances of the sound immediately.
- stopSnd: (Snd *) s
{
    return [self stopSnd: s withTimeOffset: 0.0];
}

// Return an array of the performances of a given sound.
- (NSArray *) performancesOfSnd: (Snd *) snd
{
    int performanceIndex;
    NSMutableArray *performances = [NSArray array];
    SndPerformance *aPerformance;

    // extract out from our playing/toBePlayed lists those with Snds matching snd
    [playingLock lock];
    for(performanceIndex = 0; performanceIndex < [playing count]; performanceIndex++) {
        aPerformance = [playing objectAtIndex: performanceIndex];
        if([snd isEqual: [aPerformance snd]]) {
            [performances addObject: aPerformance];
        }
    }
    for(performanceIndex = 0; performanceIndex < [toBePlayed count]; performanceIndex++) {
        aPerformance = [toBePlayed objectAtIndex: performanceIndex];
        if([snd isEqual: [aPerformance snd]]) {
            [performances addObject: aPerformance];
        }
    }
    [playingLock unlock];
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
    int numberToBePlayed;
    int numberPlaying;
    int buffLength = [ab lengthInSamples];
    int i;
    NSMutableArray *removalArray = [NSMutableArray arrayWithCapacity: 10];

    [playingLock lock];
    
    // Are any of the 'toBePlayed' samples gonna fire off during this buffer?
    // If so, add 'em to the play array
    numberToBePlayed = [toBePlayed count];
    for (i = 0; i < numberToBePlayed; i++) {
        SndPerformance *performance = [toBePlayed objectAtIndex: i];
        if ([performance playTime] < bufferEndTime) {
            [removalArray addObject: performance];
            [performance setPlayIndex: - [[performance snd] samplingRate] * ([performance playTime] - [self nowTime])];
            [self _startPerformance: performance];
        }
    }
    [toBePlayed removeObjectsInArray: removalArray];
    [removalArray removeAllObjects];
    
    //*The plan*
    //
    // Create a temporary wrapper buffer around each audio segment we are mixing.

    numberPlaying = [playing count];
    for (i = 0; i < numberPlaying; i++) {
        SndPerformance *performance = [playing objectAtIndex: i];
        Snd    *snd          = [performance snd];
        long    startIndex   = [performance playIndex];
        long    endAtIndex   = [performance endAtIndex];  // allows us to play a sub-section of a sound.
        NSRange playRegion   = {startIndex, buffLength};
        
        if (buffLength + startIndex > endAtIndex)
            buffLength = endAtIndex - startIndex;
        playRegion.length = buffLength;

        if (startIndex < 0) {
            playRegion.length += startIndex;
            playRegion.location = 0;
        }

        // NSLog(@"startIndex = %ld, endAtIndex = %ld, location = %d, length = %d\n", startIndex, endAtIndex, playRegion.location, playRegion.length);
        // Negative buffer length means the endAtIndex was moved before the current playIndex, so we should skip any mixing and stop.
        if(buffLength > 0) {      
            int start = 0, end = buffLength;
            SndAudioBuffer *temp = [SndAudioBuffer audioBufferWithSndSeg: snd range: playRegion];
    
            if (startIndex < 0)
                start = -startIndex;
            if (end + startIndex > endAtIndex)
                end = endAtIndex - startIndex;

            // NSLog(@"calling mixWithBuffer from SndPlayer processBuffers start = %ld, end = %ld\n", start, end);
            [ab mixWithBuffer: temp fromStart: start toEnd: end];
            [performance setPlayIndex: startIndex + buffLength];
        }
        // When at the end of sounds, signal the delegate and remove the performance.
        if ([performance playIndex] >= endAtIndex) {
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
    [playingLock unlock];
}

@end
