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
  Revision 1.3  2001/11/07 14:51:58  sbrandon
  Import new header file which defines PERFORM_API according to what is being
  compiled. Necesary for Win32 dlls.

  Revision 1.2  2001/10/31 17:18:20  sbrandon
  Now define PERFORM_API in MKPerformSndMIDIDefines.h

  Revision 1.1  2001/07/02 22:03:48  sbrandon
  - initial revision. Still a work in progress, but does allow the MusicKit
    and SndKit to compile on GNUstep.

  Revision 1.5  2001/05/12 08:46:59  sbrandon
  - added gsdoc comments to most method declarations
  - changed declarations from extern kern_return_t to PERFORM_API MKMDReturn,
    as in MacOSX version of framework.

  Revision 1.4  2001/04/21 22:02:29  sbrandon
  - removed importing of Mach headers
  - removed extraneous function declaration
  - fixed spelling typo

  Revision 1.3  2001/04/07 21:08:35  leighsmith
  Renamed header file to suit new more descriptive name used in MusicKit framework

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

/* for defines: */
#include "MKPerformSndMIDIDefines.h"
#include "mididriverUser.h"

/*!
    @defined MKMDPort
    @discussion An NSPort returning a Mach port (that can simply function as an unique identifier
                on non-Mach systems) that is a handle for communicating to this driver. This only
                needs to be a legitimate Mach port if MKMD_RECEPTION_USING_PORTS is non-zero.
*/
#define MKMDPort int

/*!
    @defined MKMDOwnerPort
    @discussion An NSPort returning a Mach port (that can simply function as an unique identifier
                on non-Mach systems) that is a handle for communicating back to the owner. This only
                needs to be a legitimate Mach port if MKMD_RECEPTION_USING_PORTS is non-zero.
*/
#define MKMDOwnerPort int

/*!
    @defined MKMDReplyPort
    @discussion An NSPort returning a Mach port (that can simply function as an unique identifier
                on non-Mach systems) that is a handle for communicating received MIDI data back to the
                owner. This only needs to be a legitimate Mach port if MKMD_RECEPTION_USING_PORTS
                is non-zero.
*/
#define MKMDReplyPort int

/*!
    @typedef MKMDReturn
    @discussion Value returned by MusicKit MIDI driver functions to indicate success or failure.
*/
typedef int MKMDReturn;

/*!
    @defined MKMD_RECEPTION_USING_PORTS
    @discussion There are two different schemes of management of interface to the MKMD functions.
    To achieve maximum portablity, we assume a Mach port is nothing more than an integer
    and functions as a handle with which to refer to a MIDI driver. It is only when receiving
    data do we need to actually behave as a Mach port. This is conditionally compiled using
    MKMD_RECEPTION_USING_PORTS defined in MKPerformSndMIDI/midi_driver.h. The alternative
    is to use a call back function. Therefore, while we do need a NSPort or NSMachPort,
    their support can be minimal and we are not enforced to run on a Mach type operating system.
*/
#define MKMD_RECEPTION_USING_PORTS 0

/*!
    @defined MKMD_PORT_NULL
    @discussion Indicates no communication port is to be used.
*/
#define MKMD_PORT_NULL 0

/* Each event consists of a byte and a time stamp. */
/*!
    @typedef MKMDRawEvent
    @abstract Each raw event consists of a MIDI message byte and a time stamp.
    @field time Absolute time in quanta
    @field byte The byte
*/
typedef struct {
    int time;             /* Absolute time in quanta */
    unsigned char byte;   /* The byte */
} MKMDRawEvent;

/*!
    @typedef MKMDRawEventPtr
    @abstract Pointer to a MKMDRawEvent
*/
typedef MKMDRawEvent *MKMDRawEventPtr;

/*!
    @defined MKMD_MAX_EVENT
    @discussion The maximum number of events that can be sent to or received from the driver in a single package. 
*/
#define MKMD_MAX_EVENT 100

/*!
    @defined MKMD_MAX_MSG_SIZE
    @discussion The maximum size of the message you can receive from the driver. 
*/
#define MKMD_MAX_MSG_SIZE 1024  // More than enough

/*!
    @defined MKMD_CLOCK_MODE_INTERNAL
    @discussion Sets the clock mode to synchronize to the drivers internal clock. 
*/
#define MKMD_CLOCK_MODE_INTERNAL 0

/*!
    @defined MKMD_CLOCK_MODE_MTC_SYNC
    @discussion Sets the clock mode to synchronize to incoming MIDI Time Code. 
*/
#define MKMD_CLOCK_MODE_MTC_SYNC 1

