/*
  $Id$
  Defined In: The MusicKit

  Description:
    MIDI driver typedefs, defines, and functions exported to other MusicKit frameworks.

    This file provides compatability between the various platform dependent 
    MIDI drivers used by the MusicKit.
    We only use the mididriver versions for NeXT hardware, all other
    architectures use MusicKit MIDI drivers using the DriverKit for OpenStep,
    DirectMusic for Windows, CoreMIDI/QTMA for MacOS X etc.
    The other sobering thought about this framework is that it does not rely on
    any OpenStep/Cocoa API types, unless they are declared here. 
    Therefore cStrings and ints are de rigeur...

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 2000 The MusicKit Project.
*/
/*
Modification history:

  $Log$
  Revision 1.6  2000/11/25 23:45:16  leigh
  Added prototype of MKMDSetReplyCallback and RECEPTION_USING_PORTS declaration

  Revision 1.5  2000/11/13 23:36:57  leigh
  Added back legacy NeXT MIDI port macros, more ports are now MKMDReplyPort, mach headers are removed

  Revision 1.4  2000/11/10 23:13:33  leigh
  Changed return and port types to be more transparent, reversed #define so that 68k code will use the MIDI versions, everyone else uses the MKMD versions.

  Revision 1.3  2000/10/29 06:05:54  leigh
  Moved to MKMDPort types for ports. Changed name prefixes to be specific to the MusicKit. Added MKMDGetMIDIDeviceOnHost.

  Revision 1.2  2000/05/05 22:41:44  leigh
  kludge around type definitions

  Revision 1.1  2000/03/11 01:42:20  leigh
  Initial Release

  Revision 1.1.1.1  2000/01/14 00:14:34  leigh
  Initial revision
*/
#ifndef _MKMD_
#define _MKMD_

#import <Foundation/Foundation.h>
#import <mach/kern_return.h>

// This allows us to introduce anything necessary for library declarations, namely for Windows. Unused in MacOS X.
#define PERFORM_API

// kludge around type definitions. This should be replaced.
typedef int msg_header_t;  // mach_msg_header_t

#define PORTS_ARE_NSOBJECTS 1
#define RECEPTION_USING_PORTS 0
#define MKMDPort NSMachPort *
#define MKMDOwnerPort NSMachPort *
#define MKMDReplyPort NSMachPort *
typedef int MKMDReturn;

/* Each event consists of a byte and a time stamp. */
typedef struct {
    int time;             /* Absolute time in quanta */
    unsigned char byte;   /* The byte */
} MKMDRawEvent, *MKMDRawEventPtr;

/* MKMD_MAX_EVENT is the maximum number of events that can be
 * sent to or received from the driver in a single package. 
 */
#define MKMD_MAX_EVENT 100
   
/* MKMD_MAX_MSG_SIZE is the maximum size of the message you
 * can receive from the driver. 
 */
#define MKMD_MAX_MSG_SIZE 1024  // More than enough

/* Clock modes */
#define MKMD_CLOCK_MODE_INTERNAL 0
#define MKMD_CLOCK_MODE_MTC_SYNC 1

/* error codes */
#define MKMD_SUCCESS KERN_SUCCESS  // use this until all the MKMidi checks have been converted to MKMD_SUCCESS.
//#define MKMD_SUCCESS 0
#define MKMD_ERROR_BUSY 100
#define MKMD_ERROR_NOT_OWNER 101
#define MKMD_ERROR_QUEUE_FULL 102
#define MKMD_ERROR_BAD_MODE 103
#define MKMD_ERROR_UNIT_UNAVAILABLE 104
#define MKMD_ERROR_ILLEGAL_OPERATION 105
#define MKMD_ERROR_UNKNOWN_ERROR 106

/* exception codes */
#define MKMD_EXCEPTION_MTC_STOPPED 1
#define MKMD_EXCEPTION_MTC_STARTED_FORWARD 2
#define MKMD_EXCEPTION_MTC_STARTED_REVERSE 3

/* Defines for system ignores. */
#define MKMD_IGNORE_CLOCK	 0x0100
#define MKMD_IGNORE_START	 0x0400
#define MKMD_IGNORE_CONTINUE	 0x0800
#define MKMD_IGNORE_STOP	 0x1000
#define MKMD_IGNORE_ACTIVE	 0x4000
#define MKMD_IGNORE_RESET	 0x8000
#define MKMD_IGNORE_REAL_TIME    0xdd00  /* All of the above */

// legacy MIDI port definitions referring to NeXT serial ports
#define MKMD_PORT_A_UNIT 0
#define MKMD_PORT_B_UNIT 1

/* Reply function types. */
typedef void (*MKMDDataReplyFunction)
    (port_t replyPort, short unit, MKMDRawEvent *events, unsigned int count);
typedef void (*MKMDAlarmReplyFunction)
    (port_t replyPort, int requestedTime, int actualTime);
typedef void (*MKMDExceptionReplyFunction)
    (port_t replyPort, int exception);
typedef void (*MKMDQueueReplyFunction)
    (port_t replyPort, short unit);

/* Struct for passing reply functions to midi_driver library. */
typedef struct _MKMDReplyFunctions {
    MKMDDataReplyFunction dataReply;           // called when we have received MIDI data.
    MKMDAlarmReplyFunction alarmReply;         // called to alert the caller of problems.
    MKMDExceptionReplyFunction exceptionReply; // called to alert the caller of problems (what distinction)
    MKMDQueueReplyFunction queueReply;         // 
} MKMDReplyFunctions;

