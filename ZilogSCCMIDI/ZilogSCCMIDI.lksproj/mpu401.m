/* -----------------------------------------------------------------
 * MPU 401-specific details.
 * To change to another UART-like device, it should be necessary only to
 * change these functions.
 * -----------------------------------------------------------------
 */

#import <driverkit/i386/ioPorts.h>
#import <driverkit/i386/directDevice.h>
#import <driverkit/i386/IOEISADeviceDescription.h>

/* I/O ports */
#define MPU401_DATA(_u) (driverObjects[_u]->dataPort)  /* Read-write */
#define MPU401_STAT(_u) (driverObjects[_u]->statAndCmdPort)
#define MPU401_CMD(_u)  MPU401_STAT(_u)

/* Masks. If bit is clear, condition is true */
#define MPU401_SENDRDY 0x40
#define MPU401_DATARDY 0x80

/* Commands */
#define MPU401_UART 0x3f
#define MPU401_RESET 0xff
#define MPU401_SETPORT1 0xf1  /* Is this really MPU-401 compatible? */
#define MPU401_SETPORT2 0xf2  /* Is this really MPU-401 compatible? */

/* Replies */
#define MPU401_ACK 0xfe 

#define SEND_READY(_unit) (!(inb(MPU401_STAT(_unit)) & MPU401_SENDRDY))
#define RECEIVE_READY(_unit) (!(inb(MPU401_STAT(_unit)) & MPU401_DATARDY))

// #warning SLEEP_TIMOUT set to 500.  Should be 1000.
#define SLEEP_TIMEOUT 1000  /* In ms */
#define SPIN_TIMEOUT 100    /* In us FIXME. Try making this smaller. */

static inline int spinSendReady(short unit) // public
{
  int s = splmidi();
  int i = 0;
  while (!SEND_READY(unit)) {
    splx(s);
    if (i == SPIN_TIMEOUT) { /* Timeout */
      midi_slog("SEND_READY wait timed out\n");
      return SPIN_TIMEOUT;
    }
    i++;
    IODelay(1);
    s = splmidi();
  }
  splx(s);
  return i;
}

static inline int spinReceiveReady(short unit)
{
  int s = splmidi();
  int i = 0;
  while (!RECEIVE_READY(unit)) {
    splx(s);
    if (i == SPIN_TIMEOUT) { /* Timeout */
      return SPIN_TIMEOUT;
    }
    i++;
    IODelay(1);
    s = splmidi();
  }
  splx(s);
  return i;
}

static int sleepSendReady(short unit)
{
  int s = splmidi();
  int i = 1;  /* Changed from 0 to avoid possible infinite loop */
  while (!SEND_READY(unit)) {
    splx(s);
    if (i >= SLEEP_TIMEOUT) { /* Timeout */
      return SLEEP_TIMEOUT;
    }
    i += 10;
    IOSleep(10);
    s = splmidi();
  }
  splx(s);
  return i;
}

static int sleepReceiveReady(short unit)
{
  int s = splmidi();
  int i = 1;  /* Changed from 0 to avoid possible infinite loop */
  while (!RECEIVE_READY(unit)) {
    splx(s);
    if (i >= SLEEP_TIMEOUT) { /* Timeout */
      return SLEEP_TIMEOUT;
    }
    i += 50;
    IOSleep(50);
    s = splmidi();
  }
  splx(s);
  return i;
}

