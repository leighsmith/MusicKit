/* $Id$ */

#import <math.h>
#import "Document.h"
#import "PartView.h"
#import <AppKit/NSScrollView.h>

#import <stdlib.h>
#import <string.h>

// this should become part of an NSDocument approach.

@implementation Document

- initWithScore: (MKScore *) aScore
{
    [super init];
    theScore = [aScore retain];
    
    [NSBundle loadNibNamed: @"Score" owner: self];
    [partView setScore: theScore];
    [docWindow makeKeyAndOrderFront:self];
    return self;
}

- (void) dealloc
{
    [theScore release];
    [partView release];
}

- partView
{
    return partView;
}

- (NSWindow *) docWindow
{
    return docWindow;
}

- setName:(NSString *)theName
{
    [name release];
    name = [theName copy];
    return self;
}

- (NSString *)whatName
{
    return name;
}

- whatScore
{
	return theScore;
}

- (BOOL)isCurrent
{
	return current;
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    current = YES;
}

- (void)windowDidResignMain:(NSNotification *)notification
{
    current = NO;
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{ 
	NSSize aSize, cSize;
	NSRect aRect, bRect;
        PartView *pv = [[sender contentView] viewWithTag:1];

	cSize.width = 500.0;
	cSize.height = log(MAXFREQ) * 1.6 * [pv freqScale];
	aSize = [NSScrollView frameSizeForContentSize:cSize hasHorizontalScroller:YES hasVerticalScroller:YES borderType:NSNoBorder];
	bRect = NSMakeRect(0.0, 0.0, aSize.width, aSize.height);
	aRect = [NSWindow frameRectForContentRect:bRect styleMask:NSResizableWindowMask];
	if (frameSize.height > aRect.size.height)
		frameSize.height = aRect.size.height;
	return frameSize;
}

@end
