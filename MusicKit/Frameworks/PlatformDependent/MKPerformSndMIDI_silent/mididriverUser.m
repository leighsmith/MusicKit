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
  Revision 1.1  2000/12/07 19:32:34  leigh
  Initial revision

  Revision 1.2  2000/05/05 22:41:09  leigh
  kludge around type definitions

  Revision 1.1  2000/03/11 01:42:20  leigh
  Initial Release

*/
#include "midi_driver.h"
//#include "mididriverUser.h"

//#include "PerformSoundPrivate.h"

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
PERFORM_API MKMDReturn MKMDBecomeOwner (
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
  return MKMD_SUCCESS;
}

/* Routine MKMDReleaseOwnership */
PERFORM_API MKMDReturn MKMDReleaseOwnership (
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
    return MKMD_SUCCESS;
}

/* Routine MKMDSetClockMode */
PERFORM_API MKMDReturn MKMDSetClockMode (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	int clock_mode)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDSetClockMode called %d\n", clock_mode);
#endif
  return MKMD_SUCCESS;
}

/* Routine MKMDGetClockTime */
PERFORM_API MKMDReturn MKMDGetClockTime (
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
  return MKMD_SUCCESS;
}

/* Routine MKMDGetMTCTime */
PERFORM_API MKMDReturn MKMDGetMTCTime (
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
  return MKMD_SUCCESS;
}

/* Routine MKMDSetClockTime */
PERFORM_API MKMDReturn MKMDSetClockTime (
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
  return MKMD_SUCCESS;
}

/* SimpleRoutine MKMDRequestAlarm */
PERFORM_API MKMDReturn MKMDRequestAlarm (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	MKMDReplyPort reply_port,
	int time)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDRequestAlarm called %d\n", time);
#endif
  return MKMD_SUCCESS;
}

/* Routine MKMDStartClock */
PERFORM_API MKMDReturn MKMDStartClock (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port)
{
  // TODO check the ports properly
#ifdef FUNCLOG
  fprintf(debug, "MKMDStartClock called\n");
#endif
  return MKMD_SUCCESS;
}

/* Routine MKMDStopClock */
PERFORM_API MKMDReturn MKMDStopClock (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port)
{
  // TODO check the ports properly
#ifdef FUNCLOG
  fprintf(debug, "MKMDStopClock called\n");
#endif
  return MKMD_SUCCESS;
}

/* Routine MKMDClaimUnit */
PERFORM_API MKMDReturn MKMDClaimUnit (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDClaimUnit called %d\n", unit);
#endif
  return MKMD_SUCCESS;
}

/* Routine MKMDReleaseUnit */
PERFORM_API MKMDReturn MKMDReleaseUnit (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDReleaseUnit called\n");
#endif
  return MKMD_SUCCESS;
}

/* Routine MKMDRequestExceptions */
PERFORM_API MKMDReturn MKMDRequestExceptions (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	port_t error_port)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDRequestExceptions called\n");
#endif
  return MKMD_SUCCESS;
}

/* Routine MKMDRequestData */
PERFORM_API MKMDReturn MKMDRequestData (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	MKMDReplyPort reply_port)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDRequestData called\n");
#endif
  return MKMD_SUCCESS;
}

/* Routine MKMDSendData */
// Each event consists of a time stamp per byte. This was done to allow slowing byte output
// to stop choking synths with sysex messages. Nowdays it would seem better just to specify
// an inter-byte delay and specify the start time of the channel byte.
PERFORM_API MKMDReturn MKMDSendData (
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
  return MKMD_SUCCESS;
}

/* Routine MKMDGetAvailableQueueSize */
PERFORM_API MKMDReturn MKMDGetAvailableQueueSize (
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
  return MKMD_SUCCESS;
}

/* Routine MKMDRequestQueueNotification */
PERFORM_API MKMDReturn MKMDRequestQueueNotification (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	MKMDReplyPort notification_port,
	int size)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDRequestQueueNotification called %d\n", size);
#endif
  return MKMD_SUCCESS;
}

/* Routine MKMDClearQueue */
PERFORM_API MKMDReturn MKMDClearQueue (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDClearQueue called\n");
#endif
  return MKMD_SUCCESS;
}

/* Routine MKMDFlushQueue */
PERFORM_API MKMDReturn MKMDFlushQueue (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDFlushQueue called\n");
#endif
  return MKMD_SUCCESS;
}

/* Routine MKMDSetSystemIgnores */
PERFORM_API MKMDReturn MKMDSetSystemIgnores (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	unsigned int sys_ignores)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDSetSystemIgnores called 0x%x sys_ignores\n", sys_ignores);
#endif
  return MKMD_SUCCESS;
}

/* Routine MKMDSetClockQuantum */
PERFORM_API MKMDReturn MKMDSetClockQuantum (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	int microseconds)
{
  // REFERENCE_TIME measured in 100ns units, I don't understand why MS needs such accuracy as it is well beyond perception...
  //quantumFactor = microseconds * 10;
#ifdef FUNCLOG
  fprintf(debug, "MKMDSetClockQuantum called %d microseconds, %d 100ns units\n", microseconds, 0);
#endif
  return MKMD_SUCCESS;
}

PERFORM_API MKMDReturn MKMDAwaitReply(MKMDReplyPort port_set, MKMDReplyFunctions *funcs, int timeout)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDAwaitReply called %d timeout\n", timeout);
#endif
  return MKMD_SUCCESS;
}

PERFORM_API MKMDReturn MKMDHandleReply(msg_header_t *msg, MKMDReplyFunctions *funcs)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDHandleReply called\n");
#endif
  return MKMD_SUCCESS;
}

/*
 Since DLS is apparently a MMA spec, a case can be made to make it cross-platform. Rather than falling into
 emulating the DirectMusic API, an Objective C equivalent class paradigm is the best approach.
 Therefore we will need the ability to manage DLS collections and instruments at a cross-platform level.

 "Working with DLS data requires knowledge of the DLS specification and file structure. 
 For detailed information on these topics, see the document entitled Downloadable Sounds Level 1, published
 by the MIDI Manufacturers Association."
 */
PERFORM_API MKMDReturn MKMDDownloadDLSInstruments(unsigned int *patchesToDownload, int patchesUsed)
{
    return MKMD_SUCCESS;
}

// retrieve a list of strings giving driver names, and therefore (0 based) unit numbers.
PERFORM_API const char **MKMDGetAvailableDrivers(unsigned int *selectedDriver)
{
    static char *silentDriver = "silent MIDI Driver";
    *selectedDriver = 0;
    return &silentDriver;
}

PERFORM_API MKMDPort
    MKMDGetMIDIDeviceOnHost(const char *hostname)
{
    NSMachPort *devicePort = [NSMachPort port]; // kludge it so it seems initialised
    if(*hostname) {
        NSLog(@"MIDI on remote hosts not yet implemented on MacOS X\n");
        return nil;
    }
    else
        return devicePort;
}

PERFORM_API MKMDReturn MKMDSetReplyCallback (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	void (*newCallbackFn)(void *),
        void *newCallbackParam)
{
    return MKMD_SUCCESS;
}

#ifdef __cplusplus
}
#endif