/*!
    @defined MKMD_SUCCESS
    @discussion Indicates the PerformMIDI function returning a MKMDReturn value was successful.
*/
#define MKMD_SUCCESS 0

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

/*!
    @defined PERFORM_API
    @discussion This allows us to introduce anything necessary for library declarations, namely for Windows. Unused in MacOS X.
*/
//#define PERFORM_API

/*!
    @function       MKMDErrorString
    @abstract       Interpret the errorCode and return the appropriate error string.
    @param          errorCode
                        The error code returned by a MKMD function.
    @result         Returns a readable string.
*/
PERFORM_API char *MKMDErrorString(MKMDReturn errorCode);

/*!
    @function       MKMDGetMIDIDeviceOnHost
    @abstract       Locating the driver on a given host.
    @param          hostname
                        Name of the host.
    @result         Returns NULL if unable to find the hostname,
                    otherwise whatever value for MKMDPort that has meaning.
*/
PERFORM_API MKMDPort
    MKMDGetMIDIDeviceOnHost(const char *hostname);

/******* Managing ownership of the driver ********/
/*!
    @function       MKMDBecomeOwner
    @abstract       Takes ownership of the driver.
    @param          mididriver_port
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner_port
                        Port indicating and enabling communication
			with the owner (calling routine).
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDBecomeOwner(MKMDPort mididriver_port, MKMDOwnerPort owner_port);

/*!
    @function       MKMDReleaseOwnership
    @abstract       Releases ownership of the driver.
    @param          mididriver_port
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner_port
                        Port indicating and enabling communication
			with the owner (calling routine).
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDReleaseOwnership(MKMDPort mididriver_port, MKMDOwnerPort owner_port);


/*** Claiming a particular serial port (ownership of driver required) *****/
/*!
    @function       MKMDClaimUnit
    @abstract       Claiming a particular MIDI port (cable). 
                    Ownership of driver is required.
    @param          driver
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner
                        Port indicating and enabling communication
			with the owner (calling routine).
    @param          unit
                        Indicates the MIDI port (cable) in a multiple
			MIDI port driver.
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDClaimUnit(MKMDPort driver, MKMDOwnerPort owner, short unit);

/*!
    @function       MKMDReleaseUnit
    @abstract       Releases ownership of a particular MIDI port (cable).
    @param          driver
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner
                        Port indicating and enabling communication
			with the owner (calling routine).
    @param          unit
                        Indicates the MIDI port (cable) in a multiple
			MIDI port driver.
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDReleaseUnit(MKMDPort driver, MKMDOwnerPort owner, short unit);

/******** Controlling the clock ****************/

/*!
    @function       MKMDSetClockMode
    @abstract       Controlling the clock.
    @param          driver
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner
                        Port indicating and enabling communication
			with the owner (calling routine).
    @param          synchUnit
                        Indicates the MIDI port (cable) in a multiple
			MIDI port driver to synchronize to.
    @param          mode
                        Synchronization mode (description to be expanded).
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDSetClockMode(MKMDPort driver, MKMDOwnerPort owner, short synchUnit, int mode);

/*!
    @function       MKMDSetClockQuantum
    @abstract       Set the period of each clock tick in microseconds.
    @param          driver
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner
                        Port indicating and enabling communication
			with the owner (calling routine).
    @param          microseconds
                        Period of each clock tick.
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDSetClockQuantum(MKMDPort driver, MKMDOwnerPort owner, int microseconds);

/*!
    @function       MKMDSetClockTime
    @abstract       Assign the current datum in clock quanta.
    @param          driver
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner
                        Port indicating and enabling communication
			with the owner (calling routine).
    @param          time
                        The new time.
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDSetClockTime(MKMDPort driver, MKMDOwnerPort owner, int time);

/*!
    @function       MKMDGetClockTime
    @abstract       Retrieve the time (measured in clock quanta).
    @param          driver
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner
                        Port indicating and enabling communication
			with the owner (calling routine).
    @param          time
                        Receives the current clock time.
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDGetClockTime(MKMDPort driver, MKMDOwnerPort owner, int *time);

/*!
    @function       MKMDGetMTCTime
    @abstract       Retrieve the MIDI Time Code value from the SMPTE reading device.
    @discussion     This only works if the receiver is in MTC synch mode. 
    @param          driver
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner
                        Port indicating and enabling communication
			with the owner (calling routine).
    @param          format
                        Receives the SMPTE format, as MK_MTC_FORMAT_DROP_30 etc.
                        These format codes need to be redefined as an enum and moved into this header.
    @param          hours
                        Receives the number of hours.
    @param          minutes
                        Receives the number of minutes.
    @param          seconds
                        Receives the number of seconds.
    @param          frames
                        Receives the number of frames, where the format determines the frames per second.
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDGetMTCTime(MKMDPort driver, MKMDOwnerPort owner, short *format, short *hours, short *minutes, short *seconds, short *frames);

/*!
    @function       MKMDStartClock
    @abstract       Start the clock ticking.
    @param          driver
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner
                        Port indicating and enabling communication
			with the owner (calling routine).
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDStartClock(MKMDPort driver, MKMDOwnerPort owner);

/*!
    @function       MKMDStopClock
    @abstract       Stop the clock ticking.    
    @param          driver
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner
                        Port indicating and enabling communication
			with the owner (calling routine).
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDStopClock(MKMDPort driver, MKMDOwnerPort owner);


/****************** Requesting asynchronous messages *******************/

