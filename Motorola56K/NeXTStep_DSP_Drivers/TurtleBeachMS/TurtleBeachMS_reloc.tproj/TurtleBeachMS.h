#ifndef __MK_TurtleBeachMS_H___
#define __MK_TurtleBeachMS_H___
#import <driverkit/i386/directDevice.h>

#define DSPMKDriver TurtleBeachMS /* Fake inheritance */
#import "DSPMKDriver.h"

/* Methods that would be eventually implemented by a subclass */
@interface TurtleBeachMS (SubclassMethods)
+(const char *)monitorFileName; 
+(const char *)monitorFileName_4_2; 
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

