#ifndef __MK__dsp_H___
#define __MK__dsp_H___
 /*
	_dsp.h

	Copyright 1988-1992, NeXT Inc.  All rights reserved.
  
	This file contains definitions, typedefs, and forward declarations
	used by libdsp functions.

	Modification history
	07/01/88/jos - prepended '/' to all RELATIVE file names
		       in case DSP environment variable has no trailing '/'
	10/07/88/jos - Changed default DSP directory and filenames for release.
	12/12/89/jos - Changed _DSP_MACH_SEND_TIMEOUT from 0 to 100 ms.
	01/13/90/jos - Introduced MAPPED_ONLY_POSSIBLE macro for ifdef's.
	01/13/90/jos - Introduced SIMULATOR_POSSIBLE macro for ifdef's.
	01/13/90/jos - Introduced TRACE_POSSIBLE macro for ifdef's.
	01/13/90/jos - Removed puzzling '#include "DSPMessage.h"' at EOF (!?)
	04/23/90/jos - Added private "aux dsp structures" from dsp_structs.h.
	08/27/92/daj - Changed definition of DSPRegs
*/
#ifndef _LIBDSP_
#define _LIBDSP_

#ifdef GNUSTEP
#define import include
#endif

#define SIMULATOR_POSSIBLE 0
#define TRACE_POSSIBLE 1

#define NO_VPRINTF 1

#define REMEMBER(x) /* x */

/*** INCLUDE FILES ***/

#ifdef WIN32
#import <io.h>  // LMS if we become more OpenStep-ish, this won't be necessary
#else
#import <sys/file.h>
#import <sys/time.h>		/* DSPAwaitData(), DSPMessageGet() */
                               /* DSPAwaitUnsignedReply() _DSPAwait*() */
#endif
#import <stdlib.h> // for Windows prototypes, but it's general enough
#import <string.h>

/* For access(2) which does not have definitions on Windows LMS */
#ifdef WIN32
#define R_OK	4/* test for read permission */
#define W_OK	2/* test for write permission */
#define X_OK	1/* test for execute (search) permission */
#define F_OK	0/* test for presence of file */
#endif

/*
  *** NOTE *** math.h allocates 0.0 for use by the built-in 
  functions such as log.  This allocation screws up the making 
  of the Global data section of a shared library. Thus, math.h
  cannot be included by DSPGlobals.c.
*/

#import <math.h>
#import <ctype.h>

extern int DSPDefaultTimeLimit;

/* DSP include files */

#import "dsp.h" /* main DSP header file */

#define _DSP_MAX_LINE 256	/* max chars per line on input (via fgets) */
#define _DSP_MAX_NAME 80	/* Allow for long paths (getfil.c, geti.c) */
#define _DSP_MAX_CMD 12		/* Max no. chars in a command (indexs.c) */

#if 0
#define _DSP_EXPANDSIZE 512	/* must be even (for l: data in _DSPLnkRead) */
#define _DSP_EXPANDSMALL 10	/* This one can be left small */
#else /*** FIXME: malloc bug work-around? ***/
#define _DSP_EXPANDSIZE 81920	/* must be even (for l: data in _DSPLnkRead) */
#define _DSP_EXPANDSMALL 81920	/* This one can be left small */
#endif

#define _DSP_NULLC 0		/* Null character */
#define _DSP_NOT_AN_INT (0x80000000)
#define _DSP_PATH_DELIM '/'	/* don't ask */

#define _DSP_COUNT_STEP (10)	/* how many DSPs to allocate for at a time */

/* Host message type codes (OR'd with host message opcode) */
#define _DSP_HMTYPE_UNTIMED 0x880000 /* untimed host message (stack marker) */
#define _DSP_HMTYPE_TIMEDA  0x990000 /* absolutely timed host message */
#define _DSP_HMTYPE_TIMEDR  0xAA0000 /* relatively timed (delta) host message */

/*** FIXME: Flush in 1.1 ***/
#define _DSP_UNTIMED NULL		/* time-stamp NULL means "now" */

/*** SYSTEM TYPE DECLARATIONS NEEDED BY MACROS HEREIN ***/
extern char *getenv();

/*** PRIVATE GLOBAL VARIABLES ***/	/* defined in DSPGlobals.c */
extern int _DSPTrace;
extern int _DSPVerbose;
extern int DSPAPTimeLimit;
extern int _DSPErrorBlock;
extern int _DSPMessagesEnabled;
extern int _DSPMKWriteDataIsRunning;
extern double _DSPSamplingRate;
extern DSPFix48 _DSPTimeStamp0;

#define DSP_MAYBE_RETURN(x) if (DSPIsSimulated()) ; else return(x)

#define DSP_QUESTION(q) /* q */

/*************************** Trace bits ***************************/

