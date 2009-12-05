/* This object facilitates the construction of interfaces to standard types of data. Special consideration is given to the appropriate display of musical data types such as MIDI controller names, Music Kit parameter names, key numbers, and beats.

This object is a subclass of ActionCell, but mostly just to allow connection of its instance variables and action method in NIB.  The only action methods that count here are -takeValueFrom:, assumed to come from a Slider, TextField, SliderCell, or TextFieldCell, and - incrementValueFrom:, assumed to come from a two-cell button matrix with tags of 1 and -1.

The object has it's own notion of data type, independently for each text field cell.  There are five types, defined as the macros INTS, DOUBLES, CONTROLS, KEYNUMS, and BEATS.  The default type for each text cell is INTS, except when there is a slider associated with the text cell whose maximum-minimum values is less than 3, in which case the default type is DOUBLES.

For type CONTROLS, ParamInterface implements a concept of a continuous array of possible control parameters, consisting of all the MIDI controller values, followed by all the defined Music Kit parameter values.   Integer values less than 128 are assumed to be MIDI controllers, values between 128 and 135 correspond to MIDI System Real Time messages, and values of 135 and above are assumed to refer to the corresponding Music Kit parameter enum value + 135.  If a non-numeric string is entered into the text cell, an attempt is made to match it with a MIDI controller or MK parameter name.  If no match is found, the user is prompted to create a new Music Kit parameter with that name.  This parameter may thereafter be refered to anywhere in the app.

For type BEATS, an array is constructed at initialization time which contains pointers to structures of type beat.  Each beat struct represents a common musical beat time or fraction thereof, such as 1 3/4 beats, or 3 2/5 beats.  The resolution goes down as the beat times get higher.  Incoming double values from the text field or interfaced object are assumed to be times in seconds, and incoming integer values are assumed to be indices into the beat array.

For type KEYNUMS, an array is constructed at initialization time which contains the string names of the corresponding MIDI key numbers. Incoming double values from the text field or interfaced object are assumed to be frequencies in seconds, which are converted into the nearest key number, and incoming integer values are assumed to be indices into the key name array.  Either key name strings or key numbers may be typed into the text field.

This object is not really inteneded to be archived.  Instatiate it in your NIB file and then set its initial values in your object's -awakeFromNib method.

*/

#import "ParamInterface.h"
#include <MusicKit/MusicKit.h>
#include <ctype.h>

/* ------------ MIDI controller name definitions --------------- */

const char *midiNames[NUM_MIDI_NAMES] = {
	"0", "Modwheel", "Breath", "3", "Foot", "Portamento", "Dataentry",
	"Mainvolume", "Balance", "9", "Pan", "Expression",
	"Effect 1", "Effect 2", "14", "15", "16", "17", "18", "19",
	"20", "21", "22", "23", "24", "25", "26", "27", "28", "29",
	"30", "31", "32", "33", "34", "35", "36", "37", "38", "39",
	"40", "41", "42", "43", "44", "45", "46", "47", "48", "49",
	"50", "51", "52", "53", "54", "55", "56", "57", "58", "59",
	"60", "61", "62", "63",
	"Damper", "Portamento", "Sostenuto", "Softpedal", "68", "Hold2",
	"70", "71", "72", "73", "74", "75", "76", "77", "78", "79",
	"80", "81", "82", "83", "84", "85", "86", "87", "88", "89",
	"90", "EffectControl1", "EffectControl2", "EffectControl3", "EffectControl4",
	"EffectControl5", "Dataincrement", "Datadecrement", "98", "99",
	"100", "101", "102", "103", "104", "105", "106", "107", "108", "109",
	"110", "111", "112", "113", "114", "115", "116", "117", "118", "119",
	"120", "ResetControllers", "LocalControl", "AllNotesOff", "OmniOff",
	"OmniOn", "MonoModeOn", "PolyModeOn", "Clock", "RealTime1", "Start", "Continue", "Stop", "RealTime5", "ActiveSensing", "Reset"};

