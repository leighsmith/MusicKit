#ifndef __MK_monitor_independent_H___
#define __MK_monitor_independent_H___
/* monitor_independent.h - libdsp functions independent of the DSP monitor used
 * Copyright 1988-1992, NeXT Inc.  All rights reserved.
 * Author: Julius O. Smith III
 */

/* 
 * This header file contains procedure prototypes for the monitor-independent
 * subset of the functions in libdsp_s.a.  Its main purpose is to "document"
 * which functions can be used independently of the Music Kit and array
 * processing DSP monitors.  Only the host interface of the DSP is
 * touched (via the Sound/DSP driver) by the functions. The functions can 
 * be considered higher level alternatives to the snddriver_*() functions
 * in libsys_s.a, and direct Mach messaging.  The functions which set up
 * open modes assumed DSPOpenNoBoot() or variant will be called.
 */   	

/*

#import "DSPStructMisc.h"
#import "DSPConversion.h"
#import "DSPSymbols.h"
#import "DSPError.h"

/*
    Not monitor-independent:
	#import "DSPControl.h"
	#import "DSPMessage.h"
	#import "DSPTransfer.h"
*/

/* ============================= DSPReadFile.c ============================= */
int DSPReadFile(DSPLoadSpec **dsppp, const char *fn);
/*
 * Read in a DSP file (as produced by the assembler in absolute mode).
 * It looks in the system-wide .dsp directory for the given file if 
 * the user's working directory does not contain a readable version of 
 * the file (.lnk, .lod, or .dsp).
 */

/* =============================== DSPBoot.h =============================== */

int DSPBootFile(char *fn);
/*
 * Boot DSP from the file specified.
 * Equivalent to DSPReadFile followed by DSPBoot.
 */


int DSPBoot(DSPLoadSpec *system);
/* 
 * Load DSP bootstrap program.
 * DSPBoot closes the DSP if it is open, resets it, and feeds the
 * resident monitor supplied in the struct 'system' to the bootstrapping DSP.
 * If system is NULL, the default resident monitor is supplied to the DSP.
 * On return, the DSP is open.
 */

/* =============================== DSPObject.h ============================= */
/* 
 * Excerpt - Low level DSP access and control.
 */

/*
 * These functions are organized logically with respect to the DSP open
 * routines in that functions apearing before the open routines must be called
 * before the DSP is opened (or any time), and functions apearing after the
 * open routines must be (or typically are) called after the DSP is opened.
 */

extern int DSPGetHostTime(void);
/*
 * Returns the time in microseconds since it was last called.
 */


/*********** Utilities global with respect to all DSP instances **************/


extern int DSPGetDSPCount(void);
/* 
 * Return number of DSPs in current system.
 */


extern int DSPSetHostName(char *newHost);
/*
 * Set name of host on which to open the DSP.  
 * The default is NULL which means that of the local processor.
 * Currently, only one DSP can be open at a time.
 */

extern char *DSPGetHostName(void);
/*
 * Get name of host on which the DSP is being or will be used.
 * NULL means that of the local processor.
 * Use gethostname(2) to retrieve the local processor's host name.
 */

extern int DSPSetCurrentDSP(int newidsp);
/* 
 * Set DSP number.  Calls to functions in this file will act on that DSP.
 * Release 2.0 supports only one DSP: "DSP 0".
 */

extern int DSPGetCurrentDSP(void);
/* 
 * Returns currently selected DSP number.
 */

/*************** Getting and setting "DSP instance variables" ****************/

/*
 * DSP "get" functions do not follow the convention of returning an error code.
 * Instead (because there can be no error), they return the requested value.
 * Each functions in this class has a name beginning with "DSPGet".
 */


extern int DSPGetMessagePriority(void);
/*
 * Return DSP Mach message priority:
 *
 *	 DSP_MSG_HIGH		0
 *	 DSP_MSG_MED		1
 *	 DSP_MSG_LOW		2
 *
 * Only medium and low priorities are used by user-initiated messages.
 * Normally, low priority should be used, and high priority messages
 * will bypass low priority messages enqueued in the driver.  Note,
 * however, that a multi-component message cannot be interrupted once it 
 * has begun.  The Music Kit uses low priority for all timed messages
 * and high priority for all untimed messages (so that untimed messages
 * may bypass any enqueued timed messages).
 *
 */


