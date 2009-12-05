/* 
	History:

	daj/11/20/95 - Created, from Leonard Manzara's code
	daj/12/95 - Subunit supported added 

*/

/* 
  This module supports DSP-initiated DMA transfers to and from the DSP, as
  well as DSP errors and DSP messages.  

  Explanation of how this all works:

  Interrupt handler doesn't read anything.
  Main interrupt routine (invoked in IO thread) reads first word.
  If it's HOST_W_REQ or HOST_R_REQ, calls appropriate routine.
  Otherwise, reads error or msg, enables interrupts, and then forwards msg to 
  user.
  If it's HOST_W_REQ, looks at channel.
  If the channel is 1, it's buffered mode.
  Otherwise, it's unbuffered mode.

  There's a slight complication in that the Music Kit monitor starts a 
  HOST_R_REQ and then lets it "hang".  Therefore, we detect that and keep a 
  special mode bit for that case.  For historical reasons, we call this the 
  "DMA state", even though we are actually not using DMA.

  Currently, the Music Kit does not support DSP-initiated DMA transfers *to*
  the DSP.  Hence, we have not bothered with support for subunits. 

  Note that when messaging is on, you should not do any host-initiated reads of
  the DSP.  Also, when using the DSP-initiated DMA transfer to the DSP, you 
  should not do any host-initiated writes to the DSP.  The software doesn't 
  enforce these things.  It's up to the user.  libmusickit will never do the 
  wrong thing, though (it sez here!)

  In the case of DSP-initiated DMA transfers *from* the DSP, we do have to 
  worry about subunits.  

  We currently only support interrupt-driven transfer for single-subUnit 
  devices.

*/

#import <driverkit/kernelDriver.h>
#import <kernserv/i386/spl.h>

/*********** The following macros tune the way the polling works *********/
/* 
 * Controls whether the interrupt thread suspends the timeout-sending thread
 * when it (the interrupt thread) is running 
 */
#define AVOID_FILLING_UP_INTERRUPT_PORT 1 /* Set to 1 to be better citizen */

/* 
 * Number of times interrupt thread will poll all messaging DSPs that did 
 * something. In other words, this limits a possible tight loop in the
 * interrupt thread.
 */
#define MAX_DID_SOMETHING_COUNT 16

/* 
 * Number of times we're willing to loop without sleeping in polling thread
 * loop (this may not be needed, but I'm paranoid) 
 */
// #define MAX_BUZZ 1000
#define MAX_BUZZ 100

/* 
 * Sleep duration in timeout-sending thread. Otherwise, it just bangs on interrupt 
 * port and fills it up, then blocks.
 * 
 * I found that even if I set this to 1, I get 10 ms!
 * Setting it to 0 may be dangerous, because it could lead to a tight loop, but
 * I'm going to try anyway, assuming that *something* else will block and give
 * the rest of the system a chance to run.  This is, admitedly, a dangerous
 * strategy, but I don't know what else to do.
 *
 * To avoid wasting cycles, I do sleep if there's no DMA requests pending.
 *
 * DAJ
 */
#define POLL_INTERVAL_READ_REQUEST_PENDING 0
#define POLL_INTERVAL_READ_REQUEST_NOT_PENDING 100  /* ms */


/********** Other configuration variables *************/
#define BUFFERED_CHAN DSPMK_WD_DSP_CHAN 
// #define BUFFERED_CHAN -1  /* Uncomment to disable buffering on chan 1 */

#define BUFFERED_CHAN_BUFSIZ MSG_SIZE_MAX

#define VM_ALLOCATE_CAN_BLOCK 1 /* I'm not sure if it can, but I'm being safe */

#define KEEP_OWN_VM_POOL 1      /* If 0, runs out of virtual memory */
                                /* Must match DSPObject.c */

/********* We had problems with vm_allocate so we use a static pool ***/


#if KEEP_OWN_VM_POOL

#define VM_ALLOCATE(_ret,_self,_task,_dataPtr,_count,_anywhereFlag) \
  for (;;) { \
    (*_dataPtr) = [self allocPage]; \
    if (!(*_dataPtr)) \
      { \
	  DPRINTF("Sleeping waiting for vmem.\n"); \
	  unshadowLKSSubUnit(_self); \
	  IOSleep(1); \
	  reshadowLKSSubUnit(_self); \
	  } \
    else break; \
   } \
   ret = KERN_SUCCESS

#define VM_DEALLOCATE(_task,_data,_count,_index) \
  [self deallocPage:_index]

-(vm_address_t)allocPage {
    int i;
    for (i=prevPageAlloc; i<availPageCount; i++) {
      if (!availPages[i].inUse) {
	prevPageAlloc = i;
	availPages[i].inUse = 1;
	DPRINTF("Allocating page %d\n",i);
	return availPages[i].pagePtr;
      }
    }
    for (i=0; i<prevPageAlloc; i++) {
      if (!availPages[i].inUse) {
	prevPageAlloc = i;
	availPages[i].inUse = 1;
	DPRINTF("Allocating page %d\n",i);
	return availPages[i].pagePtr;
      }
    }
    return 0;
}

-(void)deallocPage:(int)i {
    DPRINTF("Freeing page %d\n",i);
    if (i >= 0 && i < availPageCount)
      availPages[i].inUse = 0;
    else IOLog("dsp: illegal page return %d\n",i);
}

- (void)initAvailPagePool
{
    int i,ec;
    port_t kernel_task;
//    port_t io_task;
    /*  GET THE TASK ID FOR THE CURRENT KERNEL TASK  */
    kernel_task = kern_serv_kernel_task_port();
//    io_task = IOConvertPort(kernel_task,IO_CurrentTask,IO_KernelIOTask);
//    if (io_task == PORT_NULL)
//      UPRINTF("DSP driver: problem converting outputQueue port.\n");

    /*  ALLOCATE PAGES OF VIRTUAL MEMORY  */
    for (i = 0; i < availPageCount; i++) {
      ec = vm_allocate((vm_task_t)kernel_task,
		       &(availPages[i].pagePtr),
		       BUFFERED_CHAN_BUFSIZ, TRUE);
      if (ec != KERN_SUCCESS)
	IOLog("dsp: Couldn't allocate output page %d\n",i);
      availPages[i].inUse = 0;
    }
}

