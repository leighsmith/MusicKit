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
  Revision 1.3  2001/09/10 17:38:28  leighsmith
  Added abstracts from IntroSynthPatches.rtf

  Revision 1.2  2001/09/08 20:22:09  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

*/
//  classgroup WaveTable Synthesis
/*!
  @class Simp
  @abstract Single-oscillator wavetable producing periodic waveforms using a non-interpolating
            oscillator.   
  @discussion

<b>Simp</b> is a single-oscillator wavetable MKSynthPatch, capable of producing
any periodic waveform.   It is the simplest of the Music Kit MKSynthPatches.    It
uses a non-interpolating oscillator, which means it is not particularly high
quality.   

For most musical applications, it is preferable to use <b>Wave1</b> or
<b>Wave1i</b>, both of which feature amplitude and frequency
envelopes.

When using this MKSynthPatch in an interactive real-time context, such as playing
from a MIDI keyboard, call <b>MKUseRealTimeEnvelopes()</b> before allocating the
MKSynthPatch.

<h2>Parameter Interpretation</h2>

<b>amp</b> - Amplitude.  In the range 0.0:1.0.  amp1 is a synonym for amp. 
Default is 0.1.

<b>bearing</b> - Left/right panning of signal.  In range -45.0:45.0. -45.0 is
far left.  Default is 0.0.

<b>controlChange</b> - This parameter is the MIDI controller number to be
affected.  It is used in conjunction with the parameter controlVal, which
provides the value the controller is set to.  This MKSynthPatch uses MIDI volume
(controller 7) to adjust output volume as an attenuation of the final output
signal.  The default for MIDI volume is 127.

<b>controlVal</b> - See controlChange.

<b>freq</b> - Frequency in Hz.  freq1 is a synonym for freq.  Default is
A440.

<b>keyNum</b> - The MIDI key number, an alternative to freq.  If both freq and
keyNum are present, freq, takes precedence.  In the range 0:127.

<b>pitchBend</b> - Modifies frequency (or keyNum) as a 14 bit integer.  A value
of MIDI_ZEROBEND (defined as 0x2000 in &lt;mididriver/midi_spec.h&gt;) gives no 
bend.  0 is maximum negative bend.  0x3fff is maximum positive bend.  See
TuningSystem class for details.  Default is MIDI_ZEROBEND.

<b>pitchBendSensitivity</b> - A value of 0.0 means pitchBend has no effect.  A
value of 1.0 means pitch bend corresponds to plus or minus a semitone.  Larger
values give larger pitch deviation.  Default is 3.0.

<b>waveform</b> - WaveTable used for the oscillator (only the carrier, in the
case of FM).  Defaults to sine.  Note that the WaveTable you supply is
normalized so that its peak amplitude is 1.0.

<b>waveLen</b> - Length of wavetable.  Defaults to an optimal value.  May only
be set at the start of a phrase or with a noteUpdate that has no
noteTag.

<b>phase</b> - Initial phase of wavetable in degrees.  Rarely needed.  Default
is 0.0.

<b>velocity</b> - A MIDI parameter.  In range 0:127.  The default is 64. 
Velocity scales amplitude by an amount deteremined by velocitySensitivity. 


<b>velocitySensitivity</b> - In range 0.0:1.0.  Default is 0.5.  When
velocitySensitivity is 0, velocity has no effect.
*/
#ifndef __MK_Simp_H___
#define __MK_Simp_H___

#import <MusicKit/MKSynthPatch.h>

@interface Simp:MKSynthPatch
{
  double amp, freq, bearing, phase, velocitySensitivity;
  id waveform;
  int wavelen, volume, velocity;
  int pitchbend;
  double pitchbendSensitivity;  
}

/*!
  @method patchTemplateFor:
  @param  aNote is an id.
  @result Returns an id.
  @discussion Returns a default template. <i>aNote</i> is ignored.
*/
+patchTemplateFor:aNote;
 
/*!
  @method noteOnSelf:
  @param  aNote is an id.
  @result Returns an id.
  @discussion <i>aNote</i> is assumed to be a noteOn or noteDur.  If this is a new
              phrase, all instance variables are set to default values, then the
              values are read from the MKNote.  
*/
-noteOnSelf:aNote;
 
/*!
  @method noteUpdateSelf:
  @param  aNote is an id.
  @result Returns an id.
  @discussion <i>aNote</i> is assumed to be a noteUpdate and the receiver is
              assumed to be currently playing a MKNote.  Sets parameters as
              specified in <i>aNote</i>.
*/
-noteUpdateSelf:aNote;
 
/*!
  @method noteOffSelf:
  @param  aNote is an id.
  @result Returns a double.
  @discussion <i>aNote</i> is assumed to be a noteOff.  Finishes the note
              immediately.
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
