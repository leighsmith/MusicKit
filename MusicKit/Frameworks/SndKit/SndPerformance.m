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

+ performanceOfSnd: (Snd*) s playTime: (double) t 
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
