/*
  dspdriverAccess.c.
  David Jaffe, CCRMA, Stanford University.
  Feb. 1994
*/

#if !m68k && (defined(NeXT) || (defined(__APPLE__) && defined(__MACH__)))
#import "dspdriverUser.c"

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
    char *errorMessage = 
      ((r==DSPDRIVER_ERROR_BUSY) ? 
       "Someone else is using dsp driver." :
       (r==DSPDRIVER_ERROR_NOT_OWNER) ? 
       "You must be the owner of the dsp driver to do this operation." : 
       (r==DSPDRIVER_ERROR_TIMEOUT) ? 
       "dspdriver timed out." : 
       (r==DSPDRIVER_ERROR_BAD_ID) ? 
       "The DSP driver ID is invalid." : 
       (r == DSPDRIVER_ERROR_BAD_UNIT_OR_DRIVER) ?
       "The driver you specified doesn't exist." : 
       (r == DSPDRIVER_ERROR_BAD_TRANSFER_REQUEST) ?  
       "Bad DSP driver transfer request." : 
       (r == DSPDRIVER_ERROR_BAD_TRANSFER_CHAN) ?
       "Bad DSP transfer channel request." : 
       (r == DSPDRIVER_ERROR_UNKNOWN_ERROR) ?
       "Unknown dspdriver error." :
       mach_error_string(r));
    if (errorFunction)
      (*errorFunction)(dspId,caller,errorMessage,r);
    else
#ifndef NO_LIB_DSP
      if (LIBDSP_DEBUGGING)
#endif
	fprintf(stderr,"%s %s\n",caller, errorMessage);
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
static port_t *dPorts;
static port_t uPort = PORT_NULL;

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
    int r,i;
    char *hostName = "";
    if (!driver)
      return err(dspId,"dsp_addDsp",DSPDRIVER_ERROR_BAD_UNIT_OR_DRIVER);
    if (!dspInfoCount) {
	units = (int *)calloc(dspInfoCount = dspId+1,sizeof(int));
	subUnits = (int *)calloc(dspInfoCount,sizeof(int));
	driverInfos = 
	  (driverInfoStruct **)calloc(dspInfoCount,sizeof(driverInfoStruct *));
	dPorts = (port_t *)calloc(dspInfoCount,sizeof(port_t));
    }
    else if (dspInfoCount <= dspId) {
	/* FIXME Should optimize this to avoid N^2 allocation behavior */
	int i;
	units = (int *)realloc(units,sizeof(int) * (dspId+1));
	subUnits = (int *)realloc(subUnits,sizeof(int) * (dspId+1));
	driverInfos = (driverInfoStruct **)realloc(driverInfos,sizeof(driverInfoStruct *) * (dspId+1));
	dPorts = (port_t *)realloc(dPorts,sizeof(port_t) * (dspId+1));
	for (i=dspInfoCount; i<dspId+1; i++) { /* Clear out new entries */
	    dPorts[i] = PORT_NULL;
	}
	dspInfoCount = dspId+1;
    }
    if (DPORT != PORT_NULL)
      return err(dspId,"dsp_addDsp",DSPDRIVER_ERROR_BAD_ID);
    r = netname_look_up(name_server_port, hostName, (char *)driver, &DPORT);
    if (r != KERN_SUCCESS) 
      return err(dspId,"dsp_addDsp can't get dspdriver port",r);
    units[dspId] = unit;
    subUnits[dspId] = subUnit;
    if (uPort == PORT_NULL)
      r = port_allocate(task_self(), &uPort);
    if (r != KERN_SUCCESS) 
      return err(dspId,"dsp_addDsp can't allocate user port.",r);
    driverInfos[dspId] = NULL;
    for (i=0; i<dspId && !driverInfos[dspId]; i++) /* Check all but new one */
      if (DPORT == dPorts[i])   /* Driver shared */
	driverInfos[dspId] = driverInfos[i];
    if (!driverInfos[dspId]) {    /* First subunit for this driver */
	driverInfos[dspId] = 
	  (driverInfoStruct *)calloc(1,sizeof(driverInfoStruct));
	driverInfos[dspId]->curSubUnit = NO_SUBUNIT;
    }
    return KERN_SUCCESS;
}