static void sendReset(short unit) {
  int s;
  int timeOut;
  unsigned char c;
  /* Step 1. Wait for Status-in register to indictate ready to receive.
     Wait no longer than 1 second.  If, after 1 second, the MCC is
     not ready to receive, proceed to step 2 */
  sleepSendReady(unit);
  
  /* Step 2. Send the Reset command via the Command-Out register. */
  s = splmidi();
  outb(MPU401_CMD(unit),MPU401_RESET);
  splx(s);
  
  /* Step 3. Wait for the Status-in register to indicate data available.
     You should wait no longer than 1 second.
     */
  timeOut = 0;
  do { 
    timeOut += sleepReceiveReady(unit);
    
    /* Step 4. Read the available data byte from the Data-in register */
    s = splmidi();
    c = inb(MPU401_DATA(unit)); /* Read MPU401_ACK. */
    splx(s);
    
    /* Step 5. If the data byte is a command acknowledge (0xfe), then go 
       to step 10.
       */
  } 
  /* Step 6: If less than 1 second has elapsed, go back to step 3. */
  while ((timeOut < SLEEP_TIMEOUT) && (c != MPU401_ACK));
  
  /* If we were in UART mode already, then there is no MPU401_ACK */
  timeOut = 0;
  if (c != MPU401_ACK) {
    
    /* Step 7. Repeat steps 1 and 2, effectively sending a second reset 
       command. 
       */  
    sleepSendReady(unit);
    s = splmidi();
    outb(MPU401_CMD(unit),MPU401_RESET);
    splx(s);
    
    /* Step 8. Wait for the Status-in register to indicate data available.
       Wait no longer than 1 second for this condition.
       */
    do {
      timeOut += sleepReceiveReady(unit);
      
      /* Step 9. Read the available data byte from the Data-in register.
	 If the byte is not an acknowledge, go back to step 8. */
      s = splmidi();
      c = inb(MPU401_DATA(unit)); /* Read MPU401_ACK. */
      splx(s);
    } while ((timeOut < SLEEP_TIMEOUT) && (c != MPU401_ACK));
    /* According to the MPU401_ doc, this check  for SLEEP_TIMEOUT is not
       needed, but I put it in because sometimes we get stuck for a long
       time here. FIXME */
  }
  if (c != MPU401_ACK)
    IOLog("MidiDriver warning: MPU401_ACK not received.\n");
}

static void sendCommand(unsigned char cmd,short unit) {
  int s;
  int timeOut = 0;
  unsigned char c;
  /* Step 1.  Wait for the Status-in register to indicate ready to receive. */
  sleepSendReady(unit);

  /* Step 2. Send the command via the Command-out register */
  s = splmidi();
  outb(MPU401_CMD(unit),cmd);
  splx(s);

  do {
    /* Step 3. Wait for Status-in regstier to indicate data available */
    timeOut += sleepReceiveReady(unit);
  
    /* Step 4. Read the available data byte from the Data-in register. */
    s = splmidi();
    c = inb(MPU401_DATA(unit)); /* Read MPU401_ACK. */
    splx(s);

    /* Step 5. If the data byte is a command acknowledge, then go to step 8.*/ 
    /* Step 6.  Otherwise the data byte received is part of an unrelated
       message and it must be handled as such.  Failure to handle the data in 
       this way can lead to loss of state synchronization between the card
       and the PC software. */
    /* Step 7. Go to step 3. */
  } while ((c != MPU401_ACK) && timeOut < SLEEP_TIMEOUT);
    /* According to the MPU401_ doc, this check  for SLEEP_TIMEOUT is not
       needed, but I put it in because sometimes we get stuck for a long
       time here. FIXME */
  if (c != MPU401_ACK)
    IOLog("MidiDriver warning: MPU401_ACK not received.\n");
}

static int setTransmitSubunit(short unit)
{
    if (!SEND_READY(unit)) 
      IODelay(1);
    if (!SEND_READY(unit)) 
      IODelay(1);
    if (!SEND_READY(unit))
      return -1;
    if (unit == 0)
      outb(MPU401_CMD(unit),MPU401_SETPORT1);
    else outb(MPU401_CMD(unit),MPU401_SETPORT2);
    /*** Need wait for reply??? FIXME ***/
    return 0;
}

// These are the public interface routines

static void prepareForUse(short unit)
{
    sendCommand(MPU401_UART,unit);
}

static inline unsigned char getData(short unit)
{
    return inb(MPU401_DATA(unit));
}

