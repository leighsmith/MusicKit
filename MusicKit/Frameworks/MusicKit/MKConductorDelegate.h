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
  @brief Set and get Music Kit time values

  <b>MKGetTime()</b> returns the current time, in seconds, during a Music
  Kit performance.   In a conducted performance (the norm), this is the
  same as [MKConductor time]. 
   
   <b>MKSetDeltaT()</b> sets a performance's delta time in seconds.  The
  delta time value is used in one of two ways, depending on the delta time
  "mode", which is set with <b>MKSetDeltaTMode()</b>.  In
  MK_DELTAT_DEVICE_LAG mode, deltaT is added into the timestamps of DSP
  and MIDI messages, thus imposing a time lag between the Music Kit and
  these devices. If, on the other hand, the delta time mode is
  MK_DELTAT_SCHEDULER_ADVANCE, then deltaT is the amount by which the
  Music Kit MKConductor attempts to run ahead of the devices.  In either
  case, the lag is sometimes necessary to allow the Music Kit sufficient
  compute time while maintaining rhythmic integrity.  Effective delta time
  values can be quite small; for an application that requires real-time
  response, a delta time of as much as 10 milliseconds (0.01 seconds) is
  tolerable.  Delta time only affects devices that are timed.  In
  addition, in order for the delta time value to be valid, the performance
  and the devices must be started at (virtually) the same time.  That is,
  send <b>[orchestra run]</b> and <b>[midi run]</b> immediately before
  sending <b>[MKConductor startPerformance]</b>;
   
   <b>MKGetDeltaT()</b> returns the delta time value, in seconds. The
  meaning of delta time depends on whether the performance is clocked or
  unclocked.  In a clocked performance, the MKConductor tries to stay
  <i>approximately</i> delta time seconds ahead of the devices (e.g. DSP).
  In an unclocked performance, MKConductor tries to stay <i>at least</i>
  delta time seconds ahead of the devices. Delta time has an effect only
  if the device is in timed mode.
   
   <b>MKGetDeltaTTime()</b> returns the sum of the values returned by
  <b>MKGetTime()</b> and <b>MKGetDeltaT()</b>.  
   
   <b>MKSetTime()</b> and <b>MKFinishPerformance()</b> are provided to
  set the performance time and to end a performance, respectively, <i>but
  only in the case of a performance that doesn't use the MKConductor
  class.</i>  <i></i> During a conducted performance, <b>MKSetTime()</b>
  has no effect and <b>MKFinishPerformance()</b> is the same as sending
  <b>finishPerformance</b> to the MKConductor class.    Precisely,
  <b>MKFinishPerformance()</b> his the effect of evaluating the
  MKConductor's "after performance" queue of messages, which in turn tells
  the Performers and Instruments that the performance is finished. 
     
   <b>MKSetLowDeltaTThreshold()</b> and <b>MKSetHighDeltaTThreshold()</b> controls the high and low watermark for the delta time notification mechanism. For example, to receive a message when the MKConductor has fallen behind such that the effective delta time is less than 1/4 of the value of MKGetDeltaT(), you'd call <b>MKSetLowDeltaTThreshold(.25);</b>  Similarly, to receive a message when the MKConductor has recovered such that the effective delta time is more than 3/4 of the value of <b>MKGetDeltaT()</b>, you'd call <b>MKSetHighDeltaTThreshold(.75);  </b>This mechanism allows you to receive a warning when the MKConductor is about to fall out of real time, due to heavy computation.   For example, you might want to automatically reduce the tempo in this case.  The notification itself is sent to the MKConductor class' delegate object.  See MKConductor.h for further details.  
   
   <b>MKSetDeltaTMode();</b>  Sets the delta time mode to one of
  MK_DELTAT_DEVICE_LAG or MK_DELTAT_SCHEDULER_ADVANCE .    The default is
  MK_DELTAT_DEVICE_LAG.
   
   <b>MKGetDeltaTMode();</b>  Returns the delta time mode.
  @param  percentageOfDeltaT is a double.
