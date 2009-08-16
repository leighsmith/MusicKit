/* Module dspdriver */

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
#include "dspdriver_types.h"
#include <mach/mach_types.h>

/* Routine dsp_become_owner */
mig_internal novalue _Xdsp_become_owner
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_become_owner (port_t dspdriver_port, port_t owner_port, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
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
	if ((msg_size != 40) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = dsp_become_owner(In0P->Head.msg_request_port, In0P->owner_port, In0P->unit);
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	if (OutP->RetCode != KERN_SUCCESS)
		return;

	msg_size = 32;	

	OutP->Head.msg_simple = TRUE;
	OutP->Head.msg_size = msg_size;
}

/* Routine dsp_reset_chip */
mig_internal novalue _Xdsp_reset_chip
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_reset_chip (port_t dspdriver_port, port_t owner_port, char on, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t onCheck = {
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
	static const msg_type_t unitCheck = {
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
	if ((msg_size != 48) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->onType != * (int *) &onCheck)
#else	UseStaticMsgType
	if ((In0P->onType.msg_type_inline != TRUE) ||
	    (In0P->onType.msg_type_longform != FALSE) ||
	    (In0P->onType.msg_type_name != MSG_TYPE_CHAR) ||
	    (In0P->onType.msg_type_number != 1) ||
	    (In0P->onType.msg_type_size != 8))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = dsp_reset_chip(In0P->Head.msg_request_port, In0P->owner_port, In0P->on, In0P->unit);
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	if (OutP->RetCode != KERN_SUCCESS)
		return;

	msg_size = 32;	

	OutP->Head.msg_simple = TRUE;
	OutP->Head.msg_size = msg_size;
}

/* Routine dsp_release_ownership */
mig_internal novalue _Xdsp_release_ownership
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_release_ownership (port_t dspdriver_port, port_t owner_port, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
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
	if ((msg_size != 40) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = dsp_release_ownership(In0P->Head.msg_request_port, In0P->owner_port, In0P->unit);
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	if (OutP->RetCode != KERN_SUCCESS)
		return;

	msg_size = 32;	

	OutP->Head.msg_simple = TRUE;
	OutP->Head.msg_size = msg_size;
}

/* Routine dsp_get_icr */
mig_internal novalue _Xdsp_get_icr
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_get_icr (port_t dspdriver_port, port_t owner_port, char *icr, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
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

#if	TypeCheck
	msg_size = In0P->Head.msg_size;
	msg_simple = In0P->Head.msg_simple;
	if ((msg_size != 40) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = dsp_get_icr(In0P->Head.msg_request_port, In0P->owner_port, &OutP->icr, In0P->unit);
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	if (OutP->RetCode != KERN_SUCCESS)
		return;

	msg_size = 40;	

#if	UseStaticMsgType
	OutP->icrType = icrType;
#else	UseStaticMsgType
	OutP->icrType.msg_type_name = MSG_TYPE_CHAR;
	OutP->icrType.msg_type_size = 8;
	OutP->icrType.msg_type_number = 1;
	OutP->icrType.msg_type_inline = TRUE;
	OutP->icrType.msg_type_longform = FALSE;
	OutP->icrType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	OutP->Head.msg_simple = TRUE;
	OutP->Head.msg_size = msg_size;
}

/* Routine dsp_get_cvr */
mig_internal novalue _Xdsp_get_cvr
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_get_cvr (port_t dspdriver_port, port_t owner_port, char *cvr, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
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

#if	TypeCheck
	msg_size = In0P->Head.msg_size;
	msg_simple = In0P->Head.msg_simple;
	if ((msg_size != 40) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = dsp_get_cvr(In0P->Head.msg_request_port, In0P->owner_port, &OutP->cvr, In0P->unit);
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	if (OutP->RetCode != KERN_SUCCESS)
		return;

	msg_size = 40;	

#if	UseStaticMsgType
	OutP->cvrType = cvrType;
#else	UseStaticMsgType
	OutP->cvrType.msg_type_name = MSG_TYPE_CHAR;
	OutP->cvrType.msg_type_size = 8;
	OutP->cvrType.msg_type_number = 1;
	OutP->cvrType.msg_type_inline = TRUE;
	OutP->cvrType.msg_type_longform = FALSE;
	OutP->cvrType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	OutP->Head.msg_simple = TRUE;
	OutP->Head.msg_size = msg_size;
}

/* Routine dsp_get_isr */
mig_internal novalue _Xdsp_get_isr
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_get_isr (port_t dspdriver_port, port_t owner_port, char *isr, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
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
	static const msg_type_t isrType = {
		/* msg_type_name = */		MSG_TYPE_CHAR,
		/* msg_type_size = */		8,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	TypeCheck
	msg_size = In0P->Head.msg_size;
	msg_simple = In0P->Head.msg_simple;
	if ((msg_size != 40) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = dsp_get_isr(In0P->Head.msg_request_port, In0P->owner_port, &OutP->isr, In0P->unit);
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	if (OutP->RetCode != KERN_SUCCESS)
		return;

	msg_size = 40;	

#if	UseStaticMsgType
	OutP->isrType = isrType;
#else	UseStaticMsgType
	OutP->isrType.msg_type_name = MSG_TYPE_CHAR;
	OutP->isrType.msg_type_size = 8;
	OutP->isrType.msg_type_number = 1;
	OutP->isrType.msg_type_inline = TRUE;
	OutP->isrType.msg_type_longform = FALSE;
	OutP->isrType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	OutP->Head.msg_simple = TRUE;
	OutP->Head.msg_size = msg_size;
}

/* Routine dsp_get_ivr */
mig_internal novalue _Xdsp_get_ivr
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_get_ivr (port_t dspdriver_port, port_t owner_port, char *ivr, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
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

#if	TypeCheck
	msg_size = In0P->Head.msg_size;
	msg_simple = In0P->Head.msg_simple;
	if ((msg_size != 40) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = dsp_get_ivr(In0P->Head.msg_request_port, In0P->owner_port, &OutP->ivr, In0P->unit);
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	if (OutP->RetCode != KERN_SUCCESS)
		return;

	msg_size = 40;	

#if	UseStaticMsgType
	OutP->ivrType = ivrType;
#else	UseStaticMsgType
	OutP->ivrType.msg_type_name = MSG_TYPE_CHAR;
	OutP->ivrType.msg_type_size = 8;
	OutP->ivrType.msg_type_number = 1;
	OutP->ivrType.msg_type_inline = TRUE;
	OutP->ivrType.msg_type_longform = FALSE;
	OutP->ivrType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	OutP->Head.msg_simple = TRUE;
	OutP->Head.msg_size = msg_size;
}

/* SimpleRoutine dsp_put_icr */
mig_internal novalue _Xdsp_put_icr
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_put_icr (port_t dspdriver_port, port_t owner_port, char icr, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
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
	static const msg_type_t unitCheck = {
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
	if ((msg_size != 48) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->icrType != * (int *) &icrCheck)
#else	UseStaticMsgType
	if ((In0P->icrType.msg_type_inline != TRUE) ||
	    (In0P->icrType.msg_type_longform != FALSE) ||
	    (In0P->icrType.msg_type_name != MSG_TYPE_CHAR) ||
	    (In0P->icrType.msg_type_number != 1) ||
	    (In0P->icrType.msg_type_size != 8))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_put_icr(In0P->Head.msg_request_port, In0P->owner_port, In0P->icr, In0P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine dsp_put_cvr */
mig_internal novalue _Xdsp_put_cvr
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_put_cvr (port_t dspdriver_port, port_t owner_port, char cvr, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
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
	static const msg_type_t unitCheck = {
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
	if ((msg_size != 48) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->cvrType != * (int *) &cvrCheck)
#else	UseStaticMsgType
	if ((In0P->cvrType.msg_type_inline != TRUE) ||
	    (In0P->cvrType.msg_type_longform != FALSE) ||
	    (In0P->cvrType.msg_type_name != MSG_TYPE_CHAR) ||
	    (In0P->cvrType.msg_type_number != 1) ||
	    (In0P->cvrType.msg_type_size != 8))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_put_cvr(In0P->Head.msg_request_port, In0P->owner_port, In0P->cvr, In0P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine dsp_put_ivr */
mig_internal novalue _Xdsp_put_ivr
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_put_ivr (port_t dspdriver_port, port_t owner_port, char ivr, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
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
	static const msg_type_t unitCheck = {
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
	if ((msg_size != 48) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->ivrType != * (int *) &ivrCheck)
#else	UseStaticMsgType
	if ((In0P->ivrType.msg_type_inline != TRUE) ||
	    (In0P->ivrType.msg_type_longform != FALSE) ||
	    (In0P->ivrType.msg_type_name != MSG_TYPE_CHAR) ||
	    (In0P->ivrType.msg_type_number != 1) ||
	    (In0P->ivrType.msg_type_size != 8))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_put_ivr(In0P->Head.msg_request_port, In0P->owner_port, In0P->ivr, In0P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine dsp_put_data_raw */
mig_internal novalue _Xdsp_put_data_raw
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_put_data_raw (port_t dspdriver_port, port_t owner_port, char high, char med, char low, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
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
	static const msg_type_t unitCheck = {
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
	if ((msg_size != 64) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->highType != * (int *) &highCheck)
#else	UseStaticMsgType
	if ((In0P->highType.msg_type_inline != TRUE) ||
	    (In0P->highType.msg_type_longform != FALSE) ||
	    (In0P->highType.msg_type_name != MSG_TYPE_CHAR) ||
	    (In0P->highType.msg_type_number != 1) ||
	    (In0P->highType.msg_type_size != 8))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->medType != * (int *) &medCheck)
#else	UseStaticMsgType
	if ((In0P->medType.msg_type_inline != TRUE) ||
	    (In0P->medType.msg_type_longform != FALSE) ||
	    (In0P->medType.msg_type_name != MSG_TYPE_CHAR) ||
	    (In0P->medType.msg_type_number != 1) ||
	    (In0P->medType.msg_type_size != 8))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->lowType != * (int *) &lowCheck)
#else	UseStaticMsgType
	if ((In0P->lowType.msg_type_inline != TRUE) ||
	    (In0P->lowType.msg_type_longform != FALSE) ||
	    (In0P->lowType.msg_type_name != MSG_TYPE_CHAR) ||
	    (In0P->lowType.msg_type_number != 1) ||
	    (In0P->lowType.msg_type_size != 8))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_put_data_raw(In0P->Head.msg_request_port, In0P->owner_port, In0P->high, In0P->med, In0P->low, In0P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* Routine dsp_get_data_raw */
mig_internal novalue _Xdsp_get_data_raw
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_get_data_raw (port_t dspdriver_port, port_t owner_port, char *high, char *med, char *low, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
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

#if	TypeCheck
	msg_size = In0P->Head.msg_size;
	msg_simple = In0P->Head.msg_simple;
	if ((msg_size != 40) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = dsp_get_data_raw(In0P->Head.msg_request_port, In0P->owner_port, &OutP->high, &OutP->med, &OutP->low, In0P->unit);
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	if (OutP->RetCode != KERN_SUCCESS)
		return;

	msg_size = 56;	

#if	UseStaticMsgType
	OutP->highType = highType;
#else	UseStaticMsgType
	OutP->highType.msg_type_name = MSG_TYPE_CHAR;
	OutP->highType.msg_type_size = 8;
	OutP->highType.msg_type_number = 1;
	OutP->highType.msg_type_inline = TRUE;
	OutP->highType.msg_type_longform = FALSE;
	OutP->highType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

#if	UseStaticMsgType
	OutP->medType = medType;
#else	UseStaticMsgType
	OutP->medType.msg_type_name = MSG_TYPE_CHAR;
	OutP->medType.msg_type_size = 8;
	OutP->medType.msg_type_number = 1;
	OutP->medType.msg_type_inline = TRUE;
	OutP->medType.msg_type_longform = FALSE;
	OutP->medType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

#if	UseStaticMsgType
	OutP->lowType = lowType;
#else	UseStaticMsgType
	OutP->lowType.msg_type_name = MSG_TYPE_CHAR;
	OutP->lowType.msg_type_size = 8;
	OutP->lowType.msg_type_number = 1;
	OutP->lowType.msg_type_inline = TRUE;
	OutP->lowType.msg_type_longform = FALSE;
	OutP->lowType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	OutP->Head.msg_simple = TRUE;
	OutP->Head.msg_size = msg_size;
}

/* SimpleRoutine dsp_put_data */
mig_internal novalue _Xdsp_put_data
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_put_data (port_t dspdriver_port, port_t owner_port, char high, char med, char low, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
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
	static const msg_type_t unitCheck = {
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
	if ((msg_size != 64) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->highType != * (int *) &highCheck)
#else	UseStaticMsgType
	if ((In0P->highType.msg_type_inline != TRUE) ||
	    (In0P->highType.msg_type_longform != FALSE) ||
	    (In0P->highType.msg_type_name != MSG_TYPE_CHAR) ||
	    (In0P->highType.msg_type_number != 1) ||
	    (In0P->highType.msg_type_size != 8))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->medType != * (int *) &medCheck)
#else	UseStaticMsgType
	if ((In0P->medType.msg_type_inline != TRUE) ||
	    (In0P->medType.msg_type_longform != FALSE) ||
	    (In0P->medType.msg_type_name != MSG_TYPE_CHAR) ||
	    (In0P->medType.msg_type_number != 1) ||
	    (In0P->medType.msg_type_size != 8))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->lowType != * (int *) &lowCheck)
#else	UseStaticMsgType
	if ((In0P->lowType.msg_type_inline != TRUE) ||
	    (In0P->lowType.msg_type_longform != FALSE) ||
	    (In0P->lowType.msg_type_name != MSG_TYPE_CHAR) ||
	    (In0P->lowType.msg_type_number != 1) ||
	    (In0P->lowType.msg_type_size != 8))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_put_data(In0P->Head.msg_request_port, In0P->owner_port, In0P->high, In0P->med, In0P->low, In0P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* Routine dsp_get_data */
mig_internal novalue _Xdsp_get_data
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_get_data (port_t dspdriver_port, port_t owner_port, char *high, char *med, char *low, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
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

#if	TypeCheck
	msg_size = In0P->Head.msg_size;
	msg_simple = In0P->Head.msg_simple;
	if ((msg_size != 40) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = dsp_get_data(In0P->Head.msg_request_port, In0P->owner_port, &OutP->high, &OutP->med, &OutP->low, In0P->unit);
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	if (OutP->RetCode != KERN_SUCCESS)
		return;

	msg_size = 56;	

#if	UseStaticMsgType
	OutP->highType = highType;
#else	UseStaticMsgType
	OutP->highType.msg_type_name = MSG_TYPE_CHAR;
	OutP->highType.msg_type_size = 8;
	OutP->highType.msg_type_number = 1;
	OutP->highType.msg_type_inline = TRUE;
	OutP->highType.msg_type_longform = FALSE;
	OutP->highType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

#if	UseStaticMsgType
	OutP->medType = medType;
#else	UseStaticMsgType
	OutP->medType.msg_type_name = MSG_TYPE_CHAR;
	OutP->medType.msg_type_size = 8;
	OutP->medType.msg_type_number = 1;
	OutP->medType.msg_type_inline = TRUE;
	OutP->medType.msg_type_longform = FALSE;
	OutP->medType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

#if	UseStaticMsgType
	OutP->lowType = lowType;
#else	UseStaticMsgType
	OutP->lowType.msg_type_name = MSG_TYPE_CHAR;
	OutP->lowType.msg_type_size = 8;
	OutP->lowType.msg_type_number = 1;
	OutP->lowType.msg_type_inline = TRUE;
	OutP->lowType.msg_type_longform = FALSE;
	OutP->lowType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	OutP->Head.msg_simple = TRUE;
	OutP->Head.msg_size = msg_size;
}

/* SimpleRoutine dsp_put_data_array */
mig_internal novalue _Xdsp_put_data_array
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Request *In1P;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_put_data_array (port_t dspdriver_port, port_t owner_port, DSPWordPtr data, unsigned int dataCnt, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;
	unsigned int msg_size_delta;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
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
	if ((msg_size < 44) || (msg_size > 2092) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
	if ((In0P->dataType.msg_type_inline != TRUE) ||
	    (In0P->dataType.msg_type_longform != FALSE) ||
	    (In0P->dataType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->dataType.msg_type_size != 32))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	msg_size_delta = 4 * In0P->dataType.msg_type_number;
#if	TypeCheck
	if (msg_size != 44 + msg_size_delta)
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	In1P = (Request *) ((char *) In0P + msg_size_delta - 2048);

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In1P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In1P->unitType.msg_type_inline != TRUE) ||
	    (In1P->unitType.msg_type_longform != FALSE) ||
	    (In1P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In1P->unitType.msg_type_number != 1) ||
	    (In1P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_put_data_array(In0P->Head.msg_request_port, In0P->owner_port, In0P->data, In0P->dataType.msg_type_number, In1P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine dsp_put_data_byte_array */
mig_internal novalue _Xdsp_put_data_byte_array
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Request *In1P;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_put_data_byte_array (port_t dspdriver_port, port_t owner_port, DSPCharPtr data, unsigned int dataCnt, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;
	unsigned int msg_size_delta;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
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
	if ((msg_size < 44) || (msg_size > 2092) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
	if ((In0P->dataType.msg_type_inline != TRUE) ||
	    (In0P->dataType.msg_type_longform != FALSE) ||
	    (In0P->dataType.msg_type_name != MSG_TYPE_CHAR) ||
	    (In0P->dataType.msg_type_size != 8))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	msg_size_delta = (1 * In0P->dataType.msg_type_number + 3) & ~3;
#if	TypeCheck
	if (msg_size != 44 + msg_size_delta)
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	In1P = (Request *) ((char *) In0P + msg_size_delta - 2048);

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In1P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In1P->unitType.msg_type_inline != TRUE) ||
	    (In1P->unitType.msg_type_longform != FALSE) ||
	    (In1P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In1P->unitType.msg_type_number != 1) ||
	    (In1P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_put_data_byte_array(In0P->Head.msg_request_port, In0P->owner_port, In0P->data, In0P->dataType.msg_type_number, In1P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine dsp_put_data_short_array */
mig_internal novalue _Xdsp_put_data_short_array
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Request *In1P;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_put_data_short_array (port_t dspdriver_port, port_t owner_port, DSPShortPtr data, unsigned int dataCnt, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;
	unsigned int msg_size_delta;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
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
	if ((msg_size < 44) || (msg_size > 2092) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
	if ((In0P->dataType.msg_type_inline != TRUE) ||
	    (In0P->dataType.msg_type_longform != FALSE) ||
	    (In0P->dataType.msg_type_name != MSG_TYPE_INTEGER_16) ||
	    (In0P->dataType.msg_type_size != 16))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	msg_size_delta = (2 * In0P->dataType.msg_type_number + 3) & ~3;
#if	TypeCheck
	if (msg_size != 44 + msg_size_delta)
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	In1P = (Request *) ((char *) In0P + msg_size_delta - 2048);

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In1P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In1P->unitType.msg_type_inline != TRUE) ||
	    (In1P->unitType.msg_type_longform != FALSE) ||
	    (In1P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In1P->unitType.msg_type_number != 1) ||
	    (In1P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_put_data_short_array(In0P->Head.msg_request_port, In0P->owner_port, In0P->data, In0P->dataType.msg_type_number, In1P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine dsp_put_data_packed_array */
mig_internal novalue _Xdsp_put_data_packed_array
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Request *In1P;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_put_data_packed_array (port_t dspdriver_port, port_t owner_port, DSPCharPtr data, unsigned int dataCnt, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;
	unsigned int msg_size_delta;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
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
	if ((msg_size < 44) || (msg_size > 2092) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
	if ((In0P->dataType.msg_type_inline != TRUE) ||
	    (In0P->dataType.msg_type_longform != FALSE) ||
	    (In0P->dataType.msg_type_name != MSG_TYPE_CHAR) ||
	    (In0P->dataType.msg_type_size != 8))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	msg_size_delta = (1 * In0P->dataType.msg_type_number + 3) & ~3;
#if	TypeCheck
	if (msg_size != 44 + msg_size_delta)
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	In1P = (Request *) ((char *) In0P + msg_size_delta - 2048);

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In1P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In1P->unitType.msg_type_inline != TRUE) ||
	    (In1P->unitType.msg_type_longform != FALSE) ||
	    (In1P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In1P->unitType.msg_type_number != 1) ||
	    (In1P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_put_data_packed_array(In0P->Head.msg_request_port, In0P->owner_port, In0P->data, In0P->dataType.msg_type_number, In1P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine dsp_put_data_left_array */
mig_internal novalue _Xdsp_put_data_left_array
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Request *In1P;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_put_data_left_array (port_t dspdriver_port, port_t owner_port, DSPWordPtr data, unsigned int dataCnt, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;
	unsigned int msg_size_delta;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
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
	if ((msg_size < 44) || (msg_size > 2092) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
	if ((In0P->dataType.msg_type_inline != TRUE) ||
	    (In0P->dataType.msg_type_longform != FALSE) ||
	    (In0P->dataType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->dataType.msg_type_size != 32))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	msg_size_delta = 4 * In0P->dataType.msg_type_number;
#if	TypeCheck
	if (msg_size != 44 + msg_size_delta)
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	In1P = (Request *) ((char *) In0P + msg_size_delta - 2048);

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In1P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In1P->unitType.msg_type_inline != TRUE) ||
	    (In1P->unitType.msg_type_longform != FALSE) ||
	    (In1P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In1P->unitType.msg_type_number != 1) ||
	    (In1P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_put_data_left_array(In0P->Head.msg_request_port, In0P->owner_port, In0P->data, In0P->dataType.msg_type_number, In1P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* Routine dsp_get_data_array */
mig_internal novalue _Xdsp_get_data_array
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_get_data_array (port_t dspdriver_port, port_t owner_port, int count, DSPWordPtr data, unsigned int *dataCnt, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;
	unsigned int msg_size_delta;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t countCheck = {
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
	static const msg_type_t unitCheck = {
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

	unsigned int dataCnt;

#if	TypeCheck
	msg_size = In0P->Head.msg_size;
	msg_simple = In0P->Head.msg_simple;
	if ((msg_size != 48) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->countType != * (int *) &countCheck)
#else	UseStaticMsgType
	if ((In0P->countType.msg_type_inline != TRUE) ||
	    (In0P->countType.msg_type_longform != FALSE) ||
	    (In0P->countType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->countType.msg_type_number != 1) ||
	    (In0P->countType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	dataCnt = 512;

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = dsp_get_data_array(In0P->Head.msg_request_port, In0P->owner_port, In0P->count, OutP->data, &dataCnt, In0P->unit);
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	if (OutP->RetCode != KERN_SUCCESS)
		return;

	msg_size = 36;	
	/* Maximum reply size 2084 */

#if	UseStaticMsgType
	OutP->dataType = dataType;
#else	UseStaticMsgType
	OutP->dataType.msg_type_name = MSG_TYPE_INTEGER_32;
	OutP->dataType.msg_type_size = 32;
	OutP->dataType.msg_type_inline = TRUE;
	OutP->dataType.msg_type_longform = FALSE;
	OutP->dataType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	OutP->dataType.msg_type_number /* dataCnt */ = /* dataType.msg_type_number */ dataCnt;

	msg_size_delta = 4 * dataCnt;
	msg_size += msg_size_delta;

	OutP->Head.msg_simple = TRUE;
	OutP->Head.msg_size = msg_size;
}

/* SimpleRoutine dsp_put_mk_timed_message */
mig_internal novalue _Xdsp_put_mk_timed_message
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_put_mk_timed_message (port_t dspdriver_port, port_t owner_port, int highWord, int lowWord, int opCode, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t highWordCheck = {
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
	static const msg_type_t lowWordCheck = {
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
	static const msg_type_t opCodeCheck = {
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
	static const msg_type_t unitCheck = {
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
	if ((msg_size != 64) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->highWordType != * (int *) &highWordCheck)
#else	UseStaticMsgType
	if ((In0P->highWordType.msg_type_inline != TRUE) ||
	    (In0P->highWordType.msg_type_longform != FALSE) ||
	    (In0P->highWordType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->highWordType.msg_type_number != 1) ||
	    (In0P->highWordType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->lowWordType != * (int *) &lowWordCheck)
#else	UseStaticMsgType
	if ((In0P->lowWordType.msg_type_inline != TRUE) ||
	    (In0P->lowWordType.msg_type_longform != FALSE) ||
	    (In0P->lowWordType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->lowWordType.msg_type_number != 1) ||
	    (In0P->lowWordType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->opCodeType != * (int *) &opCodeCheck)
#else	UseStaticMsgType
	if ((In0P->opCodeType.msg_type_inline != TRUE) ||
	    (In0P->opCodeType.msg_type_longform != FALSE) ||
	    (In0P->opCodeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->opCodeType.msg_type_number != 1) ||
	    (In0P->opCodeType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_put_mk_timed_message(In0P->Head.msg_request_port, In0P->owner_port, In0P->highWord, In0P->lowWord, In0P->opCode, In0P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine dsp_exec_mk_host_message */
mig_internal novalue _Xdsp_exec_mk_host_message
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_exec_mk_host_message (port_t dspdriver_port, port_t owner_port, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
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
	if ((msg_size != 40) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_exec_mk_host_message(In0P->Head.msg_request_port, In0P->owner_port, In0P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* Routine dsp_get_hi */
mig_internal novalue _Xdsp_get_hi
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_get_hi (port_t dspdriver_port, port_t owner_port, int *hi, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
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
	static const msg_type_t hiType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0,
	};
#endif	UseStaticMsgType

#if	TypeCheck
	msg_size = In0P->Head.msg_size;
	msg_simple = In0P->Head.msg_simple;
	if ((msg_size != 40) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = dsp_get_hi(In0P->Head.msg_request_port, In0P->owner_port, &OutP->hi, In0P->unit);
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	if (OutP->RetCode != KERN_SUCCESS)
		return;

	msg_size = 40;	

#if	UseStaticMsgType
	OutP->hiType = hiType;
#else	UseStaticMsgType
	OutP->hiType.msg_type_name = MSG_TYPE_INTEGER_32;
	OutP->hiType.msg_type_size = 32;
	OutP->hiType.msg_type_number = 1;
	OutP->hiType.msg_type_inline = TRUE;
	OutP->hiType.msg_type_longform = FALSE;
	OutP->hiType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	OutP->Head.msg_simple = TRUE;
	OutP->Head.msg_size = msg_size;
}

/* SimpleRoutine dsp_put_and_exec_mk_host_message */
mig_internal novalue _Xdsp_put_and_exec_mk_host_message
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Request *In1P;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_put_and_exec_mk_host_message (port_t dspdriver_port, port_t owner_port, DSPWordPtr data, unsigned int dataCnt, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;
	unsigned int msg_size_delta;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
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
	if ((msg_size < 44) || (msg_size > 2092) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
	if ((In0P->dataType.msg_type_inline != TRUE) ||
	    (In0P->dataType.msg_type_longform != FALSE) ||
	    (In0P->dataType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->dataType.msg_type_size != 32))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	msg_size_delta = 4 * In0P->dataType.msg_type_number;
#if	TypeCheck
	if (msg_size != 44 + msg_size_delta)
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	In1P = (Request *) ((char *) In0P + msg_size_delta - 2048);

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In1P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In1P->unitType.msg_type_inline != TRUE) ||
	    (In1P->unitType.msg_type_longform != FALSE) ||
	    (In1P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In1P->unitType.msg_type_number != 1) ||
	    (In1P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_put_and_exec_mk_host_message(In0P->Head.msg_request_port, In0P->owner_port, In0P->data, In0P->dataType.msg_type_number, In1P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine dsp_set_sub_unit */
mig_internal novalue _Xdsp_set_sub_unit
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_set_sub_unit (port_t dspdriver_port, port_t owner_port, int sub_unit, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t sub_unitCheck = {
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
	static const msg_type_t unitCheck = {
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
	if ((msg_size != 48) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->sub_unitType != * (int *) &sub_unitCheck)
#else	UseStaticMsgType
	if ((In0P->sub_unitType.msg_type_inline != TRUE) ||
	    (In0P->sub_unitType.msg_type_longform != FALSE) ||
	    (In0P->sub_unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->sub_unitType.msg_type_number != 1) ||
	    (In0P->sub_unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_set_sub_unit(In0P->Head.msg_request_port, In0P->owner_port, In0P->sub_unit, In0P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine dsp_put_page */
mig_internal novalue _Xdsp_put_page
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_put_page (port_t dspdriver_port, port_t owner_port, DSPPagePtr pageAddress, int regionTag, boolean_t msgStarted, boolean_t msgCompleted, port_t reply_port, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t pageAddressCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		2048,
		/* msg_type_inline = */		FALSE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t regionTagCheck = {
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
	static const msg_type_t msgStartedCheck = {
		/* msg_type_name = */		MSG_TYPE_BOOLEAN,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t msgCompletedCheck = {
		/* msg_type_name = */		MSG_TYPE_BOOLEAN,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t reply_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
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
	if ((msg_size != 80) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->pageAddressType != * (int *) &pageAddressCheck)
#else	UseStaticMsgType
	if ((In0P->pageAddressType.msg_type_inline != FALSE) ||
	    (In0P->pageAddressType.msg_type_longform != FALSE) ||
	    (In0P->pageAddressType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->pageAddressType.msg_type_number != 2048) ||
	    (In0P->pageAddressType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->regionTagType != * (int *) &regionTagCheck)
#else	UseStaticMsgType
	if ((In0P->regionTagType.msg_type_inline != TRUE) ||
	    (In0P->regionTagType.msg_type_longform != FALSE) ||
	    (In0P->regionTagType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->regionTagType.msg_type_number != 1) ||
	    (In0P->regionTagType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->msgStartedType != * (int *) &msgStartedCheck)
#else	UseStaticMsgType
	if ((In0P->msgStartedType.msg_type_inline != TRUE) ||
	    (In0P->msgStartedType.msg_type_longform != FALSE) ||
	    (In0P->msgStartedType.msg_type_name != MSG_TYPE_BOOLEAN) ||
	    (In0P->msgStartedType.msg_type_number != 1) ||
	    (In0P->msgStartedType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->msgCompletedType != * (int *) &msgCompletedCheck)
#else	UseStaticMsgType
	if ((In0P->msgCompletedType.msg_type_inline != TRUE) ||
	    (In0P->msgCompletedType.msg_type_longform != FALSE) ||
	    (In0P->msgCompletedType.msg_type_name != MSG_TYPE_BOOLEAN) ||
	    (In0P->msgCompletedType.msg_type_number != 1) ||
	    (In0P->msgCompletedType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->reply_portType != * (int *) &reply_portCheck)
#else	UseStaticMsgType
	if ((In0P->reply_portType.msg_type_inline != TRUE) ||
	    (In0P->reply_portType.msg_type_longform != FALSE) ||
	    (In0P->reply_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->reply_portType.msg_type_number != 1) ||
	    (In0P->reply_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_put_page(In0P->Head.msg_request_port, In0P->owner_port, In0P->pageAddress, In0P->regionTag, In0P->msgStarted, In0P->msgCompleted, In0P->reply_port, In0P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine dsp_set_messaging */
mig_internal novalue _Xdsp_set_messaging
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_set_messaging (port_t dspdriver_port, port_t owner_port, boolean_t flag, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t flagCheck = {
		/* msg_type_name = */		MSG_TYPE_BOOLEAN,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
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
	if ((msg_size != 48) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->flagType != * (int *) &flagCheck)
#else	UseStaticMsgType
	if ((In0P->flagType.msg_type_inline != TRUE) ||
	    (In0P->flagType.msg_type_longform != FALSE) ||
	    (In0P->flagType.msg_type_name != MSG_TYPE_BOOLEAN) ||
	    (In0P->flagType.msg_type_number != 1) ||
	    (In0P->flagType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_set_messaging(In0P->Head.msg_request_port, In0P->owner_port, In0P->flag, In0P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine dsp_queue_page */
mig_internal novalue _Xdsp_queue_page
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_queue_page (port_t dspdriver_port, port_t owner_port, DSPPagePtr pageAddress, int regionTag, boolean_t msgStarted, boolean_t msgCompleted, port_t reply_port, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t pageAddressCheck = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_32,
		/* msg_type_size = */		32,
		/* msg_type_number = */		2048,
		/* msg_type_inline = */		FALSE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t regionTagCheck = {
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
	static const msg_type_t msgStartedCheck = {
		/* msg_type_name = */		MSG_TYPE_BOOLEAN,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t msgCompletedCheck = {
		/* msg_type_name = */		MSG_TYPE_BOOLEAN,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t reply_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
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
	if ((msg_size != 80) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->pageAddressType != * (int *) &pageAddressCheck)
#else	UseStaticMsgType
	if ((In0P->pageAddressType.msg_type_inline != FALSE) ||
	    (In0P->pageAddressType.msg_type_longform != FALSE) ||
	    (In0P->pageAddressType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->pageAddressType.msg_type_number != 2048) ||
	    (In0P->pageAddressType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->regionTagType != * (int *) &regionTagCheck)
#else	UseStaticMsgType
	if ((In0P->regionTagType.msg_type_inline != TRUE) ||
	    (In0P->regionTagType.msg_type_longform != FALSE) ||
	    (In0P->regionTagType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->regionTagType.msg_type_number != 1) ||
	    (In0P->regionTagType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->msgStartedType != * (int *) &msgStartedCheck)
#else	UseStaticMsgType
	if ((In0P->msgStartedType.msg_type_inline != TRUE) ||
	    (In0P->msgStartedType.msg_type_longform != FALSE) ||
	    (In0P->msgStartedType.msg_type_name != MSG_TYPE_BOOLEAN) ||
	    (In0P->msgStartedType.msg_type_number != 1) ||
	    (In0P->msgStartedType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->msgCompletedType != * (int *) &msgCompletedCheck)
#else	UseStaticMsgType
	if ((In0P->msgCompletedType.msg_type_inline != TRUE) ||
	    (In0P->msgCompletedType.msg_type_longform != FALSE) ||
	    (In0P->msgCompletedType.msg_type_name != MSG_TYPE_BOOLEAN) ||
	    (In0P->msgCompletedType.msg_type_number != 1) ||
	    (In0P->msgCompletedType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->reply_portType != * (int *) &reply_portCheck)
#else	UseStaticMsgType
	if ((In0P->reply_portType.msg_type_inline != TRUE) ||
	    (In0P->reply_portType.msg_type_longform != FALSE) ||
	    (In0P->reply_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->reply_portType.msg_type_number != 1) ||
	    (In0P->reply_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_queue_page(In0P->Head.msg_request_port, In0P->owner_port, In0P->pageAddress, In0P->regionTag, In0P->msgStarted, In0P->msgCompleted, In0P->reply_port, In0P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine dsp_set_short_big_endian_return */
mig_internal novalue _Xdsp_set_short_big_endian_return
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_set_short_big_endian_return (port_t dspdriver_port, port_t owner_port, int regionTag, int wordCount, port_t reply_port, int chan, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t regionTagCheck = {
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
	static const msg_type_t wordCountCheck = {
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
	static const msg_type_t reply_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t chanCheck = {
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
	static const msg_type_t unitCheck = {
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
	if ((msg_size != 72) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->regionTagType != * (int *) &regionTagCheck)
#else	UseStaticMsgType
	if ((In0P->regionTagType.msg_type_inline != TRUE) ||
	    (In0P->regionTagType.msg_type_longform != FALSE) ||
	    (In0P->regionTagType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->regionTagType.msg_type_number != 1) ||
	    (In0P->regionTagType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->wordCountType != * (int *) &wordCountCheck)
#else	UseStaticMsgType
	if ((In0P->wordCountType.msg_type_inline != TRUE) ||
	    (In0P->wordCountType.msg_type_longform != FALSE) ||
	    (In0P->wordCountType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->wordCountType.msg_type_number != 1) ||
	    (In0P->wordCountType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->reply_portType != * (int *) &reply_portCheck)
#else	UseStaticMsgType
	if ((In0P->reply_portType.msg_type_inline != TRUE) ||
	    (In0P->reply_portType.msg_type_longform != FALSE) ||
	    (In0P->reply_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->reply_portType.msg_type_number != 1) ||
	    (In0P->reply_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->chanType != * (int *) &chanCheck)
#else	UseStaticMsgType
	if ((In0P->chanType.msg_type_inline != TRUE) ||
	    (In0P->chanType.msg_type_longform != FALSE) ||
	    (In0P->chanType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->chanType.msg_type_number != 1) ||
	    (In0P->chanType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_set_short_big_endian_return(In0P->Head.msg_request_port, In0P->owner_port, In0P->regionTag, In0P->wordCount, In0P->reply_port, In0P->chan, In0P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine dsp_set_short_return */
mig_internal novalue _Xdsp_set_short_return
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_set_short_return (port_t dspdriver_port, port_t owner_port, int regionTag, int wordCount, port_t reply_port, int chan, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t regionTagCheck = {
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
	static const msg_type_t wordCountCheck = {
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
	static const msg_type_t reply_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t chanCheck = {
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
	static const msg_type_t unitCheck = {
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
	if ((msg_size != 72) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->regionTagType != * (int *) &regionTagCheck)
#else	UseStaticMsgType
	if ((In0P->regionTagType.msg_type_inline != TRUE) ||
	    (In0P->regionTagType.msg_type_longform != FALSE) ||
	    (In0P->regionTagType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->regionTagType.msg_type_number != 1) ||
	    (In0P->regionTagType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->wordCountType != * (int *) &wordCountCheck)
#else	UseStaticMsgType
	if ((In0P->wordCountType.msg_type_inline != TRUE) ||
	    (In0P->wordCountType.msg_type_longform != FALSE) ||
	    (In0P->wordCountType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->wordCountType.msg_type_number != 1) ||
	    (In0P->wordCountType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->reply_portType != * (int *) &reply_portCheck)
#else	UseStaticMsgType
	if ((In0P->reply_portType.msg_type_inline != TRUE) ||
	    (In0P->reply_portType.msg_type_longform != FALSE) ||
	    (In0P->reply_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->reply_portType.msg_type_number != 1) ||
	    (In0P->reply_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->chanType != * (int *) &chanCheck)
#else	UseStaticMsgType
	if ((In0P->chanType.msg_type_inline != TRUE) ||
	    (In0P->chanType.msg_type_longform != FALSE) ||
	    (In0P->chanType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->chanType.msg_type_number != 1) ||
	    (In0P->chanType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_set_short_return(In0P->Head.msg_request_port, In0P->owner_port, In0P->regionTag, In0P->wordCount, In0P->reply_port, In0P->chan, In0P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine dsp_set_long_return */
mig_internal novalue _Xdsp_set_long_return
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_set_long_return (port_t dspdriver_port, port_t owner_port, int regionTag, int wordCount, port_t reply_port, int chan, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t regionTagCheck = {
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
	static const msg_type_t wordCountCheck = {
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
	static const msg_type_t reply_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t chanCheck = {
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
	static const msg_type_t unitCheck = {
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
	if ((msg_size != 72) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->regionTagType != * (int *) &regionTagCheck)
#else	UseStaticMsgType
	if ((In0P->regionTagType.msg_type_inline != TRUE) ||
	    (In0P->regionTagType.msg_type_longform != FALSE) ||
	    (In0P->regionTagType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->regionTagType.msg_type_number != 1) ||
	    (In0P->regionTagType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->wordCountType != * (int *) &wordCountCheck)
#else	UseStaticMsgType
	if ((In0P->wordCountType.msg_type_inline != TRUE) ||
	    (In0P->wordCountType.msg_type_longform != FALSE) ||
	    (In0P->wordCountType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->wordCountType.msg_type_number != 1) ||
	    (In0P->wordCountType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->reply_portType != * (int *) &reply_portCheck)
#else	UseStaticMsgType
	if ((In0P->reply_portType.msg_type_inline != TRUE) ||
	    (In0P->reply_portType.msg_type_longform != FALSE) ||
	    (In0P->reply_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->reply_portType.msg_type_number != 1) ||
	    (In0P->reply_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->chanType != * (int *) &chanCheck)
#else	UseStaticMsgType
	if ((In0P->chanType.msg_type_inline != TRUE) ||
	    (In0P->chanType.msg_type_longform != FALSE) ||
	    (In0P->chanType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->chanType.msg_type_number != 1) ||
	    (In0P->chanType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_set_long_return(In0P->Head.msg_request_port, In0P->owner_port, In0P->regionTag, In0P->wordCount, In0P->reply_port, In0P->chan, In0P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine dsp_set_error_port */
mig_internal novalue _Xdsp_set_error_port
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_set_error_port (port_t dspdriver_port, port_t owner_port, port_t reply_port, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t reply_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
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
	if ((msg_size != 48) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->reply_portType != * (int *) &reply_portCheck)
#else	UseStaticMsgType
	if ((In0P->reply_portType.msg_type_inline != TRUE) ||
	    (In0P->reply_portType.msg_type_longform != FALSE) ||
	    (In0P->reply_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->reply_portType.msg_type_number != 1) ||
	    (In0P->reply_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_set_error_port(In0P->Head.msg_request_port, In0P->owner_port, In0P->reply_port, In0P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine dsp_set_msg_port */
mig_internal novalue _Xdsp_set_msg_port
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_set_msg_port (port_t dspdriver_port, port_t owner_port, port_t reply_port, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t reply_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t unitCheck = {
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
	if ((msg_size != 48) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->reply_portType != * (int *) &reply_portCheck)
#else	UseStaticMsgType
	if ((In0P->reply_portType.msg_type_inline != TRUE) ||
	    (In0P->reply_portType.msg_type_longform != FALSE) ||
	    (In0P->reply_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->reply_portType.msg_type_number != 1) ||
	    (In0P->reply_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_set_msg_port(In0P->Head.msg_request_port, In0P->owner_port, In0P->reply_port, In0P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine dsp_set_debug */
mig_internal novalue _Xdsp_set_debug
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t debug_flagsType;
		int debug_flags;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_set_debug (port_t dspdriver_port, int debug_flags);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t debug_flagsCheck = {
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
	if (* (int *) &In0P->debug_flagsType != * (int *) &debug_flagsCheck)
#else	UseStaticMsgType
	if ((In0P->debug_flagsType.msg_type_inline != TRUE) ||
	    (In0P->debug_flagsType.msg_type_longform != FALSE) ||
	    (In0P->debug_flagsType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->debug_flagsType.msg_type_number != 1) ||
	    (In0P->debug_flagsType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_set_debug(In0P->Head.msg_request_port, In0P->debug_flags);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* SimpleRoutine dsp_free_page */
mig_internal novalue _Xdsp_free_page
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
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

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t dsp_free_page (port_t dspdriver_port, port_t owner_port, int page_index, int unit);

#if	TypeCheck
	boolean_t msg_simple;
#endif	TypeCheck

	unsigned int msg_size;

#if	UseStaticMsgType
	static const msg_type_t owner_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
		/* msg_type_size = */		32,
		/* msg_type_number = */		1,
		/* msg_type_inline = */		TRUE,
		/* msg_type_longform = */	FALSE,
		/* msg_type_deallocate = */	FALSE,
		/* msg_type_unused = */		0
	};
#endif	UseStaticMsgType

#if	UseStaticMsgType
	static const msg_type_t page_indexCheck = {
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
	static const msg_type_t unitCheck = {
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
	if ((msg_size != 48) || (msg_simple != FALSE))
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; return; }
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->owner_portType != * (int *) &owner_portCheck)
#else	UseStaticMsgType
	if ((In0P->owner_portType.msg_type_inline != TRUE) ||
	    (In0P->owner_portType.msg_type_longform != FALSE) ||
	    (In0P->owner_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->owner_portType.msg_type_number != 1) ||
	    (In0P->owner_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->page_indexType != * (int *) &page_indexCheck)
#else	UseStaticMsgType
	if ((In0P->page_indexType.msg_type_inline != TRUE) ||
	    (In0P->page_indexType.msg_type_longform != FALSE) ||
	    (In0P->page_indexType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->page_indexType.msg_type_number != 1) ||
	    (In0P->page_indexType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->unitType != * (int *) &unitCheck)
#else	UseStaticMsgType
	if ((In0P->unitType.msg_type_inline != TRUE) ||
	    (In0P->unitType.msg_type_longform != FALSE) ||
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) dsp_free_page(In0P->Head.msg_request_port, In0P->owner_port, In0P->page_index, In0P->unit);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

boolean_t dspdriver_server
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

	if ((InP->msg_id > 534) || (InP->msg_id < 500))
		return FALSE;
	else {
		typedef novalue (*SERVER_STUB_PROC)
			(msg_header_t *, msg_header_t *);
		static const SERVER_STUB_PROC routines[] = {
			_Xdsp_become_owner,
			_Xdsp_reset_chip,
			_Xdsp_release_ownership,
			_Xdsp_get_icr,
			_Xdsp_get_cvr,
			_Xdsp_get_isr,
			_Xdsp_get_ivr,
			_Xdsp_put_icr,
			_Xdsp_put_cvr,
			_Xdsp_put_ivr,
			_Xdsp_put_data_raw,
			_Xdsp_get_data_raw,
			_Xdsp_put_data,
			_Xdsp_get_data,
			_Xdsp_put_data_array,
			_Xdsp_put_data_byte_array,
			_Xdsp_put_data_short_array,
			_Xdsp_put_data_packed_array,
			_Xdsp_put_data_left_array,
			_Xdsp_get_data_array,
			_Xdsp_put_mk_timed_message,
			_Xdsp_exec_mk_host_message,
			_Xdsp_get_hi,
			_Xdsp_put_and_exec_mk_host_message,
			_Xdsp_set_sub_unit,
			_Xdsp_put_page,
			_Xdsp_set_messaging,
			_Xdsp_queue_page,
			_Xdsp_set_short_big_endian_return,
			_Xdsp_set_short_return,
			_Xdsp_set_long_return,
			_Xdsp_set_error_port,
			_Xdsp_set_msg_port,
			_Xdsp_set_debug,
			_Xdsp_free_page,
		};

		if (routines[InP->msg_id - 500])
			(routines[InP->msg_id - 500]) (InP, &OutP->Head);
		 else
			return FALSE;
	}
	return TRUE;
}
