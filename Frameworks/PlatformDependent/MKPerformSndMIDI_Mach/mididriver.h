/*
  $Id$
  Defined In: The MusicKit
*/
/*
Modification history:

  $Log$
  Revision 1.3  2000/11/29 23:21:26  leigh
  Renamed MD functions to MKMD

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

/* Routine MKMDBecomeOwner */
mig_external kern_return_t MKMDBecomeOwner (
	mach_port_t mididriver_port,
	mach_port_t owner_port);

/* Routine MKMDReleaseOwnership */
mig_external kern_return_t MKMDReleaseOwnership (
	mach_port_t mididriver_port,
	mach_port_t owner_port);

/* Routine MKMDSetClockMode */
mig_external kern_return_t MKMDSetClockMode (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit,
	int clock_mode);

/* Routine MKMDGetClockTime */
mig_external kern_return_t MKMDGetClockTime (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	int *time);

/* Routine MKMDGetMTCTime */
mig_external kern_return_t MKMDGetMTCTime (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short *format,
	short *hours,
	short *minutes,
	short *seconds,
	short *frames);

/* Routine MKMDSetClockTime */
mig_external kern_return_t MKMDSetClockTime (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	int time);

/* SimpleRoutine MKMDRequestAlarm */
mig_external kern_return_t MKMDRequestAlarm (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	mach_port_t reply_port,
	int time);

/* Routine MKMDStartClock */
mig_external kern_return_t MKMDStartClock (
	mach_port_t mididriver_port,
	mach_port_t owner_port);

/* Routine MKMDStopClock */
mig_external kern_return_t MKMDStopClock (
	mach_port_t mididriver_port,
	mach_port_t owner_port);

/* Routine MKMDClaimUnit */
mig_external kern_return_t MKMDClaimUnit (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit);

/* Routine MKMDReleaseUnit */
mig_external kern_return_t MKMDReleaseUnit (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit);

/* Routine MKMDRequestExceptions */
mig_external kern_return_t MKMDRequestExceptions (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	mach_port_t error_port);

/* Routine MKMDRequestData */
mig_external kern_return_t MKMDRequestData (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit,
	mach_port_t reply_port);

/* Routine MKMDSendData */
mig_external kern_return_t MKMDSendData (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit,
	MKMDRawEventPtr data,
	unsigned int dataCnt);

/* Routine MKMDGetAvailableQueueSize */
mig_external kern_return_t MKMDGetAvailableQueueSize (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit,
	int *size);

/* Routine MKMDRequestQueueNotification */
mig_external kern_return_t MKMDRequestQueueNotification (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit,
	mach_port_t notification_port,
	int size);

/* Routine MKMDClearQueue */
mig_external kern_return_t MKMDClearQueue (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit);

/* Routine MKMDFlushQueue */
mig_external kern_return_t MKMDFlushQueue (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit);

/* Routine MKMDSetSystemIgnores */
mig_external kern_return_t MKMDSetSystemIgnores (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit,
	int sys_ignores);

/* Routine MKMDSetClockQuantum */
mig_external kern_return_t MKMDSetClockQuantum (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	int microseconds);

#endif	_mididriver
