/*
  $Id$
  Defined In: The MusicKit

  Description: MIDI driver typedefs, defines, and functions
  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.5  2000/11/29 23:21:26  leigh
  Renamed MD functions to MKMD

  Revision 1.4  2000/06/13 22:03:31  leigh
  Removed incorrect avoidance of MKMD_ functions when on m68k

  Revision 1.3  2000/01/27 18:15:43  leigh
  upgraded to new typedef names for Mach

  Revision 1.2  1999/11/24 17:30:38  leigh
  Added a MKMDDownloadDLSInstruments stub

  Revision 1.2  1999/07/29 01:26:06  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef _MKMD_
#define _MKMD_

// Determine the MacOsX derivative being compiled on. This is a passing phase (MOXS 1.2) until the two O.S. merge API
#define macosx_server (defined(__ppc__) && defined(ppc))
#define openstep_i386 (i386 && !WIN32)
// earlier OpenStep incantations had NSPort as a concrete class.
#if macosx_server || WIN32 || m68k || openstep_i386
#define NSMachPort NSPort
#endif

#import <mach/kern_return.h>
#import <mach/message.h>
#import <mach/port.h>
#import <mach/boolean.h>

#define PORTS_ARE_NSOBJECTS 1
#define MKMDPort NSMachPort *
#define MKMDOwnerPort NSMachPort *
#define MKMDReplyPort NSMachPort *
typedef int MKMDReturn;

#define MKMD_NAME @"Mididriver"  /* Name of driver (append unit number to use) */

/* Each event consists of a byte and a time stamp. */
typedef struct {
    int time;             /* Absolute time in quanta */
    unsigned char byte;   /* The byte */
} MKMDRawEvent;

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

#define MKMD_PORT_A_UNIT 0
#define MKMD_PORT_B_UNIT 1

/* Reply function types. */
typedef void (*MKMDDataReplyFunction)
    (mach_port_t replyPort, short unit, MKMDRawEvent *events, unsigned int count);
typedef void (*MKMDAlarmReplyFunction)
    (mach_port_t replyPort, int requestedTime, int actualTime);
typedef void (*MKMDExceptionReplyFunction)
    (mach_port_t replyPort, int exception);
typedef void (*MKMDQueueReplyFunction)
    (mach_port_t replyPort, short unit);

/* Struct for passing reply functions to midi_driver library. */
typedef struct _MKMDReplyFunctions {
    MKMDDataReplyFunction dataReply;
    MKMDAlarmReplyFunction alarmReply;
    MKMDExceptionReplyFunction exceptionReply;
    MKMDQueueReplyFunction queueReply;
} MKMDReplyFunctions;

/******* Managing ownership of the driver ********/
extern kern_return_t 
    MKMDBecomeOwner(mach_port_t driver, mach_port_t owner);
extern kern_return_t 
    MKMDReleaseOwnership(mach_port_t driver, mach_port_t owner);

/*** Claiming a particular serial port (ownership of driver required) *****/
extern kern_return_t 
    MKMDClaimUnit(mach_port_t driver, mach_port_t owner, short unit);
extern kern_return_t 
    MKMDReleaseUnit(mach_port_t driver, mach_port_t owner, short unit);

/******** Controlling the clock ****************/
extern kern_return_t 
    MKMDSetClockMode(mach_port_t driver, mach_port_t owner, short synchUnit, int mode);
extern kern_return_t 
    MKMDSetClockQuantum(mach_port_t driver, mach_port_t owner, int microseconds);
extern kern_return_t 
    MKMDSetClockTime(mach_port_t driver, mach_port_t owner, int time);
extern kern_return_t 
    MKMDGetClockTime(mach_port_t driver, mach_port_t owner, int *time);
extern kern_return_t 
    MKMDGetMTCTime(mach_port_t driver, mach_port_t owner, short *format, short *hours, short *minutes, short *seconds, short *frames);
extern kern_return_t 
    MKMDStartClock(mach_port_t driver, mach_port_t owner);
extern kern_return_t 
    MKMDStopClock(mach_port_t driver, mach_port_t owner);

/****************** Requesting asynchronous messages *******************/
extern kern_return_t 
    MKMDRequestData(mach_port_t driver, mach_port_t owner, short unit, mach_port_t replyPort);
extern kern_return_t 
    MKMDRequestAlarm(mach_port_t driver, mach_port_t owner, mach_port_t replyPort, int time);
extern kern_return_t 
    MKMDRequestExceptions(mach_port_t driver, mach_port_t owner, mach_port_t exceptionPort);
extern kern_return_t 
    MKMDRequestQueueNotification(mach_port_t driver, mach_port_t owner, short unit, mach_port_t notificationPort, int size);

/****************** Receiving asynchronous messages *******************/
extern kern_return_t 
    MKMDAwaitReply(mach_port_t ports, MKMDReplyFunctions *funcs, int timeout);

#define MKMD_NO_TIMEOUT (-1)

extern kern_return_t 
    MKMDHandleReply(msg_header_t *msg,MKMDReplyFunctions *funcs);

/****************** Writing MKMD data to the driver *********************/
extern kern_return_t 
    MKMDSendData(mach_port_t driver, mach_port_t owner, short unit, MKMDRawEvent *data, unsigned int count);
extern kern_return_t 
    MKMDGetAvailableQueueSize(mach_port_t driver, mach_port_t owner, short unit, int *size);
extern kern_return_t 
    MKMDClearQueue(mach_port_t driver, mach_port_t owner, short unit);
extern kern_return_t 
    MKMDFlushQueue(mach_port_t device_port, port_name_t owner_port, short unit);
