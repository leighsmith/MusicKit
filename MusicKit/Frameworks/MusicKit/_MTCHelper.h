#ifndef __MK__MTCHelper_H___
#define __MK__MTCHelper_H___
/* Copyright Pinnacle Research, 1993 */

#import "MKPerformer.h" /*sb*/

@interface _MTCHelper:MKPerformer
{
    double timeSlip;
    double period;
    BOOL timeSlipped;
    id theMTCCond;
}

-init;
-activateSelf;
-setPeriod:(double)p;
-perform;
-setTimeSlip:(double)v;
-setMTCCond:obj;

@end


#endif
