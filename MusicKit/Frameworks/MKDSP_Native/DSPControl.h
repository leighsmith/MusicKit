#ifndef __MK_DSPControl_H___
#define __MK_DSPControl_H___
/* DSPControl.h - Functions in libdsp_s.a having to do with DSP control.
 * Copyright 1988-1992, NeXT Inc.  All rights reserved.
 * Author: Julius O. Smith III
 */

/* Control functions are also in DSPObject.h */

#include "MKDSPDefines.h"

/********************** READING/WRITING DSP HOST FLAGS ***********************/

MKDSP_API int DSPSetHF0(void);
/*
 * Set bit HF0 in the DSP host interface.
 * In the context of the music kit or array processing kit, HF0 is set 
 * by the driver to indicate that the host interface is initialized in DMA
 * mode.
 */


MKDSP_API int DSPClearHF0(void);
/*
 * Clear bit HF0 in the DSP host interface.
 */


MKDSP_API int DSPGetHF0(void);
/* 
 * Read state of HF0 flag of ICR in DSP host interface.
 */


MKDSP_API int DSPSetHF1(void);
/*
 * Set bit HF1 in the DSP host interface.
 * In the context of the music kit or array processing kit, HF1 is not used.
 */


MKDSP_API int DSPClearHF1(void);
/*
 * Clear bit HF1 in the DSP host interface.
 */


MKDSP_API int DSPGetHF1(void);
/* 
 * Read state of HF1 flag of ICR in DSP host interface.
 */


MKDSP_API int DSPGetHF2(void);
/*
 * Return nonzero if bit HF2 in the DSP host interface is set, otherwise FALSE.
 * In the context of the music kit or array processing kit, HF2 is set during 
 * the execution of a host message.
 */


MKDSP_API int DSPGetHF3(void);
/*
 * Return nonzero if bit HF3 in the DSP host interface is set, otherwise FALSE.
 * HF3 set in the context of the music kit implies the Timed Message Queue
 * in the DSP is full.  For array processing, it means the AP program is still
 * executing on the DSP.
 */


MKDSP_API int DSPGetHF2AndHF3(void);
/*
 * Return nonzero if bits HF2 and HF3 in the DSP host interface are set, 
 * otherwise FALSE.  The Music Kit and array processing monitors set
 * both bits to indicate that the DSP has aborted.
 */

/*************************** DSP SYNCHRONIZATION ***************************/


MKDSP_API int DSPAwaitCondition(int mask, int value, int msTimeLimit);
/*
 * Await specified condition in the DSP host interface.
 * The DSP registers ICR,CVR,ISR,IVR are concatenated to form a 32-bit word.
 * Call this word dspregs.  Then the awaited condition is
 *
 *  dspregs & mask == value
 *
 * If the condition is true by msTimeLimit (millisecond time-limit),
 * 0 is returned. Otherwise, DSP_ETIMEOUT is returned.  An msTimeLimit of 0
 * means wait forever.  Note that the time-out is only for the function 
 * call. The awaited condition is still pending in the DSP driver, and 
 * there is presently no way to cancel it or give it a time-out in the driver.
 * If the condition hangs, all DSP commands at the same or lower
 * Mach message priority will be blocked. Higher priority messages can
 * still get through.
 */


MKDSP_API int DSPResumeAwaitingCondition(int msTimeLimit);
/*
 * If DSPAwaitCondition() returns nonzero, you can call this function to
 * resume waiting for a specified interval.  You should also call
 * DSPAwakenDriver() (see below) before calling this one to make sure
 * the driver rechecks the awaited condition in the DSP.  By doing this
 * in a loop at regular intervals you can set up a polling loop for the
 * awaited condition.   The polling is efficient if
 * msTimeLimit is reasonably large because during that time
 * the calling thread is sleeping in msg_receive().
 * Returns 0 if the condition comes true, nonzero if it times out.
 */


MKDSP_API int DSPAwaitConditionNoBlock(
    int mask,		/* mask to block on as bits in (ICR,CVR,ISR,IVR) */
    int value);		/* 1 or 0 as desired for each 1 mask bit */
