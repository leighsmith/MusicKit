/* An SynthInstrument for handling DBWave1vi synthpatches, and adjusting
 * their parameters via a graphic interface.
 */

#import "Wave1Instrument.h"
#import <appkit/appkit.h>
#import <objc/HashTable.h>
#import <mididriver/midi_spec.h>
#import <musickit/synthpatches/DBWave1vi.h>
#import "EnsembleApp.h"
#import "ParamInterface.h"
#import "EnvelopeView.h"

// extern double pow(double, double);
extern id sinePartials;			/* A global sinewave Partials object */
// extern long random();			/* the random number generator */

#define MAXRAN 2147483647.0		/* the maximum value random() generates */

#define NUMTIMBRES 30

/* The timbre codes in the Partials database */
char *timbreCodes[NUMTIMBRES] = {
					   "", "SA", "SO", "SU", "SE", "SI",
					   "TA", "TO", "TU", "TE", "TI",
					   "BA", "BO", "BU", "BE",
					   "VNA", "VNS", "VCA", "VCS",
					   "OB", "EH", "CL", "SS", "AS", "TR",
					   "BN", "BC", "PN", "TW", "SW"};

/* Descriptive names for the timbres */
char *timbreNames[NUMTIMBRES] = {
					   "Sine Wave",
		"Soprano ah", "Soprano oh", "Soprano oo", "Soprano eh", "Soprano ee",
				  "Tenor ah", "Tenor oh", "Tenor oo", "Tenor eh", "Tenor ee",
					   "Bass ah", "Bass oh", "Bass oo", "Bass eh",
			"Violin attack", "Violin middle", "Cello attack", "Cello middle",
			   "Oboe", "English Horn", "Clarinet", "Soprano Sax", "Alto Sax",
					   "Trumpet", "Bassoon", "Bass Clarinet", "Piano middle",
					   "Triangle Wave", "Square Wave"};

/* Test keys for the timbre codes */
int testKeys[NUMTIMBRES] = {
				  69,
				  69, 69, 69, 69, 69,
				  57, 57, 57, 57, 57,
				  42, 42, 42, 42,
				  69, 69, 42, 42,
				  69, 57, 69, 69, 57, 69,
				  30, 30, 57, 69, 69};

@implementation Wave1Instrument
{
}

+ initialize
{
	[Wave1Instrument setVersion:2];
	return self;
}

- initAmpEnvelope
 /* Initialize the amplitude envelope and the arrays used to constuct and
  * update it. 
  */
{
	double *ampX, *ampY;
	ampX = malloc(sizeof(double) * 4);
	ampY = malloc(sizeof(double) * 4);
	ampX[0] = 0;
	ampX[1] = 0.08;
	ampX[2] = 0.1;
	ampX[3] = 0.3;
	ampY[0] = 0;
	ampY[1] = 1;
	ampY[2] = 0.8;
	ampY[3] = 0;
	ampEnv = [[Envelope allocFromZone:[self zone]] init];
	[ampEnv setPointCount:4 xArray:ampX yArray:ampY];
	[ampEnv setStickPoint:2];
	free(ampX);
	free(ampY);
	return self;
}

