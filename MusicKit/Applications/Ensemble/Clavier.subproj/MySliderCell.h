#ifndef __MK_MySliderCell_H___
#define __MK_MySliderCell_H___
#import <appkit/SliderCell.h>

@interface MySliderCell:SliderCell
{
    double returnValue;
}

- setReturnValue:(double)aValue;

@end


#endif
