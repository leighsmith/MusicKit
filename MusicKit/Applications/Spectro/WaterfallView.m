/* WaterfallView.m */

#import "WaterfallView.h"
#import "SpectrumDocument.h"
#import "SoundController.h"
#import <AppKit/AppKit.h>
#import <AppKit/NSColor.h>

#import <string.h>
#import <AppKit/psopsOpenStep.h>
#import <AppKit/dpsOpenStep.h>
#import <AppKit/NSDPSContext.h>

#define WIDTH     [self bounds].size.width		/* Width of view in pixels */
#define HEIGHT    [self bounds].size.height		/* Height of view in pixels */

@implementation WaterfallView

- initWithFrame:(NSRect)theFrame
{
	NSRect tempRect = theFrame;
	
	[super initWithFrame:tempRect];
	PSsliderOps[0] = dps_moveto;
	PSsliderOps[1] = dps_lineto;
	bbox[0] = 0;
	bbox[1] = 0;
	bbox[2] = [self bounds].origin.x + WIDTH + 1;
	bbox[3] = [self bounds].origin.y + HEIGHT + 1;
	PSsliderData[0] = WIDTH;
	lastLength = 0;
	lastFrame = 0;
	currentFrame = 0;
	draw = NO;
	placeSliderLine = NO;
	cursorPixel = 0;

        [spectrumColor release];
        [cursorColor release];
        spectrumColor = [StringToColor(
                                       [[NSUserDefaults standardUserDefaults] objectForKey:@"SpectrumColor"]) retain];
	
        cursorColor = [StringToColor(
                                     [[NSUserDefaults standardUserDefaults] objectForKey:@"CursorColor"]) retain];
	
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
	int i, maxLength;

	deltaX = [self bounds].size.width * 0.2 / (numFrames + 2);
	deltaY = HEIGHT / (numFrames + 2);
	length = numPoints;
    yNorm = [frameHeight floatValue] / (numFrames + 2);
	totalFrames = numFrames;
	currentFrame = numFrames - 1;

	if (PSdata)	free(PSdata);
	PSdata = (float *)malloc(numFrames * (length+3) * 2 * sizeof(float));

	if (length != lastLength) {
		if (PSops)
			free(PSops);
		if ((length+3) > 5000)
			maxLength = 5000;
		else maxLength = (length+3);
		PSops = (char *)malloc(maxLength);
		PSops[0] = dps_moveto;
		for (i = 1; i < (maxLength); i++)
			PSops[i] = dps_lineto;
		lastLength = length;
	}
	draw = YES;
    return self;
}

- storeNext:(float *)f
{
	int i, PSoffset;
	double xstep, xmax, xoffs, ymax, yoffs, max = 0.0, temp;
	float *fptr;
	
	coefs = f;
	ymax = yNorm * HEIGHT;
	xstep = WIDTH * 0.8 / length;
	xmax = WIDTH;
    xoffs = currentFrame * deltaX;
    yoffs = currentFrame * deltaY + 2.0;

	PSoffset = (totalFrames - currentFrame - 1) * (length+3) * 2;
	fptr = &PSdata[PSoffset];
	*fptr++ = xoffs;
	*fptr++ = yoffs;
	for (i = 0; i < length; i++) {
			*fptr++ = xoffs + xstep * i;		/* X coord */
			if (coefs[i] > max) max = coefs[i];
			temp = yoffs + max * ymax;
			if (temp > HEIGHT) temp = HEIGHT;
			*fptr++ = temp;						/* Y coord */
			max = 0.0;
	}
	*fptr++ = xoffs + xstep * i;
	*fptr++ = yoffs;
	*fptr++ = deltaX + xoffs + xstep * i;
	*fptr++ = yoffs;
    currentFrame -= 1;
	return self;
}

/* drawSelf:: -- called via 'display' method. */
-(BOOL)isOpaque
{ return YES;}

- (void)drawRect:(NSRect)rects
{
	int i, j, PSoffset, times, r, n = 5000;

	if (!placeSliderLine) NSEraseRect([self bounds]);
	if (!draw) return;

	if (!placeSliderLine) {
            for (j=0; j < totalFrames; j++) {
                PSoffset = j * (length+3) * 2;
                PSsetgray(1.0);
                if ((length+2) > n) {
                    times = (length+2) / n;
                    r = (length+2) - times * n;
                    for (i = 0; i < times; i++) {
                        PSDoUserPath(&PSdata[PSoffset+n*i*2],n*2,dps_float,PSops,n,bbox,dps_ufill);
                        }
                    PSDoUserPath(&PSdata[PSoffset+n*times*2],r*2,dps_float,PSops,r,bbox, dps_ufill);
                    }
                else PSDoUserPath(&PSdata[PSoffset],(length+2)*2,dps_float,PSops,(length+2),bbox, dps_ufill);

                [spectrumColor set];
                if ((length+3) > n) {
                    times = (length+3) / n;
                    r = (length+3) - times * n;
                    for (i = 0; i < times; i++) {
                        PSDoUserPath(&PSdata[PSoffset+n*i*2],n*2,dps_float,PSops,n,bbox,dps_ustroke);
                        }
                    PSDoUserPath(&PSdata[PSoffset+n*times*2],r*2,dps_float,PSops,r,bbox,dps_ustroke);
                    }
                else PSDoUserPath(&PSdata[PSoffset],(length+3)*2,dps_float,PSops,(length+3),bbox,dps_ustroke);
                }
            }

	if (placeSliderLine) {
		PSsliderData[0] = WIDTH;
		PSsliderData[1] = deltaY * lastFrame + 2.0;
		PSsliderData[2] = WIDTH - (totalFrames - lastFrame) * deltaX;
		PSsliderData[3] = deltaY * lastFrame + 2.0;
	
		PSsetgray(1.0);
		PSDoUserPath(PSsliderData,4,dps_float,PSsliderOps,2,bbox,dps_ustroke);

		PSsliderData[1] = deltaY * currentFrame + 2.0;
		PSsliderData[2] = WIDTH - (totalFrames - currentFrame) * deltaX;
		PSsliderData[3] = deltaY * currentFrame + 2.0;

		[cursorColor set];
		PSDoUserPath(PSsliderData,4,dps_float,PSsliderOps,2,bbox,dps_ustroke);
                [self setNeedsDisplay:YES];/* because we used up the 1st one on printing the slider lines */
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
    [cursorColor release];
    spectrumColor = [StringToColor(
                                   [[NSUserDefaults standardUserDefaults] objectForKey:@"SpectrumColor"]) retain];
	
    cursorColor = [StringToColor(
                                 [[NSUserDefaults standardUserDefaults] objectForKey:@"CursorColor"]) retain];

    [self setNeedsDisplay:YES];
	return self;
}

@end
