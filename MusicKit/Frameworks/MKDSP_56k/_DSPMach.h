#ifndef __MK__DSPMach_H___
#define __MK__DSPMach_H___
/* 
 * Mach interface
 * Copyright 1988-1992, NeXT Inc.  All rights reserved.
 */
/*
 * HISTORY
 * 10-Dec-88  Gregg Kellogg (gk) at NeXT
 *	Created.
 * Modifications by Julius Smith (jos) at NeXT
 */ 

#import <mach/mach.h>

#if !m68k && (defined(NeXT) || (defined(__APPLE__) && defined(__MACH__)) || defined(WIN32))
#import "dspdriverAccess.h"

extern mach_msg_header_t *_DSP_data_request_msg (
	mach_msg_header_t *msg,		// message pointer to reuse or malloc
	mach_port_t	stream_port,		// valid stream port
        mach_port_t	reply_port,		// task port or other
	int	data_tag,		// tag associated with request
        int     chan,			// dsp transfer channel
        int     msgID);			// type of msg	    

extern mach_msg_header_t *_DSP_simple_request_msg (
        mach_port_t	cmd_port,
        mach_port_t	reply_port,
        int messageType);				       

extern void _DSP_free_simple_request_msg(mach_msg_header_t **msg);

#endif

#import "_DSPMachAccessMacros.h"

/* FIXME: Eventually, 386 version should not include any of the below. */

#import "_MachMessages.h"

// #ifndef u_int
// #define u_int unsigned int
// #endif

mach_msg_header_t *_DSP_stream_msg (
	mach_msg_header_t *msg,		// message pointer to reuse or malloc
	mach_port_t	stream_port,		// valid stream port
	mach_port_t	reply_port,		// task port or other
	int	data_tag);		// tag associated with request
mach_msg_header_t *_DSP_stream_play_data (
	mach_msg_header_t	*msg,		// message frame to add request to
	pointer_t	data,		// data to play
	boolean_t	started_msg,	// want's a message when started
	boolean_t	completed_msg,	// want's a message when completed
	boolean_t	aborted_msg,	// want's a message when aborted
	boolean_t	paused_msg,	// want's a message when paused
	boolean_t	resumed_msg,	// want's a message when resumed
	boolean_t	underflow_msg,	// want's a message on underflow
	boolean_t	preempt,	// play preemptively
	boolean_t	deallocate,	// deallocate data when sent?
	mach_port_t		reg_port,	// port for region events
	int		nbytes);	// number of bytes of data to send
mach_msg_header_t *_DSP_stream_record_data (
	mach_msg_header_t	*msg,		// message frame to add request to
	boolean_t	started_msg,	// want's a message when started
	boolean_t	completed_msg,	// want's a message when completed
	boolean_t	aborted_msg,	// want's a message when aborted
	boolean_t	paused_msg,	// want's a message when paused
	boolean_t	resumed_msg,	// want's a message when resumed
	boolean_t	overflow_msg,	// want's a message on overflow
	int		nbytes,		// number of bytes of data to record
	mach_port_t		reg_port,	// port for region events
	char		*filename);	// file for backing store (or null)
mach_msg_header_t *_DSP_stream_control (
	mach_msg_header_t	*msg,		// message frame to add request to
	int		control);	// await/abort/pause/resume
kern_return_t _DSP_stream_nsamples (
	mach_port_t		stream_port,	// valid stream port
	int		*nsamples);	// OUT number of samples played/rec'd
kern_return_t _DSP_get_stream (
	mach_port_t		device_port,	// valid device port
	mach_port_t		owner_port,	// valid soundout/in/dsp owner port
	mach_port_t		*stream_port,	// returned stream_port
	u_int		stream);	// stream to/from what?
kern_return_t _DSP_set_dsp_owner_port (
	mach_port_t		device_port,	// valid device port
	mach_port_t		owner_port,	// dsp owner port
	mach_port_t		*neg_port);	// dsp negotiation port
kern_return_t _DSP_set_sndin_owner_port (
	mach_port_t		device_port,	// valid device port
	mach_port_t		owner_port,	// sound in owner port
	mach_port_t		*neg_port);	// sound in negotiation port
kern_return_t _DSP_set_sndout_owner_port (
	mach_port_t		device_port,	// valid device port
	mach_port_t		owner_port,	// sound out owner port
	mach_port_t		*neg_port);	// sound out negotiation port
kern_return_t _DSP_get_dsp_cmd_port (
	mach_port_t		device_port,	// valid device port
	mach_port_t		owner_port,	// valid dsp owner port
	mach_port_t		*cmd_port);	// returned cmd_port
kern_return_t _DSP_dsp_proto (
	mach_port_t		device_port,	// valid device port
	mach_port_t		owner_port,	// valid dsp owner port
	int		proto);		// what protocol to use.	
kern_return_t _DSP_dspcmd_event (
	mach_port_t		cmd_port,	// valid dsp command port
	u_int		mask,		// mask of flags to inspect
	u_int		flags,		// set of flags that must be on
	mach_msg_header_t	*msg);		// message to send (simple only)
