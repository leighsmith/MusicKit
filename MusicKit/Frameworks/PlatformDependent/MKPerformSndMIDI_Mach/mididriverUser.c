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
  Revision 1.3  2000/11/29 23:21:27  leigh
  Renamed MD functions to MKMD

  Revision 1.2  2000/01/27 18:15:43  leigh
  upgraded to new typedef names for Mach

  Revision 1.1.1.1  1999/09/12 00:20:18  leigh
  separated out from MusicKit framework

  Revision 1.2  1999/07/29 01:26:07  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#include "mididriver.h"
#include <mach/mach_types.h>
#include <mach/message.h>
#include <mach/mig_errors.h>
#include <mach/msg_type.h>
#if	!defined(KERNEL) && !defined(MIG_NO_STRINGS)
#include <string.h>
#endif
/* LINTLIBRARY */

extern mach_port_t mig_get_reply_port();
extern void mig_dealloc_reply_port();

#ifndef	mig_internal
#define	mig_internal	static
#endif

#ifndef	TypeCheck
#define	TypeCheck 1
#endif

#ifndef	UseExternRCSId
#ifdef	hc
#define	UseExternRCSId		1
#endif
#endif

#ifndef	UseStaticMsgType
#if	!defined(hc) || defined(__STDC__)
#define	UseStaticMsgType	1
#endif
#endif

#define msg_request_port	msg_remote_port
#define msg_reply_port		msg_local_port


/* Routine MKMDBecomeOwner */
MKMKMD
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		mach_port_t owner_port;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	union {
		Request In;
		Reply Out;
	} Mess;

	register Request *InP = &Mess.In;
	register Reply *OutP = &Mess.Out;

	msg_return_t msg_result;

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size = 32;

#if	UseStaticMsgType
	static const msg_type_t owner_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t RetCodeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	InP->owner_portType = owner_portType;
#else	UseStaticMsgType
	InP->owner_portType.msg_type_name = MSG_TYPE_PORT;
	InP->owner_portType.msg_type_size = 32;
	InP->owner_portType.msg_type_number = 1;
	InP->owner_portType.msg_type_inline = TRUE;
	InP->owner_portType.msg_type_longform = FALSE;
	InP->owner_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->owner_port /* owner_port */ = /* owner_port */ owner_port;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = mididriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 400;

	msg_result = msg_rpc(&InP->Head, RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 0, 5000);
	if (msg_result != RPC_SUCCESS) {
		if ((msg_result == RCV_INVALID_PORT) ||
		    (msg_result == RCV_TIMED_OUT))
			mig_dealloc_reply_port();
		return msg_result;
	}

#if	TypeCheck
	msg_size = OutP->Head.msg_size;
	msg_simple = OutP->Head.msg_simple;
#endif	TypeCheck

	if (OutP->Head.msg_id != 500)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size != 32) || (msg_simple != TRUE)) &&
	    ((msg_size != sizeof(death_pill_t)) ||
	     (msg_simple != TRUE) ||
	     (OutP->RetCode == KERN_SUCCESS)))
		return MIG_TYPE_ERROR;
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->RetCodeType != * (int *) &RetCodeCheck)
#else	UseStaticMsgType
	if ((OutP->RetCodeType.msg_type_inline != TRUE) ||
	    (OutP->RetCodeType.msg_type_longform != FALSE) ||
	    (OutP->RetCodeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->RetCodeType.msg_type_number != 1) ||
	    (OutP->RetCodeType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	if (OutP->RetCode != KERN_SUCCESS)
		return OutP->RetCode;

	return OutP->RetCode;
}

/* Routine MKMDReleaseOwnership */
mig_external kern_return_t MKMDReleaseOwnership (
	mach_port_t mididriver_port,
	mach_port_t owner_port)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		mach_port_t owner_port;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	union {
		Request In;
		Reply Out;
	} Mess;

	register Request *InP = &Mess.In;
	register Reply *OutP = &Mess.Out;

	msg_return_t msg_result;

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size = 32;

#if	UseStaticMsgType
	static const msg_type_t owner_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t RetCodeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	InP->owner_portType = owner_portType;
#else	UseStaticMsgType
	InP->owner_portType.msg_type_name = MSG_TYPE_PORT;
	InP->owner_portType.msg_type_size = 32;
	InP->owner_portType.msg_type_number = 1;
	InP->owner_portType.msg_type_inline = TRUE;
	InP->owner_portType.msg_type_longform = FALSE;
	InP->owner_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->owner_port /* owner_port */ = /* owner_port */ owner_port;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = mididriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 401;

	msg_result = msg_rpc(&InP->Head, RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 0, 5000);
	if (msg_result != RPC_SUCCESS) {
		if ((msg_result == RCV_INVALID_PORT) ||
		    (msg_result == RCV_TIMED_OUT))
			mig_dealloc_reply_port();
		return msg_result;
	}

#if	TypeCheck
	msg_size = OutP->Head.msg_size;
	msg_simple = OutP->Head.msg_simple;
#endif	TypeCheck

	if (OutP->Head.msg_id != 501)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size != 32) || (msg_simple != TRUE)) &&
	    ((msg_size != sizeof(death_pill_t)) ||
	     (msg_simple != TRUE) ||
	     (OutP->RetCode == KERN_SUCCESS)))
		return MIG_TYPE_ERROR;
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->RetCodeType != * (int *) &RetCodeCheck)
#else	UseStaticMsgType
	if ((OutP->RetCodeType.msg_type_inline != TRUE) ||
	    (OutP->RetCodeType.msg_type_longform != FALSE) ||
	    (OutP->RetCodeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->RetCodeType.msg_type_number != 1) ||
	    (OutP->RetCodeType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	if (OutP->RetCode != KERN_SUCCESS)
		return OutP->RetCode;

	return OutP->RetCode;
}

/* Routine MKMDSetClockMode */
mig_external kern_return_t MKMDSetClockMode (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit,
	int clock_mode)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		mach_port_t owner_port;
		msg_type_t unitType;
		short unit;
		char unitPad[2];
		msg_type_t clock_modeType;
		int clock_mode;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	union {
		Request In;
		Reply Out;
	} Mess;

	register Request *InP = &Mess.In;
	register Reply *OutP = &Mess.Out;

	msg_return_t msg_result;

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size = 48;

#if	UseStaticMsgType
	static const msg_type_t owner_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_16,
		/* msg_type_size = */		16,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t clock_modeType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t RetCodeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	InP->owner_portType = owner_portType;
#else	UseStaticMsgType
	InP->owner_portType.msg_type_name = MSG_TYPE_PORT;
	InP->owner_portType.msg_type_size = 32;
	InP->owner_portType.msg_type_number = 1;
	InP->owner_portType.msg_type_inline = TRUE;
	InP->owner_portType.msg_type_longform = FALSE;
	InP->owner_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->owner_port /* owner_port */ = /* owner_port */ owner_port;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_16;
	InP->unitType.msg_type_size = 16;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

#if	UseStaticMsgType
	InP->clock_modeType = clock_modeType;
#else	UseStaticMsgType
	InP->clock_modeType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->clock_modeType.msg_type_size = 32;
	InP->clock_modeType.msg_type_number = 1;
	InP->clock_modeType.msg_type_inline = TRUE;
	InP->clock_modeType.msg_type_longform = FALSE;
	InP->clock_modeType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->clock_mode /* clock_mode */ = /* clock_mode */ clock_mode;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = mididriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 402;

	msg_result = msg_rpc(&InP->Head, RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 0, 5000);
	if (msg_result != RPC_SUCCESS) {
		if ((msg_result == RCV_INVALID_PORT) ||
		    (msg_result == RCV_TIMED_OUT))
			mig_dealloc_reply_port();
		return msg_result;
	}

#if	TypeCheck
	msg_size = OutP->Head.msg_size;
	msg_simple = OutP->Head.msg_simple;
#endif	TypeCheck

	if (OutP->Head.msg_id != 502)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size != 32) || (msg_simple != TRUE)) &&
	    ((msg_size != sizeof(death_pill_t)) ||
	     (msg_simple != TRUE) ||
	     (OutP->RetCode == KERN_SUCCESS)))
		return MIG_TYPE_ERROR;
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->RetCodeType != * (int *) &RetCodeCheck)
#else	UseStaticMsgType
	if ((OutP->RetCodeType.msg_type_inline != TRUE) ||
	    (OutP->RetCodeType.msg_type_longform != FALSE) ||
	    (OutP->RetCodeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->RetCodeType.msg_type_number != 1) ||
	    (OutP->RetCodeType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	if (OutP->RetCode != KERN_SUCCESS)
		return OutP->RetCode;

	return OutP->RetCode;
}

/* Routine MKMDGetClockTime */
mig_external kern_return_t MKMDGetClockTime (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	int *time)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		mach_port_t owner_port;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
		msg_type_t timeType;
		int time;
	} Reply;

	union {
		Request In;
		Reply Out;
	} Mess;

	register Request *InP = &Mess.In;
	register Reply *OutP = &Mess.Out;

	msg_return_t msg_result;

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size = 32;

