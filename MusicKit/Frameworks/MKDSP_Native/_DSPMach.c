/* _DSPMach.c
   Interface routines for composing messages to send to the sound
   facilities.

   Copyright 1988-1992, NeXT Inc.  All rights reserved.

   Modifications

 03/30/89/jos - added error message to unfinished DMA routines 
 02/13/90/jos - deleted many functions replaced by snddriver versions.
		We need not maintain the shlib vectors because the only
		user of these functions is DSPObject.c which is itself
		in the shlib.  Note that the semantics change slightly in some
		cases:  
		- In general, a timeout of 1 second was added to many functions
		  while the _DSP_ versions wait forever.
		  Anything involving negotiation ports was modified to
		  set the neg port to the remote port if not returned by kernel
		- In snddriver_set_{dsp,sndin}_owner_port(), the neg_port is 
		  set to the remote port BEFORE normal_ret() is called.
		- In snddriver_set_*_owner_port(), the neg_port is set 
		  to the remote port while the _DSP_ version never set it.
 02/19/90/jos - deleted all functions not actually used.
 		Those retained are kept purely to avoid extra 1 page mallocs.
 07/09/90/jos - changed sndmsg_dsp_data() to pass 3-byte DSP data type.
 */

#ifdef SHLIB
#include "shlib.h"
#endif

#define u_int unsigned int

#import "_DSPMach.h"
#import <mach/mach.h>
#import <stdio.h>

#ifndef SND_DSP_MT_PROTO
/*** FIXME: DELETE ME when new <nextdev/snd_msgs.h> installed ***/
#define SND_DSP_MT_PROTO	9
typedef struct {
	snd_dsp_type_t	msgtype;
	msg_type_t	protoType;
	u_int		proto;
} snd_dsp_mt_proto_t;

#endif

/* #import <ansi/stdlib.h> */
#import <stdlib.h>

#if WIN32
#import <winnt-pdo.h> // for bcopy definition
#endif

/* unprototyped procedures which trigger -Wimplicit warnings */
#if 0
extern int thread_reply();
extern void *malloc();
extern char *strcpy();
// extern int strlen();
#endif
//extern int bcopy();

/*
 * Messages are of three types: those sent to an stream port, those
 * sent to the device port, and those returned by the kernel.
 *
 * There are two types of message sent to an stream port, the first
 * message may contain several components (play_data, record_data, timeout,
 * state, and nsamples).  These components may be added, in any order,
 * to a message.  The second is for retriving the number of bytes played
 * or recorded on the stream since it was last reset.
 */

/*
 * Returns a message header of initial size size used to contain
 * a set of requests to a sound stream port.  Like snddriver_stream_msg
 * except that it will reuse an existing message frame if passed, saving
 * a one-page malloc.
 */
mach_msg_header_t *_DSP_stream_msg (
	mach_msg_header_t *msg,		// message pointer to reuse or malloc
	mach_port_t	stream_port,		// valid stream port
	mach_port_t	reply_port,		// task port or other
	int	data_tag)		// tag associated with request
{
}

/*
 * Returns a message header of initial size used to contain
 * a set of requests to dsp command port.  The message size can be
 * extended up to the maximum size MSG_SIZE_MAX.
 */
mach_msg_header_t *_DSP_dspcmd_msg (
	mach_port_t	cmd_port,		// valid dsp command port
	mach_port_t	reply_port,		// where to send reply message(s)
	int	priority,		// DSP_MSG_{LOW,MED,HIGH}
	int	atomic)			// message may not be preempted
{
	snd_dspcmd_msg_t *m;
	return ((mach_msg_header_t *)m);
}

void _DSP_free_dspcmd_msg(mach_msg_header_t **msg) {
	*msg = 0;
}

/*
 * Restores a message header as created by snd_dspcmd_msg to its initial state,
 * possibly resetting the command/reply ports, priority, and atomic bits.
 */
mach_msg_header_t *_DSP_dspcmd_msg_reset (
	mach_msg_header_t *msg,		// Existing message header
	mach_port_t	cmd_port,		// valid dsp command port
	mach_port_t	reply_port,		// where to send reply message(s)
   /* reply_port = PORT_NULL inhibits reply when it's only a msg_send ack */
	int	priority,		// DSP_MSG_{LOW,MED,HIGH}
	int	atomic)			// message may not be preempted
{
	snd_dspcmd_msg_t *m;

	if (!msg)
	  msg = _DSP_dspcmd_msg(cmd_port,reply_port,priority,atomic);

	m = (snd_dspcmd_msg_t *)msg;
	m->header.msgh_size = sizeof(snd_dspcmd_msg_t);
	m->header.msgh_remote_port = cmd_port;
	m->header.msgh_local_port = reply_port; 
	m->header.msgh_id = SND_MSG_DSP_MSG;
	m->pri = priority;
	m->atomic = atomic;
	return ((mach_msg_header_t *)m);
}

