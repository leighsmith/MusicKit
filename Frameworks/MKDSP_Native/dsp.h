#ifndef __MK_dsp_H___
#define __MK_dsp_H___
/*
	dsp.h - master include file for the DSP library (-ldsp -lsys_s)

	Copyright 1988-1992, NeXT Inc.  All rights reserved.
 
*/

#ifndef DSP_H
#define DSP_H

#include "MKDSPDefines.h"

#define DSP_SYS_VER_C 65
#define DSP_SYS_REV_C 41

/* Default start address in DSP internal program memory (just after DEGMON) */
#define DSP_PLI_USR_C 0x96

#define DSPMK_I_NTICK 0x10

#define DSP_EXT_RAM_SIZE_MIN 8192 /* Minimum external RAM size in 3byte wds */
#define DSP_CLOCK_RATE (25.0E6) /* DSP clock frequency */
#define DSP_CLOCK_PERIOD (40.0E-9) /* Cycle time in seconds. */

#import "dsp_types.h"

/****************************** Masks **************************************/

/* Basic DSP data types */
#define DSP_WORD_MASK		0x00FFFFFF /* low-order 24 bits */
#define DSP_SOUND_MASK		0x0000FFFF /* low-order 16 bits */
#define DSP_ADDRESS_MASK	0x0000FFFF /* low-order 16 bits */


/* Bits in the DSP Interrupt Control Register (ICR) */
#define DSP_ICR			0 /* ICR address in host interface */
#define DSP_ICR_RREQ		0x00000001 /* enable host int. on data->host */
#define DSP_ICR_TREQ		0x00000002 /* enable host int. on data<-host */
#define DSP_ICR_UNUSED		0x00000004
#define DSP_ICR_HF0		0x00000008
#define DSP_ICR_HF1		0x00000010
#define DSP_ICR_HM0		0x00000020
#define DSP_ICR_HM1		0x00000040
#define DSP_ICR_INIT		0x00000080

#define DSP_ICR_REGS_MASK	0xFF000000
#define DSP_ICR_RREQ_REGS_MASK	0x01000000
#define DSP_ICR_TREQ_REGS_MASK	0x02000000
#define DSP_ICR_HF0_REGS_MASK	0x08000000
#define DSP_ICR_HF1_REGS_MASK	0x10000000
#define DSP_ICR_HM0_REGS_MASK	0x20000000
#define DSP_ICR_HM1_REGS_MASK	0x40000000
#define DSP_ICR_INIT_REGS_MASK	0x80000000


/* Bits in the DSP Command Vector Register */
#define DSP_CVR			1	   /* address in host interface */
#define DSP_CVR_HV_MASK		0x0000001F /* low-order	 5 bits of CVR */
#define DSP_CVR_HC_MASK		0x00000080 /* HC bit of DSP CVR */

#define DSP_CVR_REGS_MASK	0x00FF0000 /* Regs mask for CVR */
#define DSP_CVR_HV_REGS_MASK	0x001F0000 /* low-order	 5 bits of CVR */
#define DSP_CVR_HC_REGS_MASK	0x00800000 /* Regs mask for HC bit of CVR */


/* Bits in the DSP Interrupt Status Register */
#define DSP_ISR		     2	/* address in host interface */
#define DSP_ISR_RXDF		0x00000001
#define DSP_ISR_TXDE		0x00000002
#define DSP_ISR_TRDY		0x00000004
#define DSP_ISR_HF2		0x00000008
#define DSP_BUSY		0x00000008 /* "DSP Busy"=HF2 */
#define DSP_ISR_HF3		0x00000010
#define DSP_ISR_UNUSED		0x00000020
#define DSP_ISR_DMA		0x00000040
#define DSP_ISR_HREQ		0x00000080

#define DSP_ISR_REGS_MASK	0x0000FF00
#define DSP_ISR_RXDF_REGS_MASK	0x00000100
#define DSP_ISR_TXDE_REGS_MASK	0x00000200
#define DSP_ISR_TRDY_REGS_MASK	0x00000400
#define DSP_ISR_HF2_REGS_MASK	0x00000800
#define DSP_BUSY_REGS_MASK	0x00000800
#define DSP_ISR_HF3_REGS_MASK	0x00001000
#define DSP_ISR_DMA_REGS_MASK	0x00004000
#define DSP_ISR_HREQ_REGS_MASK	0x00008000

/* DSP Interrupt Vector Register */
#define DSP_IVR		     3	/* address in host interface */

#define DSP_UNUSED	     4	/* address in host interface */

/* DSP Receive-Byte Registers */
#define DSP_RXH		     5	/* address in host interface */
#define DSP_RXM		     6	/* address in host interface */
#define DSP_RXL		     7	/* address in host interface */

