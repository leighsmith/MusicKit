/*
  $Id$
  Defined In: The MusicKit

  Description:
    Interface routines emulating the midi mach device driver of OpenStep/MacOsX

  Original Author: Leigh M. Smith, <leigh@tomandandy.com>, tomandandy music inc.

  30 July 1999, Copyright (c) 1999 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and this copyright message remains intact
  and accompanies all derived code.

  Just to cover my ass: DirectMusic, DirectSound and DirectX are registered trademarks
  of Microsoft Corp and they can have them.
*/
/*
Modification history:

  $Log$
  Revision 1.3  2000/12/14 04:59:06  leigh
  Renamed to latest function prefix

  Revision 1.2  2000/01/03 20:32:01  leigh
  moved FUNCLOG initialisation to PerformMIDI.m, fixed precision warnings

  Revision 1.1.1.1  1999/11/17 17:57:14  leigh
  Initial working version


*/
#include "stdafx.h"
typedef int port_t;
#include "mididriver_types.h"
#include "mididriverUser.h"
// According to comments in objbase.h, if initguid.h is included after it, then the
// DEFINE_GUID is magically defined which seems to stop the linking of the DLL
// from complaining about missing IID definitions, specifically IID_IDirectMusic.
// This is all new functionality of VC++6.0 which breaks the  compilation of 
// MS's own DirMusic 6.1 demos!
//#include <objbase.h>
//#include <initguid.h>
#include <dmusicc.h>  // for Core Layer DirectMusic class definitions
#include "PerformMIDI.h"

#ifdef FUNCLOG
#include <stdio.h> // for fprintf and debug

FILE *debug = NULL; // precedes extern "C".
#endif

#ifdef __cplusplus
extern "C" {
#endif 

static REFERENCE_TIME quantumFactor; // multiplicative factor difference between MusicKit quantum and REFERENCE_TIME
static REFERENCE_TIME datumRefTime;
static int datumMSecTime;

/* Routine MKMKMDBecomeOwner */
PERFORM_API kern_return_t MKMKMDBecomeOwner (
	port_t mididriver_port,
	port_t owner_port)
{
  // TODO check the ports properly
  if(!PMinitialise()) {
    return MKMKMD_ERROR_BUSY;
  }
#ifdef FUNCLOG
  // PMinitialise must open the debug log file
  fprintf(debug, "MKMKMDBecomeOwner called\n");
#endif
  datumRefTime = PMGetCurrentTime();
  return 0;
}

/* Routine MKMKMDReleaseOwnership */
PERFORM_API kern_return_t MKMKMDReleaseOwnership (
	port_t mididriver_port,
	port_t owner_port)
{
#ifdef FUNCLOG
  // TODO check the ports properly
  fprintf(debug, "MKMKMDReleaseOwnership called\n");
  fclose(debug); // hopefully save what we did.
#endif

  if(!PMterminate()) {
    return MKMKMD_ERROR_BUSY;
  }
  else
    return 0;
}

/* Routine MKMKMDSetClockMode */
PERFORM_API kern_return_t MKMKMDSetClockMode (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	int clock_mode)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMKMDSetClockMode called %d\n", clock_mode);
#endif
  return 0;
}

/* Routine MKMKMDGetClockTime */
PERFORM_API kern_return_t MKMKMDGetClockTime (
	port_t mididriver_port,
	port_t owner_port,
	int *time)
{
  REFERENCE_TIME currentRefTime;

#ifdef FUNCLOG
  fprintf(debug, "MKMKMDGetClockTime called\n");
#endif
  currentRefTime = PMGetCurrentTime();
  // TODO we need to properly convert the result to an int, since the division will reduce the actual result within those bounds.
  *time = (int) ((currentRefTime - datumRefTime) / quantumFactor);
  return 0;
}