- (void)reinitAvailPagePool 
{
    int i;
    for (i=0; i<availPageCount; i++)
      availPages[i].inUse = 0;
}

#else

/* Note that IOVmTaskSelf() doesn't work as the vm task */
#define VM_ALLOCATE(_ret,_self,_arg1,_arg2,_arg3,_arg4) \
  unshadowLKSSubUnit(_self); \
  _ret = vm_allocate(_arg1,_arg2,_arg3,_arg4); \
  reshadowLKSSubUnit(_self)

#define VM_DEALLOCATE(_task,_data,_count,_index) \
  vm_deallocate(_task,_data,_count)

- (void)initAvailPagePool { }

#endif

/* DMA state values */
#define DMA_STATE_NORMAL 0
#define DMA_STATE_HUNG_DMA_FROM_DSP 1

/* 
 * The following is needed because the "current DSP" is a global.
 *
 * It must be used as follows:
 * 
 * self->shadowedLKSThreadSubUnit = something;
 * <do something that changes subUnit>
 * unshadowLKSSubUnit(self);
 * <wait>
 * reshadowLKSSubUnit(self);
 * self->subUnit = self->shadowedLKSThreadSubUnit;
 *
 */
static inline void unshadowLKSSubUnit(DSPMKDriver *self) {
     self->shadowedIOThreadSubUnit = self->subUnit;  /* Save IOThread value */
     if (self->subUnit != self->shadowedLKSThreadSubUnit)
       [self setPhysicalSubUnit:self->shadowedLKSThreadSubUnit]; /* Restore to orig */
}

static inline void reshadowLKSSubUnit(DSPMKDriver *self) {
    self->shadowedLKSThreadSubUnit = self->subUnit;
     if (self->subUnit != self->shadowedIOThreadSubUnit) 
	[self setPhysicalSubUnit:self->shadowedIOThreadSubUnit]; /* IOThread val */
}

static inline int awaitISRMaskAndValueIO(unsigned char mask,unsigned char value, 
				  int unit, DSPMKDriver *self)
	/* Same as awaitISRMaskAndValue but safe from IO thread */
{
    if (spinISRMaskAndValue(mask,value,unit) == KERN_SUCCESS)
       return KERN_SUCCESS;
    {
      char isr;
      int timeSlept = 0;
      do {
        timeSlept += SLEEP_TIME;
        if (timeSlept > TIMEOUT) {
          UPRINTF("dsp: Timed out waiting for IO isr&0x%x=0x%x!\n",(int)mask,(int)value);
          return DSPDRIVER_ERROR_TIMEOUT;
        }
	unshadowLKSSubUnit(self);
	DPRINTF("dsp: Sleep waiting for IO isr&0x%x=0x%x!\n",(int)mask,(int)value);
	IOSleep(SLEEP_TIME);      
	reshadowLKSSubUnit(self);
	isr = inb(DSPDRIVER_ISR(unit)); /* Try again */
      } while ((isr & mask) != value);
    }
    return KERN_SUCCESS;
}

static inline int awaitISRMaskIO(unsigned char mask, int unit,DSPMKDriver *self)
{
    return awaitISRMaskAndValueIO(mask,mask,unit,self);
}

static int awaitCVRMaskAndValueIO(unsigned char mask,unsigned char value, 
				  int unit,DSPMKDriver *self)
{
    if (spinCVRMaskAndValue(mask,value,unit) == KERN_SUCCESS)
       return KERN_SUCCESS;
    {
        unsigned char cvr;
	int timeSlept = 0;
	do {
	    timeSlept += SLEEP_TIME;
	    if (timeSlept > TIMEOUT) {
		UPRINTF("dsp: Timed out waiting for IO cvr&0x%x=0x%x!\n",(int)mask,(int)value);
		return DSPDRIVER_ERROR_TIMEOUT;
	    }
	    unshadowLKSSubUnit(self);
	    DPRINTF("dsp: Sleep waiting for IO cvr&0x%x=0x%x!\n",(int)mask,(int)value);
	    IOSleep(SLEEP_TIME);      
	    reshadowLKSSubUnit(self);
	    cvr = inb(DSPDRIVER_CVR(unit)); /* Try again */
	} while ((cvr & mask) != value);
    }
    return KERN_SUCCESS;
}

static inline void hostCommandSafe(int command, int unit, DSPMKDriver *self)
    /* If safe, wait for HC==0.  This is needed, according to the DSP
     * manual, but Leonard Manzara says that for snddriver protocol,
     * it's unnecessary.  Since the Music Kit uses snddriver protocol
     * only for data coming from the dsp, we check the HC bit in
     * this case only.
     */
{
  if (awaitCVRMaskAndValueIO(HC,0,unit,self)) 
    return; /* Timeout */
  outb(DSPDRIVER_CVR(unit), ((unsigned char)command | 0x80) );
}


static inline void hostCommandUnprotected(int command, int unit)
    /* If safe, wait for HC==0.  This is needed, according to the DSP
     * manual, but Leonard Manzara says that for snddriver protocol,
     * it's unnecessary.  Since the Music Kit uses snddriver protocol
     * only for data coming from the dsp, we check the HC bit in
     * this case only.
     */
{
    outb(DSPDRIVER_CVR(unit), ((unsigned char)command | 0x80) );
}

#define MSGSEND_TIMEOUT 10000 /* ms. So driver doesn't get hung permanently */

static void timeoutThreadLoop(void *_self) { /* arg is port */
  DSPMKDriver *self = _self;
  int pollInterval;
  int buzzCount = 0;
  msg_header_t  h;
  port_t interruptPort = [self interruptPort];
  h.msg_simple = TRUE;
  h.msg_type = MSG_TYPE_NORMAL;
  h.msg_id = IO_TIMEOUT_MSG;
  while (1) {
    h.msg_local_port = PORT_NULL;
    h.msg_size = sizeof(msg_header_t);
    h.msg_remote_port = (port_t)interruptPort;
    msg_send(&h, SEND_TIMEOUT|SEND_SWITCH, MSGSEND_TIMEOUT);
    if (self->pendingReadRequests || self->pendingBufferedReadRequests)
      pollInterval = POLL_INTERVAL_READ_REQUEST_PENDING;
    else pollInterval = POLL_INTERVAL_READ_REQUEST_NOT_PENDING;
    if (pollInterval) {
      VPRINTF("dsp: Timeout sleep %d ms\n",pollInterval);
      IOSleep(pollInterval);
      buzzCount = 0;
    }
    else if (buzzCount++ > MAX_BUZZ) { /* Make sure we sleep *sometime* */
      VPRINTF("dsp: Buzzcount sleep\n");
      IOSleep(1);
      buzzCount = 0;
    }
  }
}

