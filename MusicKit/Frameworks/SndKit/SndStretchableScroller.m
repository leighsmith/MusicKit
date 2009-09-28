////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    Subclass of NSScroller that adds two handles that allows stretching the scroller.
///   See SndStretchableScroller.h for description.
//
//  Original Author: Leigh Smith and Skot McDonald.
//  
//  Copyright (c) 2004, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import "SndStretchableScroller.h"
#import "SndView.h"

#define STRETCH_HANDLE_SIZE 10
#define OFFSET_FROM_ORIGIN_X 6
#define OFFSET_FROM_ORIGIN_Y 3
#define MIN_PROPORTION 0.1

@implementation SndStretchableScroller

// We want to override the drawing of the knob to place two edge sections on the knob to make them stretch handles.

- (void) drawKnob
{
    NSRect  knobRect = [self rectForPart: NSScrollerKnob];
    
    [super drawKnob];
    
    { // Draw left arrow
	NSPoint p1 = {knobRect.origin.x + OFFSET_FROM_ORIGIN_X, knobRect.origin.y + knobRect.size.height / 2};
	NSPoint p2 = {knobRect.origin.x + STRETCH_HANDLE_SIZE, knobRect.origin.y + knobRect.size.height - OFFSET_FROM_ORIGIN_Y};
	NSPoint p3 = {knobRect.origin.x + STRETCH_HANDLE_SIZE, knobRect.origin.y + OFFSET_FROM_ORIGIN_Y};
	
	if (stretchingLeftKnob)
	    [[NSColor whiteColor] set];
	else
	    [[NSColor blackColor] set];
	[NSBezierPath strokeLineFromPoint: p1 toPoint: p2];
	[NSBezierPath strokeLineFromPoint: p2 toPoint: p3];
	[NSBezierPath strokeLineFromPoint: p3 toPoint: p1];
    }
    { // Draw right arrow
	NSPoint p1 = {knobRect.origin.x + knobRect.size.width - OFFSET_FROM_ORIGIN_X, knobRect.origin.y + knobRect.size.height / 2};
	NSPoint p2 = {knobRect.origin.x + knobRect.size.width - STRETCH_HANDLE_SIZE, knobRect.origin.y + knobRect.size.height - OFFSET_FROM_ORIGIN_Y};
	NSPoint p3 = {knobRect.origin.x + knobRect.size.width - STRETCH_HANDLE_SIZE, knobRect.origin.y + OFFSET_FROM_ORIGIN_Y};
	if (stretchingRightKnob)
	    [[NSColor whiteColor] set];
	else
	    [[NSColor blackColor] set];
	[NSBezierPath strokeLineFromPoint: p1 toPoint: p2];
	[NSBezierPath strokeLineFromPoint: p2 toPoint: p3];
	[NSBezierPath strokeLineFromPoint: p3 toPoint: p1];
    }
}

- (void) modifySndViewScale: (float) newProportion
{
    SndView *sndView = [[[self target] contentView] documentView];

    // NSLog(@"target %@ action %@\n", [self target], NSStringFromSelector([self action]));
    if([sndView isKindOfClass: [SndView class]]) {
	NSLog(@"newProportion %f\n", newProportion);
	// [sndView scaleTo: newProportion];
	[sndView resizeToScale: newProportion];
    }
}

- (void) mouseDown: (NSEvent *) theEvent
{
    NSRect knobRect = [self rectForPart: NSScrollerKnob];
    NSPoint mouseLocation = [self convertPoint: [theEvent locationInWindow] fromView: nil];
    float distanceFromLeftEdge, distanceFromRightEdge;
    
    // NSLog(@"knobRect = %f, %f, %f, %f   mouse: %f, %f\n", knobRect.origin.x, knobRect.origin.y, knobRect.size.width, knobRect.size.height, mouseLocation.x, mouseLocation.y);
    // NSLog(@"theEvent = %@\n", theEvent);
    distanceFromLeftEdge  = mouseLocation.x - knobRect.origin.x;
    distanceFromRightEdge = knobRect.origin.x + knobRect.size.width - mouseLocation.x;
    // NSLog(@"distanceFromLeftEdge = %f, distanceFromRightEdge = %f\n", distanceFromLeftEdge, distanceFromRightEdge);
    if((distanceFromLeftEdge > 0 && distanceFromLeftEdge < STRETCH_HANDLE_SIZE)  ||
       (distanceFromRightEdge > 0 && distanceFromRightEdge < STRETCH_HANDLE_SIZE )) {
	BOOL keepOn = YES;
	NSPoint mouseLoc = mouseLocation;
	NSRect slotRect = [self rectForPart: NSScrollerKnobSlot];
	
	stretchingLeftKnob  = (distanceFromLeftEdge > 0 && distanceFromLeftEdge < STRETCH_HANDLE_SIZE );
	stretchingRightKnob = (distanceFromRightEdge > 0 && distanceFromRightEdge < STRETCH_HANDLE_SIZE );
	
	[self setNeedsDisplay: YES];
	
	//    NSLog(@"On stretch handles\n");
	while (keepOn) {
	    theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
	    mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView: nil];
	    
	    if (mouseLoc.x > slotRect.origin.x + slotRect.size.width)
		mouseLoc.x = slotRect.origin.x + slotRect.size.width;
	    if (mouseLoc.x < slotRect.origin.x)
		mouseLoc.x = slotRect.origin.x;
	    
	    switch ([theEvent type]) {
	    case NSLeftMouseDragged: 
		{
		    float  newValue, newProp;
		    float  dx = mouseLoc.x - mouseLocation.x;
		    NSRect r = knobRect;
		    
		    r.size.width += (stretchingLeftKnob ? -dx : dx);
		    r.origin.x   += (stretchingLeftKnob ? dx : 0);
		    
		    newValue = (r.origin.x - slotRect.origin.x) / (slotRect.size.width - r.size.width);
		    newProp  = r.size.width / slotRect.size.width;
		    if(newProp >= MIN_PROPORTION) {
#if (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4)
			[self setFloatValue: newValue knobProportion: newProp];
#else
			[self setKnobProportion: newProp];
			[self setFloatValue: newValue];
#endif
			[self modifySndViewScale: newProp];
		    }
		}
		break;
	    case NSLeftMouseUp:
		keepOn = NO;
		break;
	    default:
		// Ignore any other kind of event. 
		break;
	    }
	}
	[self trackKnob: theEvent];
	stretchingLeftKnob  = NO;
	stretchingRightKnob = NO;
	[self setNeedsDisplay: YES];
    }
    else {
	[super mouseDown: theEvent];
    }
}

@end
