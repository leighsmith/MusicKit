#ifndef __MK_MySlider_H___
#define __MK_MySlider_H___
#import <AppKit/NSSlider.h>

@interface MySlider:NSSlider
{
    double returnValue;
}

- setReturnValue:(double)aValue;

@end


#endif
