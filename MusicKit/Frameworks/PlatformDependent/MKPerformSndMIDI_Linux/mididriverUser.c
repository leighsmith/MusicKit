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
  Revision 1.1  2000/01/14 00:14:34  leigh
  Initial revision

  Revision 1.1.1.1  1999/11/17 17:57:14  leigh
  Initial working version


*/
typedef int port_t;
#include "mididriver_types.h"
#include "mididriverUser.h"

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

/* Routine MDBecomeOwner */
PERFORM_API kern_return_t MDBecomeOwner (
	port_t mididriver_port,
	port_t owner_port)
{
#ifdef FUNCLOG
  if(debug == NULL) {
    // create a means to see where we are without having to tiptoe around the MS debugger.
    if((debug = fopen("/tmp/PerformMIDI_debug.txt", "w")) == NULL)
      return MD_ERROR_UNKNOWN_ERROR;
  }
  fprintf(debug, "MDBecomeOwner called\n");
#endif
  // TODO check the ports properly
//    if(!PMinitialise()) {
//      return MD_ERROR_BUSY;
//    }
//  datumRefTime = PMGetCurrentTime();
  return 0;
}

/* Routine MDReleaseOwnership */
PERFORM_API kern_return_t MDReleaseOwnership (
	port_t mididriver_port,
	port_t owner_port)
{
#ifdef FUNCLOG
  // TODO check the ports properly
  fprintf(debug, "MDReleaseOwnership called\n");
  fclose(debug); // hopefully save what we did.
#endif
//  if(!PMterminate()) {
//      return MD_ERROR_BUSY;
//    }
//    else
    return 0;
}

/* Routine MDSetClockMode */
PERFORM_API kern_return_t MDSetClockMode (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	int clock_mode)
{
#ifdef FUNCLOG
  fprintf(debug, "MDSetClockMode called %d\n", clock_mode);
#endif
  return 0;
}

/* Routine MDGetClockTime */
PERFORM_API kern_return_t MDGetClockTime (
	port_t mididriver_port,
	port_t owner_port,
	int *time)
{
  //  REFERENCE_TIME currentRefTime;

#ifdef FUNCLOG
  fprintf(debug, "MDGetClockTime called\n");
#endif
  //  currentRefTime = PMGetCurrentTime();
  // TODO we need to properly convert the result to an int, since the division will reduce the actual result within those bounds.
  // *time = (int) (currentRefTime - datumRefTime) / quantumFactor;
  return 0;
}

/* Routine MDGetMTCTime */
PERFORM_API kern_return_t MDGetMTCTime (
	port_t mididriver_port,
	port_t owner_port,
	short *format,
	short *hours,
	short *minutes,
	short *seconds,
	short *frames)
{
#ifdef FUNCLOG
  fprintf(debug, "MDGetMTCTime called\n");
#endif
  return 0;
}

/* Routine MDSetClockTime */
PERFORM_API kern_return_t MDSetClockTime (
	port_t mididriver_port,
	port_t owner_port,
	int time)
{
  // defines datum to associate the integer time to the nanosecond time
  //datumRefTime = PMGetCurrentTime();
  //datumMSecTime = time;
#ifdef FUNCLOG
  fprintf(debug, "MDSetClockTime called %d, datumRefTime = %I64d\n", time, 0);
#endif
  return 0;
}

/* SimpleRoutine MDRequestAlarm */
PERFORM_API kern_return_t MDRequestAlarm (
	port_t mididriver_port,
	port_t owner_port,
	port_t reply_port,
	int time)
{
#ifdef FUNCLOG
  fprintf(debug, "MDRequestAlarm called %d\n", time);
#endif
  return 0;
}

/* Routine MDStartClock */
PERFORM_API kern_return_t MDStartClock (
	port_t mididriver_port,
	port_t owner_port)
{
  // TODO check the ports properly
#ifdef FUNCLOG
  fprintf(debug, "MDStartClock called\n");
#endif
  return !PMactivate();
}

/* Routine MDStopClock */
PERFORM_API kern_return_t MDStopClock (
	port_t mididriver_port,
	port_t owner_port)
{
  // TODO check the ports properly
#ifdef FUNCLOG
  fprintf(debug, "MDStopClock called\n");
#endif
  return !PMdeactivate();
}

/* Routine MDClaimUnit */
PERFORM_API kern_return_t MDClaimUnit (
	port_t mididriver_port,
	port_t owner_port,
	short unit)
{
#ifdef FUNCLOG
  fprintf(debug, "MDClaimUnit called %d\n", unit);
#endif
  return !PMSetMIDIPortNum(unit);
}

/* Routine MDReleaseUnit */
PERFORM_API kern_return_t MDReleaseUnit (
	port_t mididriver_port,
	port_t owner_port,
	short unit)
{
#ifdef FUNCLOG
  fprintf(debug, "MDReleaseUnit called\n");
#endif
  return !PMReleaseMIDIPortNum(unit);
}

