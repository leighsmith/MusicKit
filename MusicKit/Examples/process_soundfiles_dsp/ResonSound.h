#ifndef __MK_ResonSound_H___
#define __MK_ResonSound_H___
/* Copyright CCRMA, 1992.  All rights reserved. */
#import <musickit/SynthPatch.h>

/* Interface for example SynthPatch ResonSound. */
@interface ResonSound:SynthPatch
{
    /* Parameters to which this patch responds */
    double bearing;
    char *soundfile;
    double amp,ampAtt,ampRel;
    id ampEnv;
    double freq;
    id delayMem;
    double feedbackGain;
}

+ patchTemplateFor:aNote;
- noteOnSelf:aNote;
- noteUpdateSelf:aNote;
- noteEndSelf;
- preemptFor:aNote;

@end
#endif
