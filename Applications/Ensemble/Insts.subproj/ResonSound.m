/* Copyright CCRMA, 1992.  All rights reserved. */
/* This example does real-time resonating of the DSP serial port (SSI) input stream.  
   Since the SynthPatch is instantiable, many versions of the sound 
   can be mixed/resonated at the same time. 
  
   The algorithm implemented by this SynthPatch is as follows:
  
   out[i] = (sound[i] * envelope[i] + delay[i-N] * feedbackGain)
  
*/

#import <musickit/musickit.h>
#import <musickit/unitgenerators/unitgenerators.h>
#import "ResonSound.h"
#import <appkit/nextstd.h>
#import <mididriver/midi_spec.h>

@implementation ResonSound

/* Indicies into List of UnitGenerators and Patchpoints. This List is the 
   instance variable 'synthElements'. */

static int soundReader, xPP, yPP, envelope, stereoOut, envScale, delayPP, delay,
	constPP, envInAdd, onepole;

#define SE NX_ADDRESS(synthElements)	/* Make synth element access easy */

static int chanPar, gainPar;

+ initialize
{
	chanPar = [Note parTagForName:"SoundInputChan"];
	gainPar = [Note parTagForName:"SoundInputGain"];
	return self;
}

+ patchTemplateFor:aNote
{
	/*
	 * Create the PatchTemplate if it doesn't exist. This is the specification
	 * of how to make a new SynthPatch of this kind 
	 */
	static id theATemplate = nil, theBTemplate = nil;
	id theTemplate;
	BOOL isA = YES;

	if ([aNote isParPresent:chanPar]) {
		int chan = [aNote parAsInt:chanPar];

		if (chan == 1)
			isA = NO;
	}

	if (isA) {
		if (theATemplate)
			return theATemplate;
		else
			theATemplate = theTemplate = [PatchTemplate new];
	} else {
		if (theBTemplate)
			return theBTemplate;
		else
			theBTemplate = theTemplate = [PatchTemplate new];
	}

	/* Two reusable patchpoints and two dedicated patchpoints. */
	xPP = [theTemplate addPatchpoint:MK_xPatch];
	yPP = [theTemplate addPatchpoint:MK_yPatch];
	constPP = [theTemplate addPatchpoint:MK_xPatch];
	delayPP = [theTemplate addPatchpoint:MK_yPatch];

	/* Add UnitGenerator allocation specifications */
	if (isA)
		soundReader = [theTemplate addUnitGenerator:[In1aUGx class]];
	else
		soundReader = [theTemplate addUnitGenerator:[In1bUGx class]];

	envInAdd = [theTemplate addUnitGenerator:[Mul1add2UGyxyx class]];
	onepole = [theTemplate addUnitGenerator:[OnepoleUGyy class]];
	envelope = [theTemplate addUnitGenerator:[AsympUGx class]];
	envScale = [theTemplate addUnitGenerator:[Mul2UGxyx class]];
	stereoOut = [theTemplate addUnitGenerator:[Out2sumUGx class]];
	delay = [theTemplate addUnitGenerator:[DelayUGyyx class]];

	return theTemplate;
}

- _setDefaults
 /* A local method that resets instance vars and idles output. */
{
	bearing = 0;
	amp1 = MK_DEFAULTAMP;
	feedbackGain = 0.8;
	brightness = .75;
	ampAtt = MK_NODVAL;
	ampRel = MK_NODVAL;
	/* MIDI parameters */
	velocity = MK_DEFAULTVELOCITY;
	volume = MIDI_MAXDATA;
	pitchbend = MIDI_ZEROBEND;
	modwheel = MIDI_MAXDATA;
	aftertouch = 0.0;
	inputGain = 1.0;
    velocitySensitivity = 0.0;
    pitchbendSensitivity = 0.0;
    modwheelSensitivity = 0.0;
    aftertouchSensitivity = 0.0;
	[SE[stereoOut] idle];
	[SE[constPP] setToConstant:DSPDoubleToFix24(feedbackGain)];
	return self;
}

- init
	/* Connect UnitGenerators and PatchPoints */
{

	[SE[envInAdd] setInput1:SE[xPP]];		/* Add new sound to scaled delayed sound */
	[SE[envInAdd] setInput2:SE[delayPP]];
	[SE[envInAdd] setInput3:SE[constPP]];
	[SE[envInAdd] setOutput:SE[delayPP]];

	[SE[delay] setInput:SE[delayPP]];		/* Delay the resulting mix */
	[SE[delay] setOutput:SE[delayPP]];

	[SE[onepole] setInput:SE[delayPP]];		/* Filter the delayed sound */
	[SE[onepole] setOutput:SE[yPP]];

	[SE[envelope] setOutput:SE[xPP]];		/* Generate an amplitude envelope */

	[SE[envScale] setInput1:SE[yPP]];		/* Multiply envelope times filtered sound */
	[SE[envScale] setInput2:SE[xPP]];
	[SE[envScale] setOutput:SE[xPP]];

	[SE[soundReader] setOutput:SE[xPP]];	/* Bring sound in from SSI port */
	return self;
}

