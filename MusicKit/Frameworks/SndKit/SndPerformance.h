/*
  $Id$

  Description:
    Holds the state associated with each sounding (or soon to be) Snd.
    This differs from a Snd instance itself, since we can have multiple overlapping
    performances of the same (potentially huge) Snd. We need some way of indicating
    to the delegate exactly which performance has completed.
    
  Original Author: Leigh Smith, <leigh@tomandandy.com>, tomandandy music inc.

  Sat 28-Feb-2001, Copyright (c) 2001 tomandandy music inc. All rights reserved.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/

#import <Foundation/Foundation.h>
#import "Snd.h"

@interface SndPerformance : NSObject
{
    Snd *snd;
    double playTime;
    long playIndex;
    // TODO playState should be here, not Snd.
}

+ performanceOfSnd: (Snd*) s playTime: (double) t ;
- (Snd *) snd;
- (double) playTime;

- (void) dealloc;
- (long) playIndex;
- (void) setPlayIndex: (long) li;

@end
