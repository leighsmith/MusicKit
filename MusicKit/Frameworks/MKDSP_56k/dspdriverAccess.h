#ifndef __MK_dspdriverAccess_H___
#define __MK_dspdriverAccess_H___
/*
  dspdriverAccess.h.
  David Jaffe, CCRMA, Stanford University.
  Feb. 1994

  This module is private with respect to the Music Kit and libdsp.
  However it may be exported so other systems can access the driver
  functionality directly.
*/
typedef unsigned int dsp_id;

/************  Set-up functions ****************************/

/* To use a DSP, you must first "add" it, then "open" it, then "reset" it. 
 */
extern int dsp_addDsp(dsp_id dspId,const char *driver,int unit,int subUnit);
/* dspId must not have been added yet. */

extern int dsp_open(dsp_id dspId);  
extern int dsp_close(dsp_id dspId); 
extern int dsp_reset(dsp_id dspId,char on);

extern void 
  setDSPDriverErrorProc(void (*errFunc)(dsp_id dspId,
					char *caller,
					char *errorMessage,
					int errorCode));
/* Use this to register an error function.  Otherwise, errors are
 * printed to stderr.  Note that stderr is not thread-safe.
 * Hence if you access the dspdriver in other than the main
 * thread, you should probably register your own error handler.
 */

/* Simple low level functions *************************/
extern char dsp_getICR(dsp_id dspId);
extern char dsp_getCVR(dsp_id dspId);
extern char dsp_getISR(dsp_id dspId);
extern char dsp_getIVR(dsp_id dspId);

extern void dsp_putICR(dsp_id dspId, char b);
extern void dsp_putCVR(dsp_id dspId, char b);
extern void dsp_putIVR(dsp_id dspId, char b);

extern void dsp_putTXRaw(dsp_id dspId,char high,char med,char low);
extern void dsp_getRXRaw(dsp_id dspId,char *high,char *med,char *low);

extern int dsp_getHI(dsp_id dspId); /* Returns: ICR|CVR|ISR|IVR packed */

/**************** Word I/O with checking of ISR bits ******/
extern void dsp_putTX(dsp_id dspId,char high,char med,char low);
/* Like dsp_putTXRaw, but waits for TXDE to be set. */

extern void dsp_getRX(dsp_id dspId,char *high,char *med,char *low);
/* Like dsp_getRXRaw but waits for ISR&1 (RXDF) to be set. */


/**************** Array (TX/RX) I/O with checking of ISR bits ******/
extern void dsp_putArray(dsp_id dspId,int *arr,unsigned int count);
/* Like dsp_putTX, but puts a whole array of 24-bit numbers, right-justified   
   in 32-bits
   */

extern void dsp_getArray(dsp_id dspId,int *arr,unsigned int count);
/* Like dsp_getRX but gets a whole array.
   arr must point to at least count elements 
   */

extern void dsp_putShortArray(dsp_id dspId,short *arr,unsigned int count);
/* Like dsp_putTX but puts a whole array of 16-bit numbers.  These numbers
   are sign extended into TXH */

extern void dsp_putLeftArray(dsp_id dspId,int *arr,unsigned int count);
/* Like dsp_putTX but puts a whole array of 24-bit numbers, left-justified
   in 32-bits
   */

extern void dsp_putByteArray(dsp_id dspId,char *arr,unsigned int count);
/* Like dsp_putTX but puts a whole array of bytes.  These numbers are
   sign extended into TXH and TXM 
   */

extern void dsp_putPackedArray(dsp_id dspId,char *arr,unsigned int count);
/* Like dsp_putTX but puts a whole array of 24-bit packed numbers.  
   Note that count is the number of 24-bit numbers, not the number of bytes.
   */

#define DSPDRIVER_DEBUG_UNEXPECTED 1
#define DSPDRIVER_DEBUG_DEBUG      2
#define DSPDRIVER_DEBUG_TRACE      4
#define DSPDRIVER_DEBUG_VERBOSE    8

extern int dsp_debug(char *driverName,int flags);
/* Sets debugging flags for all units.  This may be done even if you're
 * not the owner of the driver (so another process can set/clear debug flags)
 * Returns 0 if successful, -1 if bad driverName, -2 if can't set flags.
 */

