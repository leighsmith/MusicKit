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
  Revision 1.2  1999/07/29 01:26:08  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifdef SHLIB
#include "shlib.h"
#endif SHLIB

#import <kernserv/kern_server_types.h>
#import <mach/mig_errors.h>  // Changed from sys/mig_errors.h 9/26/94
#import <mach/mach_error.h>  // Changed from mach_error.h 9/26/94
#import "midi_driver.h"
#import <stdio.h>

kern_return_t MDAwaitReply(port_t port_set,
			   MDReplyFunctions *funcs,
			   int timeout)
{
    char msg_buf[MD_MAX_MSG_SIZE];
    int r;
    msg_header_t *msg = (msg_header_t *)msg_buf;
    msg->msg_local_port = port_set;  /* Port set including replyPort */
    msg->msg_size = MD_MAX_MSG_SIZE;
    r = msg_receive(msg, ((timeout == MD_NO_TIMEOUT) ? MSG_OPTION_NONE :
			  RCV_TIMEOUT),  timeout);
    if (r != KERN_SUCCESS) 
	return r;
    return MDHandleReply(msg,funcs); 
}

static MDReplyFunctions *userFuncs;

kern_return_t MDExceptionReply(port_t reply_port, 
			       int exception) {
    if (userFuncs->exceptionReply) {
	(*(userFuncs->exceptionReply))(reply_port,exception);
	return KERN_SUCCESS;
    } else return MIG_BAD_ID;
}

kern_return_t MDQueueReply(port_t reply_port, 
			   int unit) { 
    if (userFuncs->queueReply) {
	(*(userFuncs->queueReply))(reply_port,unit);
	return KERN_SUCCESS;
    } else return MIG_BAD_ID;
}

kern_return_t MDAlarmReply(port_t reply_port, 
			   int time, 
			   int actualTime) {
    if (userFuncs->alarmReply) {
	(*(userFuncs->alarmReply))(reply_port,time,actualTime);
	return KERN_SUCCESS;
    } else return MIG_BAD_ID;
}

kern_return_t MDDataReply(port_t reply_port, 
			  int unit,
			  MDRawEvent *events, 
			  int count) {
    if (userFuncs->dataReply) {
	(*(userFuncs->dataReply))(reply_port,unit,events,count);
	return KERN_SUCCESS;
    } else return MIG_BAD_ID;
}

extern boolean_t mididriver_reply_server
    (msg_header_t *InHeadP, msg_header_t *OutHeadP);
/* Defined in mididriver_replyServer.c */

kern_return_t MDHandleReply(msg_header_t *msg,
			    MDReplyFunctions *funcs)
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
//    port_t local_port = msg->msg_local_port;
    if (!funcs)
	return KERN_SUCCESS;
    userFuncs = funcs;
    mididriver_reply_server(msg, (msg_header_t *)out_msg);
    ret_code = out_msg->RetCode;
    if (out_msg->RetCode == MIG_NO_REPLY) /* This is an OK return code */
	ret_code = KERN_SUCCESS;  
    return ret_code;
}