/* Routine MKMKMDGetMTCTime */
PERFORM_API kern_return_t MKMKMDGetMTCTime (
	port_t mididriver_port,
	port_t owner_port,
	short *format,
	short *hours,
	short *minutes,
	short *seconds,
	short *frames)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMKMDGetMTCTime called\n");
#endif
  return 0;
}

/* Routine MKMKMDSetClockTime */
PERFORM_API kern_return_t MKMKMDSetClockTime (
	port_t mididriver_port,
	port_t owner_port,
	int time)
{
  // defines datum to associate the integer time to the nanosecond time
  datumRefTime = PMGetCurrentTime();
  datumMSecTime = time;
#ifdef FUNCLOG
  fprintf(debug, "MKMKMDSetClockTime called %d, datumRefTime = %I64d\n", time, datumRefTime);
#endif
  return 0;
}

/* SimpleRoutine MKMKMDRequestAlarm */
PERFORM_API kern_return_t MKMKMDRequestAlarm (
	port_t mididriver_port,
	port_t owner_port,
	port_t reply_port,
	int time)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMKMDRequestAlarm called %d\n", time);
#endif
  return 0;
}

/* Routine MKMKMDStartClock */
PERFORM_API kern_return_t MKMKMDStartClock (
	port_t mididriver_port,
	port_t owner_port)
{
  // TODO check the ports properly
#ifdef FUNCLOG
  fprintf(debug, "MKMKMDStartClock called\n");
#endif
  return !PMactivate();
}

/* Routine MKMKMDStopClock */
PERFORM_API kern_return_t MKMKMDStopClock (
	port_t mididriver_port,
	port_t owner_port)
{
  // TODO check the ports properly
#ifdef FUNCLOG
  fprintf(debug, "MKMKMDStopClock called\n");
#endif
  return !PMdeactivate();
}

/* Routine MKMKMDClaimUnit */
PERFORM_API kern_return_t MKMKMDClaimUnit (
	port_t mididriver_port,
	port_t owner_port,
	short unit)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMKMDClaimUnit called %d\n", unit);
#endif
  return !PMSetMIDIPortNum(unit);
}

/* Routine MKMKMDReleaseUnit */
PERFORM_API kern_return_t MKMKMDReleaseUnit (
	port_t mididriver_port,
	port_t owner_port,
	short unit)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMKMDReleaseUnit called\n");
#endif
  return !PMReleaseMIDIPortNum(unit);
}

/* Routine MKMKMDRequestExceptions */
PERFORM_API kern_return_t MKMKMDRequestExceptions (
	port_t mididriver_port,
	port_t owner_port,
	port_t error_port)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMKMDRequestExceptions called\n");
#endif
  return 0;
}

/* Routine MKMDRequestData */
PERFORM_API kern_return_t MKMDRequestData (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	port_t reply_port)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDRequestData called\n");
#endif
  return 0;
}

/* Routine MKMDSendData */
// Each event consists of a time stamp per byte. This was done to allow slowing byte output
// to stop choking synths with sysex messages. Nowdays it would seem better just to specify
// an inter-byte delay and specify the start time of the channel byte.
PERFORM_API kern_return_t MKMDSendData (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	MKMDRawEventPtr data,
	unsigned int dataCnt)
{
  unsigned int msgIndex;
  unsigned char *buffer;
  REFERENCE_TIME dmTime;

#ifdef FUNCLOG
  fprintf(debug, "MKMDSendData called with %d events @ time %d\n", dataCnt, data[0].time);
#endif

  // need to convert the times, extract the data and pack back into buffer.
  buffer = (unsigned char *) malloc(dataCnt);
  for(msgIndex = 0; msgIndex < dataCnt; msgIndex++) {
    buffer[msgIndex] = data[msgIndex].byte;
  }
  // we erronously assume all events specified in a single call are intended
  // to be sent immediately one after another.
  dmTime = (data[0].time - datumMSecTime) * quantumFactor + datumRefTime;
#ifdef FUNCLOG
  fprintf(debug,"Current time %I64d\n", PMGetCurrentTime());
#endif
  if(!PMPackMessageForPlay(dmTime, buffer, dataCnt)) {
    free(buffer);
    return MKMD_ERROR_UNKNOWN_ERROR;
  }
  // once the buffer has been packed, it can be discarded as packing copies the data.
  free(buffer);
  if(!PMPlayBuffer())
    return MKMD_ERROR_UNKNOWN_ERROR;
#ifdef FUNCLOG
  fprintf(debug,"MKMDSendData returning ok\n");
#endif
  return 0;
}

