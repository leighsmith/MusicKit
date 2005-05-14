//
//  $Id$
//
//  Description:
//    Creates three prototype SndViews with different display modes and scrolling.
//
//  Original Author: Stephen Brandon
//
//  Copyright (c) 2000, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//

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