#if	UseStaticMsgType
	static const msg_type_t owner_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t RetCodeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t timeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	InP->owner_portType = owner_portType;
#else	UseStaticMsgType
	InP->owner_portType.msg_type_name = MSG_TYPE_PORT;
	InP->owner_portType.msg_type_size = 32;
	InP->owner_portType.msg_type_number = 1;
	InP->owner_portType.msg_type_inline = TRUE;
	InP->owner_portType.msg_type_longform = FALSE;
	InP->owner_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->owner_port /* owner_port */ = /* owner_port */ owner_port;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = mididriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 403;

	msg_result = msg_rpc(&InP->Head, RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 0, 5000);
	if (msg_result != RPC_SUCCESS) {
		if ((msg_result == RCV_INVALID_PORT) ||
		    (msg_result == RCV_TIMED_OUT))
			mig_dealloc_reply_port();
		return msg_result;
	}

#if	TypeCheck
	msg_size = OutP->Head.msg_size;
	msg_simple = OutP->Head.msg_simple;
#endif	TypeCheck

	if (OutP->Head.msg_id != 503)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size != 40) || (msg_simple != TRUE)) &&
	    ((msg_size != sizeof(death_pill_t)) ||
	     (msg_simple != TRUE) ||
	     (OutP->RetCode == KERN_SUCCESS)))
		return MIG_TYPE_ERROR;
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->RetCodeType != * (int *) &RetCodeCheck)
#else	UseStaticMsgType
	if ((OutP->RetCodeType.msg_type_inline != TRUE) ||
	    (OutP->RetCodeType.msg_type_longform != FALSE) ||
	    (OutP->RetCodeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->RetCodeType.msg_type_number != 1) ||
	    (OutP->RetCodeType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	if (OutP->RetCode != KERN_SUCCESS)
		return OutP->RetCode;

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->timeType != * (int *) &timeCheck)
#else	UseStaticMsgType
	if ((OutP->timeType.msg_type_inline != TRUE) ||
	    (OutP->timeType.msg_type_longform != FALSE) ||
	    (OutP->timeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->timeType.msg_type_number != 1) ||
	    (OutP->timeType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	*time /* time */ = /* *time */ OutP->time;

	return OutP->RetCode;
}

/* Routine MKMDGetMTCTime */
mig_external kern_return_t MKMDGetMTCTime (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short *format,
	short *hours,
	short *minutes,
	short *seconds,
	short *frames)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		mach_port_t owner_port;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
		msg_type_t formatType;
		short format;
		char formatPad[2];
		msg_type_t hoursType;
		short hours;
		char hoursPad[2];
		msg_type_t minutesType;
		short minutes;
		char minutesPad[2];
		msg_type_t secondsType;
		short seconds;
		char secondsPad[2];
		msg_type_t framesType;
		short frames;
		char framesPad[2];
	} Reply;

	union {
		Request In;
		Reply Out;
	} Mess;

	register Request *InP = &Mess.In;
	register Reply *OutP = &Mess.Out;

	msg_return_t msg_result;

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size = 32;

#if	UseStaticMsgType
	static const msg_type_t owner_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t RetCodeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t formatCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_16,
		/* msg_type_size = */		16,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t hoursCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_16,
		/* msg_type_size = */		16,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t minutesCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_16,
		/* msg_type_size = */		16,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t secondsCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_16,
		/* msg_type_size = */		16,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t framesCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_16,
		/* msg_type_size = */		16,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	InP->owner_portType = owner_portType;
#else	UseStaticMsgType
	InP->owner_portType.msg_type_name = MSG_TYPE_PORT;
	InP->owner_portType.msg_type_size = 32;
	InP->owner_portType.msg_type_number = 1;
	InP->owner_portType.msg_type_inline = TRUE;
	InP->owner_portType.msg_type_longform = FALSE;
	InP->owner_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->owner_port /* owner_port */ = /* owner_port */ owner_port;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = mididriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 404;

	msg_result = msg_rpc(&InP->Head, RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 0, 5000);
	if (msg_result != RPC_SUCCESS) {
		if ((msg_result == RCV_INVALID_PORT) ||
		    (msg_result == RCV_TIMED_OUT))
			mig_dealloc_reply_port();
		return msg_result;
	}

#if	TypeCheck
	msg_size = OutP->Head.msg_size;
	msg_simple = OutP->Head.msg_simple;
#endif	TypeCheck

	if (OutP->Head.msg_id != 504)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size != 72) || (msg_simple != TRUE)) &&
	    ((msg_size != sizeof(death_pill_t)) ||
	     (msg_simple != TRUE) ||
	     (OutP->RetCode == KERN_SUCCESS)))
		return MIG_TYPE_ERROR;
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->RetCodeType != * (int *) &RetCodeCheck)
#else	UseStaticMsgType
	if ((OutP->RetCodeType.msg_type_inline != TRUE) ||
	    (OutP->RetCodeType.msg_type_longform != FALSE) ||
	    (OutP->RetCodeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->RetCodeType.msg_type_number != 1) ||
	    (OutP->RetCodeType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	if (OutP->RetCode != KERN_SUCCESS)
		return OutP->RetCode;

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->formatType != * (int *) &formatCheck)
#else	UseStaticMsgType
	if ((OutP->formatType.msg_type_inline != TRUE) ||
	    (OutP->formatType.msg_type_longform != FALSE) ||
	    (OutP->formatType.msg_type_name != MSG_TYPE_INTEGER_16) ||
	    (OutP->formatType.msg_type_number != 1) ||
	    (OutP->formatType.msg_type_size != 16))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	*format /* format */ = /* *format */ OutP->format;

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->hoursType != * (int *) &hoursCheck)
#else	UseStaticMsgType
	if ((OutP->hoursType.msg_type_inline != TRUE) ||
	    (OutP->hoursType.msg_type_longform != FALSE) ||
	    (OutP->hoursType.msg_type_name != MSG_TYPE_INTEGER_16) ||
	    (OutP->hoursType.msg_type_number != 1) ||
	    (OutP->hoursType.msg_type_size != 16))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	*hours /* hours */ = /* *hours */ OutP->hours;

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->minutesType != * (int *) &minutesCheck)
#else	UseStaticMsgType
	if ((OutP->minutesType.msg_type_inline != TRUE) ||
	    (OutP->minutesType.msg_type_longform != FALSE) ||
	    (OutP->minutesType.msg_type_name != MSG_TYPE_INTEGER_16) ||
	    (OutP->minutesType.msg_type_number != 1) ||
	    (OutP->minutesType.msg_type_size != 16))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	*minutes /* minutes */ = /* *minutes */ OutP->minutes;

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->secondsType != * (int *) &secondsCheck)
#else	UseStaticMsgType
	if ((OutP->secondsType.msg_type_inline != TRUE) ||
	    (OutP->secondsType.msg_type_longform != FALSE) ||
	    (OutP->secondsType.msg_type_name != MSG_TYPE_INTEGER_16) ||
	    (OutP->secondsType.msg_type_number != 1) ||
	    (OutP->secondsType.msg_type_size != 16))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	*seconds /* seconds */ = /* *seconds */ OutP->seconds;

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->framesType != * (int *) &framesCheck)
#else	UseStaticMsgType
	if ((OutP->framesType.msg_type_inline != TRUE) ||
	    (OutP->framesType.msg_type_longform != FALSE) ||
	    (OutP->framesType.msg_type_name != MSG_TYPE_INTEGER_16) ||
	    (OutP->framesType.msg_type_number != 1) ||
	    (OutP->framesType.msg_type_size != 16))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	*frames /* frames */ = /* *frames */ OutP->frames;

	return OutP->RetCode;
}

