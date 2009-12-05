/* The Quad notefilter/performer combination is used to generate simulated quadraphonic
 * sound paths using, for example, the Niche Audio Control Module (an 8-in 8-out
 * MIDI-controlled audio fader, with an optional 8-in/2-out mixing capability).  One Quad
 * instance controls four channels of the fader.  Each channel should be fed the same
 * mono input, and the output levels are modulated by Ensemble to simulate a specified
 * sound path.  If you also feed the input signal to a reverb unit, then mix the output
 * of the reverb unit with each of the four fader outputs, one obtains a fairly realistic
 * motion and distance effect.
 *
 * QuadPerformer also sends MIDI pitchbend data which, if recognized by the MIDI synth
 * or DSP instrument, simulates doppler shift.  If used judicously, this adds an
 * especially effective realism to the simulation.
 *
 * This basic setup should be easily adaptible to control other MIDI-fader units
 * such as the Yamaha DMP7.
 */

#import "Quad.h"
#import "QuadPerformer.h"
#import "EnsembleDoc.h"
#import "WmFractal.h"
#import "LineGraph.h"
#import "ParamInterface.h"
#import "../Insts.subproj/MidiOutInstrument.h"
#import <appkit/appkit.h>

@implementation Quad

#define LOG2(x) (log10(x)/.301029995)


+ initialize
 /*
  * Set the version. This can be used in a later version to distinguish older
  * formats when unarchiving documents. 
  */
{
	[Quad setVersion:4];
	return self;
}

- initializeNiche
{
	id note = [[Note alloc] init];
	char *sysex;
	int i;
	unsigned int midiChan = 1;
	BOOL *insMap = [document instrumentMap:inputNum];
	id *instruments = [document instruments];
	
	/* First find the MIDI output channel being used - the Niche needs to know it */
	if (document)
		for (i=0; i<4; i++)
			if (insMap[i] && [instruments[i] isKindOf:[MidiOutInstrument class]]) {
				midiChan = [instruments[i] outChan];
				break;
			}

	NX_MALLOC(sysex, char, 42);
	sprintf(sysex, "F0,00,00,43,07,%02x,F7", midiChan);
	MKSetNoteParToString(note, MK_sysExclusive, sysex);
	[noteSender sendNote:note];

	/* Now set the MIDI controller numbers of the 4 Niche channels being used */
	sprintf(sysex, "F0,00,00,43,08,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,F7",
			nicheOffset + 1, outControllers[0],
			nicheOffset + 2, outControllers[1],
			nicheOffset + 3, outControllers[2],
			nicheOffset + 4, outControllers[3]);
	MKSetNoteParToString(note, MK_sysExclusive, sysex);
	[noteSender sendNote:note];
	NX_FREE(sysex);

	/* Initialize all four channels to zero level */
	[note setNoteType:MK_noteUpdate];
	MKSetNoteParToInt(note, MK_controlVal, 0);
	for (i = 0; i < 4; i++) {
		MKSetNoteParToInt(note, MK_controlChange, outControllers[i]);
		[noteSender sendNote:note];
	}
	[note free];
	return self;
}

- reset
{
	return [self initializeNiche];
}

- loadNibFile
{
	[NXApp loadNibSection:"Quad.nib" owner:self];
	return self;
}

- setDefaults
{
	int i;
	[super setDefaults];
	roomSize = 20.0;
	minDistance = 2.0;
	minXY = 1.414213562;
	interval =.2;
	displayDuration = 20.0;
	pitchBendSensitivity = 1.0;
	xController = -1;
	yController = -1;
	outControllers[0] = 20;
	outControllers[1] = 21;
	outControllers[2] = 22;
	outControllers[3] = 23;
	for (i = 0; i < 4; i++)
		controlVals[i] = -1;
	for (i = 0; i < 5; i++) {
		gravityControllers[i] = -1;
		gravity[i] = 0;
	}
	thru = YES;
	[xFractal setNumTerms:4];
	[yFractal setNumTerms:4];
	[xFractal setTimeScale:16];
	[yFractal setTimeScale:16];
	return self;
}
	