extern int DSPSetMessagePriority(int pri);
/*
 * Set DSP message priority for future messages sent to the kernel.
 * Can be called before or after DSP is opened.
 */

/*********** Enable/Disable/Query for DSP open-state variables ************/

/* 
 * In general, the enable/disable functions must be called BEFORE the DSP
 * is opened.  They have the effect of selecting various open
 * modes for the DSP.  The function which ultimately acts on them is
 * DSPOpenNoBoot() (which is called by the DSP init and boot functions).
 */


extern int DSPGetOpenPriority(void);
/*
 * Return DSP open priority.
 *	0 = low priority (default).
 *	1 = high priority (used by DSP debugger, for example)
 * If the open priority is high when DSPOpenNoBoot is called,
 * the open will proceed in spite of the DSP already being in use.
 * In this case, a new pointer to the DSP owner port is returned.
 * Typically, the task already in control of the DSP is frozen and
 * the newly opening task is a DSP debugger stepping in to look around.
 * Otherwise, the two tasks may confuse the DSP with interleaved commands.
 * Note that deallocating the owner port will give up ownership capability
 * for all owners.
 */


extern int DSPSetOpenPriority(int pri);
/*
 * Set DSP open priority.
 * The new priority has effect when DSPOpenNoBoot is next called.
 *	0 = low priority (default).
 *	1 = high priority (used by DSP debugger, for example)
 */


extern int DSPEnableHostMsg(void);
/* 
 * Enable DSP host message protocol.
 * This has the side effect that all unsolicited "DSP messages"
 * (writes from the DSP to the host) are split into two streams.
 * All 24-bit words from the DSP with the most significant bit set
 * are interpreted as error messages and split off to an error port.
 * On the host side, a thread is spawned which sits in msg_receive()
 * waiting for DSP error messages, and it forwards then to the DSP 
 * error log, if enabled.  Finally, the DSP can signal an abort by
 * setting both HF2 and HF3. In the driver, the protocol bits set by
 * enabling this mode are (cf. <sound/sounddriver.h>):
 * SND_DSP_PROTO_{DSPMSG|DSPERR|HFABORT|RAW}.
 */


extern int DSPDisableHostMsg(void);
/* 
 * Disable DSP host message protocol.
 * All writes from the DSP come in on the "DSP message" port.
 * The "DSP errors" port will remain silent.
 * This corresponds to setting the DSP protocol int to 0 in
 * the DSP driver.  (cf. snddriver_dsp_protocol().)
 */


extern int DSPHostMsgIsEnabled(void);
/* 
 * Return state of HostMsg enable flag.
 */


/*********************** OPENING AND CLOSING THE DSP ***********************/


extern int DSPOpenNoBootHighPriority(void);
/*
 * Open the DSP at highest priority.
 * This will normally only be called by a debugger trying to obtain
 * ownership of the DSP when another task has ownership already.
 */ 


extern int DSPOpenNoBoot(void);
/*
 * Open the DSP in the state implied by the DSP state variables.
 * If the open is successful or DSP is already open, 0 is returned.
 * After DSPOpenNoBoot, the DSP is open in the reset state awaiting
 * a bootstrap program download.  Normally, only DSPBoot or a debugger
 * will ever call this routine.	 More typically, DSPInit() is called 
 * to open and reboot the DSP.
 */


extern int DSPIsOpen(void);
/* 
 * Returns nonzero if the DSP is open.
 */

extern int DSPClose(void);
/*
 * Close the DSP device (if open). If sound-out DMA is in progress, 
 * it is first turned off which leaves the DSP in a better state.
 * Similarly, SSI sound-out from the DSP, if running, is halted.
 */


extern int DSPCloseSaveState(void);
/*
 * Same as DSPClose(), but retains all enabled features such that
 * a subsequent DSPBoot() or DSPOpenNoBoot() will come up in the same mode.
 * If sound-out DMA is in progress, it is first turned off.
 * If SSI sound-out is running, it is halted.
 */


extern int DSPRawCloseSaveState(void);
/*
 * Close the DSP device without trying to clean up things in the DSP,
 * and without clearing the open state (so that a subsequent open
 * will be with the same modes).
 * This function is normally only called by DSPCloseSaveState, but it is nice
 * to have interactively from gdb when the DSP is wedged.
 */


