#ifndef __MK_EnvelopeSound_H___
#define __MK_EnvelopeSound_H___
/* Copyright CCRMA, 1992.  All rights reserved. */
#import <musickit/SynthPatch.h>

/* Interface for example SynthPatch EnvelopeSound. */
@interface EnvelopeSound:SynthPatch
{
    /* Parameters to which this patch responds */
    double bearing;
    char *soundfile;
    double amp,ampAtt,ampRel;
    id ampEnv;
}

+ patchTemplateFor:aNote;
- noteOnSelf:aNote;
- noteUpdateSelf:aNote;
- noteEndSelf;
- preemptFor:aNote;

@end
#endif
