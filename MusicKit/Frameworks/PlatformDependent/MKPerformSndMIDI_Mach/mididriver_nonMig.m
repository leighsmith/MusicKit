/*
  $Id$
  Defined In: The MusicKit

  Description:
  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.2  2000/12/07 00:05:15  leigh
  Corrected for MKMDPort being a mach_port_t

  Revision 1.1  2000/12/06 18:50:44  leigh
  Added ObjC version

*/
#import <Foundation/Foundation.h>

#if openstep_i386
#import <driverkit/IOConfigTable.h>
#import <driverkit/IODeviceMaster.h>
#import <driverkit/IODevice.h>
#endif

#import <kernserv/kern_server_types.h>
#import <mach/mig_errors.h>  // Changed from sys/mig_errors.h 9/26/94
#import <mach/mach_error.h>  // Changed from mach_error.h 9/26/94
#import "midi_driver.h"
#import <stdio.h>

#define MKMD_NAME "Mididriver"  /* Name of driver (append unit number to use) */

kern_return_t MKMDAwaitReply(mach_port_t port_set,
			   MKMDReplyFunctions *funcs,
			   int timeout)
{
    char msg_buf[MKMD_MAX_MSG_SIZE];
    int r;
    msg_header_t *msg = (msg_header_t *)msg_buf;
    msg->msg_local_port = port_set;  /* Port set including replyPort */
    msg->msg_size = MKMD_MAX_MSG_SIZE;
    r = msg_receive(msg, ((timeout == MKMD_NO_TIMEOUT) ? MSG_OPTION_NONE :
			  RCV_TIMEOUT),  timeout);
    if (r != KERN_SUCCESS) 
	return r;
    return MKMDHandleReply(msg,funcs); 
}

static MKMDReplyFunctions *userFuncs;

kern_return_t MKMDExceptionReply(mach_port_t reply_port, 
			       int exception) {
    if (userFuncs->exceptionReply) {
	(*(userFuncs->exceptionReply))(reply_port,exception);
	return KERN_SUCCESS;
    } else return MIG_BAD_ID;
}

kern_return_t MKMDQueueReply(mach_port_t reply_port, 
			   int unit) { 
    if (userFuncs->queueReply) {
	(*(userFuncs->queueReply))(reply_port,unit);
	return KERN_SUCCESS;
    } else return MIG_BAD_ID;
}

kern_return_t MKMDAlarmReply(mach_port_t reply_port, 
			   int time, 
			   int actualTime) {
    if (userFuncs->alarmReply) {
	(*(userFuncs->alarmReply))(reply_port,time,actualTime);
	return KERN_SUCCESS;
    } else return MIG_BAD_ID;
}

kern_return_t MKMDDataReply(mach_port_t reply_port, 
			  int unit,
			  MKMDRawEvent *events, 
			  int count) {
    if (userFuncs->dataReply) {
	(*(userFuncs->dataReply))(reply_port,unit,events,count);
	return KERN_SUCCESS;
    } else return MIG_BAD_ID;
}

extern boolean_t mididriver_reply_server
    (msg_header_t *InHeadP, msg_header_t *OutHeadP);
/* Defined in mididriver_replyServer.c */

kern_return_t MKMDHandleReply(msg_header_t *msg,
			    MKMDReplyFunctions *funcs)
{
    /* All of the reply routines are simpleroutines so they actually have
     * no reply. This Reply struct is, thus, just for the return value
     * from midi_driver_reply_server.  
     */
    typedef struct {
	msg_header_t Head;
	msg_type_t RetCodeType;
	kern_return_t RetCode;
    } Reply;
    char out_msg_buf[sizeof(Reply)];
    Reply *out_msg = (Reply *)out_msg_buf;
    kern_return_t ret_code;
//    mach_port_t local_port = msg->msg_local_port;
    if (!funcs)
	return KERN_SUCCESS;
    userFuncs = funcs;
    mididriver_reply_server(msg, (msg_header_t *)out_msg);
    ret_code = out_msg->RetCode;
    if (out_msg->RetCode == MIG_NO_REPLY) /* This is an OK return code */
	ret_code = KERN_SUCCESS;  
    return ret_code;
}

// Should download the given patch numbers to the DLS player.
// For MacOS X-Server/OpenStep, this is currently disabled since we don't have a DLS player.
kern_return_t MKMDDownloadDLSInstruments(unsigned int *patches, int patchCount)
{
    return KERN_SUCCESS;
}

// need to be moved into a separate Objective C file.
const char **MKMDGetAvailableDrivers(unsigned int *selectedDriver)
{
#if openstep_i386
    char *s;
    const char *familyStr;
    List *installedDrivers;
    NSMutableArray *midiDriverList;
    id aConfigTable;
    int midiDriverCount;
    int i;

    // RDR2/Intel or OpenStep 4.X/Intel using DriverKit
    // The IOConfigTable access should become part of the MKPerformSndMIDI framework (suitably #if i386'd)
    installedDrivers = [IOConfigTable tablesForInstalledDrivers];
    /* Creates, if necessary, and returns IOConfigTables, one for each
       device that has been loaded into the system.  This method knows only
       about those devices that are specified with the system configuration
       table's InUse Drivers and Boot Drivers keys.  It does not detect
       drivers that were loaded due to user action at boot time.  To get
       the IOConfigTables for those drivers, you can use
       tablesForBootDrivers.
       */
    midiDriverList = [[NSMutableArray alloc] init];
    /* Get MIDI drivers */
    for (i = 0; i < [installedDrivers count]; i++) {
        aConfigTable = [installedDrivers objectAt:i]; 	/* Each driver */
        familyStr = [aConfigTable valueForStringKey:"Family"];
//        NSLog(@"%s\n", [aConfigTable valueForStringKey: "Driver Name"]);
        if(familyStr != NULL) {
          if (!strcmp(familyStr,"MIDI"))
            [midiDriverList addObject:aConfigTable];
        }
    }
    midiDriverCount = [midiDriverList count];
    if (midiDriverCount == 0) {
        /* This is almost certainly an error */
        [midiDriverList release];
        return NO;
    }
    midiDriverNames = [NSMutableArray arrayWithCapacity: midiDriverCount];
    midiDriverUnits = [NSMutableArray arrayWithCapacity: midiDriverCount];
    for (i=0; i < midiDriverCount; i++) {
        /* Or "Server Name"? */
        aConfigTable = [midiDriverList objectAtIndex:i];
        [midiDriverNames insertObject: [NSString stringWithCString:(char *)[aConfigTable valueForStringKey:"Class Names"]]
                         atIndex: i];
        s = (char *)[aConfigTable valueForStringKey:"Instance"];
        [midiDriverUnits insertObject: s ? [NSNumber numberWithInt: atoi(s)] : [NSNumber numberWithInt: 0] atIndex: i];
    }
#elif macosx_server
    // hardwire this for MOXS1.0 until tablesForInstalledDrivers gives us what we expect
    static char *midiDriver = MKMD_NAME;
    *selectedDriver = 0;
    return &midiDriver;
#endif
}

MKMDPort MKMDGetMIDIDeviceOnHost(const char *hostname)
{
    MKMDPort devicePort = [[[NSPortNameServer defaultPortNameServer] portForName: [NSString stringWithCString: MKMD_NAME]
                                                                         onHost: [NSString stringWithCString: hostname]] machPort];
    return devicePort;
}