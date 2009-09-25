/* 
  $Id$ 

  Description:
    This file defines status protocol for the MusicKit "devices".
    MusicKit "devices" are objects that interface to a Mach device. 
    The two MusicKit devices are MKMidi and MKOrchestra.
 
  Copyright 1988-1992, NeXT Inc.  All rights reserved.
  Portions Copyright 1999-2005, The MusicKit Project.
*/
#ifndef __MK_devstatus_H___
#define __MK_devstatus_H___

/*! 
  @file MKDeviceStatus.h
 */

/*!
  @brief Status for MKMidi/MKOrchestra MusicKit classes.
 
  <b>MKDeviceStatus</b> enum values define the status of objects that
  represent devices, such as MKMidi and the MKOrchestra.  Such classes are
  called <i>device classes</i>.  The values for <b>MKDeviceStatus</b> are
  defined below.
 
  There are five methods for changing the state, defined in all
  MusicKit device classes:
 
  <ul>
  <li><b>open</b>	Opens Mach device if not already open.  Resets object if
  needed.  Sets status to <b>MK_devOpen</b>.  Returns nil if some problem occurs,
  else self.</li>
  <li><b>run</b>	If not open, does a <b>[self open]</b>. If not already
  running, starts device clock.  Sets status to <b>MK_devRunning</b>.</li>
  <li><b>stop</b>	If not open, does a <b>[self open]</b>. Otherwise, stops
  device clock and sets status to <b>MK_devStopped</b>.</li>
  <li><b>close</b>	Closes the device after waiting for all enqueued
  events to finish. Returns self and sets status to <b>MK_devClosed</b> unless there's
  some problem closing the device, in which case, returns nil.</li>
  <li><b>abort</b>	Like close, but doesn't wait for enqueued events to finish.</li>
  </ul>
 */
typedef enum _MKDeviceStatus { 
    /*! Device is closed. */
    MK_devClosed = 0,
    /*! Device is open but its clock has not yet begun to run.
        It's clock is in a reset state. */
    MK_devOpen,
    /*! Device is open and its clock is running. */
    MK_devRunning,
    /*! Device is open, its clock has run, but it has been temporarily stopped. */
    MK_devStopped
} MKDeviceStatus;

#endif
