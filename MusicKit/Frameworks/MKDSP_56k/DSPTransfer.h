#ifndef __MK_DSPTransfer_H___
#define __MK_DSPTransfer_H___
/* $Id$
 * Functions in libdsp_s.a having to do with data transfer.
 * Copyright 1988-1992, NeXT Inc.  All rights reserved.
 * Author: Julius O. Smith III
 */

#if 0

 TERMINOLOGY

    A "load" is an immediate transfer of a DSPLoadSpec struct into DSP memory.
    A load can occur any time after DSPBoot() or DSP{AP,MK,}Init().

    A "write" is an immediate transfer into DSP memory,
    normally used to download user data to the DSP.

    A "read" is the inverse of a "write".   The transfer is immediate,
    without regard for DSP time, if any. 

    A "get" is the same as a "read", except that the return value of the
    function contains the desired datum rather than an error code.

    A "vector" is a contiguous array of words.  A one-dimensional 
    (singly subscripted) C array is an example of a vector.

    An "array" is a not-necessarily-contiguous sequence of words.
    An array is specified by a vector plus a "skip factor".

    A "skip factor" is the number of array elements to advance in an 
    array transfer.  An array with a skip factor of 1 is equivalent to
    a vector.  A skip factor of 2 means take every other element when
    reading from the DSP and write every other element when writing to
    the DSP.  A skip factor of 3 means skip 2 elements between each
    read or write, and so on.

    ----------------------------------------------------------------------

    The following terms pertain primarily to the Music Kit DSP monitor:

    A "send" is a timed transfer into DSP memory.  Functions which do
    "sends" have prefix "DSPMKSend..." or have the form "DSPMK...Timed()".

    A "ret{rieve}" is the inverse of a "send".	

    A "tick" is DSPMK_I_NTICK samples of digital audio produced by one
    iteration of the "orchestra loop" in the DSP.

    An "immediate send" is a send in which the time stamp is 0.	 The global
    variable DSPTimeStamp0 exists for specifying a zero time stamp.  It 
    results in a tick-synchronized write, i.e., occurring at end of
    current tick in the DSP.

    An orchestra must be running on the chip to do either type of send.	 
    Time-stamped DSP directives are always used in the context of the
    Music Kit orchestra.

    If the time stamp pointer is null (DSPMK_UNTIMED), then a send reduces 
    to a write.

    A "BLT" (BLock Transfer) is a move within DSP memory.
    A "BLTB" is a Backwards move within DSP memory.

    A "fill" specifies one value to use in filling DSP memory.

#endif


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

extern int DSPReadDataAndToss(int n);
/*
 * Read n ints from the  RX register of the DSP host interface
 * and toss them into the bit bucket.  Faster than a real read
 * for pulling words out of the DSP.
 */

extern int DSPReadDataArrayMode(void *data, int nwords, int mode);
/*
 * Read nwords words from DSP Receive Byte Registers (RX) in "DMA mode" mode.
 * The mode is DSP_MODE<n> where <n> = 8,16,24,32, (using the defines in 
 * <sound/sounddriver.h>) and the modes are described under the function
 * DSPReadArraySkipMode().
 * RXDF must be true for each word before it is read.  
 * Note that it is an "error" for RXDF not to come true.  
 * Call DSPAwaitData(msTimeLimit) before calling
 * DSPReadRX() in order to await RXDF indefinitely.  
 * The default time-out used here may change in the future, and it is 
 * currently infinity.
 * This function is for simple non-DMA data reads from the DSP.
 * The only protocol used with the DSP is that HF1 is set during the read.
 */


extern int DSPReadMessageArrayMode(void *data, int nwords, int mode);
/*
 * Like DSPReadDataArrayMode() except for DSP messages.
 * Only useable in "host message protocol" mode.
 * Return value is 0 for success, nonzero if an element could not be read
 * after trying for DSPDefaultTimeLimit seconds.
 * If the read could not finish, the number of elements successfully 
 * read + 1 is returned.
 * The mode specifies the data mode as in DSPReadDataArrayMode().
 */


extern int DSPReadRXArrayMode(void *data, int nwords, int mode);
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

/* For DMA array transfers to/from DSP */

extern int DSPWriteArraySkipMode(
    void *data,			/* array to send to DSP (any type ok) */
    DSPMemorySpace memorySpace, /* /LocalDeveloper/Headers/dsp/dsp_structs.h */
    int startAddress,		/* within DSP memory */
    int skipFactor,		/* 1 means normal contiguous transfer */
    int wordCount,		/* from DSP perspective */
    int mode);			/* from <nextdev/dspvar.h> */
