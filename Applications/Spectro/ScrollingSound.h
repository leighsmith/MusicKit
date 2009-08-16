

#import <AppKit/NSScrollView.h>
#import <SndKit/Snd.h>
#import <SndKit/SndView.h>

@interface ScrollingSound:NSScrollView
{
	IBOutlet SndView *soundView;
	id delegate;
	float srate;
	float reductionFactor;
}

- initWithFrame:(NSRect)theFrame;
- centerAt:(int)sample;
- (int)centerSample;

/* Methods to set up the object: */
- (void)setDelegate:(id)anObject;
- setSoundView:anObject;
- (void)setSound:(Snd *)aSound;
- (BOOL)setReductionFactor:(float)rf;

/* Methods to retrieve information about the object: */
- delegate;
- soundView;
- (float)reductionFactor;

/* Methods to get time information about the sound, display, and selection */
- getWindowSamples:(int *)stptr Size:(int *)sizptr;

/* Methods to set display and selection by timings */
- setWindowStart:(int)start;
- setWindowSize:(int)size;
- sizeToSelection:sender;

/* Method to replace normal ScrollView methods: */
- (void)reflectScrolledClipView:(NSClipView *)sender;

@end