/* DSP Transmit-Byte Registers */
#define DSP_TXH		     5	/* address in host interface */
#define DSP_TXM		     6	/* address in host interface */
#define DSP_TXL		     7	/* address in host interface */

/* Interesting places in DSP memory */
#define DSP_MULAW_SPACE 1	/* memory space code for mulaw table in DSP */
#define DSP_MULAW_TABLE 256	/* address of mulaw table in X onchip memory */
#define DSP_MULAW_LENGTH 128	/* length  of mulaw table */

#define DSP_ALAW_SPACE 1	/* memory space code for Mu-law table in DSP */
#define DSP_ALAW_TABLE 384	/* address of A-law table */
#define DSP_ALAW_LENGTH 128	/* length  of A-law table */

#define DSP_SINE_SPACE 2	/* memory space code for sine ROM in DSP */
#define DSP_SINE_TABLE 256	/* address of sine table in Y onchip memory */
#define DSP_SINE_LENGTH 256	/* length  of sine table */

/* Host commands (cf. DSP56000/1 DSP User's Manual) */
/* To issue a host command, set CVR to (DSP_CVR_HC_MASK|<cmd>&DSP_CVR_HV_MASK) */

#define DSP_HC_RESET			 (0x0)	   /* RESET host command */
#define DSP_HC_TRACE			 (0x4>>1)  /* TRACE host command */
#define DSP_HC_SWI			 (0x6>>1)  /* SWI host command */
#define DSP_HC_SOFTWARE_INTERRUPT	 (0x6>>1)  /* SWI host command */
#define DSP_HC_ABORT			 (0x8>>1)  /* DEBUG_HALT */
#define DSP_HC_HOST_RD			 (0x24>>1) /* DMA read done */
#define DSP_HC_HOST_R_DONE		 (0x24>>1) /* DMA read done */
#define DSP_HC_EXECUTE_HOST_MESSAGE	 (0x26>>1) /* Used for host messages */
#define DSP_HC_XHM			 (0x26>>1) /* abbreviated version */
#define DSP_HC_DMAWT			 (0x28>>1) /* Terminate DMA write */
#define DSP_HC_DMA_HOST_W_DONE		 (0x28>>1) /* Terminate DMA write */
#define DSP_HC_HOST_W_DONE		 (0x28>>1) /* Terminate DMA write */
#define DSP_HC_KERNEL_ACK		 (0x2A>>1) /* Kernel acknowledge */
#define DSP_HC_SYS_CALL			 (0x2C>>1) /* cf <nextdev/snd_dsp.h> */

#import "dsp_messages.h"

#define DSP_MESSAGE_OPCODE(x) (((x)>>16)&0xFF)
#define DSP_MESSAGE_SIGNED_DATUM(x) \
	((int)((x)&0x8000?0xFFFF0000|((x)&0xFFFF):((x)&0xFFFF)))
#define DSP_MESSAGE_UNSIGNED_DATUM(x) ((x)&0xFFFF)
#define DSP_MESSAGE_ADDRESS(x) DSP_MESSAGE_UNSIGNED_DATUM(x)
#define DSP_ERROR_OPCODE_INDEX(x) ((x) & 0x7F)	 /* Strip MSB on 8-bit field */
#define DSP_IS_ERROR_MESSAGE(x) ((x) & 0x800000) /* MSB on in 24 bits */
#define DSP_IS_ERROR_OPCODE(x) ((x) & 0x80) /* MSB on in 8 bits */

#define DSP_START_ADDRESS DSP_PLI_USR /* cf. dsp_messages.h */

/* Be sure to enclose in {} when followed by an else */
#define DSP_UNTIL_ERROR(x) if ((DSPErrorNo=(x))) \
  return(_DSPError(DSPErrorNo,"Aborting"))

#define NOT_YET 1
/* Make alloca() safe */

/**** Include files ****/
#include "dsp_structs.h"		/* DSP struct declarations */
#include "dsp_errno.h"		/* Error codes for DSP C functions */
#include "libdsp.h"		/* Function prototypes for libdsp functions */

#if defined(WIN32) && !defined(__MINGW32__)
// Stephen Brandon: MINGW32 has winsock.h imported anyway and it conflicts
// LMS it turns out -ObjC++ barfs including winsock.h
// so these are taken from winsock.h
typedef unsigned int u_int;
/*
 * Structure used in select() call, taken from the BSD file sys/time.h.
 */
struct timeval {
        long    tv_sec;         /* seconds */
        long    tv_usec;        /* and microseconds */
};
#else // WIN32
 #include <unistd.h>
#endif

#include <sys/types.h> // LMS replacement
#include <stdio.h>
#include <math.h>