static inline void putData(short unit,unsigned char event)
{
    outb(MPU401_DATA(unit),event); /* MPU401_ has no xmt interrupt */
}

/*
 * to become interface routines.
 */

static boolean_t deviceInit(short unit) {
  sendReset(unit);
  prepareForUse(unit);
  var.u[unit].claimed = TRUE;
  return TRUE;
}

static void deviceReset(short unit) {
  [driverObjects[unit] disableAllInterrupts];
//  sendReset();  /* FIXME should reset MPU401 to normal mode */
  var.u[unit].claimed = FALSE;
}

static int rcvInterrupt (short unit) {
    int now;
    unsigned char data;
    int newInd;
    now = getCurrentTime();
    midi_slog("[rcvInterrupt\n");
    spinReceiveReady(unit); /* Added Sept. 4, 94. Needed? SoundBlaster doc says yes.*/
    data = getData(unit);
    midi_idatalog("i %x\n",data,2,3,4,5);
    if (!shouldFilter(data,unit) && var.rcvDataThread) {
	if (var.u[unit].rcvPort) {
	    newInd = bumpIndex(var.u[unit].rcvInInd,RCV_FIFO_SIZE);
	    if (newInd == var.u[unit].rcvOutInd) {
		var.u[unit].rcvOverrun = TRUE;
		midi_log("***rcvInterrupt overrun***\n",1,2,3,4,5);
	    }
	    else {
		var.u[unit].rcvFifo[var.u[unit].rcvInInd].time = now;
		var.u[unit].rcvFifo[var.u[unit].rcvInInd].byte = data;
		var.u[unit].rcvInInd = newInd;
		[var.rcvCalloutLock lock];
		[var.rcvCalloutLock unlockWith:DATA_AVAILABLE];
	    } 
	}
    }
    midi_slog("...rcvInterrupt]\n");
    return 0;
}

-(void)interruptOccurred
{
    rcvInterrupt([self unit]);
    // original didn't have this, but should it have?
    //    [self enableAllInterrupts];
}

static void deviceEnable(short unit) {
    var.u[unit].rcvEnabled = TRUE;
    /* Enable interrupts on all receive characters.
     */
    /*** FIXME Need to enable interrput and hook it to rcvInterrupt() */
    [driverObjects[unit] enableAllInterrupts];
}

static void deviceStartXmt(int now,short unit) {
    /* This is called by the driver to start a transmission. */
    int i;
    unsigned char event = var.u[unit].xmtFifo[var.u[unit].xmtOutInd].byte;
    int eventTime = 
      var.u[unit].xmtFifo[var.u[unit].xmtOutInd].time;
    midi_slog("[deviceStartXmt \n");
    while (isFlushing(unit) || 
	   (var.clockRunning && timeLEQ(eventTime,now))) {
        if (!checkTransmitSubunit(unit)) {
	  midi_slog("(checkTransmitSubunit failed)\n");
	  requestWakeup(isFlushing(unit) ? getCurrentTime() : eventTime);
	  midi_slog("...deviceStartXmt ]\n");
	  return;
	}
        i = 0;
	if (spinSendReady(unit) == SPIN_TIMEOUT) {
	  requestWakeup(isFlushing(unit) ? getCurrentTime() : eventTime);
	  midi_slog("...deviceStartXmt ]\n");
	  return;
	}
        var.u[unit].xmtOutInd = bumpIndex(var.u[unit].xmtOutInd,
					  XMT_FIFO_SIZE);
	midi_odatalog("o %x\n",event,2,3,4,5);
	putData(unit,event);
	checkQueueNotify(unit);
	checkFlushing(unit);
	event = var.u[unit].xmtFifo[var.u[unit].xmtOutInd].byte;
	eventTime = var.u[unit].xmtFifo[var.u[unit].xmtOutInd].time;
	if (var.u[unit].xmtInInd == var.u[unit].xmtOutInd) {
	  midi_slog("...deviceStartXmt ]\n");
	  return; 
	}
    } 
    requestWakeup(eventTime);
    midi_slog("...deviceStartXmt ]\n");
}

