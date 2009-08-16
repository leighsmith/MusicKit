/* TurtleBeachMS.m by David A. Jaffe */

#import "TurtleBeachFiji.h"
#import "DSPMKDriver.m"        /* Fake inheritance */

/* ---- Here begins where a subclass would reside if NEXTSTEP's Driver Kit
 * would allow shared abstract super-classes.  For now, it's just a
 * different category. 
 */

@implementation TurtleBeachFiji (SubclassMethods)

#import "pincfg.c"

+(int)maxDSPCount
{
    return 1;
}

+(const char *)monitorFileName
{
    return "mkmon_A_turtlebeachpin.dsp";
}

+(const char *)waitStates
{
    return "0";
}

+(const char *)serialPortDeviceName
{
    return "TurtleBeachFiji";
}

+(const char *)orchestraName
{
    return NULL;
}

#define RESET_ON 1
#define RESET_OFF 2
#define BLOCK_SELECT_SHARED (RESET_OFF)
#define BLOCK_SELECT_SEPARATE (1+RESET_OFF)

-resetDSP:(char)resetOn
{
    if (resetOn) {  
	outb(baseIO+4,RESET_ON);
    }
    else {
	long timeOutCount = 40000;
	outb(baseIO+4, RESET_OFF);
	while (timeOutCount-- !=0) {
		IOSleep(1);
		if (inb(baseIO+1) == 0x12) { /* CVR */
			outb(baseIO+4, BLOCK_SELECT_SHARED);
			return self;
		}
	}
	return nil;
    }
    return self;
}

#define DEFAULT_CONFIGURATION_PORT 0x250 

-resetHardware
{
    /* configure plug n play registers */
    static int beenHere = 0;
    if (beenHere) 
       return self;
    beenHere = 1;
    if (configFiji(configurationPort,baseIO,irq,0) == EC_NOERR)
       return self;
    else return nil;
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

-setupFromDeviceDescription:deviceDescription {
  const IORange *range = [deviceDescription portRangeList];
  if ([deviceDescription numPortRanges] < 2)
	configurationPort = DEFAULT_CONFIGURATION_PORT;
  else {
	range++;
  	configurationPort = range->start;
  }
  return self;
}

@end


