#ifndef __MK_Ilinki56_H___
#define __MK_Ilinki56_H___
#import <driverkit/i386/directDevice.h>

#define DSPMKDriver Ilinki56 /* Fake inheritance */
#import "DSPMKDriver.h"

/* Methods that would be eventually implemented by a subclass */
@interface Ilinki56 (SubclassMethods)
+(const char *)monitorFileName; 
+(const char *)serialPortDeviceName;
+(const char *)orchestraName;
+(const char *)waitStates;
-resetDSP:(char)resetOn;
-resetHardware;
-setPhysicalSubUnit:(int)aSubUnit;
+(int)maxDSPCount;
+(const char *)clockRate;
- setupFromDeviceDescription:deviceDescription;
@end

#endif

