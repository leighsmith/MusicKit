#include "dspdriver.h"
#include <mach/mach_types.h>
#include <mach/message.h>
#include <mach/mig_errors.h>
#include <mach/msg_type.h>
#if	!defined(KERNEL) && !defined(MIG_NO_STRINGS)
#include <strings.h>
#endif
/* LINTLIBRARY */

extern port_t mig_get_reply_port();
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


/* Routine dsp_become_owner */
mig_external kern_return_t dsp_become_owner (
	port_t dspdriver_port,
	port_t owner_port,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t unitType;
		int unit;
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
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 500;

	msg_result = msg_rpc(&InP->Head, SEND_TIMEOUT|RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 5000, 5000);
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

	if (OutP->Head.msg_id != 600)
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

/* Routine dsp_reset_chip */
mig_external kern_return_t dsp_reset_chip (
	port_t dspdriver_port,
	port_t owner_port,
	char on,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t onType;
		char on;
		char onPad[3];
		msg_type_t unitType;
		int unit;
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
	static const msg_type_t onType = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
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
	InP->onType = onType;
#else	UseStaticMsgType
	InP->onType.msg_type_name = MSG_TYPE_CHAR;
	InP->onType.msg_type_size = 8;
	InP->onType.msg_type_number = 1;
	InP->onType.msg_type_inline = TRUE;
	InP->onType.msg_type_longform = FALSE;
	InP->onType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->on /* on */ = /* on */ on;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 501;

	msg_result = msg_rpc(&InP->Head, SEND_TIMEOUT|RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 5000, 5000);
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

	if (OutP->Head.msg_id != 601)
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

/* Routine dsp_release_ownership */
mig_external kern_return_t dsp_release_ownership (
	port_t dspdriver_port,
	port_t owner_port,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t unitType;
		int unit;
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
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 502;

	msg_result = msg_rpc(&InP->Head, SEND_TIMEOUT|RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 5000, 5000);
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

	if (OutP->Head.msg_id != 602)
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

/* Routine dsp_get_icr */
mig_external kern_return_t dsp_get_icr (
	port_t dspdriver_port,
	port_t owner_port,
	char *icr,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t unitType;
		int unit;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
		msg_type_t icrType;
		char icr;
		char icrPad[3];
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
	static const msg_type_t icrCheck = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
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
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 503;

	msg_result = msg_rpc(&InP->Head, SEND_TIMEOUT|RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 5000, 5000);
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

	if (OutP->Head.msg_id != 603)
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
	if (* (int *) &OutP->icrType != * (int *) &icrCheck)
#else	UseStaticMsgType
	if ((OutP->icrType.msg_type_inline != TRUE) ||
	    (OutP->icrType.msg_type_longform != FALSE) ||
	    (OutP->icrType.msg_type_name != MSG_TYPE_CHAR) ||
	    (OutP->icrType.msg_type_number != 1) ||
	    (OutP->icrType.msg_type_size != 8))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	*icr /* icr */ = /* *icr */ OutP->icr;

	return OutP->RetCode;
}

/* Routine dsp_get_cvr */
mig_external kern_return_t dsp_get_cvr (
	port_t dspdriver_port,
	port_t owner_port,
	char *cvr,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t unitType;
		int unit;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
		msg_type_t cvrType;
		char cvr;
		char cvrPad[3];
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
	static const msg_type_t cvrCheck = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
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
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 504;

	msg_result = msg_rpc(&InP->Head, SEND_TIMEOUT|RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 5000, 5000);
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

	if (OutP->Head.msg_id != 604)
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
	if (* (int *) &OutP->cvrType != * (int *) &cvrCheck)
#else	UseStaticMsgType
	if ((OutP->cvrType.msg_type_inline != TRUE) ||
	    (OutP->cvrType.msg_type_longform != FALSE) ||
	    (OutP->cvrType.msg_type_name != MSG_TYPE_CHAR) ||
	    (OutP->cvrType.msg_type_number != 1) ||
	    (OutP->cvrType.msg_type_size != 8))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	*cvr /* cvr */ = /* *cvr */ OutP->cvr;

	return OutP->RetCode;
}

/* Routine dsp_get_isr */
mig_external kern_return_t dsp_get_isr (
	port_t dspdriver_port,
	port_t owner_port,
	char *isr,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t unitType;
		int unit;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
		msg_type_t isrType;
		char isr;
		char isrPad[3];
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
	static const msg_type_t isrCheck = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
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
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 505;

	msg_result = msg_rpc(&InP->Head, SEND_TIMEOUT|RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 5000, 5000);
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

	if (OutP->Head.msg_id != 605)
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
	if (* (int *) &OutP->isrType != * (int *) &isrCheck)
#else	UseStaticMsgType
	if ((OutP->isrType.msg_type_inline != TRUE) ||
	    (OutP->isrType.msg_type_longform != FALSE) ||
	    (OutP->isrType.msg_type_name != MSG_TYPE_CHAR) ||
	    (OutP->isrType.msg_type_number != 1) ||
	    (OutP->isrType.msg_type_size != 8))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	*isr /* isr */ = /* *isr */ OutP->isr;

	return OutP->RetCode;
}

/* Routine dsp_get_ivr */
mig_external kern_return_t dsp_get_ivr (
	port_t dspdriver_port,
	port_t owner_port,
	char *ivr,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t unitType;
		int unit;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
		msg_type_t ivrType;
		char ivr;
		char ivrPad[3];
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
	static const msg_type_t ivrCheck = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
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
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 506;

	msg_result = msg_rpc(&InP->Head, SEND_TIMEOUT|RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 5000, 5000);
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

	if (OutP->Head.msg_id != 606)
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
	if (* (int *) &OutP->ivrType != * (int *) &ivrCheck)
#else	UseStaticMsgType
	if ((OutP->ivrType.msg_type_inline != TRUE) ||
	    (OutP->ivrType.msg_type_longform != FALSE) ||
	    (OutP->ivrType.msg_type_name != MSG_TYPE_CHAR) ||
	    (OutP->ivrType.msg_type_number != 1) ||
	    (OutP->ivrType.msg_type_size != 8))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	*ivr /* ivr */ = /* *ivr */ OutP->ivr;

	return OutP->RetCode;
}

/* SimpleRoutine dsp_put_icr */
mig_external kern_return_t dsp_put_icr (
	port_t dspdriver_port,
	port_t owner_port,
	char icr,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t icrType;
		char icr;
		char icrPad[3];
		msg_type_t unitType;
		int unit;
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
	static const msg_type_t icrType = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
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
	InP->icrType = icrType;
#else	UseStaticMsgType
	InP->icrType.msg_type_name = MSG_TYPE_CHAR;
	InP->icrType.msg_type_size = 8;
	InP->icrType.msg_type_number = 1;
	InP->icrType.msg_type_inline = TRUE;
	InP->icrType.msg_type_longform = FALSE;
	InP->icrType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->icr /* icr */ = /* icr */ icr;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 507;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* SimpleRoutine dsp_put_cvr */
mig_external kern_return_t dsp_put_cvr (
	port_t dspdriver_port,
	port_t owner_port,
	char cvr,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t cvrType;
		char cvr;
		char cvrPad[3];
		msg_type_t unitType;
		int unit;
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
	static const msg_type_t cvrType = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
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
	InP->cvrType = cvrType;
#else	UseStaticMsgType
	InP->cvrType.msg_type_name = MSG_TYPE_CHAR;
	InP->cvrType.msg_type_size = 8;
	InP->cvrType.msg_type_number = 1;
	InP->cvrType.msg_type_inline = TRUE;
	InP->cvrType.msg_type_longform = FALSE;
	InP->cvrType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->cvr /* cvr */ = /* cvr */ cvr;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 508;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* SimpleRoutine dsp_put_ivr */
mig_external kern_return_t dsp_put_ivr (
	port_t dspdriver_port,
	port_t owner_port,
	char ivr,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t ivrType;
		char ivr;
		char ivrPad[3];
		msg_type_t unitType;
		int unit;
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
	static const msg_type_t ivrType = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
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
	InP->ivrType = ivrType;
#else	UseStaticMsgType
	InP->ivrType.msg_type_name = MSG_TYPE_CHAR;
	InP->ivrType.msg_type_size = 8;
	InP->ivrType.msg_type_number = 1;
	InP->ivrType.msg_type_inline = TRUE;
	InP->ivrType.msg_type_longform = FALSE;
	InP->ivrType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->ivr /* ivr */ = /* ivr */ ivr;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 509;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* SimpleRoutine dsp_put_data_raw */
mig_external kern_return_t dsp_put_data_raw (
	port_t dspdriver_port,
	port_t owner_port,
	char high,
	char med,
	char low,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t highType;
		char high;
		char highPad[3];
		msg_type_t medType;
		char med;
		char medPad[3];
		msg_type_t lowType;
		char low;
		char lowPad[3];
		msg_type_t unitType;
		int unit;
	} Request;

	union {
		Request In;
	} Mess;

	register Request *InP = &Mess.In;

	unsigned int msg_size = 64;

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
	static const msg_type_t highType = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t medType = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t lowType = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
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
	InP->highType = highType;
#else	UseStaticMsgType
	InP->highType.msg_type_name = MSG_TYPE_CHAR;
	InP->highType.msg_type_size = 8;
	InP->highType.msg_type_number = 1;
	InP->highType.msg_type_inline = TRUE;
	InP->highType.msg_type_longform = FALSE;
	InP->highType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->high /* high */ = /* high */ high;

#if	UseStaticMsgType
	InP->medType = medType;
#else	UseStaticMsgType
	InP->medType.msg_type_name = MSG_TYPE_CHAR;
	InP->medType.msg_type_size = 8;
	InP->medType.msg_type_number = 1;
	InP->medType.msg_type_inline = TRUE;
	InP->medType.msg_type_longform = FALSE;
	InP->medType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->med /* med */ = /* med */ med;

#if	UseStaticMsgType
	InP->lowType = lowType;
#else	UseStaticMsgType
	InP->lowType.msg_type_name = MSG_TYPE_CHAR;
	InP->lowType.msg_type_size = 8;
	InP->lowType.msg_type_number = 1;
	InP->lowType.msg_type_inline = TRUE;
	InP->lowType.msg_type_longform = FALSE;
	InP->lowType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->low /* low */ = /* low */ low;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 510;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* Routine dsp_get_data_raw */
mig_external kern_return_t dsp_get_data_raw (
	port_t dspdriver_port,
	port_t owner_port,
	char *high,
	char *med,
	char *low,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t unitType;
		int unit;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
		msg_type_t highType;
		char high;
		char highPad[3];
		msg_type_t medType;
		char med;
		char medPad[3];
		msg_type_t lowType;
		char low;
		char lowPad[3];
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
	static const msg_type_t highCheck = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t medCheck = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t lowCheck = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
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
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 511;

	msg_result = msg_rpc(&InP->Head, SEND_TIMEOUT|RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 5000, 5000);
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

	if (OutP->Head.msg_id != 611)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size != 56) || (msg_simple != TRUE)) &&
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
	if (* (int *) &OutP->highType != * (int *) &highCheck)
#else	UseStaticMsgType
	if ((OutP->highType.msg_type_inline != TRUE) ||
	    (OutP->highType.msg_type_longform != FALSE) ||
	    (OutP->highType.msg_type_name != MSG_TYPE_CHAR) ||
	    (OutP->highType.msg_type_number != 1) ||
	    (OutP->highType.msg_type_size != 8))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	*high /* high */ = /* *high */ OutP->high;

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->medType != * (int *) &medCheck)
#else	UseStaticMsgType
	if ((OutP->medType.msg_type_inline != TRUE) ||
	    (OutP->medType.msg_type_longform != FALSE) ||
	    (OutP->medType.msg_type_name != MSG_TYPE_CHAR) ||
	    (OutP->medType.msg_type_number != 1) ||
	    (OutP->medType.msg_type_size != 8))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	*med /* med */ = /* *med */ OutP->med;

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->lowType != * (int *) &lowCheck)
#else	UseStaticMsgType
	if ((OutP->lowType.msg_type_inline != TRUE) ||
	    (OutP->lowType.msg_type_longform != FALSE) ||
	    (OutP->lowType.msg_type_name != MSG_TYPE_CHAR) ||
	    (OutP->lowType.msg_type_number != 1) ||
	    (OutP->lowType.msg_type_size != 8))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	*low /* low */ = /* *low */ OutP->low;

	return OutP->RetCode;
}

/* SimpleRoutine dsp_put_data */
mig_external kern_return_t dsp_put_data (
	port_t dspdriver_port,
	port_t owner_port,
	char high,
	char med,
	char low,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t highType;
		char high;
		char highPad[3];
		msg_type_t medType;
		char med;
		char medPad[3];
		msg_type_t lowType;
		char low;
		char lowPad[3];
		msg_type_t unitType;
		int unit;
	} Request;

	union {
		Request In;
	} Mess;

	register Request *InP = &Mess.In;

	unsigned int msg_size = 64;

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
	static const msg_type_t highType = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t medType = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t lowType = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
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
	InP->highType = highType;
#else	UseStaticMsgType
	InP->highType.msg_type_name = MSG_TYPE_CHAR;
	InP->highType.msg_type_size = 8;
	InP->highType.msg_type_number = 1;
	InP->highType.msg_type_inline = TRUE;
	InP->highType.msg_type_longform = FALSE;
	InP->highType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->high /* high */ = /* high */ high;

#if	UseStaticMsgType
	InP->medType = medType;
#else	UseStaticMsgType
	InP->medType.msg_type_name = MSG_TYPE_CHAR;
	InP->medType.msg_type_size = 8;
	InP->medType.msg_type_number = 1;
	InP->medType.msg_type_inline = TRUE;
	InP->medType.msg_type_longform = FALSE;
	InP->medType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->med /* med */ = /* med */ med;

#if	UseStaticMsgType
	InP->lowType = lowType;
#else	UseStaticMsgType
	InP->lowType.msg_type_name = MSG_TYPE_CHAR;
	InP->lowType.msg_type_size = 8;
	InP->lowType.msg_type_number = 1;
	InP->lowType.msg_type_inline = TRUE;
	InP->lowType.msg_type_longform = FALSE;
	InP->lowType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->low /* low */ = /* low */ low;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 512;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* Routine dsp_get_data */
mig_external kern_return_t dsp_get_data (
	port_t dspdriver_port,
	port_t owner_port,
	char *high,
	char *med,
	char *low,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t unitType;
		int unit;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
		msg_type_t highType;
		char high;
		char highPad[3];
		msg_type_t medType;
		char med;
		char medPad[3];
		msg_type_t lowType;
		char low;
		char lowPad[3];
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
	static const msg_type_t highCheck = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t medCheck = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t lowCheck = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
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
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 513;

	msg_result = msg_rpc(&InP->Head, SEND_TIMEOUT|RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 5000, 5000);
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

	if (OutP->Head.msg_id != 613)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size != 56) || (msg_simple != TRUE)) &&
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
	if (* (int *) &OutP->highType != * (int *) &highCheck)
#else	UseStaticMsgType
	if ((OutP->highType.msg_type_inline != TRUE) ||
	    (OutP->highType.msg_type_longform != FALSE) ||
	    (OutP->highType.msg_type_name != MSG_TYPE_CHAR) ||
	    (OutP->highType.msg_type_number != 1) ||
	    (OutP->highType.msg_type_size != 8))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	*high /* high */ = /* *high */ OutP->high;

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->medType != * (int *) &medCheck)
#else	UseStaticMsgType
	if ((OutP->medType.msg_type_inline != TRUE) ||
	    (OutP->medType.msg_type_longform != FALSE) ||
	    (OutP->medType.msg_type_name != MSG_TYPE_CHAR) ||
	    (OutP->medType.msg_type_number != 1) ||
	    (OutP->medType.msg_type_size != 8))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	*med /* med */ = /* *med */ OutP->med;

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &OutP->lowType != * (int *) &lowCheck)
#else	UseStaticMsgType
	if ((OutP->lowType.msg_type_inline != TRUE) ||
	    (OutP->lowType.msg_type_longform != FALSE) ||
	    (OutP->lowType.msg_type_name != MSG_TYPE_CHAR) ||
	    (OutP->lowType.msg_type_number != 1) ||
	    (OutP->lowType.msg_type_size != 8))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	*low /* low */ = /* *low */ OutP->low;

	return OutP->RetCode;
}

