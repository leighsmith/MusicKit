/* A SynthInstrument for handling Shapev synthpatches, and adjusting
 * their parameters via a graphic interface.  This object is a subclass
 * of Wave1Instrument, so many of its functions are handled there.
 *
 * This file was created from Fm1Instrument and is very similar to it.
 */

#import "ShapeInstrument.h"
#import <appkit/appkit.h>
#import <musickit/synthpatches/Shapev.h>
#import "EnsembleApp.h"
#import "EnsembleDoc.h"
#import "EnvelopeView.h"
#import "ParamInterface.h"

// extern double pow(double, double);


@implementation ShapeInstrument:Wave1Instrument
{
}

+ initialize
{
	[ShapeInstrument setVersion:1];
	return self;
}

- initIndexEnvelope
 /* Initialize the arrays used to construct the index envelope. 
  * The amp envelope is initialized by the EnsembleSynthIns superclass.
  */
{
	double *indX, *indY;
	int i;
	indX = malloc(sizeof(double) * 4);
	indY = malloc(sizeof(double) * 4);
	indX[0] = 0;
	indX[1] =.0618;
	indX[2] =.1;
	indX[3] =.3;
	indY[0] = 0;
	indY[1] = 1;
	indY[2] =.8;
	indY[3] = 0;
	indEnv = [[Envelope alloc] init];
	[indEnv setPointCount:4 xArray:indX yArray:indY];
	[indEnv setStickPoint:2];
	free(indX);
	free(indY);

	oscAmps[0] = 1.0;
	for (i = 1; i < NCPARTIALS; i++) 
	  oscAmps[i] = 0.0;
	/* Give it some defaults */
	modAmps[0] = 1.0;
	modAmps[1] = .5;
	modAmps[2] = .25;
	modAmps[3] = .125;
	modAmps[4] = .06;
	for (i = 5; i < NWPARTIALS; i++) 
	  modAmps[i] = 0.0;
	[self takeModWaveFrom:self];
	return self;
}

- loadNibFile
 /* load the interface for ShapeInstrument. Called by [super init]. */
{
	[NXApp loadNibSection:"ShapeInstrument.nib" owner:self withNames:NO];
	return self;
}

- setDefaults
 /* Called automatically when an instance is first created. */
{
	[super setDefaults];
	index0 = 0.25;
	index1 = 1.0;
	scalingKey = c4k;
	lastKey = testKey;
	scaling = 0;
	brightness = 1;
	[self initIndexEnvelope];
	MKSetNoteParToString(updates, MK_waveform0, "");
	MKSetNoteParToString(updates, MK_waveform1, "");
	MKSetNoteParToEnvelope(updates, MK_m1IndEnv, indEnv);
	MKSetNoteParToDouble(updates, MK_m1Ind0, index0);
	MKSetNoteParToDouble(updates, MK_m1Ind1, index1);
	MKSetNoteParToInt(updates, MK_waveLen, 256);
	return self;
}

- init
 /* Called automatically when an instance is created. */
{
	[super init];
	[self setSynthPatchClass:[Shapev class]];
	return self;
}

- awakeFromNib
 /* Things that have to be done AFTER the nib section is loaded in */
{
	int i;
	[super awakeFromNib];

	[modulationInterface setPrecision:1];
	[modulationInterface setModeAt:2 to:KEYNUMS];
	[modulationInterface setModeAt:3 to:INTS];
	
	[modulationInterface setDoubleValueAt:0 to:index1];
	[modulationInterface setDoubleValueAt:1 to:index0];
	[modulationInterface setIntValueAt:2 to:scalingKey];
	[modulationInterface setDoubleValueAt:3 to:scaling];

	for (i=0; i<8; i++) {
		[[oscSliders cellAt:0:i] setDoubleValue:oscAmps[i]];
		[[modulatorSliders cellAt:0:i] setDoubleValue:modAmps[i]];
	}
	[indEnvEditor setEnvelope:indEnv];
	return self;
}

- free
 /* Free the amp and index envelopes, and wavetables. */
{
	if (oscSynthData)
		[orchestra dealloc:oscSynthData];
	if (modSynthData)
		[orchestra dealloc:modSynthData];
	/* ampEnv is freed by superclass */
	[indEnv free];
	if (oscWave)
		[oscWave free];
	if (modulatorWave)
		[modulatorWave free];
	if (modulationInterface)
		[modulationInterface free];
	return [super free];
}

