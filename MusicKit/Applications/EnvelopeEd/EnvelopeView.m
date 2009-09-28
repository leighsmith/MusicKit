//////////////////////////////////////////////////////////////
//
// $Id$
//
// Implementation for the EnvelopeView class
//
// Copyright 1991-94 Fernando Lopez Lezcano All Rights Reserved
// Portions Copyright (c) 1998-2004, The MusicKit Project.
//////////////////////////////////////////////////////////////

// Modification history prior to CVS committal:
//
// 6/16/98 Converted to OpenStep API by Leigh Smith <leigh@cs.uwa.edu.au>
// 8/25/92 Add parsing of exponential format numbers
// 8/21/92 Memory allocation bug on allocateTemp and allocateDraw
// 8/20/92 Added drawSegments option.

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "Controller.h"
#import "EnvelopeView.h"

#define KNOBSIZE 8
#define MAXNUMSEGS 8

// [self bounds]
#define WIDTH ([self bounds].size.width)
#define HEIGHT ([self bounds].size.height)

#define WHITE [NSColor whiteColor] /* 1.0 */
#define BLACK [NSColor blackColor] /* was 0.0 */
#define DKGRAY [NSColor darkGrayColor] /* was (1.0/3.0) */
#define LTGRAY [NSColor lightGrayColor] /* was LTGRAY (2.0/3.0) */
#define TRANSP 2.0

#define DRAG_MASK (NSLeftMouseUpMask|NSLeftMouseDraggedMask)

//===================================================================
// Envelope auxiliar routines and macros
//===================================================================

//-------------------------------------------------------------------
// Draw a knob in the display

#define DRAWKNOB(x,y) NSRectFillUsingOperation(NSMakeRect(x-KNOBSIZE/2,y-KNOBSIZE/2,KNOBSIZE, KNOBSIZE),NSCompositeSourceOver)

//-------------------------------------------------------------------
// Translate from x/y envelope values to display pixel coordinates

#define xToPix(x) (((x-xMin)/(xMax-xMin))*WIDTH)
#define yToPix(y) (((y-yMin)/(yMax-yMin))*HEIGHT)

//-------------------------------------------------------------------
// Translate from display pixel coordinates to x/y envelope values

#define pixToX(xPix) (xPix/WIDTH*(xMax-xMin)+xMin)
#define pixToY(yPix) (yPix/HEIGHT*(yMax-yMin)+yMin)

//-------------------------------------------------------------------
// Shorthand to access envelope object instance variables

#define pointCount [theEnvelope pointCount]
#define stickyPoint [theEnvelope stickPoint]
#define xValues [theEnvelope xArray]
#define yValues [theEnvelope yArray]
#define sValues [theEnvelope smoothingArray]

// The application defaults
#define SHOWSMOOTH   @"ShowSmoothing"
#define DRAWSEGMENTS @"DrawSegments"
#define DEFSMOOTH    @"DefaultSmoothing"
#define DEFFORMAT    @"DefaultFormat"

//-------------------------------------------------------------------
// Temporary copy arrays for envelope copy operations
// TODO - this should become an instance of Envelope

typedef struct _env {
    double *x;                     // x array for adding or removing points
    double *y;                     // y array
    double *s;                     // smoothing array
    int max;                       // currently allocated length of arrays
} Env;

static Env *temp=NULL;             // only one copy for each envelope object

// Allocate or reallocate arrays to "size" elements

void allocateTemp(int size)
{
    int newsize=size;
    if (newsize<64) newsize=64;
    if (temp==NULL)    {                   // initial creation of arrays
        temp=malloc(sizeof(Env));
        temp->x=malloc(sizeof(double)*newsize);
        temp->y=malloc(sizeof(double)*newsize);
        temp->s=malloc(sizeof(double)*newsize);
        temp->max=newsize;
    }
    else if (size>temp->max) {            // grow to double size each time
        if (size>temp->max*2) 
            temp->max=size;
	else 
	    temp->max*=2;
        temp->x=realloc(temp->x,sizeof(double)*temp->max);
        temp->y=realloc(temp->y,sizeof(double)*temp->max);
        temp->s=realloc(temp->s,sizeof(double)*temp->max);
    }
}

// Free allocated memory

void freeTemp()
{
    if (temp!=NULL) {
        free(temp->x);
        free(temp->y);
        free(temp->s);
        free(temp);
        temp=NULL;
    }
}

//-------------------------------------------------------------------
// Temporary arrays for drawing operations
// TODO this should be an array of points, bundled as an Object

typedef struct _draw {
    int num;                    // number of points in draw arrays (x,y,p)
    int *p;                     // point number array
    float *x;                   // x array of drawing coordinates
    float *y;                   // y array
    float *yr;                  // real y coordinate of each point 
    int max;                    // currently allocated length
} Draw;

// Each time the envelope is drawn in the screen the calculated positions
// of all intermediate points are stored in the x and y arrays. The point
// number is also stored in the p array. This arrays are then used to erase
// the lines by drawing them in white.

static Draw * draw=NULL;

// Allocate or reallocate arrays to "size" elements

void allocateDraw(int size)
{
    int newsize=size;
    if (newsize<64) newsize=64;
    if (draw==NULL)    {
        draw=malloc(sizeof(Draw));
        draw->x=malloc(sizeof(float)*newsize*MAXNUMSEGS);
        draw->y=malloc(sizeof(float)*newsize*MAXNUMSEGS);
        draw->p=malloc(sizeof(int)*newsize*MAXNUMSEGS);
        draw->yr=malloc(sizeof(float)*newsize);
        draw->max=newsize;
        draw->num=0;
    }
    else if (size>draw->max) {
        if (size>draw->max*2) 
            draw->max=size;
	else 
	    draw->max*=2;
        draw->x=realloc(draw->x,sizeof(float)*draw->max*MAXNUMSEGS);
        draw->y=realloc(draw->y,sizeof(float)*draw->max*MAXNUMSEGS);
        draw->p=realloc(draw->p,sizeof(int)*draw->max*MAXNUMSEGS);
        draw->yr=realloc(draw->yr,sizeof(float)*draw->max);
    }
}

// Free allocated memory

void freeDraw()
{
    if (draw!=NULL) {
        free(draw->x);
        free(draw->y);
        free(draw->p);
        free(draw->yr);
        free(draw);
        draw=NULL;
    }
}

//===================================================================
@implementation EnvelopeView
//===================================================================

//-------------------------------------------------------------------
// - resetCursorRects sets a new cursor of the view. The message first
// initializes the two cursor shapes if needed and then proceeds to
// set the default cursor for the view to a cross.

