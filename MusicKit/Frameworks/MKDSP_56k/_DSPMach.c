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
msg_header_t *_DSP_stream_msg (
	msg_header_t *msg,		// message pointer to reuse or malloc
	port_t	stream_port,		// valid stream port
	port_t	reply_port,		// task port or other
	int	data_tag)		// tag associated with request
{
	snd_stream_msg_t *m = (snd_stream_msg_t *)msg;

	static const snd_stream_msg_t M = {
		{
			/* no name */		0,
			/* msg_simple */	TRUE,
			/* msg_size */		sizeof(snd_stream_msg_t),
			/* msg_type */		MSG_TYPE_NORMAL,
			/* msg_remote_port */	0,
			/* msg_reply_port */	0,
			/* msg_id */		SND_MSG_STREAM_MSG
		},
		{
			/* msg_type_name = */		MSG_TYPE_INTEGER_32,
			/* msg_type_size = */		32,
			/* msg_type_number = */		1,
			/* msg_type_inline = */		TRUE,
			/* msg_type_longform = */	FALSE,
			/* msg_type_deallocate = */	FALSE,
		}
	};

	if (!m)
	  m = (snd_stream_msg_t *)malloc(MSG_SIZE_MAX);

	*m = M;
	m->header.msg_remote_port = stream_port;
	m->header.msg_local_port = reply_port;
	m->data_tag = data_tag;
	return ((msg_header_t *)m);
}

/*
 * Composite message sent to dsp command queue.
 * Message will consist of some combination of:
 *	condition	mask and set of register values
 *	data		1, 2, or 4 byte data
 *	host command
 *	host flags	only ICR_HF0 or ICR_HF1
 *	ret message	message to be sent (to reply port)
 */

    static const snd_dspcmd_msg_t snd_dspcmd_msg_proto = {
    /* header */ {
		    /* no name */		0,
		    /* msg_simple */		TRUE,
		    /* msg_size */		sizeof(snd_dspcmd_msg_t),
		    /* msg_type */		MSG_TYPE_NORMAL,
		    /* msg_remote_port */	0,
		    /* msg_reply_port */	0,
		    /* msg_id */		SND_MSG_DSP_MSG
		 },
   /* priType */ {
		    /* msg_type_name = */	MSG_TYPE_INTEGER_32,
		    /* msg_type_size = */	32,
		    /* msg_type_number = */	2,
		    /* msg_type_inline = */	TRUE,
		    /* msg_type_longform = */	FALSE,
		    /* msg_type_deallocate = */ FALSE,
		 },
    /* pri */	 DSP_MSG_LOW,
    /* atomic */ 0
  };

/*
 * Returns a message header of initial size used to contain
 * a set of requests to dsp command port.  The message size can be
 * extended up to the maximum size MSG_SIZE_MAX.
 */
msg_header_t *_DSP_dspcmd_msg (
	port_t	cmd_port,		// valid dsp command port
	port_t	reply_port,		// where to send reply message(s)
	int	priority,		// DSP_MSG_{LOW,MED,HIGH}
	int	atomic)			// message may not be preempted
{
	snd_dspcmd_msg_t *m;
	vm_allocate(task_self(),(vm_address_t *)(&m), MSG_SIZE_MAX, TRUE);
	*m = snd_dspcmd_msg_proto;
	_DSP_dspcmd_msg_reset((msg_header_t *)m,
			     cmd_port,reply_port,priority,atomic);
	return ((msg_header_t *)m);
}

void _DSP_free_dspcmd_msg(msg_header_t **msg) {
	vm_deallocate(task_self(), (vm_address_t)*msg, MSG_SIZE_MAX);
	*msg = 0;
}

/*
 * Restores a message header as created by snd_dspcmd_msg to its initial state,
 * possibly resetting the command/reply ports, priority, and atomic bits.
 */
