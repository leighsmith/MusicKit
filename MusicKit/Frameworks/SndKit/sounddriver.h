/*
 *	sounddriver.h - functional sound/dsp driver interface.
 *	Copyright 1988-90 NeXT, Inc.
 *
 */

#import <mach/mach.h>
#import <mach/mach_init.h>
#import <mach/message.h>
#import <bsd/sys/types.h>

/*
 * Valid sources and destination codes for stream setup
 */

#define SNDDRIVER_STREAM_FROM_SNDIN			(1)
#define SNDDRIVER_STREAM_TO_SNDOUT_22			(2)
#define SNDDRIVER_STREAM_TO_SNDOUT_44			(3)
#define SNDDRIVER_STREAM_FROM_DSP			(4)
#define SNDDRIVER_STREAM_TO_DSP				(5)
#define SNDDRIVER_STREAM_SNDIN_TO_DSP			(6)
#define SNDDRIVER_STREAM_DSP_TO_SNDOUT_22		(7)
#define SNDDRIVER_STREAM_DSP_TO_SNDOUT_44		(8)
#define SNDDRIVER_STREAM_FROM_SNDIN_THROUGH_DSP		(9)
#define SNDDRIVER_STREAM_THROUGH_DSP_TO_SNDOUT_22	(10)
#define SNDDRIVER_STREAM_THROUGH_DSP_TO_SNDOUT_44	(11)
/* New for 2.0 */
#define SNDDRIVER_DMA_STREAM_TO_DSP			(12)
#define SNDDRIVER_DMA_STREAM_FROM_DSP			(13)
#define SNDDRIVER_DMA_STREAM_THROUGH_DSP_TO_SNDOUT_22	(14)
#define SNDDRIVER_DMA_STREAM_THROUGH_DSP_TO_SNDOUT_44	(15)
/* Reserved for private sound library use */
#define SNDDRIVER_STREAM_RESERVED_1			(16)
#define SNDDRIVER_STREAM_RESERVED_2			(17)

/*
 * Protocol options for the dsp (subset of <nextdev/snd_msgs.h> protocols)
 */
#define SNDDRIVER_DSP_PROTO_DSPERR	0x1	// DSP error messages enabled
#define SNDDRIVER_DSP_PROTO_C_DMA	0x2	// Complex DMA mode
#define SNDDRIVER_DSP_PROTO_S_DMA	0x4	// Simple DMA mode
/* New for 2.0 */
#define SNDDRIVER_DSP_PROTO_HFABORT	0x80	// Enable DSP abort on HF2&HF3
#define SNDDRIVER_DSP_PROTO_DSPMSG	0x100	// DSP messages enabled
#define SNDDRIVER_DSP_PROTO_RAW 	0x200	// Enable raw DSP mode

/*
 * DSP Host Commands used with protocol SNDDRIVER_DSP_PROTO_C_DMA.
 * See on-line programming examples for usage.
 */
#define SNDDRIVER_DSP_HC_HOST_RD	(0x24>>1) 	// Host Read Done
#define SNDDRIVER_DSP_HC_HOST_WD	(0x28>>1)	// Host Write Done
#define SNDDRIVER_DSP_HC_SYS_CALL	(0x2C>>1)	// System Call

/*
 * Control codes for streams
 */
#define SNDDRIVER_AWAIT_STREAM		(0x1)
#define SNDDRIVER_ABORT_STREAM		(0x2)
#define SNDDRIVER_PAUSE_STREAM		(0x4)
#define SNDDRIVER_RESUME_STREAM		(0x8)

/*
 * Driver message priorities
 */
#define SNDDRIVER_LOW_PRIORITY		(2)
#define SNDDRIVER_MED_PRIORITY		(1)
#define SNDDRIVER_HIGH_PRIORITY		(0)

/*
 * DSP Host Interface Bits
 */
#define SNDDRIVER_ICR_INIT      (0x80000000)    // settable
#define SNDDRIVER_ICR_HM1       (0x40000000)    // settable mode bit
#define SNDDRIVER_ICR_HM0       (0x20000000)    // settable mode bit
#define SNDDRIVER_ICR_HF1       (0x10000000)    // settable host flag
#define SNDDRIVER_ICR_HF0       (0x08000000)    // settable host flag
#define SNDDRIVER_ICR_TREQ      (0x02000000)    // read-only, set by protocol
#define SNDDRIVER_ICR_RREQ      (0x01000000)    // read-only, set by protocol

#define SNDDRIVER_CVR_HC        (0x00800000)    // read-only, set by host cmd
#define SNDDRIVER_CVR_HV_MASK   (0x001F0000)    // read-only, set by host cmd

#define SNDDRIVER_ISR_HREQ      (0x00008000)    // readable host request flag
#define SNDDRIVER_ISR_DMA       (0x00004000)    // readable dma-mode flag
#define SNDDRIVER_ISR_HF3       (0x00001000)    // readable host flag
#define SNDDRIVER_ISR_HF2       (0x00000800)    // readable host flag
#define SNDDRIVER_ISR_TRDY      (0x00000400)    // readable status bit
#define SNDDRIVER_ISR_TXDE      (0x00000200)    // readable status bit
#define SNDDRIVER_ISR_RXDF      (0x00000100)    // readable status bit


#include "snddriver_client.h"

/*
 * Asynchronous return message parsing and callout (the reply server).
 *
 * The snddriver_reply_server implementation takes a pointer to a message 
 * and a pointer to a structure containing the dispatch functions for
 * each type of message. It parses the message and calls the
 * appropriate procedure, and handles the reply message (if any).
 */

typedef void (*sndreply_tagged_t)(void *arg, int tag);
typedef void (*sndreply_recorded_data_t)(void *arg, int tag, 
					 void *data, int size);
typedef void (*sndreply_dsp_cond_true_t)(void *arg, u_int mask, 
					 u_int flags, u_int regs);
typedef void (*sndreply_dsp_msg_t)(void *arg, int *data, int size);

typedef struct snddriver_handlers {
    void *			arg;
    int				timeout;
    sndreply_tagged_t		started;
    sndreply_tagged_t		completed;
    sndreply_tagged_t		aborted;
    sndreply_tagged_t		paused;
    sndreply_tagged_t		resumed;
    sndreply_tagged_t		overflow;
    sndreply_recorded_data_t	recorded_data;
    sndreply_dsp_cond_true_t	condition_true;
    sndreply_dsp_msg_t		dsp_message;
    sndreply_dsp_msg_t		dsp_error;
 } snddriver_handlers_t;

kern_return_t snddriver_reply_handler(
	msg_header_t		*msg,		// message to parse
	snddriver_handlers_t	*handlers);	// table of callout procs
