#import "SpectrumView.h"
#import "SpectrumDocument.h"
#import "SoundController.h"
#import <AppKit/AppKit.h>
#import <AppKit/NSColor.h>

#import <AppKit/psopsOpenStep.h>

#define WIDTH    [self bounds].size.width		/* Width of view in pixels */

@implementation SpectrumView

- initWithFrame:(NSRect)theFrame
{
	NSRect tempRect = theFrame;
	
	[super initWithFrame:tempRect];
	lastLength = 0;
	draw = NO;
	frames = NO;
	cursorPixel = 0;

        spectrumColor = [StringToColor(
		[[NSUserDefaults standardUserDefaults] objectForKey:@"SpectrumColor"]) retain];
	
        cursorColor = [StringToColor(
                                     [[NSUserDefaults standardUserDefaults] objectForKey:@"CursorColor"]) retain];
	
        gridColor = [StringToColor(
                                  [[NSUserDefaults standardUserDefaults] objectForKey:@"GridColor"]) retain];

	return self;
}

- (void)setDelegate:(id)anObject
{
	delegate = anObject;
}

- delegate
{
	return delegate;
}

- frames:(BOOL)value
{
	frames = value;
    if (!frames) [self setNeedsDisplay:YES];
	return self;
}

- setDataFactor:(double)dFactor
{
	dataFactor = dFactor;
	return self;
}

- (double)dataFactor
{
	return dataFactor;
}

- getCursorLocation:(float *)cursorPoint
{
	*cursorPoint = (float) cursorPixel * dataFactor;
	return self;
}

- setCursor:(float)cursorPoint
{
	cursorPixel = (int) 0.5 + cursorPoint / dataFactor;
    [self setNeedsDisplay:YES];
	if (delegate && [delegate respondsToSelector:@selector(cursorMoved:)])
		[delegate cursorMoved:self];
	
	return self;
}

- drawSpectrum:(int)npoints array:(float *)f
{
	int i, maxLength;
	
	coefs = f;
	length = npoints;
	
/* The PSdata[] and PSops[] arrays are for the graphics -- PSdata will
 * hold the pixel coordinates of the data, and PSops[] is just an
 * initial moveto followed by a bunch of linetos.  These arrays are
 * passed to DPSDoUserPath() to draw the series of line segments.
 * See the 'Lines' demo and /usr/include/dpsclients/dpsNeXT.h for more
 * info on DPSDoUserPath().  User paths have a maximum length somewhere
 * around 15000, so I'm going to make multiple paths if I have to.
 */

	if (length != lastLength) {
		if (PSdata)
			free(PSdata);
		PSdata = (float *)malloc(length * 2 * sizeof(float));
		if (PSops)
			free(PSops);
		if (length > 5000)
			maxLength = 5000;
		else maxLength = length;
		PSops = (char *)malloc(maxLength);
		PSops[0] = dps_moveto;
		for (i = 1; i < maxLength; i++)
			PSops[i] = dps_lineto;
		lastLength = length;
	}
	if (!draw) {
		PShLineData = (float *)malloc(12 * sizeof(float));
		PSvLineData = (float *)malloc(12 * sizeof(float));
		PSLineOps = (char *)malloc(6);
		PScursorData = (float *)malloc(4 * sizeof(float));
		PScursorOps = (char *)malloc(2);
		PScursorOps[0] = dps_moveto;
		PScursorOps[1] = dps_lineto;
		i = 0;
		while (i < 6) {
			PSLineOps[i] = dps_moveto;
			PSLineOps[i+1] = dps_lineto;
			i += 2;
		}
	}
	draw = YES;
        [self setNeedsDisplay:YES];
	return self;
}

/* drawSelf:: -- called via 'display' method. */

