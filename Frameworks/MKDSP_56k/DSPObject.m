/* $Id$
 Lowest-level DSP utilities
 Copyright 1988-1992, NeXT Inc.  All rights reserved.	
*/

#define DO_SENSE_CPU_TYPE 1

#define DO_AUTO_DMA 0

#ifdef SHLIB
#include "shlib.h"
#endif

/* Need new pointers:
_ioctl
_signal
_setjmp
_stat
_longjmp
*/

// LMS: SB reports OpenStep 4.2 has problems compiling with Foundation.h
#ifdef NeXT
#import <objc/objc.h> /*sb*/
#import <Foundation/NSByteOrder.h> /*sb*/
#else
#import <Foundation/Foundation.h>
#endif

/* 
 * Gdb gets confused when stepping into inline procedures, so we
 * turn inline expansion off for the debug version of the library.
 */

#ifdef DEBUG
#define INLINE
#else
#define INLINE inline
#endif

/* 
 * BRIEF is used to mark procedures that would be inline if not exported.
 * Perhaps there should be an inline "_" version which is used 
 * internally, and the exported entry point can invoke the inline version.
 * (This is all of course nothing but optimization.) 
 */
#define BRIEF

#define PROTOCOL_WAS_SET_FN 0	/*** FIXME (add to snddriver_client.c) ***/

#define SND_DSP_PROTO_HOSTMSG SND_DSP_PROTO_DSPERR 

#define DSP_DMA_WRITE_BUF_SIZE 4096 /* must be a power of 2 */
/* 8K causes assertion failure at line 1124 of snd_dspqueue.c */

#define DSP_DMA_READ_BUF_SIZE 8192

#define DSP_MIN_DMA 32
#define DSP_MIN_DMA_MASK (DSP_MIN_DMA-1)

#define DSPMK_WD_DSP_CHAN 1
#define DSPMK_RD_DSP_CHAN 2

#define DRIVER_SUPPORTS_MESSAGING(_dspNum) \
    (s_driver_version[_dspNum] > .94) /* First messaging version was .95 */

#define MMAP 1

#if DO_SENSE_CPU_TYPE
//#import <bsd/m68k/cpu.h>	/* was <m68k/kernserv/cpu.h> */
#ifndef WIN32
#import <mach/machine.h>
#endif
#endif
#import <mach/mach.h>		/* was <mach.h> */
#import <mach/cthreads.h>	/* was <cthreads.h> */

#ifndef WIN32
#import <sys/mman.h>  // LMS is this neccessary?
#import <sys/time.h>  // LMS is this neccessary?
#import <sys/file.h>		/* for fopen(), open() */ // LMS is this necessary?
#endif

/* #import <servers/bootstrap.h> */
#import <SndKit/SndKit.h>
//#import <SoundKit/SoundKit.h>

// #import "/LocalDeveloper/Headers/architecture/m68k/snd_dspreg.h"
#import "dspreg.h"

#import "_dsp.h"
//#import <SoundKit/sound.h>	/* For write-data output file */

#ifndef WIN32
//#ifdef SHLIB
#import <SoundKit/sounddriver.h>
//#else
//#import "snddriver.h"		/*** FIXME ***/
//#endif
#else
#import <SndKit/sounddriver.h>	/* This will be replaced someday as there is nothing but stubs anway */
#endif

#ifdef WIN32
#include <winnt-pdo.h>
#include <fcntl.h>   // for open() constants
#endif

/* #import <mach_init.h> */

extern int thread_reply();

#import <sys/types.h>
#import <mach/notify.h>		/* for SEND_NOTIFY et al. */

/* {long tv_sec; long tv_usec;} */
extern struct timeval _DSPTenMillisecondTimer;
extern struct timeval _DSPOneMillisecondTimer;

struct timeval _DSPTenMillisecondTimer = {0,10000};
//struct timeval _DSPOneMillisecondTimer = {0,1000};

#ifndef __FILE_HEADER__
#endif

#if 0
/* Not safe--a hack */
static int aLock = 0;

static void printflock(void) {
  while (aLock == 1) {
    cthread_yield();
  }
  aLock = 1;
}

static void printfunlock(void) {
  aLock = 0;
}

#endif


/******************* DSP OBJECT INSTANCE VARIABLES **************************/

/* True globals are in DSPGlobals.c */

/* !!! ANY CHANGES HERE MAY ALSO AFFECT DSPRawClose() !!! */

/* 
 * There are two DSP "types" at this level: memory-mapped and Mach-port-based.
 * All network DSPs are port based.  All QuintProcessor DSPs, for example, 
 * are mapped. The motherboard DSP (DSP 0) is port-based.
 *
 * Any Mach-related items below, such as ports and driver modes, pertain
 * only to port-based DSPs. Also, anything requiring DMA (read-data and 
 * write-data) cannot be supported on mapped DSPs and thus pertain only to
 * network DSPs or DSP 0.
 *
 * For the i386, we use the memory-mapped mechanism, although we actually
 * use driver function calls to access the host port registers.
 */

/* Static global variables (not per-DSP) */
static int ec = 0;			/* error code */

static int s_idsp = 0;		/* Current DSP index */
static int s_dsp_count = 0;	/* Current DSP count */
static int s_dsp_alloc = 0;	/* DSP count provided for in advance */

/* Might want to make these per-DSP--DAJ 11/26/95 */
static msg_header_t *s_dsprcv_msg = 0;  /* contains unread DSP data */
static msg_header_t *s_dspcmd_msg = 0;  /* contains a re-useable dspcmd msg */
static msg_header_t *s_msg = 0;  	/* general purpose message pointer */
static msg_header_t *s_driver_reply_msg = 0; /* re-useable reply msg */

/*** ------------------------- Per-DSP variables ------------------------ ***/

/*** Instance variables pertaining only to port-based DSPs ***/

static double *s_srate=NULL;
static int *s_low_srate=NULL;
static int *s_dsp_mode_flags=NULL;
static int *s_dsp_access_flags=NULL;
static int *s_dsp_buf_wds=NULL;
static int *s_dsp_record_buf_bytes=NULL;
static int *s_dsp_play_buf_bytes=NULL;
static short **s_rd_buf=NULL;
static int *s_do_dma_array_reads=NULL;
static int *s_do_dma_array_writes=NULL;
static int *s_do_optimization =NULL;

/* Write data */
static int *s_write_data=NULL;
static int *s_stop_write_data=NULL;
static int *s_write_data_running=NULL;
static char** s_wd_fn=NULL;
static int *s_wd_fd=NULL;

typedef DSPMKWriteDataUserFunc *DSPMKWriteDataUserFuncArray;

static DSPMKWriteDataUserFuncArray s_wd_user_func=NULL;
static FILE **s_wd_fp=NULL;
//static SNDSoundStruct **s_wd_header=NULL;
static SndSoundStruct **s_wd_header=NULL;
static int *s_wd_sample_count=NULL;
static int *s_wd_timeout=NULL;
static int *s_no_thread=NULL;

static int s_wd_reader();
static int do_wd_cleanup=1;

static cthread_t *s_wd_thread=NULL;
static int *s_wd_error=NULL;
static char **s_wd_error_str=NULL;

/* Read data */
static int s_rd_writer();

static int *s_read_data=NULL;
static int *s_stop_read_data=NULL;
static int *s_read_data_running=NULL;
static char** s_rd_fn=NULL;
static int *s_rd_fd=NULL;
static int *s_rd_chans=NULL;
//static SNDSoundStruct **s_rd_header=NULL;
static SndSoundStruct **s_rd_header=NULL;
static int *s_rd_sample_count=NULL;
static cthread_t *s_rd_thread=NULL;
static int *s_rd_error=NULL;
static char **s_rd_error_str=NULL;
static int *s_dsp_rd_buf0=NULL;
static msg_header_t *s_rd_rmsg=NULL;

static int s_dsp_err_reader();
static int *s_cur_pri=NULL;
static int *s_cur_atomicity=NULL;
static mach_port_t *s_sound_dev_port=NULL;
static mach_port_t *s_dsp_owner_port=NULL;
static mach_port_t *s_dsp_hm_port=NULL;
static mach_port_t *s_dsp_dm_port=NULL;
static mach_port_t *s_driver_reply_port=NULL;
static mach_port_t *s_dsp_err_port=NULL;
static mach_port_t *s_dsp_neg_port=NULL;
static cthread_t *s_dsp_err_thread=NULL;
static cthread_t *s_dsp_msg_thread=NULL;
static int *s_stop_msg_reader=NULL;
static mach_port_t *s_wd_stream_port=NULL;
static mach_port_t *s_wd_reply_port=NULL;
static mach_port_t *s_rd_stream_port=NULL;
static mach_port_t *s_rd_reply_port=NULL;
static int *s_msg_read_pending=NULL;
static int *s_optimizing=NULL;
static int *s_timed_zero_noflush = NULL;

/*** Instance variables pertaining only to mapped DSPs ***/
#if MMAP
/* The following are not per-DSP because they are temporary.
   They are never assumed to be valid on entry to anything. */
static unsigned int s_regs;
static int s_icr=0;
static int s_cvr=0;
static int s_isr=0;
static int s_ivr=0;

/* s_hostInterface is not per-DSP because DSPSetCurrentDSP() sets it */
static DSPRegs *s_hostInterface=NULL;

static int *s_dsp_fd=NULL;
static DSPRegs **s_hostInterfaceArray=NULL;
static int *s_max_rxdf_buzz=NULL;
static int *s_max_txde_buzz=NULL;
static int *s_max_hm_buzz=NULL;
#endif

/*** Instance variables pertaining to all DSPs ***/

static char **s_nameArray=NULL;

static int *s_ap_system=NULL;
static int *s_mk_system=NULL;

static int *s_open=NULL;
static int *s_open_priority=NULL;
static FILE* *s_whofile_fp=NULL;

static int *s_bail_out=NULL;
static int *s_clock_advancing=NULL;
static int *s_clock_just_started=NULL;
static int *s_prev_kern_ack_time=NULL;

static int *s_mapped_only=NULL;
static int *s_host_msg=NULL;
static int *s_sound_out=NULL;

static int *s_simulated=NULL;
static char* *s_simulatorFile=NULL;
static FILE* *s_simulator_fp=NULL;

static int *s_saving_commands=NULL;
static char* *s_commandsFile=NULL;
static int *s_commands_fd=NULL;
static FILE **s_commands_fp=NULL;
static int *s_commands_numbytes=NULL;

static int *s_dsp_msgs_waiting=NULL;
static int **s_dsp_msg_0=NULL;
static int **s_dsp_msg_ptr=NULL;
static int *s_dsp_msg_count=NULL;

static int *s_max_block_time=NULL;
static int *s_all_block_time=NULL;

static int *s_so_buf_bytes=NULL;
static DSPLoadSpec **s_systemImage=NULL;
static char **s_system_link_file=NULL;
static char **s_system_binary_file=NULL;
static int *s_joint_owner=NULL;
static int *s_dsp_messages_disabled=NULL;
static int *s_low_water=NULL;
static int *s_high_water=NULL;
static int *s_stream_configuration=NULL;
static int *s_frozen=NULL;
static int *s_small_buffers=NULL;
static int *s_force_tmq_flush=NULL;

static int *s_ssi_sound_out=NULL;
static int *s_ssi_read_data=NULL;

static int **s_timedMsg = NULL;
static int **s_curTimedWd = NULL;
static int **s_timedArrEnd = NULL;
static int *s_TMQMessageCount = NULL;
static DSPFix48 *s_curTimeStamp = NULL;
static int *s_hm_ptr = NULL;
static int **s_hm_array = NULL;

static msg_header_t **s_wd_rmsg = NULL; /* DAJ. 11/26/95. Was static */

static int *s_min_dma_chan = NULL;
static int *s_max_dma_chan = NULL;
static double *s_driver_version=NULL;

/******************** Cached DSP symbol variables (all DSPs) ***************/
/* 
 * There are three places to keep in synch below.
 * and DSPSetSystem() in DSPOpen.c 
 */
static int *dsp_hm_host_w=NULL;
static int *dsp_hm_host_r=NULL;
static int *dsp_dm_host_r_req=NULL;
static int *dsp_nb_hms=NULL;
static int *dsp_max_hm=NULL;

static int *dsp_de_break=NULL;

#ifdef NO_REVERT
static int *dsp_hm_poke_l=NULL;
static int *dsp_hm_get_long=NULL;
static int *dsp_dm_long0=NULL;
static int *dsp_dm_long1=NULL;
static int *dsp_dm_long2=NULL;
static int *dsp_hm_host_w_done=NULL;
#endif

static int *dsp_dm_hm_first=NULL;
static int *dsp_dm_hm_last=NULL;
static int *dsp_dm_dm_off=NULL;
static int *dsp_dm_dm_on=NULL;
static int *dsp_dm_peek0=NULL;
static int *dsp_dm_peek1=NULL;
static int *dsp_dm_idle=NULL;
static int *dsp_dm_iaa=NULL;
static int *dsp_dm_host_r_done=NULL;
static int *dsp_dm_main_done=NULL;
static int *dsp_dm_user_msg=NULL;

static int *dsp_hm_abort=NULL;
static int *dsp_hm_block_off=NULL;
static int *dsp_hm_block_on=NULL;
static int *dsp_hm_block_tmq_lwm=NULL;
static int *dsp_hm_blt_p=NULL;
static int *dsp_hm_blt_x=NULL;
static int *dsp_hm_blt_y=NULL;
static int *dsp_hm_clear_dma_hm=NULL;
static int *dsp_hm_close_paren=NULL;
static int *dsp_hm_dm_off=NULL;
static int *dsp_hm_dm_on=NULL;
static int *dsp_hm_dma_rd_ssi_off=NULL;
static int *dsp_hm_dma_rd_ssi_on=NULL;
static int *dsp_hm_dma_wd_ssi_off=NULL;
static int *dsp_hm_dma_wd_ssi_on=NULL;
static int *dsp_hm_done_int=NULL;
static int *dsp_hm_done_noint=NULL;
static int *dsp_hm_execute=NULL;
static int *dsp_hm_fill_p=NULL;
static int *dsp_hm_fill_x=NULL;
static int *dsp_hm_fill_y=NULL;
static int *dsp_hm_first=NULL;
static int *dsp_hm_go=NULL;
static int *dsp_hm_halt=NULL;
static int *dsp_hm_normal_srate=NULL;
static int *dsp_hm_hm_first=NULL;
static int *dsp_hm_hm_last=NULL;
static int *dsp_hm_host_r_done=NULL;
static int *dsp_hm_host_rd_done=NULL;
static int *dsp_hm_host_rd_off=NULL;
static int *dsp_hm_host_rd_on=NULL;
static int *dsp_hm_host_w_dt=NULL;
static int *dsp_hm_host_w_swfix=NULL;
static int *dsp_hm_host_wd_off=NULL;
static int *dsp_hm_host_wd_on=NULL;
static int *dsp_hm_idle=NULL;
static int *dsp_hm_jsr=NULL;
static int *dsp_hm_last=NULL;
static int *dsp_hm_half_srate=NULL;
static int *dsp_hm_open_paren=NULL;
static int *dsp_hm_peek_p=NULL;
static int *dsp_hm_peek_x=NULL;
static int *dsp_hm_peek_y=NULL;
static int *dsp_hm_poke_n=NULL;
static int *dsp_hm_poke_p=NULL;
static int *dsp_hm_poke_x=NULL;
static int *dsp_hm_poke_y=NULL;
static int *dsp_hm_say_something=NULL;
static int *dsp_hm_service_tmq=NULL;
static int *dsp_hm_service_write_data=NULL;
static int *dsp_hm_sine_test=NULL;
static int *dsp_hm_tmq_lwm_me=NULL;
static int *dsp_hm_tmq_room=NULL;
static int *dsp_hm_unblock_tmq_lwm=NULL;
static int *dsp_hm_write_data_switch=NULL;

static int *dsp_i_maxpos=NULL;
static int *dsp_i_minpos=NULL;
static int *dsp_i_ntick=NULL;

static int *dsp_nb_dma=NULL;
static int *dsp_nb_dma_r=NULL;
static int *dsp_nb_dma_w=NULL;
static int *dsp_nb_dmq=NULL;
static int *dsp_nb_tmq=NULL;

static int *dsp_x_nchans=NULL;
static int *dsp_x_nclip=NULL;
static int *dsp_x_sci_count=NULL;
static int *dsp_x_start=NULL;
static int *dsp_x_xhm_r_i1=NULL;
static int *dsp_x_dma_r_m=NULL;
static int *dsp_x_dma_w_m=NULL;

static int *dsp_l_status=NULL;
static int *dsp_l_tick=NULL;
static int *dsp_l_tinc=NULL;
static int *dsp_l_zero=NULL;

static int *dsp_hm_poke_sci=NULL;

static void s_cacheDSPSymbols()
{
    if (dsp_hm_host_w[s_idsp]) /* Already cached */
      return;
    dsp_hm_host_w[s_idsp]= DSP_HM_HOST_W; 
    dsp_hm_host_r[s_idsp]= DSP_HM_HOST_R; 
    dsp_dm_host_r_req[s_idsp]= DSP_DM_HOST_R_REQ; 
    dsp_nb_hms[s_idsp]= DSP_NB_HMS;
    dsp_max_hm[s_idsp]= DSP_NB_HMS-2;

    dsp_de_break[s_idsp]= DSP_DE_BREAK;

#ifdef NO_REVERT
    dsp_hm_poke_l[s_idsp]= DSP_HM_POKE_L;
    dsp_hm_get_long[s_idsp]= DSP_HM_GET_LONG;
    dsp_dm_long0[s_idsp]= DSP_DM_LONG0;
    dsp_dm_long1[s_idsp]= DSP_DM_LONG1;
    dsp_dm_long2[s_idsp]= DSP_DM_LONG2;
    dsp_hm_host_w_done[s_idsp]= DSP_HM_HOST_W_DONE;
#endif

    dsp_dm_hm_first[s_idsp]= DSP_DM_HM_FIRST;
    dsp_dm_hm_last[s_idsp]= DSP_DM_HM_LAST;
    dsp_dm_dm_off[s_idsp]= DSP_DM_DM_OFF;
    dsp_dm_dm_on[s_idsp]= DSP_DM_DM_ON;
    dsp_dm_peek0[s_idsp]= DSP_DM_PEEK0;
    dsp_dm_peek1[s_idsp]= DSP_DM_PEEK1;
    dsp_dm_idle[s_idsp]= DSP_DM_IDLE;
    dsp_dm_iaa[s_idsp]= DSP_DM_IAA;
    dsp_dm_host_r_done[s_idsp]= DSP_DM_HOST_R_DONE;
    dsp_dm_main_done[s_idsp]= DSP_DM_MAIN_DONE;
    dsp_dm_user_msg[s_idsp]= DSP_DM_USER_MSG;

    dsp_hm_abort[s_idsp]= DSP_HM_ABORT;
    dsp_hm_block_off[s_idsp]= DSP_HM_BLOCK_OFF;
    dsp_hm_block_on[s_idsp]= DSP_HM_BLOCK_ON;
    dsp_hm_dm_off[s_idsp]= DSP_HM_DM_OFF;
    dsp_hm_dm_on[s_idsp]= DSP_HM_DM_ON;
    dsp_hm_execute[s_idsp]= DSP_HM_EXECUTE;
    dsp_hm_first[s_idsp]= DSP_HM_FIRST;
    dsp_hm_go[s_idsp]= DSP_HM_GO;
    dsp_hm_halt[s_idsp]= DSP_HM_HALT;
    dsp_hm_hm_first[s_idsp]= DSP_HM_HM_FIRST;
    dsp_hm_hm_last[s_idsp]= DSP_HM_HM_LAST;
    dsp_hm_host_r_done[s_idsp]= DSP_HM_HOST_R_DONE;
    dsp_hm_idle[s_idsp]= DSP_HM_IDLE;
    dsp_hm_jsr[s_idsp]= DSP_HM_JSR;
    dsp_hm_last[s_idsp]= DSP_HM_LAST;
    dsp_hm_poke_n[s_idsp]= DSP_HM_POKE_N;
    dsp_hm_poke_p[s_idsp]= DSP_HM_POKE_P;
    dsp_hm_poke_x[s_idsp]= DSP_HM_POKE_X;
    dsp_hm_poke_y[s_idsp]= DSP_HM_POKE_Y;
    dsp_hm_say_something[s_idsp]= DSP_HM_SAY_SOMETHING;

    dsp_i_maxpos[s_idsp]= DSP_I_MAXPOS;
    dsp_i_minpos[s_idsp]= DSP_I_MINPOS;

    dsp_nb_dma[s_idsp]= DSP_NB_DMA;
    dsp_nb_dma_r[s_idsp]= DSP_NB_DMA_R;
    dsp_nb_dma_w[s_idsp]= DSP_NB_DMA_W;
    dsp_nb_dmq[s_idsp]= DSP_NB_DMQ;
    dsp_nb_tmq[s_idsp]= DSP_NB_TMQ;

    dsp_x_start[s_idsp]= DSP_X_START;
    dsp_x_xhm_r_i1[s_idsp]= DSP_X_XHM_R_I1;
    dsp_x_dma_r_m[s_idsp]= DSP_X_DMA_R_M;
    dsp_x_dma_w_m[s_idsp]= DSP_X_DMA_W_M;

    dsp_l_status[s_idsp]= DSP_L_STATUS;
    dsp_l_zero[s_idsp]= DSP_L_ZERO;

    dsp_hm_poke_sci[s_idsp]= DSP_HM_POKE_SCI;

    if (s_mk_system[s_idsp]) {
	dsp_hm_peek_p[s_idsp]= DSP_HM_PEEK_P;
	dsp_hm_peek_x[s_idsp]= DSP_HM_PEEK_X;
	dsp_hm_peek_y[s_idsp]= DSP_HM_PEEK_Y;
	dsp_hm_block_tmq_lwm[s_idsp]= DSP_HM_BLOCK_TMQ_LWM;
	dsp_hm_blt_p[s_idsp]= DSP_HM_BLT_P;
	dsp_hm_blt_x[s_idsp]= DSP_HM_BLT_X;
	dsp_hm_blt_y[s_idsp]= DSP_HM_BLT_Y;
	dsp_hm_clear_dma_hm[s_idsp]= DSP_HM_CLEAR_DMA_HM;
	dsp_hm_close_paren[s_idsp]= DSP_HM_CLOSE_PAREN;
	dsp_hm_dma_rd_ssi_off[s_idsp]= DSP_HM_DMA_RD_SSI_OFF;
	dsp_hm_dma_rd_ssi_on[s_idsp]= DSP_HM_DMA_RD_SSI_ON;
	dsp_hm_dma_wd_ssi_off[s_idsp]= DSP_HM_DMA_WD_SSI_OFF;
	dsp_hm_dma_wd_ssi_on[s_idsp]= DSP_HM_DMA_WD_SSI_ON;
	dsp_hm_done_int[s_idsp]= DSP_HM_DONE_INT;
	dsp_hm_done_noint[s_idsp]= DSP_HM_DONE_NOINT;
	dsp_hm_fill_p[s_idsp]= DSP_HM_FILL_P;
	dsp_hm_fill_x[s_idsp]= DSP_HM_FILL_X;
	dsp_hm_fill_y[s_idsp]= DSP_HM_FILL_Y;
	dsp_hm_normal_srate[s_idsp]= DSP_HM_NORMAL_SRATE;
	dsp_hm_host_rd_done[s_idsp]= DSP_HM_HOST_RD_DONE;
	dsp_hm_host_rd_off[s_idsp]= DSP_HM_HOST_RD_OFF;
	dsp_hm_host_rd_on[s_idsp]= DSP_HM_HOST_RD_ON;
	dsp_hm_host_w_dt[s_idsp]= DSP_HM_HOST_W_DT;
	dsp_hm_host_w_swfix[s_idsp]= DSP_HM_HOST_W_SWFIX;
	dsp_hm_host_wd_off[s_idsp]= DSP_HM_HOST_WD_OFF;
	dsp_hm_host_wd_on[s_idsp]= DSP_HM_HOST_WD_ON;
	dsp_hm_half_srate[s_idsp]= DSP_HM_HALF_SRATE;
	dsp_hm_open_paren[s_idsp]= DSP_HM_OPEN_PAREN;
	dsp_hm_service_tmq[s_idsp]= DSP_HM_SERVICE_TMQ;
	dsp_hm_service_write_data[s_idsp]= DSP_HM_SERVICE_WRITE_DATA;
	dsp_hm_sine_test[s_idsp]= DSP_HM_SINE_TEST;
	dsp_hm_tmq_lwm_me[s_idsp]= DSP_HM_TMQ_LWM_ME;
	dsp_hm_tmq_room[s_idsp]= DSP_HM_TMQ_ROOM;
	dsp_hm_unblock_tmq_lwm[s_idsp]= DSP_HM_UNBLOCK_TMQ_LWM;
	dsp_hm_write_data_switch[s_idsp]= DSP_HM_WRITE_DATA_SWITCH;
	dsp_i_ntick[s_idsp]= DSP_I_NTICK;
	dsp_x_nchans[s_idsp]= DSP_X_NCHANS;
	dsp_x_nclip[s_idsp]= DSP_X_NCLIP;
	dsp_x_sci_count[s_idsp]= DSP_X_SCI_COUNT;
	dsp_l_tick[s_idsp]= DSP_L_TICK;
	dsp_l_tinc[s_idsp]= DSP_L_TINC;
    }	
}

static void s_clearCachedDSPSymbols()
{
    dsp_hm_host_w[s_idsp]= 0;
    dsp_hm_host_r[s_idsp]= 0;
    dsp_dm_host_r_req[s_idsp]= 0;
    dsp_nb_hms[s_idsp]= 0;
    dsp_max_hm[s_idsp]= 0;

    dsp_de_break[s_idsp]= 0;

#ifdef NO_REVERT
    dsp_hm_poke_l[s_idsp]= 0;
    dsp_hm_get_long[s_idsp]= 0;
    dsp_dm_long0[s_idsp]= 0;
    dsp_dm_long1[s_idsp]= 0;
    dsp_dm_long2[s_idsp]= 0;
    dsp_hm_host_w_done[s_idsp]= 0;
#endif

    dsp_dm_hm_first[s_idsp]= 0;
    dsp_dm_hm_last[s_idsp]= 0;
    dsp_dm_dm_off[s_idsp]= 0;
    dsp_dm_dm_on[s_idsp]= 0;
    dsp_dm_peek0[s_idsp]= 0;
    dsp_dm_peek1[s_idsp]= 0;
    dsp_dm_idle[s_idsp]= 0;
    dsp_dm_iaa[s_idsp]= 0;
    dsp_dm_host_r_done[s_idsp]= 0;
    dsp_dm_main_done[s_idsp]= 0;
    dsp_dm_user_msg[s_idsp]= 0;

    dsp_hm_abort[s_idsp]= 0;
    dsp_hm_block_off[s_idsp]= 0;
    dsp_hm_block_on[s_idsp]= 0;
    dsp_hm_block_tmq_lwm[s_idsp]= 0;
    dsp_hm_blt_p[s_idsp]= 0;
    dsp_hm_blt_x[s_idsp]= 0;
    dsp_hm_blt_y[s_idsp]= 0;
    dsp_hm_clear_dma_hm[s_idsp]= 0;
    dsp_hm_close_paren[s_idsp]= 0;
    dsp_hm_dm_off[s_idsp]= 0;
    dsp_hm_dm_on[s_idsp]= 0;
    dsp_hm_dma_rd_ssi_off[s_idsp]= 0;
    dsp_hm_dma_rd_ssi_on[s_idsp]= 0;
    dsp_hm_dma_wd_ssi_off[s_idsp]= 0;
    dsp_hm_dma_wd_ssi_on[s_idsp]= 0;
    dsp_hm_done_int[s_idsp]= 0;
    dsp_hm_done_noint[s_idsp]= 0;
    dsp_hm_execute[s_idsp]= 0;
    dsp_hm_fill_p[s_idsp]= 0;
    dsp_hm_fill_x[s_idsp]= 0;
    dsp_hm_fill_y[s_idsp]= 0;
    dsp_hm_first[s_idsp]= 0;
    dsp_hm_go[s_idsp]= 0;
    dsp_hm_halt[s_idsp]= 0;
    dsp_hm_normal_srate[s_idsp]= 0;
    dsp_hm_hm_first[s_idsp]= 0;
    dsp_hm_hm_last[s_idsp]= 0;
    dsp_hm_host_r_done[s_idsp]= 0;
    dsp_hm_host_rd_done[s_idsp]= 0;
    dsp_hm_host_rd_off[s_idsp]= 0;
    dsp_hm_host_rd_on[s_idsp]= 0;
    dsp_hm_host_w_dt[s_idsp]= 0;
    dsp_hm_host_w_swfix[s_idsp]= 0;
    dsp_hm_host_wd_off[s_idsp]= 0;
    dsp_hm_host_wd_on[s_idsp]= 0;
    dsp_hm_idle[s_idsp]= 0;
    dsp_hm_jsr[s_idsp]= 0;
    dsp_hm_last[s_idsp]= 0;
    dsp_hm_half_srate[s_idsp]= 0;
    dsp_hm_open_paren[s_idsp]= 0;
    dsp_hm_peek_p[s_idsp]= 0;
    dsp_hm_peek_x[s_idsp]= 0;
    dsp_hm_peek_y[s_idsp]= 0;
    dsp_hm_poke_n[s_idsp]= 0;
    dsp_hm_poke_p[s_idsp]= 0;
    dsp_hm_poke_x[s_idsp]= 0;
    dsp_hm_poke_y[s_idsp]= 0;
    dsp_hm_say_something[s_idsp]= 0;
    dsp_hm_service_tmq[s_idsp]= 0;
    dsp_hm_service_write_data[s_idsp]= 0;
    dsp_hm_sine_test[s_idsp]= 0;
    dsp_hm_tmq_lwm_me[s_idsp]= 0;
    dsp_hm_tmq_room[s_idsp]= 0;
    dsp_hm_unblock_tmq_lwm[s_idsp]= 0;
    dsp_hm_write_data_switch[s_idsp]= 0;

    dsp_i_maxpos[s_idsp]= 0;
    dsp_i_minpos[s_idsp]= 0;
    dsp_i_ntick[s_idsp]= 0;

    dsp_nb_dma[s_idsp]= 0;
    dsp_nb_dma_r[s_idsp]= 0;
    dsp_nb_dma_w[s_idsp]= 0;
    dsp_nb_dmq[s_idsp]= 0;
    dsp_nb_tmq[s_idsp]= 0;

    dsp_x_nchans[s_idsp]= 0;
    dsp_x_nclip[s_idsp]= 0;
    dsp_x_sci_count[s_idsp]= 0;
    dsp_x_start[s_idsp]= 0;
    dsp_x_xhm_r_i1[s_idsp]= 0;
    dsp_x_dma_r_m[s_idsp]= 0;
    dsp_x_dma_w_m[s_idsp]= 0;

    dsp_l_status[s_idsp]= 0;
    dsp_l_tick[s_idsp]= 0;
    dsp_l_tinc[s_idsp]= 0;
    dsp_l_zero[s_idsp]= 0;
    dsp_hm_poke_sci[s_idsp]= 0;

}


/*********************** Macros and misc utilities **************************/

#define DSP_IS_SIMULATED_ONLY (s_simulated[s_idsp] && \
			       !s_saving_commands[s_idsp] && !s_open[s_idsp])
static int s_msgSend(void);


/* -------------------------------------------------------------------------
|| mycalloc - override libsys version (for Nutation 2.1 compatibility)
------------------------------------------------------------------------- */

static void *mycalloc(int count, int size)
{
    int i,n;
    char *c;
    void *p;
    n = count*size;
    p = malloc(n);
    for (i=0, c=(char *)p; i<n; i++)
      *c++ = 0;
    return p;
}

static int s_checkMsgFrameOverflow(char *fn_name)
{
    int ec=0;
    /*** FIXME: Change to an automatic flush when there is a test case ***/
    int msg_frame_overflowed = 0;
    if (s_msg != s_dspcmd_msg) { 
	if (s_msg == ((msg_header_t *)SEND_MSG_TOO_LARGE)) { 
	    if (((snd_dspcmd_msg_t *)s_dspcmd_msg)->header.msg_size 
		== sizeof(snd_dspcmd_msg_t))
	      /* A nonzero return will cause an infinite loop */
	      return 
		_DSPError(DSP_EPROTOCOL,
			  DSPCat(fn_name,": "
				 "Mach message component will not fit "
				 "in a maximum size message frame!"));
	    msg_frame_overflowed = 1; 
	    ec = s_msgSend(); 
	    if (ec != KERN_SUCCESS) 
	      return _DSPMachError(ec,DSPCat(fn_name,": " 
					     "s_msgSend failed.")); 
	    _DSP_dspcmd_msg_reset(s_dspcmd_msg, 
				  s_dsp_hm_port[s_idsp], 
				  PORT_NULL, /* DO NOT request an ack msg */ 
				  s_cur_pri[s_idsp], s_cur_atomicity[s_idsp]); 
	} else 
	  return _DSPMachError(ec,DSPCat(fn_name,":" 
					 "Could not add message component")); 
    } else 
      msg_frame_overflowed = 0;
    return msg_frame_overflowed;
}
      
/* Check for s_mapped_only added by DAJ. Feb. 28, 94 */
#define BEGIN_OPTIMIZATION \
    if (!s_mapped_only[s_idsp]) \
      _DSP_dspcmd_msg_reset(s_dspcmd_msg, \
			  s_dsp_hm_port[s_idsp], PORT_NULL, \
			  s_cur_pri[s_idsp], DSP_ATOMIC); \
    s_optimizing[s_idsp] = s_do_optimization[s_idsp]

#define END_OPTIMIZATION \
    if (!s_mapped_only[s_idsp] && s_optimizing[s_idsp] && \
	(((snd_dspcmd_msg_t *)s_dspcmd_msg)->header.msg_size \
	> sizeof(snd_dspcmd_msg_t))) \
       ec = s_msgSend(); \
    s_optimizing[s_idsp] = 0

#if m68k
#define DSP_CAN_INTERRUPT (!(s_dsp_mode_flags[s_idsp] & \
			     SNDDRIVER_DSP_PROTO_RAW) \
			   || (s_dsp_mode_flags[s_idsp] \
			       & (SNDDRIVER_DSP_PROTO_DSPMSG \
				  | SNDDRIVER_DSP_PROTO_C_DMA)))
#else
#define DSP_CAN_INTERRUPT (s_host_msg[s_idsp])
#endif


/************************ Time stamping utilities *************************/

static struct timeval s_timeval; /* used for time-stamping */
/* static struct timezone s_timezone; (not used) */
static int s_prvtime = 0;
static int s_curtime = 0;
static int s_deltime = 0;

BRIEF int DSPGetHostTime(void) 
{
    gettimeofday(&s_timeval, NULL /* &s_timezone (2K of junk) */);
    s_curtime = (s_timeval.tv_sec & (long)0x7FF)*1000000 
      + s_timeval.tv_usec;
    if (s_prvtime == 0)
      s_deltime = 0;
    else
      s_deltime = s_curtime - s_prvtime;
    s_prvtime = s_curtime;
    return(s_deltime);
}
    
/***** Utilities which belong global with respect to all DSP instances *******/
    
/*** FIXME: 
      This section should only exist in the Objective C DSP manager object
      (which has not yet been written).  DSPObject.c corresponds
      to one instance of a DSP object, and this function will 
      set the "active" DSP id to the newidsp'th element of an array of DSP 
      id's. 
***/

/************************** Multiple DSP Support **************************/

#if m68k  /* Forward declarations */
BRIEF int DSPAddNetworkDSP(const char *hostName); 
static int s_addQuintBoard(void); 
#endif

static void doInit() {
  _DSPInitDefaults();
#if !m68k && (defined(NeXT) || (defined(__APPLE__) && defined(__MACH__)))
  _DSPAddIntelBasedDSPs();
#endif
#if m68k
  DSPAddNetworkDSP("");    /* set up DSP 0 (motherboard DSP) */ 
  s_addQuintBoard();     /* if one or more exist */ 
#endif
}

#define CHECK_INIT if (s_dsp_count==0) doInit()

static void s_reallocPointers(void **ptr)
{
    int i;
    if (*ptr) {
	*ptr = realloc(*ptr, s_dsp_alloc * sizeof(int *));
	for (i=s_dsp_alloc-_DSP_COUNT_STEP;i<s_dsp_alloc;i++)
	  ((int *)(*ptr))[i] = 0;
    } else
      *ptr = mycalloc(s_dsp_alloc, sizeof(int *));
}

static void s_reallocDoubles(double **ptr)
{
    int i;
    if (*ptr) {
	*ptr = realloc(*ptr, s_dsp_alloc * sizeof(double));
	for (i=s_dsp_alloc-_DSP_COUNT_STEP;i<s_dsp_alloc;i++)
	  (*ptr)[i] = 0; /* ()s added by DAJ to fix precedence bug */
    } else
      *ptr = mycalloc(s_dsp_alloc, sizeof(double));
}

static void s_reallocDSPFix48(DSPFix48 **ptr)
{
    DSPFix48 *arr;
    DSPFix48 *el;
    int i;
    if (*ptr) {
	arr = *ptr = realloc(*ptr, s_dsp_alloc * sizeof(DSPFix48));
	for (i=s_dsp_alloc-_DSP_COUNT_STEP;i<s_dsp_alloc;i++) {
	    el = &(arr[i]);
	    el->high24 = 0;
	    el->low24 = 0;
	}
    } else
      *ptr = mycalloc(s_dsp_alloc, sizeof(DSPFix48));
}

static void s_reallocAll()
{
    /*** Port-based DSPs ***/
    s_reallocPointers((void **)&s_nameArray);
    s_reallocPointers((void **)&s_hostInterfaceArray);
    s_reallocDoubles(&s_srate);
    s_reallocPointers((void **)&s_low_srate);
    s_reallocPointers((void **)&s_dsp_mode_flags);
    s_reallocPointers((void **)&s_dsp_access_flags);
    s_reallocPointers((void **)&s_dsp_buf_wds);
    s_reallocPointers((void **)&s_dsp_record_buf_bytes);
    s_reallocPointers((void **)&s_dsp_play_buf_bytes);
    s_reallocPointers((void **)&s_rd_buf);
    s_reallocPointers((void **)&s_do_dma_array_reads);
    s_reallocPointers((void **)&s_do_dma_array_writes);
    s_reallocPointers((void **)&s_do_optimization);
    s_reallocPointers((void **)&s_ssi_sound_out);
    s_reallocPointers((void **)&s_ssi_read_data);
    
    /* Write data */
    s_reallocPointers((void **)&s_write_data);
    s_reallocPointers((void **)&s_stop_write_data);
    s_reallocPointers((void **)&s_write_data_running);
    s_reallocPointers((void **)&s_wd_fn);
    s_reallocPointers((void **)&s_wd_fd);
    s_reallocPointers((void **)&s_wd_user_func);
    s_reallocPointers((void **)&s_wd_fp);
    s_reallocPointers((void **)&s_wd_header);
    s_reallocPointers((void **)&s_wd_sample_count);
    s_reallocPointers((void **)&s_wd_timeout);
    s_reallocPointers((void **)&s_no_thread);
    
    s_reallocPointers((void **)&s_wd_thread);
    s_reallocPointers((void **)&s_wd_error);
    s_reallocPointers((void **)&s_wd_error_str);
    
    s_reallocPointers((void **)&s_read_data);
    s_reallocPointers((void **)&s_stop_read_data);
    s_reallocPointers((void **)&s_read_data_running);
    s_reallocPointers((void **)&s_rd_fn);
    s_reallocPointers((void **)&s_rd_fd);
    s_reallocPointers((void **)&s_rd_chans);
    s_reallocPointers((void **)&s_rd_header);
    s_reallocPointers((void **)&s_rd_sample_count);
    s_reallocPointers((void **)&s_rd_thread);
    s_reallocPointers((void **)&s_rd_error);
    s_reallocPointers((void **)&s_rd_error_str);
    s_reallocPointers((void **)&s_dsp_rd_buf0);
    s_reallocPointers((void **)&s_rd_rmsg);
    
    s_reallocPointers((void **)&s_cur_pri);
    s_reallocPointers((void **)&s_cur_atomicity);
    s_reallocPointers((void **)&s_sound_dev_port);
    s_reallocPointers((void **)&s_dsp_owner_port);
    s_reallocPointers((void **)&s_dsp_hm_port);
    s_reallocPointers((void **)&s_dsp_dm_port);
    s_reallocPointers((void **)&s_driver_reply_port);
    s_reallocPointers((void **)&s_dsp_err_port);
    s_reallocPointers((void **)&s_dsp_neg_port);
    s_reallocPointers((void **)&s_dsp_err_thread);
    s_reallocPointers((void **)&s_dsp_msg_thread);
    s_reallocPointers((void **)&s_stop_msg_reader);
    s_reallocPointers((void **)&s_wd_stream_port);
    s_reallocPointers((void **)&s_wd_reply_port);
    s_reallocPointers((void **)&s_rd_stream_port);
    s_reallocPointers((void **)&s_rd_reply_port);
    s_reallocPointers((void **)&s_msg_read_pending);
    s_reallocPointers((void **)&s_optimizing);
    s_reallocPointers((void **)&s_timed_zero_noflush);
    
    s_reallocPointers((void **)&s_dsp_fd);
    s_reallocPointers((void **)&s_max_rxdf_buzz);
    s_reallocPointers((void **)&s_max_txde_buzz);
    s_reallocPointers((void **)&s_max_hm_buzz);
    
    s_reallocPointers((void **)&s_ap_system);
    s_reallocPointers((void **)&s_mk_system);
    
    s_reallocPointers((void **)&s_open);
    s_reallocPointers((void **)&s_open_priority);
    s_reallocPointers((void **)&s_whofile_fp);

    s_reallocPointers((void **)&s_bail_out);
    s_reallocPointers((void **)&s_clock_advancing);
    s_reallocPointers((void **)&s_clock_just_started);
    s_reallocPointers((void **)&s_prev_kern_ack_time);
    
    s_reallocPointers((void **)&s_mapped_only);
    s_reallocPointers((void **)&s_host_msg);
    s_reallocPointers((void **)&s_sound_out);
    
    s_reallocPointers((void **)&s_simulated);
    s_reallocPointers((void **)&s_simulatorFile);
    s_reallocPointers((void **)&s_simulator_fp);
    
    s_reallocPointers((void **)&s_saving_commands);
    s_reallocPointers((void **)&s_commandsFile);
    s_reallocPointers((void **)&s_commands_fd);
    s_reallocPointers((void **)&s_commands_fp);
    s_reallocPointers((void **)&s_commands_numbytes);
    
    s_reallocPointers((void **)&s_dsp_msgs_waiting);
    s_reallocPointers((void **)&s_dsp_msg_0);
    s_reallocPointers((void **)&s_dsp_msg_ptr);
    s_reallocPointers((void **)&s_dsp_msg_count);
    
    s_reallocPointers((void **)&s_max_block_time);
    s_reallocPointers((void **)&s_all_block_time);
    
    s_reallocPointers((void **)&s_so_buf_bytes);
    s_reallocPointers((void **)&s_systemImage);
    s_reallocPointers((void **)&s_system_link_file);
    s_reallocPointers((void **)&s_system_binary_file);
    s_reallocPointers((void **)&s_joint_owner);
    s_reallocPointers((void **)&s_dsp_messages_disabled);
    s_reallocPointers((void **)&s_low_water);
    s_reallocPointers((void **)&s_high_water);
    s_reallocPointers((void **)&s_stream_configuration);
    s_reallocPointers((void **)&s_frozen);
    s_reallocPointers((void **)&s_small_buffers);
    s_reallocPointers((void **)&s_force_tmq_flush);
    s_reallocPointers((void **)&s_timedMsg);
    s_reallocPointers((void **)&s_curTimedWd);
    s_reallocPointers((void **)&s_timedArrEnd);
    s_reallocPointers((void **)&s_TMQMessageCount);
    s_reallocPointers((void **)&s_hm_array);
    s_reallocPointers((void **)&s_hm_ptr);
    s_reallocDSPFix48(&(DSPFix48 *)s_curTimeStamp);
    s_reallocPointers((void **)&s_wd_rmsg);

    s_reallocPointers((void **)&s_min_dma_chan);
    s_reallocPointers((void **)&s_max_dma_chan);
    s_reallocDoubles(&s_driver_version);
    
    /******************** Cached DSP symbols (all DSPs) ***************/
    
    s_reallocPointers((void **)&dsp_hm_host_w);
    s_reallocPointers((void **)&dsp_hm_host_r);
    s_reallocPointers((void **)&dsp_dm_host_r_req);
    s_reallocPointers((void **)&dsp_nb_hms);
    s_reallocPointers((void **)&dsp_max_hm);
    
    s_reallocPointers((void **)&dsp_de_break);
    
#ifdef NO_REVERT
    s_reallocPointers((void **)&dsp_hm_poke_l);
    s_reallocPointers((void **)&dsp_hm_get_long);
    s_reallocPointers((void **)&dsp_dm_long0);
    s_reallocPointers((void **)&dsp_dm_long1);
    s_reallocPointers((void **)&dsp_dm_long2);
    s_reallocPointers((void **)&dsp_hm_host_w_done);
#endif
    
    s_reallocPointers((void **)&dsp_dm_hm_first);
    s_reallocPointers((void **)&dsp_dm_hm_last);
    s_reallocPointers((void **)&dsp_dm_dm_off);
    s_reallocPointers((void **)&dsp_dm_dm_on);
    s_reallocPointers((void **)&dsp_dm_peek0);
    s_reallocPointers((void **)&dsp_dm_peek1);
    s_reallocPointers((void **)&dsp_dm_idle);
    s_reallocPointers((void **)&dsp_dm_iaa);
    s_reallocPointers((void **)&dsp_dm_host_r_done);
    s_reallocPointers((void **)&dsp_dm_main_done);
    s_reallocPointers((void **)&dsp_dm_user_msg);
    
    s_reallocPointers((void **)&dsp_hm_abort);
    s_reallocPointers((void **)&dsp_hm_block_off);
    s_reallocPointers((void **)&dsp_hm_block_on);
    s_reallocPointers((void **)&dsp_hm_block_tmq_lwm);
    s_reallocPointers((void **)&dsp_hm_blt_p);
    s_reallocPointers((void **)&dsp_hm_blt_x);
    s_reallocPointers((void **)&dsp_hm_blt_y);
    s_reallocPointers((void **)&dsp_hm_clear_dma_hm);
    s_reallocPointers((void **)&dsp_hm_close_paren);
    s_reallocPointers((void **)&dsp_hm_dm_off);
    s_reallocPointers((void **)&dsp_hm_dm_on);
    s_reallocPointers((void **)&dsp_hm_dma_rd_ssi_off);
    s_reallocPointers((void **)&dsp_hm_dma_rd_ssi_on);
    s_reallocPointers((void **)&dsp_hm_dma_wd_ssi_off);
    s_reallocPointers((void **)&dsp_hm_dma_wd_ssi_on);
    s_reallocPointers((void **)&dsp_hm_done_int);
    s_reallocPointers((void **)&dsp_hm_done_noint);
    s_reallocPointers((void **)&dsp_hm_execute);
    s_reallocPointers((void **)&dsp_hm_fill_p);
    s_reallocPointers((void **)&dsp_hm_fill_x);
    s_reallocPointers((void **)&dsp_hm_fill_y);
    s_reallocPointers((void **)&dsp_hm_first);
    s_reallocPointers((void **)&dsp_hm_go);
    s_reallocPointers((void **)&dsp_hm_halt);
    s_reallocPointers((void **)&dsp_hm_normal_srate);
    s_reallocPointers((void **)&dsp_hm_hm_first);
    s_reallocPointers((void **)&dsp_hm_hm_last);
    s_reallocPointers((void **)&dsp_hm_host_r_done);
    s_reallocPointers((void **)&dsp_hm_host_rd_done);
    s_reallocPointers((void **)&dsp_hm_host_rd_off);
    s_reallocPointers((void **)&dsp_hm_host_rd_on);
    s_reallocPointers((void **)&dsp_hm_host_w_dt);
    s_reallocPointers((void **)&dsp_hm_host_w_swfix);
    s_reallocPointers((void **)&dsp_hm_host_wd_off);
    s_reallocPointers((void **)&dsp_hm_host_wd_on);
    s_reallocPointers((void **)&dsp_hm_idle);
    s_reallocPointers((void **)&dsp_hm_jsr);
    s_reallocPointers((void **)&dsp_hm_last);
    s_reallocPointers((void **)&dsp_hm_half_srate);
    s_reallocPointers((void **)&dsp_hm_open_paren);
    s_reallocPointers((void **)&dsp_hm_peek_p);
    s_reallocPointers((void **)&dsp_hm_peek_x);
    s_reallocPointers((void **)&dsp_hm_peek_y);
    s_reallocPointers((void **)&dsp_hm_poke_n);
    s_reallocPointers((void **)&dsp_hm_poke_p);
    s_reallocPointers((void **)&dsp_hm_poke_x);
    s_reallocPointers((void **)&dsp_hm_poke_y);
    s_reallocPointers((void **)&dsp_hm_say_something);
    s_reallocPointers((void **)&dsp_hm_service_tmq);
    s_reallocPointers((void **)&dsp_hm_service_write_data);
    s_reallocPointers((void **)&dsp_hm_sine_test);
    s_reallocPointers((void **)&dsp_hm_tmq_lwm_me);
    s_reallocPointers((void **)&dsp_hm_tmq_room);
    s_reallocPointers((void **)&dsp_hm_unblock_tmq_lwm);
    s_reallocPointers((void **)&dsp_hm_write_data_switch);
    
    s_reallocPointers((void **)&dsp_i_maxpos);
    s_reallocPointers((void **)&dsp_i_minpos);
    s_reallocPointers((void **)&dsp_i_ntick);
    
    s_reallocPointers((void **)&dsp_nb_dma);
    s_reallocPointers((void **)&dsp_nb_dma_r);
    s_reallocPointers((void **)&dsp_nb_dma_w);
    s_reallocPointers((void **)&dsp_nb_dmq);
    s_reallocPointers((void **)&dsp_nb_tmq);
    
    s_reallocPointers((void **)&dsp_x_nchans);
    s_reallocPointers((void **)&dsp_x_nclip);
    s_reallocPointers((void **)&dsp_x_sci_count);
    s_reallocPointers((void **)&dsp_x_start);
    s_reallocPointers((void **)&dsp_x_xhm_r_i1);
    s_reallocPointers((void **)&dsp_x_dma_r_m);
    s_reallocPointers((void **)&dsp_x_dma_w_m);
    
    s_reallocPointers((void **)&dsp_l_status);
    s_reallocPointers((void **)&dsp_l_tick);
    s_reallocPointers((void **)&dsp_l_tinc);
    s_reallocPointers((void **)&dsp_l_zero);

    s_reallocPointers((void **)&dsp_hm_poke_sci);

}


static void s_addDSP(const char *name)
{
    int i = s_dsp_count++;
    if (s_dsp_count > s_dsp_alloc) {
	s_dsp_alloc += _DSP_COUNT_STEP;
	s_reallocAll();
    }

    s_nameArray[i] = malloc(strlen(name)+1);
    strcpy(s_nameArray[i],name);
    s_hostInterfaceArray[i] = 0; /* if mapped, must set this */
    s_mapped_only[i] = 0; /* if mapped, must set this nonzero */

    /* Set defaults which are different from 0 */
    s_srate[i] = 22050.;
    s_low_srate[i] = 1;
    s_dsp_record_buf_bytes[i] = _DSPMK_WD_BUF_BYTES;
    s_dsp_play_buf_bytes[i] = _DSPMK_RD_BUF_BYTES;
    s_do_optimization[i] = 1;
    /*** FIXME: Optimization seems to cause a new hanging bug reproducible
      every time via "playscore -w /tmp/e5.snd Examp5".  What happens is that
      the TMQ fills up during a DMA-out.  The next message component is
      waiting for HF3 to clear, and this prevents the higher-priority
      DMA-complete messages from getting through.  Solution is either to
      turn off optimization (done here) or allow DMA-complete messages
      to bypass anything in progress (break the atomic rule for multicomponent
      messages in this case).
      (Later) - Turning off optimization seems not to help.
      I think setting s_do_optimization[i] = 0 may not really turn it off!
      ***/
    s_wd_fd[i] = -1;
    s_wd_timeout[i] = _DSPMK_WD_TIMEOUT;
    s_rd_fd[i] = -1;
    s_rd_chans[i] = 1;
    s_cur_pri[i] = DSP_MSG_LOW;
    s_cur_atomicity[i] = DSP_NON_ATOMIC;
    s_dsp_fd[i] = -1;
    s_ap_system[i] = 1;
    s_commands_fd[i] = -1;
    s_commands_fp[i] = NULL;
    s_so_buf_bytes[i] = _DSPMK_LARGE_SO_BUF_BYTES;
    s_system_link_file[i] = DSP_AP_SYSTEM_0;
    s_system_binary_file[i] = DSP_AP_SYSTEM_BINARY_0;
    s_low_water[i] = 48*1024;
    s_high_water[i] = 64*1024;
    if (s_idsp == 0)
      s_do_dma_array_reads[0] = s_do_dma_array_writes[0] = DO_AUTO_DMA;
    s_min_dma_chan[s_idsp] = s_max_dma_chan[s_idsp] = DSPMK_WD_DSP_CHAN; 
    /* The first channel to be allocated will be DSPMK_WD_DSP_CHAN + 1 */
}

BRIEF int DSPAddNetworkDSP(const char *hostName)
{
    s_addDSP(hostName);
    return 0;
}

BRIEF int DSPAddMappedDSP(DSPRegs *hostInterfaceAddress, const char *name)
{
    s_addDSP(name);
    s_hostInterfaceArray[s_dsp_count-1] = hostInterfaceAddress;
    s_mapped_only[s_dsp_count-1] = 1;
    return 0;
}

#if !m68k && (defined(NeXT) || (defined(__APPLE__) && defined(__MACH__)))
int _DSPAddIntelBasedDSP(char *driverName,int unit,int subUnit,float version)
{
    char *name;
    /* No CHECK_INIT here! */
    if (!driverName) {
        DSPAddMappedDSP(0,"<place-holder>");
        if (_DSPVerbose)
          fprintf(stderr,"Added place-holder DSP\n");
        return 0;
    }
    dsp_addDsp(s_dsp_count,driverName,unit,subUnit);
    name = malloc(strlen(driverName)+16);
    sprintf(name,"%s%d-%d",driverName,unit,subUnit);
    DSPAddMappedDSP(0,name);
    s_driver_version[s_idsp] = version;
    if (_DSPVerbose)
      fprintf(stderr,"Added intel-based DSP %s\n", name);
    free(name);
    return 0;
}
#endif


#if m68k
#include "DSPQuintSupport.c"
static int ignoreQuintBoard = 0;

void _DSPIgnoreQuintBoard(int yesOrNo)
    /* This is needed when using gdb.  Otherwise, you get a segmentation fault. */
{
    ignoreQuintBoard = yesOrNo;
}

static int s_addQuintBoard(void)
{
    int i;
    int dspPresenceVector; 
    if (ignoreQuintBoard)
      return 0;
    dspPresenceVector = masterSetup(); /* DSPQuintSupport.c */
    if (!dspPresenceVector)
      return 0;			/* No Ariel QuintProcessor board */
    for (i=1; i<16; i++)
      if (dspExists(i)) {
	  if (s_dsp_count != i) {
	      if (_DSPVerbose)
		fprintf(stderr,"s_dsp_count=%d i=%d\n",s_dsp_count,i);
	      return _DSPError(DSP_EQUINT,
			       "Must add Quint DSPs before any others. E.g.,"
			       "add any network DSPs after opening host DSP.");
	  }
	  /* Actually, anything causing a CHECK_INIT will load the Quints */
	  /* We could make an array which maps our index to Quint index */
	  DSPAddMappedDSP(getRegsPointer(i),DSPCat("Quint",_DSPCVS(i)));
	  /*** NOTE: DSPReset() depends on the above name being "Quint<i>" ***/
      } else if (_DSPVerbose)
	fprintf(stderr,"DSP %d doesn't exist.\n",i);
    if (_DSPVerbose)
      fprintf(stderr,"%d QuintProcessor DSPs added\n", s_dsp_count-1);
    return 0;
}

#endif m68k

BRIEF int DSPGetDSPCount(void)
{
    CHECK_INIT;
    return s_dsp_count;
}

BRIEF int DSPSetHostName(char *newHost)
{
    /*     s_current_host = _DSPCopyStr(newHost); */
    /*** Use fprintf instead of _DSPError to reach David Jaffe ***/
    fprintf(stderr,"DSPSetHostName() is obsolete. Use DSPAddNetworkDSP()\n");
    return -1;
}

char *DSPGetHostName(void)
{
    /*     return s_current_host; */
    /*** Use fprintf instead of _DSPError to reach David Jaffe ***/
    fprintf(stderr,"DSPGetHostName() is obsolete.\n");
    return NULL;
}

BRIEF int DSPSetCurrentDSP(int newidsp)
{
    s_idsp = (newidsp < 0? 0 : (newidsp < s_dsp_count? newidsp : 0));
    if ( newidsp != s_idsp)
      return(_DSPError(EINVAL,"DSP number out of range - selecting DSP 0"));
    s_hostInterface = s_hostInterfaceArray[s_idsp];
#if m68k
    if (s_idsp>0 
	&& s_mapped_only[s_idsp] 
	&& strncmp(s_nameArray[s_idsp],"Quint",5)==0) { /* Quint case */
	if(!setCurrDsp(s_idsp)) /*** DEPENDS ON QUINT NUMBERS BEING SAME ***/
	  return _DSPError1(DSP_EQUINT,"DSPSetCurrentDSP(QuintProcessor): "
			    "failed for DSP %s (not present?)", 
			    _DSPCVS(s_idsp));
    } else if (!s_mapped_only[s_idsp]) { 
	/* port-based case -- nothing to do */
    } 
    else
      return _DSPError1(DSP_EMISC,"DSPReset: Don't know how to select DSP %s "
			"(memory-mapped, not a Quint)", _DSPCVS(s_idsp));
#endif
    return 0;
}

BRIEF int DSPGetCurrentDSP(void)
{
    return s_idsp;
}

BRIEF double DSPGetDriverVersion(void)
{
    return s_driver_version[s_idsp];
}

/***************** Boolean state interrogation functions ******************/

/*
 * These functions do not follow the convention of returning an error code.
 * Instead (because there can be no error), they return a boolean value.
 * Each functions in this class has a name beginning with "DSPIs".
 */


BRIEF int DSPIsOpen(void)
{
    CHECK_INIT;
    return(s_open[s_idsp]);
}


BRIEF int DSPMKIsWithSoundOut(void)
{
    CHECK_INIT;
    return(s_sound_out[s_idsp]);
}


BRIEF int DSPDataIsAvailable(void)
/*
 * Returns nonzero if DSP data is waiting to be read.
 */
{
    int isr,rxdf;
    if (ec=DSPReadISR(&isr)) {
	_DSPError(ec,"DSPMessageIsAvailable: Cannot read ISR");
	return(-1); /* Error code = invalid data */
    }
    rxdf = (isr & DSP_ISR_RXDF) != 0;
    return rxdf;
}


BRIEF int DSPMessageIsAvailable(void)
/*
 * Returns nonzero if DSP messages are waiting to be read.
 */
{
    if (s_dsp_msgs_waiting[s_idsp])
      return(TRUE);
    if (!s_host_msg[s_idsp])
      return DSPGetISR()&DSP_ISR_RXDF;
    else
      DSPReadMessages(1); /* FIXME: Flush if thread used later */
    return s_dsp_msgs_waiting[s_idsp];
}

BRIEF int DSPIsSimulated(void)
{
    CHECK_INIT;
    return(s_simulated[s_idsp]);
}

BRIEF int DSPIsSimulatedOnly(void)
{
    CHECK_INIT;
    return(DSP_IS_SIMULATED_ONLY);
}

BRIEF int DSPIsSavingCommands(void)
{
    CHECK_INIT;
    return(s_saving_commands[s_idsp]);
}

BRIEF int DSPIsSavingCommandsOnly(void)
{
    CHECK_INIT;
    return(s_saving_commands[s_idsp] 
	   && !s_simulated[s_idsp] 
	   && !s_open[s_idsp]);
}


/************************ Mapped Host Interface Access ***********************/

#if !m68k && (defined(NeXT) || (defined(__APPLE__) && defined(__MACH__)))

#define RXDF (dsp_getISR(s_idsp)&1)
#define TXDE (dsp_getISR(s_idsp)&2)
#define TRDY (dsp_getISR(s_idsp)&4)
#define HF2 (dsp_getISR(s_idsp)&8)
#define HC (dsp_getCVR(s_idsp)&0x80)
    
#else

#define RXDF (s_hostInterface->isr&1)
#define TXDE (s_hostInterface->isr&2)
#define TRDY (s_hostInterface->isr&4)
#define HF2 (s_hostInterface->isr&8)
#define HC (s_hostInterface->cvr&0x80)

#endif



#if IS_NEXT_DSP

#define TXH (s_hostInterface->data.tx.h)
#define TXM (s_hostInterface->data.tx.m)
#define TXL (s_hostInterface->data.tx.l)

#define RXH (s_hostInterface->data.rx.h)
#define RXM (s_hostInterface->data.rx.m)
#define RXL (s_hostInterface->data.rx.l)

#define SET_TRANSMIT 
#define GET_RECEIVE

#else

static unsigned char transmitArray[4];
static unsigned char receiveArray[4];
#define TXH transmitArray[1]
#define TXM transmitArray[2]
#define TXL transmitArray[3]
#define RXH receiveArray[1]
#define RXM receiveArray[2]
#define RXL receiveArray[3]

INLINE void setTransmit(void) {
#if !m68k && (defined(NeXT) || (defined(__APPLE__) && defined(__MACH__)))
    dsp_putTXRaw(s_idsp,TXH,TXM,TXL);
#else
    unsigned int tmp,ac;
    tmp = TXH;
    tmp = tmp << 16;
    ac = tmp;
    tmp = TXM;
    tmp = tmp << 8;
    ac |= tmp;
    tmp = TXL;
    ac |= tmp;
    s_hostInterface->data.transmit = ac;
#endif
}

INLINE void getReceive(void) {
#if !m68k && (defined(NeXT) || (defined(__APPLE__) && defined(__MACH__)))
    dsp_getRXRaw(s_idsp,&RXH,&RXM,&RXL);
#else
    unsigned int ac;
    ac = s_hostInterface->data.receive;
    RXH = (ac >> 16) & 0xff;
    RXM = (ac >> 8) & 0xff;
    RXL = ac & 0xff;
#endif
}

#define SET_TRANSMIT setTransmit()
#define GET_RECEIVE getReceive()

#endif


#ifdef __LITTLE_ENDIAN__
INLINE void s_writeTX(void *wp)
{
    register unsigned char *bp = ((unsigned char *)wp);
    TXL = *bp++;
    TXM = *bp++;
    TXH = *bp;
    SET_TRANSMIT;
}

INLINE int s_readRX(void)
{
    int rx;
    register unsigned char *bp = (unsigned char *)(&rx);
    GET_RECEIVE;
    *bp++ = RXL;
    *bp++ = RXM;
    *bp++ = RXH;
    *bp++ = 0;
    return rx;
}

INLINE unsigned short s_readRXML(void)
{
    short rx;
    register unsigned char *bp = (unsigned char *)(&rx);
    GET_RECEIVE;
    *bp++ = RXL;
    *bp = RXM;
    return rx;
}

INLINE void s_writeTXMLSigned(short *sp)
{
    register unsigned char c1;
    TXL = *((unsigned char *)sp)++;
    c1 = *((unsigned char *)sp);
    if (c1 & 0x80)
      TXH = 0xFF;
    else
      TXH = 0;
    TXM = c1;
    SET_TRANSMIT;
}

#else  /* __BIG_ENDIAN__ */

INLINE void s_writeTX(void *wp)
{
    register unsigned char *bp = (((unsigned char *)wp)+1);
    TXH = *bp++;
    TXM = *bp++;
    TXL = *bp;
    SET_TRANSMIT;
}

INLINE int s_readRX(void)
{
    int rx;
    register unsigned char *bp = (unsigned char *)(&rx);
    GET_RECEIVE;
    *bp++ = 0;
    *bp++ = RXH;
    *bp++ = RXM;
    *bp = RXL;
    return rx;
}

INLINE unsigned short s_readRXML(void)
{
    short rx;
    register unsigned char *bp = (unsigned char *)(&rx);
    GET_RECEIVE;
    *bp++ = RXM;
    *bp = RXL;
    return rx;
}
INLINE void s_writeTXMLSigned(short *sp)
{
    register unsigned char c1 = *((unsigned char *)sp)++;
    if (c1 & 0x80)
      TXH = 0xFF;
    else
      TXH = 0;
    TXM = c1;
    TXL = *((unsigned char *)sp);
    SET_TRANSMIT;
}

#endif  /* __BIG_ENDIAN__ */

INLINE void s_writeTXLSigned(char *bp)
{
    register unsigned char c0 = 0;
    register unsigned char c1 = *(unsigned char *)bp;
    if (c1 & 0x80)
      c0 = 0xFF;
    TXH = c0;
    TXM = c0;
    TXL = c1;
    SET_TRANSMIT;
}

INLINE unsigned char s_readRXL(void)
{
    unsigned char rx;
    GET_RECEIVE;
    rx = RXL;
    return rx;
}

#if 0

/* Unsigned versions (not needed at present) */

INLINE void s_clearTXH(void)
{
    TXH = 0;
    SET_TRANSMIT;
}

INLINE void s_writeTXML(unsigned short *sp)
/* First call s_clearTXH() */
{
    TXM = *((unsigned char *)sp)++;
    TXL = *((unsigned char *)sp);
    SET_TRANSMIT;
}

INLINE void s_clearTXHM(void)
{
    TXH = 0;
    TXM = 0;
    SET_TRANSMIT;
}

INLINE void s_writeTXL(unsigned char *bp)
/* First call s_clearTXHM() */
{
    TXL = *bp;
    SET_TRANSMIT;
}

#endif /* Unsigned versions */

/*************** Getting and setting "DSP instance variables" ****************/

/*
 * DSP "get" functions do not follow the convention of returning an error code.
 * Instead (because there can be no error), they return the requested value.
 * Each functions in this class has a name beginning with "DSPGet".
 */

BRIEF int DSPGetOpenPriority(void)
{
    CHECK_INIT;
    return s_open_priority[s_idsp];
}


BRIEF int DSPSetOpenPriority(int pri)
{
    CHECK_INIT;
    s_open_priority[s_idsp] = pri;
    return 0;
}


BRIEF int DSPGetMessagePriority(void)
{
    CHECK_INIT;
    return s_cur_pri[s_idsp];
}


BRIEF int DSPSetMessagePriority(int pri)
{
    CHECK_INIT;
    if (pri==DSP_MSG_HIGH)
      s_cur_pri[s_idsp] = DSP_MSG_HIGH;
    else if (pri==DSP_MSG_LOW)
      s_cur_pri[s_idsp] = DSP_MSG_LOW;
    else if (pri==DSP_MSG_MED)
      s_cur_pri[s_idsp] = DSP_MSG_MED;
    else return _DSPError1(DSP_EMISC, "DSPSetMessagePriority: "
			   "Mach message priority %s does not exist",
			   _DSPCVS(pri));
    return 0;
}


BRIEF int DSPGetMessageAtomicity(void)
{
    CHECK_INIT;
    return s_cur_atomicity[s_idsp];
}


BRIEF int DSPSetMessageAtomicity(int atomicity)
{
    int oa = s_cur_atomicity[s_idsp];
    CHECK_INIT;
    if (atomicity!=0)
      s_cur_atomicity[s_idsp] = DSP_ATOMIC;
    else
      s_cur_atomicity[s_idsp] = DSP_NON_ATOMIC;
    return oa;
}


BRIEF DSPRegs *_DSPGetRegs(void)
{
    CHECK_INIT;
    if (!s_open[s_idsp])
      return(NULL);
    else
      return(s_hostInterface);
}


/* 
 * The routines which toggle mapped DSP access are obsolete.
 * It used to be possible to access the CPU board DSP either
 * in mapped mode (the original interface) or port based.
 * Now the CPU's DSP can only be accessed via Mach ports,
 * and Ariel QuintProcessor DSPs can only be accessed in 
 * mapped mode.
 */

BRIEF int DSPEnableMappedOnly(void)
{
    CHECK_INIT;
    
#if !MMAP
    return _DSPError(DSP_EMISC,
		     "DSPEnableMappedOnly: Cannot map host interface");
#endif
    s_mapped_only[s_idsp] = 1;
    return 0;
}

BRIEF int DSPDisableMappedOnly(void)
{
    CHECK_INIT;
    s_mapped_only[s_idsp] = 0;
    return(0);
}

BRIEF int DSPMappedOnlyIsEnabled(void)
{
    CHECK_INIT;
    return s_mapped_only[s_idsp];
}

/* Old "private" versions */
BRIEF int _DSPEnableMappedOnly(void) 	  { return DSPEnableMappedOnly();   }
BRIEF int _DSPDisableMappedOnly(void)	  { return DSPDisableMappedOnly();  }
BRIEF int _DSPMappedOnlyIsEnabled(void) { return DSPMappedOnlyIsEnabled();}

BRIEF int DSPIsMappedOnly(void)
{
    CHECK_INIT;
    return(s_mapped_only[s_idsp]); /* || DSP_IS_SIMULATED_ONLY); */
}

/* ----------------------------------------------------------------- */
/*
 * We no longer support mapped reads and/or writes for a port-based
 * DSP interface.
 */

BRIEF int _DSPEnableMappedArrayReads(void)
{
    return _DSPError(DSP_EPROTOCOL,"DSPEnableMappedArrayReads: "
		      "DSP is now either fully mapped or not");
}

BRIEF int _DSPDisableMappedArrayReads(void)
{
    return _DSPError(DSP_EPROTOCOL,"DSPDisableMappedArrayReads: "
		      "DSP is now either fully mapped or not");
}

BRIEF int _DSPEnableMappedArrayWrites(void)
{
    return _DSPError(DSP_EPROTOCOL,"DSPEnableMappedArrayWrites: "
		      "DSP is now either fully mapped or not");
}

BRIEF int _DSPDisableMappedArrayWrites(void)
{
    return _DSPError(DSP_EPROTOCOL,"DSPDisableMappedArrayWrites: "
		      "DSP is now either fully mapped or not");
}

BRIEF int _DSPEnableMappedArrayTransfers(void)
{
    return _DSPError(DSP_EPROTOCOL,"_DSPEnableMappedArrayTransfers: "
		     "DSP is now either fully mapped or not");
}

BRIEF int _DSPDisableMappedArrayTransfers(void)
{
    return _DSPError(DSP_EPROTOCOL,"_DSPDisableMappedArrayTransfers: "
		     "DSP is now either fully mapped or not");
}

/* ----------------------------------------------------------------- */

BRIEF int DSPEnableDmaReadWrite(int enable_dma_reads, int enable_dma_writes)
{
    CHECK_INIT;
    s_do_dma_array_reads[s_idsp] = enable_dma_reads;
    s_do_dma_array_writes[s_idsp] = enable_dma_writes;
    return 0;
}

BRIEF int DSPEnableMachMessageOptimization(void)
{
    CHECK_INIT;
    s_do_optimization[s_idsp]= 1;
    return 0;
}

BRIEF int DSPDisableMachMessageOptimization(void)
{
    CHECK_INIT;
    s_do_optimization[s_idsp]= 0;
    return 0;
}

BRIEF int DSPMKEnableWriteDataCleanup(void)
{
    CHECK_INIT;
    do_wd_cleanup = 1;
    return 0;
}

BRIEF int DSPMKDisableWriteDataCleanup(void)
{
    CHECK_INIT;
    do_wd_cleanup = 0;
    return 0;
}

BRIEF int DSPMKWriteDataCleanupIsEnabled(void)
{
    CHECK_INIT;
    return do_wd_cleanup;
}

/*
 * The simulator file is largely obsolete thanks to Bug56.
 * However, it still has value for debugging the Music Kit.
 * In effect, it provides a copious log of all DSP activity.
 */

FILE *DSPGetSimulatorFP(void)
{
    CHECK_INIT;
    return(s_simulator_fp[s_idsp]);
}

BRIEF int DSPSetSimulatorFP(FILE *fp)
{
    CHECK_INIT;
    s_simulator_fp[s_idsp] = fp;
    return 0;
}

BRIEF int DSPSetCommandsFD(int fd)
{
    CHECK_INIT;
    s_commands_fd[s_idsp] = fd;
    s_commands_fp[s_idsp] = NULL;
    return(0);
}

BRIEF int DSPSetCommandsFP(FILE *fp)
{
    CHECK_INIT;
    return DSPSetCommandsFD(fileno(s_commands_fp[s_idsp]=fp));
}

BRIEF int DSPGetCommandsFD(void)
{
    CHECK_INIT;
    return(s_commands_fd[s_idsp]);
}

FILE *DSPGetCommandsFP(void)
{
    CHECK_INIT;
    return(s_commands_fp[s_idsp]);
}

double DSPMKGetSamplingRate(void)
{
    CHECK_INIT;
    return(s_srate[s_idsp]);
}

BRIEF int DSPMKSetSamplingRate(double srate)
{
    CHECK_INIT;
    s_srate[s_idsp] = srate;
    
    if (srate == DSPMK_LOW_SAMPLING_RATE)
      s_low_srate[s_idsp] = 1;
    else {
	/* Assume user is running at some odd rate in DSP if not 44.1KHz */
	s_low_srate[s_idsp] = 0;
    }
    
    return 0;
}

/*************** Enable/Disable/Query for DSP state variables ****************/

BRIEF int DSPEnableHostMsg(void)
{
    CHECK_INIT;
    if (s_mapped_only[s_idsp])
      return _DSPError(DSP_EPROTOCOL,"DSPEnableHostMsg: "
		       "HostMessage mode not available in mapped mode");
    s_host_msg[s_idsp] = 1;
    return 0;
}

BRIEF int DSPDisableHostMsg(void)
{
    CHECK_INIT;
    s_host_msg[s_idsp] = 0;
    return 0;
}

BRIEF int DSPHostMsgIsEnabled(void)
{
    CHECK_INIT;
    return s_host_msg[s_idsp];
}

BRIEF int DSPMKEnableSoundOut(void)
{
    CHECK_INIT;
    if (s_mapped_only[s_idsp])
      return _DSPError(DSP_EPROTOCOL,"DSPEnableSoundOut: "
		       " not available in mapped mode");
    s_sound_out[s_idsp] = 1;
    return 0;
}

BRIEF int DSPMKDisableSoundOut(void)
{
    CHECK_INIT;
    s_sound_out[s_idsp] = 0;
    return 0;
}

BRIEF int DSPMKSoundOutIsEnabled(void)
{
    CHECK_INIT;
    return(s_sound_out[s_idsp]);
}

BRIEF int DSPMKEnableSSIReadData(void)
{
    CHECK_INIT;
    s_ssi_read_data[s_idsp] = 1;
    return 0;
}

BRIEF int DSPMKDisableSSIReadData(void)
{
    CHECK_INIT;
    s_ssi_read_data[s_idsp] = 0;
    return 0;
}

BRIEF int DSPMKSSIReadDataIsEnabled(void)
{
    CHECK_INIT;
    return(s_ssi_read_data[s_idsp]);
}

/*** FIXME: not supported yet by DSPOpenNoBoot() ***/
BRIEF int DSPMKEnableSSISoundOut(void)
{
    CHECK_INIT;
    s_ssi_sound_out[s_idsp] = 1;
    return 0;
}

BRIEF int DSPMKDisableSSISoundOut(void)
{
    CHECK_INIT;
    s_ssi_sound_out[s_idsp] = 0;
    return 0;
}

BRIEF int DSPMKSSISoundOutIsEnabled(void)
{
    CHECK_INIT;
    return(s_ssi_sound_out[s_idsp]);
}


BRIEF int DSPMKEnableWriteData(void)
{
    CHECK_INIT;
#if m68k /* Write data in mapped mode on Intel is ok */
    if (s_mapped_only[s_idsp])
      return _DSPError(DSP_EPROTOCOL,"DSPEnableWriteData: "
		       " not available in mapped mode");
#endif
    s_write_data[s_idsp] = 1;
    return 0;
}

BRIEF int DSPMKDisableWriteData(void)
{
    CHECK_INIT;
    s_write_data[s_idsp] = 0;
    return 0;
}

BRIEF int DSPMKWriteDataIsEnabled(void)
{
    CHECK_INIT;
    return(s_write_data[s_idsp]);
}

BRIEF int DSPMKWriteDataIsRunning(void)
{
    CHECK_INIT;
    return(s_write_data_running[s_idsp]);
}

BRIEF int DSPMKEnableReadData(void)
{
    CHECK_INIT;
    if (s_mapped_only[s_idsp])
      return _DSPError(DSP_EPROTOCOL,"DSPEnableReadData: "
		       " not available in mapped mode");
    s_read_data[s_idsp] = 1;
    return 0;
}

BRIEF int DSPMKDisableReadData(void)
{
    CHECK_INIT;
    s_read_data[s_idsp] = 0;
    return 0;
}

BRIEF int DSPMKReadDataIsEnabled(void)
{
    CHECK_INIT;
    return(s_read_data[s_idsp]);
}

BRIEF int DSPMKReadDataIsRunning(void)
{
    CHECK_INIT;
    return(s_read_data_running[s_idsp]);
}

BRIEF int DSPMKEnableSmallBuffers(void)
{
    CHECK_INIT;
    s_small_buffers[s_idsp] = 1;
    return 0;
}

BRIEF int DSPMKDisableSmallBuffers(void)
{
    CHECK_INIT;
    s_small_buffers[s_idsp] = 0;
    return 0;
}

BRIEF int DSPMKSmallBuffersIsEnabled(void)
{
    CHECK_INIT;
    return s_small_buffers[s_idsp];
}

BRIEF int DSPMKEnableTMFlush(void)
{
    CHECK_INIT;
    s_force_tmq_flush[s_idsp] = 1;
    return 0;
}

BRIEF int DSPMKDisableTMFlush(void)
{
    CHECK_INIT;
    s_force_tmq_flush[s_idsp] = 0;
    return 0;
}

BRIEF int DSPMKTMFlushIsEnabled(void)
{
    CHECK_INIT;
    return s_force_tmq_flush[s_idsp];
}

BRIEF int _DSPGetNumber(void)
{
    CHECK_INIT;
    return(s_idsp);
}

BRIEF int _DSPSetNumber(int i)
{
    CHECK_INIT;
    s_idsp = i;
    return 0;
}

BRIEF int _DSPOwnershipIsJoint()
{
    CHECK_INIT;
    return s_joint_owner[s_idsp];
}

/************ Getting/Setting Mach Ports associated with the DSP *************/

BRIEF int DSPSetNegotiationPort(mach_port_t np)
{
    CHECK_INIT;
    s_dsp_neg_port[s_idsp] = np;
    return 0;
}

mach_port_t DSPGetNegotiationPort(void)
{
    CHECK_INIT;
    return s_dsp_neg_port[s_idsp];
}

mach_port_t DSPMKGetSoundPort(void)
{
    CHECK_INIT;
    if (!s_open[s_idsp])
      return _DSPError(DSP_EMISC, "DSPGetSoundPort: Attempt to access port "
		       "before its creation");
    return s_sound_dev_port[s_idsp];
}

mach_port_t DSPGetSoundPort(void)
{
    CHECK_INIT;
    return DSPMKGetSoundPort();
}

mach_port_t DSPGetOwnerPort(void)
{
    CHECK_INIT;
    if (!s_open[s_idsp])
      return _DSPError(DSP_EMISC, "DSPGetOwnerPort: Attempt to access port "
		       "before its creation");
    return s_dsp_owner_port[s_idsp];
}

mach_port_t DSPGetHostMessagePort(void)
{
    CHECK_INIT;
    if (!s_open[s_idsp])
      return _DSPError(DSP_EMISC, "DSPGetHostMessagePort: "
		       "Attempt to access port before its creation");
    return s_dsp_hm_port[s_idsp];
}

mach_port_t DSPGetDSPMessagePort(void)
{
    CHECK_INIT;
    if (!s_open[s_idsp])
      return _DSPError(DSP_EMISC, "DSPGetDSPMessagePort: "
		       "Attempt to access port before its creation");
    return s_dsp_dm_port[s_idsp];
}

mach_port_t DSPGetErrorPort(void)
{
    CHECK_INIT;
    if (!s_open[s_idsp])
      return _DSPError(DSP_EMISC, "DSPGetErrorPort: Attempt to access port "
		       "before its creation");
    return s_dsp_err_port[s_idsp];
}

mach_port_t DSPMKGetWriteDataStreamPort(void)
{
    CHECK_INIT;
    if (!s_open[s_idsp])
      return _DSPError(DSP_EMISC, "DSPMKGetWriteDataStreamPort: "
		       "Attempt to access port "
		       "before its creation");
    return s_wd_stream_port[s_idsp];
}

mach_port_t DSPMKGetReadDataStreamPort(void)
{
    CHECK_INIT;
    if (!s_open[s_idsp])
      return _DSPError(DSP_EMISC, "DSPMKGetReadDataStreamPort: "
		       "Attempt to access port "
		       "before its creation");
    return s_rd_stream_port[s_idsp];
}

mach_port_t DSPMKGetWriteDataReplyPort(void)
{
    CHECK_INIT;
    if (!s_open[s_idsp])
      return _DSPError(DSP_EMISC, "DSPMKGetWriteDataReplyPort: "
		       "Attempt to access port "
		       "before its creation");
    return s_wd_reply_port[s_idsp];
}

mach_port_t DSPMKGetReadDataReplyPort(void)
{
    CHECK_INIT;
    if (!s_open[s_idsp])
      return _DSPError(DSP_EMISC, "DSPMKGetReadDataReplyPort: Attempt to access port before its creation");
    return s_rd_reply_port[s_idsp];
}

/****************** Getting and setting DSP system files *********************/

const char *DSPGetDSPDirectory(void)
{
    NSString *dspdir;
    char *dspdirenv;
    //    struct stat sbuf;
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDir;

    CHECK_INIT;
    dspdirenv = getenv("DSP"); // LMS FIXME: getenv should be replaced with access from NSUserDefaults
    dspdir = (dspdirenv == NULL) ? 
	    DSP_SYSTEM_DIRECTORY :
		[manager stringWithFileSystemRepresentation:dspdirenv length:strlen(dspdirenv)];
    // here is the potential to do path grooming appropriate to the Operating system.
//    if(stat(dspdir,&sbuf)) LMS
    if([manager fileExistsAtPath: dspdir isDirectory: &isDir] != YES || !isDir) {
      [dspdir release];
      dspdir = DSP_FALLBACK_SYSTEM_DIRECTORY;
    }
    return [dspdir fileSystemRepresentation];
}

char *DSPGetImgDirectory(void) 
{
    char *dspimgdir;
    CHECK_INIT;
    dspimgdir = DSPGetDSPDirectory();
    dspimgdir = DSPCat(dspimgdir,"/img/"); 
    return dspimgdir;
}	

char *DSPGetAPDirectory(void) 
{
    char *dspimgdir;
    CHECK_INIT;
    dspimgdir = DSPGetDSPDirectory();
    dspimgdir = DSPCat(dspimgdir,DSP_AP_BIN_DIRECTORY);
    return dspimgdir;
}	

char *DSPGetSystemDirectory(void) 
{
    char *sysdir;
    CHECK_INIT;
    sysdir = DSPGetDSPDirectory();
    sysdir = DSPCat(sysdir,"/monitor/");
    return sysdir;
}

char *DSPGetLocalBinDirectory(void) 
{
    char *lbdir;
    char *dspdir;
    CHECK_INIT;
    dspdir = getenv("DSP");
    if (dspdir == NULL)
      lbdir = DSP_BIN_DIRECTORY; /* revert to installed binary */
    else
      lbdir = DSPCat(dspdir,"/bin/");
    return lbdir;
}

DSPLoadSpec *DSPGetSystemImage(void)
{
    CHECK_INIT;
    return s_systemImage[s_idsp];
}

static void s_initMessageArrays(void); /* defined later and used below */

static int setSystemAux(DSPLoadSpec *system,int firstTime) {
    CHECK_INIT;
    s_systemImage[s_idsp] = system;
    s_ap_system[s_idsp] = 0;
    s_mk_system[s_idsp] = 0;
    s_system_link_file[s_idsp] = NULL;
    s_system_binary_file[s_idsp] = NULL;
    if (system->module) {
	if (strncmp(system->module,"MKMON",5)==0) {
	    s_ap_system[s_idsp] = 0;
	    s_mk_system[s_idsp] = 1;
	    s_system_link_file[s_idsp]   = DSP_MUSIC_SYSTEM_0; /* _dsp.h */
	    s_system_binary_file[s_idsp] = DSP_MUSIC_SYSTEM_BINARY_0;
	} else if (strncmp(system->module,"APMON",5)==0) {
	    s_ap_system[s_idsp] = 1;
	    s_mk_system[s_idsp] = 0;
	    s_system_link_file[s_idsp]   = DSP_AP_SYSTEM_0; /* _dsp.h */
	    s_system_binary_file[s_idsp] = DSP_AP_SYSTEM_BINARY_0;
	}		
    }		

    if (firstTime) {
      DSPSetCurrentSymbolTable(s_idsp); /* Get rid of old one */
      DSPFreeSymbolTable();
    }
    if (s_ap_system[s_idsp] || s_mk_system[s_idsp]) {
        if (firstTime)
	  s_clearCachedDSPSymbols(); 
	s_cacheDSPSymbols();
	s_initMessageArrays(); /* allocate TMQ array and hm_array */
    }
    return 0;
}

int DSPSetSystem(DSPLoadSpec *system)
{
    return setSystemAux(system,1);
}	

int _DSPResetSystem(DSPLoadSpec *system)
{
    return setSystemAux(system,0);
}	

BRIEF int DSPMonitorIsAP(void)
{
    CHECK_INIT;
    return s_ap_system[s_idsp];
}

BRIEF int DSPMonitorIsMK(void)
{
    CHECK_INIT;
    return s_mk_system[s_idsp];
}

char *DSPGetSystemBinaryFile(void) 
{
    char *dspdir = DSPGetSystemDirectory(); /* _dsp.h */
    CHECK_INIT;
    return DSPCat(dspdir,s_system_binary_file[s_idsp]);
}

char *DSPGetSystemLinkFile(void)
{
    char *dspdir = DSPGetSystemDirectory(); /* _dsp.h */
    CHECK_INIT;
    return DSPCat(dspdir,s_system_link_file[s_idsp]);
    return 0;
}

char *DSPGetSystemMapFile(void)
{
    return "Map files are no longer used";
}

BRIEF int DSPSetAPSystemFiles(void)
{
    CHECK_INIT;
    s_system_link_file[s_idsp]	 = DSP_AP_SYSTEM_0; /* _dsp.h */
    s_system_binary_file[s_idsp] = DSP_AP_SYSTEM_BINARY_0;
    s_ap_system[s_idsp] = 1;
    s_mk_system[s_idsp] = 0;
    return 0;
}

BRIEF int DSPSetMKSystemFiles(void)
{
    CHECK_INIT;
    s_system_link_file[s_idsp]	 = DSP_MUSIC_SYSTEM_0; /* dsp.h */
    s_system_binary_file[s_idsp] = DSP_MUSIC_SYSTEM_BINARY_0;
    s_ap_system[s_idsp] = 0;
    s_mk_system[s_idsp] = 1;
    return 0;
}

/***************************** Small Utilities ****************************/

BRIEF int DSPMKEnableBlockingOnTMQEmptyTimed(DSPFix48 *aTimeStampP)
{
    CHECK_INIT;
    return DSPMKHostMessageTimed(aTimeStampP,dsp_hm_block_tmq_lwm[s_idsp]);
}

BRIEF int DSPMKDisableBlockingOnTMQEmptyTimed(DSPFix48 *aTimeStampP)
/* 
 * Tell the DSP not to block when the Timed Message Queue reaches its
 * "low-water mark."
 */
{
    CHECK_INIT;
    return DSPMKHostMessageTimed(aTimeStampP,dsp_hm_unblock_tmq_lwm[s_idsp]);
}

static int s_allocPort(mach_port_t *portP)
/* 
 * Allocate Mach port.
 */
{
    int ec;
    ec = port_allocate(task_self(), portP);
    if (ec != KERN_SUCCESS)
      return _DSPMachError(ec,"DSPObject.c: port_allocate failed.");
    else 
      return 0;
}

static int s_freePort(mach_port_t *portP)
/* 
 * Deallocate Mach port.
 */
{
    int ec;
    
    if (!portP)
      return 0;
    
    if (*portP) {
	ec = port_deallocate(task_self(), *portP);
	if (ec != KERN_SUCCESS)
	  return _DSPMachError(ec,"s_freePort: port_deallocate failed.");
	*portP	= 0;
    }
    return 0;
}


int DSPAwakenDriver(void)
/* 
 * Send empty message to DSP to wake up driver. 
 */
{
#if m68k 
    static msg_header_t *dspcmd_msg = 0;
    if (s_mapped_only[s_idsp] == 0)
      return 0;
    CHECK_INIT;

    if (!dspcmd_msg)
      dspcmd_msg = _DSP_dspcmd_msg(s_dsp_hm_port[s_idsp],
				   s_dsp_dm_port[s_idsp],
				   DSP_MSG_HIGH,0);
    else
      _DSP_dspcmd_msg_reset(dspcmd_msg,
			    s_dsp_hm_port[s_idsp],
			    s_dsp_dm_port[s_idsp],
			    DSP_MSG_HIGH,0);
    /* fprintf(stderr,"*** Faking DSPAwakenDriver() to find memory leak\n"); */
    ec = msg_send(dspcmd_msg, MSG_OPTION_NONE,0);
    return ec;
#else /* No need to awaken driver on Intel */
    return KERN_SUCCESS;
#endif
}


/***************************** WriteData Handling ****************************/

BRIEF int DSPMKGetWriteDataSampleCount(void)
{
    return s_wd_sample_count[s_idsp];
}

BRIEF int DSPMKGetWriteDataTimeOut(void)
{
    CHECK_INIT;
    return s_wd_timeout[s_idsp];
}

BRIEF int DSPMKSetWriteDataTimeOut(int to)
{
    CHECK_INIT;
    s_wd_timeout[s_idsp] = to;
    return 0;
}

/* 
 * The file pointer should no longer be used.  It is kept around
 * for 1.0 compatibility.  File pointers are not thread safe.
 */

BRIEF int DSPMKSetWriteDataFD(int fd)
{
    CHECK_INIT;
    s_wd_fd [s_idsp]= fd;
    s_wd_fp[s_idsp] = NULL;
    s_wd_fn[s_idsp] = 0;
    return 0;
}

BRIEF int DSPMKSetWriteDataFP(FILE *fp)
{
    CHECK_INIT;
    return DSPMKSetWriteDataFD(fileno(s_wd_fp[s_idsp]=fp));
}

BRIEF int DSPMKGetWriteDataFD(void)
{
    CHECK_INIT;
    return s_wd_fd[s_idsp];
}

BRIEF FILE *DSPMKGetWriteDataFP(void)
{
    return s_wd_fp[s_idsp];
}

BRIEF int DSPMKSetWriteDataFile(const char *fn)
{
    CHECK_INIT;
    s_wd_fn[s_idsp] = fn;
    s_wd_fd [s_idsp]= -1;
    s_wd_fp[s_idsp] = NULL;
    return 0;
}

BRIEF char *DSPMKGetWriteDataFile(void)
{
    CHECK_INIT;
    return s_wd_fn[s_idsp];
}

BRIEF int DSPMKCloseWriteDataFile(void)
{
    CHECK_INIT;
    if (s_write_data_running[s_idsp])
      DSPMKStopWriteData();
    if (s_wd_fd [s_idsp]>= 0)
      close(s_wd_fd[s_idsp]);
    s_wd_fd [s_idsp]= -1;
    s_wd_fp[s_idsp] = NULL;
    return 0;
}

BRIEF int DSPMKRewindWriteData(void) 
{
    if (s_wd_fd[s_idsp]>=0)
      lseek(s_wd_fd[s_idsp],0,SEEK_SET);
    return 0;
}

BRIEF int DSPMKStopWriteDataTimed(DSPTimeStamp *aTimeStampP)
{
    int ec=0;
    int chan = DSPMK_WD_DSP_CHAN; /* Sound-out is DSP DMA channel 1 */
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(s_simulator_fp[s_idsp],
	      ";; Disable write data from DSP to host\n");
#endif SIMULATOR_POSSIBLE
    
    /* It's ok if DSPMK*StopSoundOut*() does this redundantly */
    DSP_UNTIL_ERROR(DSPMKCallTimed(aTimeStampP,dsp_hm_host_wd_off[s_idsp],
				   1,&chan));
    ec = DSPMKEnableBlockingOnTMQEmptyTimed(aTimeStampP);
    return ec;
}

BRIEF int 
  DSPMKSetUserWriteDataFunc(DSPMKWriteDataUserFunc userFunc)
/* See DSPObject.h for documentation */
{
    CHECK_INIT;
    s_wd_user_func[s_idsp] = userFunc;
    return 0;
}

static void s_finish_msg_reader(void)
{
    if (s_dsp_msg_thread[s_idsp]) {
	s_stop_msg_reader[s_idsp] = 1;
	cthread_join(s_dsp_msg_thread[s_idsp]);
	s_dsp_msg_thread[s_idsp] = 0;
    } /* else thread was never started */
}


static void s_finish_error_reader(void)
{
    if (s_dsp_err_thread[s_idsp]) {
	cthread_join(s_dsp_err_thread[s_idsp]);
	s_dsp_err_thread[s_idsp] = 0;
#if !m68k && (defined(NeXT) || (defined(__APPLE__) && defined(__MACH__)))
	dsp_setErrorPort(s_idsp,PORT_NULL);
#endif
    } /* else thread was never started */
}

static int s_finish_wd()
{
    /* 
     * Halt write-data thread 
     */
    if (s_write_data_running[s_idsp]) {
	s_stop_write_data[s_idsp] = 1;
	cthread_join(s_wd_thread[s_idsp]);
#if i386 && defined(NeXT)
	/* Just tell driver to drop data on the floor */
	dsp_setShortBigEndianReturn(s_idsp, 0,dsp_nb_dma_w[s_idsp]>>1,
				    PORT_NULL,DSPMK_WD_DSP_CHAN);
#endif
	s_wd_thread[s_idsp] = 0;
    } /* else thread is already dead */

    if (s_wd_error[s_idsp] != 0)
      _DSPMachError(ec,DSPCat("DSPObject.c: s_finish_wd: error in reader thread: ", s_wd_error_str[s_idsp]));
    s_wd_error[s_idsp] = 0;
    s_wd_error_str[s_idsp] = 0;

#if m68k /* Intel driver doesn't count samples */
    if (do_wd_cleanup) {	/* conditional due to bugs */
	int ndata;

	/*
	 * *** ALL DONE RECORDING WRITE DATA ***
	 * Find out how many samples were recorded.
	 */
	ec = snddriver_stream_nsamples(s_wd_stream_port[s_idsp], &ndata);
	if (ec != KERN_SUCCESS)
	  _DSPMachError(ec,"DSPObject.c: s_finish_wd: "
			"snd_stream_nsamples failed");
	ndata >>= 1;
	if (_DSPVerbose)
	  fprintf(stderr,"\nTotal length = %d bytes (%d samples)\n",
		  (ndata<<1), ndata);
	
	if ((ndata) != s_wd_sample_count[s_idsp]) {
	    _DSPError1(0,"DSPObject.c: s_finish_wd: "
		       "I count total number of samples = %s",
		       _DSPCVS(s_wd_sample_count[s_idsp]));
	    _DSPError1(0,"... while the driver counts %s",
		       _DSPCVS(ndata));
	}
    }
#endif 
    
    /* 
     * Rewrite header to disk to get byte-count right, 
     * then close the write-data file. 
     */
    if (s_wd_header[s_idsp]) {
	lseek(s_wd_fd[s_idsp],0,SEEK_SET);
	s_wd_header[s_idsp]->dataSize = 
	  NSSwapHostIntToBig(s_wd_sample_count[s_idsp] * sizeof(short));
	write(s_wd_fd[s_idsp],(char *)s_wd_header[s_idsp], 
	      sizeof *s_wd_header[s_idsp]); 
	if (do_wd_cleanup)
	/*
	 * *** FIXME: The following triggers a malloc_debug(7) complaint 
	 * (attempt to free something already freed) in the next fclose call:
	 *
	 * 	SNDFree(s_rd_header[s_idsp]); 
	 */
	  s_rd_header[s_idsp] = 0;
    }
    
    if (s_wd_fd[s_idsp]>= 0 && s_wd_fn[s_idsp]) {  
	/* Can't close FD which was passed to us */
	close(s_wd_fd[s_idsp]); 
	s_wd_fd[s_idsp]= -1;
	if (_DSPVerbose)
	  _DSPError1(0,"Closed write-data output file %s.",s_wd_fn[s_idsp]);
    }
    
    s_write_data_running[s_idsp] = 0;	/* Already done on wd thread exit  */

    return 0;
}

int DSPMKStopWriteData(void) 
{
    int ec;
    int chan = DSPMK_WD_DSP_CHAN; /* Sound-out is DSP DMA channel 1 */
    CHECK_INIT;
    /* It's ok if DSPMKStopSoundOut() does this redundantly */
    DSP_UNTIL_ERROR(DSPCall(dsp_hm_host_wd_off[s_idsp],1,&chan));
    DSPMKDisableBlockingOnTMQEmptyTimed(NULL);
    ec=DSPHostMessage(dsp_hm_host_r_done[s_idsp]); /* in case DMA running */

    s_finish_wd();
    
    return ec;
}

static int s_enqueue_record_region(void)
{
    static int tag=0;

#if i386 && defined(NeXT)
/* DAJ 11/20/95 */
    /* Unlike in the case of black hardware, we pass the number of words we are expecting
     * in ==each== buffer.  We will not get the data back until a whole page is received.
     */
    dsp_setShortBigEndianReturn(s_idsp, 
				tag++,
				dsp_nb_dma_w[s_idsp]>>1,
				s_wd_reply_port[s_idsp],
				DSPMK_WD_DSP_CHAN);
#elif m68k
    int ec;
    ec = snddriver_stream_start_reading(s_wd_stream_port[s_idsp],NULL,
    	/* no. samples to read */ (s_dsp_record_buf_bytes[s_idsp]>>1),
	tag++,0, /* completed */ 1, /* aborted */ 1, 0,0,0,
					s_wd_reply_port[s_idsp]);
    if (ec != KERN_SUCCESS)
      return _DSPMachError(ec,"s_enqueue_record_region: "
		  "snddriver_stream_start_reading for write-data failed");
#endif

    return 0;
}

#if m68k
static int wd_region = 0;
#endif

int DSPMKStartWriteDataTimed(DSPTimeStamp *aTimeStampP)
{
    int chan = DSPMK_WD_DSP_CHAN; /* DSP write-data and sound-out channel=1 */
    /* Note that this is NOT DSP_SO_CHAN,
       but rather a DMA channel no. IN THE DSP */
    CHECK_INIT;
    if(!s_write_data[s_idsp])
      return _DSPError(DSP_EMISC,"DSPMKStartWriteData:write data not enabled");
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(s_simulator_fp[s_idsp], ";; Enable write data from DSP to host\n");
#endif SIMULATOR_POSSIBLE
    /* It's ok if DSPMKStartSoundOut() does this redundantly */

    /* 
     * Tell the DSP to block when the Timed Message Queue reaches its
     * "low-water mark."
     */
    DSPMKEnableBlockingOnTMQEmptyTimed(aTimeStampP);

    DSP_UNTIL_ERROR(DSPMKCallTimed(aTimeStampP
				   ,dsp_hm_host_wd_on[s_idsp],
				   1,&chan));
    s_stop_write_data[s_idsp] = 0; /* watched by s_wd_reader() */

    if (!s_wd_user_func[s_idsp]) 
      if (!s_wd_fn[s_idsp] && s_wd_fd[s_idsp]< 0)
	s_wd_fn[s_idsp] = "dsp_write_data.raw";
	
    /* if file pointer is null, use file name, if any */
    if (s_wd_fd[s_idsp]< 0 && s_wd_fn[s_idsp]) {
	/* Get header to use for the write-data output sound file */
	ec = SndAlloc(&s_wd_header[s_idsp],
		      0 /* data size (we'll have to fix this later) */,
		      SND_FORMAT_LINEAR_16 /* 3 */,
		      s_low_srate[s_idsp]? 
		      SND_RATE_LOW /* 22050.0 */ : 
		      SND_RATE_HIGH /* 44100.0 */,
		      2 /* chans */,
		      104 /* info string space to allocate (for 128 bytes) */
		      );
	if (ec)
	  _DSPError(DSP_EMISC, 
		    "DSPMKStartWriteData: SndAlloc for header failed");
	s_wd_header[s_idsp]->dataSize = 2000000000; /* 2 gigabyte limit! */
	/* Swap it all (in case we're on a little-endian machine) */
	s_wd_header[s_idsp]->magic = 
	  NSSwapHostIntToBig(s_wd_header[s_idsp]->magic);
	s_wd_header[s_idsp]->dataLocation = 
	  NSSwapHostIntToBig(s_wd_header[s_idsp]->dataLocation);
	s_wd_header[s_idsp]->dataFormat = 
	  NSSwapHostIntToBig(s_wd_header[s_idsp]->dataFormat);
	s_wd_header[s_idsp]->samplingRate = 
	  NSSwapHostIntToBig(s_wd_header[s_idsp]->samplingRate);
	s_wd_header[s_idsp]->channelCount = 
	  NSSwapHostIntToBig(s_wd_header[s_idsp]->channelCount);
	s_wd_header[s_idsp]->dataSize = 
	  NSSwapHostIntToBig(s_wd_header[s_idsp]->dataSize);
	strcpy( s_wd_header[s_idsp]->info,
	       "DSP write data written by Music Kit performance");
	s_wd_fd[s_idsp]= open(s_wd_fn[s_idsp],O_CREAT|O_WRONLY|O_TRUNC,0666);
	if (_DSPVerbose)
	  fprintf(stderr,"Opened write-data output file %s\n",s_wd_fn[s_idsp]);
	if (s_wd_fd[s_idsp]< 0)
	  return _DSPError1(DSP_EUNIX,"DSPMKStartWriteDataTimed: "
			    "Could not open write-data output file %s ",
			    s_wd_fn[s_idsp]);
	
	/* write header to disk */
	write(s_wd_fd[s_idsp],(char *)s_wd_header[s_idsp], 
	      sizeof *s_wd_header[s_idsp]); 
    }
    s_write_data_running[s_idsp] = 1;
    s_freePort(&s_wd_reply_port[s_idsp]);
    if (ec=s_allocPort(&s_wd_reply_port[s_idsp])) return ec;

    /* For many DSPs, the machine would crash.  I believe this
     * is because it runs out of VM.   Apparently, vm_allocate()
     * doesn't return an error code--it just crashes the system.
     * (I'm not sure about that, but it's a conjecture.)
     * Anyway, by setting the port backlog to 1 we ensure that
     * only one vm buffers will be allocated per DSP.
     */
//    port_set_backlog(task_self(), s_wd_reply_port[s_idsp], 1);
    
    /* Set s_wd_rmsg */
    s_wd_rmsg[s_idsp] = _DSP_STREAM_MSG(s_wd_rmsg[s_idsp],s_wd_stream_port[s_idsp],
				thread_reply(),1,DSPMK_WD_DSP_CHAN,
				DSPDRIVER_MSG_READ_BIG_ENDIAN_SHORT_COMPLETED);

    DSP_UNTIL_ERROR(s_enqueue_record_region());		/* region 1 */
#if m68k
    DSP_UNTIL_ERROR(s_enqueue_record_region());		/* region 2 */
#endif
    
#if TRACE_POSSIBLE
    if (_DSPTrace && DSP_TRACE_WRITE_DATA)
      fprintf(stderr,"Entering write-data loop:\n");
#endif TRACE_POSSIBLE
    
    if (s_no_thread[s_idsp])
      s_wd_reader(s_idsp);
    else {
      s_wd_thread[s_idsp] = cthread_fork((cthread_fn_t) s_wd_reader,(void *)s_idsp);
      cthread_yield();	/* Allow write-data thread to get going */
    }
    return 0;
}


BRIEF int DSPMKStartWriteData(void) 
{
    return DSPMKStartWriteDataTimed(DSPMK_UNTIMED);
}


BRIEF int _DSPMKStartWriteDataNoThread(void) 
{
    CHECK_INIT;
    s_no_thread[s_idsp] = 1;
    return DSPMKStartWriteDataTimed(DSPMK_UNTIMED);
}

BRIEF int DSPBailingOut(int dspNum)
    /* Can't use s_idsp here because we want to be thread-safe */
{
    return s_bail_out[dspNum];
}

static int s_wd_reader(int myDSP)
/*
 * function which runs in its own thread reading write-data buffers from
 * the DSP. 
 */
{
    int ndata,ec;
    int stopping=0;
    /* timeout subdivision vars */
    int timeout=500;		/* timeout we really use in ms */
    int timeout_so_far=0;	/* total timeout used so far */
    msg_header_t *wd_rmsg = s_wd_rmsg[myDSP];
    if (timeout > s_wd_timeout[myDSP])	/* take min */
      timeout = s_wd_timeout[myDSP];	/* do not exceed user-req'd timeout */
    while (1) {
	short int *data;
	
	/*
	 *
	 */
	wd_rmsg->msg_size = _DSP_DATA_MSG_SIZE;
	wd_rmsg->msg_local_port = s_wd_reply_port[myDSP];
	
	ec = msg_receive(wd_rmsg, RCV_TIMEOUT, timeout);
	
	/*
	 * NOTE: stdio cannot be used in multiple threads!
	 */

	if (ec != KERN_SUCCESS && ec != RCV_TIMED_OUT) {
	    s_wd_error[myDSP] = ec;
	    s_wd_error_str[myDSP] = "msg_receive 1 failed";
	}

	if (ec == RCV_TIMED_OUT) {
	    if (s_stop_write_data[myDSP])
	      goto abort_wd;
	    if (s_frozen[myDSP])
	      continue;		/* keep trying to read DSP buffer */
	    if (_DSPVerbose)
	      fprintf(stderr,"\ns_wd_reader: "
		      "data msg_receive timeout\n");
	    timeout_so_far += timeout;
	    if (timeout_so_far<s_wd_timeout[myDSP]) {
		DSPAwakenDriver();
		continue;	/* retry buffer read from DSP */
	    }
	    else {
		s_wd_error[myDSP] = ec;
		s_wd_error_str[myDSP] = "Timed out waiting for "
		  "write-data buffer.";
		s_bail_out[myDSP] = 1;
	        break;		/* exit write-data thread */
	    }
	}
	else
	  timeout_so_far = 0;	/* reset cumulated timeout */

	/* The following should never happen on Intel (or maybe even on m68k?)-DAJ */
	if (wd_rmsg->msg_id != SND_MSG_RECORDED_DATA) {
	    s_wd_error[myDSP] = ec;
	    s_wd_error_str[myDSP] = "Unexpected msg while expecting "
	      "SND_MSG_RECORDED_DATA. "
		"See snd_msgs.h(SND_MSG_*)";
	    /* Unexpected msg = _DSPCVS(wd_rmsg->msg_id)); */
	    continue;
	}
	
	/* 
	 * Here we have a buffer of write-data to send to disk.
	 */
	
	data = (short int *)_DSP_DATA_MSG_DATA(wd_rmsg);
	ndata = _DSP_DATA_MSG_COUNT(wd_rmsg);

	ndata >>= 1;
	s_wd_sample_count[myDSP] += ndata; /* Total number of words written */
	
	if (_DSPVerbose)
	  fprintf(stderr,"%d ",s_wd_sample_count[myDSP]);

#if TRACE_POSSIBLE
	if (_DSPTrace)
	  fprintf(stderr,"received msgid %d, %d samples\n", wd_rmsg->msg_id, 
		  ndata);
#endif TRACE_POSSIBLE
	
	if (s_wd_fd[myDSP]>=0)
	  write(s_wd_fd[myDSP],(char *)data, ndata*2); /* write to disk */
	if (s_wd_user_func[myDSP])
	  (*(s_wd_user_func[myDSP]))(data,  /* Data */
				     ndata,         /* Number of words */
				     myDSP);        /* DSP number */

#if TRACE_POSSIBLE
    	if (_DSPTrace && DSP_TRACE_WRITE_DATA)
      	   fprintf(stderr,"Region received and written.\n");
#endif TRACE_POSSIBLE

	/* 
	 * Deallocate the write-data buffer.
	 */

	ec = vm_deallocate(task_self(),
			   _DSP_DATA_MSG_DATA(wd_rmsg),
			   _DSP_DATA_MSG_DATA_SIZE(wd_rmsg));
	
	if (ec != KERN_SUCCESS) {
	    s_wd_error[myDSP] = ec;
	    s_wd_error_str[myDSP] =  "write-data buffer deallocate failed";
	}

#define KEEP_OWN_VM_POOL 1 /* Must match driver value */

#if (i386 && defined(NeXT) && KEEP_OWN_VM_POOL)
	/* 
	 * Note that we still vm_deallocate from *our* address space, even though
	 * the driver doesn't vm_deallocate it from *its* address space.
	 */
	dsp_freePage(myDSP,((DSPDRIVERDataMessage *)wd_rmsg)->pageIndex);
#endif
	/* 
	 * Terminate if so requested.
	 */
  abort_wd:			/* placement here catches abort timeout too */
	if (stopping)
	  break;           /* We just wrote out the last (partial) buffer */

	if (!s_open[myDSP]) {
	    if (_DSPVerbose)
	      fprintf(stderr,"\ns_wd_reader: terminating on DSP closed\n");
	    s_stop_write_data[myDSP] = 1;
	}
	
	if (s_stop_write_data[myDSP]) {
	    if (_DSPVerbose)
	      fprintf(stderr,"\ns_wd_reader: "
		      "terminating on s_stop_write_data[myDSP]\n");
#if m68k
	    ec = snddriver_stream_control(s_wd_stream_port[myDSP],
					  0,SND_DC_ABORT);
	    if (ec != KERN_SUCCESS) {
		s_wd_error[myDSP] = ec;
		s_wd_error_str[myDSP] = "snddriver_stream_control(abort) "
		  "failed";
	    }
#endif
    	    stopping = 1;
	    continue;
	}
	
	/* 
	 * Send a request to record the next buffer.
	 * No need to do this for Intel driver.
	 */
#if m68k
#if TRACE_POSSIBLE
    	if (_DSPTrace && DSP_TRACE_WRITE_DATA)
      	   fprintf(stderr,"Enqueing region %d.\n",++wd_region);
#endif TRACE_POSSIBLE
	if (s_enqueue_record_region()) {
#if TRACE_POSSIBLE
    	  if (_DSPTrace && DSP_TRACE_WRITE_DATA)
      	    fprintf(stderr,"Enqueing of region %d FAILED. "
	    		   "Aborting wd reader.\n",wd_region);
#endif TRACE_POSSIBLE
	  break;
	}
#endif
    }
    
    s_write_data_running[myDSP] = 0;

    return 0;
}


/***************************** ReadData Handling ****************************/

BRIEF int DSPMKGetReadDataSampleCount(void)
{
    int ndata;
    if (!s_read_data_running[s_idsp])
      return s_rd_sample_count[s_idsp];
      
    ec = snddriver_stream_nsamples(s_rd_stream_port[s_idsp], &ndata);
    if (ec != KERN_SUCCESS)
      return _DSPMachError(ec,"DSPMKGetReadDataSampleCount: "
			   "snddriver_stream_nsamples failed");
	
    ndata >>= 1;
	
    s_rd_sample_count[s_idsp] = ndata;
    
    return s_rd_sample_count[s_idsp];
}

/* Flushed from documented API */
BRIEF int DSPMKGetReadDataFD(void)
{
    CHECK_INIT;
    return s_rd_fd[s_idsp];
}

BRIEF int DSPMKSetReadDataBytePointer(int offset)
{
    CHECK_INIT;
    return lseek(s_rd_fd[s_idsp],offset,SEEK_SET);
}

BRIEF int DSPMKIncrementReadDataBytePointer(int offset)
{
    CHECK_INIT;
    return lseek(s_rd_fd[s_idsp],offset,SEEK_CUR);
}

BRIEF int DSPSetTimedZeroNoFlush(int yesOrNo)
{
    s_timed_zero_noflush[s_idsp] = yesOrNo;
    return 0;
}

BRIEF int DSPMKSetReadDataFile(const char *fn)
{
    CHECK_INIT;
    s_rd_fn[s_idsp] = fn;

    if (!s_rd_fn[s_idsp])
      return _DSPError(DSP_EBADFILETYPE,
		       "DSPMKSetReadDataFile: NULL read-data filename");
    
    s_rd_fd[s_idsp] = open(s_rd_fn[s_idsp],O_RDONLY,0666);
    
    if (s_rd_fd[s_idsp] < 0)
      return 
	_DSPError1(DSP_EUNIX,"DSPMKSetReadDataFile: "
		   "Could not open read-data output file %s",s_rd_fn[s_idsp]);
    
    if (_DSPVerbose)
      fprintf(stderr,"Opened read-data input file %s\n",s_rd_fn[s_idsp]);
    
    /* read header */
    
    if (ec=SndReadHeader(s_rd_fd[s_idsp],&s_rd_header[s_idsp]))
      return 
	_DSPMachError(ec,DSPCat("DSPMKSetReadDataFile: "
				 "Failed reading header of read-data file. "
				 "sound library error: ",SndSoundError(ec)));
    
#define RD(x) s_rd_header[s_idsp]->x
    
    if (RD(dataFormat) != SND_FORMAT_LINEAR_16)
      return 
	_DSPError(DSP_EBADFILEFORMAT,"DSPMKSetReadDataFile: "
		   "Read-data file must be 16-bit linear format");
    
    s_rd_chans[s_idsp] = RD(channelCount);
    
    return 0;
}

int DSPMKRewindReadData(void) 
{
    int ec;
    if (s_rd_fd[s_idsp] >= 0)
      lseek(s_rd_fd[s_idsp],0,SEEK_SET);
    else
      return _DSPError(DSP_EMISC,
		       "Attempt to rewind non-existent read-data stream");
    /* move ptr past header: */
    ec = SndReadHeader(s_rd_fd[s_idsp],&s_rd_header[s_idsp]); 
    if (ec == SND_ERR_NONE)
      return 0;
    else
      return
	_DSPError(DSP_EMISC,
		  "Could not read header after rewinding read-data stream");
}

BRIEF int DSPMKPauseReadDataTimed(DSPTimeStamp *aTimeStampP) 
{
    int chan = DSPMK_RD_DSP_CHAN;
    CHECK_INIT;
    return DSPMKCallTimed(aTimeStampP,dsp_hm_host_rd_off[s_idsp],1,&chan);
}

BRIEF int DSPMKResumeReadDataTimed(DSPTimeStamp *aTimeStampP) 
{
    int chan = DSPMK_RD_DSP_CHAN;
    CHECK_INIT;
    return DSPMKCallTimed(aTimeStampP,dsp_hm_host_rd_on[s_idsp],1,&chan);
}

static int s_finish_rd(void)
{
    int ndata;

    /* 
     * Halt read-data thread 
     */
    if (s_read_data_running[s_idsp]) {
	s_stop_read_data[s_idsp] = 1;
	cthread_join(s_rd_thread[s_idsp]);
    } /* else thread is already dead */

    if (s_rd_error != 0)
      _DSPMachError(ec,DSPCat("DSPObject.c: s_finish_rd: "
			      "error in writer thread: ",
			       s_rd_error_str[s_idsp]));
    s_rd_error = 0;
    s_rd_error_str[s_idsp] = 0;

    /*
     * *** ALL DONE RECORDING READ DATA ***
     * Find out how many samples were recorded.
     */
    ec = snddriver_stream_nsamples(s_rd_stream_port[s_idsp], &ndata);
    if (ec != KERN_SUCCESS)
      _DSPMachError(ec,"DSPObject.c: s_finish_rd: "
		    "sndriver_stream_nsamples failed");
    
    ndata >>= 1;

    s_rd_sample_count[s_idsp] = ndata;
    
    if (_DSPVerbose)
      fprintf(stderr,"\nTotal read-data count = %d bytes (%d samples)\n",
	      (ndata<<1), ndata);
    
    if (s_rd_fd[s_idsp] >= 0)
      close(s_rd_fd[s_idsp]);
    s_rd_fd[s_idsp] = -1;

    if (_DSPVerbose)
      _DSPError1(0,"Closed read-data output file %s.",s_rd_fn[s_idsp]);
    
    s_read_data_running[s_idsp] = 0;	/* Already done on rd thread exit  */

    if (s_rd_buf[s_idsp])
      free(s_rd_buf[s_idsp]);

    return 0;
}


BRIEF int DSPMKStopReadDataTimed(DSPTimeStamp *aTimeStampP)
{
    CHECK_INIT;
    DSP_UNTIL_ERROR(DSPMKPauseReadDataTimed(aTimeStampP));
    return s_finish_rd();	/* kill thread */
}

BRIEF int DSPMKStopReadData(void) 
{
    return DSPMKStopReadDataTimed(NULL);
}

static int s_write_two_rd_buffers(void)
/* 
 * Called by DSPMKStartReadDataTimed() to initialize read-data buffers
 * in the DSP
 */
{
    int n;

    if (!s_dsp_buf_wds[s_idsp])
      s_dsp_buf_wds[s_idsp] = (dsp_nb_dma_w[s_idsp] >> 1); 
    n = (s_dsp_buf_wds[s_idsp]<<2);	/* two DSP buffers worth, in bytes */
    if (n > s_dsp_play_buf_bytes[s_idsp])
      return _DSPError(DSP_EMISC,"Compile-time Configuration error.\n"
		       "s_dsp_play_buf_bytes[s_idsp] must be "
		       ">= 4*s_dsp_buf_wds[s_idsp]");

    read(s_rd_fd[s_idsp],(char *)s_rd_buf[s_idsp], n); /* malloc is below */

    if (!s_dsp_rd_buf0[s_idsp])
      s_dsp_rd_buf0[s_idsp] = DSP_YB_DMA_W2; 

    DSPWriteArraySkipMode((DSPFix24 *)s_rd_buf[s_idsp],DSP_MS_Y,
			  s_dsp_rd_buf0[s_idsp],1,
			  s_dsp_buf_wds[s_idsp]>>1,DSP_MODE16);

    return 0;
}

static int s_enqueue_play_region(void)
/* Called by the read-data thread to send a buffer of sound to the DSP */
{
    static int tag=0;
    int ec;

    read(s_rd_fd[s_idsp],(char *)s_rd_buf[s_idsp], 
	 s_dsp_play_buf_bytes[s_idsp]); /* malloc is below */

    ec = snddriver_stream_start_writing(s_rd_stream_port[s_idsp],
					(void *)s_rd_buf[s_idsp],
	/* no. SAMPLES to write */ (s_dsp_play_buf_bytes[s_idsp]>>1), tag++, 
        /* preempt */ 0, /* deallocate */ 0,  /* started */ 0, 
	/* completed */ 1, /* aborted */ 1, 0,0,0,s_rd_reply_port[s_idsp]);

    if (ec != KERN_SUCCESS)
      return _DSPMachError(ec,"s_enqueue_play_region: "
		  "snddriver_stream_start_writing for read-data failed");
    return 0;
}

int DSPMKStartReadDataTimed(DSPTimeStamp *aTimeStampP)
{
    int chan = DSPMK_RD_DSP_CHAN; /* read-data is DSP DMA channel 1 */
    CHECK_INIT;

#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(s_simulator_fp[s_idsp],";; Enable read data from DSP to host\n");
#endif SIMULATOR_POSSIBLE

    s_freePort(&s_rd_reply_port[s_idsp]);
    if (ec=s_allocPort(&s_rd_reply_port[s_idsp])) return ec;
    
    s_rd_rmsg = _DSP_stream_msg(s_rd_rmsg,s_rd_stream_port[s_idsp],
				thread_reply(),1);
    
    if (!s_rd_buf[s_idsp])
      s_rd_buf[s_idsp] = (short *)malloc(s_dsp_play_buf_bytes[s_idsp]);

    DSP_UNTIL_ERROR(s_write_two_rd_buffers());
    
#if TRACE_POSSIBLE
    if (_DSPTrace)
      fprintf(stderr,"Entering read-data loop:\n");
#endif TRACE_POSSIBLE
    
    /* Tell DSP when to start reading */
    if (aTimeStampP != DSPMK_UNTIMED) {
	DSP_UNTIL_ERROR(DSPMKCallTimed(aTimeStampP,
				       dsp_hm_host_rd_on[s_idsp],1,&chan));
    }    

    s_stop_read_data[s_idsp] = 0;	/* watched by s_rd_writer() */
    s_read_data_running[s_idsp] = 1;

    if (s_no_thread[s_idsp])
      s_rd_writer(s_idsp);
    else {
	s_rd_thread[s_idsp] = cthread_fork((cthread_fn_t)s_rd_writer,(void *)s_idsp);
	cthread_yield();	/* Allow read-data thread to get going */
    }
    return 0;
}


BRIEF int DSPMKStartReadDataPaused(void) 
{
    CHECK_INIT;
    return DSPMKStartReadDataTimed(DSPMK_UNTIMED);
}


BRIEF int DSPMKStartReadData(void) 
{
    CHECK_INIT;
    return DSPMKStartReadDataTimed(&DSPMKTimeStamp0);
}


BRIEF int _DSPMKStartReadDataNoThread(void) 
{
    CHECK_INIT;
    s_no_thread[s_idsp] = 1;
    return DSPMKStartReadDataTimed(DSPMK_UNTIMED);
}


static int s_rd_writer(int myDSP)
/*
 * function which runs in its own thread writing read-data buffers to
 * the DSP.  
 */
{
    int timeout=2000;		/* timeout we use internally in ms */
    
    while (1) {

	/*
	 * Wait for "completed" message on the read-data stream port.
	 */

	s_rd_rmsg->msg_size = MSG_SIZE_MAX;
	s_rd_rmsg->msg_local_port = s_rd_reply_port[myDSP];
	
	ec = msg_receive(s_rd_rmsg, RCV_TIMEOUT, timeout);
	
	/*
	 * NOTE: stdio cannot be used in multiple threads!
	 */
	
	if (ec != KERN_SUCCESS && ec != RCV_TIMED_OUT) {
	    s_rd_error[myDSP] = ec;
	    s_rd_error_str[myDSP] = "msg_receive 1 failed";
	}

	if (ec == RCV_TIMED_OUT) {
	    if (s_frozen[myDSP])
	      continue;		/* keep trying to read DSP buffer */
	    if (_DSPVerbose)
	      fprintf(stderr,"\ns_rd_writer: "
		      "data msg_receive timeout\n");
	    DSPAwakenDriver();
	    continue;	/* retry buffer read from DSP */
	}

	if (s_rd_rmsg->msg_id != SND_MSG_COMPLETED) {
	    s_rd_error[myDSP] = ec;
	    s_rd_error_str[myDSP] = "Unexpected msg while expecting "
	      "SND_MSG_COMPLETED... "
	      "See snd_msgs.h(SND_MSG_*)";
	    /* Unexpected msg = _DSPCVS(s_rd_rmsg->msg_id)); */
	    continue;
	}
	
	/* 
	 * Terminate if so requested.
	 */
	if (!s_open[myDSP]) {
	    if (_DSPVerbose)
	      fprintf(stderr,"\ns_rd_writer: terminating on DSP closed\n");
	    s_stop_read_data[myDSP] = 1;
	}
	
	if (s_stop_read_data[myDSP]) {
	    if (_DSPVerbose)
	      fprintf(stderr,"\ns_rd_writer: "
		      "terminating on s_stop_read_data[myDSP]\n");
	    ec = snddriver_stream_control(s_rd_stream_port[myDSP],
					  0,SND_DC_ABORT);
	    if (ec != KERN_SUCCESS) {
		s_rd_error[myDSP] = ec;
		s_rd_error_str[myDSP] = "snddriver_stream_control(abort) "
		  "failed";
	    }
	    break;
	}
	
	/* 
	 * Send a request to play the next buffer.
	 */
	if (ec = s_enqueue_play_region()) {
	    s_rd_error[myDSP] = ec;
	    s_rd_error_str[myDSP] = "Enqueing of read-data region FAILED.";
	    break;
	}
    }
    
    s_read_data_running[myDSP] = 0;

    return 0;
}


/***************************** SoundOut Handling ****************************/

BRIEF int DSPMKStartSoundOut(void) 
{
    int chan = DSPMK_WD_DSP_CHAN;
    CHECK_INIT;

    if (!s_sound_out[s_idsp] && !s_ssi_sound_out[s_idsp])
      return _DSPError(DSP_EMISC,"DSPMKStartSoundOut: "
		       "DSP link to sound-out not enabled");

    if (s_sound_out[s_idsp]) {
#if SIMULATOR_POSSIBLE
	if (s_simulated[s_idsp]) 
	  fprintf(s_simulator_fp[s_idsp],
		  ";; Enable write data from DSP to host\n");
#endif SIMULATOR_POSSIBLE    
	/* It's ok if DSPMKStartWriteData() does this redundantly */
	DSP_UNTIL_ERROR(DSPCall(dsp_hm_host_wd_on[s_idsp],1,&chan));
    }
    
    if (s_ssi_sound_out[s_idsp])
      return DSPMKStartSSISoundOut();

    return 0;
}

BRIEF int DSPMKStopSoundOut(void) 
{
    int chan = DSPMK_WD_DSP_CHAN; /* Sound-out is DSP DMA channel 1 */
    CHECK_INIT;
    if (s_bail_out[s_idsp]) {
	if (s_sound_out[s_idsp])  /* Check added by DAJ. Oct 12, 1993 */
	  DSPMKDisableSoundOut(); 
	if (s_ssi_sound_out[s_idsp])
	  DSPMKDisableSSISoundOut(); 
	return DSP_EABORT;
    }
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(s_simulator_fp[s_idsp],
	      ";; Disable sound-out from DSP to host\n");
#endif SIMULATOR_POSSIBLE

    /* It's ok if DSPMKStopWriteData() does this redundantly */
    if (s_sound_out[s_idsp])  /* Check added by DAJ. Oct 12, 1993 */
      DSP_UNTIL_ERROR(DSPCall(dsp_hm_host_wd_off[s_idsp],1,&chan));

    if (s_ssi_sound_out[s_idsp])
      return DSPMKStopSSISoundOut();

    return 0;
}

int DSPMKStartSSIReadData(void) 
{
    CHECK_INIT;
    if (!s_ssi_read_data[s_idsp])
      return _DSPError(DSP_EMISC,"DSPMKStartSSIReadData: not enabled");
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(s_simulator_fp[s_idsp],
	      ";; Enable read data from SSI serial port to DSP\n");
#endif SIMULATOR_POSSIBLE
    return DSPHostMessage(dsp_hm_dma_rd_ssi_on[s_idsp]);
}

BRIEF int DSPMKStopSSIReadData(void) 
{
    CHECK_INIT;
    DSPMKDisableSSIReadData(); /* Set instance variable in DSPObject() */
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(s_simulator_fp[s_idsp],
	      ";; Disable read data from SSI serial port to DSP\n");
#endif SIMULATOR_POSSIBLE
    return DSPHostMessage(dsp_hm_dma_rd_ssi_off[s_idsp]);
}

int DSPMKStartSSISoundOut(void) 
{
    CHECK_INIT;
    if (!s_ssi_sound_out[s_idsp])
      return _DSPError(DSP_EMISC,"DSPMKStartSSISoundOut: not enabled");
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(s_simulator_fp[s_idsp],
	      ";; Enable write data from DSP to SSI serial port\n");
#endif SIMULATOR_POSSIBLE
    return DSPHostMessage(dsp_hm_dma_wd_ssi_on[s_idsp]);
}

BRIEF int DSPMKStopSSISoundOut(void) 
{
    CHECK_INIT;
    DSPMKDisableSSISoundOut(); /* Set instance variable in DSPObject() */
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(s_simulator_fp[s_idsp],
	      ";; Disable write data from DSP to SSI serial port\n");
#endif SIMULATOR_POSSIBLE
    return DSPHostMessage(dsp_hm_dma_wd_ssi_off[s_idsp]);
}


/******************************** MACH INTERFACE ****************************/

int notify_switch=1;

#if 0
static int s_notifyingMsgSend(void)
/*
 * Send Mach message.
 */
{
    int ec;
    int toc; /* time-out count for msg_receive() */
    int rpe=0; /* reply port exists */

/* 
 * Normally, messages to send have a null "local port" in order
 * to suppress a reply.  If there is a local port, we use it. 
 */
    if (s_dspcmd_msg->msg_local_port && (s_dspcmd_msg->msg_local_port != thread_reply()))
        _DSPError(DSP_EMACH,"DSPObject.c: s_msgSend: "
	   "Reply port in Mach message not thread_reply() "
		  "for SEND_NOTIFY reply.");
   
    if (s_dspcmd_msg->msg_local_port)
        rpe=1;
    else
        s_dspcmd_msg->msg_local_port = thread_reply();

    if (notify_switch)
    	ec = msg_send(s_dspcmd_msg, SEND_NOTIFY,0); 
    else
    	ec = msg_send(s_dspcmd_msg, MSG_OPTION_NONE,0); 
    
    if (ec == KERN_SUCCESS)
	return 0;

    if (ec != SEND_WILL_NOTIFY)
        return _DSPError(DSP_EMACH,"DSPObject.c: s_msgSend: "
			 "Did not get will-notify or success "
			 "from msg_send().");
    

#if 0
    *** FIXME: The following for loop always times out without ever getting the
    notify message.  We do get several SND messages (ill_msgid 200 =>
    SND_MSG_DSP_MSG) which are probably due to our setting msg_local_port in
    the message sent when it otherwise would have been NULL.  (The sound driver
    suppresses replies when the local port is NULL in the sent message.)  It
    seems the NOTIFY_MSG_ACCEPTED message is getting lost.
#endif

    for(toc=0; toc<10; toc++) {
    
    	_DSP_dsprcv_msg_reset(s_dsprcv_msg,s_dsp_hm_port[s_idsp],
			      s_dspcmd_msg->msg_local_port);

    	ec = msg_receive(s_dsprcv_msg, RCV_TIMEOUT, 100); /* wait 100 ms */
    
    	if (ec == RCV_TIMED_OUT)
	    continue;

	if ( s_dsprcv_msg->msg_id == NOTIFY_MSG_ACCEPTED ) 
	    break;
	else {
	    if ( s_dsprcv_msg->msg_id == NOTIFY_PORT_DELETED )
	    	return _DSPError(DSP_EMACH,"DSPObject.c: s_msgSend: "
	    		"Got NOTIFY_PORT_DELETED message waiting for "
				 "msg_send() to unblock.");
	    
    	    if (rpe)
      		_DSPError(DSP_EMACH,"_DSPAwaitMsgSendAck: "
			 "Original message had a reply_port, "
			 "and we may have got its msg while waiting for "
			  "NOTIFY_MSG_ACCEPTED");
    	    if (s_dsprcv_msg->msg_id == SND_MSG_ILLEGAL_MSG)
      		_DSPError1(DSP_EMACH,"_DSPAwaitMsgSendAck: "
			 "Got reply to msg_id %s instead of SEND_NOTIFY",
			 _DSPCVS(((snd_illegal_msg_t *) 
				  s_dsprcv_msg)->ill_msgid));
	    else
	      _DSPError1(DSP_EMACH,"DSPObject.c: s_msgSend: "
			 "msg_id %s in reply not recognized while waiting for "
			 "NOTIFY_MSG_ACCEPTED. \n"
			 ";; Look in snd_msgs.h for "
			 "300 series messages,\n "
			 ";; and /usr/include/sys/notify.h for "
			 "100 series messages.\n"
			 ";; THROWING THIS MESSAGE AWAY and continuing.",
			 _DSPCVS(s_dsprcv_msg->msg_id));
	}
    }
    return 0;
}
#endif

static int s_msgSend(void)
/*
 * Send Mach message.
 */
{
    int ec;

    if (s_saving_commands[s_idsp]) {
	/* FIXME This would need to be swapped to big if we want to support
	 * writing of commands files on Intel hardware. - DAJ
	 */
	if (write(s_commands_fd[s_idsp],(void *)s_dspcmd_msg, 
		  s_dspcmd_msg->msg_size)
	    != s_dspcmd_msg->msg_size)
	  return _DSPError(DSP_EUNIX, 
			   "Could not write message to dsp commands file");
	s_commands_numbytes[s_idsp] += s_dspcmd_msg->msg_size;
    }
	    
    ec = msg_send(s_dspcmd_msg, SEND_TIMEOUT,_DSP_MACH_SEND_TIMEOUT);
    
    while (ec == SEND_TIMED_OUT) {
	/* 
	* If we get stuck here, consider the possibility that the DSP is
	* sending error messages that aren't being read.  This will block
	* the DSP driver when its 512-word receive buffer fills up. 
	*/
	DSPGetHostTime();
	ec = msg_send(s_dspcmd_msg, SEND_TIMEOUT,_DSP_MACH_SEND_TIMEOUT); 
	DSPGetHostTime();
	s_all_block_time[s_idsp] += s_deltime;
	if (s_deltime > s_max_block_time[s_idsp])
	    s_max_block_time[s_idsp] = s_deltime;
    }

    if (ec != KERN_SUCCESS)
	return _DSPMachError(ec,"DSPObject.c: s_msgSend: msg_send failed.");

    return 0;
}

/*********************** OPENING AND CLOSING THE DSP ***********************/

/*I #include "DSPOpen.c" */
/* included by DSPObject.c */
/*********************** OPENING AND CLOSING THE DSP ***********************/

/*
 * Modification history
 *
 * 07/14/90/jos - s_host_msg[s_idsp] now 
 *		  = SNDDRIVER_DSP_PROTO_{DSPMSG|DSPERR|HFABORT|RAW}
 * 3/12/93/daj - Commented out clearing of s_mapped_only in DSPRawClose().
 */


int DSPRawCloseSaveState(void)
{
    int ec = 0;
    
    CHECK_INIT;
    s_open[s_idsp] = 0;		/* DSP is officially closed. (See threads) */
    
    _DSPResetTMQ();		/* Clear timed-message-queue buffering */
    
    if (s_wd_thread[s_idsp]) { 
	s_finish_wd();
	s_wd_thread[s_idsp] = 0;
    }

    if (s_rd_thread[s_idsp]) { 
	s_finish_rd();
	s_rd_thread[s_idsp] = 0;
    }

    s_finish_error_reader(); /* Added by DAJ, 12/13/94 */

#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      DSPCloseSimulatorFile();
#endif SIMULATOR_POSSIBLE
    if (s_saving_commands[s_idsp])
      DSPCloseCommandsFile(NULL);
    
    DSPCloseErrorFP();		/* _DSPError.c */
    
    if ( s_freePort(&s_dsp_hm_port[s_idsp]) )
      _DSPError(0,"DSPRawCloseSaveState: "
		"Could not free s_dsp_hm_port[s_idsp]");

/*
  We cannot free the sound device port because the sound library may
  also think it is the owner of soundout.  When ownership is freed, it
  goes away for everyone else also.  What should be happening is that
  there is never joint ownership.  The negotiation port mechanism will
  eventually result in the passing of the ownership capability from one
  task to another (rather than effectively "copying" ownership as is done
  now).  This, by the way, was the "stealth bug" wherein Stealth could
  not use sound-out after a DSPClose().

*    if ( s_freePort(&s_sound_dev_port[s_idsp]) )
*      _DSPError(0,"DSPRawCloseSaveState: "
*		 "Could not free s_sound_dev_port[s_idsp]");
*/

    ec = 0;
#if m68k
    ec = SNDRelease(s_dsp_access_flags[s_idsp],
		    s_sound_dev_port[s_idsp],
		    s_dsp_owner_port[s_idsp]);
#endif

    s_dsp_access_flags[s_idsp] = 0;
    s_sound_dev_port[s_idsp] = 0;	/* Indicate release */
    s_dsp_owner_port[s_idsp] = 0;	/* Indicate release */

    if ( s_freePort(&s_dsp_dm_port[s_idsp]) )
      _DSPError(0,"DSPRawCloseSaveState: "
		"Could not free s_dsp_dm_port[s_idsp]");
    if ( s_freePort(&s_driver_reply_port[s_idsp]) )
      _DSPError(0,"DSPRawCloseSaveState: "
		"Could not free s_driver_reply_port[s_idsp]");
    if ( s_freePort(&s_dsp_err_port[s_idsp]) )
      _DSPError(0,"DSPRawCloseSaveState: "
		"Could not free s_dsp_err_port[s_idsp]");
    if ( s_freePort(&s_dsp_neg_port[s_idsp]) )
      _DSPError(0,"DSPRawCloseSaveState: "
		"Could not free s_dsp_neg_port[s_idsp]");
    
    s_dsp_msgs_waiting[s_idsp] = 0;
    s_dsp_msg_ptr[s_idsp] = s_dsp_msg_0[s_idsp];
    s_dsp_msg_count[s_idsp] = 0;
    s_msg_read_pending[s_idsp] = 0;
    s_wd_stream_port[s_idsp] = 0;
    if ( s_freePort(&s_wd_reply_port[s_idsp]) )
      _DSPError(0,"DSPRawCloseSaveState: "
		"Could not free s_wd_reply_port[s_idsp]");
    
    if (_DSPVerbose && s_mk_system[s_idsp])
      fprintf(stderr,"Time spent blocked in msg_send:\n"
	      "\t maximum = %d (msec)\n"
	      "\t total	  = %d (msec)\n",
	      (int)(s_max_block_time[s_idsp]*0.001 + 0.5),
	      (int)(s_all_block_time[s_idsp]*0.001 + 0.5));
    
    s_max_block_time[s_idsp] = 0;
    s_all_block_time[s_idsp] = 0;
    s_prvtime = 0;
    s_curtime = 0;
    s_deltime = 0;

    s_frozen[s_idsp] = 0;

    s_dsp_rd_buf0[s_idsp] = 0;

    s_optimizing[s_idsp] = 0;
    
    DSPCloseWhoFile();
    
      
#if m68k /* The quint board is special--we don't clear the mapped HI 
	    (I guess) -- DAJ */
    if (s_idsp == 0 && s_dsp_fd[s_idsp] >= 0) {
	close(s_dsp_fd[s_idsp]);
	vm_deallocate(task_self(),(vm_address_t)s_hostInterface,
  		      getpagesize());
	s_hostInterfaceArray[s_idsp] = s_hostInterface = 0;
    }
#endif

#if i386 && defined(NeXT)
    dsp_close(s_idsp);  /* Removed from above conditional by DAJ 10/21/94 */
    s_hostInterfaceArray[s_idsp] = s_hostInterface = 0;
#endif

    s_dsp_fd[s_idsp] = -1;	/* Memory-mapped DSP file descriptor */

    return ec;
}

int DSPRawClose(void)
{
    int ec;
    
    ec = DSPRawCloseSaveState(); /* close DSP without clearing state */

    s_systemImage[s_idsp] = 0;

//    s_mapped_only[s_idsp] = 0;  /* Commented out by DAJ */
    s_low_srate[s_idsp] = 1;
    s_srate[s_idsp]=22050.0;
    s_sound_out[s_idsp]=0;
    s_host_msg[s_idsp]=0;

    s_dsp_msg_ptr[s_idsp] = 0;
    free(s_dsp_msg_0[s_idsp]);	/* Thanks to Nick for finding this! 6/6/95 */
    s_dsp_msg_0[s_idsp] = 0;

    s_write_data[s_idsp]=0;
    s_stop_write_data[s_idsp]=0;
    s_write_data_running[s_idsp]=0;
    s_wd_sample_count[s_idsp]=0;
    s_wd_timeout[s_idsp]=_DSPMK_WD_TIMEOUT;
    s_wd_fn[s_idsp] = 0;
    s_wd_user_func[s_idsp] = 0;
    s_wd_fd[s_idsp] = -1;
    s_wd_fp[s_idsp] = NULL;

    s_commands_fd[s_idsp] = -1;
    s_commands_fp[s_idsp] = NULL;

    s_read_data[s_idsp]=0;
    s_stop_read_data[s_idsp]=0;
    s_read_data_running[s_idsp]=0;
    s_rd_sample_count[s_idsp]=0;
    s_rd_fn[s_idsp] = 0;
    s_rd_fd[s_idsp] = -1;

    s_ssi_read_data[s_idsp]=0;
    s_ssi_sound_out[s_idsp]=0;
    s_small_buffers[s_idsp] = 0;
    s_force_tmq_flush[s_idsp] = 0;
    s_system_link_file[s_idsp] = DSP_AP_SYSTEM_0;
    s_system_binary_file[s_idsp] = DSP_AP_SYSTEM_BINARY_0;
    s_ap_system[s_idsp] = 1;
    s_mk_system[s_idsp] = 0;

    s_prvtime = 0;
    s_curtime = 0;
    s_deltime = 0;
    
    if (s_dspcmd_msg) {
	_DSP_free_dspcmd_msg(&s_dspcmd_msg);
    }

    if (s_dsprcv_msg) {
	_DSP_FREE_DSPMSG_MSG(&s_dsprcv_msg);
    }

    /* DO NOT FREE s_driver_reply_msg */

    if (s_wd_rmsg[s_idsp]) {
	free(s_wd_rmsg[s_idsp]);
	s_wd_rmsg[s_idsp] = 0;
    }
    s_bail_out[s_idsp] = 0;
    s_clock_advancing[s_idsp] = 0;
    s_clock_just_started[s_idsp] = 0;

    free(s_hm_array[s_idsp]); /* 6/7/95 */
    s_hm_array[s_idsp] = 0;   /* 6/7/95 */
    free(s_timedMsg[s_idsp]); /* 6/7/95 */
    s_timedMsg[s_idsp] = 0;   /* 6/7/95 */

//    s_idsp = 0;	/* moved and commented out by DAJ. No need to do it */
    return ec;
}


BRIEF int DSPClose(void)		/* close DSP device */
{
    CHECK_INIT;
    if (!s_open[s_idsp])
      return 0;

    /* 
     * If we're bailing out, we have to make sure we don't try to talk to
     * the DSP anywhere 
     */
    DSPMKFlushTimedMessages();	/* Not that they can get much done! */
    
    if (s_sound_out[s_idsp] || s_ssi_sound_out[s_idsp]) 
      DSPMKStopSoundOut();

    if (s_ssi_read_data[s_idsp]) 
      DSPMKStopSSIReadData();

    return (DSPRawClose());
}


BRIEF int DSPCloseSaveState(void) /* close DSP device, saving open state */
{
    CHECK_INIT;
    if (!s_open[s_idsp])
      return 0;
    
    if (s_sound_out[s_idsp] || s_ssi_sound_out[s_idsp])
      DSPMKStopSoundOut();
    
    if (s_write_data[s_idsp])
      if (!s_bail_out[s_idsp]) 
	DSPMKStopWriteData();
      else s_finish_wd();    

    if (s_read_data[s_idsp]) /* Not supported */
      DSPMKStopReadData();
    
    if (s_ssi_read_data[s_idsp])
      DSPMKStopSSIReadData();

    return (DSPRawCloseSaveState());
}

#if i386 && defined(NeXT)
static void doReset(void)
{
    dsp_reset(s_idsp,1);    /* Enable reset state */
    usleep(10000);         /* Give it a chance */
    dsp_reset(s_idsp,0);    /* Disable reset state */
//    dsp_selectMemoryMap(s_idsp,1);   /* Select split memory map */
}
#endif

int _DSPMapHostInterface(void)	/* Memory-map DSP Host Interface Registers */
{
    /*** FIXME: Test permissions here and fail gracefully if not enough ***/

#if i386 && defined(NeXT)
    if (s_dsp_fd[s_idsp]>0)
      return 0;
    if (dsp_open(s_idsp))
      return _DSPError(DSP_EMISC,"openDSPDriver() failed.\n");
    doReset();
    s_dsp_fd[s_idsp] = 1; /* Give it a positive value to fudge tests */
    return 0;
#endif    

    if (s_hostInterface)
      return 0;			/* Already have it */

#if MMAP
    if (s_dsp_fd[s_idsp]<0)
      s_dsp_fd[s_idsp] = open("/dev/dsp",O_RDWR,0);	/* need <sys/file.h> */

    if (s_dsp_fd[s_idsp] == -1) {
	return _DSPError(DSP_EMISC,
			 "DSPMapHostInterface: open /dev/dsp failed");
    }
#endif
#ifndef WIN32
    vm_allocate(task_self(),(vm_address_t *)&s_hostInterface, getpagesize(),TRUE);
#endif
    s_hostInterfaceArray[s_idsp] = s_hostInterface;
    
#if MMAP && !defined(WIN32)
    ec = (int) mmap((caddr_t) s_hostInterface,
	      getpagesize(),		/* Must map a full page */
	      PROT_READ|PROT_WRITE,	/* read-write access */
	      MAP_SHARED,		/* shared access (of course) */
	      s_dsp_fd[s_idsp],		/* This device */
	      0);			/* 0 offset (cf P_DSP <next/cpu.h>) */
    if (ec == -1) {
	s_hostInterfaceArray[s_idsp] = s_hostInterface = 0;
	return _DSPError(ec,"DSP Host Interface mmap failed.");
    }
#endif

    return 0;
}


static int s_initMessageFramesAndPorts()
/*
 * Set up ports for communication with the DSP.
 */
{
    int ec;

    /* s_dsp_hm_port[s_idsp] is allocated by kernel. */
    s_allocPort(&s_dsp_dm_port[s_idsp]);
    s_allocPort(&s_dsp_err_port[s_idsp]);
    s_allocPort(&s_dsp_neg_port[s_idsp]);

    s_allocPort(&s_driver_reply_port[s_idsp]);
    
    ec = snddriver_get_dsp_cmd_port(s_sound_dev_port[s_idsp], 
			       s_dsp_owner_port[s_idsp], 
			       &s_dsp_hm_port[s_idsp]);
    
    if (ec != KERN_SUCCESS)
      return _DSPMachError(ec,"s_initMessageFramesAndPorts: "
			   "snddriver_get_dsp_cmd_port failed.");
    

    /* Initialize reuseable receive-data message */
    if (s_dsprcv_msg)
      _DSP_free_dspcmd_msg(&s_dsprcv_msg);
    s_dsprcv_msg = _DSP_dsprcv_msg(s_dsp_hm_port[s_idsp],
				   s_dsp_dm_port[s_idsp]);
    
    /* Initialize reuseable DSP command message */
    if (s_dspcmd_msg)
      _DSP_free_dspcmd_msg(&s_dspcmd_msg);
    s_dspcmd_msg = _DSP_dspcmd_msg(s_dsp_hm_port[s_idsp],
				   s_dsp_dm_port[s_idsp],DSP_MSG_LOW,0);
    
    /* Initialize reuseable driver reply message - DO NOT FREE IT */
    s_driver_reply_msg = _DSP_dspreply_msg(s_driver_reply_port[s_idsp]);
    
    return 0;
    
}

static int s_setupProtocol()
/*
 * Set up data streams and DSP driver protocol flags according to 
 * whether sound output and/or write-data is desired.
 * The DSP-soundout stream requires a DSP system to be registered!
 */
{
    int ec = 0;
    
#if m68k
    if (s_mapped_only[s_idsp] && s_idsp > 0)
      return 0;
#endif

    if (s_mapped_only[s_idsp]) {
	s_dsp_mode_flags[s_idsp] = SNDDRIVER_DSP_PROTO_RAW;
	if (s_host_msg[s_idsp]) {
	    ec = _DSPError(DSP_EPROTOCOL,
		       "s_setupProtocol: "
		       "HostMessage mode not available in mapped mode");
	    s_host_msg[s_idsp] = 0;
	}
	if (s_sound_out[s_idsp]) {
	    ec = _DSPError(DSP_EPROTOCOL,
		       "s_setupProtocol: "
		       "Sound not available in mapped mode");
	    s_sound_out[s_idsp] = 0;
	}
#if m68k
	if (s_read_data[s_idsp] || s_write_data[s_idsp]) {
	    ec = _DSPError(DSP_EPROTOCOL,
		       "s_setupProtocol: "
		       "Read/write data not available in mapped mode");
	    s_read_data[s_idsp] = s_write_data[s_idsp] = 0;
	}
#endif
	goto setup_protocol;
    }

    /*** NOTE: The host_msg mode flags below must stay in synch with
      DSP{Set,Clear}HostMessageMode(); ***/

    s_dsp_mode_flags[s_idsp] = 0;
    if (s_host_msg[s_idsp]) {
	s_dsp_mode_flags[s_idsp] |= SND_DSP_PROTO_HOSTMSG;
	s_dsp_mode_flags[s_idsp] |= SND_DSP_PROTO_TXD;
	/* 2nd DSP interrupt to driver */
    } else
      s_dsp_mode_flags[s_idsp] |= SND_DSP_PROTO_RAW;

    if (s_sound_out[s_idsp] && s_srate[s_idsp] != DSPMK_HIGH_SAMPLING_RATE &&
	s_srate[s_idsp] != DSPMK_LOW_SAMPLING_RATE) {
	_DSPError1(DSP_EMISC,
		   "s_setupProtocol: Cannot set up sound-out stream "
		   "when using non-standard sampling rate. "
		   "Changing sampling rate to %s Hz.",
		   _DSPCVS(DSPMK_LOW_SAMPLING_RATE));
	DSPMKSetSamplingRate(DSPMK_LOW_SAMPLING_RATE);
    }

    /*
     * Determine DSP DMA buffer sizes for input and output.
     */
    if (s_read_data[s_idsp] || s_write_data[s_idsp] || s_sound_out[s_idsp]) {
	/*** The following requires a DSP system to be registered! ***/
	s_dsp_buf_wds[s_idsp] = (dsp_nb_dma_w[s_idsp] >> 1); 
	/* default (used if no read data) */
    }

#if 0
    /* DAJ: This is done by the smsrc code so we don't do it here. */
    if ((s_ssi_read_data[s_idsp] || s_read_data[s_idsp]) &&  
	(s_write_data[s_idsp] || s_sound_out[s_idsp])) {
	s_dsp_buf_wds[s_idsp] >>= 1; /* cut in half for full duplex */
    }
#endif

    /*
     * Set up stream into DSP, if read-data enabled.
     */
    if (s_read_data[s_idsp]) {

	if (s_sound_out[s_idsp])
	  s_stream_configuration[s_idsp] = (s_low_srate[s_idsp] ?
				    SNDDRIVER_STREAM_THROUGH_DSP_TO_SNDOUT_22 :
				    SNDDRIVER_STREAM_THROUGH_DSP_TO_SNDOUT_44);
	else 
	  s_stream_configuration[s_idsp] = SNDDRIVER_STREAM_TO_DSP;
	ec = snddriver_stream_setup (
				     s_sound_dev_port[s_idsp],
				     s_dsp_owner_port[s_idsp],
				     s_stream_configuration[s_idsp],
				     s_dsp_buf_wds[s_idsp], /* SAMPLES/buf */
				     2, /* bytes per sample */
				     s_low_water[s_idsp], /* low water mark */
				     s_high_water[s_idsp], /* high water mk */
				     &s_dsp_mode_flags[s_idsp], /* new proto */
				     &s_rd_stream_port[s_idsp]);/* rtnd port */
	if (ec != KERN_SUCCESS)
	  return _DSPMachError(ec,"DSPObject.c: can't setup read-data stream");
    } else
      s_rd_stream_port[s_idsp] = 0;

    /*
     * Set up stream out of DSP, if write-data enabled.
     * The "write-data" stream is also used as a handle on the 
     * DSP->soundOut link when there is no read-data or write-data.
     */
    if (s_write_data[s_idsp])
      s_stream_configuration[s_idsp] = SNDDRIVER_STREAM_FROM_DSP;
    else if (s_sound_out[s_idsp] && !s_read_data[s_idsp])
      s_stream_configuration[s_idsp] = (s_low_srate[s_idsp] ?
				SNDDRIVER_STREAM_DSP_TO_SNDOUT_22 :
				SNDDRIVER_STREAM_DSP_TO_SNDOUT_44 );
    else s_stream_configuration[s_idsp] = 0;
    
    if (s_sound_out[s_idsp]) {
	s_so_buf_bytes[s_idsp] = (s_small_buffers[s_idsp]? 
			  2*s_dsp_buf_wds[s_idsp] : _DSPMK_LARGE_SO_BUF_BYTES);
	ec = snddriver_set_sndout_bufsize( 
				   s_sound_dev_port[s_idsp],
				   s_dsp_owner_port[s_idsp],
				   s_so_buf_bytes[s_idsp]);
	if (ec != KERN_SUCCESS)
	  return 
	    _DSPMachError(ec,"DSPObject.c: "
		  "snddriver_set_sndout_bufsize() failed");
	/*** FIXME: call snddriver_set_sndout_bufcnt() also ***/
    }

    if (s_stream_configuration[s_idsp]) {
	ec = snddriver_stream_setup (
				 s_sound_dev_port[s_idsp],
				 s_dsp_owner_port[s_idsp],
				 s_stream_configuration[s_idsp],
				 s_dsp_buf_wds[s_idsp], /* SAMPLES/buffer */
				 2, /* bytes per sample */
				 s_low_water[s_idsp], /* low water mark */
				 s_high_water[s_idsp], /* high water mark */
				 &s_dsp_mode_flags[s_idsp], /* new dsp proto */
				 &s_wd_stream_port[s_idsp]);/* rtnd strmport */

	if (ec != KERN_SUCCESS)
	  return _DSPMachError(ec,"DSPObject.c:snddriver_stream_setup failed");
    } else
      s_wd_stream_port[s_idsp] = 0;

    /*
     * Set up DSP protocol.
     * This must be one AFTER setting the DMA buffer sizes (?).
     */
 setup_protocol:
    ec = 0;
#if m68k
    ec = snddriver_dsp_protocol(s_sound_dev_port[s_idsp], 
				s_dsp_owner_port[s_idsp], 
				s_dsp_mode_flags[s_idsp]);
    if (ec != KERN_SUCCESS)
      return _DSPMachError(ec,"DSPObject.c: snddriver_dsp_protocol failed.");
#endif    
    return ec;
}

BRIEF int DSPMKSoundOutDMASize(void)
{
    return s_dsp_buf_wds[s_idsp]>>1; /* Single DMA buffer size in 16-bit wds */
}

/******************************* DSP File Locking ****************************/

#ifdef GETPWUID_BUG_FIXED
#import <pwd.h>		/* for getpwuid */
#endif

int DSPOpenWhoFile(void)
{
    time_t tloc;
    
    CHECK_INIT;
    umask(0); /* Don't CLEAR any filemode bits (arg is backwards!) */
    if (!s_whofile_fp[s_idsp])
      if ((s_whofile_fp[s_idsp]=fopen(DSP_WHO_FILE,"w"))==NULL)
	return _DSPError1(0,"*** DSPOpenWhoFile: Could not open %s."
			  " Perhaps the file is write protected."
			  " We will continue without it."
			  " (Mach port ownership, not the who file,"
			  " is used to arbitrate use of the DSP.)",
			  DSP_WHO_FILE); 
    tloc = time(0);

#ifdef GETPWUID_BUG_FIXED
    if (!lname)
      lname = getlogin();
    if (!lname) {
	    pw = getpwuid(getuid());
	    if (pw)
	      lname = pw->pw_name;
	    else
	      lname = "<user not in /etc/passwd>";
    }
    fprintf(s_whofile_fp[s_idsp],"DSP opened in PID %d by %s on %s\n",
	    getpid(),lname,ctime(&tloc));
#else	
    fprintf(s_whofile_fp[s_idsp],"DSP opened in PID %d on %s\n",
	    getpid(),ctime(&tloc));
#endif

    fflush(s_whofile_fp[s_idsp]);
    return 0;
}      

int DSPCloseWhoFile(void)
{
    if (s_whofile_fp[s_idsp]) {
	fclose(s_whofile_fp[s_idsp]);
	s_whofile_fp[s_idsp] = 0;
	unlink(DSP_WHO_FILE);
    }
    return 0;
}

char *DSPGetOwnerString(void)
/* "DSP opened in PID 351 by me on Sun Jun 18 17:50:46 1989" */
{
    FILE *lockFP;
    char linebuf[_DSP_MAX_LINE]; /* input line buffer */
    
    if ((lockFP=fopen(DSP_WHO_FILE,"r"))==NULL)
      return NULL;
    
    if (fgets(linebuf,_DSP_MAX_LINE,lockFP)==NULL) {
	_DSPError1(DSP_EUNIX,"DSPOpenNoBoot: Could not read %s\n",
		   DSP_WHO_FILE);
	fclose(lockFP);
	return NULL;
    }
    fclose(lockFP);
    if (linebuf[strlen(linebuf)-1]=='\n')
      linebuf[strlen(linebuf)-1]='\0';
    return _DSPCopyStr(linebuf);
}


BRIEF int DSPOpenNoBootHighPriority(void)
{
    CHECK_INIT;
    DSPSetOpenPriority(1);
    return DSPOpenNoBoot();
}	

int DSPAlternateReset(void)	/*** FIXME: This seems not to work ***/
{
    mach_port_t neg_port;

    CHECK_INIT;
    if (s_dsp_neg_port[s_idsp])
      neg_port = s_dsp_neg_port[s_idsp];
    else
      neg_port = s_dsp_owner_port[s_idsp];

    ec = snddriver_set_dsp_owner_port(s_sound_dev_port[s_idsp], 
				      s_dsp_owner_port[s_idsp], 
				      &neg_port);
    if (ec != KERN_SUCCESS) {
	_DSPMachError(ec,"DSPReset: "
		      "snddriver_set_dsp_owner (for reset) failed. "
		      "Trying DSPClose().");
	DSPClose();		/* This should also cause a reset */
	ec = DSPOpenNoBoot();
	if (ec)
	  _DSPError(ec,"DSPReset: Could not reset via close either.");
    }
    return ec;
}


BRIEF int DSPReset(void)
/* 
 * Reset the DSP.
 * On return, the DSP should be awaiting a 512-word bootstrap program.
 * Note that we can reset the negotiation port for the DSP from its
 * default of the owner port this way.
 */
{
    CHECK_INIT;
#if m68k
    if (s_idsp>0 
	&& s_mapped_only[s_idsp] 
	&& strncmp(s_nameArray[s_idsp],"Quint",5)==0) {
	if(!reset_processor56(LLRESET_CURR))
	  return _DSPError1(DSP_EQUINT,"DSPReset: failed for DSP %s",
			    _DSPCVS(s_idsp));
    } else if (!s_mapped_only[s_idsp]) {
	ec = snddriver_dsp_reset(s_dsp_hm_port[s_idsp],s_cur_pri[s_idsp]);
	if (ec != KERN_SUCCESS)
	  return _DSPMachError(ec,"DSPReset: snddriver_dsp_reset failed.");
    } else
      return _DSPError1(DSP_EMISC,"DSPReset: Don't know how to reset DSP %s "
			"(memory-mapped, not a Quint)", _DSPCVS(s_idsp));
#endif
#if i386 && defined(NeXT)
    doReset();
#endif
    return 0;
}


/*** FIXME: Describe state variables in comment below ***/

int DSPOpenNoBoot(void)		/* open current DSP */
{
    /*** FIXME: Move outside of single DSP instance ***/
    int ec=0,ecs;
    mach_port_t neg_port;
    char *host;

    CHECK_INIT;

#if m68k
    if(s_idsp > 0)
      QP_RstNmi(s_idsp-1,DSP_TRUE);
#endif
 
    host = (s_mapped_only[s_idsp]? "" : s_nameArray[s_idsp]);

    if (s_open[s_idsp]) 
      return _DSPError(0,"DSPOpenNoBoot: DSP is already open. Returning...");
    
    s_bail_out[s_idsp] = 0;
    s_clock_advancing[s_idsp] = 0;
    s_clock_just_started[s_idsp] = 0;

#if MMAP
    if (s_mapped_only[s_idsp]) {
	if(ec=_DSPMapHostInterface())	
	  return _DSPError(ecs=ec,"DSPOpenNoBoot: Could not map DSP host interface");
    }
#endif
    
    /*
     * Get the sound driver device port.  Try the bootstrap server first if
     * hostname is "" (local machine).  This gives you a secure port that
     * can't be yanked away from a different machine.
     * 
     * Note that even in mapped_only mode, we need the sound device
     * port and dsp owner port to set the protocol mode for DSP 0.
     */

    /* DAJ: Consider not doing this if we're not doing soundout. Might help
       panic problem. FIXME */
#if m68k
    if (s_idsp==0 || !s_mapped_only[s_idsp]) {
	if (!s_sound_dev_port[s_idsp]) {
	    s_dsp_access_flags[s_idsp] = SND_ACCESS_DSP;
	    if (s_sound_out[s_idsp])
	      s_dsp_access_flags[s_idsp] |= SND_ACCESS_OUT;
	    ec = SNDAcquire(s_dsp_access_flags[s_idsp], MAXINT /* 10? */, 
			    0, 0, NULL_NEGOTIATION_FUN, 0, 
			    &s_sound_dev_port[s_idsp], 
			    &s_dsp_owner_port[s_idsp] /* BOTH */);
	    if (ec != KERN_SUCCESS 
		&& (s_dsp_access_flags[s_idsp] & SND_ACCESS_OUT))
	      return _DSPError1(ec,"DSPOpenNoBoot: "
				"Could not get DSP or sound-out.\n;; %s",
				DSPGetOwnerString());
	} /* Here we have both sound dev and DSP owner ports */
    }
#else
    ec = KERN_SUCCESS; /* Make it so */
#endif
  
    cthread_init(); /* used for write data, dsp errors, abort */

    if (ec == KERN_SUCCESS) {
	DSPOpenWhoFile();	/* Tell the world who has the DSP */
	/* FIXME - spawn thread listening to neg port, or should app do it? */
    } else {			
	/* could not become owner of DSP. Become JOINT owner. */

	/*
	 * Existing DSP owner or negotiation port is returned in neg_port.
	 * Assume it is the DSP owner port and try to continue since there
	 * is no negotiation protocol defined at the time of this writing.
	 * 6/17/89/jos
	 */
	
	/* If we can't open the DSP, we can't own its error log either */
	/* Hence, we fprintf to stderr in this situation */
	
	char *os = DSPGetOwnerString();
	
	if (os)
	  _DSPError(0,os);
	else
	  _DSPError1(DSP_EUNIX,"DSPOpenNoBoot: Could not read %s to find out "
		     " what process has the DSP open.",
		     DSP_WHO_FILE);
	
	if (s_open_priority[s_idsp] < 1) { /* give up */
	    DSPSetErrorFP(stderr);
	    s_freePort(&s_dsp_owner_port[s_idsp]);
	    return DSP_EMACH;
	}
	else if (!s_mapped_only[s_idsp]) { /* Mapped access is always joint */
	    DSP_UNTIL_ERROR(s_allocPort(&s_dsp_owner_port[s_idsp]));
	    
	    neg_port = s_dsp_owner_port[s_idsp];
	    ec = snddriver_set_dsp_owner_port(s_sound_dev_port[s_idsp], 
					      s_dsp_owner_port[s_idsp], 
					      &neg_port);
	    _DSPError(0,"DSPOpenNoBoot: Obtaining joint DSP ownership");
	    if (s_dsp_owner_port[s_idsp] == neg_port) {
		s_freePort(&s_dsp_owner_port[s_idsp]);
		return _DSPMachError(ec,"DSPOpenNoBoot: "
				     "libsys/sounddriver_client.c/"
				     "snddriver_set_dsp_owner_port "
				     "did not give us the DSP owner port");
	    } else {
		s_freePort(&s_dsp_owner_port[s_idsp]);
		s_dsp_owner_port[s_idsp] = neg_port; /* Gives co-ownership */
		s_joint_owner[s_idsp]=1; /* Detect w _DSPOwnershipIsJoint() */
		return DSP_EMISC; /* Error return indicates joint ownership */
	    }
	}
    }

    if (!s_mapped_only[s_idsp]) {
	if (s_sound_out[s_idsp]) {
	    
	    neg_port = s_dsp_owner_port[s_idsp];
	    ec = snddriver_set_sndout_owner_port(s_sound_dev_port[s_idsp], 
						 s_dsp_owner_port[s_idsp], 
						 &neg_port);
	    if (ec != KERN_SUCCESS)
	      return _DSPMachError(ec,"DSPOpenNoBoot: "
				   "Could not obtain sound-out ownership");
	}				/* if (s_sound_out[s_idsp]) */
	
	if (ec=s_initMessageFramesAndPorts())
	  _DSPError(ecs=ec,"DSPOpenNoBoot: Could not set up DSP streams");
    }

#if i386 && defined(NeXT)
    /* For non-mapped m68k, this is done in s_initMessageFramesAndPorts() */
    s_allocPort(&s_dsp_err_port[s_idsp]);
    s_allocPort(&s_dsp_dm_port[s_idsp]);

    /* Initialize reuseable receive-data message */
    if (s_dsprcv_msg)
      _DSP_free_simple_request_msg(&s_dsprcv_msg);
    s_dsprcv_msg = _DSP_simple_request_msg(s_dsp_hm_port[s_idsp],
					   s_dsp_dm_port[s_idsp],0);
    
#endif
	
    /* Initialize receive-data initial pointer */
    /*s_dsp_msg_0[s_idsp]=(int *)&(((snd_dsp_msg_t *)s_dsprcv_msg)->data[0]);*/
    s_dsp_msg_0[s_idsp] = (int *)malloc(512 * sizeof(int));
    
    if(ec=s_setupProtocol())
      _DSPError(ecs=ec,"DSPOpenNoBoot: "
		"Could not set up sound-out stream");
    /* DSPHostMessage(dsp_hm_dma_wd_host_on); (done in DSPMKInit) */
    
    s_open[s_idsp] = 1;
    
    if (!s_simulated[s_idsp])
      s_simulator_fp[s_idsp] = NULL;
    if (!s_saving_commands[s_idsp])
      s_commands_fd[s_idsp] = -1;
    
    s_max_block_time[s_idsp] = 0;
    s_all_block_time[s_idsp] = 0;
    s_prvtime = 0;
    s_curtime = 0;
    s_deltime = 0;


    return ec;
}


BRIEF int DSPMKStartReaders(void) /* Start error and message readers */
/* Called by DSPMKInit() after DSPBoot() */
{
#if i386 && defined(NeXT)
    dsp_setErrorPort(s_idsp,s_dsp_err_port[s_idsp]);
#endif
    s_dsp_err_thread[s_idsp]=cthread_fork((cthread_fn_t)s_dsp_err_reader,(void *)s_idsp);
    return 0;
}    
  
BRIEF int DSPMKStopMsgReader(void) /* Stop message reader */
/* Called by the Orchestra before waiting for the end of time */
{
    s_finish_msg_reader();
    return 0;
}    
  
BRIEF int _DSPOpenMapped(void) 
{
#if MMAP    
    _DSPEnableMappedOnly();
#else
    return _DSPError(DSP_EMISC,"_DSPOpenMapped: host interface not mappable");
#endif
    return DSPOpenNoBoot();
}

/*I END #include "DSPOpen.c" */

/************************** SIMULATOR FILE PRINTING *************************/
#if SIMULATOR_POSSIBLE
/*I #include "DSPSimulator.c" */
/* included by DSPObject.c */
/* NOTE: Any change in API here must also change in DSPObject.c at #include */
/************************** SIMULATOR FILE PRINTING *************************/

static char *s_decodeReg(reg,val) 
    int reg,val;
    /* 
     * Return string describing host interface register.
     */
{
    int r,v, hv;
    char *str = _DSPMakeStr(200,NULL);
    char *hcname;
    r = reg & 7;
    if (r!=reg) 
      _DSPError(EDOM,
		"s_decodeReg: DSP host-interface address out of range");
    v = val & 0xFF;
    if (v!=val) 
      _DSPError(EDOM,"s_decodeReg: DSP host-interface byte out of range");
    
    switch (r) {
    case DSP_ICR:
	sprintf(str,"ICR: %s %s %s %s %s %s %s",
		v & DSP_ICR_INIT ? "INIT" : "",
		v & DSP_ICR_HM1	 ? "HM1"  : "",
		v & DSP_ICR_HM0	 ? "HM0"  : "",
		v & DSP_ICR_HF1	 ? "HF1"  : "",
		v & DSP_ICR_HF0	 ? "HF0"  : "",
		v & DSP_ICR_TREQ ? "TREQ" : "",
		v & DSP_ICR_RREQ ? "RREQ" : "");
	break;
    case DSP_CVR:
	
	hv = v & DSP_CVR_HV_MASK;
	
	switch(hv) {
	case DSP_HC_RESET:
	    hcname = "RESET";
	    break;
	case DSP_HC_TRACE:
	    hcname = "TRACE";
	    break;
	case DSP_HC_SOFTWARE_INTERRUPT:
	    hcname = "SW int";
	    break;
	case DSP_HC_EXECUTE_HOST_MESSAGE:
	    hcname = "exec host msg";
	    break;
	case DSP_HC_HOST_W_DONE:
	    hcname = "HOST_W_DONE";
	    break;
	default:
	    hcname = "*** UNKNOWN ***";
	}
	
	sprintf(str,"CVR: $%X, %s Vector=0x%X (hc %d = %s)",
		v,  v & DSP_CVR_HC_MASK ? "HC" : "(NO HC)",
		hv, hv, hcname );
	break;
    case DSP_ISR:
	sprintf(str,"ISR: %s %s %s %s %s %s %s",
		v & DSP_ISR_HREQ ? "HREQ" : "",
		v & DSP_ISR_DMA	 ? "DMA"  : "",
		v & DSP_ISR_HF3	 ? "HF3"  : "",
		v & DSP_ISR_HF2	 ? "HF2"  : "",
		v & DSP_ISR_TRDY ? "TRDY" : "",
		v & DSP_ISR_TXDE ? "TXDE" : "",
		v & DSP_ISR_RXDF ? "RXDF" : "");
	break;
    case DSP_IVR:
	sprintf(str,"IVR: Vector=0x%X",v);
	break;
    case DSP_UNUSED:
	sprintf(str,"*** UNUSED DSP REGISTER *** Contents=0x%X",v);
	break;
    case DSP_TXH:
	sprintf(str,"TXH: $%02X",v);
	break;
    case DSP_TXM:
	sprintf(str,"TXM: $%02X",v);
	break;
    case DSP_TXL:
	sprintf(str,"TXL: $%02X",v);
	break;
    default:
	sprintf(str,"???: $%02X",v);
    }
    
    return str;
}

static int s_simPrintFNC(fp,reg,val) /* print host reg in simulator format */
    FILE *fp;	/* mach port for simulator file, open for write */
    int reg;	/* host-interface register to write (0:7) */
    int val;	/* least-significant 8 bits written */
{
    int r;
    r = reg & 7;
    if (r!=reg) 
      _DSPError(EDOM,"s_simPrintFNC: "
		"DSP host-interface register out of range");
    r += 8*0; /* or in the r/w~ bit */
    fprintf(fp,"4%01X%02X ",r,val);
    return 0;
}

static int s_simPrintF(fp,reg,val) 
    /* 
     * print host interface reg in simulator format 
     */
    FILE *fp;	/* file pointer for simulator file, open for write */
    int reg;	/* host-interface register to write (0:7) */
    int val;	/* least-significant 8 bits written */
{
    char *regstr;
    s_simPrintFNC(fp,reg,val); /* Print all but comment */
    regstr = s_decodeReg(reg,val);
    fprintf(fp,"\t\t ; %s [%d]\n",regstr,DSPGetHostTime()); /* add comment */
    free(regstr);
    return 0;
}

static int s_simReadRX(word) 
    int word;	/* Actual value of RX read in mapped mode */
    /* 
     * read host interface RX reg in simulator file 
     */
{
    unsigned int usword; 
    int sword; 
    float fword;
    usword = word;
    if (word & (1<<23)) usword |= (0xFF << 24); /* ignore overflow */
    sword = usword; /* re-interpret as signed */
    fword = sword*0.00000011920928955078125; /* 1/2^23 */
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],
	      "4D00 4E00 4F00   ; RX : $%06X = `%-8d = %10.8f = %s [%d]\n",
	      word&0xFFFFFF,sword,fword,DSPMessageExpand(word),
	      DSPGetHostTime());
    return 0;
}

static int s_simWriteTX(int word) /* Value of TX to write */
    /* 
     * Record write of host interface TX register to simulator file 
     */
{
    unsigned int usword; 
    int sword,i; 
    float fword;
    
    usword = word;
    if (word & (1<<23)) usword |= (0xFF << 24); /* ignore overflow */
    sword = usword; /* re-interpret as signed */
    fword = sword*0.00000011920928955078125; /* 1/2^23 */
    /* The 4F00 below reads RXL to avoid blocking of host output */
    s_simPrintFNC(s_simulator_fp[s_idsp], DSP_TXH, word>>16);
    s_simPrintFNC(s_simulator_fp[s_idsp], DSP_TXM, (word>>8)&0xFF);
    s_simPrintFNC(s_simulator_fp[s_idsp], DSP_TXL, word&0xFF);
    fprintf(s_simulator_fp[s_idsp],
	    "\t ; TX : $%06X = `%-8d = %10.8f /* [%d] */\n",
	    word,sword,fword /* ,DSPGetHostTime() */);
    return 0;
}

/************************ SIMULATOR STREAM MANAGEMENT ***********************/

int DSPOpenSimulatorFile(char *fn)			
{
    CHECK_INIT;
    if (!fn) {
	fn = "dsp000.io";
	if (s_idsp>999) return _DSPError(EDOM,"Too many DSPs for name gen");
	sprintf(fn,"dsp%03d.io",s_idsp);
	fn[3] += s_idsp;
    }
    if ((s_simulator_fp[s_idsp]=fopen(fn,"w"))==NULL)
      return 
	_DSPError1(ENOENT,
		   "_DSPUtilities: Can't open simulator output file '%s'",fn);
    if (_DSPVerbose||_DSPTrace)
      printf("\tWriting simulator output file:\t%s\n",fn);
    
    s_simulated[s_idsp] = 1;
    
    setlinebuf(s_simulator_fp[s_idsp]); /* turn off buffering */
    fprintf(s_simulator_fp[s_idsp],
	    "delay=2000;\t; *** wait for sim8k.lod reset ***\n");
    fprintf(s_simulator_fp[s_idsp],
	    ";; Read a 0 sitting in RX\n");
    s_simReadRX(0);
    fprintf(s_simulator_fp[s_idsp],
	    ";; Read DSP_DM_RESET_SOFT (0x10) message\n");
    s_simReadRX(0x100000);
    return 0;
}

int DSPCloseSimulatorFile(void)
{
    int i;
    
    for (i=0;i<20;i++)
      s_simReadRX(-1);		/* Read any waiting messages */
    
    /* fprintf(s_simulator_fp[s_idsp],"6F00#1000\t ;"
       " *** wait a while and then HALT ***\n"); */
    
    /*
      This turns out to be more trouble than it is worth because the orchestra
      has been running while.  It basically restarts the orch loop after an 
      unpredictable running stretch.
      
      fprintf(s_simulator_fp[s_idsp],
      ";; *** HALT for interactive simulation ***\n"
      "6588 663F 67B8	 ; TX : $883FB8 (dsp_hm_halt[s_idsp])\n"
      "6193		 ; CVR: $93, HC 0x13 (exec host msg)\n\n");
      
      fprintf(s_simulator_fp[s_idsp],";; *** Set time to 0 and GO! ***\n"
      "6588 663F 678A	 ; TX : $883F8A (DSPStart())\n"
      "6193		 ; CVR: $93, HC 0x13 (exec host msg)\n\n");
      */    
    
    fclose(s_simulator_fp[s_idsp]);
    s_simulated[s_idsp] = 0;
    s_simulator_fp[s_idsp] = NULL;		/* DSPGlobals.c */
    if (_DSPVerbose||_DSPTrace)
      printf("\tSimulator output stream closed.\n");
    return 0;
}


BRIEF int DSPStartSimulatorFP(FILE *fp)
{
    CHECK_INIT;
    if (fp!=NULL)
      s_simulator_fp[s_idsp]=fp;
    if(s_simulator_fp[s_idsp]==NULL)
      return _DSPError(EIO,"DSPStartSimulator: Cannot start. "
		       "No open stream");
    s_simulated[s_idsp] = 1;
    return 0;
}


BRIEF int DSPStartSimulator(void)
{
    return DSPStartSimulatorFP(s_simulator_fp[s_idsp]);
}


BRIEF int DSPStopSimulator(void)
{
    s_simulated[s_idsp] = 0;	/* s_simulator_fp[s_idsp] is not changed */
    return 0;
}

/*I END #include "DSPSimulator.c" */

/****************************************************************************/
#else				/* must define shlib entry points anyway */
int DSPOpenSimulatorFile(char *fn) 
{ 
    fprintf(stderr,"Simulation code not compiled\n"); return -1; 
}

int DSPCloseSimulatorFile(void) 
{ 
    fprintf(stderr,"Simulation code not compiled\n"); return -1; 
}

int DSPStartSimulatorFP(FILE *fp) 
{ 
    fprintf(stderr,"Simulation code not compiled\n"); return -1; 
}

int DSPStartSimulator(void) 
{ 
    fprintf(stderr,"Simulation code not compiled\n"); return -1; 
}

int DSPStopSimulator(void) 
{ 
    fprintf(stderr,"Simulation code not compiled\n"); return -1; 
}
#endif SIMULATOR_POSSIBLE

/* #define s_mode_to_width(x) MIN(x,4) */

static int s_mode_to_width(int mode) {
    int byte_width = 0;	
    switch (mode) {
    case DSP_MODE8:
	byte_width = 1;
	break;
    case DSP_MODE16:
	byte_width = 2;
	break;
    case DSP_MODE24:
	byte_width = 3;
	break;
    case DSP_MODE32:
    case DSP_MODE32_LEFT_JUSTIFIED:
	byte_width = 4;
	break;
    }
    return byte_width;
}


static int s_resetProtocol(char *caller)
{
    if (s_optimizing[s_idsp]) {
	do { s_msg = _DSP_dsp_protocol(s_dspcmd_msg,
				  s_sound_dev_port[s_idsp], 
				  s_dsp_owner_port[s_idsp], 
				  s_dsp_mode_flags[s_idsp]);
	} while (s_checkMsgFrameOverflow(caller)==1);
    } else {
	_DSP_dspcmd_msg_reset(s_dspcmd_msg,
			      s_dsp_hm_port[s_idsp], 
			      PORT_NULL, /* DO NOT request an ack message */
			      s_cur_pri[s_idsp], s_cur_atomicity[s_idsp]);

	s_dspcmd_msg = _DSP_dsp_protocol(s_dspcmd_msg,
					 s_sound_dev_port[s_idsp], 
					 s_dsp_owner_port[s_idsp], 
					 s_dsp_mode_flags[s_idsp]);
	ec = s_msgSend();
	if (ec != KERN_SUCCESS)
	  return _DSPMachError(ec,DSPCat(caller,": "
				"s_msgSend failed."));
    }
#if PROTOCOL_WAS_SET_FN
    snddriver_dsp_protocol_was_set(s_sound_dev_port[s_idsp],
				   s_dsp_owner_port[s_idsp],
				   s_dsp_mode_flags[s_idsp]);
#endif
    return 0;
}

BRIEF int DSPSetComplexDMAModeBit(int bit) 
{
    if (bit && (s_dsp_mode_flags[s_idsp] & SND_DSP_PROTO_C_DMA)) 
      return 0;
    if (!bit && !(s_dsp_mode_flags[s_idsp] & SND_DSP_PROTO_C_DMA)) 
      return 0;
    if (bit) 
      s_dsp_mode_flags[s_idsp] |= SND_DSP_PROTO_C_DMA; /* complex dma mode */
#if 1
    /* FIXME: Clearing C_DMA mode bit causes driver panic? */    
    else 
      s_dsp_mode_flags[s_idsp] &= ~SND_DSP_PROTO_C_DMA; /* simple proto mode */
#endif
    return s_resetProtocol("DSPSetComplexDMAModeBit");
}

/*** NOTE: The host_msg mode flags below must stay in synch with 
  s_setupProtocol() **/


/* 
  Untimed data readback:

  I did things a bit differently from how they are for black hardware.
  In DSPSetHostMessageMode(), for Intel, I set the message mach port
  and just leave it set.  That way, there's no race between setting the
  mach port and an expected message coming from the dsp.  (You didn't
  have this problem on black hardware because there incoming messages
  were buffered in the driver whether or not there was a port to retrieve
  them.)  On intel, you just supply a mach port for messages and messages
  come in on that port until you reset the port to PORT_NULL.  

  There's one assumption I'm making:
  Let's say that the DSP started spewing messages
  (but not errors) and nobody were listening to this port.  This would
  cause the driver to hang waiting for the app to read the messages.
  But this should never happen.  In the current architecture, we only
  listen to the port in the main (or MusicKit) thread and only immediately
  after we have requested (untimed) data.  The only timed readback we
  do is the "awaitEndOfTime", in which case we similarly issue the
  timed request and then wait in a msg_receive() for data.
  Errors don't go through this path--they're handled by the err_reader.
  So the only way the hung driver could happen would be if the DSP started
  sending messages and nobody ever listened to them.  It's my understanding 
  that can never happen.  DAJ. 1/31/96
*/


BRIEF int DSPSetHostMessageMode(void) 
{
    CHECK_INIT;
    if (s_host_msg[s_idsp])
      return 0;
#if m68k
    if (s_mapped_only[s_idsp])
      return 0;
    s_dsp_mode_flags[s_idsp] |= (  SNDDRIVER_DSP_PROTO_DSPMSG 
			 | SNDDRIVER_DSP_PROTO_DSPERR);
    s_host_msg[s_idsp] = 1;
    return s_resetProtocol("DSPSetHostMessageMode");
#endif
#if i386 && defined(NeXT)
    if (DRIVER_SUPPORTS_MESSAGING(s_idsp)) {
	dsp_setMessaging(s_idsp,1);
	dsp_setMsgPort(s_idsp,s_dsp_dm_port[s_idsp]);
	s_host_msg[s_idsp] = 1;
    }
    return 0;
#endif
    return 0;   // keep the compiler happy
}

BRIEF int DSPClearHostMessageMode(void) 
{
    CHECK_INIT;
    if (!s_host_msg[s_idsp])
      return 0;
#if m68k
    s_dsp_mode_flags[s_idsp] &= ~(  SNDDRIVER_DSP_PROTO_DSPMSG 
			  | SNDDRIVER_DSP_PROTO_DSPERR);
    s_host_msg[s_idsp] = 0;
    return s_resetProtocol("DSPClearHostMessageMode");
#endif
#if i386 && defined(NeXT)
    dsp_setMsgPort(s_idsp,PORT_NULL);
    dsp_setMessaging(s_idsp,0);
    s_host_msg[s_idsp] = 0;
    return 0;
#endif
    return 0;   // keep the compiler happy
}

BRIEF int DSPGetProtocol(void) 
{
    CHECK_INIT;
    return s_dsp_mode_flags[s_idsp];
}

BRIEF int DSPSetProtocol(int newProto) 
{
    CHECK_INIT;
    s_dsp_mode_flags[s_idsp] = newProto;
    return s_resetProtocol("DSPSetProtocol");
}

/************************** READING DSP REGISTERS AND DATA *******************/

/*I #include "DSPReadArrays.c" */
/* included by DSPObject.c */

/****************** READING ARRAYS FROM THE DSP HOST INTERFACE ***************/

#if MMAP
/*I #include "DSPReadMapped.c" */
/* included by DSPReadArrays.c */

static int s_readDSPRXArrayModeMapped(
    DSPFix24 *data,		/* array returned from DSP (any type ok) */
    int wordCount,
    int mode)			/* from FIXME */
{
    register int i,j;
    /* 
     * Read the array from the DSP via the memory-mapped interface
     */
    switch (mode) {
    case DSP_MODE8: {
	register unsigned char* c = (unsigned char *)data;
	for (i=0,j=wordCount;j;j--) {
	    while (!RXDF) i += 1;
	    *c++ = s_readRXL();
	} 
    } break;
    case DSP_MODE16: {
	register short* s = (short *)data;
	for (i=0,j=wordCount;j;j--) {
	    while (!RXDF) i += 1;
	    *s++ = s_readRXML();
	} 
    } break;
    case DSP_MODE24: {
	register unsigned char* c = (unsigned char *)data;
	register unsigned int w;
	for (i=0,j=wordCount;j;j--) {
	    while (!RXDF) i += 1;
	    w = s_readRX();
	    *c++ = w & 0xff;
	    *c++ = (w>>8)&0xff;
	    *c++ = (w>>16);
	}
    } break;
    case DSP_MODE32: {
	register unsigned int *p = (unsigned int *)data;
	for (i=0,j=wordCount;j;j--) {
	    while (!RXDF)
	      i += 1;
	    *p++ = s_readRX();
	}
    } break;
    case DSP_MODE32_LEFT_JUSTIFIED: {
	register unsigned int *p = (unsigned int *)data;
	for (i=0,j=wordCount;j;j--) {
	    while (!RXDF)
	      i += 1;
	    *p++ = (((unsigned int)s_readRX()) << 8);
	}
    } break;
    default:
	return _DSPError1(EINVAL,"s_readDSPRXArrayModeMapped: "
			  "Unrecognized data mode = %s",_DSPCVS(mode));
	
    }

    if (i>s_max_rxdf_buzz[s_idsp]) {
	s_max_rxdf_buzz[s_idsp] = i;
	if (_DSPVerbose)
	  _DSPError1(0,"DSPReadArraySkipMode: RXDF wait-count max "
		     "increased to %s",_DSPCVS(s_max_rxdf_buzz[s_idsp]));
    }
    return 0;
}

static int s_readDSPArrayMapped(
    void *data,			/* array returned from DSP (any type ok) */
    int wordCount,
    int mode)			/* from FIXME */
{
    int dspack;
    int dsprp;
    register int i;
    
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],
	      ";; Await R_REQ from DSP, possibly after msgs\n");
#endif SIMULATOR_POSSIBLE
    
    ec = DSPAwaitUnsignedReply(dsp_dm_host_r_req[s_idsp],&dspack,
			       DSPDefaultTimeLimit);
    if (ec)
      return _DSPError(ec,"DSPReadArraySkipMode: "
		       "Timed out waiting for R_REQ from  DSP");
    if (dspack != 0)
      return _DSPError1(DSP_EMISC,"DSPReadArraySkipMode: "
			"Instead of channel 0, got an R_REQ from "
			"DSP on channel %s",_DSPCVS(dspack));
    
    /*
     * After R_REQ, the DSP is waiting for HF1 before it will send
     * anything.  This means there cannot be unread DSP messages.
     */

    if (s_dsp_msgs_waiting[s_idsp]) {
	_DSPError(0,"DSPReadArraySkipMode: There are unread DSP messages "
		  "following a DM_HOST_R_REQ!!! Flushing... ");
	s_dsp_msgs_waiting[s_idsp] = 0; /* DSPFlushMessageBuffer(); */
    }

#if i386 && defined(NeXT)
    dsp_putICR(s_idsp,0x10);
#else
    s_hostInterface->icr = 0x10; /* Set HF1 to enable transfer */
#endif
    
    DSP_UNTIL_ERROR(s_readDSPRXArrayModeMapped(data, wordCount, mode));

    /*
     * Send HOST_R_DONE Host Message
     */
    
    i = 0;		/* cumulative Host Message wait count */
    
    while (!TRDY) i += 1;
    
    /* Exit DMA mode */
#if i386 && defined(NeXT)
    dsp_putCVR(s_idsp,0x80|DSP_HC_HOST_R_DONE);
#else
    s_hostInterface->cvr = (0x80 | DSP_HC_HOST_R_DONE);
#endif
    
    while (HC) i += 1;
    usleep(1);
    while (HF2) i += 1;
    while (!RXDF) i += 1; /* Flush garbage word in RX */
    dsprp = s_readRX();

#if i386 && defined(NeXT)
    dsp_putICR(s_idsp,0);
#else
    s_hostInterface->icr = 0; /* Clear HF1 */
#endif

    /* Read R_DONE DSP message */
    while (1) {
	
	while (!RXDF) i += 1;
	dsprp = s_readRX();
	
	if (DSP_MESSAGE_OPCODE(dsprp) == dsp_dm_host_r_done[s_idsp])
	  break;
	else {
	    char *arg;
	    arg = "DSPReadArraySkipMode: got unexpected DSP message ";
	    arg = DSPCat(arg,DSPMessageExpand(dsprp));
	    arg = DSPCat(arg," while waiting for dsp_hm_host_r_done[s_idsp]");
	    _DSPError(DSP_EMISC,arg);
	}
    }
    return 0;
}

#endif MMAP

int DSPReadMessageArrayMode(void *dataP, int n, int mode)
{
    register int i;
    register DSPFix24 *dp = dataP;
    DSPFix24 d;
    
    for (i=0; i<n; i++)
    {
	if(DSPMessageGet(&d))
	  return i+1;
	switch (mode) {
	case DSP_MODE8:
	    *((char *)dp)++ = d;
	    break;
	case DSP_MODE16:
	    *((short *)dp)++ = d;
	    break;
	case DSP_MODE32_LEFT_JUSTIFIED:
	    *((unsigned int *)dp)++ = (((unsigned int)d)<<8);
	    break;
	case DSP_MODE24:
          #ifdef __LITTLE_ENDIAN__  /* Is this right??? */
	    *(((char *)dp)+2) = ((d>>16)&0xff);
	    *(((char *)dp)+1) = ((d>>8)&0xff);
	    *((char *)dp) = (d&0xff);
	    ((char *)dp) += 3;
	  #else
	    *((char *)dp)++ = ((d>>16)&0xff);
	    *((char *)dp)++ = ((d>>8)&0xff);
	    *((char *)dp)++ = (d&0xff);
	  #endif
	    break;
	case DSP_MODE32:
	default:
	    *((int *)dp)++ = d;
	    break;
	}
    }
    return 0;
}


int DSPReadDataArrayMode(void *dataP, int n, int mode)
{
    /*** FIXME: Make version which does not malloc a dspcmd msg each time.
      Call it _DSP_dsp_read() ***/

    if (s_mapped_only[s_idsp])
      return s_readDSPRXArrayModeMapped(dataP,n,mode);

    if ( s_dsp_mode_flags[s_idsp] & SNDDRIVER_DSP_PROTO_DSPERR )
      return 
	_DSPMachError(ec,"DSPReadDataArrayMode: "
		      "Cannot read data in HostMsg mode. "
		      "(data gets split into message and error streams)");
#if 0
    /* We may have called DSPClearHostMessageMode() as in
       s_readDSPArrayNoDMA().  Thus, we assume we're in the right mode here.
       Need positive way to sense RREQ. */

    if (DSP_CAN_INTERRUPT) {
	ec = DSPReadMessageArrayMode(dataP,n,mode);
	if (ec != KERN_SUCCESS)
	  return _DSPMachError(ec,"DSPReadDataArrayMode: "
			       "DSPReadMessageArrayMode() failed.");
    } else {
#endif
	ec = snddriver_dsp_read_data(s_dsp_hm_port[s_idsp],(void **)&dataP,n,
				     s_mode_to_width(mode),s_cur_pri[s_idsp]);
	if (ec != KERN_SUCCESS)
	  return _DSPMachError(ec,"DSPReadDataArrayMode: "
			       "snddriver_dsp_read_data() failed.");
//  }
    if (mode == DSP_MODE32_LEFT_JUSTIFIED) {
	register int i;
	register int *p = (int *)dataP;
	for (i=n;i;i--)
	  *p++ <<= 8;	
    }	
    return 0;
}


BRIEF int DSPReadDataAndToss(int n)
{
    if (DSP_CAN_INTERRUPT 
	&& (!s_optimizing[s_idsp] 
	    || /* nothing yet placed in optimization group: */
	    (((snd_dspcmd_msg_t *)s_dspcmd_msg)->header.msg_size
	     <= sizeof(snd_dspcmd_msg_t))))
      return _DSPError(0,"DSPReadDataAndToss: "
		       "Only designed to work in RAW mode or in opt group");
    /* We would have to pull the words out of the message buffer 
       and toss them. If optimizing, this will work if messages 
       in the same optimization group before the 'toss' cause the RXDF.
       (The toss occurs before the DSP interrupt is taken.) */
	
    if (s_optimizing[s_idsp]) {
	do { s_msg = _DSP_dsp_read_data(s_dspcmd_msg,1,n);
	 } while (s_checkMsgFrameOverflow("DSPReadDataAndToss")==1);
    } else {
	_DSP_dspcmd_msg_reset(s_dspcmd_msg,
			      s_dsp_hm_port[s_idsp], 
			      PORT_NULL, /* DO NOT request an ack msg */
			      s_cur_pri[s_idsp], s_cur_atomicity[s_idsp]);
	
	s_dspcmd_msg = _DSP_dsp_read_data(s_dspcmd_msg,1,n);
	ec = s_msgSend();
	if (ec != KERN_SUCCESS)
	  return (_DSPMachError(ec,"DSPReadDataAndToss: "
				"s_msgSend failed."));
    }
    return 0;
}
    

int DSPReadRXArrayMode(void *dataP, int n, int mode)
{
    static int warned = 0;

    if ( s_dsp_mode_flags[s_idsp] & SNDDRIVER_DSP_PROTO_DSPERR && !warned) {
	_DSPError(0,"DSPReadRXArrayMode: Warning: "
		  "Attempt to read data from DSP in protocol mode DSPERR. "
		  "Only positive numbers can be read this way. "
		  "Negative 24-bit values will be split out as error msgs.");
	warned = 1;
    }

    if (DSP_CAN_INTERRUPT) {
	DSPAwaitMessages(DSP_TIMEOUT_FOREVER);
	return DSPReadMessageArrayMode(dataP,n,mode);
    } else
      return DSPReadDataArrayMode(dataP,n,mode);
}


BRIEF int _DSPReadData(DSPFix24 *dataP, int *nP)
{
    ec = DSPReadDataArrayMode(dataP,*nP,4);
    if (ec) {
	*nP = ec;
	ec = -1;
    }
    return ec;
}


BRIEF int _DSPReadDatum(DSPFix24 *datumP)
{
    return DSPReadDataArrayMode(datumP,1,4);
}


int DSPReadRXArray(DSPFix24 *data, int nwords)
{  
    return DSPReadRXArrayMode(data, nwords, DSP_MODE32);
}

static int s_specifyDSPArrayRead(
    DSPMemorySpace memorySpace, /* from <dsp/dspstructs.h> */
    int startAddress,		/* within DSP memory */
    int skipFactor)		/* 1 means normal contiguous transfer */
{
    /* Enter DMA mode, DSP-to-host */
    
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],
	      ";; dsp_hm_host_r[s_idsp]: Enter DMA mode, DSP to host\n");
#endif SIMULATOR_POSSIBLE

    DSP_UNTIL_ERROR(DSPCallV(dsp_hm_host_r[s_idsp],
			     3,(int)memorySpace,startAddress,skipFactor));
    
    /*
     * Array will be sent by DSP when sys_call(read) HC occurs & HF1 is set.
     */
    return 0;
}


static int s_readDSPArrayNoDMA(
    void *data,			/* array to read from DSP (any type ok) */
    DSPMemorySpace memorySpace, /* from <dsp/dspstructs.h> */
    DSPAddress startAddress,	/* within DSP memory */
    int skipFactor,		/* 1 means normal contiguous transfer */
    int wordCount,		/* from DSP perspective */
    int mode)			/* from FIXME */
/*
 * Read an array of data from the DSP without using DMA.
 * Assumes s_specifyDSPArrayRead() has NOT been called.
 * We will do it herein in order to read back its ack without
 * leaving a dspcmd_req_msg pending (s_host_message case).
 */
{
    int dspack,oldhm=0;

    if (wordCount <= 0) 
      return 0;
    
    if (s_sound_out[s_idsp] || s_write_data[s_idsp]) 
	return _DSPError(DSP_EPROTOCOL,
			 "DSPObject.c: s_readDSPArrayNoDMA(): Cannot do "
			 "block reads from the DSP during sound-out or "
			 "write-data. Use DSPMKRetValueTimed() instead.");

    /* DSPFlushMessages(); */

    BEGIN_OPTIMIZATION;
    DSP_UNTIL_ERROR(DSPClearHF1());

    if (s_host_msg[s_idsp]) {
	oldhm = 1;
	DSP_UNTIL_ERROR(DSPClearHostMessageMode());
    }	
    DSP_UNTIL_ERROR(s_specifyDSPArrayRead(memorySpace,startAddress,
					  skipFactor));
    /*
     * Issue the "Sys Call" that is normally done by the driver.
     */
    DSP_UNTIL_ERROR(DSPHostCommand(DSP_HC_SYS_CALL));
    DSP_UNTIL_ERROR(DSPWriteTX(0x10000));
    
    if (s_mapped_only[s_idsp]) {
	/*
	 * The switch on s_mapped_only is this high up for performance reasons.
	 */
	ec = s_readDSPArrayMapped(data,wordCount,mode); 
    } else {
	if (oldhm) {		/* may have stuff to flush */
	    END_OPTIMIZATION;
	    /*
	     * FIXME: Need "RX-comparing condition" 
	     * to wait for this in dsp_dev_loop() without us having to block 
	     */
	    ec = DSPAwaitUnsignedReply(dsp_dm_host_r_req[s_idsp],&dspack,
				       DSPDefaultTimeLimit);
	    if (dspack != 0) {
		/* Asynchronous protocol confusion! DSP-initiated read came in! */
		/*** FIXME: Need to to inhibit DSP-initiated reads
		  when not in complex DMA mode. ***/
		DSPHostCommand(DSP_HC_HOST_R_DONE);
		return _DSPError1(DSP_EMISC,"DSPReadArrayNoDMA: "
				  "Instead of channel 0, got an R_REQ from "
				  "DSP on channel %s",_DSPCVS(dspack));
	    }
	    if (ec)
	      return _DSPError(ec,"DSPReadArrayNoDMA: "
			       "Timed out waiting for R_REQ from  DSP");
	} else
	  /* 
	   * else (!oldhm) no need to await R_REQ.
	   * Note that DSP-initiated DMA cannot happen either since
	   * C_DMA mode is not enabled.
	   */
	  ec=DSPReadDataAndToss(1);	/* R_REQ */
	
	DSPSetHF1();		/* Start array coming */
	if (!oldhm) { END_OPTIMIZATION; } /* else already ended it */
	if (ec != KERN_SUCCESS)
	  return _DSPMachError(ec,"s_readDSPArrayNoDMA: s_msgSend failed.");
	ec = DSPReadDataArrayMode((void *)data, wordCount, mode);
	if(ec)
	  return _DSPError(DSP_ESYSHUNG,"s_readDSPArrayNoDMA: "
			   "Could not read DSP array");
	BEGIN_OPTIMIZATION;
	DSPHostCommand(DSP_HC_HOST_R_DONE);
	DSPClearHF1();
	DSPReadDataAndToss(2);
	if (oldhm)
	  DSPSetHostMessageMode();
    }
    END_OPTIMIZATION;
    return ec;
}    


static int bc_dma,ws_dma;

static int s_readDSPArray(
    void **dataPP,		/* array of returned data, possibly alloc'd */
    DSPMemorySpace memorySpace, /* from <dsp/dspstructs.h> */
    int startAddress,		/* within DSP memory */
    int skipFactor,		/* 1 means normal contiguous transfer */
    int wordCount,		/* from DSP perspective */
    int mode)			/* from FIXME */
/*
 * Read array from the DSP using DMA.
 */
{
    int byteCount,paddedByteCount;
    char *dma_data;
    int set_c_dma_proto = 0;
    int bc,wc=0,sc,tbc;
    int bc_done = 0;
    int wds_done = 0;
    
    if (wordCount <= 0)
      return 0;

    /*
     * DMA transfers must be a multiple of 16 bytes.
     */
    ws_dma = s_mode_to_width(mode);

    byteCount = wordCount * ws_dma;
    
    bc_dma = byteCount;
    if (bc_dma & DSP_MIN_DMA_MASK) /* e.g. 0xF */
      bc_dma = (bc_dma & ~DSP_MIN_DMA_MASK) + DSP_MIN_DMA; /* round up */
    paddedByteCount = bc_dma;

    if (!(*dataPP) && bc_dma > DSP_DMA_READ_BUF_SIZE) /* need multiple reads */
      vm_allocate(task_self(),(vm_address_t *)dataPP,
		  bc_dma * sizeof(char), TRUE);	/* enough to cover read */

    /* FIXME - Should turn off DSP messages here to avoid losing them when
     in raw mode (in case going to msg mode after the read or some such) */

    BEGIN_OPTIMIZATION;
    if (!(s_dsp_mode_flags[s_idsp] & SND_DSP_PROTO_C_DMA)) {
	set_c_dma_proto = 1;
	DSPSetComplexDMAModeBit(1); /*** FIXME: Driver should do this 
				      for each UI DMA write as needed ***/
    }
    bc_done = 0;
    wds_done = 0;
    while (bc_dma>0) {

	bc = (bc_dma > DSP_DMA_READ_BUF_SIZE ? DSP_DMA_READ_BUF_SIZE : bc_dma);
	
	switch (mode) {
	case DSP_MODE8:
	    wc = bc;
	    break;
	case DSP_MODE16:
	    wc = bc>>1;
	    break;
	case DSP_MODE24:
	    /*** FIXME: driver should take bytecount ***/
	    sc = bc/(3*DSP_MIN_DMA);
	    /* Compute largest mult. of 3 & DSP_MIN_DMA 
	       < DSP_DMA_READ_BUF_SIZE */
	    tbc = sc*(3*DSP_MIN_DMA);
	    if (bc == bc_dma /* last chunk */ && bc != tbc /* truncated */) {
		sc += 1;	/* round up on last chunk if count truncated */
		tbc += (3*DSP_MIN_DMA);
	    }
	    bc = tbc;
	    wc = sc*DSP_MIN_DMA;
	    break;
	case DSP_MODE32:
	case DSP_MODE32_LEFT_JUSTIFIED:
	    wc = bc>>2;
	    break;
	}
	
	/* DSP_dm_R_REQ on channel 0 (0x50000) happens AFTER DRIVER SYSCALL */
	DSPClearHF1();		/* required! */

	/* FIXME: Won't have to specify each chunk when using simple DMA */
	s_specifyDSPArrayRead(memorySpace,startAddress+wds_done,skipFactor);

	END_OPTIMIZATION;	/* FIXME?  Read in separate thread? */
	ec = snddriver_dsp_dma_read(s_dsp_hm_port[s_idsp],wc,mode, 
				    (void **)(&dma_data));
	BEGIN_OPTIMIZATION;	/* FIXME?  Read in separate thread? */
	    
	if (ec) {
	    _DSPError(ec,"DSPReadArraySkipMode: "
			     "snddriver_dsp_dma_read() failed.");
	    goto early_exit;
	}

	if (*dataPP) {
	    if (bc == bc_dma)	/* last chunk */
	      bcopy((char *)dma_data,(((char *)(*dataPP))+bc_done),
		    bc - (paddedByteCount - byteCount));
	    else
	      bcopy((char *)dma_data,(((char *)(*dataPP))+bc_done),bc);
	    vm_deallocate(task_self(),(vm_address_t)dma_data,(vm_size_t)bc);
	} else {
	    *dataPP = (void *)dma_data;
	    if (bc != bc_dma)
	      fprintf(stderr,"DSPObject.c: s_readDSPArray(): "
		      "reality failure!\n");
	}
	bc_dma -= bc;
	bc_done += bc;
	wds_done += wc;
    }

 early_exit:

    if (set_c_dma_proto)
      DSPSetComplexDMAModeBit(0); /*** FIXME: Driver should do this */
    END_OPTIMIZATION;

    if (mode==DSP_MODE32) {	/* must explicitly right-justify after DMA */
	register int i;
	register int *s = *dataPP;
	for (i=wordCount;i;i--)
	  *s++ >>= 8;
    }

    return ec;
}


int DSPReadNewArraySkipMode(
    void **dataPP,		/* array from DSP ALLOCATED BY KERNEL */
    DSPMemorySpace memorySpace, /* from <dsp/dspstructs.h> */
    int startAddress,		/* within DSP memory */
    int skipFactor,		/* 1 means normal contiguous xfer */
    int wordCount,		/* from DSP perspective */
    int mode)			/* from FIXME */
{
    int use_dma;

    if (wordCount <= 0) 
      return 0;
    
    use_dma = (wordCount >= DSP_MIN_DMA_READ_SIZE) 
      && !s_mapped_only[s_idsp] 
	&& s_do_dma_array_reads[s_idsp]
	  && mode<3;		/* FIXME: mode<4 should work */

    /*
     * There are two ways to read from the DSP without using DMA.
     * (1) read the memory-mapped DSP registers, bypassing the driver.
     * (2) read using the driver, obtaining mapped reads that way too.
     * 
     * Using the driver is slower than doing mapped reads, if DMA is not
     * used, so normally you want to do short reads in mapped mode.
     *
     * If write-data is active,
     * we CANNOT bypass the driver because we cannot distinguish between
     * write-data and our array transfer by just reading the registers.
     * (Write-data is done using a 16-bit true DMA from the DSP.)
     * The reason to support the limited case (1) is that it is fastest
     * when it can be done.
     */

    if (!use_dma) {
	vm_allocate(task_self(),
		    (vm_address_t *)dataPP,
		    wordCount * s_mode_to_width(mode),
		    TRUE);
	return s_readDSPArrayNoDMA(*dataPP,memorySpace,startAddress,
				   skipFactor,wordCount,mode);
    }

#if SIMULATOR_POSSIBLE
    if(s_simulated[s_idsp]) 
      fprintf(s_simulator_fp[s_idsp],
	      ";; Read %d words from %s:$%X:%d:$%X:\n",
	      wordCount,DSPMemoryNames(memorySpace),
	      startAddress,skipFactor,
	      startAddress+skipFactor*wordCount-1);
#endif SIMULATOR_POSSIBLE
    
    if (s_dsp_msgs_waiting[s_idsp]) {
	_DSPError(0,"DSPReadArraySkipMode: Flushing unread messages/data "
		  "from the DSP");
	DSPFlushMessages();
    }

#if SIMULATOR_POSSIBLE
	if (s_simulated[s_idsp])
	  fprintf(s_simulator_fp[s_idsp],
		  ";; Set HF1 and do DMA read, DSP to host\n");
#endif SIMULATOR_POSSIBLE

    ec = s_readDSPArray(dataPP,memorySpace,startAddress,
				   skipFactor,wordCount,mode);

    return ec;
}


int DSPReadArraySkipMode(
    void *dataP,		/* array to read from DSP (any type ok) */
    DSPMemorySpace memorySpace, /* from <dsp/dspstructs.h> */
    int startAddress,		/* within DSP memory */
    int skipFactor,		/* 1 means normal contiguous transfer */
    int wordCount,		/* from DSP perspective */
    int mode)			/* from FIXME */
/*
 * Identical to DSPReadNewArraySkipMode except data not allocated.
 */
{
    int use_dma;
    
    if (wordCount <= 0) 
      return 0;
    
    use_dma = (wordCount >= DSP_MIN_DMA_READ_SIZE) 
      && !s_mapped_only[s_idsp] 
	&& s_do_dma_array_reads[s_idsp]
	  && mode<3;		/* FIXME: mode<4 should work */

    if (!use_dma)
      return s_readDSPArrayNoDMA(dataP,memorySpace,startAddress,
				 skipFactor,wordCount,mode);
    
#if SIMULATOR_POSSIBLE
    if(s_simulated[s_idsp]) 
      fprintf(s_simulator_fp[s_idsp],
	      ";; Read %d words from %s:$%X:%d:$%X:\n",
	      wordCount,DSPMemoryNames(memorySpace),
	      startAddress,skipFactor,
	      startAddress+skipFactor*wordCount-1);
#endif SIMULATOR_POSSIBLE
    
    if (s_dsp_msgs_waiting[s_idsp]) {
	_DSPError(0,"DSPReadArraySkipMode: Flushing unread messages/data "
		  "from the DSP");
	DSPFlushMessages();
    }

#if SIMULATOR_POSSIBLE
	if (s_simulated[s_idsp])
	  fprintf(s_simulator_fp[s_idsp],
		  ";; Set HF1 and do DMA read, DSP to host\n");
#endif SIMULATOR_POSSIBLE

    ec = s_readDSPArray(&dataP,memorySpace,startAddress,
			skipFactor,wordCount,mode);

    return ec;
}
/*I END #include "DSPReadArrays.c" */

/*I #include "DSPReadRegisters.c" */
/* included by DSPObject.c */
/*************************** READING DSP REGISTERS ***************************/

INLINE int _DSPUpdateRegBytesMapped(void)
{
#if i386 && defined(NeXT)
    int i = dsp_getHI(s_idsp);
//    s_icr = dsp_getICR(s_idsp);
//    s_cvr = dsp_getCVR(s_idsp);
//    s_isr = dsp_getISR(s_idsp);
//    s_ivr = dsp_getIVR(s_idsp);
    s_icr = (i >> 24);
    s_cvr = (i >> 16) & 0xFF;
    s_isr = (i >> 8) & 0xFF;
    s_ivr = i & 0xFF;
#else
    s_icr = s_hostInterface->icr & 0xFF;
    s_cvr = s_hostInterface->cvr & 0xFF;
    s_isr = s_hostInterface->isr & 0xFF;
    s_ivr = s_hostInterface->ivr & 0xFF;
#endif
    
    s_regs = s_icr;
#define ADD_BYTE(byte,dest) dest = ((dest<<8)|byte)
    ADD_BYTE(s_cvr,s_regs);
    ADD_BYTE(s_isr,s_regs);
    ADD_BYTE(s_ivr,s_regs);

    return 0;
}

INLINE int _DSPUpdateRegBytesFromRegsInt(void)
{ 
    /* s_regs read via driver... only need to make cached bytes valid */
    s_icr = (s_regs >> 24) & 0xFF;
    s_cvr = (s_regs >> 16) & 0xFF;
    s_isr = (s_regs >>	8) & 0xFF;
    s_ivr = (s_regs	 ) & 0xFF;
    return 0;
}

BRIEF int _DSPReadRegs(void)
{
    int ec;
    
    if (s_mapped_only[s_idsp])
      ec = _DSPUpdateRegBytesMapped();
    else {

	ec = snddriver_dspcmd_req_condition(s_dsp_hm_port[s_idsp],0,0,
					    s_cur_pri[s_idsp],
					    s_dsp_owner_port[s_idsp]);
	/*
	 * Get the reply containing the DSP registers.
	 */
	_DSP_dsprcv_msg_reset(s_dsprcv_msg,
			      s_dsp_hm_port[s_idsp],
			      s_dsp_owner_port[s_idsp]);
	
	ec = msg_receive(s_dsprcv_msg, RCV_TIMEOUT, _DSP_MACH_RCV_TIMEOUT);
	
	if (ec == RCV_TIMED_OUT)
	  return _DSPMachError(ec,"_DSPReadRegs: "
				"Timed out reading DSP regs!");

	if (ec != KERN_SUCCESS)
	  return _DSPMachError(ec,"_DSPReadRegs: msg_receive failed.");

	if (s_dsprcv_msg->msg_id != SND_MSG_DSP_COND_TRUE) /* snd_msgs.h */
	  return (_DSPError1(DSP_EMACH,"_DSPReadRegs: "
			     "Unrecognized msg id %s",
			     _DSPCVS(s_dsprcv_msg->msg_id)));

	s_regs = ((snd_dsp_cond_true_t *)s_dsprcv_msg)->value; /* snd_msgs.h */
    }

    _DSPUpdateRegBytesFromRegsInt();
    
    return 0;
}

BRIEF int DSPReadRegs(unsigned int *regsP)
{
    ec = _DSPReadRegs();
    *regsP = s_regs;
    return ec;
}

unsigned BRIEF int DSPGetRegs(void)
{
    _DSPReadRegs();
    return s_regs;
}

int _DSPPrintRegs(void)
{
    int ec;
    
    ec = _DSPReadRegs();
    
    if (ec)
      return (_DSPError(ec,"_DSPPrintRegs: _DSPReadRegs() failed."));
    
    printf(" icr = 0x%X",(unsigned int)s_icr);
    printf(" cvr = 0x%X",(unsigned int)s_cvr);
    printf(" isr = 0x%X",(unsigned int)s_isr);
    /* printf(" isr = 0x%X",(unsigned int)s_isr); */
    printf("\n");
    
    return 0;
}

BRIEF int DSPReadICR(int *icrP)
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],";; DSPReadICR:\n");
#endif SIMULATOR_POSSIBLE
    
    if (s_mapped_only[s_idsp])
      #if i386 && defined(NeXT)
      s_icr = dsp_getICR(s_idsp);
      #else
      s_icr = s_hostInterface->icr;
      #endif
    else {
	DSP_UNTIL_ERROR(_DSPReadRegs());
    }
    *icrP = s_icr;

#if TRACE_POSSIBLE
    if (_DSPTrace & DSP_TRACE_DSP) 
      printf("\tICR[%d]	 =  0x%X\n",s_idsp,(unsigned int)*icrP);
#endif TRACE_POSSIBLE

    return 0;
}


BRIEF int DSPGetHF0(void)
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],";; DSPGetHF0:\n");
#endif SIMULATOR_POSSIBLE

    if (s_mapped_only[s_idsp])
      #if i386 && defined(NeXT)
      s_icr = dsp_getICR(s_idsp);
      #else
      s_icr = s_hostInterface->icr;
      #endif
    else {
	DSP_UNTIL_ERROR(DSPReadICR(&s_icr));
    }
    return (s_icr&DSP_ICR_HF0)!=0;
}

BRIEF int DSPGetHF1(void)
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],";; DSPGetHF1:\n");
#endif SIMULATOR_POSSIBLE
    
    if (s_mapped_only[s_idsp])
      #if i386 && defined(NeXT)
      s_icr = dsp_getICR(s_idsp);
      #else
      s_icr = s_hostInterface->icr;
      #endif
    else {
	DSP_UNTIL_ERROR(DSPReadICR(&s_icr));
    }
    return (s_icr&DSP_ICR_HF1)!=0;
}

BRIEF int DSPReadCVR(int *cvrP)
{
    if (s_mapped_only[s_idsp])
      #if i386 && defined(NeXT)
      s_cvr = dsp_getCVR(s_idsp);
      #else
      s_cvr = s_hostInterface->cvr;
      #endif
    else {
	DSP_UNTIL_ERROR(_DSPReadRegs());
    }
    *cvrP = s_cvr;
    
#if TRACE_POSSIBLE
    if (_DSPTrace & DSP_TRACE_DSP) 
      printf("\tCVR[%d]	 =  0x%X\n",s_idsp,(unsigned int)*cvrP);
#endif TRACE_POSSIBLE
    
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],";; DSPReadCVR:\n");
#endif SIMULATOR_POSSIBLE
    
    return 0;
}

BRIEF int DSPReadISR(int *isrP)
{
    if (s_mapped_only[s_idsp])
      #if i386 && defined(NeXT)
      s_isr = dsp_getISR(s_idsp);
      #else
      s_isr = s_hostInterface->isr;
      #endif
    else {
	DSP_UNTIL_ERROR(_DSPReadRegs());
    }
    *isrP = s_isr;

#if TRACE_POSSIBLE
    if (_DSPTrace & DSP_TRACE_DSP) 
      printf("\tISR[%d]	 =  0x%X\n",s_idsp,(unsigned int)*isrP);
#endif TRACE_POSSIBLE
    
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],";; DSPReadISR:\n");
#endif SIMULATOR_POSSIBLE
    
    return 0;
}

BRIEF int DSPReadRX(DSPFix24 *wordp)
{
    if (s_mapped_only[s_idsp]) {
        DSPAwaitData(0);        /* 1/30/92/jos */
	*wordp = s_readRX();
	return 0;
    }
    return DSPReadRXArrayMode(wordp, 1, DSP_MODE32); /* DSPReadArrays.c */
}

BRIEF int DSPGetICR(void)
{
    if (s_mapped_only[s_idsp])
      #if i386 && defined(NeXT)
      return dsp_getICR(s_idsp);
      #else
      return s_hostInterface->icr;
      #endif
    else {
	DSP_UNTIL_ERROR(DSPReadICR(&s_icr));
    }
    return s_icr;
}

BRIEF int DSPGetCVR(void)
{
    if (s_mapped_only[s_idsp])
      #if i386 && defined(NeXT)
      return dsp_getCVR(s_idsp);
      #else
      return s_hostInterface->cvr;
      #endif
    else {
	DSP_UNTIL_ERROR(DSPReadCVR(&s_cvr));
    }
    return s_cvr;
}

BRIEF int DSPGetISR(void)
{
    if (s_mapped_only[s_idsp])
      #if i386 && defined(NeXT)
      return dsp_getISR(s_idsp);
      #else
      return s_hostInterface->isr;
      #endif
    else {
	DSP_UNTIL_ERROR(DSPReadISR(&s_isr));
    }
    return s_isr;
}

BRIEF int DSPGetRX(void)
{
    if (s_mapped_only[s_idsp])
      return s_readRX();
    else {
	int rx;
	DSP_UNTIL_ERROR(DSPReadRX(&rx));
	return rx;
    }
}

BRIEF int DSPGetHF2(void)
{
    int isr;			/* Cannot be register */
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],";; Read HF2\n");
#endif SIMULATOR_POSSIBLE
    DSP_UNTIL_ERROR(DSPReadISR(&isr));
    return isr & DSP_ISR_HF2;
}

BRIEF int DSPGetHF3(void)
{
    int isr;			/* Cannot be register */
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],";; Read HF3\n");
#endif SIMULATOR_POSSIBLE
    DSP_UNTIL_ERROR(DSPReadISR(&isr));
    return isr & DSP_ISR_HF3;
}

BRIEF int DSPGetHF2AndHF3(void)
{
    int isr;			/* Cannot be register */
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],";; Read HF3\n");
#endif SIMULATOR_POSSIBLE
    DSP_UNTIL_ERROR(DSPReadISR(&isr));
    return isr & (DSP_ISR_HF3 || DSP_ISR_HF2);
}

/*I END #include "DSPReadRegisters.c" */

/************************** WRITING DSP REGISTERS AND DATA *******************/

/*I #include "DSPWriteArrays.c" */
/* included by DSPObject.c */

/******************** WRITING ARRAYS TO DSP HOST INTERFACE *******************/

static int s_startDSPArrayWrite(
    DSPMemorySpace memorySpace, /* from <dsp/dspstructs.h> */
    int startAddress,		/* within DSP memory */
    int skipFactor)		/* 1 means normal contiguous transfer */
{

#if MMAP
    if (!s_mapped_only[s_idsp]) {
#endif MMAP
	
	ec = DSPCallV(dsp_hm_host_w[s_idsp],
		      3,(int)memorySpace,startAddress,skipFactor);
	if (ec)
	  return _DSPError(ec,"DSPWriteArraySkipMode: s_startDSPArrayWrite: "
			   "DSPCallV(dsp_hm_host_w[s_idsp]) failed.");

#if MMAP
    } else { /* Assumes mapped mode */

	/*
	 * Send HOST_W Host Message
	 */
	
	int i = 0;		/* cumulative Host Message wait count */
	
	while (!TXDE) i += 1;
	TXH = 0;
	TXM = 0;
	TXL = memorySpace;
	SET_TRANSMIT;
	
	while (!TXDE) i += 1;
	TXH = 0;
	TXM = (startAddress>>8) & 0xFF;
	TXL = startAddress & 0xFF;
	SET_TRANSMIT;
	
	while (!TXDE) i += 1;
	TXH = 0;
	TXM = (skipFactor>>8) & 0xFF;
	TXL = skipFactor & 0xFF;
	SET_TRANSMIT;
	
	while (!TXDE) i += 1;
	i = (_DSP_HMTYPE_UNTIMED|DSP_HM_HOST_W);
	TXH = (i>>16) & 0xFF;
	TXM = (i>>8) & 0xFF;
	TXL = i & 0xFF;
	SET_TRANSMIT;

	while (HC) i += 1;
	while (!TRDY) i += 1;
        #if i386 && defined(NeXT)
	dsp_putCVR(s_idsp,0x80 | DSP_HC_XHM);
	#else
	s_hostInterface->cvr = (0x80 | DSP_HC_XHM);
	#endif
	
	/*
	 * Wait until host message is started
	 */
	while (HC) i += 1;
	while (HC) i += 1;	/* Have 320 ns between !HC and HF2 */
	while (HF2) i += 1;
	
	if (i>s_max_hm_buzz[s_idsp]) {
	    s_max_hm_buzz[s_idsp] = i; /* 15 seems typical here */
	    if (_DSPVerbose)
	      _DSPError1(0,"DSPWriteArraySkipMode: s_startDSPArrayWrite: "
			"HM wait-count max increased to %s",
			_DSPCVS(s_max_hm_buzz[s_idsp]));
	}
	ec = 0;
    }
#endif MMAP
    return ec;
}

static int s_finishDSPArrayWrite(void)
{

#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],";; Exit pseudo-dma-write mode in DSP\n");
#endif SIMULATOR_POSSIBLE    

#if MMAP
    if (!s_mapped_only[s_idsp]) {
#endif
	

	ec = DSPHostCommand(DSP_HC_HOST_W_DONE);
	if (ec)
	  return _DSPError(ec,"DSPWriteArraySkipMode: s_startDSPArrayWrite: "
			   "DSPHostCommand(DSP_HC_HOST_W_DONE) failed.");

#if MMAP
    } else { /* Assumes mapped mode */

	/*
	 * Send HOST_W_DONE Host Message
	 */
	
	int i = 0;		/* cumulative Host Message wait count */
	
	while (!TRDY) i += 1;
	
	/* Exit DMA mode */
        #if i386 && defined(NeXT)
	dsp_putCVR(s_idsp,0x80|DSP_HC_HOST_W_DONE);
	#else
	s_hostInterface->cvr = (0x80 | DSP_HC_HOST_W_DONE);
	#endif
	/* don't wait for it */

	ec = 0;
    }
#endif MMAP

    return ec;
}

#if MMAP
/*I #include DSPWriteMapped.c */
/* included by DSPWriteArrays.c */

static int s_writeArraySkipModeMapped(
    DSPFix24 *data,		/* array to send to DSP (any type ok) */
    int wordCount,		/* from DSP perspective */
    int mode)			/* from FIXME */
{
#if i386 && defined(NeXT)
    switch (mode) {
    case DSP_MODE8:
      dsp_putByteArray(s_idsp,(char *)data,wordCount);
      break;
    case DSP_MODE16:
      dsp_putShortArray(s_idsp,(short *)data,wordCount);
      break;
    case DSP_MODE24:
      dsp_putPackedArray(s_idsp,(char *)data,wordCount);
      break;
    case DSP_MODE32:
      dsp_putArray(s_idsp,(int *)data,wordCount);
      break;
    case DSP_MODE32_LEFT_JUSTIFIED:
      dsp_putLeftArray(s_idsp,(int *)data,wordCount);
      break;
    default:
	return _DSPError1(EINVAL,"DSPWriteArraySkipMode: "
			  "Unrecognized data mode = %s",_DSPCVS(mode));
	
    }
#else
    register int i,j,*p=data;
    int dval;
    
    /*
     * Send array down
     */
    switch (mode) {
    case DSP_MODE8: {
	register char* c = (char *)data;
	for (i=0,j=wordCount;j;j--) {
	    while (!TXDE) i += 1;
	    s_writeTXLSigned(c++);
	} 
    } break;
    case DSP_MODE16: {
	register short* s = (short *)data;
	for (i=0,j=wordCount;j;j--) {
	    while (!TXDE) i += 1;
	    s_writeTXMLSigned(s++);
	} 
    } break;
    case DSP_MODE24: {
	register unsigned char* c = (unsigned char *)data;
	unsigned int w;
	for (i=0,j=wordCount;j;j--) {
	    while (!TXDE) i += 1;
          #ifdef __LITTLE_ENDIAN__
	    w = *(c+2);          /* Get high byte */
	    w = (w<<8) | *(c+1); /* Shift and or in middle byte */
	    w = (w<<8) | *c;     /* Get low byte */
	    c += 3;              /* Increment over these 3 bytes */
	  #else
	    w = *c++;
	    w = (w<<8) | *c++;
	    w = (w<<8) | *c++;
	  #endif
	    s_writeTX(&w);
	}
    } break;
    case DSP_MODE32:
	for (i=0,j=wordCount;j;j--) {
	    while (!TXDE) i += 1;
	    s_writeTX(p++);
	} 
	break;
    case DSP_MODE32_LEFT_JUSTIFIED:
	for (i=0,j=wordCount;j;j--) {
	    while (!TXDE) i += 1;
	    dval = (*p++ >> 8);
	    s_writeTX(&dval);
	} 
	break;
    default:
	return _DSPError1(EINVAL,"DSPWriteArraySkipMode: "
			  "Unrecognized data mode = %s",_DSPCVS(mode));
	
    }
    if (i>s_max_txde_buzz[s_idsp]) {
	s_max_txde_buzz[s_idsp] = i;
	if (_DSPVerbose)
	  _DSPError1(0,"DSPWriteArraySkipMode: TXDE wait-count max "
		     "increased to %s",_DSPCVS(s_max_txde_buzz[s_idsp]));
    }
#endif    
    return 0;

}

/*I END #include DSPWriteMapped.c */

#endif

static int s_writeDSPArrayNoDMA(void *dataP, int ndata, int data_width)
{
#if MMAP
    /* If memory-mapped only, write to DSP in mapped mode */
    int ec;
    if (s_mapped_only[s_idsp])
      ec = s_writeArraySkipModeMapped(dataP,ndata,data_width);
    else {
#endif MMAP
	/*
	  The data is sent down atomically to shut out DMA completes
	  while it is trickling in.  A DMA complete INITs the host interface
	  which would clear any data in the DSP host interface pipe.
	  */
	if (s_optimizing[s_idsp]) {
	    do { s_msg = _DSP_dsp_data(s_dspcmd_msg,
				       (pointer_t)dataP, data_width, ndata);
	     } while (s_checkMsgFrameOverflow("s_writeDSPArrayNoDMA")==1);
	} else {
	    _DSP_dspcmd_msg_reset(s_dspcmd_msg,
				  s_dsp_hm_port[s_idsp], 
				  PORT_NULL, s_cur_pri[s_idsp], 1);
	    s_dspcmd_msg = _DSP_dsp_data(s_dspcmd_msg, 
					 (pointer_t)dataP, data_width, ndata);
	    ec = s_msgSend();
	    if (ec != KERN_SUCCESS)
	      return (_DSPMachError(ec,"s_writeDSPArrayNoDMA: "
				    "s_msgSend failed."));
	}
#if MMAP
    }
#endif
    
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) {
	int i;
	fprintf(s_simulator_fp[s_idsp],
		";; s_writeDSPArrayNoDMA: writing %d = 0x%X words to TX\n",
		ndata,ndata);
	if (data_width != 4)
	  fprintf(s_simulator_fp[s_idsp],";;*** DATA WIDTH %d NOT SUPPORTED "
		  "IN SIMULATOR FILES ***\n",data_width);
	for (i=0;i<ndata;i++) 
	  s_simWriteTX(((int *)dataP)[i]); /* write to simulator file */
	fprintf(s_simulator_fp[s_idsp],"\n");
    }
#endif SIMULATOR_POSSIBLE
    
    return 0;
}

int DSPWriteArraySkipMode(
    void *data,			/* array to send to DSP (any type ok) */
    DSPMemorySpace memorySpace, /* from <dsp/dspstructs.h> */
    int startAddress,		/* within DSP memory */
    int skipFactor,		/* 1 means normal contiguous transfer */
    int wordCount,		/* from DSP perspective */
    int mode)			/* from FIXME */
{
    int ec=0;
    int use_dma;
    
    if (wordCount <= 0) 
      return 0;
    
    /* Enter pseudo-DMA mode, host-to-DSP */

    use_dma = (wordCount >= DSP_MIN_DMA_WRITE_SIZE) 
      && !s_mapped_only[s_idsp] 
	&& s_do_dma_array_writes [s_idsp]
	  && mode<3;		/* FIXME: mode<4 should work! 
				   (Make buffer size a multiple of 3*32?) */

    /*
     * There are two ways to write to the DSP without using DMA.
     * (1) write the memory-mapped DSP registers, bypassing the driver.
     * (2) write using the driver, obtaining mapped writes that way also.
     */

    if (!use_dma) {
	int *sdata = 0;
	DSPFix24 *just_data;
	if (mode==DSP_MODE32_LEFT_JUSTIFIED) {
	    register int i;
	    register int *s,*d;
	    sdata = (int *)alloca(wordCount * sizeof(int));
	    for (i=wordCount, s=data, d=sdata; i; i--)
	      *d++ = (*s++ >> 8); /* simulate ljust xfer w rjust xfer */
	    just_data = sdata;
	} else {
	    just_data = data;
	}
	if (mode>2)		/* FIXME */
	  { BEGIN_OPTIMIZATION; }

	s_startDSPArrayWrite(memorySpace,startAddress,skipFactor);
#if 0
	/*** FIXME: Not needed... simulates driver for debugging purposes ***/
	DSP_UNTIL_ERROR(DSPHostCommand(DSP_HC_SYS_CALL));
	DSP_UNTIL_ERROR(DSPWriteTX(0x10000));
	/*** FIXME: Not needed... simulates driver for debugging purposes ***/
#endif
	s_writeDSPArrayNoDMA(just_data,wordCount,s_mode_to_width(mode));
	s_finishDSPArrayWrite();
	if (mode>2)		/* FIXME */
	  { END_OPTIMIZATION; }
    } else {
	/*
	 * Write the array to the DSP via "user-initiated DMA"
	 */
	int ec, *sdata = 0, *dmadata;
	int wsize,byteCount,wc,sentBytes,use_dma_sect,dpdif,nextStart;
	char *dp,*dpa;
	int buf_size_mask = (DSP_DMA_WRITE_BUF_SIZE-1); /* bytes */
	int buf_align_mask = ~buf_size_mask;
	int page_align_mask = ~(vm_page_size-1);
	int min_dma_bytes;
	int set_c_dma_proto = 0;
	
	/*
	 * If the mode is DSP_MODE32 (right-justified), we must
	 * left-justify the data before doing the DMA (sigh).
	 * This is why DSP_MODE32_LEFT_JUSTIFIED was added.
	 * The point is moot at present, however, because the
	 * DMA hardware is unreliable for 32-bit unpacked reads and writes.
	 */
	if (mode==DSP_MODE32) { /* snd_msgs.h */
	    register int i;
	    register int *s,*d;
	    sdata = (int *)alloca(vm_page_size + wordCount * sizeof(int));
	    sdata = (int *)(((int)sdata) & page_align_mask); /* page align */
	    for (i=wordCount, s=data, d=sdata; i; i--)
	      *d++ = (*s++ << 8);
	    dmadata = sdata;
	} else {
	    dmadata = data;
	}
	
	/*
	 * DMA transfers must be buffer aligned and a multiple of 16 bytes.
	 * They cannot cross a page boundary.
	 */

	wsize = s_mode_to_width(mode);
	min_dma_bytes = DSP_MIN_DMA_WRITE_SIZE * wsize;
	byteCount = wordCount * wsize;
	wc = wordCount;

	dp = (char *)dmadata;	/* address of 1st byte to send */
	
	BEGIN_OPTIMIZATION;
	if (!(s_dsp_mode_flags[s_idsp] & SND_DSP_PROTO_C_DMA)) {
	    set_c_dma_proto = 1;
	    DSPSetComplexDMAModeBit(1); /*** FIXME: Driver should do this 
					 for each UI DMA write as needed ***/
	}
	s_startDSPArrayWrite(memorySpace,startAddress,skipFactor);
	nextStart = startAddress;
	while (byteCount>0) {
	    dpa = (char *)((int)dp & buf_align_mask);
	    dpdif = dp-dpa;
	    sentBytes = DSP_DMA_WRITE_BUF_SIZE - dpdif; /* get to buf bdry */
	    if (sentBytes>byteCount)
	      sentBytes = byteCount;
	    use_dma_sect = (sentBytes==DSP_DMA_WRITE_BUF_SIZE);

	    if (mode==2)
	      wc = (sentBytes>>1);
	    else if (mode==1)
	      wc = sentBytes;
	    else if (mode==3)
	      wc = (sentBytes/3);
	    else
	      wc = (sentBytes >> 2);
	    
	    nextStart += wc;

	    if (use_dma_sect) {
		END_OPTIMIZATION; /* FIXME */
		/*
		 * FIXME: Need version which just adds message components. 
		 * But not until PORT_NULL msg_receive bug is fixed. 
		 * Then we can put all writes in the optimization block.
		 */
		ec = snddriver_dsp_dma_write(s_dsp_hm_port[s_idsp],wc,mode,
					     (void *)dp);
		if (ec) {
		    _DSPMachError(ec,"DSPWriteArraySkipMode: Part 2 "
				  "snddriver_dsp_dma_write() failed.");
		    break;
		}
		BEGIN_OPTIMIZATION; /* FIXME */
	    } else {
		END_OPTIMIZATION; /* FIXME: "invalid memory" w last dribble */
		s_writeDSPArrayNoDMA(dp, wc, mode);
		s_finishDSPArrayWrite(); /* FIXME(c): Must act like DMA case */
		BEGIN_OPTIMIZATION; /* FIXME "invalid memory" */
	    }
	    byteCount -= sentBytes;
	    dp += sentBytes;
	    /*
	     * FIXME(c): Because dma_write uses complex DMA mode, the
	     * write has been terminated with a DSP_hc_HOST_WD.
	     * When snddriver_dsp_dma_write_simple() is possible and 
	     * exists, the writes can be issued back to back without
	     * calling s_startDSPArrayWrite() each time.
	     */ 
	    if (byteCount>0) { /* Start write for next section */
		/*** FIXME: Workaround for dspq_check() driver bug in which
		 a programmed write after a DMA write can jump in front of
		 the DMA because the stream enqueuing is so slow. ***/
		DSPAwaitConditionNoBlock(DSP_CVR_HV_REGS_MASK,(0x14<<16));
		s_startDSPArrayWrite(memorySpace,nextStart,skipFactor);
	    }
	}			/* while (byteCount>0) */
	if (set_c_dma_proto)
	  DSPSetComplexDMAModeBit(0); /*** FIXME: Driver should do this ***/
	END_OPTIMIZATION;
    }

    return ec;
}

/*I END #include "DSPWriteArrays.c" */

/*I #include "DSPWriteRegisters.c" */
/* included by DSPObject.c */

/*************************** WRITING DSP REGISTERS ***************************/

BRIEF int DSPWriteRegs(int mask, int value)
{

#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) {
	int oicr,ocvr;
	_DSPReadRegs();
	oicr = s_icr;
	ocvr = s_cvr;
	s_regs |= (mask & value);
	_DSPUpdateRegBytesFromRegsInt();
	if (oicr != s_icr)
	  DSP_UNTIL_ERROR(s_simPrintF(s_simulator_fp[s_idsp], DSP_ICR, s_icr));
	if (ocvr != s_cvr)
	  DSP_UNTIL_ERROR(s_simPrintF(s_simulator_fp[s_idsp], DSP_CVR, s_cvr));
	fprintf(s_simulator_fp[s_idsp],"\n");
    }
#endif SIMULATOR_POSSIBLE    
    
#if MMAP
    if (s_mapped_only[s_idsp]) {
	register unsigned char m,v,c;

	m = (mask >> 24);
	if (m) {
	    v = (value >> 24);
            #if i386 && defined(NeXT)
	    c = dsp_getICR(s_idsp);
	    #else
	    c = s_hostInterface->icr;
	    #endif
	    c &= ~m;		/* clear bits indicated by mask */
            #if i386 && defined(NeXT)
	    dsp_putICR(s_idsp,c|(m&v));
	    #else
	    s_hostInterface->icr = c | (m & v); /* or in bits being set */
	    #endif
	}

	m = (mask >> 16);
	if (m) {
	    v = (value >> 16);
#if i386 && defined(NeXT)
	    c = dsp_getCVR(s_idsp);
#else
	    c = s_hostInterface->cvr;
#endif
	    c &= ~m;		/* clear bits indicated by mask */
#if i386 && defined(NeXT)
	    dsp_putCVR(s_idsp,c|(m&v));
#else
	    s_hostInterface->cvr = c | (m & v); /* or in bits being set */
#endif
	}

	m = (mask >> 8);
	if (m) {
	  fprintf(stderr,"libdsp.a: Attempt to write read-only ISR register "
		  "in the DSP host interface\n");
	}
	
	/* Never need to set IVR */

    } else {
#endif    
	if (s_optimizing[s_idsp]) {
	    do { s_msg = _DSP_dsp_host_flag(s_dspcmd_msg, mask, value);
	    } while (s_checkMsgFrameOverflow("DSPWriteRegs")==1);
	} else {
	    _DSP_dspcmd_msg_reset(s_dspcmd_msg,
				  s_dsp_hm_port[s_idsp], 
#if 0
		  1.0:		  thread_reply(), /* request an ack message */
#else
				  PORT_NULL, /* DO NOT request ack message */
#endif
				  s_cur_pri[s_idsp], DSP_NON_ATOMIC);
	    
	    s_dspcmd_msg = _DSP_dsp_host_flag(s_dspcmd_msg, mask, value);
	    
	    ec = s_msgSend();
	    if (ec != KERN_SUCCESS)
	      return (_DSPMachError(ec,"DSPWriteRegs: s_msgSend failed."));
	    
	}
	/* 7/9/90: 
	   ec = _DSPAwaitMsgSendAck(s_dspcmd_msg); 
	   if (ec)
	   return (_DSPError(ec,"DSPWriteRegs: _DSPAwaitMsgSendAck failed."));
	   */
	
#if MMAP
    }
#endif    
    
    return 0;
}


BRIEF int _DSPPutBit( int bit, int value)
{
    return DSPWriteRegs(bit,(value? bit : 0));
}


BRIEF int _DSPSetBit(int bit)
{
    return DSPWriteRegs(bit,bit);
}


BRIEF int _DSPClearBit(int bit)
{
    return DSPWriteRegs(bit,0);
}


BRIEF int DSPSetHF0(void)
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],";; Set HF0\n");
#endif SIMULATOR_POSSIBLE
    
    return _DSPSetBit(DSP_ICR_HF0_REGS_MASK);
}


BRIEF int DSPClearHF0(void)
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],";; Clear HF0\n");
#endif SIMULATOR_POSSIBLE
    
    return _DSPClearBit(DSP_ICR_HF0_REGS_MASK);
}


BRIEF int DSPSetHF1(void)
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],";; Set HF1\n");
#endif SIMULATOR_POSSIBLE
    
    return _DSPSetBit(DSP_ICR_HF1_REGS_MASK);
}

BRIEF int DSPClearHF1(void)
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],";; Clear HF1\n");
#endif SIMULATOR_POSSIBLE
    
    return _DSPClearBit(DSP_ICR_HF1_REGS_MASK);
}

BRIEF int DSPWriteTX(DSPFix24 word)			
{

#if TRACE_POSSIBLE
    if (_DSPTrace & DSP_TRACE_HOST_INTERFACE)
      printf("\tTX*[%d]	 <-- 0x%X\n", s_idsp,(unsigned int)word);
#endif TRACE_POSSIBLE
    
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],";; DSPWriteTX:\n");
#endif SIMULATOR_POSSIBLE

    return s_writeDSPArrayNoDMA(&word,1,4);
}

int DSPWriteTXArray(DSPFix24 *data, int nwords)
{  
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],";; DSPWriteTXArray:\n");
#endif SIMULATOR_POSSIBLE
    return s_writeDSPArrayNoDMA(data,nwords,4);
}    

int DSPWriteTXArrayB(DSPFix24 *data, int nwords)
{  
    int i;
    DSPFix24 *rdata = (DSPFix24 *) alloca(nwords*sizeof(int));
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],";; DSPWriteTXArrayB:\n");
#endif SIMULATOR_POSSIBLE
    for (i=0;i<nwords;i++)
      rdata[i] = data[nwords-i-1];
    return s_writeDSPArrayNoDMA(rdata,nwords,4);
}    

/*I END #include "DSPWriteRegisters.c" */

/************************ COMMANDS STREAM MANAGEMENT ***********************/

typedef struct { /* Keep in sync with sound library performsound.c */
    	int	sampleCount;
	int	dspBufSize;
	int	soundoutBufSize;
	int	reserved;
/*
 * DSP sound parameters never implemented:
 *	int	soundParameterCount;
 *	int	*soundParameters;
 */
} commandsSubHeader;

int DSPOpenCommandsFile(const char *fn)			
{
//    SNDSoundStruct dummySoundHeader;
    SndSoundStruct dummySoundHeader;
    commandsSubHeader dummySubHeader;
    
    if (s_saving_commands[s_idsp])
        return _DSPError(DSP_EMISC, "Commands file already open");

    if ((s_commands_fd[s_idsp]=open(fn,O_CREAT|O_WRONLY|O_TRUNC,0666))<0)
      return _DSPError1(DSP_EUNIX,
			"DSPObject: Can't open commands output file '%s'",fn);
    if (_DSPVerbose||_DSPTrace)
      printf("\tWriting commands output file:\t%s\n",fn);
    
    /* Write dummy header and subheader to soundfile */
    if (write(s_commands_fd[s_idsp], 
	      (void *)&dummySoundHeader, 
	      sizeof(SndSoundStruct))
	!= sizeof(SndSoundStruct))
      return _DSPError(DSP_EUNIX, 
		       "Could not write initial header to dsp commands file");
    if (write(s_commands_fd[s_idsp], 
	      (void *)&dummySubHeader, 
	      sizeof(commandsSubHeader)) 
	!= sizeof(commandsSubHeader))
      return _DSPError(DSP_EUNIX, "Could not write initial subheader to"
		       " dsp commands file");
    
    s_commands_numbytes[s_idsp] = sizeof(commandsSubHeader);
    s_saving_commands[s_idsp] = 1;
    return 0;
}

int DSPCloseCommandsFile(DSPFix48 *endTimeStamp)
{
    static SndSoundStruct commandsSoundHeader = {
        SND_MAGIC,			/* magic number */
	sizeof(SndSoundStruct),		/* offset to data */
	0,				/* data size (filled in) */
	SND_FORMAT_DSP_COMMANDS,	/* data format */
	0,			        /* sampling rate (filled in) */
	2				/* channel count */
    };
    commandsSubHeader subheader;
    
    /* Write header and subheader to soundfile */
    if (s_saving_commands[s_idsp]) {
	commandsSoundHeader.magic = 
	  NSSwapHostIntToBig(commandsSoundHeader.magic);
	commandsSoundHeader.dataLocation = 
	  NSSwapHostIntToBig(commandsSoundHeader.dataLocation);
	commandsSoundHeader.dataSize = 
	  NSSwapHostIntToBig(s_commands_numbytes[s_idsp]);
	commandsSoundHeader.dataFormat = 
	  NSSwapHostIntToBig(commandsSoundHeader.dataFormat);
        commandsSoundHeader.samplingRate = 
	  NSSwapHostIntToBig((s_srate[s_idsp] == DSPMK_HIGH_SAMPLING_RATE ? 
			      SND_RATE_HIGH : SND_RATE_LOW));
        commandsSoundHeader.channelCount = 
	  NSSwapHostIntToBig(commandsSoundHeader.channelCount);
        lseek(s_commands_fd[s_idsp],0,SEEK_SET);
	if (write(s_commands_fd[s_idsp],
		  (void *)&commandsSoundHeader, 
		  sizeof(SndSoundStruct))
	    != sizeof(SndSoundStruct))
	  return _DSPError(DSP_EUNIX, 
			   "Could not write final header "
			   "to dsp commands file");
	subheader.sampleCount = 
	  NSSwapHostIntToBig(endTimeStamp ? DSPFix48ToInt(endTimeStamp):0);
	subheader.dspBufSize = NSSwapHostIntToBig(s_dsp_buf_wds[s_idsp]);
	subheader.soundoutBufSize = NSSwapHostIntToBig(s_so_buf_bytes[s_idsp]);
	subheader.reserved = 0;
	if (write(s_commands_fd[s_idsp],
		  (void *)&subheader,
		  sizeof(commandsSubHeader)) 
	    != sizeof(commandsSubHeader))
	  return _DSPError(DSP_EUNIX, "Could not write final subheader to"
			   " dsp commands file");
    }
    close(s_commands_fd[s_idsp]);
    s_saving_commands[s_idsp] = 0;
    s_commands_numbytes[s_idsp] = 0;
    s_commands_fd[s_idsp] = -1;
    s_commands_fp[s_idsp] = NULL;
    
    if (_DSPVerbose||_DSPTrace)
      printf("\tCommands output stream closed.\n");
    return 0;
}

/* FIXME: is it useful and safe to start and stop commands file? */
BRIEF int DSPStartCommandsFP(FILE *fp)
{
    if (fp!=NULL) {
	s_commands_fp[s_idsp] = fp;
	s_commands_fd[s_idsp] = fileno(fp);
    }
    if(s_commands_fd[s_idsp]<0)
      return _DSPError(EIO,"DSPStartCommandsFP: Cannot start. "
		       "No open stream");
    s_saving_commands[s_idsp] = 1;
    return 0;
}

BRIEF int DSPStartCommandsFD(int fd)
{
    if(s_commands_fd[s_idsp]<0)
      return _DSPError(EIO,"DSPStartCommandsFP: Cannot start. "
		       "No open stream");
    s_saving_commands[s_idsp] = 1;
    return 0;
}

BRIEF int DSPStopCommands(void)
{
    s_saving_commands[s_idsp] = 0; /* s_commands_fd[s_idsp] is not changed */
    return 0;
}

int _DSPOpenStatePrint()
{
    printf("\nDSP Open State:\n");
    printf("s_sound_dev_port[s_idsp] = %d\n",s_sound_dev_port[s_idsp]);
    printf("s_dsp_hm_port[s_idsp] = %d\n",s_dsp_hm_port[s_idsp]);
    printf("s_dsp_dm_port[s_idsp] = %d\n",s_dsp_dm_port[s_idsp]);
    printf("s_dsp_err_port[s_idsp] = %d\n",s_dsp_err_port[s_idsp]);
    printf("s_dsp_neg_port[s_idsp] = %d\n",s_dsp_neg_port[s_idsp]);
    printf("s_driver_reply_port[s_idsp] = %d\n",s_driver_reply_port[s_idsp]);
    printf("s_wd_stream_port[s_idsp] = %d\n",s_wd_stream_port[s_idsp]);
    printf("s_so_buf_bytes[s_idsp] = %d\n",s_so_buf_bytes[s_idsp]);
    printf("s_dsp_owner_port[s_idsp] = %d\n",s_dsp_owner_port[s_idsp]);
    
    printf("s_simulated[s_idsp] = %d\n",s_simulated[s_idsp]);
    printf("s_simulatorFile[s_idsp] = %s\n",s_simulatorFile[s_idsp]);
    printf("s_simulator_fp[s_idsp] = %d\n",(int)s_simulator_fp[s_idsp]);
    printf("s_saving_commands[s_idsp] = %d\n",(int)s_saving_commands[s_idsp]);
    printf("s_commandsFile[s_idsp] = %s\n",s_commandsFile[s_idsp]);
    printf("s_commands_fd[s_idsp] = %d\n",s_commands_fd[s_idsp]);
    
    printf("s_dsp_count = %d\n",s_dsp_count);
    printf("s_open[s_idsp] = %d\n",s_open[s_idsp]);
    printf("s_mapped_only[s_idsp] = %d\n",s_mapped_only[s_idsp]);
    printf("s_low_srate[s_idsp] = %d\n",s_low_srate[s_idsp]);
    printf("s_sound_out[s_idsp] = %d\n",s_sound_out[s_idsp]);
    printf("s_write_data[s_idsp] = %d\n",s_write_data[s_idsp]);
    printf("s_read_data[s_idsp] = %d\n",s_read_data[s_idsp]);
    printf("s_ssi_sound_out[s_idsp] = %d\n",s_ssi_sound_out[s_idsp]);
    printf("s_ssi_read_data[s_idsp] = %d\n",s_ssi_read_data[s_idsp]);
    printf("s_srate[s_idsp] = %f\n",s_srate[s_idsp]);
    
    printf("s_system_link_file[s_idsp] = %s\n",s_system_link_file[s_idsp]);
    printf("s_system_binary_file[s_idsp] = %s\n",s_system_binary_file[s_idsp]);
    printf("s_idsp = %d\n\n",s_idsp);
    
    return 0;
}

/*************************** DSP SYNCHRONIZATION ***************************/

/*** FIXME: Delete _DSPAwaitMsgSendAck(msg_header_t *msg) ***/

int _DSPAwaitMsgSendAck(msg_header_t *msg)
{    
    int ec;
    
    if (!msg->msg_local_port)
      return (_DSPError(0,"_DSPAwaitMsgSendAck: "
			"no msg_local_port in message for ack"));
    
    _DSP_dsprcv_msg_reset(s_dsprcv_msg,
			  s_dsp_hm_port[s_idsp],
			  msg->msg_local_port);
    ec = msg_receive(s_dsprcv_msg, RCV_TIMEOUT, 10000); /* wait 10 seconds */
    
    if (ec == RCV_TIMED_OUT)
      return (_DSPMachError(ec,"_DSPAwaitMsgSendAck: "
			    "msg_receive timed out after 10 seconds."));
    
    if (ec != KERN_SUCCESS)
      return (_DSPMachError(ec,"_DSPAwaitMsgSendAck: msg_receive failed."));
    
    if (   s_dsprcv_msg->msg_id != SND_MSG_ILLEGAL_MSG
	|| ((snd_illegal_msg_t *)s_dsprcv_msg)->ill_msgid != SND_MSG_DSP_MSG
	|| ((snd_illegal_msg_t *)s_dsprcv_msg)->ill_error != SND_NO_ERROR )
      return (_DSPError1(DSP_EMACH,"_DSPAwaitMsgSendAck: "
			 "msg_id %s in reply not recognized",
			 _DSPCVS(s_dsprcv_msg->msg_id)));
    
    if (((snd_illegal_msg_t *)s_dsprcv_msg)->ill_msgid != msg->msg_id)
      return (_DSPError1(DSP_EMACH,"_DSPAwaitMsgSendAck: "
			 "Got reply to msg_id %s",
			 DSPCat(_DSPCVS(((snd_illegal_msg_t *) 
					 s_dsprcv_msg)->ill_msgid),
				 DSPCat(" instead of msg_id ",
					 _DSPCVS(s_dsprcv_msg->msg_id)))));
    
    return 0;
}

static BOOL (*s_dsp_abortfn)(void) = NULL;

void DSPSetUserAbortedFunction(BOOL (*abortFunc)(void))
{
    s_dsp_abortfn = abortFunc;
}

int _DSPBailOutNow(void)
{
    s_bail_out[s_idsp] = 1;
//    (*s_dsp_user_reset_aborted_function)();
    return DSP_EABORT;
}

BRIEF int DSPAwaitConditionNoBlock(
    int mask,		/* mask to block on as bits in (ICR,CVR,ISR,IVR) */
    int value)		/* 1 or 0 as desired for each 1 mask bit */
{    
    
#if SIMULATOR_POSSIBLE
    if (DSP_IS_SIMULATED_ONLY)
      return 0;
#endif SIMULATOR_POSSIBLE
    
#if MMAP
    if (s_mapped_only[s_idsp])
      return 0;
#endif
    
    if (s_optimizing[s_idsp]) {
	do { 
	    s_msg = _DSP_dsp_condition(s_dspcmd_msg, mask, value);
	} while (s_checkMsgFrameOverflow("DSPAwaitCondition")==1);
    } else {
	_DSP_dspcmd_msg_reset(s_dspcmd_msg,
			      s_dsp_hm_port[s_idsp], 
			      PORT_NULL, /* DO NOT request an ack message */
			      s_cur_pri[s_idsp], s_cur_atomicity[s_idsp]);
	
	s_dspcmd_msg = _DSP_dsp_condition(s_dspcmd_msg, mask, value);
	
	ec = s_msgSend();
	if (ec != KERN_SUCCESS)
	  return (_DSPMachError(ec,"DSPAwaitCondition: s_msgSend failed."));
    }
	
    return 0;
}

BRIEF int DSPAwaitCondition(
    int mask,		/* mask to block on as bits in (ICR,CVR,ISR,IVR) */
    int value,		/* 1 or 0 as desired for each 1 mask bit */
    int msTimeLimit)	/* time limit in milliseconds. 0=>forever */
{    
    int retryCount = 0;
#if SIMULATOR_POSSIBLE
    if (DSP_IS_SIMULATED_ONLY)
      return 0;
#endif SIMULATOR_POSSIBLE
    
#if MMAP
    if (s_mapped_only[s_idsp]) {
	int i=0;
	int tl = msTimeLimit/10;
	while ((msTimeLimit==0) || (i++ < tl) ) {
	    _DSPReadRegs();
	    if ( (s_regs & mask) == value )
	      goto dsp_ready;
#ifndef WIN32
	    select(0,0,0,0,&_DSPTenMillisecondTimer);
#endif

	    /* Nick:  6/5/96 */
	    if (s_dsp_abortfn && (*s_dsp_abortfn)()) /* DAJ/Nick/5/8/96 */
	      return _DSPBailOutNow();
	}
	return _DSPError1(DSP_ETIMEOUT,
		  "DSPAwaitCondition: Timed out waiting for reg bits 0x%s ",
		  _DSPCVHS(mask));
    dsp_ready:
	return 0;
    }
#endif

    if (s_optimizing[s_idsp])
      return _DSPError(DSP_EMISC,
			"DSPAwaitCondition: Cannot call a blocking condition "
			"within an optimization block!  "
			"Use DSPAwaitConditionNoBlock().");

    _DSP_dspcmd_msg_reset(s_dspcmd_msg,
			  s_dsp_hm_port[s_idsp], 
			  PORT_NULL, /* DO NOT request an ack message */
			  s_cur_pri[s_idsp], s_cur_atomicity[s_idsp]);
    /* 
     * Add block spec for desired mask.
     * Note that snddriver_dspcmd_req_condition is very expensive to use here.
     */
    s_dspcmd_msg = _DSP_dsp_condition(s_dspcmd_msg, mask, value);
    
    /* add reply message to be sent when mask comes true */
    s_dspcmd_msg = _DSP_dsp_ret_msg(s_dspcmd_msg, s_driver_reply_msg);
    
    /* 
     * Send the condition-wait message.
     * Note that snddriver_dspcmd_req_condition is too expensive to use here.
     */
    ec = s_msgSend();
    if (ec != KERN_SUCCESS)
      return (_DSPMachError(ec,"DSPAwaitCondition: s_msgSend failed."));
    
    /*
     * Get the reply we've enqueued.
     */
retry:
    s_dsprcv_msg->msg_size = MSG_SIZE_MAX;
    s_dsprcv_msg->msg_local_port = s_driver_reply_port[s_idsp];

    /* Nick/daj:  6/5/96  Broke up msg_receive wait below for abort detection */
//	ec = msg_receive(s_dsprcv_msg, RCV_TIMEOUT, 
//			 (msTimeLimit? msTimeLimit : _DSP_MACH_FOREVER) );
    {
	int foreverTime = msTimeLimit ? msTimeLimit : _DSP_MACH_FOREVER;
	int elapsedTime;
	int timeToWait = foreverTime > 30000 ? foreverTime : 30000; /* 30" */
	for (elapsedTime = 0; elapsedTime < foreverTime; elapsedTime += timeToWait) {
	    ec = msg_receive(s_dsprcv_msg, RCV_TIMEOUT, timeToWait);
	    if (ec != RCV_TIMED_OUT) /* Something valid? */
	      break;
	    if (s_dsp_abortfn && (*s_dsp_abortfn)()) 
	      return _DSPBailOutNow();
	}
    }
	
    /* If we made it here, we timed out on msTimeLimit (or _DSP_MACH_FOREVER) */
    if (ec == RCV_TIMED_OUT) {
      if (s_bail_out[s_idsp])
	return DSP_EABORT;
      if (!msTimeLimit) {  
	  retryCount += 1;
	  /* This can only happen if we time out on _DSP_MACH_FOREVER */
	  goto retry; 
      }
      return _DSPError1(DSP_ETIMEOUT,"DSPAwaitCondition: "
			"Timed out waiting for condition 0x%s",
			DSPCat(_DSPCVHS(DSPGetRegs()),
			       DSPCat(" & 0x",
				      DSPCat(_DSPCVHS(mask),
					     DSPCat(" == 0x",
						    _DSPCVHS(value))))));
    }
    
    if (ec != KERN_SUCCESS)
      return (_DSPMachError(ec,"DSPAwaitCondition: msg_receive failed."));
    
    if (s_dsprcv_msg->msg_id != s_driver_reply_msg->msg_id)
      return (_DSPError1(DSP_EMACH,"DSPAwaitCondition: "
			 "Unrecognized msg id %s",
			 _DSPCVS(s_dsprcv_msg->msg_id)));
    return 0;
}


BRIEF int DSPResumeAwaitingCondition(int msTimeLimit)
{
    if (s_optimizing[s_idsp])
      return _DSPError(DSP_EMISC,
		       "DSPResumeAwaitingCondition: "
		       "Cannot call a blocking condition "
		       "within an optimization block!  ");

    _DSP_dspcmd_msg_reset(s_dspcmd_msg,
			  s_dsp_hm_port[s_idsp], 
			  PORT_NULL, /* DO NOT request an ack message */
			  s_cur_pri[s_idsp], s_cur_atomicity[s_idsp]);
    /*
     * Get the reply we've enqueued using DSPAwaitCondition():
     */
 retry:
    s_dsprcv_msg->msg_size = MSG_SIZE_MAX;
    s_dsprcv_msg->msg_local_port = s_driver_reply_port[s_idsp];
    
    ec = msg_receive(s_dsprcv_msg, RCV_TIMEOUT, 
		     (msTimeLimit? msTimeLimit : _DSP_MACH_FOREVER) );
    
    if (ec == RCV_TIMED_OUT) {
	if (!msTimeLimit)
	  goto retry;
	return DSP_ETIMEOUT;
    }
    
    if (ec != KERN_SUCCESS)
      return _DSPMachError(ec,"DSPResumeAwaitingCondition: "
			   "msg_receive failed.");
    
    if (s_dsprcv_msg->msg_id != s_driver_reply_msg->msg_id)
      return _DSPError1(DSP_EMACH,"DSPResumeAwaitingCondition: "
			 "Unrecognized msg id %s",
			 _DSPCVS(s_dsprcv_msg->msg_id));
    return 0;
}


BRIEF int _DSPAwaitBit(
    int bit,		/* bit to block on as bit in (ICR,CVR,ISR,IVR) */
    int value,		/* 1 or 0 */
    int msTimeLimit)	/* time limit in milliseconds */
{    
    return DSPAwaitCondition(bit,(value? bit : 0),msTimeLimit);
}


BRIEF int DSPAwaitHC(int msTimeLimit)
{
    return DSPAwaitCondition(DSP_CVR_HC_REGS_MASK,0,msTimeLimit);
}


BRIEF int DSPAwaitTRDY(int msTimeLimit)
{
    /* The TRDY bit comes on when all HRX data has been processed by the DSP */
    /* It is defined as TXDE && !HRDF */
    return DSPAwaitCondition((DSP_ISR_TRDY_REGS_MASK),(DSP_ISR_TRDY_REGS_MASK),
			 msTimeLimit);
}


BRIEF int DSPAwaitHostMessage(int msTimeLimit)
{
    DSP_UNTIL_ERROR(DSPAwaitHC(msTimeLimit));	/* First let HC clear */
    
#if (DSP_BUSY != DSP_ISR_HF2 && DSP_BUSY != DSP_ISR_HF3)
    _DSPFatalError(DSP_EMISC,
		   "DSPAwaitHostMessage: DSP_BUSY != DSP_ISR_HF2 or HF3");
#endif
    
    return DSPAwaitCondition(DSP_BUSY_REGS_MASK,0,
			 msTimeLimit); /* Assumed in ISR */
}

BRIEF int DSPAwaitHF3Clear(int msTimeLimit)
{
    return DSPAwaitCondition(DSP_ISR_HF3_REGS_MASK,0,msTimeLimit);
}

BRIEF int _DSPAwaitHF3ClearHF2ClearHCClearTRDYSet(int timeout)
{
  static int hm_mask  = ((DSP_CVR_HC_REGS_MASK)
			 | ((DSP_ISR_TRDY_REGS_MASK
			     | DSP_ISR_HF3_REGS_MASK
			     | DSP_ISR_HF2_REGS_MASK)));
  static int hm_flags = (DSP_ISR_TRDY_REGS_MASK);
  DSP_UNTIL_ERROR(DSPAwaitCondition(hm_mask,hm_flags,timeout));
  return 0;
}

BRIEF int DSPMKFreezeOrchestra(void) /* Freeze orch at "end of cur tick" */
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(DSPGetSimulatorFP(),";; Freeze orchestra loop\n");
#endif SIMULATOR_POSSIBLE
    ec = DSPSetHF0();		/* Pause DSP orchestra loop */
    s_frozen[s_idsp] = 1;
    s_clock_advancing[s_idsp] = 0;
    return ec;
}

BRIEF int DSPMKThawOrchestra(void) /* Freeze orch at "end of current tick" */
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(DSPGetSimulatorFP(),";; Unfreeze (thaw) orchestra loop\n");
#endif SIMULATOR_POSSIBLE
    ec = DSPClearHF0();	/* Unpause DSP orchestra loop */
    s_frozen[s_idsp] = 0;
    return ec;
}

BRIEF int DSPMKPauseSoundOut(void)
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(DSPGetSimulatorFP(),";; Pause sound-out\n");
#endif SIMULATOR_POSSIBLE
    if (s_sound_out[s_idsp])
      ec=snddriver_stream_control(s_wd_stream_port[s_idsp],
				  0,SNDDRIVER_PAUSE_STREAM);
    return ec;
}

BRIEF int DSPMKResumeSoundOut(void)
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(DSPGetSimulatorFP(),";; Unpause (resume) sound-out\n");
#endif SIMULATOR_POSSIBLE
    if (s_sound_out[s_idsp])
      ec=snddriver_stream_control(s_wd_stream_port[s_idsp],
				  0,SNDDRIVER_RESUME_STREAM);
    return ec;
}

/*************************** DSP BREAKPOINT ***************************/

/* The following will probably move to _DSPDebug.c when it exists */

int DSPBreakPoint(int bpmsg)
/*
 * Process DSP breakpoint 
 */
{
/* maximum number of error messages read back after hitting DSP breakpoint */
#define DSP_MAX_BREAK_MESSAGES 32

    int i;
    if(DSP_MESSAGE_OPCODE(bpmsg)!=dsp_de_break[s_idsp])
      return _DSPError1(EINVAL,
			"DSPBreakPoint: Passed invalid DSP breakpoint "
			"message = 0x%s",_DSPCVHS(bpmsg));
    fprintf(stderr,";;*** DSP BREAKPOINT at address 0x%X ***\n",
	    (unsigned int)DSP_MESSAGE_ADDRESS(bpmsg));
    for(i=0;i<DSP_MAX_BREAK_MESSAGES;i++) {
	if (DSPMessageIsAvailable()) {
	    DSPReadRX(&bpmsg); /* Read back DSP 'stderr' messages */
	    fprintf(stderr,";;*** %s\n",DSPMessageExpand(bpmsg));
	}
	else
	  goto gotem;
    }	
    fprintf(stderr,"\n;;*** There may be unread DSP messages ***\n\n");
 gotem:
    fprintf(stderr,"\n;; Use dspabort to prepare DSP for Bug56 'grab'"
	    " or kill this process and reset the DSP in Bug56.\n\n");
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      DSPCloseSimulatorFile();
#endif SIMULATOR_POSSIBLE
    if (s_saving_commands[s_idsp])
      DSPCloseCommandsFile(NULL);
    pause();
    return 0;
}	

/********************** DSP MESSAGES AND DSP ERROR MESSAGES ******************/


static int s_dsp_err_reader(int myDSP)
    /*
     * Function which blocks reading error messages from DSP in its own thread.
     * Called once when the DSP is initialized.
     * Returns 0 unless there was a problem checking for errors.
     */
{
    register int r, rsize, i;
    int err_read_pending = 0;	   /* set when err read request is out */
    static msg_header_t *rcv_msg = 0; /* message frame for msg_receive */

    int kern_ack_op_code = DSP_DE_KERNEL_ACK;
    struct timeval atimeval;       /* Needs to be on a per-DSP basis FIXME */
    int hangDetectionTimeout;      /* Needs to be on a per-DSP basis FIXME */

    #define I_ALIVE_PERIOD ((double)0x8000)  /* Must be in synch with defines.asm */
    #define WAIT_FACTOR ((double)6) /* 
				     * If things don't arrive within this factor
				     * of when they should arrive, we assume
				     * DSP is dead. 
				     */
    hangDetectionTimeout = (I_ALIVE_PERIOD/s_srate[myDSP]) * WAIT_FACTOR + 0.5;
    gettimeofday(&atimeval,NULL);   /* Assume an initial kern_ack */
    s_prev_kern_ack_time[myDSP] = atimeval.tv_sec;

    if (rcv_msg)
      _DSP_FREE_ERROR_MSG(&rcv_msg);
    // free(rcv_msg);
    rcv_msg = _DSP_ALLOC_ERROR_MSG(s_dsp_hm_port[myDSP],s_dsp_err_port[myDSP]);
    
#if m68k
    if (s_mapped_only[myDSP])
      return _DSPError(0,"DSPObject: s_dsp_err_reader: "
		       "no separate error thread in mapped-only mode");
#endif
    /* This needs to be duplicated to loop over all DSPs FIXME */

    while (1) {
	if (!s_open[myDSP])	/* cleared before join and port dealloc */
	  break;
	
#if m68k
	if (s_mapped_only[myDSP])	/* no can do */
	  break;
	
	if (!err_read_pending) { /* request error messages if necessary */
	    r = snddriver_dspcmd_req_err(s_dsp_hm_port[myDSP], 
					 s_dsp_err_port[myDSP]);
	    err_read_pending = 1;
	    if (r != KERN_SUCCESS)
	      return _DSPMachError(r,"DSPObject: s_dsp_err_reader: "
				   "snddriver_dspcmd_req_err failed.");
	}
	
#endif
	_DSP_DSPRCV_MSG_RESET(rcv_msg,s_dsp_hm_port[myDSP],
			      s_dsp_err_port[myDSP]);

	r = msg_receive(rcv_msg, RCV_TIMEOUT, _DSP_ERR_TIMEOUT);
	if (r == KERN_SUCCESS) {/* read error messages and print them to log */
	    DSPFix24 errwd;
	    err_read_pending = 0;
	    rsize = _DSP_ERROR_MSG_COUNT(rcv_msg);
	    for (i=0; i<rsize; i++)  {
                errwd = _DSP_ERROR_MSG(rcv_msg,i);
		if(DSP_MESSAGE_OPCODE(errwd)==dsp_de_break[myDSP])
		  DSPBreakPoint(errwd);
		else {
		    if ((errwd >> 16) == kern_ack_op_code) {
			gettimeofday(&atimeval,NULL);
			s_prev_kern_ack_time[myDSP] = atimeval.tv_sec;
		    }
		    else _DSPError(DSP_EDSP,DSPMessageExpand(errwd));
		}
	    }
	}
	else if (r == RCV_TIMED_OUT) {
	    if (s_clock_advancing[myDSP] && !s_write_data[myDSP] && s_open[myDSP]) {
		gettimeofday(&atimeval,NULL /* &s_timezone (2K of junk) */);
		if (s_clock_just_started[myDSP]) { /* Initialize */
		    s_prev_kern_ack_time[myDSP] = atimeval.tv_sec;
		    s_clock_just_started[myDSP] = 0;
		}
		if ((atimeval.tv_sec - s_prev_kern_ack_time[myDSP]) > 
		    hangDetectionTimeout) {
		    /*** s_bail_out[myDSP] = 1;  
		      This causes sound interruptions after a while? DAJ/Nick 
		     ***/
		}
	    }
	}
	else if (r == RCV_INVALID_PORT) {
	    if (_DSPVerbose && s_open[myDSP])
	      _DSPMachError(r,"DSPObject: "
			    "s_dsp_err_reader(): "
			    "error port gone while DSP open");
	    break;
	}
	else
	  return _DSPMachError(r,"DSPObject: s_dsp_err_reader: "
			       "msg_receive failed.");
    }
//    s_dsp_err_thread[myDSP] = 0;
    return 0;
}

int DSPReadMessages(int msTimeLimit)
{
    register int i;
    int timeout,timeout_progress;

    if (s_dsp_msgs_waiting[s_idsp])
      return 0;			/* Cannot read until existing data consumed */
    
#if MMAP
    if (s_mapped_only[s_idsp]
#if i386 && defined(NeXT)
	&& (!s_host_msg[s_idsp])
#endif
    ) {
	register i = 0;
	register int *dp;
	dp = s_dsp_msg_ptr[s_idsp] = s_dsp_msg_0[s_idsp];
	while (i<128 && RXDF) {		/* 128 is defined in snd_msgs.h */
	    i++;
	    *dp++ = s_readRX();
	    /* select(0,0,0,0,&_DSPTenMillisecondTimer); */
	}
	s_dsp_msg_count[s_idsp] = dp - s_dsp_msg_0[s_idsp];
	s_dsp_msgs_waiting[s_idsp] = (s_dsp_msg_count[s_idsp]>0);
	return !s_dsp_msgs_waiting[s_idsp];
    }
#endif
    
    if (!DSP_CAN_INTERRUPT) { /* read DSP messages in "raw" mode */
	int *dp;		/* cannot be register */
	ec = DSPAwaitCondition((DSP_ISR_RXDF<<8),
			       (DSP_ISR_RXDF<<8),
			       msTimeLimit);
	if (ec != 0)
	  return ec;

	dp = s_dsp_msg_ptr[s_idsp] = s_dsp_msg_0[s_idsp];

	ec = snddriver_dsp_read_data(s_dsp_hm_port[s_idsp],
				     (void **)&s_dsp_msg_ptr[s_idsp],
				     1 /* count */,4 /* width */,
				     s_cur_pri[s_idsp]);
	if (ec != KERN_SUCCESS)
	  return _DSPMachError(ec,"DSPReadMessages: "
			       "snddriver_dsp_read_data() failed.");

	s_dsp_msgs_waiting[s_idsp] = 1;
	s_dsp_msg_count[s_idsp] = 1;

	while (DSPGetISR() & DSP_ISR_RXDF) {
	    if (s_bail_out[s_idsp])
	      return DSP_EABORT;
	    dp++;
	    s_dsp_msg_count[s_idsp]++;
	    ec = snddriver_dsp_read_data(s_dsp_hm_port[s_idsp],
					 (void **)(&dp),
					 1 /* count */,4 /* width */,
					 s_cur_pri[s_idsp]);
	    if (ec != KERN_SUCCESS)
	      return _DSPMachError(ec,"DSPReadMessages: "
				   "snddriver_dsp_read_data() failed.");
	}

    } else {

	if (!s_msg_read_pending[s_idsp]) {
#if i386 && defined(NeXT)
	    dsp_setMsgPort(s_idsp,s_dsp_dm_port[s_idsp]);
#endif

#if m68k
	    ec = snddriver_dspcmd_req_msg(s_dsp_hm_port[s_idsp], 
					  s_dsp_dm_port[s_idsp]);
	    if (ec != KERN_SUCCESS)
	      return _DSPMachError(ec,"DSPReadMessages: "
				   "snddriver_dspcmd_req_msg failed.");
#endif
	    s_msg_read_pending[s_idsp] = 1;
	}
    
    /*
     * We must replace msTimeLimit by succession of small time-outs
     * interspersed with calls to DSPAwakenDriver() to inhibit the
     * classic DSP driver hang.
     */

    timeout_progress = 0;

    retry:
	_DSP_DSPRCV_MSG_RESET(s_dsprcv_msg,
			      s_dsp_hm_port[s_idsp],
			      s_dsp_dm_port[s_idsp]);
	timeout_progress += _DSP_MACH_RCV_TIMEOUT_SEGMENT;
	if (timeout_progress > msTimeLimit) {
	    timeout = msTimeLimit 
	      - (timeout_progress - _DSP_MACH_RCV_TIMEOUT_SEGMENT);
	    timeout_progress =  msTimeLimit;
	} else
	  timeout = _DSP_MACH_RCV_TIMEOUT_SEGMENT;
    
	ec = msg_receive(s_dsprcv_msg, RCV_TIMEOUT, timeout);

	if (ec == KERN_SUCCESS) {
	    register int *dp1,*dp2;
	    if (s_dsprcv_msg->msg_id != SND_MSG_RET_DSP_MSG) {
		if (DSPErrorLogIsEnabled()) { /* _DSPCVS() is a memory leak! */
		    _DSPError1(DSP_EMISC,"got msg %s instead of "
			   "SND_MSG_RET_DSP_MSG", 
			   _DSPCVS(s_dsprcv_msg->msg_id));
		}
		if (s_dsprcv_msg->msg_id == SND_MSG_ILLEGAL_MSG) {
		  if (DSPErrorLogIsEnabled()) { /* _DSPCVS() = memory leak! */
		    _DSPError1(DSP_EMISC,"s_msgSend ack SND_MSG_ILLEGAL_MSG "
			       "to msg %s",_DSPCVS(((snd_illegal_msg_t *)
						      s_dsprcv_msg)->
						     ill_msgid));
		    _DSPError(DSP_EMISC,"We'll retry the msg_receive . . .");
		  }
		  goto retry;
		}	    
		else
		  return DSP_EMACH;
	    }
	    s_dsp_msg_ptr[s_idsp] = s_dsp_msg_0[s_idsp];
	    s_dsp_msg_count[s_idsp] = _DSP_DSPMSG_MSG_COUNT(s_dsprcv_msg);
	    s_dsp_msgs_waiting[s_idsp] = (s_dsp_msg_count[s_idsp]>0);
	    s_msg_read_pending[s_idsp] = 0;
	    dp1 = s_dsp_msg_ptr[s_idsp];
	    dp2 = (int *)&(_DSP_DSPMSG_MSG(s_dsprcv_msg,0));
	    for (i=s_dsp_msg_count[s_idsp];i;i--)
	      *dp1++ = *dp2++;
	} else if (ec == RCV_TIMED_OUT) {
	    if (s_bail_out[s_idsp])
	      return DSP_EABORT;
	    if (timeout_progress <  msTimeLimit) {
		_DSPError(DSP_EMISC,"DSPReadMessages: msg_receive timeout "
			  ". . . ping driver");
		DSPAwakenDriver();
		goto retry;
	    }
	    s_dsp_msgs_waiting[s_idsp] = 0;
	} else
	  return _DSPMachError(ec,"DSPReadMessages: msg_receive failed.");
    }
    return !s_dsp_msgs_waiting[s_idsp];
}

BRIEF int DSPFlushMessages(void)
{
    if (s_host_msg[s_idsp])
      do {
	  s_dsp_msgs_waiting[s_idsp] = 0;
	  DSPReadMessages(1);
      } while (s_dsp_msgs_waiting[s_idsp] && !s_bail_out[s_idsp]);
    /* s_dsp_msg_count[s_idsp] is zero here */
    return 0;
}

BRIEF int DSPFlushMessageBuffer(void)
{
    s_dsp_msgs_waiting[s_idsp] = 0;
    return 0;
}

BRIEF int DSPAwaitMessages(int msTimeLimit)
{
    /* See comment on "untimed data readback" above--DAJ */
#if MMAP
    if (s_mapped_only[s_idsp]
#if i386 && defined(NeXT)
	&& !s_host_msg[s_idsp]
#endif	
    ) {
	int i=0;
	int tl = msTimeLimit/10;
	while (!DSPMessageIsAvailable()) {
	    if (msTimeLimit != 0 && i++ > tl)
	      return _DSPError(DSP_ETIMEOUT,
			       "DSPAwaitMessages: Timed out waiting for RXDF in DSP");
#ifndef WIN32
	    select(0,0,0,0,&_DSPTenMillisecondTimer);
#endif
	    /* Nick:  6/5/96 */
	    if (s_dsp_abortfn && (*s_dsp_abortfn)()) /* Nick/DAJ/5/8/96 */
	      return _DSPBailOutNow();
	}		
	return 0;
    }
#endif
    
#if SIMULATOR_POSSIBLE
    if (DSP_IS_SIMULATED_ONLY)
      return 1;			/* simulate time-out */
#endif SIMULATOR_POSSIBLE
    
    if (s_dsp_msgs_waiting[s_idsp])
      return 0;
    
    if (DSP_CAN_INTERRUPT)
      return DSPReadMessages(msTimeLimit? msTimeLimit : _DSP_MACH_FOREVER);
    else {
	if (DSPGetISR() & DSP_ISR_RXDF)
	  return 0;		/* At least one message is waiting */
	/*** FIXME: Driver should set RREQ automatically when awaiting
	  RXDF.  This is in the bug tracker and was deferred for now. */

	DSPSetHostMessageMode();/* Enabled DSP interrupt on msg available */
	ec = DSPReadMessages(msTimeLimit? msTimeLimit : _DSP_MACH_FOREVER);
	DSPClearHostMessageMode();
    }
    return ec;
}


BRIEF int DSPAwaitData(int msTimeLimit)
{
    /*** FIXME: Need interrupt on RXDF somehow ***/
    int i=0;
    int tl = msTimeLimit/10 + 1;
    if (s_dsp_msgs_waiting[s_idsp])
      return 0;
#if SIMULATOR_POSSIBLE
    if (DSP_IS_SIMULATED_ONLY)
      return 1;			/* simulate time-out */
#endif SIMULATOR_POSSIBLE
    while (DSPDataIsAvailable() == 0) {
	if (msTimeLimit != 0 && i++ > tl)
	  return _DSPError(DSP_ETIMEOUT,
			   "DSPAwaitData: Timed out waiting for RXDF in DSP");
#ifndef WIN32
	select(0,0,0,0,&_DSPTenMillisecondTimer);
#endif
    }		
    return 0;
}
    

BRIEF int DSPAwaitRX(int msTimeLimit)
{
    if(s_host_msg[s_idsp])
      return DSPAwaitMessages(msTimeLimit);
    else
      return DSPAwaitData(msTimeLimit);
}


int _DSPWriteHostMessage(int *hm_array, int nwords)
{
    static int hm_mask  = (DSP_CVR_HC_REGS_MASK) 
      | ((DSP_ISR_TRDY_REGS_MASK 
	  | DSP_ISR_HF3_REGS_MASK 
	  | DSP_ISR_HF2_REGS_MASK));
    static int hm_flags = (DSP_ISR_TRDY_REGS_MASK);
    int tshi=0,tslo=0,old_pri;
    register int hm_type,ec;
    if (s_bail_out[s_idsp])
      return DSP_EABORT;

    if (nwords > dsp_max_hm[s_idsp])	/* dsp.h */
      return _DSPError(DSP_EHMSOVFL,
		       DSPCat(DSPCat("_DSPWriteHostMessage: "
				       "Host message total length = ",
				       _DSPCVS(nwords)),
			       DSPCat(" while maximum is ",
				       _DSPCVS(dsp_max_hm[s_idsp]))));
    /* DSP host message type code */
    hm_type = hm_array[nwords-1] & 0xFF0000;
    if (hm_type != _DSP_HMTYPE_UNTIMED) {
	tshi = hm_array[nwords-3];
	tslo = hm_array[nwords-2];
    }
    
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) {
	DSPTimeStamp ts,*tsp;
	int i;
	if (hm_type == _DSP_HMTYPE_UNTIMED) {
	    tsp = 0;
	} else {
	    tsp = &ts;
	    ts.high24 = tshi;
	    ts.low24 = tslo;
	}
	fprintf(s_simulator_fp[s_idsp],";; _DSPWriteHostMessage: "
		"Await hc~,hf3~,hf2~,trdy == 0x%X in 0x%X,\n"
		";;     and send length %d = 0x%X host msg %s\n",
		hm_flags,hm_mask,nwords,nwords,DSPTimeStampStr(tsp));
	/* write to simulator file */
	for (i=0;i<nwords;i++) 
	  s_simWriteTX(hm_array[i]);
	s_simPrintF(s_simulator_fp[s_idsp], DSP_CVR, 
		    DSP_CVR_HC_MASK|DSP_HC_XHM);
	fprintf(s_simulator_fp[s_idsp],"\n");
    }
#endif SIMULATOR_POSSIBLE

    old_pri = s_cur_pri[s_idsp];

/*  s_cur_pri[s_idsp] = (hm_type==_DSP_HMTYPE_UNTIMED)? DSP_MSG_MED 
    : DSP_MSG_LOW; */
    
    if (hm_type==_DSP_HMTYPE_UNTIMED)
      s_cur_pri[s_idsp] = DSP_MSG_MED;	/* Untimed messages go around TMQ */
    else /* timed absolute or relative */
	if (hm_type==_DSP_HMTYPE_TIMEDA && (tshi == 0 && tslo == 0))
	  s_cur_pri[s_idsp] = DSP_MSG_MED; /* Timed-0 msgs also bypass TMQ */
	else
	  s_cur_pri[s_idsp] = DSP_MSG_LOW; /* True timed messages enqueue */
    
    
    if (s_mapped_only[s_idsp]) {
//	DSP_UNTIL_ERROR(DSPAwaitCondition(hm_mask,hm_flags,
//					  DSP_TIMEOUT_FOREVER));
        _DSPAwaitHF3ClearHF2ClearHCClearTRDYSet(DSP_TIMEOUT_FOREVER);
#if i386 && defined(NeXT)
        /* The following two calls optimized to a single dsp_call()--7/29/95 */
//	DSP_UNTIL_ERROR(s_writeArraySkipModeMapped(hm_array,nwords,4));
//	dsp_executeMKHostMessage(s_idsp);
        dsp_call(s_idsp,(int *)hm_array,nwords);
#else
	DSP_UNTIL_ERROR(s_writeArraySkipModeMapped(hm_array,nwords,4));
	DSP_UNTIL_ERROR(DSPAwaitCondition(hm_mask,hm_flags,
					  DSP_TIMEOUT_FOREVER));
	DSP_UNTIL_ERROR(DSPHostCommand(DSP_HC_XHM));
#endif
    } else {
	/* 
	  Reset dsp command message fields. Host Message must be ATOMIC.
	  This is because a DMA complete will send a hc_host_r_done
	  host message to the DSP.	It this happens while we are in the
	  middle of a host message, all arguments written to the DSP
	  so far will be lost.  Host messages could be made interruptible,
	  but at the price of not being able to check up on the
	  host message handler to see that it consumed the precise number
	  of arguments it should have.  If we assumed the interrupting HM
	  is always correct (only the OS can do it, and only hm_host_r_done
	  can occur this way at present) then we could actually arrange to
	  keep the error checking with some rewrite in jsrlib.asm et al.
	  */
	
	if(!s_sound_out[s_idsp]) { /* Moved from _DSPFlushTMQ(). 7/28/95 */
	    int logstate = DSPErrorLogIsEnabled();
	    DSPDisableErrorLog();
	    _DSPAwaitHF3ClearHF2ClearHCClearTRDYSet(DSP_TIMEOUT_FOREVER);
//        while(_DSPAwaitHF3ClearHF2ClearHCClearTRDYSet(20*_DSP_MACH_DEADLOCK_TIMEOUT))
//        while(DSPAwaitHF3Clear(20*_DSP_MACH_DEADLOCK_TIMEOUT))
//        while(DSPAwaitHF3Clear(10*_DSP_MACH_DEADLOCK_TIMEOUT))
          /* DAJ: Consider smaller timeout here. Can't be too small, though. 
           * 1*_DSP_MACH_DEADLOCK_TIMEOUT wedges the system  FIXME
           */
             ;
	  if (logstate)
	      DSPEnableErrorLog();
	}
	if (s_optimizing[s_idsp] && s_cur_pri[s_idsp]<=old_pri) {
	    /* Elevate atomicity of all message components */
	    ((snd_dspcmd_msg_t *)s_dspcmd_msg)->atomic = DSP_ATOMIC; 
	    do { s_msg = _DSP_dsp_condition(s_dspcmd_msg,hm_mask,hm_flags);
	     } while (s_checkMsgFrameOverflow("_DSPWriteHostMessage")==1);
	    do { s_msg = _DSP_dsp_data(s_dspcmd_msg, (pointer_t)hm_array, 
				       sizeof(int), nwords);
	     } while (s_checkMsgFrameOverflow("_DSPWriteHostMessage")==1);
	    do { s_msg = _DSP_dsp_condition(s_dspcmd_msg,hm_mask,hm_flags);
	     } while (s_checkMsgFrameOverflow("_DSPWriteHostMessage")==1);
	    do { s_msg = _DSP_dsp_host_command(s_dspcmd_msg, DSP_HC_XHM);
	     } while (s_checkMsgFrameOverflow("_DSPWriteHostMessage")==1);
	} else {
	    if (s_optimizing[s_idsp])	/* priority elevation forces flush */
	      ec = s_msgSend();	/* Flush stored message components */
	    
	    _DSP_dspcmd_msg_reset(s_dspcmd_msg,
				  s_dsp_hm_port[s_idsp], PORT_NULL, 
				  s_cur_pri[s_idsp], DSP_ATOMIC);
	    /* 
	      Wait on HF3 now since any long-term block must occur at the
	      beginning of the message.	*** AN ATOMIC MESSAGE MUST
	      NOT BLOCK AFTER IT HAS SENT ANYTHING TO THE DSP.  IT CAN
	      ONLY BLOCK AT THE BEGINNING. *** This is because sound-out
	      DMA packets cannot be terminated while blocked. At the end
	      of a sound-out DMA, the hc_host_r_done host-command must be
	      issued, and HF1 should be cleared.  If an atomic message is
	      in progress, neither will occur, so the DSP will continue
	      sending garbage in DMA mode while the driver has left DMA
	      mode.

	      Here we also wait for HC and HF2 because during a host
	      message execution, HF3 is cleared so that both HF2 and HF3
	      can imply "abort".

	      We block until TRDY since we need it too.
	
	      */

	    s_dspcmd_msg = _DSP_dsp_condition(s_dspcmd_msg,hm_mask,hm_flags);
	    s_dspcmd_msg = _DSP_dsp_data(s_dspcmd_msg, (pointer_t)hm_array, 
					 sizeof(int), nwords);
	    
	    /* Issue "Execute host message" host command to DSP */
	    /*** FIXME:
	      Try eliminating the condition.   In principle, it
	      guarantees all args have been digested (by waiting for TRDY).
	      If interrupts are off in the DSP, and the host command is
	      pending at the same time the above data is pending, the HC
	      will fire first.  However, the DSP hc_xhm handler can be
	      programmed to read all pending data (by directly calling
	      the host_receive handler until HRDF is clear) before processing
	      the host command.  This should allow elimination of the condition
	      which is a significant performance improvement.
	      ***/
	    s_dspcmd_msg = _DSP_dsp_condition(s_dspcmd_msg,hm_mask,hm_flags);
	    s_dspcmd_msg = _DSP_dsp_host_command(s_dspcmd_msg, DSP_HC_XHM);
	    
	    /* Send atomic mach message containing full DSP host message */
	    if (!s_optimizing[s_idsp]) { /* 7/3/91/jos !!! */
		ec = s_msgSend(); /*** FIXME: at least set optimizing to 0!! */
		if (ec)
		  return _DSPMachError(ec,"_DSPWriteHostMessage: "
				       "s_msgSend failed.");
	    }
	}
    }
    s_cur_pri[s_idsp] = old_pri;
    return 0;
}

#if i386 && defined(NeXT)
int DSPAllocDMAChannel(void) {
  /* Returns valid DMA channel or -1 if no more channels for this DSP */
  int i = s_max_dma_chan[s_idsp];
  if (++i > DSPDRIVER_MAX_TRANSFER_CHAN)
    i = DSPMK_RD_DSP_CHAN+1; /* 0,1 and 2 are reserved */
  if (i == s_min_dma_chan[s_idsp])
    return -1;
  else return s_max_dma_chan[s_idsp] = i;
}

void _DSPDeallocDMAChannel(void) {
  int i = s_min_dma_chan[s_idsp];
  if (++i > DSPDRIVER_MAX_TRANSFER_CHAN)
    i = DSPMK_RD_DSP_CHAN+1; /* 0,1 and 2 are reserved */
  s_min_dma_chan[s_idsp] = i;
}
#endif

int DSPMKAwaitEndOfTime(DSPFix48 *aTimeStampP)
     /* Moved by DAJ (11/26/95) from orchControl.m, since it really should 
      * have been in libdsp anyway.
      * However, this may go away for Intel when we use a msg reader
      * thread.  
      */
{
    /* Used to just do this, but it caused hangs: 
       if (DSPMKRetValueTimed(&endTimeStamp,DSP_MS_X,
           DSPMKGetClipCountXAddress(),&nclip))
       */

    int opcode = DSP_HM_PEEK_X;
    int ec;
    DSPAddress address = DSPMKGetClipCountXAddress();
    int msTimeLimit = 250;		/* in milliseconds */
    int vallo,valhi;
    DSPMKCallTimedV(aTimeStampP,opcode,1,address);
    DSPMKFlushTimedMessages();
    while((ec=DSPAwaitUnsignedReply(DSP_DM_PEEK0,&vallo,msTimeLimit)) &&
	   ec != DSP_EABORT)
      DSPAwakenDriver();

    /* should not block, since there should be two words there */
    while((ec=DSPAwaitUnsignedReply(DSP_DM_PEEK1,&valhi,msTimeLimit)) &&
	   ec != DSP_EABORT)
	DSPAwakenDriver();
    return ec;
}

/*************************** DSP Host Commands ***************************/


BRIEF int DSPHostCommand(int cmd)			
{
    static int hm_mask  = (DSP_CVR_HC_REGS_MASK) | 
      ((DSP_ISR_TRDY_REGS_MASK 
	| DSP_ISR_HF3_REGS_MASK 
	| DSP_ISR_HF2_REGS_MASK));

    static int hm_flags = (DSP_ISR_TRDY_REGS_MASK);

    int cvrVal,ec;			/* DSP command vector register */
    
    if (cmd!=(cvrVal=cmd&DSP_CVR_HV_MASK))
      _DSPError(DSP_EMISC,"DSPHostCommand: MSBs of CVR host vector not 0\n");
    
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],
	      ";; DSPHostCommand(0x%X):\n",cmd);
#endif SIMULATOR_POSSIBLE
    
#if MMAP	
    if (s_mapped_only[s_idsp]) {
	cvrVal |= DSP_CVR_HC_MASK; /* Or "HC" bit with command code */
	ec = DSPWriteRegs( 0xFF << 16 , (cvrVal & 0xff) << 16 );
	if (ec && _DSPVerbose)
	  _DSPError1(ec,"DSPHostCommand(0x%s): Could not write CVR",
		     _DSPCVHS(cmd));
    } else {
#endif
#if SIMULATOR_POSSIBLE	
	if (s_simulated[s_idsp]) {
	    s_simPrintF(s_simulator_fp[s_idsp], 
			DSP_CVR, 
			DSP_CVR_HC_MASK | cvrVal);
	    fprintf(s_simulator_fp[s_idsp],"\n");
	}
#endif SIMULATOR_POSSIBLE		
	if (s_optimizing[s_idsp]) {
	    do { s_msg = _DSP_dsp_condition(s_dspcmd_msg,hm_mask,hm_flags);
	    } while (s_checkMsgFrameOverflow("_DSPHostCommand")==1);
	    do { s_msg = _DSP_dsp_host_command(s_dspcmd_msg, cmd);
	    } while (s_checkMsgFrameOverflow("_DSPHostCommand")==1);
	} else {
	    _DSP_dspcmd_msg_reset(s_dspcmd_msg, s_dsp_hm_port[s_idsp], 
				  PORT_NULL, s_cur_pri[s_idsp], DSP_ATOMIC);
	
	    /* New 89jul20/jos */
	    s_dspcmd_msg = _DSP_dsp_condition(s_dspcmd_msg,hm_mask,hm_flags);
	    s_dspcmd_msg = _DSP_dsp_host_command(s_dspcmd_msg, cmd);
	
	    if (ec = s_msgSend())
	      return (_DSPMachError(ec,"_DSPHostCommand: s_msgSend failed."));
	}
#if MMAP	
    }
#endif
    return 0;
}


/****************************** DSPMessage.c ********************************/

/*	DSPMessage.c - Utilities for messages between host and DSP
	Copyright 1987,1988, by NeXT, Inc.

There are two types of message:

	DSP  Message - message from DSP to host (single 24-bit word)
	Host Message - message from host to DSP (several TX args + host cmd)

Modification history:
	07/28/88/jos - Created from _DSPUtilities.c
	08/19/88/jos - Added host message ioctl to DSPCall{V}.
	08/20/88/jos - rewrote DSPHostMessage* et al for atomic host msgs.
	08/21/88/jos - added msTimeLimit (in milliseconds) to every "Await" fn
	08/21/88/jos - changed DSPDataAvailable to DSPDataIsAvailable.
	08/21/88/jos - converted to procedure prototypes.
	08/13/88/gk  - changed _DSPSendHmStruct() to _DSPWriteHm() using write.
		       KEEP DSPMessage.h UP TO DATE !!!!
	11/20/89/daj - changed _DSPCallTimedV() to write arguments backwards 
		       onto TMQ. (To match DSPMKCallTimed())
		       Also replaced DSP_MALLOC with alloca() for speed. 
		       (see DAJ comments)
	02/17/89/jos - added check to _DSPWriteHm() to return if DSP not open
	02/19/89/jos - moved DSPDataIsAvailable and DSPAwaitData to DSPObject
	03/23/89/jos - placed call to DSPReadErrors in _DSPWriteHM().
	03/24/89/jos - rewrote hm_array usage for faster service
	06/19/89/jos - flushed curTime for better optimization
	06/19/89/jos - flushed s_mapped_only support in DSPMKFlushTimed...
	06/19/89/jos - took out s_simulated tests below DSPMKFlushTimed...
	03/1/93/daj - vectorized hm_array, etc. and added wait for TRDY in 
	               DSPHostCommand()
*/
 
//#import <sys/time.h>		/* DSPAwaitData(), DSPMessageGet() */  // LMS is this neccessary?
				/*     DSPAwaitUnsignedReply() */
#import <stdarg.h>

/**************************** DSP MESSAGES *********************************/

BRIEF int DSPMessagesOff(void)
/* 
 * Turn off DSP messages at the source.
 */
{

    /* Turn off DSP messages. The DSP will not try to send any more. */
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],";; Turn off DSP messages\n");
#endif SIMULATOR_POSSIBLE
    DSP_UNTIL_ERROR(DSPHostMessage(dsp_hm_dm_off[s_idsp]));
    
    if (s_mapped_only[s_idsp]) {
#if SIMULATOR_POSSIBLE
	if (s_simulated[s_idsp])
	  fprintf(s_simulator_fp[s_idsp],
		  ";; Await ack for DSP messages off\n");
#endif SIMULATOR_POSSIBLE
	/* Read up to two pending DSP messages in the host interface regs. */
	DSP_UNTIL_ERROR(DSPAwaitMessage(dsp_dm_dm_off[s_idsp],
					DSPDefaultTimeLimit));
    }

    s_dsp_messages_disabled[s_idsp] = 1;

    return 0;
}

BRIEF int DSPMessagesOn(void)
/* 
 * Enable DSP messages.
 */
{

    s_dsp_messages_disabled[s_idsp] = 0;
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],";; Turn on DSP messages\n");
#endif SIMULATOR_POSSIBLE
    DSP_UNTIL_ERROR(DSPHostMessage(dsp_hm_dm_on[s_idsp]));
    if (s_mapped_only[s_idsp]) {
#if SIMULATOR_POSSIBLE
	if (s_simulated[s_idsp])
	  fprintf(s_simulator_fp[s_idsp],";; Await ack for DSP messages on\n");
#endif SIMULATOR_POSSIBLE
	DSP_UNTIL_ERROR(DSPAwaitMessage(dsp_dm_dm_on[s_idsp],
					DSPDefaultTimeLimit));
    }
    return 0;
}


static int s_readDSPMessage(DSPFix24 *datumP)
{
    if (s_dsp_msgs_waiting[s_idsp]) {
	*datumP = *s_dsp_msg_ptr[s_idsp]++;
	if (s_dsp_msg_ptr[s_idsp] 
	    >=  s_dsp_msg_0[s_idsp] 
	    + s_dsp_msg_count[s_idsp]) {
	    s_dsp_msgs_waiting[s_idsp] = 0;
	    if (s_host_msg[s_idsp])
	      DSPReadMessages(1); /* initiate next read, but don't wait */
	}
    }
    else 
      return -1;
    
    /* The purpose of explicit reads is to synch with HM_HOST_R_DONE */

#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      s_simReadRX(*datumP);
#endif SIMULATOR_POSSIBLE
    
#if TRACE_POSSIBLE
    if (_DSPTrace & DSP_TRACE_DSP) 
      printf("\tRX [%d]	 =  0x%X\n",s_idsp,(unsigned int)*datumP);
#endif TRACE_POSSIBLE
    
    return 0;
}


BRIEF int DSPMessageGet(int *msgp)
{
    if (s_bail_out[s_idsp])
      return DSP_EABORT;
    if (s_dsp_messages_disabled[s_idsp])
      return _DSPError(DSP_EPROTOCOL,
		       "DSPGetMessage: DSP Messages are turned off");

    if (!s_dsp_msgs_waiting[s_idsp])
      if (DSPReadMessages(DSPDefaultTimeLimit?
		      DSPDefaultTimeLimit:_DSP_MACH_FOREVER))
	return DSP_ENOMSG;
    
    if (s_readDSPMessage(msgp)) /* Read back DSP message */
      return DSP_ENOMSG;
    else
      return 0;
}


BRIEF int DSPAwaitAnyMessage(
    int *dspackp,		/* returned DSP message */
    int msTimeLimit)		/* time-out in milliseconds */
/*
 * Await any message from the DSP.
 */
{
    /* DAJ: Consider looping until other than KERNEL_ACK here. 
       if (DSP_MESSAGE_OPCODE(dspack) != DSP_DM_KERNEL_ACK) 
       FIXME 
       */

    DSPMKFlushTimedMessages();
    if(ec=DSPAwaitMessages(msTimeLimit))
      return _DSPError(ec,"DSPAwaitAnyMessage: DSPAwaitMessages() failed.");
    if(ec=DSPMessageGet(dspackp))
      return _DSPError(ec,"DSPAwaitAnyMessage: "
			   "DSPMessageGet() failed after DSPAwaitMessages() "
			   "returned successfully.");
    return 0;
}

int DSPAwaitUnsignedReply(
    DSPAddress opcode,	       /* opcode of expected DSP message */
    DSPFix24 *datum,	       /* datum of  expected DSP message (returned) */
    int msTimeLimit)	       /* time-out in milliseconds */
/* 
 * Wait for specific DSP message containing an unsigned datum.
 */
{
    int dspack;

    while (1) {
	/* SimulatorOnly or CommandsOnly => error */
	DSP_UNTIL_ERROR(DSPAwaitAnyMessage(&dspack,msTimeLimit)); 
	if (DSP_MESSAGE_OPCODE(dspack)==opcode)
	  break;
	else { 
	    char *arg;
	    arg = "DSPAwaitUnsignedReply: got unexpected DSP message ";
	    arg = DSPCat(arg,DSPMessageExpand(dspack));
	    arg = DSPCat(arg," while waiting for ");
	    arg = DSPCat(arg,DSPMessageExpand(opcode<<16));
	    _DSPError(DSP_EMISC,arg);
	}
    }
    *datum = DSP_MESSAGE_UNSIGNED_DATUM(dspack);
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],
	      ";; DSP reply = %s\n\n",DSPMessageExpand(dspack));
#endif SIMULATOR_POSSIBLE
    return 0;
}

BRIEF int DSPAwaitSignedReply(
    DSPAddress opcode,	    /* opcode of expected DSP message */
    int *datum,		    /* datum of	 expected DSP message (returned) */
    int msTimeLimit)	    /* time-out in milliseconds */
/* 
 * Wait for specific DSP message containing a signed datum.
 */
{
    int ec;
    ec = DSPAwaitUnsignedReply(opcode,datum,msTimeLimit);
    *datum = DSP_MESSAGE_SIGNED_DATUM(*datum);
    return ec;
}

BRIEF int DSPAwaitMessage(
    DSPAddress opcode,		/* opcode of expected DSP message */
    int msTimeLimit)		/* time-out in milliseconds */
/* 
 * Return succesfully on specified DSP message 
 */
{
    int dspack;			/* unneeded opcode */
    return DSPAwaitUnsignedReply(opcode,&dspack,msTimeLimit);
}

BRIEF int _DSPForceIdle(void) 
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(s_simulator_fp[s_idsp],";; Force DSP into IDLE state \n");
#endif SIMULATOR_POSSIBLE
    DSP_UNTIL_ERROR(DSPHostMessage(dsp_hm_idle[s_idsp]));
    return DSPAwaitMessage(dsp_dm_idle[s_idsp],DSPDefaultTimeLimit);
}

/****************************** HOST MESSAGES *******************************/

/* See $DSP/doc/host-messages for documentation */

/* This struct is used to send a host message to the DSP atomically */

#if 0
static int *hm_array = 0;
static int hm_ptr;
#endif

BRIEF int DSPHostMessage(int msg)		
/* 
 * Issue untimed DSP "host message" (minus args) by issuing "xhm" 
 * host command.
 */
{
    return DSPMKHostMessageTimed(DSPMK_UNTIMED,msg);
}

BRIEF int DSPMKHostMessageTimedFromInts(
    int msg,	      /* Host message opcode. */
    int hiwd,	      /* High word of time stamp. */
    int lowd)	      /* Lo   word of time stamp. */
{
    DSPFix48 aTimeStamp = {hiwd,lowd};
    return DSPMKHostMessageTimed(&aTimeStamp,msg);
}    

/************************** TIMED HOST MESSAGES *****************************/

int DSPMKHostMessageTimed(DSPFix48 *aTimeStampP, int msg)
{
    int ec;
    if (s_bail_out[s_idsp])
      return DSP_EABORT;

#if TRACE_POSSIBLE
    if (_DSPTrace & DSP_TRACE_HOST_MESSAGES)
      printf("Host message = 0x%X %s\n",(unsigned int)msg,
	     DSPTimeStampStr(aTimeStampP));
#endif TRACE_POSSIBLE

#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(s_simulator_fp[s_idsp],
	      ";; DSPMKHostMessageTimed(0x%X) %s:\n",msg,
	      DSPTimeStampStr(aTimeStampP));
#endif SIMULATOR_POSSIBLE

    if ( msg < dsp_hm_first[s_idsp] || msg > dsp_hm_last[s_idsp] )
      return _DSPError1(EDOM,"DSPMKHostMessageTimed: "
			    "opcode = 0x%s is too large",
			    _DSPCVHS(msg));
    if (s_mapped_only[s_idsp]) {
	/* put time stamp */
//	_DSPCheckTMQFlush(aTimeStampP,0); /* Added Oct. 10, 1994 */
        _DSPFlushTMQ();  /* Added Oct. 10, 1994 */
	_DSPAwaitHF3ClearHF2ClearHCClearTRDYSet(DSP_TIMEOUT_FOREVER);
//        DSP_UNTIL_ERROR(DSPAwaitCondition(hm_mask,hm_flags,
//                                          DSP_TIMEOUT_FOREVER));
#if i386 && defined(NeXT)
        if (aTimeStampP!=DSPMK_UNTIMED) {
	  dsp_executeMKTimedMessage(s_idsp,DSP_FIX24_CLIP(aTimeStampP->high24),
				    DSP_FIX24_CLIP(aTimeStampP->low24),
				    _DSP_HMTYPE_TIMEDA | msg);
	} else dsp_executeMKTimedMessage(s_idsp,-1,-1,
					 _DSP_HMTYPE_UNTIMED | msg);
	ec = 0;
#else
	if (aTimeStampP!=DSPMK_UNTIMED) {
	    DSP_UNTIL_ERROR(DSPWriteTX(DSP_FIX24_CLIP(aTimeStampP->high24))); 
	    DSP_UNTIL_ERROR(DSPWriteTX(DSP_FIX24_CLIP(aTimeStampP->low24))); 
	}

	/* put opcode */
	DSP_UNTIL_ERROR(DSPWriteTX((aTimeStampP==DSPMK_UNTIMED?
			     _DSP_HMTYPE_UNTIMED :_DSP_HMTYPE_TIMEDA)
			     | msg ));

        DSP_UNTIL_ERROR(DSPAwaitTRDY(DSP_TIMEOUT_FOREVER));
//	while (!TRDY) i += 1;
	/* issue host command */
	ec = DSPHostCommand(DSP_HC_XHM); /* xhm host command */
#endif
    } else
      ec = DSPMKCallTimed(aTimeStampP,msg,0,0);
    
    if (ec)
      _DSPError1(ec,
		 "DSPMKHostMessageTimed: Could not issue host message 0x%s",
		 DSPCat(_DSPCVHS(msg),DSPTimeStampStr(aTimeStampP)));
    return ec;
}


BRIEF int _DSPStartHmArray(void)
{
    s_hm_ptr[s_idsp] = 0;
    return 0;
}


BRIEF int _DSPExtendHmArray(DSPFix24 *argArray, int nArgs)
{
    int i;
    int *hm_array = s_hm_array[s_idsp];
    int hm_ptr = s_hm_ptr[s_idsp];
    for (i=0; i<nArgs; i++)  hm_array[hm_ptr++] = argArray[i];
    s_hm_ptr[s_idsp] = hm_ptr;
    return 0;
}

int _DSPExtendHmArrayMode(void *argArray, int nArgs, int mode)
/*
 * Add arguments to a host message (for the DSP).
 * Add nArgs elements from argArray to hm_array.
 * Mode codes are discussed in DSPObject.h(DSPWriteArraySkipMode).
 */
{
    int i,j;
    int *hm_array = s_hm_array[s_idsp];
    int hm_ptr = s_hm_ptr[s_idsp];
    switch (mode) {
    case DSP_MODE8: {
	register unsigned char* c = (unsigned char *)argArray;
	for (i=0,j=nArgs;j;j--)
	  hm_array[hm_ptr++] = *c++;
    } break;
    case DSP_MODE16: {
	register short* s = (short *)argArray;
	for (i=0,j=nArgs;j;j--)
	  hm_array[hm_ptr++] = *s++;
    } break;
    case DSP_MODE24: {
	register unsigned char* c = (unsigned char *)argArray;
	register unsigned int w;
	for (i=0,j=nArgs;j;j--) {
          #ifdef __LITTLE_ENDIAN__
	    w = *(c+2);          /* Get high byte */
	    w = (w<<8) | *(c+1); /* Shift and or in middle byte */
	    w = (w<<8) | *c;     /* Get low byte */
	    c += 3;              /* Increment over these 3 bytes */
	  #else
	    w = *c++;
	    w = (w<<8) | *c++;
	    w = (w<<8) | *c++;
	  #endif
	    hm_array[hm_ptr++] = w;
	}
    } break;
    case DSP_MODE32: {
	register DSPFix24* p = (DSPFix24 *)argArray;
	for (i=0,j=nArgs;j;j--)
	  hm_array[hm_ptr++] = *p++;
    } break;
    case DSP_MODE32_LEFT_JUSTIFIED: {
	register DSPFix24* p = (DSPFix24 *)argArray;
	for (i=0,j=nArgs;j;j--)
	  hm_array[hm_ptr++] = (*p++ >> 8);
    } break;
    default: 
	return _DSPError1(EINVAL,"_DSPExtendHmArrayMode: "
			  "Unrecognized data mode = %s",_DSPCVS(mode));
    }
    s_hm_ptr[s_idsp] = hm_ptr;
    return 0;
}

BRIEF int _DSPExtendHmArrayB(DSPFix24 *argArray, int nArgs)
{
    int i;
    int *hm_array = s_hm_array[s_idsp];
    int hm_ptr = s_hm_ptr[s_idsp];
    for (i=nArgs-1; i>=0; i--)	hm_array[hm_ptr++] = argArray[i];
    s_hm_ptr[s_idsp] = hm_ptr;
    return 0;
}


BRIEF int _DSPFinishHmArray(DSPFix48 *aTimeStampP, DSPAddress opcode)
{
    int timed = ( aTimeStampP == DSPMK_UNTIMED ? 0 : 1 );
    int pfx = ( timed ? _DSP_HMTYPE_TIMEDA : _DSP_HMTYPE_UNTIMED );

    if (timed) {		/* install time stamp */
	s_hm_array[s_idsp][(s_hm_ptr[s_idsp])++] = DSP_FIX24_CLIP(aTimeStampP->high24); 
	s_hm_array[s_idsp][(s_hm_ptr[s_idsp])++] = DSP_FIX24_CLIP(aTimeStampP->low24); 
    }

    s_hm_array[s_idsp][(s_hm_ptr[s_idsp])++] = pfx | opcode; 
    /* host message type and opcode */

    return 0;
}


BRIEF int _DSPWriteHm(void)
{
    int ec;

// #if MMAP
#if 0
    if (s_mapped_only[s_idsp]) {
	int i;
	if (ec = DSPWriteTXArray(s_hm_array[s_idsp],s_hm_ptr[s_idsp]))
	  return _DSPError(DSP_EMISC,"_DSPWriteHm: host msg args failed");
	while (!TRDY) i += 1; /* Added by DAJ. March 8, 1993 */
	if (ec = DSPHostCommand(DSP_HC_XHM)) /* xhm host command */
	  return _DSPError(DSP_EMISC,"_DSPWriteHm: host command failed");
    } else {
#endif
	if (ec = _DSPWriteHostMessage(s_hm_array[s_idsp], s_hm_ptr[s_idsp]))
	  return _DSPError1(ec,
			    "_DSPWriteHm: _DSPWriteHostMessage failed for "
			    "message 0x%s", _DSPCVHS(s_hm_array[s_idsp][s_hm_ptr[s_idsp]-1]));
#if 0
// #if MMAP
    }
#endif
    return 0;
}
    

BRIEF int _DSPCallTimedMaybeB(
    DSPFix48 *aTimeStampP,
    DSPAddress hm_opcode,
    int nArgs,
    DSPFix24 *argArray,
    int reverse)
/*
 * Low-level routine for sending timed host messages to the DSP.
 * Called when the buffer of timed messages for the same time stamp
 * is flushed.
 */
{
    if (s_bail_out[s_idsp])
      return DSP_EABORT;
    s_hm_ptr[s_idsp] = 0;		/* no host message arguments yet written */

    if (reverse)
      _DSPExtendHmArrayB(argArray,nArgs);
    else
      _DSPExtendHmArray(argArray,nArgs);

    _DSPFinishHmArray(aTimeStampP,hm_opcode);

    return _DSPWriteHostMessage(s_hm_array[s_idsp],s_hm_ptr[s_idsp]);
    /* If moved back to separate file: return _DSPWriteHm(); */
}


BRIEF int DSPCall(
    DSPAddress hm_opcode,
    int nArgs,
    DSPFix24 *argArray)
/*
 * Send an untimed host message to the DSP.
 */
{
    return _DSPCallTimedMaybeB(DSPMK_UNTIMED,hm_opcode,nArgs,argArray,FALSE);
}	


BRIEF int DSPCallB(
    DSPAddress hm_opcode,
    int nArgs,
    DSPFix24 *argArray)
/*
 * Same as DSPCall() except that the argArray is sent in reverse
 * order to the DSP.
 */
{
    return _DSPCallTimedMaybeB(DSPMK_UNTIMED,hm_opcode,nArgs,argArray,TRUE);
}	


BRIEF int _DSPCallTimedFlush(
    DSPFix48 *aTimeStampP,
    DSPAddress hm_opcode,
    int nArgs,
    DSPFix24 *argArray)
/*
 * Send a timed host message without accumulating messages for
 * the same time into a single buffer before sending.
 */
{
    return _DSPCallTimedMaybeB(aTimeStampP,hm_opcode,nArgs,argArray,FALSE);
}	

BRIEF int _DSPCallTimedFlushB(
    DSPFix48 *aTimeStampP,
    DSPAddress hm_opcode,
    int nArgs,
    DSPFix24 *argArray)
/*
 * Same as DSPMKCallTimed() except that the argArray is sent in reverse
 * order to the DSP.
 */
{
    return _DSPCallTimedMaybeB(aTimeStampP,hm_opcode,nArgs,argArray,TRUE);
}	


int _DSPCallTimedFlushV(DSPFix48 *aTimeStampP,DSPAddress hm_opcode,
			int nArgs,...)
/*
 * Usage is _DSPCallTimedFlushV(aTimeStampP,hm_opcode,N,arg1,...,ArgN);
 * Same as _DSPCallTimedFlush() except that a variable number of arguments 
 * is specified explicitly (using stdarg) rather than being passed in an
 * array.
 */
{
    va_list ap;
    int i;

    va_start(ap,nArgs);

    if (s_mapped_only[s_idsp]) {
	DSPFix24 *argArray;
	argArray = (DSPFix24 *)alloca(nArgs * sizeof(DSPFix24));
/*	DSP_MALLOC(argArray,DSPFix24,nArgs);  DAJ */
	for (i=0;i<nArgs;i++)
	  argArray[i] = va_arg(ap,DSPFix24);
	va_end(ap);
	return _DSPCallTimedMaybeB(aTimeStampP,hm_opcode,nArgs,argArray,FALSE);
    } else {

	/* Don't call _DSPCallTimedMaybeB() and avoid an array copy */
	int *hm_array = s_hm_array[s_idsp];
	int hm_ptr = s_hm_ptr[s_idsp];
	for (hm_ptr=0;hm_ptr<nArgs;) hm_array[hm_ptr++] = va_arg(ap,DSPFix24);
	s_hm_ptr[s_idsp] = hm_ptr;
	_DSPFinishHmArray(aTimeStampP,hm_opcode);

	return _DSPWriteHostMessage(s_hm_array[s_idsp],s_hm_ptr[s_idsp]);
	/* If moved back to separate file: return _DSPWriteHm(); */
    }
}


int DSPCallV(DSPAddress hm_opcode,int nArgs,...)
/*
 * Usage is int DSPCallV(hm_opcode,nArgs,arg1,...,ArgNargs);
 * Same as DSPCall() except that a variable number of host message arguments 
 * is specified explicitly (using stdarg) rather than being passed in an
 * array.
 */
{
    va_list ap;

    va_start(ap,nArgs);

#if MMAP
    if (s_mapped_only[s_idsp]) {
	int i;
	DSPFix24 *argArray;
	argArray = (DSPFix24 *)alloca(nArgs * sizeof(DSPFix24));
/*	DSP_MALLOC(argArray,DSPFix24,nArgs); // DAJ */
	for (i=0;i<nArgs;i++)
	  argArray[i] = va_arg(ap,DSPFix24);
	va_end(ap);
	return _DSPCallTimedMaybeB(DSPMK_UNTIMED,hm_opcode,nArgs,
				   argArray,FALSE);
    } else {
#endif
	/* Don't call _DSPCallTimedMaybeB() and avoid an array copy */
	int *hm_array = s_hm_array[s_idsp];
	int hm_ptr = s_hm_ptr[s_idsp];
	for (hm_ptr=0;hm_ptr<nArgs;) hm_array[hm_ptr++] = va_arg(ap,DSPFix24);
	va_end(ap);
	s_hm_ptr[s_idsp] = hm_ptr;
	_DSPFinishHmArray(DSPMK_UNTIMED,hm_opcode);
	return _DSPWriteHostMessage(s_hm_array[s_idsp],s_hm_ptr[s_idsp]);
	/* If moved back to separate file: return _DSPWriteHm(); */
#if MMAP
    }
#endif
}


/********************** COMBINED TIMED HOST MESSAGES ************************/

/* We are seeing TMQ overflow. */
#define TMQ_FUDGE 0
#define TMQ_GUARD_ROOM 100 

/* 
 * The purpose of combining timed host messages having the same time
 * into a single host message is to reduce the control bandwidth to the DSP.
 */

#define FILLER_FUDGE 2		/*** FIXME ***/
#define TIMED_MSG_FILLER (4+FILLER_FUDGE)
/* 2 for time stamp of host msg (opcode included already)+2 for topmk,botmk */
#define TIMED_MSG_BUF_SIZE (dsp_nb_hms[s_idsp] - TIMED_MSG_FILLER)

#if 0

static int *timedMsg = 0;

#define FIRST_TIMED_WD (&timedMsg[0])
#define TIMED_WD_2 (&timedMsg[1])
#define LAST_TIMED_WD (&timedMsg[TIMED_MSG_BUF_SIZE - 1])

static int *curTimedWd = 0;
static int *timedArrEnd = 0;
static int TMQMessageCount = 0;
static DSPFix48 s_curTimeStamp[s_idsp] = {0,0};

#define TIMED_MSG_IS_EMPTY() (curTimedWd == FIRST_TIMED_WD)
#define TIMED_MSG_IS_NOT_EMPTY() (curTimedWd > FIRST_TIMED_WD)
#define TIMED_MSG_BUFFER_SIZE() (curTimedWd - FIRST_TIMED_WD)


#endif

#define FIRST_TIMED_WD (&((s_timedMsg[s_idsp])[0]))
#define TIMED_WD_2 (&((s_timedMsg[s_idsp])[1]))
#define LAST_TIMED_WD (&((s_timedMsg[s_idsp])[TIMED_MSG_BUF_SIZE - 1]))

#define TIMED_MSG_IS_EMPTY() (s_curTimedWd[s_idsp] == FIRST_TIMED_WD)
#define TIMED_MSG_IS_NOT_EMPTY() (s_curTimedWd[s_idsp] > FIRST_TIMED_WD)
#define TIMED_MSG_BUFFER_SIZE() (s_curTimedWd[s_idsp] - FIRST_TIMED_WD)

static void s_initMessageArrays(void)
{
    /* times 2 so ovfl less likely to kill */
    if (s_hm_array[s_idsp]) /* This should never happen unless the DSP wasn't
			     * properly closed. - DAJ
			     */
      free(s_hm_array[s_idsp]);
    s_hm_array[s_idsp] = malloc(dsp_max_hm[s_idsp]*2*sizeof(int)); 

    if (s_timedMsg[s_idsp]) /* This should never happen unless the DSP wasn't
			     * properly closed. - DAJ
			     */
      free(s_timedMsg[s_idsp]);
    s_timedMsg[s_idsp] = malloc(TIMED_MSG_BUF_SIZE * sizeof(int));
    s_curTimedWd[s_idsp] = FIRST_TIMED_WD;
    s_timedArrEnd[s_idsp] = LAST_TIMED_WD;
}

int _DSPResetTMQ(void) 
{
    s_curTimedWd[s_idsp] = FIRST_TIMED_WD;
    s_TMQMessageCount[s_idsp] = 0;
    s_curTimeStamp[s_idsp].high24 = 0;
    s_curTimeStamp[s_idsp].low24 = 0;
    if (!s_mk_system[s_idsp])
      return 0;
    s_timedArrEnd[s_idsp] = LAST_TIMED_WD; /* not defined if no MK sys */
    /* Called by DSPRawCloseSaveState() */
    return 0;
}

BRIEF int _DSPFlushTMQ(void) 
{
    if (TIMED_MSG_IS_EMPTY()) 
      return 0;

    /* Don't include first opcode. It is sent below. */
    if (TIMED_MSG_BUFFER_SIZE() > dsp_nb_hms[s_idsp]-2)
      _DSPFatalError(DSP_EPROTOCOL,
		    "_DSPFlushTMQ: Accumulated timed messages overflow HMS");

#if 0	/* Removed by DAJ.  This special case not needed, at least if there's
	   no sound out */
    if (s_mapped_only[s_idsp]) {
	/* wait until TMQ can accept a write */
	if (s_sound_out[s_idsp]) /* If not, we already waited. (DAJ 2/16/94) */
	  DSPAwaitHF3Clear(0);

	DSP_UNTIL_ERROR(DSPWriteTXArrayB(TIMED_WD_2,
					 TIMED_MSG_BUFFER_SIZE()-1));
	ec = DSPMKHostMessageTimed(&s_curTimeStamp[s_idsp],*FIRST_TIMED_WD);
    } else {
	ec = _DSPCallTimedMaybeB(&s_curTimeStamp[s_idsp],
					    *FIRST_TIMED_WD, 
					    TIMED_MSG_BUFFER_SIZE()-1,
					    TIMED_WD_2,DSP_TRUE);
    }
#else
    ec = _DSPCallTimedMaybeB(&s_curTimeStamp[s_idsp],*FIRST_TIMED_WD, 
			     TIMED_MSG_BUFFER_SIZE()-1,
			     TIMED_WD_2,DSP_TRUE);
#endif
    if (ec)
      _DSPError(ec,"_DSPFlushTMQ: Timed message to DSP failed");

    s_curTimedWd[s_idsp] = FIRST_TIMED_WD;	       /* Reset ptr */
    s_TMQMessageCount[s_idsp] = 0;
    return ec;
}

BRIEF int DSPMKFlushTimedMessages(void)
/* 
 * Flush all combined timed messages for the current time. 
 * You must call this if you are sending updates to the DSP 
 * asynchronously (e.g. in response to MIDI or mouse events 
 * as opposed to via the musickit Conductor).  It should
 * also be called after all timed messages have been sent.
 */
{
    if (s_bail_out[s_idsp]) {
	s_curTimedWd[s_idsp] = FIRST_TIMED_WD;	       /* Reset ptr */
	s_TMQMessageCount[s_idsp] = 0;
	return DSP_EABORT;
    }
    if (!TIMED_MSG_IS_EMPTY())
      DSP_UNTIL_ERROR(_DSPFlushTMQ());
    return 0;
}


#define TWO_TO_24   ((double) 16777216.0)

static double s_fix48ToDouble(register DSPFix48 *aFix48P)
{
    if (!aFix48P)
      return -1.0; /* FIXME or some other value */
    return ((double) aFix48P->high24) * TWO_TO_24 + (double) aFix48P->low24;
}


#define BACKUP_ERROR \
    if (DSPErrorLogIsEnabled()) \
        _DSPError1(DSP_EMISC, "_DSPCheckTMQFlush: Warning:" \
	       "Attempt to move current time backwards from %s", \
	       DSPCat(DSPCat("current sample ", \
			     _DSPCVDS(s_fix48ToDouble(&s_curTimeStamp[s_idsp]))), \
		      DSPCat(" to sample ", \
			     _DSPCVDS(s_fix48ToDouble(aTimeStampP)))))
    /* NO ERROR RETURN (warning only) */

int _DSPCheckTMQFlush(DSPFix48 *aTimeStampP, int nArgs)
/* 
 * Flush Timed Message buffer if the new message is timed for later,
 * or if the new message won't fit because of the limited HMS size 
 * in the DSP, or if s_force_tmq_flush is set
 */
{
    register int newTimeH,newTimeL;
    register int curTimeH,curTimeL;

    /* Note: This routine gets called a LOT, and should be optimized */

    if (aTimeStampP == DSPMK_UNTIMED)
      return 0;

    curTimeH = s_curTimeStamp[s_idsp].high24;
    curTimeL = s_curTimeStamp[s_idsp].low24;
    newTimeH = aTimeStampP->high24;
    newTimeL = aTimeStampP->low24;

    /*
     * See if time has advanced, and if so, flush timed messages.
     * They are flushed also for timed-zero messages.
     */
    if (newTimeH == curTimeH) { /* Typical case (24b active timestamp)*/
	if (newTimeL<curTimeL && (newTimeL != 0 || newTimeH != 0)) /* TZM ok */
	  { BACKUP_ERROR; }
	else if (newTimeL>curTimeL) {
	    DSPMKFlushTimedMessages();
	    s_curTimeStamp[s_idsp] = *aTimeStampP; /* Remember new time */
	} 
    } else { /* Have to deal with whole 48-bit time-stamps */
	if (newTimeH<curTimeH && (newTimeL != 0 || newTimeH != 0)) /* TZM ok */
	  { BACKUP_ERROR; }
	else {
	    DSPMKFlushTimedMessages();
	    s_curTimeStamp[s_idsp] = *aTimeStampP; /* Remember new time */
	} 
    }

    /* 
     * Flush if current message overflows maximum message size to DSP 
     */
    if ((nArgs + s_curTimedWd[s_idsp]) > LAST_TIMED_WD)
      /* Check if there's room. Since curTimedWd is preincremented, the
	 value nArgs + curTimedWd is 1 too big. But we need to save room
	 for the opcode, so this works out right. */
      if (TIMED_MSG_IS_EMPTY())	 /* First msg. Flushing won't help! */
	return _DSPError(E2BIG,
			 "_DSPCheckTMQFlush: Too many host message args "
			 "to fit in existing HMS size on DSP");
      else DSPMKFlushTimedMessages(); /* Make room for new msg by flushing */

    if (s_force_tmq_flush[s_idsp])
      DSPMKFlushTimedMessages();

    return 0;
}


BRIEF int DSPMKCallTimed(
    DSPFix48 *aTimeStampP,
    DSPAddress hm_opcode,
    int nArgs,
    DSPFix24 *argArray)
/*
 * Enqueue a timed host message for the DSP.  If the time stamp of the
 * host message is greater than that of the host messages currently
 * in the timed message buffer, the buffer is flushed before the
 * new message is enqueued.  If the timed stamp is equal to those
 * currently in the buffer, it is appended to the buffer.  It is an
 * error for the time stamp to be less than that of the current
 * timed message buffer.  When the DSP Timed Message Queue is full,
 * this routine will block.
 */
{
    int i;

    if (aTimeStampP == DSPMK_UNTIMED)
      return DSPCall(hm_opcode,nArgs,argArray);

    DSP_UNTIL_ERROR(_DSPCheckTMQFlush(aTimeStampP,nArgs));

    *s_curTimedWd[s_idsp]++ = hm_opcode;	/* Install opcode of new message in buffer */
    /* 
       Load array backwards so that when combined by DSPMKFlushTimedMessages
       and written out backwards to the DSP, timed messages will be executed
       in the same order as when they are not combined. 
    */
    for (i = nArgs-1; i >= 0; i--)
	*s_curTimedWd[s_idsp]++ = argArray[i];

    s_TMQMessageCount[s_idsp] += 1;

#if TRACE_POSSIBLE
    if (_DSPTrace & DSP_TRACE_NOOPTIMIZE)
      DSPMKFlushTimedMessages(); /* Flush for clarity in simulator file */
#endif TRACE_POSSIBLE

    if (!s_timed_zero_noflush[s_idsp] && aTimeStampP->high24 == 0 && aTimeStampP->low24 == 0) 
      DSPMKFlushTimedMessages();  /* TZM must be alone on HMS when mixing timed+timed-zero */

    return 0;
}
 

int _DSPCallTimedV(DSPFix48 *aTimeStampP,int hm_opcode,int nArgs,...)
/*
 * Usage is int _DSPCallTimedV(aTimeStampP,hm_opcode,nArgs,arg1,...,ArgNargs);
 * Same as _DSPCallTimed() except that a variable number of host message 
 * arguments is specified explicitly in the argument list (using stdarg) 
 * rather than being passed in an array.
 */
{
    va_list ap;
    int i;

    va_start(ap,nArgs);

    if (aTimeStampP == DSPMK_UNTIMED) {
	DSPFix24 *argArray;
	argArray = (DSPFix24 *)alloca(nArgs * sizeof(DSPFix24));
/*	DSP_MALLOC(argArray,DSPFix24,nArgs); // DAJ */
	for (i=0;i<nArgs;i++)
	  argArray[i] = va_arg(ap,DSPFix24);
	return DSPCall(hm_opcode,nArgs,argArray);
    }

    DSP_UNTIL_ERROR(_DSPCheckTMQFlush(aTimeStampP,nArgs));

    *s_curTimedWd[s_idsp]++ = hm_opcode;	/* Install opcode of new message in buffer */

    /* This was changed by DAJ. We need to write the arguments backwards
       into the TMQ buffer. */
    s_curTimedWd[s_idsp] += nArgs;
    for (i = nArgs-1; i >= 0; i--)
	*--s_curTimedWd[s_idsp] = va_arg(ap,int); /* Install hm args in msg buffer */
    s_curTimedWd[s_idsp] += nArgs;		/* Set it to first loc after msg. */

    va_end(ap);

    s_TMQMessageCount[s_idsp] += 1;

#if TRACE_POSSIBLE
    if (_DSPTrace & DSP_TRACE_NOOPTIMIZE)
      DSPMKFlushTimedMessages(); /* Flush for clarity in simulator file */
#endif TRACE_POSSIBLE

    if (!s_timed_zero_noflush[s_idsp] && aTimeStampP->high24 == 0 && aTimeStampP->low24 == 0)
      DSPMKFlushTimedMessages();  /* TZM must be alone on HMS when mixing timed+timed-zero */

    return 0;
}

int DSPMKCallTimedV(DSPFix48 *aTimeStampP,int hm_opcode,int nArgs,...)
/*
 * Usage is int _DSPCallTimedV(aTimeStampP,hm_opcode,nArgs,arg1,...,ArgNargs);
 * Same as _DSPCallTimed() except that a variable number of host message 
 * arguments is specified explicitly in the argument list (using stdarg) 
 * rather than being passed in an array.
 */
{
    va_list ap;
    int i;
    if (s_bail_out[s_idsp])
      return DSP_EABORT;

    va_start(ap,nArgs);

    if (aTimeStampP == DSPMK_UNTIMED) {
	DSPFix24 *argArray;
	argArray = (DSPFix24 *)alloca(nArgs * sizeof(DSPFix24));
/*	DSP_MALLOC(argArray,DSPFix24,nArgs); // DAJ */
	for (i=0;i<nArgs;i++)
	  argArray[i] = va_arg(ap,DSPFix24);
	return DSPCall(hm_opcode,nArgs,argArray);
    }

    DSP_UNTIL_ERROR(_DSPCheckTMQFlush(aTimeStampP,nArgs));

    *(s_curTimedWd[s_idsp])++ = hm_opcode;	/* Install opcode of new message in buffer */

    /* This was changed by DAJ. We need to write the arguments backwards
       into the TMQ buffer. */
    s_curTimedWd[s_idsp] += nArgs;
    for (i = nArgs-1; i >= 0; i--)
	*--(s_curTimedWd[s_idsp]) = va_arg(ap,int); /* Install hm args in msg buffer */
    s_curTimedWd[s_idsp] += nArgs;		/* Set it to first loc after msg. */

    va_end(ap);

    s_TMQMessageCount[s_idsp] += 1;

#if TRACE_POSSIBLE
    if (_DSPTrace & DSP_TRACE_NOOPTIMIZE)
      DSPMKFlushTimedMessages(); /* Flush for clarity in simulator file */
#endif TRACE_POSSIBLE

    if (!s_timed_zero_noflush[s_idsp] && aTimeStampP->high24 == 0 && aTimeStampP->low24 == 0) 
      DSPMKFlushTimedMessages(); /* TZM must be alone on HMS when mixing timed+timed-zero */

    return 0;
}
 
/************************************ Ping ***********************************/

BRIEF int DSPPingVersionTimeOut( int *verrevP, int msTimeLimit)
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(s_simulator_fp[s_idsp],";; DSPPingVersion: HM_SAY_SOMETHING\n");
#endif SIMULATOR_POSSIBLE
    DSP_UNTIL_ERROR(DSPHostMessage(dsp_hm_say_something[s_idsp]));
#if SIMULATOR_POSSIBLE
    if (DSP_IS_SIMULATED_ONLY) return 0;
#endif SIMULATOR_POSSIBLE
    if(DSPAwaitUnsignedReply(dsp_dm_iaa[s_idsp],verrevP,msTimeLimit))
      DSP_MAYBE_RETURN(_DSPError(DSP_ESYSHUNG,
				 "DSPPing: DSP system is not responding."));
    return 0;
}

BRIEF int DSPPingVersion(int *verrevP)
{
    return DSPPingVersionTimeOut(verrevP,DSPDefaultTimeLimit);
}

BRIEF int DSPPingTimeOut(int msTimeLimit)
{
    int verrev=0;
    return DSPPingVersionTimeOut(&verrev,msTimeLimit);
}

BRIEF int DSPPing(void)
{
    int verrev=0;
/*   return DSPPingVersion(&verrev);  Need optimization... hence repeat code */
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(s_simulator_fp[s_idsp],";; DSPPing: HM_SAY_SOMETHING\n");
#endif SIMULATOR_POSSIBLE
    DSP_UNTIL_ERROR(DSPHostMessage(dsp_hm_say_something[s_idsp]));
#if SIMULATOR_POSSIBLE
    if (DSP_IS_SIMULATED_ONLY) 
      return 0;
#endif SIMULATOR_POSSIBLE
    if(DSPAwaitUnsignedReply(dsp_dm_iaa[s_idsp],&verrev,DSPDefaultTimeLimit))
      DSP_MAYBE_RETURN(_DSPError(DSP_ESYSHUNG,
				 "DSPPing: DSP system is not responding."));
    return 0;
}

/*********************** Memory mapped mode toggling ************************/

#define MAPPING_NOW_PERMANENT _DSPError(DSP_EPROTOCOL, \
	   "We no longer support toggling of mapped DSP access")
BRIEF int _DSPCheckMappedMode(void)  { return MAPPING_NOW_PERMANENT; }
BRIEF int _DSPEnterMappedModeNoCheck(void) { return MAPPING_NOW_PERMANENT; }
BRIEF int _DSPEnterMappedModeNoPing(void)  { return MAPPING_NOW_PERMANENT; }
BRIEF int _DSPEnterMappedMode(void)  { return MAPPING_NOW_PERMANENT; }
BRIEF int _DSPExitMappedMode(void) { return MAPPING_NOW_PERMANENT; }

/******************************  DSP Symbols *********************************/

/* 
 * Moved here from DSPTransfer.c on 90Aug13 to try to eliminate a cycle 
 * cited by `lorder *.o | tsort`
 */

BRIEF int DSPSymbolIsFloat(DSPSymbol *sym)
{
    int isF=0;
    if (!sym)
      return 0;
    if (strlen(sym->type)==1)	/* absolute assembly */
      isF = (*sym->type!='I'); 
    else if (strlen(sym->type)>1) /* relative assembly */
      isF = (sym->type[2]!='I');
    return(isF);
}

/*==== Known Section ====*/

DSPSymbol *DSPGetSectionSymbolInLC(char *name, DSPSection *sec, 
				   DSPLocationCounter lc)
{
    int k,symcount;
    DSPSymbol *sym;
    DSPSymbol *ret;
    if (!name || !sec)
      return NULL;
    DSPSetCurrentSymbolTable(s_idsp);
    if (DSPLookupSymbol(name, &sym)==0)
      return sym;
    name = _DSPCopyToUpperStr(name);
    symcount = sec->symCount[lc];
    for (k=0;k<symcount;k++) {
	sym = &sec->symbols[lc][k];
	if (_DSPStrCmpI(sym->name,name)==0)
	  goto found;
    }
    ret = (DSPSymbol *)_DSPError1(0,"DSPGetSectionSymbolInLC: "
				  "Could not find symbol '%s'",name);
    free(name);	/* uppercase copy */
    return ret;
 found:
    DSPEnterSymbol(name,sym);  /* Need to lookup upper case -- DAJ, 1/11/96 */
    free(name);	/* uppercase copy */
//    DSPEnterSymbol(sym->name,sym); /* let's not do this again */
    return(sym);
}

DSPSymbol *DSPGetSectionSymbol(char *name, DSPSection *sec)
{
    int j,k,symcount;
    DSPSymbol *sym;
    DSPSymbol *ret;

    if (!name || !sec)
      return NULL;
    DSPSetCurrentSymbolTable(s_idsp);
    if (DSPLookupSymbol(name, &sym)==0)
      return sym;
    name = _DSPCopyToUpperStr(name);
    for (j=0;j<DSP_LC_NUM;j++) {
	symcount = sec->symCount[j];
	for (k=0;k<symcount;k++) {
	    sym = &sec->symbols[j][k];
	    if (_DSPStrCmpI(sym->name,name)==0)
	      goto found;
	}
    }
    ret = (DSPSymbol *)_DSPError1(0,"DSPGetSectionSymbol: "
				  "Could not find symbol '%s'",name);
    free(name);	/* uppercase copy */
    return ret;
 found:
    DSPEnterSymbol(name,sym);  /* Need to lookup upper case -- DAJ, 1/11/96 */
    free(name);	/* uppercase copy */
//    DSPEnterSymbol(sym->name,sym);
    return sym;
}

int DSPReadSectionSymbolAddress(DSPMemorySpace *spacep,
			DSPAddress *addressp,
			char *name,			/* name of symbol */
			DSPSection *sec)
{
    DSPSymbol *sym;
    sym = DSPGetSectionSymbol(name,sec);
    if (!sym)
      return _DSPError1(DSP_EMISC,"DSPReadSectionSymbolAddress: "
			   "Symbol %s not found",name);
    if (DSPSymbolIsFloat(sym))
      return(_DSPError(DSP_EMISC,"DSPReadSectionSymbolAddress: "
			   "Desired symbol is a floating-point "
			   "variable, not a DSP memory location."));
    
    *spacep = DSPLCtoMS[sym->locationCounter];
    if (*spacep == DSP_MS_N)
      return _DSPError(DSP_EMISC,"DSPReadSectionSymbolAddress: "
			   "Desired symbol is in memory space N "
			   "which is not a DSP memory location.");
    *addressp = (DSPAddress)sym->value.i;
    return(0);
}

/*==== System section ====*/

int DSPGetSystemSymbolValue(char *name)
{
    DSPSymbol *dspsym;
    DSPLoadSpec *dspsys = DSPGetSystemImage();

    if (dspsys==NULL)
      return -1;

    dspsym = DSPGetSectionSymbol(name, dspsys->globalSection);

    if (dspsym==NULL)
      return -1;

    if (DSPSymbolIsFloat(dspsym))
      _DSPError1(DSP_EWARNING,
		 DSPCat("(int)DSPGetSystemSymbolValue: "
			"Unexpected type '%s' for symbol ",name),
		 dspsym->type);

    return dspsym->value.i;
}

int DSPGetSystemSymbolValueInLC(char *name, DSPLocationCounter lc)
{
    DSPSymbol *dspsym;
    DSPLoadSpec *dspsys = DSPGetSystemImage();

    if (dspsys==NULL || !name)
      return -1;

    dspsym = DSPGetSectionSymbolInLC(name, dspsys->globalSection, lc);

    if (dspsym==NULL)
      return -1;

    if (DSPSymbolIsFloat(dspsym))
      _DSPError1(DSP_EWARNING,
		 DSPCat("(int)DSPGetSystemSymbolValueInLC: "
			"Unexpected type '%s' for symbol ",name),
		 dspsym->type);

    return dspsym->value.i;
}

BRIEF int DSPReadSystemSymbolAddress(DSPMemorySpace *spacep,
			       DSPAddress *addressp,
			       char *name)
{
    DSPLoadSpec *dspsys = DSPGetSystemImage();

    if (dspsys==NULL)
      return _DSPError(DSP_EMISC,"DSPReadSystemSymbolAddress: "
			"No DSP monitor is selected => no symbols yet");

    return DSPReadSectionSymbolAddress(spacep,addressp,name,
				       dspsys->globalSection);
}

/****************************  Poking DSP Symbols ****************************/

BRIEF int DSPPoke(char *name, DSPFix24 value, DSPLoadSpec *dsp)
{
    int ec;
    DSPSection *usr;
    DSPMemorySpace symMS;
    DSPAddress symAddr;
    if (*dsp->type=='R')	/* shouldn't happen */
      _DSPError(DSP_EWARNING,"DSPPoke: "
		 "Relative assembly used. It better be relocated!");
    usr = DSPGetUserSection(dsp); /* Also system section if abs assembly */
    if (ec = DSPReadSectionSymbolAddress(&symMS,&symAddr,name,usr))
      return(ec);
    return DSPWriteValue(value,symMS,symAddr);
}


BRIEF int DSPPokeFloat(char *name, float value, DSPLoadSpec *dsp)
{
    return(DSPPoke(name,DSPFloatToFix24(value),dsp));
}


/******************** GETTING DSP MEMORY BOUNDARIES **************************/

/* All of these routines return -1 for error */

DSPAddress DSPGetLowestInternalUserXAddress(void) 
{ return (DSPAddress)DSPGetSystemSymbolValue("XLI_USR"); }

DSPAddress DSPGetHighestInternalUserXAddress(void)
{ return (DSPAddress)DSPGetSystemSymbolValue("XHI_USR"); }

DSPAddress DSPGetLowestInternalUserYAddress(void) 
{ return (DSPAddress)DSPGetSystemSymbolValue("YLI_USR"); }

DSPAddress DSPGetHighestInternalUserYAddress(void)
{ return (DSPAddress)DSPGetSystemSymbolValue("YHI_USR"); }

DSPAddress DSPGetLowestInternalUserPAddress(void) 
{ return (DSPAddress)DSPGetSystemSymbolValue("PLI_USR"); }

DSPAddress DSPGetHighestInternalUserPAddress(void)
{ return (DSPAddress)DSPGetSystemSymbolValue("PHI_USR"); }

DSPAddress DSPGetLowestExternalUserXAddress(void) 
{ return (DSPAddress)DSPGetSystemSymbolValue("XLE_USR"); }

DSPAddress DSPGetHighestExternalUserXAddress(void)
{ return (DSPAddress)DSPGetSystemSymbolValue("XHE_USR"); }

DSPAddress DSPGetLowestExternalUserYAddress(void) 
{ return (DSPAddress)DSPGetSystemSymbolValue("YLE_USR"); }

DSPAddress DSPGetHighestExternalUserYAddress(void)
{ return (DSPAddress)DSPGetSystemSymbolValue("YHE_USR"); }

DSPAddress DSPGetLowestExternalUserPAddress(void) 
{ return (DSPAddress)DSPGetSystemSymbolValue("PLE_USR"); }

DSPAddress DSPGetHighestExternalUserPAddress(void)
{ return (DSPAddress)DSPGetSystemSymbolValue("PHE_USR"); }

DSPAddress DSPGetHighestExternalUserAddress(void)
{ return (DSPAddress)DSPGetSystemSymbolValue("HE_USR"); }

DSPAddress DSPGetLowestExternalUserAddress(void)
{ return (DSPAddress)DSPGetSystemSymbolValue("LE_USR"); }

DSPAddress DSPGetLowestDegMonAddress(void)
{ return (DSPAddress)DSPGetSystemSymbolValue("DEGMON_L"); }

DSPAddress DSPGetLowestXYPartitionUserAddress(void)
{ return (DSPAddress)DSPGetSystemSymbolValue("XLE_USG"); }

DSPAddress DSPGetHighestXYPartitionXUserAddress(void) 
{ return (DSPAddress)DSPGetSystemSymbolValue("XHE_USG"); }

DSPAddress DSPGetHighestXYPartitionYUserAddress(void)
{ return (DSPAddress)DSPGetSystemSymbolValue("YHE_USG"); }

DSPAddress DSPGetHighestXYPartitionUserAddress(void)
{ 
    return MIN(DSPGetHighestXYPartitionXUserAddress(), 
	       DSPGetHighestXYPartitionYUserAddress()); 
}

DSPAddress DSPGetHighestDegMonAddress(void)
{ return (DSPAddress)DSPGetSystemSymbolValue("DEGMON_H"); }

DSPAddress DSPMKGetClipCountAddress(void) /* obsolete */
{ return (DSPAddress)DSPGetSystemSymbolValue("X_NCLIP"); }

DSPAddress DSPMKGetClipCountXAddress(void)
{ return (DSPAddress)DSPGetSystemSymbolValue("X_NCLIP"); }

/*****************************************************************************/
/*	DSPControl.c -	Utilities for DSP control from host.
	Copyright 1987,1988, by NeXT, Inc.

Modification history:
	07/28/88/jos - Created from _DSPUtilities.c
	05/12/89/jos - Added DSPEnableHostMsg() to DSPMKInit().
	06/08/89/jos - Brought in paren, TMQ block routines. Added DMA_M pokes.
	07/14/89/daj - Commented out DSP_UNTIL_ERROR in _DSPReadTime.
	07/21/89/daj - Made mkSys be static and cached in DSPMKInit().
	01/22/90/jos - Suppressed untimed parens.
	04/23/90/jos - flushed unsupported entry points.
	05/04/90/jos - explicitly including dsp_messages.h
	05/16/90/jos - converted X_DMA_{R,W}_M reg hm to x poke.
	05/16/90/jos - converted HM_SET_TINC to use of poke long.
	05/16/90/jos - converted HM_SET_TIME to use of poke long.
	05/16/90/jos - added DSPGetLong() and DSPReadLong().
	05/16/90/jos - flushed _DSPReadSSI(nbufs)
	07/07/90/jos - Removed DSPEnableHostMsg() in DSPMKInit().
*/

// #import <sound/sound.h>
// #import <sound/snddriver_client.h>
// #import <mach/mach.h>

/* JOS sez:

  Ideally, you'd write 1-64k in x, 64k+1 to 128k in y,
  etc., and then figure out what's going on.  A more efficient check
  would be to write different numbers in locations 7k, 15k, 31k, and 63k
  (say) of x, y, and p, and then work it out.  (I am avoiding the top 1k
  of memory because device addresses are there in the 64k case.) To only
  test for 8k, 32k, and 64k x 3 (192k), you only need to write different
  numbers at locations 7k, 31k, and 63k in any one address space.  Then
  64k would imply three separate memory banks, and the other two cases
  would be overlaid.

*/

#if m68k
static int cpuSense(int *processorType,int *processorSubType)
{
#if DO_SENSE_CPU_TYPE
    kern_return_t           ret;
    struct host_basic_info  basic_info;
    unsigned int            count=HOST_BASIC_INFO_COUNT;
    ret=host_info(host_self(), HOST_BASIC_INFO,
                  (host_info_t)&basic_info, &count);
    if (ret != KERN_SUCCESS) 
      return _DSPMachError(ret,"DSPSenseMem: host_info failed.");
    *processorType = basic_info.cpu_type;
    *processorSubType = basic_info.cpu_subtype;
#endif
    return 0;
}

int DSPSenseMem(int *memCount)  
    /* Returns 0 for success, 1 otherwise.
     * If successful, *memCount is 0x1fff for 8k, 0x7fff for 32k.
     *
     * Only supported for NeXT hardware 
     */
{
    int size, result;
    mach_port_t dev_port = 0, owner_port = 0, cmd_port;
    SndSoundStruct *dspStruct;
    int i,*p,ec;
#   define HEADERBYTES (128)
#   define DSPBYTES (404)
#   define DSPCORESIZE (DSPBYTES/4)
    int data[DSPCORESIZE]={
	/* I don't know what these first 10 words are--probably some preamble. */
	0, 0, 0x5, 0, 0, 0, 0, 0, 0x4, 0, 
	0x56, 	/* Word count */
	/* This is the beginning */
	0xaf080, 0x44, 		/* jmp >reset */
	/* Interrupt vectors */
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 
	/* Location 0x40--putSamp */
	0xaa981, 0x40, 	/* jclr	#m_htde,x:m_hsr,putSamp ;wait till host read prev word 	*/
	0x8ce2b, 	/* movep a,x:m_htx	;move in new word		*/
	0xc, 		/* rts */
	/* Location 0x44--reset */
	0x506ba, 	/* movec   #6,omr	;data rom enabled, mode 2	*/
	0xaa020, 	/* bset #0,x:m_pbc	;host port			*/
	0xaa323, 	/* bset	#3,x:m_pcddr	;   pc3 is an output with value	*/
	0xaa503, 	/* bclr #3,x:m_pcd	;   zero to enable the external ram  */
	0x8f4be, 0x0,   /* movep #>$000000,x:m_bcr	;no wait states on the external sram */
	0x56f400,DSP_64K,/* move #>$fbff,a	;top of 64k memory   	*/
	0x567000,DSP_64K,/* move a,x:$fbff	;write it there      	*/
	0x56f400,DSP_32K,/* move #>$7bff,a	;top of 32k memory   	*/
	0x567000,DSP_32K,/* move a,x:$7bff	;write it there      	*/
	0x56f400,DSP_8K, /* move #>$1bff,a	;top of 8k memory    	*/
	0x567000,DSP_8K, /* move a,x:$1bff   	;write it there	 	*/
	0x56f000,DSP_64K,/* move x:$fbff,a	;fetch top of 32k memory	*/
	0xd0040, 	/* jsr putSamp		;host will check if it's been  	*/ 	
	0xc0059 	/* jmp stop 		;loop safely	*/
      };

    int processorType,processorSubType;
    ec = cpuSense(&processorType,&processorSubType);
    if (processorType != CPU_TYPE_MC680x0 && processorType != CPU_TYPE_I386)
      return _DSPError(ec,"DSPSenseMem: "
		       "Only 680x0 processors are currently supported.\n");
    /* 68030 computers incorrectly sense DSP memory. I don't know why!
       Since 68030 computers can't have more than 8K of DSP mem,
       we just return 8K for them.
       */
    if (processorSubType == CPU_SUBTYPE_MC68030 ||
	processorSubType == CPU_SUBTYPE_MC68030_ONLY) {
	*memCount = DSP_8K;
	return 0;
    }
    dspStruct = calloc(HEADERBYTES + DSPBYTES,1);
    dspStruct->magic = SND_MAGIC;
    dspStruct->dataLocation = HEADERBYTES;
    dspStruct->dataSize = DSPBYTES;
    dspStruct->dataFormat = SND_FORMAT_DSP_CORE;
    p = (int *)dspStruct;
    p += (HEADERBYTES/sizeof(int));
    for (i=0; i<DSPCORESIZE; i++)
      p[i] = data[i];
    ec = SNDAcquire(SND_ACCESS_DSP, 0, 0, 0, NULL_NEGOTIATION_FUN,
		    0, &dev_port, &owner_port);
    if (ec != KERN_SUCCESS)
      return _DSPError1(ec,"DSPSenseMem: "
			"Could not get DSP or sound-out.\n;; %s",
			DSPGetOwnerString());
    ec = snddriver_get_dsp_cmd_port(dev_port,owner_port,&cmd_port); 
    if (ec != KERN_SUCCESS)
      return _DSPMachError(ec,"DSPSenseMem: "
			   "snddriver_get_dsp_cmd_port failed.");
    ec = SNDBootDSP(dev_port, owner_port, dspStruct);
    if (ec != SND_ERR_NONE) 
      return _DSPMachError(ec,"DSPSenseMem: SNDBootDSP failed.");
    /* read one word from the DSP */
    size = 1;
    snddriver_dsp_read(cmd_port,(void *)(&result),&size,sizeof(int),0);
    if (ec != KERN_SUCCESS || size != 1)
      return _DSPMachError(ec,"DSPSenseMem: snddriver_dsp_read() failed.");
    *memCount = result;
    free(dspStruct);	/* 6/7/95 */
    return 0;
}
#endif m68k

BRIEF int DSPInit(void) 
{
    return(DSPBoot(NULL));
}


int DSPMKInit(void) 
    /* This function is not currently used.  The Music Kit has its own version
       (see orchControl.m) in order to take advantage of the app wrapper bundle.
       (We don't have access to it here because its in libNeXT_s.)
       */
{
    int ec;
    static DSPLoadSpec *mkSys = NULL; /* Fixme--not vectorized for multiple DSPs */
	
    if (!mkSys) { 
	ec = DSPReadFile(&mkSys,DSP_MUSIC_SYSTEM_BINARY_0);
	if(ec)
	  return _DSPError1(ec,"DSPMKInit: Could not read music system '%s' "
			    "for booting the DSP", DSP_MUSIC_SYSTEM_BINARY_0);
    }
//    DSPSetHostMessageMode();

//    DSPEnableHostMsg();  /* DAJ: This causes system to hang! */

    ec = DSPBoot(mkSys);
    if(ec)
      return(_DSPError(ec,"DSPMKInit: Could not boot DSP"));

    return(ec); 
}

int DSPMKInitWithSoundOut(
    int lowSamplingRate)
{
    int ec;

    DSPMKEnableSoundOut();

    if (lowSamplingRate)
      DSPMKSetSamplingRate(DSPMK_LOW_SAMPLING_RATE);
    else
      DSPMKSetSamplingRate(DSPMK_HIGH_SAMPLING_RATE);

    ec = DSPMKInit();
    if(ec)
      return(_DSPError(ec,"DSPMKInitWithSoundOut: Could not init DSP"));
    else
      return(0); 
}

BRIEF int DSPSetStart(int startAddress)
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(DSPGetSimulatorFP(),
	      ";; Set start address to 0x%X \n", startAddress);
#endif SIMULATOR_POSSIBLE
    return DSPWriteValue(startAddress, DSP_MS_X, dsp_x_start[s_idsp]);
}

BRIEF int DSPStart()
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(DSPGetSimulatorFP(),";; GO \n");
#endif SIMULATOR_POSSIBLE
    return(DSPHostMessage(dsp_hm_go[s_idsp]));
}

BRIEF int DSPStartAtAddress(int startAddress)
{
    DSP_UNTIL_ERROR(DSPSetStart(startAddress));
    return(DSPStart());
}

int DSPCheckVersion(
    int *sysver,	   /* system version running on DSP (returned) */
    int *sysrev)	   /* system revision running on DSP (returned) */
{
    int dspack=0,verrev=0;
    if (DSPPingVersion(&verrev))
      DSP_MAYBE_RETURN(_DSPError(DSP_ESYSHUNG, "DSPCheckVersion: "
				 "DSP system is not responding."));
    *sysver = (verrev>>8)&0xFF;
    *sysrev = (verrev)&0xFF;
    if (*sysver != DSP_SYS_VER) /* || *sysrev != DSP_SYS_REV) - daj 9/30/94 */
      _DSPError(DSP_EBADVERSION,
		DSPCat(DSPCat("DSPCheckVersion: *** WARNING *** "
				"DSP system version.revision = ",
				DSPCat(_DSPCVS(*sysver),
					DSPCat(".0(",_DSPCVS(*sysrev)))),
			DSPCat(") while this program was compiled assuming ",
				DSPCat(_DSPCVS(DSP_SYS_VER),
					DSPCat(".0(",
						DSPCat(_DSPCVS(DSP_SYS_REV),
							")")
						)))));
		
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(DSPGetSimulatorFP(),";; DSPCheckVersion: HM_FIRST\n");
#endif SIMULATOR_POSSIBLE
    DSP_UNTIL_ERROR(DSPHostMessage(dsp_hm_hm_first[s_idsp]));
    DSP_UNTIL_ERROR(DSPAwaitUnsignedReply(dsp_dm_hm_first[s_idsp],&dspack,
				      DSPDefaultTimeLimit));

    if(DSP_MESSAGE_ADDRESS(dspack)!=dsp_hm_first[s_idsp])
      _DSPFatalError(DSP_EBADVERSION, 
		     /* This is a very rotten situation */
		     "*** DSPCheckVersion: DSP host-message dispatch "
		     "table origin is not the same in this compilation "
		     "as in the DSP.");

#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(DSPGetSimulatorFP(),
	      ";; DSPCheckVersion: HM_LAST\n");
#endif SIMULATOR_POSSIBLE
    DSP_UNTIL_ERROR(DSPHostMessage(dsp_hm_hm_last[s_idsp]));
    DSP_UNTIL_ERROR(DSPAwaitUnsignedReply(dsp_dm_hm_last[s_idsp],&dspack,
				      DSPDefaultTimeLimit));
    if(DSP_MESSAGE_ADDRESS(dspack)!=dsp_hm_last[s_idsp])
      _DSPFatalError(DSP_EBADVERSION, 
		     /* This is a wholly flagitious condition */
		     "*** DSPCheckVersion: VERSIONITIS! "
		     "DSP host-message dispatch table end "
		     "is not the same in this compilation as in the DSP.");
    return(0);
}


BRIEF int DSPIsAlive(void) 
{
    return !DSPPing();
}


BRIEF int DSPMKIsAlive(void) 
{
    if (!DSPMonitorIsMK())
      return _DSPError(DSP_EMISC,"DSPMKIsAlive: "
		       "DSP is not running the Music Kit monitor");
    return !DSPPing();
}


/******************************** TIMED CONTROL ******************************/

/* 
   Timed messages are used by the music kit.  Time is maintained in the DSP.
   The current time (in samples) is incremented by the tick size
   once each iteration of the orchestra loop on the DSP.  When the orchestra
   loop is initially loaded and started, the time increment is zero so that
   time does not advance.  This is the "paused" state for the DSP orchestra.
   DSPMKPauseOrchestra() will place the orchestra into the paused state at 
   any time.  A DSPMKResumeOrchestra() is necessary to clear the pause.

*/

BRIEF int DSPMKSetTime(DSPFix48 *aTimeStampP)
{
    if (aTimeStampP == DSPMK_UNTIMED)
      return 0;
    return DSPMKSendLongTimed(&DSPMKTimeStamp0,aTimeStampP,dsp_l_tick[s_idsp]);
}

BRIEF int DSPMKSetTimeFromInts(highTime,lowTime)
    int highTime;
    int lowTime;
{
    DSPFix48 newTime;
    newTime.low24 = lowTime;
    newTime.high24 = highTime;
    return DSPMKSendLong(&newTime,dsp_l_tick[s_idsp]);
}

BRIEF int DSPMKClearTime(void)
{
    return DSPMKSetTimeFromInts(0,0);
}

DSPFix48 *DSPMKGetTime(void)
{
    DSPFix48 *dspTimeP = (DSPFix48 *)malloc(sizeof(DSPFix48));
    if(DSPMKReadTime(dspTimeP))
    	return NULL;
    else
	return dspTimeP;
}

BRIEF int DSPMKReadTime(DSPFix48 *dspTime)
{
    return DSPReadLong(dspTime,dsp_l_tick[s_idsp]);
}

DSPFix48 *DSPGetLong(DSPAddress address)
{
    DSPFix48 *dspLongP = (DSPFix48 *)malloc(sizeof(DSPFix48));
    if(DSPReadLong(dspLongP,address))
    	return NULL;
    else
	return dspLongP;
}

int DSPReadLong(DSPFix48 *longValue,DSPAddress address)
{
    int t0,t1,t2=0,ec;
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(DSPGetSimulatorFP(), 
	      ";; Get long value from DSP at address 0x%X \n",address);
#endif SIMULATOR_POSSIBLE
#ifdef NO_REVERT
    ec = DSPCall(dsp_hm_get_long[s_idsp],1,&address);
    if (ec)
      return _DSPError(DSP_EMISC,"DSPReadLong: DSPCall failed");
    ec = DSPAwaitUnsignedReply(dsp_dm_long0[s_idsp],&t0,10000);
    if (ec)
      return _DSPError(DSP_EMISC,"DSPReadLong: Could not read low 16 bits");
    ec = DSPAwaitUnsignedReply(dsp_dm_long1[s_idsp],&t1,10000);
    if (ec)
      return _DSPError(DSP_EMISC,"DSPReadLong: Could not read middle 16 bits");
    ec = DSPAwaitUnsignedReply(dsp_dm_long2[s_idsp],&t2,10000);
    if (ec)
      return _DSPError(DSP_EMISC,"DSPReadLong: Could not read high 16 bits");
    longValue->low24 = ((t1&0xFF)<<16)|(t0&0xFFFF);
    longValue->high24 = ((t2&0xFFFF)<<8)|((t1>>8)&0xFF);
#else
    ec = DSPReadValue(DSP_MS_Y,address,&t0);
    if (ec)
      return _DSPError(DSP_EMISC,"DSPReadLong: DSPReadValue Y failed");
    ec = DSPReadValue(DSP_MS_X,address,&t1);
    if (ec)
      return _DSPError(DSP_EMISC,"DSPReadLong: DSPReadValue X failed");
    longValue->low24 = t0;
    longValue->high24 = t1;
#endif    

#if TRACE_POSSIBLE
    if (_DSPTrace)
      printf("DSP Long Value received from address 0x%X = 0x%X 0x%X 0x%X\n\n",
	     (unsigned int)address,
	     (unsigned int)t2,(unsigned int)t1,(unsigned int)t0);
#endif TRACE_POSSIBLE

    return 0;
}


BRIEF int DSPMKPauseOrchestra(void) /* Stop sample-ctr at "end of cur tick" */
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(DSPGetSimulatorFP(),";; Pause orchestra loop\n");
#endif SIMULATOR_POSSIBLE
    s_clock_advancing[s_idsp] = 0;
    return DSPMKSendLong(&DSPMKTimeStamp0, dsp_l_tinc[s_idsp]);
}


BRIEF int DSPMKPauseOrchestraTimed(DSPFix48 *aTimeStampP)
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(DSPGetSimulatorFP(),
	      ";; PAUSE at time %s\n",DSPFix48ToSampleStr(aTimeStampP));
#endif SIMULATOR_POSSIBLE
    return DSPMKSendLongTimed(aTimeStampP, &DSPMKTimeStamp0, 
			      dsp_l_tinc[s_idsp]);
}


BRIEF int DSPMKResumeOrchestra(void)
{
    DSPFix48 tick_increment;
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(DSPGetSimulatorFP(),";; Resume orchestra loop\n");
#endif SIMULATOR_POSSIBLE
    tick_increment.high24 = 0;
    tick_increment.low24 = dsp_i_ntick[s_idsp];
    s_clock_advancing[s_idsp] = 1;
    s_clock_just_started[s_idsp] = 1; /* Cleared by dsp error thread */
    return DSPMKSendLong(&tick_increment, dsp_l_tinc[s_idsp]);
}


BRIEF int _DSPStartTimed(aTimeStampP)
    DSPFix48 *aTimeStampP;
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(DSPGetSimulatorFP(),";; GO at sample %s\n",DSPFix48ToSampleStr(aTimeStampP));
#endif SIMULATOR_POSSIBLE
    return DSPMKCallTimedV(aTimeStampP,dsp_hm_go[s_idsp],0);
}

BRIEF int _DSPSetStartTimed(aTimeStampP,startAddress)
    DSPFix48 *aTimeStampP;
    int startAddress;
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      if (aTimeStampP)
	fprintf(DSPGetSimulatorFP(),";; Set start address at sample %s\n",
		DSPFix48ToSampleStr(aTimeStampP));
#endif SIMULATOR_POSSIBLE
    return DSPMKSendValueTimed(aTimeStampP, startAddress,
			       DSP_MS_X, dsp_x_start[s_idsp]);
}

BRIEF int _DSPSineTest(int nbufs)
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(DSPGetSimulatorFP(),";; Enable sine test for %d buffers\n", 
	      nbufs);
#endif SIMULATOR_POSSIBLE
    return DSPCall(dsp_hm_sine_test[s_idsp],1,&nbufs);
}

BRIEF int _DSPSetSCISCR(scr)	
    int scr;			
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(DSPGetSimulatorFP(),";; Set control reg SCR in SCI to 0x%X\n",scr);
#endif SIMULATOR_POSSIBLE
    return DSPWriteValue(scr,DSP_MS_X,0xFFF0);
}

BRIEF int _DSPSetSCISCCR(sccr)	
    int sccr;			
{				
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(DSPGetSimulatorFP(),";; Set control reg SCCR in SCI to 0x%X\n",sccr);
#endif SIMULATOR_POSSIBLE
    return DSPWriteValue(sccr,DSP_MS_X,0xFFF2);
}

BRIEF int _DSPSetSSICRA(cra)		/* Set Control Register A of the SSI */
    int cra;			/* 0x30C for FSL=1, 0x20C for FSL=0 */
{				/* cf. $DSP/smsrc/jsrlib.asm */
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(DSPGetSimulatorFP(),";; Set control reg A in SSI to 0x%X\n",cra);
#endif SIMULATOR_POSSIBLE
    return DSPWriteValue(cra,DSP_MS_X,0xFFEC);
}

BRIEF int _DSPSetSSICRB(crb)		/* Set Control Register B of the SSI */
    int crb;			/* 0x30C for FSL=1, 0x20C for FSL=0 */
{				/* cf. $DSP/smsrc/jsrlib.asm */
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(DSPGetSimulatorFP(),";; Set control reg B in SSI to 0x%X\n",crb);
#endif SIMULATOR_POSSIBLE
    return DSPWriteValue(crb,DSP_MS_X,0xFFED);
}

BRIEF int DSPMKEnableAtomicTimed(DSPFix48 *aTimeStampP)
{
    if (aTimeStampP != DSPMK_UNTIMED)
         return DSPMKHostMessageTimed(aTimeStampP,dsp_hm_open_paren[s_idsp]);
    else return 0;
    /* _DSPError(DSP_EPROTOCOL,"DSPMKEnableAtomicTimed: atomic execution "
    			"not supported for untimed messages."); */
}

BRIEF int DSPMKDisableAtomicTimed(aTimeStampP) 
    DSPFix48 *aTimeStampP;
{
    if (aTimeStampP != DSPMK_UNTIMED)
         return DSPMKHostMessageTimed(aTimeStampP,dsp_hm_close_paren[s_idsp]);
    else return 0;
    /* _DSPError(DSP_EPROTOCOL,"DSPMKDisableAtomicTimed: atomic execution "
    			"not supported for untimed messages."); */
}

BRIEF int DSPSetDMAReadMReg(DSPAddress M)
{
    return DSPWriteValue(M, DSP_MS_X, dsp_x_dma_r_m[s_idsp]);
}


BRIEF int DSPSetDMAWriteMReg(DSPAddress M)
{
    return DSPWriteValue(M, DSP_MS_X, dsp_x_dma_w_m[s_idsp]);
}


BRIEF int DSPAbort(void)
{
    return DSPHostCommand(DSP_HC_ABORT);
}

/**********************************************************************/

/*	DSPTransfer.c - DSP utilities for data transfer.
	Copyright 1987,1988, by NeXT, Inc.

Modification history:
	07/28/88/jos - Created from _DSPUtilities.c
	12/12/88/jos - Rewrote DSPMKSendSkipArrayTimed() to be atomic and fast
	02/20/89/daj - Fixed timestamp argument in timed BLTs.
		       Added DSPIntToFix24 to -1 arguments in BLTs.
	03/24/89/jos - DSPMKRetValueTimed now always waits forever.
	05/12/89/jos - Added NOP before JMP LOOP_BEGIN in 
		       _DSPMKSendUnitGeneratorWithLooperTimed()
	05/12/89/jos - Brought in DSP{Get,Put}{Int,Float}Array() from 
		       DSPAPUtilities() and removed checking of addresses.
		       AP versions will now have DSPAP prefix.
	01/13/90/jos - Added DSPMKSendArraySkipModeTimed.
		       Moved data arg to 2nd position and added mode arg.
	01/13/90/jos - Added DSPMKSendShortArraySkipTimed() for David.
		       Moved data arg to 2nd position and added mode arg.
	03/19/90/jos - Changed header file: reordered some routines. 
		       Deleted ReadArray prototype. 
		       Changed ShortArray data ptr to short int *!
		       Added DSP_MIN_DMA_{READ,WRITE}_SIZE to dsp.h.
		       Still need to add support for it.
		       Added LJ version of Read/Write Fix24 Array.  
	03/24/90/daj - Fixed extra loopers when breaking up UGs in
		       _DSPMKSendUnitGeneratorWithLooperTimed()
        04/23/90/jos - flushed unsupported entry points.
        04/23/90/jos - fixed arg order in publication of 
		       DSPMKSendArraySkipTimed, DSPMKSendValueTimed,
		       DSPMKSendLongTimed. Old versions kept for MK 1.0.
        04/24/90/jos - fixed arg order in publication of 
		       DSPMKSendValue, DSPMKSendLong,
		       DSPWriteValue, DSPWriteLong,
		       and DSPMKSendArray IN PLACE
        04/25/90/jos - added DSPGetSymbolInLC()
        04/26/90/jos - Since DSPWriteValue and DSPWriteLong were published in
		       1.0, they were reverted, renamed to DSPWrite{}1p0(),
		       and the new correct-arg-order versions have fresh
		       shlib slots. (For 1.0 binary compatibility.)
	04/30/90/jos - Removed "r" prefix from rData, rWordCount, rRepeatCount
	05/01/90/jos - Added DSP memory boundary sensing functions
	05/01/90/jos - added DSPMKClearDSPSoundOutBufferTimed(ts);
	05/04/90/jos - explicitly including dsp_messages.h
	05/04/90/jos - Changed DSPAP to DSP and removed check of MK vs AP
	05/14/90/jos - Completed implementation of DSPMKRetValueTimed()
	05/14/90/jos - Added support for symbol table hashed on name.
*/
	
#   define NEGATIVE1 (-1 & 0xffffff)

static int ec;			/* Error code */

/************************ UNTIMED TRANSFERS TO THE DSP ***********************/

BRIEF int DSPMemoryFill(
    DSPFix24 fillConstant,	/* value to use as DSP memory initializer */
    DSPMemorySpace memorySpace, /* from <dsp/dsp_structs.h> */
    DSPAddress startAddress,	/* first address within DSP memory to fill */
    int wordCount)		/* number of DSP words to initialize */
{
    int ec;
    ec =DSPMKMemoryFillTimed(DSPMK_UNTIMED,fillConstant,
				memorySpace,startAddress,wordCount);
    return(ec);
}    

BRIEF int DSPMemoryClear(
    DSPMemorySpace memorySpace, /* from <dsp/dsp_structs.h> */
    DSPAddress startAddress,	/* first address within DSP memory to fill */
    int wordCount)		/* number of DSP words to initialize */
/*
 * Set a block of DSP private RAM to zero.
 * It is equivalent to DSPMemoryFill(0,memorySpace,startAddress,wordCount))
 */
{
    return DSPMKMemoryClearTimed(DSPMK_UNTIMED,memorySpace,startAddress,
				   wordCount);
}

BRIEF int DSPWriteFix24Array(
    DSPFix24 *data,		/* array to send to DSP */
    DSPMemorySpace memorySpace, /* from <dsp/dsp_structs.h> */
    DSPAddress startAddress,	/* within DSP memory */
    int skipFactor,		/* 1 means normal contiguous transfer */
    int wordCount)		/* from DSP perspective */
{
    return(DSPWriteArraySkipMode(data,memorySpace,startAddress,
			       skipFactor,wordCount,DSP_MODE32));
}

BRIEF int DSPWriteFix24ArrayLJ(
    DSPFix24 *data,		/* array to send to DSP */
    DSPMemorySpace memorySpace, /* from <dsp/dsp_structs.h> */
    DSPAddress startAddress,	/* within DSP memory */
    int skipFactor,		/* 1 means normal contiguous transfer */
    int wordCount)		/* from DSP perspective */
{
    return(DSPWriteArraySkipMode(data,memorySpace,startAddress,
			 skipFactor,wordCount,DSP_MODE32_LEFT_JUSTIFIED));
}

BRIEF int DSPWritePackedArray(
    unsigned char *data,	/* Data to send to DSP */
    DSPMemorySpace memorySpace, /* DSP memory space */
    DSPAddress startAddress,	/* DSP start address */
    int skipFactor,		/* DSP index increment per DSP word written */
    int wordCount)		/* DSP words = byte count / 3 */
{	
    return DSPWriteArraySkipMode((void *)data,memorySpace,startAddress,
			       skipFactor,wordCount,DSP_MODE24);
}


BRIEF int DSPWriteShortArray(
    short int *data,		/* Packed short data to send to DSP */
    DSPMemorySpace memorySpace, /* DSP memory space */
    DSPAddress startAddress,	/* DSP start address */
    int skipFactor,		/* DSP index increment per short written */
    int wordCount)		/* DSP word count = byte count / 2 */
{	
    return DSPWriteArraySkipMode((void *)data,memorySpace,startAddress,
			       skipFactor,wordCount,DSP_MODE16);
}


BRIEF int DSPWriteByteArray(
    unsigned char *data,	/* Data to send to DSP */
    DSPMemorySpace memorySpace, /* DSP memory space */
    DSPAddress startAddress,	/* DSP start address */
    int skipFactor,		/* DSP index increment per byte transferred */
    int byteCount)		/* Total number of bytes to transfer */
{	
    return DSPWriteArraySkipMode((void *)data,
				 memorySpace,startAddress,skipFactor,
				 byteCount,DSP_MODE8);
}


BRIEF int DSPWriteIntArray(
    int *intArray,
    DSPMemorySpace memorySpace,
    DSPAddress startAddress,
    int skipFactor,
    int wordCount)
{
    int ec;
    if (wordCount<=0)
      return(0);
    /* old AP version: 
       DSPCheckWriteAddresses(startAddress,skipFactor,wordCount); 
     */
    /* not needed: ec = DSPIntToFix24Array(fix24Array,intArray,wordCount); */
    ec = DSPWriteArraySkipMode(intArray,memorySpace,startAddress,skipFactor,
			       wordCount,DSP_MODE32);
    return(ec);
}

    
BRIEF int DSPWriteFloatArray(
    float *floatArray,
    DSPMemorySpace memorySpace,
    DSPAddress startAddress,
    int skipFactor,
    int wordCount)
{
    int ec1,ec2;
    DSPFix24 fix24Array[wordCount];
    if (wordCount<=0)
      return(0);
    ec1 = DSPFloatToFix24Array(floatArray,fix24Array,wordCount);
    /* old AP version: 
       DSPCheckWriteAddresses(startAddress,skipFactor,wordCount); 
     */
    ec2 = DSPWriteArraySkipMode(fix24Array,memorySpace,startAddress,
			   skipFactor,wordCount,DSP_MODE32);
    return(ec2);

    REMEMBER(Clipping ignored)

}

BRIEF int DSPWriteDoubleArray(
    double *doubleArray,
    DSPMemorySpace memorySpace,
    DSPAddress startAddress,
    int skipFactor,
    int wordCount)
{
    int ec1,ec2;
    DSPFix24 *fix24Array;
    if (wordCount<=0)
      return(0);
    fix24Array = (DSPFix24 *)malloc(wordCount * sizeof(DSPFix24));
    ec1 = DSPDoubleToFix24Array(doubleArray,fix24Array,wordCount);
 /*DSPCheckWriteAddresses[XY](memorySpace,startAddress,skipFactor,wordCount);*/
    ec2 = DSPWriteArraySkipMode(fix24Array,memorySpace,startAddress,
			   skipFactor,wordCount,DSP_MODE32);
    free(fix24Array);
    return(ec2);

    REMEMBER(Clipping ignored)
}


BRIEF int DSPWriteFloatArrayXY(
    float *floatArray,
    DSPMemorySpace memorySpace,
    DSPAddress startAddress,
    int skipFactor,
    int wordCount)
{
    return DSPWriteFloatArray(floatArray,
			      memorySpace,startAddress,skipFactor,wordCount);
}


BRIEF int DSPWriteDoubleArrayXY(
    double *doubleArray,
    DSPMemorySpace memorySpace,
    DSPAddress startAddress,
    int skipFactor,
    int wordCount)
{
    return DSPWriteDoubleArray(doubleArray,
			       memorySpace,startAddress,skipFactor,wordCount);
}

/******************************* Data Record Transfer ************************/

int DSPDataRecordLoad(DSPDataRecord *dr) /* cf. <dsp/dsp_structs.h> */
{
    int i,ms,la,wc,rc,*dp;

    while (dr) {
	
	ms = DSPLCtoMS[(int)dr->locationCounter];
	la =dr->loadAddress+dr->section->loadAddress[(int)dr->locationCounter];
	dp = dr->data;
	rc = dr->repeatCount;
	wc = dr->wordCount;
	
	if (rc == 1) {
	    DSP_UNTIL_ERROR(DSPWriteFix24Array(dp,ms,la,1,wc));
	}
	else
	  if (wc == 1) {
	      DSP_UNTIL_ERROR(DSPMemoryFill(*dp,ms,la,rc));
	  }
	  else
	    for (i=0;i<rc;i++)
	      DSP_UNTIL_ERROR(DSPWriteFix24Array(dp,ms,la,1,wc));

	dr = dr->next;
    }
    return(0);
}

/************************** TRANSFERS FROM THE DSP ***************************/

int DSPMKRetValueTimed(
    DSPTimeStamp *aTimeStampP,
    DSPMemorySpace space,
    DSPAddress address,
    DSPFix24 *value)
{
    int vallo,valhi;
    int msTimeLimit = 0;		/* in milliseconds */
    int opcode;

    switch(space) {
      case DSP_MS_X:
	opcode = dsp_hm_peek_x[s_idsp];
	break;
      case DSP_MS_Y:
	opcode = dsp_hm_peek_y[s_idsp];
	break;
      case DSP_MS_P:	
	opcode = dsp_hm_peek_p[s_idsp];
	break;
    default:
	return(_DSPError1(EDOM,
			  "DSPMKRetValueTimed: cannot send memory space: "
			  "%s", (char *) DSPMemoryNames((int)space)));
    }
    DSP_UNTIL_ERROR(DSPMKCallTimedV(aTimeStampP,opcode,1,address));
    DSP_UNTIL_ERROR(DSPMKFlushTimedMessages());
    
#if SIMULATOR_POSSIBLE
    if (DSPIsSimulatedOnly()) return(-1);
#endif SIMULATOR_POSSIBLE
    if(DSPAwaitUnsignedReply(dsp_dm_peek0[s_idsp],&vallo,msTimeLimit))
      return(_DSPError(DSP_ESYSHUNG,
		       "DSPMKRetValueTimed: No reply to timed peek"));
    if(DSPAwaitUnsignedReply(dsp_dm_peek1[s_idsp],&valhi,msTimeLimit))
      return(_DSPError(DSP_ESYSHUNG, "DSPMKRetValueTimed: "
		       "Hi word of timed peek never came"));
    *value = (valhi<<16) | vallo;
    return(0);
}


BRIEF int DSPMKRetValue(
    DSPMemorySpace space,
    DSPAddress address,
    DSPFix24 *value)
{
    return(DSPMKRetValueTimed(&DSPMKTimeStamp0,space,address,value));
}


BRIEF int DSPReadValue(
    DSPMemorySpace space,
    DSPAddress address,
    DSPFix24 *value)
{
    return(DSPMKRetValueTimed(DSPMK_UNTIMED,space,address,value));
}


DSPFix24 DSPGetValue(
    DSPMemorySpace space,
    DSPAddress address)
{
    int ec, count = 1, skipFactor = 1;
    DSPFix24 datum;

    if (ec = DSPReadArraySkipMode(&datum,space,address,skipFactor,
				  count,DSP_MODE32))
      _DSPError(ec,"DSPGetValue: DSP read failed");
    return datum;
}


BRIEF int DSPReadArray(
    DSPFix24 *data,		/* array to fill from DSP */
    DSPMemorySpace memorySpace, /* from <dsp/dsp_structs.h> */
    DSPAddress startAddress,	/* within DSP memory */
    int wordCount)		/* from DSP perspective */
{
    static int warned=0;
    if(!warned) {
	_DSPError(0,"Note: DSPReadArray() has been superceded by "
		  "DSPReadFix24Array() (which has a skipFactor argument)");
	warned=1;
    }
    /* See DSPObject.c */
    return(DSPReadArraySkipMode((void *)data,memorySpace,startAddress,1,
			   wordCount,DSP_MODE32));
}


BRIEF int DSPReadFix24Array(
    DSPFix24 *data,		/* array to fill from DSP */
    DSPMemorySpace memorySpace, /* from <dsp/dsp_structs.h> */
    DSPAddress startAddress,	/* within DSP memory */
    int skipFactor,		/* 1 means normal contiguous transfer */
    int wordCount)		/* from DSP perspective */
{
    /* See DSPObject.c */
    return(DSPReadArraySkipMode((void *)data,memorySpace,startAddress,
			   skipFactor,wordCount,DSP_MODE32));
}


BRIEF int DSPReadFix24ArrayLJ(
    DSPFix24 *data,		/* array to fill from DSP */
    DSPMemorySpace memorySpace, /* from <dsp/dsp_structs.h> */
    DSPAddress startAddress,	/* within DSP memory */
    int skipFactor,		/* 1 means normal contiguous transfer */
    int wordCount)		/* from DSP perspective */
{
    /* See DSPObject.c */
    return(DSPReadArraySkipMode((void *)data,memorySpace,startAddress,
			   skipFactor,wordCount,DSP_MODE32_LEFT_JUSTIFIED));
}


BRIEF int DSPReadPackedArray(
    unsigned char *data,	/* Data to fill from DSP */
    DSPMemorySpace memorySpace, /* DSP memory space */
    DSPAddress startAddress,	/* DSP start address */
    int skipFactor,		/* DSP index increment per DSP word read */
    int wordCount)		/* DSP words = byte count / 3 */
{	
    return(DSPReadArraySkipMode((void *)data,
				memorySpace,startAddress,skipFactor,
				wordCount,DSP_MODE24));
}


BRIEF int DSPReadByteArray(
    unsigned char *data,	/* Data to fill from DSP */
    DSPMemorySpace memorySpace, /* DSP memory space */
    DSPAddress startAddress,	/* DSP start address */
    int skipFactor,		/* DSP index increment per byte transferred */
    int byteCount)		/* Same as DSP word count */
{	
    return(DSPReadArraySkipMode((void *)data,
				memorySpace,startAddress,skipFactor,
				byteCount,DSP_MODE8));
}


BRIEF int DSPReadShortArray(
    short int *data,		/* Packed data to fill from DSP */
    DSPMemorySpace memorySpace, /* DSP memory space */
    DSPAddress startAddress,	/* DSP start address */
    int skipFactor,		/* DSP index increment per array element */
    int wordCount)		/* DSP word count = byte count / 2 */
{	
    return(DSPReadArraySkipMode((void *)data,memorySpace,startAddress,
			       skipFactor,wordCount,DSP_MODE16));
}


BRIEF int DSPReadIntArray(
    int *intArray,
    DSPMemorySpace memorySpace,
    DSPAddress startAddress,
    int skipFactor,
    int wordCount)
{
    if (wordCount<=0)
      return(0);
    ec = DSPReadArraySkipMode(intArray,memorySpace,startAddress,skipFactor,
			wordCount,DSP_MODE32);
    ec = DSPFix24ToIntArray(intArray,intArray,wordCount);
    return(ec);
}

    
BRIEF int DSPReadIntArrayXY(
    int *intArray,
    DSPMemorySpace memorySpace,
    DSPAddress startAddress,
    int skipFactor,
    int wordCount)
{
    return DSPReadIntArray(intArray,
			   memorySpace,startAddress,skipFactor,wordCount);
}

    
BRIEF int DSPReadFloatArray(
    float *floatArray,
    DSPMemorySpace memorySpace,
    DSPAddress startAddress,
    int skipFactor,
    int wordCount)
{
    if (wordCount<=0)
      return(0);
    ec = DSPReadArraySkipMode((void *)floatArray,memorySpace,startAddress,
			 skipFactor,wordCount,DSP_MODE32);
    if (ec) return(ec);
    ec = DSPFix24ToFloatArray((void *)floatArray,floatArray,wordCount);
    return(ec);
}


BRIEF int DSPReadFloatArrayXY(
    float *floatArray,
    DSPMemorySpace memorySpace,
    DSPAddress startAddress,
    int skipFactor,
    int wordCount)
{
    return DSPReadFloatArray(floatArray,
			       memorySpace,startAddress,skipFactor,wordCount);
}


BRIEF int DSPReadDoubleArray(
    double *doubleArray,
    DSPMemorySpace memorySpace,
    DSPAddress startAddress,
    int skipFactor,
    int wordCount)
{
    DSPFix24 *fix24Array;
    if (wordCount<=0)
      return(0);
    fix24Array = (DSPFix24 *)malloc(wordCount * sizeof(DSPFix24));
    ec = DSPReadArraySkipMode((void *)fix24Array,memorySpace,startAddress,
			      skipFactor,wordCount,DSP_MODE32);
    if (ec) return(ec);
    ec = DSPFix24ToDoubleArray((void *)fix24Array,doubleArray,wordCount);
    free(fix24Array);
    return(ec);
}


BRIEF int DSPReadDoubleArrayXY(
    double *doubleArray,
    DSPMemorySpace memorySpace,
    DSPAddress startAddress,
    int skipFactor,
    int wordCount)
{
    return DSPReadDoubleArray(doubleArray,
			      memorySpace,startAddress,skipFactor,wordCount);
}

/************************ INTERACTIVE DEBUGGING SUPPORT **********************/

int _DSPPrintDatum(
    FILE *fp,
    DSPFix24 word)
{
    unsigned int usword; 
    int sword; 
    float fword;

    usword = word;
    if (word & (1<<23)) 
      usword |= (0xFF << 24); /* ignore overflow */
    sword = usword; /* re-interpret as signed */
    fword = DSPIntToFloat(sword);
    fprintf(fp,"0x%06X = %-8u = %10.8f\n",(unsigned int)word,usword,fword);
    
    return 0;
}


int _DSPPrintValue(
    DSPMemorySpace space,
    DSPAddress address)
{
    return _DSPPrintDatum(stderr,DSPGetValue(space,address));
}


int _DSPDump(
    char *name)
{
    int i,j,ec, address, count=0, skipFactor = 1;
    DSPMemorySpace spc;
    DSPFix24 data[8192];
    char *fn, *spcn;
    FILE *fp;

    if (DSPMKIsWithSoundOut() || DSPMKWriteDataIsEnabled())
      DSPMKStopSoundOut();

    address = 0;
    spc = DSP_MS_Y;

    for (i=0; i<4; i++) {
	switch (i) {
	case 0:			/* X */
	    spc = DSP_MS_X;
	case 1:			/* Y */
	    count = 256;
	    break;
	case 2:			/* L --> external Y */
	    address = 512;
	    count = 8192-512;
	    break;
	case 3:			/* P */
	    count = 512;
	    break;
	}
	if (ec = DSPReadArraySkipMode(data,spc,address,skipFactor,
				      count,DSP_MODE32))
	  _DSPError(ec,"_DSPDump: DSP read failed");
	spcn = (i==2? "E":(char *)DSPMemoryNames(i));
	fn = DSPCat(name,DSPCat(spcn,".ram"));
	fp = _DSPMyFopen(fn,"w");
	for (j=0;j<count;j++) {
	    fprintf(fp,"%c[0x%04X=%-5d] = ",
	    spc,(unsigned int)j+address,j+address);
	    _DSPPrintDatum(fp,data[j]);
	}
	fclose(fp);
    }
    return(0);
}


/************************ UNTIMED TRANSFERS WITHIN DSP ***********************/

/* Currently only MK monitor has this service */

BRIEF int DSPMKBLT(
    DSPMemorySpace memorySpace,
    DSPAddress sourceAddr,
    DSPAddress destinationAddr,
    int wordCount)
{
    return(DSPMKBLTSkipTimed(DSPMK_UNTIMED,memorySpace,sourceAddr,1,
			       destinationAddr,1,wordCount));
}

BRIEF int DSPMKBLTB(
    DSPMemorySpace memorySpace,
    DSPAddress sourceAddr,
    DSPAddress destinationAddr,
    int wordCount)
{
    return(DSPMKBLTSkipTimed(DSPMK_UNTIMED,memorySpace,
			   sourceAddr+wordCount-1,NEGATIVE1,
			   destinationAddr+wordCount-1,NEGATIVE1,
			   wordCount));
}

/**************************** TIMED TRANSFERS TO DSP ***********************/

/* (Plus untimed special cases of the timed transfers) */

/* KEEP FOR 1.0 MK BINARY COMPATIBILITY */
BRIEF int _DSPSendValueTimed(
    DSPFix48 *aTimeStampP,
    DSPMemorySpace space,
    int addr,
    int value)
{
    return DSPMKSendValueTimed(aTimeStampP, value, space, addr);
}

int DSPMKSendValueTimed(
    DSPFix48 *aTimeStampP,
    int value,
    DSPMemorySpace space,
    int addr)
{
    DSPAddress opcode;
    DSPFix24 cvalue = DSP_FIX24_CLIP(value);

    if (cvalue != value && ((value|0xFFFFFF) != -1))
      _DSPError1(DSP_EFPOVFL,
		     "DSPMKSendValueTimed: Value 0x%s overflows 24 bits",
		     _DSPCVHS(value));

#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(DSPGetSimulatorFP(),
	      ";; Send value 0x%X = `%d = %s to %s:$%X %s\n",
	      value,value,DSPFix24ToStr(value),
	      DSPMemoryNames(space),addr,
	      DSPTimeStampStr(aTimeStampP));
#endif SIMULATOR_POSSIBLE

    switch(space) {
      case DSP_MS_P:	
	opcode = dsp_hm_poke_p[s_idsp];
	break;
      case DSP_MS_X:
	opcode = dsp_hm_poke_x[s_idsp];
	break;
      case DSP_MS_Y:
	opcode = dsp_hm_poke_y[s_idsp];
	break;
    default:
	return(_DSPError1(EDOM,
			  "DSPMKSendValueTimed: cannot send memory space: "
			  "%s", (char *) DSPMemoryNames((int)space)));
    }
    return DSPMKCallTimedV(aTimeStampP,opcode,2,value,addr);
    /* address must be atop value in arg stack */
    /* reason: address takes 2 cycles to set up */
}

BRIEF int DSPMKSendValue(int value, DSPMemorySpace space, int addr)
{
    return DSPMKSendValueTimed(&DSPMKTimeStamp0,value,space,addr);
}

/* KEEP FOR 1.0 BINARY COMPATIBILITY */
BRIEF int DSPWriteValue1p0(DSPMemorySpace space, int addr, int value)
{
    return DSPWriteArraySkipMode(&value,space,addr,0,1,DSP_MODE32);
}

BRIEF int DSPWriteValue(int value, DSPMemorySpace space, int addr)
{
    /* return DSPWriteArraySkipMode(&value,space,addr,0,1,DSP_MODE32); */
    DSPAddress opcode;
    DSPFix24 cvalue = DSP_FIX24_CLIP(value);
    if (addr < 0)
      return DSP_EMISC;
    if (cvalue != value && ((value|0xFFFFFF) != -1))
      _DSPError1(DSP_EFPOVFL,
		     "DSPWriteValue: Value 0x%s overflows 24 bits",
		     _DSPCVHS(value));

#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(DSPGetSimulatorFP(),
	      ";; Send value 0x%X = `%d = %s to %s:$%X\n",
	      value,value,DSPFix24ToStr(value), DSPMemoryNames(space),addr);
#endif SIMULATOR_POSSIBLE
    switch(space) {
      case DSP_MS_P:	
	opcode = dsp_hm_poke_p[s_idsp];
	break;
      case DSP_MS_X:
	opcode = dsp_hm_poke_x[s_idsp];
	break;
      case DSP_MS_Y:
	opcode = dsp_hm_poke_y[s_idsp];
	break;
    default:
	return(_DSPError1(EDOM,
			  "DSPWriteValue: cannot write memory space: "
			  "%s", (char *) DSPMemoryNames((int)space)));
    }
    return DSPCallV(opcode,2,value,addr);
}


/* KEEP FOR 1.0 BINARY COMPATIBILITY */
BRIEF int _DSPSendLongTimed(
    DSPFix48 *aTimeStampP,
    int addr,
    DSPFix48 *aFix48Val)
{
    return DSPMKSendLongTimed(aTimeStampP, aFix48Val, addr);
}

BRIEF int DSPMKSendLongTimed(
    DSPFix48 *aTimeStampP,
    DSPFix48 *aFix48Val,
    int addr)
{
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) 
      fprintf(DSPGetSimulatorFP(),
	      ";; Send long 0x%X,,0x%X =%s to l:$%X %s\n",
	      aFix48Val->high24,aFix48Val->low24,
	      DSPTimeStampStr(aFix48Val),addr, DSPTimeStampStr(aTimeStampP));
#endif SIMULATOR_POSSIBLE
#ifdef NO_REVERT
    return DSPMKCallTimedV(aTimeStampP,dsp_hm_poke_l[s_idsp],3,
			   aFix48Val->high24,aFix48Val->low24,addr);
#else
    DSP_UNTIL_ERROR(DSPMKSendValueTimed(aTimeStampP,
				 aFix48Val->high24,
				 DSP_MS_X,addr));

    DSP_UNTIL_ERROR(DSPMKSendValueTimed(aTimeStampP,
				 aFix48Val->low24,
				 DSP_MS_Y,addr));
#endif
    return(0);
}

BRIEF int DSPMKSendLong(DSPFix48 *aFix48Val, int addr)
{
    return DSPMKSendLongTimed(&DSPMKTimeStamp0,aFix48Val,addr);
}

/* KEEP FOR 1.0 BINARY COMPATIBILITY */
BRIEF int DSPWriteLong1p0(int addr, DSPFix48 *aFix48Val)
{
    return DSPMKSendLongTimed(DSPMK_UNTIMED,aFix48Val,addr);
}

BRIEF int DSPWriteLong(DSPFix48 *aFix48Val, int addr)
{
    return DSPMKSendLongTimed(DSPMK_UNTIMED,aFix48Val,addr);
}

BRIEF int DSPMKMemoryFillSkipTimed(
    DSPFix48 *aTimeStampP,
    DSPFix24 fillConstant,	/* value to fill memory with */
    DSPMemorySpace space,	/* space of memory fill in DSP */
    DSPAddress address,		/* first address of fill in DSP memory	*/
    int skip,			/* skip factor in DSP memory */
    int wordCount)		/* number of DSP memory words to fill */
{
    int err;
    DSPAddress opcode;
    if (wordCount <= 0) return(0);
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(DSPGetSimulatorFP(),
	      ";; Fill %d words %s:$%X:%d:$%X with $%X %s\n",
	      wordCount,DSPMemoryNames(space),
	      address,skip,address+skip*wordCount-1,fillConstant,
	      DSPTimeStampStr(aTimeStampP));
#endif SIMULATOR_POSSIBLE

    switch(space) {
      case DSP_MS_P:	
	opcode = dsp_hm_fill_p[s_idsp];
	break;
      case DSP_MS_X:
	opcode = dsp_hm_fill_x[s_idsp];
	break;
      case DSP_MS_Y:
	opcode = dsp_hm_fill_y[s_idsp];
	break;
      default:
	return _DSPError1(EDOM,
			  "DSPMKMemoryFillTimed: "
			  "can't fill memory space %s",
			  (char *) DSPMemoryNames((int)space));
    }
    /*** FIXME: Add skip factor argument to DSP routines when ready ***/
    if (skip != 1) {
	fprintf(stderr,"DSPMKMemoryFillSkipTimed: "
		"Skip factor not yet implemented\n");
	exit(1);
    }

    err = DSPMKCallTimedV(aTimeStampP,opcode,3,wordCount,fillConstant,address);
    /* want wordCount at stack bottom for in-place use */
    /* address must be atop value in arg stack	*/
    /* reason: address takes 2 cycles to set up */

/* The following change slows down SB patch loads too much - jos 2/2/95 */
#if 0
#if m68k
    /* Long memory fills can cause the driver queue to fill up and deadlock */
    if (wordCount > 512 && (!aTimeStamp)) /* could also do for timed-0 */
        DSPAwaitHostMessage(wordCount); 
#endif
#endif

    return err;
}

BRIEF int DSPMKMemoryFillTimed(
    DSPFix48 *aTimeStampP,
    DSPFix24 fillConstant,
    DSPMemorySpace space,
    DSPAddress address,
    int count)
{
    return DSPMKMemoryFillSkipTimed(aTimeStampP,fillConstant,
				  space,address,1,count);
}

BRIEF int DSPMKSendMemoryFill(
    DSPFix24 fillConstant,
    DSPMemorySpace space,
    DSPAddress address,
    int count)
{
    return DSPMKMemoryFillTimed(&DSPMKTimeStamp0,fillConstant,
				  space,address,count);
}

BRIEF int DSPMKMemoryClearTimed(
    DSPFix48 *aTimeStampP, 
    DSPMemorySpace space,
    DSPAddress address,
    int count)
{
    return DSPMKMemoryFillTimed(aTimeStampP,0,space,address,count);
}

BRIEF int DSPMKSendMemoryClear(
    DSPMemorySpace space,
    DSPAddress address,
    int count)
{
    return DSPMKMemoryClearTimed(&DSPMKTimeStamp0,space,address,count);
}

BRIEF int DSPMKClearDSPSoundOutBufferTimed(DSPTimeStamp *aTimeStampP)
{
    return DSPMKMemoryFillTimed(aTimeStampP,0,DSP_MS_Y,DSP_YB_DMA_W,
				2*DSPMKSoundOutDMASize());
}

BRIEF int DSPMKSendArraySkipModeTimed(
    DSPFix48 *aTimeStampP,
    void *data, 	/* See DSPObject.c(DSPWriteArraySkipMode) for interp */
    DSPMemorySpace space,
    DSPAddress address,
    int skipFactor,
    int count,		/* DSP wdcount (e.g. 1 for each byte in DSP_MODE8) */
    int mode)		/* from FIXME */
{
    int nwds;
    DSPFix24 val;
#if SIMULATOR_POSSIBLE
    if (sim = s_simulated[s_idsp])
      fprintf(DSPGetSimulatorFP(),
	      ";; Send %d words to %s:$%X:%d:$%X %s\n",
	      count,DSPMemoryNames(space),
	      address,skipFactor,address+skipFactor*count-1,
	      DSPTimeStampStr(aTimeStampP));
#endif SIMULATOR_POSSIBLE
    
    address--; /* We pass the last address of the buffer to the DSP routine. 
		  So we decrement address now and all works out below. */
    
/*
 * Optimization is omitted here because
 * since the array transfers are already large, we may lose more in the
 * extra handling than we gain from the message combining.  It is important
 * to optimize this function for speed, and skipping optimization gives the
 * most direct path to the output.
 * 
 * However, see comment by DAJ below.
 */

//   DSPMKFlushTimedMessages();
   /* Changed by DAJ from DSPMKFlushTimedMessages() to _DSPCheckTMQFlush().  
    * Aug 9 1996 */
   _DSPCheckTMQFlush(aTimeStampP,count+9);  /* See below */

/* The following is taken out as an optimization because the Music Kit
   always has parens around its loads */
#if 0    
   if (aTimeStampP)
      DSPMKOpenParenTimed(aTimeStampP); /* Don't allow TMQ underrun */
#endif

    while (count > 0) {
	nwds = MIN(count,dsp_nb_hms[s_idsp] - 9);
	/* The - 9 above is 
	   4 for arguments nwds,skipFactor,address, and space (below).
	   Room (3 words) for accompanying timed host msg already reserved 
	   by DSP in the DM_TMQ_ROOM reply.  We will write nwds+4+3 words
	   to the HMS, and this cannot exceed dsp_nb_hms[s_idsp]-2 (HMS size
	   -2 for the begin-mark and end-mark in the HMS). Hence the 9 above.
	 */

#if SIMULATOR_POSSIBLE
	if (sim)
	  fprintf(DSPGetSimulatorFP(),
		  ";; %d-word Timed Message Data to TX %s\n",
		  nwds,DSPTimeStampStr(aTimeStampP));
#endif SIMULATOR_POSSIBLE

#if TRACE_POSSIBLE
	if (_DSPTrace & DSP_TRACE_TMQ)
	  printf("msg = %3d words --> TMQ\n",nwds);
#endif TRACE_POSSIBLE

	if (s_bail_out[s_idsp])
	  return DSP_EABORT;

	_DSPStartHmArray();
	_DSPExtendHmArrayMode(data,nwds,mode);
	_DSPExtendHmArray(&nwds,1);
	_DSPExtendHmArray(&skipFactor,1);
	address += nwds;
	_DSPExtendHmArray(&address,1);
	val = (DSPFix24)space;
	_DSPExtendHmArray(&val,1);
	_DSPFinishHmArray(aTimeStampP,dsp_hm_poke_n[s_idsp]);
	if(DSPErrorNo=_DSPWriteHm())
	  return(DSPErrorNo);

	count -= nwds;
	data += nwds * s_mode_to_width(mode);
    }

/*  if (aTimeStampP)
      DSPMKCloseParenTimed(aTimeStampP); */
    return DSPErrorNo;
}

/* KEEP FOR 1.0 BINARY COMPATIBILITY */
BRIEF int _DSPSendArraySkipTimed(
    DSPFix48 *aTimeStampP,
    DSPMemorySpace space,
    DSPAddress address,
    DSPFix24 *data,		/* DSP gets rightmost 24 bits of each word */
    int skipFactor,
    int count)
{
    return DSPMKSendArraySkipModeTimed(aTimeStampP,data,space,address, 
    				      skipFactor,count,DSP_MODE32);
}


BRIEF int DSPMKSendArraySkipTimed(
    DSPFix48 *aTimeStampP,
    DSPFix24 *data,		/* DSP gets rightmost 24 bits of each word */
    DSPMemorySpace space,
    DSPAddress address,
    int skipFactor,
    int count)
{
    return DSPMKSendArraySkipModeTimed(aTimeStampP,data,space,address, 
    				      skipFactor,count,DSP_MODE32);
}
    
BRIEF int DSPMKSendArrayTimed(
    DSPFix48 *aTimeStampP, 
    DSPFix24 *data,		/* DSP gets rightmost 24 bits of each word */
    DSPMemorySpace space,
    DSPAddress address,
    int count)
{
    return DSPMKSendArraySkipModeTimed(aTimeStampP,data,space,address,1,
				       count,DSP_MODE32);
}

BRIEF int DSPMKSendShortArraySkipTimed(
    DSPFix48 *aTimeStampP,
    short int *data,  /* 2 DSP words get left and right 16 bits of data word */
    DSPMemorySpace space,
    DSPAddress address,
    int skipFactor,
    int count)
{
    return DSPMKSendArraySkipModeTimed(aTimeStampP,(DSPFix24 *)data,
				      space,address, 
    				      skipFactor,count,DSP_MODE16);
}
    
/* FIXME - order should be (timeStamp,data,space,addr,count) */
int _DSPMKSendUnitGeneratorWithLooperTimed(
    DSPFix48 *aTimeStampP, 
    DSPMemorySpace space,
    DSPAddress address,
    DSPFix24 *data,		/* DSP gets rightmost 24 bits of each word */
    int count,
    int looperWord)
{
    int mapped;
    int z,nwds,skipFactor=1;
    DSPFix24 val;
    if (s_bail_out[s_idsp])
      return DSP_EABORT;

    mapped = _DSPMappedOnlyIsEnabled();

#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp])
      fprintf(DSPGetSimulatorFP(),
	      ";; Send %d words plus 'jmp 0x%X' word to %s:$%X:$%X %s\n",
	      count,looperWord & 0xfff,DSPMemoryNames(space),
	      address,address+count-1+1,
	      DSPTimeStampStr(aTimeStampP));
#endif SIMULATOR_POSSIBLE
    
    address--; /* We pass the last address of the buffer to the DSP routine. 
		  So we decrement address now and everything works out below.*/

    DSPMKFlushTimedMessages();	/* Flush to preserve order since no opt */

#if 0
    if (aTimeStampP)
      DSPMKOpenParenTimed(aTimeStampP); /* Don't allow TMQ underrun */
#endif

    while (count > 0) {
	/* See DSPMKSendArraySkipTimed: */
	nwds = MIN(count,dsp_nb_hms[s_idsp] - 9);	

#if SIMULATOR_POSSIBLE
	if (s_simulated[s_idsp])
	  fprintf(DSPGetSimulatorFP(),
		  ";; %d-word Timed Message Data to TX %s\n",
		  nwds,DSPTimeStampStr(aTimeStampP));
#endif SIMULATOR_POSSIBLE

#if TRACE_POSSIBLE
	if (_DSPTrace & DSP_TRACE_TMQ)
	  printf("msg = %3d words --> TMQ\n",nwds);
#endif TRACE_POSSIBLE

	_DSPStartHmArray();
	_DSPExtendHmArray(data,nwds);
	if (count - 2 <= nwds) {  
	    z = 0;
	    _DSPExtendHmArray(&z,1); 
	    /* Need NOP if last UG ends with DO loop */
	    _DSPExtendHmArray(&looperWord,1);
	    nwds += 2;	/* account for new words */
	}
	_DSPExtendHmArray(&nwds,1);
	_DSPExtendHmArray(&skipFactor,1);
	address += nwds;
	_DSPExtendHmArray(&address,1);
	val = (DSPFix24)space;
	_DSPExtendHmArray(&val,1);
	_DSPFinishHmArray(aTimeStampP,dsp_hm_poke_n[s_idsp]);
	if(DSPErrorNo=_DSPWriteHm())
	  return(DSPErrorNo);

	count -= nwds;
	data += nwds;
	
    }

/*  if (aTimeStampP)
      DSPMKCloseParenTimed(aTimeStampP); */

    return DSPErrorNo;
}


/* Special hack for atomically piggybacking nops to UG code in music kit */
/* FIXME - Flush? Does anyone use it? */
/* FIXME - order should be (timeStamp,data,space,addr,count) */
BRIEF int _DSPMKSendTwoArraysTimed(
    DSPFix48 *aTimeStampP, 
    DSPMemorySpace space,
    DSPAddress address,
    DSPFix24 *data1,
    int count1,
    DSPFix24 *data2,
    int count2)
{
    DSPFix24 *data;
    int ec,count,i;
    count = count1 + count2;
    data = (DSPFix24 *) alloca( count * sizeof(DSPFix24) );
    for (i=0;i<count1;i++)
      data[i] = data1[i];
    for (i=0;i<count2;i++)
      data[count1+i] = data2[i];
    ec = DSPMKSendArraySkipModeTimed(aTimeStampP,data,space,address,1,
				     count,DSP_MODE32);
    return(ec);
}

BRIEF int DSPMKSendArray(
    DSPFix24 *data,		/* DSP gets rightmost 24 bits of each word */
    DSPMemorySpace space,
    DSPAddress address,
    int count)
{
    return DSPMKSendArraySkipModeTimed(&DSPMKTimeStamp0,data,space,address,1,
				       count,DSP_MODE32);
}

/************************ TIMED TRANSFERS WITHIN DSP ***********************/

BRIEF int DSPMKBLTSkipTimed(
    DSPFix48 *timeStamp,
    DSPMemorySpace memorySpace,
    DSPAddress srcAddr,
    DSPFix24 srcSkip,
    DSPAddress dstAddr,
    DSPFix24 dstSkip,
    int wordCount)
{
    DSPAddress opcode;
    
    if (wordCount <= 0) return(0);
#if SIMULATOR_POSSIBLE
    if (s_simulated[s_idsp]) {
	int sourceSkip, destinationSkip;	  /* DAJ */
	sourceSkip = DSPFix24ToInt(srcSkip);	  /* These may be negative. */
	destinationSkip = DSPFix24ToInt(dstSkip); 
	fprintf(DSPGetSimulatorFP(),
		";; BLT %d words from %s:$%X:%d:$%X to %s:$%X:%d:$%X\n",
		wordCount,
		DSPMemoryNames(memorySpace),
		srcAddr,
		sourceSkip,
		srcAddr+wordCount*sourceSkip-1,
		DSPMemoryNames(memorySpace),
		dstAddr,
		destinationSkip,
		dstAddr+wordCount*destinationSkip-1);
    }
#endif SIMULATOR_POSSIBLE
    switch(memorySpace) {
      case DSP_MS_P:	
	opcode = dsp_hm_blt_p[s_idsp];
	break;
      case DSP_MS_X:
	opcode = dsp_hm_blt_x[s_idsp];
	break;
      case DSP_MS_Y:
	opcode = dsp_hm_blt_y[s_idsp];
	break;
      default:
	return(_DSPError1(EDOM,
	   "DSPMKBLTSkipTimed: cannot BLT memory space: %s",
			  (char *)DSPMemoryNames((int)memorySpace)));
    }

    return (DSPMKCallTimedV(timeStamp,opcode,5,wordCount,
			  srcAddr,srcSkip,dstAddr,dstSkip));
}

BRIEF int DSPMKBLTTimed(
    DSPFix48 *timeStamp,
    DSPMemorySpace memorySpace,
    DSPAddress sourceAddr,
    DSPAddress destinationAddr,
    int wordCount)
{
    return(DSPMKBLTSkipTimed(timeStamp,memorySpace,sourceAddr,1,
			       destinationAddr,1,wordCount));
}

BRIEF int DSPMKBLTBTimed(
    DSPFix48 *timeStamp,
    DSPMemorySpace memorySpace,
    DSPAddress sourceAddr,
    DSPAddress destinationAddr,
    int wordCount)
{
    return(DSPMKBLTSkipTimed(timeStamp,memorySpace,
			   sourceAddr+wordCount-1,NEGATIVE1,
			   destinationAddr+wordCount-1,NEGATIVE1,
			   wordCount));
}

BRIEF int DSPMKSendBLT(
    DSPMemorySpace memorySpace,
    DSPAddress sourceAddr,
    DSPAddress destinationAddr,
    int wordCount)
{
    return(DSPMKBLTSkipTimed(&DSPMKTimeStamp0,memorySpace,sourceAddr,1,
			       destinationAddr,1,
			       wordCount));
}

BRIEF int DSPMKSendBLTB(
    DSPMemorySpace memorySpace,
    DSPAddress sourceAddr,
    DSPAddress destinationAddr,
    int wordCount)
{
    return(DSPMKBLTSkipTimed(&DSPMKTimeStamp0,memorySpace,
			   sourceAddr+wordCount-1,-1,
			   destinationAddr+wordCount-1,-1,
			   wordCount));
}

BRIEF int DSPWriteSCI(unsigned char value, DSPSCITXReg reg)
{
    DSPAddress opcode;
    DSPAddress addr;
    DSPFix24 cvalue = DSP_FIX24_CLIP(value);
    DSPMKFlushTimedMessages();	/* Flush to preserve order since no opt */
    if (cvalue != value && ((value|0xffffff) != -1))
      _DSPError1(DSP_EFPOVFL,
		 "DSPWriteValue: Value 0x%s overflows 24 bits",
		 _DSPCVHS(value));
    opcode = dsp_hm_poke_sci[s_idsp];
    addr = (int)reg + 0xfff3;
    return DSPCallV(opcode,2,value,addr);
}

/*

Modification history:

  12/28/87/jos - File created
  12/18/89/jos - Added "if(s_sound_out)
  			while( DSPAwaitHF3Clear(_DSP_MACH_DEADLOCK_TIMEOUT));" 
		 to _DSPFlushTMQ(). This slows down throughput a lot, but the
		 possibility of deadlock is made extremely smaller.
  02/19/90/jos - DSPMK{Freeze,Thaw}Orchestra() added (from DSPControl.c)
		 Note that this changes HF0 from an abort signal (which
	 	 was never used as such) to a freeze signal. We still have
		 the abort untimed message and the old "pause" command which
		 merely halts the advance of the sample counter in the DSP.
  03/13/90/jos - Added DSPGetHF2AndHF3(void).
  03/21/90/jos - _DSPCheckTMQFlush() now flushes on timed-zero messages.
  03/21/90/jos -  DSPMKCallTimed() also flushes on timed-zero messages.
  03/21/90/mtm - added support for dsp commands file
  03/26/90/jos - added single-file read-data support
  04/17/90/jos - added read-data file seek support
  04/17/90/jos - revised ReadArraySkipMode, WriteArraySM, and setupProtocol.
  04/17/90/jos - read-data, when enabled, steals half of write-data buffers.
  04/17/90/jos - flushed Get/Set * BufferCount.  Can only do 1 page anyway?
  04/19/90/mtm - Use SND_FORMAT_DSP_COMMANDS in DSPCloseCommandsFile().
  04/23/90/jos - flushed unsupported entry points.
  04/23/90/jos - changed _DSPSendHm() to _DSPWriteHm()
  05/01/90/jos - added DSPLoadSpec *DSPGetSystemImage(void);
  05/01/90/jos - added DSPMKSoundOutDMASize(void);
  05/01/90/jos - added call to DSPMKFlushTimedMessages() in DSPClose().
  05/04/90/jos - explicitly including dsp_messages.h
  05/14/90/jos - _DSPCheckTMQFlush() no longer flushes on timed-zero messages.
  		 We decided it was worth supporting multicomponent TZMs in DSP.
  05/26/90/jos - Forced complex DMA mode bit always in s_setupProtocol(). [*]
  06/04/90/jos - Flushed everything to do with *map_file*.
  06/06/90/jos - Undid [*] above because non-dma reads must not be intercepted.
  		 In complex DMA mode, any in of the form 0x4???? or 0x5???? is
		 intercepted as a DMA request. Need another host flag HF4
		 which is set to enable interception of DSP data.
  06/08/90/jos - Rewrote DSP{Read,Write}ArraySkipMode() and descendants.
  06/08/90/jos - Added data_width arg to _DSPWriteData(). Made it static.
  		 Changed its name to s_writeDSPArrayNoDMA().
  06/08/90/jos - Flushed _DSPWriteDatum(). Special case of s_writeDSPDatum().
  06/22/90/jos - Added negotiation port "s_dsp_neg_port"
  08/28/90/jos - Removed history up through 1.0
  10/25/90/jos - Enabled SND_DSP_PROTO_TXD protocol bit.
  05/30/91/jos - Added timeout break-up to DSPReadMessages()
  06/30/91/jos - Fixed terrible bug which utterly broke DSPDataIsAvailable()
  07/01/91/jos - Reabsorbed all source include files for multi-DSP support.
  07/02/91/jos - Revived mapped array I/O (for sake of QP board support).
  		 Flushed parametric sound support stubs to grub/ParametricS*.
  		 Flushed do_mapped_array_{reads,writes} support.
		 	Now there's only one mapped-related bit: s_mapped_only.
			We no longer support going in and out of mapped mode.
  07/20/91/jos - s_cur_pri[i] was being initialized to 0 which is DSP_MSG_HIGH!
  		 Initialized to DSP_MSG_LOW on start-up.  This fixed the 
		 write-data hanging bug "playscore -w e5.snd Examp5".
		 FIXME: The priority-setting logic in _DSPWriteHostMessage()
		 (search for "<=old_pri") should be carefully reviewed.
  10/27/91/jos - Changed DSPAwaitData() to poll RXDF instead of calling
  		 DSPReadMessages() (which aimed at sleeping in msg_receive).
		 The problem is that if !DSP_CAN_INTERRUPT, reading messages
		 in effect throws away the data from the DSP! 
		 dspramtest from Ken Taylor flushed out this bug.
  11/08/91/mtm - Changed import locations of cpu.h and snd_dspreg.h
  08/30/92/daj - Changed references to TX* and RX* to be int if IS_NEXT_DSP
  12/20/92/daj - Added check for !s_mapped_only in DSPSetHostMessageMode()
  12/20/92/daj - Added DSPWriteSCI().
  12/20/92/daj - Fixed bug in DSPMKStopSoundOut().  Was calling DSPMKStartSSISoundOut()
                 instead of DSPMKStopSSISoundOut().  Added conditional comp. loop
                 for QP debugging.  Added s_ssi_read_data and associated functions.
                 Added check for s_ssi_read_data in buffer size setup.
  1/25/93/daj -  Flushed midi host message.
  26/11/95/daj -  Various changes to support Intel read-back from DSP and multiple DSPs

*/