- (void) resetCursorRects
{
    NSRect visible;    
    NSPoint spot;

    if (theFilledCross == nil) {
        spot.x = 7.0;
        spot.y = 7.0;
        theFilledCross = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crossfill.tiff"] hotSpot:spot];
    }
    if (theCross == nil) {
        spot.x = 7.0; 
        spot.y = 7.0;
        theCross = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cross.tiff"] hotSpot:spot];
    }
    visible = [self visibleRect];
    if (!NSIsEmptyRect(visible)) {
        [self addCursorRect:visible cursor:theCross];
	[theCross setOnMouseEntered: YES];
    }
}

//-------------------------------------------------------------------
// - selectPoint:n
// Selects point number n in the envelope and broadcasts the change
// to the controller object.

- selectPoint:(int)n
{
    selected=n;
    [self display];
    [(Controller *)theController update:self];
    return self;
}

//-------------------------------------------------------------------
// - initFrame:  -- initialize a new Envelope View object

- initWithFrame:(NSRect)frameRect
{
    NSUserDefaults *envelopeDefaults = [NSUserDefaults standardUserDefaults];
    static double xs[]={0.0,1.0};
    static double ys[]={0.0,0.0};
    static double ss[]={1.0,1.0};

    if([envelopeDefaults objectForKey: DEFSMOOTH] == nil)
        [envelopeDefaults setFloat: 1.0 forKey: DEFSMOOTH];
    defaultSmooth = [envelopeDefaults floatForKey: DEFSMOOTH];

    ss[0] = ss[1] = defaultSmooth;
    // the default copy/paste format we use
    if([envelopeDefaults objectForKey: DEFFORMAT] == nil)
        [envelopeDefaults setInteger: 0 forKey: DEFFORMAT];
    defaultFormat = [envelopeDefaults integerForKey: DEFFORMAT];

    self = [super initWithFrame:frameRect];
    
    theEnvelope=[[MKEnvelope alloc] init];
    [theEnvelope
        setPointCount: 2 
        xArray: xs
        orSamplingPeriod: 1.0
        yArray: ys
        smoothingArray: ss
        orDefaultSmoothing: defaultSmooth];
    [theEnvelope setStickPoint: MAXINT];      // init new envelope to default values
    
    allocateDraw(64);                         // arrays for drawing and erasing
    allocateTemp(64);                         // temporary arrays for move operations
    userPath = [NSBezierPath bezierPath];     // allocate a user path for drawing
    [userPath retain];			      // keep it for the life of this object
    xMin  = yMin  = 0.0;                      // max and min limits of display
    xMax  = yMax  = 1.0;
    xSnap = ySnap = 0.001;                    // initial Snap off in both directions
    
    envColour = BLACK;
    if([envelopeDefaults objectForKey: SHOWSMOOTH] == nil)
        [envelopeDefaults setBool: YES forKey: SHOWSMOOTH];
    showSmooth = [envelopeDefaults boolForKey: SHOWSMOOTH];

    if([envelopeDefaults objectForKey: DRAWSEGMENTS] == nil)
        [envelopeDefaults setBool: YES forKey: DRAWSEGMENTS];
    if([envelopeDefaults boolForKey: DRAWSEGMENTS])
        drawSegments = YES;
    else
	showSmooth = NO;
    [self selectPoint: 0];                    // select first point and display
    return self;
}

//-------------------------------------------------------------------
// -- Release the allocated memory when object is freed
- (void) dealloc
{
    [theEnvelope release];
    [userPath release];
    freeTemp();
    freeDraw();
    [super dealloc]; 
}

//-------------------------------------------------------------------
- (id) copyWithZone: (NSZone *) zone
{
   NSLog(@"Danger! unimplemented copyWithZone!\n");
   return nil;
}

//-------------------------------------------------------------------
// - controllerIs:  Receive the object id of the controller of the view

- (void) controllerIs:sender
{
    theController = sender; 
}

//-------------------------------------------------------------------
// Finds the place in the envelope where the point p should be inserted.
// Returns the point number at the insertion or -1 if an error is
// detected. 

- (int) insertPointAt: (NSPoint) p
{
    int point;

    point=0;
    while (point<=pointCount-1) {
        if (xValues[point]>p.x)
            return point;
        point++;
    }
    return pointCount;
}

//-------------------------------------------------------------------
// - (int) hitKnobAt: p border: delta 
// Test if the user hits a knob when clicking the mouse at point p. 
// The boundaries of the zone are delta pixels wide. Returns the
// number of the hit point or -1 if no hit.

- (int) hitKnobAt: (NSPoint) p border: (float) delta;
{
// TODO use mouse:inRect:
    int point;
    float kx, ky, dx, dy;
    
    dx = delta / WIDTH * (xMax - xMin);
    dy = delta / HEIGHT * (yMax - yMin);
    for (point = 0; point < pointCount; point++) {
        kx = xValues[point];
        ky = yValues[point];
        if (p.x < kx - dx)
            break;
        if (p.x <= kx + dx && p.x >= kx - dx &&
            p.y <= ky + dy && p.y >= ky - dy)
            return point;
    }
    return -1;
}

//-------------------------------------------------------------------
// drawKnobs(from,to,lcolour,hcolour) draws a set of knobs starting at 
// point from and ending at point to. Also highlights the selected
// knob if necessary. The second colour argument specifies the colour
// of the highlighted knob.

- drawKnobsFrom: (int) from to: (int) to in: (NSColor *) lcolour hilighted: (NSColor *) hcolour
{
    int point;
    
    [lcolour set];
    for (point=from; point<=to; point++) {
        if (point!=selected)
            DRAWKNOB(xToPix(xValues[point]),yToPix(yValues[point]));
    }
    if (selected>=from && selected<=to && hcolour != WHITE) {
        [hcolour set];
        DRAWKNOB(xToPix(xValues[selected]),yToPix(yValues[selected]));
    }
    return self;
}

//-------------------------------------------------------------------
// drawSegments(from,to,colour) draws line segments starting at point
// from and ending at point to. It also takes care of the sticky point
// marker. Due to problems with rounding each time a path is drawn the
// moves are recorded in a set of arrays. This path is used to "erase"
// the segment when a point is moved.

- recordMovex: (double) x y: (double) y p:(int) n draw: (int) state
{
    NSPoint point;
    
    draw->p[draw->num] = n;
    draw->x[draw->num] = point.x = xToPix(x);
    draw->y[draw->num++] = point.y = yToPix(y);
    if (state == 0)
        [userPath moveToPoint: point];
    else
        [userPath lineToPoint: point];
    return self;
}