extern kern_return_t 
    MKMDDownloadDLSInstruments(unsigned int *patches, int patchCount);

/********************* Controling how incoming data is formated ***********/
extern kern_return_t 
    MKMDFilterMessage(mach_port_t driver, mach_port_t owner, short unit, unsigned char statusByte, boolean_t filterIt);
extern kern_return_t 
    MKMDParseInput(mach_port_t driver, mach_port_t owner, short unit, boolean_t parseIt);

/* This will be obsolete soon: */
extern kern_return_t 
    MKMDSetSystemIgnores(mach_port_t driver, mach_port_t owner, short unit, unsigned int ignoreBits);

/*
 * Originally from <MusicKit/midi_driver_compatability.h
 * Author: David Jaffe
 * CCRMA, Stanford University, 1994.
 *
 * These definitions provide compatability between the Music Kit
 * MIDI driver and the NeXT hardware driver.  
 *
 * Actually, now we only use the mididriver versions
 * for NeXT hardware, and all other architectures use DriverKit
 * MusicKit MIDI drivers. However all architectures use the MKMD_ versions
 * so these definitions apply for m68k in addition to non-NeXT systems.
 */

/* These macros make the MusicKit functions and macros look like those in libdsp. */
#if m68k
#define MKMDRawEvent                       MIDIRawEvent
#define MKMD_MAX_EVENT                     MIDI_MAX_EVENT
#define MKMD_MAX_MSG_SIZE                  MIDI_MAX_MSG_SIZE
#define MKMD_CLOCK_MODE_INTERNAL           MIDI_CLOCK_MODE_INTERNAL
#define MKMD_CLOCK_MODE_MTC_SYNC           MIDI_CLOCK_MODE_MTC_SYNC
#define MKMD_ERROR_BUSY                    MIDI_ERROR_BUSY
#define MKMD_ERROR_NOT_OWNER               MIDI_ERROR_NOT_OWNER
#define MKMD_ERROR_QUEUE_FULL              MIDI_ERROR_QUEUE_FULL
#define MKMD_ERROR_BAD_MODE                MIDI_ERROR_BAD_MODE
#define MKMD_ERROR_UNIT_UNAVAILABLE        MIDI_ERROR_UNIT_UNAVAILABLE
#define MKMD_ERROR_ILLEGAL_OPERATION       MIDI_ERROR_ILLEGAL_OPERATION
#define MKMD_ERROR_UNKNOWN_ERROR           MIDI_ERROR_UNKNOWN_ERROR
#define MKMD_EXCEPTION_MTC_STOPPED         MIDI_EXCEPTION_MTC_STOPPED
#define MKMD_EXCEPTION_MTC_STARTED_FORWARD MIDI_EXCEPTION_MTC_STARTED_FORWARD
#define MKMD_EXCEPTION_MTC_STARTED_REVERSE MIDI_EXCEPTION_MTC_STARTED_REVERSE
#define MKMD_IGNORE_CLOCK                  MIDI_IGNORE_CLOCK
#define MKMD_IGNORE_START                  MIDI_IGNORE_START
#define MKMD_IGNORE_CONTINUE               MIDI_IGNORE_CONTINUE
#define MKMD_IGNORE_STOP                   MIDI_IGNORE_STOP
#define MKMD_IGNORE_ACTIVE                 MIDI_IGNORE_ACTIVE
#define MKMD_IGNORE_RESET                  MIDI_IGNORE_RESET
#define MKMD_IGNORE_REAL_TIME              MIDI_IGNORE_REAL_TIME
#define MKMDDataReplyFunction              MIDIDataReplyFunction
#define MKMDAlarmReplyFunction             MIDIAlarmReplyFunction
#define MKMDExceptionReplyFunction         MIDIExceptionReplyFunction
#define MKMDQueueReplyFunction             MIDIQueueReplyFunction
#define MKMDReplyFunctions                 MIDIReplyFunctions
#define MKMDBecomeOwner                    MIDIBecomeOwner
#define MKMDReleaseOwnership               MIDIReleaseOwnership
#define MKMDClaimUnit                      MIDIClaimUnit
#define MKMDReleaseUnit                    MIDIReleaseUnit
#define MKMDSetClockMode                   MIDISetClockMode
#define MKMDSetClockQuantum                MIDISetClockQuantum
#define MKMDSetClockTime                   MIDISetClockTime
#define MKMDGetClockTime                   MIDIGetClockTime
#define MKMDGetMTCTime                     MIDIGetMTCTime
#define MKMDStartClock                     MIDIStartClock
#define MKMDStopClock                      MIDIStopClock
#define MKMDSetSystemIgnores               MIDISetSystemIgnores
#define MKMDRequestData                    MIDIRequestData
#define MKMDRequestAlarm                   MIDIRequestAlarm
#define MKMDRequestExceptions              MIDIRequestExceptions
#define MKMDRequestQueueNotification       MIDIRequestQueueNotification
#define MKMDAwaitReply                     MIDIAwaitReply
#define MKMD_NO_TIMEOUT                    MIDI_NO_TIMEOUT
#define MKMDHandleReply                    MIDIHandleReply
#define MKMDSendData                       MIDISendData
#define MKMDGetAvailableQueueSize          MIDIGetAvailableQueueSize
#define MKMDClearQueue                     MIDIClearQueue
#define MKMDFlushQueue                     MIDIFlushQueue
#define MKMDFilterMessage                  MIDIFilterMessage
#define MKMDParseInput                     MIDIParseInput
#endif // m68K compatability

#endif _MKMD_

