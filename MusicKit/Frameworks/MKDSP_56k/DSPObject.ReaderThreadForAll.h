#ifndef __MK_DSPObject.ReaderThreadForAll_H___
#define __MK_DSPObject.ReaderThreadForAll_H___
/* DSPObject.h - Low level DSP access and control functions.
 * Copyright 1988-1992, NeXT Inc.  All rights reserved.
 * Author: Julius O. Smith III
 */

/*
 * This file is organized logically with respect to the DSPOpen*()
 * routines in that functions apearing before the open routines must be
 * called before the DSP is opened (or any time), and functions apearing 
 * after the open routines must be (or are typically) called after the 
 * DSP is opened.
 *
 * The functions which depend on the Music Kit DSP monitor have the
 * prefix "DSPMK".  The prefix "DSP" may either be independent of the
 * monitor used, or require the array processing monitor.  Generally,
 * functions with prefix "DSP are monitor-independent unless they involve
 * input/output to or from private DSP memory, i.e., unless they require
 * services of a DSP monitor to carry out their function.
 * To upgrade your own DSP monitor to support these DSP functions, lift
 * out the I/O support in the array processing monitor.  The sources are
 * distributed online in /usr/local/lib/dsp/smsrc (system monitor source).
 */

#import <stdio.h>
#import "dsp_types.h"
#import "dsp_structs.h"

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


extern double DSPMKGetSamplingRate(void);
/*
 * Returns sampling rate assumed by DSP software in Hz.
 */


extern int DSPMKSetSamplingRate(double srate);
/*
 * Set sampling rate assumed by DSP software to rate in samples per
 * second (Hz).	 Note that only sampling rates 22050.0 and 44100.0 
 * are supported for real time digital audio output.  Use of other sampling
 * rates implies non-real-time processing or sound-out through the DSP serial
 * port to external hardware.
 */


extern int DSPEnableMachMessageOptimization(void);
extern int DSPDisableMachMessageOptimization(void);
/*
 * By default, optimization is enabled.  In this mode, as many Mach
 * message components as possible are combined into a single, multicomponent
 * message.  This minimizes context-switching between the application and
 * the kernel.  The ability to turn it off exists solely to provide a 
 * workaround in the event a bug turns up in it.  We know there is a problem
 * with non-dma 16-bit and 8-bit data messages which are not at the beginning
 * of the message, and in these cases optimization is always disabled.
 */


/*********** Enable/Disable/Query for DSP open-state variables ************/

/* 
 * In general, the enable/disable functions must be called BEFORE the DSP
 * is "opened" via DSPInit(), DSPAPInit(), DSPMKInit(), DSPBoot(), or one of
 * the DSPOpen*() functions.  They have the effect of selecting various open
 * modes for the DSP.  The function which ultimately acts on them is
 * DSPOpenNoBoot() (which is called by the Init and Boot functions above).
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


int DSPEnableHostMsg(void);
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


int DSPDisableHostMsg(void);
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


extern int DSPMKIsWithSoundOut(void);
/* 
 * Returns nonzero if the DSP is linked to sound out.
 */


extern int DSPMKEnableSoundOut(void);
/* 
 * Enable DSP linkage to sound out.
 * When DSP is next opened, it will be linked to sound out.
 */


extern int DSPMKDisableSoundOut(void);
/* 
 * Disable DSP linkage to sound out.
 * When DSP is next opened, it will not be linked to sound out.
 */


extern int DSPMKSoundOutIsEnabled(void);
/* 
 * Return state of SoundOut enable flag.
 */


/* Sound out to the serial port */

extern int DSPMKEnableSSISoundOut(void);
/* 
 * Enable DSP serial port sound out.
 * When DSP is next opened with a Music Kit DSP system, it will be 
 * configured to have SSI sound out. 
 */


