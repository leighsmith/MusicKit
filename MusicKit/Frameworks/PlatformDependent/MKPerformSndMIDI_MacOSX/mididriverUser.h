/*
  $Id$
  Defined In: The MusicKit

  Description:
  Original Author: Leigh M. Smith <leigh@tomandandy.com>

 Copyright (c) Copyright (c) 1999 tomandandy.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and this copyright message remains intact
  and accompanies all derived code.

  Just to cover my ass: DirectMusic and DirectX are registered trademarks
  of Microsoft Corp and they can have them.

*/
/*
Modification history:

  $Log$
  Revision 1.1  2000/03/11 01:42:20  leigh
  Initial Release

  Revision 1.1.1.1  2000/01/14 00:14:34  leigh
  Initial revision

  Revision 1.1.1.1  1999/11/17 17:57:14  leigh
  Initial working version


*/
// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the PERFORMMIDI_EXPORTS
// symbol defined on the command line. this symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// PERFORMMIDI_API functions as being imported from a DLL, wheras this DLL sees symbols
// defined with this macro as being exported.
#define PERFORM_API

#ifdef __cplusplus
extern "C" {
#endif 

typedef int kern_return_t;
//typedef void *MDRawEventPtr;
//typedef int *MDReplyFunctions;
typedef int msg_header_t;

/* Routine MDBecomeOwner */
PERFORM_API kern_return_t MDBecomeOwner (
	port_t mididriver_port,
	port_t owner_port);

/* Routine MDReleaseOwnership */
PERFORM_API kern_return_t MDReleaseOwnership (
	port_t mididriver_port,
	port_t owner_port);

/* Routine MDSetClockMode */
PERFORM_API kern_return_t MDSetClockMode (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	int clock_mode);

/* Routine MDGetClockTime */
PERFORM_API kern_return_t MDGetClockTime (
	port_t mididriver_port,
	port_t owner_port,
	int *time);

/* Routine MDGetMTCTime */
PERFORM_API kern_return_t MDGetMTCTime (
	port_t mididriver_port,
	port_t owner_port,
	short *format,
	short *hours,
	short *minutes,
	short *seconds,
	short *frames);

/* Routine MDSetClockTime */
PERFORM_API kern_return_t MDSetClockTime (
	port_t mididriver_port,
	port_t owner_port,
	int time);

/* SimpleRoutine MDRequestAlarm */
PERFORM_API kern_return_t MDRequestAlarm (
	port_t mididriver_port,
	port_t owner_port,
	port_t reply_port,
	int time);

/* Routine MDStartClock */
PERFORM_API kern_return_t MDStartClock (
	port_t mididriver_port,
	port_t owner_port);

/* Routine MDStopClock */
PERFORM_API kern_return_t MDStopClock (
	port_t mididriver_port,
	port_t owner_port);

/* Routine MDClaimUnit */
PERFORM_API kern_return_t MDClaimUnit (
	port_t mididriver_port,
	port_t owner_port,
	short unit);

/* Routine MDReleaseUnit */
PERFORM_API kern_return_t MDReleaseUnit (
	port_t mididriver_port,
	port_t owner_port,
	short unit);

/* Routine MDRequestExceptions */
PERFORM_API kern_return_t MDRequestExceptions (
	port_t mididriver_port,
	port_t owner_port,
	port_t error_port);

/* Routine MDRequestData */
PERFORM_API kern_return_t MDRequestData (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	port_t reply_port);

/* Routine MDSendData */
PERFORM_API kern_return_t MDSendData (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	MDRawEventPtr data,
	unsigned int dataCnt);

/* Routine MDGetAvailableQueueSize */
PERFORM_API kern_return_t MDGetAvailableQueueSize (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	int *size);

/* Routine MDRequestQueueNotification */
PERFORM_API kern_return_t MDRequestQueueNotification (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	port_t notification_port,
	int size);

/* Routine MDClearQueue */
PERFORM_API kern_return_t MDClearQueue (
	port_t mididriver_port,
	port_t owner_port,
	short unit);

/* Routine MDFlushQueue */
PERFORM_API kern_return_t MDFlushQueue (
	port_t mididriver_port,
	port_t owner_port,
	short unit);

/* Routine MDSetSystemIgnores */
PERFORM_API kern_return_t MDSetSystemIgnores (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	int sys_ignores);

/* Routine MDSetClockQuantum */
PERFORM_API kern_return_t MDSetClockQuantum (
	port_t mididriver_port,
	port_t owner_port,
	int microseconds);

PERFORM_API kern_return_t MDAwaitReply(
  port_t port_set, 
  MDReplyFunctions *funcs,
  int timeout);

PERFORM_API kern_return_t MDHandleReply(
  msg_header_t *msg,
  MDReplyFunctions *funcs);

/* download the patch numbers (MSB,LSB,patch) to the sound card */
PERFORM_API kern_return_t MIDIDownloadDLSInstruments(
  unsigned int *instruments,
  int instrCount);

/* return the available drivers */
PERFORM_API const char **MIDIGetAvailableDrivers(
  unsigned int *selectedDriver);

#ifdef __cplusplus
}
#endif
