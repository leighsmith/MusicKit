/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    (See discussion below)

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.2  2001/09/08 20:22:09  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

*/
/*!
  @class Fm1i
  @abstract Fm1i is a frequency modulation MKSynthPatch with arbitrary waveforms for
            carrier and modulator and an interpolating oscillator for the carrier. 
  @discussion


<b>Fm1i</b> is an FM (frequency modulation) MKSynthPatch that uses an
arbitrary-wavetable oscillator to modulate the frequency of another
arbitrary-wavetable oscillator.  <b>Fm1i</b> uses an interpolating oscillator
for the carrier, while <b>Fm1</b> uses a non-interpolating oscillator (lower
quality, but uses less DSP computation.) 
<b>Fm1i</b> is used as the root class for a number of FM MKSynthPatches.
It supports a wide variety of parameters, including many MIDI parameters.
It supports a wide variety of parameters, including many MIDI parameters.

See the FM literature for details of FM synthesis.                       
(Note that the implementation here is "frequency modulation" rather than 
"phase modulation" and that the deviation scaling does not follow the    
frequency envelope -- it is exactly as defined in the literature only    
when the frequency envelope is at 1.                                     

When using this MKSynthPatch in an interactive real-time context, such as playing
from a MIDI keyboard, call <b>MKUseRealTimeEnvelopes()</b> before allocating the
MKSynthPatch.

<h2>Parameter Interpretation</h2>

<b>afterTouch</b> - MIDI afterTouch (also called channel pressure) attenuates
the  amount of frequency modulation.  In the range 0:127.  A value of 127 (the
default) produces no attenuation.

<b>afterTouchSensitivity</b> - Controls the amount of attenuation caused by
afterTouch.  If afterTouchSensitivity is 1.0 and afterTouch is 0, modulation is
0.  If afterTouchSensitivity is .5 and afterTouch is 0, modulation is half the
normal amount.  Default sensitivity is 0.5.  

<b>ampEnv</b> - Amplitude envelope.  Default is an envelope that is always a
constant 1.0.

<b>amp</b> - Amplitude.  In the range 0.0:1.0.  amp1 is a synonym for amp. 
Default is 0.1.

<b>amp0</b> - Amplitude when the envelope is at 0.0.  amp is amplitude when the
envelope is at 1.0.  amp1 is a synonym for amp.  Default is 0.0.

<b>ampAtt</b> - Time of attack portion of envelope in seconds.  If this
parameter is not present, the times in the envelope are used
verbatim.

<b>ampRel</b> - Time of release portion of envelope in seconds.  If this
parameter is not present, the times in the envelope are used
verbatim.

<b>bearing</b> - Left/right panning of signal.  In range -45.0:45.0.  -45.0 is
far left.  Default is 0.0.

<b>bright</b> - Brightness, a multiplier on fm index.  Defaults to
1.0.

<b>controlChange</b> - This parameter is the MIDI controller number to be
affected.  It is used in conjunction with the parameter controlVal, which
provides the value the controller is set to.  This SynthPatch uses MIDI volume
(controller 7) to adjust output volume as an attenuation of the final output
signal.  The default for MIDI volume is 127.

<b>controlVal</b> - See controlChange.

<b>cRatio</b> - Carrier frequency scaler.  The resulting carrier frequency is
cRatio multiplied by the freq parameter (or the frequency derived from the
keyNum parameter).  c1Ratio is a synonym.  Default is 1.0.

<b>freq</b> - Frequency in Hz.  freq1 is a synonym for freq.  Default is
A440.

<b>freqEnv</b> - Frequency envelope.  Default is an envelope that is always a
constant 1.0.

<b>freq0</b> - Fundamental frequency when the envelope is at 0.  freq is
frequency when the envelope is at 1.  freq1 is a synonym for freq.  Default is
0.0.

<b>freqAtt</b> - Time of attack portion of envelope in seconds.  If this
parameter is not present, the times in the envelope are used
verbatim.

<b>freqRel</b> - Time of release portion of envelope in seconds.  If this
parameter is not present, the times in the envelope are used
verbatim.

<b>keyNum</b> - The MIDI key number, an alternative to freq.  If both freq and
keyNum are present, freq, takes precedence.  In the range 0:127.

<b>m1Ind</b> - Modulation index.  If an envelope, is specified, this is the
index when the envelope is at 1.  <b>m1Ind1</b> is synonym for <b>m1Ind</b>. 
Default is 2.0.

<b>m1IndEnv</b> - Modulation index envelope.  Default is a constant value of
1.0.

<b>m1Ind0</b> - Modulation index when envelope is at 0.0.  <b>m1Ind</b> is index
when envelope is at 1.0.  Default is 0.0.

<b>m1IndAtt</b> -Time of attack portion of envelope in seconds.  If this
parameter is not present, the times in the envelope are used
verbatim.

<b>m1IndRel</b> - Time of release portion of envelope in seconds.  If this
parameter is not present, the times in the envelope are used
verbatim.

<b>m1Ratio</b> - Modulator frequency scaler.  The resulting modulator frequency
is m1Ratio multiplied by the freq parameter.  Default is 1.0.

<b>m1Phase</b> - Initial phase in degrees of modulator wavetable.  Rarely
needed.  Default is 0.0.

<b>m1Waveform</b> - Modulator wave table. Default produces a sine wave.   If you
specify a Samples object to an FM SynthPatch, the length may be any power of
2.

<b>phase</b> - Initial phase of wavetable in degrees.  Rarely needed.  Default
is 0.0.

<b>pitchBend</b> - Modifies frequency (or keyNum) as a 14 bit integer.  A value
of MIDI_ZEROBEND (defined as 0x2000 in &lt;mididriver/midi_spec.h&gt;) gives no 
bend.  0 is maximum negative bend.  0x3fff is maximum positive bend.  See
TuningSystem class for details.  May give unexpected results when combined with
frequency envelopes.  Default is MIDI_ZEROBEND.

<b>portamento</b> - Portamento time.  In a phrase, the transition time to a note
from the immediately preceding note.  Overrides the time values of the first
segment of the envelopes.  Note that portamento is applied after the attack-time
parameters.

<b>velocity</b> - A MIDI parameter.  In range 0:127.  The default is 64. 
Velocity scales amplitude by an amount deteremined by velocitySensitivity.  Some
SynthPatches also scale brightness or FM index based on velocity. 

<b>velocitySensitivity</b> - In range 0.0:1.0.  Default is 0.5.  When
velocitySensitivity is 0, velocity has no effect.
<b>pitchBendSensitivity</b> - A value of 0.0 means pitchBend has no effect.  A
value of 1.0 means pitch bend corresponds to plus or minus a semitone.  Larger
values give larger pitch deviation.  Default is 3.0.

<b>waveform</b> - WaveTable used for the oscillator (only the carrier, in the
case of FM).  Defaults to sine.  Note that the WaveTable you supply is
normalized so that its peak amplitude is 1.0.

<b>waveLen</b> - Length of wavetable.  Defaults to an optimal value.  May only
be set at the start of a phrase or with a noteUpdate that has no
noteTag.
*/
#ifndef __MK_Fm1i_H___
#define __MK_Fm1i_H___