- setSynthPatchClass:aSynthPatchClass orchestra:anOrch
 /* Unused now, this will be needed when we move to multiple DSPs */
{
	/* Deallocate the wavetables on the current DSP */
	if (oscSynthData)
		[orchestra dealloc:oscSynthData];
	if (modSynthData)
		[orchestra dealloc:modSynthData];
	oscSynthData = nil;
	modSynthData = nil;

	return [super setSynthPatchClass:aSynthPatchClass orchestra:anOrch];
}

static double indexScaling(ShapeInstrument *self)
{
	/*
	 * Scaling = how many dB per octave to increase or decrease the
	 * modulation, with reference to scalingKey. 
	 */
	return pow(10.0, (((self->scalingKey - self->lastKey) / 12.0)
					  * self->scaling) / 20.0);
}

- takeModParamsFrom:sender
{
	switch ([sender selectedIndex]) {
		case 1:
			index0 = [sender doubleValue];
			[self updatePar:MK_m1Ind0 asDouble:index0 * indexScaling(self)];
			break;
		case 0:
			index1 = [sender doubleValue];
			[self updatePar:MK_m1Ind1 asDouble:index1 * indexScaling(self)];
			break;
		case 2:
			scalingKey = [sender intValue];
			break;
		case 3:
			scaling = [sender doubleValue];
			[self updatePar:MK_m1Ind0 asDouble:index0 * indexScaling(self)];
			[self updatePar:MK_m1Ind1 asDouble:index1 * indexScaling(self)];
			break;
	}

	[document setEdited];

	return self;
}

- setOscWave
 /*
  * Set the osc wavetable by directly computing a synthData and sending it
  * to the synthpatch. 
  */
{
	if (oscWave) {
		if (!oscSynthData)
			oscSynthData = [orchestra allocSynthData:MK_yData length:256];
		[oscSynthData setData:[oscWave dataDSPLength:256]
		 length:256 offset:0];
		[self updatePar:MK_waveform asWave:oscSynthData];
	}
	return self;
}

- setModulatorWave
 /*
  * Set the modulator wavetable by directly computing a synthData and sending
  * it to the synthpatch. 
  */
{
	if (modulatorWave) {
		if (!modSynthData)
			modSynthData = [orchestra allocSynthData:MK_yData length:256];
		[modSynthData setData:[modulatorWave dataDSPAsWaveshapingTableLength:256]
		 length:256 offset:0];
		[self updatePar:MK_m1Waveform asWave:modSynthData];
	}
	return self;
}

- takeOscWaveFrom:sender
 /*
  * Adjust the amplitude of the components of the osc wavetable. Recompute
  * the SynthData and send it to the synthpatches. 
  */
{
	static double amps[NCPARTIALS];
	static double freqs[NCPARTIALS];
	register int i, n = 0;
	id cell = [sender selectedCell];

	if (!cell)
		return self;
	oscAmps[[cell tag]] = [cell doubleValue];
	/* Optimize computation of wavetable by omitting 0 amplitude components */
	for (i = 0; i < NCPARTIALS; i++)
		if (oscAmps[i] > 0.0) {
			amps[n] = oscAmps[i];
			freqs[n] = (double)(i + 1);
			n++;
		}
	if (n) {
		[Conductor lockPerformance];
		if (!oscWave)
			oscWave = [[Partials alloc] init];
		[oscWave setPartialCount:n freqRatios:freqs ampRatios:amps
		 phases:NULL orDefaultPhase:0];
		[self setOscWave];
		[Conductor unlockPerformance];
	}
	[document setEdited];

	return self;
}

- takeModWaveFrom:sender
 /*
  * Adjust the amplitude of the components of the modulator wavetable.
  * Recompute the SynthData and send it to the synthpatches. 
  */
{
	static double amps[NWPARTIALS];
	static double freqs[NWPARTIALS];
	int i, n = 0;
	id cell;

	if (sender != self) {
	        cell = [sender selectedCell];
		if (!cell)
			return self;
		modAmps[[cell tag]] = [cell doubleValue];
	}
	/* Since we need to fill freqs[] anyway, we might as well omit 
	 * zero amplitudes while we're at it. 
	 */
	for (i = 0; i < NWPARTIALS; i++)
		if (modAmps[i] > 0.0) {
			amps[n] = modAmps[i];
			freqs[n] = (double)(i + 1);
			n++;
		}
	if (n) {
		[Conductor lockPerformance];
		if (!modulatorWave)
			modulatorWave = [[Partials alloc] init];
		[modulatorWave setPartialCount:n freqRatios:freqs ampRatios:amps
		 phases:NULL orDefaultPhase:0];
		[self setModulatorWave];
		[Conductor unlockPerformance];
	}
	if (sender != self)
		[document setEdited];

	return self;
}

