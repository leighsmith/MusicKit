/* Obsolete.  See MidiOutInstrument.m */
#import "MidiOutInstrument.h"
#import "MidiInstrument.h"
#import <appkit/appkit.h>

@implementation MidiInstrument
{
}

- takeVelocityFrom:sender {return self;}
- takeMinVelFrom:sender {return self;}
- takeControlValFrom:sender {return self;}
- takeControllerFrom:sender {return self;}
- takeChannelFrom:sender {return self;}
- takePanFrom:sender {return self;}
- takeControlControllerFrom:sender {return self;}
- takeVelocityControllerFrom:sender {return self;}
- takeChannelControllerFrom:sender {return self;}
- takeControlMinFrom:sender {return self;}
- takeControlMaxFrom:sender {return self;}
- takeVelocityAdjustMinFrom:sender {return self;}
- takeVelocityAdjustMaxFrom:sender {return self;}
- showParameters:sender {return self;}

- read:(NXTypedStream *) stream
 /* Unarchive the instrument from a typed stream. */
{
	int version;

	[super read:stream];
	version = NXTypedStreamClassVersion(stream, "MidiInstrument");
	if (version <= 1)
		NXReadTypes(stream, "iiiiiii@@@@@@@@", &testKey, &velocityIncrement,
					&outChan, &pan, &minVel, &controller, &controlVal, &info,
					&document, &view, &panDisplayer, &velocityDisplayer,
					&channelDisplayer, &controllerDisplayer,
					&controlValDisplayer);
	else if (version == 2) {
		NXReadTypes(stream, "iiiiiii@@@@@@@@", &testKey, &velocityIncrement,
					&outChan, &pan, &minVel, &controller, &controlVal, &info,
					&document, &view, &panDisplayer, &velocityDisplayer,
					&channelDisplayer, &controllerDisplayer,
					&controlValDisplayer);
		NXReadTypes(stream, "@", &minVelDisplayer);
	} else if (version == 3)
		NXReadTypes(stream, "iiiiiiiiiiiiii@@@@@@@@@@@@@@@@@@@",
					&testKey, &velocityIncrement,
					&outChan, &pan, &minVel, &controller, &controlVal,
					&velocityAdjustMin, &velocityAdjustMax,
					&controlMin, &controlMax,
				  	&velocityController, &channelController, &controlController,
					&info, &parametersWindow, &document, &view,
					&panDisplayer, &velocityDisplayer,
					&channelDisplayer, &controllerDisplayer,
					&controlValDisplayer, &minVelDisplayer,
					&controlControllerDisplayer, &velocityControllerDisplayer,
					&channelControllerDisplayer, &controlMinDisplayer,
					&controlMaxDisplayer, &velocityMinDisplayer,
					&velocityMaxDisplayer, &velocityAdjustSlider,
					&controlSlider);
	if (version < 3)
		channelController = 17;
	return self;
}

typedef struct {@defs (NoteReceiver)} nrId;
#define OWNER(noteRcvr) (((nrId *)(noteRcvr))->owner)

- finishUnarchiving
{
	id nr;
	MidiOutInstrument *newself = [MidiOutInstrument allocFromZone:[self zone]];
	newself->testKey = testKey;
	newself->velocityIncrement = velocityIncrement;
	newself->outChan = outChan;
	newself->bearing = floor(-45.0 + 90.0 * (double)pan/127.0+0.5);
	newself->minVel = minVel;
	newself->controller = controller;
	newself->controlVal = controlVal;
	newself->velocityAdjustMin = velocityAdjustMin;
	newself->velocityAdjustMax = velocityAdjustMax;
	newself->controlMin = controlMin;
	newself->controlMax = controlMax;
    newself->controlController = controlController;
    newself->channelController = channelController;
    newself->velocityController = velocityController;
	/* Connect whatever was connected to the old instrument to its successor  */
	nr = [self noteReceiver];
	OWNER(nr) = self;	/* For some reason this is nil sometimes and needs to be set */
	[newself addNoteReceiver:nr];
	[newself awake];
	[NXApp delayedFree:self];
	return newself;
}

@end
