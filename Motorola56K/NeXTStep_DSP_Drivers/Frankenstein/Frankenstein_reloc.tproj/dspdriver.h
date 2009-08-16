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
	port_t dspdriver_port,
	port_t owner_port,
	int unit);

/* Routine dsp_reset_chip */
mig_external kern_return_t dsp_reset_chip (
	port_t dspdriver_port,
	port_t owner_port,
	char on,
	int unit);

/* Routine dsp_release_ownership */
mig_external kern_return_t dsp_release_ownership (
	port_t dspdriver_port,
	port_t owner_port,
	int unit);

/* Routine dsp_get_icr */
mig_external kern_return_t dsp_get_icr (
	port_t dspdriver_port,
	port_t owner_port,
	char *icr,
	int unit);

/* Routine dsp_get_cvr */
mig_external kern_return_t dsp_get_cvr (
	port_t dspdriver_port,
	port_t owner_port,
	char *cvr,
	int unit);

/* Routine dsp_get_isr */
mig_external kern_return_t dsp_get_isr (
	port_t dspdriver_port,
	port_t owner_port,
	char *isr,
	int unit);

/* Routine dsp_get_ivr */
mig_external kern_return_t dsp_get_ivr (
	port_t dspdriver_port,
	port_t owner_port,
	char *ivr,
	int unit);

/* SimpleRoutine dsp_put_icr */
mig_external kern_return_t dsp_put_icr (
	port_t dspdriver_port,
	port_t owner_port,
	char icr,
	int unit);

/* SimpleRoutine dsp_put_cvr */
mig_external kern_return_t dsp_put_cvr (
	port_t dspdriver_port,
	port_t owner_port,
	char cvr,
	int unit);

/* SimpleRoutine dsp_put_ivr */
mig_external kern_return_t dsp_put_ivr (
	port_t dspdriver_port,
	port_t owner_port,
	char ivr,
	int unit);

/* SimpleRoutine dsp_put_data_raw */
mig_external kern_return_t dsp_put_data_raw (
	port_t dspdriver_port,
	port_t owner_port,
	char high,
	char med,
	char low,
	int unit);

/* Routine dsp_get_data_raw */
mig_external kern_return_t dsp_get_data_raw (
	port_t dspdriver_port,
	port_t owner_port,
	char *high,
	char *med,
	char *low,
	int unit);

/* SimpleRoutine dsp_put_data */
mig_external kern_return_t dsp_put_data (
	port_t dspdriver_port,
	port_t owner_port,
	char high,
	char med,
	char low,
	int unit);

/* Routine dsp_get_data */
mig_external kern_return_t dsp_get_data (
	port_t dspdriver_port,
	port_t owner_port,
	char *high,
	char *med,
	char *low,
	int unit);

/* SimpleRoutine dsp_put_data_array */
mig_external kern_return_t dsp_put_data_array (
	port_t dspdriver_port,
	port_t owner_port,
	DSPWordPtr data,
	unsigned int dataCnt,
	int unit);

/* SimpleRoutine dsp_put_data_byte_array */
mig_external kern_return_t dsp_put_data_byte_array (
	port_t dspdriver_port,
	port_t owner_port,
	DSPCharPtr data,
	unsigned int dataCnt,
	int unit);

/* SimpleRoutine dsp_put_data_short_array */
mig_external kern_return_t dsp_put_data_short_array (
	port_t dspdriver_port,
	port_t owner_port,
	DSPShortPtr data,
	unsigned int dataCnt,
	int unit);

/* SimpleRoutine dsp_put_data_packed_array */
mig_external kern_return_t dsp_put_data_packed_array (
	port_t dspdriver_port,
	port_t owner_port,
	DSPCharPtr data,
	unsigned int dataCnt,
	int unit);

/* SimpleRoutine dsp_put_data_left_array */
mig_external kern_return_t dsp_put_data_left_array (
	port_t dspdriver_port,
	port_t owner_port,
	DSPWordPtr data,
	unsigned int dataCnt,
	int unit);

