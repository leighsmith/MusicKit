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
#import <mach/message.h>
#import <mach/port.h>
#import <mach/boolean.h>

// This allows us to introduce anything necessary for library declarations, namely for Windows. Unused in MacOS X.
#define PERFORM_API

// kludge around type definitions. This should be replaced.
typedef int msg_header_t;  // mach_msg_header_t
#define MKMDPort NSMachPort *
#define MKMDOwnerPort NSMachPort *

#define MKMD_NAME @"Mididriver"  /* Name of driver (append unit number to use) */

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
    MKMDDataReplyFunction dataReply;
    MKMDAlarmReplyFunction alarmReply;
    MKMDExceptionReplyFunction exceptionReply;
    MKMDQueueReplyFunction queueReply;
} MKMDReplyFunctions;

/******* Locating the driver ********/
// returns NULL if unable to find the hostname, otherwise whatever value for MKMDPort
// that has meaning.
PERFORM_API MKMDPort
    MKMDGetMIDIDeviceOnHost(const char *hostname);

/******* Managing ownership of the driver ********/
/* Routine MKMDBecomeOwner */
PERFORM_API kern_return_t 
    MKMDBecomeOwner(MKMDPort mididriver_port, MKMDOwnerPort owner_port);
/* Routine MKMDReleaseOwnership */
PERFORM_API kern_return_t 
    MKMDReleaseOwnership(MKMDPort mididriver_port, MKMDOwnerPort owner_port);

/*** Claiming a particular serial port (ownership of driver required) *****/
PERFORM_API kern_return_t 
    MKMDClaimUnit(MKMDPort driver, MKMDOwnerPort owner, short unit);
PERFORM_API kern_return_t 
    MKMDReleaseUnit(MKMDPort driver, MKMDOwnerPort owner, short unit);

/******** Controlling the clock ****************/
PERFORM_API kern_return_t 
    MKMDSetClockMode(MKMDPort driver, MKMDOwnerPort owner, short synchUnit, int mode);
PERFORM_API kern_return_t 
    MKMDSetClockQuantum(MKMDPort driver, MKMDOwnerPort owner, int microseconds);
PERFORM_API kern_return_t 
    MKMDSetClockTime(MKMDPort driver, MKMDOwnerPort owner, int time);
PERFORM_API kern_return_t 
    MKMDGetClockTime(MKMDPort driver, MKMDOwnerPort owner, int *time);
PERFORM_API kern_return_t 
    MKMDGetMTCTime(MKMDPort driver, MKMDOwnerPort owner, short *format, short *hours, short *minutes, short *seconds, short *frames);
PERFORM_API kern_return_t 
    MKMDStartClock(MKMDPort driver, MKMDOwnerPort owner);
PERFORM_API kern_return_t 
    MKMDStopClock(MKMDPort driver, MKMDOwnerPort owner);

/****************** Requesting asynchronous messages *******************/
PERFORM_API kern_return_t 
    MKMDRequestData(MKMDPort driver, MKMDOwnerPort owner, short unit, port_t replyPort);
PERFORM_API kern_return_t 
    MKMDRequestAlarm(MKMDPort driver, MKMDOwnerPort owner, port_t replyPort, int time);
PERFORM_API kern_return_t 
    MKMDRequestExceptions(MKMDPort driver, MKMDOwnerPort owner, port_t exceptionPort);
PERFORM_API kern_return_t 
    MKMDRequestQueueNotification(MKMDPort driver, MKMDOwnerPort owner, short unit, port_t notificationPort, int size);

/****************** Receiving asynchronous messages *******************/
PERFORM_API kern_return_t 
    MKMDAwaitReply(port_t ports, MKMDReplyFunctions *funcs, int timeout);

#define MKMD_NO_TIMEOUT (-1)

PERFORM_API kern_return_t 
    MKMDHandleReply(msg_header_t *msg,MKMDReplyFunctions *funcs);

/****************** Writing MKMD data to the driver *********************/
PERFORM_API kern_return_t 
    MKMDSendData(MKMDPort driver, MKMDOwnerPort owner, short unit, MKMDRawEvent *data, unsigned int count);
PERFORM_API kern_return_t 
    MKMDGetAvailableQueueSize(MKMDPort driver, MKMDOwnerPort owner, short unit, int *size);
PERFORM_API kern_return_t 
    MKMDClearQueue(MKMDPort driver, MKMDOwnerPort owner, short unit);
PERFORM_API kern_return_t 
    MKMDFlushQueue(MKMDPort device_port, MKMDOwnerPort owner_port, short unit);
/* download the patch numbers (MSB,LSB,patch) to the sound card */
PERFORM_API kern_return_t 
    MKMDDownloadDLSInstruments(unsigned int *patches, int patchCount);
/* return the names of available drivers */
PERFORM_API const char **
    MKMDGetAvailableDrivers(unsigned int *selectedDriver);

/********************* Controling how incoming data is formated ***********/
PERFORM_API kern_return_t 
    MKMDFilterMessage(MKMDPort driver, MKMDOwnerPort owner, short unit, unsigned char statusByte, boolean_t filterIt);