/* Routine MDRequestExceptions */
PERFORM_API kern_return_t MDRequestExceptions (
	port_t mididriver_port,
	port_t owner_port,
	port_t error_port)
{
#ifdef FUNCLOG
  fprintf(debug, "MDRequestExceptions called\n");
#endif
  return 0;
}

/* Routine MDRequestData */
PERFORM_API kern_return_t MDRequestData (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	port_t reply_port)
{
#ifdef FUNCLOG
  fprintf(debug, "MDRequestData called\n");
#endif
  return 0;
}

/* Routine MDSendData */
// Each event consists of a time stamp per byte. This was done to allow slowing byte output
// to stop choking synths with sysex messages. Nowdays it would seem better just to specify
// an inter-byte delay and specify the start time of the channel byte.
PERFORM_API kern_return_t MDSendData (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	MDRawEventPtr data,
	unsigned int dataCnt)
{
  //  unsigned int msgIndex;
  //unsigned char *buffer;
  //REFERENCE_TIME dmTime;

#ifdef FUNCLOG
  fprintf(debug, "MDSendData called with %d events @ time %d\n", dataCnt, data[0].time);
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
  //  return MD_ERROR_UNKNOWN_ERROR;
  //}
  // once the buffer has been packed, it can be discarded as packing copies the data.
  //free(buffer);
  //if(!PMPlayBuffer())
  //  return MD_ERROR_UNKNOWN_ERROR;
#ifdef FUNCLOG
  fprintf(debug,"MDSendData returning ok\n");
#endif
  return 0;
}

/* Routine MDGetAvailableQueueSize */
PERFORM_API kern_return_t MDGetAvailableQueueSize (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	int *size)
{
#ifdef FUNCLOG
  fprintf(debug, "MDGetAvailableQueueSize called\n");
#endif
  // return the queue size
  //if(!PMGetAvailableQueueSize(size)) {
  //  return MD_ERROR_UNKNOWN_ERROR;
  //}
  return 0;
}

/* Routine MDRequestQueueNotification */
PERFORM_API kern_return_t MDRequestQueueNotification (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	port_t notification_port,
	int size)
{
#ifdef FUNCLOG
  fprintf(debug, "MDRequestQueueNotification called %d\n", size);
#endif
  return 0;
}

/* Routine MDClearQueue */
PERFORM_API kern_return_t MDClearQueue (
	port_t mididriver_port,
	port_t owner_port,
	short unit)
{
#ifdef FUNCLOG
  fprintf(debug, "MDClearQueue called\n");
#endif
  return 0;
}

/* Routine MDFlushQueue */
PERFORM_API kern_return_t MDFlushQueue (
	port_t mididriver_port,
	port_t owner_port,
	short unit)
{
#ifdef FUNCLOG
  fprintf(debug, "MDFlushQueue called\n");
#endif
  return 0;
}

/* Routine MDSetSystemIgnores */
PERFORM_API kern_return_t MDSetSystemIgnores (
	port_t mididriver_port,
	port_t owner_port,
	short unit,
	int sys_ignores)
{
#ifdef FUNCLOG
  fprintf(debug, "MDSetSystemIgnores called 0x%x sys_ignores\n", sys_ignores);
#endif
  return 0;
}

/* Routine MDSetClockQuantum */
PERFORM_API kern_return_t MDSetClockQuantum (
	port_t mididriver_port,
	port_t owner_port,
	int microseconds)
{
  // REFERENCE_TIME measured in 100ns units, I don't understand why MS needs such accuracy as it is well beyond perception...
  //quantumFactor = microseconds * 10;
#ifdef FUNCLOG
  fprintf(debug, "MDSetClockQuantum called %d microseconds, %I64d 100ns units\n", microseconds, 0);
#endif
  return 0;
}

PERFORM_API kern_return_t MDAwaitReply(port_t port_set, MDReplyFunctions *funcs, int timeout)
{
#ifdef FUNCLOG
  fprintf(debug, "MDAwaitReply called %d timeout\n");
#endif
  return 0;
}

PERFORM_API kern_return_t MDHandleReply(msg_header_t *msg, MDReplyFunctions *funcs)
{
#ifdef FUNCLOG
  fprintf(debug, "MDHandleReply called\n");
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
    return PMDownloadDLSInstruments(patchesToDownload, patchesUsed);
}

// retrieve a list of strings giving driver names, and therefore (0 based) unit numbers.
PERFORM_API const char **MIDIGetAvailableDrivers(unsigned int *selectedDriver)
{
    return PMGetAvailableMIDIPorts(selectedDriver);
}


#ifdef __cplusplus
}
#endif