/*!
    @function       MKMDRequestData
    @abstract       Requesting asynchronous messages.
    @param          driver
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner
                        Port indicating and enabling communication
			with the owner (calling routine).
    @param          unit
                        Indicates the MIDI port (cable) in a multiple
			MIDI port driver.
    @param          replyPort
                        Port indicating a communications channel to return the MIDI data to.
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDRequestData(MKMDPort driver, MKMDOwnerPort owner, short unit, MKMDReplyPort replyPort);

/*!
    @function       MKMDRequestAlarm
    @abstract       Set an alarm to be triggered on replyPort after time.
    @param          driver
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner
                        Port indicating and enabling communication
			with the owner (calling routine).
    @param          replyPort
                        Port indicating a communications channel to return the alarm on.
    @param          time
                        Clock quanta for alarm notice.
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDRequestAlarm(MKMDPort driver, MKMDOwnerPort owner, MKMDReplyPort replyPort, int time);

/*!
    @function       MKMDRequestExceptions
    @abstract       Define communications port to receive exception notices.
    @param          driver
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner
                        Port indicating and enabling communication
			with the owner (calling routine).
    @param          exceptionPort
                        Port for receiving exceptions.
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDRequestExceptions(MKMDPort driver, MKMDOwnerPort owner, MKMDReplyPort exceptionPort);

/*!
    @function       MKMDRequestQueueNotification
    @abstract       Send a message on <b>notificationPort</b> when playback
                    queue has <b>size</b> MIDI elements available.
    @param          driver
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner
                        Port indicating and enabling communication
			with the owner (calling routine).
    @param          unit
                        Indicates the MIDI port (cable) in a multiple
			MIDI port driver.
    @param          notificationPort
                        Can be nil to cancel the queue request.
    @param          size
                        The desired number of MKMDRawEvents requested to be available.
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDRequestQueueNotification(MKMDPort driver, MKMDOwnerPort owner, short unit, MKMDReplyPort notificationPort, int size);


/****************** Receiving asynchronous messages *******************/

/*!
    @function       MKMDAwaitReply
    @abstract       Waits until a reply is received on reply ports or until timeout.
    @param          ports
                        Port (or port sets) to monitor.
    @param          funcs
                        Reply functions to trigger on reception of 
    @param          timeout
                        Time in quanta to wait for a reply, MKMD_NO_TIMEOUT to wait indefinitely.
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDAwaitReply(MKMDReplyPort ports, MKMDReplyFunctions *funcs, int timeout);

/*!
    @defined MKMD_NO_TIMEOUT
    @discussion Indicates that no timeout is to occur, the called function waits indefinitely.
*/
#define MKMD_NO_TIMEOUT (-1)
/*!
    @function       MKMDHandleReply

    @abstract       Handle Reply
    
    @param          msg
                        

    @param          funcs


    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code.

*/
PERFORM_API MKMDReturn 
    MKMDHandleReply(msg_header_t *msg, MKMDReplyFunctions *funcs);

/*!
    @function       MKMDSetReplyCallback
    @abstract       Called to nominate a function to be called on reception
                    of events instead of sending a message to a Mach port.
    @param          mididriver_port
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner_port
                        Port indicating and enabling communication
			with the owner (calling routine).
    @param          unit
                        Indicates the MIDI port (cable) in a multiple
			MIDI port driver.
    @param          newCallbackFn
                        The function to call on receipt of a driver callback.
    @param          newCallbackParam
                        Any parameter to pass to the callback function.
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn MKMDSetReplyCallback (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	void (*newCallbackFn)(void *),
        void *newCallbackParam);


/****************** Writing MKMD data to the driver *********************/

