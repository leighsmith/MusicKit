#ifndef __MK__DSPObject_H___
#define __MK__DSPObject_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */

/* Private functions in DSPObject.c */

extern int _DSPSetNumber(int i);
/* 
 * Set assigned DSP number for this instance.  Called by the new method.
 */


extern int _DSPAwaitMsgSendAck(msg_header_t *msg);
/*
 * Read ack message sent to msg->local_port by Mach kernel in response to a 
 * msg_snd. Returns 0 if all is well.
 */


extern int _DSPAwaitRegs(
    int mask,		/* mask to block on as bits in (ICR,CVR,ISR,IVR) */
    int value,		/* 1 or 0 as desired for each 1 mask bit */
    int msTimeLimit);	/* time limit in milliseconds */
/*
 * Block until the specified mask is true in the DSP host interface.
 * Example conditions are (cf. <nextdev/snd_dspreg.h>):
 *  mask=DSP_CVR_REGS_MASK, value=0
 *	Wait for HC bit of DSP host interface to clear
 *  mask=value=DSP_ISR_HF2_REGS_MASK,
 * 	Wait for HF2 bit of DSP host interface to set
 */


extern int _DSPAwaitBit(
    int bit,		/* bit to block on as bit in (ICR,CVR,ISR,IVR) */
    int value,		/* 1 or 0 */
    int msTimeLimit);	/* time limit in milliseconds */
/*
 * Block until the specified bit is true in the DSP host interface.
 * Example conditions are (cf. <nextdev/snd_dspreg.h>):
 *
 * 	bit		value
 * 	--- 		-----
 * DSP_CVR_REGS_MASK	  0	Wait for HC bit of DSP host interface to clear
 * DSP_ISR_HF2_REGS_MASK  1 	Wait for HF2 bit of DSP host interface to set
 *
 */
extern int _DSPAwaitMsgSendAck(
    msg_header_t *msg);
/*
 * Read ack message sent to msg->local_port by Mach kernel in response to a 
 * msg_snd. Returns 0 if all is well.
 */


extern int _DSPAwaitRegs(
    int mask,		/* mask to block on as bits in (ICR,CVR,ISR,IVR) */
    int value,		/* 1 or 0 as desired for each 1 mask bit */
    int msTimeLimit);	/* time limit in milliseconds */
/*
 * Block until the specified mask is true in the DSP host interface.
 * Example conditions are (cf. <nextdev/snd_dspreg.h>):
 *  mask=DSP_CVR_REGS_MASK, value=0
 *	Wait for HC bit of DSP host interface to clear
 *  mask=value=DSP_ISR_HF2_REGS_MASK,
 * 	Wait for HF2 bit of DSP host interface to set
 */


extern int _DSPAwaitBit(
    int bit,		/* bit to block on as bit in (ICR,CVR,ISR,IVR) */
    int value,		/* 1 or 0 */
    int msTimeLimit);	/* time limit in milliseconds */
/*
 * Block until the specified bit is true in the DSP host interface.
 * Example conditions are (cf. <nextdev/snd_dspreg.h>):
 *
 * 	bit		value
 * 	--- 		-----
 * DSP_CVR_REGS_MASK	  0	Wait for HC bit of DSP host interface to clear
 * DSP_ISR_HF2_REGS_MASK  1 	Wait for HF2 bit of DSP host interface to set
 *
 */


extern int _DSPReadDatumMode(DSPDatum *datumP, int mode);

extern int _DSPReadDatum(DSPDatum *datumP);
/*
 * Read a single DSP message.
 * Returns nonzero if there is no more data.
 * *** NOTE *** This routine is private because it does not support
 * mapped mode.	 A routine DSPReadDatum() routine can be made which 
 * simply calls DSPReadRX().
 */


extern int _DSPReadData(DSPDatum *dataP, int *nP);
/*
 * Read back up to *nP DSP messages into array dataP.
 * On input,nP is the maximum number of DSP data words to be read.
 * On output,nP contains the number of DSP data words actually read.
 * Returns nonzero if *nP changes.
 * *** NOTE *** This routine is private because it does not support
 * mapped mode.	 A routine DSPReadData() routine can be made which 
 * simply calls DSPReadRXArray().
 */


extern int _DSPReadRegs(void);
/* 
 * Return first four DSP host interface register bytes (ICR,CVR,ISR,IVR)
 * in *regsP.  Returns 0 on success.  Calls to this routine do not affect
 * the simulator output file because they do not affect the state of the DSP.
 */


extern int _DSPPrintRegs(void);
/* 
 * Print first four DSP host interface register bytes (ICR,CVR,ISR,IVR).
 */


extern int _DSPPutBit(
    int bit,			/* bit mask in (ICR,CVR,ISR,IVR) longword */
    int value);			/* 1 or 0 */
/*
 * Set DSP host-interface bit to given value.
 * Returns 0 for success, nonzero on error.
 * Example:
 *	_DSPPutBit(DSP_ICR_HF0_REGS_MASK,1),
 * sets host flag 0 to 1 and 
 *	_DSPPutBit(DSP_ICR_HF0_REGS_MASK,0));
 * clears it.
 *
 * *** NOTE: This routine is private because it does not support mapped mode.
 */


extern int _DSPSetBit(int bit);	/* bit mask in (ICR,CVR,ISR,IVR) longword */
/*
 * Set DSP host-interface bit.
 * Returns 0 for success, nonzero on error.
 * Example: "_DSPSetBit(DSP_ICR_HF0_REGS_MASK)" sets host flag 0.
 * *** NOTE: This routine is private because it does not support mapped mode.
 */


