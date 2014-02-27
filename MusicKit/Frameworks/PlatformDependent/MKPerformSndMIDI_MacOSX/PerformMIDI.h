/*
  $Id$
  Defined In: The MusicKit

  Description:
    MIDI driver typedefs, defines, and functions exported to other MusicKit frameworks.
    See the HeaderDoc header below.

  Original Author of MacOS X version: Leigh M. Smith

  Copyright (c) 2000-2004 The MusicKit Project.
*/
/*!
  @header PerformMIDI
  
  This file provides compatability between the various platform dependent 
  MIDI drivers used by the MusicKit.
  We only use the mididriver versions for NeXT hardware, all other
  architectures use MusicKit MIDI drivers using the DriverKit for OpenStep,
  DirectMusic for Windows, CoreMIDI/QTMA for MacOS X etc.
  The other sobering thought about this framework is that it does not rely on
  any OpenStep/Cocoa API types, unless they are declared here. 
  Therefore C Strings and ints are de rigeur...

  There are two different schemes of management of interface to the MKMD functions.
  To achieve maximum portablity, we assume a Mach port is nothing more than an integer
  and functions as a handle with which to refer to a MIDI driver. It is only when receiving
  data do we need to actually behave as a Mach port. This is conditionally compiled using
  MKMD_RECEPTION_USING_PORTS defined in MKPerformSndMIDI/midi_driver.h. The alternative
  is to use a call back function. Therefore, while we do need a NSPort or NSMachPort,
  their support can be minimal and we are not enforced to run on a Mach type operating system.
*/
#ifndef _MKMD_
#define _MKMD_

#import <Foundation/Foundation.h>
#import <mach/kern_return.h>

/*!
  @defined PERFORM_API
  @brief This allows us to introduce anything necessary for library declarations, namely for Windows.

  Unused in MacOS X.
*/
#define PERFORM_API

// kludge around type definitions. This should be replaced.
typedef int msg_header_t;  // mach_msg_header_t

/*!
  @defined MKMDPort
  @brief An NSPort returning a Mach port (that can simply function as an unique identifier
  on non-Mach systems) that is a handle for communicating to this driver.

  This only needs to be a legitimate Mach port if MKMD_RECEPTION_USING_PORTS is non-zero.
*/
#define MKMDPort int

/*!
  @defined MKMDOwnerPort
  @brief An NSPort returning a Mach port (that can simply function as an unique identifier
  on non-Mach systems) that is a handle for communicating back to the owner.

  This only needs to be a legitimate Mach port if MKMD_RECEPTION_USING_PORTS is non-zero.
*/
#define MKMDOwnerPort int

/*!
  @defined MKMDReplyPort
  @brief An NSPort returning a Mach port (that can simply function as an unique identifier
  on non-Mach systems) that is a handle for communicating received MIDI data back to the
  owner.

  This only needs to be a legitimate Mach port if MKMD_RECEPTION_USING_PORTS
  is non-zero.
*/
#define MKMDReplyPort int

/*!
  @typedef MKMDReturn
  @brief Value returned by MusicKit MIDI driver functions to indicate success or failure.
*/
typedef int MKMDReturn;

/*!
  @defined MKMD_RECEPTION_USING_PORTS
  @brief There are two different schemes of management of interface to the MKMD functions.

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
  @brief Indicates no communication port is to be used.
*/
#define MKMD_PORT_NULL 0

/*!
  @brief Each raw event consists of a single MIDI message byte and a time stamp.
*/
typedef struct {
    /*! @brief Absolute time in quanta. */
    int time;
    /*! @brief The MIDI message byte. */
    unsigned char byte;
} MKMDRawEvent;

/*!
  @typedef MKMDRawEventPtr
  @brief Pointer to a MKMDRawEvent
*/
typedef MKMDRawEvent *MKMDRawEventPtr;

/*!
  @defined MKMD_MAX_EVENT
  @brief The maximum number of events that can be sent to or received from the driver in a single package.
*/
#define MKMD_MAX_EVENT 100
   
/*!
  @defined MKMD_MAX_MSG_SIZE
  @brief The maximum size of the message you can receive from the driver.
*/
#define MKMD_MAX_MSG_SIZE 1024  // More than enough

/*!
  @defined MKMD_CLOCK_MODE_INTERNAL
  @brief Sets the clock mode to synchronize to the drivers internal clock.
*/
#define MKMD_CLOCK_MODE_INTERNAL 0