/* Routine MKMDSetClockTime */
mig_external kern_return_t MKMDSetClockTime (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	int time)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		mach_port_t owner_port;
		msg_type_t timeType;
		int time;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	union {
		Request In;
		Reply Out;
	} Mess;

	register Request *InP = &Mess.In;
	register Reply *OutP = &Mess.Out;

	msg_return_t msg_result;

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size = 40;

#if	UseStaticMsgType
	static const msg_type_t owner_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t timeType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t RetCodeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	InP->owner_portType = owner_portType;
#else	UseStaticMsgType
	InP->owner_portType.msg_type_name = MSG_TYPE_PORT;
	InP->owner_portType.msg_type_size = 32;
	InP->owner_portType.msg_type_number = 1;
	InP->owner_portType.msg_type_inline = TRUE;
	InP->owner_portType.msg_type_longform = FALSE;
	InP->owner_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->owner_port /* owner_port */ = /* owner_port */ owner_port;

#if	UseStaticMsgType
	InP->timeType = timeType;
#else	UseStaticMsgType
	InP->timeType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->timeType.msg_type_size = 32;
	InP->timeType.msg_type_number = 1;
	InP->timeType.msg_type_inline = TRUE;
	InP->timeType.msg_type_longform = FALSE;
	InP->timeType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->time /* time */ = /* time */ time;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = mididriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 405;

	msg_result = msg_rpc(&InP->Head, RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 0, 5000);
	if (msg_result != RPC_SUCCESS) {
		if ((msg_result == RCV_INVALID_PORT) ||
		    (msg_result == RCV_TIMED_OUT))
			mig_dealloc_reply_port();
		return msg_result;
	}

#if	TypeCheck
	msg_size = OutP->Head.msg_size;
	msg_simple = OutP->Head.msg_simple;
#endif	TypeCheck

	if (OutP->Head.msg_id != 505)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size != 32) || (msg_simple != TRUE)) &&
	    ((msg_size != sizeof(death_pill_t)) ||
	     (msg_simple != TRUE) ||
	     (OutP->RetCode == KERN_SUCCESS)))
		return MIG_TYPE_ERROR;
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->RetCodeType != * (int *) &RetCodeCheck)
#else	UseStaticMsgType
	if ((OutP->RetCodeType.msg_type_inline != TRUE) ||
	    (OutP->RetCodeType.msg_type_longform != FALSE) ||
	    (OutP->RetCodeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->RetCodeType.msg_type_number != 1) ||
	    (OutP->RetCodeType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	if (OutP->RetCode != KERN_SUCCESS)
		return OutP->RetCode;

	return OutP->RetCode;
}

/* SimpleRoutine MKMDRequestAlarm */
mig_external kern_return_t MKMDRequestAlarm (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	mach_port_t reply_port,
	int time)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		mach_port_t owner_port;
		msg_type_t reply_portType;
		mach_port_t reply_port;
		msg_type_t timeType;
		int time;
	} Request;

	union {
		Request In;
	} Mess;

	register Request *InP = &Mess.In;

	unsigned int msg_size = 48;

#if	UseStaticMsgType
	static const msg_type_t owner_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t reply_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t timeType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	InP->owner_portType = owner_portType;
#else	UseStaticMsgType
	InP->owner_portType.msg_type_name = MSG_TYPE_PORT;
	InP->owner_portType.msg_type_size = 32;
	InP->owner_portType.msg_type_number = 1;
	InP->owner_portType.msg_type_inline = TRUE;
	InP->owner_portType.msg_type_longform = FALSE;
	InP->owner_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->owner_port /* owner_port */ = /* owner_port */ owner_port;

#if	UseStaticMsgType
	InP->reply_portType = reply_portType;
#else	UseStaticMsgType
	InP->reply_portType.msg_type_name = MSG_TYPE_PORT;
	InP->reply_portType.msg_type_size = 32;
	InP->reply_portType.msg_type_number = 1;
	InP->reply_portType.msg_type_inline = TRUE;
	InP->reply_portType.msg_type_longform = FALSE;
	InP->reply_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->reply_port /* reply_port */ = /* reply_port */ reply_port;

#if	UseStaticMsgType
	InP->timeType = timeType;