/******************* Special Music Kit functions. *************/
extern void dsp_executeMKTimedMessage(dsp_id dspId,int highWord,int lowWord,
				      int opCode);
    /* Special Music Kit function for finishing a timed message */

extern void dsp_executeMKHostMessage(dsp_id dspId);
    /* Special Music Kit function for executing a Host Message, which
     * is assumed already written to the HMS. (obsolete)
     */

extern void dsp_call(dsp_id dspId,int *arr,unsigned int count); 
    /* Special Music Kit function for writing a host message to the HMS 
     * and executing it.
     */


#import <mach/mach_types.h>

/******************* Special functions for DSP-initiated transfer protocol ***/

extern void dsp_setMessaging(dsp_id dspId, boolean_t flag);
    /* Turns DSP messaging (i.e. "DSP-initiated DMA") on or off.
     * Messaging should be turned on once the DSP has been booted
     * and code loaded, using the functions above.  Reseting the
     * DSP always turns off messaging.  Once messaging is on, you
     * can use the following functions to send or receive data
     * efficiently.  Note, however, that if you are using a DSP-initiated
     * communication path, you should do no other simultaneous communication
     * in that direction. 
     */

extern void dsp_putPage(dsp_id dspId, vm_address_t pageAddress,
			int regionTag, boolean_t msgStarted,
			boolean_t msgCompleted, mach_port_t reply_port);
    /* Puts a page of ints (actually 2048 DSPFix24s), located at
     * the vm allocated by the user at pageAddress, to the DSP.
     * A mach message is returned to the reply_port if the caller
     * sets the write started or completed flag.  This function
     * partially replaces the functionality of the
     * snddriver_start_writing function found on black hardware.
     * This function does not rely on messaging (i.e. interrupts)
     * used in the following three functions, so it can be used
     * like the other "put" functions above.  However, this function
     * is somewhat more efficient since the data is mapped, not copied,
     * using out-of-line mach messaging.
     * 
     * This function is not used by the Music Kit.  It is included
     * for compatibility with snddriver protocol.
     */

extern void dsp_queuePage(dsp_id dspId, vm_address_t pageAddress,
			  int regionTag, boolean_t msgStarted,
			  boolean_t msgCompleted, mach_port_t reply_port);
    /* Queues a page of 2048 DSPFix24s to the driver.  This queue is
     * a circular buffer which can hold up to 16 pages, so be sure the
     * DSP starts reading data before the queue overfills.  The DSP
     * reads data from the queue using the "DMA stream" protocol found
     * on black hardware (i.e. the DSP initiates the transfer by sending
     * a $040002 to the host, and then follows the handshaking sequence).
     * A mach message is returned to the reply_port if the msgStarted or
     * msgCompleted flags are set.  This function provides a minimal
     * emulation of the snddriver_start_writing function found on black
     * hardware.  It is efficient since the data is mapped, not copied,
     * using out-of-line mach messaging, and the data is sent to the DSP
     * when the DSP messages (interrupts) the host.
     *
     * This function is not used by the Music Kit.  It is included
     * for compatibility with snddriver protocol.
     */

#define DSPDRIVER_MAX_TRANSFER_CHAN             18

extern void dsp_setShortBigEndianReturn(dsp_id dspId, int regionTag,
					int wordCount, mach_port_t reply_port, 
					int chan);
    /* Sets the reply_port, region tag, and buffer size for returning
     * 16 bit sample data to the host.  The wordCount is the buffer size
     * used by the DSP for one transfer to the host.  The host must
     * use msg_receive to get this data, and must deallocate the vm
     * sent in the out-of-line message.  (The user should implement
     * a function that emulates snddriver_reply_handler(), to read the
     * reply messages the driver now generates in this, and the above,
     * function).  The DSP sends data to the host using the "DMA stream"
     * protocol on found on black hardware (i.e. the DSP initiates the
     * transfer by sending a $050000|chan to the host, and then follows the
     * established handshaking sequence).  This function provides
     * a minimal emulation of the snddriver_start_reading function on
     * black hardware.  It is efficient since data is mapped in out-of-line
     * mach messages, and the data is sent immediately when the DSP
     * interrupts (i.e. messages) the host.  Note that the host takes the
     * lower two bytes of data transferred, and swaps them, so that the
     * returned region contains big-endian short (16 bit) ints.
     *
     * Note that channel 1 is special: It is buffered, whereas all
     * other channels are unbuffered.  Channel 1 requests must be
     * a power of 2. 
     * All requests must be less than MSG_SIZE_MAX/sizeof(short).
     * Channel is between 0 and DSPDRIVER_MAX_TRANSFER_CHAN
     */

