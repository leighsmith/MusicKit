/*
  $Id$
  Defined In: The MusicKit

  Description:
    MusicKit Interface routines to portmusic.

  Original Author: Leigh M. Smith, <leigh@leighsmith.com>

  Copyright (c) 2004 The MusicKit Project, All Rights Reserved.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and this copyright message remains intact
  and accompanies all derived code.
*/

#include <Foundation/Foundation.h>
#include "PerformSoundPrivate.h"
#include "PerformMIDI.h"

//#if HAVE_PORTMIDI_H
#include <portmidi.h>
//#endif
//#if HAVE_PORTTIME_H
#include <porttime.h>
//#endif

#include <stdlib.h>
#include <string.h>

#define FUNCLOG 1

#ifdef __cplusplus
extern "C" {
#endif 

//static REFERENCE_TIME quantumFactor; // multiplicative factor difference between MusicKit quantum and REFERENCE_TIME
//static REFERENCE_TIME datumRefTime;
//static int datumMSecTime;
static void (*callbackFn)(void *);
static void *callbackParam;

static PortMidiStream *inputStream;
static PortMidiStream *outputStream;
static long outputLatency = 10;

#define TIME_PROC ((long (*)(void *)) Pt_Time)
#define TIME_INFO NULL

PERFORM_API MKMDPort MKMDGetMIDIDeviceOnHost(const char *hostname)
{
    if(*hostname) {
        NSLog(@"MIDI on remote hosts not yet implemented on GNUstep\n");
        return MKMD_PORT_NULL;
    }
    else
        return !MKMD_PORT_NULL; // kludge it so it seems initialised
}

// Interpret the errorCode and return the appropriate error string
PERFORM_API char *MKMDErrorString(MKMDReturn errorCode)
{
    static char errMsg[80];
    sprintf(errMsg, "MusicKit portmidi Driver error encountered, code %d", errorCode);
    return errMsg;
}

/* Routine MKMDBecomeOwner */
PERFORM_API kern_return_t MKMDBecomeOwner (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port)
{
    PmError error;

#if FUNCLOG
    NSLog(@"MKMDBecomeOwner called owner port %d\n", owner_port);
#endif

    // TODO check the ports properly
    error = Pm_Initialize();
    if(error != pmNoError) {
	NSLog(@"MKMDBecomeOwner error: %s\n", Pm_GetErrorText(error));
	return MKMD_ERROR_BUSY;
    }
//  datumRefTime = PMGetCurrentTime();
    Pt_Start(1, 0, 0); /* timer started w/millisecond accuracy */
    NSLog(@"successful initialisation\n");
    return MKMD_SUCCESS;
}

/* Routine MKMDReleaseOwnership */
PERFORM_API kern_return_t MKMDReleaseOwnership (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port)
{
#if FUNCLOG
    // TODO check the ports properly
    NSLog(@"MKMDReleaseOwnership called\n");
#endif
    if(Pm_Terminate() != pmNoError) {
	return MKMD_ERROR_BUSY;
    }
    else {
	return MKMD_SUCCESS;
    }
}

/* Routine MKMDSetClockMode */
PERFORM_API kern_return_t MKMDSetClockMode (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	int clock_mode)
{
#if FUNCLOG
  NSLog(@"MKMDSetClockMode called %d\n", clock_mode);
#endif
  return MKMD_SUCCESS;
}

/* Routine MKMDGetClockTime */
PERFORM_API kern_return_t MKMDGetClockTime (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	int *time)
{
  //  REFERENCE_TIME currentRefTime;

#if FUNCLOG
  NSLog(@"MKMDGetClockTime called\n");
#endif
  //  currentRefTime = PMGetCurrentTime();
  // TODO we need to properly convert the result to an int, since the division will reduce the actual result within those bounds.
  // *time = (int) (currentRefTime - datumRefTime) / quantumFactor;
  return MKMD_SUCCESS;
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
#if FUNCLOG
  NSLog(@"MKMDGetMTCTime called\n");
#endif
  return MKMD_SUCCESS;
}

/* Routine MKMDSetClockTime */
PERFORM_API kern_return_t MKMDSetClockTime (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	int time)
{
    // defines datum to associate the integer time to the nanosecond time
    //datumRefTime = PMGetCurrentTime(); //datumMSecTime = time;
#if FUNCLOG
    NSLog(@"MKMDSetClockTime called %d, datumRefTime = %d\n", time, 0);
#endif
    return MKMD_SUCCESS;
}

/* SimpleRoutine MKMDRequestAlarm */
PERFORM_API kern_return_t MKMDRequestAlarm (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	MKMDReplyPort reply_port,
	int time)
{
#if FUNCLOG
    NSLog(@"MKMDRequestAlarm called %d\n", time);
#endif
    return MKMD_SUCCESS;
}

/* Routine MKMDStartClock */
PERFORM_API kern_return_t MKMDStartClock (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port)
{
    // TODO check the ports properly
#if FUNCLOG
    NSLog(@"MKMDStartClock called\n");
#endif
    return MKMD_SUCCESS;
}

/* Routine MKMDStopClock */
PERFORM_API kern_return_t MKMDStopClock (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port)
{
    // TODO check the ports properly
#if FUNCLOG
    NSLog(@"MKMDStopClock called\n");
#endif
    return MKMD_SUCCESS;
}

/* Routine MKMDClaimUnit */
PERFORM_API kern_return_t MKMDClaimUnit (BOOL input,
					 MKMDPort mididriver_port,
					 MKMDOwnerPort owner_port,
					 short unit)
{
    PmError error;
    PmDeviceID deviceID;
    int deviceIndex, availableDriverIndex = 0;

#if FUNCLOG
    // NSLog(@"MKMDClaimUnit called %d\n", unit);
#endif
    NSLog(@"MKMDClaimUnit called %d\n", unit);

    /* find the unit number in the single (input and output) device list */
    for (deviceIndex = 0; deviceIndex < Pm_CountDevices(); deviceIndex++) {
	const PmDeviceInfo *info = Pm_GetDeviceInfo(deviceIndex);

	if (info != NULL && ((input && info->input) || (!input && info->output))) {
	    NSLog(@"checking %d: %s %s\n", deviceIndex, info->name,
		  info->input ? "(input)" : info->output ? "(output)" : "problem!");

	    if(availableDriverIndex == unit)
		deviceID = deviceIndex;
	    availableDriverIndex++;    
	}
    }
    NSLog(@"Found deviceID %d for claiming\n", deviceID);

    if(input) {
	// buffer size is the number of input events to be buffered
	// waiting to be read using Pm_Read().
        // The value of 100 is a value used in portmidi test code, for now we use it.
	error = Pm_OpenInput(&inputStream,
			     deviceID,
			     NULL,
			     100, 
			     TIME_PROC,
			     TIME_INFO);
	if (error != pmNoError)
	    return MKMD_ERROR_UNIT_UNAVAILABLE;
    }
    else {
        // buffer_size specifies the number of output events to be buffered waiting for output.
	error = Pm_OpenOutput(&outputStream,
			      deviceID,
			      NULL,
			      0,
			      (outputLatency == 0 ? NULL : TIME_PROC),
			      (outputLatency == 0 ? NULL : TIME_INFO), 
			      outputLatency);
	if (error != pmNoError) {
	    NSLog(@"MKMDClaimUnit error: %s\n", Pm_GetErrorText(error));
	    return MKMD_ERROR_UNIT_UNAVAILABLE;
	}
    }
    return MKMD_SUCCESS;
}

/* Routine MKMDReleaseUnit */
PERFORM_API kern_return_t MKMDReleaseUnit (BOOL input,
					   MKMDPort mididriver_port,
					   MKMDOwnerPort owner_port,
					   short unit)
{
#if FUNCLOG
    NSLog(@"MKMDReleaseUnit called\n");
#endif
    if(Pm_Close(input ? inputStream : outputStream) != pmNoError) {
	return MKMD_ERROR_UNKNOWN_ERROR;
    }
    return MKMD_SUCCESS;
}

/* Routine MKMDRequestExceptions */
PERFORM_API kern_return_t MKMDRequestExceptions (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	MKMDReplyPort error_port)
{
#if FUNCLOG
    NSLog(@"MKMDRequestExceptions called\n");
#endif
    return MKMD_SUCCESS;
}

/* Routine MKMDRequestData */
PERFORM_API kern_return_t MKMDRequestData (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	MKMDReplyPort reply_port)
{
#if FUNCLOG
    NSLog(@"MKMDRequestData called\n");
#endif
  return MKMD_SUCCESS;
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
#define BYTES_PER_EVENT 4
    PmError error;
    unsigned int msgIndex = 0;
    PmEvent *eventBuffer;
    long eventIndex;
    long eventCount = (dataCnt + BYTES_PER_EVENT - 1) / BYTES_PER_EVENT;
    //REFERENCE_TIME dmTime;
    
#if FUNCLOG
    NSLog(@"MKMDSendData called with %d data, %ld events @ time %d\n", dataCnt, eventCount, data[0].time);
#endif

    // need to convert the times, extract the data and pack back into eventBuffer.
    eventBuffer = (PmEvent *) malloc(sizeof(PmEvent) * eventCount);
    for(eventIndex = 0; eventIndex < eventCount; eventIndex++) {
	eventBuffer[eventIndex].message = Pm_Message(data[msgIndex].byte, data[msgIndex+1].byte, data[msgIndex+2].byte);
	NSLog(@"msg = %lx", eventBuffer[eventIndex].message);
	// eventBuffer[eventIndex].timestamp = 0;
	eventBuffer[eventIndex].timestamp = data[msgIndex].time;
	// assume all events specified in a single call are intended
	// to be sent immediately one after another.
	// eventBuffer[eventIndex].timestamp = (data[msgIndex].time - datumMSecTime) * quantumFactor + datumRefTime;
	msgIndex += 3;
    }
#if FUNCLOG
    //NSLog(@"Current time %I64d\n", PMGetCurrentTime());
#endif
    error = Pm_Write(outputStream, eventBuffer, eventCount);
    free(eventBuffer);
    if(error != pmNoError) {
	NSLog(@"MKMDSendData error: %s\n", Pm_GetErrorText(error));
	return MKMD_ERROR_UNKNOWN_ERROR;
    }
#if FUNCLOG
    NSLog(@"MKMDSendData returning ok\n");
#endif
    return MKMD_SUCCESS;
}

/* Routine MKMDGetAvailableQueueSize */
PERFORM_API kern_return_t MKMDGetAvailableQueueSize (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	int *size)
{
#if FUNCLOG
    NSLog(@"MKMDGetAvailableQueueSize called\n");
#endif
    // return the queue size
    //if(!PMGetAvailableQueueSize(size)) {
    //  return MKMD_ERROR_UNKNOWN_ERROR;
    //}
    return MKMD_SUCCESS;
}

/* Routine MKMDRequestQueueNotification */
PERFORM_API kern_return_t MKMDRequestQueueNotification (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	MKMDReplyPort notification_port,
	int size)
{
#if FUNCLOG
    NSLog(@"MKMDRequestQueueNotification called %d\n", size);
#endif
    return MKMD_SUCCESS;
}

/* Routine MKMDClearQueue */
PERFORM_API kern_return_t MKMDClearQueue (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit)
{
#if FUNCLOG
    NSLog(@"MKMDClearQueue called\n");
#endif
    return MKMD_SUCCESS;
}

/* Routine MKMDFlushQueue */
PERFORM_API kern_return_t MKMDFlushQueue (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit)
{
#if FUNCLOG
    NSLog(@"MKMDFlushQueue called\n");
#endif
    return MKMD_SUCCESS;
}

/* Routine MKMDSetSystemIgnores */
PERFORM_API kern_return_t MKMDSetSystemIgnores (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	unsigned int ignoreBits)
{
#if FUNCLOG
    NSLog(@"MKMDSetSystemIgnores called 0x%x sys_ignores\n", ignoreBits);
#endif
    // Pm_SetFilter()
    return MKMD_SUCCESS;
}

/* Routine MKMDSetClockQuantum */
PERFORM_API kern_return_t MKMDSetClockQuantum (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	int microseconds)
{
    // REFERENCE_TIME measured in 100ns units, I don't understand why MS needs such accuracy as it is well beyond perception...
    //quantumFactor = microseconds * 10;
#if FUNCLOG
    NSLog(@"MKMDSetClockQuantum called %d microseconds, %d 100ns units\n", microseconds, 0);
#endif
    return MKMD_SUCCESS;
}

PERFORM_API kern_return_t MKMDAwaitReply(MKMDPort port_set, MKMDReplyFunctions *funcs, int timeout)
{
#if FUNCLOG
    NSLog(@"MKMDAwaitReply called %d timeout\n", timeout);
#endif
    return MKMD_SUCCESS;
}

PERFORM_API kern_return_t MKMDHandleReply(msg_header_t *msg, MKMDReplyFunctions *funcs)
{
#if FUNCLOG
    NSLog(@"MKMDHandleReply called\n");
#endif
    return MKMD_SUCCESS;
}

/* Routine MKMDSetReplyCallback - this is called to nominate a function to be called on reception of events
instead of sending a message to a Mach port */
PERFORM_API MKMDReturn MKMDSetReplyCallback (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	void (*newCallbackFn)(void *),
	void *newCallbackParam)
{
#if FUNCLOG
    NSLog(@"MKMDSetReplyCallback called\n");
#endif
    callbackFn = newCallbackFn;
    callbackParam = newCallbackParam;
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
PERFORM_API kern_return_t MKMDDownloadDLSInstruments(unsigned int *patchesToDownload, int patchesUsed)
{
    return MKMD_SUCCESS;
}

// retrieve a list of strings giving driver names, and therefore (0 based) unit numbers.
PERFORM_API const char **MKMDGetAvailableDrivers(BOOL input, unsigned int *selectedDriver)
{
    int deviceIndex;
    int availableDriverIndex = 0;
    /* Allocate enough space for each name */
    char **driverList = (char **) malloc(sizeof(char *) * (Pm_CountDevices() + 1));
    // portmidi can provide the users preferred device
    PmDeviceID defaultDeviceID = input ? Pm_GetDefaultInputDeviceID() : Pm_GetDefaultOutputDeviceID();

    // defaulting to the first in the list.
    *selectedDriver = 0; 

    if(driverList != NULL) {
	/* list device information */
	for (deviceIndex = 0; deviceIndex < Pm_CountDevices(); deviceIndex++) {
	    const PmDeviceInfo *info = Pm_GetDeviceInfo(deviceIndex);

	    if (info != NULL && ((input && info->input) || (!input && info->output))) {
		NSLog(@"%d: %s\n", deviceIndex, info->name,
		      info->input ? "(input)" : info->output ? "(output)" : "problem!");

		driverList[availableDriverIndex] = (char *) malloc(strlen(info->name) + 1);
		if(driverList[availableDriverIndex] != NULL) {
		    strcpy(driverList[availableDriverIndex], info->name);
		    // If this is the default, save it's index of the returned name list.
		    if(defaultDeviceID == deviceIndex)
			*selectedDriver = availableDriverIndex;
		    availableDriverIndex++;    
		}
	    }
	}
	driverList[availableDriverIndex] = NULL;
    }
    return (const char **) driverList;
}

#ifdef __cplusplus
}
#endif
