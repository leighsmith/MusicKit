/* WaterfallView.h -- Interface for WaterfallView class */

#import <AppKit/NSView.h>

@interface WaterfallView:NSView
{
	id delegate;
    id frameHeight;
	NSColor * spectrumColor;
	NSColor * cursorColor;
	int lastLength;
	int length;
	int totalFrames;
	int currentFrame;
	int lastFrame;
	double dataFactor;			/* Number of data points per pixel */
	double deltaX;
	double deltaY;
	double yNorm;
	float *coefs;				/* The FFT coefficients */
	float *PSdata;				/* User path data for drawing*/
	float PSsliderData[4];		/* User path data for slider line */
	float bbox[4];				/* User path bounding box */
	char *PSops;				/* User path operators for drawing */
	char PSsliderOps[2];		/* User path operators for slider line */
	int cursorPixel;			/* Cursor location (as pixel column) */
	BOOL draw;
	BOOL placeSliderLine;
}

- initWithFrame:(NSRect)theFrame;
- (void)setDelegate:(id)anObject;
- delegate;
- setup:(int)numFrames length:(int)numPoints;
- storeNext:(float *)f;
- (void)drawRect:(NSRect)rects;
- placeSliderLineAt:(int)frameNum;
- setColors;

@end
