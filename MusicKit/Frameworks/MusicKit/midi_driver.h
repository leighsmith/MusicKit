/*
 *	File:	<MusicKit/midi_driver.h>
 *	Author:	David Jaffe
 *
 *      MIDI driver typedefs, defines, and functions
 *
 * Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under
 * license from NeXT
 *
 * Portions copyright (c) 1994 Stanford University
 *	Copyright (C) 1991, NeXT Computer, Inc.
 *
 */


#ifndef _MD_
#define _MD_

#import <mach/kern_return.h>
#import <mach/message.h>
#import <mach/port.h>
#import <mach/boolean.h>

#define MD_NAME @"Mididriver"  /* Name of driver (append unit number to use) */

/* Each event consists of a byte and a time stamp. */
typedef struct {
    int time;             /* Absolute time in quanta */
    unsigned char byte;   /* The byte */
} MDRawEvent;

/* MD_MAX_EVENT is the maximum number of events that can be
 * sent to or received from the driver in a single package. 
 */
#define MD_MAX_EVENT 100
   
/* MD_MAX_MSG_SIZE is the maximum size of the message you
 * can receive from the driver. 
 */
#define MD_MAX_MSG_SIZE 1024  // More than enough

/* Clock modes */
#define MD_CLOCK_MODE_INTERNAL 0
#define MD_CLOCK_MODE_MTC_SYNC 1

/* error codes */
#define MD_ERROR_BUSY 100
#define MD_ERROR_NOT_OWNER 101
#define MD_ERROR_QUEUE_FULL 102
#define MD_ERROR_BAD_MODE 103
#define MD_ERROR_UNIT_UNAVAILABLE 104
#define MD_ERROR_ILLEGAL_OPERATION 105
#define MD_ERROR_UNKNOWN_ERROR 106

/* exception codes */
#define MD_EXCEPTION_MTC_STOPPED 1
#define MD_EXCEPTION_MTC_STARTED_FORWARD 2
#define MD_EXCEPTION_MTC_STARTED_REVERSE 3

/* Defines for system ignores. */
#define MD_IGNORE_CLOCK	 0x0100
#define MD_IGNORE_START	 0x0400
#define MD_IGNORE_CONTINUE	 0x0800
#define MD_IGNORE_STOP	 0x1000
#define MD_IGNORE_ACTIVE	 0x4000
#define MD_IGNORE_RESET	 0x8000
#define MD_IGNORE_REAL_TIME    0xdd00  /* All of the above */

#define MD_PORT_A_UNIT 0
#define MD_PORT_B_UNIT 1

/* Reply function types. */
typedef void (*MDDataReplyFunction)
    (port_t replyPort, short unit, MDRawEvent *events, unsigned int count);
typedef void (*MDAlarmReplyFunction)
    (port_t replyPort, int requestedTime, int actualTime);
typedef void (*MDExceptionReplyFunction)
    (port_t replyPort, int exception);
typedef void (*MDQueueReplyFunction)
    (port_t replyPort, short unit);

/* Struct for passing reply functions to midi_driver library. */
typedef struct _MDReplyFunctions {
    MDDataReplyFunction dataReply;
    MDAlarmReplyFunction alarmReply;
    MDExceptionReplyFunction exceptionReply;
    MDQueueReplyFunction queueReply;
} MDReplyFunctions;

/******* Managing ownership of the driver ********/
extern kern_return_t 
    MDBecomeOwner(port_t driver, port_t owner);
extern kern_return_t 
    MDReleaseOwnership(port_t driver, port_t owner);

/*** Claiming a particular serial port (ownership of driver required) *****/
extern kern_return_t 
    MDClaimUnit(port_t driver, port_t owner, short unit);
extern kern_return_t 
    MDReleaseUnit(port_t driver, port_t owner, short unit);

/******** Controlling the clock ****************/
extern kern_return_t 
    MDSetClockMode(port_t driver, port_t owner, short synchUnit, int mode);
extern kern_return_t 
    MDSetClockQuantum(port_t driver, port_t owner, int microseconds);
extern kern_return_t 
    MDSetClockTime(port_t driver, port_t owner, int time);
extern kern_return_t 
    MDGetClockTime(port_t driver, port_t owner, int *time);
extern kern_return_t 
    MDGetMTCTime(port_t driver, port_t owner, short *format, short *hours, short *minutes, short *seconds, short *frames);
extern kern_return_t 
    MDStartClock(port_t driver, port_t owner);
extern kern_return_t 
    MDStopClock(port_t driver, port_t owner);

/****************** Requesting asynchronous messages *******************/
extern kern_return_t 
    MDRequestData(port_t driver, port_t owner, short unit, port_t replyPort);
extern kern_return_t 
    MDRequestAlarm(port_t driver, port_t owner, port_t replyPort, int time);
extern kern_return_t 
    MDRequestExceptions(port_t driver, port_t owner, port_t exceptionPort);
extern kern_return_t 
    MDRequestQueueNotification(port_t driver, port_t owner, short unit, port_t notificationPort, int size);

/****************** Receiving asynchronous messages *******************/
extern kern_return_t 
    MDAwaitReply(port_t ports, MDReplyFunctions *funcs, int timeout);

#define MD_NO_TIMEOUT (-1)

extern kern_return_t 
    MDHandleReply(msg_header_t *msg,MDReplyFunctions *funcs);

/****************** Writing MD data to the driver *********************/
extern kern_return_t 
    MDSendData(port_t driver, port_t owner, short unit, MDRawEvent *data, unsigned int count);
extern kern_return_t 
    MDGetAvailableQueueSize(port_t driver, port_t owner, short unit, int *size);
