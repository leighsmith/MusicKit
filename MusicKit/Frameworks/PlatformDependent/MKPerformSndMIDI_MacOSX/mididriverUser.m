/*
  $Id$
  Defined In: The MusicKit

  Description:
    Interface routines emulating the midi mach device driver of OpenStep on MacOS X

  Original Author: Leigh M. Smith, <leigh@tomandandy.com>, tomandandy music inc.

  30 July 1999, Copyright (c) 1999 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and this copyright message remains intact
  and accompanies all derived code.
*/
/*
Modification history:

  $Log$
  Revision 1.3  2000/11/14 04:37:24  leigh
  Further isolated mach port reliance, changing queuePort to MKMDReplyPort. Corrected quantumFactor to use the NanosecondsToAbsoluteTime converter.

  Revision 1.2  2000/11/10 23:12:11  leigh
  First stab at CoreMIDI support, changed return and port types to be more transparent.

  Revision 1.1  2000/10/29 06:06:37  leigh
  Replaced the C code with ObjC so we can pass NSPorts

*/
#include "midi_driver.h"
#include <CoreMIDI/MIDIServices.h>
#include <CarbonCore/CarbonCore.h> // needed for AbsoluteTime definitions.

#define FUNCLOG 1

#ifdef FUNCLOG
#include <stdio.h> // for fprintf and debug

FILE *debug; // precedes extern "C".
#endif

