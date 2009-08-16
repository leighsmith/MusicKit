#ifndef __MK_ResonSound_H___
#define __MK_ResonSound_H___
/* Copyright CCRMA, 1992.  All rights reserved. */
#import <MusicKit/MKSynthPatch.h>

/* Interface for example MKSynthPatch ResonSound. */
@interface ResonSound: MKSynthPatch
{
    /* Parameters to which this patch responds */
    double bearing;
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