#define SUBUNIT_MASK(_theSubUnit) (1<<_theSubUnit)

/* 
 * Originally, I had sendMessage loop.  But this caused problems because
 * of the use of the auto-deallocate feature in the Mach message.
 * I know it *shouldn't* cause a problem, since the data is only supposed
 * to be deallocated if the message is successfully queued, but that's not
 * what I found--DAJ. 
 * So this version waits forever, unless there's a failure.
 */

static void sendMessage(int messageType, port_t port, int regionTag,
			void *data, int nbytes, int chan, int pageIndex,
			BOOL fromIOThread, 
			int unit)
{
    int ec;	
    DSPMKDriver *self = classVars.driverObjects[unit];
    DPRINTF("dsp: sending message subUnit %d\n",self->subUnit);
    if (fromIOThread)
      unshadowLKSSubUnit(self);
    /* Now do the type-specific fields */
    if (messageType == DSPDRIVER_MSG_READ_SHORT_COMPLETED ||
	messageType == DSPDRIVER_MSG_READ_BIG_ENDIAN_SHORT_COMPLETED ||
	messageType == DSPDRIVER_MSG_READ_LONG_COMPLETED) {
      DSPDRIVERDataMessage msg;
      /*  FILL IN THE MESSAGE HEADER  */
      msg.h.msg_type = MSG_TYPE_NORMAL;
      msg.h.msg_local_port = PORT_NULL;
      msg.h.msg_remote_port = port;
      msg.h.msg_id = messageType;
      msg.h.msg_simple = FALSE;
      msg.h.msg_size = sizeof(DSPDRIVERDataMessage);
      /*  FILL IN THE INTEGER TYPE DESCRIPTOR  */
      msg.t1.msg_type_name = MSG_TYPE_INTEGER_32;
      msg.t1.msg_type_size = 32;
      msg.t1.msg_type_number = 4;
      msg.t1.msg_type_inline = TRUE;
      msg.t1.msg_type_longform = FALSE;
      msg.t1.msg_type_deallocate = FALSE;
      /*  FILL IN THE INTEGER VALUES  */
      msg.regionTag = regionTag;
      msg.nbytes = nbytes;
      msg.chan = chan;
      msg.pageIndex = pageIndex;
      /*  FILL IN THE OUT-OF-LINE TYPE DESCRIPTOR  */
      /*  Even if we are sending shorts, it's more
       *  efficient to describe them as 32-bit ints,
       *  for some reason (I found that I could transfer
       *  only a maximum of MAX_MSG_SIZE/4 shorts, but 
       *  I could also transfer MAX_MSG_SIZE/4 ints--twice.
       *  as much data--DAJ)
       */
      msg.t2.msg_type_name = MSG_TYPE_INTEGER_32;
      msg.t2.msg_type_size = 32;
      msg.t2.msg_type_number = nbytes / 4;
      msg.t2.msg_type_inline = FALSE;
      msg.t2.msg_type_longform = FALSE;
#if KEEP_OWN_VM_POOL
      msg.t2.msg_type_deallocate = FALSE; /* Never deallocate */
#else
      msg.t2.msg_type_deallocate = TRUE;  
#endif
      /*  FILL IN THE OUT-OF-LINE DATA  */
      msg.data = data;
      /*  SEND THE MESSAGE  */
      ec = msg_send(&msg.h, MSG_OPTION_NONE, 0);
      /* If the message is not queued, then the deallocation doesn't happen */
      if (ec != SEND_SUCCESS) {
	UPRINTF("DSP driver msg_send returns %d\n",ec);
	VM_DEALLOCATE(task_self(),(vm_address_t)data,nbytes,regionTag);
      }
    } else {
      DSPDRIVERSimpleMessage msg;
      /*  FILL IN THE MESSAGE HEADER  */
      msg.h.msg_type = MSG_TYPE_NORMAL;
      msg.h.msg_local_port = PORT_NULL;
      msg.h.msg_remote_port = port;
      msg.h.msg_id = messageType;
      msg.h.msg_simple = TRUE;
      msg.h.msg_size = sizeof(DSPDRIVERSimpleMessage);
      /*  FILL IN THE TYPE DESCRIPTOR  */
      msg.t.msg_type_name = MSG_TYPE_INTEGER_32;
      msg.t.msg_type_size = 32;
      msg.t.msg_type_number = 1;
      msg.t.msg_type_inline = TRUE;
      msg.t.msg_type_longform = FALSE;
      msg.t.msg_type_deallocate = FALSE;
      /*  FILL IN THE DATA  */
      msg.regionTag = regionTag;
      /*  SEND THE MESSAGE  */
      ec = msg_send(&msg.h, MSG_OPTION_NONE, 0);
      if (ec != SEND_SUCCESS)
	UPRINTF("DSP driver msg_send returns %d\n",ec);
    }
    if (fromIOThread)
      reshadowLKSSubUnit(self);
    DPRINTF("dsp: message sent subUnit %d\n",self->subUnit);
}

static void interruptHandler(void *identity, void *state, unsigned int unit)
    /* FIXME This only works if we have a single subUnit. */
{
    unsigned char isr;
    DSPMKDriver *self = classVars.driverObjects[unit];
    /*  GET THE VALUE OF THE INTERRUPT STATUS REGISTER  */
    isr = inb(DSPDRIVER_ISR(unit));
    /*  IF NOT IN MESSAGING MODE, RETURN IMMEDIATELY  */
//    DPRINTF("dsp: interrupt\n");
    if (!(self->messagingOn))
        return;
    /*  IF THE DSP DIDN'T CAUSE THE INTERRUPT, RETURN IMMEDIATELY  */
    if (!(isr & 0x80))
        return;
    /*  RETURN IMMEDIATELY, IF RXDF DIDN'T CAUSE INTERRUPT  */
    if (!(isr & RXDF))
        return;
    /*  TURN OFF INTERRUPTS */
    outb(DSPDRIVER_ICR(unit),0x0);
    IOSendInterrupt(identity, state, IO_DEVICE_INTERRUPT_MSG);
}