int dsp_open(dsp_id dspId)
{
    int r;
    unsigned long bits;
    if (dspId >= dspInfoCount) 
      return err(dspId,"dsp_open",DSPDRIVER_ERROR_BAD_ID);
    /* 
     * Can't use dspIdCheckErrReturn here because we don't want
     * to set subunit before becoming owner! 
     */
    bits = driverInfos[dspId]->claimedSubUnits;
    if (!bits) { /* First one? */
	r = dsp_become_owner(DPORT,uPort,UNIT);
	if (r != KERN_SUCCESS) 
	  return err(dspId,"dsp_open can't become owner of driver.",r);
    }
    setSubUnit();
    driverInfos[dspId]->claimedSubUnits |= (1<<subUnits[dspId]);
    return KERN_SUCCESS;
}

int dsp_close(dsp_id dspId)
{
    int r;
    dspIdCheckErrReturn("dsp_close");
    if (!driverInfos[dspId]->claimedSubUnits)
      return KERN_SUCCESS;
    driverInfos[dspId]->claimedSubUnits 
      &= ~((unsigned long)(1<<subUnits[dspId]));
    dsp_setMessaging(dspId,FALSE);
    if (driverInfos[dspId]->claimedSubUnits)
      return KERN_SUCCESS;
    r = dsp_release_ownership(DPORT,uPort,UNIT);
    if (r != KERN_SUCCESS)
      return err(dspId,"dsp_close can't release ownership.",r);
    /* May want to eventually count open DSPs and enable this when
     * closing the last one. 
     */
    driverInfos[dspId]->curSubUnit = NO_SUBUNIT;
    return KERN_SUCCESS;
}

int dsp_reset(dsp_id dspId,char on)
    /* It's assumed that dspId is open */
{
    int r;
    dspIdCheckErrReturn("dsp_reset");
    r = dsp_reset_chip(DPORT,uPort,on,UNIT);
    if (r != KERN_SUCCESS)
      return err(dspId,"dsp_reset",r);
    return r;
}

char dsp_getICR(dsp_id dspId) 
{
    int r;
    char b;
    dspIdCheckCharReturn("dsp_getICR");
    r = dsp_get_icr(DPORT,uPort,&b,UNIT);
    if (r != KERN_SUCCESS)
      err(dspId,"dsp_getICR",r);
    return b;
}

char dsp_getCVR(dsp_id dspId)
{
    int r;
    char b;
    dspIdCheckCharReturn("dsp_getCVR");
    r = dsp_get_cvr(DPORT,uPort,&b,UNIT);
    if (r != KERN_SUCCESS)
      err(dspId,"dsp_getCVR",r);
    return b;
}

char dsp_getISR(dsp_id dspId)
{
    int r;
    char b;
    dspIdCheckCharReturn("dsp_getISR");
    r = dsp_get_isr(DPORT,uPort,&b,UNIT);
    if (r != KERN_SUCCESS)
      err(dspId,"dsp_getISR",r);
    return b;
}

char dsp_getIVR(dsp_id dspId)
{
    char b;
    int r;
    dspIdCheckCharReturn("dsp_getIVR");
    r = dsp_get_ivr(DPORT,uPort,&b,UNIT);
    if (r != KERN_SUCCESS)
      err(dspId,"dsp_getIVR",r);
    return b;
}

int dsp_getHI(dsp_id dspId)
{
    int r,v;
    dspIdCheckCharReturn("dsp_getHI");
    r = dsp_get_hi(DPORT,uPort,&v,UNIT);
    if (r != KERN_SUCCESS)
      err(dspId,"dsp_getHI",r);
    return v;
}

void dsp_putICR(dsp_id dspId,char b)
{
    int r;
    dspIdCheckVoidReturn("dsp_putICR");
    r = dsp_put_icr(DPORT,uPort,b,UNIT);
    if (r != KERN_SUCCESS)
      err(dspId,"dsp_putICR",r);
}

