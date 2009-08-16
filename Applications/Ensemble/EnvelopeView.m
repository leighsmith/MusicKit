#import "EnvelopeView.h"
#import "XAxisView.h"
#import "YAxisView.h"
#import <MusicKit/Envelope.h>

static id blackPoint=nil, whitePoint=nil;
float pointWidth;

@implementation EnvelopeView

- setArrays
{
	if (nPoints >= arraySize) {
		if (arraySize == 0) arraySize = 8;
		while (nPoints >= arraySize) arraySize *= 2;
		if (x)
			x = NXZoneRealloc([self zone], x, sizeof(double)*arraySize);
		else
			x = NXZoneMalloc([self zone], sizeof(double)*arraySize);
		if (y)
			y = NXZoneRealloc([self zone], y, sizeof(double)*arraySize);
		else
			y = NXZoneMalloc([self zone], sizeof(double)*arraySize);
		if (points) NXZoneFree([self zone],points);
		if (ops) NXZoneFree([self zone],ops);
		points = NXZoneMalloc([self zone], sizeof(float)*arraySize*2);
		ops = NXZoneMalloc([self zone], sizeof(char)*arraySize);
		*ops = dps_moveto;
		memset(ops+1, dps_lineto, arraySize-1);
	}
	return self;
}
	
- initFrame:(const NXRect *)rect
{
	NXRect r = {0.0,0.0,6.0,6.0};
	[super initFrame:rect];
	nPoints = 2;
	[self setArrays];
	minY = 0;
	maxY = 127.0;
	x[0] = y[0] = 0;
	x[1] = y[1] = 127;
	selectedPoint = -1;
	stickPoint = MAXINT;
	if (!blackPoint) {
		blackPoint = [[NXImage allocFromZone:[NXApp zone]] initSize:&(r.size)];
		whitePoint = [[NXImage allocFromZone:[NXApp zone]] initSize:&(r.size)];
		[blackPoint lockFocus];
		PSsetgray(NX_BLACK);
		NXRectFill(&r);
		[blackPoint unlockFocus];
		[whitePoint lockFocus];
		NXFrameRect(&r);
		[whitePoint unlockFocus];
		pointWidth = r.size.width;
	}
	[self setClipping:NO];
	[self setOpaque:YES];
	userPathInvalid = YES;
	gridPathInvalid = YES;
	stickPointEnabled = YES;
	return self;
}

- free
{
	if (x) NXZoneFree([self zone], x);
	if (y) NXZoneFree([self zone], y);
	if (points) NXZoneFree([self zone],points);
	if (ops) NXZoneFree([self zone],ops);
	if (gridPoints) NXZoneFree([self zone],gridPoints);
	if (gridOps) NXZoneFree([self zone],gridOps);
	return [super free];
}

- updateRanges
{
	if ([inRangeFields isKindOf:[Matrix class]]) {
		[[inRangeFields findCellWithTag:0] setFloatValue:(float)x[0]];
		[[inRangeFields findCellWithTag:1] setFloatValue:(float)x[nPoints-1]];
	}
	else if ([inRangeFields tag] == 0)
		[inRangeFields setFloatValue:(float)x[0]];
	else 
		[inRangeFields setFloatValue:(float)x[nPoints-1]];
	if ([outRangeFields isKindOf:[Matrix class]]) {
		[[outRangeFields findCellWithTag:0] setFloatValue:(float)minY];
		[[outRangeFields findCellWithTag:1] setFloatValue:(float)maxY];
	}
	else if ([outRangeFields tag] == 0)
		[outRangeFields setFloatValue:(float)minY];
	else
		[outRangeFields setFloatValue:(float)maxY];
	[xAxisView setMinDisplayValue:x[0]];
	[xAxisView setMaxDisplayValue:x[nPoints-1]];
	[yAxisView setMinDisplayValue:minY];
	[yAxisView setMaxDisplayValue:maxY];
	[xAxisView display];
	[yAxisView display];
	return self;
}

