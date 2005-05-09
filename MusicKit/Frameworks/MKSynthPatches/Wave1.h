/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    This class is just like Wave1i but overrides the interpolating osc
    with a non-interpolating osc. Thus, it is slightly less expensive than
    Wave1i (See discussion below).

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.6  2005/05/09 15:27:44  leighsmith
  Converted headerdoc comments to doxygen comments

  Revision 1.5  2001/11/16 20:37:51  leighsmith
  Made images use musickit.org URL since it will be too difficult to place the image into the generated class documentation directory and too location specific to specify relative URLs to images

  Revision 1.4  2001/09/10 17:38:28  leighsmith
  Added abstracts from IntroSynthPatches.rtf

  Revision 1.3  2001/09/08 20:22:09  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

*/
//  classgroup WaveTable Synthesis
/*!
  @class Wave1
  @brief Wavetable synthesis with 1 non-interpolating (drop-sample) oscillator.
  
  

<b>Wave1i</b> is a single-interpolating-oscillator wavetable MKSynthPatch with an amplitude and frequency envelope.  
<b>Wave1</b> (a subclass of <b>Wave1i</b>) is identical, but it uses a non-interpolating-oscillator (lower quality, but uses less DSP computation.)  <b>Wave1i</b> is used as the root class for a number of wavetable MKSynthPatches.

Here is a diagram of <b>Wave1</b>:

<img src="http://www.musickit.org/Frameworks/MKSynthPatches/Images/Wave1i.png"> .

When using this MKSynthPatch in an interactive real-time context, such as playing from a MIDI keyboard, call <b>MKUseRealTimeEnvelopes()</b> before allocating the MKSynthPatch.

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

<b>freq0</b> - Fundamental frequency when the envelope is at 0.  freq is frequency when the envelope is at 1.  freq1 is a synonym for freq.  Default is 0.0.

<b>freqAtt</b> - Time of attack portion of envelope in seconds.  If this parameter is not present, the times in the envelope are used verbatim.

<b>freqRel</b> - Time of release portion of envelope in seconds.  If this parameter is not present, the times in the envelope are used verbatim.

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
#ifndef __MK_Wave1_H___
#define __MK_Wave1_H___

#import "Wave1i.h"

@interface Wave1:Wave1i
{
}

/*!
  @param aNote is a (id)
  @return A (id)
  @brief Returns a template using the non-interpolating osc.

  <i>aNote </i>is ignored.
*/
+patchTemplateFor:aNote;

@end

#endif
