#ifndef __MK_LineGraph_H___
#define __MK_LineGraph_H___

#import <appkit/View.h>

@interface LineGraph:View
{
    float *points;	/* coords of the userpath used to draw graph */
    int numPoints;	/* number of points in the graph */
    float bbox[4];	/* bounding box of graph - minx, miny, maxx, maxy */
    char *ops;		/* operator array of the userpath used to draw graph */
    float lineGray;	/* gray value for the line of the graph */
    float backgroundGray;	/* gray value for the background */
    BOOL showPoints;
}
 /*
  * LineGraph is simple view which plots an xy graph of a series of points.
  * You use it by setting the x and y coords of the points of the graph, and
  * then tell it to display.  In addition, it will also zoom and rescale
  * itself so the whole graph is visible.
  */

- initFrame:(NXRect *)aRect;
 /* Called as part of nib instantiation. */

- setPoints:(int)num x:(float *)x y:(float *)y
	minX:(float)minX minY:(float)minY maxX:(float)maxX maxY:(float)maxY;
 /*
  * Sets the points of the graph.  Num is the number of points, x and y are
  * arrays of coordinates.  The other parameters are the boundaries of the
  * coordinates you pass in.
  */

- scaleToFit;
 /*
  * Scales the view to that the whole graph is within the view.
  */

- zoom:(float)scale;
 /*
  * Zooms the view by the given scale.  A factor of 2 makes the image twice
  * as large.
  */

- setLineGray:(float)gray;
- setBackgroundGray:(float)gray;
- (float)lineGray;
- (float)backgroundGray;
 /*
  * Methods to set and get the gray values used to draw the line and
  * background of the graph.
  */

- setShowPoints:(BOOL)yesOrNo;
/* Display little boxes at each point. */

@end
#endif
