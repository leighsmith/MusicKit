#ifndef __MK_MeterView_H___
#define __MK_MeterView_H___
#import <appkit/View.h>

@interface MeterView:View
{
    float currentValue;
	float lastValue;
    float backgroundGray;
    float meterGray;
}

- initFrame:(const NXRect *)frameRect;
- setBackgroundGray:(float)aValue;
- setMeterGray:(float)aValue;
- setFloatValue:(float)aValue;
- setFloatValue:(float)aValue withDelay:(double)aDelay;
- takeFloatValueFrom:sender;
- drawSelf:(const NXRect *)rects :(int)rectCount;

@end
#endif
