/* TurtleBeachMS.m by David A. Jaffe */

#import "TurtleBeachMS.h"

#define IMPLEMENTS_MONITOR_4_2
#import "DSPMKDriver.m"        /* Fake inheritance */

/* ---- Here begins where a subclass would reside if NEXTSTEP's Driver Kit
 * would allow shared abstract super-classes.  For now, it's just a
 * different category. 
 */

@implementation TurtleBeachMS (SubclassMethods)


// host port / hw control regs
#define MULTISOUND_MEMM(b) (b+0x08)// memory map reg
#define MULTISOUND_IRQM(b) (b+0x09)// irq map reg
#define MULTISOUND_DSPR(b) (b+0x0A)// dsp reset
#define MULTISOUND_PROR(b) (b+0x0B)// proteus reset
#define MULTISOUND_BLKS(b) (b+0x0C)// block(bank) select
#define MULTISOUND_WAIT(b) (b+0x0D)// extra wait state select
#define MULTISOUND_BITM(b) (b+0x0E)// bit memory bus mode: 8/16

#define MULTISOUND_R_BLRC(b) (b+0x08)// read - board level R/C timer
#define MULTISOUND_R_SPR1(b) (b+0x09)
#define MULTISOUND_R_SPR2(b) (b+0x0A)
#define MULTISOUND_R_TCL0(b) (b+0x0B)//  "   - TOPCAT chip level lsb
#define MULTISOUND_R_TCL1(b) (b+0x0C)
#define MULTISOUND_R_TCL2(b) (b+0x0D)
#define MULTISOUND_R_TCL3(b) (b+0x0E)
#define MULTISOUND_R_TCL4(b) (b+0x0F)//  "        "     "     "  msb

#define MULTISOUND_RESETON 1
#define MULTISOUND_RESETOFF 0

+(int)maxDSPCount
{
    return 1;
}

+(const char *)monitorFileName_4_2
{
    return "mkmon_A_turtlebeachms32.dsp";
}

+(const char *)monitorFileName
{
    return "mkmon_A_turtlebeachms.dsp";
}

+(const char *)waitStates
{
    return "3";
}

+(const char *)serialPortDeviceName
{
    return "TurtleBeachMS";
}

+(const char *)orchestraName
{
    return NULL;
}

// added by len
#define HPIRQ_NONE      0
#define HPIRQ_5         1
#define HPIRQ_7         2
#define HPIRQ_9         3
#define HPIRQ_10        4
#define HPIRQ_11        5
#define HPIRQ_12        6
#define HPIRQ_15        7


/* altered by len */
-resetDSP:(char)resetOn
{
    if (resetOn) {
	outb(MULTISOUND_MEMM(baseIO),0);
	outb(MULTISOUND_WAIT(baseIO),0);  /* no extra PC wait states */
	outb(MULTISOUND_BITM(baseIO),0);
	outb(MULTISOUND_DSPR(baseIO),MULTISOUND_RESETON);
    }
    else {
	unsigned int irqMap = HPIRQ_NONE;
	outb(MULTISOUND_DSPR(baseIO),MULTISOUND_RESETOFF);

	/*  MAP THE INTERRUPT;  DONE HERE SINCE TXDE GUARANTEED SET TO 1  */
	/*  NOTE:  TXDE MUST EQUAL 1, SO IT IS BEST TO CALL THIS METHOD
	    AFTER RESET DEASSERTED (SEE CHAPTER 2 OF MSOUND REFERENCE)  */
	
	/*  CONVERT IRQ TO MSOUND-DEFINED NUMBER  */
	switch (irq) {
	  case 5:  irqMap = HPIRQ_5;    break;
	  case 7:  irqMap = HPIRQ_7;    break;
	  case 9:  irqMap = HPIRQ_9;    break;
	  case 10: irqMap = HPIRQ_10;   break;
	  case 11: irqMap = HPIRQ_11;   break;
	  case 12: irqMap = HPIRQ_12;   break;
	  case 15: irqMap = HPIRQ_15;   break;
	  default: irqMap = HPIRQ_NONE; break;
	}
	
	/*  SET INTERRUPT LOGIC HIGH (TXDE MUST EQUAL 1)  */
	outb(DSPDRIVER_ICR([self unit]),0x02);
	
	/*  MAP THE MSOUND INTERRUPT BY WRITING VALUE TO THE HARDWARE   */
	outb(MULTISOUND_IRQM(baseIO),irqMap);

	/*  RESET INTERRUPT LOGIC TO LOW  */
	outb(DSPDRIVER_ICR([self unit]),0x00);
    }
    return self;
}

-resetHardware
{
    return self;
}

-setPhysicalSubUnit:(int)aSubUnit
{
    if (aSubUnit != 0)
      return nil;
    return self;
}

-(void)setPhysicalSubUnitRaw:(int)aSubUnit
{
}

+(const char *)clockRate
{
    return "40";
}

- setupFromDeviceDescription:deviceDescription
{
    return self;
}
@end


