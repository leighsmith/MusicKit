//////////////////////////////////////////////////////////////
//
// EnvelopeView.h -- Interface for the EnvelopeView class
// Copyright 1991-94 Fernando Lopez Lezcano All Rights Reserved
//
//////////////////////////////////////////////////////////////

#import <AppKit/AppKit.h>
#import <MusicKit/MusicKit.h>            // for envelope class stuff
//#import <Envelope.h>			   // so we substitute this for now.

@interface EnvelopeView : NSView <NSCopying>
{
    // Controller theController;
    id theController;				// object which controls the envelope view
    MKEnvelope *theEnvelope;			// the envelope object being viewed
    NSCursor *theCross;				// crosshairs cursor
    NSCursor *theFilledCross;			// crosshairs plus knob cursor
	
    int selected;				// current highlighted point in envelope
    float defaultSmooth;			// default smoothing read from the defaults database
    float envColour;				// colour to draw envelope with
    int defaultFormat;				// which copy format to begin popup menu on.

    float xMax;					// coordinate system limits
    float xMin;
    float yMax;
    float yMin;
	
    float xSnap;				// Snap increments
    float ySnap;
	
    NSBezierPath *userPath;			// user path for drawing segments
	
    BOOL showSmooth;				// show or not smoothing in envelopes
    BOOL drawSegments;				// draw or not segments between points
}

- (void)resetCursorRects;
- initWithFrame:(NSRect)frameRect;
- (void)controllerIs:sender;
- (void)drawRect:(NSRect)rect;
- (int) hitKnobAt:(NSPoint)p border:(float)delta;
- (int) movePoint:(int)n to: (NSPoint)p;
- (void)mouseDown:(NSEvent *)event;

- (void)highlight;
- (void)dim;
- (BOOL) acceptsFirstResponder;
- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;

- (void)copy:(id)id;
- (void)paste:(id)id;

- (void)setPointTo:(int)i;
- (void)nextPoint;
- (void)previousPoint;
- setXAt: (int)point to: (float)coord;
- setYAt: (int)point to: (float)coord;
- setYrAt: (int)point to: (float)coord;
- setSmoothAt: (int)point to: (float)val;
- (void)setXMinTo:(float)coord;
- (void)setXMaxTo:(float)coord;
- setXLimitsTo: (float)min : (float)max;
- (void)setYMinTo:(float)coord;
- (void)setYMaxTo:(float)coord;
- (void)setXSnapTo:(float)coord;
- (void)setYSnapTo:(float)coord;
- (void)setStickyAt:(int)point To:(int)state;
- (void) setShowSmooth: (BOOL) state;
- (void) setDrawSegments: (BOOL) state;
- (void)scaleLimits;
- (int)getPoint;
- (float)getX:(int)i;
- (float)getY:(int)i;
- (float)getYr:(int)i;
- (float)getSmoothing:(int)i;
- (int)getSticky:(int)i;
- (float)getXMax;
- (float)getXMin;
- (float)getYMax;
- (float)getYMin;
- (float)getXSnap;
- (float)getYSnap;
- (BOOL) getShowSmooth;
- (BOOL) getDrawSegments;

@end