const char *controlNames(int control)
	/* Return the name of the corresponding MIDI controller if control < 128,
	 * or the name of the System Real Time message if less than 135, or the
	 * corresponding Music Kit parameter - 135 if controller >= 135.
	 */
{
	if (control < 0)
		return "Off";
	else if (control < MK_PAR_START) 
		return midiNames[control];
	else if (control-MK_PAR_START <= _MKHighestPar())
		return (const char *)[Note parNameForTag:control-MK_PAR_START];
	return "";
}

static BOOL strcmpNoCase(char *s1, char *s2)
	/* Compare two strings in a case-independent fashion */
{
	char c1, c2;
	while (*s1 && *s2) {
		c1 = isupper(*s1) ? *s1 : toupper(*s1);
		c2 = isupper(*s2) ? *s2 : toupper(*s2);
		if (c1 != c2) return 1;
		s1++; s2++;
	}
	return (*s1 || *s2);
}
 
static int controlFromName(char *name)
{
	int i, j, n = _MKHighestPar();
	char *p;
	if (!strcmpNoCase(name,"OFF")) return -1;
	/* First check to see if it's a MIDI controller name or number */
	for (i=0; i<MK_PAR_START; i++) {
		j = strtol(name,&p,0);
		if ((!*p && (j==i)) ||
			!strcmpNoCase(name,(char *)midiNames[i])) return i;
	}
	/* Then check all the Music Kit parameters */
	for (i=0; i<=n; i++)
		if (!strcmpNoCase(name,[Note parNameForTag:i])) return MK_PAR_START+i;
	if (NXRunAlertPanel([NXApp appName],"Create new parameter %s?",
			"Ok", "Cancel", NULL, name) == NX_ALERTDEFAULT)
		return [Note parTagForName:name]+MK_PAR_START;
	return MAXINT;
}

void setControlValToInt(id note, int control, int value)
{
	if (control < 128) {
		MKSetNoteParToInt(note, MK_controlChange, control);
		MKSetNoteParToInt(note, MK_controlVal, value);
	}
	else if (control < MK_PAR_START) /* value is ignored */
		MKSetNoteParToInt(note, MK_sysRealTime, MK_sysClock+control-128);
	else MKSetNoteParToInt(note, control-MK_PAR_START, value);
}

void setControlValToDouble(id note, int control, double value)
{
	if (control < 128) {
		MKSetNoteParToInt(note, MK_controlChange, control);
		MKSetNoteParToDouble(note, MK_controlVal, value);
	}
	else if (control < MK_PAR_START)
		MKSetNoteParToInt(note, MK_sysRealTime, MK_sysClock+control-128);
	else MKSetNoteParToDouble(note, control-MK_PAR_START, value);
}

int getControlValAsInt(id note, int control)
{
	if (control < 128) {
		if (MKGetNoteParAsInt(note, MK_controlChange) == control)
			return MKGetNoteParAsInt(note, MK_controlVal);
		else return MAXINT;
	}
	else if (control < MK_PAR_START)
		return MKGetNoteParAsInt(note, MK_sysClock+control-128);
	return MKGetNoteParAsInt(note, control-MK_PAR_START);
}

double getControlValAsDouble(id note, int control)
{
	if (control < 128) {
		if (MKGetNoteParAsInt(note, MK_controlChange) == control)
			return MKGetNoteParAsDouble(note, MK_controlVal);
		else return MK_NODVAL;
	}
	else if (control < MK_PAR_START)
		return MKGetNoteParAsDouble(note, MK_sysClock+control-128);
	return MKGetNoteParAsDouble(note, control-MK_PAR_START);
}

BOOL isControlPresent(id note, int control)
{
	if ((control < 128) && 
		(MKGetNoteParAsInt(note, MK_controlChange)==control))
		return YES;
	else if ((control < MK_PAR_START) &&
			 (MKGetNoteParAsInt(note, MK_sysRealTime) == MK_sysClock+control-128))
		return YES;
	return MKIsNoteParPresent(note, control-MK_PAR_START);
}

void removeControl(id note, int control)
{
	if (control < 128) {
		[note removePar:MK_controlChange];
		[note removePar:MK_controlVal];
	}
	else if (control < MK_PAR_START)
		[note removePar:MK_sysClock+control-128];
	[note removePar:control-MK_PAR_START];
}

/* ------------ Key name definitions --------------- */

