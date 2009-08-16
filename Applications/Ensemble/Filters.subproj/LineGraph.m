
/*
    LineGraph.m

    LineGraph is a simple view which plots a set of points as a connected line.
    LineGraph draws the graph using a userpath.  It retains the two arrays
    that make up the userpath: the coordinates of the userpath and the
    userpath operators (e.g., dps_lineto).
*/

#import "LineGraph.h"
#import <appkit/nextstd.h>
#import <appkit/graphics.h>
#import <dpsclient/wraps.h>
#import <dpsclient/dpsNeXT.h>
#import <stdlib.h>

static void drawAxes(float x1, float y1, float x2, float y2);
static void testBounds(float *min, float *max, float *points, int num);

#define POS_INFINITY	(1.0/0.0)
#define NEG_INFINITY	(-1.0/0.0)
#define IS_NAN(x)	((x)!=(x))	/* IEEE test for NAN (not a number) */
#define IS_STRANGE(x)	(IS_NAN(x) || x == POS_INFINITY || x == NEG_INFINITY)


@implementation LineGraph

- initFrame:(NXRect *)aRect
{
    [super initFrame:aRect];
    lineGray = NX_WHITE;
    backgroundGray = NX_BLACK;
    return self;
}

- free
{
    NXZoneFree([self zone], points);
    NXZoneFree([self zone], ops);
    return [super free];
}

- setPoints:(int)num x:(float *)x y:(float *)y
	minX:(float)minX minY:(float)minY maxX:(float)maxX maxY:(float)maxY;
{
    float *f;
    int i;
    char *op;
    NXZone *zone;
    int segPoints;

 /*
  * We copy these points into our own an array that we later use when
  * we draw them as a userpath.  This array has the x and y values
  * interleaved.  We also generate an array of userpath operators that we
  * will use to draw the userpath.  These operators are just a moveto to
  * get to the start of the line, and then lineto's connecting all the points
  * from there on.
  *
  * We also filter out the troublesome floating point values of positive
  * infinity, negative infinity and NAN ("not a number").  When we encounter
  * these values, we skip that particular point and remember to start a new
  * segment of the graph when we see the next well behaved value.
  */
    zone = [self zone];
    NXZoneFree(zone, points);
    NXZoneFree(zone, ops);
    numPoints = num;
    points = NXZoneMalloc(zone, 2 * num * sizeof(float));
    ops = NXZoneMalloc(zone, num * sizeof(char));
    numPoints = 0;
    segPoints = 0;
    for (f = points, op = ops, i = num; i--; ) {
	if (IS_STRANGE(*x) || IS_STRANGE(*y)) {
	    if (segPoints == 1) {
	      /*
	       * This is a the case of a well behaved point with weird values
	       * on either side.  In this case we just make a tiny line
	       * segment of this point to itself to.
	       */
		*f++ = f[-2];
		*f++ = f[-2];
		*op++ = dps_lineto;
		numPoints++;
	    }
	    segPoints = 0;
	    x++;
	    y++;
	} else {
	    *f++ = *x++;
	    *f++ = *y++;
	    if (segPoints == 0)
		*op++ = dps_moveto;
	    else
		*op++ = dps_lineto;
	    segPoints++;
	    numPoints++;
	}
    }
    if (numPoints > 0) {
	testBounds(&minX, &maxX, points, numPoints);
	bbox[0] = minX;
	bbox[2] = maxX;
	testBounds(&minY, &maxY, points+1, numPoints);
	bbox[1] = minY;
	bbox[3] = maxY;
    } else {
	bbox[0] = bbox[1] = -1;
	bbox[2] = bbox[3] = 1;
    }
    return self;
}

- sizeTo:(NXCoord)width :(NXCoord)height
{
    NXPoint center;

 /*
  * We override sizeto so that after we're resized the point at the center
  * of the view remains the same.  We just note the center, pass the message
  * up to the super class, and then reset the center to what it was.
  */
    center.x = NX_X(&bounds) + NX_WIDTH(&bounds) / 2;
    center.y = NX_Y(&bounds) + NX_HEIGHT(&bounds) / 2;
    [super sizeTo:width :height];
    [self setDrawOrigin:center.x - NX_WIDTH(&bounds) / 2
			:center.y - NX_HEIGHT(&bounds) / 2];
    return self;
}

- scaleToFit
{
    float scaleX, scaleY;
    float bbWidth = bbox[2] - bbox[0];
    float bbHeight = bbox[3] - bbox[1];

 /*
  * First we figure out how much we need to scale so that our current graph
  * will just fit within the view.  We do this by taking the ratio of the
  * the view's current size to the bounding box of the graph.  We also add
  * a little fudge factor of 0.95 so the graph will have a little border
  * space around it.
  */
    if (bbWidth == 0 && bbHeight == 0)
	scaleX = scaleY = 10;
    else if (bbWidth == 0) {
	scaleY = NX_HEIGHT(&frame) / bbHeight * 0.95;
	scaleX = 10.0;
    }
    else if (bbHeight == 0) {
	scaleX = NX_WIDTH(&frame) / bbWidth * 0.95;
	scaleY = 10.0;
    }
    else {
	scaleX = (NX_WIDTH(&frame) / bbWidth) * 0.95;
	scaleY = (NX_HEIGHT(&frame) / bbHeight) * 0.95;
    }
    
    /* scale the size of the view */
    [self setDrawSize:NX_WIDTH(&frame) / scaleX :NX_HEIGHT(&frame) / scaleY];

  /*
   * translate the view so the graph's bounding box is in the lower left corner
   */
    [self setDrawOrigin:bbox[0] - (NX_WIDTH(&bounds) - bbWidth) / 2
			:bbox[1] - (NX_HEIGHT(&bounds) - bbHeight) / 2];
    return self;
}

