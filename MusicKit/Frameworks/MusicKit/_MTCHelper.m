/*
  $Id$
  Defined In: The MusicKit

  Description:
  Original Author: David Jaffe

  Copyright (c) Pinnacle Research, 1993
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:26:00  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#import "ConductorPrivate.h"
#import "_MTCHelper.h"


@implementation _MTCHelper

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