extern int DSPMKDisableSSISoundOut(void);
/* 
 * Disable DSP serial port sound out.
 * When DSP is next opened with a Music Kit DSP system, the SSI
 * port of the DSP will not be used.
 */


extern int DSPMKSSISoundOutIsEnabled(void);
/* 
 * Return state of serial port SoundOut enable flag.
 */


extern int DSPMKStartSSISoundOut(void);
/*
 * Tell DSP to send sound-out data to the SSI serial port in the DSP.
 * The DSP will block until the SSI port has read the current sound-out
 * buffer.  SSI sound-out to the SSI can not occur simultaneously with 
 * sound-out to the host.
 */


extern int DSPMKStopSSISoundOut(void);
/*
 * Tell DSP not to send sound-out data to the SSI serial port.
 */


/* Sound in from the serial port */

extern int DSPMKEnableSSIReadData(void);
/* 
 * Enable DSP serial port sound in.
 * When DSP is next opened with a Music Kit DSP system, it will be 
 * configured to have SSI sound in.
 */


extern int DSPMKDisableSSIReadData(void);
/* 
 * Disable DSP serial port sound in.
 * When DSP is next opened with a Music Kit DSP system, the SSI
 * port of the DSP will not be used.
 */


extern int DSPMKSSIReadDataIsEnabled(void);
/* 
 * Return state of serial port ReadData enable flag.
 */


extern int DSPMKStartSSIReadData(void);
/*
 * Tell DSP to read sound-in data from the SSI serial port in the DSP.
 * The DSP will block until the SSI port has written the current sound-in
 * buffer.  Sound-in from the SSI can occur simultaneously with SSI sound-out
 */


extern int DSPMKStopSSIReadData(void);
/*
 * Tell DSP not to take sound-in data from the SSI serial port.
 */


extern int DSPMKEnableSmallBuffers(void);
/* 
 * Enable use of small buffers for DSP sound-out.
 * This is something worth doing when real-time response
 * is desired.	Normally, the sound-out driver uses
 * four 8K byte buffers.  With small buffers enabled,
 * four 1K byte buffers are used.
 */


extern int DSPMKDisableSmallBuffers(void);
/* 
 * Disable use of small buffers for DSP sound-out.
 */


extern int DSPMKSmallBuffersIsEnabled(void);
/* 
 * Return true if small sound-out buffers are enabled.
 */


extern int DSPMKEnableTMFlush(void);
/* 
 * Enable flushing timed messages every message.
 * This is for debugging so it is easy to see each message go by.
 * It also can be tried if a bug is suspected in the timed message
 * optimization.
 */


extern int DSPMKDisableTMFlush(void);
/* 
 * Disable auto-flushing timed messages.
 */


extern int DSPMKTMFlushIsEnabled(void);
/* 
 * Return true if auto-flushing timed messages is enabled.
 */


extern int DSPMKEnableBlockingOnTMQEmptyTimed(DSPFix48 *aTimeStampP);
/* 
 * Tell the DSP to block when the Timed Message Queue is empty.
 * This prevents the possibility of late score information.
 * It is necessary to call DSPMKDisableBlockingOnTMQEmptyTimed()
 * after the last time message is sent to the DSP to enable the 
 * computing of all sound after the time of the last message.
 */


extern int DSPMKDisableBlockingOnTMQEmptyTimed(DSPFix48 *aTimeStampP);
/* 
 * Tell the DSP to NOT block when the Timed Message Queue is empty.
 */

/****************** Getting and setting DSP system files *********************/

/*
 * Get/set various DSP system file names.
 * The default filenames are defined in dsp.h.
 * The "get" versions return an absolute path.
 * The "set" versions take a relative path.
 * The environment variable $DSP must be overwritten appropriately
 * before a "get" version will return what the "set" version set.
 * Or, one could place custom system files in the $DSP directory.
 */