extern int DSPRawClose(void);
/*
 * Close the DSP device without trying to clean up things in the DSP.
 * This function is normally only called by DSPClose, but it is nice
 * to have interactively from gdb when the DSP is known to be hosed.
 */


extern int DSPOpenWhoFile(void);
/*
 * Open DSP "who file" (unless already open) and log PID and time of open.
 * This file is read to find out who has the DSP when an attempt to
 * access the DSP fails because another task has ownership of the DSP
 * device port.  The file is removed by DSPClose().  If a task is
 * killed before it can delete the who file, nothing bad will happen.
 * It will simply be overwritten by the next open.
 */


extern int DSPCloseWhoFile(void);
/*
 * Close and delete the DSP lock file.
 */


char *DSPGetOwnerString(void);
/*
 * Return string containing information about the current task owning
 * the DSP.  An example of the returned string is as follows:
 * 
 *	DSP opened in PID 351 by me on Sun Jun 18 17:50:46 1989
 *
 * The string is obtained from the file /tmp/dsp_lock and was written
 * when the DSP was initialized.  If the DSP is not in use, or if there
 * was a problem reading the lock file, NULL is returned.
 * The owner string is returned without a newline.
 */


extern int DSPReset(void);
/* 
 * Reset the DSP.
 * The DSP must be open.
 * On return, the DSP should be awaiting a 512-word bootstrap program.
 */


/********************** READING/WRITING DSP HOST FLAGS ***********************/

extern int DSPSetHF0(void);
/*
 * Set bit HF0 in the DSP host interface.
 */


extern int DSPClearHF0(void);
/*
 * Clear bit HF0 in the DSP host interface.
 */


extern int DSPGetHF0(void);
/* 
 * Read state of HF0 flag of ICR in DSP host interface.
 */


extern int DSPSetHF1(void);
/*
 * Set bit HF1 in the DSP host interface.
 */


extern int DSPClearHF1(void);
/*
 * Clear bit HF1 in the DSP host interface.
 */


extern int DSPGetHF1(void);
/* 
 * Read state of HF1 flag of ICR in DSP host interface.
 */


extern int DSPGetHF2(void);
/*
 * Return nonzero if bit HF2 in the DSP host interface is set, otherwise FALSE.
 */


extern int DSPGetHF3(void);
/*
 * Return nonzero if bit HF3 in the DSP host interface is set, otherwise FALSE.
 */


extern int DSPGetHF2AndHF3(void);
/*
 * Return nonzero if bits HF2 and HF3 in the DSP host interface are set, 
 * otherwise FALSE.  A driver DSP protocol mode bit can be set such
 * that both bits indicate the DSP has aborted.
 */

/****************** READING/WRITING HOST-INTERFACE REGISTERS *****************/


extern int DSPReadRegs(unsigned int *regsP);
/* 
 * Read DSP Interrupt Control Register (ICR), 
 * Command Vector Register (CVR),
 * Interrupt Status Register (ISR), and
 * Interrupt Vector Register (IVR),
 * in that order, concatenated to form
 * a single 32-bit word.
 */


extern unsigned int DSPGetRegs(void);
/*
 * Same as DSPReadRegs() but returns regs as function value.
 */


extern int DSPWriteRegs(
    int mask,			/* bit mask in (ICR,CVR,ISR,IVR) longword */
    int value);			/* bit values in (ICR,CVR,ISR,IVR) longword */
/*
 * Set DSP host-interface bits to given value.
 * Returns 0 for success, nonzero on error.
 * Example:
 *	DSPWriteRegs(DSP_ICR_HF0_REGS_MASK,DSP_ICR_HF0_REGS_MASK),
 * sets host flag 0 to 1 and 
 *	DSPWriteRegs(DSP_ICR_HF0_REGS_MASK,0));
 * clears it.
 */


extern int DSPReadICR(int *icrP);		
/* 
 * Read DSP Interrupt Control Register (ICR).
 * value returned in *icrP is 8 bits, right justified.
 */


extern int DSPGetICR(void);
/*
 * Return ICR register of the DSP host interface.
 */


extern int DSPReadCVR(int *cvrP);
/* 
 * Read DSP Command Vector Register (CVR).
 * value returned in *cvrP is 8 bits, right justified.
 */


