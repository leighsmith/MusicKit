/*
  $Id$

  Description:
    Holds the state associated with each sounding (or soon to be) Snd.
    This differs from a Snd instance itself, since we can have multiple overlapping
    performances of the same Snd. We need some way of indicating to the delegate
    exactly which performance has completed.
    
  Original Author: Leigh Smith, <leigh@tomandandy.com>, tomandandy music inc.

  Sat 28-Feb-2001, Copyright (c) 2001 tomandandy music inc. All rights reserved.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/

#import "SndPerformance.h"

@implementation SndPerformance

+ (SndPerformance *) performanceOfSnd: (Snd *) s playTime: (double) t;
{
    SndPerformance *spd = [[SndPerformance alloc] init];
    spd->snd = [s retain];
    spd->playTime = t;
    spd->playIndex = 0;
    return [spd autorelease];
}

- (void) dealloc
{
    [snd release];
}

// Copies receiver, including its Snd reference, play time and index.
- copyWithZone: (NSZone *) zone
{
    SndPerformance *newPerformance = [[SndPerformance allocWithZone: zone] init];
    
    // We do a lightweight copy since this is just a reference to the Snd anyway.
    newPerformance->snd = snd; 
    newPerformance->playTime = playTime;
    newPerformance->playIndex = playIndex;
    return newPerformance; // should we autorelease?
}

// We consider the performances to be equal if they are the same sound and start at the same time.
// The reason we don't consider the playIndex is because a performance would never match
// unless it is playing at exactly same sample.
- (BOOL) isEqual: (id) anotherPerformance
{
    BOOL equal = ((SndPerformance *) anotherPerformance)->snd == snd &&
                 ((SndPerformance *) anotherPerformance)->playTime == playTime;
    // NSLog(@"checking if equal %@ vs. %@ = %s\n", self, anotherPerformance, equal ? "YES" : "NO");
    return equal;
}

- (NSString *) description
{
    return [NSString stringWithFormat: @"%@, playing at %f, from %ld", snd, playTime, playIndex];
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
