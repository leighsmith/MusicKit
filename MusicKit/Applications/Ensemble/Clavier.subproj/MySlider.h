#ifndef __MK_MySlider_H___
#define __MK_MySlider_H___
#import <AppKit/Slider.h>

@interface MySlider:Slider
{
    double returnValue;
}

- setReturnValue:(double)aValue;

@end


#endif
