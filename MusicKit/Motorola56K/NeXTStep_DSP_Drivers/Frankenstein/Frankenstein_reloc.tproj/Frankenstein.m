/* Frankenstein.m */

#import "Frankenstein.h"
#import "DSPMKDriver.m"        /* Fake inheritance */

/* ---- Here begins where a subclass would reside if NEXTSTEP's Driver Kit
 * would allow shared abstract super-classes.  For now, it's just a
 * different category. 
 */

@implementation Frankenstein (SubclassMethods)

#define FRANK_ICR (baseIO)
#define FRANK_DATA_HIGH (baseIO+5)
#define FRANK_DATA_MED (baseIO+6)
#define FRANK_DATA_LOW (baseIO+7)
#define FRANK_DSP_SELECT (baseIO+8)
#define FRANK_CONTROL (baseIO+11)
#define FRANK_RESET_0_7 (baseIO + 9)
#define FRANK_RESET_8_15 (baseIO + 10)

/* EPROM Commands */
#define BOOT_FROM_HOST_HIGH 6
#define BOOT_FROM_HOST_MED 0
#define BOOT_FROM_HOST_LOW 0

/* This is used for detecting the Coctail Frank */
#define READBACK_HIGH 5
#define READBACK_MED 15 /* Anything, actually */
#define READBACK_LOW 27

/* Control commands */
#define RESET_HARDWARE_MESSAGE 0x80

// #define MAX_SUBUNITS 16
#define MAX_SUBUNITS 8
#warning MAX_SUBUNITS==8 to work around sensing bug

+(int)maxDSPCount
{
    return MAX_SUBUNITS;
}

+(const char *)monitorFileName
{
    return "mkmon_A_frankenstein.dsp";
}

+(const char *)waitStates
{
    return "0";
}

+(const char *)serialPortDeviceName
{
    return "Frankenstein";  
}

+(const char *)orchestraName
{
    return NULL;
}

#define DO_RESET 1 /* Set to 0 when debugging with the "once port" */

-resetDSP:(char)resetOn
{
    unsigned char b,currentState;
    int ioPort = (subUnit < 8) ? FRANK_RESET_0_7 : FRANK_RESET_8_15;
    b = (1 << (subUnit % 8));
    currentState = inb(ioPort);
    if (resetOn) {
      currentState &= ~b;
#if DO_RESET
      outb(ioPort,currentState);
#endif
    }
    else {
      currentState |= b;
#if DO_RESET
      outb(ioPort,currentState);
#endif
      IOSleep(100);  /* was 1000 */
      outb(FRANK_DSP_SELECT,subUnit);
      outb(FRANK_DATA_HIGH,BOOT_FROM_HOST_HIGH);
      outb(FRANK_DATA_MED,BOOT_FROM_HOST_MED);
      outb(FRANK_DATA_LOW,BOOT_FROM_HOST_LOW);
      IOSleep(100);  /* was 1000 */
    }
    return self;
}

-resetHardware
  /* This is the first thing to happen */
{
    outb(FRANK_CONTROL,RESET_HARDWARE_MESSAGE);
    outb(FRANK_RESET_0_7,0xFF);  /* Take dsps out of reset */
    outb(FRANK_RESET_8_15,0xFF); 
    return self;
}

-setPhysicalSubUnit:(int)aSubUnit
{
    subUnit = aSubUnit;
    outb(FRANK_DSP_SELECT,aSubUnit);
    VPRINTF("subUnit = %d\n",subUnit);
    return self;
}

-(void)setPhysicalSubUnitRaw:(int)aSubUnit
{
    outb(FRANK_DSP_SELECT,aSubUnit);
}

+(const char *)clockRate
{
    return "40";
}

-(BOOL)_testDSP:(int)i {
    unsigned char senseByte;
    [self setPhysicalSubUnit:i];
    [self resetDSP:1];
    IOSleep(10);
    [self resetDSP:0];
    IOSleep(10);
    outb(FRANK_ICR,8);
    IOSleep(1); /* Shouldn't be needed, but what the hell */
    senseByte = inb(FRANK_ICR);
    return ((senseByte & 0x18) == (unsigned char)8);
}  
      
-(int)senseDSPs {
    int i;
    actualDSPCount = 0;
    i = 0;
    if ([self _testDSP:i])
      subUnitMap[actualDSPCount++] = i;
    else return 0;
    /* Now we write a turd to dsp 0 */
    outb(FRANK_DATA_HIGH,READBACK_HIGH);
    outb(FRANK_DATA_MED,READBACK_MED);
    outb(FRANK_DATA_LOW,READBACK_LOW);
    i = 1;
    if ([self _testDSP:i]) {
	/* We think we have a DSP */
	if ((inb(FRANK_DATA_MED) == READBACK_MED) &&
	    (inb(FRANK_DATA_LOW) == READBACK_LOW)) {
	    /* We're being fooled by the coctail frank. */
	    return 1;
	}
	subUnitMap[actualDSPCount++] = i;
    }
    for (i=2; i<maxDSPCount; i++) 
      if ([self _testDSP:i])
	subUnitMap[actualDSPCount++] = i;
    return actualDSPCount;
}

- setupFromDeviceDescription:deviceDescription
{
    return self;
}
@end



/*

Actually, no "locks" are needed to manage bi-directional traffic if we
assume that the driver is running on a single processor (a safe
assumption for now). Here's how:

Whenever we poll the DSPs, we do this:

1. save current value of "current DSP"
2. poll DSPs, reading back data if necessary
3. restore current value of "current DSP"

This will work as long as there is never any IOSleep() calls in this function.

However, we may sleep for a little while waiting for the DSP.  So
whenever we sleep we have to restore the current DSP, then set it
again after the sleep.

This is what I'm going to implement.  It favors to-DSP traffic.

The screw-case (in terms of performance) is while we're reading back
an array (or write data) from the DSP.  In this case we repeatedly do
this:

await RXDF
read data

If the Pentium is faster than the DSP, then we'll end up doing a sleep
in await RXDF.  This will cause the above to be much slower:

  await RXDF = read RXDF, set current DSP, sleep, set current DSP
  read data

So we've effectively doubled the cost of reading the DSP (we've
increased the traffic to Frank by a factor of 2).

But we can get around this by putting an IOWait() (a buzz loop) to
slow down the Pentium so it doesn't have to do an IOSleep() most of
the time.


In order to implement this, we will to change interruptOccurred: and
otherOccurred: and the reading methods.
 
*/