/* Misc. routines for getting various directories. */
const char *DSPGetDSPDirectory(void);    /* DSP_SYSTEM_DIRECTORY or $DSP if set */
char *DSPGetSystemDirectory(void); /* <DSPDirectory>/monitor */
char *DSPGetAPDirectory(void);	   /* <DSPDirectory>/DSP_AP_BIN_DIRECTORY */

extern int DSPSetSystem(DSPLoadSpec *system);
/* 
 * Set the DSP system image (called by DSPBoot.c) 
 * If the system name begins with "MKMON" or "APMON",
 * all system filenames (binary, link, and map) are set accordingly.
 */


char *DSPGetSystemBinaryFile(void);
/* 
 * Get system binary filename.
 * Used by DSPBoot.c.
 */


char *DSPGetSystemLinkFile(void);
/* 
 * Get system linkfile name.
 * Used by _DSPMakeMusicIncludeFiles.c.
 */


char *DSPGetSystemMapFile(void);
/* 
 * Get system linkfile name.
 * Used by _DSPRelocateUser.c.
 */


extern int DSPMonitorIsMK(void);
/*
 * Returns true if the currently set DSP system is of the
 * for "mkmon*.dsp", otherwise false.
 */


extern int DSPSetMKSystemFiles(void);
/*
 * Set the system binary, link, and map files to the MK world.
 */


extern int DSPMonitorIsAP(void);
/*
 * Returns true if the currently set DSP system is of the
 * form "apmon*.dsp", otherwise false.
 */


extern int DSPSetAPSystemFiles(void);
/*
 * Set the system binary, link, and map files to the AP world.
 */


/***************************** WriteData Setup *******************************/

/*
 * "Write data" is DSP sound data which is being recorded to disk.
 */


extern int DSPMKSetWriteDataFile(const char *fn);
/* 
 * Set the file-name for DSP write-data to fn.
 */


char *DSPMKGetWriteDataFile(void);
/* 
 * Read the file-name being used for DSP write-data.
 */


extern int DSPMKEnableWriteData(void);
/* 
 * Enable DSP write data.
 * When DSP is next opened, stream ports will be set up between the
 * DSP, host, and sound-out such that write-data can be used.
 * 
 * After opening the DSP with DSPMKInit(), call DSPMKStartWriteDataTimed() 
 * (described below) to spawn the thread which reads DSP data to disk.
 *
 *  Bug: Audible sound-out is disabled during write data.
 */


extern int DSPMKDisableWriteData(void);
/* 
 * Disable DSP write data (default).
 */


extern int DSPMKWriteDataIsEnabled(void);
/* 
 * Return state of DSP write-data enable flag.
 */


extern int DSPMKWriteDataIsRunning(void);
/* 
 * Return nonzero if DSP write data thread is still running.
 */


/* 
 * The write-data time-out is the number of milliseconds to wait in 
 * msg_receive() for a write-data sound buffer from the DSP.
 * On time-out, it is assumed that the DSP is not sending any more
 * write-data, and the thread reading write data terminates.
 */


extern int DSPMKGetWriteDataTimeOut(void);
/* 
 * Get number of milliseconds to wait in msg_receive() for a sound buffer
 * from the DSP before giving up.
 */


extern int DSPMKSetWriteDataTimeOut(int to);
/* 
 * Set number of milliseconds to wait in msg_receive() for a sound buffer
 * from the DSP before giving up.  The default is 60 seconds.  It must be
 * made larger if the DSP program might take longer than this to compute
 * a single buffer of data, and it can be set shorter to enable faster
 * detection of a hung DSP program.
 */


extern int DSPMKSoundOutDMASize(void);
/*
 * Returns the size of single DMA transfer used for DSP sound-out
 * 16-bit words.  This may change at run time depending on whether
 * read-data is used or if a smaller buffer size is requested.
 */


extern int DSPMKClearDSPSoundOutBufferTimed(DSPTimeStamp *aTimeStamp);
/*
 * Clears the DSP's sound-out buffer.  Normally, this is unnecessary
 * because the DSP orchestra puts out zeros by default.
 */

