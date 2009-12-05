#ifndef __MK_XAxisView_H___
#define __MK_XAxisView_H___
#import <appkit/appkit.h>

@interface XAxisView:View
{	
    float  *cArray;				/* Userpath x and y position array */
    char   *oArray;				/* Userpath postscript operator array */
    float   bbox[4];			/* Userpath bounding box array */
	int		majorTicks;			/* Number of major tick marks */
	int		minorTicks;			/* Number of minor tick marks */
	BOOL 	needNewUserPath;	/* Whether user path needs to be updated */
	char 	**labelArray;		/* Array of label strings */
	int		labelArraySize;		/* Length of label array */
	float	*labelPositions;	/* Array of label x positions */
	float	labelWidth;			/* Maximum label width */
	float	minValue;			/* Value at left end of axis */
	float	maxValue;			/* Value at right end of axis */
	float	resolution;			/* Number of points per unit value */
	id		font;				/* Font used for labels */
	float	backgroundGray;		/* Gray value used to paint the background */
	float	lineGray;			/* Gray value used to draw the lines */
	BOOL	constrained;		/* Whether labels must be adjusted to fit view bounds */

	float 	firstMajorTick;		/* X location of first major tick */
	float 	majorTickInterval;	/* Interval between major ticks */
	BOOL showLabels;
}

- setMinDisplayValue:(float)value;
- setMaxDisplayValue:(float)value;
- (float)minDisplayValue;
- (float)maxDisplayValue;
- (float)valueForX:(float)x;
- (float)xForValue:(float)value;
- setLineGray:(float)gray;
- setBackgroundGray:(float)gray;
- (float)lineGray;
- (float)backgroundGray;
- (int)majorTicks;
- (int)minorTicks;
- (float)firstMajorTick;
- (float)majorTickInterval;
- setConstrained:(BOOL)flag;
- setShowLabels:(BOOL)flag;

@end
#endif
