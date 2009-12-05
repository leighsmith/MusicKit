/* EnvelopeView.h -- Interface for EnvelopeView class
 * 
 * This is a sub-class of View that allows the user to draw a
 * simple line segment envelope.  The envelope appears in the
 * view as a series of line segments with square "knobs" at
 * the junction points.  The envelope is manipulated by click-dragging
 * these knobs.  Shift-clicking will create a new point (and
 * hence add a segment).  Shift-clicking on an existing knob removes
 * it (and hence removes a segment).  Moving, adding, and removing
 * junction points can be accomplished programatically as well.
 * Points are numbered from 0.
 *
 * The envelope is recorded as a series of NXPoints which represent
 * the junction points.  Both the x and y coordinates of these
 * points are floats in the range 0 to 1.  The EnvelopeView will
 * return a pointer to an array of NXPoints representing the envelope,
 * and the envelope can be set by passing a pointer to such an array.
 *
 * jwp@silvertone.Princeton.edu, 12/89
 */

#import <appkit/View.h>

/* Within the EnvelopeView, the envelope is stored as a doubly-linked
 * list of NXPoints.  No outside objects have access to this list,
 * and hence need not concern themselves with its construction.
 *
 * An element in the list is stored in an envpoint struct, which
 * is typedef'd to EnvPoint.
 */

typedef struct envpoint {
	NXPoint p;			/* The point in question */
	struct envpoint *next;		/* Next in the list */
	struct envpoint *last;		/* Previous in the list */
} EnvPoint;


@interface EnvelopeView : View
{
	EnvPoint *envelope;		/* The envelope list */
	int npoints;			/* Number of points in list */
	id delegate;			/* Delegate for this view */
}

/* CLASS METHODS:
 *
 * 	+ newFrame:	-- Create and initialize.  Initializes to a
 *			   single segment rising from 0 to 1.
 */
+ newFrame:(const NXRect *)frameRect;

/* INSTANCE METHODS:
 *
 * Methods to set/get the envelope:
 *	- (int) envelope:(NXPoint **)envptr
 *			-- Places pointer to the envelope in envptr and
 *			   returns the number of points in that array.
 *	- setEnvelope:(NXPoint *)env Points:(int)n
 *			-- Sets envelope from an array env with n points.
 */
- (int) envelope:(NXPoint **)envptr;
- setEnvelope:(NXPoint *)env Points:(int)n;

/* Methods to alter the envelope.  These methods need not be used, since
 * the envelope can be altered via the mouse.  They are provided for
 * flexibility.
 *
 *	- (int) movePoint:(int)n To:(NXPoint *)pt
 *			-- Move point number n to the point given by pt.
 *			   Returns -1 if move is impossible, n otherwise.
 *	- (int) addPoint:(NXPoint *)pt
 *			-- Add a point at pt.  Returns the number of
 *			   the new point in the list, or -1 if disallowed.
 *	- (int) rmPoint:(int)n
 *			-- Remove point number n.  Returns the total
 *			   number of points remaining or -1 if disallowed.
 */
- (int) movePoint:(int)n To:(NXPoint *)pt;
- (int) addPoint:(NXPoint *)pt;
- (int) rmPoint:(int)n;

/* Methods to query the object:
 *	- (int) npoints		-- Returns the number of points in envelope
 * 	- setDelegate:		-- Sets up a delegate
 *	- delegate		-- Returns current delegate
 */
- (int) npoints;
- setDelegate:anObject;
- delegate;

/* Methods for internal use:
 *	- acceptsFirstResponder:
 *	- mouseDown:
 *	- drawSelf::
 */
- drawSelf:(NXRect *)rects :(int)rectCount;
- mouseDown:(NXEvent *)event;
- (BOOL)acceptsFirstResponder;

@end

/* These are the delegate messages available:
 *	- point:MovedTo:	-- Notifies that a point is being moved
 *	- envelopeChanged:	-- Notifies that envelope was changed
 */

@interface AnEnvViewDelegate:Object
- point:(int)n MovedTo:(NXPoint *)p;
- envelopeChanged:sender;
@end


