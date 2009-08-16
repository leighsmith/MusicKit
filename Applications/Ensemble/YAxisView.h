#ifndef __MK_YAxisView_H___
#define __MK_YAxisView_H___
#import <appkit/appkit.h>

@interface YAxisView:View
{	
    float  *cArray;				/* Userpath x and y position array */
    char   *oArray;				/* Userpath postscript operator array */
    float   bbox[4];			/* Userpath bounding box array */
	int		majorTicks;			/* Number of major tick marks */
	int		minorTicks;			/* Number of minor tick marks */
	BOOL 	needNewUserPath;	/* Whether user path needs to be updated */
	char 	**labelArray;		/* Array of label strings */
	int		labelArraySize;		/* Length of label array */
	float	*labelPositions;	/* Array of label y positions */
	float	labelWidth;			/* Maximum label width */
	float	minValue;			/* Value at bottom of axis */
	float	maxValue;			/* Value at top of axis */
	float	resolution;			/* Number of points per unit value */
	id		font;				/* Font used for labels */
	float	backgroundGray;		/* Gray value used to paint the background */
	float	lineGray;			/* Gray value used to draw the lines */
	BOOL	constrained;		/* Whether labels must be adjusted to fit view bounds */

	BOOL	autoTicks;			/* Whether to automatically set number of ticks */
	BOOL	showLabels;			/* Whether to show labels */
	int		minorDivs;			/* Number of minor tick divisions per major tick */
	float	labelHeight;		/* Height of label in current font */
	
	float majorTickInterval;
	float firstMajorTick;
}

- setMinDisplayValue:(float)value;
- setMaxDisplayValue:(float)value;
- (float)minDisplayValue;
- (float)maxDisplayValue;
- (float)valueForY:(float)y;
- (float)yForValue:(float)value;
- setLineGray:(float)gray;
- setBackgroundGray:(float)gray;
- (float)lineGray;
- (float)backgroundGray;
- (int)majorTicks;
- (int)minorDivs;
- setConstrained:(BOOL)flag;
- setAutoTicks:(BOOL)flag;
- setMajorTicks:(int)numTicks;
- setMinorDivs:(int)numDivs;
- setFontSize:(float)size;
- setShowLabels:(BOOL)flag;
- (float)majorTickInterval;
- (float)firstMajorTick;

@end
#endif
