/* Slider which snaps back to a settable value when the mouse goes up */

#import "MySliderCell.h"
#import "MySlider.h"

@implementation MySliderCell
{}

- (BOOL)trackMouse:(NXEvent *)theEvent
    inRect:(const NXRect *)cellFrame
    ofView:controlView
    /* When finished tracking, snap back to a preset value. */
{
    BOOL retval;
    retval = [super trackMouse:theEvent inRect:cellFrame ofView:controlView];
    [self setDoubleValue:returnValue];
    [controlView sendAction:action to:target];
    return retval;
}

- setReturnValue:(double)aValue
{
    returnValue = aValue;
    return self;
}

@end

