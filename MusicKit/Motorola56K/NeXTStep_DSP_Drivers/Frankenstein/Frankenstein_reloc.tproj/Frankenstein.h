#ifndef __MK_Frankenstein_H___
#define __MK_Frankenstein_H___
#import <driverkit/i386/directDevice.h>

#define OVERRIDE_DEFAULT_SENSING
#define DSPMKDriver Frankenstein /* Fake inheritance */
#import "DSPMKDriver.h"

/* Methods that would be eventually implemented by a subclass */
@interface Frankenstein (SubclassMethods)
+(const char *)monitorFileName; 
+(const char *)serialPortDeviceName;
+(const char *)orchestraName;
+(const char *)waitStates;
-resetDSP:(char)resetOn;
-resetHardware;
-setPhysicalSubUnit:(int)aSubUnit;
+(int)maxDSPCount;
+(const char *)clockRate;
-(int)senseDSPs;
- setupFromDeviceDescription:deviceDescription;
@end

#endif