void dsp_putCVR(dsp_id dspId,char b)
{
    int r;
    dspIdCheckVoidReturn("dsp_putCVR");
    r = dsp_put_cvr(DPORT,uPort,b,UNIT);
    if (r != KERN_SUCCESS)
      err(dspId,"dsp_putCVR",r);
}

void dsp_putIVR(dsp_id dspId,char b)
{
    int r;
    dspIdCheckVoidReturn("dsp_putIVR");
    r = dsp_put_ivr(DPORT,uPort,b,UNIT);
    if (r != KERN_SUCCESS)
      err(dspId,"dsp_putIVR",r);
}

void dsp_putTXRaw(dsp_id dspId,char high,char med,char low)
{
    int r;
    dspIdCheckVoidReturn("dsp_putTXRaw");
    r = dsp_put_data_raw(DPORT,uPort,high,med,low,UNIT);
    if (r != KERN_SUCCESS)
      err(dspId,"dsp_putTXRaw",r);
}

void dsp_getRXRaw(dsp_id dspId,char *high,char *med,char *low)
{
    int r;
    dspIdCheckVoidReturn("dsp_putRXRaw");
    r = dsp_get_data_raw(DPORT,uPort,high,med,low,UNIT);
    if (r != KERN_SUCCESS)
      err(dspId,"dsp_getRXRaw",r);
}

void dsp_putTX(dsp_id dspId,char high,char med,char low)
/* Like putDSPData but waits for ISR&4 (TRDY) to be set. */
{
    int r;
    dspIdCheckVoidReturn("dsp_putTX");
    r = dsp_put_data(DPORT,uPort,high,med,low,UNIT);
    if (r != KERN_SUCCESS)
      err(dspId,"dsp_putTX",r);
}

void dsp_getRX(dsp_id dspId,char *high,char *med,char *low)
    /* Like getDSPData but waits for ISR&1 (RXDF) to be set. */
{
    int r;
    dspIdCheckVoidReturn("dsp_putRX");
    r = dsp_get_data(DPORT,uPort,high,med,low,UNIT);
    if (r != KERN_SUCCESS)
      err(dspId,"dsp_getRX",r);
}

void dsp_putArray(dsp_id dspId,int *arr,unsigned int count)
    /* Like putDSPData but puts a whole array  */
{
    int r;
    int c;
    dspIdCheckVoidReturn("dsp_putArray");
    while (count > 0) {
	c = (count > DSP_MAX_WORDS) ? DSP_MAX_WORDS : count;
	r = dsp_put_data_array(DPORT,uPort,arr,c,UNIT);
	arr += c;
	count -= c;
	if (r != KERN_SUCCESS)
	  err(dspId,"dsp_putArray",r);
    }
}

void dsp_putShortArray(dsp_id dspId,short *arr,unsigned int count)
    /* Like putDSPDataArray but puts a short array  */
{
    int r,c;
    dspIdCheckVoidReturn("dsp_putShortArray");
    while (count > 0) {
	c = (count > DSP_MAX_SHORTS) ? DSP_MAX_SHORTS : count;
	r = dsp_put_data_short_array(DPORT,uPort,arr,c,UNIT);
	arr += c;
	count -= c;
	if (r != KERN_SUCCESS)
	  err(dspId,"dsp_putShortArray",r);
    }
}

void dsp_putLeftArray(dsp_id dspId,int *arr,unsigned int count)
    /* Like putDSPDataArray but puts a left-justified array  */
{
    int r,c;
    dspIdCheckVoidReturn("dsp_putLeftArray");
    while (count > 0) {
	c = (count > DSP_MAX_WORDS) ? DSP_MAX_WORDS : count;
	r = dsp_put_data_left_array(DPORT,uPort,arr,c,UNIT);
	arr += c;
	count -= c;
	if (r != KERN_SUCCESS)
	  err(dspId,"dsp_putLeftArray",r);
    }
}