/* 
 * Send an array of words to the DSP.
 * The mode is one of (cf. dspvar.h):
 *
 *	DSP_MODE8
 *	DSP_MODE16
 *	DSP_MODE24
 *	DSP_MODE32
 *
 * Mode DSP_MODE8 maps successive bytes from the source byte array to 
 * successive words in the DSP.	 Each byte is right justified in the 
 * 24-bit DSP word.  The upper two bytes of each DSP word will contain
 * whatever was last written to the TXH and TXM registers in the DSP
 * host interface.  Therefore, if you want leading zeros, for example,
 * you could write the first byte using DSPWriteValue(value,space,addr).
 *
 * Mode DSP_MODE16 maps successive byte pairs from the source byte array to 
 * successive words in the DSP.	 Each 16-bit word from the source is right 
 * justified in the 24-bit DSP word. The upper byte of each DSP word 
 * will contain whatever was last written to the TXH register 
 * in the DSP host interface.
 *
 * Mode DSP_MODE24 maps successive byte trios from the source byte array to 
 * successive words in the DSP.	 Each 24-bit word from the source occupies
 * a full 24-bit DSP word.
 *
 * Mode DSP_MODE32 maps the least significant three bytes from each four-byte
 * word in the source array to successive words in the DSP.  Each 32-bit word 
 * from the source specifies a full 24-bit DSP word.
 *
 * The skip factor specifies the increment for the DSP address register
 * used in the DMA transfer.  A skip factor of 1 means write successive
 * words contiguously in DSP memory.  A skip factor of 2 means skip every
 * other DSP memory word, etc.
 *
 * A DMA transfer is performed if it will be sufficiently large.
 * DMA transfers must be quad aligned (16-bytes = 1 quad) and a multiple of 16 bytes
 * in length.   A DMA cannot cross a page boundary (currently 8192 bytes).
 * This routine will break up your array into 
 * separate transfers, if necessary.  For best performance, use arrays
 * that begin on a page boundary (e.g. "mem = malloc(byteCount+vm_page_size);
 * array = mem & (~(vm_page_size-1));").  
 *
 * This routing calls snddriver_dsp_dma_write() to carry out the DMA transfers.
 * You can save a little overhead by using vm_allocate() to prepare your data
 * buffer and calling snddriver_dsp_dma_write() directly.  In that case, you
 * will need to set and clear the "complex DMA" protocol bit yourself (see 
 * DSPSetComplexDMAModeBit(int bit)), and you will have to prepare the DSP
 * for the transfer yourself.  (The Music Kit and array processing monitors
 * support a transfer-preparation call that libdsp uses.  The snddriver functions
 * assume a minimum of DSP-side protocol, so transfer preparation is up to the
 * DSP programmer.)  Note that vm_allocate() always allocates a multiple of whole
 * virtual-memory pages, and the starting address is always page aligned.
 * Such buffers are most effficient for DMA transfer.  If you pass such a buffer
 * to libdsp, it will look over it quite a bit, but otherwise realize the benefits.
 */


extern int DSPReadNewArraySkipMode(
    void **data,		/* array to fill from DSP */
    DSPMemorySpace memorySpace, /* /LocalDeveloper/Headers/dsp/dsp_structs.h */
    int startAddress,		/* within DSP memory */
    int skipFactor,		/* 1 means normal contiguous transfer */
    int wordCount,		/* from DSP perspective */
    int mode);			/* from <nextdev/dspvar.h> */
/* 
 * Receive an array of bytes from the DSP.
 * Operation is analogous to that of DSPWriteArraySkipMode()
 * except that the array is allocated by the function.  Its size
 * will be the number of bytes returned rounded up to the next
 * multiple of 32.  It should be freed using vm_deallocate().
 *
 * Note: In order to relieve pressure on the host side,
 * the DSP blocks from the time the host is interrupted
 * to say that reading can begin and the time the host tells
 * the DSP that the host interface has been initialized in DMA
 * mode.  Therefore, this routine should not be used to read DSP
 * memory while an orchestra is running.
 */


extern int DSPReadArraySkipMode(
    void *data,			/* array to fill from DSP */
    DSPMemorySpace memorySpace,
    int startAddress,		/* within DSP memory */
    int skipFactor,		/* 1 means normal contiguous transfer */
    int wordCount,		/* from DSP perspective */
    int mode);			/* DMA mode from <nextdev/dspvar.h> */
