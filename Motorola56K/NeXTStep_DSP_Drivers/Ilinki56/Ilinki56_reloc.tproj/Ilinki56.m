/* Ilinki56.m by David A. Jaffe */

#import "Ilinki56.h"
#import "DSPMKDriver.m"        /* Fake inheritance */

/* ---- Here begins where a subclass would reside if NEXTSTEP's Driver Kit
 * would allow shared abstract super-classes.  For now, it's just a
 * different category. 
 */

@implementation Ilinki56 (SubclassMethods)

/* Here's some good code to probe for a DSP.  Should work it in eventually.
   FIXME
   // CVR, ISR and IVR must hold default values after reset.
   // if these values are not correct, the reset failed or
   // no board is present
   if( inportb(Ilinki56_base+1) != 0x12 ) return FAILURE;
   if( inportb(Ilinki56_base+2) != 0x06 ) return FAILURE;
   if( inportb(Ilinki56_base+3) != 0x0f ) return FAILURE;
*/

+(int)maxDSPCount
{
    return 1;
}

+(const char *)monitorFileName
{
    return "mkmon_A_ilinki56.dsp";
}

+(const char *)waitStates
{
    return "0";
}

+(const char *)serialPortDeviceName
{
    return "NeXT";
}

+(const char *)orchestraName
{
    return "Ilinki56";
}

#define Ilinki56_RESET_ON(b) (b | (1 << 14))  
#define Ilinki56_RESET_OFF(b) (b+0)
#define Ilinki56_ENABLE_MEMORY_PART1(b) (b | (1 << 13))
#define Ilinki56_ENABLE_MEMORY_PART2(b) (b+0)

-resetDSP:(char)resetOn
{
    if (resetOn) {
	outb(Ilinki56_RESET_ON(baseIO),0);
    }
    else {
	outb(Ilinki56_RESET_OFF(baseIO),0);
	IOSleep(1);
	outb(Ilinki56_ENABLE_MEMORY_PART1(baseIO),0);
	IOSleep(1);
	outb(Ilinki56_ENABLE_MEMORY_PART2(baseIO),0);
	IOSleep(1);
	/* Next, need to reset HI, but this is (presumably)
	   done by caller. */
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
    return "33";
}

- setupFromDeviceDescription:deviceDescription
{
    return self;
}
@end




