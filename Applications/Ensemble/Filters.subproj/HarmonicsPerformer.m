/* A performer which generates dynamically-changing harmonics */

#import <musickit/musickit.h>
// #import <appkit/appkit.h>
#import <mididriver/midi_spec.h>
#import "WmFractal.h"
#import "HarmonicsPerformer.h"

@implementation HarmonicsPerformer
{
}

+ initialize
{
	[HarmonicsPerformer setVersion:3];
	return self;
}

- init
 /* Called automatically when an instance is created. */
{
	int i;
	id note;

	[super init];

	noteSender = [self addNoteSender:[[NoteSender alloc] init]];
	interval = 0.2;
	noteDuration = 1.0;
	amp =.125;
	velocityAmp = -1;
	freq = 440.0;
	firstHarm = 1.0;
	numHarms = 8.0;
	harmScale = 1.0;
	intervalScale = 1.0;
	durationScale = 1.0;
	spectralPower = 1.0;
	useFractal = NO;
	conductor = [Conductor defaultConductor];
	bendSensitivity = 0.0;
	for (i = 0; i < NUMHARMS; i++) {
		tags[i] = MKNoteTag();
		note = [[Note alloc] init];
		[note setNoteType:MK_noteOff];
		[note setNoteTag:tags[i]];
		noteOffs[i] = note;
	}
	numTags = NUMHARMS;

	return self;
}

- free
{
	int i;

	[self deactivate];
	for (i = 0; i < NUMHARMS; i++)
		[noteOffs[i] free];

	if (fractal) [fractal free];
	return [super free];
}

- setFreq:(float)aFreq
{
	freq = aFreq;
	return self;
}

- setVelocity:(int)aVelocity
{
	velocityAmp = MKMidiToAmp(aVelocity);
	return self;
}

- setAmp:(float)anAmp
{
	amp = anAmp;
	return self;
}

- setIntervalScale:(float)aScaler
{
	intervalScale = aScaler;
	return self;
}

- setDurationScale:(float)aScaler
{
	durationScale = aScaler;
	return self;
}

- setHarmonicsScale:(float)aScaler
{
	harmScale = aScaler;
	return self;
}

- setInterval:(double)anInterval
{
	interval = anInterval;
	return self;
}

- setDuration:(double)aDuration
{
	noteDuration = aDuration;
	return self;
}

- setFirstHarmonic:(float)firstHarmonic
{
	firstHarm = firstHarmonic;
	return self;
}

- setNumHarmonics:(int)numHarmonics
{
	numHarms = numHarmonics;
	return self;
}

- setSpectralPower:(float)power
{
	spectralPower = power;
	return self;
}

- setBendSensitivity:(int)bend
{
	bendSensitivity = bend;
	return self;
}

- setNoRepeats:(BOOL)state
{
	noRepeats = state;
	return self;
}

- setUseFractal:(BOOL)state
{
	useFractal = state;
	if (useFractal && !fractal)
		fractal = [[WmFractal allocFromZone:[self zone]] init];
	return self;
}

- inspectFractal:sender
{
	[fractal show:sender];
	return self;
}

- setNumTags:(int)num
{
	numTags = num;
	return self;
}

- (int)numTags
{
	return numTags;
}

- (double)interval
{
	return interval;
}

- (double)noteDuration
{
	return noteDuration;
}

- (float)firstHarmonic
{
	return firstHarm;
}

- (int)numHarmonics
{
	return numHarms;
}

- (float)spectralPower
{
	return spectralPower;
}

- (int)bendSensitivity
{
	return bendSensitivity;
}

- (BOOL)noRepeats
{
	return noRepeats;
}

- (BOOL)usingFractal
{
	return useFractal;
}

- activateSelf
{
	startTime = 0;
	return self;
}

- deactivateSelf
{
	int i;

	for (i = 0; i < numHarms; i++)
		[noteSender sendNote:noteOffs[i]];

	return self;
}

- reset
{
	startTime = 0;
	tagIndex = 0;
	return self;
}

extern long random();

#define MAXRAN 2147483647.0
#define NRAN (MIN(1.0,(float)random()/MAXRAN))