/*!
  @defined MKMD_CLOCK_MODE_MTC_SYNC
  @brief Sets the clock mode to synchronize to incoming MIDI Time Code.
*/
#define MKMD_CLOCK_MODE_MTC_SYNC 1

/* error codes */
/*!
  @defined MKMD_SUCCESS
  @brief Indicates the PerformMIDI function returning a MKMDReturn value was successful.
*/
#define MKMD_SUCCESS KERN_SUCCESS  // use this until all the MKMidi checks have been converted to MKMD_SUCCESS.
//#define MKMD_SUCCESS 0
#define MKMD_ERROR_BUSY              100
#define MKMD_ERROR_NOT_OWNER         101
#define MKMD_ERROR_QUEUE_FULL        102
#define MKMD_ERROR_BAD_MODE          103
#define MKMD_ERROR_UNIT_UNAVAILABLE  104
#define MKMD_ERROR_ILLEGAL_OPERATION 105
#define MKMD_ERROR_UNKNOWN_ERROR     106

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

/*!
  @defined MKMD_PORT_A_UNIT
  @brief Legacy MIDI port definition referring to NeXT serial port A
*/
#define MKMD_PORT_A_UNIT 0

/*!
  @defined MKMD_PORT_B_UNIT
  @brief Legacy MIDI port definition referring to NeXT serial port B
*/
#define MKMD_PORT_B_UNIT 1

/* Reply function types. */
/*!
  @typedef MKMDDataReplyFunction
  @brief Reply function communicating received MIDI data.
  @param userData User data supplied via MKMDHandleReply().
  @param unit The MIDI port (cable) the data is to be sent to.
  @param events A count terminated array of MIDI events.
  @param count Number of MIDI events received.
*/
typedef void (*MKMDDataReplyFunction) (void *userData, short unit, MKMDRawEvent *events, unsigned int count);

/*!
  @typedef MKMDAlarmReplyFunction
  @brief Reply function indicating a problem occured reading MIDI data.
  @param replyPort The communications port for the reply.
  @param requestedTime The time the alarm was requested to be sent.
  @param actualTime The time the alarm was actually sent.
*/
typedef void (*MKMDAlarmReplyFunction) (MKMDReplyPort replyPort, int requestedTime, int actualTime);

/*!
  @typedef MKMDExceptionReplyFunction
  @brief Reply function indicating an exception occured reading MIDI data.
  @param replyPort The communications port for the reply.
  @param exception The exception code.
*/
typedef void (*MKMDExceptionReplyFunction) (MKMDReplyPort replyPort, int exception);

/*!
  @typedef MKMDQueueReplyFunction
  @brief Reply function called when queue has the number of MKMDRawEvents available as requested
  by <b>MKMDRequestQueueNotification</b>.
  @param replyPort The communications port that received the reply. 
  @param unit The MIDI port (cable) the reply is from.
*/
typedef void (*MKMDQueueReplyFunction) (MKMDReplyPort replyPort, short unit);

/*!
  @typedef MKMDReplyFunctions
  @brief Struct for passing reply functions to MusicKit MIDI driver library.

  @field dataReply Called when we have received MIDI data.
  @field alarmReply Called to alert the caller of problems.
  @field exceptionReply Called to alert the caller of problems (what distinction?).
  @field queueReply Called to alert the caller the queue is empty.
*/
typedef struct _MKMDReplyFunctions {
    MKMDDataReplyFunction dataReply;           
    MKMDAlarmReplyFunction alarmReply;         
    MKMDExceptionReplyFunction exceptionReply; 
    MKMDQueueReplyFunction queueReply;         
} MKMDReplyFunctions;

/*!
  @function MKMDGetMIDIDeviceOnHost
  @brief Locating the driver on a given host.
  @param hostname Name of the host.
  @return Returns NULL if unable to find the hostname,
  otherwise whatever value for MKMDPort that has meaning.
*/
PERFORM_API MKMDPort
    MKMDGetMIDIDeviceOnHost(const char *hostname);