+ (BOOL)probe:deviceDescription
  /*
   * Probe, configure board and init new instance.  This method is 
   * documented in the IODevicespec sheet.
   */
{
    Mididriver *instance;
    IOEISADeviceDescription
      *devDesc = (IOEISADeviceDescription *)deviceDescription;

    IOLog("trying to probe Mididriver\n");
    if (_MididriverUnit >= MAX_UNITS) {
	IOLog("Mididriver: Too many MIDI devices installed.  Maximum allowed = %d\n",
	      MAX_UNITS);
	return NO;
    }
    instance = [self alloc];
    if (instance == nil) {
      IOLog("Can't allocate Mididriver object.\n");
      return NO;
    }
    /* Check that we have some I/O ports, mapped memory, and 
     * interrupts assigned. */
    if ([devDesc numPortRanges] < 1 || [devDesc numInterrupts] < 1) {
      IOLog("Mididriver: Num port ranges == %d. Num interrupts == %d.\n",
	    [devDesc numPortRanges],[devDesc numInterrupts]);
      [instance free]; 
      return NO;
    }
    /* Perform more device-specific validation, e.g. checking to make 
     * sure the I/O port range is large enough.  Make sure the 
     * hardware is really there. Return NO if anything is wrong. */
    
    return [instance initFromDeviceDescription:devDesc] != nil;
}

- initFromDeviceDescription:deviceDescription
{
  /*
   * Init the new instance.  This method is documented in the i386-specific
   * part of the IODirectDevice spec sheet.
   */
    int err;
    int baseIO;
    char name[80];
    const IORange *range; 
    /* 
     * If the resources specified in this driver's bundle 
     * (in /usr/Devices/Mididriver.config/*.table) are already reserved,
     * [super initFromDeviceDescription:] will return nil.
     */
    if ([super initFromDeviceDescription:deviceDescription] == nil)
    	return nil;
    range = [deviceDescription portRangeList];
    baseIO = range->start;
    dataPort = baseIO;
    statAndCmdPort = baseIO+1;
    sprintf(name, "%s%d", "Mididriver", _MididriverUnit);
    [self setName:name];
    /* Make it possible for MIG interface to find us */
    [self setUnit:_MididriverUnit];
    driverObjects[_MididriverUnit++] = self;
    [self setDeviceKind:"MIDI"]; /* Added Sept. 5, 94 */
    [self setLocation:NULL];
    [self registerDevice];
    if ((err=[self startIOThread]) != IO_R_SUCCESS) {
	IOLog("startIOThread failed: %d\n",err);
	return nil;
    }
    IOLog("%s: interrupt=%d, IO base address=0x%x\n",
        name, [deviceDescription interrupt], baseIO);
    return self; 
}


/* This really is no longer neccessary as processor speeds mean
 *  we can service interrupts fast enough via the IOThread.
 */

#define AT_INTERRUPT_LEVEL 0  /* Set to 1 to handle interrupts at true interrupt level */

#if AT_INTERRUPT_LEVEL

static void myIntHandler(void *identity, void *state, 
                         unsigned int arg)
{
  rcvInterrupt(arg);
  return;        
}

- (BOOL) getHandler:(IOEISAInterruptHandler *)handler
       level:(unsigned int *) ipl
       argument:(unsigned int *) arg
       forInterrupt:(unsigned int) localInterrupt
{
    *handler = myIntHandler;
    *ipl = IPLDEVICE;
    *arg = [self unit];
    IOLog("Mididriver: interrupt %d associated with object 0x%x\n",localInterrupt,
	  self);
    return YES;
}
#endif


/* -------------------------------------------------------------------------
 * End of MPU-401-specific code 
 * -------------------------------------------------------------------------
 */
