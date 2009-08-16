//
//  $Id: SndViewP.m 3260 2005-05-14 06:48:16Z leighsmith $
//
//  Description:
//    Defines a SndView Interface Builder Plugin. 
//    Inspectors allow setting different display modes and scrolling.
//
//  Original Author: Leigh M. Smith
//
//  Copyright (c) 2008, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//

#import "SndViewIBPlugin.h"

@implementation SndViewIBPlugin

- (NSArray *) libraryNibNames 
{
    return [NSArray arrayWithObject: @"SndViewIBPluginLibrary"];
}

// For inspector, set:
// [sndView setDisplayMode: SND_SOUNDVIEW_WAVE]; // Scrolling version & non scrolling version wave view. 
// or 
// [sndView setDisplayMode: SND_SOUNDVIEW_MINMAX]; // Scrolling version min/max view.

@end
