/* Copyright Pinnacle Research, 1993 */

#import "ConductorPrivate.h"
#import "_MTCHelper.h"


@implementation _MTCHelper:MKPerformer
{
    double timeSlip;
    double period;
    BOOL timeSlipped;
    id theMTCCond;
}

-init
{
    [super init];
    [self setConductor:[MKConductor clockConductor]];
    period = _MK_DEFAULT_MTC_POLL_PERIOD;
    return self;
}

-setMTCCond:obj
{
    theMTCCond = obj;
    return self;
}

-setPeriod:(double)p
{
    period = p;
    return self;
}

-activateSelf
{
    nextPerform = period;
    timeSlip = 0;
    timeSlipped = NO;
    return self;
}

-perform
{
    if (timeSlipped) {
	[theMTCCond _adjustPauseOffset:timeSlip];
	timeSlip = 0;
	timeSlipped = NO;
    }
    nextPerform = period;
    return self;
}

-setTimeSlip:(double)v
  /* Writing this sets the flag */
{
    timeSlip = v;
    timeSlipped = (timeSlip != 0);
    return self;
}

@end
