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
  Revision 1.2  1999/07/29 01:26:07  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
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

/* Routine MDBecomeOwner */
mig_internal novalue _XMDBecomeOwner
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t MDBecomeOwner (port_t mididriver_port, port_t owner_port);

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

#if	TypeCheck
	msg_size = In0P->Head.msg_size;
	msg_simple = In0P->Head.msg_simple;
	if ((msg_size != 32) || (msg_simple != FALSE))
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

	OutP->RetCode = MDBecomeOwner(In0P->Head.msg_request_port, In0P->owner_port);
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

/* Routine MDReleaseOwnership */
mig_internal novalue _XMDReleaseOwnership
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t MDReleaseOwnership (port_t mididriver_port, port_t owner_port);

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

#if	TypeCheck
	msg_size = In0P->Head.msg_size;
	msg_simple = In0P->Head.msg_simple;
	if ((msg_size != 32) || (msg_simple != FALSE))
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

	OutP->RetCode = MDReleaseOwnership(In0P->Head.msg_request_port, In0P->owner_port);
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

/* Routine MDSetClockMode */
mig_internal novalue _XMDSetClockMode
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
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

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t MDSetClockMode (port_t mididriver_port, port_t owner_port, short unit, int clock_mode);

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
	static const msg_type_t clock_modeCheck = {
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
#if	UseStaticMsgType
	if (* (int *) &In0P->clock_modeType != * (int *) &clock_modeCheck)
#else	UseStaticMsgType
	if ((In0P->clock_modeType.msg_type_inline != TRUE) ||
	    (In0P->clock_modeType.msg_type_longform != FALSE) ||
	    (In0P->clock_modeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->clock_modeType.msg_type_number != 1) ||
	    (In0P->clock_modeType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = MDSetClockMode(In0P->Head.msg_request_port, In0P->owner_port, In0P->unit, In0P->clock_mode);
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

/* Routine MDGetClockTime */
mig_internal novalue _XMDGetClockTime
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
		msg_type_t timeType;
		int time;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t MDGetClockTime (port_t mididriver_port, port_t owner_port, int *time);

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

#if	TypeCheck
	msg_size = In0P->Head.msg_size;
	msg_simple = In0P->Head.msg_simple;
	if ((msg_size != 32) || (msg_simple != FALSE))
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

	OutP->RetCode = MDGetClockTime(In0P->Head.msg_request_port, In0P->owner_port, &OutP->time);
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	if (OutP->RetCode != KERN_SUCCESS)
		return;

	msg_size = 40;	

#if	UseStaticMsgType
	OutP->timeType = timeType;
#else	UseStaticMsgType
	OutP->timeType.msg_type_name = MSG_TYPE_INTEGER_32;
	OutP->timeType.msg_type_size = 32;
	OutP->timeType.msg_type_number = 1;
	OutP->timeType.msg_type_inline = TRUE;
	OutP->timeType.msg_type_longform = FALSE;
	OutP->timeType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	OutP->Head.msg_simple = TRUE;
	OutP->Head.msg_size = msg_size;
}

/* Routine MDGetMTCTime */
mig_internal novalue _XMDGetMTCTime
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
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

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t MDGetMTCTime (port_t mididriver_port, port_t owner_port, short *format, short *hours, short *minutes, short *seconds, short *frames);

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
	static const msg_type_t formatType = {
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
	static const msg_type_t hoursType = {
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
	static const msg_type_t minutesType = {
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
	static const msg_type_t secondsType = {
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
	static const msg_type_t framesType = {
		/* msg_type_name = */		MSG_TYPE_INTEGER_16,
		/* msg_type_size = */		16,
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
	if ((msg_size != 32) || (msg_simple != FALSE))
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

	OutP->RetCode = MDGetMTCTime(In0P->Head.msg_request_port, In0P->owner_port, &OutP->format, &OutP->hours, &OutP->minutes, &OutP->seconds, &OutP->frames);
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	if (OutP->RetCode != KERN_SUCCESS)
		return;

	msg_size = 72;	

#if	UseStaticMsgType
	OutP->formatType = formatType;
#else	UseStaticMsgType
	OutP->formatType.msg_type_name = MSG_TYPE_INTEGER_16;
	OutP->formatType.msg_type_size = 16;
	OutP->formatType.msg_type_number = 1;
	OutP->formatType.msg_type_inline = TRUE;
	OutP->formatType.msg_type_longform = FALSE;
	OutP->formatType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

#if	UseStaticMsgType
	OutP->hoursType = hoursType;
#else	UseStaticMsgType
	OutP->hoursType.msg_type_name = MSG_TYPE_INTEGER_16;
	OutP->hoursType.msg_type_size = 16;
	OutP->hoursType.msg_type_number = 1;
	OutP->hoursType.msg_type_inline = TRUE;
	OutP->hoursType.msg_type_longform = FALSE;
	OutP->hoursType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

#if	UseStaticMsgType
	OutP->minutesType = minutesType;
#else	UseStaticMsgType
	OutP->minutesType.msg_type_name = MSG_TYPE_INTEGER_16;
	OutP->minutesType.msg_type_size = 16;
	OutP->minutesType.msg_type_number = 1;
	OutP->minutesType.msg_type_inline = TRUE;
	OutP->minutesType.msg_type_longform = FALSE;
	OutP->minutesType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

#if	UseStaticMsgType
	OutP->secondsType = secondsType;
#else	UseStaticMsgType
	OutP->secondsType.msg_type_name = MSG_TYPE_INTEGER_16;
	OutP->secondsType.msg_type_size = 16;
	OutP->secondsType.msg_type_number = 1;
	OutP->secondsType.msg_type_inline = TRUE;
	OutP->secondsType.msg_type_longform = FALSE;
	OutP->secondsType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

#if	UseStaticMsgType
	OutP->framesType = framesType;
#else	UseStaticMsgType
	OutP->framesType.msg_type_name = MSG_TYPE_INTEGER_16;
	OutP->framesType.msg_type_size = 16;
	OutP->framesType.msg_type_number = 1;
	OutP->framesType.msg_type_inline = TRUE;
	OutP->framesType.msg_type_longform = FALSE;
	OutP->framesType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	OutP->Head.msg_simple = TRUE;
	OutP->Head.msg_size = msg_size;
}

/* Routine MDSetClockTime */
mig_internal novalue _XMDSetClockTime
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t timeType;
		int time;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t MDSetClockTime (port_t mididriver_port, port_t owner_port, int time);

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
	if (* (int *) &In0P->timeType != * (int *) &timeCheck)
#else	UseStaticMsgType
	if ((In0P->timeType.msg_type_inline != TRUE) ||
	    (In0P->timeType.msg_type_longform != FALSE) ||
	    (In0P->timeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->timeType.msg_type_number != 1) ||
	    (In0P->timeType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = MDSetClockTime(In0P->Head.msg_request_port, In0P->owner_port, In0P->time);
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

/* SimpleRoutine MDRequestAlarm */
mig_internal novalue _XMDRequestAlarm
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t reply_portType;
		port_t reply_port;
		msg_type_t timeType;
		int time;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t MDRequestAlarm (port_t mididriver_port, port_t owner_port, port_t reply_port, int time);

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
	if (* (int *) &In0P->timeType != * (int *) &timeCheck)
#else	UseStaticMsgType
	if ((In0P->timeType.msg_type_inline != TRUE) ||
	    (In0P->timeType.msg_type_longform != FALSE) ||
	    (In0P->timeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->timeType.msg_type_number != 1) ||
	    (In0P->timeType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	(void) MDRequestAlarm(In0P->Head.msg_request_port, In0P->owner_port, In0P->reply_port, In0P->time);
	OutP->RetCode = MIG_NO_REPLY;
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	;
}

/* Routine MDStartClock */
mig_internal novalue _XMDStartClock
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t MDStartClock (port_t mididriver_port, port_t owner_port);

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

#if	TypeCheck
	msg_size = In0P->Head.msg_size;
	msg_simple = In0P->Head.msg_simple;
	if ((msg_size != 32) || (msg_simple != FALSE))
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

	OutP->RetCode = MDStartClock(In0P->Head.msg_request_port, In0P->owner_port);
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

/* Routine MDStopClock */
mig_internal novalue _XMDStopClock
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t MDStopClock (port_t mididriver_port, port_t owner_port);

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

#if	TypeCheck
	msg_size = In0P->Head.msg_size;
	msg_simple = In0P->Head.msg_simple;
	if ((msg_size != 32) || (msg_simple != FALSE))
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

	OutP->RetCode = MDStopClock(In0P->Head.msg_request_port, In0P->owner_port);
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

/* Routine MDClaimUnit */
mig_internal novalue _XMDClaimUnit
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
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
	extern kern_return_t MDClaimUnit (port_t mididriver_port, port_t owner_port, short unit);

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
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_16) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 16))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = MDClaimUnit(In0P->Head.msg_request_port, In0P->owner_port, In0P->unit);
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

/* Routine MDReleaseUnit */
mig_internal novalue _XMDReleaseUnit
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
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
	extern kern_return_t MDReleaseUnit (port_t mididriver_port, port_t owner_port, short unit);

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
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_16) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 16))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = MDReleaseUnit(In0P->Head.msg_request_port, In0P->owner_port, In0P->unit);
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

/* Routine MDRequestExceptions */
mig_internal novalue _XMDRequestExceptions
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t error_portType;
		port_t error_port;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t MDRequestExceptions (port_t mididriver_port, port_t owner_port, port_t error_port);

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
	static const msg_type_t error_portCheck = {
		/* msg_type_name = */		MSG_TYPE_PORT,
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
	if (* (int *) &In0P->error_portType != * (int *) &error_portCheck)
#else	UseStaticMsgType
	if ((In0P->error_portType.msg_type_inline != TRUE) ||
	    (In0P->error_portType.msg_type_longform != FALSE) ||
	    (In0P->error_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->error_portType.msg_type_number != 1) ||
	    (In0P->error_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = MDRequestExceptions(In0P->Head.msg_request_port, In0P->owner_port, In0P->error_port);
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

/* Routine MDRequestData */
mig_internal novalue _XMDRequestData
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t unitType;
		short unit;
		char unitPad[2];
		msg_type_t reply_portType;
		port_t reply_port;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t MDRequestData (port_t mididriver_port, port_t owner_port, short unit, port_t reply_port);

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

	OutP->RetCode = MDRequestData(In0P->Head.msg_request_port, In0P->owner_port, In0P->unit, In0P->reply_port);
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

/* Routine MDSendData */
mig_internal novalue _XMDSendData
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
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
	extern kern_return_t MDSendData (port_t mididriver_port, port_t owner_port, short unit, MDRawEventPtr data, unsigned int dataCnt);

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
	if ((msg_size < 44) || (msg_size > 844) || (msg_simple != FALSE))
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
	if (msg_size != 44 + msg_size_delta)
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = MDSendData(In0P->Head.msg_request_port, In0P->owner_port, In0P->unit, In0P->data, In0P->dataType.msg_type_number / 8);
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

/* Routine MDGetAvailableQueueSize */
mig_internal novalue _XMDGetAvailableQueueSize
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
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

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t MDGetAvailableQueueSize (port_t mididriver_port, port_t owner_port, short unit, int *size);

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
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_16) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 16))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = MDGetAvailableQueueSize(In0P->Head.msg_request_port, In0P->owner_port, In0P->unit, &OutP->size);
#ifdef	label_punt0
#undef	label_punt0
punt0:
#endif	label_punt0
	if (OutP->RetCode != KERN_SUCCESS)
		return;

	msg_size = 40;	

#if	UseStaticMsgType
	OutP->sizeType = sizeType;
#else	UseStaticMsgType
	OutP->sizeType.msg_type_name = MSG_TYPE_INTEGER_32;
	OutP->sizeType.msg_type_size = 32;
	OutP->sizeType.msg_type_number = 1;
	OutP->sizeType.msg_type_inline = TRUE;
	OutP->sizeType.msg_type_longform = FALSE;
	OutP->sizeType.msg_type_deallocate = FALSE;
#endif	UseStaticMsgType

	OutP->Head.msg_simple = TRUE;
	OutP->Head.msg_size = msg_size;
}

/* Routine MDRequestQueueNotification */
mig_internal novalue _XMDRequestQueueNotification
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t unitType;
		short unit;
		char unitPad[2];
		msg_type_t notification_portType;
		port_t notification_port;
		msg_type_t sizeType;
		int size;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t MDRequestQueueNotification (port_t mididriver_port, port_t owner_port, short unit, port_t notification_port, int size);

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
	static const msg_type_t notification_portCheck = {
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

#if	TypeCheck
	msg_size = In0P->Head.msg_size;
	msg_simple = In0P->Head.msg_simple;
	if ((msg_size != 56) || (msg_simple != FALSE))
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
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_16) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 16))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->notification_portType != * (int *) &notification_portCheck)
#else	UseStaticMsgType
	if ((In0P->notification_portType.msg_type_inline != TRUE) ||
	    (In0P->notification_portType.msg_type_longform != FALSE) ||
	    (In0P->notification_portType.msg_type_name != MSG_TYPE_PORT) ||
	    (In0P->notification_portType.msg_type_number != 1) ||
	    (In0P->notification_portType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

#if	TypeCheck
#if	UseStaticMsgType
	if (* (int *) &In0P->sizeType != * (int *) &sizeCheck)
#else	UseStaticMsgType
	if ((In0P->sizeType.msg_type_inline != TRUE) ||
	    (In0P->sizeType.msg_type_longform != FALSE) ||
	    (In0P->sizeType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->sizeType.msg_type_number != 1) ||
	    (In0P->sizeType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = MDRequestQueueNotification(In0P->Head.msg_request_port, In0P->owner_port, In0P->unit, In0P->notification_port, In0P->size);
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

/* Routine MDClearQueue */
mig_internal novalue _XMDClearQueue
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
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
	extern kern_return_t MDClearQueue (port_t mididriver_port, port_t owner_port, short unit);

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
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_16) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 16))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = MDClearQueue(In0P->Head.msg_request_port, In0P->owner_port, In0P->unit);
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

/* Routine MDFlushQueue */
mig_internal novalue _XMDFlushQueue
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
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
	extern kern_return_t MDFlushQueue (port_t mididriver_port, port_t owner_port, short unit);

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
	    (In0P->unitType.msg_type_name != MSG_TYPE_INTEGER_16) ||
	    (In0P->unitType.msg_type_number != 1) ||
	    (In0P->unitType.msg_type_size != 16))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = MDFlushQueue(In0P->Head.msg_request_port, In0P->owner_port, In0P->unit);
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