- drawSegmentsFrom: (int) from to: (int) to in: (NSColor *) colour
{
    NSPoint pointToDraw;
    int pointIndex, seg;
    double 
        incx, incy,
        deltax, deltay, 
        xi, xf, x, 
        yi, yf, y,
        smooth, numsegs;
        
    // If drawing colour is white then use erase arrays to remove 
    // the previously drawn segments
    
    if (colour == WHITE) {
        [colour set];
	[userPath removeAllPoints]; // reset
        for (pointIndex = 0; draw->p[pointIndex] <= from && pointIndex < draw->num; pointIndex++)
	    ;
        if (pointIndex-1 >= 0) 
	    pointIndex--;
        pointToDraw.x = draw->x[pointIndex];
        pointToDraw.y = draw->y[pointIndex];
        [userPath moveToPoint: pointToDraw];
        for (; draw->p[pointIndex] <= to && pointIndex < draw->num; pointIndex++) {
   	    pointToDraw.x = draw->x[pointIndex];
    	    pointToDraw.y = draw->y[pointIndex];
            [userPath lineToPoint: pointToDraw];
	}
        [userPath stroke];
        return self;
    }

    // Else construct path for next erase and draw segments
    // first draw x and y axis if necessary
    
    draw->num = 0;
    if (xMin != 0 || xMax != 0) {
        //PSsetgray(LTGRAY);
        [LTGRAY set];
	[userPath removeAllPoints];
        if (xMin != 0) {
            [self recordMovex: 0 y: yMin p: from draw: 0];
            [self recordMovex: 0 y: yMax p: from draw: 1];    
        }
        if (yMin != 0) {
            [self recordMovex: xMin y: 0 p: from draw: 0];
            [self recordMovex: xMax y: 0 p: from draw: 1];
        }
        [userPath stroke];
    }
    
    // and then draw the segments that interconnect the breakpoints.
    
    if (drawSegments == NO)
	return self;
    
    draw->num = 0;
    [colour set];
    [userPath removeAllPoints];
    [self recordMovex: xValues[from] y: yValues[from] p: from draw: 0];
    yi=draw->yr[from] = yValues[from];
    for (pointIndex = from + 1; pointIndex <= to; pointIndex++) {	
        xi = xValues[pointIndex - 1];
        xf = x = xValues[pointIndex];
        yf = y = yValues[pointIndex];
        deltax = xf - xi;
        deltay = yf - yi;
        numsegs = floor((deltax * WIDTH / (xMax - xMin)) / 3);        // at least 3 pixels per segment
        if (numsegs > MAXNUMSEGS)
	    numsegs = MAXNUMSEGS;        // but no more than MAXNUMSEGS...
        if (numsegs < 2)
	    numsegs = 2;                          // or less than 2
        if (showSmooth != NO && deltax != 0 && deltay != 0) {
            smooth = sValues[pointIndex];
            incx = deltax / numsegs;                           // effective deltax is always
            if (smooth < 0.01)
		incx *= 0.01;                   // determined by the time
            else 
		if (smooth < 1.0)
		    incx *= smooth;             // constant of the segment
            incy = deltay / numsegs;
            for (seg = 0, x = xi + incx; seg < numsegs - 1; seg++, x += incx) {
                y = yi + (deltay * (1 - exp(-5.5262 * (x - xi) / (deltax * smooth))));
                [self recordMovex: x y: y p: pointIndex draw: 1];
            }
            y = yi + (deltay * (1 - exp(-5.5262 / smooth)));         // last segment to xf directly
            [self recordMovex: xf y: y p: pointIndex draw: 1];
        }
        else 
	    [self recordMovex: x y: y p: pointIndex draw: 1];
        if (pointIndex == stickyPoint) {
            [self recordMovex: xValues[pointIndex] y: 0 p: pointIndex draw: 1];
            [self recordMovex: xValues[pointIndex] y: y p: pointIndex draw: 0];
        }
        yi = draw->yr[pointIndex] = y;
    }
    [userPath stroke];
    return self;
}

//-------------------------------------------------------------------
// - drawRect: - Draw the envelope object in the view

- (void) drawRect: (NSRect) rect
{
    NSEraseRect([self bounds]);                        // clear the view
    [NSBezierPath setDefaultLineWidth:0.0];
    if (theEnvelope != nil) {
        [self drawKnobsFrom: 0 to: pointCount-1 in: LTGRAY hilighted: envColour];
        [self drawSegmentsFrom: 0 to: pointCount-1 in: envColour];
    }
}
    
//-------------------------------------------------------------------
// - eraseSelectedKnob Draw the envelope again without drawing the 
// selected knob. This is used just before the modal loop for draging
// a point is entered. In the loop the cursor itself acts as the knob.

- eraseSelectedKnob
{
    NSEraseRect([self bounds]);                        // clear the view
    [NSBezierPath setDefaultLineWidth: 0.0];
    if (theEnvelope != nil) {
        [self drawKnobsFrom: 0 to: pointCount - 1 in: LTGRAY hilighted: WHITE];//TRANSP
        [self drawSegmentsFrom: 0 to: pointCount - 1 in: envColour];
    }
    return self;
}
    
//-------------------------------------------------------------------
// movePoint:to: Move point n to a new location.
// This is called from within the drag modal loop so it tries to be
// quick. Each time it erases the old knobs and segments (up to two)
// and then draws the new knobs and segments. This last step can draw
// any number of segments depending on how close the other points are
// to the selected point (the problem is that the knob can erase 
// small portions of the segments that are lying outside of the area
// bounded by the selected point and its two enclosing points).

