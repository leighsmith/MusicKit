#ifndef __MK_EnsembleIns_H___
#define __MK_EnsembleIns_H___
#import <musickit/musickit.h>
#import "InstrumentCategory.h"
#import "EnsembleDoc.h"
#import "EnsembleApp.h"

@interface EnsembleIns : Instrument
{
    id document;				/* The document for this instrument */
	id window;					/* The main parameter panel */
	id view;					/* The main parameter view */
    id inspector;				/* The additional parameter panel, if any */
    id ampField;
    id ampSlider;
    id bearingField;
    id bearingSlider;
    id brightField;
    id brightSlider;
	id sensitivityInterface;
    id sustainButton;
    id hashtable;					/* hashtable used in handling damper pedal */
@public
	int patchAllocation;
    double velocitySensitivity;		/* MIDI velocity sensitivity */
    double aftertouchSensitivity; 	/* MIDI after touch sensititvity */
    double pitchbendSensitivity; 	/* MIDI pitch bend sensitivity */
    double modwheelSensitivity; 	/* MIDI mod wheel sensitivity */
    double breathSensitivity; 		/* MIDI breath sensitivity */
    double panSensitivity; 			/* MIDI pan sensitivity */
    double expressionSensitivity; 	/* MIDI expression sensitivity */
    double balanceSensitivity; 		/* MIDI balance sensitivity */
    BOOL damperOn;					/* state of damper pedal */
	double amp;						/* The most common parameters */
	double brightness;
	double bearing;
    int testKey;					/* Key number used for test notes. */
	BOOL damperButtonOn;			/* State of damper button */
}

- setDefaults;
- setDocument:aDocument;
- showInspector:sender;
- takeSensitivityFrom:sender;
- takeAmpFrom:sender;
- takeBearingFrom:sender;
- takeSustainFrom:sender;
- (int)testKey;
- view;
- inspector;

@end


#endif
