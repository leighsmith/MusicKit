#ifndef __MK_DSPMKDriver_H___
#define __MK_DSPMKDriver_H___
#import <driverkit/i386/directDevice.h>
#import <driverkit/generalFuncs.h>
#import <mach/message.h>
#import "dspdriver_types.h"

#import "dspdriverAccess.h"

/* The following must match dspmsg.asm */
#define NO_MSG                   0x00
#define HOST_R_REQ               0x05  
#define HOST_W_REQ               0x04 
#define HOST_R_DONE              0x03 

#define DSPMK_WD_DSP_CHAN 1 /* Must match libdsp */

/*  LOCAL DEFINES  ***********************************************************/
// #define OUTPUT_QUEUE_SIZE        16                /*  MUST BE A POWER OF 2  */
#define OUTPUT_QUEUE_SIZE        4                /*  MUST BE A POWER OF 2  */
#define OUTPUT_QUEUE_MOD         (OUTPUT_QUEUE_SIZE-1)

#define SENSE_DSPS_AT_BOOT 0   /* Set to 1 to sense DSPs on boot */

#define READ_TYPE_LONG 0
#define READ_TYPE_SHORT 1
#define READ_TYPE_SHORT_BIG_ENDIAN 2

extern int debugFlags;

/* Set to 1 for debugging */
#define DEBUGGING 1

#if DEBUGGING
#warning Debugging enabled
#define UPRINTF if (debugFlags & DSPDRIVER_DEBUG_UNEXPECTED) IOLog
#define DPRINTF if (debugFlags & DSPDRIVER_DEBUG_DEBUG) IOLog
#define TPRINTF if (debugFlags & DSPDRIVER_DEBUG_TRACE) IOLog
#define VPRINTF if (debugFlags & DSPDRIVER_DEBUG_VERBOSE) IOLog
#else
static void inline DPRINTF(){}
static void inline UPRINTF(){}
static void inline TPRINTF(){}
static void inline VPRINTF(){}
#endif 

/* An attempt at avoiding running out of vmem--we manage our own pool. */

typedef struct {
  vm_address_t pagePtr;
  BOOL inUse;
} DSPDRIVERAvailPage;

@interface DSPMKDriver : IODirectDevice
{
    int baseIO;           
    port_t owner;         /* Owner port */
    int maxDSPCount;      /* Same as [[self class] maxDSPCount] */
    int subUnit;          /* Currently-selected physical subUnit (DSP)    */
    int shadowedIOThreadSubUnit;  /* Used to synchronize IO and LKS thread accesses */
    int shadowedLKSThreadSubUnit; /* Used to synchronize IO and LKS thread accesses */
    int actualDSPCount;   /* Number of DSPs actually present (LEQ maxDSPCount) */
    int *subUnitMap;      /* Maps virtual-to-physical DSPs. Size is actualDSPCount */
    int useInterrupts;    /* True if we're using interrupts */
    unsigned int irq;     /* The interrupt, if any */
    unsigned messagingOn; /* Vector of flags of the form (1<<physicalSubUnit) */
    int *messagingDSPs;   /* List of messaging DSPs (physicalSubUnits) */
    int messagingDSPsCount; /* Number of messaging DSPs */
    /* The following three instance vars are for pseudo-DMA *to* DSP 
     * (not supported by Music Kit and not supported for multiple subUnits) 
     */
    DSPDRIVEROutputQueueMessage outputQueue[OUTPUT_QUEUE_SIZE];
    int outputHead;
    int outputTail;
    /* The following 2D arrays are for dsp-initiated transfers *from* DSP.
     * They are all arrays indexed by physical subUnit and "DMA" transfer channel.
     * We assume that a channel is unique only to a particular subUnits.
     */
    int **dspReadRegionTag; 
    short **dspReadWordCount;
    char **dspReadType;
    /* The following 1D array is indexed by physical subUnit.  It gives the
     * port for all readbacks, except the special "DMA" channel 1.
     */
    port_t *dspReadReplyPort;
    /* The following arrays are to buffer the special "DMA" channel 1 (write data).
     * Since there can only be one of these per subUnit, the arrays are 1D
     * indexed by physical subUnit. 
     */
    port_t *dspBufferedReadReplyPort;
    short *curBufferedChanCount;
    void **pendingBufferedChanData; /* Array of pointers to vm_allocated buffers */
    char *bufferedChanState;  
    /* The following arrays are for DSP errors and messages.  Indexed by
     * physical subUnit. 
     */
    port_t *msgPort;
    port_t *errPort;
    /* For polling the DSP */
    IOThread pollingThread;
    BOOL pollThreadRunning;
    /* An attempt at optimizing the polling */
    int pendingReadRequests; 
    int pendingBufferedReadRequests; 
    /* An attempt at working around vm_allocate/vm_deallocate bug */
    DSPDRIVERAvailPage *availPages;
    int prevPageAlloc;
    short *pendingBufferedChanPageIndex;
    int availPageCount;
    int configurationPort; /* Used by plug n play drivers */
}

+ (BOOL)probe: deviceDescription;
- initFromDeviceDescription: deviceDescription;
- setVirtualSubUnit:(int)aUnit;
- resetAllDSPs;
- (int) resetSleepTime;

- (void)setMessagingOn:(BOOL)flag;
- (void)initOutputQueue;
- (void)resetOutputQueue;
- (int)outputQueueFull;
- (void)pushOutputQueue:(DSPPagePtr)pageAddress:(int)regionTag:(BOOL)msgStarted
        :(BOOL)msgCompleted:(port_t)replyPort;
- (DSPDRIVEROutputQueueMessage *)popOutputQueue;
- (DSPDRIVEROutputQueueMessage *)pendingOutputMessage;
- (void)setDSPReadRegionTag:(int)regionTag wordCount:(int)wordCount
        replyPort:(port_t)replyPort chan:(int)chan readType:(int)reatType;
- (void)sendPageToDSP;
- (void)getDataFromDSP:(int)chan;
- (void)sendDSPMsg:(unsigned int)msg;
- (void)sendDSPErr:(unsigned int)err;
- (void)setMsgPort:(port_t)replyPort;
- (void)setErrorPort:(port_t)replyPort;
- (void)initAvailPagePool;
- (void)reinitAvailPagePool;
- (void)deallocPage:(int)pageIndex;
@end

#endif