extern int _DSPClearBit(int bit);	/* bit mask in (ICR,CVR,ISR,IVR) longword */
/*
 * Clear DSP host-interface bit.
 * Returns 0 for success, nonzero on error.
 * Example: "_DSPSetBit(DSP_ICR_HF0_REGS_MASK)" sets host flag 0.
 * *** NOTE: This routine is private because it does not support mapped mode.
 */


extern int _DSPStartHmArray(void);
/*
 * Start host message by zeroing the host message buffer pointer hm_ptr.
 */


extern int _DSPExtendHmArray(DSPDatum *argArray, int nArgs);
/*
 * Add arguments to a host message (for the DSP).
 * Add nArgs elements from argArray to hm_array.
 */


extern int _DSPExtendHmArrayMode(void *argArray, int nArgs, int mode);
/*
 * Add arguments to a host message (for the DSP).
 * Add nArgs elements from argArray to hm_array according to mode.
 * Mode codes are in <nextdev/dspvar.h> and discussed in 
 * DSPObject.h(DSPWriteArraySkipMode).
 */


extern int _DSPExtendHmArrayB(DSPDatum *argArray, int nArgs);
/*
 * Add nArgs elements from argArray to hm_array in reverse order.
 */


extern int _DSPFinishHmArray(DSPFix48 *aTimeStampP, DSPAddress opcode);
/*
 * Finish off host message by installing time stamp (if timed) and opcode.
 * Assumes host-message arguments have already been installed in hm_array via 
 * _DSPExtendHmArray().
 */


extern int _DSPWriteHm(void);
/*
 * Send host message struct to the DSP.
 */


extern int _DSPWriteHostMessage(int *hm_array, int nwords);
/*
 * Write host message array.
 * See DSPMessage.c for how this array is set up. (Called by _DSPWriteHm().)
 */


extern int _DSPResetTMQ(void);
/*
 * Reset TMQ buffers to empty state and reset "current time" to 0.
 * Any waiting timed messages in the buffer are lost.
 */


extern int _DSPFlushTMQ(void) ;
/*
 * Flush current buffer of accumulated timed host messages (all for the
 * same time).
 */


extern int _DSPOpenMapped(void);
/*
 * Open DSP in memory-mapped mode. 
 * No reset or boot is done.
 * DSPGetRegs() can be used to obtain a pointer to the DSP host interface.
 */


extern int _DSPEnableMappedOnly(void);
extern int _DSPDisableMappedOnly(void);
extern int _DSPMappedOnlyIsEnabled(void);


extern int _DSPCheckMappedMode(void) ;
/*
 * See if mapped mode would be a safe thing to do.
 */


extern int _DSPEnterMappedModeNoCheck(void) /* Don't call this directly! */;


extern int _DSPEnterMappedModeNoPing(void) ;
/*
 * Turn off DSP interrupts.
 */


extern int _DSPEnterMappedMode(void);
/*
 * Flush driver's DSP command queue and turn off DSP interrupts.
 */


extern int _DSPExitMappedMode(void);
/*
 * Flush driver's DSP command queue and turn off DSP interrupts.
 */


DSPRegs *_DSPGetRegs(void);

extern int _DSPMappedOnlyIsEnabled(void);
extern int _DSPEnableMappedArrayReads(void);
extern int _DSPDisableMappedArrayReads(void);
extern int _DSPEnableMappedArrayWrites(void);
extern int _DSPDisableMappedArrayWrites(void);
extern int _DSPEnableMappedArrayTransfers(void);
extern int _DSPDisableMappedArrayTransfers(void);

extern int _DSPEnableUncheckedMappedArrayTransfers(void);

extern int _DSPDisableUncheckedMappedArrayTransfers(void);

extern int _DSPMKStartWriteDataNoThread(void);
/*
 * Same as DSPMKStartWriteData() but using an untimed host message
 * to the DSP.
 */

extern int _DSPMKStartWriteDataNoThread(void);

extern int _DSPForceIdle(void);

extern int _DSPOwnershipIsJoint();
/*
 * Returns TRUE if DSP owner port is held by more than one task.
 */

/* Added 3/30/90/jos from DSPObject.h */

FILE *DSPMKGetWriteDataFP(void);
/* 
 * Get the file-pointer being used for DSP write-data.
 */

int DSPMKSetWriteDataFP(FILE *fp);
/* 
 * Set the file-pointer for DSP write-data to fp.
 * The file-pointer will clear and override any prior specification
 * of write-data filename using DSPMKSetWriteDataFile().
 */

#if !m68k && (defined(NeXT) || (defined(__APPLE__) && defined(__MACH__)))
extern int _DSPAddIntelBasedDSP(char *driverName,int driverUnit,int subUnit, 
				float version);
/*
 * Add Intel card-based DSP56001 with specified driver name and unit.
 * On Intel machines, you must call this before any other libdsp functions.
 * Note that DSPAddIntelBasedDSPs() is defined in terms of this function.
 */

extern void _DSPAddIntelBasedDSPs(void);
/* Invokes DSPAddIntelBasedDSP() for each "in use" DSP (see below).  
 * This function must be called before any other libdsp functions.  
 * The Music Kit invokes DSPAddIntelBasedDSPs automatically.
 */

#endif

extern void _DSPInitDefaults(void);
/* Init defaults data base values */

extern int _DSPResetSystem(DSPLoadSpec *system);
/* Like DSPSetSystem() but assumes system is the same as the last one used
 * for this DSP (an optimization).
 */

#endif
