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
*/
/*
Modification history:

  $Log$
  Revision 1.4  2000/12/15 02:02:29  leigh
  Initial Revision

  Revision 1.3  2000/11/29 19:44:38  leigh
  Updated to new function naming

  Revision 1.2  2000/03/11 01:58:55  leigh
  Removed uncompilable references to Windows PerformMidi cruft

  Revision 1.1.1.1  2000/01/14 00:14:34  leigh
  Initial revision
 
*/
#include "midi_driver.h"

#include "PerformSoundPrivate.h"

#define FUNCLOG 1

#ifdef FUNCLOG
#include <stdio.h> // for fprintf and debug

FILE *debug; // precedes extern "C".
#endif

#ifdef __cplusplus
extern "C" {
#endif 

  //static REFERENCE_TIME quantumFactor; // multiplicative factor difference between MusicKit quantum and REFERENCE_TIME
  //static REFERENCE_TIME datumRefTime;
  //static int datumMSecTime;

/* Routine MKMDBecomeOwner */
PERFORM_API kern_return_t MKMDBecomeOwner (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port)
{
#ifdef FUNCLOG
  if(debug == NULL) {
    // create a means to see where we are without having to tiptoe around the MS debugger.
    if((debug = fopen("/tmp/PerformMIDI_debug.txt", "w")) == NULL)
      return MKMD_ERROR_UNKNOWN_ERROR;
  }
  fprintf(debug, "MKMDBecomeOwner called\n");
#endif
  // TODO check the ports properly
//    if(!PMinitialise()) {
//      return MKMD_ERROR_BUSY;
//    }
//  datumRefTime = PMGetCurrentTime();
  return 0;
}

/* Routine MKMDReleaseOwnership */
PERFORM_API kern_return_t MKMDReleaseOwnership (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port)
{
#ifdef FUNCLOG
  // TODO check the ports properly
  fprintf(debug, "MKMDReleaseOwnership called\n");
  fclose(debug); // hopefully save what we did.
#endif
//  if(!PMterminate()) {
//      return MKMD_ERROR_BUSY;
//    }
//    else
    return 0;
}

/* Routine MKMDSetClockMode */
PERFORM_API kern_return_t MKMDSetClockMode (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	int clock_mode)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDSetClockMode called %d\n", clock_mode);
#endif
  return 0;
}

/* Routine MKMDGetClockTime */
PERFORM_API kern_return_t MKMDGetClockTime (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	int *time)
{
  //  REFERENCE_TIME currentRefTime;

#ifdef FUNCLOG
  fprintf(debug, "MKMDGetClockTime called\n");
#endif
  //  currentRefTime = PMGetCurrentTime();
  // TODO we need to properly convert the result to an int, since the division will reduce the actual result within those bounds.
  // *time = (int) (currentRefTime - datumRefTime) / quantumFactor;
  return 0;
}

/* Routine MKMDGetMTCTime */
PERFORM_API kern_return_t MKMDGetMTCTime (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short *format,
	short *hours,
	short *minutes,
	short *seconds,
	short *frames)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDGetMTCTime called\n");
#endif
  return 0;
}

/* Routine MKMDSetClockTime */
PERFORM_API kern_return_t MKMDSetClockTime (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	int time)
{
  // defines datum to associate the integer time to the nanosecond time
  //datumRefTime = PMGetCurrentTime();
  //datumMSecTime = time;
#ifdef FUNCLOG
  fprintf(debug, "MKMDSetClockTime called %d, datumRefTime = %d\n", time, 0);
#endif
  return 0;
}

/* SimpleRoutine MKMDRequestAlarm */
PERFORM_API kern_return_t MKMDRequestAlarm (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	MKMDReplyPort reply_port,
	int time)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDRequestAlarm called %d\n", time);
#endif
  return 0;
}

/* Routine MKMDStartClock */
PERFORM_API kern_return_t MKMDStartClock (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port)
{
  // TODO check the ports properly
#ifdef FUNCLOG
  fprintf(debug, "MKMDStartClock called\n");
#endif
  return TRUE;
}

/* Routine MKMDStopClock */
PERFORM_API kern_return_t MKMDStopClock (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port)
{
  // TODO check the ports properly
#ifdef FUNCLOG
  fprintf(debug, "MKMDStopClock called\n");
#endif
  return TRUE;
}

