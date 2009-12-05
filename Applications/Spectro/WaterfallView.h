/* 
 * $Id$ 
 *
 * Modifications Copyright (c) 2005 The MusicKit Project, All Rights Reserved.
 *
 * Legal Statement Covering Additions by The MusicKit Project:
 *
 *   Permission is granted to use and modify this code for commercial and
 *   non-commercial purposes so long as the author attribution and copyright
 *   messages remain intact and accompany all relevant code.
 *
 */

#import <AppKit/AppKit.h>

@interface WaterfallView: NSView
{
    id delegate;
    IBOutlet id frameHeight;
    NSColor *spectrumColor;
    NSColor *cursorColor;
    NSColor *waterfallColor;
    int lastLength;
    int length;
    int totalFrames;			/* number of spectral frames to display */
    int currentFrame;
    double dataFactor;			/* Number of data points per pixel */
    double deltaX;
    double deltaY;
    double yNorm;
    NSBezierPath **waterFallPaths;	/* array of bezier paths, one per frame */
    int cursorPixel;			/* Cursor location (as pixel column) */
}

- initWithFrame: (NSRect) theFrame;
- (void) setDelegate: (id) anObject;
- delegate;
- setup: (int) numFrames length: (int) numPoints;
- storeNext: (float *) f;
- (void) drawRect: (NSRect) rects;
- (void) placeSliderLineAt: (int) frameNum;
- (void) setColors;

@end