/* 
 * Same as DSPReadNewArraySkipMode() except that data from the
 * DSP is copied into the data array provided in the argument.
 */

/****************************************************************************/

extern int DSPWriteValue(int value, DSPMemorySpace space, int addr);
/*
 * Write the low-order 24 bits of value to space:addr in DSP memory.
 * The space argument is one of
 * (cf. "/LocalDeveloper/Headers/dsp/dsp_structs.h"):
 *	DSP_MS_X
 *	DSP_MS_Y
 *	DSP_MS_P
 */


extern int DSPWriteLong(DSPFix48 *aFix48Val, int addr);
/* 
 * Write a DSP double-precision value to l:addr in DSP memory.
 * Equivalent to two calls to DSPWriteValue() for the high-order
 * and low-order words.
 */


extern int DSPWriteFix24Array(
    DSPFix24 *data,		/* array to write to DSP */
    DSPMemorySpace memorySpace,
    DSPAddress startAddress,	/* within DSP memory */
    int skipFactor,		/* 1 means normal contiguous transfer */
    int wordCount);		/* from DSP perspective */

/* 
 * Write an array of 24-bit words, right-justified in 32 bits, to the DSP, 
 * writing three bytes to each successive DSP word.  Uses 32-bit DMA mode.
 * The rightmost (least-significant) three bytes of each 32-bit source
 * word go to the corresponding DSP word.  The most significant byte of
 * each source word is ignored.
 *
 * The skip factor specifies the increment for the DSP address register
 * used in the DMA transfer.  A skip factor of 1 means write successive
 * words contiguously in DSP memory.  A skip factor of 2 means skip every
 * other DSP memory word, etc.
 *
 * The write is done using 32-bit DMA mode if wordCount is
 * DSP_MIN_DMA_WRITE_SIZE or greater, programmed I/O otherwise.  Note 
 * that the DMA transfer is inherently left-justified, while programmed I/O 
 * is inherently right justified.  For large array transfers, it is more
 * efficient to work with left-justified data, as provided by
 * DSPWriteFix24ArrayLJ().
 *
 * This function is also used to transfer unpacked byte arrays or 
 * unpacked sound arrays to the DSP.  In these cases the data words
 * are right-justified in the 32-bit words of the source array.
 *
 * The memorySpace is one of (see dsp_structs.h):
 *	DSP_MS_X
 *	DSP_MS_Y
 *	DSP_MS_P
 */


extern int DSPWriteFix24ArrayLJ(
    DSPFix24 *data,		/* array to write to DSP */
    DSPMemorySpace memorySpace,
    DSPAddress startAddress,	/* within DSP memory */
    int skipFactor,		/* 1 means normal contiguous transfer */
    int wordCount);		/* from DSP perspective */
/*
 * Same as DSPWriteFix24Array except that the data array is assumed to be 
 * left-justified in 32 bits.
 */


extern int DSPWriteIntArray(
    int *intArray,
    DSPMemorySpace memorySpace,
    DSPAddress startAddress,
    int skipFactor,
    int wordCount);
/*
 * Same as DSPWriteFix24Array.  The low-order 24 bits of each int are
 * transferred into each DSP word.
 */


extern int DSPWritePackedArray(
    unsigned char *data,	/* Data to write to DSP */
    DSPMemorySpace memorySpace, /* DSP memory space */
    DSPAddress startAddress,	/* DSP start address */
    int skipFactor,		/* DSP index increment per DSP word written */
    int wordCount);		/* DSP words = byte count / 3 */

/* 
 * Write a byte array to the DSP, writing three bytes to
 * each successive DSP word.  Uses 24-bit DMA mode.
 * This is the most compact form of transfer to the DSP.
 */


extern int DSPEnableDmaReadWrite(int enable_dma_reads, int enable_dma_writes);
/*
 * Enable or disable use of DMA in 16-bit and 8-bit mode transfers.
 * The default is disabled.  To enable DMA in both directions, say
 *
 * 	DSPEnableDmaReadWrite(1,1);
 *
 * DMA is disabled by default because it cannot currently be mixed with
 * programmed transfers.  Attempting to do so may cause a driver panic.
 */