/* SimpleRoutine dsp_put_data_array */
mig_external kern_return_t dsp_put_data_array (
	port_t dspdriver_port,
	port_t owner_port,
	DSPWordPtr data,
	unsigned int dataCnt,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t dataType;
		int data[512];
		msg_type_t unitType;
		int unit;
	} Request;

	union {
		Request In;
	} Mess;

	register Request *InP = &Mess.In;

	unsigned int msg_size = 44;
	/* Maximum request size 2092 */
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
	static const msg_type_t dataType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		512,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
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
	InP->dataType = dataType;
#else	UseStaticMsgType
	InP->dataType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->dataType.msg_type_size = 32;
	InP->dataType.msg_type_inline = TRUE;
	InP->dataType.msg_type_longform = FALSE;
	InP->dataType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	if (dataCnt > 512)
		return MIG_ARRAY_TOO_LARGE;
	bcopy((char *) data, (char *) InP->data, 4 * dataCnt);

	InP->dataType.msg_type_number /* dataCnt */ = /* dataType.msg_type_number */ dataCnt;

	msg_size_delta = 4 * dataCnt;
	msg_size += msg_size_delta;
	InP = (Request *) ((char *) InP + msg_size_delta - 2048);

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP = &Mess.In;
	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 514;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* SimpleRoutine dsp_put_data_byte_array */