void dsp_putByteArray(dsp_id dspId,char *arr,unsigned int count)
    /* Like putDSPDataArray but puts a byte array  */
{
    int r,c;
    dspIdCheckVoidReturn("dsp_putByteArray");
    while (count > 0) {
	c = (count > DSP_MAX_IN_LINE_BYTES) ? DSP_MAX_IN_LINE_BYTES : count;
	r = dsp_put_data_byte_array(DPORT,uPort,arr,c,UNIT);
	arr += c;
	count -= c;
	if (r != KERN_SUCCESS)
	  err(dspId,"dsp_putByteArray",r);
    }
}

void dsp_putPackedArray(dsp_id dspId,char *arr,unsigned int count)
    /* Like putDSPDataArray but puts a packed array  */
{
    int r,c;
    count *= 3;
    dspIdCheckVoidReturn("dsp_putPackedArray");
    while (count > 0) {
	c = (count > DSP_MAX_PACKED_BYTES) ? DSP_MAX_PACKED_BYTES : count;
	r = dsp_put_data_packed_array(DPORT,uPort,arr,c,UNIT);
	arr += c;
	count -= c;
	if (r != KERN_SUCCESS)
	  err(dspId,"dsp_putPackedArray",r);
    }
}

void dsp_getArray(dsp_id dspId,int *arr,unsigned int count)
    /* Like getDSPData but gets a whole array  */
{
    int r,c,dataCount;
    dspIdCheckVoidReturn("dsp_getArray");
    while (count > 0) {
	dataCount = (c = (count > DSP_MAX_WORDS) ? DSP_MAX_WORDS : count);
	r = dsp_get_data_array(DPORT,uPort,c,arr,&dataCount,
			       UNIT);
	arr += c;
	count -= c;
	if (r != KERN_SUCCESS)
	  err(dspId,"dsp_getArray",r);
    }
}

void dsp_executeMKTimedMessage(dsp_id dspId,int highWord,int lowWord,
			       int opCode)
    /* Special Music Kit function for finishing a timed message */
{
  int r;
  dspIdCheckVoidReturn("dsp_executeMKTimedMessage");
  r = dsp_put_mk_timed_message(DPORT,uPort,highWord,lowWord,
			       opCode,UNIT);
  if (r != KERN_SUCCESS)
    err(dspId,"dsp_executeMKTimedMessage",r);
}

void dsp_call(dsp_id dspId,int *arr,unsigned int count)
    /* Puts an array and then executes DSP_HC_XHM */
{
    int r;
    int c;
    dspIdCheckVoidReturn("dsp_call");
    for (;;) {
	c = (count > DSP_MAX_WORDS) ? DSP_MAX_WORDS : count;
	count -= c;
	if (count > 0) {
	    r = dsp_put_data_array(DPORT,uPort,arr,c,UNIT);
	    if (r != KERN_SUCCESS)
	      err(dspId,"dsp_call",r);
	    arr += c;
	}
	else {
	    r = dsp_put_and_exec_mk_host_message(DPORT,uPort,arr,c,UNIT);
	    if (r != KERN_SUCCESS)
	      err(dspId,"dsp_cal",r);
	    break;
	}
    }
}

/* The following function is obsolete */
void dsp_executeMKHostMessage(dsp_id dspId)
    /* Special Music Kit function for finishing a timed message */
{
  int r;
  dspIdCheckVoidReturn("dsp_executeMKHostMessage");
  r = dsp_exec_mk_host_message(DPORT,uPort,UNIT);
  if (r != KERN_SUCCESS)
    err(dspId,"dsp_executeMKTimedMessage",r);
}

// added by Leonard Manzara
void dsp_putPage(dsp_id dspId, vm_address_t pageAddress, int regionTag,
		 boolean_t msgStarted, boolean_t msgCompleted,
		 port_t reply_port)
{
    int r;
    dspIdCheckVoidReturn("dsp_putPage");
    r = dsp_put_page(DPORT,uPort,(DSPPagePtr)pageAddress,regionTag,
     msgStarted,msgCompleted,reply_port,UNIT);
    if (r != KERN_SUCCESS)
        err(dspId,"dsp_putPage",r);
}

void dsp_setMessaging(dsp_id dspId, boolean_t flag)
{
    int r;
    dspIdCheckVoidReturn("dsp_setMessaging");
    r = dsp_set_messaging(DPORT,uPort,flag,UNIT);
    if (r != KERN_SUCCESS)
      err(dspId,"dsp_setMessaging",r);
    return;
}

