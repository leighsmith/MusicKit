/* Module mididriver_reply */

#define EXPORT_BOOLEAN
#include <mach/boolean.h>
#include <mach/message.h>
#include <mach/mig_errors.h>

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

#define novalue void

#define msg_request_port	msg_local_port
#define msg_reply_port		msg_remote_port
#include <mach/std_types.h>
#include "mididriver_types.h"

/* SimpleRoutine MDAlarmReply */
mig_internal novalue _XMDAlarmReply
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t requestedTimeType;
		int requestedTime;
		msg_type_t actualTimeType;
		int actualTime;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t MDAlarmReply (port_t reply_port, int requestedTime, int actualTime);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t requestedTimeCheck = {
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
	static const msg_type_t actualTimeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	TypeCheck
	msg_size = In0P->Head.msg_size;
	msg_simple = In0P->Head.msg_simple;
	if ((msg_size != 40) || (msg_simple != TRUE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->requestedTimeType != * (int *) &requestedTimeCheck)
#else	UseStaticMsgType
	if ((In0P->requestedTimeType.msg_type_inline != TRUE) ||
	    (In0P->requestedTimeType.msg_type_longform != FALSE) ||
	    (In0P->requestedTimeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->requestedTimeType.msg_type_number != 1) ||
	    (In0P->requestedTimeType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->actualTimeType != * (int *) &actualTimeCheck)
#else	UseStaticMsgType
	if ((In0P->actualTimeType.msg_type_inline != TRUE) ||
	    (In0P->actualTimeType.msg_type_longform != FALSE) ||
	    (In0P->actualTimeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->actualTimeType.msg_type_number != 1) ||
	    (In0P->actualTimeType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) MDAlarmReply(In0P->Head.msg_request_port, In0P->requestedTime, In0P->actualTime);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine MDDataReply */
mig_internal novalue _XMDDataReply
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t unitType;
		short unit;
		char unitPad[2];
		msg_type_t dataType;
		MDRawEvent data[100];
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t MDDataReply (port_t reply_port, short unit, MDRawEventPtr data, unsigned int dataCnt);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;
	unsigned int msg_size_delta;

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_16,
		/* msg_type_size = */		16,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	TypeCheck
	msg_size = In0P->Head.msg_size;
	msg_simple = In0P->Head.msg_simple;
	if ((msg_size < 36) || (msg_size > 836) || (msg_simple != TRUE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_16) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 16))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
	if ((In0P->dataType.msg_type_inline != TRUE) ||
	    (In0P->dataType.msg_type_longform != FALSE) ||
	    (In0P->dataType.msg_type_name != MSG_TYPE_BYTE) ||
	    (In0P->dataType.msg_type_size != 8))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
	msg_size_delta = 1 * In0P->dataType.msg_type_number;
	if (msg_size != 36 + msg_size_delta)
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) MDDataReply(In0P->Head.msg_request_port, In0P->unit, In0P->data, In0P->dataType.msg_type_number / 8);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine MDExceptionReply */
mig_internal novalue _XMDExceptionReply
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t exception_codeType;
		int exception_code;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t MDExceptionReply (port_t reply_port, int exception_code);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t exception_codeCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	TypeCheck
	msg_size = In0P->Head.msg_size;
	msg_simple = In0P->Head.msg_simple;
	if ((msg_size != 32) || (msg_simple != TRUE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->exception_codeType != * (int *) &exception_codeCheck)
#else	UseStaticMsgType
	if ((In0P->exception_codeType.msg_type_inline != TRUE) ||
	    (In0P->exception_codeType.msg_type_longform != FALSE) ||
	    (In0P->exception_codeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->exception_codeType.msg_type_number != 1) ||
	    (In0P->exception_codeType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) MDExceptionReply(In0P->Head.msg_request_port, In0P->exception_code);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine MDQueueReply */
mig_internal novalue _XMDQueueReply
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t unitType;
		short unit;
		char unitPad[2];
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t MDQueueReply (port_t reply_port, short unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_16,
		/* msg_type_size = */		16,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	TypeCheck
	msg_size = In0P->Head.msg_size;
	msg_simple = In0P->Head.msg_simple;
	if ((msg_size != 32) || (msg_simple != TRUE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_16) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 16))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) MDQueueReply(In0P->Head.msg_request_port, In0P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

boolean_t mididriver_reply_server
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	register msg_header_t *InP =  InHeadP;
	register death_pill_t *OutP = (death_pill_t *) OutHeadP;

#if	UseStaticMsgType
	static const msg_type_t RetCodeType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

	OutP->Head.msg_simple = TRUE;
	OutP->Head.msg_size = sizeof *OutP;
	OutP->Head.msg_type = InP->msg_type;
	OutP->Head.msg_local_port = PORT_NULL;
	OutP->Head.msg_remote_port = InP->msg_reply_port;
	OutP->Head.msg_id = InP->msg_id + 100;

#if	UseStaticMsgType
	OutP->RetCodeType = RetCodeType;
#else	UseStaticMsgType
	OutP->RetCodeType.msg_type_name = MSG_TYPE_INTEGER_32;
	OutP->RetCodeType.msg_type_size = 32;
	OutP->RetCodeType.msg_type_number = 1;
	OutP->RetCodeType.msg_type_inline = TRUE;
	OutP->RetCodeType.msg_type_longform = FALSE;
	OutP->RetCodeType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType
	OutP->RetCode = MIG_BAD_ID;

	if ((InP->msg_id > 403) || (InP->msg_id < 400))
		return FALSE;
	else {
		typedef novalue (*SERVER_STUB_PROC)
			(msg_header_t *, msg_header_t *);
		static const SERVER_STUB_PROC routines[] = {
			_XMDAlarmReply,
			_XMDDataReply,
			_XMDExceptionReply,
			_XMDQueueReply,
		};

		if (routines[InP->msg_id - 400])
			(routines[InP->msg_id - 400]) (InP, &OutP->Head);
		 else
			return FALSE;
	}
	return TRUE;
}
