#ifndef __MK_Wave1Instrument_H___
#define __MK_Wave1Instrument_H___
#import "EnsembleSynthIns.h"

@interface Wave1Instrument : EnsembleSynthIns
    /* A SynthInstrument which handles a DBWave1vi synthpatch */
{
    double svibAmp0, svibAmp1;	/* min and max sine vibrato amount */
    double svibFreq0, svibFreq1;		/* min and max sine vibrato frequencies */
    double rvibAmp;				/* percentage of random vibrato */
    double vibRanPc;			/* percentage of variation in sine vib freq */
    double vran0, vran1;
	double balance;				/* blend of the two timbres */
	double modwheel;			/* controls vibrato */
    id ampEnv;					/* The amplitude envelope */
	id ampEnvEditor;
    id interpField;				/* interface objects */
    id interpSlider;
    id modwheelField;
    id modwheelSlider;
    id waveformButton;
	id vibratoInterface;
    id timbreMenu;
}

- setDefaults;
- takeWaveInterpFrom:sender;
- takeModwheelFrom:sender;
- takeWaveformFrom:sender;
- takeVibratoFrom:sender;
- toggleVibrato:sender;

@end


#endif