- awakeFromNib
{
	id view, sview;
	
	/* First make the axes lower in the view hierarchy so that they get redrawn
	 * first when the window is resized.  This is necessary because the grid 
	 * drawing depends on the axes being up to date.
	 */
	sview = [xAxisView superview];
	view = self;
	while (view && ([view superview] != sview)) view = [view superview];
	[xAxisView removeFromSuperview];
	[sview addSubview:xAxisView :NX_BELOW relativeTo:view];
	[yAxisView removeFromSuperview];
	[sview addSubview:yAxisView :NX_BELOW relativeTo:view];

	if ([inRangeFields isKindOf:[Matrix class]]) {
		[[inRangeFields findCellWithTag:0] setFloatingPointFormat:NO left:3 right:2];
		[[inRangeFields findCellWithTag:1] setFloatingPointFormat:NO left:3 right:2];
	}
	else
		[inRangeFields setFloatingPointFormat:NO left:3 right:2];
	if ([outRangeFields isKindOf:[Matrix class]]) {
		[[outRangeFields findCellWithTag:0] setFloatingPointFormat:NO left:3 right:2];
		[[outRangeFields findCellWithTag:1] setFloatingPointFormat:NO left:3 right:2];
	}
	else
		[outRangeFields setFloatingPointFormat:NO left:3 right:2];
	[xAxisView setConstrained:NO];
	[yAxisView setConstrained:NO];
	[self updateRanges];
	gridPathInvalid = YES;
	[self display];
	return self;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)acceptsFirstMouse
{
	return YES;
}

- setEnvelope:anEnvelope
{
	int i;
	envelope = anEnvelope;
	nPoints = [envelope pointCount];
	[self setArrays];
	memcpy(x, [envelope xArray], sizeof(double)*nPoints);
	memcpy(y, [envelope yArray], sizeof(double)*nPoints);
	selectedPoint = -1;
	stickPoint = [envelope stickPoint];
	userPathInvalid = YES;
	gridPathInvalid = YES;
	minY = MAXDOUBLE;
	maxY = -MAXDOUBLE;
	for (i=0; i<nPoints; i++) {
		if (y[i] < minY) minY = y[i];
		if (y[i] > maxY) maxY = y[i];
	}
	[self updateRanges];
	return [self display];
}

- setStickPointEnabled:(BOOL)flag
{
	stickPointEnabled = flag;
	return self;
}

- envelope
{
	return envelope;
}

- setDelegate:anObject
{
	delegate = anObject;
	return self;
}

- takeInputRangeFrom:sender
{
	double oldMin, oldMax, newMin, newMax;
	double scaler;
	int i;
	id cell = [sender isKindOf:[Matrix class]] ? [sender selectedCell] : sender;
	int which = [cell tag];

	oldMin = x[0];
	oldMax = x[nPoints-1];

	newMin = oldMin;
	newMax = oldMax;

	if (which == 0) {
		newMin = [cell doubleValue];
		if (newMin > oldMax) {
			newMin = oldMax-0.1;
			[cell setDoubleValue:newMin];
		}
		[xAxisView setMinDisplayValue:newMin];
	}	
	else if (which == 1) {
		newMax = [cell doubleValue];
		if (oldMin > newMax) {
			newMax = oldMin+0.1;
			[cell setDoubleValue:newMax];
		}
		[xAxisView setMaxDisplayValue:newMax];
	}	

	scaler = (newMax - newMin) / (oldMax - oldMin);
	for (i=0; i<nPoints; i++)
		x[i] = newMin + (x[i]-oldMin) * scaler;

	[envelope setPointCount:nPoints xArray:x yArray:y];

	[xAxisView display];
	gridPathInvalid = YES;
    return [self display];
}