/*!
  @function MKMDBecomeOwner
  @brief Takes ownership of the driver.
  @param mididriver_port Port indicating and enabling communication with the MIDI driver.
  @param owner_port Port indicating and enabling communication with the owner (calling routine).
  @param replyFunctions Nominates functions called back when MIDI data is received or other exceptions.
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDBecomeOwner(MKMDPort mididriver_port, MKMDOwnerPort owner_port, MKMDReplyFunctions *replyFunctions);

/*!
  @function MKMDReleaseOwnership
  @brief Releases ownership of the driver.
  @param mididriver_port Port indicating and enabling communication with the MIDI driver.
  @param owner_port Port indicating and enabling communication with the owner (calling routine).
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDReleaseOwnership(MKMDPort mididriver_port, MKMDOwnerPort owner_port);

/*!
  @function MKMDClaimUnit
  @brief Claiming a particular MIDI port (cable). 
  Ownership of driver is required.
  @param driver Port indicating and enabling communication with the MIDI driver.
  @param owner Port indicating and enabling communication with the owner (calling routine).
  @param unit Indicates the MIDI port (cable) in a multiple MIDI port driver.
  @param userData A pointer to user data that will be returned when calling the reply functions supplied to MKMDBecomeOwner().
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDClaimUnit(BOOL input, MKMDPort driver, MKMDOwnerPort owner, short unit, void *userData);

/*!
  @function MKMDReleaseUnit
  @brief Releases ownership of a particular MIDI port (cable).
  @param driver Port indicating and enabling communication with the MIDI driver.
  @param owner Port indicating and enabling communication with the owner (calling routine).
  @param unit Indicates the MIDI port (cable) in a multiple MIDI port driver.
  @param userData A pointer to user data that was supplied to MKMDClaimUnit().
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDReleaseUnit(BOOL input, MKMDPort driver, MKMDOwnerPort owner, short unit, void *userData);

/*!
  @function MKMDSetClockMode
  @brief Controlling the clock.
  @param driver Port indicating and enabling communication with the MIDI driver.
  @param owner Port indicating and enabling communication with the owner (calling routine).
  @param synchUnit Indicates the MIDI port (cable) in a multiple MIDI port driver to synchronize to.
  @param mode Synchronization mode (description to be expanded).
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDSetClockMode(MKMDPort driver, MKMDOwnerPort owner, short synchUnit, int mode);

/*!
  @function MKMDSetClockQuantum
  @brief Set the period of each clock tick in microseconds.
  @param driver Port indicating and enabling communication with the MIDI driver.
  @param owner Port indicating and enabling communication with the owner (calling routine).
  @param microseconds Period of each clock tick.
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDSetClockQuantum(MKMDPort driver, MKMDOwnerPort owner, int microseconds);

/*!
  @function MKMDSetClockTime
  @brief Assign the current datum in clock quanta.
  @param driver Port indicating and enabling communication with the MIDI driver.
  @param owner Port indicating and enabling communication with the owner (calling routine).
  @param time The new time.
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDSetClockTime(MKMDPort driver, MKMDOwnerPort owner, int time);

/*!
  @function MKMDGetClockTime
  @brief Retrieve the time (measured in clock quanta).
  @param driver Port indicating and enabling communication with the MIDI driver.
  @param owner Port indicating and enabling communication with the owner (calling routine).
  @param time Receives the current clock time.
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDGetClockTime(MKMDPort driver, MKMDOwnerPort owner, int *time);

/*!
  @function MKMDGetMTCTime
  @brief Retrieve the MIDI Time Code value from the SMPTE reading device.
  
  This only works if the receiver is in MTC synch mode. 
  @param driver Port indicating and enabling communication with the MIDI driver.
  @param owner Port indicating and enabling communication with the owner (calling routine).
  @param format Receives the SMPTE format, as MK_MTC_FORMAT_DROP_30 etc.
  These format codes need to be redefined as an enum and moved into this header.
  @param hours Receives the number of hours.
  @param minutes Receives the number of minutes.
  @param seconds Receives the number of seconds.
  @param frames Receives the number of frames, where the format determines the frames per second.
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDGetMTCTime(MKMDPort driver, MKMDOwnerPort owner, short *format, short *hours, short *minutes, short *seconds, short *frames);

/*!
  @function MKMDStartClock
  @brief Start the clock ticking.
  @param driver Port indicating and enabling communication with the MIDI driver.
  @param owner Port indicating and enabling communication with the owner (calling routine).
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDStartClock(MKMDPort driver, MKMDOwnerPort owner);

/*!
  @function MKMDStopClock
  @brief Stop the clock ticking.    
  @param driver Port indicating and enabling communication with the MIDI driver.
  @param owner Port indicating and enabling communication with the owner (calling routine).
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDStopClock(MKMDPort driver, MKMDOwnerPort owner);

/*!
  @function MKMDRequestData
  @brief Requesting asynchronous messages.
  @param driver Port indicating and enabling communication with the MIDI driver.
  @param owner Port indicating and enabling communication with the owner (calling routine).
  @param unit Indicates the MIDI port (cable) in a multiple MIDI port driver.
  @param replyPort Port indicating a communications channel to return the MIDI data to.
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDRequestData(MKMDPort driver, MKMDOwnerPort owner, short unit, MKMDReplyPort replyPort);

/*!
  @function MKMDRequestAlarm
  @brief Set an alarm to be triggered on replyPort after time.
  @param driver Port indicating and enabling communication with the MIDI driver.
  @param owner Port indicating and enabling communication with the owner (calling routine).
  @param replyPort Port indicating a communications channel to return the alarm on.
  @param time Clock quanta for alarm notice.
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDRequestAlarm(MKMDPort driver, MKMDOwnerPort owner, MKMDReplyPort replyPort, int time);

/*!
  @function MKMDRequestExceptions
  @brief Define communications port to receive exception notices.
  @param driver Port indicating and enabling communication with the MIDI driver.
  @param owner Port indicating and enabling communication with the owner (calling routine).
  @param exceptionPort Port for receiving exceptions.
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDRequestExceptions(MKMDPort driver, MKMDOwnerPort owner, MKMDReplyPort exceptionPort);

/*!
  @function MKMDRequestQueueNotification
  @brief Send a message on <b>notificationPort</b> when playback
  queue has <b>size</b> MIDI elements available.
  @param driver Port indicating and enabling communication with the MIDI driver.
  @param owner Port indicating and enabling communication with the owner (calling routine).
  @param unit Indicates the MIDI port (cable) in a multiple MIDI port driver.
  @param notificationPort Can be nil to cancel the queue request.
  @param size The desired number of MKMDRawEvents requested to be available.
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDRequestQueueNotification(MKMDPort driver, MKMDOwnerPort owner, short unit, MKMDReplyPort notificationPort, int size);

/****************** Receiving asynchronous messages *******************/

