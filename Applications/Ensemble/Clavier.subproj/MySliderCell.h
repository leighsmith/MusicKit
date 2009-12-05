#ifndef __MK_MySliderCell_H___
#define __MK_MySliderCell_H___
#import <AppKit/NSSliderCell.h>

@interface MySliderCell:NSSliderCell
{
    double returnValue;
}

- (void) setReturnValue:(double)aValue;

@end


#endif
