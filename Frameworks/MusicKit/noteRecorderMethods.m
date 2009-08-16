/*
  $Id$
  Defined In: The MusicKit

  Description:
  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:26:12  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
//sb:
//#import <objc/objc.h> /* for BOOL */
//#import "timeunits.h" /* for MKTimeUnit */

-(MKTimeUnit)timeUnit
  /* TYPE: Querying; Returns the receiver's recording mode.
   * Returns YES if the receiver is set to do post-tempo recording.
   */
{
    return timeUnit;
}

-setTimeUnit:(MKTimeUnit)aTimeUnit
  /* TYPE: Modifying; Sets the receiver's recording mode to evaluate tempo.
   * Sets the receiver's realization recording mode to do post-tempo recording.
   * Returns the receiver.
   * Illegal while the receiver is active. Returns nil in this case, otherwise
   * self.
   */
{
    if ([self inPerformance] && (timeUnit != aTimeUnit))
      return nil;
    timeUnit = aTimeUnit;
    return self;
}

- setDeltaTCompensation:(BOOL)yesOrNo /* default is NO */
{
    compensatesDeltaT = yesOrNo;
    return self;
}

- (BOOL)compensatesDeltaT
{
    return compensatesDeltaT;
}

