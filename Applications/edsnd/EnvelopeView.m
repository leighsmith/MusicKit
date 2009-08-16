/* EnvelopeView.m -- Implementation of EnvelopeView class
 *
 * For info, see EnvelopeView.h
 *
 * jwp@silvertone.Princeton.edu, 12/89
 */

#import "EnvelopeView.h"
#import "PWenv.h"
#import <dpsclient/wraps.h>
#import <appkit/Application.h>
#import <stdlib.h>

/* Shorthand for making new EnvPoints:
 */
#define MAKENODE() (EnvPoint *)malloc(sizeof(EnvPoint))

/* Macro to draw a 7 pixel-wide knob around a point (x,y)
 */
#define DRAWKNOB(x,y) PScompositerect(x-3,y-3,7,7,NX_HIGHLIGHT)

/* Shorthand for view dimensions:
 */
#define WIDTH bounds.size.width
#define HEIGHT bounds.size.height

/* Grayscale values for PostScript
 */
#define WHITE 1.0
#define BLACK 0.0

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */
/* C functions needed by EnvelopeView
 *
 *	getpoint(n,ep) returns a pointer to node number n in list ep
 *	getinsert(pt,ep) finds the point at which point pt should
 *		be inserted into the list.  Returns -1 on error.
 */

EnvPoint *getpoint(n,ep)
int n;
EnvPoint *ep;
{
	while (n--)
		ep = ep->next;
	return ep;
}

int getinsert(pt,ep)
NXPoint *pt;
EnvPoint *ep;
{
	int inacol;		/* Number of pts with identical x coords */
	int n;
	float x = pt->x;	/* copy of x coord of pt */
	float lastx = 2;

	for (n = inacol = 0; ep; ep = ep->next, n++) {
		if (ep->p.x > x)		/* Break at first x > pt */
			break;
		if (ep->p.x == lastx)
			inacol++;
		else
			inacol = 0;
		lastx = ep->p.x;
	}
	if (lastx == x && inacol)		/* Can't have 3 in a column */
		return -1;
	else
		return n-1;
}

/* testHit(pt,ep) checks to see whether pt lands on any knob.  If so,
 * 	it returns the number of that point, else -1
 */
int testHit(pt,ep,dx,dy)
NXPoint *pt;
EnvPoint *ep;
float dx,dy;		/* Size of knob (in envelope coords) */
{
	float x,y,kx,ky;
	int n;

	x = pt->x;		/* Local copies of x and y */
	y = pt->y;

/* Test each point in the envelope.  This loop exits when a hit
 * is found, or when we go past x in the envelope, or when there
 * are no more points to test.
 */
	for (n = 0; ep; ep = ep->next, n++) {
		kx = ep->p.x;
		ky = ep->p.y;
		if (x < kx-dx)		/* No hope of a match now */
			break;
		if (x <= kx+dx && x >= kx-dx &&
		    y <= ky+dy && y >= ky-dy)
		    return n;
	}
	return -1;
}

/* draw1(ep,grayval) draws one line segment from ep to ep->next
 * draw2(ep,grayval) draws two segments (ep->last to ep to ep->next)
 */

draw1(ep,grayval,width,height)
EnvPoint *ep;
float grayval;
float width;
float height;
{
	float x1,y1,x2,y2;	/* Coordinates */

	x1 = (ep->p.x) * width;
	y1 = (ep->p.y) * height;
	ep = ep->next;
	x2 = (ep->p.x) * width;
	y2 = (ep->p.y) * height;

	PWdraw1(x1,y1,x2,y2,grayval);
}

