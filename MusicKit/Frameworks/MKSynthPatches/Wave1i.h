/*!
  @header Wave1i


<b>Wave1i</b> is a single-interpolating-oscillator wavetable SynthPatch with an amplitude and frequency envelope.  
<b>Wave1</b> (a subclass of <b>Wave1i</b>) is identical, but it uses a non-interpolating-oscillator (lower quality, but uses less DSP computation.)  <b>Wave1i</b> is used as the root class for a number of wavetable SynthPatches.

Here is a diagram of <b>Wave1</b>:

<img src="Images/Wave1i.gif"> .

When using this SynthPatch in an interactive real-time context, such as playing from a MIDI keyboard, call <b>MKUseRealTimeEnvelopes()</b> before allocating the SynthPatch.

<h2>Parameter Interpretation</h2>

<b>ampEnv</b> - Amplitude envelope.  Default is an envelope that is always a constant 1.0.

<b>amp</b> - Amplitude.  In the range 0.0:1.0.  amp1 is a synonym for amp.  Default is 0.1.

<b>amp0</b> - Amplitude when the envelope is at 0.0.  amp is amplitude when the envelope is at 1.0.  amp1 is a synonym for amp.  Default is 0.0.

<b>ampAtt</b> - Time of attack portion of envelope in seconds.  If this parameter is not present, the times in the envelope are used verbatim.

<b>ampRel</b> - Time of release portion of envelope in seconds. If this parameter is not present, the times in the envelope are used verbatim.

<b>bearing</b> - Left/right panning of signal.  In range -45.0:45.0.  -45.0 is far left.  Default is 0.0.

<b>controlChange</b> - This parameter is the MIDI controller number to be affected.  It is used in conjunction with the parameter controlVal, which provides the value the controller is set to.  This SynthPatch uses MIDI volume (controller 7) to adjust output volume as an attenuation of the final output signal.  The default for MIDI volume is 127.

<b>controlVal</b> - See controlChange.

<b>freq</b> - Frequency in Hz.  freq1 is a synonym for freq.  Default is A440.

<b>freqEnv</b> - Frequency envelope.  Default is an envelope that is always a constant 1.0.

<b>freq0</b> -Fundamental frequency when the envelope is at 0.  freq is frequency when the envelope is at 1.  freq1 is a synonym for freq.  Default is 0.0.

<b>freqAtt</b> -Time of attack portion of envelope in seconds.  If this parameter is not present, the times in the envelope are used verbatim.

<b>freqRel</b> -Time of release portion of envelope in seconds.  If this parameter is not present, the times in the envelope are used verbatim.

<b>keyNum</b> - The MIDI key number, an alternative to freq.  If both freq and keyNum are present, freq, takes precedence.  In the range 0:127.

<b>pitchBend</b> - Modifies frequency (or keyNum) as a 14 bit integer.  A value of MIDI_ZEROBEND (defined as 0x2000 in &lt;mididriver/midi_spec.h&gt;) gives no  bend.  0 is maximum negative bend.  0x3fff is maximum positive bend.  See TuningSystem class for details.  May give unexpected results when combined with frequency envelopes.  Default is MIDI_ZEROBEND.

<b>pitchBendSensitivity</b> - A value of 0.0 means pitchBend has no effect.  A value of 1.0 means pitch bend corresponds to plus or minus a semitone.  Larger values give larger pitch deviation.  Default is 3.0.

<b>portamento</b> - Portamento time.  In a phrase, the transition time to a note from the immediately preceding note.  Overrides the time values of the first segment of the envelopes.  Note that portamento is applied after the attack-time parameters.

<b>waveform</b> - WaveTable used for the oscillator (only the carrier, in the case of FM).  Defaults to sine.  Note that the WaveTable you supply is normalized so that its peak amplitude is 1.0.

<b>waveLen</b> - Length of wavetable.  Defaults to an optimal value. May only be set at the start of a phrase or with a noteUpdate that has no noteTag.

<b>phase</b> - Initial phase of wavetable in degrees.  Rarely needed.  Default is 0.0.

<b>velocity</b> - A MIDI parameter.  In range 0:127.  The default is 64.  Velocity scales amplitude by an amount deteremined by velocitySensitivity.  Some SynthPatches also scale brightness or FM index based on velocity.  

<b>velocitySensitivity</b> - In range 0.0:1.0.  Default is 0.5.  When velocitySensitivity is 0, velocity has no effect.


*/
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#import <MusicKit/MKSynthPatch.h>
#import <MusicKit/MKWaveTable.h>
#import <MusicKit/MKEnvelope.h>