/***************************** ReadData Setup *******************************/

/*
 * "Read data" is DSP sound data (stereo or mono) which is being read from 
 * disk and sent to a Music Kit Orchestra running on the DSP.
 */


extern int DSPMKEnableReadData(void);
/* 
 * Enable DSP read data.
 * When the DSP is next opened, a read-data stream to the DSP will be opened.
 */


extern int DSPMKDisableReadData(void);
/* 
 * Disable DSP read data (default).
 */


extern int DSPMKReadDataIsEnabled(void);
/* 
 * Return state of DSP read-data enable flag.
 */


extern int DSPMKSetReadDataFile(const char *fn);
/* 
 * Set the read-data file-name to fn.
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


DSPLoadSpec *DSPGetSystemImage(void);
/* 
 * Get pointer to struct containing DSP load image installed by DSPBoot().
 * If no system has been loaded, NULL is returned.
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


/************************ Opening the DSP in special modes **************************/

/* 
 * These are equivalent to some combination of DSPEnable*() and/or DSPDisable*()
 * function calls followed by DSPOpen().
 */

#define DSP_8K  (0x1bff)  /* 7k-1  */
#define DSP_32K (0x7bff)  /* 31k-1 */
#define DSP_64K (0xfbff)  /* 63k-1 */

extern int DSPSenseMem(int *memCount);
    /* Returns 0 for success, 1 otherwise.
     * If successful, *memCount is DSP_8K, DSP_32K or DSP_64K (or 64k x 3 = 192K)
     */


extern int DSPMKInit(void);
/* NOTE: The Music Kit currently uses its own version of this function
 *       so that it can check the "app wrapper" for a version of the monitor.
 *
 * Open and reset the DSP such that it is ready to receive a user 
 * orchestra program.  It is the same as DSPBoot(musicKitSystem)
 * followed by starting up sound-out or write-data, if enabled.
 * Also differs from DSPInit() in that "Host Message" protocol is enabled.
 * This protocol implies that DSP messages (any word sent by the DSP
 * to the host outside of a data transfer is a DSP message) with the
 * high-order bit on are error messages, and they are routed to an
 * error port separate from the DSP message port.  Only the Music Kit
 * currently uses this protocol.
 */


extern int DSPMKInitWithSoundOut(int lowSamplingRate);
/* 
 * Open and reset the DSP such that it is ready to receive a user 
 * orchestra program.  Also set up link from DSP to sound-out.
 * If lowSamplingRate is TRUE, the sound-output sampling rate is set
 * to 22KHz, otherwise it is set to 44KHz.
 */


/****************************** SoundOut Handling ****************************/

extern int DSPMKStartSoundOut(void);
/*
 * Tell the DSP to begin sending sound-out packets which were linked
 * to the sound-out hardware by calling DSPMKEnableSoundOut().
 * The DSP must have been initialized via DSPMKInit() already.
 */


extern int DSPMKStopSoundOut(void);
/*
 * Tell DSP to stop sending sound-out packets.
 */


/***************************** WriteData Handling ****************************/

extern int DSPMKStartWriteDataTimed(DSPTimeStamp *aTimeStampP);
/*
 * Tell the DSP to start sending sound-out requests to the DSP driver when a
 * buffer of sound-out data is ready in the DSP.  A thread is spawned which
 * blocks in msg_receive() until each record region is received, and the
 * buffers are written to disk in the file established by
 * DSPMKSetWriteDataFile().  A second effect of this function is that the 
 * DSP will now block until the driver reads each sound-out buffer.
 * This function must be called after the DSP is initialized by DSPMKInit().
 *
 * If sound-out is also requested (via DSPMKEnableSoundOut()), each buffer
 * will be played immediately after it is written to disk.  In this case,
 * there is no need to also call DSPMKStartSoundOut().
 *
 * Bug: Audible sound-out is disabled during write data.
 * Since this should be fixed in the future, do not call both 
 * DSPMKEnableSoundOut() and DSPMKEnableWriteData() if you want
 * the same behavior in future releases.
 */


