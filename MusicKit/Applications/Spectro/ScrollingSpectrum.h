#import <AppKit/NSScrollView.h>

@interface ScrollingSpectrum:NSScrollView
{
	id spectrumView;
	id delegate;
	double dataFactor;
}

- initWithFrame:(NSRect)theFrame;

/* Methods to set up the object: */
- (void)setDelegate:(id)anObject;
- setSpectrumView:anObject;

/* Methods to retrieve information about the object: */
- delegate;
- spectrumView;

/* Methods to get data information about the display */
- getWindowPoints:(float *)stptr Size:(float *)sizptr;

/* Methods to set display and selection by timings */
- setWindowStart:(int)startpoint;
- setDisplayPoints:(float)points;

/* Method to replace normal ScrollView methods: */
- (void)reflectScrolledClipView:(NSClipView *)sender;

@end
