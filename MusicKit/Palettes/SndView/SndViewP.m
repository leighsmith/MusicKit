#import "SndViewP.h"

@implementation SndViewP

- (void) finishInstantiate
{
    // NSLog(@"finishInstantiate called\n");
    [view1 setDisplayMode: SND_SOUNDVIEW_WAVE]; // Non scrolling version.
    [view2 setDisplayMode: SND_SOUNDVIEW_WAVE]; // Scrolling version wave view.
    [view3 setDisplayMode: SND_SOUNDVIEW_MINMAX]; // Scrolling version min/max view.
}

@end
