/*!
  @header Shape


<b>Shape</b> is a single-lookup table non-linear distortion (waveshaping) SynthPatch.  It has an interpolating-oscillator for a "carrier" (oscillator driving the lookup) with an arbitrary waveform, an interpolating lookup table, and envelopes on amplitude (scaler on output), frequency, and waveshaping index (amplitude of carrier).  Additionally, 

For further information, see the LeBrun article sited below.   Other documentation includes <b>WaveShaping.math.ps</b> (or the similarly-named Mathematica files) in the folder <b>/LocalLibrary/Documentation/MusicKit+DSP/Music/Concepts/SpecialTopics/</b>

Note that the result of the usual envelope computation (val = m1IndEnv(time) * (m1Ind1 - m1Ind0) + m1Ind0) must be between 0.0 and 1.0, otherwise you will be reading values outside of the table.  Note also that m1IndEnv can have some small effect on amplitude, even though its primary purpose is to affect timbre.  (The smallness of the effect is achieved through the Le Brun "signification" algorithm.) 
	
Here is a diagram of <b>Shape:</b>
<img src="Images/Waveshape.gif"> 
If the <b>m1Waveform</b> parameter's value is a Partials object, it gives a specification for the harmonic structure of the lookup table.  For example, if you want the table to produce two harmonics, you could specify a Partials object with two partials, one at harmonic number 1 and one at harmonic number 2.  Note also that using higher numbered harmonics in a waveshaping table Partials object, results in a greater compute time to create the table.  If you specify a Samples object to <b>m1Waveform</b>, it is used directly as the distortion lookup table.   
 
 Additional features that ambitious users might want to consider adding include doing some of the other things that Arfib, LeBrun, and Beauchamp described in their articles:

        1- adding a post-lookup multiplication with a sinusoid, to
                obtain symmetric Spectra, and with proper choice of the 
                multiplying sine's frequency, inharmonic to obtain bell-like
                sounds. (see LeBrun; Arfib)
        2- Double Modulation (See Arfib)
        3- adding a filter after the table-lookup. (See Beauchamp)

When using this SynthPatch in an interactive real-time context, such as playing from a MIDI keyboard, call <b>MKUseRealTimeEnvelopes()</b> before allocating the SynthPatch.

For more Information:

Arfib, D. 1979. "Digital Waveshaping Synthesis of complex spectra by
     means of multiplication of nonlinear distorted sine waves."
     Journal of the Audio Engineering Society 27(10): 757-768.
Beauchamp, J. 1979. "Brass Tone Synthesis by Spectrum Evolution Matching
     with Nonlinear Functions." Computer Music Journal 3(2): 35-43.
    (Available in: Foundations of Computer Music, Curtis Roads and John
     Strawn, eds. The MIT Press, Cambridge, MA. 1985.)
LeBrun, M. 1979. "Digital WaveShaping Synthesis." Journal of the Audio
     Engineering Society 27(4): 250-266.
Moore, F. R. 1990. Elements of Computer Music. Prentice Hall, Englewood
     Cliffs, NJ.
Roads, C. 1979. "A Tutorial on Nonlinear Distortion or Waveshaping Synthesis."
     Computer Music Journal 3(2): 29-34. (Also available in the Roads
     and Strawn book.)

<h2>Parameter Interpretation</h2>

<b>ampEnv</b> - Amplitude envelope.  Default is an envelope that is always a constant 1.0.

<b>amp</b> - Amplitude.  In the range 0.0:1.0.  amp1 is a synonym for amp.  Default is 0.1.

<b>amp0</b> - Amplitude when the envelope is at 0.0.  amp is amplitude when the envelope is at 1.0.  amp1 is a synonym for amp.  Default is 0.0.

<b>ampAtt</b> - Time of attack portion of envelope in seconds.  If this parameter is not present, the times in the envelope are used verbatim.

<b>ampRel</b> - Time of release portion of envelope in seconds. If this parameter is not present, the times in the envelope are used verbatim.

<b>bearing</b> - Left/right panning of signal.  In range -45.0:45.0.  -45.0 is far left.  Default is 0.0.

<b>bright</b> - Brightness, a multiplier on index.  Defaults to 1.0.

<b>controlChange</b> - This parameter is the MIDI controller number to be affected.  It is used in conjunction with the parameter controlVal, which provides the value the controller is set to.  This SynthPatch uses MIDI volume (controller 7) to adjust output volume as an attenuation of the final output signal.  The default for MIDI volume is 127.

<b>controlVal</b> - See controlChange.

<b>freq</b> - Frequency in Hz.  freq1 is a synonym for freq.  Default is A440.

<b>freqEnv</b> - Frequency envelope.  Default is an envelope that is always a constant 1.0.

<b>freq0</b> -Fundamental frequency when the envelope is at 0.  freq is frequency when the envelope is at 1.  freq1 is a synonym for freq.  Default is 0.0.

<b>freqAtt</b> -Time of attack portion of envelope in seconds.  If this parameter is not present, the times in the envelope are used verbatim.

<b>freqRel</b> -Time of release portion of envelope in seconds.  If this parameter is not present, the times in the envelope are used verbatim.

<b>keyNum</b> - The MIDI key number, an alternative to freq.  If both freq and keyNum are present, freq, takes precedence.  In the range 0:127.

<b>m1Ind</b> - Modulation index.  If an envelope, is specified, this is the index when the envelope is at 1.  <b>m1Ind1</b> is synonym for <b>m1Ind</b>.  Default is 1.0.

<b>m1IndEnv</b> - Modulation index envelope.  Default is a constant value of 1.0.

<b>m1Ind0</b> - Modulation index when envelope is at 0.0.  <b>m1Ind</b> is index when envelope is at 1.0.  Default is 0.0.

<b>m1IndAtt</b> -Time of attack portion of envelope in seconds.  If this parameter is not present, the times in the envelope are used verbatim.

<b>m1IndRel</b> - Time of release portion of envelope in seconds.  If this parameter is not present, the times in the envelope are used verbatim.

<b>m1Waveform</b> - Modulator wave table.  Default produces a sine wave.  See comments above.

<b>phase</b> - Initial phase of wavetable in degrees.  Rarely needed.  Default is 0.0.

<b>pitchBend</b> - Modifies frequency (or keyNum) as a 14 bit integer.  A value of MIDI_ZEROBEND (defined as 0x2000 in &lt;mididriver/midi_spec.h&gt;) gives no  bend.  0 is maximum negative bend.  0x3fff is maximum positive bend.  See TuningSystem class for details.  May give unexpected results when combined with frequency envelopes.  Default is MIDI_ZEROBEND.

<b>portamento</b> - Portamento time.  In a phrase, the transition time to a note from the immediately preceding note.  Overrides the time values of the first segment of the envelopes.  Note that portamento is applied after the attack-time parameters.

<b>velocity</b> - A MIDI parameter.  In range 0:127.  The default is 64.  Velocity scales amplitude by an amount deteremined by velocitySensitivity.  Some SynthPatches also scale brightness or FM index based on velocity.  

<b>velocitySensitivity</b> - In range 0.0:1.0.  Default is 0.5.  When velocitySensitivity is 0, velocity has no effect.

<b>pitchBendSensitivity</b> - A value of 0.0 means pitchBend has no effect.  A value of 1.0 means pitch bend corresponds to plus or minus a semitone.  Larger values give larger pitch deviation.  Default is 3.0.

<b>waveform</b> - WaveTable used for the oscillator.  Defaults to sine.  Note that the WaveTable you supply is normalized so that its peak amplitude is 1.0.

<b>waveLen</b> - Length of wavetable.  Defaults to an optimal value.  May only be set at the start of a phrase or with a noteUpdate that has no noteTag.


*/
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