- (void)setMessagingOn:(BOOL)flag
  /* Records whether the driver is in messaging mode, and
   * and sets the DSP interrupts appropriately. */
{
    /*  SET THE MESSAGING FLAG IVAR  */
    unsigned subUnitMask = SUBUNIT_MASK(subUnit);
    DPRINTF("dsp: messaging = %d, subUnit %d\n",flag,subUnit);
    if (flag) {
      if (!(messagingOn & subUnitMask)) {
	messagingDSPs[messagingDSPsCount++] = subUnit;
	messagingOn |= subUnitMask;
      }
    } 
    else /* !flag */
      if (messagingOn & subUnitMask) {
	int i;
	messagingOn &= ~subUnitMask; /* Turn off bit */
	/* Move others down and decrement count */
	for (i=0; i<messagingDSPsCount; i++) {
	  if (messagingDSPs[i] == subUnit) {
	    int j;
	    messagingDSPsCount--;
	    for (j=i; j < messagingDSPsCount; j++) {
	      messagingDSPs[j] = messagingDSPs[j+1];
	    }
	    break;
	  }
	}
      }
    /*  IF MESSAGING, ENABLE INTERRUPT SO THE DSP CAN MESSAGE THE HOST  */
    if (useInterrupts) {
      if (messagingOn)
	outb(DSPDRIVER_ICR([self unit]),0x01);
      else
	outb(DSPDRIVER_ICR([self unit]),0x00);
    } else {
         if (messagingOn) {
	  if (!pollingThread) {
	    pollThreadRunning = TRUE;
	    pollingThread = 
	      IOForkThread(timeoutThreadLoop, (void *)self);
	  }
	  else if (!pollThreadRunning) {
	       pollThreadRunning = TRUE;
	       IOResumeThread(pollingThread);
	  }
	}
	else /* messaging off */
	  if (pollingThread && pollThreadRunning) {
	    IOSuspendThread(pollingThread);
	    pollThreadRunning = FALSE;
	}
    }
    if (!flag) {
      /* 
       * FIXME.  Are we sure this will dealloc the data in the IOThread?
       * Is it the same task? - DAJ
       */
      bufferedChanState[subUnit] = DMA_STATE_NORMAL;
      if (pendingBufferedChanData[subUnit])
	VM_DEALLOCATE(task_self(),
		      (vm_address_t)pendingBufferedChanData[subUnit],
		      BUFFERED_CHAN_BUFSIZ,pendingBufferedChanPageIndex[subUnit]);
      pendingBufferedChanData[subUnit] = NULL;
      curBufferedChanCount[subUnit] = 0;
      [self reinitAvailPagePool];
    }	
    return;
}

- (BOOL)getHandler:(IOEISAInterruptHandler *)handler
                   level:(unsigned int *)ipl
                   argument:(unsigned int *)arg
                   forInterrupt:(unsigned int)localInterrupt
{
    *handler = interruptHandler;
    *ipl = IPLDEVICE;
    *arg = [self unit];
    return YES;
}

- (int)doDSPInitiatedTransfer {
    int unit = [self unit];
    int didSomething;
    unsigned char isr = inb(DSPDRIVER_ISR(unit));
    unsigned char high, med, low;
    if ((isr & RXDF) == 0)
       return 0; /* Nothing to do */
    /* We've got something to do */
    /* First we check for the special case of a hung dma from dsp */
    if (bufferedChanState[subUnit] == DMA_STATE_HUNG_DMA_FROM_DSP) {
       outb(DSPDRIVER_ICR(unit),0x10); /* Turn off interrupts, with HF1 on */
       bufferedChanState[subUnit] = DMA_STATE_NORMAL;
       [self getDataFromDSP:BUFFERED_CHAN]; 
       outb(DSPDRIVER_ICR(unit),0x1);  /* Reenable interrupts, with HF1 off */
       return 1; /* We did something useful */
    } 
    didSomething = 0;
    outb(DSPDRIVER_ICR(unit),0);  /* Turn off interrupts, with HF1 off */
    /*  GET THE DSP MESSAGE FROM THE RX REGISTER  */
    high = inb(DSPDRIVER_DATA_HIGH(unit));
    med = inb(DSPDRIVER_DATA_MED(unit));
    low = inb(DSPDRIVER_DATA_LOW(unit));
    TPRINTF("dsp: %x,%x,%x\n",(int)high,(int)med,(int)low);
    switch (high) {
          case HOST_W_REQ: {
	      /* SLEEP UNTIL THERE IS SOMETHING TO SEND TO THE DSP  */
	      int totalTimeOut = 0;
	      UPRINTF("Host_w_req\n");
	      for (;;) {
		if (!(messagingOn & SUBUNIT_MASK(subUnit)))
		   return 0; /* Return, leave interrupts off */
		if ([self pendingOutputMessage])
		   break;
		if ((totalTimeOut += SLEEP_TIME) >= TIMEOUT) {
		   UPRINTF("DSP driver: Host_w_req timed out.\n");
		   return 0; /* Return, leave interrupts off */
		}
		unshadowLKSSubUnit(self);
		DPRINTF("dsp: Sleeping waiting for host_w_req\n");
	        IOSleep(SLEEP_TIME);
		reshadowLKSSubUnit(self);
	      }
	      /*  SEND THE PAGE OF DATA TO THE DSP, USING DMA PROTOCOL  */
	      [self sendPageToDSP];
	      didSomething = 1;
	      break;
	  }
	  case HOST_R_REQ: {
	      /*  GET THE DATA FROM THE DSP, USING DMA PROTOCOL  */
	      int chan = (((unsigned)med) << 8) | (unsigned)low;
	      if (chan > DSPDRIVER_MAX_TRANSFER_CHAN) { /* Error */
		  UPRINTF("DSP driver: invalid DSP transfer channel %d received from DSP\n",chan);
		  return 0; /* Give up */
	      }
	      /* 
	       * Still have to pull data, even if port is NULL. 
	       * When we first boot the DSP, we apparently
	       * start up with a hung DMA even before the write data. 
	       * See comment in getDataFromDSP: below. 
	       */
	      outb(DSPDRIVER_ICR(unit),0x10); /* Interrupts off, HF1 on */
	      if (chan == BUFFERED_CHAN) {
	        if (inb(DSPDRIVER_ISR(unit)) & RXDF) { 
		  /* Might be ready if multiple DSPs */
		  [self getDataFromDSP:chan]; 
		} else {
		  /* It's a "hung dma" */
		  bufferedChanState[subUnit] = DMA_STATE_HUNG_DMA_FROM_DSP;
		  outb(DSPDRIVER_ICR(unit),0x11); /* reenable interrupts with HF1 on */
		  return 0; /* We know there's no data, so no need to re-poll now */
		}
	      }
	      else 
		[self getDataFromDSP:chan];
	      didSomething = 1;
	      break;
	  }
	  default: {
	      /*  Send dspmsg or dsperror */
	      unsigned int info = 
		(((unsigned int)high) << 16) | 
		  (((unsigned int)med) << 8) | low;
	      if (high & 0x80)  /* High order bit of 24-bit word on? */
		[self sendDSPErr:info];
	      else [self sendDSPMsg:info];
	      didSomething = 1;
	      break;
	  }
    } /* end switch */
    outb(DSPDRIVER_ICR(unit),1);  /* reenable interrupts, with HF1 off */
    return didSomething; 
}