/*
 * Same as DSPAwaitCondition() except the function returns immediately.
 * The condition serves as a possible block for the DSP command queue
 * within the driver, but not for the calling program.
 */


MKDSP_API int DSPAwaitHC(int msTimeLimit);
/*
 * Wait for "HC bit" to clear. 
 * The HC clears when the next instruction to be executed in the DSP
 * is the first word of the host command interrupt vector.
 * Equivalent to "DSPAwaitCondition(0x00800000,0x00000000,msTimeLimit);"
 */


MKDSP_API int DSPAwaitTRDY(int msTimeLimit);
/*
 * Wait for "TRDY bit" to set. 
 * Equivalent to "DSPAwaitCondition(0x00040000,0x00040000,msTimeLimit);"
 */


MKDSP_API int DSPAwaitHF3Clear(int msTimeLimit);
/*
 * Wait for HF3 = "MK TMQ full" or "AP Program Busy" bit to clear. 
 * Equivalent to "DSPAwaitCondition(0x00100000,0x00100000,msTimeLimit);"
 */


MKDSP_API int DSPAwaitHostMessage(int msTimeLimit);
/*
 * Wait for currently executing host message to finish.
 */


int DSPAwakenDriver(void);
/* 
 * Send empty message to DSP at priority DSP_MSG_HIGH to wake up the driver. 
 * When the DSP driver is awaiting a condition, such as is done by
 * DSPAwaitCondition(), there no automatic polling that is done by the system.
 * Instead, it is up to the programmer to ensure that some event, such
 * as a Mach message to the Sound/DSP driver, a DMA-completion interrupt 
 * involving the DSP, or a DSP interrupt, will cause the driver to run and 
 * check the awaited condition.  See DSPResumeAwaitingCondition().
 */

/**************************** DSP Program Execution ********************************/

MKDSP_API int DSPSetStart(DSPAddress startAddress);
/*
 * Set default DSP start address for user program.
 */


MKDSP_API int DSPStart(void);
/*
 * Initiate execution of currently loaded DSP user program at current
 * default DSP start address.
 */


MKDSP_API int DSPStartAtAddress(DSPAddress startAddress);
/*
 * Equivalent to DSPSetStart(startAddress) followed by DSPStart().
 */

/********************** Querying the DSP MK or AP Monitor  **************************/

MKDSP_API int DSPPingVersionTimeOut(
    int *verrevP,
    int msTimeLimit);
/* 
 * Like DSPPingVersion but allowing specification of a time-out in
 * milliseconds.
 */


MKDSP_API int DSPPingVersion(int *verrevP);
/* 
 * "Ping" the DSP.  The DSP responds with an "I am alive" message
 * containing the system version and revision.
 * Returns 0 if this reply is received, nonzero otherwise.
 * (version<<8 | revision) is returned in *verrevP.
 */


MKDSP_API int DSPPingTimeOut(int msTimeLimit);
/* 
 * Like DSPPing but allowing specification of a time-out in
 * milliseconds.
 */


MKDSP_API int DSPPing(void);
/* 
 * "Ping" the DSP.  The DSP responds with an "I am alive" message.
 * Returns 0 if this reply is received, nonzero otherwise.
 */


MKDSP_API int DSPCheckVersion(
    int *sysver,	   /* system version running on DSP (returned) */
    int *sysrev);	   /* system revision running on DSP (returned) */
/* 
 * "Ping" the DSP.  The DSP responds with an "I am alive" message
 * containing the DSP system version and revision as an argument.
 * For extra safety, two more messages are sent to the DSP asking for the
 * address boundaries of the DSP host-message dispatch table.  These
 * are compared to the values compiled into the program. 
 * A nonzero return value indicates a version mismatch or a hung DSP.
 * The exact nature of the error will appear in the error log file, if enabled.
 */


MKDSP_API int DSPIsAlive(void);
/*
 * Ask DSP monitor if it's alive, ignoring system version and revision.
 * "Alive" means anything but hung.  System version compatibility is
 * immaterial.	Use DSPCheckVersion() to check for compatibility between 
 * the loaded DSP system and your compilation.
 */