extern int DSPWriteShortArray(
    short int *data,		/* Packed short data to write to DSP */
    DSPMemorySpace memorySpace, /* DSP memory space */
    DSPAddress startAddress,	/* DSP start address */
    int skipFactor,		/* DSP index increment per short written */
    int wordCount);		/* DSP word count = byte count / 2 */

/* 
 * Write a packed array of 16-bit words to the DSP (typically sound data).
 * Uses 16-bit DMA mode if possible and if enabled.  Each 32-bit word in the
 * source array provides two successive 16-bit samples in the DSP.
 * In the DSP, each 16-bit word is received right-justified in 24 bits,
 * with no sign extension.  For best results, the data array should be 
 * allocated using vm_allocate() (to obtain page alignment), and the length
 * of the transfer should be a multiple of 4096 bytes (the current DMA buffer
 * size within libdsp).  Otherwise, if the buffer is poorly aligned and of
 * an odd length, the first and last block transfers will be carried out using
 * programmed I/O.  Internally, the function snddriver_dsp_dma_write() is used
 * to perform the DMA transfers.  See the release notes DSPNotes.rtf for more 
 * information about DMA usage.
 */


extern int DSPWriteByteArray(
    unsigned char *data,	/* Data to write to DSP */
    DSPMemorySpace memorySpace, /* DSP memory space */
    DSPAddress startAddress,	/* DSP start address */
    int skipFactor,		/* DSP index increment per byte transferred */
    int byteCount);		/* Total number of bytes to transfer */

/* 
 * Write a packed array of 8-bit words to the DSP (typically microphone data).
 * Uses 8-bit DMA mode if possible and if enabled. Each 32-bit word in the
 * source array provides four successive 8-bit samples to the DSP,
 * right-justified within 24 bits without sign extension.
 * In the DSP, each byte is received right-justified in 24 bits.
 * See DSPWriteShortArray() for alignment and length considerations.
 * See the release notes DSPNotes.rtf for more information about DMA usage.
 */


extern int DSPWriteFloatArray(
    float *floatArray,
    DSPMemorySpace memorySpace,
    DSPAddress startAddress,
    int skipFactor,
    int wordCount);
/*
 * Write a vector of floating-point numbers to a DSP array.
 * Equivalent to DSPFloatToFix24Array() followed by DSPWriteFix24Array().
 */


extern int DSPWriteDoubleArray(
    double *doubleArray,
    DSPMemorySpace memorySpace,
    DSPAddress startAddress,
    int skipFactor,
    int wordCount);
/*
 * Write a vector of double-precision floating-point numbers to a DSP array.
 * Equivalent to DSPDoubleToFix24Array() followed by DSPWriteFix24Array().
 */

extern int DSPWriteSCI(unsigned char value, DSPSCITXReg reg);
/* Write a byte to the specified SCI register.  SCI must already be
 * set up with DSPSetupSerialPort(DSPSerialPortParameters *p).
 */

extern int DSPDataRecordLoad(DSPDataRecord *dr); 
/* 
 * Load data record (as filled from assembler's _DATA record) into DSP.
 * See "/LocalDeveloper/Headers/dsp/dsp_structs.h" for the struct format.
 */


/* Music Kit versions: timed data transfers to DSP */

extern int DSPMKSendValue(int value, DSPMemorySpace space, int addr);
/*
 * Equivalent to DSPWriteValue() except synchronized to a tick boundary
 * (i.e., executed at the top of the orchestra loop).
 * Equivalent to DSPMKSendValueTimed(DSPMKTimeStamp0,value,space,addr).
 */


extern int DSPMKSendValueTimed(DSPFix48 *aTimeStampP,
			       int value,
			       DSPMemorySpace space,
			       int addr);
/*
 * Set a DSP memory location to a particular value at a particular time.
 */


extern int DSPMKSendLong(DSPFix48 *aFix48Val, int addr);
/*
 * etc.
 */


extern int DSPMKSendLongTimed(DSPFix48 *aTimeStampP, 
			      DSPFix48 *aFix48Val,
			      int addr);


extern int DSPMKSendArraySkipModeTimed(
    DSPFix48 *aTimeStampP,
    void *data,			/* Interpretation depends on mode arg */
    DSPMemorySpace space,
    DSPAddress address,
    int skipFactor,
    int count,			/* DSP wordcount */
    int mode);			/* from <nextdev/dspvar.h> */
