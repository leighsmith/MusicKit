/*
  dspdriverAccess.c.
  David Jaffe, CCRMA, Stanford University.
  Feb. 1994
*/

#if !m68k && (defined(NeXT) || (defined(__APPLE__) && defined(__MACH__)))

// #import <mach/mach.h>
#import <mach/mach_init.h>
#import <mach/mach_error.h>
#import <mach/mach_interface.h>
#import <servers/netname.h>
#import <stdio.h>
#import <stdlib.h>

// #import "dspdriver.h"
#import "dspdriverAccess.h"

static void (*errorFunction)
    (dsp_id dspId,char *caller,char *errorMessage,int r) = NULL;

#ifndef NO_LIB_DSP 
extern int _DSPVerbose,_DSPTrace;
#define LIBDSP_DEBUGGING (_DSPVerbose||_DSPTrace)
#endif

static int err(dsp_id dspId,char *caller,int r)
{
    return r;
}

void setDSPDriverErrorProc(void (*errFunc)
			   (dsp_id dspId,
			    char *caller,
			    char *errorMessage,
			    int r))
{
    errorFunction = errFunc;
}

static int dspInfoCount = 0;
static int *units;
static int *subUnits;
static mach_port_t *dPorts;
static mach_port_t uPort = PORT_NULL;

#define UNIT units[dspId]
#define DPORT dPorts[dspId]

typedef struct dinfo {
    unsigned long claimedSubUnits;
    int curSubUnit;
} driverInfoStruct;

static driverInfoStruct **driverInfos = NULL; /* Array of pointers */

#define setSubUnit() \
  if (subUnits[dspId] != driverInfos[dspId]->curSubUnit) \
  dsp_set_sub_unit(DPORT,uPort,\
		   driverInfos[dspId]->curSubUnit = subUnits[dspId],UNIT)

#define dspIdCheckErrReturn(_caller) \
  if (dspId >= dspInfoCount) return err(dspId,_caller,DSPDRIVER_ERROR_BAD_ID); else setSubUnit()

#define dspIdCheckVoidReturn(_caller) \
  if (dspId >= dspInfoCount) \
    {  err(dspId,_caller,DSPDRIVER_ERROR_BAD_ID); \
       return;} else setSubUnit()

#define dspIdCheckCharReturn(_caller) \
  if (dspId >= dspInfoCount) \
    {  err(dspId,_caller,DSPDRIVER_ERROR_BAD_ID); \
       return (char)0;} else setSubUnit()

#define NO_SUBUNIT (-1)

int dsp_addDsp(dsp_id dspId,const char *driver,int unit,int subUnit)
{
    return KERN_SUCCESS;
}

int dsp_open(dsp_id dspId)
{
    return KERN_SUCCESS;
}

int dsp_close(dsp_id dspId)
{
    return KERN_SUCCESS;
}

int dsp_reset(dsp_id dspId,char on)
    /* It's assumed that dspId is open */
{
    int r;
    return r;
}

char dsp_getICR(dsp_id dspId) 
{
    char b;
    return b;
}

char dsp_getCVR(dsp_id dspId)
{
    char b;
    return b;
}

char dsp_getISR(dsp_id dspId)
{
    int r;
    char b;
    return b;
}

char dsp_getIVR(dsp_id dspId)
{
    char b;
    int r;
    return b;
}

int dsp_getHI(dsp_id dspId)
{
    int r,v;
    return v;
}

void dsp_putICR(dsp_id dspId,char b)
{
}

void dsp_putCVR(dsp_id dspId,char b)
{
}

void dsp_putIVR(dsp_id dspId,char b)
{
}

void dsp_putTXRaw(dsp_id dspId,char high,char med,char low)
{
}

void dsp_getRXRaw(dsp_id dspId,char *high,char *med,char *low)
{
}

void dsp_putTX(dsp_id dspId,char high,char med,char low)
/* Like putDSPData but waits for ISR&4 (TRDY) to be set. */
{
}

void dsp_getRX(dsp_id dspId,char *high,char *med,char *low)
    /* Like getDSPData but waits for ISR&1 (RXDF) to be set. */
{
}

void dsp_putArray(dsp_id dspId,int *arr,unsigned int count)
    /* Like putDSPData but puts a whole array  */
{
}

void dsp_putShortArray(dsp_id dspId,short *arr,unsigned int count)
    /* Like putDSPDataArray but puts a short array  */
{
}

void dsp_putLeftArray(dsp_id dspId,int *arr,unsigned int count)
    /* Like putDSPDataArray but puts a left-justified array  */
{
}

void dsp_putByteArray(dsp_id dspId,char *arr,unsigned int count)
    /* Like putDSPDataArray but puts a byte array  */
{
}

void dsp_putPackedArray(dsp_id dspId,char *arr,unsigned int count)
    /* Like putDSPDataArray but puts a packed array  */
{
}

void dsp_getArray(dsp_id dspId,int *arr,unsigned int count)
    /* Like getDSPData but gets a whole array  */
{
}

void dsp_executeMKTimedMessage(dsp_id dspId,int highWord,int lowWord,
			       int opCode)
    /* Special Music Kit function for finishing a timed message */
{
}

void dsp_call(dsp_id dspId,int *arr,unsigned int count)
    /* Puts an array and then executes DSP_HC_XHM */
{
}

/* The following function is obsolete */
void dsp_executeMKHostMessage(dsp_id dspId)
    /* Special Music Kit function for finishing a timed message */
{
}

// added by Leonard Manzara
void dsp_putPage(dsp_id dspId, vm_address_t pageAddress, int regionTag,
		 boolean_t msgStarted, boolean_t msgCompleted,
		 mach_port_t reply_port)
{
}

void dsp_setMessaging(dsp_id dspId, boolean_t flag)
{
}

void dsp_queuePage(dsp_id dspId, vm_address_t pageAddress,
		   int regionTag, boolean_t msgStarted,
		   boolean_t msgCompleted, mach_port_t reply_port)
{
}

#ifndef NO_LIB_DSP
#define chan1PowerOf2Check(_name,_type) \
  if ((LIBDSP_DEBUGGING) && chan == 1 && notPowerOf2(wordCount,sizeof(_type))) \
  { err(dspId,_name, DSPDRIVER_ERROR_BAD_TRANSFER_REQUEST); return; } else
#else
#define chan1PowerOf2Check(_name,_type) \
  if (chan == 1 && notPowerOf2(wordCount,sizeof(_type))) \
  { err(dspId,_name, DSPDRIVER_ERROR_BAD_TRANSFER_REQUEST); return; } else 
#endif

void dsp_setShortBigEndianReturn(dsp_id dspId, int regionTag,
				 int wordCount, mach_port_t reply_port,int chan)
{
}

void dsp_setShortReturn(dsp_id dspId, int regionTag,
			int wordCount, mach_port_t reply_port,int chan)
{
}

void dsp_setLongReturn(dsp_id dspId, int regionTag,
		       int wordCount, mach_port_t reply_port,int chan)
{
}

void dsp_setMsgPort(dsp_id dspId, mach_port_t replyPort)
{
}

void dsp_setErrorPort(dsp_id dspId, mach_port_t replyPort)
{
}

void dsp_freePage(dsp_id dspId, int pageIndex)
{
}

int dsp_debug(char *driverName,int flags)
{
  return 0;
}

#endif
