#ifndef __MK_Shape_H___
#define __MK_Shape_H___
/* Shape.
 *
 * Eric J. Graves and David A. Jaffe
 * (c) 1992 Eric J. Graves & Stanford University
 *
 */

#import <MusicKit/MKSynthPatch.h>
#import <MusicKit/MKEnvelope.h>
#import <MusicKit/MKWaveTable.h>

@interface Shape:MKSynthPatch
{
    /* Amplitude parameters. */
    MKEnvelope *ampEnv;/* the Envelope object for amplitude */
    double  amp1,    /* amplitude scaler */
            amp0,    /* amplitude offset */
            ampAtt,  /* ampEnv attack duration in seconds */
            ampRel;  /* ampEnv release duration in seconds */

    /* Frequency parameters. */
    MKEnvelope *freqEnv;/* the Envelope object for frequency */
    double  freq1,    /* frequency scaler */
            freq0,    /* frequency offset */
            freqAtt,  /* freqEnv attack duration in seconds */
            freqRel;  /* freqEnv release duration in seconds */

    /* Waveshaping index Parameters. */
    MKEnvelope *indEnv; /* the Envelope for the index */
    double  indAtt,   /* indEnv attack duration in seconds */
            indRel;   /* indEnv release duration in seconds */
    double  m1Ind0, m1Ind1; /* Effective index must be between 0 and 1 */

    /* Other parameters. */
    double    portamento; /* transition time in seconds */
    double    bearing;    /* stereo location */

    id table;             /* The waveshaping table itself */
    MKWaveTable *tableInfo; /* Description of table */

    double phase;         /* Initial phase of osc */

    double velocitySensitivity; /* Sensitivity to velocity. Scale of 0 to 1 */
    double pitchbendSensitivity; /* Sensitivity to pitchBend in semitones. */

    id waveform;          /* Wavetable for oscillator */
    int wavelen;          /* Length of wavetable */
    int velocity;     /* MIDI velocity. Boosts or attenuates amplitude. */
    int pitchbend;    /* MIDI pitchBend. Raises or lowers pitch. */
    int volume;       /* MIDI volume pedal. Anything less than full pedal 
			 functions as an attenuation. */
    double bright;    /* A multiplier on index */

    /* Store unit generators in instance variables for convenience in 
     * subclassing
     */
    id freqAsymp,indAsymp,osc,tab,mul,ampAsymp,ampPp,stereoOut,ySig,xSig; 
}

+ patchTemplateFor:aNote;
- noteOnSelf:aNote;
- noteUpdateSelf:aNote;
- (double)noteOffSelf:aNote;
- noteEndSelf;
- preemptFor:aNote;
- init;

/* These methods are used by the subclass */
-_setDefaults;
-_initUGvars;
- _applyParameters:aNote;

@end

#endif
