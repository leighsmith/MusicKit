/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
*/
/*
  $Log$
  Revision 1.3  2005/05/14 03:27:26  leighsmith
  Clean up of parameter names to correct doxygen warnings

  Revision 1.2  1999/07/29 01:25:44  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_ConductorDelegate_H___
#define __MK_ConductorDelegate_H___

#import <Foundation/NSObject.h>
@interface MKConductorDelegate : NSObject

- conductorWillSeek: (id) sender;
- conductorDidSeek: (id) sender;
- conductorDidReverse: (id) sender;
- conductorDidPause: (id) sender;
- conductorDidResume: (id) sender;

-(double) beatToClock:(double)t from: (id) sender;
-(double) clockToBeat:(double)t from: (id) sender;

- conductorCrossedLowDeltaTThreshold;
- conductorCrossedHighDeltaTThreshold;

void MKSetLowDeltaTThreshold(double percentageOfDeltaT);
void MKSetHighDeltaTThreshold(double percentageOfDeltaT);

@end

#endif
