#ifndef __MK__DSPMK_H___
#define __MK__DSPMK_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* 4.0 Revisions Copyright 1993 CCRMA, Stanford U.  All rights reserved. */
/* Frozen prototypes of all private libdsp functions used by Music Kit */

extern int _DSPError(int errorcode, char *msg);

extern int _DSPMKSendUnitGeneratorWithLooperTimed(
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

extern int _DSPReloc(DSPDataRecord *data, DSPFixup *fixups,
    int fixupCount, int *loadAddresses);
/* 
 * dataRec is assumed to be a P data space. Fixes it up in place. 
 * This is a private libdsp method used by _DSPSendUGTimed and
 * _DSPRelocate. 
 */




#endif
