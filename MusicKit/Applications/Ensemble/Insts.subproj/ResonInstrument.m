/* An SynthInstrument for handling ResonSound synthpatches, and adjusting
 * their parameters via a graphic interface.
 */

#import "ResonInstrument.h"
#import "ParamInterface.h"
#import "ResonSound.h"
#import <appkit/appkit.h>
#import <objc/HashTable.h>
#import <mididriver/midi_spec.h>
#import "EnsembleApp.h"
#import "EnvelopeView.h"

@implementation ResonInstrument
{
}

static int chanPar, gainPar;

+ initialize
{
    [ResonInstrument setVersion:2];
	chanPar = [Note parTagForName:"SoundInputChan"];
	gainPar = [Note parTagForName:"SoundInputGain"];
	return self;
}

- initEnvelope
 /* Initialize the amplitude envelope and the arrays used to constuct and update it. */
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

- setDefaults
{
	[self initEnvelope];
	[super setDefaults];
	feedback = .95;
	inputGain = 1.0;
	/* Preload the SynthInstrument update note with our defaults */
	MKSetNoteParToString(updates, MK_synthPatch, "ResonSound");
	MKSetNoteParToDouble(updates, MK_feedback, feedback);
	MKSetNoteParToDouble(updates, gainPar, inputGain);
	MKSetNoteParToEnvelope(updates, MK_ampEnv, ampEnv);
	MKSetNoteParToInt(updates, chanPar, 0);
	return self;
}
	
- loadNibFile
{
	[NXApp loadNibSection:"ResonInstrument.nib" owner:self withNames:NO];
	return self;
}
	
- init
 /* Called automatically when an instance is created. */
{
	[super init];
	[self setSynthPatchClass:[ResonSound class]];
	return self;
}

- awakeFromNib
 /* Things that have to be done AFTER the nib section is loaded in */
{
	[super awakeFromNib];
	[feedbackSlider setDoubleValue:feedback];
	[feedbackField setDoubleValue:feedback];
	[channelSwitch selectCellWithTag:chan];
	[ampEnvEditor setEnvelope:ampEnv];
	[gainInterface setMode:DB];
	[gainInterface setDoubleValue:inputGain];
	return self;
}

- free
{
	[ampEnv free];
	[gainInterface free];
	return [super free];
}

- envelopeModified:sender
{
	[document setEdited];
	return self;
}

- takeFeedbackFrom:sender
	/* Gain factor in feedback loop - controls amount of resonance */
{
	static id note = nil;
	feedback = [sender doubleValue];
	feedback = MAX(MIN(feedback,.999),-.999);
	if (!note) {
		 note = [[Note alloc] init];
		[note setNoteType:MK_noteUpdate];
	}
	[Conductor lockPerformance];
	[note setPar:MK_feedback toDouble:feedback];
	[self realizeNote:note fromNoteReceiver:nil];
	[Conductor unlockPerformance];
	[feedbackField setDoubleValue:feedback];
	if (sender == feedbackField)
		[feedbackSlider setDoubleValue:feedback];
    [document setEdited];
	return self;
}

- takeInputGainFrom:sender
	/* Gain of input unit generator reading from the SSI serial port */
{
	static id note = nil;
	inputGain = [sender doubleValue];
	if (!note) {
		 note = [[Note alloc] init];
		[note setNoteType:MK_noteUpdate];
	}
	[Conductor lockPerformance];
	[note setPar:gainPar toDouble:inputGain];
	[self realizeNote:note fromNoteReceiver:nil];
	[Conductor unlockPerformance];
    [document setEdited];
	return self;
}

- takeChannelFrom:sender
{
	[Conductor lockPerformance];
	[self abort];
	[self setSynthPatchCount:0];
	MKSetNoteParToInt(updates, chanPar, chan = [[sender selectedCell] tag]);
	[self allocatePatches];
	[Conductor unlockPerformance];
	NXPing();
	[NXApp synchDSPDelayed:0.5];
    [document setEdited];
	return self;
}

- write:(NXTypedStream *) stream
    /* Archive the instrument to a typed stream. */
{
    [super write:stream];
    NXWriteTypes(stream, "@did", &ampEnv, &feedback, &chan, &inputGain);
	return self;
}

- read:(NXTypedStream *) stream
    /* Un-archive the instrument from a typed stream. */
{
    int version;
    [super read:stream];
    version = NXTypedStreamClassVersion(stream,"ResonInstrument");
	switch (version) {
		case 1:
    		NXReadTypes(stream, "@di", &ampEnv, &feedback, &chan);
			inputGain = 1.0;
			break;
		case 2:
    		NXReadTypes(stream, "@did", &ampEnv, &feedback, &chan, &inputGain);
			break;
		default:
			break;
	}
	return self;
}

- awake
{

 	[super awake];

	MKSetNoteParToInt(updates, chanPar, chan);
	MKSetNoteParToDouble(updates, gainPar, inputGain);
	return self;
}

@end
