/*
  $Id$
  Defined In: The MusicKit

  Description: MIDI driver typedefs, defines, etc.

  Author: David Jaffe
*/
/*
Modification history:

  $Log$
  Revision 1.3  2000/11/29 23:21:27  leigh
  Renamed MD functions to MKMD

  Revision 1.2  2000/01/27 18:15:43  leigh
  upgraded to new typedef names for Mach

  Revision 1.1.1.1  1999/09/12 00:20:18  leigh
  separated out from MusicKit framework

  Revision 1.2  1999/07/29 01:26:08  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef _MKMDDRIVER_TYPES_
#define _MKMDDRIVER_TYPES_

/*** IMPORTANT:  Any changes to this file must be migrated over to
  mididriver.h.  The reason for having two files is to simplify the
  API for users, allowing them to import only one file. ***/


#import <mach/kern_return.h>
#import <mach/message.h>
#import <mach/port.h>

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
typedef void (*MKMDDataReplyFunction)(mach_port_t replyPort, short unit, MKMDRawEvent *events, unsigned int count);
typedef void (*MKMDAlarmReplyFunction)(mach_port_t replyPort, int requestedTime, int actualTime);
typedef void (*MKMDExceptionReplyFunction)(mach_port_t replyPort, int exception);
typedef void (*MKMDQueueReplyFunction)(mach_port_t replyPort, short unit);

/* Struct for passing reply functions to mididriver library. */
typedef struct MKMDReplyFunctions {
    MKMDDataReplyFunction dataReply;
    MKMDAlarmReplyFunction alarmReply;
    MKMDExceptionReplyFunction exceptionReply;
    MKMDQueueReplyFunction queueReply;
} MKMDReplyFunctions;

#endif _MKMDDRIVER_TYPES_