- takeOutputRangeFrom:sender
{
	double oldMin, oldMax;
	double scaler;
	int i;
	id cell = [sender isKindOf:[Matrix class]] ? [sender selectedCell] : sender;
	int which = [cell tag];

	oldMin = minY;
	oldMax = maxY;
	
	if (which == 0) {
		minY = [cell doubleValue];
		if (minY > maxY) {
			minY = maxY-0.1;
			[cell setDoubleValue:minY];
		}
		[yAxisView setMinDisplayValue:minY];
	}	
	else if (which == 1) {
		maxY = [cell doubleValue];
		if (minY > maxY) {
			maxY = minY+0.1;
			[cell setDoubleValue:maxY];
		}
		[yAxisView setMaxDisplayValue:maxY];
	}	

	scaler = (maxY - minY) / (oldMax - oldMin);

	for (i=0; i<nPoints; i++)
		y[i] = minY + (y[i]-oldMin) * scaler;

	[envelope setPointCount:nPoints xArray:x yArray:y];

	[yAxisView display];
	gridPathInvalid = YES;
    return [self display];
}

- setFrame:(const NXRect *)frameRect
{
	[super setFrame:frameRect];
	userPathInvalid = YES;
	gridPathInvalid = YES;
	return self;
}
	
- sizeTo:(NXCoord)width :(NXCoord)height
{
	[super sizeTo:width:height];
	userPathInvalid = YES;
	gridPathInvalid = YES;
	return self;
}
	
- buildUserPath
{
	float *p = points;
	float *end = points+nPoints*2;
	double *xArr = x;
	double *yArr = y;
	float xOffset = x[0];
	float xScale = bounds.size.width/(x[nPoints-1] - x[0]);
	float yOffset = minY;
	float yScale = bounds.size.height/(maxY - minY);
	
	while (p < end) {
		*p++ = ((float)*xArr++ - xOffset) * xScale;
		*p++ = ((float)*yArr++ - yOffset) * yScale;
	}

	bbox[0] = bbox[1] = 0.0;
	bbox[2] = bounds.size.width;
	bbox[3] = bounds.size.height;
	userPathInvalid = NO;
	return self;
}

- drawPoints:(int)which
{
	int i, n, start;
	float *p = points;
	NXPoint to;
	float maxXPoint, maxYPoint;
	float pointOffset = pointWidth*0.5;

	maxXPoint = bounds.size.width - pointWidth;
	maxYPoint = bounds.size.height - pointWidth;
	
	if (which >=0) {
		start = which;
		n = start+1;
		p = points + which*2;
	}
	else {
		start = 0;
		n = nPoints;
		p = points;
	}
	
	for (i=start; i<n; i++) {
		to.x = *p++ - pointOffset;
		to.y = *p++ - pointOffset;
		to.x = MIN(MAX(to.x,0.0), maxXPoint);
		to.y = MIN(MAX(to.y,0.0), maxYPoint);
		if (i==selectedPoint)
			[whitePoint composite:NX_COPY toPoint:&to];
		else
			[blackPoint composite:NX_COPY toPoint:&to];
	}
	return self;
}

- drawStickPoint
{
	float dash = 4;
	float x1, y1;
	if (stickPoint == MAXINT) return self;
	PSsetdash(&dash, 1, 0);
	x1 = points[stickPoint*2];
	if (stickPoint == nPoints-1) x1 -= 3.0;
	y1 = points[stickPoint*2 + 1];
	PSmoveto(x1, 0.0);
	PSrlineto(0.0, y1);
	PSstroke();
	if (stickPointSelected) {
		PSsetdash(NULL, 0, 0);
		PSsetgray(NX_DKGRAY);
		PSmoveto(x1-3.0, 0.0);
		PSrlineto(0.0, y1);
		PSmoveto(x1+3.0, 0.0);
		PSrlineto(0.0, y1);
		PSstroke();
	}
	return self;
}