- (int) movePoint: (int) n to: (NSPoint) p;
{
    int left, right;                               // limits for x movement of point
    int drawFrom, drawTo;                          // start and end points for drawing lines
    
    if (n == 0) {                                    // determine limits for erase and draw
        drawFrom = 0; 
        drawTo = 1;
    } 
    else if (n == pointCount-1) {
        drawFrom = n - 1; 
        drawTo = n;
    } 
    else {
        drawFrom = n - 1; 
        drawTo = n + 1;
    }
    left = drawFrom;
    right = drawTo;
    
    if (showSmooth != NO) {                          // if showing smoothing draw points...
        while(drawFrom-1 >= 0 && sValues[drawFrom] > 1.0)  // ...that have smoothing greater that 1
            drawFrom--;
        while(drawTo+1 < pointCount && sValues[drawTo] > 1.0)
            drawTo++;
    }
    if (n != 0 && p.x < xValues[left])                // force selected point to be within
        p.x = xValues[left];                        // neighbouring points
    if (n != pointCount - 1 && p.x > xValues[right]) 
        p.x = xValues[right];
    if (xSnap != 0 && xValues[right] - xValues[left] > 2 * xSnap)
        p.x = floor(p.x / xSnap) * xSnap;                // snap into x grid
    if (p.y > yMax)
	p.y = yMax;                       // clip y values to max and min
    if (p.y < yMin)
	p.y = yMin;
    if (ySnap != 0) 
        p.y = floor(p.y / ySnap) * ySnap;                // snap into y grid
    
    if (n > 1)                                      // avoid 3 points with the same x value
        if (p.x == xValues[n - 1] && p.x == xValues[n - 2])
            p.x = xValues[n - 1] + (1 / WIDTH * (xMax - xMin));
    if (n < (pointCount - 2))
        if (p.x == xValues[n + 1] && p.x == xValues[n + 2])
            p.x = xValues[n + 1] - (1 / WIDTH * (xMax - xMin));

    [self drawKnobsFrom: drawFrom                  // erase old knobs and segments
		     to: drawTo in: WHITE hilighted: WHITE];//TRANSP
    [self drawSegmentsFrom: drawFrom to: drawTo in: WHITE];

    xValues[n] = p.x;
    yValues[n] = p.y;                               // update coordinates in arrays
    
    [self drawKnobsFrom: drawFrom                  // draw new knobs and segments
		     to: drawTo in: LTGRAY hilighted: WHITE];//TRANSP
    [self drawSegmentsFrom: drawFrom 
			to: drawTo in: envColour];

    [[self window] flushWindow];
    return n;
}

//-------------------------------------------------------------------
// addPoint:  -- Adds a point to the envelope
// Returns number of new point, -1 on error

- (int) addPoint: (NSPoint) p
{
    int point, newp, oldp, newpc, newSticky;

    if (p.x < xMin || p.x >= xMax ||                 // check point is within bounds
        p.y < yMin || p.y > yMax)
        return -1;
    if (ySnap != 0) p.y = floor(p.y / ySnap) * ySnap;     // snap into y grid

    if ((point = [self insertPointAt: p]) < 0)        // and that we get a valid point number
        return -1;

    newpc = pointCount + 1;
    allocateTemp(newpc);
    allocateDraw(newpc);

    draw->num = 0;                                 // clear erase path
    newSticky = [theEnvelope stickPoint];
    if (newSticky != MAXINT && stickyPoint > point) 
        newSticky++;                             // adjust value of stick point
    
    for (newp = oldp = 0; newp < newpc; newp++) {
        if (newp == point) {
            temp->x[newp] = p.x;                   // set values of new point
            temp->y[newp] = p.y;
            temp->s[newp] = defaultSmooth;
            draw->yr[newp] = p.y;
        }
        else {
            temp->x[newp] = xValues[oldp];         // copy old values into new arrays
            temp->y[newp] = yValues[oldp];
            if (sValues != NULL)
                temp->s[newp] = sValues[oldp];
            else
                temp->s[newp] = defaultSmooth;
            draw->yr[newp] = draw->yr[oldp];
            oldp++;
        }
    }
    [theEnvelope                                 // redefine the old envelope object
        setPointCount: newpc
        xArray: temp->x
        orSamplingPeriod: 1.0
        yArray: temp->y
        smoothingArray: temp->s
        orDefaultSmoothing: defaultSmooth];
    [theEnvelope setStickPoint: newSticky];

    return point;
}

//-------------------------------------------------------------------
// removePoint: -- Remove a point from the envelope
// Returns the new number of points or -1 on error

- (int) removePoint: (int) n
{
    int oldp, newp, newpc, newSticky;
    
    if (pointCount < 3)
	return -1;                // leave always at least two breaks
    
    newpc = pointCount - 1;
    allocateTemp(newpc);
    allocateDraw(newpc);
    
    draw->num = 0;
    for (oldp = newp = 0; newp < newpc; newp++, oldp++) {
        if (oldp == n)
	    oldp++;                    // copy arrays skipping deleted element
        temp->x[newp] = xValues[oldp];
        temp->y[newp] = yValues[oldp];
        draw->yr[newp] = draw->yr[oldp];
        if (sValues != NULL)
            temp->s[newp] = sValues[oldp];
    }
    newSticky = [theEnvelope stickPoint];
    if (newSticky != MAXINT) {
        if (newSticky == n)
            newSticky = MAXINT;                   // remove stick point with point
        else if (newSticky > n)
            newSticky--;                        // or adjust value if higher
    }
    [theEnvelope
        setPointCount: newpc
        xArray: temp->x
        orSamplingPeriod: 1.0
        yArray: temp->y
        smoothingArray: temp->s
        orDefaultSmoothing: defaultSmooth];
    [theEnvelope setStickPoint: newSticky];     // update envelope object

    [self selectPoint: n - 1];                    // and select previous point
    return pointCount;
}

//-------------------------------------------------------------------
// mouseDown:  -- Responds to a mousedown event
// The following is the behaviour of the mouse:
// hit a knob:            --> drag the point
// hit with shift:        --> delete envelope breakpoint
// hit with alternate:    --> toggle sticky point at breakpoint
// no hit with shift:    --> create a new envelope breakpoint

- (void)mouseDown: (NSEvent *) event 
{
    NSPoint ep, p;
    int hitpt;                // Point to move/remove

    ep = [self convertPoint: [event locationInWindow] fromView: nil];
    p.x = pixToX(ep.x);
    p.y = pixToY(ep.y);                                    // convert from pixels to x/y
    hitpt = [self hitKnobAt: p border: KNOBSIZE/2];        // see if it is a breakpoint    
    if ([event modifierFlags] & NSShiftKeyMask) {        // with shift key down...
        if (hitpt >= 0) {
            if ([self removePoint: hitpt] > 0)           // hit --> remove point
                hitpt = -1;
        }
        else 
	    hitpt = [self addPoint: p];                   // no hit --> add point
    }
    if (([event modifierFlags] & NSAlternateKeyMask) && (hitpt >= 0)) {   // hit plus alternate...
        if (stickyPoint==hitpt)
            [theEnvelope setStickPoint: MAXINT];                
        else
            [theEnvelope setStickPoint: hitpt];
        [self selectPoint: hitpt];
        hitpt=-1;
    }
    
    if (hitpt >= 0) {                                    // Move hitpt as mouse drags
        [self selectPoint: hitpt];                       // select and redraw image
// TODO dunno if this should be here, probably during init, perhaps replace with tracking rectangle?
        [[self window] setAcceptsMouseMovedEvents: YES];
        
        [self lockFocus];
        [theFilledCross push];                           // use cursor = cross+knob
        [self eraseSelectedKnob];
        while ([event type] != NSLeftMouseUp) {
            ep = [self convertPoint: [event locationInWindow] fromView: nil];
            if ([event type] == NSLeftMouseDragged) {
                p.x = pixToX(ep.x);
                p.y = pixToY(ep.y);
                [self movePoint: hitpt to: p];
                [theController updateCoords: self at: hitpt];
            }
            event = [[self window] nextEventMatchingMask: DRAG_MASK];
        }
        [NSCursor pop];                                   // return to crosshair cursor
        [self unlockFocus];
    }
    [self display];
}