- perform
{
	int harmonic;
	id note;
	float harmFreq, n;

	nextPerform = interval * intervalScale;

	n = floor((numHarms-.001) * harmScale);

	if (n == 0)	return self;

	note = [[Note alloc] init];
	[note setNoteType:MK_noteOn];
	if (useFractal) {
		float tmp = (float)[conductor time] - startTime;
		do {
			harmonic = firstHarm + (int)floor(n * [fractal generate:tmp]);
			tmp += nextPerform;
		}
		while ((n > 1.0) && noRepeats && (lastHarm == harmonic));
	} else {
		do
			harmonic = firstHarm + (int)floor(n * NRAN);
		while ((n > 1.0) && noRepeats && (lastHarm == harmonic));
	}
	lastHarm = harmonic;
	if (numTags==NUMHARMS)
		[note setNoteTag:tags[harmonic]];
	else {
		[note setNoteTag:tags[tagIndex++]];
		if (tagIndex == numTags) tagIndex = 0;
	}
	if (harmonic > 0)
		harmFreq = freq * (float)harmonic;
	else
		harmFreq = freq * pow(2.0, harmonic-1);
	if (bendSensitivity == 0)
		MKSetNoteParToDouble(note, MK_freq, harmFreq);
	else {
		int bend;

		MKSetNoteParToInt(note, MK_keyNum,
						  MKFreqToKeyNum(harmFreq, &bend, bendSensitivity));
		if ((bendSensitivity > 0.0))
			MKSetNoteParToInt(note, MK_pitchBend, bend);
	}
	if (velocityAmp >= 0.0)
		MKSetNoteParToInt(note, MK_velocity,
						  MKAmpToMidi(velocityAmp /
									  pow(harmonic, spectralPower)));
	else
		MKSetNoteParToDouble(note, MK_amp, amp / pow(harmonic, spectralPower));
	[note setDur:noteDuration * durationScale];
	[noteSender sendAndFreeNote:note];

	return self;
}

- write:(NXTypedStream *) stream
 /* Archive the performer to a typed stream. */
{
	[super write:stream];
	NXWriteTypes(stream, "ddddddddddddcc@i", &interval,
				 &velocityAmp, &freq, &amp, &firstHarm, &numHarms, &lastHarm,
				 &spectralPower, &noteDuration, &bendSensitivity,
				 &intervalScale, &harmScale, &useFractal,
				 &noRepeats, &fractal, &numTags);
	return self;
}

- read:(NXTypedStream *) stream
 /* Unarchive the performer from a typed stream. */
{
	int version;
	[super read:stream];
	version = NXTypedStreamClassVersion(stream, "HarmonicsPerformer");

	if (version < 2) {
		id doc;
		NXReadTypes(stream, "ddddddddddddcc@@", &interval,
				&velocityAmp, &freq, &amp, &firstHarm, &numHarms, &lastHarm,
				&spectralPower, &noteDuration, &bendSensitivity,
				&intervalScale, &harmScale, &useFractal,
				&noRepeats, &fractal, &doc);
	}
	else if (version == 2)
		NXReadTypes(stream, "ddddddddddddcc@", &interval,
				&velocityAmp, &freq, &amp, &firstHarm, &numHarms, &lastHarm,
				&spectralPower, &noteDuration, &bendSensitivity,
				&intervalScale, &harmScale, &useFractal,
				&noRepeats, &fractal);
	else if (version == 3)
		NXReadTypes(stream, "ddddddddddddcc@i", &interval,
				&velocityAmp, &freq, &amp, &firstHarm, &numHarms, &lastHarm,
				&spectralPower, &noteDuration, &bendSensitivity,
				&intervalScale, &harmScale, &useFractal,
				&noRepeats, &fractal, &numTags);
	return self;
}

- awake
 /* Initialize certain non-archived data */
{
	int i;
	id note;

	[super awake];
	noteSender = [self noteSender];
	conductor = [Conductor defaultConductor];
	for (i = 0; i < NUMHARMS; i++) {
		tags[i] = MKNoteTag();
		note = [[Note alloc] init];
		[note setNoteType:MK_noteOff];
		[note setNoteTag:tags[i]];
		noteOffs[i] = note;
	}

	return self;
}

@end