- buildGridPath
{
	float x1, y1, dx, dy;
	float *p;
	unsigned char *o;

	if (xAxisView) {
		dx = [xAxisView majorTickInterval];
		x1 = [xAxisView firstMajorTick];
		if (x1 <= 1.0) x1 += dx;
	}
	else {
		dx = bounds.size.width * 0.25;
		x1 = dx;
	}

	if (yAxisView) {
		dy = [yAxisView majorTickInterval];
		y1 = [yAxisView firstMajorTick];
		if (y1 <= 1.0) y1 += dy;
	}
	else {
		dy = bounds.size.height * 0.25;
		y1 = dy;
	}

	nGridPoints = (ceil(bounds.size.width/dx) + ceil(bounds.size.height/dy)) * 2;
	if (nGridPoints > gridArraySize) {
		gridArraySize = nGridPoints;
		if (gridPoints) NXZoneFree([self zone], gridPoints);
		if (gridOps) NXZoneFree([self zone], gridOps);
		gridPoints = NXZoneMalloc([self zone], sizeof(float)*gridArraySize*2);
		gridOps = NXZoneMalloc([self zone], sizeof(float)*gridArraySize);
		gridArraySize = nGridPoints;
	}
	
	p = gridPoints;
	o = gridOps;
	nGridPoints = 0;

	while (x1 < bounds.size.width) {
		*p++ = x1;
		*p++ = 1.0;
		*o++ = dps_moveto;
		*p++ = 0.0;
		*p++ = bounds.size.height-1.0;
		*o++ = dps_rlineto;
		x1 += dx;
		nGridPoints += 2;
	}

	while (y1 < bounds.size.height) {
		*p++ = 0.0;
		*p++ = y1;
		*o++ = dps_moveto;
		*p++ = bounds.size.width;
		*p++ = 0.0;
		*o++ = dps_rlineto;
		y1 += dy;
		nGridPoints += 2;
	}

	gridPathInvalid = NO;
	return self;
}

- drawSelf:(const NXRect *)rects :(int)count
{
	PSsetgray(NX_WHITE);
	if (count == 1)
		NXRectFill(&(rects[0]));
	else {
		NXRectFill(&(rects[1]));
		NXRectFill(&(rects[2]));
	}

	if (userPathInvalid) [self buildUserPath];
	if (gridPathInvalid) [self buildGridPath];

	PSsetgray(NX_LTGRAY);
	DPSDoUserPath(gridPoints, nGridPoints<<1, dps_float, gridOps, nGridPoints,
					bbox, dps_ustroke);
		
	PSsetgray(NX_BLACK);
	DPSDoUserPath(points, nPoints<<1, dps_float, ops, nPoints, bbox, dps_ustroke);

	if (stickPoint != MAXINT) [self drawStickPoint];
	[self drawPoints:-1];
	return self;
}

- mouseDown:(NXEvent *)e
{
	int i, j;
	NXPoint p = e->location;
	BOOL shiftDown = ((e->flags & (NX_SHIFTMASK)) != 0);
	BOOL altDown = ((e->flags & (NX_ALTERNATEMASK)) != 0);
	float halfPointWidth = pointWidth * 0.5;
	float lastX = bounds.size.width - pointWidth;
	float lastY = bounds.size.height - pointWidth;
	float x1, x2, y1, y2;

	[self convertPoint:&p fromView:nil];
	
	if (!altDown || !stickPointEnabled) {
		stickPointSelected = NO;
		for (i=0, j=0; i<nPoints; i++,j+=2) {
			x1 = points[j] - halfPointWidth;
			x1 = MIN(MAX(x1,0.0),lastX);
			x2 = x1 + pointWidth;
	
			y1 = points[j+1] - halfPointWidth;
			y1 = MIN(MAX(y1,0.0),lastY);
			y2 = y1 + pointWidth;
	
			if ((p.x >= x1) && (p.x <= x2) && (p.y >= y1) && (p.y <= y2))
				break;
		}
	
		if (i < nPoints) {
			int oldSelection = selectedPoint;
			/* User picked an existing point */
			selectedPoint = i;
			if (shiftDown && (selectedPoint == oldSelection))
				selectedPoint = -1;
			if (selectedPoint != oldSelection)
				[self display];
		}
		else {
			/* Create a new point at the mouse position */
			float newX = x[0] + (x[nPoints-1]-x[0]) * p.x/bounds.size.width;
			float newY = minY + (maxY-minY) * p.y/bounds.size.height;
			for (i=1; i<nPoints; i++)
				if (newX < x[i]) break;
			nPoints++;
			[self setArrays];
			memmove(&x[i+1], &x[i], (nPoints-i)*sizeof(double));
			memmove(&y[i+1], &y[i], (nPoints-i)*sizeof(double));
			x[i] = newX;
			y[i] = newY;
			userPathInvalid = YES;
			selectedPoint = i;
			if (stickPoint >= i) stickPoint++;
			[self display];
		}
	}
	else {
		/* We're dealing with the stickPoint */
		int newPoint;
		selectedPoint = -1;
		for (i=0, j=0; i<nPoints-1; i++,j+=2)
			if ((p.x >= points[j]) && (p.x <= points[j+2])) break;
		if (i < nPoints-1) {
			newPoint = ((p.x-points[j]) < (points[j+2]-p.x)) ? i : i+1;
			stickPointSelected = ((newPoint == stickPoint) && 
				(!(shiftDown && stickPointSelected)));
			stickPoint = newPoint;
		}
		[self display];
	}

	if ((selectedPoint >= 0) || (altDown && (stickPoint != MAXINT)))
		[window addToEventMask:NX_MOUSEDRAGGEDMASK];
	
	return self;
}