mig_external kern_return_t dsp_put_data_byte_array (
	port_t dspdriver_port,
	port_t owner_port,
	DSPCharPtr data,
	unsigned int dataCnt,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t dataType;
		char data[2048];
		msg_type_t unitType;
		int unit;
	} Request;

	union {
		Request In;
	} Mess;

	register Request *InP = &Mess.In;

	unsigned int msg_size = 44;
	/* Maximum request size 2092 */
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
	static const msg_type_t dataType = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
		/* msg_type_number = */		2048,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
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
	InP->dataType = dataType;
#else	UseStaticMsgType
	InP->dataType.msg_type_name = MSG_TYPE_CHAR;
	InP->dataType.msg_type_size = 8;
	InP->dataType.msg_type_inline = TRUE;
	InP->dataType.msg_type_longform = FALSE;
	InP->dataType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	if (dataCnt > 2048)
		return MIG_ARRAY_TOO_LARGE;
	bcopy((char *) data, (char *) InP->data, 1 * dataCnt);

	InP->dataType.msg_type_number /* dataCnt */ = /* dataType.msg_type_number */ dataCnt;

	msg_size_delta = (1 * dataCnt + 3) & ~3;
	msg_size += msg_size_delta;
	InP = (Request *) ((char *) InP + msg_size_delta - 2048);

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP = &Mess.In;
	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 515;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* SimpleRoutine dsp_put_data_short_array */
