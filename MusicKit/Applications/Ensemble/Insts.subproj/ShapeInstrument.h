#ifndef __MK_ShapeInstrument_H___
#define __MK_ShapeInstrument_H___
#import <musickit/musickit.h>
#import "Wave1Instrument.h"

#define NCPARTIALS 8
#define NWPARTIALS 17

@interface ShapeInstrument:Wave1Instrument
{
    id indEnv;	   			/* Waveshaping index envelope */
    double oscAmps[NCPARTIALS];		/* Oscillator component amplitudes  */
    double modAmps[NWPARTIALS];		/* Waveshaping table component amplitudes */
    id oscWave, modulatorWave;	        /* The osc and waveshaping Partials */
    id oscSynthData, modSynthData;	/* The SynthData for the above */
    double index0, index1;		/* Modulation min and max indices */
    int lastKey, scalingKey;		/* Variables for index scaling by freq */
    double scaling;
    id modulationInterface;
    id indEnvEditor;
    id oscSliders;
    id modulatorSliders;
    id modSustainSwitch;
    id modSmoothingFields;
}

- takeOscWaveFrom:sender;
- takeModWaveFrom:sender;
- takeModParamsFrom:sender;

@end


#endif
