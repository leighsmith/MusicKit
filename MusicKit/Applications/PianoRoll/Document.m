/* $Id$ */

#import <math.h>
#import "Document.h"
#import "PartView.h"
#import <AppKit/NSScrollView.h>

#import <stdlib.h>
#import <string.h>
#define MAXFREQ 7040
#define DEFAULT_FREQSCALE 64

// this should become part of an NSDocument approach.

@implementation Document

- initScore: (MKScore *) aScore
{
	NSRect aRect;
	NSSize aSize, cSize;
	id bigScroll;
	
	[super init];
	theScore = [aScore retain];
	
	cSize.width = 500.0;
	cSize.height = log(MAXFREQ)*DEFAULT_FREQSCALE/2;
	aSize = [NSScrollView frameSizeForContentSize:cSize hasHorizontalScroller:YES hasVerticalScroller:YES borderType:NSNoBorder];
	docWindow = [NSWindow alloc];
	aRect = NSMakeRect(400.0, 400.0, aSize.width, aSize.height);
	[docWindow initWithContentRect:aRect styleMask:NSResizableWindowMask|(NSMiniaturizableWindowMask |
							NSClosableWindowMask) backing:NSBackingStoreBuffered defer:YES];
	[docWindow setDelegate:self];

	bigScroll = [[NSScrollView alloc] init];
	[bigScroll setHasHorizontalScroller:YES];
	[bigScroll setHasVerticalScroller:YES];
	[docWindow setContentView:bigScroll];
	
	partView = [[PartView alloc] initScore:theScore];
	[bigScroll setDocumentView:partView];
	[bigScroll setBackgroundColor:[NSColor darkGrayColor]];
	
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

	cSize.width = 500.0;
	cSize.height = log(MAXFREQ)*[[[sender contentView] documentView] freqScale];
	aSize = [NSScrollView frameSizeForContentSize:cSize hasHorizontalScroller:YES hasVerticalScroller:YES borderType:NSNoBorder];
	bRect = NSMakeRect(0.0, 0.0, aSize.width, aSize.height);
	aRect = [NSWindow frameRectForContentRect:bRect styleMask:NSResizableWindowMask];
	if (frameSize.height > aRect.size.height)
		frameSize.height = aRect.size.height;
	return frameSize;
}

@end