/*!
  @function MKMDAwaitReply
  @brief Waits until a reply is received on reply ports or until timeout.
  @param ports Port (or port sets) to monitor.
  @param funcs Reply functions to trigger on reception of 
  @param timeout Time in quanta to wait for a reply, MKMD_NO_TIMEOUT to wait indefinitely.
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDAwaitReply(MKMDReplyPort ports, MKMDReplyFunctions *funcs, int timeout);

/*!
  @defined MKMD_NO_TIMEOUT
  @brief Indicates that no timeout is to occur, the called function waits indefinitely.
*/
#define MKMD_NO_TIMEOUT (-1)

/*!
  @function MKMDHandleReply
  @brief Manage the received message and  call the appropriate reply function from those supplied.
  @param msg The message reply to be handled.
  @param funcs The functions handling received data, exceptions, alarms, and queue reports.
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDHandleReply(void *userData, MKMDReplyFunctions *funcs);

/*!
  @function MKMDSetReplyCallback
  @brief Called to nominate a function to be called on reception of events instead of sending a message to a Mach port.
  @param mididriver_port Port indicating and enabling communication with the MIDI driver.
  @param owner_port Port indicating and enabling communication with the owner (calling routine).
  @param unit Indicates the MIDI port (cable) in a multiple MIDI port driver.
  @param newCallbackFn The function to call on receipt of a driver callback.
  @param newCallbackParam Any parameter to pass to the callback function.
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn MKMDSetReplyCallback (
 MKMDPort mididriver_port,
    MKMDOwnerPort owner_port,
    short unit,
    void (*newCallbackFn)(void *),
        void *newCallbackParam);

/*!
  @function MKMDSendData
  @brief Writes MIDI data to the driver.
  @param driver Port indicating and enabling communication with the MIDI driver.
  @param owner Port indicating and enabling communication with the owner (calling routine).
  @param unit Indicates the MIDI port (cable) in a multiple MIDI port driver.
  @param data Each event consists of a time stamp per byte. 
  This allows slowing byte output to stop choking synths with sysex messages. 
  @param count Number of data items.
  @return Returns MKMD_SUCCESS if able to send the MIDI data correctly.
*/
PERFORM_API MKMDReturn 
    MKMDSendData(MKMDPort driver, MKMDOwnerPort owner, short unit, MKMDRawEvent *data, unsigned int count);