/* Routine MKMDClaimUnit */
PERFORM_API kern_return_t MKMDClaimUnit (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDClaimUnit called %d\n", unit);
#endif
  return TRUE;
}

/* Routine MKMDReleaseUnit */
PERFORM_API kern_return_t MKMDReleaseUnit (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDReleaseUnit called\n");
#endif
  return TRUE;
}

/* Routine MKMDRequestExceptions */
PERFORM_API kern_return_t MKMDRequestExceptions (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	MKMDReplyPort error_port)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDRequestExceptions called\n");
#endif
  return 0;
}

/* Routine MKMDRequestData */
PERFORM_API kern_return_t MKMDRequestData (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	MKMDReplyPort reply_port)
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
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	MKMDRawEventPtr data,
	unsigned int dataCnt)
{
  //  unsigned int msgIndex;
  //unsigned char *buffer;
  //REFERENCE_TIME dmTime;

#ifdef FUNCLOG
  fprintf(debug, "MKMDSendData called with %d events @ time %d\n", dataCnt, data[0].time);
#endif

  // need to convert the times, extract the data and pack back into buffer.
  //buffer = (unsigned char *) malloc(dataCnt);
  //for(msgIndex = 0; msgIndex < dataCnt; msgIndex++) {
  //  buffer[msgIndex] = data[msgIndex].byte;
  // }
  // we erronously assume all events specified in a single call are intended
  // to be sent immediately one after another.
  //dmTime = (data[0].time - datumMSecTime) * quantumFactor + datumRefTime;
#ifdef FUNCLOG
  //fprintf(debug,"Current time %I64d\n", PMGetCurrentTime());
#endif
  //if(!PMPackMessageForPlay(dmTime, buffer, dataCnt)) {
  //  free(buffer);
  //  return MKMD_ERROR_UNKNOWN_ERROR;
  //}
  // once the buffer has been packed, it can be discarded as packing copies the data.
  //free(buffer);
  //if(!PMPlayBuffer())
  //  return MKMD_ERROR_UNKNOWN_ERROR;
#ifdef FUNCLOG
  fprintf(debug,"MKMDSendData returning ok\n");
#endif
  return 0;
}

/* Routine MKMDGetAvailableQueueSize */
PERFORM_API kern_return_t MKMDGetAvailableQueueSize (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	int *size)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDGetAvailableQueueSize called\n");
#endif
  // return the queue size
  //if(!PMGetAvailableQueueSize(size)) {
  //  return MKMD_ERROR_UNKNOWN_ERROR;
  //}
  return 0;
}

/* Routine MKMDRequestQueueNotification */
PERFORM_API kern_return_t MKMDRequestQueueNotification (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	MKMDReplyPort notification_port,
	int size)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDRequestQueueNotification called %d\n", size);
#endif
  return 0;
}

/* Routine MKMDClearQueue */
PERFORM_API kern_return_t MKMDClearQueue (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDClearQueue called\n");
#endif
  return 0;
}

/* Routine MKMDFlushQueue */
PERFORM_API kern_return_t MKMDFlushQueue (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDFlushQueue called\n");
#endif
  return 0;
}

/* Routine MKMDSetSystemIgnores */
PERFORM_API kern_return_t MKMDSetSystemIgnores (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
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
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	int microseconds)
{
  // REFERENCE_TIME measured in 100ns units, I don't understand why MS needs such accuracy as it is well beyond perception...
  //quantumFactor = microseconds * 10;
#ifdef FUNCLOG
  fprintf(debug, "MKMDSetClockQuantum called %d microseconds, %d 100ns units\n", microseconds, 0);
#endif
  return 0;
}

PERFORM_API kern_return_t MKMDAwaitReply(MKMDPort port_set, MKMDReplyFunctions *funcs, int timeout)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDAwaitReply called %d timeout\n", timeout);
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
 */
PERFORM_API kern_return_t MIDIDownloadDLSInstruments(unsigned int *patchesToDownload, int patchesUsed)
{
    return TRUE;
}

// retrieve a list of strings giving driver names, and therefore (0 based) unit numbers.
PERFORM_API const char **MIDIGetAvailableDrivers(unsigned int *selectedDriver)
{
    static char *silentDriver = "silent MIDI Driver";
    *selectedDriver = 0;
    return &silentDriver;
}


#ifdef __cplusplus
}
#endif
