#import "SpectrumView.h"
#import "SpectrumDocument.h"
#import "SoundController.h"
#import <AppKit/AppKit.h>
#import <AppKit/NSColor.h>

//#import <AppKit/psopsOpenStep.h>

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
    coefs = f;
    length = npoints;
    
    if (length != lastLength) {
        lastLength = length;
    }
    draw = YES;
    [self setNeedsDisplay:YES];
    return self;
}

/* drawRect: -- called via 'display' method. */
- (void) drawRect: (NSRect) rects
{
    NSBezierPath *energyPath;		/* path of coefficient plot */
    NSBezierPath *cursorPath;		/* path for cursor */
    NSBezierPath *horizLinePath;	/* path for horizontal lines */
    NSBezierPath *vertLinePath;		/* path for vertical lines */
    int i;
    double xstep, ymax, xmax, xstart;
    float height, width;
    NSRect aRect;
    NSPoint minCursor, maxCursor, horizPointLeft, horizPointRight, vertPointMin, vertPointMax;

    /* First, erase what we have now. */
    NSEraseRect([self bounds]);
    if (!draw)
        return;

    /* Set up the view width and other factors. */
    cursorPixel = (int) 0.5 + cursorPixel * (length+1) / (WIDTH * dataFactor);
    height = [self bounds].size.height;
    width = length / dataFactor;
    [self setFrameSize: NSMakeSize(width, height)];

    ymax = [self bounds].size.height;
    xstep = 1.0 / dataFactor;
    xmax = WIDTH;

    // Fill the horizontal line path with the coordinates for the
    // horizontal lines.
    horizLinePath = [NSBezierPath bezierPath];
    [gridColor set];
    for (i = 1; i < 4; i++) {
        horizPointLeft.x = 0.0;				/* X coord */
        horizPointLeft.y = ymax * 0.25 * i;		/* Y coord */
        [horizLinePath moveToPoint: horizPointLeft];

        horizPointRight.x = xmax;			/* X coord */
        horizPointRight.y = ymax * 0.25 * i;		/* Y coord */
        [horizLinePath lineToPoint: horizPointRight];
    }

    // Get the visible frame bounds, and fill the vertLinePath
    // array with the coordinates for the vertical lines.
    aRect = [(NSClipView *) [self superview] documentVisibleRect];
    vertLinePath = [NSBezierPath bezierPath];
    [gridColor set];
    xmax = aRect.size.width;
    xstart = aRect.origin.x;
    for (i = 1; i < 4; i++) {
        vertPointMin.x = xstart + xmax * 0.25 * i;	/* X coord */
        vertPointMin.y = 0.0;				/* Y coord */
        [vertLinePath moveToPoint: vertPointMin];

        vertPointMax.x = xstart + xmax * 0.25 * i;	/* X coord */
        vertPointMax.y = ymax;				/* Y coord */
        [vertLinePath moveToPoint: vertPointMax];
    }
    [horizLinePath stroke];
    [vertLinePath stroke];
    
    /* Create the cursor path. */
    cursorPath = [NSBezierPath bezierPath];
    minCursor.x = cursorPixel;
    minCursor.y = 0.0;
    maxCursor.x = cursorPixel;
    maxCursor.y = ymax;
    [cursorPath moveToPoint: minCursor];
    [cursorPath lineToPoint: maxCursor];
    
    if (frames) {
        /* Fill the energyPath with the coordinates for the plot,
        * and set the bounding box to the size of our view.  The
        * plot of the data will be done via a NSBezierPath stroke,
        * which is the zippiest way to do such things.  
        */
        NSPoint coeffPoint;
        coeffPoint.x = 0;
        coeffPoint.y = (coefs[0] > 1.0 ? 1.0 : coefs[0]) * ymax;
        energyPath = [NSBezierPath bezierPath];
        [energyPath moveToPoint: coeffPoint];

        for (i = 0; i < length; i++) {
            coeffPoint.x = xstep * i;
            coeffPoint.y = (coefs[i] > 1.0 ? 1.0 : coefs[i]) * ymax;
            [energyPath lineToPoint: coeffPoint];
        }
        [spectrumColor set];
        [energyPath stroke];    
    }
    [cursorColor set];
    [cursorPath stroke];
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