msg_header_t *_DSP_dspcmd_msg_reset (
	msg_header_t *msg,		// Existing message header
	port_t	cmd_port,		// valid dsp command port
	port_t	reply_port,		// where to send reply message(s)
   /* reply_port = PORT_NULL inhibits reply when it's only a msg_send ack */
	int	priority,		// DSP_MSG_{LOW,MED,HIGH}
	int	atomic)			// message may not be preempted
{
	snd_dspcmd_msg_t *m;

	if (!msg)
	  msg = _DSP_dspcmd_msg(cmd_port,reply_port,priority,atomic);

	m = (snd_dspcmd_msg_t *)msg;
	m->header.msg_size = sizeof(snd_dspcmd_msg_t);
	m->header.msg_remote_port = cmd_port;
	m->header.msg_local_port = reply_port; 
	m->header.msg_id = SND_MSG_DSP_MSG;
	m->pri = priority;
	m->atomic = atomic;
	return ((msg_header_t *)m);
}

/*
 * Returns a message header of maximum size size used to receive
 * data from the DSP.
 */
msg_header_t *_DSP_dsprcv_msg (
	port_t	cmd_port,		// valid dsp command port
	port_t	reply_port)		// where to get message receives
{
    msg_header_t *m = _DSP_dspcmd_msg(cmd_port,reply_port,DSP_MSG_LOW,0);
    m->msg_size = MSG_SIZE_MAX;
    return(m);
}

msg_header_t *_DSP_dsprcv_msg_reset(
	msg_header_t *msg,		// message created by _DSP_dsprcv_msg
	port_t	cmd_port,		// valid dsp command port
	port_t	reply_port)		// where to get message receives
{
    if (!msg)
      msg = _DSP_dsprcv_msg (cmd_port,reply_port);
    msg->msg_size = MSG_SIZE_MAX;
    msg->msg_local_port = reply_port;
    return(msg);
}


static msg_header_t snd_dspreply_msg_proto = { 
		/* no name */		0,
		/* msg_simple */	TRUE,
		/* msg_size */		sizeof(msg_header_t),
		/* msg_type */		MSG_TYPE_NORMAL,
		/* msg_remote_port */	PORT_NULL,	// MUST BE SET
		/* msg_local_port */	PORT_NULL,
		/* msg_id */		54321
	};


/*
 * Restores a message header as created by _DSP_dspreply_msg to initial state.
 */
msg_header_t *_DSP_dspreply_msg_reset (
	msg_header_t *msg,		// Existing message header
	port_t	reply_port)		// where to send reply message
{
    if (!msg)
      msg = _DSP_dspreply_msg(reply_port);
    msg->msg_size = sizeof(msg_header_t);
    msg->msg_remote_port = reply_port;
    msg->msg_local_port = PORT_NULL;
    msg->msg_id = 54321;
    return (msg);
}

/*
 * Returns a message header suitable for general purpose reply messages.
 * It cannot be extended.
 */
msg_header_t *_DSP_dspreply_msg (
	port_t	reply_port)		// where to send reply message
{
	msg_header_t *m = &snd_dspreply_msg_proto;
	_DSP_dspreply_msg_reset(m,reply_port);
	return (m);
}

/*
 * Add a DSP reset message.
 */
msg_header_t *_DSP_dspreset (
	msg_header_t	*msg)		// message frame to add request to
{
	snd_dsp_reset_t *m =
		(snd_dsp_reset_t *)(((int)msg)+msg->msg_size);
	static const snd_dsp_reset_t M = {
		{{
			/* msg_type_name = */		MSG_TYPE_INTEGER_32,
			/* msg_type_size = */		32,
			/* msg_type_number = */		1,
			/* msg_type_inline = */		TRUE,
			/* msg_type_longform = */	FALSE,
			/* msg_type_deallocate = */	FALSE,
		},
		SND_DSP_MT_RESET}
	};
			
	if (msg->msg_size + sizeof(*m) >= MSG_SIZE_MAX)
		return (msg_header_t *)SEND_MSG_TOO_LARGE;

	/*
	 * Add this message component to the message.
	 */
	*m = M;

	msg->msg_size += sizeof(*m);
	return(msg);
}

/*
 * Add a condition to the message.
 */