- (void)drawRect:(NSRect)rects
{
	int i, times, r, n = 5000;
	double xstep, ymax, xmax, xstart, max = 0.0;
	float bbox[4];
	float *fptr;
	float *hptr;
	float *vptr;
	float *cptr;
	float height, width;
	NSRect aRect;

/* First, erase what we have now. */
	NSEraseRect([self bounds]);
	if (!draw) return;

/* Set up the view width and other factors. */
	cursorPixel = (int) 0.5 + cursorPixel * (length+1) / (WIDTH * dataFactor);
	height = [self bounds].size.height;
	width = length / dataFactor;
	[self setFrameSize:NSMakeSize(width, height)];

	ymax = [self bounds].size.height;
	xstep = 1.0 / dataFactor;
	xmax = WIDTH;

/* Fill the PSdata[] array with the coordinates for the plot,
 * and set the bounding box to the size of our view.  The
 * plot of the data will be done via a DPSDoUserPath() call,
 * which is the zippiest way to do such things.  Unfortunately,
 * user paths can't be much longer than about 16,000 points,
 * so, for longer paths I split the data up when I go to call
 * DPSDoUserPath().
 */

	if (frames) {
		fptr = PSdata;
		for (i = 0; i < length; i++) {
			*fptr++ = xstep * i;			/* X coord */
			if (coefs[i] > max) max = coefs[i];
			if (max > 1) max = 1.0;
			*fptr++ = max * ymax;			/* Y coord */
			max = 0.0;
		}
	}

/* Fill the PShLineData array with the coordinates for the
 * horizontal lines.
 */

	hptr = PShLineData;
	for (i = 1; i < 4; i++) {
		*hptr++ = 0.0;					/* X coord */
		*hptr++ = ymax * 0.25 * i;		/* Y coord */
		*hptr++ = xmax;					/* X coord */
		*hptr++ = ymax * 0.25 * i;		/* Y coord */
	}

/* Get the visible frame bounds, and fill the PSvLineData
 * array with the coordinates for the vertical lines.
 */

	aRect = [(NSClipView *)[self superview] documentVisibleRect];
	vptr = PSvLineData;
	xmax = aRect.size.width;
	xstart = aRect.origin.x;
	for (i = 1; i < 4; i++) {
		*vptr++ = xstart + xmax * 0.25 * i;		/* X coord */
		*vptr++ = 0.0;							/* Y coord */
		*vptr++ = xstart + xmax * 0.25 * i;		/* X coord */
		*vptr++ = ymax;							/* Y coord */
	}

/* Fill the PScursorData array with the coordinates for the cursor. */

	cptr = PScursorData;
	*cptr++ = cursorPixel;
	*cptr++ = 0.0;
	*cptr++ = cursorPixel;
	*cptr = ymax;
	
	bbox[0] = 0;
	bbox[1] = 0;
	bbox[2] = [self bounds].origin.x + WIDTH + 1;
	bbox[3] = [self bounds].origin.y + [self bounds].size.height + 1;

	[gridColor set];
	PSDoUserPath(PShLineData,12,dps_float,PSLineOps,6,bbox,dps_ustroke);
	PSDoUserPath(PSvLineData,12,dps_float,PSLineOps,6,bbox,dps_ustroke);
	
	if (frames) {
		[spectrumColor set];
		if (length > n) {
			times = length / n;
			r = length - times * n;
			for (i = 0; i < times; i++) {
				PSDoUserPath(&PSdata[n*i*2],n*2,dps_float,PSops,n,bbox,dps_ustroke);
			}
			PSDoUserPath(&PSdata[n*2*times],r*2,dps_float,PSops,r,bbox,dps_ustroke);
		}
		else PSDoUserPath(PSdata,length*2,dps_float,PSops,length,bbox,dps_ustroke);
	}
	[cursorColor set];
	PSDoUserPath(PScursorData,4,dps_float,PScursorOps,2,bbox,dps_ustroke);
}

#define MOVE_MASK NSLeftMouseUpMask|NSLeftMouseDraggedMask

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
  return YES;
}

- (void)mouseDown:(NSEvent *)event 
{
    NSPoint p;				/* Current mouse position */
    
/* Ask for mousedragged and mouseup events only for the duration
 * of this method.
 */
//	oldMask = [[self window] addToEventMask:MOVE_MASK];
        [[self window] setAcceptsMouseMovedEvents:YES];

/* For the initial mousedown event and all subsequent mousedragged events,
 * update the cursor as necessary and send a cursorMoved: message to
 * the delegate.
 */    
	do {
		p = [event locationInWindow];
		p = [self convertPoint:p fromView:nil];
		if (p.x < 0.0)
			p.x = 0.0;
		if (p.x > WIDTH)
			p.x = WIDTH;
		if (cursorPixel != p.x) {

			cursorPixel = p.x;
                    [self setNeedsDisplay:YES];
			
			if (delegate && 
				[delegate respondsToSelector:@selector(cursorMoved:)])
				[delegate cursorMoved:self];
		}
		event = [[self window] nextEventMatchingMask:MOVE_MASK];
	} while ([event type] != NSLeftMouseUp);

//	[[self window] setEventMask:oldMask];
        [[self window] setAcceptsMouseMovedEvents:NO];
}

- setColors
{
    spectrumColor = [StringToColor(
                                   [[NSUserDefaults standardUserDefaults] objectForKey:@"SpectrumColor"]) retain];
	
    cursorColor = [StringToColor(
                                 [[NSUserDefaults standardUserDefaults] objectForKey:@"CursorColor"]) retain];
	
    gridColor = [StringToColor(
                               [[NSUserDefaults standardUserDefaults] objectForKey:@"GridColor"]) retain];

    [self setNeedsDisplay:YES];
	
    return self;
}

@end