#define DSP_TRACE_DSPLOADSPECREAD 1
#define DSP_TRACE_DSPLOADSPECWRITE 2
#define DSP_TRACE_DSPLNKREAD 4
#define DSP_TRACE_FIXUPS 8
#define DSP_TRACE_NOOPTIMIZE 16
#define DSP_TRACE__DSPMEMMAPREAD 32
#define DSP_TRACE__DSPRELOCATE 64
#define DSP_TRACE__DSPRELOCATEUSER 128
#define DSP_TRACE_DSP 256
#define DSP_TRACE_HOST_MESSAGES 256  /* Same as DSP_TRACE_DSP in DSPObject.c */
#define DSP_TRACE_SYMBOLS 512 /* Also def'd in dspmsg/_DSPMakeIncludeFiles.c */
#define DSP_TRACE_HOST_INTERFACE 1024
#define DSP_TRACE_BOOT 2048
#define DSP_TRACE_LOAD 4096
#define DSP_TRACE_UTILITIES 8192
#define DSP_TRACE_TEST 16384
#define DSP_TRACE_DSPWRITEC 32768
#define DSP_TRACE_TMQ 0x10000
#define DSP_TRACE_NOSOUND 0x20000
#define DSP_TRACE_SOUND_DATA 0x40000
#define DSP_TRACE_MALLOC 0x80000
#define DSP_TRACE_MEMDIAG 0x100000 /* DSPBoot.c */
#define DSP_TRACE_WRITE_DATA 0x200000 /* DSPObject.c */

/*************************** Mach-related defines **************************/
/* Mach time-outs are in ms */
#define _DSP_MACH_RCV_TIMEOUT_SEGMENT 10
#define _DSP_MACH_RCV_TIMEOUT 100
#define _DSP_MACH_DEADLOCK_TIMEOUT 100
#define _DSP_ERR_TIMEOUT 100
#define _DSP_MACH_SEND_TIMEOUT 100
#define _DSP_MACH_FOREVER 1000000000

/*** AUXILIARY DSP STRUCTURES ***/

#if 0  /* DAJ */
/* DSP host-interface registers, as accessed in memory-mapped mode */
typedef volatile struct _DSPRegs {
	unsigned char icr;
	unsigned char cvr;
	unsigned char isr;
	unsigned char ivr;
	union {
		struct {
			unsigned char	pad;
			unsigned char	h;
			unsigned char	m;
			unsigned char	l;
		} rx;
		struct {
			unsigned char	pad;
			unsigned char	h;
			unsigned char	m;
			unsigned char	l;
		} tx;
	} data;
} DSPRegs;

#else

/* DSP host-interface registers, as accessed in memory-mapped mode */
//for the QP board, dsp regs are in byte 3 of each word
//NOTE: this struct can't be used with the NeXT's DSP!
typedef volatile struct _DSPRegs {  //byte offsets are in hex...
 	unsigned char icr_pad[3]; //00,01,02
 	unsigned char icr;	  //03
 	unsigned char cvr_pad[3]; //04.05.06
 	unsigned char cvr;	  //07
 	unsigned char isr_pad[3]; //08.09,0a
 	unsigned char isr;	  //0b
 	unsigned char ivr_pad[3]; //0c,0d,0e
 	unsigned char ivr;	  //0f
	union {
		unsigned int	receive;
		struct {
			unsigned char	pad;
			unsigned char	h;
			unsigned char	m;
			unsigned char	l;
		} rx;
		unsigned int	transmit;
		struct {
			unsigned char	pad;
			unsigned char	h;
			unsigned char	m;
			unsigned char	l;
		} tx;
	} data;
} DSPRegs;

#endif

typedef struct __DSPMemMap {	/* DSP memory map descriptor */
    /* NeXT MK and AP software makes use of relocation only within the USER 
       section at present. The GLOBAL and SYSTEM sections must be absolute. 
       However, the struct can easily be extended to multiple relocatable 
       sections: */
    int defaultOffsets[DSP_LC_NUM];/* START directive in .mem file: NOT USED */
    int userOffsets[DSP_LC_NUM];   /* SECTION USER in memory-map (.mem) file */
    int nOtherOffsets[DSP_LC_NUM]; /* number of other relocatable sections */
    int *otherOffsets[DSP_LC_NUM]; /* SECTION <whatever>: NOT USED */
				   /* _DSPMemMapRead() will complain if this
				      is needed (and won't malloc it) */
} _DSPMemMap;

#define _DSPMK_WD_BUF_BYTES 8192 /* vm_page_size */
#define _DSPMK_RD_BUF_BYTES 8192 /* vm_page_size */
#define _DSPMK_LARGE_SO_BUF_BYTES 8192
/* #define _DSPMK_SMALL_SO_BUF_BYTES DSPMK_NB_DMA_W */
#define _DSPMK_WD_TIMEOUT 60000

#import "_libdsp.h"
#import "dsp_messages.h"
#import "dsp_memory_map.h"

#endif _LIBDSP_

#endif
