#import <musickit/SynthPatch.h>
#import <musickit/WaveTable.h>
#import <musickit/Envelope.h>

/* ------------------------------------------------------------------------ * 
 * FM is a frequency modulation SynthPatch with arbitrary waveforms for     *
 * carrier and modulator and an interpolating oscillator for the carrier.   *
 * It supports a wide variety of parameters, including many MIDI parameters.* 
 * It supports a wide variety of parameters, including many MIDI parameters.* 
 *                                                                          *
 * This example is almost identical to the Fm1vi supplied with the 2.0      *
 * Music Kit SynthPatch Library. The only difference is that Fm1vi supports *
 * multiple "flavors" for optimization. For example, Fm1vi allows you to    *
 * specify a patch implementing only periodic or only random vibrato.       *
 *                                                                          *
 * See the FM literature for details of FM synthesis.                       *
 * (Note that the implementation here is "frequency modulation" rather than *
 * "phase modulation" and that the deviation scaling does not follow the    *
 * frequency envelope -- it is exactly as defined in the literature only    *
 * when the frequency envelope is at 1 and the vibrato is neither above nor *
 * below the pitch.)                                                        *
 * ------------------------------------------------------------------------ */

@interface FM:SynthPatch
{
    /* Instance variables for the parameters to which the SynthPatch 
       responds. */

    WaveTable *waveform;    /* Carrier waveform */
    WaveTable *m1Waveform;  /* Modulator waveform */

    double cRatio;    /* Carrier frequency scaler. */
    double m1Ratio;   /* Modulater frequency scaler. */

    Envelope *ampEnv; /* Amplitude envelope. */ 
    double amp0;      /* Amplitude when ampEnv is at 0 */
    double amp1;      /* Amplitude when ampEnv is at 1 */
    double ampAtt;    /* ampEnv attack time or MK_NODVAL for 'not set'. */
    double ampRel;    /* ampEnv release time or MK_NODVAL for 'not set'. */

    Envelope *freqEnv; /* Frequency envelope. */
    double freq0;     /* Frequency when freqEnv is at 0. */
    double freq1;     /* Frequency when freqEnv is at 1. */
    double freqAtt;   /* freqEnv attack time or MK_NODVAL for 'not set'. */
    double freqRel;   /* freqEnv release time or MK_NODVAL for 'not set'. */

    Envelope *m1IndEnv;/* FM index envelope */
    double m1Ind0;    /* FM index when m1IndEnv is at 0 */
    double m1Ind1;    /* FM index when m1IndEnv is at 1 */
    double m1IndAtt;  /* m1IndEnv attack time or MK_NODVAL for 'not set'. */
    double m1IndRel;  /* m1IndEnv release time or MK_NODVAL for 'not set'. */

    double bright;    /* Brightness. A multiplier on index. */

    double bearing;   /* Left/right panning. -45 to 45. */

    double portamento;/* Transition time upon rearticulation, in seconds. */

    WaveTable *vibWaveform; /* Waveform used for vibrato. */
    double svibAmp0;  /* Vibrato, on a scale of 0 to 1, when modWheel is 0. */
    double svibAmp1;  /* Vibrato, on a scale of 0 to 1, when modWheel is 127.*/
    double svibFreq0; /* Vibrato freq in Hz. when modWheel is 0. */
    double svibFreq1; /* Vibrato freq in Hz. when modWheel is 1. */
    
    double rvibAmp;   /* Random vibrato. On a scale of 0 to 1. */

    double phase;     /* Initial phase in radians */
    double m1Phase;   /* Initial modulator phase in radians */

    double velocitySensitivity; /* Sensitivity to velocity. Scale of 0 to 1 */
    double afterTouchSensitivity;/* Sensitivity to afterTouch. 0 to 1. */
    double pitchbendSensitivity; /* Sensitivity to pitchBend in semitones. */

    int velocity;     /* MIDI velocity. Boosts or attenuates amplitude. */
    int pitchbend;    /* MIDI pitchBend. Raises or lowers pitch. */
    int modWheel;     /* MIDI modWheel. Controls vibrato frequency and amp */
    int afterTouch;   /* MIDI afterTouch. Anything less than full after touch 
			 functions as an attenuation. */
    int volume;       /* MIDI volume pedal. Anything less than full pedal 
			 functions as an attenuation. */

    int wavelen;      /* WaveTable size. Rarely needed. */
}

/* Default parameter values, if corresponding parameter is omitted: 
   
   waveform - sine wave
   m1Waveform - sine wave

   cRatio - 1.0
   m1Ratio - 1.0

   ampEnv - none
   amp0 - 0
   amp1 - 0.1
   ampAtt - not set (use times specified in envelope directly)
   ampRel - not set (use times specified in envelope directly)

   freqEnv - none
   freq0 - 0.0 Hz.
   freq1 - 440.0 Hz.
   freqAtt - not set (use times specified in envelope directly)
   freqRel - not set (use times specified in envelope directly)

   m1IndEnv - none
   m1Ind0 - 0.0
   m1Ind1 - 2.0
   m1IndAtt - not set (use times specified in envelope directly)
   m1IndRel - not set (use times specified in envelope directly)

   bright - 1.0

   bearing - 0.0

   portamento - not set (use times specified in envelope directly)

   vibWaveform - sine wave
   svibAmp0 - 0.0
   svibAmp1 - 0.0
   svibFreq0 - 0.0 Hz.
   svibFreq1 - 0.0 Hz.
    
   rvibAmp - 0.0

   phase - 0.0 radians
   m1Phase - 0.0 radians

   velocitySensitivity - 0.5 of maximum
   afterTouchSensitivity - 0.5 of maximum
   pitchbendSensitivity - 3.0 semitones

   velocity - no boost or attenuation (64)
   pitchbend - no bend (MIDI_ZEROBEND -- see <midi/midi_types.h>)
   afterTouch - no attenuation (127)
   volume - no attenuation (127)
   modWheel - vibrato amplitude of svibAmp1 and frequency of svibFreq1 (127)

   wavelen - automatically-selected value
*/

/* The methods are all explained in the class description for SynthPatch */
+patchTemplateFor:currentNote;
-init;
-controllerValues:controllers;
-noteOnSelf:aNote;
-preemptFor:aNote;
-noteUpdateSelf:aNote;
-(double)noteOffSelf:aNote;
-noteEndSelf;

/* Private methods included here only for forward referencing. */ 
-_setDefaults;
-_updateParameters:aNote;

@end

