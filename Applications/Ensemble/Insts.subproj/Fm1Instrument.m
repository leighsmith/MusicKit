/* An SynthInstrument for handling Fm1vi synthpatches, and adjusting
 * their parameters via a graphic interface.  This object is a subclass
 * of Wave1Instrument, so many of its functions are handled there.
 */

#import "Fm1Instrument.h"
#import <appkit/appkit.h>
#import <musickit/synthpatches/DBFm1vi.h>
#import "EnsembleApp.h"
#import "EnsembleDoc.h"
#import "EnvelopeView.h"
#import "ParamInterface.h"

// extern double pow(double, double);


@implementation Fm1Instrument:Wave1Instrument
{
}

+ initialize
{
	[Fm1Instrument setVersion:2];
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

	carAmps[0] = 1.0;
	modAmps[0] = 1.0;
	for (i = 1; i < NPARTIALS; i++) {
		carAmps[i] = 0.0;
		modAmps[i] = 0.0;
	}

	return self;
}

- loadNibFile
 /* load the interface for Fm1Instrument. Called by [super init]. */
{
	[NXApp loadNibSection:"Fm1Instrument.nib" owner:self withNames:NO];
	return self;
}

- setDefaults
 /* Called automatically when an instance is first created. */
{
	[super setDefaults];
	index0 = 0.0;
	index1 = 2.0;
	cRatio = 1.0;
	mRatio = 1.0;
	scalingKey = c4k;
	lastKey = testKey;
	scaling = 2.0;
	brightness = 1.0;
	[self initIndexEnvelope];
	MKSetNoteParToString(updates, MK_waveform0, "");
	MKSetNoteParToString(updates, MK_waveform1, "");
	MKSetNoteParToEnvelope(updates, MK_m1IndEnv, indEnv);
	MKSetNoteParToDouble(updates, MK_m1Ind0, index0);
	MKSetNoteParToDouble(updates, MK_m1Ind1, index1);
	MKSetNoteParToDouble(updates, MK_cRatio, cRatio);
	MKSetNoteParToDouble(updates, MK_m1Ratio, mRatio);
	MKSetNoteParToInt(updates, MK_waveLen, 256);
	return self;
}

- init
 /* Called automatically when an instance is created. */
{
	[super init];
	[self setSynthPatchClass:[Fm1vi class]];
	return self;
}

- awakeFromNib
 /* Things that have to be done AFTER the nib section is loaded in */
{
	int i;
	[super awakeFromNib];

	[modulationInterface setPrecision:1];
	[modulationInterface setModeAt:4 to:KEYNUMS];
	[modulationInterface setModeAt:5 to:INTS];
	
	[modulationInterface setDoubleValueAt:0 to:index1];
	[modulationInterface setDoubleValueAt:1 to:index0];
	[modulationInterface setDoubleValueAt:2 to:cRatio];
	[modulationInterface setDoubleValueAt:3 to:mRatio];
	[modulationInterface setIntValueAt:4 to:scalingKey];
	[modulationInterface setDoubleValueAt:5 to:scaling];

	for (i=0; i<8; i++) {
		[[carrierSliders cellAt:0:i] setDoubleValue:carAmps[i]];
		[[modulatorSliders cellAt:0:i] setDoubleValue:modAmps[i]];
	}
	[indEnvEditor setEnvelope:indEnv];
	return self;
}

- free
 /* Free the amp and index envelopes, and wavetables. */
{
	if (carSynthData)
		[orchestra dealloc:carSynthData];
	if (modSynthData)
		[orchestra dealloc:modSynthData];
	/* ampEnv is freed by superclass */
	[indEnv free];
	if (carrierWave)
		[carrierWave free];
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
	if (carSynthData)
		[orchestra dealloc:carSynthData];
	if (modSynthData)
		[orchestra dealloc:modSynthData];
	carSynthData = nil;
	modSynthData = nil;

	return [super setSynthPatchClass:aSynthPatchClass orchestra:anOrch];
}

static double indexScaling(Fm1Instrument * self)
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
			cRatio = [sender doubleValue];
			[self updatePar:MK_cRatio asDouble:cRatio];
			break;
		case 3:
			mRatio = [sender doubleValue];
			[self updatePar:MK_m1Ratio asDouble:mRatio];
			break;
		case 4:
			scalingKey = [sender intValue];
			break;
		case 5:
			scaling = [sender doubleValue];
			[self updatePar:MK_m1Ind0 asDouble:index0 * indexScaling(self)];
			[self updatePar:MK_m1Ind1 asDouble:index1 * indexScaling(self)];
			break;
	}

	[document setEdited];

	return self;
}