- initWaveformButton
 /* Create a menu of timbres and attach it to the timbre buttons */
{
	int i, j;
	id obj;
	char *wave0, *wave1;

	if (!timbreMenu) {
		timbreMenu = [[PopUpList alloc] init];
		for (i = 0; i < NUMTIMBRES; i++)
			[timbreMenu addItem:timbreNames[i]];
	}
	/* We also want to initialize the menu titles to the default timbres */
	wave0 = [updates parAsStringNoCopy:MK_waveform0];
	wave1 = [updates parAsStringNoCopy:MK_waveform1];
	if ([waveformButton isKindOf:[Matrix class]]) {
		for (i = 0; i < [waveformButton cellCount]; i++)
			NXAttachPopUpList(obj = [waveformButton findCellWithTag:i],
							  timbreMenu);
		for (j = 0; j < NUMTIMBRES; j++)
			if (!strcmp(wave0, timbreCodes[j]))
				break;
		[[waveformButton findCellWithTag:0] setTitle:
			timbreNames[(j < NUMTIMBRES) ? j : 0]];
		testKey = testKeys[(j < NUMTIMBRES) ? j : 0];
		for (j = 0; j < NUMTIMBRES; j++)
			if (!strcmp(wave1, timbreCodes[j]))
				break;
		[[waveformButton findCellWithTag:1] setTitle:
			timbreNames[(j < NUMTIMBRES) ? j : 0]];
	} else {
		NXAttachPopUpList(waveformButton, timbreMenu);
		for (j = 0; j < NUMTIMBRES; j++)
			if (!strcmp(wave0, timbreCodes[j]))
				break;
		[waveformButton setTitle:timbreNames[(j < NUMTIMBRES) ? j : 0]];
		testKey = testKeys[(j < NUMTIMBRES) ? j : 0];
	}
	[timbreMenu setTarget:self];
	[timbreMenu setAction:@selector(takeWaveformFrom:)];

	return self;
}

- loadNibFile
 /* load the interface for Fm1Instrument. Called by [super init]. */
{
	[NXApp loadNibSection:"Wave1Instrument.nib" owner:self withNames:NO];
	return self;
}

- setDefaults
{
	[super setDefaults];
	/* Variables used to compute variations on the vibrato frequencies */
	svibAmp0 = 0.007;
	svibAmp1 = 0.014;
	rvibAmp = 0.004;
	svibFreq0 = 3.8;
	svibFreq1 = 4.5;
	vibRanPc = 0.15 / MAXRAN;
	vran0 = svibFreq0 * vibRanPc;
	vran1 = svibFreq1 * vibRanPc;
	balance = 0.0;
	modwheel = 0.2;
	[self initAmpEnvelope];
	MKSetNoteParToDouble(updates, MK_svibAmp0, svibAmp0);
	MKSetNoteParToDouble(updates, MK_svibAmp1, svibAmp1);
	MKSetNoteParToDouble(updates, MK_rvibAmp, rvibAmp);
	MKSetNoteParToDouble(updates, MK_svibFreq0, svibFreq0);
	MKSetNoteParToDouble(updates, MK_svibFreq1, svibFreq1);
	MKSetNoteParToString(updates, MK_waveform0, "SA");
	MKSetNoteParToString(updates, MK_waveform1, "SU");
	MKSetNoteParToInt(updates, MK_waveLen, 128);
	MKSetNoteParToEnvelope(updates, MK_ampEnv, ampEnv);
	[self updateController:MIDI_BALANCE toValue:0];
	[self updateController:MIDI_MODWHEEL toValue:(int)(modwheel*127.0+0.5)];
	return self;
}
	
- init
 /* Called automatically when an instance is created. */
{
	[super init];
	[self setSynthPatchClass:[DBWave1vi class]];
	return self;
}

- awakeFromNib
 /* Things that have to be done AFTER the nib section is loaded in */
{
	[super awakeFromNib];
	[self initWaveformButton];
	[[interpField cell] setFloatingPointFormat:NO left:2 right:2];
	[[modwheelField cell] setFloatingPointFormat:NO left:2 right:2];
	[interpField setDoubleValue:balance];
	[interpSlider setDoubleValue:balance];
	[modwheelField setDoubleValue:modwheel];
	[modwheelSlider setDoubleValue:modwheel];
	[vibratoInterface setMode:DOUBLES];
    [vibratoInterface setDoubleValueAt:0 to:svibFreq0];
    [vibratoInterface setDoubleValueAt:1 to:svibFreq1];
    [vibratoInterface setDoubleValueAt:2 to:svibAmp0];
    [vibratoInterface setDoubleValueAt:3 to:svibAmp1];
    [vibratoInterface setDoubleValueAt:4 to:rvibAmp];
	[ampEnvEditor setEnvelope:ampEnv];
	return self;
}

- free
 /* Free the amp envelope as well */
{
	[ampEnv free];
	[vibratoInterface free];
	return [super free];
}