//===================================================================
// Messages received from window to change first responder status
//===================================================================

//-------------------------------------------------------------------
// highlight

- (void) highlight
{
    envColour = BLACK;
    [self display]; 
}

//-------------------------------------------------------------------
// dim

- (void) dim
{
    envColour = DKGRAY;
    [self display]; 
}

//-------------------------------------------------------------------
// acceptsFirstResponder: 

- (BOOL) acceptsFirstResponder
{
    return YES;
}

//-------------------------------------------------------------------
// becomeFirstResponder: 

- (BOOL) becomeFirstResponder
{
    if (theController != nil)
        [(Controller *)theController update: self];
    envColour = BLACK;
    [self display];
    return YES;
}

//-------------------------------------------------------------------
// resignFirstResponder: 

- (BOOL) resignFirstResponder
{
    return YES;
}

//===================================================================
// Pasteboard interface methods
//===================================================================

//-------------------------------------------------------------------
// copy: -- Copy the current envelope to the pasteboard

- (void) copy: (id) sender
{
    int point;                        // current point
    enum { STYLE_MK, STYLE_pX_Yp, STYLE_pXcYp, STYLE_X_Y, STYLE_XcY, STYLE_X_Y_Zc, STYLE_XcYcZ_, STYLE_ppX_Yp }
        selectedStyle = STYLE_MK;     // number representing the style
    NSString *style;                  // string representing the style
    NSArray *types;
    NSMutableString *stringToCopy = [NSMutableString stringWithCapacity: 1024];          // output string
    
    if (theController != nil) {       // get current selected style
        style = [theController getStyle];
        if (style != nil) {
            if ([style isEqualToString: @"MusicKit"]) selectedStyle = STYLE_MK;
            if ([style isEqualToString: @"(x y ...)"]) selectedStyle = STYLE_pX_Yp;
            if ([style isEqualToString: @"(x,y ...)"]) selectedStyle = STYLE_pXcYp;
            if ([style isEqualToString: @"x y ..."]) selectedStyle = STYLE_X_Y;
            if ([style isEqualToString: @"x,y ..."]) selectedStyle = STYLE_XcY;
            if ([style isEqualToString: @"x,y,z ..."]) selectedStyle = STYLE_XcYcZ_;
            if ([style isEqualToString: @"x y z,..."]) selectedStyle = STYLE_X_Y_Zc;
            if ([style isEqualToString: @"((x y)...)"]) selectedStyle = STYLE_ppX_Yp;
        }
    }

    switch(selectedStyle) {
    case STYLE_MK:
        [stringToCopy appendString: @"["];
        for (point = 0; point < pointCount; point++) {
            [stringToCopy appendFormat: @"(%5.3f,%5.3f", xValues[point], yValues[point]];
            if (sValues[point] != defaultSmooth)
                [stringToCopy appendFormat: @",%5.3f", sValues[point]];
            [stringToCopy appendString: @")"];
            if (stickyPoint == point) 
                [stringToCopy appendString: @"|"];
        }
        [stringToCopy appendString: @"]"];
        break;

    case STYLE_pX_Yp:
        [stringToCopy appendString: @"("];
        for (point = 0; point < pointCount - 1; point++)
            [stringToCopy appendFormat: @"%5.3f %5.3f ", xValues[point], yValues[point]];
        [stringToCopy appendFormat: @"%5.3f %5.3f)", xValues[pointCount-1], yValues[pointCount-1]]; 
        break;

    case STYLE_pXcYp:
        [stringToCopy appendString: @"("];
        for (point = 0; point < pointCount - 1; point++)
            [stringToCopy appendFormat: @"%5.3f,%5.3f,", xValues[point], yValues[point]];
        [stringToCopy appendFormat: @"%5.3f,%5.3f)", xValues[pointCount-1], yValues[pointCount-1]]; 
        break;

    case STYLE_X_Y:
        for (point = 0; point < pointCount - 1; point++)
            [stringToCopy appendFormat: @"%5.3f %5.3f ", xValues[point], yValues[point]];
        [stringToCopy appendFormat: @"%5.3f %5.3f", xValues[pointCount-1], yValues[pointCount-1]]; 
        break;
            
    case STYLE_XcY:
        for (point = 0; point < pointCount - 1; point++)
            [stringToCopy appendFormat: @"%5.3f,%5.3f,", xValues[point], yValues[point]];
        [stringToCopy appendFormat: @"%5.3f,%5.3f", xValues[pointCount-1], yValues[pointCount-1]];
        break;

    case STYLE_XcYcZ_:
        for (point = 0; point < pointCount - 1; point++)
            [stringToCopy appendFormat: @"%5.3f,%5.3f,%5.3f ", xValues[point], yValues[point], sValues[point]];
        [stringToCopy appendFormat: @"%5.3f,%5.3f,%5.3f", xValues[pointCount-1], yValues[pointCount-1], sValues[pointCount-1]];
        break;

    case STYLE_X_Y_Zc:
        for (point = 0; point < pointCount - 1; point++)
            [stringToCopy appendFormat: @"%5.3f %5.3f %5.3f,", xValues[point], yValues[point], sValues[point]];
        [stringToCopy appendFormat: @"%5.3f %5.3f %5.3f", xValues[pointCount-1], yValues[pointCount-1], sValues[pointCount-1]];
        break;

    case STYLE_ppX_Yp:
        [stringToCopy appendString: @"("];
        for (point = 0; point < pointCount - 1; point++)
            [stringToCopy appendFormat: @"(%5.3f %5.3f)", xValues[point], yValues[point]];
        [stringToCopy appendFormat: @"(%5.3f %5.3f))", xValues[pointCount-1], yValues[pointCount-1]];
        break;

    }
    types = [NSArray arrayWithObject: NSStringPboardType];
    [[NSPasteboard generalPasteboard] declareTypes: types owner: self];
    if(![[NSPasteboard generalPasteboard] setString: stringToCopy forType: NSStringPboardType])
	NSLog(@"Unable to copy %@\n", stringToCopy);
}

