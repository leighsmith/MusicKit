#ifndef __MK_TurtleBeachFiji_H___
#define __MK_TurtleBeachFiji_H___
#import <driverkit/i386/directDevice.h>

#define DSPMKDriver TurtleBeachFiji /* Fake inheritance */
#import "DSPMKDriver.h"

/* Methods that would be eventually implemented by a subclass */
@interface TurtleBeachFiji (SubclassMethods)
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

