#import "SndViewP.h"
#import <SndKit/SndKit.h>

@implementation SndViewP
- (void)finishInstantiate
{	
    [(SndView *)view2 setDisplayMode: NX_SOUNDVIEW_WAVE];
    [(SndView *)view3 setDisplayMode: NX_SOUNDVIEW_MINMAX];
}


@end
