/* ArielPC56D.m by David A. Jaffe */

#import "ArielPC56D.h"
#import "DSPMKDriver.m"        /* Fake inheritance */

/* ---- Here begins where a subclass would reside if NEXTSTEP's Driver Kit
 * would allow shared abstract super-classes.  For now, it's just a
 * different category. 
 */

@implementation ArielPC56D (SubclassMethods)

#define ARIELPC56D_RESET_ON(b) (b+0xC000)
#define ARIELPC56D_RESET_OFF(b) (b+0x8000)
#define ARIELPC56D_SPLIT_MEMORY_MAP(b) (b+0xA000)
#define ARIELPC56D_NORMAL_MEMORY_MAP(b) (b+0x8000)

+(int)maxDSPCount
{
    return 1;
}

+(const char *)monitorFileName
{
    return "mkmon_A_arielpc56d.dsp";
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
    return "ArielPC56D";
}

-resetDSP:(char)resetOn
{
    if (resetOn) {
	outb(ARIELPC56D_RESET_ON(baseIO),0);
    }
    else {
	outb(ARIELPC56D_RESET_OFF(baseIO),0);
	outb(ARIELPC56D_SPLIT_MEMORY_MAP(baseIO),0);
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
    /* 
     * The Ariel card has two versions, one 27 Mhz., the other 33 Mhz. 
     * We should (somehow) sense which one we have and do the right thing.
     * Right now, we take the conservative path. FIXME
     */
    return "27";
}

- setupFromDeviceDescription:deviceDescription
{
    return self;
}
@end