#import <MusicKit/MKSynthPatch.h>
#import <MusicKit/MKEnvelope.h>
#import <MusicKit/MKWaveTable.h>

@interface Fm1i:MKSynthPatch
{
    /* Instance variables for the parameters to which the MKSynthPatch 
       responds. */

    MKWaveTable *waveform;    /* Carrier waveform */
    MKWaveTable *m1Waveform;  /* Modulator waveform */

    double cRatio;    /* Carrier frequency scaler. */
    double m1Ratio;   /* Modulater frequency scaler. */

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

    MKEnvelope *m1IndEnv;/* FM index envelope */
    double m1Ind0;    /* FM index when m1IndEnv is at 0 */
    double m1Ind1;    /* FM index when m1IndEnv is at 1 */
    double m1IndAtt;  /* m1IndEnv attack time or MK_NODVAL for 'not set'. */
    double m1IndRel;  /* m1IndEnv release time or MK_NODVAL for 'not set'. */

    double bright;    /* Brightness. A multiplier on index. */

    double bearing;   /* Left/right panning. -45 to 45. */

    double portamento;/* Transition time upon rearticulation, in seconds. */

    double phase;     /* Initial phase in degrees */
    double m1Phase;   /* Initial modulator phase in degrees */

    double velocitySensitivity; /* Sensitivity to velocity. Scale of 0 to 1 */
    double afterTouchSensitivity;/* Sensitivity to afterTouch. 0 to 1. */
    double pitchbendSensitivity; /* Sensitivity to pitchBend in semitones. */

    int velocity;     /* MIDI velocity. Boosts or attenuates amplitude. */
    int pitchbend;    /* MIDI pitchBend. Raises or lowers pitch. */
    int afterTouch;   /* MIDI afterTouch. Anything less than full after touch 
			 functions as an attenuation. */
    int volume;       /* MIDI volume pedal. Anything less than full pedal 
			 functions as an attenuation. */

    int wavelen;      /* WaveTable size. Rarely needed. */
    void *_reservedFm1i;
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

   phase - 0.0 deg
   m1Phase - 0.0 deg

   velocitySensitivity - 0.5 of maximum
   afterTouchSensitivity - 0.5 of maximum
   pitchbendSensitivity - 3.0 semitones

   velocity - no boost or attenuation (64)
   pitchbend - no bend (MIDI_ZEROBEND -- see <midi/midi_types.h>)
   afterTouch - no attenuation (127)
   volume - no attenuation (127)

   wavelen - automatically-selected value
*/

/* The methods are all explained in the class description for MKSynthPatch */

/*!
  @method patchTemplateFor:
  @param  aNote is an id.
  @result Returns an id.
  @discussion Returns a default template. <i>aNote </i>is ignored.
*/
+patchTemplateFor:currentNote;
-init;
-controllerValues:controllers;

/*!
  @method noteOnSelf:
  @param  aNote is an id.
  @result Returns an id.
  @discussion <i>aNote</i> is assumed to be a noteOn or noteDur.  This method
              triggers (or retriggers) the Note's envelopes, if any.  If this is a
              new phrase, all instance variables are set to default values, then
              the values are read from the Note.  
*/
-noteOnSelf:aNote;

/*!
  @method preemptFor:
  @param  aNote is an id.
  @result Returns an id.
  @discussion Preempts envelope, if any.
*/
-preemptFor:aNote;

/*!
  @method noteUpdateSelf:
  @param  aNote is an id.
  @result Returns an id.
  @discussion <i>aNote</i> is assumed to be a noteUpdate and the receiver is
              assumed to be currently playing a Note.  Sets parameters as
              specified in <i>aNote.</i>
*/
-noteUpdateSelf:aNote;

/*!
  @method noteOffSelf:
  @param  aNote is an id.
  @result Returns a double.
  @discussion <i>aNote</i> is assumed to be a noteOff.  This method causes the
              Note's envelopes (if any) to begin its release portion and returns
              the time for the envelopes to finish.  Also sets any parameters
              present in <i>aNote.</i>
*/
-(double)noteOffSelf:aNote;

/*!
  @method noteEndSelf
  @result Returns an id.
  @discussion Resest instance variables to default values.
*/
-noteEndSelf;

@end

#endif