extern int DSPGetCVR(void);
/*
 * Return CVR register of the DSP host interface.
 */


extern int DSPHostCommand(int cmd);
/*
 * Issue DSP "host command". The low-order 5 bits of cmd are sent.
 * There are 32 possible host commands, with 18 predefined by Motorola.
 * Others are used by the DSP driver for DMA control. See
 * <sound/sounddriver.h> for their definitions.
 */


extern int DSPReadISR(int *isrP);
/*
 * Read DSP Interrupt Status Register (ISR).
 * value returned in *isrP is 8 bits, right justified.
 */


extern int DSPGetISR(void);
/*
 * Return ISR register of the DSP host interface.
 */


extern int DSPGetRX(void);
/*
 * Return RX register of the DSP host interface.
 * Equivalent to "DSPReadRX(&tmp); return tmp;".
 */


extern int DSPReadDataArrayMode(DSPFix24 *data, int nwords, int mode);
/*
 * Read nwords words from DSP Receive Byte Registers (RX) in "DMA mode" mode.
 * The mode is DSP_MODE<n> where <n> = 8,16,24,32, (using the defines in 
 * <sound/sounddriver.h>) and the modes are described under the function
 * DSPReadArraySkipMode() (which requires the MK or AP DSP monitor).
 * RXDF must be true for each word before it is read.  
 * Note that it is an "error" for RXDF not to come true.  
 * Call DSPAwaitData(msTimeLimit) before calling
 * DSPReadRX() in order to await RXDF indefinitely.  
 * The default time-out used here may change in the future, and it is 
 * currently infinity.
 * This function is for simple non-DMA data reads from the DSP.
 * The only protocol used with the DSP is that HF1 is set during the read.
 */


extern int DSPReadMessageArrayMode(DSPFix24 *data, int nwords, int mode);
/*
 * Like DSPReadDataArrayMode() except for DSP messages.
 * Only useable in "host message protocol" mode, i.e., the driver takes
 * DSP interrupts and places words from the DSP into a "message buffer".
 * Return value is 0 for success, nonzero if an element could not be read
 * after trying for DSPDefaultTimeLimit seconds.
 * If the read could not finish, the number of elements successfully 
 * read + 1 is returned.
 * The mode specifies the data mode as in DSPReadDataArrayMode().
 */


extern int DSPReadRXArrayMode(DSPFix24 *data, int nwords, int mode);
/*
 * Equivalent to 
 *
 * 	if (DSPHostMsgIsEnabled())
 *	 	return DSPReadMessageArrayMode();
 *	 else 
 *	 	return DSPReadDataArrayMode();
 */


extern int DSPAwaitRX(int msTimeLimit);
/*
 * Equivalent to 
 *
 * 	if (DSPHostMsgIsEnabled())
 *	 	return DSPAwaitMessages(msTimeLimit);
 *	 else 
 *	 	return DSPAwaitData(msTimeLimit);
 */


extern int DSPReadRXArray(DSPFix24 *data, int nwords);
/*
 * Equivalent to DSPReadRXArrayMode(data,nwords,DSP_MODE32);
 * Each value is returned as 24 bits, right justified in 32.
 */


extern int DSPReadRX(DSPFix24 *wordp);
/*
 * Equivalent to DSPReadRXArrayMode(data,1,DSP_MODE32);
 * Value returned in *wordp is 24 bits, right justified.
 * after waiting DSPDefaultTimeLimit.  
 */


extern int DSPWriteTX(DSPFix24 word);
/*
 * Write word into DSP transmit byte registers.
 * Low-order 24 bits are written from word.
 */


extern int DSPWriteTXArray(
    DSPFix24 *data,
    int nwords);
/* 
 * Feed array to DSP transmit register.
 */


extern int DSPWriteTXArrayB(
    DSPFix24 *data,
    int nwords);
/*
 * Feed array *backwards* to DSP TX register 
 */


/***************** READ/WRITE ARRAY FROM/TO DSP HOST INTERFACE ***************/

/* 
	For DMA array transfers to/from DSP, use the "snddriver" functions.
	They are prototyped in <sound/sound_client.h>.
	See /NextDeveloper/Examples/DSP/SoundDSPDriver/* for examples of 
		using them.
 */


