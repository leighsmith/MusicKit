/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* 4.0 Revisions Copyright 1993 CCRMA, Stanford U.  All rights reserved. */
/* Frozen prototypes of all private libdsp functions used by Music Kit */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.3  2001/11/07 13:07:50  sbrandon
  This file is a kludge. We should be fixing up the headers at source (in
  MKDSP) rather than defining MKDSP export headers in this framework. Oh well.

  Revision 1.2  1999/07/29 01:25:58  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK__DSPMK_H___
#define __MK__DSPMK_H___

/* sbrandon Nov 2001: 
 * these really need a header file of their own in MKDSP. The only reason
 * why we don't just import the headers like we should is that the headers
 * in question include things like Mach headers, which don't go down well
 * on Windows and other platforms. FIXME at source.
 */

//#include <MKDSP/_libdsp.h>
//#include <MKDSP/_DSPTransfer.h>
#include <MKDSP/MKDSPDefines.h>

MKDSP_API int _DSPError(int errorcode, char *msg);

MKDSP_API int _DSPError1(
    int errorcode,
    char *msg,
    char *arg);

MKDSP_API int _DSPMKSendUnitGeneratorWithLooperTimed(
    DSPFix48 *aTimeStampP, 
    DSPMemorySpace space,
    DSPAddress address,
    DSPFix24 *data,		/* DSP gets rightmost 24 bits of each word */
    int count,
    int looperWord);
/*
 * Same as DSPMKSendArrayTimed() but tacks on one extra word which is a
 * DSP instruction which reads "jmp orchLoopStartAddress". Note that
 * code was copied from	 DSPMKSendArraySkipTimed().
 */

MKDSP_API int _DSPReloc(DSPDataRecord *data, DSPFixup *fixups,
    int fixupCount, int *loadAddresses);
/* 
 * dataRec is assumed to be a P data space. Fixes it up in place. 
 * This is a private libdsp method used by _DSPSendUGTimed and
 * _DSPRelocate. 
 */




#endif
