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

////////////////////////////////////////////////////////////////////////////////
// SndPlayerData
////////////////////////////////////////////////////////////////////////////////

@implementation SndPlayerData

+ soundPlayerDataWithSnd: (Snd*) s playTime: (double) t 
{
    SndPlayerData *spd = [SndPlayerData alloc];
    spd->snd = s;
    [spd->snd retain];
    spd->playTime = t;
    spd->playIndex = 0;
    return [spd autorelease];
}

- (void) dealloc
{
    [snd release];
}

- (Snd*) snd
{
    return snd;
}

- (double) playTime
{
    return playTime;
}

- (long) playIndex
{
    return playIndex;
}

- (void) setPlayIndex: (long) li
{
    playIndex = li;
}

@end

////////////////////////////////////////////////////////////////////////////////
//  SndPlayer
////////////////////////////////////////////////////////////////////////////////

@implementation SndPlayer

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

+ player
{
    SndPlayer *sp = [SndPlayer alloc];
    sp->toBePlayed = nil;
    sp->playing    = nil;
    [sp init];
    return [sp autorelease];
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- init
{
    
    toBePlayed = [NSMutableArray arrayWithCapacity: 10];
    playing    = [NSMutableArray arrayWithCapacity: 10];

    [toBePlayed retain];
    [playing    retain];

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
    return @"SndPlayer object";
}

////////////////////////////////////////////////////////////////////////////////
// playSnd:
////////////////////////////////////////////////////////////////////////////////

- playSnd: (Snd*) s
{
    SndPlayerData *spd = [SndPlayerData soundPlayerDataWithSnd: s playTime: nowTime];
    [playing addObject: spd];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// playSnd:withTimeOffset:
////////////////////////////////////////////////////////////////////////////////

- playSnd: (Snd*) s withTimeOffset: (double) dt
{
    double playT = nowTime+dt;
    int i, c = [toBePlayed count];
    SndPlayerData *spd = [SndPlayerData soundPlayerDataWithSnd: s playTime: playT];
    int insertIndex = c;

    for (i = 0; i < c; i++) {
        SndPlayerData *this = [toBePlayed objectAtIndex: i];
        if ([this playTime] > playT) {
            insertIndex = i;
            break;
        }
    }
    [toBePlayed insertObject: spd atIndex: i];

    return self;
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


    // Are any of the 'TobePlayed' samples gonna fire off during this buffer?
    // If so, add 'em to the play array
    c = [toBePlayed count];
    for (i = 0; i < c; i++) {
        SndPlayerData *spd = [toBePlayed objectAtIndex: i];
        if ([spd playTime] < bufferEndTime) {
            [removalArray addObject: spd];
            [spd setPlayIndex: - [[spd snd] samplingRate] * ([spd playTime] - nowTime)];
            [playing addObject: spd];
        }
    }
    c = [removalArray count];
    for (i = 0; i < c; i++) {
        [toBePlayed removeObject: [removalArray objectAtIndex: i]];
    }
    [removalArray removeAllObjects];
    
    //*The plan*
    //
    // Create a temporary wrapper buffer around each audio segment we are mixing.

    c = [playing count];
    for (i = 0; i < c; i++) {
        SndPlayerData *spd = [playing objectAtIndex: i];
        Snd    *snd        = [spd snd];
        long    startIndex = [spd playIndex];
        long    sndLength  = [snd sampleCount];
        SndAudioBuffer *temp = nil;
        NSRange r = {startIndex, buffLength};

        if (buffLength + startIndex > sndLength)
            buffLength = sndLength - startIndex;
        r.length = buffLength;

        if (startIndex < 0) {
            r.length += startIndex;
            r.location = 0;
        }
        
        // TO DO trick: audio buffer must be sensitive to setting up segments
        // with start times/end times inside the buffer...?

        temp = [SndAudioBuffer audioBufferWithSndSeg: snd
                                            range: r];

        {
            int start = 0, end = buffLength;
            if (startIndex < 0)
                start = -startIndex;
            if (end + startIndex > sndLength)
                end = sndLength - startIndex;

            [outputBuffer mixWithBuffer: temp fromStart: start toEnd: end];
        }
        [spd setPlayIndex: startIndex + buffLength];
        if (r.location + buffLength > sndLength)
            [removalArray addObject: snd];
    }

    c = [removalArray count];
    for (i = 0; i < c; i++) {
        [playing removeObject: [removalArray objectAtIndex: i]];
    }
}

@end