void dsp_queuePage(dsp_id dspId, vm_address_t pageAddress,
		   int regionTag, boolean_t msgStarted,
		   boolean_t msgCompleted, port_t reply_port)
{
    int r;
    dspIdCheckVoidReturn("dsp_queuePage");
    r = dsp_queue_page(DPORT,uPort,(DSPPagePtr)pageAddress,regionTag,
		       msgStarted,msgCompleted,reply_port,UNIT);
    if (r != KERN_SUCCESS)
      err(dspId,"dsp_queuePage",r);
}

static int notPowerOf2(int wordCount,int size) {
    /* Channel 1 requests must be a power of 2 less than MSG_SIZE_MAX */
    int i = wordCount * size;
    int j;
    if (i == 32 || i == 64) /* Common cases */
      return 0;
    for (j=MSG_SIZE_MAX; j>0; j>>=1)
      if (j == i)
	return 0;
    return 1;
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
				 int wordCount, port_t reply_port,int chan)
{
    int r;
    dspIdCheckVoidReturn("dsp_setShortBigEndianReturn");
    chan1PowerOf2Check("dsp_setShortBigEndianReturn",short);
    r = dsp_set_short_big_endian_return(DPORT,uPort,regionTag,
					wordCount,reply_port,chan,UNIT);
    if (r != KERN_SUCCESS)
      err(dspId,"dsp_setShortBigEndianReturn",r);
}

void dsp_setShortReturn(dsp_id dspId, int regionTag,
			int wordCount, port_t reply_port,int chan)
{
    int r;
    dspIdCheckVoidReturn("dsp_setShortReturn");
    chan1PowerOf2Check("dsp_setShortReturn",short);
    r = dsp_set_short_return(DPORT,uPort,regionTag,
			     wordCount,reply_port,chan,UNIT);
    if (r != KERN_SUCCESS)
      err(dspId,"dsp_setShortReturn",r);
}

void dsp_setLongReturn(dsp_id dspId, int regionTag,
		       int wordCount, port_t reply_port,int chan)
{
    int r;
    dspIdCheckVoidReturn("dsp_setLongReturn");
    chan1PowerOf2Check("dsp_setLongReturn",int);
    r = dsp_set_long_return(DPORT,uPort,regionTag,
			    wordCount,reply_port,chan,UNIT);
    if (r != KERN_SUCCESS)
      err(dspId,"dsp_setLongReturn",r);
}

void dsp_setMsgPort(dsp_id dspId, port_t replyPort)
{
    int r;
    dspIdCheckVoidReturn("dsp_setMsgPort");
    r = dsp_set_msg_port(DPORT,uPort,replyPort,UNIT);
    if (r != KERN_SUCCESS)
      err(dspId,"dsp_setMsgPort",r);
}

void dsp_setErrorPort(dsp_id dspId, port_t replyPort)
{
    int r;
    dspIdCheckVoidReturn("dsp_setErrorPort");
    r = dsp_set_error_port(DPORT,uPort,replyPort,UNIT);
    if (r != KERN_SUCCESS)
      err(dspId,"dsp_setErrorPort",r);
}

void dsp_freePage(dsp_id dspId, int pageIndex)
{
    int r;
    if (dspId >= dspInfoCount) {
      err(dspId,"dsp_freePage",DSPDRIVER_ERROR_BAD_ID); 
      return;
    }
    r = dsp_free_page(DPORT,uPort,pageIndex,UNIT);
    if (r != KERN_SUCCESS)
      err(dspId,"dsp_freePage",r);
}

int dsp_debug(char *driverName,int flags) {
  char *hostName = "";
  int r;
  port_t dport;
  if (!driverName)
    return -1;
  r = netname_look_up(name_server_port, hostName, driverName, &dport);
  if (r != KERN_SUCCESS) {
    return -1;
  }
  r = dsp_set_debug(dport,flags);
  if (r != KERN_SUCCESS) {
    return -2;
  }
  return 0;
}

#endif