draw2(ep,grayval,width,height)
EnvPoint *ep;
float grayval,width,height;
{
	float x1,y1,x2,y2,x3,y3;
	ep = ep->last;
	x1 = ep->p.x * width;
	y1 = ep->p.y * height;
	ep = ep->next;
	x2 = ep->p.x * width;
	y2 = ep->p.y * height;
	ep = ep->next;
	x3 = ep->p.x * width;
	y3 = ep->p.y * height;

	PWdraw2(x1,y1,x2,y2,x3,y3,grayval);
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */


@implementation EnvelopeView


/* + newFrame:  -- create a new object and initialize
 */
+ newFrame:(const NXRect *)frameRect
{
	EnvPoint *a, *b;	/* Start/end points of envelope */

        self = [super newFrame:frameRect];
	envelope = a = MAKENODE();
	b = MAKENODE();

/* Start-up points are at (0,0.5) and (1,0.5)
 */
 	a->p.x = 0.0;
	b->p.x = 1.0;
	a->p.y = b->p.y = 0.5;
	a->next = b;			/* They point to each other */
	b->last = a;
	a->last = NULL;			/* And to nowhere */
	b->next = NULL;
	npoints = 2;

	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* envelope:	-- Get the envelope as an array of NXPoints.
 * 	Returns the number of points in the array.
 */
- (int) envelope:(NXPoint **)envptr
{
	NXPoint *a;		/* Local copy of array pointer */
	EnvPoint *ep;		/* Pointer into envelope list */

/* Make the array of npoints NXPoint structs
 */
	a = *envptr = (NXPoint *)malloc(npoints * sizeof(NXPoint));

/* Go down the list, fill up the array, and return the number of
 * points.
 */
	for (ep = envelope; ep; ep = ep->next, a++)
		*a = ep->p;

	return npoints;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* setEnvelope:Points:	-- Set the envelope from an array of NXPoints
 */
- setEnvelope:(NXPoint *)env Points:(int)n
{
	EnvPoint *ep, *tmp;
	int i;
	float lastx;

/* Test this envelope to see if it's valid
 */
	if (n < 2)			/* Must have at least 2 points */
		return self;
	if (env[0].x != 0 || env[n-1].x != 1)
		return self;
	for (i = 1, lastx = 0; i < n; lastx = env[i].x, i++)
		if (env[i].x < lastx || env[i].y > 1 || env[i].y < 0)
			return self;
	npoints = n;

/* Free up the old envelope space
 */
	ep = envelope;
	while (ep) {
		tmp = ep->next;
		free(ep);
		ep = tmp;
	}

/* Make the new envelope
 */
	envelope = MAKENODE();
	envelope->p = *env++;
	envelope->last = NULL;
	n--;
	for (ep = envelope; n; n--, env++) {
		ep->next = tmp = MAKENODE();
		tmp->p = *env;
		tmp->last = ep;
		tmp->next = NULL;
		ep = tmp;
	}

	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* movePoint:To: -- Move a point to a new location.
 * Points are numbered from 0.
 * Returns -1 if disallowed; otherwise returns the number of the point.
 */
- (int) movePoint:(int)n To:(NXPoint *)pt
{
	EnvPoint *ep;

/* Determine the legality of this move:
 */

	if (n < 0 || n >= npoints)		/* Must be valid point */
		return -1;

	ep = getpoint(n,envelope);		/* Get it */
	if (pt->y > 1) pt->y = 1;	/* Put y in range */
	if (pt->y < 0) pt->y = 0;

/* Put x in proper range
 */
	if (n == 0) pt->x = 0;
	else if (n == npoints-1) pt->x = 1;
	else {
		if (pt->x < ep->last->p.x) pt->x = ep->last->p.x;
		else if (pt->x > ep->next->p.x) pt->x = ep->next->p.x;
	}

/* Avoid 3 in a column
 */
	if (n > 1)
		if (pt->x == ep->last->p.x && pt->x == ep->last->last->p.x)
			pt->x = ep->last->p.x + 1/WIDTH;
	if (n < (npoints-2))
		if (pt->x == ep->next->p.x && pt->x == ep->next->next->p.x)
			pt->x = ep->next->p.x - 1/WIDTH;

/* Undraw the old lines, set the new point, and draw the new lines
 */
 	[self lockFocus];
	if (n == 0)			  /* Only one segment to undraw for */
		draw1(ep,WHITE,WIDTH,HEIGHT);  /*	endpoints 	*/
	else if (n == npoints-1)
		draw1(ep->last,WHITE,WIDTH,HEIGHT);
	else
		draw2(ep,WHITE,WIDTH,HEIGHT);

	ep->p = *pt;
	if (n == 0)
		draw1(ep,BLACK,WIDTH,HEIGHT);
	else if (n == (npoints-1))
		draw1(ep->last,BLACK,WIDTH,HEIGHT);
	else
		draw2(ep,BLACK,WIDTH,HEIGHT);
	[self unlockFocus];
	[[self window] flushWindow];

	return n;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* addPoint:  -- Adds a point to the envelope
 * Returns number of new point, -1 on error
 */
- (int) addPoint:(NXPoint *)pt
{
	EnvPoint *ep;
	int n;

/* Determine validity of this point.
 */
	if (pt->x < 0 || pt->x >= 1 || pt->y < 0 || pt->y > 1)
		return -1;

	if ((n = getinsert(pt,envelope)) < 0)
		return -1;

	ep = MAKENODE();
	ep->p = *pt;
	ep->last = getpoint(n,envelope);
	ep->next = ep->last->next;

/* Undraw the old segment, insert this point, then draw the new segments
 */

	[self lockFocus];
	draw1(ep->last,WHITE,WIDTH,HEIGHT);

	ep->last->next = ep->next->last = ep;
	npoints++;

	draw2(ep,BLACK,WIDTH,HEIGHT);
	[self unlockFocus];
	[window flushWindow];

	return n+1;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* rmPoint: -- Remove a point from the envelope
 * Returns the new npoints or -1 on error
 */
- (int) rmPoint:(int)n
{
	EnvPoint *ep;

/* Determine the validity of this point
 */
	if (n <= 0 || n >= npoints-1)
		return -1;

	ep = getpoint(n,envelope);

/* Undraw the old segments, remove the point, then draw the new segment
 */

	[self lockFocus];
	draw2(ep,WHITE,WIDTH,HEIGHT);
	ep->last->next = ep->next;
	ep->next->last = ep->last;
	draw1(ep->last,BLACK,WIDTH,HEIGHT);
	[self unlockFocus];
	[window flushWindow];

	free(ep);
	npoints--;

	return npoints;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* npoints -- Returns the number of points in the envelope
 */
- (int) npoints
{
	return npoints;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

- setDelegate:anObject
{
	delegate = anObject;
	return self;
}

- delegate
{
	return delegate;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

- (BOOL) acceptsFirstResponder
{
	return YES;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */
#define DRAG_MASK (NX_MOUSEUPMASK|NX_MOUSEDRAGGEDMASK)

/* mouseDown:  -- Responds to a mousedown event
 */

- mouseDown:(NXEvent *)event
{
	NXPoint eventp;		/* Copy of event point */
	NXPoint pt;		/* To hold converted x/y values */
	int hitpt;		/* Point to move/remove */
	BOOL changed = NO;	/* Has envelope changed? */
	int oldMask;

/* Convert pixel coordinates to envelope coordinates.
 */
 	eventp = event->location;
	[self convertPoint:&eventp fromView:nil];

	pt.x = eventp.x / WIDTH;
	pt.y = eventp.y / HEIGHT;

/* Did we hit a knob? If so, which one?
 */
	hitpt = testHit(&pt,envelope,4/WIDTH,4/HEIGHT);

/* With shift key down, hit = remove point, nohit = add point.
 */
	if (event->flags & NX_SHIFTMASK) {
		if (hitpt >= 0) {
			if ([self rmPoint:hitpt] > 0)
				changed = YES;
			hitpt = -1;
		}
		else
			hitpt = [self addPoint:&pt];
	}


/* Move hitpt as mouse drags
 */
	if (hitpt >= 0) {
		changed = YES;
        	oldMask = [[self window] addToEventMask:DRAG_MASK];
		while (event->type != NX_MOUSEUP) {
 			eventp = event->location;
			[self convertPoint:&eventp fromView:nil];
			pt.x = eventp.x / WIDTH;
			pt.y = eventp.y / HEIGHT;
			[self movePoint:hitpt To:&pt];
			if (delegate &&
			    [delegate respondsTo:@selector(point:MovedTo:)])
				[delegate point:hitpt MovedTo:&pt];
			event = [NXApp getNextEvent:DRAG_MASK];
		}
	}

/* Notify delegate if envelope changed
 */
	if (changed &&
	    delegate && [delegate respondsTo:@selector(envelopeChanged:)])
		[delegate envelopeChanged:self];

	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* drawSelf:: -- Draw the envelope in the view
 */
- drawSelf:(NXRect *)rects :(int)rectCount
{
	EnvPoint *ep;
	float x,y;
/* Clear the view first
 */
        NXEraseRect(&bounds);
	PSsetgray(0);

/* Draw all the line segments
 */
	if (!(ep = envelope))
		return self;

	x = ep->p.x * WIDTH;
	y = ep->p.y * HEIGHT;
	PSnewpath();
	PSmoveto(x,y);
	for (ep = envelope->next; ep; ep=ep->next) {
		x = ep->p.x * WIDTH;
		y = ep->p.y * HEIGHT;
		PSlineto(x,y);
	}
	PSstroke();

/* Draw all the knobs
 */
	for (ep = envelope; ep; ep=ep->next) {
		x = ep->p.x * WIDTH;
		y = ep->p.y * HEIGHT;
		DRAWKNOB(x,y);
	}

	return self;
}

@end


