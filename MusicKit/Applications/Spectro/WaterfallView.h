/* WaterfallView.h -- Interface for WaterfallView class */

#import <AppKit/AppKit.h>

@interface WaterfallView:NSView
{
    id delegate;
    id frameHeight;
    NSColor *spectrumColor;
    NSColor *cursorColor;
    NSColor *waterfallColor;
    int lastLength;
    int length;
    int totalFrames;			/* number of spectral frames to display */
    int currentFrame;
    int lastFrame;
    double dataFactor;			/* Number of data points per pixel */
    double deltaX;
    double deltaY;
    double yNorm;
    NSBezierPath **waterFallPath;	/* array of bezier paths, one per frame */
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