/*!
  @method patchTemplateFor:
  @param aNote is a (id)
  @result A (id)
  @discussion Returns a default template. <i>aNote </i>is ignored.
*/
+ patchTemplateFor:aNote;

/*!
  @method noteOnSelf:
  @param aNote is a (id)
  @result A (id)
  @discussion <i>aNote</i> is assumed to be a noteOn or noteDur.  This method triggers (or retriggers) the Note's envelopes, if any.  If this is a new phrase, all instance variables are set to default values, then the values are read from the Note.  
*/
- noteOnSelf:aNote;

/*!
  @method noteUpdateSelf:
  @param aNote is a (id)
  @result A (id)
  @discussion <i>aNote</i> is assumed to be a noteUpdate and the receiver is assumed to be currently playing a Note.  Sets parameters as specified in <i>aNote.</i>
*/
- noteUpdateSelf:aNote;

/*!
  @method noteOffSelf:
  @param aNote is a (id)
  @result A (double)
  @discussion <i>aNote</i> is assumed to be a noteOff.  This method causes the Note's envelopes (if any) to begin its release portion and returns the time for the envelopes to finish.  Also sets any parameters present in <i>aNote.</i>
*/
- (double)noteOffSelf:aNote;

/*!
  @method noteEndSelf
  @result A (id)
  @discussion Resest instance variables to default values.
*/
- noteEndSelf;

/*!
  @method preemptFor:
  @param aNote is a (id)
  @result A (id)
  @discussion Preempts envelope, if any.
*/
- preemptFor:aNote;
- init;

/* These methods are used by the subclass */
-_setDefaults;
-_initUGvars;
- _applyParameters:aNote;

@end

#endif