#define NUM_KEYNAMES 144

const char *keyNames[NUM_KEYNAMES];
static BOOL keyNamesInitialized = NO;

static void initializeKeyArrays()
 /* Construct an array of note names indexed by key number */
{
	int i = 0, j, n = 0;
	int size = sizeof(char)*5;
	char *noteNames[] =
		{"C", "C#", "D", "Eb", "E", "F", "F#", "G", "G#", "A", "Bb", "B"};
	char *octaveNames[] =
		{"00", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"};
	while (n < NUM_KEYNAMES) {
		for (j = 0; j < 12; j++) {
			keyNames[n] = NXZoneMalloc([NXApp zone], size);
			strcpy((char *)keyNames[n],noteNames[j]);
			strcat((char *)keyNames[n], octaveNames[i]);
			if (++n == NUM_KEYNAMES) break;
		}
		i++;
	}
	keyNamesInitialized = NO;
}

static int keyNumFromName(char *name)
{
	int key;
	if (isdigit(*name)) {
		if (strchr(name,'.'))
			/* It's a frequency */
			key = MKFreqToKeyNum(strtod(name,NULL),NULL,0);
		else
			/* It's a key number */
			key = strtol(name,NULL,10);
	}
	else /* Must be a literal like "c4" */
		for (key=0; key<NUM_KEYNAMES; key++)
			if (!strcmpNoCase(name,(char *)keyNames[key])) return key;
	return MAXINT;
}



/* ------------ Beat value definitions --------------- */

/* We construct an array of time values which correspond to likely beat values
 * and fractional beat values, e.g., 1 5/16 beats, or 4 1/3 beats.  The number
 * of sub-beat divisions is large for small values and goes down for larger beat
 * values.
 *
 * The idea is that these are values that the user is likely to want to choose
 * from in specifying note durations, echo times, etc.
 *
 * The user is of course also allowed to type any arbitrary number into the
 * text field.
 */

#define NUM_BEATS 294

typedef struct {int wholePart; int numer; int denom; double value;} rational;
static rational **beats = NULL;
static int numBeats = 0;

static int rationalCompare(const void *r1, const void *r2)
{
	rational *b1 = *(rational **)r1;
	rational *b2 = *(rational **)r2;
	return ((b2->value-b1->value) > .001) ? -1 : 
			 (((b1->value-b2->value) > .001) ? 1 :
				((b1->numer > b2->numer) ? 1 : 0));
}

static BOOL beatsInitialized = NO;

static void initializeBeats()
{
	int i, j, k;
	rational *beat, *b1, *b2;
	double d;
	int denoms[11] = {1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 32};

	beats = (rational **)malloc(sizeof(rational *)*NUM_BEATS*8);

	/* Build a list of beats plus common fractional beats */
	for (k=0; k<NUM_BEATS; k++) {
		for (i=0; i<MAX(11-k,1); i++) {
			d = denoms[i];
			for (j=0; j<d; j++) {
				beat = beats[numBeats++] = (rational *)malloc(sizeof(rational));
				beat->wholePart = k;
				beat->numer = j;
				beat->denom = d;
				beat->value = (double)k + (double)j / (double)d;
			}
		}
	}

	/* Sort in time order */
	qsort(beats, numBeats, sizeof(rational *), rationalCompare);

	/* Get rid of duplicate times */
	for (i=0; i<numBeats-1; i++) {
		b1 = beats[i];
		b2 = beats[i+1];
		if (fabs(b1->value-b2->value)<.001) {
			memcpy(&(beats[i+1]), &(beats[i+2]), sizeof(rational *)*(numBeats-i));
			i--;
			numBeats--;
		}
	}
	
	beats = (rational **)realloc(beats, sizeof(rational *)*numBeats);
	beatsInitialized = YES;
}

static char *beatString(rational *beat)
{
	static char s[32];
	if (beat->numer==0) 
		sprintf(s, "%.0f", beat->value);
	else if (beat->wholePart==0)
		sprintf(s, "%.3g (%d/%d)",
			beat->value, beat->numer, beat->denom);
	else
		sprintf(s, "%.3g (%d %d/%d)",
			beat->value, beat->wholePart, beat->numer, beat->denom);
	return s;
}

int beatIndexForTime(float time)
{
	rational **beat = beats;
	rational **end = beat + numBeats;
	while ((beat < end) && (time > (*beat)->value)) beat++;
	if (beat == beats) return 0;
	if (beat == end) return numBeats-1;
	return ((time-(*(beat-1))->value) < ((*beat)->value-time)) ? 
			beat-beats-1 : beat-beats;
}

double timeForBeatIndex(int index)
{
	if (!beatsInitialized) initializeBeats();
	return (index < numBeats) ? beats[index]->value : MK_ENDOFTIME;
}

static char *dbString(int dB)
{
	static char s[32];
	sprintf(s, "%+2ddB", dB);
	return s;
}

static int ampToDB(double linearAmp)
{
	return (int)floor(20.0*log10(linearAmp)+.5);
}

static id matrixClass, sliderClass, textFieldClass, sliderCellClass, textFieldCellClass;

#define IS_MATRIX(aControl) ([control isKindOf:matrixClass])

typedef struct {@defs (Matrix)} matrixId;
#define CELLS(matrix) (NX_ADDRESS(((matrixId *)(matrix))->cellList))
#define CELL_AT(matrix,i) (*((NX_ADDRESS(((matrixId *)(matrix))->cellList))+i))

@implementation ParamInterface
{}

+ initArrays
{
	if (!keyNamesInitialized) initializeKeyArrays();
	if (!beatsInitialized) initializeBeats();
	return self;
}	

+ initialize
{
	matrixClass = [Matrix class];
	sliderClass = [Slider class];
	textFieldClass = [TextField class];
	sliderCellClass = [SliderCell class];
	textFieldCellClass = [TextFieldCell class];
	[ParamInterface initArrays];
	return self;
}

+ (const char *)keyNameFor:(int)keyNum
{
	return keyNames[keyNum];
}

+ (const char *)midiNameFor:(int)controller
{
	return midiNames[controller];
}

- awakeFromNib
{
	if (textFields && [textFields isKindOf:matrixClass]) {
		int i;
		isMatrix = YES;
		[textFields getNumRows:&numRows numCols:&numCols];
		numValues =  numRows * numCols;
		displayModes = NXZoneCalloc([self zone], numValues, sizeof(int));
		if (sliders && [sliders isKindOf:matrixClass]) {
			/* If sliders have a range of less than 10, default to DOUBLES format,
			 * and set display precision accordingly.
			 */
			TextFieldCell **textCells = (TextFieldCell **)CELLS(textFields);
			SliderCell **sliderCells = (SliderCell **)CELLS(sliders);
			double range;
			int precision;
			for (i=0; i<numValues; i++) {
				range = [sliderCells[i] maxValue] - [sliderCells[i] minValue];
				if (range < 10.0) {
					precision = (range > 1.0) ? 2 : 3;
					displayModes[i] = DOUBLES;
					[textCells[i] setFloatingPointFormat:NO left:3-precision
						right:precision];
				}
			}
		}
	}
	else if	(sliders && [sliders isKindOf:matrixClass]) {
		isMatrix = YES;
		[sliders getNumRows:&numRows numCols:&numCols];
		numValues =  numRows * numCols;
		displayModes = NXZoneCalloc([self zone], numValues, sizeof(int));
	}
	else {
		numRows = numCols = numValues = 1;
		displayModes = NXZoneCalloc([self zone], numValues, sizeof(int));
		if (sliders && 
			(([(Slider *)sliders maxValue] - [(Slider *)sliders minValue]) < 3.0)) {
			displayModes[0] = DOUBLES;
			[textFields setFloatingPointFormat:NO left:1 right:3];
		}
	}
	precisions = NXZoneCalloc([self zone], numValues, sizeof(double));
	intValues = NXZoneCalloc([self zone], numValues, sizeof(int));
	doubleValues = NXZoneCalloc([self zone], numValues, sizeof(double));
	return self;
}

- free
{
	if (displayModes) NXZoneFree([self zone], displayModes);
	if (precisions)  NXZoneFree([self zone], precisions);
	if (intValues) NXZoneFree([self zone], intValues);
	if (doubleValues) NXZoneFree([self zone], doubleValues);
	displayModes = NULL;
	precisions = NULL;
	intValues = NULL;
	doubleValues = NULL;
	return [super free];
}
	
- setModeAt:(int)index to:(int)mode
{
	int oldMode = displayModes[index];
	id cell = ([textFields isKindOf:matrixClass]) ? 
				CELL_AT(textFields,index) : [textFields cell];
	int precision = 3;
	displayModes[index] = mode;
	switch (mode) {
		case INTS: 
			[cell setEntryType:NX_INTTYPE];
			break;
		case DOUBLES: 
			[cell setEntryType:NX_FLOATTYPE];
			if (sliders) {
				SliderCell *slCell = (isMatrix)?CELL_AT(sliders,index):[sliders cell];
				double range = [slCell maxValue] - [slCell minValue];
				precision = (range > 10.0) ? 1 : ((range > 1.0) ? 2 : 3);
			}
			[cell setFloatingPointFormat:NO left:3-precision right:precision];
			break;
		case CONTROLS:
			[cell setEntryType:NX_ANYTYPE];		/* Might be a text string or int */
			if (oldMode != CONTROLS)
				[self setIntValueAt:index to:-1];
			break;
		case KEYNUMS:
		case BEATS:
		case DB: 
		default:
			[cell setEntryType:NX_ANYTYPE];
			break;
	}
	return self;
}

- setModeAt:(int)row :(int)col to:(int)mode
{
	return [self setModeAt:row*numCols+col to:mode];
}

- setMode:(int)mode
{
	int i;
	for (i=0; i<numValues; i++)
		[self setModeAt:i to:mode];
	return self;
}

- setPrecisionAt:(int)index to:(int)precision
{
	precisions[index] = pow(10.0,(double)precision);
	if ((precision > 0) && (displayModes[index] != DOUBLES))
		[self setModeAt:index to:DOUBLES];
	[CELL_AT(textFields,index) setFloatingPointFormat:NO left:2 right:precision];
 	return self;
}

- setPrecisionAt:(int)row :(int)col to:(int)precision
{
	return [self setPrecisionAt:row*numCols+col to:precision];
}

- setPrecision:(int)precision
{
	int i;
	for (i=0; i<numValues; i++)
		[self setPrecisionAt:i to:precision];
	return self;
}

- updateText:field toIntAt:(int)index
{
	switch (displayModes[index]) {
		case INTS:
			[field setIntValue:intValues[index]];
			break;
		case DOUBLES:
			[field setDoubleValue:(double)intValues[index]];
			break;
		case CONTROLS:
			[field setStringValueNoCopy:controlNames(intValues[index])];
			break;
		case KEYNUMS:
			if (intValues[index] < 0) [field setStringValue:""];
			else [field setStringValueNoCopy:
					keyNames[MIN(MAX(intValues[index],0),NUM_KEYNAMES-1)]];
			break;
		case BEATS:
			/* We assume an int is an index into the beats array */
			if (intValues[index] >= 0)
				[field setStringValue:
					beatString(beats[MIN(MAX(intValues[index],0),numBeats)])];
			else [field setStringValue:"---"];
			break;
		case DB:
			[field setStringValue:dbString(intValues[index])];
			break;
		default:
			[field setIntValue:intValues[index]];
			break;
	}
	return self;
}

- updateText:field toDoubleAt:(int)index
{
	switch (displayModes[index]) {
		case INTS:
			[field setIntValue:(int)(doubleValues[index]+0.5)];
			break;
		case DOUBLES:
			[field setDoubleValue:doubleValues[index]];
			break;
		case KEYNUMS:
			[field setStringValueNoCopy:
				keyNames[MKFreqToKeyNum(doubleValues[index],NULL,0)]];
			break;
		case BEATS: {
			/* We assume that a double is a time, not an index */
			if (doubleValues[index] >= 0.0) {
				rational *beat = beats[beatIndexForTime(doubleValues[index])];
				if (fabs(beat->value-doubleValues[index]) < .001)
					[field setStringValue:beatString(beat)];
				else [field setDoubleValue:doubleValues[index]];
			}
			else [field setStringValue:"---"];
			break;
		}
		case DB:
			/* We assume a double value is a linear amp */
			[field setStringValue:dbString(ampToDB(doubleValues[index]))];
			break;
		default:
			[field setDoubleValue:doubleValues[index]];
			break;
	}
	return self;
}

- updateSlider:slider toIntAt:(int)index
{
	switch (displayModes[index]) {
		case DOUBLES:
		case INTS:
		case CONTROLS:
		case KEYNUMS:
		case BEATS:	/* Beat sliders index into an array of preset times */
		case DB:
		default:
			[slider setIntValue:intValues[index]];
			break;
	}
	return self;
}

- updateSlider:slider toDoubleAt:(int)index
{
	switch (displayModes[index]) {
		case INTS:
		case DOUBLES:
			[slider setDoubleValue:doubleValues[index]];
			break;
		case CONTROLS:
			[slider setIntValue:(int)doubleValues[index]];
			break;
		case KEYNUMS:
			[slider setIntValue:MKFreqToKeyNum(doubleValues[index],NULL,0)];
			break;
		case BEATS:
			[slider setIntValue:beatIndexForTime(doubleValues[index])];
			break;
		case DB:
			/* We assume a double value is a linear amp */
			[slider setIntValue:ampToDB(doubleValues[index])];
			break;
		default:
			[slider setDoubleValue:doubleValues[index]];
	}
	return self;
}

- takeValueFrom:sender
{
	id slider = nil, field = nil;

	if (isMatrix) {
		id matrix = sender;
		sender = [sender selectedCell];
		selectedRow = [matrix selectedRow];
		selectedCol = [matrix selectedCol];
		selectedIndex = selectedRow*numCols + selectedCol;
		if ([sender isKindOf:sliderCellClass]) {
			slider = sender;
			if (textFields)
				field = [textFields cellAt:selectedRow:selectedCol];
		}
		else {
			field = sender;
			if (sliders)
				slider = [sliders cellAt:selectedRow:selectedCol];
		}
	}
	else {
		slider = sliders;
		field = textFields;
	}

	if (sender == slider) {
		double pr = precisions[selectedIndex];
		switch (displayModes[selectedIndex]) {
			case BEATS:
				intValues[selectedIndex] = [sender intValue];
				if (intValues[selectedIndex] >= 0) {
					doubleValues[selectedIndex] = beats[intValues[selectedIndex]]->value;
					if (pr)
						doubleValues[selectedIndex] =
							floor(doubleValues[selectedIndex]*pr)/pr;
				}
				else doubleValues[selectedIndex] = MK_NODVAL;
				[self updateText:field toIntAt:selectedIndex];
				break;
			case DB:
				intValues[selectedIndex] = [sender intValue];
				doubleValues[selectedIndex] = MKdB(intValues[selectedIndex]);
				if (pr)
					doubleValues[selectedIndex]=floor(doubleValues[selectedIndex]*pr)/pr;
				[self updateText:field toIntAt:selectedIndex];
				break;
			case DOUBLES:
				doubleValues[selectedIndex] = [sender doubleValue];
				if (pr)
					doubleValues[selectedIndex]=floor(doubleValues[selectedIndex]*pr)/pr;
				intValues[selectedIndex] = (int)floor(doubleValues[selectedIndex]+0.5);
				[self updateText:field toDoubleAt:selectedIndex];
				break;
			default:
				intValues[selectedIndex] = [sender intValue];
				doubleValues[selectedIndex] = (double)intValues[selectedIndex];
				[self updateText:field toIntAt:selectedIndex];
				break;
		}
	}
	else {
		switch (displayModes[selectedIndex]) {
			case INTS:
				intValues[selectedIndex] = [sender intValue];
				doubleValues[selectedIndex] = (double)intValues[selectedIndex];
				if (slider) {
					if (doubleValues[selectedIndex] > [(Slider *)slider maxValue])
						[slider setMaxValue:doubleValues[selectedIndex]];
					if (doubleValues[selectedIndex] < [(Slider *)slider minValue])
						[slider setMinValue:doubleValues[selectedIndex]];
					[self updateSlider:slider toIntAt:selectedIndex];
				}
				break;
			case DOUBLES:
				doubleValues[selectedIndex] = [sender doubleValue];
				intValues[selectedIndex] = (int)(doubleValues[selectedIndex]+.5);
				if (slider) {
					if (doubleValues[selectedIndex] > [(Slider *)slider maxValue])
						[slider setMaxValue:doubleValues[selectedIndex]];
					if (doubleValues[selectedIndex] < [(Slider *)slider minValue])
						[slider setMinValue:doubleValues[selectedIndex]];
					[self updateSlider:slider toDoubleAt:selectedIndex];
				}
				break;
			case CONTROLS: {
					int value = controlFromName((char *)[sender stringValue]);
					doubleValues[selectedIndex] = (double)value;
					intValues[selectedIndex] = value;
					if (slider) {
						if (value > [(Slider *)slider maxValue])
							[slider setMaxValue:value];
						[self updateSlider:slider toIntAt:selectedIndex];
					}
				}
				break;
			case KEYNUMS: {
					int value = keyNumFromName((char *)[sender stringValue]);
					if (value != MAXINT) {
						doubleValues[selectedIndex] = (double)value;
						intValues[selectedIndex] = value;
					}
					[self updateText:field toIntAt:selectedIndex];
					if (slider) {
						if (intValues[selectedIndex] > [(Slider *)slider maxValue])
							[slider setMaxValue:intValues[selectedIndex]];
						if (intValues[selectedIndex] < [(Slider *)slider minValue])
							[slider setMinValue:intValues[selectedIndex]];
						[self updateSlider:slider toIntAt:selectedIndex];
					}
				}
				break;
			case BEATS:
				doubleValues[selectedIndex] = [sender doubleValue]; /* time in seconds */
				intValues[selectedIndex] = beatIndexForTime(doubleValues[selectedIndex]);
				if (slider) {	
					if (intValues[selectedIndex] > [(Slider *)slider maxValue])
						[slider setMaxValue:intValues[selectedIndex]];
					if (intValues[selectedIndex] < [(Slider *)slider minValue])
						[slider setMinValue:intValues[selectedIndex]];
					[self updateSlider:slider toIntAt:selectedIndex];
				}
				break;
			case DB:
				doubleValues[selectedIndex] = MKdB([sender doubleValue]);
				intValues[selectedIndex] = (int)floor([sender doubleValue]+0.5);
				[self updateText:field toIntAt:selectedIndex];
				break;
			default:
				doubleValues[selectedIndex] = [sender doubleValue];
				intValues[selectedIndex] = (int)doubleValues[selectedIndex];
				[slider setIntValue:intValues[selectedIndex]];
		}
	}
	
	[target perform:action with:self];
	return self;
}

- incrementValueFrom:sender
	/* We assume the sender is a two button matrix, with the matrix tag indicating
	 * which element is being adjusted, and the cell tag indicating the increment
	 */
{
	int index = [sender tag];
	int direction = ([[sender selectedCell] tag] < 0) ? -1 : 1;
	int row = index/numCols;
	int col = index - row*numCols;
	if (displayModes[index] == DOUBLES) {
		double value = doubleValues[index]+(double)direction*0.1;
		if (value < .001) value = 0.0;
		[self setDoubleValueAt:row:col to:value];
	}
	else {
		int value = intValues[index]+direction;
		switch (displayModes[index]) {
			case CONTROLS:
				if (value < -1) value = -1.0;
				if (value > _MKHighestPar()+MK_PAR_START)
					value = _MKHighestPar()+MK_PAR_START;
				break;
			case BEATS:
				if (value < 0) value = 0;
				if (value >= NUM_BEATS) value = NUM_BEATS-1;
				break;
			case KEYNUMS:
				if (value < 0) value = 0;
				if (value >= NUM_KEYNAMES) value = NUM_KEYNAMES-1;
				break;
			default:
				break;
		}
		[self setIntValueAt:row:col to:value];
	}
	[target perform:action with:self];
	return self;
}

- setIntValueAt:(int)row :(int)col to:(int)value
{
	id slider = isMatrix ? [sliders cellAt:row:col] : sliders;
	id field = isMatrix ? [textFields cellAt:row:col] : textFields;
	int index = row*numCols + col;
	if (index < numValues) {
		selectedIndex = index;
		selectedRow = row;
		selectedCol = col;
		intValues[selectedIndex] = value;
		if (displayModes[selectedIndex]==BEATS)
			doubleValues[selectedIndex] = timeForBeatIndex(value);
		else doubleValues[selectedIndex] = (double)value;
		if (slider) [self updateSlider:slider toIntAt:selectedIndex];
		if (field) [self updateText:field toIntAt:selectedIndex];
	}
	return self;
}

- setDoubleValueAt:(int)row :(int)col to:(double)value
{
	id slider = isMatrix ? [sliders cellAt:row:col] : sliders;
	id field = isMatrix ? [textFields cellAt:row:col] : textFields;
	int index = row*numCols + col;
	if (index < numValues) {
		selectedIndex = index;
		selectedRow = row;
		selectedCol = col;
		doubleValues[selectedIndex] = value;
		if (displayModes[selectedIndex]==BEATS) {
			intValues[selectedIndex] = beatIndexForTime(value);
			if (slider) [self updateSlider:slider toIntAt:selectedIndex];
		}
		else {
			intValues[selectedIndex] = (int)(value+0.5);
			if (slider) [self updateSlider:slider toDoubleAt:selectedIndex];
		}
		if (field) [self updateText:field toDoubleAt:selectedIndex];
	}
	return self;
}

- setIntValueAt:(int)index to:(int)value
{
	int row = index/numCols;
	int col = index - row*numCols;
	return [self setIntValueAt:row:col to:value];
}

- setDoubleValueAt:(int)index to:(double)value
{
	int row = index/numCols;
	int col = index - row*numCols;
	return [self setDoubleValueAt:row:col to:value];
}

- setIntValue:(int)value
{
	if (numValues == 1)
		[self setIntValueAt:0:0 to:value];
	else {
		int i;
		for (i=0; i<numValues; i++)
			[self setIntValueAt:i to:value];
	}
	return self;
}

- setDoubleValue:(double)value
{
	if (numValues == 1)
		[self setDoubleValueAt:0:0 to:value];
	else {
		int i;
		for (i=0; i<numValues; i++)
			[self setDoubleValueAt:i to:value];
	}
	return self;
}

- setIntValues:(int *)values
{
	int i;
	for (i=0; i<numValues; i++)
		[self setIntValueAt:i to:values[i]];
	return self;
}

- setDoubleValues:(double *)values
{
	int i;
	for (i=0; i<numValues; i++)
		[self setDoubleValueAt:i to:values[i]];
	return self;
}

- (int)intValueAt:(int)row:(int)col
	/* Get one of a matrix of values */
{
	return intValues[row*numCols+col];
}

- (double)doubleValueAt:(int)row:(int)col
	/* Get one of a matrix of values */
{
	return doubleValues[row*numCols+col];
}

- (int)intValueAt:(int)index
	/* Get one of a matrix of values */
{
	return intValues[index];
}

- (double)doubleValueAt:(int)index
	/* Get one of a matrix of values */
{
	return doubleValues[index];
}

- (int)intValue
	/* Get the last modified (or only) value */
{
	return intValues[selectedIndex];
}

- (double)doubleValue
	/* Get the last modified (or only) value */
{
	return doubleValues[selectedIndex];
}

- (int *)intValues
	/* Get all the values */
{
	return intValues;
}

- (double *)doubleValues
	/* Get all the values */
{
	return doubleValues;
}

- (int)selectedRow
{
	return selectedRow;
}
	
- (int)selectedCol
{
	return selectedCol;
}

- (int)selectedIndex
{
	return selectedIndex;
}
	
- (int)numValues
{
	return numValues;
}

- setEnabled:(BOOL)flag
{
	[textFields setEnabled:flag];
	[sliders setEnabled:flag];
	return self;
}

- setEnabledAt:(int)index to:(BOOL)flag
{
	if (textFields && [textFields isKindOf:matrixClass])
		[CELL_AT(textFields,index) setEnabled:flag];
	if (sliders && [sliders isKindOf:matrixClass])
		[CELL_AT(sliders,index) setEnabled:flag];
	return self;
}

@end