extern int DSPMKStartWriteData(void);
/*
 * Equivalent to DSPMKStartWriteDataTimed(DSPMK_UNTIMED);
 */


extern int DSPMKGetWriteDataSampleCount(void);
/* 
 * Get number of samples written to disk since write-data was initialized.
 */


extern int DSPMKStopWriteDataTimed(DSPTimeStamp *aTimeStampP);
/*
 * Tell DSP not to generate write-data requests.
 * If write-data is going to disk, it does NOT tell the write-data thread
 * to exit.  This must be the case since only the DSP knows when to turn
 * off write-data. Call DSPMKStopWriteData() to halt the write-data thread,
 * or let it time-out and abort on its own, (cf. DSPMKSetWriteDataTimeOut()).
 * Note that as far as the DSP is concerned, there is no difference between
 * write-data and sound-out.  Thus, calling this function will also turn off
 * sound-out, if it was enabled, whether or not write data was specifically
 * enabled.  A byproduct of this function is that the DSP stops blocking 
 * until each sound-out buffer is read by the driver. The timed start/stop
 * write-data functions can be used to write out specific sections of
 * a Music Kit performance, running as fast as possible (silently, throwing
 * away sound output buffers) during intervals between the stop and start
 * times.
 */


extern int DSPMKStopWriteData(void);
/*
 * Same as DSPMKStopWriteDataTimed(aTimeStampP) but using an untimed
 * host message to the DSP.  Called by DSPMKStopSoundOut().
 * If write-data is going to disk, also tells write-data thread
 * to exit.  See DSPMKStopWriteDataTimed() above.
 */


extern int DSPMKRewindWriteData(void);
/*
 * Rewind write-data to beginning of file.
 * DSPMKStopWriteData() must have been called first to terminate
 * the thread which actively writes the file.
 * After this, write-data can be resumed by DSPMKStartWriteData{Timed}().
 */

extern int DSPMKCloseWriteDataFile(void);
/*
 * Close the write-data file.
 * DSPMKStopWriteData() is called automatically if write-data is running.
 * This function is called by DSPClose(), so it is normally not used
 * unless the file is needed as an input before the DSP is next closed and
 * reopened.
 */

/***************************** ReadData Handling ****************************/

extern int DSPMKStartReadDataTimed(DSPTimeStamp *aTimeStampP);
/*
 * Start read-data flowing from disk to the DSP.
 * This function must be called after the DSP is initialized by DSPMKInit()
 * with read-data enabled by DSPMKEnableReadData(), and with
 * the input disk file having been specified by DSPMKSetReadDataFile().
 * The first two buffers of read-data are sent to the DSP immediately,
 * and a timed message is sent to the DSP saying when to start consumption.
 * A thread is spawned which blocks in msg_send() until each buffer is taken.
 * The DSP will request buffer refills from the driver as needed.
 * There is no timeout as there is for write data because the thread knows 
 * how much data to expect from the file, and it waits forever trying to give 
 * buffers to the DSP.  
 *
 * A second effect of this function is that the DSP orchestra program will 
 * begin blocking on read-data underrun.  There are two read-data buffers in 
 * the DSP, so blocking tends not happen if the host is able to convey sound 
 * from the disk to the DSP in real time or better, on average.
 *
 * If aTimeStamp == DSPMK_UNTIMED, the read-data is started in the PAUSED
 * state.  A subsequent DSPMKResumeReadDataTimed() is necessary to tell the
 * DSP when to begin consuming the read data.  The time-stamp can be set to 
 * contain zero which means start read data immediately in the DSP.
 *
 * Note that DSPMKStartReadDataTimed(ts) is equivalent to
 * DSPMKStartReadDataPaused() followed by DSPMKResumeReadDataTimed(ts).
 */