msg_header_t *_DSP_dsp_condition (
	msg_header_t	*msg,		// message frame to add request to
	u_int		mask,		// mask of flags to inspect
	u_int		flags)		// set of flags that must be on
{
	snd_dsp_condition_t *m =
		(snd_dsp_condition_t *)(((int)msg)+msg->msg_size);
	static const snd_dsp_condition_t M = {
		{{
			/* msg_type_name = */		MSG_TYPE_INTEGER_32,
			/* msg_type_size = */		32,
			/* msg_type_number = */		1,
			/* msg_type_inline = */		TRUE,
			/* msg_type_longform = */	FALSE,
			/* msg_type_deallocate = */	FALSE,
		},
		SND_DSP_MT_CONDITION},
		{
			/* msg_type_name = */		MSG_TYPE_INTEGER_32,
			/* msg_type_size = */		32,
			/* msg_type_number = */		2,
			/* msg_type_inline = */		TRUE,
			/* msg_type_longform = */	FALSE,
			/* msg_type_deallocate = */	FALSE,
		}
	};
			
	if (msg->msg_size + sizeof(*m) >= MSG_SIZE_MAX)
		return (msg_header_t *)SEND_MSG_TOO_LARGE;

	/*
	 * Add this message component to the message.
	 */
	*m = M;
	m->mask = mask;
	m->flags = flags;

	msg->msg_size += sizeof(*m);
	return(msg);
}

/*
 * Add return message dsp command message.
 */
msg_header_t *_DSP_dsp_ret_msg (
	msg_header_t	*msg,		// message frame to add request to
	msg_header_t	*ret_msg)	// message to sent to reply port
{
	int msize;
	snd_dsp_ret_msg_t *m =
		(snd_dsp_ret_msg_t *)(((int)msg)+msg->msg_size);
	static const snd_dsp_ret_msg_t M = {
		{{
			/* msg_type_name = */		MSG_TYPE_INTEGER_32,
			/* msg_type_size = */		32,
			/* msg_type_number = */		1,
			/* msg_type_inline = */		TRUE,
			/* msg_type_longform = */	FALSE,
			/* msg_type_deallocate = */	FALSE,
		},
		SND_DSP_MT_RET_MSG},
		{
			/* msg_type_name = */		MSG_TYPE_PORT,
			/* msg_type_size = */		32,
			/* msg_type_number = */		1,
			/* msg_type_inline = */		TRUE,
			/* msg_type_longform = */	FALSE,
			/* msg_type_deallocate = */	FALSE,
		},
		0,
		{
			{
				/* msg_type_name = */		0,
				/* msg_type_size = */		0,
				/* msg_type_number = */		0,
				/* msg_type_inline = */		TRUE,
				/* msg_type_longform = */	TRUE,
				/* msg_type_deallocate = */	FALSE,
			},
			/* msg_type_long_name = */	MSG_TYPE_INTEGER_8,
			/* msg_type_long_size = */	8,
			/* msg_type_long_number = */	0,
		}
	};
			
	msize = sizeof(*m) - sizeof(*ret_msg) + ret_msg->msg_size;

	if (msg->msg_size + msize >= MSG_SIZE_MAX)
		return (msg_header_t *)SEND_MSG_TOO_LARGE;

	/*
	 * Add this message component to the message.
	 */
	*m = M;
	m->ret_port = ret_msg->msg_remote_port;
	bcopy((char *)ret_msg, (char *)&m->ret_msg, ret_msg->msg_size);
	m->ret_msgType.msg_type_long_number = ret_msg->msg_size;
	msg->msg_simple = FALSE;
	/*
	 * Message can't be a simple type anymore.
	 */
	msg->msg_size += msize;
	return(msg);
}

/*
 * Add transmit data request to dsp command message.
 */
