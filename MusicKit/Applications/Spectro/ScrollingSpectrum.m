
#import "ScrollingSpectrum.h"
#import "SpectrumView.h"

#import <AppKit/NSApplication.h>
#import <AppKit/NSCursor.h>


@implementation ScrollingSpectrum

- initWithFrame:(NSRect)theFrame
{
	NSRect tempRect = theFrame;
	id theSpectrumView;
	int borderType = NSNoBorder;
    
	(tempRect.size) = [NSScrollView contentSizeForFrameSize:(theFrame.size) hasHorizontalScroller:YES hasVerticalScroller:NO borderType:borderType];
	theSpectrumView = [[SpectrumView alloc] initWithFrame:tempRect];
	[super initWithFrame:theFrame];
    [self setBorderType:borderType];
    [self setHasHorizontalScroller:YES];
    [self setHasVerticalScroller:NO];
    [self setScrollsDynamically:YES];
    [self setSpectrumView:theSpectrumView];
    [self setBackgroundColor:[NSColor whiteColor]];
    [self setAutoresizesSubviews:YES];
    [self setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [[theSpectrumView superview] setAutoresizesSubviews:YES];
    [theSpectrumView setAutoresizingMask:NSViewHeightSizable];
    return self;
}

- (void)setDelegate:(id)anObject
{
	delegate = anObject;
}

- setSpectrumView:aSpectrumView
{
	if (spectrumView)
		[spectrumView release];
	spectrumView = aSpectrumView;
	[self setDocumentView:spectrumView];
	return self;
}

- delegate
{
	return delegate;
}

- spectrumView
{
	return spectrumView;
}

- getWindowPoints:(float *)stptr Size:(float *)sizptr
{
	NSRect aRect;			/* dimensions of visible view */

/* Get the graphic dimensions of the currently visible portion of the
 * SpectrumView and convert those graphic coordinates to data points.
 */
	aRect = [self documentVisibleRect];
	*stptr  = aRect.origin.x   * dataFactor;
	*sizptr = aRect.size.width * dataFactor;
	return self;
}

- setWindowStart:(int)startpoint
{
	NSRect aRect;			/* Visible part of SoundView */

/* Get the coordinates of the visible part of the SoundView,
 * change its origin, and force a scroll.
 */
	aRect = [self documentVisibleRect];
	aRect.origin.x = startpoint / dataFactor;
	[spectrumView scrollRectToVisible:aRect];
	return self;
}

/* setDisplayPoints:  -- Change the duration of the display.
 * 	Argument is a float.  The change in duration is accomplished by
 *	changing the data factor while keeping the graphic size of the
 *  SpectrumView constant.
 */
- setDisplayPoints:(float)points
{
	NSRect aRect;			/* Visible part of SoundView */
	
/* Get the width of the display and calculate the new reduction factor
 * needed to fit the requested duration within that size.
 */
	aRect = [self documentVisibleRect];
	dataFactor = points / aRect.size.width;
	if (dataFactor <= 0.0)		/* dataFactor can't be <= 0 */
		dataFactor = 1.0;
	[spectrumView setDataFactor:dataFactor];
	return self;
}

/* reflectScroll: -- handle a change in the relationship between
 *	the contentView and the docView.  This method overrides
 *	the standard ScrollView method so as to send a displayChanged:
 *	message to the delegate.
 */
- (void)reflectScrolledClipView:(NSClipView *)sender
{	
	[super reflectScrolledClipView:sender];		/* Do the default actions */
	if (delegate && [delegate respondsToSelector:@selector(spectrumMoved:)])
            [delegate performSelector:@selector(spectrumMoved:) withObject:self];
}

@end
