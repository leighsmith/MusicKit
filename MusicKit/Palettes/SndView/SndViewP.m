#import "SndViewP.h"
#import <SndKit/SndKit.h>

@implementation SndViewP
- (void)finishInstantiate
{	
    [view2 setDisplayMode: NX_SOUNDVIEW_WAVE];
    [view3 setDisplayMode: NX_SOUNDVIEW_MINMAX];
}


@end