kern_return_t _DSP_dspcmd_chandata (
	mach_port_t		cmd_port,	// valid dsp command port
	int		addr,		// .. of dsp buffer
	int		size,		// .. of dsp buffer
	int		skip,		// dma skip factor
	int		space,		// dsp space of buffer
	int		mode,		// mode of dma [1..5]
	int		chan);		// channel for dma
kern_return_t _DSP_dspcmd_dmaout (
	mach_port_t		cmd_port,	// valid dsp command port
	int		addr,		// .. in dsp
	int		size,		// # dsp words to transfer
	int		skip,		// dma skip factor
	int		space,		// dsp space of buffer
	int		mode,		// mode of dma [1..5]
	pointer_t	data);		// data to output
kern_return_t _DSP_dspcmd_dmain (
	mach_port_t		cmd_port,	// valid dsp command port
	int		addr,		// .. of dsp buffer
	int		size,		// .. of dsp buffer
	int		skip,		// dma skip factor
	int		space,		// dsp space of buffer
	int		mode,		// mode of dma [1..5]
	pointer_t	*data);		// where data is put
kern_return_t _DSP_dspcmd_abortdma (
	mach_port_t		cmd_port,	// valid dsp command port
	int		*dma_state,	// returned dma state
	vm_address_t	*start,		// returned dma start address
	vm_address_t	*stop,		// returned dma stop address
	vm_address_t	*next);		// returned dma next address
kern_return_t _DSP_dspcmd_req_msg (
	mach_port_t		cmd_port,	// valid dsp command port
	mach_port_t		reply_port);	// where to recieve messages
kern_return_t _DSP_dspcmd_req_err (
	mach_port_t		cmd_port,	// valid dsp command port
	mach_port_t		reply_port);	// where to recieve messages
void _DSP_dspcmd_msg_data (
	snd_dsp_msg_t	*msg,		// message containing returned data
	int		**buf_addr,	// INOUT address of returned data
	int		*buf_size);	// INOUT # ints returned

mach_msg_header_t *_DSP_dspcmd_msg (
	mach_port_t	cmd_port,		// valid dsp command port
	mach_port_t	reply_port,		// where to send reply message(s)
	int	priority,		// DSP_MSG_{LOW,MED,HIGH}
	int	atomic);		// message may not be preempted

void _DSP_free_dspcmd_msg(mach_msg_header_t **msg);

mach_msg_header_t *_DSP_dspcmd_msg_reset (
	mach_msg_header_t *msg,		// Existing message header
	mach_port_t	cmd_port,		// valid dsp command port
	mach_port_t	reply_port,		// where to send reply message(s)
	int	priority,		// DSP_MSG_{LOW,MED,HIGH}
	int	atomic);		// message may not be preempted

mach_msg_header_t *_DSP_dsprcv_msg (
	mach_port_t	cmd_port,		// valid dsp command port
	mach_port_t	reply_port);		// where to send reply message(s)

mach_msg_header_t *_DSP_dsprcv_msg_reset (
	mach_msg_header_t *msg,		// message frame to reset
	mach_port_t cmd_port,		// valid dsp command port
	mach_port_t reply_port);		// where to send reply message(s)

mach_msg_header_t *_DSP_dspreply_msg (
	mach_port_t	reply_port);		// where to send reply message

mach_msg_header_t *_DSP_dspreply_msg_reset (
	mach_msg_header_t *msg,		// Existing message header
	mach_port_t	reply_port);		// where to send reply message

mach_msg_header_t *_DSP_dsp_condition (
	mach_msg_header_t	*msg,		// message frame to add request to
	u_int		mask,		// mask of flags to inspect
	u_int		flags);		// set of flags that must be on
mach_msg_header_t *_DSP_dsp_data (
	mach_msg_header_t	*msg,		// message frame to add request to
	pointer_t	data,		// data to play
	int		eltsize,	// 1, 2, or 4 byte data
	int		nelts);		// number of elements of data to send
mach_msg_header_t *_DSP_dsp_host_command (
	mach_msg_header_t	*msg,		// message frame to add request to
	u_int		host_command);	// host command to execute
mach_msg_header_t *_DSP_dsp_host_flag (
	mach_msg_header_t	*msg,		// message frame to add request to
	u_int		mask,		// mask of flags to inspect
	u_int		flags);		// set of flags that must be on
mach_msg_header_t *_DSP_dsp_ret_msg (
	mach_msg_header_t	*msg,		// message frame to add request to
	mach_msg_header_t	*ret_msg);	// message to sent to reply port
mach_msg_header_t *_DSP_dspreset (
	mach_msg_header_t	*msg);		// message frame to add request to
mach_msg_header_t *_DSP_dspregs (
	mach_msg_header_t	*msg);		// message frame to add request to
mach_msg_header_t *_DSP_stream_options (
	mach_msg_header_t	*msg,		// message frame to add request to
	int		high_water,
	int		low_water,
	int		dma_size);
mach_msg_header_t *_DSP_dsp_protocol (
	mach_msg_header_t	*msg,		// message frame to add request to
	mach_port_t		device_port,	// valid device port
	mach_port_t		owner_port,	// port registered as owner
	int		protocol);	// protocol bits
mach_msg_header_t *_DSP_dsp_read_data(
	mach_msg_header_t *msg, 		// message frame
	int eltsize,			// 1, 2, 3, or 4 byte data
	int nelts); 			// number of data elements

#endif