/*************************** DSP SYNCHRONIZATION ***************************/


extern int DSPAwaitCondition(int mask, int value, int msTimeLimit);
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


extern int DSPResumeAwaitingCondition(int msTimeLimit);
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


extern int DSPAwaitConditionNoBlock(
    int mask,		/* mask to block on as bits in (ICR,CVR,ISR,IVR) */
    int value);		/* 1 or 0 as desired for each 1 mask bit */
/*
 * Same as DSPAwaitCondition() except the function returns immediately.
 * The condition serves as a possible block for the DSP command queue
 * within the driver, but not for the calling program.
 */


extern int DSPAwaitHC(int msTimeLimit);
/*
 * Wait for "HC bit" to clear. 
 * The HC clears when the next instruction to be executed in the DSP
 * is the first word of the host command interrupt vector.
 * Equivalent to "DSPAwaitCondition(0x00800000,0x00000000,msTimeLimit);"
 */


extern int DSPAwaitTRDY(int msTimeLimit);
/*
 * Wait for "TRDY bit" to set. 
 * Equivalent to "DSPAwaitCondition(0x00040000,0x00040000,msTimeLimit);"
 */


extern int DSPAwaitHF3Clear(int msTimeLimit);
/*
 * Wait for HF3 = "MK TMQ full" or "AP Program Busy" bit to clear. 
 * Equivalent to "DSPAwaitCondition(0x00100000,0x00100000,msTimeLimit);"
 */


extern int DSPAwaitHostMessage(int msTimeLimit);
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


/******************************** DSP MESSAGES *******************************/

/* 
 * Any unsolicited single word written by the DSP to the host (via RX) 
 * is defined as a "DSP Message".  This 24-bit message consist of a high-order
 * "opcode" byte, and two low-order "data" bytes. 
 *
 * If  "DSPEnableHostMsg()" is called before opening the DSP, 
 * "Host Message protocol" is used by the DSP driver.  
 * In this mode, RREQ is kept on in the DSP interface,
 * and each "DSP message" causes an interrupt in the host.  The DSP messages 
 * are buffered up by the driver.  When not using host message protocol,
 * RXDF is ignored, and only "data" is assumed to come from the DSP.
 * The data does not go into a driver buffer.  Instead, there are driver
 * calls to explicitly read data from the RX register.
 *
 * Note that "complex DMA mode" also
 * forces the driver to "listen" to the DSP.  In that case, if an 
 * unrecognized DSP message comes in (anything other than a DMA request)
 * the message goes to the DSP message buffer as in host message protocol
 * mode.
 */

extern int DSPDataIsAvailable(void);
/*
 * Return nonzero if RXDF is set.
 */


extern int DSPAwaitData(int msTimeLimit);
/*
 * Block until RXDF is set in the DSP host interface.
 * An msTimeLimit of zero means wait forever.
 * Returns 0 when data available, nonzero if
 * no data available before time-out.
 */

extern int DSPMessageIsAvailable(void);
/*
 * Return nonzero if DSP has one or more pending DSP messages waiting in the
 * DSP host interface.	
 * Only useable in host message protocol mode or to look for unrecognized
 * messages in complex DMA mode.
 */

extern int DSPAwaitMessages(int msTimeLimit);
/*
 * Block until DSPMessageIsAvailable() will return nonzero.
 * An msTimeLimit of zero means wait forever.
 * Returns 0 when a message is available, nonzero on time-out.
 * Only useable in host message protocol mode.
 */

extern int DSPReadMessages(int msTimeLimit);
/*
 * Read messages from DSP into internal buffers.
 * Returns 0 if DSP messages were read by msTimeLimit milliseconds.
 * A 0 msTimeLimit means DON'T WAIT if there are no messages waiting
 * from the DSP.  See DSPMessage.h for functions which process the messages.
 * Only useable in host message protocol mode or to look for unrecognized
 * messages in complex DMA mode.
 */

extern int DSPMessageGet(int *msgp);
/*
 * Return a single DSP message in *msgp, if one is waiting,
 * otherwise wait DSPDefaultTimeLimit for it (0 => wait forever). 
 * On time-out, returns the DSP error code DSP_ENOMSG.
 * The DSP message returned in *msgp is 24 bits, right justified.
 * Only called when a message is really expected.
 * Use DSPAwaitMessages(msTimeLimit) to obtain a precise time-limit.
 * Use DSPMessageIsAvailable() to determine if a message is waiting.
 */