extern int DSPMKStartReadDataPaused(void);
/*
 * Equivalent to DSPMKStartReadDataTimed(DSPMK_UNTIMED);
 */


extern int DSPMKStartReadData(void);
/*
 * Equivalent to DSPMKStartReadDataTimed(&DSPMKTimeStamp0);
 * Read-data starts in the DSP immediately.
 */


extern int DSPMKGetReadDataSampleCount(void);
/* 
 * Get number of samples sent to the DSP since read-data was started.
 */


extern int DSPMKPauseReadDataTimed(DSPTimeStamp *aTimeStampP); 
/* 
 * Tell the DSP to stop requesting read-data buffer refills at the
 * specified time.  When this happens, the read-data stream going from
 * disk to the DSP will block.
 * 
 * This function and its "resume" counterpart provide
 * a way to save disk space in the read-data file when there are stretches
 * of time in the Music Kit performance during which no read-data is needed.
 * Silence in the read-data file can be squeezed out, and the pause/resume
 * functions can be used to read in the sound sections only when needed.
 */


extern int DSPMKResumeReadDataTimed(DSPTimeStamp *aTimeStampP);
/* 
 * Tell the DSP to resume read-data at the specified time.
 */


extern int DSPMKReadDataIsRunning(void);
/* 
 * Return nonzero if DSP read data thread is still running.
 * "Paused" is considered a special case of "running" since the
 * thread which spools data to the DSP is still alive.
 */


extern int DSPMKStopReadData(void);
/*
 * Tell DSP to stop read-data consumption, if active, and tell the host
 * read-data thread to exit.  See also DSPMKPauseReadDataTimed() above.
 */


extern int DSPMKRewindReadData(void);
/*
 * Rewind read-data to beginning of file.
 * The read-data thread should be paused or stopped during this operation.
 */


extern int DSPMKSetReadDataBytePointer(int offset);
/*
 * Move read-data file pointer to given offset in bytes.
 * Returns file pointer in bytes from beginning of file after the seek
 * or -1 if an error occurs.
 * The read-data thread should be paused or stopped during this operation.
 */

extern int DSPMKIncrementReadDataBytePointer(int offset);
/*
 * Move read-data file pointer to given offset from current location in bytes.
 * Returns file pointer in bytes from beginning of file after the seek
 * or -1 if an error occurs.
 * The read-data thread should be paused or stopped during this operation.
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


port_t DSPGetSoundPort(void);
/* 
 * Get sound device port.
 */


port_t DSPMKGetWriteDataStreamPort(void);
/* 
 * Get stream port used to receive "DSP write data" buffers from the DSP.
 */


port_t DSPMKGetSoundOutStreamPort(void);
/* 
 * Get stream port used to convey "sound out" buffers from the DSP
 * to the stereo DAC.
 */

port_t DSPMKGetWriteDataReplyPort(void);
/* 
 * Get reply port used to receive status information on "DSP write data" 
 * buffers transfers from the DSP.
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

extern int DSPCloseCommandsFile(DSPFix48 *endTimeStamp);
/*
 * Closes a "DSP Commands file".  The endTimeStamp is used by the
 * sound library to terminate the DSP-sound playback thread.
 */

/******************************* DSP Driver Protocol *******************************/

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
 * Set or clear the bit "SNDDRIVER_DSP_PROTO_C_DMA" in the DSP driver protocol.
 * For DMA transfers carried out by libdsp, this protocol bit is automatically
 * set before and cleared after the transfer.  If you use 
 * snddriver_dsp_dma_{read,write}() to carry out DMA transfers between the
 * DSP and main memory, you must set the C_DMA protocol bit yourself.
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
 * See /usr/local/lib/dsp/monitor/apmon_8k.lod and mkmon_A_8k.lod for example 
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