@interface Wave1i:MKSynthPatch
{
    /* Instance variables for the parameters to which the MKSynthPatch 
       responds. */

    MKWaveTable *waveform;    /* Carrier waveform */

    MKEnvelope *ampEnv; /* Amplitude envelope. */ 
    double amp0;      /* Amplitude when ampEnv is at 0 */
    double amp1;      /* Amplitude when ampEnv is at 1 */
    double ampAtt;    /* ampEnv attack time or MK_NODVAL for 'not set'. */
    double ampRel;    /* ampEnv release time or MK_NODVAL for 'not set'. */

    MKEnvelope *freqEnv; /* Frequency envelope. */
    double freq0;     /* Frequency when freqEnv is at 0. */
    double freq1;     /* Frequency when freqEnv is at 1. */
    double freqAtt;   /* freqEnv attack time or MK_NODVAL for 'not set'. */
    double freqRel;   /* freqEnv release time or MK_NODVAL for 'not set'. */

    double bearing;   /* Left/right panning. -45 to 45. */

    double portamento;/* Transition time upon rearticulation, in seconds. */

    double phase;     /* Initial phase in degrees */

    double velocitySensitivity; /* Sensitivity to velocity. Scale of 0 to 1 */
    double pitchbendSensitivity; /* Sensitivity to pitchBend in semitones. */

    int velocity;     /* MIDI velocity. Boosts or attenuates amplitude. */
    int pitchbend;    /* MIDI pitchBend. Raises or lowers pitch. */
    int volume;       /* MIDI volume pedal. Anything less than full pedal 
			 functions as an attenuation. */

    int wavelen;      /* WaveTable size. Rarely needed. */
    void *_reservedWave1i;
}

/* Default parameter values, if corresponding parameter is omitted: 
   
   waveform - sine wave

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

   bearing - 0.0

   portamento - not set (use times specified in envelope directly)

   phase - 0.0 degrees

   velocitySensitivity - 0.5 of maximum
   pitchbendSensitivity - 3.0 semitones

   velocity - no boost or attenuation (64)
   pitchbend - no bend (MIDI_ZEROBEND -- see <midi/midi_types.h>)
   volume - no attenuation (127)

   wavelen - automatically-selected value
*/

/* The methods are all explained in the class description for MKSynthPatch */

/*!
  @method patchTemplateFor:
  @param aNote is a (id)
  @result A (id)
  @discussion Returns a default template. <i>aNote </i>is ignored.
*/
+patchTemplateFor:currentNote;
-init;
-controllerValues:controllers;

/*!
  @method noteOnSelf:
  @param aNote is a (id)
  @result A (id)
  @discussion <i>aNote</i> is assumed to be a noteOn or noteDur.  This method triggers (or retriggers) the Note's envelopes, if any.  If this is a new phrase, all instance variables are set to default values, then the values are read from the Note.  
*/
-noteOnSelf:aNote;

/*!
  @method preemptFor:
  @param aNote is a (id)
  @result A (id)
  @discussion Preempts envelope, if any.
*/
-preemptFor:aNote;

/*!
  @method noteUpdateSelf:
  @param aNote is a (id)
  @result A (id)
  @discussion <i>aNote</i> is assumed to be a noteUpdate and the receiver is assumed to be currently playing a Note.  Sets parameters as specified in <i>aNote.</i>
*/
-noteUpdateSelf:aNote;

/*!
  @method noteOffSelf:
  @param aNote is a (id)
  @result A (double)
  @discussion <i>aNote</i> is assumed to be a noteOff.  This method causes the Note's envelopes (if any) to begin its release portion and returns the time for the envelopes to finish.  Also sets any parameters present in <i>aNote.</i>
*/
-(double)noteOffSelf:aNote;

/*!
  @method noteEndSelf
  @result A (id)
  @discussion Resest instance variables to default values.
*/
-noteEndSelf;

@end
