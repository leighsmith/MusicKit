#ifndef __MK_ArielPC56D_H___
#define __MK_ArielPC56D_H___
#import <driverkit/i386/directDevice.h>

#define DSPMKDriver ArielPC56D /* Fake inheritance */
#import "DSPMKDriver.h"

/* Methods that would be eventually implemented by a subclass */
@interface ArielPC56D (SubclassMethods)
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