- controllerValues:controllers
  /* Sent when a new phrase starts. controllers is a HashTable containing
   * key/value pairs as controller-number/controller-value. */
{
#   define CONTROLPRESENT(_key) [controllers isKey:(const void *)_key]
#   define GETVALUE(_key) (int)[controllers valueForKey:(const void *)_key]
    if (CONTROLPRESENT(MIDI_MAINVOLUME))
      volume = GETVALUE(MIDI_MAINVOLUME);
    if (CONTROLPRESENT(MIDI_MODWHEEL))
      aftertouch = GETVALUE(MIDI_MODWHEEL);
    return self;
}

- _updateParameters:aNote
 /*
  * Updates the SynthPatch according to the information in the note and the
  * note's relationship to a possible ongoing phrase. 
  */
{
	BOOL setWaveform, setOutput, setAmpEnv, setFreq, setBrightness, setInputGain,
		setFeedback, isNewPhrase;
	MKPhraseStatus phraseStatus = [self phraseStatus];
	void *state;				/* For parameter iteration below */
	int par;

	/* Initialize booleans based on phrase status -------------------------- */
	switch (phraseStatus) {
		case MK_phraseOn:				/* New phrase. */
		case MK_phraseOnPreempt:		/* New phrase but using preempted patch. */
			isNewPhrase = setWaveform = setOutput = 
				setAmpEnv = setFreq = setInputGain =
			    setBrightness = setFeedback = YES; /* Set all at new phrase */
			break;
		case MK_phraseRearticulate:		/* NoteOn rearticulation within phrase. */
			isNewPhrase = setWaveform = setOutput = setBrightness = setFreq =
				setInputGain = setFeedback = NO;
			setAmpEnv = YES;	/* Just restart envelopes */
			break;
		case MK_phraseUpdate:			/* NoteUpdate to running phrase. */
		case MK_phraseOff:				/* NoteOff to running phrase. */
		case MK_phraseOffUpdate:		/* NoteUpdate to finishing phrase. */
		default:
			isNewPhrase = setWaveform = setOutput = setAmpEnv = setInputGain =
				setBrightness = setFeedback = setFreq = NO;	/* Only set what's in Note */
			break;
	}

	/* Since this SynthPatch supports so many parameters, it would be
	 * inefficient to check each one with Note's -isParPresent: method.
	 * Instead, we iterate over the parameters in aNote. 
	 */

	state = MKInitParameterIteration(aNote);
	while (par = MKNextParameter(aNote, state)) {
		if (par == gainPar) {
			inputGain = MKGetNoteParAsDouble(aNote, gainPar);
			setInputGain = YES;
			continue;
		}
		switch (par) {			/* Parameters in (roughly) alphabetical order. */
			case MK_afterTouch:
				aftertouch = MKGetNoteParAsInt(aNote, MK_afterTouch);
				setBrightness = YES;
			case MK_afterTouchSensitivity:
				aftertouchSensitivity =
					MKGetNoteParAsDouble(aNote, MK_afterTouchSensitivity);
				setBrightness = YES;
				break;
			case MK_ampEnv:
				ampEnv = MKGetNoteParAsEnvelope(aNote, MK_ampEnv);
				setAmpEnv = YES;
				break;
			case MK_ampAtt:
				ampAtt = MKGetNoteParAsDouble(aNote, MK_ampAtt);
				setAmpEnv = YES;
				break;
			case MK_ampRel:
				ampRel = MKGetNoteParAsDouble(aNote, MK_ampRel);
				setAmpEnv = YES;
				break;
			case MK_amp0:
				amp0 = MKGetNoteParAsDouble(aNote, MK_amp0);
				setAmpEnv = YES;
				break;
			case MK_amp1:		/* MK_amp is synonym */
				amp1 = MKGetNoteParAsDouble(aNote, MK_amp1);
				setAmpEnv = YES;
				break;
			case MK_bearing:
				bearing = MKGetNoteParAsDouble(aNote, MK_bearing);
				setOutput = YES;
				break;
			case MK_bright:
				brightness = MKGetNoteParAsDouble(aNote, MK_bright);
				setBrightness = YES;
				break;
			case MK_controlChange:{
					int controller = MKGetNoteParAsInt(aNote, MK_controlChange);
					if (controller == MIDI_MAINVOLUME) {
						int oldVolume = volume;
						volume = MKGetNoteParAsInt(aNote, MK_controlVal);
						setOutput = (volume != oldVolume);
					} else if (controller == MIDI_MODWHEEL) {
						modwheel = MKGetNoteParAsInt(aNote, MK_controlVal);
						setFeedback = YES;
					}
					break;
				}
			case MK_feedback:
				feedbackGain = [aNote parAsDouble:MK_feedback];
				setFeedback = YES;
				break;
			case MK_freq:
			case MK_freq0:
			case MK_keyNum:
				freq = [aNote freq];
				setFreq = YES;
				break;
			case MK_modWheelSensitivity:
				modwheelSensitivity =
					MKGetNoteParAsDouble(aNote, MK_modWheelSensitivity);
				setFeedback = YES;
				break;
			case MK_pitchBendSensitivity:
				pitchbendSensitivity =
					MKGetNoteParAsDouble(aNote, MK_pitchBendSensitivity);
				setFreq = YES;
				break;
			case MK_pitchBend:
				pitchbend = MKGetNoteParAsInt(aNote, MK_pitchBend);
				setFreq = YES;
				break;
			case MK_velocity:
				velocity = MKGetNoteParAsDouble(aNote, MK_velocity);
				setAmpEnv = YES;
				break;
			case MK_velocitySensitivity:
				velocitySensitivity =
					MKGetNoteParAsDouble(aNote, MK_velocitySensitivity);
				setAmpEnv = YES;
				break;
			default:			/* Skip unrecognized parameters */
				break;
		} /* End of parameter loop. */
	}

	/* ------------------------------ Frequency ------------------------ */

	if (setFreq) {
		/* Crude tuning of resonator.  This tuning is quantized to the delay
		 * length.  To see how to do fine tuning, see the code to Pluck in the
		 * MusicKitSource package or read the paper "Extensions of the Karplus
		 * Strong Algorithm" by Jaffe & Smith (Computer Music Journal, 1983) 
		 */
#define PIPE 16					/* One tick of delay is implicit */
		double fr;
		int delayLen;
		BOOL newMem = NO;
		if (pitchbendSensitivity)
			fr = MKAdjustFreqWithPitchBend(freq, pitchbend, pitchbendSensitivity);
		else fr = freq;
		delayLen = [orchestra samplingRate] / fr - PIPE;
		if (delayLen <= 0)
			return nil;
		if (!delayMem || ([delayMem length] != delayLen)) {
			[delayMem free];
			delayMem = [[self orchestra] allocSynthData:MK_yData length:delayLen];
			if (!delayMem) {
				fprintf(stderr, "Can't allocate memory.\n");
				return nil;
			}
			newMem = YES;
		}
		if (isNewPhrase) {
			[delayMem clear];
			[SE[delayPP] clear];	/* Clear pipe */
		}
		if (newMem) [SE[delay] setDelayMemory:delayMem];
	}

	/* ------------------------------ Brightness ------------------------ */

	if (setFreq || setBrightness) {
		double br = brightness;
		if (aftertouchSensitivity)
			br*=MKMidiToAmpAttenuationWithSensitivity(aftertouch,aftertouchSensitivity);
		[SE[onepole] setBrightness:br forFreq:freq];
	}

	/* ------------------------------ Feedback Gain ------------------------ */

	if (setFeedback) {
		double gain = feedbackGain;
		if (modwheelSensitivity)
			gain *= MKMidiToAmpAttenuationWithSensitivity(modwheel,modwheelSensitivity);
		[SE[constPP] setToConstant:DSPDoubleToFix24(gain)];
	}
	
	/* ------------------------------ Input Scale ------------------------ */

	if (setInputGain)
		[SE[soundReader] setScale:inputGain];

	/* ------------------------------ Envelopes ------------------------ */

	if (setAmpEnv)
		MKUpdateAsymp(SE[envelope], ampEnv, amp0,
					  amp1*MKMidiToAmpWithSensitivity(velocity, velocitySensitivity),
					  ampAtt, ampRel, MK_NODVAL, phraseStatus);

	/* ------------------- Bearing, volume and after touch -------------- */
	if (setOutput)
		[SE[stereoOut] setBearing :bearing scale:MKMidiToAmpAttenuation(volume)];

	return self;
}

- noteOnSelf:aNote
{
	if (![self _updateParameters:aNote])
		return nil;
	[synthElements makeObjectsPerform:@selector(run)];
	[SE[stereoOut] setInput:SE[xPP]];
	return self;
}

- noteUpdateSelf:aNote
 /* We support parameter changing in NoteUpdates. */
{
	return[self _updateParameters:aNote];
}

- (double)noteOffSelf:aNote
{
	if (![self _updateParameters:aNote]) {
		[SE[envelope] abortEnvelope];
		return 0;
	}
	return [SE[envelope] finish];
}

- noteEndSelf
 /* This resets the patch at the end of a phrase */
{
	[self _setDefaults];
	[delayMem free];
	delayMem = nil;
	[SE[delay] setDelayMemory:nil];
	return self;
}

- preemptFor:aNote
 /* This resets the patch when a preemption occurs. */
{
	[SE[envelope] preemptEnvelope];
	[SE[delay] setDelayMemory:nil];
	[self _setDefaults];
	return self;
}

@end