- init
 /* Called automatically when an instance is created. */
{
	pitchBendNote = [[Note alloc] init];
	[pitchBendNote setNoteType:MK_noteUpdate];
	xFractal = [[WmFractal allocFromZone:[self zone]] init];
	yFractal = [[WmFractal allocFromZone:[self zone]] init];
	[xFractal setDelegate:self];
	[yFractal setDelegate:self];
	performer = [[QuadPerformer allocFromZone:[self zone]] init];
	[performer setNoteFilter:self];
	[performer setFractalX:xFractal y:yFractal];
	[super init];
	return self;
}

- awakeFromNib
{
	[super awakeFromNib];
	[lineGraph setLineGray:NX_WHITE];
	[lineGraph setBackgroundGray:NX_BLACK];
	[lineGraph setShowPoints:YES];

    [intervalField setFloatValue:interval];
    [intervalSlider setFloatValue:interval*100.0];
    [displayDurationField setFloatValue:displayDuration];
    [displayDurationSlider setFloatValue:displayDuration];
	[pathEnableSwitch setState:fractalEnabled];

    [roomSizeField setFloatValue:roomSize];
    [roomSizeSlider setFloatValue:roomSize];
    [minDistanceField setFloatValue:minDistance];
    [minDistanceSlider setFloatValue:minDistance];

 	[channelButtons selectCellWithTag:nicheOffset];
    [delayField setFloatValue:delay];
    [delaySlider setFloatValue:delay];
    [pitchBendField setIntValue:pitchBendSensitivity];
    [pitchBendSlider setIntValue:pitchBendSensitivity];

    [outControlInterface setMode:CONTROLS];
	[inControlInterface setMode:CONTROLS];
	[gravControlInterface setMode:CONTROLS];
	
	[outControlInterface setIntValues:outControllers];
	[inControlInterface setIntValueAt:0 to:xController];
	[inControlInterface setIntValueAt:1 to:yController];
	[gravControlInterface setIntValues:gravityControllers];

	[thruButton setState:thru];

	[self graphPath];
//	[self initializeNiche];
	return self;
}

- free
 /* Fractals are freed when performer is freed */
{
	[pitchBendNote free];
	return [super free];
}

- graphPath
 /* Graph the first displayDuration seconds of the path */
{
	register int i;
	register float t = 0.0;
	float *x, *y;
	int n;

	if (!(xFractal && yFractal))
		return self;
	n = displayDuration / interval + 1;
	NX_MALLOC(x, float, n);
	NX_MALLOC(y, float, n);
	for (i = 0; i < n; i++) {
		x[i] = 2 * [xFractal generate:t] - 1.0;
		y[i] = 2 * [yFractal generate:t] - 1.0;
		t += interval;
	}
	[lineGraph setPoints:n x:x y:y minX:-1.0 minY:-1.0 maxX:1.0 maxY:1.0];
	[lineGraph scaleToFit];
	[lineGraph display];
	NX_FREE(x);
	NX_FREE(y);
	return self;
}

- fractalChanged:sender
{
	[document setEdited];
	return[self graphPath];
}

- takeFractalEnableFrom:sender
{
	fractalEnabled = [sender state];
	[document setEdited];
	return self;
}

- takeIntervalFrom:sender
{
	interval = (float)[sender intValue] *.01;
	[performer setInterval:interval];
	[intervalField setFloatValue:interval];
	[document setEdited];
	return[self graphPath];
}

- takePitchBendFrom:sender
{
	int pb = [sender intValue];

	pitchBendSensitivity = (float)pb;
	[pitchBendField setIntValue:pb];
	[document setEdited];
	return self;
}

- takeRoomSizeFrom:sender
{
	roomSize = [sender floatValue];
	[roomSizeField setFloatValue:roomSize];
	[document setEdited];
	return self;
}

- takeMinDistanceFrom:sender
{
	minDistance = [sender floatValue];
	minXY = (float)pow((double)((minDistance*minDistance)/2.0),.5);
	[minDistanceField setFloatValue:minDistance];
	[document setEdited];
	return self;
}

