/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#ifndef __MK_ConductorDelegate_H___
#define __MK_ConductorDelegate_H___

#import <Foundation/NSObject.h>
@interface MKConductorDelegate : NSObject

- conductorWillSeek:sender;
- conductorDidSeek:sender;
- conductorDidReverse:sender;
- conductorDidPause:sender;
- conductorDidResume:sender;

-(double) beatToClock:(double)t from:sender;
-(double) clockToBeat:(double)t from:sender;

- conductorCrossedLowDeltaTThreshold;
- conductorCrossedHighDeltaTThreshold;

void MKSetLowDeltaTThreshold(double percentageOfDeltaT);
void MKSetHighDeltaTThreshold(double percentageOfDeltaT);

@end



#endif