//-------------------------------------------------------------------
// paste: -- Paste the current pasteboard contents into the view. The
// method parses the text representation of the envelope automatically
// deciding on the type of envelope received. The internal representation
// is a standard MusicKit envelope object.

// Get next token from a string (symbol or number)

#define NUMBER 0

char *data;

// Parse the data stream in tokens representing symbols and numbers

int token(char *t)
{
    char c;
    int i;
    
    while (((t[0]=c=*data++) == ' ')||(c == '\t')||(c == '\n'));
    t[1]='\0';
    if (c=='\0') {
        data--;
        return EOF;
    }
    if (!isdigit(c) && c!= '.' && c!= '-')
        return c;        
    i=0;                            // collect a number stream
    if (c=='-')
        t[++i]=c=*data++;
    if (isdigit(c))
        while (isdigit(t[++i]=c=*data++));
    if (c == '.')
        while (isdigit(t[++i]=c=*data++));
	
    if ((c == 'e')||(c == 'E')) {
        t[++i]=c=*data++;
    	if (c=='-')
            t[++i]=c=*data++;
    	if (isdigit(c))
            while (isdigit(t[++i]=c=*data++));
    }
    
    t[i]='\0';
    if (c!='\0')
        data--;
    return NUMBER;
}

- (void) paste: (id) sender
{
    char *orig, tk[1024];
    int   symb;
    unsigned int length;
    NSString *prs;
    NSArray *pastetypes;
    int sticky, point;

    pastetypes = [[NSPasteboard generalPasteboard] types];    
    prs = [[NSPasteboard generalPasteboard] stringForType:NSStringPboardType];
    if (prs != nil) {                            // if ASCII in pasteboard...
	length = [prs maximumLengthOfBytesUsingEncoding: NSUTF8StringEncoding];
// TODO change calloc to object declaration.	
        data = orig = calloc(length + 16,sizeof(char));     // copy data to local buffer
        strncpy(data, [prs UTF8String], length);
        
        point=0;                                      // start by converting point 0
        sticky=MAXINT;                                // no sticky point by default
        allocateTemp(64);                             // 64 points long by default
        
        if ((symb = token(tk)) == '(') {
	    if ((symb = token(tk)) == '(') {
	    
    // parse a list of lists type envelope
    // accepted syntax: "((x0 y0)...(xn yn))" or "((x0,y0)...(xn,yn))"

            while((symb != ')') && (symb != -1)) {
	        symb = token(tk);                       // should be "x" component
                if (symb != NUMBER) {                   // must be x component
                    NSRunAlertPanel(@"Error", @"Expected x component at:\n\"%s\"\nin:\n\"%s\"", @"", nil,
			@"Continue", data - 1, orig);
                    break;
                }
                else {
                    temp->x[point] = atof(tk);           // convert "x" component!
                    temp->y[point] = 0.0;                // and set defaults
                    temp->s[point] = defaultSmooth;
                }
		symb=token(tk);
                if (symb!=NUMBER) {
                    NSRunAlertPanel(@"Error", @"Expected y component at:\n\"%s\"\nin:\n\"%s\"", @"", nil,
			@"Continue", data - 1, orig);
                    break;
                }
                else {
                    temp->y[point] = atof(tk);        // convert "y" component
                    point++;                          // count a complete envelope node
                    allocateTemp(point + 1);
                }
                if ((symb = token(tk)) != ')') {
                    NSRunAlertPanel(@"Error", @"Expected closing parenthesis at:\n\"%s\"\nin:\n\"%s\"", @"", nil,
			@"Continue", data - 1, orig);
                    break;
                }
                else symb = token(tk);
            }
            showSmooth = NO;                            // only MK shows smoothing by default
	    }	
	else {
	
    // parse a CLM type envelope
    // accepted syntax: "(x0 y0 ... xn yn)" or "(x0,y0, ... xn,yn)"
            
            while((symb != ')') && (symb != -1)) {
                if (symb == ',') symb = token(tk);      // ignore commas between xy pairs
                if (symb != NUMBER) {                   // must be x component
                    NSRunAlertPanel(@"Error", @"Expected x component at:\n\"%s\"\nin:\n\"%s\"", @"", nil,
			@"Continue", data-1,orig);
                    break;
                }
                else {
                    temp->x[point] = atof(tk);          // convert "x" component!
                    temp->y[point] = 0.0;               // and set defaults
                    temp->s[point] = defaultSmooth;
                }
                if ((symb = token(tk)) == ',')          // ignore commas between values
                    symb = token(tk);
                if (symb != NUMBER) {
                    NSRunAlertPanel(@"Error", @"Expected y component at:\n\"%s\"\nin:\n\"%s\"", @"", nil,
			@"Continue", data - 1, orig);
                    break;
                }
                else {
                    temp->y[point] = atof(tk);          // convert "y" component
                    point++;                            // count a complete envelope node
                    allocateTemp(point + 1);
                }
                symb = token(tk);
            }
            showSmooth = NO;                            // only MK shows smoothing by default
        }
	}
        else if (symb == '[')    {    
        
            // parse a MusicKit envelope, uses normal MusicKit syntax
            
            symb = token(tk);                           // should be starting '(' or '|'
            while((symb == '(') || (symb == '|')) {
                if (symb == '|') {
                    sticky = point - 1;                 // last point was the sticky point
                    symb = token(tk);                   // should be '(' or the end
                    continue;
                }
                if ((symb = token(tk)) != NUMBER) {     // break if not a number
                    NSRunAlertPanel(@"Error", @"Expected x component at:\n\"%s\"\nin:\n\"%s\"", @"", nil, @"Continue", data-1,orig);
                    break;
                }
                else {
                    temp->x[point] = atof(tk);         // convert "x" component!
                    temp->y[point] = 0.0;
                    temp->s[point] = defaultSmooth;
                }
                if ((symb=token(tk))==',')             // skip comma but also accept a space
                    symb=token(tk);
                if (symb!=NUMBER) {                    // break if not a number
                    NSRunAlertPanel(@"Error", @"Expected y component at:\n\"%s\"\nin:\n\"%s\"", @"", nil, @"Continue", data-1,orig);
                    break;
                }
                else {
                    temp->y[point] = atof(tk);           // convert "y" component
                }
                if ((symb = token(tk)) == ',')             // is there a smoothing component?
                    if ((symb = token(tk)) == NUMBER) {    // if number...
                        temp->s[point] = atof(tk);       // convert smoothing component
                        symb = token(tk);
                    }
                point++;                               // count a complete envelope node
                allocateTemp(point + 1);

                if (symb != ')') {                       // must be point's closing parenthesis
                    NSRunAlertPanel(@"Error", @"Expected a ')' at:\n\"%s\"\nin:\n\"%s\"", @"", nil, @"Continue", data-1,orig);
                    break;
                }
                symb = token(tk);
            }
            showSmooth = YES;
        }
        else if (symb == NUMBER) {

    // parse a x-y-<z> pair type envelope
    // accepted syntax: "x0 y0 ... xn yn" or "x0,y0, ... xn,yn" for xy pairs
    // accepted syntax: "x0,y0,z0 x1,y1,z1 ..." or " x0 y0 z0,x1 y1 z1, ..." for xyz sets
            
            int commas = 0;
            double last_value = 0.0;
            int pending = 0;

            while(symb != -1) {
                if (pending == 0) {
                    if (symb != NUMBER) {                  // not a number!
                        NSRunAlertPanel(@"Error", @"Expected x component at:\n\"%s\"\nin:\n\"%s\"", @"", nil,
			    @"Continue", data-1,orig);
                        break;
                    }
                    else {
                        temp->x[point] = atof(tk);        // convert "x" component!
                        temp->y[point] = 0;
                        temp->s[point] = defaultSmooth;
                    }
                    if ((symb = token(tk)) == ',') {
                        commas++;
                        symb = token(tk);
                    }
                }
                else {
                    temp->x[point] = last_value;
                    temp->y[point] = 0.0;
                    temp->s[point] = defaultSmooth;
                    pending = 0;
                }
                if (symb!=NUMBER) {
                    NSRunAlertPanel(@"Error", @"Expected y component at:\n\"%s\"\nin:\n\"%s\"", @"", nil,
			@"Continue", data - 1, orig);
                    break;
                }
                else temp->y[point] = atof(tk);        // convert "y" component
                if ((symb = token(tk)) == ',') {
                    commas++;
                    symb = token(tk);
                }
                if (symb == -1) {
                    point++;
                    allocateTemp(point + 1);
                    break;
                }
                else {
                    if (symb != NUMBER) {
                        NSRunAlertPanel(@"Error", @"Expected x or z component at:\n\"%s\"\nin:\n\"%s\"", @"", nil,
			    @"Continue", data-1,orig);
                        break;
                    }
                    else last_value = atof(tk);
                    if ((((symb = token(tk)) != ',') && (commas == 2)) ||
                         ((symb == ',') && (commas == 0))) {
                        temp->s[point] = last_value;
                        pending = 0;
                        commas = 0;
                    }
                    else {
                        pending = 1;
                        commas = 1;
                    }
                    point++;
                    allocateTemp(point + 1);
                }
                if (symb==',') symb = token(tk);
            }
            showSmooth = NO;                            // only MK shows smoothing by default
        }
        else
            NSRunAlertPanel(@"Error", @"The envelope must start with '[','(' or a number:\n\"%s\"", @"", nil,
		@"Continue", orig);
        
        if (point < 2) {                                // if envelope has less than 2 nodes
            NSRunAlertPanel(@"Error", @"Less than 2 legal points in envelope:\n\"%s\"", @"", nil, @"Continue", orig);
        }
        else {
            [theEnvelope setPointCount: point
                                xArray: temp->x
                      orSamplingPeriod: 1.0
                                yArray: temp->y
                        smoothingArray: temp->s
                    orDefaultSmoothing: defaultSmooth];
            [theEnvelope setStickPoint: sticky];      // update envelope object
            allocateDraw(temp->max); //(pointCount);                 // resize drawing arrays
            [self scaleLimits];                       // define drawing limits
        }
        if (selected < pointCount)
            [self selectPoint: selected];
        else
            [self selectPoint: 0];                    // display and update controller
        free(orig);                                   // free local copy of data
    }
}

