#ifndef __MK_Envy_H___
#define __MK_Envy_H___
#import <musickit/SynthPatch.h>
#import <musickit/Envelope.h>

/* Interface for example SynthPatch Envy. */
@interface Envy:SynthPatch
{
    /* Amplitude parameters. */
    Envelope *ampEnv;/* the Envelope object for amplitude */
    double  amp1,    /* amplitude scaler */
            amp0,    /* amplitude offset */
            ampAtt,  /* ampEnv attack duration in seconds */
            ampRel;  /* ampEnv release duration in seconds */

    /* Frequency parameters. */     
    Envelope *freqEnv;/* the Envelope object for frequency */
    double  freq1,    /* frequency scaler */
            freq0,    /* frequency offset */
            freqAtt,  /* freqEnv attack duration in seconds */
            freqRel;  /* freqEnv release duration in seconds */

    /* Other parameters. */
    double    portamento; /* transition time in seconds */
    double    bearing;    /* stereo location */
}


+ patchTemplateFor:aNote;
- noteOnSelf:aNote;
- noteUpdateSelf:aNote;
- (double)noteOffSelf:aNote;
- noteEndSelf;
- preemptFor:aNote;
- init;

@end

#endif