- (void)interruptOccurred:(int)msgID
{ /* This doesn't really support subUnits yet */
  shadowedLKSThreadSubUnit = subUnit;  /* Shadow LKS subUnit */
  [self doDSPInitiatedTransfer];
  if (subUnit != shadowedLKSThreadSubUnit)  /* Remove shadow from LKS subUnit */
    [self setPhysicalSubUnit:shadowedLKSThreadSubUnit];  
}

- (void)timeoutOccurred
  /* 
   * This is like interruptOccurred, but for DSP cards without interrupts.  
   * But unlike interruptOccured, it supports mutliple subUnits.
   */
{
    /* Poll all DSPs */
  int i,aSubUnit,didSomethingCount;
  unsigned keepLookingVector;
  /* Poll DSP for data */
  /* We need check in here because we may have messages queued up */
  if (!messagingOn) 
    return;
#if AVOID_FILLING_UP_INTERRUPT_PORT
  if (pollThreadRunning) {
    /* Attempt at avoiding filling up io mach port */
    IOSuspendThread(pollingThread);
    pollThreadRunning = FALSE;
  }
#endif
  shadowedLKSThreadSubUnit = subUnit;  /* Shadow LKS subUnit */
  /* 
   * The idea of MAX_DID_SOMETHING_COUNT is to prevent us from monopolizing the CPU.
   * If the DSPs are running very quickly, we could always have something
   * to do here.
   */
  keepLookingVector = messagingOn;
  didSomethingCount = 0; 
  VPRINTF("dsp: polling\n");
  do {
    for (i = 0; i < messagingDSPsCount; i++) { /* Check DSPs with messaging on */
      aSubUnit = messagingDSPs[i];
      if (subUnit != aSubUnit)     /* Set physical subunit, if needed */
	[self setPhysicalSubUnit:aSubUnit];
      VPRINTF("dsp: polling %d\n",subUnit);
      if ([self doDSPInitiatedTransfer])
	didSomethingCount++;      /* Did something */
      else 
	keepLookingVector &= ~SUBUNIT_MASK(aSubUnit);
    }
  } while ((didSomethingCount < MAX_DID_SOMETHING_COUNT) && messagingOn && 
	   keepLookingVector);
  VPRINTF("dsp: done polling\n");
  if (subUnit != shadowedLKSThreadSubUnit)  
    /* Remove shadow from LKS subUnit */
    [self setPhysicalSubUnit:shadowedLKSThreadSubUnit];  
#if AVOID_FILLING_UP_INTERRUPT_PORT
  if (!pollThreadRunning && messagingOn) {
    pollThreadRunning = TRUE;
    IOResumeThread(pollingThread);
  }
#endif
}

- (void)initOutputQueue
/* Allocates memory and initializes data structures for
 * the output queue (for data from host to DSP).
 */		       
{
    int i,ec;
    port_t kernel_task;
    /*  SET TAIL AND HEAD POINTERS  */
    outputTail = 0;
    outputHead = 0;
    /*  GET THE TASK ID FOR THE CURRENT KERNEL TASK  */
    kernel_task = kern_serv_kernel_task_port();

    /*  ALLOCATE PAGES OF VIRTUAL MEMORY  */
    for (i = 0; i < OUTPUT_QUEUE_SIZE; i++) {
      ec = vm_allocate((vm_task_t)kernel_task, &(outputQueue[i].pagePtr),
		       8192, TRUE);
      if (ec != KERN_SUCCESS)
	IOLog("dsp: Couldn't allocate output page %d\n",i);
//  Use the following instead, if wired vm preferred
//        outputQueue[i].pagePtr = (vm_address_t)kalloc(8192);
    }
}

- (void)resetOutputQueue
  /* Resets the data structures which control the output queue. */
{
    /*  RESET TAIL AND HEAD POINTERS  */
    outputTail = 0;
    outputHead = 0;
}

- (int)outputQueueFull
{
    /*  GET CURRENT TAIL AND HEADER POINTERS FOR THE OUTPUT QUEUE  */
    int tail = outputTail;
    int head = outputHead;
    /*  ADVANCE HEAD BY BUFFER SIZE, IF NECESSARY, TO DO MODULUS COMPARE  */
    if (head <= tail)
        head += OUTPUT_QUEUE_SIZE;
    /*  COMPARE FILL AND EMPTY POINTERS, RETURNING TRUE IF QUEUE FULL  */
    if ((head - tail) <= 1)
        return(1);
    /*  IF HERE, THEN THE QUEUE IS NOT FULL  */
    return(0);
}


/******************************************************************************
*
*	method:  	pushOutputQueue:::::
*
*	purpose:	Takes data from the user process, and pushes it onto
*                       the tail of the output queue.  Note that user data
*			is mapped into queue memory, not copied, so it must
*                       be page-aligned vm.
*
*       arguments:      pageAddress - page-aligned data to be transferred
*                                     to the DSP
*                       regionTag - the tag for the page of data
*                       msgStarted - set on, if started reply message desired
*                       msgCompleted - set on, if completed reply message
*                                      desired
*                       replyPort - port where reply messages are sent to
*
*	internal
*	functions:	outputQueueFull
*
*	library
*	functions:	vm_write, kern_serv_kernel_task_port, IOConvertPort
*
******************************************************************************/