msg_header_t *_DSP_dsp_data (
	msg_header_t	*msg,		// message frame to add request to
	pointer_t	data,		// data to play
	int		eltsize,	// 1, 2, or 4 byte data
	int		nelts)		// number of elements of data to send
{
	int msize, dsize;
	snd_dsp_data_t *m = (snd_dsp_data_t *)(((int)msg)+msg->msg_size);
	static const snd_dsp_data_t M = {
		{{
			/* msg_type_name = */		MSG_TYPE_INTEGER_32,
			/* msg_type_size = */		32,
			/* msg_type_number = */		1,
			/* msg_type_inline = */		TRUE,
			/* msg_type_longform = */	FALSE,
			/* msg_type_deallocate = */	FALSE,
		},
		SND_DSP_MT_DATA},
		{
			{
				/* msg_type_name = */		0,
				/* msg_type_size = */		0,
				/* msg_type_number = */		0,
				/* msg_type_inline = */		TRUE,
				/* msg_type_longform = */	TRUE,
				/* msg_type_deallocate = */	FALSE,
			},
			/* msg_type_long_name = */	MSG_TYPE_INTEGER_32,
			/* msg_type_long_size = */	0,
			/* msg_type_long_number = */	0,
		},
		0,
	};
			
	if (eltsize < 1 || eltsize > 4)
	  eltsize = 4;
	dsize = eltsize * nelts;
	msize = sizeof(*m) - sizeof(m->data) + dsize; /* in-line msg sz */

	if (msg->msg_size + sizeof(*m) >= MSG_SIZE_MAX)
	  return (msg_header_t *)SEND_MSG_TOO_LARGE; /* can't even go o.o.l */

	/*
	 * Add this message component to the message.
	 */
	*m = M;

	if ((msg->msg_size + msize) >= MSG_SIZE_MAX) {
		/*
		 * Too big to be sent inline, construct out-of-line data
		 * message.
		 */
		m->dataType.msg_type_header.msg_type_inline = FALSE;
		*(pointer_t *)&m->data = data;
		msize = sizeof(*m);
		msg->msg_simple = FALSE;
	} else {
		/*
		 * Send data inline.
		 */
		bcopy((char *)data, (char *)&(m->data), dsize);
	}

	m->dataType.msg_type_long_number = nelts;
	m->dataType.msg_type_long_size = eltsize*8;

	/*
	 * Message can't be a simple type anymore.
	 */
	msg->msg_size += msize;
	return(msg);
}

/*
 * Add a host flag to the message.
 */
msg_header_t *_DSP_dsp_host_flag (
	msg_header_t	*msg,		// message frame to add request to
	u_int		mask,		// mask of flags to inspect
	u_int		flags)		// set of flags that must be on
{
	snd_dsp_host_flag_t *m =
		(snd_dsp_host_flag_t *)(((int)msg)+msg->msg_size);
	static const snd_dsp_host_flag_t M = {
		{{
			/* msg_type_name = */		MSG_TYPE_INTEGER_32,
			/* msg_type_size = */		32,
			/* msg_type_number = */		1,
			/* msg_type_inline = */		TRUE,
			/* msg_type_longform = */	FALSE,
			/* msg_type_deallocate = */	FALSE,
		},
		SND_DSP_MT_HOST_FLAG},
		{
			/* msg_type_name = */		MSG_TYPE_INTEGER_32,
			/* msg_type_size = */		32,
			/* msg_type_number = */		2,
			/* msg_type_inline = */		TRUE,
			/* msg_type_longform = */	FALSE,
			/* msg_type_deallocate = */	FALSE,
		}
	};
			
	if (msg->msg_size + sizeof(*m) >= MSG_SIZE_MAX)
		return (msg_header_t *)SEND_MSG_TOO_LARGE;

	/*
	 * Add this message component to the message.
	 */
	*m = M;
	m->mask = mask;
	m->flags = flags;

	msg->msg_size += sizeof(*m);
	return(msg);
}

/*
 * Add a host command to the message.
 */
