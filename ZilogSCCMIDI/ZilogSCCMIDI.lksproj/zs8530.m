// $Id$
// Zilog 8530 serial port code, assuming memory map access
// Extensive conversion from old NeXT hardware to Macintosh PPC serial port hardware
// by Leigh Smith <leigh@leighsmith.com>, <leigh@tomandandy.com>, <leigh@cs.uwa.edu.au>
// $Log$
// Revision 1.2  2000/02/29 01:01:19  leigh
// Added G4 OpenFirmware test
//

#define ARCH_PRIVATE

#import "zsreg.h"  // our own kludged version

#define CHECK_INPUT_STATUS 1     // Set to 0 to skip check for hw overflow
#define NON_RECEIVING 0	         // Set to 1 to disable reception while PPC version is buggy
#define G4_OPENFIRMWARE_BUG 1    // Set to 1 if escc-legacy/ch-a is found before escc/ch-a by the DriverKit.

/* Forward declarations */
static int rcvInterrupt (short unit);
static int xmtInterrupt (short unit);
//static int stsInterrupt (short unit);

static boolean_t deviceInit(short unit) {
    int reset;
    struct zsdevice *zsaddr;

    midi_slog("[deviceInit ");

    if (unit == 0) {
	reset = WR9_RESETA;
    }
    else {
	reset = WR9_RESETB;
    }
    zsaddr = var.u[unit].addr = (struct zsdevice *) driverObjects[unit]->zsaddr;

    midi_log("zsaddr = 0x%x...\n", zsaddr, 2, 3, 4, 5);

    /* Reset appropriate channel */
    ZSWRITE(zsaddr, 9, reset);            
    IODelay(10);	// FIXME, is this necessary? see 4.1.10 in ZS8530 man

    /* Don't respond to IACK (Interrupt Acknowledge). 
     * Enable interrupts globally (master switch) */ 
    ZSWRITE(zsaddr, 9, WR9_NV | WR9_MIE); 

    /* Set transmit and receive coding option to NRZ mode: 1 high/0 low */
    ZSWRITE(zsaddr, 10, WR10_NRZ);        

    // Set transmit and receive clocks to TRxC fed from 1MHz crystal
    // via HSKi in MIDI interface.
    ZSWRITE(zsaddr, 11, WR11_TXCLKTRXC | WR11_RXCLKTRXC); 

    /* No external/status interrupts (such as DCD or break) enabled. */
    ZSWRITE(zsaddr, 15, 0);

    /* Reset error bits. */
    ZSWRITE(zsaddr, 0, WR0_RESET); 

    /* Reenable external/status interrupts. */
    zsaddr->zs_ctrl = WR0_RESET_STAT;
    IODelay(1);

    /* Reset pending Tx interrupt. */
    zsaddr->zs_ctrl = WR0_RESETTXPEND;

    /* Set clock mode to 32 x the data rate = 31250 baud
     * Asynchronous mode, with 1 stop bit per character. No parity.
     */
    ZSWRITE(zsaddr, 4, WR4_X32CLOCK | WR4_STOP1); 

    /* Set number of bits per character to 8. */
    ZSWRITE(zsaddr, 3, WR3_RX8);          

    /* Transmit parameters: 
     * 8 bit characters.
     * DTR (data terminal ready): controls DTR pin (see man)
     * RTS (request to send): controls RTS pin (see man)
     */
    ZSWRITE(zsaddr, 5, WR5_TX8 | WR5_RTS | WR5_DTR);

    // baud rate generator is disabled since we simply divide down the TRxC
    // We disable baud rate and clear all miscellaneous control bits.
    ZSWRITE(zsaddr, 14, 0);

    /* Enable receive of 8 bit bytes. */
    ZSWRITE(zsaddr, 3, WR3_RX8 | WR3_RXENABLE); 

    /* Enable transmit of 8 bit bytes, RTS. */
    ZSWRITE(zsaddr, 5, WR5_TX8 | WR5_RTS | WR5_TXENABLE);
    var.u[unit].claimed = TRUE;
    midi_slog("...deviceInit]\n");
    return TRUE;
}

static void deviceReset(short unit) {
    volatile struct zsdevice *zsaddr = var.u[unit].addr;

    [driverObjects[unit] disableAllInterrupts];

    ZSWRITE(zsaddr, 5, WR5_TX8 | WR5_RTS);

    /* Disable all interrupts. */ 
    ZSWRITE(zsaddr, 1, 0);

    var.u[unit].rcvEnabled = FALSE;
    var.u[unit].addr = (struct zsdevice *)0;
    var.u[unit].claimed = FALSE;
    midi_log("reset device\n",1,2,3,4,5);
}

static void deviceEnable(short unit) {
    volatile struct zsdevice *zsaddr = var.u[unit].addr;
    var.u[unit].rcvEnabled = TRUE;

    /* Enable interrupts on all receive characters or special condition.
     * Enable transmit interrupts. 
     * No External/status interrupts.
     */
#if NON_RECEIVING
    ZSWRITE(zsaddr, 1, WR1_TXIE); // this ensures we never get a receive.
#else
    ZSWRITE(zsaddr, 1, WR1_RXALLIE | WR1_TXIE);
#endif
    [driverObjects[unit] enableAllInterrupts];
}

