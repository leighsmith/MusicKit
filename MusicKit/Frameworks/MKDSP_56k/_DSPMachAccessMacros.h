/* $Id$
 * This file contains macros intended to hide the differences between the
 * m68k and i386 Mach message structures 
 */

/************************ 68k macros **********************/
#if m68k

/* snd_recorded_data_t */
#define _DSP_DATA_MSG_DATA(_msg) \
  ((vm_address_t)((snd_recorded_data_t *)_msg)->recorded_data)

#define _DSP_DATA_MSG_COUNT(_msg) \
  ((vm_size_t)((snd_recorded_data_t *)_msg)->dataType.msg_type_long_number)

#define _DSP_DATA_MSG_DATA_SIZE(_msg) _DSP_DATA_MSG_COUNT(_msg)

#define _DSP_DATA_MSG_SIZE MSG_SIZE_MAX

#define _DSP_STREAM_MSG(_oldMsg,_port,_threadReply,_tag,_chan,_msgID) \
  _DSP_stream_msg(_oldMsg,_port,_threadReply,_tag)

/* snd_dsp_msg_t */
/* Errors */
#define _DSP_ERROR_MSG_COUNT(_msg) \
  ((snd_dsp_msg_t *)_msg)->dataType.msg_type_long_number

#define _DSP_ERROR_MSG(_msg,_index) \
  ((snd_dsp_msg_t *)_msg)->data[_index] 

#define _DSP_ALLOC_ERROR_MSG(_cmd_port,_reply_port) \
  _DSP_dsprcv_msg(_cmd_port,_reply_port)

#define _DSP_FREE_ERROR_MSG(_msg) _DSP_free_dspcmd_msg(_msg)

/* DSP msgs */
#define _DSP_DSPMSG_MSG_COUNT(_msg) \
  ((snd_dsp_msg_t *)_msg)->dataType.msg_type_long_number

#define _DSP_DSPMSG_MSG(_msg,_index) \
  ((snd_dsp_msg_t *)_msg)->data[_index] 

#define _DSP_ALLOC_DSPMSG_MSG(_cmd_port,_reply_port) \
  _DSP_dsprcv_msg(_cmd_port,_reply_port)

#define _DSP_FREE_DSPMSG_MSG(_msg) _DSP_free_dspcmd_msg(_msg)

#define _DSP_DSPRCV_MSG_RESET(_msg,_hmPort,_rcvPort) \
	_DSP_dsprcv_msg_reset(_msg,_hmPort,_rcvPort)

#endif

/************************ Intel macros **********************/
#if !m68k && defined(NeXT)

/* DSPDRIVERDataMessage */
#define _DSP_DATA_MSG_DATA(_msg) \
  ((vm_address_t)((DSPDRIVERDataMessage *)_msg)->data)

#define _DSP_DATA_MSG_COUNT(_msg) \
  ((vm_size_t)((DSPDRIVERDataMessage *)_msg)->nbytes)

#define _DSP_DATA_MSG_DATA_SIZE(_msg) _DSP_DATA_MSG_COUNT(_msg)

#define _DSP_DATA_MSG_SIZE sizeof(DSPDRIVERDataMessage)

#define MSGSIZ sizeof(DSPDRIVERDataMessage) /* MSG_SIZE_MAX? */
#define _DSP_STREAM_MSG(_oldMsg,_port,_threadReply,_tag,_chan,_msgID) \
   _DSP_data_request_msg(_oldMsg,_port,_threadReply,_tag,_chan,_msgID)

/* DSPDRIVERSimpleMessage */
/* Errors */
#define _DSP_ERROR_MSG_COUNT(_msg) 1 /* No count supported on Intel */

#define _DSP_ERROR_MSG(_msg,_index) \
  ((DSPDRIVERSimpleMessage *)_msg)->regionTag 

#define _DSP_ALLOC_ERROR_MSG(_cmd_port,_reply_port) \
  _DSP_simple_request_msg(_cmd_port,_reply_port,DSPDRIVER_MSG_RET_DSP_ERR)

#define _DSP_FREE_ERROR_MSG(_msg) _DSP_free_simple_request_msg(_msg)

/* DSP Msgs */
#define _DSP_DSPMSG_MSG_COUNT(_msg) 1 /* No count supported on Intel */

#define _DSP_DSPMSG_MSG(_msg,_index) \
  ((DSPDRIVERSimpleMessage *)_msg)->regionTag 

#define _DSP_ALLOC_DSPMSG_MSG(_cmd_port,_reply_port) \
  _DSP_simple_request_msg(_cmd_port,_reply_port,DSPDRIVER_MSG_RET_DSP_ERR)

#define _DSP_FREE_DSPMSG_MSG(_msg) _DSP_free_simple_request_msg(_msg)

#define _DSP_DSPRCV_MSG_RESET(_msg,_hmPort,_rcvPort) \
	_msg->msg_size = sizeof(DSPDRIVERSimpleMessage); \
	_msg->msg_local_port = _rcvPort

#endif