/* Routine MKMDGetAvailableQueueSize */
PERFORM_API kern_return_t MKMDGetAvailableQueueSize (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	int *size)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDGetAvailableQueueSize called\n");
#endif
  // return the queue size
  if(!PMGetAvailableQueueSize(size)) {
    return MKMD_ERROR_UNKNOWN_ERROR;
  }
  return 0;
}

/* Routine MKMDRequestQueueNotification */
PERFORM_API kern_return_t MKMDRequestQueueNotification (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	port_t notification_port,
	int size)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDRequestQueueNotification called %d\n", size);
#endif
  return 0;
}

/* Routine MKMDClearQueue */
PERFORM_API kern_return_t MKMDClearQueue (
	port_t mididriver_port,
	port_t owner_port,
	short unit)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDClearQueue called\n");
#endif
  return 0;
}

/* Routine MKMDFlushQueue */
PERFORM_API kern_return_t MKMDFlushQueue (
	port_t mididriver_port,
	port_t owner_port,
	short unit)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDFlushQueue called\n");
#endif
  return 0;
}

/* Routine MKMDSetSystemIgnores */
PERFORM_API kern_return_t MKMDSetSystemIgnores (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	int sys_ignores)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDSetSystemIgnores called 0x%x sys_ignores\n", sys_ignores);
#endif
  return 0;
}

/* Routine MKMDSetClockQuantum */
PERFORM_API kern_return_t MKMDSetClockQuantum (
	port_t mididriver_port,
	port_t owner_port,
	int microseconds)
{
  // REFERENCE_TIME measured in 100ns units, I don't understand why MS needs such accuracy as it is well beyond perception...
  quantumFactor = microseconds * 10;
#ifdef FUNCLOG
  fprintf(debug, "MKMDSetClockQuantum called %d microseconds, %I64d 100ns units\n", microseconds, quantumFactor);
#endif
  return 0;
}

PERFORM_API kern_return_t MKMDAwaitReply(port_t port_set, MKMDReplyFunctions *funcs, int timeout)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDAwaitReply called %d timeout\n");
#endif
  return 0;
}

PERFORM_API kern_return_t MKMDHandleReply(msg_header_t *msg, MKMDReplyFunctions *funcs)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDHandleReply called\n");
#endif
  return 0;
}

/*
 Since DLS is apparently a MMA spec, a case can be made to make it cross-platform. Rather than falling into
 emulating the DirectMusic API, an Objective C equivalent class paradigm is the best approach.
 Therefore we will need the ability to manage DLS collections and instruments at a cross-platform level.

 "Working with DLS data requires knowledge of the DLS specification and file structure. 
 For detailed information on these topics, see the document entitled Downloadable Sounds Level 1, published
 by the MIDI Manufacturers Association."

 Returns TRUE if successfully downloaded the sounds, FALSE if there was a problem.
 */
PERFORM_API kern_return_t MKMDDownloadDLSInstruments(unsigned int *patchesToDownload, int patchesUsed)
{
    return PMDownloadDLSInstruments(patchesToDownload, patchesUsed);
}

// return a list of strings giving driver names, and therefore (0 based) unit numbers.
PERFORM_API const char **MKMDGetAvailableDrivers(unsigned int *selectedDriver)
{
    return PMGetAvailableMIDIPorts(selectedDriver);
}


#ifdef __cplusplus
}
#endif