- (void)pushOutputQueue:(DSPPagePtr)pageAddress:(int)regionTag:(BOOL)msgStarted
  :(BOOL)msgCompleted:(port_t)replyPort
{
    /*  MAKE SURE WE DON'T OVERRUN THE BUFFER, BLOCKING IF NECESSARY  */
    while ([self outputQueueFull])
        ;
    /*  PUSH THE DATA ONTO THE TAIL OF THE QUEUE  */
    vm_write(kern_serv_kernel_task_port(), outputQueue[outputTail].pagePtr,
	     (pointer_t)pageAddress, 8192);
    outputQueue[outputTail].regionTag = regionTag;
    outputQueue[outputTail].msgStarted = msgStarted;
    outputQueue[outputTail].msgCompleted = msgCompleted;
    /*  THE IO THREAD SENDS THE MESSAGES BACK TO THE REPLY PORT  */
    if (replyPort == PORT_NULL)
	outputQueue[outputTail].replyPort = PORT_NULL;
    else {
	outputQueue[outputTail].replyPort =
        	IOConvertPort(replyPort,IO_CurrentTask,IO_KernelIOTask);
	if (outputQueue[outputTail].replyPort == PORT_NULL)
	   UPRINTF("DSP driver: problem converting outputQueue port.\n");
    }
    /*  DO MODULUS INCREMENT OF TAIL POINTER  */
    outputTail++;
    outputTail &= OUTPUT_QUEUE_MOD;
}

- (DSPDRIVEROutputQueueMessage *)popOutputQueue
/* Removes one item from the head of the output queue. */
{
    DSPDRIVEROutputQueueMessage *ptr = NULL;
    if (outputHead != outputTail) {
        ptr = &outputQueue[outputHead++];
	outputHead &= OUTPUT_QUEUE_MOD;
    }
    return(ptr);
}

- (DSPDRIVEROutputQueueMessage *)pendingOutputMessage
/* Returns a pointer to the pending output queue item,
 * if there is one, else returns NULL.
 */
{
    if (outputHead != outputTail)
        return(&outputQueue[outputHead]);

    return(NULL);
}

/******************************************************************************
*
*	method:  	setDSPReadRegionTag:wordCount:replyPort:long:
*
*	purpose:	Records where data from the DSP to the host should be
*                       sent, what size buffers are used, and the tag for the
*                       region of data.
*			
*       arguments:      regionTag - tag for the region of data returned
*                       wordCount - the number of words transferred by the
*                                    DSP to the host
*                       replyPort - the port where reply messages are sent to
*                       chan - in range [1|3:DSPDRIVER_MAX_TRANSFER_CHAN] 
*                       readType - one of READ_TYPE_LONG,
*                                         READ_TYPE_SHORT,
*                                         READ_TYPE_SHORT_BIG_ENDIAN 
*	internal
*	functions:	none
*
*	library
*	functions:	IOConvertPort
*
******************************************************************************/

- (void)setDSPReadRegionTag:(int)regionTag wordCount:(int)wordCount
        replyPort:(port_t)replyPort chan:(int)chan readType:(int)readType
{
    unsigned subUnitMask;
    dspReadRegionTag[subUnit][chan] = regionTag;
    dspReadWordCount[subUnit][chan] = wordCount;
    DPRINTF("dsp: setread subUnit=%d count=%d chan=%d\n",subUnit,wordCount,chan);
    if (replyPort != PORT_NULL) {
      replyPort = IOConvertPort(replyPort,IO_CurrentTask,IO_KernelIOTask);
      if (replyPort == PORT_NULL)
	UPRINTF("DSP driver: problem converting read port.\n");
    }
    subUnitMask = SUBUNIT_MASK(subUnit);
    if (chan == BUFFERED_CHAN) {
      if (replyPort)
	pendingBufferedReadRequests |= subUnitMask;
      else pendingBufferedReadRequests &= ~subUnitMask;
      dspBufferedReadReplyPort[subUnit] = replyPort;
    }
    else {
      if (replyPort)
	pendingReadRequests |= subUnitMask;
      else pendingReadRequests &= ~subUnitMask;
      dspReadReplyPort[subUnit] = replyPort;
    }
    dspReadType[subUnit][chan] = readType;
}

- (void)setMsgPort:(port_t)replyPort
  /* Set port to receive DSP errors and DSP messages */
{
    DPRINTF("dsp: setMsgPort subUnit=%d port=%d\n",subUnit,replyPort);
    if (replyPort == PORT_NULL)
       msgPort[subUnit] = PORT_NULL;
    else {
       msgPort[subUnit] = IOConvertPort(replyPort,IO_CurrentTask,IO_KernelIOTask);
       if (msgPort[subUnit] == PORT_NULL)
          UPRINTF("DSP driver: problem converting msg port.\n");
    }
}

- (void)setErrorPort:(port_t)replyPort
  /* Set port to receive DSP errors and DSP messages */
{
    DPRINTF("dsp: setErrorPort subUnit=%d port=%d\n",subUnit,replyPort);
    if (replyPort == PORT_NULL)
       errPort[subUnit] = PORT_NULL;
    else {
       errPort[subUnit] = IOConvertPort(replyPort,IO_CurrentTask,IO_KernelIOTask);
       if (errPort[subUnit] == PORT_NULL)
          UPRINTF("DSP driver: problem converting error port.\n");
    }
}

/******************************************************************************
*
*	method:  	sendPageToDSP
*
*	purpose:	Sends a page of data from the output queue to the DSP
*                       using the "DSP-initiated DMA" protocol.  Started and/or
*                       completed messages are also sent to the reply port, if
*                       requested.  The transferred item is popped from the
*                       output queue.
*			
******************************************************************************/