extern int DSPFlushMessages(void);
/*
 * Flush any unread messages from the DSP.
 */

extern int DSPFlushMessageBuffer(void);
/*
 * Flush any DSP messages cached internally in libdsp.
 * Same as DSPFlushMessages() except that the DSP
 * is not checked for more messages.  Anything
 * queued up in the driver buffer will stay there.
 * Use DSPFlushMessages() to flush the driver's message queue.
 * Note: since there is no input-data buffer in the driver,
 * there is no DSPFlushDataBuffer() function.
 */


/******************************* DSP Negotiation Port ************************/

int DSPSetNegotiationPort(port_t neg_port);
/* 
 * Set port given to anyone attempting to open the DSP.
 */

port_t DSPGetNegotiationPort(void);
/* 
 * Get port set by DSPSetNegotiationPort().
 */

/******************************* Port fetching *******************************/

/*
 * In all these routines for obtaining Mach ports,
 * the DSP must be opened before asking for the ports.
 */

port_t DSPGetOwnerPort(void);
/* 
 * Get port conveying DSP and sound-out ownership capability.
 */


port_t DSPGetHostMessagePort(void);
/* 
 * Get port used to send "host messages" to the DSP.
 * Also called the "command port" in other contexts.
 */


port_t DSPGetDSPMessagePort(void);
/* 
 * Get port used to send "DSP messages" from the DSP to the host.
 * Messages on this port are enabled by DSPEnableHostMsg().
 */


port_t DSPGetErrorPort(void);
/* 
 * Get port used to send "DSP error messages" from the DSP to the host.
 * Error messages on this port are enabled by DSPEnableHostMsg().
 */


port_t DSPMKGetSoundPort(void);
/* 
 * Get sound device port.
 */


port_t DSPMKGetSoundOutStreamPort(void);
/* 
 * Get stream port used to convey "sound out" buffers from the DSP
 * to the stereo DAC.
 */

/************************ SIMULATOR FILE MANAGEMENT **************************/

extern int DSPIsSimulated(void);
/* 
 * Returns nonzero if the DSP is simulated.
 */


extern int DSPIsSimulatedOnly(void);
/* 
 * Returns nonzero if the DSP simulator output is open but the DSP device 
 * is not open.	 This would happen if DSPOpenSimulatorFile() were called
 * without opening the DSP.
 */


FILE *DSPGetSimulatorFP(void);
/*
 * Returns file pointer used for the simulator output file, if any.
 */


extern int DSPOpenSimulatorFile(char *fn);			
/* 
 * Open simulator output file fn.
 */


extern int DSPStartSimulator(void);
/*
 * Initiate simulation mode, copying DSP commumications to the simulator
 * file pointer.
 */


extern int DSPStartSimulatorFP(FILE *fp);
/*
 * Initiate simulation mode, copying DSP commumications to the file pointer fp.
 * If fp is NULL, the previously set fp, if any, will be used.
 */


extern int DSPStopSimulator(void);
/*
 * Clear simulation bit, halting DSP command output to the simulator file.
 */


extern int DSPCloseSimulatorFile(void);
/* 
 * Close simulator output file.
 */


/*********************** DSP COMMANDS FILE MANAGEMENT ************************/

/*
 * DSP commands are saved only for libdsp functions, not snddriver functions 
 * and not direct Mach messaging.
 */

extern int DSPIsSavingCommands(void);
/* 
 * Returns nonzero if a "DSP commands file" is open.
 */

extern int DSPIsSavingCommandsOnly(void);
/* 
 * Returns nonzero if the DSP commands file is open but the DSP device 
 * is not open.	 This would happen if DSPOpenCommandsFile() were called
 * without opening the DSP.
 */

extern int DSPOpenCommandsFile(char *fn);
/*
 * Opens a "DSP Commands file" which will receive all Mach messages
 * to the DSP.  The filename suffix should be ".snd".  This pseudo-
 * sound file can be played by the sound library.
 */

/******************************* Miscellaneous *******************************/

/******************************* Miscellaneous *******************************/

