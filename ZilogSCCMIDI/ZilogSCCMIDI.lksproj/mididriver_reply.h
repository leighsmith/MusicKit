#ifndef	_mididriver_reply
#define	_mididriver_reply

/* Module mididriver_reply */

#include <mach/kern_return.h>
#include <mach/port.h>
#include <mach/message.h>

#ifndef	mig_external
#define mig_external extern
#endif

#include <mach/std_types.h>
#include "mididriver_types.h"

/* SimpleRoutine MDAlarmReply */
mig_external kern_return_t MDAlarmReply (
	port_t reply_port,
	int requestedTime,
	int actualTime);

/* SimpleRoutine MDDataReply */
mig_external kern_return_t MDDataReply (
	port_t reply_port,
	short unit,
	MDRawEventPtr data,
	unsigned int dataCnt);

/* SimpleRoutine MDExceptionReply */
mig_external kern_return_t MDExceptionReply (
	port_t reply_port,
	int exception_code);

/* SimpleRoutine MDQueueReply */
mig_external kern_return_t MDQueueReply (
	port_t reply_port,
	short unit);

#endif	_mididriver_reply