PERFORM_API kern_return_t 
    MKMDParseInput(MKMDPort driver, MKMDOwnerPort owner, short unit, boolean_t parseIt);

/* This will be obsolete soon: */
PERFORM_API kern_return_t 
    MKMDSetSystemIgnores(MKMDPort driver, MKMDOwnerPort owner, short unit, unsigned int ignoreBits);

#if !m68k
/* These macros make the musickit functions and macros look like those in libdsp. */
#define MIDIRawEvent                       MKMDRawEvent
#define MIDI_MAX_EVENT                     MKMD_MAX_EVENT
#define MIDI_MAX_MSG_SIZE                  MKMD_MAX_MSG_SIZE
#define MIDI_CLOCK_MODE_INTERNAL           MKMD_CLOCK_MODE_INTERNAL
#define MIDI_CLOCK_MODE_MTC_SYNC           MKMD_CLOCK_MODE_MTC_SYNC
#define MIDI_ERROR_BUSY                    MKMD_ERROR_BUSY
#define MIDI_ERROR_NOT_OWNER               MKMD_ERROR_NOT_OWNER
#define MIDI_ERROR_QUEUE_FULL              MKMD_ERROR_QUEUE_FULL
#define MIDI_ERROR_BAD_MODE                MKMD_ERROR_BAD_MODE
#define MIDI_ERROR_UNIT_UNAVAILABLE        MKMD_ERROR_UNIT_UNAVAILABLE
#define MIDI_ERROR_ILLEGAL_OPERATION       MKMD_ERROR_ILLEGAL_OPERATION
#define MIDI_ERROR_UNKNOWN_ERROR           MKMD_ERROR_UNKNOWN_ERROR
#define MIDI_EXCEPTION_MTC_STOPPED         MKMD_EXCEPTION_MTC_STOPPED
#define MIDI_EXCEPTION_MTC_STARTED_FORWARD MKMD_EXCEPTION_MTC_STARTED_FORWARD
#define MIDI_EXCEPTION_MTC_STARTED_REVERSE MKMD_EXCEPTION_MTC_STARTED_REVERSE
#define MIDI_PORT_A_UNIT                   MKMD_PORT_A_UNIT
#define MIDI_PORT_B_UNIT                   MKMD_PORT_B_UNIT
#define MIDI_IGNORE_CLOCK                  MKMD_IGNORE_CLOCK
#define MIDI_IGNORE_START                  MKMD_IGNORE_START
#define MIDI_IGNORE_CONTINUE               MKMD_IGNORE_CONTINUE
#define MIDI_IGNORE_STOP                   MKMD_IGNORE_STOP
#define MIDI_IGNORE_ACTIVE                 MKMD_IGNORE_ACTIVE
#define MIDI_IGNORE_RESET                  MKMD_IGNORE_RESET
#define MIDI_IGNORE_REAL_TIME              MKMD_IGNORE_REAL_TIME
#define MIDIDataReplyFunction              MKMDDataReplyFunction
#define MIDIAlarmReplyFunction             MKMDAlarmReplyFunction
#define MIDIExceptionReplyFunction         MKMDExceptionReplyFunction
#define MIDIQueueReplyFunction             MKMDQueueReplyFunction
#define MIDIReplyFunctions                 MKMDReplyFunctions
#define MIDIBecomeOwner                    MKMDBecomeOwner
#define MIDIReleaseOwnership               MKMDReleaseOwnership
#define MIDIClaimUnit                      MKMDClaimUnit
#define MIDIReleaseUnit                    MKMDReleaseUnit
#define MIDISetClockMode                   MKMDSetClockMode
#define MIDISetClockQuantum                MKMDSetClockQuantum
#define MIDISetClockTime                   MKMDSetClockTime
#define MIDIGetClockTime                   MKMDGetClockTime
#define MIDIGetMTCTime                     MKMDGetMTCTime
#define MIDIStartClock                     MKMDStartClock
#define MIDIStopClock                      MKMDStopClock
#define MIDISetSystemIgnores               MKMDSetSystemIgnores
#define MIDIRequestData                    MKMDRequestData
#define MIDIRequestAlarm                   MKMDRequestAlarm
#define MIDIRequestExceptions              MKMDRequestExceptions
#define MIDIRequestQueueNotification       MKMDRequestQueueNotification
#define MIDIAwaitReply                     MKMDAwaitReply
#define MIDI_NO_TIMEOUT                    MKMD_NO_TIMEOUT
#define MIDIHandleReply                    MKMDHandleReply
#define MIDISendData                       MKMDSendData
#define MIDIGetAvailableQueueSize          MKMDGetAvailableQueueSize
#define MIDIClearQueue                     MKMDClearQueue
#define MIDIFlushQueue                     MKMDFlushQueue
#define MIDIFilterMessage                  MKMDFilterMessage
#define MIDIParseInput                     MKMDParseInput
#endif // !m68K compatability

#endif _MKMD_