/*
 * Send an array of data to the DSP at a particular time.
 * The array is broken down into chunks which will fit into the Music Kit
 * DSP monitor's Host Message Stack, and as many timed messages as necessary
 * are sent to transfer the array. 
 *
 * See DSPObject.h, function DSPWriteArraySkipMode() for a description of
 * the various data modes and how they work.
 *
 * When this function is called, timed messages are flushed, and the
 * array transfers are not optimized.  That is, there is no command
 * stream optimization for timed array transfers as there is for
 * other timed host messages.  This means that multiple timed array transfers
 * going out at the same time will be transferred separately rather than being
 * batched.  If the arrays are so small and numerous that this optimization
 * seems warranted, use DSPMKSendValueTimed() instead.
 *
 * This function and its derivatives are intended for timed one-shot transfers
 * such as downloading oscillator wavetables.  DMA is not used, and the entire
 * array is held in the Timed Message Queue within the DSP until the
 * transfer time according to the DSP sample clock arrives.
 * For continuous data transfers into a DSP orchestra, use the "read data"
 * feature in the Music Kit.  The read-data stream can be stopped and
 * started at particular times if desired.
 */


extern int DSPMKSendArraySkipTimed(DSPFix48 *aTimeStampP,
				   DSPFix24 *data,
				   DSPMemorySpace space,
				   DSPAddress address,
				   int skipFactor,
				   int count);
/*
 * Calls DSPMKSendArraySkipModeTimed() with mode == DSP_MODE32.
 */


extern int DSPMKSendArrayTimed(DSPFix48 *aTimeStampP, 
			       DSPFix24 *data,
			       DSPMemorySpace space,
			       DSPAddress address,
			       int count);
/*
 * Calls DSPMKSendArraySkipTimed() with skipFactor equal to 1.
 */


extern int DSPMKSendArray(DSPFix24 *data,
			  DSPMemorySpace space,
			  DSPAddress address,
			  int count);
/*
 * Calls DSPMKSendArrayTimed() with skipFactor == 1 and time stamp == 0.
 */


extern int DSPMKSendShortArraySkipTimed(DSPFix48 *aTimeStampP,
    short int *data,
    DSPMemorySpace space,
    DSPAddress address,
    int skipFactor,
    int count);
/*
 * Calls DSPMKSendArraySkipModeTimed() with mode == DSP_MODE16.
 * Two successive DSP words get left and right 16 bits of each data word.
 * The 16-bit words are received right-justified in each DSP word.
 */


/****************************** DSP MEMORY FILLS *****************************/

/*
 * DSP "memory fills" tell the DSP to rapidly initialize a block of
 * the DSP's private static RAM.
 */

extern int DSPMemoryFill(
    DSPFix24 fillConstant,	/* value to use as DSP memory initializer */
    DSPMemorySpace memorySpace, 
    DSPAddress startAddress,	/* first address within DSP memory to fill */
    int wordCount);		/* number of DSP words to initialize */
/*
 * Set a block of DSP private RAM to the given fillConstant.
 * The memorySpace is one of (see dsp_structs.h):
 *
 *	DSP_MS_X
 *	DSP_MS_Y
 *	DSP_MS_P
 *
 * corresponding to the three memory spaces within the DSP.
 * The wordCount is in DSP words.  The least-significant 24-bits
 * of the fillConstant are copied into wordCount DSP words, beginning
 * with location startAddress.
 */


extern int DSPMKSendMemoryFill(
    DSPFix24 fillConstant,	/* value to fill memory with */
    DSPMemorySpace space,	/* space of memory fill in DSP */
    DSPAddress address,		/* first address of fill in DSP memory	*/
    int count);			/* number of DSP memory words to fill */
/*
 * Fill DSP memory block space:address#count with given fillConstant.
 * Synchronized to tick boundary.
 */


extern int DSPMKMemoryFillTimed(
    DSPFix48 *aTimeStampP,	/* time to do memory fill in the DSP */
    DSPFix24 fillConstant,
    DSPMemorySpace space,
    DSPAddress address,
    int count);
/*
 * Fill DSP memory block space:address#count with given fillConstant
 * at specified time.
 */


extern int DSPMKMemoryFillSkipTimed(
    DSPFix48 *aTimeStampP,
    DSPFix24 fillConstant,
    DSPMemorySpace space,
    DSPAddress address,
    int skip,			/* skip factor in DSP memory */
    int count);
/*
 * Fill DSP memory block space:address+skip*i, i=0 to count-1
 * with given fillConstant at specified time.
 */


extern int DSPMemoryClear(DSPMemorySpace memorySpace,
			  DSPAddress startAddress,
			  int wordCount);