- takeControllerFrom:sender
{
	int which = [sender selectedIndex];
	int val = [sender intValue];
	int i;

	if (which == 0)
		xController = val;
	else
		yController = val;

	midiIn = ((xController >= 0) && (yController >= 0));
	if (!midiIn)
		for (i = 0; i < 5; i++)
			if (gravityControllers[i] >= 0) {
				midiIn = YES;
				break;
			}
	[document setEdited];
	return self;
}

- takeNicheOffsetFrom:sender
{
	nicheOffset = [[sender selectedCell] tag];
	return self;
}

- takeOutControllerFrom:sender
{
	int which = [sender selectedIndex];
	int val = [sender intValue];
	id note = [[Note alloc] init];
	char *sysex;
	
	if (val > 97)
		[sender setIntValueAt:which to:val=97];

	outControllers[which] = val;

	if (val >= 0) {
		NX_MALLOC(sysex, char, 24);
		sprintf(sysex, "F0,00,00,43,08,%02x,%02x,F7", which + 1 + nicheOffset, (unsigned)val);
		MKSetNoteParToString(note, MK_sysExclusive, sysex);
		[noteSender sendAndFreeNote:note];
		NX_FREE(sysex);
	}

	[document setEdited];
	return self;
}

- takeGravityControllerFrom:sender
{
	int which = [sender selectedIndex];
	int val = [sender intValue];
	int i;

	gravityControllers[which] = val;

	for (i = 0; i < 5; i++) gravity[i] = 0;

	midiIn = ((xController >= 0) && (yController >= 0));

	if (!midiIn)
		for (i = 0; i < 5; i++)
			if (gravityControllers[i] >= 0) {
				midiIn = YES;
				break;
			}

	[document setEdited];
	return self;
}

- takeDelayFrom:sender
{
	delay = (float)[sender intValue] / 50.0;
	[delayField setFloatValue:delay];
	[document setEdited];
	return self;
}

- takeDisplayDurationFrom:sender
{
	displayDuration = (float)[sender intValue];
	[displayDurationField setFloatValue:displayDuration];
	[document setEdited];
	[self graphPath];
	return self;
}

- takeThruFrom:sender
{
	thru = [sender state];
	[document setEdited];
	return self;
}

- inspectFractal:sender
{
	[performer inspectFractal:sender];
	return self;
}

int dBToMidi(float dB)
	/* Designed to map dB to MIDI controller values specifically for the Niche 
	 * Audio Control Module 
	 */
{
	if (dB > -20.0)
		return 127.99 + dB /.32;
	else if (dB > -33.5)
		return 64.99 + (dB + 20.0) /.42;
	else if (dB > -46.7)
		return 32.99 + (dB + 33.6) /.82;
	else if (dB > -57.0)
		return 16.99 + (dB + 46.4) / 1.3;
	else
		return MAX(8.99 + (dB + 55.9) / 2.3, 0);
}

#define ampToMIDI(amp) (dBToMidi(20.0*log10(amp)))

