/* WaterfallView.m */

#import "WaterfallView.h"
#import "SpectrumDocument.h"
#import "SoundController.h"
#import <AppKit/AppKit.h>
#import <AppKit/NSColor.h>

#import <string.h>

#define WIDTH     [self bounds].size.width		/* Width of view in pixels */
#define HEIGHT    [self bounds].size.height		/* Height of view in pixels */

@implementation WaterfallView

- initWithFrame:(NSRect)theFrame
{
    NSRect tempRect = theFrame;
    
    [super initWithFrame:tempRect];
/*
    bbox[0] = 0;
    bbox[1] = 0;
    bbox[2] = [self bounds].origin.x + WIDTH + 1;
    bbox[3] = [self bounds].origin.y + HEIGHT + 1;
*/
    lastLength = 0;
    lastFrame = 0;
    currentFrame = 0;
    draw = NO;
    placeSliderLine = NO;
    cursorPixel = 0;

    [self setColors];
    
    return self;
}
- (oneway void)dealloc
{
    [spectrumColor release];
    [cursorColor release];
}

- (void)setDelegate:(id)anObject
{
    delegate = anObject;
}

- delegate
{
    return delegate;
}

- setup:(int)numFrames length:(int)numPoints
{
    int frameIndex;

    deltaX = [self bounds].size.width * 0.2 / (numFrames + 2);
    deltaY = HEIGHT / (numFrames + 2);
    length = numPoints;
    yNorm = [frameHeight floatValue] / (numFrames + 2);
    totalFrames = numFrames;
    currentFrame = numFrames - 1;

    if (waterFallPath)
        free(waterFallPath);
    waterFallPath = (NSBezierPath **) malloc(numFrames * sizeof(NSBezierPath *));
    for(frameIndex = 0; frameIndex < numFrames; frameIndex++) {
        waterFallPath[frameIndex] = [[NSBezierPath bezierPath] retain];
    }
    if (length != lastLength) {
        lastLength = length;
    }
    draw = YES;
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
    [waterFallPath[frameIndex] moveToPoint: waterFallPoint];
    for (i = 0; i < length; i++) {
        waterFallPoint.x = xoffs + xstep * i;		/* X coord */
        if (coefs[i] > max) max = coefs[i];
        temp = yoffs + max * ymax;
        if (temp > HEIGHT) temp = HEIGHT;
        waterFallPoint.y = temp;			/* Y coord */
        max = 0.0;
        [waterFallPath[frameIndex] lineToPoint: waterFallPoint];
    }
    waterFallPoint.x = xoffs + xstep * i;
    waterFallPoint.y = yoffs;
    [waterFallPath[frameIndex] lineToPoint: waterFallPoint];

    waterFallPoint.x = deltaX + xoffs + xstep * i;
    waterFallPoint.y = yoffs;
    [waterFallPath[frameIndex] lineToPoint: waterFallPoint];

    currentFrame--;
    return self;
}

-(BOOL)isOpaque
{
    return YES;
}

- (void)drawRect:(NSRect)rects
{
    NSBezierPath *sliderPath = [NSBezierPath bezierPath];		/* path for slider line */

    if (!placeSliderLine)
        NSEraseRect([self bounds]);
    if (!draw)
        return;

    if (!placeSliderLine) {
        int frameIndex;
        for (frameIndex = 0; frameIndex < totalFrames; frameIndex++) {
            [waterfallColor set]; 
            [waterFallPath[frameIndex] fill];

            [spectrumColor set];
            [waterFallPath[frameIndex] stroke];
        }
    }

    if (placeSliderLine) {
        NSPoint sliderMovePoint, sliderDrawPoint;
        sliderMovePoint.x = WIDTH;
        sliderMovePoint.y = deltaY * lastFrame + 2.0;
        sliderDrawPoint.x = WIDTH - (totalFrames - lastFrame) * deltaX;
        sliderDrawPoint.y = deltaY * lastFrame + 2.0;
        // PSsetgray(1.0);
        [[NSColor blackColor] set];
        [sliderPath moveToPoint: sliderMovePoint];
        [sliderPath lineToPoint: sliderDrawPoint];
        [sliderPath stroke];

        sliderMovePoint.x = WIDTH;
        sliderMovePoint.y = deltaY * currentFrame + 2.0;
        sliderDrawPoint.x = WIDTH - (totalFrames - currentFrame) * deltaX;
        sliderDrawPoint.y = deltaY * currentFrame + 2.0;

        [cursorColor set];
        [sliderPath moveToPoint: sliderMovePoint];
        [sliderPath lineToPoint: sliderDrawPoint];
        [sliderPath stroke];
        [self setNeedsDisplay: YES]; /* because we used up the 1st one on printing the slider lines */
    }
}

- placeSliderLineAt:(int)frameNum
{
	currentFrame = frameNum;
	placeSliderLine = YES;
        [self display];
	placeSliderLine = NO;
	lastFrame = frameNum;
	return self;
}

- setColors
{
    [spectrumColor release];
    [waterfallColor release];
    [cursorColor release];
    
    spectrumColor = [StringToColor([[NSUserDefaults standardUserDefaults] objectForKey:@"SpectrumColor"]) retain];
    waterfallColor = [StringToColor([[NSUserDefaults standardUserDefaults] objectForKey:@"WaterfallColor"]) retain];
    cursorColor = [StringToColor([[NSUserDefaults standardUserDefaults] objectForKey:@"CursorColor"]) retain];

    [self setNeedsDisplay:YES];
    return self;
}

@end
