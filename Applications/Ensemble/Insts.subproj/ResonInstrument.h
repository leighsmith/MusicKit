#ifndef __MK_ResonInstrument_H___
#define __MK_ResonInstrument_H___
#import <musickit/musickit.h>
#import "EnsembleSynthIns.h"

#define NPOINTS 4

@interface ResonInstrument : EnsembleSynthIns
    /* A SynthInstrument which handles a Reson synthpatch */
{
    id ampEnv;			/* The amplitude envelope */
	double feedback;
	double inputGain;
	int chan;
	id feedbackSlider;
	id feedbackField;
	id gainInterface;
    id ampEnvEditor;
	id channelSwitch;
}

- takeFeedbackFrom:sender;
- takeChannelFrom:sender;
- takeInputGainFrom:sender;

@end


#endif