#ifndef GNUSTEP
# import <mach/mach.h>
#endif

#define DSP_MAX_HM (DSP_NB_HMS-2) /* Leave room in HMS for begin/end marks */

#define DSPMK_UNTIMED NULL	/* Denotes untimed, not tick-synchronized */

/*** GLOBAL VARIABLES ***/	/* defined in DSPGlobals.c */
MKDSP_API int DSPErrorNo;
MKDSP_API DSPTimeStamp DSPMKTimeStamp0; /* Tick-synchronized, untimed */

/* Numerical conversion */
#define DSP_TWO_TO_24   ((double)16777216.0)
#define DSP_TWO_TO_M_24 ((double)5.960464477539063e-08)
#define DSP_TWO_TO_23   ((double)8388608.0)
#define DSP_TWO_TO_M_23 ((double)1.192092895507813e-7)
#define DSP_TWO_TO_48   ((double)281474976710656.0)
#define DSP_TWO_TO_M_48 ((double)3.552713678800501e-15)
#define DSP_TWO_TO_15   ((double)32768.0)
#define DSP_TWO_TO_M_15 ((double)3.0517578125e-05)

#define DSP_INT_TO_FLOAT(x) ((((float)(x))*((float)DSP_TWO_TO_M_23)))
#define DSP_SHORT_TO_FLOAT(x) ((((float)(x))*((float)DSP_TWO_TO_M_15)))
#define DSP_FIX24_TO_FLOAT(x) ((((float)(x))*((float)DSP_TWO_TO_M_23)))
#define DSP_INT_TO_DOUBLE(x) ((((double)(x))*(DSP_TWO_TO_M_23)))
#define DSP_SHORT_TO_DOUBLE(x) ((((double)(x))*((float)DSP_TWO_TO_M_15)))
#define DSP_FIX48_TO_DOUBLE(x) ((double)((x)->high24)*(DSP_TWO_TO_24) + ((double) (x)->low24))
#define DSP_FLOAT_TO_INT(x) ((int)(((double)(x))*((double)DSP_TWO_TO_23)+0.5))
#define DSP_FLOAT_TO_SHORT(x) ((int)(((double)(x))*((double)DSP_TWO_TO_15)+0.5))
#define DSP_DOUBLE_TO_INT(x) ((int)(((double)(x))*(DSP_TWO_TO_23)+0.5))
#define DSP_DOUBLE_TO_SHORT(x) ((int)(((double)(x))*((double)DSP_TWO_TO_15)+0.5))

/* Max positive DSP float = (1-1/2^23) */
#define DSP_F_MAXPOS ((double)(1.0-DSP_TWO_TO_M_23))
#define DSP_ONE DSP_F_MAXPOS

/* Max negative DSP float = -2^23 */
#define DSP_F_MAXNEG (float) -1.0 

#define DSP_FIX24_CLIP(_x) (((int)_x) & 0xFFFFFF)

#define DSPMK_LOW_SAMPLING_RATE 22050.0
#define DSPMK_HIGH_SAMPLING_RATE 44100.0

#ifndef REMEMBER
#define REMEMBER(x) /* x */
#endif

#define DSPMK_NTICK DSPMK_I_NTICK

/*** FILE NAMES ***/
/*** These filenames must stay in synch with those in $DSP/Makefile.config ***/

#define DSP_SYSTEM_DIRECTORY @"/usr/local/lib/dsp/"
#define DSP_FALLBACK_SYSTEM_DIRECTORY @"/usr/lib/dsp/"
#define DSP_BIN_DIRECTORY "/usr/local/bin/"
#define DSP_AP_BIN_DIRECTORY "/apbin/"
#define DSP_INSTALL_ROOT "/usr/local/lib/dsp/"
#define DSP_ERRORS_FILE "/tmp/dsperrors"
#define DSP_WHO_FILE "/tmp/dsp.who"

MKDSP_API const char *DSPGetDSPDirectory();	/* as above or $DSP if $DSP set */
MKDSP_API char *DSPGetSystemDirectory();	/* /u/l/l/monitor|$DSP/monitor */
MKDSP_API char *DSPGetImgDirectory();	/* /u/l/l/dsp/img or $DSP/img */
MKDSP_API char *DSPGetAPDirectory();	/* /u/l/l/dsp/imgap or $DSP/imgap */
MKDSP_API char *DSPGetMusicDirectory();	/* DSP_MUSIC_DIRECTORY */
MKDSP_API char *DSPGetLocalBinDirectory(); /* /usr/bin or $DSP/bin */