MKDSP_API int DSPMKIsAlive(void);
/*
 * Ask DSP monitor if it's alive, and if it's the Music Kit monitor.
 */

/***************************** Untimed Control  *******************************/

MKDSP_API int DSPMKFreezeOrchestra(void);
/*
 * Place the DSP orchestra into the "frozen" state.  The orchestra loop enters
 * this state when it finishes computing the current "tick" of sound and jumps
 * back to the loop top.  It busy-waits there until DSPMKThawOrchestra() is
 * called.  In the frozen state, DSP device interrupts remain enabled, but no
 * new sound is computed.  Thus, if sound-out is flowing, it will soon
 * under-run.
 */


MKDSP_API int DSPMKThawOrchestra(void);
/*
 * Release the DSP orchestra from the frozen state.
 */


MKDSP_API int DSPMKPauseOrchestra(void);
/*
 * Place the DSP orchestra into the paused state.  In this type of pause, the
 * orchestra loop continues to run, emitting sound, but time does not advance.
 * Thus, a better name would be DSPMKPauseTimedMessages().
 */


MKDSP_API int DSPMKResumeOrchestra(void);
/*
 * Release the DSP orchestra from the paused state.
 */


MKDSP_API int DSPSetDMAReadMReg(DSPAddress M);
/* 
 * Set the M index register used in DMA reads from DSP to host to M.
 * The default is M = -1 which means linear addressing.
 * The value M = 0 implies bit-reverse addressing, and
 * positive M is one less than the size of the modulo buffer used.
 */


MKDSP_API int DSPSetDMAWriteMReg(DSPAddress M);
/* 
 * Set the M index register used in DMA writes from host to DSP to M.
 * The default is M = -1 which means linear addressing.
 * The value M = 0 implies bit-reverse addressing, and
 * positive M is one less than the size of the modulo buffer used.
 */


MKDSP_API int DSPAbort(void);
/* 
 * Tell the DSP to abort.
 */


/******************************** TIMED CONTROL ******************************/
/* 
   Timed messages are used by the music kit.  Time is maintained in the DSP.
   The current time (in samples) is incremented by the tick size DSPMK_I_NTICK
   once each iteration of the orchestra loop on the DSP.  When the orchestra
   loop is initially loaded and started, the time increment is zero so that
   time does not advance.  This is the "paused" state for the DSP orchestra
   (to be distinguished from the "frozen" state in which everything suspends).
*/

MKDSP_API int DSPMKSetTime(DSPFix48 *aTimeStampP);
/*
 * Set DSP sample time to that contained in *aTimeStampP.
 */


MKDSP_API int DSPMKClearTime(void);
/*
 * Set DSP sample time to zero.
 */


MKDSP_API int DSPReadLong(DSPFix48 *longValue,DSPAddress address);
/*
 * Read a 48-bit value from DSP l memory.
 */


DSPFix48 *DSPGetLong(DSPAddress address);
/*
 * Read a 48-bit value from DSP l memory.
 * Pointer returned is to freshly allocated DSPFix48.
 */


MKDSP_API int DSPMKReadTime(DSPFix48 *dspTime);
/*
 * Read DSP sample time.
 * Equivalent to DSPReadLong(dspTime,DSP_L_TICK);
 */


MKDSP_API DSPFix48 *DSPMKGetTime(void);
/*
 * Read DSP sample time.  Returns NULL on error instead of error code.
 * Pointer returned is to freshly allocated DSPFix48.
 */


MKDSP_API int DSPMKEnableAtomicTimed(DSPFix48 *aTimeStampP);
/* 
 * Tell the DSP to begin an atomic block of timed messages.
 */


MKDSP_API int DSPMKDisableAtomicTimed(DSPFix48 *aTimeStampP);
/* 
 * Terminate an atomic block of timed messages in the DSP TMQ.
 */


MKDSP_API int DSPMKPauseOrchestraTimed(DSPFix48 *aTimeStampP);
/*
 * Place the orchestra into the paused state at the requested DSP sample time.
 */

#endif