- moveTo:(float)x :(float)y
 /* Arguments should be between -1 and 1 */
{
	float xDist, yDist, newDistance, distFactor;
	float pan, offset;
	int i, val;
	float centerX = 0.0, centerY = 0.0;
	float maxGravity = 0;
	float totalGravity = 0;
	float size = roomSize;
	static float newAmps[4];

	if (gravity[0]) {
		offset = minXY * 2 * gravity[0];
		centerX += offset;
		centerY += offset;
		maxGravity = gravity[0];
		totalGravity += gravity[0];
	}
	if (gravity[1]) {
		offset = minXY * 2 * gravity[1];
		centerX -= offset;
		centerY += offset;
		maxGravity = MAX(maxGravity, gravity[1]);
		totalGravity += gravity[1];
	}
	if (gravity[2]) {
		offset = minXY * 2 * gravity[2];
		centerX -= offset;
		centerY -= offset;
		maxGravity = MAX(maxGravity, gravity[2]);
		totalGravity += gravity[2];
	}
	if (gravity[3]) {
		offset = minXY * 2 * gravity[3];
		centerX += offset;
		centerY -= offset;
		maxGravity = MAX(maxGravity, gravity[3]);
		totalGravity += gravity[3];
	}
	if (gravity[4]) {
		/* "Center" gravity */
		maxGravity = MAX(maxGravity, gravity[4]);
		totalGravity += gravity[4];
	}
	if (maxGravity)
		size += minDistance * totalGravity - size * maxGravity;

	xDist = centerX + x * size;
	yDist = centerY + y * size;
	newDistance = MAX((float)pow((double)(xDist*xDist+yDist*yDist),0.5), minDistance);
	distFactor = minDistance / MAX(newDistance, minDistance);

	if (xDist >= fabs(yDist)) {	/* Right */
		pan = (1.0 + yDist / xDist) / 2.0;
		newAmps[0] = pan*distFactor;
		newAmps[1] = 0.0;
		newAmps[2] = 0.0;
		newAmps[3] = (1.0-pan)*distFactor;
	} else if (yDist >= fabs(xDist)) {	/* Front */
		pan = (1.0 - xDist / yDist) / 2.0;
		newAmps[0] = (1.0-pan)*distFactor;
		newAmps[1] = pan*distFactor;
		newAmps[2] = 0.0;
		newAmps[3] = 0.0;
	} else if (xDist <= -fabs(yDist)) {	/* Left */
		pan = (1.0 + yDist / xDist) / 2.0;
		newAmps[0] = 0.0;
		newAmps[1] = (1.0-pan)*distFactor;
		newAmps[2] = pan*distFactor;
		newAmps[3] = 0.0;
	} else {					/* Rear */
		pan = (1.0 - xDist / yDist) / 2.0;
		newAmps[0] = 0.0;
		newAmps[1] = 0.0;
		newAmps[2] = (1.0-pan)*distFactor;
		newAmps[3] = pan*distFactor;
	}

	for (i = 0; i < 4; i++) {
		/* Low pass filter the amps to insure smooth transitions between speakers */
		amps[i] = newAmps[i]*0.667 + amps[i]*0.333;
		val = ampToMIDI(amps[i]);
		if (val != controlVals[i]) {
			id note = [[[Note alloc] init] setNoteType:MK_noteUpdate];

			MKSetNoteParToInt(note, MK_controlChange, outControllers[i]);
			MKSetNoteParToInt(note, MK_controlVal, controlVals[i] = val);
			if (delay > 0)
				[noteSender sendAndFreeNote:note withDelay:delay];
			else
				[noteSender sendAndFreeNote:note];
		}
	}
	if ((pitchBendSensitivity > 0) && (distance < 1000.0)) {
		float ratio = 300.0 / (300.0 - (distance - newDistance) / interval);
		float halfSteps = 12.0 * (float)LOG2((double)ratio);
		int pb = (int)(8191.0 * halfSteps / pitchBendSensitivity) + 8192;

		MKSetNoteParToInt(pitchBendNote, MK_pitchBend, MIN(MAX(pb, 0), 16383));
		[noteSender sendNote:pitchBendNote];
	}
	distance = newDistance;
	return self;
}

- realizeNote:aNote fromNoteReceiver:aNoteReceiver
{
	MKNoteType type = [aNote noteType];
	BOOL move = NO;

	if (thru)
		[noteSender sendNote:aNote];
	if (fractalEnabled && MKIsNoteParPresent(aNote, MK_sysRealTime)) {
		switch (MKGetNoteParAsInt(aNote, MK_sysRealTime)) {
			case MK_sysStart:
				if ([performer status] == MK_paused)
					[(QuadPerformer *)performer deactivate];
				if ([performer status] != MK_active) {
					distance = 1000.0;
					[self initializeNiche];
					[(QuadPerformer *)performer activate];
					break;
				}
			case MK_sysContinue:
				[(QuadPerformer *)performer resume];
				break;
			case MK_sysStop:
				[(QuadPerformer *)performer pause];
				break;
			case MK_sysReset:
				[(QuadPerformer *)performer pause];
				[(QuadPerformer *)performer deactivate];
				break;
		}
	} else if (midiIn && (type == MK_noteUpdate) &&
			   MKIsNoteParPresent(aNote, MK_controlChange)) {
		int controller = MKGetNoteParAsInt(aNote, MK_controlChange);
		int value = MKGetNoteParAsInt(aNote, MK_controlVal);
		int i;

		if (controller == xController) {
			currentX = (float)(value - 63) / 64.0;
			move = YES;
		} else if (controller == yController) {
			currentY = (float)(value - 63) / 64.0;
			move = YES;
		} else
			for (i = 0; i < 5; i++)
				if (controller == gravityControllers[i])
					gravity[i] = (float)value / 127.0;
		if (move)
			[self moveTo:currentX :currentY];
	}
	return self;
}