/* 
   Convert Y-space address in DSP "XY memory partition" 
   (where X and Y memories are each 4K long addressed from 0xA000)
   into an equivalent address in the "overlaid memory partition"
   (where memory addresses are irrespective of space).
   *** NOTE: This macro depends on there being 8K words of DSP static RAM ***
   Behaves like a function returning int.
*/
#define DSPMapPMemY(ya) ((int) ((ya) & 0x7FFF))

/* 
   Convert X-space address in DSP "XY memory partition" 
   into an equivalent address in the "overlaid memory partition"
   *** NOTE: This macro depends on there being 8K words of DSP static RAM ***
   Behaves like a function returning int.
*/
#define DSPMapPMemX(xa) ((int) (((xa)|0x1000) & 0x7FFF))

/* 
   File names below are ALL assumed to exist in the directory returned by
   DSPGetSystemDirectory(): 
*/

/* Default AP and MK monitors installed with the system */

/* dsp0 */

/* All these should be NSConstantStrings but currently they are included in C source - LMS */

/* The following are used by _DSPRelocate.c for backward 2.0 compatibility */
#define DSP_MUSIC_SYSTEM_MEM "/mkmon8k.mem" 
#define DSP_AP_SYSTEM_MEM "/apmon8k.mem"

/* The following are used by DSPObject.c DSPBoot.c */
#define DSP_MUSIC_SYSTEM_BINARY_0 "/mkmon_A_8k.dsp" 
#define DSP_MUSIC_SYSTEM_0 "/mkmon_A_8k.lod"

#define DSP_AP_SYSTEM_BINARY_0 "/apmon_8k.dsp"
#define DSP_AP_SYSTEM_0 "/apmon_8k.lod"

/* NeXT 32K word DSP memory expansion SIMM */
#define DSP_32K_MUSIC_SYSTEM_BINARY_0 @"/mkmon_A_32k.dsp"
#define DSP_32K_MUSIC_SYSTEM_0 @"/mkmon_A_32k.lod"

/* NeXT 32K word DSP memory expansion SIMM */
#define DSP_32K_AP_SYSTEM_BINARY_0 @"/apmon_32k.dsp"
#define DSP_32K_AP_SYSTEM_0 @"/apmon_32k.lod"

/* UCSF 64K x 3 word DSP memory expansion SIMM */
#define DSP_192K_MUSIC_SYSTEM_BINARY_0 @"/mkmon_A_192k.dsp"
#define DSP_192K_MUSIC_SYSTEM_0 @"/mkmon_A_192k.lod"

/* Ariel PC56D 16K x 2 + 32K (P) word DSP memory */
#define DSP_64K_SPLIT_MUSIC_SYSTEM_BINARY_0 @"/mkmon_A_192k.dsp"
#define DSP_64K_SPLIT_MUSIC_SYSTEM_0 @"/mkmon_A_192k.lod"

/* Number of words above which array-reads from the DSP use DMA */
#define DSP_MIN_DMA_READ_SIZE 0

/* Number of words above which array-writes to the DSP use DMA */
#define DSP_MIN_DMA_WRITE_SIZE 128

/* New mode for more efficient DMA transfers (cf. <nextdev/snd_msgs.h>) */
#define DSP_MODE32_LEFT_JUSTIFIED 6

#ifndef MAX
#define  MAX(A,B)	((A) > (B) ? (A) : (B))
#endif

#ifndef MIN
#define  MIN(A,B)	((A) < (B) ? (A) : (B))
#endif

#ifndef ABS
#define  ABS(A)		((A) < 0 ? (-(A)) : (A))
#endif

#define  DSP_MALLOC( VAR, TYPE, NUM ) ((VAR) = (TYPE *) malloc( (unsigned)(NUM)*sizeof(TYPE)))

#define  DSP_REALLOC( VAR, TYPE, NUM )				\
   ((VAR) = (TYPE *) realloc((char *)(VAR), (unsigned)(NUM)*sizeof(TYPE)))

#define  DSP_FREE( PTR ) free( (char *) (PTR) );

/* Exports from DSPGlobals.c */

// this is declared above
//MKDSP_API int DSPErrorNo;		 /* Last DSP error */
MKDSP_API int DSPDefaultTimeLimit;  /* Default is 1000 which is 1 second */
MKDSP_API int DSPAPTimeLimit;	 /* Default is 0 which means "forever" */
// this is declared above with DSPTimeStamp. Which is right?
// MKDSP_API DSPFix48 DSPMKTimeStamp0; /* Always {0,0} (tick-synchronizer) */

#define DSP_ATOMIC 1
#define DSP_NON_ATOMIC 0
#define DSP_TIMEOUT_FOREVER 0
#define _DSP_MSG_READER_TIMEOUT 30

#endif /* DSP_H */

#endif