- (void)sendPageToDSP
  /* Subunits not supported */
{
    int i, *data;
    int unit = [self unit];
    /*  SEND STARTED MESSAGE TO REPLY PORT, IF REQUESTED  */
    if (outputQueue[outputHead].msgStarted)
        sendMessage(DSPDRIVER_MSG_WRITE_STARTED, outputQueue[outputHead].replyPort,
		    outputQueue[outputHead].regionTag, NULL, 0, 0, 0, TRUE, unit);
    /*  SEND THE DATA IN THE OUTPUT QUEUE TO THE DSP  */
    /*  SEND DMA_IN_ACCEPTED HOST COMMAND, PLUS A DUMMY VALUE  */
    hostCommandUnprotected(0x2C>>1, unit);
    writeInt(0, unit);
    /*  SEND THE DMA BUFFER TO THE DSP  */
    data = (int *)(outputQueue[outputHead].pagePtr);
    for (i = 0; i < (MSG_SIZE_MAX/sizeof(int)); i++)
        writeInt(*(data++),unit);
    /*  SEND A DMA_DONE HOST COMMAND  */
    hostCommandUnprotected(0x28>>1, unit);
    /*  SEND COMPLETED MESSAGE TO REPLY PORT, IF REQUESTED  */
    if (outputQueue[outputHead].msgCompleted)
        sendMessage(DSPDRIVER_MSG_WRITE_COMPLETED, outputQueue[outputHead].replyPort,
		    outputQueue[outputHead].regionTag, NULL, 0,0, 0,TRUE, unit);
    /*  DISCARD THE LAST ELEMENT OF THE OUTPUT QUEUE  */
    [self popOutputQueue];
}