/*
 * Set a block of DSP private RAM to zero.
 * Equivalent to DSPMemoryFill(0,memorySpace,startAddress,wordCount);
 */

extern int DSPMKSendMemoryClear(DSPMemorySpace space,
				DSPAddress address,
				int count);

extern int DSPMKMemoryClearTimed(DSPFix48 *aTimeStampP, 
				 DSPMemorySpace space,
				 DSPAddress address,
				 int count);

/****************************  Poking DSP Symbols ****************************/

extern int DSPPoke(char *name, DSPFix24 value, DSPLoadSpec *dsp);
/*
 * Set the value of the DSP symbol with the given name to value (in the DSP).
 *
 * Equivalent to DSPWriteValue(value,space,address) where space and address
 * are obtained via DSPReadSectionSymbolAddres(&space,&address,name,
 * DSPGetUserSection(dsp));
 */


extern int DSPPokeFloat(char *name, float value, DSPLoadSpec *dsp);
/*
 * Equivalent to DSPPoke(name, DSPFloatToFix24(value), dsp).
 */


/************************** TRANSFERS FROM THE DSP ***************************/

/* 
 * These "from the DSP" routines are analogous to the "to DSP" routines
 * above.  Hence, they are generally not documented when exactly analogous.
 */


extern int DSPMKRetValueTimed(
    DSPTimeStamp *aTimeStampP,
    DSPMemorySpace space,
    DSPAddress address,
    DSPFix24 *value);
/*
 * Send a timed peek.  Since we do not know the current time within the
 * DSP, we wait forever for the returned value from the DSP.  The Music Kit
 * orchestra loop must be running, as is the case for any timed message.
 */


extern int DSPMKRetValue(DSPMemorySpace space, 
			 DSPAddress address, 
			 DSPFix24 *value);
/* 
 * Implemented as DSPMKRetValueTimed(&DSPMKTimeStamp0,space,address,value);
 *
 * A time stamp of zero means "as soon as possible" which is the time of the
 * last message currently waiting in the timed message queue.  Note: this is
 * the result of a bug in time-zero messages.  They are supposed to be
 * processed at the next tick boundary before any timed messages waiting in
 * the queue.  To avoid having zero-timed messages stuck behind messages 
 * timed for the distant future, it is necessary to avoid running far ahead
 * of real time (e.g., using "unclocked mode" in the Music Kit).  In clocked
 * mode, the execution delay should be approximately "delta-T" which is the
 * time the Music Kit runs ahead of the DSP's clock.
 */

extern int DSPReadValue(DSPMemorySpace space,
			DSPAddress address,
			DSPFix24 *value);
/* 
 * Implemented as DSPMKRetValueTimed(DSPMK_UNTIMED,space,address,value);
 *
 * A null time stamp means "instantly" at interrupt level within the DSP.
 * The orchestra loop, if running, will be at an unknown point, and the read
 * is not synchronized to a tick boundary.
 */

/*
 * The following routines cannot be used with the Music Kit because
 * the read mechanism uses the same I/O register in the DSP as does
 * sound-out or write date.
 */

DSPFix24 DSPGetValue(DSPMemorySpace space, DSPAddress address);
/*
 * Get DSP memory datum at space:address.
 *
 * Implemented as 
 * DSPReadArraySkipMode(&datum,space,address,skipFactor,count,DSP_MODE32))
 */

extern int DSPReadFix24Array(
    DSPFix24 *data,		/* array to fill from DSP */
    DSPMemorySpace memorySpace, 
    DSPAddress startAddress,	/* within DSP memory */
    int skipFactor,		/* 1 means normal contiguous transfer */
    int wordCount);		/* from DSP perspective */
/* 
 * Read an array of 24-bit words, right-justified in 32 bits, to the DSP, 
 * reading three bytes to each successive DSP word.
 * The rightmost (least-significant) three bytes of each 32-bit source
 * word go to the corresponding DSP word.  The most significant byte of
 * each source word is ignored.
 *
 * The skip factor specifies the increment for the DSP address register
 * used in the DMA transfer.  A skip factor of 1 means write successive
 * words contiguously in DSP memory.  A skip factor of 2 means skip every
 * other DSP memory word, etc.
 * 
 * The read is done using 32-bit DMA mode if wordCount is
 * DSP_MIN_DMA_READ_SIZE or greater, programmed I/O otherwise.  Note 
 * that DMA transfers are inherently left-justified, while programmed I/O is
 * inherently right justified.  For large array transfers, it is more
 * efficient to work with left-justified data, as provided by
 * DSPReadFix24ArrayLJ().
 * 
 * This function is also used to transfer unpacked byte arrays or 
 * unpacked sound arrays to the DSP.  In these cases the data words
 * are right-justified in the 32-bit words of the source array.
 *
 * The memorySpace is one of (see dsp_structs.h):
 *	DSP_MS_X
 *	DSP_MS_Y
 *	DSP_MS_P
 *
 * Implemented as
 * DSPReadArraySkipMode(data,memorySpace,startAddress,skipFactor,
 *			wordCount,DSP_MODE32);
 */