- getUpdates:(Note **) aNoteUpdate controllerValues:(HashTable **) controllers
 /*
  * We cannot write to the score file the SynthDatas we may be using for the
  * wavetable parameter, so substitute the WaveTable objects. 
  */
{
	if (oscWave)
		MKSetNoteParToWaveTable(updates, MK_waveform, oscWave);
	if (modulatorWave)
		MKSetNoteParToWaveTable(updates, MK_m1Waveform, modulatorWave);
	return[super getUpdates:aNoteUpdate controllerValues:controllers];
}

- (int)setSynthPatchCount:(int)voices
 /*
  * We override setSynthPatchCount in order to synchronize loading and
  * unloading of the wavetables. 
  */
{
	int n;

	[Conductor lockPerformance];
	if (oscSynthData) {
		[orchestra dealloc:oscSynthData];
		oscSynthData = nil;
	}
	if (modSynthData) {
		[orchestra dealloc:modSynthData];
		modSynthData = nil;
	}
	if (n = [super setSynthPatchCount:voices]) {
		[self setOscWave];
		[self setModulatorWave];
	}
	[Conductor unlockPerformance];

	return n;
}

- realizeNote:aNote fromNoteReceiver:aNoteReceiver
 /* Adjust the modulation index of each note according to its frequency */
{
	double scaler, ind0 = MK_NODVAL, ind1 = MK_NODVAL;
	MKNoteType type = [aNote noteType];
	if ((scaling > 0.0) && ((type == MK_noteOn) || (type == MK_noteDur))) {
		if (MKIsNoteParPresent(aNote, MK_m1Ind0))
			ind0 = MKGetNoteParAsDouble(aNote, MK_m1Ind0);
		if (MKIsNoteParPresent(aNote, MK_m1Ind1))
			ind1 = MKGetNoteParAsDouble(aNote, MK_m1Ind1);
		lastKey = [aNote keyNum];
		scaler = indexScaling(self);
		MKSetNoteParToDouble(aNote, MK_m1Ind0, index0 * scaler);
		MKSetNoteParToDouble(aNote, MK_m1Ind1, index1 * scaler);
	}
	[super realizeNote:aNote fromNoteReceiver:aNoteReceiver];
	if (!MKIsNoDVal(ind0))
		MKSetNoteParToDouble(aNote, MK_m1Ind0, ind0);
	if (!MKIsNoDVal(ind1))
		MKSetNoteParToDouble(aNote, MK_m1Ind1, ind1);

	return self;
}

- write:(NXTypedStream *) stream
 /* Archive the instrument to a typed stream. */
{
	int npc = NCPARTIALS, npw = NWPARTIALS;

	/*
	 * Can't archive a SynthData, so flush them from the update note. They
	 * will be reset by setSynthPatchCount: after archiving is done. 
	 */
	[updates removePar:MK_waveform];
	[updates removePar:MK_m1Waveform];
	[super write:stream];
	NXWriteTypes(stream, "dddii@@@ii",
				 &index0, &index1, &scaling, &lastKey,
				 &scalingKey, &indEnv, &oscWave, &modulatorWave, &npc, &npw);
	NXWriteArray(stream, "d", npc, oscAmps);
	NXWriteArray(stream, "d", npw, modAmps);

	return self;
}

- read:(NXTypedStream *) stream
 /* Unarchive the instrument from a typed stream. */
{
	int npc,npw;
	int version;
	[super read:stream];
	version = NXTypedStreamClassVersion(stream, "ShapeInstrument");
	if (version == 1)
		NXReadTypes(stream, "dddii@@@ii",
				 &index0, &index1, &scaling, &lastKey,
				 &scalingKey, &indEnv, &oscWave, &modulatorWave, &npc,&npw);
	NXReadArray(stream, "d", npc, oscAmps);
	NXReadArray(stream, "d", npw, modAmps);

	return self;
}

- awake
 /* Initialize certain non-archived data */
{
	[super awake];

	[self setOscWave];
	[self setModulatorWave];

	return self;
}

@end