- zoom:(float)scale
{
    NXPoint center;

  /* remember the center to we can reset it after the scaling */
    center.x = NX_X(&bounds) + NX_WIDTH(&bounds) / 2;
    center.y = NX_Y(&bounds) + NX_HEIGHT(&bounds) / 2;

  /* scale the view to its new size */
    [self setDrawSize:NX_WIDTH(&bounds) / scale :NX_HEIGHT(&bounds) / scale];

  /* reset the center point */
    [self setDrawOrigin:center.x - NX_WIDTH(&bounds) / 2
			:center.y - NX_HEIGHT(&bounds) / 2];
    return self;
}

- setShowPoints:(BOOL)yesOrNo
{
    showPoints = yesOrNo;
    return self;
}

/*
 * In both the drawSelf method and the drawAxes function, we use a little
 * trick to get the right line width regardless of how much we are zoomed
 * in.  If we are drawing on the screen, we just draw the lines with zero
 * width.  This the fastest way to draw lines, and ensures they will always
 * one pixel wide.  When drawing on the printer, we do the trick of
 * setting the matrix to the default matrix after the path has been made
 * but before it is stroked.  Since the line width is actually used when
 * the path is stroked, this makes the line width be the same regardless of
 * what scale we were at when we stroked the path.  The purpose of this is
 * to make the line width independent of how far in or our we are zoomed.
 */

- drawSelf:(const NXRect *)rects :(int)rectCount
{
    int i;
    NXRect spot;
    PSsetgray(backgroundGray);
    NXRectFill(&bounds);
    drawAxes(NX_X(&bounds), NX_Y(&bounds), NX_MAXX(&bounds), NX_MAXY(&bounds));
    if (points && numPoints > 0) {
	PSnewpath();
	PSsetlinewidth(NXDrawingStatus == NX_DRAWING ? 0.0 : 1.0);
	PSsetgray(lineGray);
	if (NXDrawingStatus == NX_DRAWING) {
	  /* stroke the userpath */
	    DPSDoUserPath(points, numPoints * 2, dps_float, ops, numPoints,
							bbox, dps_ustroke);
	    if (showPoints) {
		NX_WIDTH(&spot) = .02;
		NX_HEIGHT(&spot) = .02;
		for (i=0; i<numPoints*2; i+=2) {
		    NX_X(&spot) = points[i]-.01;
		    NX_Y(&spot) = points[i+1]-.01;
		    NXRectFill(&spot);
		}
	    }
	}
	else {
	  /* append the userpath to the current path, but dont stroke yet */
	    DPSDoUserPath(points, numPoints * 2, dps_float, ops, numPoints,
							bbox, dps_uappend);
	  /* trick to ensure line width is independent of zoom */
	    PSgsave();
	    PSmatrix();
	    PSdefaultmatrix();
	    PSsetmatrix();
	    PSstroke();
	    PSgrestore();
	}
    }
    return self;
}


/*
 * Simple line drawer, used to draw the axes of the graph in the current
 * color and line width.
 */
static void drawAxes(float x1, float y1, float x2, float y2)
{
    PSsetlinewidth(NXDrawingStatus == NX_DRAWING ? 0.0 : 0.4);
    PSsetgray(NX_DKGRAY);
    PSnewpath();
    PSmoveto(0.0, y1);
    PSlineto(0.0, y2);
    PSmoveto(x1, 0.0);
    PSlineto(x2, 0.0);
    if (NXDrawingStatus != NX_DRAWING) {
      /* trick to ensure line width is independent of zoom */
	PSgsave();
	PSmatrix();
	PSdefaultmatrix();
	PSsetmatrix();
	PSstroke();
	PSgrestore();
    } else
	PSstroke();
}

- setLineGray:(float)gray
{
    lineGray = gray;
    return self;
}

- setBackgroundGray:(float)gray
{
    backgroundGray = gray;
    return self;
}

- (float)lineGray
{
    return lineGray;
}

- (float)backgroundGray
{
    return backgroundGray;
}

/*
 * Tests the bounds for NAN or infinite values.  If there are such values,
 * we recalc the bounds with the given points.  Since these points are
 * the interleaved x-y pairs for the userpath, we skip every other value,
 * since we want to only consider x's or y's.
 */
static void testBounds(float *min, float *max, float *points, int num)
{
    if (IS_STRANGE(*min) || IS_STRANGE(*max)) {
	*min = *max = *points;
	while (--num) {
	    points += 2;
	    if (*points > *max)
		*max = *points;
	    else if (*points < *min)
		*min = *points;
	}
    }
}

@end
