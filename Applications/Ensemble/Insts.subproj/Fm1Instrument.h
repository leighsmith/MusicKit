#ifndef __MK_Fm1Instrument_H___
#define __MK_Fm1Instrument_H___
#import <musickit/musickit.h>
#import "Wave1Instrument.h"

#define NPARTIALS 8

@interface Fm1Instrument:Wave1Instrument
{
    double cRatio; 					/* The carrier frequency ratio */
    double mRatio; 					/* The modulator frequency ratio */
    id indEnv;			   			/* Modulation index envelope */
    double carAmps[NPARTIALS];		/* Carrier component amplitudes  */
    double modAmps[NPARTIALS];		/* Modulator component amplitudes */
    id carrierWave, modulatorWave;	/* The carrier and modulator wavetables */
    id carSynthData, modSynthData;	/* The SynthData for the above */
    double index0, index1;			/* Modulation min and max indices */
    int lastKey, scalingKey;		/* Variables for index scaling by freq */
    double scaling;
	id modulationInterface;
	id indEnvEditor;
	id carrierSliders;
	id modulatorSliders;
	id modSustainSwitch;
	id modSmoothingFields;
}

- takeCarWaveFrom:sender;
- takeModWaveFrom:sender;
- takeModParamsFrom:sender;

@end


#endif