static void deviceStartXmt(int now,short unit) {
    /* This is called by the driver to start a transmission. */
    unsigned char event = var.u[unit].xmtFifo[var.u[unit].xmtOutInd].byte;
    int eventTime = 
      var.u[unit].xmtFifo[var.u[unit].xmtOutInd].time;
    midi_slog("[deviceStartXmt \n");
    if (isFlushing(unit) || 
	(var.clockRunning && timeLEQ(eventTime,now))) {
 	var.u[unit].xmtOutInd = bumpIndex(var.u[unit].xmtOutInd,
					  XMT_FIFO_SIZE);
	midi_odatalog("o %x\n",event,2,3,4,5);
	var.u[unit].xmtInProgress = TRUE;
	{
	  volatile struct zsdevice *zsaddr = var.u[unit].addr;
	  ZSWRITE(zsaddr, 8, event);
	}
	checkQueueNotify(unit);
	checkFlushing(unit);
    }
    else
      requestWakeup(eventTime);
    midi_slog("...deviceStartXmt ]\n");
}

static int xmtInterrupt (short unit) {
    /* This is called by the Zylog chip to tell us a transmission finished
       and it's safe to begin another. */
    volatile struct zsdevice *zsaddr = var.u[unit].addr;
    midi_slog("[xmtInterrupt\n");
    IODelay(1);
    if (var.owner && var.u[unit].xmtInInd != var.u[unit].xmtOutInd) {
	unsigned char event = var.u[unit].xmtFifo[var.u[unit].xmtOutInd].byte;
	int eventTime = var.u[unit].xmtFifo[var.u[unit].xmtOutInd].time;
	if (isFlushing(unit) || (var.clockRunning && timeLEQ(eventTime,getCurrentTime()))) {
            midi_odatalog("o %x fl %d ck %d xip %d\n", 		
		event,isFlushing(unit),var.clockRunning,var.u[unit].xmtInProgress,5);
	    var.u[unit].xmtOutInd = bumpIndex(var.u[unit].xmtOutInd, XMT_FIFO_SIZE);
	    ZSWRITE(zsaddr, 8, event);
	    checkQueueNotify(unit);
	    checkFlushing(unit);
	    midi_slog("xmtInterrupt 1]\n");
	    return 0;
	}
	else
	    requestWakeup(eventTime);
    }
    var.u[unit].xmtInProgress = FALSE;
    ZSWRITE(zsaddr, 0, WR0_RESETTXPEND); // this is necessary to play more than one note
    midi_slog("xmtInterrupt 2]\n");
    return 0;
}

