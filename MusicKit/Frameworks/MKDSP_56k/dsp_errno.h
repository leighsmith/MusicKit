#ifndef __MK_dsp_errno_H___
#define __MK_dsp_errno_H___
/*
	dsperrno.h

	Copyright 1988-1992, NeXT Inc.  All rights reserved.
  
	This file contains globally unique error codes for the DSP C library.

*/

// locations are different between Win and Unix
#ifdef WIN32
#import <errno.h>
#else
#import <sys/errno.h>
#endif

extern int errno;

#define DSP_EWARNING 0		/* used to print warning and continue */

#define DSP_ERRORBASE    7000	/* global error codes for DSP C library*/

#define DSP_EBADLA	   (DSP_ERRORBASE+1) /* bad load address */
#define DSP_EBADDR	   (DSP_ERRORBASE+2) /* bad data record */
#define DSP_EBADFILETYPE   (DSP_ERRORBASE+3) /* bad file type */
#define DSP_EBADSECTION	   (DSP_ERRORBASE+4) /* bad section */
#define DSP_EBADLNKFILE	   (DSP_ERRORBASE+5) /* bad link file */
#define DSP_EBADLODFILE	   (DSP_ERRORBASE+6) /* bad link file */
#define DSP_ETIMEOUT	   (DSP_ERRORBASE+7) /* time out */
#define DSP_EBADSYMBOL	   (DSP_ERRORBASE+8) /* bad symbol */
#define DSP_EBADFILEFORMAT (DSP_ERRORBASE+9) /* bad file format */
#define DSP_EBADMEMMAP	   (DSP_ERRORBASE+10) /* invalid DSP memory map */


#define DSP_EMISC	   (DSP_ERRORBASE+11) /* miscellaneous error */
#define DSP_EPEOF	   (DSP_ERRORBASE+12) /* premature end of file */
#define DSP_EPROTOCOL	   (DSP_ERRORBASE+13) /* DSP communication trouble */
#define DSP_EBADRAM	   (DSP_ERRORBASE+14) /* DSP private RAM broken */
#define DSP_ESYSHUNG	   (DSP_ERRORBASE+15) /* DSP system not responding */
#define DSP_EBADDSPFILE	   (DSP_ERRORBASE+16) /* bad .dsp file */
#define DSP_EILLDMA	   (DSP_ERRORBASE+17) /* attempt to write p:$20#2 */
#define DSP_ENOMSG	   (DSP_ERRORBASE+18) /* no DSP messages to read */
#define DSP_EBADMKLC	   (DSP_ERRORBASE+19) /* lc not used by musickit */
#define DSP_EBADVERSION	   (DSP_ERRORBASE+20) /* DSP sys version mismatch */
#define DSP_EDSP	   (DSP_ERRORBASE+21) /* DSP error code */
#define DSP_EILLADDR	   (DSP_ERRORBASE+22) /* Attempt to overwrite sys */
#define DSP_EHWERR	   (DSP_ERRORBASE+23) /* Apparent hardware problem */
#define DSP_EFPOVFL	   (DSP_ERRORBASE+24) /* 24b Fixed-point Overflow */
#define DSP_EHMSOVFL	   (DSP_ERRORBASE+25) /* Host Message Stack Overf. */
#define DSP_EMACH	   (DSP_ERRORBASE+26) /* Error says Mach kernel */
#define DSP_EUSER	   (DSP_ERRORBASE+27) /* User error code */
#define DSP_EABORT	   (DSP_ERRORBASE+28) /* DSP aborted execution */
#define DSP_ENOTOPEN	   (DSP_ERRORBASE+29) /* can't do this when closed */
#define DSP_EQUINT	   (DSP_ERRORBASE+30) /* QuintProcessor error */

#define DSP_EUNIX	   (-1) /* Use errno to get error code */

#endif