extern int DSPReadFix24ArrayLJ(
    DSPFix24 *data,		/* array to fill from DSP */
    DSPMemorySpace memorySpace, 
    DSPAddress startAddress,	/* within DSP memory */
    int skipFactor,		/* 1 means normal contiguous transfer */
    int wordCount);		/* from DSP perspective */
/*
 * Same as DSPReadFix24Array() except that data is returned 
 * left-justified in 32 bits.
 *
 * Implemented as
 * DSPReadArraySkipMode(data,memorySpace,startAddress,skipFactor,
 *			wordCount,DSP_MODE32_LEFT_JUSTIFIED);
 */


extern int DSPReadIntArray(int *intArray,
			   DSPMemorySpace memorySpace,
			   DSPAddress startAddress,
			   int skipFactor,
			   int wordCount);
/*
 * Same as DSPReadFix24Array() followed by DSPFix24ToIntArray() for 
 * sign extension.
 */


extern int DSPReadPackedArray(
    unsigned char *data,	/* Data to fill from DSP */
    DSPMemorySpace memorySpace, /* DSP memory space */
    DSPAddress startAddress,	/* DSP start address */
    int skipFactor,		/* DSP index increment per DSP word read */
    int wordCount);		/* DSP words = byte count / 3 */

extern int DSPReadShortArray(
    short int *data,		/* Packed data to fill from DSP */
    DSPMemorySpace memorySpace, /* DSP memory space */
    DSPAddress startAddress,	/* DSP start address */
    int skipFactor,		/* DSP index increment per array element */
    int wordCount);		/* DSP word count = byte count / 2 */

extern int DSPReadByteArray(
    unsigned char *data,	/* Data to fill from DSP */
    DSPMemorySpace memorySpace, /* DSP memory space */
    DSPAddress startAddress,	/* DSP start address */
    int skipFactor,		/* DSP index increment per byte transferred */
    int byteCount);		/* Same as DSP word count */

extern int DSPReadFloatArray(float *floatArray,
			     DSPMemorySpace memorySpace,
			     DSPAddress startAddress,
			     int skipFactor,
			     int wordCount);

extern int DSPReadDoubleArray(double *doubleArray,
			      DSPMemorySpace memorySpace,
			      DSPAddress startAddress,
			      int skipFactor,
			      int wordCount);

/************************** TRANSFERS WITHIN THE DSP *************************/

extern int DSPMKBLT(DSPMemorySpace memorySpace,
		    DSPAddress sourceAddr,
		    DSPAddress destinationAddr,
		    int wordCount);

extern int DSPMKBLTB(DSPMemorySpace memorySpace,
		     DSPAddress sourceAddr,
		     DSPAddress destinationAddr,
		     int wordCount);

extern int DSPMKBLTSkipTimed(DSPFix48 *timeStamp,
			     DSPMemorySpace memorySpace,
			     DSPAddress srcAddr,
			     DSPFix24 srcSkip,
			     DSPAddress dstAddr,
			     DSPFix24 dstSkip,
			     DSPFix24 wordCount);

extern int DSPMKBLTTimed(DSPFix48 *timeStamp,
			 DSPMemorySpace memorySpace,
			 DSPAddress sourceAddr,
			 DSPAddress destinationAddr,
			 DSPFix24 wordCount);

extern int DSPMKBLTBTimed(DSPFix48 *timeStamp,
			  DSPMemorySpace memorySpace,
			  DSPAddress sourceAddr,
			  DSPAddress destinationAddr,
			  DSPFix24 wordCount);

extern int DSPMKSendBLT(DSPMemorySpace memorySpace,
			DSPAddress sourceAddr,
			DSPAddress destinationAddr,
			DSPFix24 wordCount);

