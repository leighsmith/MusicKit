/* Created because of bugs in SoundView's getSelection and
 * setSelection methods.
 */

#import "SubSoundView.h"

#import <math.h>

extern double floor();

@implementation SubSoundView

#if 0
- initWithFrame:(NSRect)theFrame
{
	NSRect tempRect = theFrame;
	
	[super initWithFrame:tempRect];
	return self;
}

- getSelection:(int *)firstSample size:(int *)sampleCount
{
	*firstSample = selectionRect.origin.x * reductionFactor;
	*sampleCount = selectionRect.size.width * reductionFactor;
	return self;
}

- setSelection:(int)firstSample size:(int)sampleCount
{
	int max = [sound sampleCount];
	int offset=firstSample;
	int count=sampleCount;
	if (!sound) return self;
	if (NO /* was [<view> isAutoDisplay] */) {
	[self lockFocus];
	if (!selectionRect.size.width)
		[self hideCursor];
	else
		NSHighlightRect(selectionRect);
	}
	if (offset < 0) offset = 0;
	else if (offset > max) offset = max;
	if ((firstSample+sampleCount) > max) count = max - offset;
	selectionRect.origin.x = floor(offset/reductionFactor + 0.5);
	selectionRect.size.width = floor(count/reductionFactor + 0.5);
	if (NO /* was [<view> isAutoDisplay] */) {
		if (!selectionRect.size.width)
			[self showCursor];
		else
			NSHighlightRect(selectionRect);
		[self unlockFocus];
		[[self window] flushWindow];
	}
	svFlags.selectionDirty = YES;
	[[self window] makeFirstResponder:self];
	[self tellDelegate:@selector(selectionChanged:)];
	return self;
}

- (void)selectAll:(id)sender;
{
    if (sound)
	[self setSelection:0 size:[sound sampleCount]];
    return self;
}
#endif

@end