#else	UseStaticMsgType
	InP->timeType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->timeType.msg_type_size = 32;
	InP->timeType.msg_type_number = 1;
	InP->timeType.msg_type_inline = TRUE;
	InP->timeType.msg_type_longform = FALSE;
	InP->timeType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->time /* time */ = /* time */ time;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = mididriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 406;

	return msg_send(&InP->Head, SEND_SWITCH, 0);
}

/* Routine MKMDStartClock */
mig_external kern_return_t MKMDStartClock (
	mach_port_t mididriver_port,
	mach_port_t owner_port)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		mach_port_t owner_port;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	union {
		Request In;
		Reply Out;
	} Mess;

	register Request *InP = &Mess.In;
	register Reply *OutP = &Mess.Out;

	msg_return_t msg_result;

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size = 32;

#if	UseStaticMsgType
	static const msg_type_t owner_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t RetCodeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	InP->owner_portType = owner_portType;
#else	UseStaticMsgType
	InP->owner_portType.msg_type_name = MSG_TYPE_PORT;
	InP->owner_portType.msg_type_size = 32;
	InP->owner_portType.msg_type_number = 1;
	InP->owner_portType.msg_type_inline = TRUE;
	InP->owner_portType.msg_type_longform = FALSE;
	InP->owner_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->owner_port /* owner_port */ = /* owner_port */ owner_port;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = mididriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 407;

	msg_result = msg_rpc(&InP->Head, RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 0, 5000);
	if (msg_result != RPC_SUCCESS) {
		if ((msg_result == RCV_INVALID_PORT) ||
		    (msg_result == RCV_TIMED_OUT))
			mig_dealloc_reply_port();
		return msg_result;
	}

#if	TypeCheck
	msg_size = OutP->Head.msg_size;
	msg_simple = OutP->Head.msg_simple;