/* Routine MDSetSystemIgnores */
mig_internal novalue _XMDSetSystemIgnores
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
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

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t MDSetSystemIgnores (port_t mididriver_port, port_t owner_port, short unit, int sys_ignores);

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
	static const msg_type_t sys_ignoresCheck = {
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
#if	UseStaticMsgType
	if (* (int *) &In0P->sys_ignoresType != * (int *) &sys_ignoresCheck)
#else	UseStaticMsgType
	if ((In0P->sys_ignoresType.msg_type_inline != TRUE) ||
	    (In0P->sys_ignoresType.msg_type_longform != FALSE) ||
	    (In0P->sys_ignoresType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->sys_ignoresType.msg_type_number != 1) ||
	    (In0P->sys_ignoresType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = MDSetSystemIgnores(In0P->Head.msg_request_port, In0P->owner_port, In0P->unit, In0P->sys_ignores);
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

/* Routine MDSetClockQuantum */
mig_internal novalue _XMDSetClockQuantum
	(msg_header_t *InHeadP, msg_header_t *OutHeadP)
{
	typedef struct {
		msg_header_t Head;
		msg_type_t owner_portType;
		port_t owner_port;
		msg_type_t microsecondsType;
		int microseconds;
	} Request;

	typedef struct {
		msg_header_t Head;
		msg_type_t RetCodeType;
		kern_return_t RetCode;
	} Reply;

	register Request *In0P = (Request *) InHeadP;
	register Reply *OutP = (Reply *) OutHeadP;
	extern kern_return_t MDSetClockQuantum (port_t mididriver_port, port_t owner_port, int microseconds);

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
	static const msg_type_t microsecondsCheck = {
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
	if (* (int *) &In0P->microsecondsType != * (int *) &microsecondsCheck)
#else	UseStaticMsgType
	if ((In0P->microsecondsType.msg_type_inline != TRUE) ||
	    (In0P->microsecondsType.msg_type_longform != FALSE) ||
	    (In0P->microsecondsType.msg_type_name != MSG_TYPE_INTEGER_32) ||
	    (In0P->microsecondsType.msg_type_number != 1) ||
	    (In0P->microsecondsType.msg_type_size != 32))
#endif	UseStaticMsgType
		{ OutP->RetCode = MIG_BAD_ARGUMENTS; goto punt0; }
#define	label_punt0
#endif	TypeCheck

	OutP->RetCode = MDSetClockQuantum(In0P->Head.msg_request_port, In0P->owner_port, In0P->microseconds);
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

boolean_t mididriver_server
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

	if ((InP->msg_id > 419) || (InP->msg_id < 400))
		return FALSE;
	else {
		typedef novalue (*SERVER_STUB_PROC)
			(msg_header_t *, msg_header_t *);
		static const SERVER_STUB_PROC routines[] = {
			_XMDBecomeOwner,
			_XMDReleaseOwnership,
			_XMDSetClockMode,
			_XMDGetClockTime,
			_XMDGetMTCTime,
			_XMDSetClockTime,
			_XMDRequestAlarm,
			_XMDStartClock,
			_XMDStopClock,
			_XMDClaimUnit,
			_XMDReleaseUnit,
			_XMDRequestExceptions,
			_XMDRequestData,
			_XMDSendData,
			_XMDGetAvailableQueueSize,
			_XMDRequestQueueNotification,
			_XMDClearQueue,
			_XMDFlushQueue,
			_XMDSetSystemIgnores,
			_XMDSetClockQuantum,
		};

		if (routines[InP->msg_id - 400])
			(routines[InP->msg_id - 400]) (InP, &OutP->Head);
		 else
			return FALSE;
	}
	return TRUE;
}