/*!
  @function MKMDGetAvailableQueueSize
  @brief Returns the size of the queue used for output of MIDI. 
  @param driver Port indicating and enabling communication with the MIDI driver.
  @param owner Port indicating and enabling communication with the owner (calling routine).
  @param unit Indicates the MIDI port (cable) in a multiple MIDI port driver.
  @param size Receives the size of the queue.
  @return Returns MKMD_SUCCESS if able to return the queue size.
*/
PERFORM_API MKMDReturn 
    MKMDGetAvailableQueueSize(MKMDPort driver, MKMDOwnerPort owner, short unit, int *size);

/*!
  @function MKMDClearQueue
  @brief Remove any pending MIDI messages already requested to be played.
  @param driver Port indicating and enabling communication with the MIDI driver.
  @param owner Port indicating and enabling communication with the owner (calling routine).
  @param unit Indicates the MIDI port (cable) in a multiple MIDI port driver.
  @return Returns MKMD_SUCCESS if able to clear the queue, an error otherwise.
*/
PERFORM_API MKMDReturn 
    MKMDClearQueue(MKMDPort driver, MKMDOwnerPort owner, short unit);

/*!
  @function MKMDFlushQueue
  @brief 
  @param driver Port indicating and enabling communication with the MIDI driver.
  @param owner Port indicating and enabling communication with the owner (calling routine).
  @param unit Indicates the MIDI port (cable) in a multiple MIDI port driver.
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDFlushQueue(MKMDPort device_port, MKMDOwnerPort owner_port, short unit);

/*!
  @function MKMDDownloadDLSInstruments
  @brief Download the patch numbers (MSB,LSB,patch) to the sound card.    
  @param patches
  An array of patches to download.
  @param patchCount Number of patches.
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code. 
*/
PERFORM_API MKMDReturn 
    MKMDDownloadDLSInstruments(unsigned int *patches, int patchCount);

/*!
  @function MKMDGetAvailableDrivers
  @brief Return the names of available drivers.
  @param input Indicates whether the drivers listed are for input or output. 
  These may differ for devices which provide only output or only input.
  @param selectedDriver Receives the default driver index.
  @return Returns a list of strings giving driver names and available ports,
  and therefore (0 based) unit numbers. A NULL char * terminates the
  list similar to argv behaviour.
*/
PERFORM_API const char **
    MKMDGetAvailableDrivers(BOOL inputDrivers, unsigned int *selectedDriver);

/*!
  @function MKMDFilterMessage
  @brief Controling how incoming data is formated.
  @param driver Port indicating and enabling communication with the MIDI driver.
  @param owner Port indicating and enabling communication with the owner (calling routine).
  @param unit Indicates the MIDI port (cable) in a multiple MIDI port driver.
  @param statusByte The MIDI status byte to filter.
  @param filterIt Enables or disables the filtering out of the status byte.
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDFilterMessage(MKMDPort driver, MKMDOwnerPort owner, short unit, unsigned char statusByte, boolean_t filterIt);

/*!
  @function MKMDParseInput
  @brief Parse Input
  @param driver Port indicating and enabling communication with the MIDI driver.
  @param owner Port indicating and enabling communication with the owner (calling routine).
  @param unit Indicates the MIDI port (cable) in a multiple MIDI port driver.
  @param parseIt Enables or disables parsing.
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code. 
*/
PERFORM_API MKMDReturn 
    MKMDParseInput(MKMDPort driver, MKMDOwnerPort owner, short unit, boolean_t parseIt);

/*!
  @function MKMDErrorString
  @brief Interpret the errorCode and return the appropriate error string.
  @param errorCode The error code returned by a MKMD function.
  @return Returns a readable string.
*/
PERFORM_API char *MKMDErrorString(MKMDReturn errorCode);

/*!
  @function MKMDSetSystemIgnores
  @brief This will be obsolete soon.
  @param driver Port indicating and enabling communication with the MIDI driver.
  @param owner Port indicating and enabling communication with the owner (calling routine).
  @param unit Indicates the MIDI port (cable) in a multiple MIDI port driver.
  @param ignoreBits A binary value indicating messages to ignore.
  @return Returns MKMD_SUCCESS if on correct completion, otherwise an error code.
*/
PERFORM_API MKMDReturn 
    MKMDSetSystemIgnores(MKMDPort driver, MKMDOwnerPort owner, short unit, unsigned int ignoreBits);

#endif // _MKMD_

