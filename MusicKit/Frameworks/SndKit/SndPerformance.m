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

+ (SndPerformance *) performanceOfSnd: (Snd *) s
                        playingAtTime: (double) t;
{
    return [[[SndPerformance alloc] initWithSnd: s playingAtTime: t] autorelease];
}

+ (SndPerformance *) performanceOfSnd: (Snd *) s
                        playingAtTime: (double) t
                         beginAtIndex: (long) beginIndex
			                     endAtIndex: (long) endIndex;
{
    return [[[SndPerformance alloc] initWithSnd: s
                                  playingAtTime: t
                                   beginAtIndex: beginIndex
				                             endAtIndex: endIndex] autorelease];
}

- initWithSnd: (Snd *) s playingAtTime: (double) t
{
    if (!snd) {
        return nil;
    }
    return [self initWithSnd:s playingAtTime:t beginAtIndex: 0 endAtIndex:[s sampleCount]];
}

- initWithSnd: (Snd *) s playingAtTime: (double) t 
                          beginAtIndex: (long) beginIndex
                            endAtIndex: (long) endIndex
{
    [super init];
    snd        = [s retain];
    playTime   = t;
    playIndex  = beginIndex;
    endAtIndex = endIndex;
    return self;
}

- (void) dealloc
{
    [snd release];
    [super dealloc]; 
}

// Copies receiver, including its Snd reference, play time and index.
- copyWithZone: (NSZone *) zone
{
    SndPerformance *newPerformance = [[SndPerformance allocWithZone: zone] init];
    
    // We do a lightweight copy since this is just a reference to the Snd anyway.
    newPerformance->snd        = [snd retain]; 
    newPerformance->playTime   = playTime;
    newPerformance->playIndex  = playIndex;
    newPerformance->endAtIndex = endAtIndex;
    return newPerformance; // no need to autorelease (by definition, "copy" is retained)
}

// We consider the performances to be equal if they are the same sound and start at the same time.
// The reason we don't consider the playIndex is because a performance would never match
// unless it is playing at exactly same sample.
- (BOOL) isEqual: (id) anotherPerformance
{
    BOOL equal = ((SndPerformance *) anotherPerformance)->snd == snd &&
                 ((SndPerformance *) anotherPerformance)->playTime == playTime &&
                 ((SndPerformance *) anotherPerformance)->endAtIndex == endAtIndex;
    // NSLog(@"checking if equal %@ vs. %@ = %s\n", self, anotherPerformance, equal ? "YES" : "NO");
    return equal;
}

- (NSString *) description
{
    return [NSString stringWithFormat: @"%@, playing at %f, from %ld, to %ld", snd, playTime, playIndex, endAtIndex];
}

- (Snd*) snd
{
    return [[snd retain] autorelease];
}

- (double) playTime
{
    return playTime;
}

- (long) playIndex
{
    return playIndex;
}

- (void) setPlayIndex: (long) newPlayIndex
{
    playIndex = newPlayIndex;
}

- (long) endAtIndex
{
    return endAtIndex;
}

- (void) setEndAtIndex: (long) newEndAtIndex
{
    endAtIndex = newEndAtIndex;
}

- (void) stopInFuture: (double) inSeconds
{
    [Snd stopPerformance: self inFuture: inSeconds];
}

@end
