/*
  $Id$
  Defined In: The MusicKit
*/
/*
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:26:06  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef	_mididriver
#define	_mididriver

#include <mach/kern_return.h>
#include <mach/port.h>
#include <mach/message.h>

#ifndef	mig_external
#define mig_external extern
#endif

#include <mach/std_types.h>
#include "mididriver_types.h"

/* Routine MDBecomeOwner */
mig_external kern_return_t MDBecomeOwner (
	port_t mididriver_port,
	port_t owner_port);

/* Routine MDReleaseOwnership */
mig_external kern_return_t MDReleaseOwnership (
	port_t mididriver_port,
	port_t owner_port);

/* Routine MDSetClockMode */
mig_external kern_return_t MDSetClockMode (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	int clock_mode);

/* Routine MDGetClockTime */
mig_external kern_return_t MDGetClockTime (
	port_t mididriver_port,
	port_t owner_port,
	int *time);

/* Routine MDGetMTCTime */
mig_external kern_return_t MDGetMTCTime (
	port_t mididriver_port,
	port_t owner_port,
	short *format,
	short *hours,
	short *minutes,
	short *seconds,
	short *frames);

/* Routine MDSetClockTime */
mig_external kern_return_t MDSetClockTime (
	port_t mididriver_port,
	port_t owner_port,
	int time);

/* SimpleRoutine MDRequestAlarm */
mig_external kern_return_t MDRequestAlarm (
	port_t mididriver_port,
	port_t owner_port,
	port_t reply_port,
	int time);

/* Routine MDStartClock */
mig_external kern_return_t MDStartClock (
	port_t mididriver_port,
	port_t owner_port);

/* Routine MDStopClock */
mig_external kern_return_t MDStopClock (
	port_t mididriver_port,
	port_t owner_port);

/* Routine MDClaimUnit */
mig_external kern_return_t MDClaimUnit (
	port_t mididriver_port,
	port_t owner_port,
	short unit);

/* Routine MDReleaseUnit */
mig_external kern_return_t MDReleaseUnit (
	port_t mididriver_port,
	port_t owner_port,
	short unit);

/* Routine MDRequestExceptions */
mig_external kern_return_t MDRequestExceptions (
	port_t mididriver_port,
	port_t owner_port,
	port_t error_port);

/* Routine MDRequestData */
mig_external kern_return_t MDRequestData (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	port_t reply_port);

/* Routine MDSendData */
mig_external kern_return_t MDSendData (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	MDRawEventPtr data,
	unsigned int dataCnt);

/* Routine MDGetAvailableQueueSize */
mig_external kern_return_t MDGetAvailableQueueSize (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	int *size);

/* Routine MDRequestQueueNotification */
mig_external kern_return_t MDRequestQueueNotification (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	port_t notification_port,
	int size);

/* Routine MDClearQueue */
mig_external kern_return_t MDClearQueue (
	port_t mididriver_port,
	port_t owner_port,
	short unit);

/* Routine MDFlushQueue */
mig_external kern_return_t MDFlushQueue (
	port_t mididriver_port,
	port_t owner_port,
	short unit);

/* Routine MDSetSystemIgnores */
mig_external kern_return_t MDSetSystemIgnores (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	int sys_ignores);

/* Routine MDSetClockQuantum */
mig_external kern_return_t MDSetClockQuantum (
	port_t mididriver_port,
	port_t owner_port,
	int microseconds);

#endif	_mididriver
