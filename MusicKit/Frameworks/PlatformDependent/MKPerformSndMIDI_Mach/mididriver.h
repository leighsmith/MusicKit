/*
  $Id$
  Defined In: The MusicKit
*/
/*
Modification history:

  $Log$
  Revision 1.2  2000/01/27 18:15:43  leigh
  upgraded to new typedef names for Mach

  Revision 1.1.1.1  1999/09/12 00:20:18  leigh
  separated out from MusicKit framework

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
	mach_port_t mididriver_port,
	mach_port_t owner_port);

/* Routine MDReleaseOwnership */
mig_external kern_return_t MDReleaseOwnership (
	mach_port_t mididriver_port,
	mach_port_t owner_port);

/* Routine MDSetClockMode */
mig_external kern_return_t MDSetClockMode (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit,
	int clock_mode);

/* Routine MDGetClockTime */
mig_external kern_return_t MDGetClockTime (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	int *time);

/* Routine MDGetMTCTime */
mig_external kern_return_t MDGetMTCTime (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short *format,
	short *hours,
	short *minutes,
	short *seconds,
	short *frames);

/* Routine MDSetClockTime */
mig_external kern_return_t MDSetClockTime (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	int time);

/* SimpleRoutine MDRequestAlarm */
mig_external kern_return_t MDRequestAlarm (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	mach_port_t reply_port,
	int time);

/* Routine MDStartClock */
mig_external kern_return_t MDStartClock (
	mach_port_t mididriver_port,
	mach_port_t owner_port);

/* Routine MDStopClock */
mig_external kern_return_t MDStopClock (
	mach_port_t mididriver_port,
	mach_port_t owner_port);

/* Routine MDClaimUnit */
mig_external kern_return_t MDClaimUnit (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit);

/* Routine MDReleaseUnit */
mig_external kern_return_t MDReleaseUnit (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit);

/* Routine MDRequestExceptions */
mig_external kern_return_t MDRequestExceptions (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	mach_port_t error_port);

/* Routine MDRequestData */
mig_external kern_return_t MDRequestData (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit,
	mach_port_t reply_port);

/* Routine MDSendData */
mig_external kern_return_t MDSendData (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit,
	MDRawEventPtr data,
	unsigned int dataCnt);

/* Routine MDGetAvailableQueueSize */
mig_external kern_return_t MDGetAvailableQueueSize (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit,
	int *size);

/* Routine MDRequestQueueNotification */
mig_external kern_return_t MDRequestQueueNotification (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit,
	mach_port_t notification_port,
	int size);

/* Routine MDClearQueue */
mig_external kern_return_t MDClearQueue (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit);

/* Routine MDFlushQueue */
mig_external kern_return_t MDFlushQueue (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit);

/* Routine MDSetSystemIgnores */
mig_external kern_return_t MDSetSystemIgnores (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit,
	int sys_ignores);

/* Routine MDSetClockQuantum */
mig_external kern_return_t MDSetClockQuantum (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	int microseconds);

#endif	_mididriver