//===================================================================
// Messages received from controller to change parameters
//===================================================================

//-------------------------------------------------------------------
// setPointTo: set current point to n (as a side effect updates values
// of x and y coordinates on the controller object
 
- (void) setPointTo: (int) point
{
    if (point >= pointCount)
        point = pointCount-1;
    if (point < 0)
        point = 0;
    [self selectPoint: point];
    [(Controller *)theController update:self]; 
}

//-------------------------------------------------------------------
// nextPoint go to the next point in the envelope if possible
 
- (void) nextPoint
{
    int next;
    
    next=selected+1;
    if (next>=pointCount) next=selected;
    if (next<0) next=0;
    if (next!=selected) {
        [self selectPoint:next];
        [(Controller *)theController update:self];
    } 
}

//-------------------------------------------------------------------
// previousPoint go to the previous point in the envelope if possible
 
- (void) previousPoint
{
    int previous;
    
    previous = selected - 1;
    if (previous >= pointCount)
	previous = selected;
    if (previous < 0)
	previous = 0;
    if (previous != selected) {
        [self selectPoint: previous];
        [(Controller *)theController update: self];
    } 
}

//-------------------------------------------------------------------
// setXAt:to: changes value of x coordinate of point n
- setXAt: (int) n to: (float) coord
{
    if (n != 0 && coord < xValues[n - 1])             // force selected point to be within
        coord = xValues[n - 1];                     // enclosing points
    if (n != pointCount - 1 && coord > xValues[n + 1]) 
        coord = xValues[n + 1];
    if (coord != xValues[n]) {                    // if x changed update display panel
        xValues[n] = coord;
        [self display];
        [(Controller *)theController update: self];
    }
    return self;
}

//-------------------------------------------------------------------
// setYAt:to: changes value of y coordinate of point n
- setYAt: (int) n to: (float) coord
{
    if (coord > yMax) coord = yMax;                // clip y values to max and min
    if (coord < yMin) coord = yMin;
    
    if (coord != yValues[n]) {                   // if y changed update display panel
        yValues[n] = coord;
        [self display];
        [(Controller *)theController update: self];
    }
    return self;
}

//-------------------------------------------------------------------
// setYrAt:to: changes value of real y coordinate of point n
 
- setYrAt: (int) n to: (float) coord
{
    double y;
    
    if (coord > yMax) coord=yMax;               // clip y values to max and min
    if (coord < yMin) coord=yMin;
    
    if (n == 0) return self;                    // no sense to change this in first point
    
    draw->yr[n] = coord;
    y = (coord - yValues[n - 1] * exp(-5.5262 / sValues[n])) / (1 - exp(-5.5262 / sValues[n]));
    [self setYAt: n to: y];
    return self;
}

