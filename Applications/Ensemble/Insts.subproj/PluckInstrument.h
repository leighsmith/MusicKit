#ifndef __MK_PluckInstrument_H___
#define __MK_PluckInstrument_H___
#import <musickit/musickit.h>
#import "EnsembleSynthIns.h"

@interface PluckInstrument : EnsembleSynthIns
    /* A SynthInstrument which handles a Pluck synthpatch */
{
	double sustain;
	double decay;
	double ampRel;
    id sustainField;
    id sustainSlider;
	id envInterface;
}

- takePSustainFrom:sender;
- takeEnvParFrom:sender;

@end


#endif