msg_header_t *_DSP_dsp_host_command (
	msg_header_t	*msg,		// message frame to add request to
	u_int		host_command)	// host command to execute
{
	snd_dsp_host_command_t *m =
		(snd_dsp_host_command_t *)(((int)msg)+msg->msg_size);
	static const snd_dsp_host_command_t M = {
		{{
			/* msg_type_name = */		MSG_TYPE_INTEGER_32,
			/* msg_type_size = */		32,
			/* msg_type_number = */		1,
			/* msg_type_inline = */		TRUE,
			/* msg_type_longform = */	FALSE,
			/* msg_type_deallocate = */	FALSE,
		},
		SND_DSP_MT_HOST_COMMAND},
		{
			/* msg_type_name = */		MSG_TYPE_INTEGER_32,
			/* msg_type_size = */		32,
			/* msg_type_number = */		1,
			/* msg_type_inline = */		TRUE,
			/* msg_type_longform = */	FALSE,
			/* msg_type_deallocate = */	FALSE,
		}
	};
			
	if (msg->msg_size + sizeof(*m) >= MSG_SIZE_MAX)
		return (msg_header_t *)SEND_MSG_TOO_LARGE;

	/*
	 * Add this message component to the message.
	 */
	*m = M;
	m->hc = host_command;

	msg->msg_size += sizeof(*m);
	return(msg);
}


msg_header_t *_DSP_dsp_protocol (
	msg_header_t	*msg,		// message frame to add request to
	port_t		device_port,		// valid device port
	port_t		owner_port,		// port registered as owner
	int		protocol)		// protocol bits
{
	snd_dsp_mt_proto_t *m =
	  (snd_dsp_mt_proto_t *)(((int)msg)+(msg->msg_size));
	static const snd_dsp_mt_proto_t M = {
		{{
			/* msg_type_name = */		MSG_TYPE_INTEGER_32,
			/* msg_type_size = */		32,
			/* msg_type_number = */		1,
			/* msg_type_inline = */		TRUE,
			/* msg_type_longform = */	FALSE,
			/* msg_type_deallocate = */	FALSE,
		},
		SND_DSP_MT_PROTO},
		{
			/* msg_type_name = */		MSG_TYPE_INTEGER_32,
			/* msg_type_size = */		32,
			/* msg_type_number = */		1,
			/* msg_type_inline = */		TRUE,
			/* msg_type_longform = */	FALSE,
			/* msg_type_deallocate = */	FALSE,
		}
	};
			
	if (msg->msg_size + sizeof(*m) >= MSG_SIZE_MAX)
		return (msg_header_t *)SEND_MSG_TOO_LARGE;

#ifdef VERSION_1
	return _DSPError(DSP_EMISC,"DSP protocol changes cannot work "
			 "until a case is added to the 'DSP_MSG' "
			 "case in snd_dspcmd.c (see snd_dspcmd_msg()). "
			 "DSP Protocol setting "
			 "is currently a device message only which "
			 "is a separate switch.");
#endif

	/*
	 * Add this message component to the message.
	 */
	*m = M;
	m->proto = protocol;

	msg->msg_size += sizeof(*m);
	return(msg);
}

/*
 * Add read-data request to dsp command message. (New for 2.0.)
 */
msg_header_t *_DSP_dsp_read_data(msg_header_t *msg, // message frame
				 int eltsize,	// 1, 2, 3, or 4 byte data
				 int nelts) 	// number of data elements
{
    snd_dsp_data_t *m = (snd_dsp_data_t *)(((int)msg)+msg->msg_size);
    static const snd_dsp_data_t M = {
	       {{
			/* msg_type_name = */		MSG_TYPE_INTEGER_32,
			/* msg_type_size = */		32,
			/* msg_type_number = */		1,
			/* msg_type_inline = */		TRUE,
			/* msg_type_longform = */	FALSE,
			/* msg_type_deallocate = */	FALSE,
		},
		/* M.msgtype.type? */ SND_DSP_MT_RDATA},
	        {
			{
				/* msg_type_name = */		0,
				/* msg_type_size = */		0,
				/* msg_type_number = */		0,
				/* msg_type_inline = */		TRUE,
				/* msg_type_longform = */	TRUE,
				/* msg_type_deallocate = */	FALSE,
			},
			/* msg_type_long_name = */	MSG_TYPE_INTEGER_32,
			/* msg_type_long_size = */	0,
			/* msg_type_long_number = */	0,
		},
		0,
	};
			
    if (eltsize < 1 || eltsize > 4)
      eltsize = 1;

    if (msg->msg_size + sizeof(*m) >= MSG_SIZE_MAX)
      return (msg_header_t *)SEND_MSG_TOO_LARGE;

    /*
     * Add this message component to the message.
     */
    *m = M;

#if 0
    m->dataType.msg_type_long_number = nelts;
    m->dataType.msg_type_long_size = eltsize*8;
#else
    /*** FIXME: What's this all about???? ***/
    /*** See also foodriver_client.c ***/
    m->dataType.msg_type_long_number = 4/eltsize; /* Make it come out to 32b */
    m->dataType.msg_type_long_size = eltsize*8;	/* So driver knows data size */
    m->data = nelts * eltsize;	/* How many bytes to read */
#endif

	/*
	 * Message can't be a simple type anymore.
	 */
	msg->msg_size += sizeof(*m);
	return(msg);
}