/* Routine dsp_get_data_array */
mig_external kern_return_t dsp_get_data_array (
	port_t dspdriver_port,
	port_t owner_port,
	int count,
	DSPWordPtr data,
	unsigned int *dataCnt,
	int unit);

/* SimpleRoutine dsp_put_mk_timed_message */
mig_external kern_return_t dsp_put_mk_timed_message (
	port_t dspdriver_port,
	port_t owner_port,
	int highWord,
	int lowWord,
	int opCode,
	int unit);

/* SimpleRoutine dsp_exec_mk_host_message */
mig_external kern_return_t dsp_exec_mk_host_message (
	port_t dspdriver_port,
	port_t owner_port,
	int unit);

/* Routine dsp_get_hi */
mig_external kern_return_t dsp_get_hi (
	port_t dspdriver_port,
	port_t owner_port,
	int *hi,
	int unit);

/* SimpleRoutine dsp_put_and_exec_mk_host_message */
mig_external kern_return_t dsp_put_and_exec_mk_host_message (
	port_t dspdriver_port,
	port_t owner_port,
	DSPWordPtr data,
	unsigned int dataCnt,
	int unit);

/* SimpleRoutine dsp_set_sub_unit */
mig_external kern_return_t dsp_set_sub_unit (
	port_t dspdriver_port,
	port_t owner_port,
	int sub_unit,
	int unit);

/* SimpleRoutine dsp_put_page */
mig_external kern_return_t dsp_put_page (
	port_t dspdriver_port,
	port_t owner_port,
	DSPPagePtr pageAddress,
	int regionTag,
	boolean_t msgStarted,
	boolean_t msgCompleted,
	port_t reply_port,
	int unit);

/* SimpleRoutine dsp_set_messaging */
mig_external kern_return_t dsp_set_messaging (
	port_t dspdriver_port,
	port_t owner_port,
	boolean_t flag,
	int unit);

/* SimpleRoutine dsp_queue_page */
mig_external kern_return_t dsp_queue_page (
	port_t dspdriver_port,
	port_t owner_port,
	DSPPagePtr pageAddress,
	int regionTag,
	boolean_t msgStarted,
	boolean_t msgCompleted,
	port_t reply_port,
	int unit);

/* SimpleRoutine dsp_set_short_big_endian_return */
mig_external kern_return_t dsp_set_short_big_endian_return (
	port_t dspdriver_port,
	port_t owner_port,
	int regionTag,
	int wordCount,
	port_t reply_port,
	int chan,
	int unit);

/* SimpleRoutine dsp_set_short_return */
mig_external kern_return_t dsp_set_short_return (
	port_t dspdriver_port,
	port_t owner_port,
	int regionTag,
	int wordCount,
	port_t reply_port,
	int chan,
	int unit);

/* SimpleRoutine dsp_set_long_return */
mig_external kern_return_t dsp_set_long_return (
	port_t dspdriver_port,
	port_t owner_port,
	int regionTag,
	int wordCount,
	port_t reply_port,
	int chan,
	int unit);

/* SimpleRoutine dsp_set_error_port */
mig_external kern_return_t dsp_set_error_port (
	port_t dspdriver_port,
	port_t owner_port,
	port_t reply_port,
	int unit);

/* SimpleRoutine dsp_set_msg_port */
mig_external kern_return_t dsp_set_msg_port (
	port_t dspdriver_port,
	port_t owner_port,
	port_t reply_port,
	int unit);

/* SimpleRoutine dsp_set_debug */
mig_external kern_return_t dsp_set_debug (
	port_t dspdriver_port,
	int debug_flags);

/* SimpleRoutine dsp_free_page */
mig_external kern_return_t dsp_free_page (
	port_t dspdriver_port,
	port_t owner_port,
	int page_index,
	int unit);

#endif	_dspdriver
