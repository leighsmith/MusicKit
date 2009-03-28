/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
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

/*!
  @brief Controls the low watermark for the delta time notification mechanism.

  <b>MKSetLowDeltaTThreshold()</b> and <b>MKSetHighDeltaTThreshold()</b> controls the high and low watermark for the
  delta time notification mechanism. For example, to receive a message when the MKConductor has fallen behind such 
  that the effective delta time is less than 1/4 of the value of MKGetDeltaT(), you'd call <b>MKSetLowDeltaTThreshold(.25);</b>
  Similarly, to receive a message when the MKConductor has recovered such that the effective delta time is more than 3/4
  of the value of <b>MKGetDeltaT()</b>, you'd call <b>MKSetHighDeltaTThreshold(.75);  </b>This mechanism allows you to
  receive a warning when the MKConductor is about to fall out of real time, due to heavy computation.   
  For example, you might want to automatically reduce the tempo in this case.  The notification itself is sent to the
  MKConductor class' delegate object.  See MKConductor.h for further details.  
   
  @param  percentageOfDeltaT is a double.
  @see <b>MKGetTime()</b>.
*/
void MKSetLowDeltaTThreshold(double percentageOfDeltaT);

/*!
 @brief Controls the high watermark for the delta time notification mechanism.
 
 <b>MKSetLowDeltaTThreshold()</b> and <b>MKSetHighDeltaTThreshold()</b> controls the high and low watermark for the
 delta time notification mechanism. For example, to receive a message when the MKConductor has fallen behind such 
 that the effective delta time is less than 1/4 of the value of MKGetDeltaT(), you'd call <b>MKSetLowDeltaTThreshold(.25);</b>
 Similarly, to receive a message when the MKConductor has recovered such that the effective delta time is more than 3/4
 of the value of <b>MKGetDeltaT()</b>, you'd call <b>MKSetHighDeltaTThreshold(.75);  </b>This mechanism allows you to
 receive a warning when the MKConductor is about to fall out of real time, due to heavy computation.   
 For example, you might want to automatically reduce the tempo in this case.  The notification itself is sent to the
 MKConductor class' delegate object.  See MKConductor.h for further details.  
 
 @param  percentageOfDeltaT is a double.
 @see <b>MKGetTime()</b>.
*/
void MKSetHighDeltaTThreshold(double percentageOfDeltaT);

@end

#endif