/*
 * Returns a message header of maximum size size used to receive
 * data from the DSP.
 */
mach_msg_header_t *_DSP_dsprcv_msg (
	mach_port_t	cmd_port,		// valid dsp command port
	mach_port_t	reply_port)		// where to get message receives
{
    mach_msg_header_t *m;
    return(m);
}

mach_msg_header_t *_DSP_dsprcv_msg_reset(
	mach_msg_header_t *msg,		// message created by _DSP_dsprcv_msg
	mach_port_t	cmd_port,		// valid dsp command port
	mach_port_t	reply_port)		// where to get message receives
{
    return(msg);
}

/*
 * Restores a message header as created by _DSP_dspreply_msg to initial state.
 */
mach_msg_header_t *_DSP_dspreply_msg_reset (
	mach_msg_header_t *msg,		// Existing message header
	mach_port_t	reply_port)		// where to send reply message
{
    if (!msg)
      msg = _DSP_dspreply_msg(reply_port);
    msg->msgh_size = sizeof(mach_msg_header_t);
    msg->msgh_remote_port = reply_port;
    msg->msgh_local_port = PORT_NULL;
    msg->msgh_id = 54321;
    return (msg);
}

/*
 * Returns a message header suitable for general purpose reply messages.
 * It cannot be extended.
 */
mach_msg_header_t *_DSP_dspreply_msg (
	mach_port_t	reply_port)		// where to send reply message
{
	mach_msg_header_t *m;
	return (m);
}

/*
 * Add a DSP reset message.
 */
mach_msg_header_t *_DSP_dspreset (
	mach_msg_header_t	*msg)		// message frame to add request to
{
	return(msg);
}

/*
 * Add a condition to the message.
 */
mach_msg_header_t *_DSP_dsp_condition (
	mach_msg_header_t	*msg,		// message frame to add request to
	u_int		mask,		// mask of flags to inspect
	u_int		flags)		// set of flags that must be on
{
	return(msg);
}

/*
 * Add return message dsp command message.
 */
mach_msg_header_t *_DSP_dsp_ret_msg (
	mach_msg_header_t	*msg,		// message frame to add request to
	mach_msg_header_t	*ret_msg)	// message to sent to reply port
{
	return(msg);
}

/*
 * Add transmit data request to dsp command message.
 */
mach_msg_header_t *_DSP_dsp_data (
	mach_msg_header_t	*msg,		// message frame to add request to
	pointer_t	data,		// data to play
	int		eltsize,	// 1, 2, or 4 byte data
	int		nelts)		// number of elements of data to send
{
	return(msg);
}

/*
 * Add a host flag to the message.
 */
mach_msg_header_t *_DSP_dsp_host_flag (
	mach_msg_header_t	*msg,		// message frame to add request to
	u_int		mask,		// mask of flags to inspect
	u_int		flags)		// set of flags that must be on
{
	return(msg);
}

/*
 * Add a host command to the message.
 */
mach_msg_header_t *_DSP_dsp_host_command (
	mach_msg_header_t	*msg,		// message frame to add request to
	u_int		host_command)	// host command to execute
{
	return(msg);
}


mach_msg_header_t *_DSP_dsp_protocol (
	mach_msg_header_t	*msg,		// message frame to add request to
	mach_port_t		device_port,		// valid device port
	mach_port_t		owner_port,		// port registered as owner
	int		protocol)		// protocol bits
{
	return(msg);
}

/*
 * Add read-data request to dsp command message. (New for 2.0.)
 */
mach_msg_header_t *_DSP_dsp_read_data(mach_msg_header_t *msg, // message frame
				 int eltsize,	// 1, 2, 3, or 4 byte data
				 int nelts) 	// number of data elements
{
	return(msg);
}

#if !m68k && (defined(NeXT) || (defined(__APPLE__) && defined(__MACH__)) || defined(WIN32))
/* Maybe move this somewhere else */

mach_msg_header_t *_DSP_data_request_msg (
	mach_msg_header_t *msg,		// message pointer to reuse or malloc
	mach_port_t	stream_port,		// valid stream port
	mach_port_t	reply_port,		// task port or other
	int	data_tag,		// tag associated with request
        int     chan,			// dsp transfer channel
        int     msgID)			// type of msg	    
{
    return msg;
}

/*
 * Returns a message header of maximum size size used to receive
 * data from the DSP.
 */
mach_msg_header_t *_DSP_simple_request_msg (
	mach_port_t	cmd_port,		// valid dsp command port
	mach_port_t	reply_port,		// where to get message receives
        int messageType)				       
{
    return (mach_msg_header_t *)0;					 
}

void _DSP_free_simple_request_msg(mach_msg_header_t **msg) {
	free(*msg);
	*msg = 0;
}

#endif
