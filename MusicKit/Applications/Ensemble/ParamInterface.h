#ifndef __MK_ParamInterface_H___
#define __MK_ParamInterface_H___
#import <AppKit/AppKit.h>
#import <MusicKit/MusicKit.h>

#define NUM_MIDI_NAMES 136
#define MK_PAR_START NUM_MIDI_NAMES

extern int _MKHighestPar();

extern void setControlValToInt(id note, int control, int value);
extern void setControlValToDouble(id note, int control, double value);
extern int getControlValAsInt(id note, int control);
extern double getControlValAsDouble(id note, int control);
extern BOOL isControlPresent(id note, int control);
extern void removeControl(id note, int control);
extern const char *controlNames(int control);

extern double timeForBeatIndex(int index);
extern int beatIndexForTime(float time);

/* The four possible types of displayed values */

#define INTS		0
#define DOUBLES		1
#define CONTROLS	2
#define KEYNUMS		3
#define BEATS		4
#define DB			5

@interface ParamInterface:NSActionCell
{
	id textFields;
	id sliders;
	int *intValues;
	double *doubleValues;
	int *displayModes;
	double *precisions;
	int numValues;
	BOOL isMatrix;
	int numRows;
	int numCols;
	int selectedRow;
	int selectedCol;
	int selectedIndex;
}

+ (const char *)keyNameFor:(int)keyNum;
+ (const char *)midiNameFor:(int)controller;
- setMode:(int)displayMode;					/* Set type of data being interfaced */
- setModeAt:(int)index to:(int)displayMode;	/* Set type of data at index */
- setModeAt:(int)row:(int)col to:(int)displayMode;	/* Set type at cell */
- takeValueFrom:sender;						/* Get a value from slider or text field */
- incrementValueFrom:sender;				/* Increment or decrement the controls */
- setIntValue:(int)value;					/* Display the specified value */
- setDoubleValue:(double)value;				/* Display the specified value */
- setIntValueAt:(int)index to:(int)aValue;	/* Display one of a matrix of values */
- setDoubleValueAt:(int)index to:(double)aValue;  /* Same */
- setIntValueAt:(int)row:(int)col to:(int)aValue; /* Display one of a matrix of values */
- setDoubleValueAt:(int)row:(int)col to:(double)aValue;	/* Same */
- setIntValues:(int *)values;
- setDoubleValues:(double *)value;
- (int)intValue;							/* Get the last modified or only value */
- (int *)intValues;							/* Get all the values */
- (int)intValueAt:(int)index;				/* Get one of a matrix of values */
- (int)intValueAt:(int)row:(int)col;		/* Get one of a matrix of values */
- (double)doubleValue;						/* Get the last modified or only value */
- (double *)doubleValues;					/* Get all the values */
- (double)doubleValueAt:(int)index;			/* Get one of a matrix of values */
- (double)doubleValueAt:(int)row:(int)col;	/* Get one of a matrix of values */
- (int)numValues;							/* How many values are displayed */
- (int)selectedRow;							/* Row of last selected slider or field */
- (int)selectedCol;							/* Column of last selected slider or field */
- (int)selectedIndex;						/* Index of last selected slider or field */
- setEnabledAt:(int)index to:(BOOL)flag;
- setPrecision:(int)precision;
- setPrecisionAt:(int)index to:(int)precision;

@end
#endif