extern kern_return_t 
    MDClearQueue(port_t driver, port_t owner, short unit);
extern kern_return_t 
    MDFlushQueue(port_t device_port, port_name_t owner_port, short unit);

/********************* Controling how incoming data is formated ***********/
extern kern_return_t 
    MDFilterMessage(port_t driver, port_t owner, short unit, unsigned char statusByte, boolean_t filterIt);
extern kern_return_t 
    MDParseInput(port_t driver, port_t owner, short unit, boolean_t parseIt);

/* This will be obsolete soon: */
extern kern_return_t 
    MDSetSystemIgnores(port_t driver, port_t owner, short unit, unsigned int ignoreBits);

/*
 * Originally from <MusicKit/midi_driver_compatability.h
 *	Author:	David Jaffe
 *      CCRMA, Stanford University, 1994.
 *
 *      This file provides compatability between the Music Kit
 *      Intel MIDI driver and the NeXT hardware driver.  If you
 *      want your software to run on both architectures, include
 *      this file before <mididriver/midi_driver.h> or anything else
 *      that includes <mididriver/midi_driver.h>.
 *
 *      31/12/98 Actually, now we only use the mididriver versions
 *      for NeXT hardware, and all other architectures use DriverKit
 *      MusicKit MIDI drivers.
 */

#if !m68k
/* These macros make the musickit functions and macros look like those in libdsp. */
#define MIDIRawEvent                       MDRawEvent
#define MIDI_MAX_EVENT                     MD_MAX_EVENT
#define MIDI_MAX_MSG_SIZE                  MD_MAX_MSG_SIZE
#define MIDI_CLOCK_MODE_INTERNAL           MD_CLOCK_MODE_INTERNAL
#define MIDI_CLOCK_MODE_MTC_SYNC           MD_CLOCK_MODE_MTC_SYNC
#define MIDI_ERROR_BUSY                    MD_ERROR_BUSY
#define MIDI_ERROR_NOT_OWNER               MD_ERROR_NOT_OWNER
#define MIDI_ERROR_QUEUE_FULL              MD_ERROR_QUEUE_FULL
#define MIDI_ERROR_BAD_MODE                MD_ERROR_BAD_MODE
#define MIDI_ERROR_UNIT_UNAVAILABLE        MD_ERROR_UNIT_UNAVAILABLE
#define MIDI_ERROR_ILLEGAL_OPERATION       MD_ERROR_ILLEGAL_OPERATION
#define MIDI_ERROR_UNKNOWN_ERROR           MD_ERROR_UNKNOWN_ERROR
#define MIDI_EXCEPTION_MTC_STOPPED         MD_EXCEPTION_MTC_STOPPED
#define MIDI_EXCEPTION_MTC_STARTED_FORWARD MD_EXCEPTION_MTC_STARTED_FORWARD
#define MIDI_EXCEPTION_MTC_STARTED_REVERSE MD_EXCEPTION_MTC_STARTED_REVERSE
#define MIDI_PORT_A_UNIT                   MD_PORT_A_UNIT
#define MIDI_PORT_B_UNIT                   MD_PORT_B_UNIT
#define MIDI_IGNORE_CLOCK                  MD_IGNORE_CLOCK
#define MIDI_IGNORE_START                  MD_IGNORE_START
#define MIDI_IGNORE_CONTINUE               MD_IGNORE_CONTINUE
#define MIDI_IGNORE_STOP                   MD_IGNORE_STOP
#define MIDI_IGNORE_ACTIVE                 MD_IGNORE_ACTIVE
#define MIDI_IGNORE_RESET                  MD_IGNORE_RESET
#define MIDI_IGNORE_REAL_TIME              MD_IGNORE_REAL_TIME
#define MIDIDataReplyFunction              MDDataReplyFunction
#define MIDIAlarmReplyFunction             MDAlarmReplyFunction
#define MIDIExceptionReplyFunction         MDExceptionReplyFunction
#define MIDIQueueReplyFunction             MDQueueReplyFunction
#define MIDIReplyFunctions                 MDReplyFunctions
#define MIDIBecomeOwner                    MDBecomeOwner
#define MIDIReleaseOwnership               MDReleaseOwnership
#define MIDIClaimUnit                      MDClaimUnit
#define MIDIReleaseUnit                    MDReleaseUnit
#define MIDISetClockMode                   MDSetClockMode
#define MIDISetClockQuantum                MDSetClockQuantum
#define MIDISetClockTime                   MDSetClockTime
#define MIDIGetClockTime                   MDGetClockTime
#define MIDIGetMTCTime                     MDGetMTCTime
#define MIDIStartClock                     MDStartClock
#define MIDIStopClock                      MDStopClock
#define MIDISetSystemIgnores               MDSetSystemIgnores
#define MIDIRequestData                    MDRequestData
#define MIDIRequestAlarm                   MDRequestAlarm
#define MIDIRequestExceptions              MDRequestExceptions
#define MIDIRequestQueueNotification       MDRequestQueueNotification
#define MIDIAwaitReply                     MDAwaitReply
#define MIDI_NO_TIMEOUT                    MD_NO_TIMEOUT
#define MIDIHandleReply                    MDHandleReply
#define MIDISendData                       MDSendData
#define MIDIGetAvailableQueueSize          MDGetAvailableQueueSize
#define MIDIClearQueue                     MDClearQueue
#define MIDIFlushQueue                     MDFlushQueue
#define MIDIFilterMessage                  MDFilterMessage
#define MIDIParseInput                     MDParseInput
#endif // !m68K compatability

#endif _MD_