mig_external kern_return_t dsp_put_data_short_array (
	port_t dspdriver_port,
	port_t owner_port,
	DSPShortPtr data,
	unsigned int dataCnt,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t dataType;
		short data[1024];
		msg_type_t unitType;
		int unit;
	} Request;

	union {
		Request In;
	} Mess;

	register Request *InP = &Mess.In;

	unsigned int msg_size = 44;
	/* Maximum request size 2092 */
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
	static const msg_type_t dataType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_16,
		/* msg_type_size = */		16,
		/* msg_type_number = */		1024,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
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
	InP->dataType = dataType;
#else	UseStaticMsgType
	InP->dataType.msg_type_name = MSG_TYPE_INTEGER_16;
	InP->dataType.msg_type_size = 16;
	InP->dataType.msg_type_inline = TRUE;
	InP->dataType.msg_type_longform = FALSE;
	InP->dataType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	if (dataCnt > 1024)
		return MIG_ARRAY_TOO_LARGE;
	bcopy((char *) data, (char *) InP->data, 2 * dataCnt);

	InP->dataType.msg_type_number /* dataCnt */ = /* dataType.msg_type_number */ dataCnt;

	msg_size_delta = (2 * dataCnt + 3) & ~3;
	msg_size += msg_size_delta;
	InP = (Request *) ((char *) InP + msg_size_delta - 2048);

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP = &Mess.In;
	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 516;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* SimpleRoutine dsp_put_data_packed_array */
mig_external kern_return_t dsp_put_data_packed_array (
	port_t dspdriver_port,
	port_t owner_port,
	DSPCharPtr data,
	unsigned int dataCnt,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t dataType;
		char data[2048];
		msg_type_t unitType;
		int unit;
	} Request;

	union {
		Request In;
	} Mess;

	register Request *InP = &Mess.In;

	unsigned int msg_size = 44;
	/* Maximum request size 2092 */
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
	static const msg_type_t dataType = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
		/* msg_type_number = */		2048,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
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
	InP->dataType = dataType;
#else	UseStaticMsgType
	InP->dataType.msg_type_name = MSG_TYPE_CHAR;
	InP->dataType.msg_type_size = 8;
	InP->dataType.msg_type_inline = TRUE;
	InP->dataType.msg_type_longform = FALSE;
	InP->dataType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	if (dataCnt > 2048)
		return MIG_ARRAY_TOO_LARGE;
	bcopy((char *) data, (char *) InP->data, 1 * dataCnt);

	InP->dataType.msg_type_number /* dataCnt */ = /* dataType.msg_type_number */ dataCnt;

	msg_size_delta = (1 * dataCnt + 3) & ~3;
	msg_size += msg_size_delta;
	InP = (Request *) ((char *) InP + msg_size_delta - 2048);

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP = &Mess.In;
	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 517;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* SimpleRoutine dsp_put_data_left_array */
mig_external kern_return_t dsp_put_data_left_array (
	port_t dspdriver_port,
	port_t owner_port,
	DSPWordPtr data,
	unsigned int dataCnt,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t dataType;
		int data[512];
		msg_type_t unitType;
		int unit;
	} Request;

	union {
		Request In;
	} Mess;

	register Request *InP = &Mess.In;

	unsigned int msg_size = 44;
	/* Maximum request size 2092 */
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
	static const msg_type_t dataType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		512,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
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
	InP->dataType = dataType;
#else	UseStaticMsgType
	InP->dataType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->dataType.msg_type_size = 32;
	InP->dataType.msg_type_inline = TRUE;
	InP->dataType.msg_type_longform = FALSE;
	InP->dataType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	if (dataCnt > 512)
		return MIG_ARRAY_TOO_LARGE;
	bcopy((char *) data, (char *) InP->data, 4 * dataCnt);

	InP->dataType.msg_type_number /* dataCnt */ = /* dataType.msg_type_number */ dataCnt;

	msg_size_delta = 4 * dataCnt;
	msg_size += msg_size_delta;
	InP = (Request *) ((char *) InP + msg_size_delta - 2048);

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP = &Mess.In;
	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 518;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* Routine dsp_get_data_array */