- mouseDragged:(NXEvent *)e
{
	NXPoint p = e->location;
	BOOL altDown = ((e->flags & (NX_ALTERNATEMASK)) != 0);
	[self convertPoint:&p fromView:nil];
	
	if (!altDown || !stickPointEnabled) {
		if ((selectedPoint > 0) && (selectedPoint < nPoints-1)) {
			x[selectedPoint] = x[0] + (x[nPoints-1]-x[0]) * p.x/bounds.size.width;
			x[selectedPoint] = 
				MIN(MAX(x[selectedPoint], x[selectedPoint-1]), x[selectedPoint+1]);
		}
		y[selectedPoint] = minY + (maxY-minY) * p.y/bounds.size.height;
		y[selectedPoint] = MIN(MAX(y[selectedPoint], minY), maxY);
		userPathInvalid = YES;
	}
	else {
		int i, j;
		for (i=0, j=0; i<nPoints-1; i++,j+=2)
			if ((p.x >= points[j]) && (p.x <= points[j+2])) break;
		if (i < nPoints-1)
			stickPoint = ((p.x-points[j]) < (points[j+2]-p.x)) ? i : i+1;
	}
	return [self display];
}

- mouseUp:(NXEvent *)e
{
	[window removeFromEventMask:NX_MOUSEDRAGGEDMASK];
	[envelope setPointCount:nPoints xArray:x yArray:y];
	[envelope setStickPoint:stickPoint];
	if (delegate && [delegate respondsTo:@selector(envelopeModified:)])
		[delegate envelopeModified:self];
	return self;
}

- deleteSelectedPoint
{
	if (stickPointSelected) {
		[envelope setStickPoint:stickPoint=MAXINT];
		stickPointSelected = NO;
	}
	else {
		if ((selectedPoint < 1) || (selectedPoint == nPoints-1)) return self;
		memmove(&x[selectedPoint], &x[selectedPoint+1],
				(nPoints-selectedPoint+1)*sizeof(double));
		memmove(&y[selectedPoint], &y[selectedPoint+1],
				(nPoints-selectedPoint+1)*sizeof(double));
		nPoints--;
		if (stickPoint >= nPoints-1) {
			stickPoint--;
			[envelope setStickPoint:stickPoint];
		}
		[envelope setPointCount:nPoints xArray:x yArray:y];
		if (delegate && [delegate respondsTo:@selector(envelopeModified:)])
			[delegate envelopeModified:self];
		userPathInvalid = YES;
	}
	return [self display];
}

- keyDown:(NXEvent *)e
{
	if ((e->data.key.charSet==NX_ASCIISET) && (e->data.key.charCode==127) &&
		(((selectedPoint > 0) && (selectedPoint < nPoints-1)) || stickPointSelected))
		[self deleteSelectedPoint];
	else NXBeep();
	return self;
}

- cut:sender
{
	if (((selectedPoint > 0) && (selectedPoint < nPoints-1)) || stickPointSelected)
		[self deleteSelectedPoint];
	else NXBeep();
	return self;
}

@end
