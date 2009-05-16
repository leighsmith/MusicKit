/*
  $Id$
  Defined In: The MusicKit

  Description:
    Interface routines emulating the MIDI Mach device driver of OpenStep on MacOS X.
    
    Apple's MIDI driver currently sucks because:
    
    1. There is no means to know when a single MIDI message has actually been sent or
       when a list of packets has completed being played.
    2. There is no means to time individual Sysex bytes to avoid swamping a MIDI device.
    3. There is no means to cancel notes that are pending to be played.
    4. There is no means to flush any notes that are waiting to be played immediately.

  Original Author: Leigh M. Smith, <leigh@tomandandy.com>, tomandandy music inc.

  30 July 1999, Copyright (c) 1999 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and this copyright message remains intact
  and accompanies all derived code.
*/
#include "PerformMIDI.h"
#include <CoreMIDI/MIDIServices.h>

#define FUNCLOG 0      // 1 == write a log to disk whenever a function in this API is called.
#define DUMPPACKETS 0  // 1 == print out each packet sent to the driver.

#if FUNCLOG
#include <stdio.h> // for fprintf and debug

FILE *debug; // precedes extern "C".
#endif

#ifdef __cplusplus
extern "C" {
#endif 

// multiplicative factor difference between MusicKit quantum and MIDITimeStamp
static MIDITimeStamp   quantumFactor; 
static MIDITimeStamp   datumRefTime;
static int             datumMilliSecTime;
static NSDate          *datumAsDate;
static float           quantumInSeconds = 0.0;

static MIDIClientRef   client = NULL;   // handle indicating we are a client of the MIDI server.
static MIDIPortRef     outPort = NULL;
static MIDIPortRef     inPort = NULL;
static MIDIEndpointRef *claimedDestinations = NULL;
static MIDIEndpointRef *claimedSources = NULL;
static MKMDReplyFunctions *userFuncs;   // functions to be called on reception from the driver.

static MKMDReplyPort   dataReplyPort;	// mach port-like port to reply received MIDI on.
  //static MKMDReplyPort   queue_port;	// mach port-like port to reply when queue is available.
static const MIDIPacketList *receivedPacketList;
static void (*callbackFn)(void *);
static void *callbackParam;

// Amount of time in seconds estimated for the current collection of MIDI packets to play.
static long playEndTimeEstimate = 0;

// This should become part of the CoreMIDI library.
MIDITimeStamp MIDIGetCurrentTime(void)
{
    AbsoluteTime now = UpTime();
    return UnsignedWideToUInt64(now);
}

// TODO we need to properly convert the result to an int, since the division will reduce the actual result within those bounds.
static int timeStampToMKTime(MIDITimeStamp timeStamp)
{
    return (int) ((timeStamp - datumRefTime) / quantumFactor);
}

// called on reception of MIDI packets.
static void readProc(const MIDIPacketList *pktlist, void *refCon, void *connRefCon)
{
    if(callbackFn != NULL) {
        receivedPacketList = pktlist;
        (*callbackFn)(callbackParam);
    }
}

// Return the available port and driver names and the index of the current selected port.
// A NULL char * terminates the list a la argv behaviour.
// The order in which the driver names and available ports are returned is fixed, and a unit
// number directly references that port.
//
// For MacOS X, this returns a collection of endpoints (each being a 16 channel MIDI source or destination). 
// Endpoints reside within entities, which are configurations of system wide interoperating MIDI streams,
// including virtual streams.
// The Apple Man sez: "The recommended way to display an endpoint's name is to ask for the endpoint name,
// and display only that name if it is unique. If it is non-unique, prepend the device name."
// We prepend the device name always.
PERFORM_API const char **MKMDGetAvailableDrivers(BOOL input, unsigned int *selectedDriver)
{
    const char **driverList = NULL;
    NSMutableArray *driverNameList = [NSMutableArray array];
    unsigned int driverListIndex;
    ItemCount endpointIndex;
    ItemCount endpointCount = input ? MIDIGetNumberOfSources() : MIDIGetNumberOfDestinations();
    
    for(endpointIndex = 0; endpointIndex < endpointCount; endpointIndex++) {
	MIDIEndpointRef endPoint = input ? MIDIGetSource(endpointIndex) : MIDIGetDestination(endpointIndex);
	
	if(endPoint != NULL) {
	    CFStringRef endPointName;
	    /* CFDataRef connectionUniqueID; */
	    OSStatus endpointPropertyError;
	    
	    /*
	    endpointPropertyError = MIDIObjectGetDataProperty(endPoint, kMIDIPropertyConnectionUniqueID, &connectionUniqueID);
	    if(endpointPropertyError == noErr) {
		fprintf(stderr, "endPointIndex %ld has %d uniqueIDs\n", endpointIndex, [(NSData *) connectionUniqueID length]);
		OSStatus MIDIObjectFindByUniqueID(
						  MIDIUniqueID      inUniqueID,
						  MIDIObjectRef *   outObject,
						  MIDIObjectType *  outObjectType
						  );
	    }
	     */
	    endpointPropertyError = MIDIObjectGetStringProperty(endPoint, kMIDIPropertyName, &endPointName);
	    if(endpointPropertyError == noErr) { // We need the entity in order to determine the device name.
		MIDIEntityRef entityOfEndpoint; 
		OSStatus entityError = MIDIEndpointGetEntity(endPoint, &entityOfEndpoint);

		if(entityError == noErr) {
		    CFStringRef deviceName;
		    MIDIDeviceRef deviceOfEntity;
		    OSStatus deviceError = MIDIEntityGetDevice(entityOfEndpoint, &deviceOfEntity);
		    
		    if(deviceError == noErr) {
			MIDIObjectGetStringProperty(deviceOfEntity, kMIDIPropertyName, &deviceName);
			[driverNameList addObject: [NSString stringWithFormat: @"%@ %@", (NSString *) deviceName, (NSString *) endPointName]];
		    }
		}
		else
		    [driverNameList addObject: (NSString *) endPointName];		
	    }
	    else {
		NSLog(@"Error getting endPoint's string property\n");
	    }
	}
    }	
    
    // always create at least one entry for the terminating NULL pointer.
    driverList = (const char **) malloc(([driverNameList count] + 1) * sizeof(char *));
    if(driverList == NULL)
	NSLog(@"Unable to allocate driverList of %d drivers, driverNameList %@\n", [driverNameList count] + 1, driverNameList);
    for(driverListIndex = 0; driverListIndex < [driverNameList count]; driverListIndex++) {
	driverList[driverListIndex] = [[driverNameList objectAtIndex: driverListIndex] UTF8String];
    }
    driverList[driverListIndex] = NULL;
    *selectedDriver = 0;
    return driverList;
}

// Interpret the errorCode and return the appropriate error string
PERFORM_API char *MKMDErrorString(MKMDReturn errorCode)
{
    static char errMsg[80];
    sprintf(errMsg, "MusicKit MacOS X MIDI Driver error encountered, code %d", errorCode);
    return errMsg;
}

// returns NULL if unable to find the hostname, otherwise whatever value for MKMDPort
// that has meaning.
// hostname should eventually be a URL.
PERFORM_API MKMDPort MKMDGetMIDIDeviceOnHost(const char *hostname)
{
    if(*hostname) {
        NSLog(@"MIDI on remote hosts not yet implemented on MacOS X\n");
        return MKMD_PORT_NULL;
    }
    else
        return !MKMD_PORT_NULL; // kludge it so it seems initialised
}

/* Routine MKMDBecomeOwner */
PERFORM_API MKMDReturn MKMDBecomeOwner(MKMDPort mididriver_port, MKMDOwnerPort owner_port)
{
    // create client and ports
    NSString *executable;
    OSStatus result;

#if FUNCLOG
    if(debug == NULL) {
        // create a means to see where we are without having to tiptoe around the debugger.
        if((debug = fopen("/tmp/PerformMIDI_debug.txt", "w")) == NULL)
            return MKMD_ERROR_UNKNOWN_ERROR;
    }
#endif
    executable = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleExecutable"];
    if(executable == nil) {
        executable = @"tool"; // TODO, this should determine the name from argv[0]
    }

#if FUNCLOG
    fprintf(debug, "MKMDBecomeOwner called, appname: %s\n", [executable UTF8String]);
#else
    NSLog(@"in MKMDBecomeOwner before MIDIClientCreate, appname: %@\n", executable);
#endif
    if((result = MIDIClientCreate((CFStringRef) executable, NULL, NULL, &client)) != noErr)
	return MKMD_ERROR_UNKNOWN_ERROR;
    NSLog(@"in MKMDBecomeOwner before MIDIInputPortCreate\n");
    if((result = MIDIInputPortCreate(client, CFSTR("Input port"), readProc, NULL, &inPort)) != noErr)
	return MKMD_ERROR_UNKNOWN_ERROR;
    NSLog(@"in MKMDBecomeOwner before MIDIOutputPortCreate\n");
    if((result = MIDIOutputPortCreate(client, CFSTR("Output port"), &outPort)) != noErr)
       return MKMD_ERROR_UNKNOWN_ERROR;

    return MKMD_SUCCESS;
}

/* Routine MKMDReleaseOwnership */
PERFORM_API MKMDReturn MKMDReleaseOwnership(MKMDPort mididriver_port, MKMDOwnerPort owner_port)
{
#if FUNCLOG
    // TODO check the ports properly
    fprintf(debug, "MKMDReleaseOwnership called\n");
    fclose(debug); // hopefully save what we did.
#endif
    if(MIDIPortDispose(outPort) != noErr)
        return MKMD_ERROR_BUSY;

    if(MIDIPortDispose(inPort) != noErr)
        return MKMD_ERROR_BUSY;
        
    if(MIDIClientDispose(client) != noErr)
        return MKMD_ERROR_BUSY;
    else
        return MKMD_SUCCESS;
}

/* Routine MKMDSetClockMode */
PERFORM_API MKMDReturn MKMDSetClockMode (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	int clock_mode)
{
#if FUNCLOG
  fprintf(debug, "MKMDSetClockMode called %d\n", clock_mode);
#endif
  return MKMD_SUCCESS;
}

/* Routine MKMDGetClockTime */
PERFORM_API MKMDReturn MKMDGetClockTime (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	int *time)
{
    MIDITimeStamp currentRefTime;

    currentRefTime = MIDIGetCurrentTime();
    *time = timeStampToMKTime(currentRefTime);

#if FUNCLOG
    fprintf(debug, "MKMDGetClockTime called currentRefTime = %f time = %d\n", 
        (double) currentRefTime, *time);
#endif
    return MKMD_SUCCESS;
}

/* Routine MKMDGetMTCTime */
PERFORM_API MKMDReturn MKMDGetMTCTime (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short *format,
	short *hours,
	short *minutes,
	short *seconds,
	short *frames)
{
#if FUNCLOG
  fprintf(debug, "MKMDGetMTCTime called\n");
#endif
    return MKMD_SUCCESS;
}

/* Routine MKMDSetClockTime */
PERFORM_API MKMDReturn MKMDSetClockTime (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	int time)
{
    // defines datum to associate the integer time to the nanosecond time
    datumRefTime = MIDIGetCurrentTime();
    datumMilliSecTime = time;
    if(datumAsDate)
        [datumAsDate release];
    datumAsDate = [[NSDate date] retain]; // Note the absolute date we set the time datum, for MKMDAwaitReply
#if FUNCLOG
    fprintf(debug, "MKMDSetClockTime called %d, datumRefTime = %f\n", time, (double) datumRefTime);
#endif
    return MKMD_SUCCESS;
}

/* SimpleRoutine MKMDRequestAlarm */
PERFORM_API MKMDReturn MKMDRequestAlarm (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	MKMDReplyPort reply_port,
	int time)
{
#if FUNCLOG
    fprintf(debug, "MKMDRequestAlarm called %d\n", time);
#endif
    return MKMD_SUCCESS;
}

/* Routine MKMDStartClock */
PERFORM_API MKMDReturn MKMDStartClock (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port)
{
    // TODO check the ports properly
#if FUNCLOG
    fprintf(debug, "MKMDStartClock called\n");
#endif
    return MKMD_SUCCESS;
}

/* Routine MKMDStopClock */
PERFORM_API MKMDReturn MKMDStopClock(MKMDPort mididriver_port, MKMDOwnerPort owner_port)
{
    // TODO check the ports properly
#if FUNCLOG
    fprintf(debug, "MKMDStopClock called\n");
#endif
    return MKMD_SUCCESS;
}

/* Routine MKMDClaimUnit */
PERFORM_API MKMDReturn MKMDClaimUnit(BOOL input,
				     MKMDPort mididriver_port,
				     MKMDOwnerPort owner_port,
				     short unit)
{
    ItemCount destinationCount;
    ItemCount sourceCount;
    
#if FUNCLOG
    fprintf(debug, "MKMDClaimUnit called unit %d\n", unit);
#endif
    if(input) {
	// open connections from all sources
	sourceCount = MIDIGetNumberOfSources();
	// NSLog(@"MKMDClaimUnit %ld sources\n", sourceCount);
	if(sourceCount > 0) {
	    if(claimedSources == NULL) {
		if((claimedSources = malloc(sourceCount * sizeof(MIDIEndpointRef))) == NULL)
		    NSLog(@"Couldn't allocate %ld sources\n", sourceCount);
	    }
	    claimedSources[unit] = MIDIGetSource(unit);
	    if(claimedSources[unit] == NULL)
		return MKMD_ERROR_UNKNOWN_ERROR;
	    if(MIDIPortConnectSource(inPort, claimedSources[unit], NULL) != noErr)
		return MKMD_ERROR_UNKNOWN_ERROR;
	}
	else {
	    NSLog(@"No MIDI sources present\n");
	}
    }
    else {
	// find the first destination
	destinationCount = MIDIGetNumberOfDestinations();
	// NSLog(@"MKMDClaimUnit %ld destinations\n", destinationCount);
	if (destinationCount > 0) {
	    if(claimedDestinations == NULL) {
		if((claimedDestinations = malloc(destinationCount * sizeof(MIDIEndpointRef))) == NULL)
		    NSLog(@"Couldn't allocate %ld destinations\n", destinationCount);
	    }
	    claimedDestinations[unit] = MIDIGetDestination(unit);
	    if (claimedDestinations[unit] == NULL)
		return MKMD_ERROR_UNKNOWN_ERROR;

#if 0
	    {
		CFStringRef pname;
		
		if(MIDIObjectGetStringProperty(claimedDestinations[unit], kMIDIPropertyName, &pname) != noErr)
		    return MKMD_ERROR_UNKNOWN_ERROR;
		NSLog(@"Output to %@\n", pname);
		// CFRelease(pname); shouldn't need this?
	    }
#endif
	}
	else {
	    NSLog(@"No MIDI destinations present\n");
	}	
    }
    return MKMD_SUCCESS;
}

/* Routine MKMDReleaseUnit */
PERFORM_API MKMDReturn MKMDReleaseUnit(BOOL input,
				       MKMDPort mididriver_port,
				       MKMDOwnerPort owner_port,
				       short unit)
{
#if FUNCLOG
    fprintf(debug, "MKMDReleaseUnit %d called\n", unit);
#endif
    if(input) {
	if(MIDIPortDisconnectSource(inPort, claimedSources[unit]) != noErr)
	    return MKMD_ERROR_UNKNOWN_ERROR;	
    }
    else {
    // Not quite sure how to rescind destinations, or if we even need to.
    //    if(claimedDestinations != NULL) {
    //        MIDIDestination(claimedDestinations[unit]);
    //        claimedDestinations[unit] = NULL;
    //    }	
    }
    return MKMD_SUCCESS;
}

/* Routine MKMDRequestExceptions */
PERFORM_API MKMDReturn MKMDRequestExceptions (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	MKMDReplyPort error_port)
{
#if FUNCLOG
  fprintf(debug, "MKMDRequestExceptions called\n");
#endif
  return MKMD_SUCCESS;
}

/* Routine MKMDRequestData */
PERFORM_API MKMDReturn MKMDRequestData (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	MKMDReplyPort reply_port)
{
#if FUNCLOG
    fprintf(debug, "MKMDRequestData called\n");
#endif
    // reply_port is nil when indicating no data is to be returned.
    dataReplyPort = reply_port;
    return MKMD_SUCCESS;
}

#if DUMPPACKETS
static void dumpPackets(MIDIPacketList *pktlist)
{
    unsigned int i, j;
    MIDIPacket *packet;

    printf("number of packets = %ld\n", pktlist->numPackets);
    
    packet = (MIDIPacket *) pktlist->packet;	// remove const (!)
    for(i = 0; i < pktlist->numPackets; i++) {
        printf("timestamp = %f, length = %d\n", (double) packet->timeStamp, packet->length);
        for(j = 0; j < packet->length; j++)
            printf("data[%d] = 0x%X ", j, packet->data[j]);
        printf("\n");
        packet = MIDIPacketNext(packet);
    }
}
#endif

/* Routine MKMDSendData */
// Each event consists of a time stamp per byte. This was done to allow slowing byte output
// to stop choking synths with sysex messages. Nowdays it would seem better just to specify
// an inter-byte delay and specify the start time of the channel byte. Still, this is about
// as general as you can get.
PERFORM_API MKMDReturn MKMDSendData (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	MKMDRawEventPtr data,
	unsigned int dataCnt)
{
    unsigned int msgIndex;
    MIDITimeStamp playTime;
    Byte *buffer;
    // Assume worst case that each byte must be individually timed. We use MKMD_MAX_EVENT to ensure
    // we have enough bytes to cover MIDIPacketList's storage of the maximum number of packets
    // receivable, plus the packet count itself.
    // Unfortunately MIDISend expects that packet list to remain resident while playing, so we
    // can't allocate the memory on the fly (and that would probably incur a processor burden).
    static Byte pbuf[(sizeof(MIDIPacket) * MKMD_MAX_EVENT) + sizeof(UInt32)];
    MIDIPacketList *pktlist = (MIDIPacketList *) pbuf;
    MIDIPacket *packet;
    OSStatus errCode;

#if FUNCLOG
    fprintf(debug, "MKMDSendData called with %d events to unit %d @ time %d\n", dataCnt, unit, data[0].time);
#endif

    // Assume worst case that we need to send the entire event list all at the same time.
    if((buffer = (Byte *) malloc(dataCnt)) == NULL) {
        return MKMD_ERROR_QUEUE_FULL;
    }

    // Create a packet list, each packet will contain those bytes all to be played at the same time.
    if((packet = MIDIPacketListInit(pktlist)) == NULL) {
        free(buffer);
        return MKMD_ERROR_QUEUE_FULL;
    }
    
    // Convert the times, extract the data and pack back into a buffer.
    msgIndex = 0;
    while(msgIndex < dataCnt) {
        unsigned int firstUniqueTimeIndex = msgIndex;
        unsigned int bufferIndex;

	if (data[msgIndex].time == 0)
	    playTime = 0; // zero time is reserved for play notes immediately.
	else
	    playTime = (data[msgIndex].time - datumMilliSecTime) * quantumFactor + datumRefTime;
        // since note-offs are also timed, playEndTimeEstimate will save the end time of the last note.
        if(data[msgIndex].time > playEndTimeEstimate)
            playEndTimeEstimate = data[msgIndex].time;

#if FUNCLOG
        fprintf(debug, "MK time %d, playEndTimeEstimate %ld\n", data[msgIndex].time, playEndTimeEstimate);
        fprintf(debug, "Current time %f, play time %f:\n", (double) MIDIGetCurrentTime(), (double) playTime);
#endif
        // collect all event bytes marked with the same time into a single buffer.
        for(bufferIndex = 0; data[msgIndex].time == data[firstUniqueTimeIndex].time && msgIndex < dataCnt; bufferIndex++) {
            buffer[bufferIndex] = data[msgIndex++].byte;
#if FUNCLOG
            fprintf(debug, "%02X ", buffer[bufferIndex]);
#endif
        }
#if FUNCLOG
        fprintf(debug, "\n");
#endif

        // send all same-time bytes in a separate packet.
        packet = MIDIPacketListAdd(pktlist, sizeof(pbuf), packet, playTime, bufferIndex, buffer);
        if(packet == NULL) {
#if FUNCLOG
            fprintf(debug, "couldn't add packet to packet list\n");
#endif
            free(buffer);
            return MKMD_ERROR_QUEUE_FULL;
        }
    }
#if DUMPPACKETS
    dumpPackets(pktlist);
#endif

    if((errCode = MIDISend(outPort, claimedDestinations[unit], pktlist)) != noErr) {
#if FUNCLOG
        fprintf(debug, "couldn't send packet list errCode = %d\n", (int) errCode);
#endif
        free(buffer);
        return MKMD_ERROR_UNKNOWN_ERROR;
    }

    // once the buffer has been packed, it can be discarded as packing copies the data.
    free(buffer);

#if FUNCLOG
    fprintf(debug, "MKMDSendData returning ok\n");
#endif
    return MKMD_SUCCESS;
}

/* Routine MKMDGetAvailableQueueSize */
// Return the queue size. On MacOS X, the queues are dynamic, or at least, their sizes are 
// unable to be retrieved. Since we can't (as of 10.0.1) obtain an indication of when a
// queued message list has been played, we fudge this so MKMDRequestQueueNotification with
// the returned size becomes the question "when have all the messages been sent?".
PERFORM_API MKMDReturn MKMDGetAvailableQueueSize (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	int *size)
{
#if FUNCLOG
    fprintf(debug, "MKMDGetAvailableQueueSize called %d\n", unit);
#endif
    *size = 1; // we create an arbitary non-zero size to differentiate from a flush queue.
    return MKMD_SUCCESS;
}

/* Routine MKMDRequestQueueNotification */
// Send a message on notification_port when playback queue has size MIDI elements available.
// notification_port can be nil to cancel the queue request.
PERFORM_API MKMDReturn MKMDRequestQueueNotification (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	MKMDReplyPort notification_port,
	int size)
{
#if FUNCLOG
    fprintf(debug, "MKMDRequestQueueNotification called size = %d\n", size);
#endif
    return MKMD_SUCCESS;
}

/* Routine MKMDClearQueue. On MacOS X it's the same as MKMDFlushQueue, flushing the output. */
PERFORM_API MKMDReturn MKMDClearQueue (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit)
{
#if FUNCLOG
    fprintf(debug, "MKMDClearQueue called\n");
#endif
    return MIDIFlushOutput(claimedDestinations[unit]) != noErr ? MKMD_ERROR_UNKNOWN_ERROR : MKMD_SUCCESS;
}

/* Routine MKMDFlushQueue */
PERFORM_API MKMDReturn MKMDFlushQueue (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit)
{
#if FUNCLOG
    fprintf(debug, "MKMDFlushQueue called unit %d\n", unit);
#endif
    return MIDIFlushOutput(claimedDestinations[unit]) != noErr ? MKMD_ERROR_UNKNOWN_ERROR : MKMD_SUCCESS;
}

/* Routine MKMDSetSystemIgnores */
PERFORM_API MKMDReturn MKMDSetSystemIgnores (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	unsigned int sys_ignores)
{
#if FUNCLOG
    fprintf(debug, "MKMDSetSystemIgnores called 0x%x sys_ignores\n", sys_ignores);
#endif
    return MKMD_SUCCESS;
}

/* Routine MKMDSetClockQuantum */
PERFORM_API MKMDReturn MKMDSetClockQuantum (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	int microseconds)
{
    // MIDITimeStamp is measured in AbsoluteTime units which is not counted in clock-time units.
    // Therefore we need to convert to arrive at a divisor/multiplicand for conversion of quantum units.
    UInt64 nanoseconds = ((UInt64) microseconds) * 1000;
    AbsoluteTime absTimeFactor = NanosecondsToAbsolute(UInt64ToUnsignedWide(nanoseconds));
    quantumFactor = UnsignedWideToUInt64(absTimeFactor);
    quantumInSeconds = (float) microseconds / 1000000.0;

#if FUNCLOG
    fprintf(debug, "MKMDSetClockQuantum called %d microseconds, %f MIDITimeStamp units\n",
        microseconds, (double) quantumFactor);
#endif
    return MKMD_SUCCESS;
}

// probably need to look at the msg to determine what to do.
static void replyDispatch(MKMDReplyFunctions *userFuncs)
{
    short incomingUnit;
    if (userFuncs->dataReply) {
        unsigned int packetIndex;
        int dataIndex;    
        MIDIPacket *packet = (MIDIPacket *) receivedPacketList->packet;	// remove const (!)
	
        for (packetIndex = 0; packetIndex < receivedPacketList->numPackets; ++packetIndex) {
            MKMDRawEvent *events = (MKMDRawEvent *) malloc(sizeof(MKMDRawEvent) * packet->length);

            // NSLog(@"received packet of %d: ", packet->length);
            for (dataIndex = 0; dataIndex < packet->length; ++dataIndex) {
                // NSLog(@"%02X ", packet->data[dataIndex]);
                events[dataIndex].byte = packet->data[dataIndex];
                events[dataIndex].time = timeStampToMKTime(packet->timeStamp);
            }
            // NSLog(@"\n");
            // claimedSources[unit] == 0; // determine from refCon and connRefCon
            incomingUnit = 0; // TODO determine the unit the data was received on.
            if(dataReplyPort != MKMD_PORT_NULL)
                (*(userFuncs->dataReply))(dataReplyPort, incomingUnit, events, packet->length);
            else
                fprintf(stderr, "not receiving MIDI since dataReplyPort is null!\n");
            free(events);
            packet = MIDIPacketNext(packet);
        }
    }
#if 0
    if (userFuncs->alarmReply) {
	(*(userFuncs->alarmReply))(reply_port,time,actualTime);
    }
    if (userFuncs->queueReply) {
	(*(userFuncs->queueReply))(reply_port,unit);
    }
    if (userFuncs->exceptionReply) {
	(*(userFuncs->exceptionReply))(reply_port,exception);
    }
#endif
}

// This should wait until a reply is received on port_set or until timeout.
// For MacOS X, this is achieved by waiting for the playEndTimeEstimate, which is the time we
// assume by which all the notes have been played. This is a bodge because cancelling should
// shorten this playEndTimeEstimate to 0 and/or cancel the run loop...#@$%# Apple... :-(
PERFORM_API MKMDReturn MKMDAwaitReply(MKMDReplyPort port_set, MKMDReplyFunctions *funcs, int timeout)
{
    double delayEstimateInSeconds;
    
#if FUNCLOG
    fprintf(debug, "MKMDAwaitReply called %d timeout\n", timeout);
#endif
    userFuncs = funcs;
    // since readProc will be called asynchronously when data is available, don't wait, just return
    if(timeout != MKMD_NO_TIMEOUT) { 
        playEndTimeEstimate = playEndTimeEstimate < timeout ? playEndTimeEstimate : timeout;
    }
    delayEstimateInSeconds = (playEndTimeEstimate - datumMilliSecTime) * quantumInSeconds;
#if FUNCLOG
    fprintf(debug, "MKMDAwaitReply waiting %ld quantums or %f seconds\n", playEndTimeEstimate, delayEstimateInSeconds);
#endif

    // delayEstimateInSeconds never reduces as events are to be played, since
    // we can't estimate their consumption rate, so this is the entire
    // performance duration since last MKMDSetClockTime. 
    // We note the start date of MKMDSetClockTime and wait an absolute date.
    [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                             beforeDate: [datumAsDate addTimeInterval: delayEstimateInSeconds]];

    // Should be calling userFuncs appropriately.
    
    playEndTimeEstimate = 0;
    return MKMD_SUCCESS;
}

// Here we save up the reply functions and then dispatch them.
PERFORM_API MKMDReturn MKMDHandleReply(msg_header_t *msg, MKMDReplyFunctions *funcs)
{
#if FUNCLOG
    fprintf(debug, "MKMDHandleReply called\n");
#endif
    userFuncs = funcs;
    replyDispatch(userFuncs);
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
    fprintf(debug, "MKMDSetReplyCallback called\n");
#endif
    callbackFn = newCallbackFn;
    callbackParam = newCallbackParam;
    return MKMD_SUCCESS;
}


/*
 Download the DLS instruments
 */
PERFORM_API MKMDReturn MKMDDownloadDLSInstruments(unsigned int *patchesToDownload, int patchesUsed)
{
    return MKMD_SUCCESS;
}

#ifdef __cplusplus
}
#endif