extern int DSPMKSendBLTB(DSPMemorySpace memorySpace,
			 DSPAddress sourceAddr,
			 DSPAddress destinationAddr,
			 DSPFix24 wordCount);


/******************** GETTING DSP MEMORY ADDRESSES **************************/

/*
 * The DSP memory addresses are obtained directly from the DSPLoadSpec
 * struct registered by DSPBoot() as the currently loaded DSP system.
 * The memory boundary symbol names must follow the conventions used
 * in the Music Kit and array processing DSP monitors.  
 * /usr/include/dsp/dsp_memory_map_*.h for a description of the name
 * convention, and see /usr/local/lib/dsp/monitor/apmon_8k.lod for an example
 * system file which properly defines the address-boundary symbols.
 *
 * Note that the DSP symbols relied upon below constitute the set of
 * symbols any new DSP monitor should export for compatibility with libdsp.
 *
 * All of these routines return -1 (an impossible address) on error.
 */

extern DSPAddress DSPGetLowestInternalUserXAddress(void);
/* Returns DSPGetSystemSymbolValue("XLI_USR") */

extern DSPAddress DSPGetHighestInternalUserXAddress(void);
/* Returns DSPGetSystemSymbolValue("XHI_USR") */

extern DSPAddress DSPGetLowestInternalUserYAddress(void);
/* Returns DSPGetSystemSymbolValue("YLI_USR") */

extern DSPAddress DSPGetHighestInternalUserYAddress(void);
/* Returns DSPGetSystemSymbolValue("YHI_USR") */

extern DSPAddress DSPGetLowestInternalUserPAddress(void);
/* Returns DSPGetSystemSymbolValue("PLI_USR") */

extern DSPAddress DSPGetHighestInternalUserPAddress(void);
/* Returns DSPGetSystemSymbolValue("PHI_USR") */

extern DSPAddress DSPGetLowestExternalUserXAddress(void);
/* Returns DSPGetSystemSymbolValue("XLE_USR") */

extern DSPAddress DSPGetHighestExternalUserXAddress(void);
/* Returns DSPGetSystemSymbolValue("XHE_USR") */

extern DSPAddress DSPGetLowestExternalUserYAddress(void);
/* Returns DSPGetSystemSymbolValue("YLE_USR") */

extern DSPAddress DSPGetHighestExternalUserYAddress(void);
/* Returns DSPGetSystemSymbolValue("YHE_USR") */

extern DSPAddress DSPGetLowestExternalUserPAddress(void);
/* Returns DSPGetSystemSymbolValue("PLE_USR") */

extern DSPAddress DSPGetHighestExternalUserPAddress(void);
/* Returns DSPGetSystemSymbolValue("PHE_USR") */

extern DSPAddress DSPGetHighestExternalUserAddress(void);
/* Returns DSPGetSystemSymbolValue("HE_USR") */

extern DSPAddress DSPGetLowestExternalUserAddress(void);
/* Returns DSPGetSystemSymbolValue("LE_USR") */

DSPAddress DSPGetLowestXYPartitionUserAddress(void);
/* Returns DSPGetSystemSymbolValue("XLE_USG") */

DSPAddress DSPGetHighestXYPartitionXUserAddress(void);
/* Returns DSPGetSystemSymbolValue("XHE_USG") */

DSPAddress DSPGetHighestXYPartitionYUserAddress(void);
/* Returns DSPGetSystemSymbolValue("YHE_USG") */

DSPAddress DSPGetHighestXYPartitionUserAddress(void);
/* Returns MIN(DSPGetHighestXYPartitionXUserAddress(), 
 *	       DSPGetHighestXYPartitionYUserAddress());
 */

extern DSPAddress DSPGetLowestDegMonAddress(void);
/* Returns DSPGetSystemSymbolValue("DEGMON_L") */

extern DSPAddress DSPGetHighestDegMonAddress(void);
/* Returns DSPGetSystemSymbolValue("DEGMON_H") */

extern DSPAddress DSPMKGetClipCountXAddress(void);
/* 
 * Returns DSPGetSystemSymbolValue("X_NCLIP").  This is the address of the
 * location in DSP X memory used to store a cumulative count of "clips". A
 * "clip" occurs when an oversized value is moved from the DSP ALU to DSP
 * memory.  The clip value is reset to zero when the DSP is rebooted.
 * A standard usage is to do a timed peek on this location at the end of
 * a performance (using DSPMKRetValueTimed()).
 */

#endif
