/* Copyright Pinnacle Research, 1993 */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:25:59  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK__MTCHelper_H___
#define __MK__MTCHelper_H___

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
