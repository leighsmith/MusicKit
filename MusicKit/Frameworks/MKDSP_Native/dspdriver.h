#ifndef	_dspdriver
#define	_dspdriver

/* Module dspdriver */

#include <mach/kern_return.h>
#include <mach/port.h>
#include <mach/message.h>

#ifndef	mig_external
#define mig_external extern
#endif

#include <mach/std_types.h>
#include "dspdriver_types.h"
#include <mach/mach_types.h>

/* Routine dsp_become_owner */
mig_external kern_return_t dsp_become_owner (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	int unit);

/* Routine dsp_reset_chip */
mig_external kern_return_t dsp_reset_chip (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	char on,
	int unit);

/* Routine dsp_release_ownership */
mig_external kern_return_t dsp_release_ownership (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	int unit);

/* Routine dsp_get_icr */
mig_external kern_return_t dsp_get_icr (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	char *icr,
	int unit);

/* Routine dsp_get_cvr */
mig_external kern_return_t dsp_get_cvr (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	char *cvr,
	int unit);

/* Routine dsp_get_isr */
mig_external kern_return_t dsp_get_isr (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	char *isr,
	int unit);

/* Routine dsp_get_ivr */
mig_external kern_return_t dsp_get_ivr (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	char *ivr,
	int unit);

/* SimpleRoutine dsp_put_icr */
mig_external kern_return_t dsp_put_icr (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	char icr,
	int unit);

/* SimpleRoutine dsp_put_cvr */
mig_external kern_return_t dsp_put_cvr (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	char cvr,
	int unit);

/* SimpleRoutine dsp_put_ivr */
mig_external kern_return_t dsp_put_ivr (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	char ivr,
	int unit);

/* SimpleRoutine dsp_put_data_raw */
mig_external kern_return_t dsp_put_data_raw (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	char high,
	char med,
	char low,
	int unit);

/* Routine dsp_get_data_raw */
mig_external kern_return_t dsp_get_data_raw (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	char *high,
	char *med,
	char *low,
	int unit);

/* SimpleRoutine dsp_put_data */
mig_external kern_return_t dsp_put_data (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	char high,
	char med,
	char low,
	int unit);

/* Routine dsp_get_data */
mig_external kern_return_t dsp_get_data (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	char *high,
	char *med,
	char *low,
	int unit);

/* SimpleRoutine dsp_put_data_array */
mig_external kern_return_t dsp_put_data_array (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	DSPWordPtr data,
	unsigned int dataCnt,
	int unit);

/* SimpleRoutine dsp_put_data_byte_array */
mig_external kern_return_t dsp_put_data_byte_array (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	DSPCharPtr data,
	unsigned int dataCnt,
	int unit);

/* SimpleRoutine dsp_put_data_short_array */
mig_external kern_return_t dsp_put_data_short_array (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	DSPShortPtr data,
	unsigned int dataCnt,
	int unit);

/* SimpleRoutine dsp_put_data_packed_array */
mig_external kern_return_t dsp_put_data_packed_array (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	DSPCharPtr data,
	unsigned int dataCnt,
	int unit);

/* SimpleRoutine dsp_put_data_left_array */
mig_external kern_return_t dsp_put_data_left_array (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	DSPWordPtr data,
	unsigned int dataCnt,
	int unit);

/* Routine dsp_get_data_array */
mig_external kern_return_t dsp_get_data_array (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	int count,
	DSPWordPtr data,
	unsigned int *dataCnt,
	int unit);

/* SimpleRoutine dsp_put_mk_timed_message */
mig_external kern_return_t dsp_put_mk_timed_message (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	int highWord,
	int lowWord,
	int opCode,
	int unit);

/* SimpleRoutine dsp_exec_mk_host_message */
mig_external kern_return_t dsp_exec_mk_host_message (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	int unit);

/* Routine dsp_get_hi */
mig_external kern_return_t dsp_get_hi (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	int *hi,
	int unit);

/* SimpleRoutine dsp_put_and_exec_mk_host_message */
mig_external kern_return_t dsp_put_and_exec_mk_host_message (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	DSPWordPtr data,
	unsigned int dataCnt,
	int unit);

/* SimpleRoutine dsp_set_sub_unit */
mig_external kern_return_t dsp_set_sub_unit (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	int sub_unit,
	int unit);

/* SimpleRoutine dsp_put_page */
mig_external kern_return_t dsp_put_page (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	DSPPagePtr pageAddress,
	int regionTag,
	boolean_t msgStarted,
	boolean_t msgCompleted,
	mach_port_t reply_port,
	int unit);

/* SimpleRoutine dsp_set_messaging */
mig_external kern_return_t dsp_set_messaging (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	boolean_t flag,
	int unit);

/* SimpleRoutine dsp_queue_page */
mig_external kern_return_t dsp_queue_page (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	DSPPagePtr pageAddress,
	int regionTag,
	boolean_t msgStarted,
	boolean_t msgCompleted,
	mach_port_t reply_port,
	int unit);

/* SimpleRoutine dsp_set_short_big_endian_return */
mig_external kern_return_t dsp_set_short_big_endian_return (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	int regionTag,
	int wordCount,
	mach_port_t reply_port,
	int chan,
	int unit);

/* SimpleRoutine dsp_set_short_return */
mig_external kern_return_t dsp_set_short_return (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	int regionTag,
	int wordCount,
	mach_port_t reply_port,
	int chan,
	int unit);

/* SimpleRoutine dsp_set_long_return */
mig_external kern_return_t dsp_set_long_return (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	int regionTag,
	int wordCount,
	mach_port_t reply_port,
	int chan,
	int unit);

/* SimpleRoutine dsp_set_error_port */
mig_external kern_return_t dsp_set_error_port (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	mach_port_t reply_port,
	int unit);

/* SimpleRoutine dsp_set_msg_port */
mig_external kern_return_t dsp_set_msg_port (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	mach_port_t reply_port,
	int unit);

/* SimpleRoutine dsp_set_debug */
mig_external kern_return_t dsp_set_debug (
	mach_port_t dspdriver_port,
	int debug_flags);

/* SimpleRoutine dsp_free_page */
mig_external kern_return_t dsp_free_page (
	mach_port_t dspdriver_port,
	mach_port_t owner_port,
	int page_index,
	int unit);

#endif	_dspdriver
