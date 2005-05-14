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

#import <InterfaceBuilder/InterfaceBuilder.h>
#import <SndKit/SndKit.h>

@interface SndViewP : IBPalette
{
    IBOutlet SndView *view1;
    IBOutlet SndView *view2;
    IBOutlet SndView *view3;
}

- (void) finishInstantiate;

@end