- envelopeModified:sender
{
	[document setEdited];
	return self;
}

- takeVibratoFrom:sender
 /* Adjust vibrato parameters. See DBWave1vi documentation. */
{
	double val = [sender doubleValue];

	switch ([sender selectedIndex]) {
		case 0:
			[self updatePar:MK_svibFreq0 asDouble:svibFreq0 = val];
			vran0 = svibFreq0 * vibRanPc;
			break;
		case 1:
			[self updatePar:MK_svibFreq1 asDouble:svibFreq1 = val];
			vran1 = svibFreq1 * vibRanPc;
			break;
		case 2:
			[self updatePar:MK_svibAmp0 asDouble:svibAmp0 = val];
			break;
		case 3:
			[self updatePar:MK_svibAmp1 asDouble:svibAmp1 = val];
			break;
		case 4:
			[self updatePar:MK_rvibAmp asDouble:rvibAmp = val];
			break;
	}

	[document setEdited];

	return self;
}

- toggleVibrato:sender
 /*
  * Add or remove vibrato information from the update note.  Since this note
  * is used to choose a patch template when patches are loaded, this can
  * affect the number of possible synthpatches (more of the version without
  * the vibrato unit generators can fit on the DSP). 
  */
{
	BOOL isActive = ([NXApp performanceStatus] == MK_active);

	[document setEdited];
	if (isActive)
		[(EnsembleApp *) NXApp pause];
	[Conductor lockPerformance];
	[self abort];
	[self setSynthPatchCount:0];
	if ([sender state]) {
		MKSetNoteParToDouble(updates, MK_svibAmp0, svibAmp0);
		MKSetNoteParToDouble(updates, MK_svibAmp1, svibAmp1);
		MKSetNoteParToDouble(updates, MK_rvibAmp, rvibAmp);
	} else {
		svibAmp0 = [updates parAsDouble:MK_svibAmp0];
		svibAmp1 = [updates parAsDouble:MK_svibAmp1];
		rvibAmp = [updates parAsDouble:MK_rvibAmp];
		MKSetNoteParToDouble(updates, MK_svibAmp0, 0.0);
		MKSetNoteParToDouble(updates, MK_svibAmp1, 0.0);
		MKSetNoteParToDouble(updates, MK_rvibAmp, 0.0);
	}
	[self allocatePatches];
	[Conductor unlockPerformance];
	NXPing();
	[NXApp synchDSPDelayed:.5];
	if (isActive) {
		[Conductor lockPerformance];
		[[Conductor clockConductor] sel:@selector(resume)
		 to :NXApp withDelay:1.0 argCount:0];
		[Conductor unlockPerformance];
	}
	return self;
}

- takeWaveformFrom:sender
 /* Select a wavetable from the timbre database. */
{
	int n;
	char *str;
	int tag;

	tag = ([waveformButton isKindOf:[Matrix class]]) ?
		[[waveformButton selectedCell] tag] : 0;
	if ([sender isKindOf:[Matrix class]])
		sender = [sender selectedCell];
	str = timbreCodes[n = [timbreMenu indexOfItem:[sender title]]];
	if (tag == 0) {
		if (n > 0)
			[self updatePar:MK_waveform0 asString:str];
		else
			[self updatePar:MK_waveform0 asWave:sinePartials];
		testKey = testKeys[n];
	} else {
		if (n > 0)
			[self updatePar:MK_waveform1 asString:str];
		else
			[self updatePar:MK_waveform1 asWave:sinePartials];
	}
	[document setEdited];

	return self;
}

- takeWaveInterpFrom:sender
 /* Degree of interpolation between the two selected wavetables */
{
	balance = [sender doubleValue];

	balance = MAX(MIN(balance,1.0),0);
	[self updateController:MIDI_BALANCE toValue:(int)floor(balance*127.0+.5)];
	[interpField setDoubleValue:balance];
	[document setEdited];

	return self;
}