//-------------------------------------------------------------------
// setSmoothAt:to: changes value of smoothing of point n
 
- setSmoothAt: (int) n to: (float) value
{
    if (value != sValues[n]) {                  // if smoothing changed update panel
        sValues[n] = value;
        [self display];
        [(Controller *)theController update: self];
    }
    return self;
}

//-------------------------------------------------------------------
// setXMinTo: changes minimum value of x component of envelope
 
- (void) setXMinTo: (float) coord
{
    if (coord < xMax) {
        xMin = coord;
        [self display];
    }
    else if (theController != nil)
        [(Controller *)theController update: self]; 
}

//-------------------------------------------------------------------
// setXMaxTo: changes maximun value of x component of envelope
 
- (void) setXMaxTo: (float) coord
{
    if (coord > xMin) {
        xMax = coord;
        [self display];
    }
    else if (theController != nil)
        [(Controller *)theController update: self]; 
}

//-------------------------------------------------------------------
// setXLimitsTo:: changes max and min values of x component
 
- setXLimitsTo: (float) min : (float) max
{
    xMin = min;
    xMax = max;
    [self display];
    return self;
}

//-------------------------------------------------------------------
// setYMinTo: changes minimum value of y component of envelope
 
- (void) setYMinTo: (float) coord
{
    if (coord < yMax) {
        yMin = coord;
        [self display];
    }
    else if (theController != nil)
        [(Controller *)theController update: self]; 
}

//-------------------------------------------------------------------
// setYMaxTo: changes maximun value of y component of envelope
 
- (void) setYMaxTo: (float) coord
{
    if (coord > yMax) {
        yMax = coord;
        [self display];
    }
    else if (theController != nil)
        [(Controller *)theController update: self]; 
}

//-------------------------------------------------------------------
// setXSnapTo: changes value of x Snap
 
- (void) setXSnapTo: (float) coord
{
    xSnap = coord;
    [self display]; 
}

//-------------------------------------------------------------------
// setYSnapTo: changes value of y Snap
 
- (void) setYSnapTo: (float) coord
{
    ySnap = coord;
    [self display]; 
}

//-------------------------------------------------------------------
// setStickyAt:To: sets point to be the sticky point of envelope
 
- (void) setStickyAt: (int) point To: (int) state
{
    if (state == 0)
        [theEnvelope setStickPoint: MAXINT];
    else
        [theEnvelope setStickPoint: point];
    [(Controller *)theController update: self];
    [self display]; 
}

//-------------------------------------------------------------------
// setShowSmooth: sets type of graphics to be used
 
- (void) setShowSmooth: (BOOL) state
{
    showSmooth = state;
    [self display];
    [(Controller *)theController update: self]; 
}

//-------------------------------------------------------------------
// setDrawSegments: choose to draw segments or only points
 
- (void) setDrawSegments: (BOOL) state
{
    drawSegments = state;
    [self display];
    [(Controller *)theController update: self]; 
}

//-------------------------------------------------------------------
// scaleLimits computes the max and min bounds of the view
 
- (void) scaleLimits
{
    double xmin, xmax, ymin, ymax;
    int point;
    
    xmin = xmax = xValues[0];
    ymin = ymax = yValues[0];
    for (point = 1; point < pointCount; point++) {
        if (xValues[point] < xmin) xmin = xValues[point];
        if (xValues[point] > xmax) xmax = xValues[point];
        if (yValues[point] < ymin) ymin = yValues[point];
        if (yValues[point] > ymax) ymax = yValues[point];
    }
    xMax = xmax;
    xMin = xmin;
    if (ymax >= 0.0 && ymax <= 10.0)
        yMax = floor(ymax * 10 + 1.0) / 10;
    else
        yMax = floor(ymax + 1.0);
    if (ymin <= 0.0 && ymin >= -1.0)
        yMin = floor(ymin * 10 - 1.0) / 10;
    else
        yMin = floor(ymin - 1.0);
    if (ymin == 0)
	yMin = ymin;
    
    [self display]; 
}

//===================================================================
// Messages received from controller to query for envelope values
//===================================================================

//-------------------------------------------------------------------
// (int)getPoint Return the selected point

- (int) getPoint
{
    return selected;
}

//-------------------------------------------------------------------
// (float)getX:(int)i Return value of x component of point i

- (float) getX: (int) i
{
    if (i >= pointCount) 
	i = pointCount - 1;
    if (i < 0)
	i = 0;
    return xValues[i];
}

//-------------------------------------------------------------------
// (float)getY:(int)i Return value of y component of point i

- (float) getY: (int) i
{
    if (i >= pointCount)
	i = pointCount - 1;
    if (i < 0) 
	i = 0;
    return yValues[i];
}

//-------------------------------------------------------------------
// (float)getYr:(int)i Return value of real y component of point i

- (float) getYr: (int) i
{
    if (i >= pointCount) 
	i = pointCount - 1;
    if (i < 0) 
	i = 0;
    return draw->yr[i];
}

//-------------------------------------------------------------------
// (float)getSmoothing:(int)i Return value of smoothing of point i

- (float) getSmoothing: (int) i
{
    if (i >= pointCount) 
	i = pointCount - 1;
    if (i < 0)
	i = 0;
    return sValues[i];
}

//-------------------------------------------------------------------
// (int)getSticky:(int)i Return value of stickyness of point i

- (int) getSticky: (int) i
{
    if (i>=pointCount) 
	i = pointCount-1;
    if (i < 0)
	i = 0;
    if (stickyPoint == i)
        return 1;
    else
        return 0;
}

//-------------------------------------------------------------------
// (float) getXMax 

- (float) getXMax 
{ 
    return xMax;
}

//-------------------------------------------------------------------
// (float)getXMin 

- (float) getXMin 
{
    return xMin;
}

//-------------------------------------------------------------------
// (float)getYMax 

- (float) getYMax
{
    return yMax;
}

//-------------------------------------------------------------------
// (float)getYMin 

- (float) getYMin
{
    return yMin;
}

//-------------------------------------------------------------------
// (float)getXSnap 

- (float) getXSnap
{
    return xSnap;
}

//-------------------------------------------------------------------
// (float)getYSnap 

- (float) getYSnap
{
    return ySnap;
}

//-------------------------------------------------------------------
- (BOOL) getShowSmooth
{
    return showSmooth;
}

//-------------------------------------------------------------------
- (BOOL) getDrawSegments
{
    return drawSegments;
}

@end