int DSPGetProtocol(void);
/*
 * Returns the DSP protocol int in effect.  Some of the relevant bits are
 *
 *   SNDDRIVER_DSP_PROTO_RAW     - disable all DSP interrupts
 *   SNDDRIVER_DSP_PROTO_DSPMSG  - enable DSP messages (via intrpt)
 *   SNDDRIVER_DSP_PROTO_DSPERR  - enable DSP error messages (hi bit on)
 *   SNDDRIVER_DSP_PROTO_C_DMA   - enable "complex DMA mode"
 *   SNDDRIVER_DSP_PROTO_HFABORT - recognize HF2&HF3 as "DSP aborted"
 *
 * See the snddriver function documentation for more information (e.g.
 * snddriver_dsp_protocol()).
 */

int DSPSetProtocol(int newProto);
/*
 * Sets the protocol used by the DSP driver.
 * This function logically calls snddriver_dsp_proto(), but it's faster
 * inside libdsp optimization blocks.  (As many Mach messages as possible are 
 * combined into a single message to maximize performance.)
 */

extern int DSPSetComplexDMAModeBit(int bit);
/*
 * Set or clear the bit "SNDDRIVER_DSP_PROTO_CDMA" in the DSP driver protocol.
 */

extern int DSPSetHostMessageMode(void);
/*
 * Set "Host Message" protocol.  This is the dynamic version of DSPEnableHostMsg()
 * followed by a form of DSPOpen().  It can be called after the DSP is already open.
 * Host message mode consists of the driver protocol flags 
 * SNDDRIVER_DSP_PROTO_{DSPMSG|DSPERR} in addition to the flags enabled by libdsp
 * when not in host message mode, which are SNDDRIVER_DSP_PROTO_{RAW|HFABORT}.
 */

extern int DSPClearHostMessageMode(void);
/*
 * Clear "Host Message" protocol.  This is the dynamic version of DSPDisableHostMsg()
 * followed by a form of DSPOpen().  It can be called after the DSP is already open.
 * Clearing host message mode means clearing the driver protocol flags 
 * SNDDRIVER_DSP_PROTO_{DSPMSG|DSPERR}.  The usual protocol bits
 * SNDDRIVER_DSP_PROTO_{RAW|HFABORT} are left on.  
 * 
 * Note that the "complex DMA mode bit " bit is not touched.  
 * If you have enabled the SNDDRIVER_DSP_PROTO_C_DMA protocol bit,
 * clearing host message mode will probably not do what you want (prevent the driver
 * from taking DSP interrupts and filling the message buffer with whatever the
 * DSP has to send).  In general, the driver is taking DSP interrupts whenever
 * SNDDRIVER_DSP_PROTO_RAW is off and when any of
 * SNDDRIVER_DSP_PROTO_{DSPMSG|DSPERR|C_DMA} are set.  
 * 
 * When the "RAW" mode bit is off, you can think of it as "release 1.0 mode", 
 * where you get DSPERR mode by default, even with no other protocol bits enabled.
 * Consult the snddriver function documentation for more details
 * of this complicated protocol business.  Yes, there's actually documentation.
 * ("Inside every mode, there is a simpler mode struggling to get out.")
 */

extern int DSPCloseCommandsFile(DSPFix48 *endTimeStamp);
/*
 * Closes a "DSP Commands file".  The endTimeStamp is used by the
 * sound library to terminate the DSP-sound playback thread.
 */

extern int DSPGetMessageAtomicity(void);
/*
 * Returns nonzero if libdsp Mach messages are atomic, zero otherwise.
 */

extern int DSPSetMessageAtomicity(int atomicity);
/*
 * If atomicity is nonzero, future libdsp Mach messages will be atomic.
 * Otherwise they will not be atomic.  If not atomic, DMA complete interrupts,
 * and DSP DMA requests, for example, can get in between message components,
 * unless they are at priority DSP_MSG_HIGH.
 * (DMA related messages queued by the driver in response to DSP or user
 * DMA initiation are at priority DSP_MSG_HIGH, while libdsp uses 
 * DSP_MSG_LOW for timed messages and DSP_MSG_MED for untimed messages to
 * the DSP.
 */

extern int DSPCloseCommandsFile(DSPFix48 *endTimeStamp);
/*
 * Closes a "DSP Commands file".  The endTimeStamp is used by the
 * sound library to terminate the DSP-sound playback thread.
 */