#ifdef __cplusplus
extern "C" {
#endif 

// multiplicative factor difference between MusicKit quantum and MIDITimeStamp
static MIDITimeStamp   quantumFactor; 
static MIDITimeStamp   datumRefTime;
static int             datumMSecTime;

static MIDIClientRef   client = NULL;   // handle indicating we are a client of the MIDI server.
static MIDIPortRef     outPort = NULL;
static MIDIPortRef     inPort = NULL;
static MIDIEndpointRef claimedDestinationUnit = NULL;
static MIDIEndpointRef claimedSourceUnit = NULL;
static MKMDReplyFunctions *userFuncs;   // functions to be called on reception from the driver.

static MKMDReplyPort   dataReplyPort;	// NSPort-like port to reply received MIDI on.
static MKMDReplyPort   queue_port;	// NSPort-like port to reply when queue is available.

// This should become part of the CoreMIDI library.
MIDITimeStamp MIDIGetCurrentTime(void)
{
    AbsoluteTime now = UpTime();
    return UnsignedWideToUInt64(now);
}

// TODO we need to properly convert the result to an int, since the division will reduce the actual result within those bounds.
static int timeStampToMKTime(MIDITimeStamp timeStamp)
{
    return (int) (timeStamp - datumRefTime) / quantumFactor;
}

// called on reception of MIDI packets.
static void readProc(const MIDIPacketList *pktlist, void *refCon, void *connRefCon)
{
    unsigned int packetIndex;
    int dataIndex;

//    if (outPort != NULL && claimedDestinationUnit != NULL) {
//    if (userFuncs->dataReply) {
    if (1) {
        MIDIPacket *packet = (MIDIPacket *)pktlist->packet;	// remove const (!)
        for (packetIndex = 0; packetIndex < pktlist->numPackets; ++packetIndex) {
            MKMDRawEvent *events = (MKMDRawEvent *) malloc(sizeof(MKMDRawEvent) * packet->length);

            printf("received packet of %d: ", packet->length);
            for (dataIndex = 0; dataIndex < packet->length; ++dataIndex) {
                printf("%02X ", packet->data[dataIndex]);
                events[dataIndex].byte = packet->data[dataIndex];
                events[dataIndex].time = timeStampToMKTime(packet->timeStamp);
            }
            printf("\n");
            claimedSourceUnit = 0; // determine from refCon and connRefCon
            free(events);
            packet = MIDIPacketNext(packet);
        }
    }
}

// retrieve a list of strings giving driver names, and therefore (0 based) unit numbers.
PERFORM_API const char **MKMDGetAvailableDrivers(unsigned int *selectedDriver)
{
    const char **driverList;
    ItemCount i, n;
    CFStringRef pname, pmanuf, pmodel;
    char name[64], manuf[64], model[64];
	
#if 1 // USE_DEVICES
    // enumerate devices 
    n = MIDIGetNumberOfDevices();
    driverList = (char **) calloc(n, sizeof(char *));
    for (i = 0; i < n; ++i) {
        MIDIDeviceRef dev = MIDIGetDevice(i);
        
        MIDIObjectGetStringProperty(dev, kMIDIPropertyName, &pname);
        MIDIObjectGetStringProperty(dev, kMIDIPropertyManufacturer, &pmanuf);
        MIDIObjectGetStringProperty(dev, kMIDIPropertyModel, &pmodel);
        
        CFStringGetCString(pname, name, sizeof(name), 0);
        CFStringGetCString(pmanuf, manuf, sizeof(manuf), 0);
        CFStringGetCString(pmodel, model, sizeof(model), 0);
        driverList[i] = [[NSString stringWithFormat: @"%@ %@ %@", pmanuf, pname, pmodel] cString];
        CFRelease(pname);
        CFRelease(pmanuf);
        CFRelease(pmodel);

        // printf("driver[%ld] = %s\n", i, driverList[i]);
    }
#else
    // Actually, this should return a collection of entities rather than devices, which are configurations
    // of system wide interoperating MIDI streams.
    n = MIDIDeviceGetNumberOfEntities(MIDIDeviceRef device);

#endif

    *selectedDriver = 0;
    
    return driverList;
}

// returns NULL if unable to find the hostname, otherwise whatever value for MKMDPort
// that has meaning.
PERFORM_API MKMDPort MKMDGetMIDIDeviceOnHost(const char *hostname)
{
    NSMachPort *devicePort = [NSMachPort port]; // kludge it so it seems initialised
    if(*hostname) {
        NSLog(@"MIDI on remote hosts not yet implemented on MacOS X\n");
        return NULL;
    }
    else
        return devicePort;
}

/* Routine MKMDBecomeOwner */
PERFORM_API MKMDReturn MKMDBecomeOwner (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port)
{
    // create client and ports

#ifdef FUNCLOG
    if(debug == NULL) {
        // create a means to see where we are without having to tiptoe around the MS debugger.
        if((debug = fopen("/tmp/PerformMIDI_debug.txt", "w")) == NULL)
            return MKMD_ERROR_UNKNOWN_ERROR;
    }
    fprintf(debug, "MKMDBecomeOwner called\n");
#endif

    // NSApplicationName
    // NSLog(@"appname %@\n", [[[NSBundle mainBundle] infoDictionary] valueForKey: NSExecutable]);
    MIDIClientCreate(CFSTR("MusicKit - This has to be whatever the app is"), NULL, NULL, &client);	
    MIDIInputPortCreate(client, CFSTR("Input port"), readProc, NULL, &inPort);
    MIDIOutputPortCreate(client, CFSTR("Output port"), &outPort);

    return MKMD_SUCCESS;
}

/* Routine MKMDReleaseOwnership */
PERFORM_API MKMDReturn MKMDReleaseOwnership (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port)
{
#ifdef FUNCLOG
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
#ifdef FUNCLOG
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

#ifdef FUNCLOG
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
#ifdef FUNCLOG
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
    datumMSecTime = time;
#ifdef FUNCLOG
    fprintf(debug, "MKMDSetClockTime called %d, datumRefTime = %f\n", time, (double) datumRefTime);
#endif
    return MKMD_SUCCESS;
}

/* SimpleRoutine MKMDRequestAlarm */
PERFORM_API MKMDReturn MKMDRequestAlarm (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	port_t reply_port,
	int time)
{
#ifdef FUNCLOG
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
#ifdef FUNCLOG
    fprintf(debug, "MKMDStartClock called\n");
#endif
    return MKMD_SUCCESS;
}

/* Routine MKMDStopClock */
PERFORM_API MKMDReturn MKMDStopClock (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port)
{
    // TODO check the ports properly
#ifdef FUNCLOG
    fprintf(debug, "MKMDStopClock called\n");
#endif
    return MKMD_SUCCESS;
}

/* Routine MKMDClaimUnit */
PERFORM_API MKMDReturn MKMDClaimUnit (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit)
{
    ItemCount destinationCount;
    ItemCount sourceCount;
    ItemCount i;
#ifdef FUNCLOG
    fprintf(debug, "MKMDClaimUnit called %d\n", unit);
#endif
    // find the first destination
    destinationCount = MIDIGetNumberOfDestinations();
    if (destinationCount > 0) {
        // should be unit?
        claimedDestinationUnit = MIDIGetDestination(unit);
    }

    if (claimedDestinationUnit != NULL) {
        CFStringRef pname;
        char name[64]; // TODO what is the size?

        MIDIObjectGetStringProperty(claimedDestinationUnit, kMIDIPropertyName, &pname);
        CFStringGetCString(pname, name, sizeof(name), 0);
        CFRelease(pname);
        printf("Output to %s\n", name);
    }
    else {
        printf("No MIDI destinations present\n");
    }

    // open connections from all sources
    sourceCount = MIDIGetNumberOfSources();
    printf("%ld sources\n", sourceCount);
    for (i = 0; i < sourceCount; ++i) {
        MIDIEndpointRef src = MIDIGetSource(i);
        MIDIPortConnectSource(inPort, src, NULL);
    }
	
    return MKMD_SUCCESS;
}

/* Routine MKMDReleaseUnit */
PERFORM_API MKMDReturn MKMDReleaseUnit (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit)
{
#ifdef FUNCLOG
    fprintf(debug, "MKMDReleaseUnit %d called\n", unit);
#endif
    return TRUE;
}

/* Routine MKMDRequestExceptions */
PERFORM_API MKMDReturn MKMDRequestExceptions (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	port_t error_port)
{
#ifdef FUNCLOG
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
#ifdef FUNCLOG
    fprintf(debug, "MKMDRequestData called\n");
#endif
    // reply_port is nil when indicating no data is to be returned.
    dataReplyPort = reply_port;
    return MKMD_SUCCESS;
}

/* Routine MKMDSendData */
// Each event consists of a time stamp per byte. This was done to allow slowing byte output
// to stop choking synths with sysex messages. Nowdays it would seem better just to specify
// an inter-byte delay and specify the start time of the channel byte.
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
    static Byte pbuf[512];
    MIDIPacketList *pktlist = (MIDIPacketList *) pbuf;
    MIDIPacket *packet;

#ifdef FUNCLOG
    fprintf(debug, "MKMDSendData called with %d events @ time %d\n", dataCnt, data[0].time);
#endif

    if((packet = MIDIPacketListInit(pktlist)) == NULL) {
        return MKMD_ERROR_UNKNOWN_ERROR;
    }

    // need to convert the times, extract the data and pack back into a buffer.
    buffer = (Byte *) malloc(dataCnt);
    for(msgIndex = 0; msgIndex < dataCnt; msgIndex++) {
        buffer[msgIndex] = data[msgIndex].byte;
#ifdef FUNCLOG
        fprintf(debug, "%02X ", buffer[msgIndex]);
#endif
    }

    // we erronously assume all events specified in a single call are intended
    // to be sent immediately one after another.
    playTime = (data[0].time - datumMSecTime) * quantumFactor + datumRefTime;
#ifdef FUNCLOG
    fprintf(debug, "\nCurrent time %f, play time %f\n", (double) MIDIGetCurrentTime(), (double) playTime);
#endif
    packet = MIDIPacketListAdd(pktlist, sizeof(pbuf), packet, playTime, dataCnt, buffer);
    if(packet == NULL) {
        free(buffer);
        return MKMD_ERROR_UNKNOWN_ERROR;
    }
    if(MIDISend(outPort, claimedDestinationUnit, pktlist) != noErr) {
        free(buffer);
        return MKMD_ERROR_UNKNOWN_ERROR;
    }
    // once the buffer has been packed, it can be discarded as packing copies the data.
    free(buffer);
#ifdef FUNCLOG
    fprintf(debug,"MKMDSendData returning ok\n");
#endif
    return MKMD_SUCCESS;
}