/*!
    @function       MKMDSendData
    @abstract       Writes MIDI data to the driver.
    @param          driver
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner
                        Port indicating and enabling communication
			with the owner (calling routine).
    @param          unit
                        Indicates the MIDI port (cable) in a multiple
			MIDI port driver.
    @param          data
                        Each event consists of a time stamp per byte. This
	                allows slowing byte output to stop choking synths
                        with sysex messages. 
    @param          count
                        Number of data items.
    @result         Returns MKMD_SUCCESS if able to send the MIDI data correctly.
*/
PERFORM_API MKMDReturn 
    MKMDSendData(MKMDPort driver, MKMDOwnerPort owner, short unit, MKMDRawEvent *data, unsigned int count);

/*!
    @function       MKMDGetAvailableQueueSize
    @abstract       Returns the size of the queue used for output of MIDI. 
    @param          driver
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner
                        Port indicating and enabling communication
			with the owner (calling routine).
    @param          unit
                        Indicates the MIDI port (cable) in a multiple
			MIDI port driver.
    @param          size
                        Receives the size of the queue.
    @result         Returns MKMD_SUCCESS if able to return the queue size.
*/
PERFORM_API MKMDReturn 
    MKMDGetAvailableQueueSize(MKMDPort driver, MKMDOwnerPort owner, short unit, int *size);

/*!
    @function       MKMDClearQueue
    @abstract       Remove any pending MIDI messages already requested to be played.
    @param          driver
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner
                        Port indicating and enabling communication
			with the owner (calling routine).
    @param          unit
                        Indicates the MIDI port (cable) in a multiple
			MIDI port driver.
    @result         Returns MKMD_SUCCESS if able to clear the queue, an error otherwise.
*/
PERFORM_API MKMDReturn 
    MKMDClearQueue(MKMDPort driver, MKMDOwnerPort owner, short unit);

/*!
    @function       MKMDFlushQueue
    @abstract       
    @param          driver
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner
                        Port indicating and enabling communication
			with the owner (calling routine).
    @param          unit
                        Indicates the MIDI port (cable) in a multiple
			MIDI port driver.
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDFlushQueue(MKMDPort device_port, MKMDOwnerPort owner_port, short unit);

/*!
    @function       MKMDDownloadDLSInstruments
    @abstract       Download the patch numbers (MSB,LSB,patch) to the sound card.    
    @param          patches
                        An array of patches to download.
    @param	    patchCount
                        Number of patches.
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code. 
*/
PERFORM_API MKMDReturn 
    MKMDDownloadDLSInstruments(unsigned int *patches, int patchCount);

/*!
    @function       MKMDGetAvailableDrivers
    @abstract       Return the names of available drivers.    
    @param          selectedDriver
                        Receives the default driver index.
    @result         Returns a list of strings giving driver names and available ports,
                    and therefore (0 based) unit numbers. A NULL char * terminates the
                    list a la argv behaviour.
*/
PERFORM_API const char **
    MKMDGetAvailableDrivers(unsigned int *selectedDriver);

/********************* Controling how incoming data is formatted ***********/
/*!
    @function       MKMDFilterMessage
    @abstract       Controling how incoming data is formated.
    @param          driver
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner
                        Port indicating and enabling communication
			with the owner (calling routine).
    @param          unit
                        Indicates the MIDI port (cable) in a multiple
			MIDI port driver.
    @param          statusByte
                        The MIDI status byte to filter.
    @param          filterIt
                        Enables or disables the filtering out of the
			status byte.
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDFilterMessage(MKMDPort driver, MKMDOwnerPort owner, short unit, unsigned char statusByte, boolean_t filterIt);

/*!
    @function       MKMDParseInput
    @abstract       Parse Input
    @param          driver
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner
                        Port indicating and enabling communication
			with the owner (calling routine).
    @param          unit
                        Indicates the MIDI port (cable) in a multiple
			MIDI port driver.
    @param          parseIt
                        Enables or disables parsing.
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code. 
*/
PERFORM_API MKMDReturn 
    MKMDParseInput(MKMDPort driver, MKMDOwnerPort owner, short unit, boolean_t parseIt);

/* This will be obsolete soon: */
/*!
    @function       MKMDSetSystemIgnores
    @abstract       This will be obsolete soon.    
    @param          driver
                        Port indicating and enabling communication
			with the MIDI driver.
    @param          owner
                        Port indicating and enabling communication
			with the owner (calling routine).
    @param          unit
                        Indicates the MIDI port (cable) in a multiple
			MIDI port driver.
    @param          ignoreBits
                        A binary value indicating messages to ignore.
    @result         Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDSetSystemIgnores(MKMDPort driver, MKMDOwnerPort owner, short unit, unsigned int ignoreBits);


#endif /* _MD_ */