extern int DSPGetMessageAtomicity(void);
/*
 * Returns nonzero if libdsp Mach messages are atomic, zero otherwise.
 */

extern int DSPSetMessageAtomicity(int atomicity);
/*
 * If atomicity is nonzero, future libdsp Mach messages will be atomic.
 * Otherwise they will not be atomic.  If not atomic, DMA complete interrupts,
 * and DSP DMA requests, for example, can get in between message components,
 * unless they are at priority DSP_MSG_HIGH.
 * (DMA related messages queued by the driver in response to DSP or user
 * DMA initiation are at priority DSP_MSG_HIGH, while libdsp uses 
 * DSP_MSG_LOW for timed messages and DSP_MSG_MED for untimed messages to
 * the DSP.
 */

/******************************  DSP Symbols *********************************/

/*
 * DSP symbols are produced by asm56000, the DSP56000/1 assembler.
 * They are written into either a .lnk or .lod file, depending on 
 * whether the assembly was "relative" or "absolute", respectively.
 * When DSPReadFile() reads one of these files (ASCII), or their .dsp file
 * counterparts (binary), all symbols are loaded as well into the
 * structs described in /usr/include/dsp/dsp_structs.h.  The functions
 * below support finding these symbols and their values.  Because the
 * assembler does not fully support mixed case, all symbol names are 
 * converted to upper case when read in, and any name to be searched for
 * in the symbol table is converted to upper case before the search.
 */


extern int DSPSymbolIsFloat(DSPSymbol *sym);
/* 
 * Returns TRUE if the DSP assembler symbol is type 'F'.
 */


extern DSPSymbol *DSPGetSectionSymbol(char *name, DSPSection *sec);
/*
 * Find symbol within the given DSPSection with the given name. 
 * See "/LocalDeveloper/Headers/dsp/dsp_structs.h" for the definition of a 
 * DSPSection. Equivalent to trying DSPGetSectionSymbolInLC() for each of 
 * the 12 DSP location counters.
 */


extern DSPSymbol *DSPGetSectionSymbolInLC(char *name, DSPSection *sec, 
				   DSPLocationCounter lc);
/*
 * Find symbol within the given DSPSection and location counter
 * with the given name.  See "/LocalDeveloper/Headers/dsp/dsp_structs.h" 
 * for an lc list.
 */


extern int DSPReadSectionSymbolAddress(DSPMemorySpace *spacep,
				       DSPAddress *addressp,
				       char *name,
				       DSPSection *sec);
/*
 * Returns the space and address of symbol with the given name in the 
 * given DSP section.  Note that there is no "Get" version because
 * both space and address need to be returned.
 */

extern int DSPGetSystemSymbolValue(char *name);
/*
 * Returns the value of the symbol "name" in the DSP system image, or -1 if
 * the symbol is not found or the DSP is not opened.  
 *
 * The "system image" is that of the currently loaded monitor in the currently
 * selected DSP.  The current DSP must be open so for this monitor image to
 * be available.
 * 
 * The requested symbol
 * is assumed to be type "I" and residing in the GLOBAL section under location
 * counter "DSP_LC_N" (i.e., no memory space is associated with the symbol).
 * No fixups are performed, i.e., the symbol is assumed to belong to an 
 * absolute (non-relocatable) section.  
 * See /usr/local/lib/dsp/monitor/apmon_8k.lod and mkmon_8k.lod for example 
 * system files which compatibly define system symbols.
 *
 * Equivalent to
 *  DSPGetSectionSymbol(name,DSPGetUserSection(DSPGetSystemImage()));
 * (because the DSP system is assembled in absolute mode, and there
 * is only one section, the global section, for absolute assemblies).
 */

extern int DSPGetSystemSymbolValueInLC(char *name, DSPLocationCounter lc);
/*
 * Same as DSPGetSystemSymbolValue() except faster because the location 
 * counter is known, and the rest are not searched.
 */

int DSPReadSystemSymbolAddress(DSPMemorySpace *spacep, DSPAddress *addressp,
			       char *name);
/*
 * Same as DSPReadSectionSymbolAddress() except it knows to look in the
 * system section (GLOBAL).
 */

#endif
