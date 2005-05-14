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

#import "WaterfallView.h"
#import "SpectrumDocument.h"
#import "SoundController.h"
#import <AppKit/AppKit.h>
//#import <AppKit/NSColor.h>

#define WIDTH     [self bounds].size.width		/* Width of view in pixels */
#define HEIGHT    [self bounds].size.height		/* Height of view in pixels */

@implementation WaterfallView

- initWithFrame: (NSRect) theFrame
{
    NSRect tempRect = theFrame;
    
    [super initWithFrame: tempRect];
    lastLength = 0;
    currentFrame = 0;
    cursorPixel = 0;
    
    [self setColors];
    
    return self;
}

- (oneway void) dealloc
{
    [spectrumColor release];
    [cursorColor release];
    [waterfallColor release];
    // TODO we're leaking like a sieve here...
    // waterFallPaths
    [super dealloc];
}

- (void) setDelegate: (id) anObject
{
    delegate = anObject;
}

- delegate
{
    return delegate;
}

- setup: (int) numFrames length: (int) numPoints
{
    int frameIndex;
    
    deltaX = [self bounds].size.width * 0.2 / (numFrames + 2);
    deltaY = HEIGHT / (numFrames + 2);
    length = numPoints;
    yNorm = [frameHeight floatValue] / (numFrames + 2);
    totalFrames = numFrames;
    currentFrame = numFrames - 1;
    
    if (waterFallPaths)
        free(waterFallPaths);
    waterFallPaths = (NSBezierPath **) malloc(numFrames * sizeof(NSBezierPath *));
    for(frameIndex = 0; frameIndex < numFrames; frameIndex++) {
        waterFallPaths[frameIndex] = [[NSBezierPath bezierPath] retain];
    }
    if (length != lastLength) {
        lastLength = length;
    }
    return self;
}

- storeNext: (float *) coefs
{
    int i, frameIndex;
    double xstep, xmax, xoffs, ymax, yoffs, max = 0.0, temp;
    NSPoint waterFallPoint;
    
    ymax = yNorm * HEIGHT;
    xstep = WIDTH * 0.8 / length;
    xmax = WIDTH;
    xoffs = currentFrame * deltaX;
    yoffs = currentFrame * deltaY + 2.0;
    
    frameIndex = (totalFrames - currentFrame - 1);
    waterFallPoint.x = xoffs;
    waterFallPoint.y = yoffs;
    [waterFallPaths[frameIndex] moveToPoint: waterFallPoint];
    for (i = 0; i < length; i++) {
        waterFallPoint.x = xoffs + xstep * i;		/* X coord */
        if (coefs[i] > max) max = coefs[i];
        temp = yoffs + max * ymax;
        if (temp > HEIGHT) temp = HEIGHT;
        waterFallPoint.y = temp;			/* Y coord */
        max = 0.0;
        [waterFallPaths[frameIndex] lineToPoint: waterFallPoint];
    }
    waterFallPoint.x = xoffs + xstep * i;
    waterFallPoint.y = yoffs;
    [waterFallPaths[frameIndex] lineToPoint: waterFallPoint];
    
    waterFallPoint.x = deltaX + xoffs + xstep * i;
    waterFallPoint.y = yoffs;
    [waterFallPaths[frameIndex] lineToPoint: waterFallPoint];
    
    currentFrame--;
    return self;
}

- (BOOL) isOpaque
{
    return YES;
}

// Returns the region of the display drawn using a slider at the given spectral frame.
- (NSRect) rectOfSliderAtFrame: (int) frame
{
    NSRect sliderRectangle;
    
    sliderRectangle.origin.x = WIDTH - (totalFrames - frame) * deltaX;
    sliderRectangle.origin.y = deltaY * frame + 1.0;
    sliderRectangle.size.width = (totalFrames - frame) * deltaX;
    sliderRectangle.size.height = 2.0;

    return sliderRectangle;
}

- (void) drawRect: (NSRect) updateRect
{
    NSRect currentFrameRect;
    int frameIndex;
    
    NSEraseRect(updateRect);
	
    for (frameIndex = 0; frameIndex < totalFrames; frameIndex++) {
	// Since drawing the waterfall can be slow, we check which regions we need to redraw.
	if(NSIntersectsRect(updateRect, [waterFallPaths[frameIndex] bounds])) {
	    // NSLog(@"drawing waterfall frame %d\n", frameIndex);
	    // NSLog(@"updateRect %f, %f, %f, %f\n", updateRect.origin.x, updateRect.origin.y, updateRect.size.width, updateRect.size.height);
	    // NSLog(@"waterFallPaths bounds %f, %f, %f, %f\n", [waterFallPaths[frameIndex] bounds].origin.x, [waterFallPaths[frameIndex] bounds].origin.y, [waterFallPaths[frameIndex] bounds].size.width, [waterFallPaths[frameIndex] bounds].size.height);
	    [waterfallColor set]; 
	    [waterFallPaths[frameIndex] fill];
	    
	    [spectrumColor set];
	    [waterFallPaths[frameIndex] stroke];
	}
    }
    
    currentFrameRect = [self rectOfSliderAtFrame: currentFrame];
    
    if (NSIntersectsRect(updateRect, currentFrameRect)) {
	NSBezierPath *sliderPath = [NSBezierPath bezierPath];		/* path for slider line */
        NSPoint sliderMovePoint, sliderDrawPoint;

	// NSLog(@"currentFrameRect %f, %f, %f, %f\n", currentFrameRect.origin.x, currentFrameRect.origin.y, currentFrameRect.size.width, currentFrameRect.size.height);

	sliderMovePoint.y = sliderDrawPoint.y = currentFrameRect.origin.y + 1.0;
	sliderMovePoint.x = currentFrameRect.origin.x;
        sliderDrawPoint.x = currentFrameRect.origin.x + currentFrameRect.size.width;

        [cursorColor set];
        [sliderPath moveToPoint: sliderMovePoint];
        [sliderPath lineToPoint: sliderDrawPoint];
        [sliderPath stroke];
    }
}

- (void) placeSliderLineAt: (int) frameNum
{
    // Mark the previous frame rectangle for redraw, thus erasing it.
    [self setNeedsDisplayInRect: [self rectOfSliderAtFrame: currentFrame]];
    currentFrame = frameNum;
    // Mark the current frame rectangle for redraw, drawing the slider
    [self setNeedsDisplayInRect: [self rectOfSliderAtFrame: currentFrame]];
}

- (void) setColors
{
    [spectrumColor release];
    [waterfallColor release];
    [cursorColor release];
    
    spectrumColor = [StringToColor([[NSUserDefaults standardUserDefaults] objectForKey:@"SpectrumColor"]) retain];
    waterfallColor = [StringToColor([[NSUserDefaults standardUserDefaults] objectForKey:@"WaterfallColor"]) retain];
    cursorColor = [StringToColor([[NSUserDefaults standardUserDefaults] objectForKey:@"CursorColor"]) retain];
    
    [self setNeedsDisplay: YES];
}

@end