/* This is called by the Zylog chip when data is ready */
static int rcvInterrupt (short unit) {
    volatile struct zsdevice *zsaddr = var.u[unit].addr;
    register int rr0;
    register int rr1;
    int now;
    unsigned char data;
    int newInd;

    now = getCurrentTime();
    midi_slog("[rcvInterrupt\n");
#if 1
    ZSREAD(zsaddr, rr0, 0);
    midi_ilog("initial rr0 = %x\n", rr0, 2, 3, 4, 5);
    while (rr0 & RR0_RXAVAIL) { /* While data in zs fifo */
#if CHECK_INPUT_STATUS
      ZSREAD(zsaddr, rr1, 1);
      midi_ilog("rr1 = %x\n", rr1, 2, 3, 4, 5);
#endif CHECK_INPUT_STATUS
      ZSREAD(zsaddr, data, 8);	// grab the data received.
#if CHECK_INPUT_STATUS
      if (rr1 & RR1_RXOVER) { // We didn't read it fast enough (our fault).
	IODelay(1);
	zsaddr->zs_ctrl = WR0_RESET; /* Reset error condition. */
	midi_log("***midi rxover***\n",1, 2, 3, 4, 5);
	PRINTF("MIDI driver hardware overrun\n");
      }
      /* If we ever enabled parity, we could check here. */
      if(rr1 & RR1_FRAME) {  	    /* Framing error? */
	IODelay(1);
	midi_log("***midi framing error***\n",1, 2, 3, 4, 5);
	PRINTF("MIDI driver hardware framing error\n");
	continue;	/* Junk character */
      }
#endif CHECK_INPUT_STATUS
      midi_idatalog("i %x\n",data,2,3,4,5);
#if 1 // no scheduling only hardware
      if (!shouldFilter(data,unit) && var.rcvDataThread) { // check we are doing things right.
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
#endif
      ZSREAD(zsaddr, rr0, 0);
      midi_ilog("final rr0 = %x\n", rr0, 2, 3, 4, 5);
// ZSWRITE(zsaddr, 1, WR1_RXALLIE | WR1_TXIE); // kludge in a fix to a disabled TX interrupt -nah NOP
    }
#else
    /* ultra minimal read and abandon */
    ZSREAD(zsaddr, rr0, 0);
    midi_ilog("initial rr0 = %x\n", rr0, 2, 3, 4, 5);
//    ZSREAD(zsaddr, rr1, 1);
//    midi_ilog("data recvd rr1 = %x\n", rr1, 2, 3, 4, 5);
    ZSREAD(zsaddr, data, 8);	// grab the data received.
    midi_idatalog("i %x\n",data,2,3,4,5);
#endif
    midi_slog("...rcvInterrupt]\n");
    return 0;
}

// Receives both transmit and receive interrupts, so we determine the direction and invoke the appropriate function.
- (void) interruptOccurred
{
    int unit;
    int rr3;
    int rr2;
    int txip, rxip;

    // FIXME we must always read from the A channel register 
    // to check for both channels.
    unit = [self unit];
    if(unit == 0) {
      txip = RR3_A_TXIP;
      rxip = RR3_A_RXIP;
    }
    else {
      txip = RR3_B_TXIP;
      rxip = RR3_B_RXIP;
    }
    ZSREAD(zsaddr, rr3, 3);	// check if the interrupt is TX or RX
    midi_log("rr3 = %x\n", rr3, 2, 3, 4, 5);

    // RR2 Channel B returns the status bits
    ZSREAD(zsaddr, rr2, 2); // this isn't right ch-a = 13020 ch-b = 13000
    midi_log("Chan B rr2 = %x\n",rr2,2,3,4,5);

    if(rr3 & rxip) {
      rcvInterrupt(unit);
    }
    if(rr3 & txip) {
      xmtInterrupt(unit);
    }
    [self enableAllInterrupts];
}


#if 0
static int stsInterrupt(short unit) {
    /* This can currently never happen, since we haven't enabled 
     * WR1_EXIE (status/external interrupt enabled). */
    return 0;
}
#endif

+ (BOOL)probe: (IOPPCDeviceDescription *) deviceDescription
  /*
   * Probe, configure board and init new instance.  This method is 
   * documented in the IODevice spec sheet.
   */
{
    Mididriver *instance;

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

    /* Check that we have some channels, and interrupts assigned. */
    //    if ([devDesc numRanges] < 1 || [devDesc numInterrupts] < 1) {
    // somehow this causes a kernel panic
    //IOLog("Mididriver: Number of channels == %d, number of interrupts == %d, number of Memory Ranges == %d.\n",
    //      [deviceDescription numChannels],[deviceDescription numInterrupts],[deviceDescription numMemoryRanges]);
    //  [instance free]; 
    //  return NO;
    //}
    /* Perform more device-specific validation, e.g. checking to make 
     * sure the I/O port range is large enough.  Make sure the 
     * hardware is really there. Return NO if anything is wrong. */
    
    return [instance initFromDeviceDescription: deviceDescription] != nil;
}

// Init the new instance.
- initFromDeviceDescription:(IOPPCDeviceDescription *) deviceDescription
{
    int err;
    unsigned int baseMem;
    char name[80];
    const IORange *range; 

    /* 
     * If the resources specified in this driver's bundle 
     * (in {Default,Instance*}.table) are already reserved,
     * [super initFromDeviceDescription:] will return nil.
     */
    if ([super initFromDeviceDescription:deviceDescription] == nil)
    	return nil;

    range = [deviceDescription memoryRangeList];
    IOLog("number of memory ranges = %d\n", [deviceDescription numMemoryRanges]);
    baseMem = range->start;

#if G4_OPENFIRMWARE_BUG
    // This is a horrible hack to work around the PowerMac G4 OpenFirmware and DriverKit bug
    // which conflagrates to have a escc-legacy chip be chosen by the DriverKit (matching ch-a in Default.table) 
    // as the first Mididriver instead of the legitimite escc chip. Since there seems no way to change the order
    // of search in the DriverKit, nor the device name escc-legacy/ch-a, we have to check a hardwired address
    // and if found, reject the driver load. Any slight variation in the firmware address will cause this to break.
    // Hopefully that variation will be to improve the DriverKit...fat chance...
    if((baseMem & 0xFFFF) == 0x2004)
	return nil;
#warning Checking for G4 OpenFirmware bug
#endif

    zsaddr = (struct zsdevice *) baseMem;
    // determine zsaddrB from deviceDescription
    sprintf(name, "%s%d", "Mididriver", _MididriverUnit);
    [self setName:name];

    /* Make it possible for MIG interface to find us */
    [self setUnit:_MididriverUnit];
    driverObjects[_MididriverUnit++] = self;
    [self setDeviceKind:"MIDI"];
    [self setLocation:NULL];
    [self registerDevice];
    if ((err=[self startIOThread]) != IO_R_SUCCESS) {
	IOLog("%s: startIOThread failed: %d\n", name, err);
	return nil;
    }
    IOLog("%s: interrupt=%d, base address=0x%x %s\n",
          name, [deviceDescription interrupt], baseMem,
#if NON_RECEIVING
	"(non-receiving)");
#warning Non-receiving version.
#else
	"");
#endif
    //IOLog("range->size = %d\n", range->size);
    return self; 
}