/* Routine MKMDGetAvailableQueueSize */
PERFORM_API MKMDReturn MKMDGetAvailableQueueSize (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	int *size)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDGetAvailableQueueSize called %d\n", unit);
#endif
  // return the queue size
  //if(!PMGetAvailableQueueSize(size)) {
  //  return MKMD_ERROR_UNKNOWN_ERROR;
  //}
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
#ifdef FUNCLOG
  fprintf(debug, "MKMDRequestQueueNotification called size = %d\n", size);
#endif
  return MKMD_SUCCESS;
}

/* Routine MKMDClearQueue */
PERFORM_API MKMDReturn MKMDClearQueue (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDClearQueue called\n");
#endif
  return MKMD_SUCCESS;
}

/* Routine MKMDFlushQueue */
PERFORM_API MKMDReturn MKMDFlushQueue (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit)
{
#ifdef FUNCLOG
  fprintf(debug, "MKMDFlushQueue called\n");
#endif
  return MKMD_SUCCESS;
}

/* Routine MKMDSetSystemIgnores */
PERFORM_API MKMDReturn MKMDSetSystemIgnores (
	MKMDPort mididriver_port,
	MKMDOwnerPort owner_port,
	short unit,
	unsigned int sys_ignores)
{
#ifdef FUNCLOG
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

#ifdef FUNCLOG
    fprintf(debug, "MKMDSetClockQuantum called %d microseconds, %f MIDITimeStamp units\n",
        microseconds, (double) quantumFactor);
#endif
    return MKMD_SUCCESS;
}

// This should wait until a reply is received on port_set or until timeout
PERFORM_API MKMDReturn MKMDAwaitReply(MKMDReplyPort port_set, MKMDReplyFunctions *funcs, int timeout)
{
#ifdef FUNCLOG
    fprintf(debug, "MKMDAwaitReply called %d timeout\n", timeout);
#endif
    queue_port = port_set;
    return MKMD_SUCCESS;
}

// Here we do is save up the reply functions.
PERFORM_API MKMDReturn MKMDHandleReply(msg_header_t *msg, MKMDReplyFunctions *funcs)
{
#ifdef FUNCLOG
    fprintf(debug, "MKMDHandleReply called\n");
#endif
    userFuncs = funcs;
// probably need to look at the msg to determine what to do.
#if 0
    if (userFuncs->dataReply) {
        (*(userFuncs->dataReply))([dataReplyPort machPort], claimedSourceUnit, events, packet->length);
    }
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