/******* Locating the driver ********/
// returns NULL if unable to find the hostname, otherwise whatever value for MKMDPort
// that has meaning.
PERFORM_API MKMDPort
    MKMDGetMIDIDeviceOnHost(const char *hostname);

/******* Managing ownership of the driver ********/
/* Routine MKMDBecomeOwner */
PERFORM_API MKMDReturn 
    MKMDBecomeOwner(MKMDPort mididriver_port, MKMDOwnerPort owner_port);
/* Routine MKMDReleaseOwnership */
PERFORM_API MKMDReturn 
    MKMDReleaseOwnership(MKMDPort mididriver_port, MKMDOwnerPort owner_port);

/*** Claiming a particular serial port (ownership of driver required) *****/
PERFORM_API MKMDReturn 
    MKMDClaimUnit(MKMDPort driver, MKMDOwnerPort owner, short unit);
PERFORM_API MKMDReturn 
    MKMDReleaseUnit(MKMDPort driver, MKMDOwnerPort owner, short unit);

/******** Controlling the clock ****************/
PERFORM_API MKMDReturn 
    MKMDSetClockMode(MKMDPort driver, MKMDOwnerPort owner, short synchUnit, int mode);
// set the period of each clock tick in microseconds.
PERFORM_API MKMDReturn 
    MKMDSetClockQuantum(MKMDPort driver, MKMDOwnerPort owner, int microseconds);
PERFORM_API MKMDReturn 
    MKMDSetClockTime(MKMDPort driver, MKMDOwnerPort owner, int time);
PERFORM_API MKMDReturn 
    MKMDGetClockTime(MKMDPort driver, MKMDOwnerPort owner, int *time);
PERFORM_API MKMDReturn 
    MKMDGetMTCTime(MKMDPort driver, MKMDOwnerPort owner, short *format, short *hours, short *minutes, short *seconds, short *frames);
PERFORM_API MKMDReturn 
    MKMDStartClock(MKMDPort driver, MKMDOwnerPort owner);
PERFORM_API MKMDReturn 
    MKMDStopClock(MKMDPort driver, MKMDOwnerPort owner);

/****************** Requesting asynchronous messages *******************/
PERFORM_API MKMDReturn 
    MKMDRequestData(MKMDPort driver, MKMDOwnerPort owner, short unit, MKMDReplyPort replyPort);
PERFORM_API MKMDReturn 
    MKMDRequestAlarm(MKMDPort driver, MKMDOwnerPort owner, port_t replyPort, int time);
PERFORM_API MKMDReturn 
    MKMDRequestExceptions(MKMDPort driver, MKMDOwnerPort owner, port_t exceptionPort);
PERFORM_API MKMDReturn 
    MKMDRequestQueueNotification(MKMDPort driver, MKMDOwnerPort owner, short unit, MKMDReplyPort notificationPort, int size);

/****************** Receiving asynchronous messages *******************/
// This waits until a reply is received on port_set
PERFORM_API MKMDReturn 
    MKMDAwaitReply(MKMDReplyPort ports, MKMDReplyFunctions *funcs, int timeout);

#define MKMD_NO_TIMEOUT (-1)

PERFORM_API MKMDReturn 
    MKMDHandleReply(msg_header_t *msg, MKMDReplyFunctions *funcs);

/* Routine MKMDSetReplyCallback - this is called to nominate a function to be called on reception of events
instead of sending a message to a Mach port */
PERFORM_API MKMDReturn MKMDSetReplyCallback (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	void (*newCallbackFn)(void *),
        void *newCallbackParam);

/****************** Writing MKMD data to the driver *********************/
PERFORM_API MKMDReturn 
    MKMDSendData(MKMDPort driver, MKMDOwnerPort owner, short unit, MKMDRawEvent *data, unsigned int count);
PERFORM_API MKMDReturn 
    MKMDGetAvailableQueueSize(MKMDPort driver, MKMDOwnerPort owner, short unit, int *size);
PERFORM_API MKMDReturn 
    MKMDClearQueue(MKMDPort driver, MKMDOwnerPort owner, short unit);
PERFORM_API MKMDReturn 
    MKMDFlushQueue(MKMDPort device_port, MKMDOwnerPort owner_port, short unit);
/* download the patch numbers (MSB,LSB,patch) to the sound card */
PERFORM_API MKMDReturn 
    MKMDDownloadDLSInstruments(unsigned int *patches, int patchCount);
/* return the names of available drivers */
PERFORM_API const char **
    MKMDGetAvailableDrivers(unsigned int *selectedDriver);

/********************* Controling how incoming data is formated ***********/
PERFORM_API MKMDReturn 
    MKMDFilterMessage(MKMDPort driver, MKMDOwnerPort owner, short unit, unsigned char statusByte, boolean_t filterIt);
PERFORM_API MKMDReturn 
    MKMDParseInput(MKMDPort driver, MKMDOwnerPort owner, short unit, boolean_t parseIt);

/* This will be obsolete soon: */
PERFORM_API MKMDReturn 
    MKMDSetSystemIgnores(MKMDPort driver, MKMDOwnerPort owner, short unit, unsigned int ignoreBits);

#endif _MKMD_

