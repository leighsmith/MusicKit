/*
  $Id$
  Defined In: The MusicKit

  Description: MIDI driver typedefs, defines, etc.

  Author: David Jaffe
*/
/*
Modification history:

  $Log$
  Revision 1.1  2001/07/02 22:03:48  sbrandon
  - initial revision. Still a work in progress, but does allow the MusicKit
    and SndKit to compile on GNUstep.

  Revision 1.1.1.1  2000/01/14 00:14:34  leigh
  Initial revision

  Revision 1.1.1.1  1999/11/17 17:57:14  leigh
  Initial working version

  Revision 1.2  1999/07/29 01:26:08  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef _MDDRIVER_TYPES_
#define _MDDRIVER_TYPES_

/*** IMPORTANT:  Any changes to this file must be migrated over to
  mididriver.h.  The reason for having two files is to simplify the
  API for users, allowing them to import only one file. ***/

/*
#import <mach/kern_return.h>
#import <mach/message.h>
#import <mach/port.h>
*/

/* Each event consists of a byte and a time stamp. */
typedef struct {
    int time;             /* Absolute time in quanta */
    unsigned char byte;   /* The byte */
} MDRawEvent, *MDRawEventPtr;

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
typedef void (*MDDataReplyFunction)(port_t replyPort, short unit, MDRawEvent *events, unsigned int count);
typedef void (*MDAlarmReplyFunction)(port_t replyPort, int requestedTime, int actualTime);
typedef void (*MDExceptionReplyFunction)(port_t replyPort, int exception);
typedef void (*MDQueueReplyFunction)(port_t replyPort, short unit);

/* Struct for passing reply functions to mididriver library. */
typedef struct MDReplyFunctions {
    MDDataReplyFunction dataReply;
    MDAlarmReplyFunction alarmReply;
    MDExceptionReplyFunction exceptionReply;
    MDQueueReplyFunction queueReply;
} MDReplyFunctions;

#endif _MDDRIVER_TYPES_