#endif	TypeCheck

	if (OutP->Head.msg_id != 507)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size != 32) || (msg_simple != TRUE)) &&
	    ((msg_size != sizeof(death_pill_t)) ||
	     (msg_simple != TRUE) ||
	     (OutP->RetCode == KERN_SUCCESS)))
		return MIG_TYPE_ERROR;
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->RetCodeType != * (int *) &RetCodeCheck)
#else	UseStaticMsgType
	if ((OutP->RetCodeType.msg_type_inline != TRUE) ||
	    (OutP->RetCodeType.msg_type_longform != FALSE) ||
	    (OutP->RetCodeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->RetCodeType.msg_type_number != 1) ||
	    (OutP->RetCodeType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	if (OutP->RetCode != KERN_SUCCESS)
		return OutP->RetCode;

	return OutP->RetCode;
}

/* Routine MKMDStopClock */
mig_external kern_return_t MKMDStopClock (
	mach_port_t mididriver_port,
	mach_port_t owner_port)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		mach_port_t owner_port;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	union {
		Request In;
		Reply Out;
	} Mess;

	register Request *InP = &Mess.In;
	register Reply *OutP = &Mess.Out;

	msg_return_t msg_result;

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size = 32;

#if	UseStaticMsgType
	static const msg_type_t owner_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t RetCodeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	InP->owner_portType = owner_portType;
#else	UseStaticMsgType
	InP->owner_portType.msg_type_name = MSG_TYPE_PORT;
	InP->owner_portType.msg_type_size = 32;
	InP->owner_portType.msg_type_number = 1;
	InP->owner_portType.msg_type_inline = TRUE;
	InP->owner_portType.msg_type_longform = FALSE;
	InP->owner_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->owner_port /* owner_port */ = /* owner_port */ owner_port;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = mididriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 408;

	msg_result = msg_rpc(&InP->Head, RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 0, 5000);
	if (msg_result != RPC_SUCCESS) {
		if ((msg_result == RCV_INVALID_PORT) ||
		    (msg_result == RCV_TIMED_OUT))
			mig_dealloc_reply_port();
		return msg_result;
	}

#if	TypeCheck
	msg_size = OutP->Head.msg_size;
	msg_simple = OutP->Head.msg_simple;
#endif	TypeCheck

	if (OutP->Head.msg_id != 508)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size != 32) || (msg_simple != TRUE)) &&
	    ((msg_size != sizeof(death_pill_t)) ||
	     (msg_simple != TRUE) ||
	     (OutP->RetCode == KERN_SUCCESS)))
		return MIG_TYPE_ERROR;
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->RetCodeType != * (int *) &RetCodeCheck)
#else	UseStaticMsgType
	if ((OutP->RetCodeType.msg_type_inline != TRUE) ||
	    (OutP->RetCodeType.msg_type_longform != FALSE) ||
	    (OutP->RetCodeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->RetCodeType.msg_type_number != 1) ||
	    (OutP->RetCodeType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	if (OutP->RetCode != KERN_SUCCESS)
		return OutP->RetCode;

	return OutP->RetCode;
}

/* Routine MKMDClaimUnit */
mig_external kern_return_t MKMDClaimUnit (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		mach_port_t owner_port;
		msg_type_t unitType;
		short unit;
		char unitPad[2];
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	union {
		Request In;
		Reply Out;
	} Mess;

	register Request *InP = &Mess.In;
	register Reply *OutP = &Mess.Out;

	msg_return_t msg_result;

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size = 40;

#if	UseStaticMsgType
	static const msg_type_t owner_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_16,
		/* msg_type_size = */		16,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t RetCodeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	InP->owner_portType = owner_portType;
#else	UseStaticMsgType
	InP->owner_portType.msg_type_name = MSG_TYPE_PORT;
	InP->owner_portType.msg_type_size = 32;
	InP->owner_portType.msg_type_number = 1;
	InP->owner_portType.msg_type_inline = TRUE;
	InP->owner_portType.msg_type_longform = FALSE;
	InP->owner_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->owner_port /* owner_port */ = /* owner_port */ owner_port;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_16;
	InP->unitType.msg_type_size = 16;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = mididriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 409;

	msg_result = msg_rpc(&InP->Head, RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 0, 5000);
	if (msg_result != RPC_SUCCESS) {
		if ((msg_result == RCV_INVALID_PORT) ||
		    (msg_result == RCV_TIMED_OUT))
			mig_dealloc_reply_port();
		return msg_result;
	}

#if	TypeCheck
	msg_size = OutP->Head.msg_size;
	msg_simple = OutP->Head.msg_simple;
#endif	TypeCheck

	if (OutP->Head.msg_id != 509)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size != 32) || (msg_simple != TRUE)) &&
	    ((msg_size != sizeof(death_pill_t)) ||
	     (msg_simple != TRUE) ||
	     (OutP->RetCode == KERN_SUCCESS)))
		return MIG_TYPE_ERROR;
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->RetCodeType != * (int *) &RetCodeCheck)
#else	UseStaticMsgType
	if ((OutP->RetCodeType.msg_type_inline != TRUE) ||
	    (OutP->RetCodeType.msg_type_longform != FALSE) ||
	    (OutP->RetCodeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->RetCodeType.msg_type_number != 1) ||
	    (OutP->RetCodeType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	if (OutP->RetCode != KERN_SUCCESS)
		return OutP->RetCode;

	return OutP->RetCode;
}

/* Routine MKMDReleaseUnit */
mig_external kern_return_t MKMDReleaseUnit (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		mach_port_t owner_port;
		msg_type_t unitType;
		short unit;
		char unitPad[2];
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	union {
		Request In;
		Reply Out;
	} Mess;

	register Request *InP = &Mess.In;
	register Reply *OutP = &Mess.Out;

	msg_return_t msg_result;

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size = 40;

#if	UseStaticMsgType
	static const msg_type_t owner_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_16,
		/* msg_type_size = */		16,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t RetCodeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	InP->owner_portType = owner_portType;
#else	UseStaticMsgType
	InP->owner_portType.msg_type_name = MSG_TYPE_PORT;
	InP->owner_portType.msg_type_size = 32;
	InP->owner_portType.msg_type_number = 1;
	InP->owner_portType.msg_type_inline = TRUE;
	InP->owner_portType.msg_type_longform = FALSE;
	InP->owner_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->owner_port /* owner_port */ = /* owner_port */ owner_port;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_16;
	InP->unitType.msg_type_size = 16;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = mididriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 410;

	msg_result = msg_rpc(&InP->Head, RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 0, 5000);
	if (msg_result != RPC_SUCCESS) {
		if ((msg_result == RCV_INVALID_PORT) ||
		    (msg_result == RCV_TIMED_OUT))
			mig_dealloc_reply_port();
		return msg_result;
	}

#if	TypeCheck
	msg_size = OutP->Head.msg_size;
	msg_simple = OutP->Head.msg_simple;
#endif	TypeCheck

	if (OutP->Head.msg_id != 510)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size != 32) || (msg_simple != TRUE)) &&
	    ((msg_size != sizeof(death_pill_t)) ||
	     (msg_simple != TRUE) ||
	     (OutP->RetCode == KERN_SUCCESS)))
		return MIG_TYPE_ERROR;
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->RetCodeType != * (int *) &RetCodeCheck)
#else	UseStaticMsgType
	if ((OutP->RetCodeType.msg_type_inline != TRUE) ||
	    (OutP->RetCodeType.msg_type_longform != FALSE) ||
	    (OutP->RetCodeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->RetCodeType.msg_type_number != 1) ||
	    (OutP->RetCodeType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	if (OutP->RetCode != KERN_SUCCESS)
		return OutP->RetCode;

	return OutP->RetCode;
}

/* Routine MKMDRequestExceptions */
mig_external kern_return_t MKMDRequestExceptions (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	mach_port_t error_port)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		mach_port_t owner_port;
		msg_type_t error_portType;
		mach_port_t error_port;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	union {
		Request In;
		Reply Out;
	} Mess;

	register Request *InP = &Mess.In;
	register Reply *OutP = &Mess.Out;

	msg_return_t msg_result;

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size = 40;

#if	UseStaticMsgType
	static const msg_type_t owner_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t error_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t RetCodeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	InP->owner_portType = owner_portType;
#else	UseStaticMsgType
	InP->owner_portType.msg_type_name = MSG_TYPE_PORT;
	InP->owner_portType.msg_type_size = 32;
	InP->owner_portType.msg_type_number = 1;
	InP->owner_portType.msg_type_inline = TRUE;
	InP->owner_portType.msg_type_longform = FALSE;
	InP->owner_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->owner_port /* owner_port */ = /* owner_port */ owner_port;

#if	UseStaticMsgType
	InP->error_portType = error_portType;
#else	UseStaticMsgType
	InP->error_portType.msg_type_name = MSG_TYPE_PORT;
	InP->error_portType.msg_type_size = 32;
	InP->error_portType.msg_type_number = 1;
	InP->error_portType.msg_type_inline = TRUE;
	InP->error_portType.msg_type_longform = FALSE;
	InP->error_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->error_port /* error_port */ = /* error_port */ error_port;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = mididriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 411;

	msg_result = msg_rpc(&InP->Head, RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 0, 5000);
	if (msg_result != RPC_SUCCESS) {
		if ((msg_result == RCV_INVALID_PORT) ||
		    (msg_result == RCV_TIMED_OUT))
			mig_dealloc_reply_port();
		return msg_result;
	}

#if	TypeCheck
	msg_size = OutP->Head.msg_size;
	msg_simple = OutP->Head.msg_simple;
#endif	TypeCheck

	if (OutP->Head.msg_id != 511)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size != 32) || (msg_simple != TRUE)) &&
	    ((msg_size != sizeof(death_pill_t)) ||
	     (msg_simple != TRUE) ||
	     (OutP->RetCode == KERN_SUCCESS)))
		return MIG_TYPE_ERROR;
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->RetCodeType != * (int *) &RetCodeCheck)
#else	UseStaticMsgType
	if ((OutP->RetCodeType.msg_type_inline != TRUE) ||
	    (OutP->RetCodeType.msg_type_longform != FALSE) ||
	    (OutP->RetCodeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->RetCodeType.msg_type_number != 1) ||
	    (OutP->RetCodeType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	if (OutP->RetCode != KERN_SUCCESS)
		return OutP->RetCode;

	return OutP->RetCode;
}

/* Routine MKMDRequestData */
mig_external kern_return_t MKMDRequestData (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit,
	mach_port_t reply_port)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		mach_port_t owner_port;
		msg_type_t unitType;
		short unit;
		char unitPad[2];
		msg_type_t reply_portType;
		mach_port_t reply_port;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	union {
		Request In;
		Reply Out;
	} Mess;

	register Request *InP = &Mess.In;
	register Reply *OutP = &Mess.Out;

	msg_return_t msg_result;

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size = 48;

#if	UseStaticMsgType
	static const msg_type_t owner_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_16,
		/* msg_type_size = */		16,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t reply_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t RetCodeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	InP->owner_portType = owner_portType;
#else	UseStaticMsgType
	InP->owner_portType.msg_type_name = MSG_TYPE_PORT;
	InP->owner_portType.msg_type_size = 32;
	InP->owner_portType.msg_type_number = 1;
	InP->owner_portType.msg_type_inline = TRUE;
	InP->owner_portType.msg_type_longform = FALSE;
	InP->owner_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->owner_port /* owner_port */ = /* owner_port */ owner_port;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_16;
	InP->unitType.msg_type_size = 16;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

#if	UseStaticMsgType
	InP->reply_portType = reply_portType;
#else	UseStaticMsgType
	InP->reply_portType.msg_type_name = MSG_TYPE_PORT;
	InP->reply_portType.msg_type_size = 32;
	InP->reply_portType.msg_type_number = 1;
	InP->reply_portType.msg_type_inline = TRUE;
	InP->reply_portType.msg_type_longform = FALSE;
	InP->reply_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->reply_port /* reply_port */ = /* reply_port */ reply_port;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = mididriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 412;

	msg_result = msg_rpc(&InP->Head, RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 0, 5000);
	if (msg_result != RPC_SUCCESS) {
		if ((msg_result == RCV_INVALID_PORT) ||
		    (msg_result == RCV_TIMED_OUT))
			mig_dealloc_reply_port();
		return msg_result;
	}

#if	TypeCheck
	msg_size = OutP->Head.msg_size;
	msg_simple = OutP->Head.msg_simple;
#endif	TypeCheck

	if (OutP->Head.msg_id != 512)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size != 32) || (msg_simple != TRUE)) &&
	    ((msg_size != sizeof(death_pill_t)) ||
	     (msg_simple != TRUE) ||
	     (OutP->RetCode == KERN_SUCCESS)))
		return MIG_TYPE_ERROR;
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->RetCodeType != * (int *) &RetCodeCheck)
#else	UseStaticMsgType
	if ((OutP->RetCodeType.msg_type_inline != TRUE) ||
	    (OutP->RetCodeType.msg_type_longform != FALSE) ||
	    (OutP->RetCodeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->RetCodeType.msg_type_number != 1) ||
	    (OutP->RetCodeType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	if (OutP->RetCode != KERN_SUCCESS)
		return OutP->RetCode;

	return OutP->RetCode;
}

/* Routine MKMDSendData */
mig_external kern_return_t MKMDSendData (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit,
	MKMDRawEventPtr data,
	unsigned int dataCnt)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		mach_port_t owner_port;
		msg_type_t unitType;
		short unit;
		char unitPad[2];
		msg_type_t dataType;
		MKMDRawEvent data[100];
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	union {
		Request In;
		Reply Out;
	} Mess;

	register Request *InP = &Mess.In;
	register Reply *OutP = &Mess.Out;

	msg_return_t msg_result;

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size = 44;
	/* Maximum request size 844 */
	unsigned int msg_size_delta;

#if	UseStaticMsgType
	static const msg_type_t owner_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_16,
		/* msg_type_size = */		16,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t dataType = {
		/* msg_type_name = */		MSG_TYPE_BYTE,
		/* msg_type_size = */		8,
		/* msg_type_number = */		800,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t RetCodeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	InP->owner_portType = owner_portType;
#else	UseStaticMsgType
	InP->owner_portType.msg_type_name = MSG_TYPE_PORT;
	InP->owner_portType.msg_type_size = 32;
	InP->owner_portType.msg_type_number = 1;
	InP->owner_portType.msg_type_inline = TRUE;
	InP->owner_portType.msg_type_longform = FALSE;
	InP->owner_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->owner_port /* owner_port */ = /* owner_port */ owner_port;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_16;
	InP->unitType.msg_type_size = 16;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

#if	UseStaticMsgType
	InP->dataType = dataType;
#else	UseStaticMsgType
	InP->dataType.msg_type_name = MSG_TYPE_BYTE;
	InP->dataType.msg_type_size = 8;
	InP->dataType.msg_type_inline = TRUE;
	InP->dataType.msg_type_longform = FALSE;
	InP->dataType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	if (dataCnt > 100)
		return MIG_ARRAY_TOO_LARGE;
	bcopy((char *) data, (char *) InP->data, 8 * dataCnt);

	InP->dataType.msg_type_number /* 8 dataCnt */ = /* dataType.msg_type_number */ 8 * dataCnt;

	msg_size_delta = 8 * dataCnt;
	msg_size += msg_size_delta;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = mididriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 413;

	msg_result = msg_rpc(&InP->Head, RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 0, 5000);
	if (msg_result != RPC_SUCCESS) {
		if ((msg_result == RCV_INVALID_PORT) ||
		    (msg_result == RCV_TIMED_OUT))
			mig_dealloc_reply_port();
		return msg_result;
	}

#if	TypeCheck
	msg_size = OutP->Head.msg_size;
	msg_simple = OutP->Head.msg_simple;
#endif	TypeCheck

	if (OutP->Head.msg_id != 513)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size != 32) || (msg_simple != TRUE)) &&
	    ((msg_size != sizeof(death_pill_t)) ||
	     (msg_simple != TRUE) ||
	     (OutP->RetCode == KERN_SUCCESS)))
		return MIG_TYPE_ERROR;
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->RetCodeType != * (int *) &RetCodeCheck)
#else	UseStaticMsgType
	if ((OutP->RetCodeType.msg_type_inline != TRUE) ||
	    (OutP->RetCodeType.msg_type_longform != FALSE) ||
	    (OutP->RetCodeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->RetCodeType.msg_type_number != 1) ||
	    (OutP->RetCodeType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	if (OutP->RetCode != KERN_SUCCESS)
		return OutP->RetCode;

	return OutP->RetCode;
}

/* Routine MKMDGetAvailableQueueSize */
mig_external kern_return_t MKMDGetAvailableQueueSize (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit,
	int *size)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		mach_port_t owner_port;
		msg_type_t unitType;
		short unit;
		char unitPad[2];
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
		msg_type_t sizeType;
		int size;
	} Reply;

	union {
		Request In;
		Reply Out;
	} Mess;

	register Request *InP = &Mess.In;
	register Reply *OutP = &Mess.Out;

	msg_return_t msg_result;

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size = 40;