- takeModwheelFrom:sender
 /*
  * Controls interpolation between svibAmp0 and svibAmp1, and svibFreq0 and
  * svibFreq1. 
  */
{
	modwheel = [sender doubleValue];

	modwheel = MAX(MIN(modwheel,1.0),0);
	[self updateController:MIDI_MODWHEEL toValue:(int)floor(modwheel*127.0+.5)];
	[modwheelField setDoubleValue:modwheel];
	[document setEdited];

	return self;
}

- realizeNote:aNote fromNoteReceiver:aNoteReceiver
 /* Vary slightly the frequency of sine vibrato from note to note */
{
	int noteType = [aNote noteType];

	/* apply a random variation to the sine vibrato */
	if ((noteType == MK_noteOn) || (noteType == MK_noteDur)) {
		MKSetNoteParToDouble(aNote, MK_svibFreq0,
							 svibFreq0 - (double)random() * vran0);
		MKSetNoteParToDouble(aNote, MK_svibFreq1,
							 svibFreq1 + (double)random() * vran1);
	}
	return[super realizeNote:aNote fromNoteReceiver:aNoteReceiver];
}

- write:(NXTypedStream *) stream
 /* Archive the instrument to a typed stream. */
{
	BOOL sine0 = NO, sine1 = NO;

	/*
	 * Don't archive the sinepartials, since we want to share the same one
	 * among all instruments (see below) 
	 */
	if (MKGetNoteParAsWaveTable(updates, MK_waveform0) == sinePartials) {
		sine0 = YES;
		[updates removePar:MK_waveform0];
	}
	if (MKGetNoteParAsWaveTable(updates, MK_waveform1) == sinePartials) {
		sine1 = YES;
		[updates removePar:MK_waveform0];
	}
	[super write:stream];
	NXWriteTypes(stream, "dddddddd@", &svibAmp0, &svibAmp1, &rvibAmp,
				&svibFreq0, &svibFreq1, &vibRanPc,
				&balance, &modwheel, &ampEnv);

	if (sine0)
		MKSetNoteParToWaveTable(updates, MK_waveform0, sinePartials);
	if (sine1)
		MKSetNoteParToWaveTable(updates, MK_waveform1, sinePartials);
	return self;
}

- read:(NXTypedStream *) stream
 /* Unarchive the instrument from a typed stream. */
{
	int version;
	[super read:stream];
	version = NXTypedStreamClassVersion(stream, "Wave1Instrument");
	if (version < 2) {
		id dummy;
		NXReadTypes(stream, "dddddddd@@@@@@@", &svibAmp0, &svibAmp1, &rvibAmp,
				&svibFreq0, &svibFreq1, &vran0, &vran1, &vibRanPc, &ampEnv,
				&interpField, &modwheelField, &waveformButton,
				&dummy, &dummy, &timbreMenu);
	}
	else if (version == 2)
		NXReadTypes(stream, "dddddddd@", &svibAmp0, &svibAmp1, &rvibAmp,
				&svibFreq0, &svibFreq1, &vibRanPc, 
				&balance, &modwheel, &ampEnv);

	return self;
}

- awake
 /* Initialize certain non-archived data */
{
	vran0 = svibFreq0 * vibRanPc;
	vran1 = svibFreq1 * vibRanPc;

	[super awake];
	
	/* If there is no wave parameter, it must have been set to sinewave */
	if (!MKIsNoteParPresent(updates, MK_waveform0) ||
		!strlen(MKGetNoteParAsString(updates, MK_waveform0)))
		MKSetNoteParToWaveTable(updates, MK_waveform0, sinePartials);
	if (!MKIsNoteParPresent(updates, MK_waveform1) ||
		!strlen(MKGetNoteParAsString(updates, MK_waveform1)))
		MKSetNoteParToWaveTable(updates, MK_waveform1, sinePartials);

	return self;
}

/* The following are obsolete - defined for compatability with old archived documents */
- takeAmpEnvFrom:sender {return self;}
- takeAmpSmoothingFrom:sender {return self;}
- takeAmpSustainFrom:sender {return self;}

@end