extern void dsp_setShortReturn(dsp_id dspId, int regionTag,
			       int wordCount, mach_port_t reply_port, 
			       int chan);
     /* Like dsp_setShortBigEndianReturn(), but little-endian.  */


extern void dsp_setLongReturn(dsp_id dspId, int regionTag,
			      int wordCount, mach_port_t reply_port, 
				int chan);
     /* Like dsp_setShortReturn(), but for 24-bit numbers, 
      * right justified in 32 bits. 
      * All requests must be less than MSG_SIZE_MAX/sizeof(long).
      * Channel is between 0 and DSPDRIVER_MAX_TRANSFER_CHAN
      */

extern void dsp_freePage(dsp_id dspId, int pageIndex);
/* 
 * May be called in a separate thread. Use instead of vm_deallocate() to
 * free memory returned by above functions.  pageIndex is a field
 * in the message.
 */

extern void dsp_setMsgPort(dsp_id dspId, mach_port_t replyPort);
/* Set port to receive asynchronous DSP messages */

extern void dsp_setErrorPort(dsp_id dspId, mach_port_t replyPort);
/* Set port to receive asynchronous DSP errors */

/*** The following are for decoding messages returned via reply ports ***/

/* Reply mach message IDs. */
#define DSPDRIVER_MSG_WRITE_STARTED            1    
#define DSPDRIVER_MSG_WRITE_COMPLETED          2    
#define DSPDRIVER_MSG_READ_SHORT_COMPLETED     3    
#define DSPDRIVER_MSG_READ_LONG_COMPLETED      4    
#define DSPDRIVER_MSG_READ_BIG_ENDIAN_SHORT_COMPLETED  300 
                                        /* Must match SND_MSG_RECORDED_DATA */
#define DSPDRIVER_MSG_RET_DSP_ERR  315  /* Must match SND_MSG_RET_DSP_ERR */
#define DSPDRIVER_MSG_RET_DSP_MSG  316  /* Must match SND_MSG_RET_DSP_MSG */

/* Mach message typedefs */
typedef struct {
    vm_address_t pagePtr;
    int regionTag;
    boolean_t msgStarted;
    boolean_t msgCompleted;
    mach_port_t replyPort;
} DSPDRIVEROutputQueueMessage;

typedef struct {
    mach_msg_header_t  h;
    msg_type_t    t;
    int           regionTag; /* Also used for dsperror and dspmsg codes */
} DSPDRIVERSimpleMessage;

typedef struct {
    mach_msg_header_t  h;
    msg_type_t    t1;
    int           regionTag;
    int           nbytes;
    int           pageIndex;
    int           chan;
    msg_type_t    t2;
    void          *data;  /* Either short * or int * */
} DSPDRIVERDataMessage;

/* 
 * The following must be kept in synch with DSPObject.h.
 * We can't include DSPObject.h here because we're trying to keep this 
 * module independent of libdsp so CLM and others can use it.
 */
#ifndef DSPDRIVER_PAR_MONITOR

/* Parameters of DSPDRIVERs */
#define DSPDRIVER_PAR_MONITOR "Monitor"
#define DSPDRIVER_PAR_MONITOR_4_2 "Monitor_4_2"
#define DSPDRIVER_PAR_SERIALPORTDEVICE "SerialPortDevice"
#define DSPDRIVER_PAR_ORCHESTRA "Orchestra"
#define DSPDRIVER_PAR_WAITSTATES "WaitStates"
#define DSPDRIVER_PAR_SUBUNITS "SubUnits"
#define DSPDRIVER_PAR_CLOCKRATE "ClockRate"
#endif

#endif

