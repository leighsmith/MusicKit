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
  Revision 1.2  2000/12/15 02:02:28  leigh
  Initial Revision

  Revision 1.1.1.1  2000/01/14 00:14:34  leigh
  Initial revision

  Revision 1.1.1.1  1999/11/17 17:57:14  leigh
  Initial working version

  Revision 1.2  1999/07/29 01:26:06  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef _MKMD_
#define _MKMD_

#import <mach/kern_return.h>
#import <mach/message.h>
#import <mach/port.h>
#import <mach/boolean.h>

// kludge around type definitions. This should be replaced.
typedef int msg_header_t;  // mach_msg_header_t

#define MKMDPort int
#define MKMDOwnerPort int
#define MKMDReplyPort int
typedef int MKMDReturn;

#define MKMD_RECEPTION_USING_PORTS 0
#define MKMD_PORT_NULL 0

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

#define MKMD_PORT_A_UNIT 0
#define MKMD_PORT_B_UNIT 1

/* Reply function types. */
typedef void (*MKMDDataReplyFunction)
    (MKMDReplyPort replyPort, short unit, MKMDRawEvent *events, unsigned int count);
typedef void (*MKMDAlarmReplyFunction)
    (MKMDReplyPort replyPort, int requestedTime, int actualTime);
typedef void (*MKMDExceptionReplyFunction)
    (MKMDReplyPort replyPort, int exception);
typedef void (*MKMDQueueReplyFunction)
    (MKMDReplyPort replyPort, short unit);

/* Struct for passing reply functions to midi_driver library. */
typedef struct _MKMDReplyFunctions {
    MKMDDataReplyFunction dataReply;
    MKMDAlarmReplyFunction alarmReply;
    MKMDExceptionReplyFunction exceptionReply;
    MKMDQueueReplyFunction queueReply;
} MKMDReplyFunctions;

/******* Managing ownership of the driver ********/
extern kern_return_t 
    MKMDBecomeOwner(MKMDPort driver, MKMDOwnerPort owner);
extern kern_return_t 
    MKMDReleaseOwnership(MKMDPort driver, MKMDOwnerPort owner);

/*** Claiming a particular serial port (ownership of driver required) *****/
extern kern_return_t 
    MKMDClaimUnit(MKMDPort driver, MKMDOwnerPort owner, short unit);
extern kern_return_t 
    MKMDReleaseUnit(MKMDPort driver, MKMDOwnerPort owner, short unit);

/******** Controlling the clock ****************/
extern kern_return_t 
    MKMDSetClockMode(MKMDPort driver, MKMDOwnerPort owner, short synchUnit, int mode);
extern kern_return_t 
    MKMDSetClockQuantum(MKMDPort driver, MKMDOwnerPort owner, int microseconds);
extern kern_return_t 
    MKMDSetClockTime(MKMDPort driver, MKMDOwnerPort owner, int time);
extern kern_return_t 
    MKMDGetClockTime(MKMDPort driver, MKMDOwnerPort owner, int *time);
extern kern_return_t 
    MKMDGetMTCTime(MKMDPort driver, MKMDOwnerPort owner, short *format, short *hours, short *minutes, short *seconds, short *frames);
extern kern_return_t 
    MKMDStartClock(MKMDPort driver, MKMDOwnerPort owner);
extern kern_return_t 
    MKMDStopClock(MKMDPort driver, MKMDOwnerPort owner);

/****************** Requesting asynchronous messages *******************/
extern kern_return_t 
    MKMDRequestData(MKMDPort driver, MKMDOwnerPort owner, short unit, MKMDReplyPort replyPort);
extern kern_return_t 
    MKMDRequestAlarm(MKMDPort driver, MKMDOwnerPort owner, MKMDReplyPort replyPort, int time);
extern kern_return_t 
    MKMDRequestExceptions(MKMDPort driver, MKMDOwnerPort owner, MKMDReplyPort exceptionPort);
extern kern_return_t 
    MKMDRequestQueueNotification(MKMDPort driver, MKMDOwnerPort owner, short unit, MKMDReplyPort notificationPort, int size);

/****************** Receiving asynchronous messages *******************/
extern kern_return_t 
    MKMDAwaitReply(MKMDPort ports, MKMDReplyFunctions *funcs, int timeout);

#define MKMD_NO_TIMEOUT (-1)

extern kern_return_t 
    MKMDHandleReply(msg_header_t *msg,MKMDReplyFunctions *funcs);

/****************** Writing MKMD data to the driver *********************/
extern kern_return_t 
    MKMDSendData(MKMDPort driver, MKMDOwnerPort owner, short unit, MKMDRawEvent *data, unsigned int count);
extern kern_return_t 
    MKMDGetAvailableQueueSize(MKMDPort driver, MKMDOwnerPort owner, short unit, int *size);
extern kern_return_t 
    MKMDClearQueue(MKMDPort driver, MKMDOwnerPort owner, short unit);
extern kern_return_t 
    MKMDFlushQueue(MKMDPort device_port, MKMDOwnerPort owner_port, short unit);
extern kern_return_t 
    MIDIDownloadDLSInstruments(unsigned int *patches, int patchCount);
extern char **MIDIGetAvailableDrivers(unsigned int *selectedDriver);

/********************* Controling how incoming data is formated ***********/
extern kern_return_t 
    MKMDFilterMessage(MKMDPort driver, MKMDOwnerPort owner, short unit, unsigned char statusByte, boolean_t filterIt);
extern kern_return_t 
    MKMDParseInput(MKMDPort driver, MKMDOwnerPort owner, short unit, boolean_t parseIt);

/* This will be obsolete soon: */
extern kern_return_t 
    MKMDSetSystemIgnores(MKMDPort driver, MKMDOwnerPort owner, short unit, unsigned int ignoreBits);

#endif _MD_