mig_external kern_return_t dsp_get_data_array (
	port_t dspdriver_port,
	port_t owner_port,
	int count,
	DSPWordPtr data,
	unsigned int *dataCnt,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t countType;
		int count;
		msg_type_t unitType;
		int unit;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
		msg_type_t dataType;
		int data[512];
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
	static const msg_type_t countType = {
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
	static const msg_type_t unitType = {
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
	InP->countType = countType;
#else	UseStaticMsgType
	InP->countType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->countType.msg_type_size = 32;
	InP->countType.msg_type_number = 1;
	InP->countType.msg_type_inline = TRUE;
	InP->countType.msg_type_longform = FALSE;
	InP->countType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->count /* count */ = /* count */ count;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 519;

	msg_result = msg_rpc(&InP->Head, SEND_TIMEOUT|RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 5000, 5000);
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

	if (OutP->Head.msg_id != 619)
		return MIG_REPLY_MISMATCH;

#if	TypeCheck
	if (((msg_size < 36) || (msg_size > 2084) || (msg_simple != TRUE)) &&
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
	if ((OutP->dataType.msg_type_inline != TRUE) ||
	    (OutP->dataType.msg_type_longform != FALSE) ||
	    (OutP->dataType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->dataType.msg_type_size != 32))
		return MIG_TYPE_ERROR;
#endif	TypeCheck

#if	TypeCheck
	msg_size_delta = 4 * OutP->dataType.msg_type_number;
	if (msg_size != 36 + msg_size_delta)
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	if (OutP->dataType.msg_type_number / 1 > *dataCnt) {
		bcopy((char *) OutP->data, (char *) data, 4 * *dataCnt);
		*dataCnt /* dataType.msg_type_number 1 */ = /* *dataCnt */ OutP->dataType.msg_type_number / 1;
		return MIG_ARRAY_TOO_LARGE;
	}
	bcopy((char *) OutP->data, (char *) data, 4 * OutP->dataType.msg_type_number);

	*dataCnt /* dataType.msg_type_number */ = /* *dataCnt */ OutP->dataType.msg_type_number;

	OutP = &Mess.Out;
	return OutP->RetCode;
}

/* SimpleRoutine dsp_put_mk_timed_message */
mig_external kern_return_t dsp_put_mk_timed_message (
	port_t dspdriver_port,
	port_t owner_port,
	int highWord,
	int lowWord,
	int opCode,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t highWordType;
		int highWord;
		msg_type_t lowWordType;
		int lowWord;
		msg_type_t opCodeType;
		int opCode;
		msg_type_t unitType;
		int unit;
	} Request;

	union {
		Request In;
	} Mess;

	register Request *InP = &Mess.In;

	unsigned int msg_size = 64;

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
	static const msg_type_t highWordType = {
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
	static const msg_type_t lowWordType = {
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
	static const msg_type_t opCodeType = {
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
	static const msg_type_t unitType = {
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
	InP->highWordType = highWordType;
#else	UseStaticMsgType
	InP->highWordType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->highWordType.msg_type_size = 32;
	InP->highWordType.msg_type_number = 1;
	InP->highWordType.msg_type_inline = TRUE;
	InP->highWordType.msg_type_longform = FALSE;
	InP->highWordType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->highWord /* highWord */ = /* highWord */ highWord;

#if	UseStaticMsgType
	InP->lowWordType = lowWordType;
#else	UseStaticMsgType
	InP->lowWordType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->lowWordType.msg_type_size = 32;
	InP->lowWordType.msg_type_number = 1;
	InP->lowWordType.msg_type_inline = TRUE;
	InP->lowWordType.msg_type_longform = FALSE;
	InP->lowWordType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->lowWord /* lowWord */ = /* lowWord */ lowWord;

#if	UseStaticMsgType
	InP->opCodeType = opCodeType;
#else	UseStaticMsgType
	InP->opCodeType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->opCodeType.msg_type_size = 32;
	InP->opCodeType.msg_type_number = 1;
	InP->opCodeType.msg_type_inline = TRUE;
	InP->opCodeType.msg_type_longform = FALSE;
	InP->opCodeType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->opCode /* opCode */ = /* opCode */ opCode;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 520;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* SimpleRoutine dsp_exec_mk_host_message */
mig_external kern_return_t dsp_exec_mk_host_message (
	port_t dspdriver_port,
	port_t owner_port,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t unitType;
		int unit;
	} Request;

	union {
		Request In;
	} Mess;

	register Request *InP = &Mess.In;

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
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 521;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* Routine dsp_get_hi */
mig_external kern_return_t dsp_get_hi (
	port_t dspdriver_port,
	port_t owner_port,
	int *hi,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t unitType;
		int unit;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
		msg_type_t hiType;
		int hi;
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
	static const msg_type_t hiCheck = {
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
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL | MSG_TYPE_RPC;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = mig_get_reply_port();
	InP->Head.msg_id = 522;

	msg_result = msg_rpc(&InP->Head, SEND_TIMEOUT|RCV_TIMEOUT|SEND_SWITCH, sizeof(Reply), 5000, 5000);
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

	if (OutP->Head.msg_id != 622)
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
	if (* (int *) &OutP->hiType != * (int *) &hiCheck)
#else	UseStaticMsgType
	if ((OutP->hiType.msg_type_inline != TRUE) ||
	    (OutP->hiType.msg_type_longform != FALSE) ||
	    (OutP->hiType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (OutP->hiType.msg_type_number != 1) ||
	    (OutP->hiType.msg_type_size != 32))
#endif	UseStaticMsgType
		return MIG_TYPE_ERROR;
#endif	TypeCheck

	*hi /* hi */ = /* *hi */ OutP->hi;

	return OutP->RetCode;
}

/* SimpleRoutine dsp_put_and_exec_mk_host_message */
mig_external kern_return_t dsp_put_and_exec_mk_host_message (
	port_t dspdriver_port,
	port_t owner_port,
	DSPWordPtr data,
	unsigned int dataCnt,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t dataType;
		int data[512];
		msg_type_t unitType;
		int unit;
	} Request;

	union {
		Request In;
	} Mess;

	register Request *InP = &Mess.In;

	unsigned int msg_size = 44;
	/* Maximum request size 2092 */
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
	static const msg_type_t dataType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		512,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitType = {
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
	InP->dataType = dataType;
#else	UseStaticMsgType
	InP->dataType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->dataType.msg_type_size = 32;
	InP->dataType.msg_type_inline = TRUE;
	InP->dataType.msg_type_longform = FALSE;
	InP->dataType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	if (dataCnt > 512)
		return MIG_ARRAY_TOO_LARGE;
	bcopy((char *) data, (char *) InP->data, 4 * dataCnt);

	InP->dataType.msg_type_number /* dataCnt */ = /* dataType.msg_type_number */ dataCnt;

	msg_size_delta = 4 * dataCnt;
	msg_size += msg_size_delta;
	InP = (Request *) ((char *) InP + msg_size_delta - 2048);

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP = &Mess.In;
	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 523;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* SimpleRoutine dsp_set_sub_unit */
mig_external kern_return_t dsp_set_sub_unit (
	port_t dspdriver_port,
	port_t owner_port,
	int sub_unit,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t sub_unitType;
		int sub_unit;
		msg_type_t unitType;
		int unit;
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
	static const msg_type_t sub_unitType = {
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
	static const msg_type_t unitType = {
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
	InP->sub_unitType = sub_unitType;
#else	UseStaticMsgType
	InP->sub_unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->sub_unitType.msg_type_size = 32;
	InP->sub_unitType.msg_type_number = 1;
	InP->sub_unitType.msg_type_inline = TRUE;
	InP->sub_unitType.msg_type_longform = FALSE;
	InP->sub_unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->sub_unit /* sub_unit */ = /* sub_unit */ sub_unit;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 524;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* SimpleRoutine dsp_put_page */
mig_external kern_return_t dsp_put_page (
	port_t dspdriver_port,
	port_t owner_port,
	DSPPagePtr pageAddress,
	int regionTag,
	boolean_t msgStarted,
	boolean_t msgCompleted,
	port_t reply_port,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t pageAddressType;
		DSPPagePtr pageAddress;
		msg_type_t regionTagType;
		int regionTag;
		msg_type_t msgStartedType;
		boolean_t msgStarted;
		msg_type_t msgCompletedType;
		boolean_t msgCompleted;
		msg_type_t reply_portType;
		port_t reply_port;
		msg_type_t unitType;
		int unit;
	} Request;

	union {
		Request In;
	} Mess;

	register Request *InP = &Mess.In;

	unsigned int msg_size = 80;

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
	static const msg_type_t pageAddressType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		2048,
		/* msg_type_inline = */		FALSE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t regionTagType = {
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
	static const msg_type_t msgStartedType = {
		/* msg_type_name = */		MSG_TYPE_BOOLEAN,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t msgCompletedType = {
		/* msg_type_name = */		MSG_TYPE_BOOLEAN,
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
	static const msg_type_t unitType = {
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
	InP->pageAddressType = pageAddressType;
#else	UseStaticMsgType
	InP->pageAddressType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->pageAddressType.msg_type_size = 32;
	InP->pageAddressType.msg_type_number = 2048;
	InP->pageAddressType.msg_type_inline = FALSE;
	InP->pageAddressType.msg_type_longform = FALSE;
	InP->pageAddressType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->pageAddress /* pageAddress */ = /* pageAddress */ pageAddress;

#if	UseStaticMsgType
	InP->regionTagType = regionTagType;
#else	UseStaticMsgType
	InP->regionTagType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->regionTagType.msg_type_size = 32;
	InP->regionTagType.msg_type_number = 1;
	InP->regionTagType.msg_type_inline = TRUE;
	InP->regionTagType.msg_type_longform = FALSE;
	InP->regionTagType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->regionTag /* regionTag */ = /* regionTag */ regionTag;

#if	UseStaticMsgType
	InP->msgStartedType = msgStartedType;
#else	UseStaticMsgType
	InP->msgStartedType.msg_type_name = MSG_TYPE_BOOLEAN;
	InP->msgStartedType.msg_type_size = 32;
	InP->msgStartedType.msg_type_number = 1;
	InP->msgStartedType.msg_type_inline = TRUE;
	InP->msgStartedType.msg_type_longform = FALSE;
	InP->msgStartedType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->msgStarted /* msgStarted */ = /* msgStarted */ msgStarted;

#if	UseStaticMsgType
	InP->msgCompletedType = msgCompletedType;
#else	UseStaticMsgType
	InP->msgCompletedType.msg_type_name = MSG_TYPE_BOOLEAN;
	InP->msgCompletedType.msg_type_size = 32;
	InP->msgCompletedType.msg_type_number = 1;
	InP->msgCompletedType.msg_type_inline = TRUE;
	InP->msgCompletedType.msg_type_longform = FALSE;
	InP->msgCompletedType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->msgCompleted /* msgCompleted */ = /* msgCompleted */ msgCompleted;

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
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 525;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* SimpleRoutine dsp_set_messaging */
mig_external kern_return_t dsp_set_messaging (
	port_t dspdriver_port,
	port_t owner_port,
	boolean_t flag,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t flagType;
		boolean_t flag;
		msg_type_t unitType;
		int unit;
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
	static const msg_type_t flagType = {
		/* msg_type_name = */		MSG_TYPE_BOOLEAN,
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
	InP->flagType = flagType;
#else	UseStaticMsgType
	InP->flagType.msg_type_name = MSG_TYPE_BOOLEAN;
	InP->flagType.msg_type_size = 32;
	InP->flagType.msg_type_number = 1;
	InP->flagType.msg_type_inline = TRUE;
	InP->flagType.msg_type_longform = FALSE;
	InP->flagType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->flag /* flag */ = /* flag */ flag;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 526;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* SimpleRoutine dsp_queue_page */
mig_external kern_return_t dsp_queue_page (
	port_t dspdriver_port,
	port_t owner_port,
	DSPPagePtr pageAddress,
	int regionTag,
	boolean_t msgStarted,
	boolean_t msgCompleted,
	port_t reply_port,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t pageAddressType;
		DSPPagePtr pageAddress;
		msg_type_t regionTagType;
		int regionTag;
		msg_type_t msgStartedType;
		boolean_t msgStarted;
		msg_type_t msgCompletedType;
		boolean_t msgCompleted;
		msg_type_t reply_portType;
		port_t reply_port;
		msg_type_t unitType;
		int unit;
	} Request;

	union {
		Request In;
	} Mess;

	register Request *InP = &Mess.In;

	unsigned int msg_size = 80;

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
	static const msg_type_t pageAddressType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		2048,
		/* msg_type_inline = */		FALSE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t regionTagType = {
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
	static const msg_type_t msgStartedType = {
		/* msg_type_name = */		MSG_TYPE_BOOLEAN,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t msgCompletedType = {
		/* msg_type_name = */		MSG_TYPE_BOOLEAN,
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
	static const msg_type_t unitType = {
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
	InP->pageAddressType = pageAddressType;
#else	UseStaticMsgType
	InP->pageAddressType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->pageAddressType.msg_type_size = 32;
	InP->pageAddressType.msg_type_number = 2048;
	InP->pageAddressType.msg_type_inline = FALSE;
	InP->pageAddressType.msg_type_longform = FALSE;
	InP->pageAddressType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->pageAddress /* pageAddress */ = /* pageAddress */ pageAddress;

#if	UseStaticMsgType
	InP->regionTagType = regionTagType;
#else	UseStaticMsgType
	InP->regionTagType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->regionTagType.msg_type_size = 32;
	InP->regionTagType.msg_type_number = 1;
	InP->regionTagType.msg_type_inline = TRUE;
	InP->regionTagType.msg_type_longform = FALSE;
	InP->regionTagType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->regionTag /* regionTag */ = /* regionTag */ regionTag;

#if	UseStaticMsgType
	InP->msgStartedType = msgStartedType;
#else	UseStaticMsgType
	InP->msgStartedType.msg_type_name = MSG_TYPE_BOOLEAN;
	InP->msgStartedType.msg_type_size = 32;
	InP->msgStartedType.msg_type_number = 1;
	InP->msgStartedType.msg_type_inline = TRUE;
	InP->msgStartedType.msg_type_longform = FALSE;
	InP->msgStartedType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->msgStarted /* msgStarted */ = /* msgStarted */ msgStarted;

#if	UseStaticMsgType
	InP->msgCompletedType = msgCompletedType;
#else	UseStaticMsgType
	InP->msgCompletedType.msg_type_name = MSG_TYPE_BOOLEAN;
	InP->msgCompletedType.msg_type_size = 32;
	InP->msgCompletedType.msg_type_number = 1;
	InP->msgCompletedType.msg_type_inline = TRUE;
	InP->msgCompletedType.msg_type_longform = FALSE;
	InP->msgCompletedType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->msgCompleted /* msgCompleted */ = /* msgCompleted */ msgCompleted;

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
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 527;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* SimpleRoutine dsp_set_short_big_endian_return */
mig_external kern_return_t dsp_set_short_big_endian_return (
	port_t dspdriver_port,
	port_t owner_port,
	int regionTag,
	int wordCount,
	port_t reply_port,
	int chan,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t regionTagType;
		int regionTag;
		msg_type_t wordCountType;
		int wordCount;
		msg_type_t reply_portType;
		port_t reply_port;
		msg_type_t chanType;
		int chan;
		msg_type_t unitType;
		int unit;
	} Request;

	union {
		Request In;
	} Mess;

	register Request *InP = &Mess.In;

	unsigned int msg_size = 72;

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
	static const msg_type_t regionTagType = {
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
	static const msg_type_t wordCountType = {
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
	static const msg_type_t chanType = {
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
	static const msg_type_t unitType = {
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
	InP->regionTagType = regionTagType;
#else	UseStaticMsgType
	InP->regionTagType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->regionTagType.msg_type_size = 32;
	InP->regionTagType.msg_type_number = 1;
	InP->regionTagType.msg_type_inline = TRUE;
	InP->regionTagType.msg_type_longform = FALSE;
	InP->regionTagType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->regionTag /* regionTag */ = /* regionTag */ regionTag;

#if	UseStaticMsgType
	InP->wordCountType = wordCountType;
#else	UseStaticMsgType
	InP->wordCountType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->wordCountType.msg_type_size = 32;
	InP->wordCountType.msg_type_number = 1;
	InP->wordCountType.msg_type_inline = TRUE;
	InP->wordCountType.msg_type_longform = FALSE;
	InP->wordCountType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->wordCount /* wordCount */ = /* wordCount */ wordCount;

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
	InP->chanType = chanType;
#else	UseStaticMsgType
	InP->chanType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->chanType.msg_type_size = 32;
	InP->chanType.msg_type_number = 1;
	InP->chanType.msg_type_inline = TRUE;
	InP->chanType.msg_type_longform = FALSE;
	InP->chanType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->chan /* chan */ = /* chan */ chan;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 528;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* SimpleRoutine dsp_set_short_return */
mig_external kern_return_t dsp_set_short_return (
	port_t dspdriver_port,
	port_t owner_port,
	int regionTag,
	int wordCount,
	port_t reply_port,
	int chan,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t regionTagType;
		int regionTag;
		msg_type_t wordCountType;
		int wordCount;
		msg_type_t reply_portType;
		port_t reply_port;
		msg_type_t chanType;
		int chan;
		msg_type_t unitType;
		int unit;
	} Request;

	union {
		Request In;
	} Mess;

	register Request *InP = &Mess.In;

	unsigned int msg_size = 72;

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
	static const msg_type_t regionTagType = {
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
	static const msg_type_t wordCountType = {
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
	static const msg_type_t chanType = {
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
	static const msg_type_t unitType = {
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
	InP->regionTagType = regionTagType;
#else	UseStaticMsgType
	InP->regionTagType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->regionTagType.msg_type_size = 32;
	InP->regionTagType.msg_type_number = 1;
	InP->regionTagType.msg_type_inline = TRUE;
	InP->regionTagType.msg_type_longform = FALSE;
	InP->regionTagType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->regionTag /* regionTag */ = /* regionTag */ regionTag;

#if	UseStaticMsgType
	InP->wordCountType = wordCountType;
#else	UseStaticMsgType
	InP->wordCountType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->wordCountType.msg_type_size = 32;
	InP->wordCountType.msg_type_number = 1;
	InP->wordCountType.msg_type_inline = TRUE;
	InP->wordCountType.msg_type_longform = FALSE;
	InP->wordCountType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->wordCount /* wordCount */ = /* wordCount */ wordCount;

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
	InP->chanType = chanType;
#else	UseStaticMsgType
	InP->chanType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->chanType.msg_type_size = 32;
	InP->chanType.msg_type_number = 1;
	InP->chanType.msg_type_inline = TRUE;
	InP->chanType.msg_type_longform = FALSE;
	InP->chanType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->chan /* chan */ = /* chan */ chan;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 529;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* SimpleRoutine dsp_set_long_return */
mig_external kern_return_t dsp_set_long_return (
	port_t dspdriver_port,
	port_t owner_port,
	int regionTag,
	int wordCount,
	port_t reply_port,
	int chan,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t regionTagType;
		int regionTag;
		msg_type_t wordCountType;
		int wordCount;
		msg_type_t reply_portType;
		port_t reply_port;
		msg_type_t chanType;
		int chan;
		msg_type_t unitType;
		int unit;
	} Request;

	union {
		Request In;
	} Mess;

	register Request *InP = &Mess.In;

	unsigned int msg_size = 72;

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
	static const msg_type_t regionTagType = {
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
	static const msg_type_t wordCountType = {
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
	static const msg_type_t chanType = {
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
	static const msg_type_t unitType = {
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
	InP->regionTagType = regionTagType;
#else	UseStaticMsgType
	InP->regionTagType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->regionTagType.msg_type_size = 32;
	InP->regionTagType.msg_type_number = 1;
	InP->regionTagType.msg_type_inline = TRUE;
	InP->regionTagType.msg_type_longform = FALSE;
	InP->regionTagType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->regionTag /* regionTag */ = /* regionTag */ regionTag;

#if	UseStaticMsgType
	InP->wordCountType = wordCountType;
#else	UseStaticMsgType
	InP->wordCountType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->wordCountType.msg_type_size = 32;
	InP->wordCountType.msg_type_number = 1;
	InP->wordCountType.msg_type_inline = TRUE;
	InP->wordCountType.msg_type_longform = FALSE;
	InP->wordCountType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->wordCount /* wordCount */ = /* wordCount */ wordCount;

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
	InP->chanType = chanType;
#else	UseStaticMsgType
	InP->chanType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->chanType.msg_type_size = 32;
	InP->chanType.msg_type_number = 1;
	InP->chanType.msg_type_inline = TRUE;
	InP->chanType.msg_type_longform = FALSE;
	InP->chanType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->chan /* chan */ = /* chan */ chan;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 530;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* SimpleRoutine dsp_set_error_port */
mig_external kern_return_t dsp_set_error_port (
	port_t dspdriver_port,
	port_t owner_port,
	port_t reply_port,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t reply_portType;
		port_t reply_port;
		msg_type_t unitType;
		int unit;
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
	static const msg_type_t unitType = {
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
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 531;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* SimpleRoutine dsp_set_msg_port */
mig_external kern_return_t dsp_set_msg_port (
	port_t dspdriver_port,
	port_t owner_port,
	port_t reply_port,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t reply_portType;
		port_t reply_port;
		msg_type_t unitType;
		int unit;
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
	static const msg_type_t unitType = {
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
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 532;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* SimpleRoutine dsp_set_debug */
mig_external kern_return_t dsp_set_debug (
	port_t dspdriver_port,
	int debug_flags)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t debug_flagsType;
		int debug_flags;
	} Request;

	union {
		Request In;
	} Mess;

	register Request *InP = &Mess.In;

	unsigned int msg_size = 32;

#if	UseStaticMsgType
	static const msg_type_t debug_flagsType = {
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
	InP->debug_flagsType = debug_flagsType;
#else	UseStaticMsgType
	InP->debug_flagsType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->debug_flagsType.msg_type_size = 32;
	InP->debug_flagsType.msg_type_number = 1;
	InP->debug_flagsType.msg_type_inline = TRUE;
	InP->debug_flagsType.msg_type_longform = FALSE;
	InP->debug_flagsType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->debug_flags /* debug_flags */ = /* debug_flags */ debug_flags;

	InP->Head.msg_simple = TRUE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 533;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}

/* SimpleRoutine dsp_free_page */
mig_external kern_return_t dsp_free_page (
	port_t dspdriver_port,
	port_t owner_port,
	int page_index,
	int unit)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t page_indexType;
		int page_index;
		msg_type_t unitType;
		int unit;
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
	static const msg_type_t page_indexType = {
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
	static const msg_type_t unitType = {
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
	InP->page_indexType = page_indexType;
#else	UseStaticMsgType
	InP->page_indexType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->page_indexType.msg_type_size = 32;
	InP->page_indexType.msg_type_number = 1;
	InP->page_indexType.msg_type_inline = TRUE;
	InP->page_indexType.msg_type_longform = FALSE;
	InP->page_indexType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->page_index /* page_index */ = /* page_index */ page_index;

#if	UseStaticMsgType
	InP->unitType = unitType;
#else	UseStaticMsgType
	InP->unitType.msg_type_name = MSG_TYPE_INTEGER_32;
	InP->unitType.msg_type_size = 32;
	InP->unitType.msg_type_number = 1;
	InP->unitType.msg_type_inline = TRUE;
	InP->unitType.msg_type_longform = FALSE;
	InP->unitType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	InP->unit /* unit */ = /* unit */ unit;

	InP->Head.msg_simple = FALSE;
	InP->Head.msg_size = msg_size;
	InP->Head.msg_type = MSG_TYPE_NORMAL;
	InP->Head.msg_request_port = dspdriver_port;
	InP->Head.msg_reply_port = PORT_NULL;
	InP->Head.msg_id = 534;

	return msg_send(&InP->Head, SEND_TIMEOUT, 5000);
}