- write:(NXTypedStream *) stream
 /* Archive the performer to a typed stream. */
{
	[super write:stream];
	NXWriteTypes(stream, "@@cccffffffiii",
				&xFractal, &yFractal,
				&midiIn, &fractalEnabled, &thru,
				&pitchBendSensitivity, &roomSize, &minDistance,
				&interval, &delay, &displayDuration,
				&xController, &yController, &nicheOffset);
	NXWriteArray(stream, "i", 4, outControllers);
	NXWriteArray(stream, "i", 5, gravityControllers);
	return self;
}

- read:(NXTypedStream *) stream
 /* Unarchive the performer from a typed stream. */
{
	id foo;
	int version;
	[super read:stream];
	version = NXTypedStreamClassVersion(stream, "Quad");
	if (version <= 1) {
		double d1, d2, d3, d4, d5, d6;
		NXReadTypes(stream, "@@@@@@@@@@@@@@cccddddddiii@",
				&foo, &minDistanceField, &pitchBendField,
				&foo, &intervalField, &foo,
				&roomSizeField, &foo, &delayField,
				&displayDurationField, &lineGraph,
				&foo, &xFractal, &yFractal,
				&midiIn, &fractalEnabled, &thru,
				&d1, &d2, &d3, &d4, &d5, &d6,
				&xController, &yController, &nicheOffset, &document);
		pitchBendSensitivity = (float)d1;
		roomSize = (float)d2;
		minDistance = (float)d3;
		interval = (float)d4;
		delay = (float)d5;
		displayDuration = (float)d6;
	}
	else if (version == 2) {
		NXReadTypes(stream, "@@@@@@@@@@@@@@cccffffffiii@",
				&foo, &minDistanceField, &pitchBendField,
				&foo, &intervalField, &foo,
				&roomSizeField, &foo, &delayField,
				&displayDurationField, &lineGraph,
				&foo, &xFractal, &yFractal,
				&midiIn, &fractalEnabled, &thru,
				&pitchBendSensitivity, &roomSize, &minDistance,
				&interval, &delay, &displayDuration,
				&xController, &yController, &nicheOffset, &document);
		NXReadArray(stream, "i", 4, outControllers);
		NXReadArray(stream, "i", 4, gravityControllers);
	}
	else if ((version == 3) || (version == 4)) {
		NXReadTypes(stream, "@@cccffffffiii",
				&xFractal, &yFractal,
				&midiIn, &fractalEnabled, &thru,
				&pitchBendSensitivity, &roomSize, &minDistance,
				&interval, &delay, &displayDuration,
				&xController, &yController, &nicheOffset);
		NXReadArray(stream, "i", 4, outControllers);
		if (version==3) {
			NXReadArray(stream, "i", 4, gravityControllers);
			gravityControllers[4] = -1;
		}
		else
			NXReadArray(stream, "i", 5, gravityControllers);
	}
	return self;
}

- awake
 /* Initialize certain non-archived data */
{
	int i;
	[super awake];
	conductor = [Conductor defaultConductor];
	for (i = 0; i < 4; i++)
		controlVals[i] = -1;
	pitchBendNote = [[Note alloc] init];
	[pitchBendNote setNoteType:MK_noteUpdate];
	minXY = pow(pow(minDistance, 2.0) / 2.0,.5);
	return self;
}

@end