#if !m68k && (defined(NeXT) || (defined(__APPLE__) && defined(__MACH__)) || defined(WIN32))
/* Maybe move this somewhere else */

msg_header_t *_DSP_data_request_msg (
	msg_header_t *msg,		// message pointer to reuse or malloc
	port_t	stream_port,		// valid stream port
	port_t	reply_port,		// task port or other
	int	data_tag,		// tag associated with request
        int     chan,			// dsp transfer channel
        int     msgID)			// type of msg	    
{
    DSPDRIVERDataMessage *m;
    if (!msg) 
      msg = (void *)malloc(MSGSIZ); 
    m = (void *)msg;
    /* Probably don't need to fill in all these fields, but it doesn't hurt */ 
    m->h.msg_remote_port = stream_port;  /* Or PORT_NULL? */ 
    m->h.msg_local_port = reply_port;
    m->h.msg_simple = TRUE; 
    m->h.msg_size = sizeof(DSPDRIVERDataMessage); 
    m->h.msg_type = MSG_TYPE_NORMAL; 
    m->h.msg_id = msgID; 
    m->t1.msg_type_name = MSG_TYPE_INTEGER_32; 
    m->t1.msg_type_size = 32; 
    m->t1.msg_type_number = 3; 
    m->t1.msg_type_inline = TRUE; 
    m->t1.msg_type_longform = FALSE; 
    m->t1.msg_type_deallocate = FALSE; 
    m->regionTag = data_tag; 
    m->nbytes = 0; /* Will be supplied by driver */ 
    m->chan = chan; 
    if (msgID == DSPDRIVER_MSG_READ_LONG_COMPLETED) { 
	m->t2.msg_type_name = MSG_TYPE_INTEGER_32; 
	m->t2.msg_type_size = 32; 
    } 
    else { 
	m->t2.msg_type_name = MSG_TYPE_INTEGER_16; 
	m->t2.msg_type_size = 16; 
    } 
    m->t2.msg_type_number = 0;  /* Supplied by driver */
    m->t2.msg_type_inline = FALSE; 
    m->t2.msg_type_longform = FALSE; 
    m->t2.msg_type_deallocate = TRUE;
    return msg;
}

/*
 * Returns a message header of maximum size size used to receive
 * data from the DSP.
 */
msg_header_t *_DSP_simple_request_msg (
	port_t	cmd_port,		// valid dsp command port
	port_t	reply_port,		// where to get message receives
        int messageType)				       
{
    DSPDRIVERSimpleMessage *msg = malloc(sizeof(DSPDRIVERSimpleMessage));
    /*  FILL IN THE MESSAGE HEADER  */
    msg->h.msg_simple = TRUE;
    msg->h.msg_size = sizeof(DSPDRIVERSimpleMessage);
    msg->h.msg_type = MSG_TYPE_NORMAL;
    msg->h.msg_remote_port = cmd_port;
    msg->h.msg_local_port = reply_port;
    msg->h.msg_id = messageType;
    /*  FILL IN THE TYPE DESCRIPTOR  */
    msg->t.msg_type_name = MSG_TYPE_INTEGER_32;
    msg->t.msg_type_size = 32;
    msg->t.msg_type_number = 1;
    msg->t.msg_type_inline = TRUE;
    msg->t.msg_type_longform = FALSE;
    msg->t.msg_type_deallocate = FALSE;
    return (msg_header_t *)msg;					 
}

void _DSP_free_simple_request_msg(msg_header_t **msg) {
	free(*msg);
	*msg = 0;
}

#endif