*/
void MKSetLowDeltaTThreshold(double percentageOfDeltaT);

/*!
  @brief Set and get Music Kit time values

  <b>MKGetTime()</b> returns the current time, in seconds, during a Music
  Kit performance.   In a conducted performance (the norm), this is the
  same as [MKConductor time]. 
   
   <b>MKSetDeltaT()</b> sets a performance's delta time in seconds.  The
  delta time value is used in one of two ways, depending on the delta time
  "mode", which is set with <b>MKSetDeltaTMode()</b>.  In
  MK_DELTAT_DEVICE_LAG mode, deltaT is added into the timestamps of DSP
  and MIDI messages, thus imposing a time lag between the Music Kit and
  these devices. If, on the other hand, the delta time mode is
  MK_DELTAT_SCHEDULER_ADVANCE, then deltaT is the amount by which the
  Music Kit MKConductor attempts to run ahead of the devices.  In either
  case, the lag is sometimes necessary to allow the Music Kit sufficient
  compute time while maintaining rhythmic integrity.  Effective delta time
  values can be quite small; for an application that requires real-time
  response, a delta time of as much as 10 milliseconds (0.01 seconds) is
  tolerable.  Delta time only affects devices that are timed.  In
  addition, in order for the delta time value to be valid, the performance
  and the devices must be started at (virtually) the same time.  That is,
  send <b>[orchestra run]</b> and <b>[midi run]</b> immediately before
  sending <b>[MKConductor startPerformance]</b>;
   
   <b>MKGetDeltaT()</b> returns the delta time value, in seconds. The
  meaning of delta time depends on whether the performance is clocked or
  unclocked.  In a clocked performance, the MKConductor tries to stay
  <i>approximately</i> delta time seconds ahead of the devices (e.g. DSP).
  In an unclocked performance, MKConductor tries to stay <i>at least</i>
  delta time seconds ahead of the devices. Delta time has an effect only
  if the device is in timed mode.
   
   <b>MKGetDeltaTTime()</b> returns the sum of the values returned by
  <b>MKGetTime()</b> and <b>MKGetDeltaT()</b>.  
   
   <b>MKSetTime()</b> and <b>MKFinishPerformance()</b> are provided to
  set the performance time and to end a performance, respectively, <i>but
  only in the case of a performance that doesn't use the MKConductor
  class.</i>  <i></i> During a conducted performance, <b>MKSetTime()</b>
  has no effect and <b>MKFinishPerformance()</b> is the same as sending
  <b>finishPerformance</b> to the MKConductor class.    Precisely,
  <b>MKFinishPerformance()</b> his the effect of evaluating the
  MKConductor's "after performance" queue of messages, which in turn tells
  the Performers and Instruments that the performance is finished. 
     
   <b>MKSetLowDeltaTThreshold()</b> and <b>MKSetHighDeltaTThreshold()</b> controls the high and low watermark for the delta time notification mechanism. For example, to receive a message when the MKConductor has fallen behind such that the effective delta time is less than 1/4 of the value of MKGetDeltaT(), you'd call <b>MKSetLowDeltaTThreshold(.25);</b>  Similarly, to receive a message when the MKConductor has recovered such that the effective delta time is more than 3/4 of the value of <b>MKGetDeltaT()</b>, you'd call <b>MKSetHighDeltaTThreshold(.75);  </b>This mechanism allows you to receive a warning when the MKConductor is about to fall out of real time, due to heavy computation.   For example, you might want to automatically reduce the tempo in this case.  The notification itself is sent to the MKConductor class' delegate object.  See MKConductor.h for further details.  
   
   <b>MKSetDeltaTMode();</b>  Sets the delta time mode to one of
  MK_DELTAT_DEVICE_LAG or MK_DELTAT_SCHEDULER_ADVANCE .    The default is
  MK_DELTAT_DEVICE_LAG.
   
   <b>MKGetDeltaTMode();</b>  Returns the delta time mode.
  @param  percentageOfDeltaT is a double.
*/
void MKSetHighDeltaTThreshold(double percentageOfDeltaT);

@end

#endif