/* LMS - currently just a duplicate of intel with routines commented out*/
/************************ PPC macros **********************/
#if ppc

/* DSPDRIVERDataMessage */
#define _DSP_DATA_MSG_DATA(_msg) \
  ((vm_address_t)((DSPDRIVERDataMessage *)_msg)->data)

#define _DSP_DATA_MSG_COUNT(_msg) \
  ((vm_size_t)((DSPDRIVERDataMessage *)_msg)->nbytes)

#define _DSP_DATA_MSG_DATA_SIZE(_msg) _DSP_DATA_MSG_COUNT(_msg)

#define _DSP_DATA_MSG_SIZE sizeof(DSPDRIVERDataMessage)

#define MSGSIZ sizeof(DSPDRIVERDataMessage) /* MSG_SIZE_MAX? */
#define _DSP_STREAM_MSG(_oldMsg,_port,_threadReply,_tag,_chan,_msgID) \
   _DSP_data_request_msg(_oldMsg,_port,_threadReply,_tag,_chan,_msgID)

/* DSPDRIVERSimpleMessage */
/* Errors */
#define _DSP_ERROR_MSG_COUNT(_msg) 1 /* No count supported on Intel */

#define _DSP_ERROR_MSG(_msg,_index) \
  ((DSPDRIVERSimpleMessage *)_msg)->regionTag 

#define _DSP_ALLOC_ERROR_MSG(_cmd_port,_reply_port) \
  _DSP_simple_request_msg(_cmd_port,_reply_port,DSPDRIVER_MSG_RET_DSP_ERR)

#define _DSP_FREE_ERROR_MSG(_msg)  _DSP_free_simple_request_msg(_msg)

/* DSP Msgs */
#define _DSP_DSPMSG_MSG_COUNT(_msg) 1 /* No count supported on Intel */

#define _DSP_DSPMSG_MSG(_msg,_index) \
  ((DSPDRIVERSimpleMessage *)_msg)->regionTag 

#define _DSP_ALLOC_DSPMSG_MSG(_cmd_port,_reply_port) \
   _DSP_simple_request_msg(_cmd_port,_reply_port,DSPDRIVER_MSG_RET_DSP_ERR)

#define _DSP_FREE_DSPMSG_MSG(_msg) _DSP_free_simple_request_msg(_msg)

#define _DSP_DSPRCV_MSG_RESET(_msg,_hmPort,_rcvPort) \
	_msg->msg_size = sizeof(DSPDRIVERSimpleMessage); \
	_msg->msg_local_port = _rcvPort

#endif

/* LMS - currently just a duplicate of intel with routines commented out*/
/************************ WIN32 macros **********************/
#if WIN32

/* DSPDRIVERDataMessage */
#define _DSP_DATA_MSG_DATA(_msg) \
  ((vm_address_t)((DSPDRIVERDataMessage *)_msg)->data)

#define _DSP_DATA_MSG_COUNT(_msg) \
  ((vm_size_t)((DSPDRIVERDataMessage *)_msg)->nbytes)

#define _DSP_DATA_MSG_DATA_SIZE(_msg) _DSP_DATA_MSG_COUNT(_msg)

#define _DSP_DATA_MSG_SIZE sizeof(DSPDRIVERDataMessage)

#define MSGSIZ sizeof(DSPDRIVERDataMessage) /* MSG_SIZE_MAX? */
#define _DSP_STREAM_MSG(_oldMsg,_port,_threadReply,_tag,_chan,_msgID) \
   _DSP_data_request_msg(_oldMsg,_port,_threadReply,_tag,_chan,_msgID)

/* DSPDRIVERSimpleMessage */
/* Errors */
#define _DSP_ERROR_MSG_COUNT(_msg) 1 /* No count supported on Intel */

#define _DSP_ERROR_MSG(_msg,_index) \
  ((DSPDRIVERSimpleMessage *)_msg)->regionTag

#define _DSP_ALLOC_ERROR_MSG(_cmd_port,_reply_port) \
  _DSP_simple_request_msg(_cmd_port,_reply_port,DSPDRIVER_MSG_RET_DSP_ERR)

#define _DSP_FREE_ERROR_MSG(_msg)  _DSP_free_simple_request_msg(_msg)

/* DSP Msgs */
#define _DSP_DSPMSG_MSG_COUNT(_msg) 1 /* No count supported on Intel */

#define _DSP_DSPMSG_MSG(_msg,_index) \
  ((DSPDRIVERSimpleMessage *)_msg)->regionTag

#define _DSP_ALLOC_DSPMSG_MSG(_cmd_port,_reply_port) \
   _DSP_simple_request_msg(_cmd_port,_reply_port,DSPDRIVER_MSG_RET_DSP_ERR)

#define _DSP_FREE_DSPMSG_MSG(_msg) _DSP_free_simple_request_msg(_msg)

#define _DSP_DSPRCV_MSG_RESET(_msg,_hmPort,_rcvPort) \
        _msg->msg_size = sizeof(DSPDRIVERSimpleMessage); \
        _msg->msg_local_port = _rcvPort

#endif