- setCarrierWave
 /*
  * Set the carrier wavetable by directly computing a synthData and sending it
  * to the synthpatch. 
  */
{
	if (carrierWave) {
		if (!carSynthData)
			carSynthData = [orchestra allocSynthData:MK_yData length:256];
		[carSynthData setData:[carrierWave dataDSPLength:256]
		 length:256 offset:0];
		[self updatePar:MK_waveform asWave:carSynthData];
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
		[modSynthData setData:[modulatorWave dataDSPLength:256]
		 length:256 offset:0];
		[self updatePar:MK_m1Waveform asWave:modSynthData];
	}
	return self;
}

- takeCarWaveFrom:sender
 /*
  * Adjust the amplitude of the components of the carrier wavetable. Recompute
  * the SynthData and send it to the synthpatches. 
  */
{
	static double amps[NPARTIALS];
	static double freqs[NPARTIALS];
	register int i, n = 0;
	id cell = [sender selectedCell];

	if (!cell)
		return self;
	carAmps[[cell tag]] = [cell doubleValue];
	/* Optimize computation of wavetable by omitting 0 amplitude components */
	for (i = 0; i < NPARTIALS; i++)
		if (carAmps[i] > 0.0) {
			amps[n] = carAmps[i];
			freqs[n] = (double)(i + 1);
			n++;
		}
	if (n) {
		[Conductor lockPerformance];
		if (!carrierWave)
			carrierWave = [[Partials alloc] init];
		[carrierWave setPartialCount:n freqRatios:freqs ampRatios:amps
		 phases:NULL orDefaultPhase:0];
		[self setCarrierWave];
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
	static double amps[NPARTIALS];
	static double freqs[NPARTIALS];
	int i, n = 0;
	id cell = [sender selectedCell];

	if (!cell)
		return self;
	modAmps[[cell tag]] = [cell doubleValue];
	/* Optimize computation of wavetable by omitting 0 amplitude components */
	for (i = 0; i < NPARTIALS; i++)
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
	[document setEdited];

	return self;
}

- getUpdates:(Note **) aNoteUpdate controllerValues:(HashTable **) controllers
 /*
  * We cannot write to the score file the SynthDatas we may be using for the
  * wavetable parameter, so substitute the WaveTable objects. 
  */
{
	if (carrierWave)
		MKSetNoteParToWaveTable(updates, MK_waveform, carrierWave);
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
	if (carSynthData) {
		[orchestra dealloc:carSynthData];
		carSynthData = nil;
	}
	if (modSynthData) {
		[orchestra dealloc:modSynthData];
		modSynthData = nil;
	}
	if (n = [super setSynthPatchCount:voices]) {
		[self setCarrierWave];
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
	int np = NPARTIALS;

	/*
	 * Can't archive a SynthData, so flush them from the update note. They
	 * will be reset by setSynthPatchCount: after archiving is done. 
	 */
	[updates removePar:MK_waveform];
	[updates removePar:MK_m1Waveform];
	[super write:stream];
	NXWriteTypes(stream, "dddddii@@@i",
				 &cRatio, &mRatio, &index0, &index1, &scaling, &lastKey,
				 &scalingKey, &indEnv, &carrierWave, &modulatorWave, &np);
	NXWriteArray(stream, "d", np, carAmps);
	NXWriteArray(stream, "d", np, modAmps);

	return self;
}

- read:(NXTypedStream *) stream
 /* Unarchive the instrument from a typed stream. */
{
	int np;
	int version;
	[super read:stream];
	version = NXTypedStreamClassVersion(stream, "Fm1Instrument");
	if (version < 2) {
		id dummy; double crFine, mrFine;
		NXReadTypes(stream, "dddddddii@@@@@@@@i",
				&cRatio, &crFine, &mRatio, &mrFine,
				&index0, &index1, &scaling, &lastKey, &scalingKey,
				&indEnv, &carrierWave, &modulatorWave,
				&dummy, &dummy, &dummy,
				&brightField, &dummy, &np);
		mRatio += mrFine;
		cRatio += crFine;
	}
	else if (version == 2)
		NXReadTypes(stream, "dddddii@@@i",
				 &cRatio, &mRatio, &index0, &index1, &scaling, &lastKey,
				 &scalingKey, &indEnv, &carrierWave, &modulatorWave, &np);
	NXReadArray(stream, "d", np, carAmps);
	NXReadArray(stream, "d", np, modAmps);

	return self;
}

- awake
 /* Initialize certain non-archived data */
{
	[super awake];

	[self setCarrierWave];
	[self setModulatorWave];

	return self;
}

/* Obsolete - defined for compatability with old archived documents */
- takeIndScalingFrom:sender {return self;}
- takeIndEnvFrom:sender {return self;}
- takeIndSustainFrom:sender {return self;}
- takeIndSmoothingFrom:sender {return self;}
- takeIndexFrom:sender {return self;}
- takeRatioFrom:sender {return self;}
- takeBrightFrom:sender {return self;}

@end
