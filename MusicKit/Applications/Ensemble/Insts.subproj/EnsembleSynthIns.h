#ifndef __MK_EnsembleSynthIns_H___
#define __MK_EnsembleSynthIns_H___
#import <musickit/musickit.h>
#import "InstrumentCategory.h"
#import "EnsembleDoc.h"
#import "EnsembleApp.h"

@interface EnsembleSynthIns : SynthInstrument
{
    id document;				/* The document for this instrument */
	id window;					/* The main parameter panel */
	id view;					/* The main parameter view */
    id inspector;				/* The additional parameter panel, if any */
    id patchCountField;			/* Some common paramter displayers  */
    id ampField;
    id ampSlider;
    id bearingField;
    id bearingSlider;
    id brightField;
    id brightSlider;
	id sensitivityInterface;
    id sustainButton;
	double amp;						/* The most common parameters */
	double bearing;
	double brightness;
    int patchAllocation;			/* Number of patches to allocate */
    double velocitySensitivity;		/* MIDI velocity sensitivity */
    double aftertouchSensitivity; 	/* MIDI after touch sensititvity */
    double pitchbendSensitivity; 	/* MIDI pitch bend sensitivity */
    double modwheelSensitivity; 	/* MIDI mod wheel sensitivity */
    double breathSensitivity; 		/* MIDI breath sensitivity */
    double panSensitivity; 			/* MIDI pan sensitivity */
    double expressionSensitivity; 	/* MIDI expression sensitivity */
    double balanceSensitivity; 		/* MIDI balance sensitivity */
    BOOL damperOn;					/* state of damper pedal controller */
    int testKey;					/* Key number used for test notes. */
    id hashtable;					/* hashtable used in handling damper pedal */
	int orchestraNum;				/* DSP number in multi-DSP setting */
	BOOL damperButtonOn;			/* State of damper button */
}

- setDefaults;
- setDocument:aDocument;
- showInspector:sender;
- takePatchCountFrom:sender;
- takeSensitivityFrom:sender;
- takeAmpFrom:sender;
- takeBearingFrom:sender;
- takeSustainFrom:sender;
- takeBrightnessFrom:sender;
- (int)testKey;
- allocatePatches;
- displayPatchCount;
- setPatchAllocation:(int)nPatches;
- (int)patchAllocation;
- inspector;
- view;

@end


#endif