#if	UseStaticMsgType
	static const msg_type_t owner_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_16,
		/* msg_type_size = */		16,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t RetCodeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t sizeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	InP->owner_portType = owner_portType;
#else	UseStaticMsgType
	InP->owner_portType.msg_type_name = MSG_TYPE_PORT;
	InP->owner_portType.msg_type_size = 32;
	InP->owner_portType.msg_type_number = 1;
	InP->owner_portType.msg_type_inline = TRUE;
	InP->owner_portType.msg_type_longform = FALSE;
	InP->owner_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->owner_port /* owner_port */ = /* owner_port */ owner_port;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_16;
	InP->unitType.msg_type_size = 16;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = mididriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 414;

	msg_result = msg_rpc(&InP->Head, RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 0, 5000);
	if (msg_result != RPC_SUCCESS) {
		if ((msg_result == RCV_INVALID_PORT) ||
		    (msg_result == RCV_TIMED_OUT))
			mig_dealloc_reply_port();
		return msg_result;
	}

#if	TypeCheck
	msg_size = OutP->Head.msg_size;
	msg_simple = OutP->Head.msg_simple;
#endif	TypeCheck

	if (OutP->Head.msg_id != 514)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size != 40) || (msg_simple != TRUE)) &&
	    ((msg_size != sizeof(death_pill_t)) ||
	     (msg_simple != TRUE) ||
	     (OutP->RetCode == KERN_SUCCESS)))
		return MIG_TYPE_ERROR;
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->RetCodeType != * (int *) &RetCodeCheck)
#else	UseStaticMsgType
	if ((OutP->RetCodeType.msg_type_inline != TRUE) ||
	    (OutP->RetCodeType.msg_type_longform != FALSE) ||
	    (OutP->RetCodeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->RetCodeType.msg_type_number != 1) ||
	    (OutP->RetCodeType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	if (OutP->RetCode != KERN_SUCCESS)
		return OutP->RetCode;

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->sizeType != * (int *) &sizeCheck)
#else	UseStaticMsgType
	if ((OutP->sizeType.msg_type_inline != TRUE) ||
	    (OutP->sizeType.msg_type_longform != FALSE) ||
	    (OutP->sizeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->sizeType.msg_type_number != 1) ||
	    (OutP->sizeType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	*size /* size */ = /* *size */ OutP->size;

	return OutP->RetCode;
}

/* Routine MKMDRequestQueueNotification */
mig_external kern_return_t MKMDRequestQueueNotification (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit,
	mach_port_t notification_port,
	int size)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		mach_port_t owner_port;
		msg_type_t unitType;
		short unit;
		char unitPad[2];
		msg_type_t notification_portType;
		mach_port_t notification_port;
		msg_type_t sizeType;
		int size;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	union {
		Request In;
		Reply Out;
	} Mess;

	register Request *InP = &Mess.In;
	register Reply *OutP = &Mess.Out;

	msg_return_t msg_result;

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size = 56;

#if	UseStaticMsgType
	static const msg_type_t owner_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_16,
		/* msg_type_size = */		16,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t notification_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t sizeType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t RetCodeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	InP->owner_portType = owner_portType;
#else	UseStaticMsgType
	InP->owner_portType.msg_type_name = MSG_TYPE_PORT;
	InP->owner_portType.msg_type_size = 32;
	InP->owner_portType.msg_type_number = 1;
	InP->owner_portType.msg_type_inline = TRUE;
	InP->owner_portType.msg_type_longform = FALSE;
	InP->owner_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->owner_port /* owner_port */ = /* owner_port */ owner_port;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_16;
	InP->unitType.msg_type_size = 16;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

#if	UseStaticMsgType
	InP->notification_portType = notification_portType;
#else	UseStaticMsgType
	InP->notification_portType.msg_type_name = MSG_TYPE_PORT;
	InP->notification_portType.msg_type_size = 32;
	InP->notification_portType.msg_type_number = 1;
	InP->notification_portType.msg_type_inline = TRUE;
	InP->notification_portType.msg_type_longform = FALSE;
	InP->notification_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->notification_port /* notification_port */ = /* notification_port */ notification_port;

#if	UseStaticMsgType
	InP->sizeType = sizeType;
#else	UseStaticMsgType
	InP->sizeType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->sizeType.msg_type_size = 32;
	InP->sizeType.msg_type_number = 1;
	InP->sizeType.msg_type_inline = TRUE;
	InP->sizeType.msg_type_longform = FALSE;
	InP->sizeType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->size /* size */ = /* size */ size;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = mididriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 415;

	msg_result = msg_rpc(&InP->Head, RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 0, 5000);
	if (msg_result != RPC_SUCCESS) {
		if ((msg_result == RCV_INVALID_PORT) ||
		    (msg_result == RCV_TIMED_OUT))
			mig_dealloc_reply_port();
		return msg_result;
	}

#if	TypeCheck
	msg_size = OutP->Head.msg_size;
	msg_simple = OutP->Head.msg_simple;
#endif	TypeCheck

	if (OutP->Head.msg_id != 515)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size != 32) || (msg_simple != TRUE)) &&
	    ((msg_size != sizeof(death_pill_t)) ||
	     (msg_simple != TRUE) ||
	     (OutP->RetCode == KERN_SUCCESS)))
		return MIG_TYPE_ERROR;
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->RetCodeType != * (int *) &RetCodeCheck)
#else	UseStaticMsgType
	if ((OutP->RetCodeType.msg_type_inline != TRUE) ||
	    (OutP->RetCodeType.msg_type_longform != FALSE) ||
	    (OutP->RetCodeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->RetCodeType.msg_type_number != 1) ||
	    (OutP->RetCodeType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	if (OutP->RetCode != KERN_SUCCESS)
		return OutP->RetCode;

	return OutP->RetCode;
}

/* Routine MKMDClearQueue */
mig_external kern_return_t MKMDClearQueue (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		mach_port_t owner_port;
		msg_type_t unitType;
		short unit;
		char unitPad[2];
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	union {
		Request In;
		Reply Out;
	} Mess;

	register Request *InP = &Mess.In;
	register Reply *OutP = &Mess.Out;

	msg_return_t msg_result;

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size = 40;

#if	UseStaticMsgType
	static const msg_type_t owner_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_16,
		/* msg_type_size = */		16,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t RetCodeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	InP->owner_portType = owner_portType;
#else	UseStaticMsgType
	InP->owner_portType.msg_type_name = MSG_TYPE_PORT;
	InP->owner_portType.msg_type_size = 32;
	InP->owner_portType.msg_type_number = 1;
	InP->owner_portType.msg_type_inline = TRUE;
	InP->owner_portType.msg_type_longform = FALSE;
	InP->owner_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->owner_port /* owner_port */ = /* owner_port */ owner_port;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_16;
	InP->unitType.msg_type_size = 16;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = mididriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 416;

	msg_result = msg_rpc(&InP->Head, RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 0, 5000);
	if (msg_result != RPC_SUCCESS) {
		if ((msg_result == RCV_INVALID_PORT) ||
		    (msg_result == RCV_TIMED_OUT))
			mig_dealloc_reply_port();
		return msg_result;
	}

#if	TypeCheck
	msg_size = OutP->Head.msg_size;
	msg_simple = OutP->Head.msg_simple;
#endif	TypeCheck

	if (OutP->Head.msg_id != 516)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size != 32) || (msg_simple != TRUE)) &&
	    ((msg_size != sizeof(death_pill_t)) ||
	     (msg_simple != TRUE) ||
	     (OutP->RetCode == KERN_SUCCESS)))
		return MIG_TYPE_ERROR;
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->RetCodeType != * (int *) &RetCodeCheck)
#else	UseStaticMsgType
	if ((OutP->RetCodeType.msg_type_inline != TRUE) ||
	    (OutP->RetCodeType.msg_type_longform != FALSE) ||
	    (OutP->RetCodeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->RetCodeType.msg_type_number != 1) ||
	    (OutP->RetCodeType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	if (OutP->RetCode != KERN_SUCCESS)
		return OutP->RetCode;

	return OutP->RetCode;
}

/* Routine MKMDFlushQueue */
mig_external kern_return_t MKMDFlushQueue (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		mach_port_t owner_port;
		msg_type_t unitType;
		short unit;
		char unitPad[2];
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	union {
		Request In;
		Reply Out;
	} Mess;

	register Request *InP = &Mess.In;
	register Reply *OutP = &Mess.Out;

	msg_return_t msg_result;

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size = 40;

#if	UseStaticMsgType
	static const msg_type_t owner_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_16,
		/* msg_type_size = */		16,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t RetCodeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	InP->owner_portType = owner_portType;
#else	UseStaticMsgType
	InP->owner_portType.msg_type_name = MSG_TYPE_PORT;
	InP->owner_portType.msg_type_size = 32;
	InP->owner_portType.msg_type_number = 1;
	InP->owner_portType.msg_type_inline = TRUE;
	InP->owner_portType.msg_type_longform = FALSE;
	InP->owner_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->owner_port /* owner_port */ = /* owner_port */ owner_port;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_16;
	InP->unitType.msg_type_size = 16;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = mididriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 417;

	msg_result = msg_rpc(&InP->Head, RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 0, 5000);
	if (msg_result != RPC_SUCCESS) {
		if ((msg_result == RCV_INVALID_PORT) ||
		    (msg_result == RCV_TIMED_OUT))
			mig_dealloc_reply_port();
		return msg_result;
	}

#if	TypeCheck
	msg_size = OutP->Head.msg_size;
	msg_simple = OutP->Head.msg_simple;
#endif	TypeCheck

	if (OutP->Head.msg_id != 517)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size != 32) || (msg_simple != TRUE)) &&
	    ((msg_size != sizeof(death_pill_t)) ||
	     (msg_simple != TRUE) ||
	     (OutP->RetCode == KERN_SUCCESS)))
		return MIG_TYPE_ERROR;
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->RetCodeType != * (int *) &RetCodeCheck)
#else	UseStaticMsgType
	if ((OutP->RetCodeType.msg_type_inline != TRUE) ||
	    (OutP->RetCodeType.msg_type_longform != FALSE) ||
	    (OutP->RetCodeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->RetCodeType.msg_type_number != 1) ||
	    (OutP->RetCodeType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	if (OutP->RetCode != KERN_SUCCESS)
		return OutP->RetCode;

	return OutP->RetCode;
}

/* Routine MKMDSetSystemIgnores */
mig_external kern_return_t MKMDSetSystemIgnores (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	short unit,
	int sys_ignores)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		mach_port_t owner_port;
		msg_type_t unitType;
		short unit;
		char unitPad[2];
		msg_type_t sys_ignoresType;
		int sys_ignores;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	union {
		Request In;
		Reply Out;
	} Mess;

	register Request *InP = &Mess.In;
	register Reply *OutP = &Mess.Out;

	msg_return_t msg_result;

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size = 48;

#if	UseStaticMsgType
	static const msg_type_t owner_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_16,
		/* msg_type_size = */		16,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t sys_ignoresType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t RetCodeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	InP->owner_portType = owner_portType;
#else	UseStaticMsgType
	InP->owner_portType.msg_type_name = MSG_TYPE_PORT;
	InP->owner_portType.msg_type_size = 32;
	InP->owner_portType.msg_type_number = 1;
	InP->owner_portType.msg_type_inline = TRUE;
	InP->owner_portType.msg_type_longform = FALSE;
	InP->owner_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->owner_port /* owner_port */ = /* owner_port */ owner_port;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_16;
	InP->unitType.msg_type_size = 16;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

#if	UseStaticMsgType
	InP->sys_ignoresType = sys_ignoresType;
#else	UseStaticMsgType
	InP->sys_ignoresType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->sys_ignoresType.msg_type_size = 32;
	InP->sys_ignoresType.msg_type_number = 1;
	InP->sys_ignoresType.msg_type_inline = TRUE;
	InP->sys_ignoresType.msg_type_longform = FALSE;
	InP->sys_ignoresType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->sys_ignores /* sys_ignores */ = /* sys_ignores */ sys_ignores;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = mididriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 418;

	msg_result = msg_rpc(&InP->Head, RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 0, 5000);
	if (msg_result != RPC_SUCCESS) {
		if ((msg_result == RCV_INVALID_PORT) ||
		    (msg_result == RCV_TIMED_OUT))
			mig_dealloc_reply_port();
		return msg_result;
	}

#if	TypeCheck
	msg_size = OutP->Head.msg_size;
	msg_simple = OutP->Head.msg_simple;
#endif	TypeCheck

	if (OutP->Head.msg_id != 518)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size != 32) || (msg_simple != TRUE)) &&
	    ((msg_size != sizeof(death_pill_t)) ||
	     (msg_simple != TRUE) ||
	     (OutP->RetCode == KERN_SUCCESS)))
		return MIG_TYPE_ERROR;
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->RetCodeType != * (int *) &RetCodeCheck)
#else	UseStaticMsgType
	if ((OutP->RetCodeType.msg_type_inline != TRUE) ||
	    (OutP->RetCodeType.msg_type_longform != FALSE) ||
	    (OutP->RetCodeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->RetCodeType.msg_type_number != 1) ||
	    (OutP->RetCodeType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	if (OutP->RetCode != KERN_SUCCESS)
		return OutP->RetCode;

	return OutP->RetCode;
}

/* Routine MKMDSetClockQuantum */
mig_external kern_return_t MKMDSetClockQuantum (
	mach_port_t mididriver_port,
	mach_port_t owner_port,
	int microseconds)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		mach_port_t owner_port;
		msg_type_t microsecondsType;
		int microseconds;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	union {
		Request In;
		Reply Out;
	} Mess;

	register Request *InP = &Mess.In;
	register Reply *OutP = &Mess.Out;

	msg_return_t msg_result;

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size = 40;

#if	UseStaticMsgType
	static const msg_type_t owner_portType = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t microsecondsType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t RetCodeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	InP->owner_portType = owner_portType;
#else	UseStaticMsgType
	InP->owner_portType.msg_type_name = MSG_TYPE_PORT;
	InP->owner_portType.msg_type_size = 32;
	InP->owner_portType.msg_type_number = 1;
	InP->owner_portType.msg_type_inline = TRUE;
	InP->owner_portType.msg_type_longform = FALSE;
	InP->owner_portType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->owner_port /* owner_port */ = /* owner_port */ owner_port;

#if	UseStaticMsgType
	InP->microsecondsType = microsecondsType;
#else	UseStaticMsgType
	InP->microsecondsType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->microsecondsType.msg_type_size = 32;
	InP->microsecondsType.msg_type_number = 1;
	InP->microsecondsType.msg_type_inline = TRUE;
	InP->microsecondsType.msg_type_longform = FALSE;
	InP->microsecondsType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->microseconds /* microseconds */ = /* microseconds */ microseconds;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = mididriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 419;

	msg_result = msg_rpc(&InP->Head, RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 0, 5000);
	if (msg_result != RPC_SUCCESS) {
		if ((msg_result == RCV_INVALID_PORT) ||
		    (msg_result == RCV_TIMED_OUT))
			mig_dealloc_reply_port();
		return msg_result;
	}

#if	TypeCheck
	msg_size = OutP->Head.msg_size;
	msg_simple = OutP->Head.msg_simple;
#endif	TypeCheck

	if (OutP->Head.msg_id != 519)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size != 32) || (msg_simple != TRUE)) &&
	    ((msg_size != sizeof(death_pill_t)) ||
	     (msg_simple != TRUE) ||
	     (OutP->RetCode == KERN_SUCCESS)))
		return MIG_TYPE_ERROR;
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->RetCodeType != * (int *) &RetCodeCheck)
#else	UseStaticMsgType
	if ((OutP->RetCodeType.msg_type_inline != TRUE) ||
	    (OutP->RetCodeType.msg_type_longform != FALSE) ||
	    (OutP->RetCodeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->RetCodeType.msg_type_number != 1) ||
	    (OutP->RetCodeType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	if (OutP->RetCode != KERN_SUCCESS)
		return OutP->RetCode;

	return OutP->RetCode;
}