- (void)getDataFromDSP:(int)chan
/*
 * Gets a buffer of data from the DSP and copies it to
 * a region of vm.  
 * Three modes are supported:
 * 
 * READ_TYPE_LONG - 24 bits, right-justified in 32 bits
 * READ_TYPE_SHORT - 16 lower bits
 * READ_TYPE_SHORT_BIG_ENDIAN - 16 lower bits, big-endian
 *
 * Each buffer of data is sent to user code
 * using out-of-line mach messages.
 *
 * If chan is 1, the data is collected until it fills the page.
 */
{
    int i, unit = [self unit];
    int ret;
    void *data;
    short *shortPtr;
    int *longPtr;
    unsigned char low, med = 0, high, nextHigh;
    int count = dspReadWordCount[subUnit][chan];
    short int v;
    BOOL sendNow,dummyMode;
    int readType = dspReadType[subUnit][chan];
    int readSize = (readType == READ_TYPE_LONG) ? 4 : 2; /* In bytes */
    unsigned subUnitMask;
    int pageIndex = 0; /* init to make compiler happy */
    DPRINTF("dsp: getting data subUnit=%d\n",subUnit);
    if (chan == BUFFERED_CHAN) {
        dummyMode = dspBufferedReadReplyPort[subUnit] == PORT_NULL; 
	if (!dummyMode) {
	  if (curBufferedChanCount[subUnit] == 0) {
	    VM_ALLOCATE(ret,self,task_self(), (vm_address_t *)&data,
			BUFFERED_CHAN_BUFSIZ, TRUE);
	    if (ret != KERN_SUCCESS) {
	      IOLog("DSP driver: vm_allocate failed: %d\n",ret);
	      [self setMessagingOn:0];
	      return;
	    }
	    pendingBufferedChanPageIndex[subUnit] = prevPageAlloc;
	    pendingBufferedChanData[subUnit] = data; /* Save it here */
	  } else {
	    /* Point into middle of buff */
	    if (readSize == 4)
	      data = 
		((int *)pendingBufferedChanData[subUnit]) + curBufferedChanCount[subUnit]; 
	    else 
	      data = 
		((short *)pendingBufferedChanData[subUnit]) + curBufferedChanCount[subUnit]; 
	  }
	  curBufferedChanCount[subUnit] += count;
	}
    } else {
        dummyMode = dspReadReplyPort[subUnit] == PORT_NULL;
	if (!dummyMode) {
	  /*  ALLOCATE MEMORY TO HOLD THE INPUT FROM THE DSP  */
	  VM_ALLOCATE(ret,self,task_self(), (vm_address_t *)&data,
		      (count * readSize), TRUE);
	  if (ret != KERN_SUCCESS) {
	    IOLog("DSP drvier: vm_allocate failed: %d\n",ret);
	    [self setMessagingOn:0];
	    return;
	  }
	  pageIndex = prevPageAlloc;
	}
    }
    subUnitMask = SUBUNIT_MASK(subUnit);
    if (dummyMode) {
      DPRINTF("dsp: no data port\n");
      /* Get one word (we get another at the end) */
      while (awaitISRMaskIO(RXDF,unit,self) && (messagingOn & subUnitMask)) 
	;
      if (messagingOn & subUnitMask)
	low = inb(DSPDRIVER_DATA_LOW(unit));
    }
    else {
      if (readType != READ_TYPE_LONG) {
	for (i = 0, shortPtr = data; i < count; i++) {
	  /*  WAIT UNTIL RXDF IS SET  */
	  while (awaitISRMaskIO(RXDF,unit,self) && (messagingOn & subUnitMask)) 
	    ;
	  if (!(messagingOn & subUnitMask)) /* Bail out, we've been reset */
	    break;
	  /*  GET THE WORD FROM THE DSP  */
	  //	high = inb(DSPDRIVER_DATA_HIGH(unit));
	  med = inb(DSPDRIVER_DATA_MED(unit));
	  low = inb(DSPDRIVER_DATA_LOW(unit));
	  if (readType == READ_TYPE_SHORT_BIG_ENDIAN) {
	    /*  IGNORE HIGH BYTE, AND SWAP LOWER TWO BYTES  */
	    v = low;
	    v = (v << 8) | (short)med;
	  } else {
	    v = med;
	    v = (v << 8) | (short)low;
	  }
	  *shortPtr++ = v;
	} 
      } else for (i = 0, longPtr = data; i < count; i++) {
	/*  Same thing for longs */
	while (awaitISRMaskIO(RXDF,unit,self) && (messagingOn & subUnitMask))
	  ;
	if (!(messagingOn & subUnitMask))
	  break;
	high = inb(DSPDRIVER_DATA_HIGH(unit));
	med = inb(DSPDRIVER_DATA_MED(unit));
	low = inb(DSPDRIVER_DATA_LOW(unit));
	v = high;
	v = (v << 8) | (int)med;
        v = (v << 8) | (int)low;
	*longPtr++ = v;
      }
    }
    while (awaitISRMaskIO(RXDF,unit,self) && (messagingOn & subUnitMask))
      ; /* Wait for garbage word.  If we don't do this, the DSP can overwrite it. */
    if (!(messagingOn & subUnitMask)) { /* Bail out, we've been reset */
        if (chan != BUFFERED_CHAN && !dummyMode)
	  VM_DEALLOCATE(task_self(),(vm_address_t)data,
			(count * readSize),pendingBufferedChanPageIndex[subUnit]);
	/* If chan == BUFFERED_CHAN, the vm_deallocate done in setMessagingOn: */
	UPRINTF("DSP driver: messaging turned off while reading data.");
	return;
      }
    /*  SEND A DMA_OUT_DONE HOST COMMAND  */
    hostCommandSafe(0x24>>1, unit, self);
    awaitCVRMaskAndValueIO(HC,0,unit,self); /* Wait for HC to go off */
    IODelay(1);                      /* 1 us spin (80 ns needed) */
    /*  STOP THE DMA REQUEST ACKNOWLEDGE BY CLEARING HOST FLAG 1 */
    outb(DSPDRIVER_ICR(unit),0x0);
    IODelay(1); /* This prevents sleeping waiting for HF2 below on Turtle Beach */
#warning Document waiting for HOST_R_DONE and HF2
    /*  At this point, there should be 1 word of junk followed by 
     * 	HOST_R_DONE.
     */
    /* We also check for HF2 clear (to insure above hostCommand finished. */	
    if (awaitISRMaskAndValueIO((RXDF | HF2), RXDF, unit, self) == KERN_SUCCESS) {
        /* Read garbage */
        high = inb(DSPDRIVER_DATA_HIGH(unit)); 
#if DEBUGGING
	if (debugFlags & DSPDRIVER_DEBUG_UNEXPECTED) 
	  med = inb(DSPDRIVER_DATA_MED(unit));
#endif
	low = inb(DSPDRIVER_DATA_LOW(unit));
	if (high == 5 && low == 1) 
	  IOLog("DSP driver warning: found 5,x,1 instead of first garbage word for subunit %d\n",subUnit);
	if (awaitISRMaskIO(RXDF, unit, self) == KERN_SUCCESS) {
	  /* Read HOST_R_DONE */
	  nextHigh = inb(DSPDRIVER_DATA_HIGH(unit));
	  if (nextHigh != HOST_R_DONE && high == HOST_R_DONE) {
	    /* Sometimes the garbage word seems to be missing.
	     * If so, we neglect to read DATA_LOW so that we can re-read
	     * high again in the main loop above. FIXME
	     */
	    UPRINTF("DSP driver: expected extra DMA word missing. Found 0x%x\n",(((unsigned)high)<<16)|(((unsigned)med)<<8)|(unsigned)low);
	  } else {
	    high = nextHigh;
//          med = inb(DSPDRIVER_DATA_MED(unit));
	    /* Sometimes the HOST_R_DONE is missing! If so, we neglect
	     * to read DATA_LOW so that we can re-read high again
	     * in the main loop above. FIXME
	     */
	    if (high == HOST_R_DONE) {
#if DEBUGGING
	      if (debugFlags & DSPDRIVER_DEBUG_VERBOSE) 
		med = inb(DSPDRIVER_DATA_MED(unit));
#endif
	      low = inb(DSPDRIVER_DATA_LOW(unit));
	      VPRINTF("DSP driver: R_IO=0x%x\n",(((unsigned)med)<<8)|(unsigned)low);
	    } else UPRINTF("DSP driver found %x instead of HOST_R_DONE.\n",(int)high);
	  }
	} else UPRINTF("DSP driver timed out waiting for HOST_R_DONE.\n");
      } else if (messagingOn & subUnitMask)  /* Wasn't an abort */
	UPRINTF("DSP driver timed out waiting for first extra DMA word.\n");
    if ((!(messagingOn & subUnitMask)) || dummyMode) 
      /* Needed, since could have been turned off in Sleeps above */
      return;
    if (chan == BUFFERED_CHAN) {
	sendNow = (curBufferedChanCount[subUnit] == (BUFFERED_CHAN_BUFSIZ/readSize));
	if (sendNow) {
	    count = curBufferedChanCount[subUnit];
	    curBufferedChanCount[subUnit] = 0;  /* Reset */
	    data = pendingBufferedChanData[subUnit]; /* So whole buf gets sent below */
	    pendingBufferedChanData[subUnit] = NULL;
	}
    } else sendNow = TRUE;
    /*  SEND COMPLETED MESSAGE (WITH DATA) TO REPLY PORT */
    if (sendNow) {
       int msgID;
       port_t replyPort;
       switch (readType) {
          case READ_TYPE_SHORT_BIG_ENDIAN:
	     msgID = DSPDRIVER_MSG_READ_BIG_ENDIAN_SHORT_COMPLETED;
             break;
          case READ_TYPE_SHORT:
             msgID = DSPDRIVER_MSG_READ_SHORT_COMPLETED;
             break;
          default:
	     msgID = DSPDRIVER_MSG_READ_LONG_COMPLETED;
             break;
       }
       if (chan == BUFFERED_CHAN) {
	 replyPort = dspBufferedReadReplyPort[subUnit];
	 pageIndex = pendingBufferedChanPageIndex[subUnit];
       } else {
	 replyPort = dspReadReplyPort[subUnit];
       }
       if (replyPort != PORT_NULL) 
	 sendMessage(msgID, replyPort,  dspReadRegionTag[subUnit][chan], data, 
		     (count * readSize), chan, pageIndex, TRUE, unit);
       /*  if (chan != BUFFERED_CHAN) pendingReadRequests &= ~SUBUNIT_MASK(subUnit); */
       /* ^^ In case we decide to clear dspReplyPort[subUnit] when msg is sent */
    }
    DPRINTF("dsp: got data\n");
}

- (void)sendDSPMsg:(unsigned int)msg
  /* Forwards DSP error or msg to appropriate port. */
{
    if (msgPort[subUnit] != PORT_NULL)
       sendMessage(DSPDRIVER_MSG_RET_DSP_MSG,msgPort[subUnit],msg,NULL,0, 0, 0, TRUE,
		   [self unit]); 
}

- (void)sendDSPErr:(unsigned int)err
  /* Forwards DSP error or msg to appropriate port. */
{
    if (errPort[subUnit] != PORT_NULL)
       sendMessage(DSPDRIVER_MSG_RET_DSP_ERR,errPort[subUnit],err,NULL,0, 0, 0, TRUE, 
		   [self unit]); 
}

