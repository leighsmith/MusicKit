/*!
  @header DBWave2vi


<b>DBWave2vi</b> is a double interpolating oscillator wavetable synthesis SynthPatch with dynamic envelope-driven interpolation between the two oscillators, amplitude and frequency envelopes.    It supports the Timbre Data Base (see <b>TimbreDataBase.rtf.</b>)

Although <b>DBWave2vi</b> does not inherit from any other wavetable synthesis class, it is similar to <b>DBWave1vi</b>, except that there are two oscillators doing the synthesis.  

<img src="Images/Wave2vi.gif"> 
When using this SynthPatch in an interactive real-time context, such as playing from a MIDI keyboard, call <b>MKUseRealTimeEnvelopes()</b> before allocating the SynthPatch.

<h2>Parameter Interpretation</h2>

In addition to the parameters described in <b>Wave1vi.rtfd</b>, the following parameters are supported:

<b>controlChange</b> - MIDI pan (controller 10) has the same effect as <b>bearing</b>.  If the <b>panSensitivity</b> is 1.0, a MIDI pan value of  0 is full left and 127 is full right.  If the value of  <b>panSensitivity</b> is less than 1.0, the pan range is narrowed toward the center.  The value is set by the companion parameter, <b>controlVal</b>.  

<b>controlVal</b> - See controlChange.

<b>panSensitivity -</b> In the range 0.0:1.0.  Default is 1.0.

<b>waveformEnv</b>  - wavetable cross-fading envelope

<b>waveform0</b> - The waveform when waveformEnv is 0.  Defaults to sine 

<b>waveform1</b> - The waveform when waveformEnv is 1.  Defaults to sine 

<b>waveformAtt</b> - Waveform envelope attack time.

<b>waveformRel</b> - Waveform envelope balance release time.  


*/
#ifndef __MK_DBWave2vi_H___
#define __MK_DBWave2vi_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* 
	DBWave2vi.h 

	This class is part of the Music Kit MKSynthPatch Library.
*/
#import <MusicKit/MKSynthPatch.h>
@interface DBWave2vi:MKSynthPatch

{
  double amp0, amp1, ampAtt, ampRel, freq0, freq1, freqAtt, freqRel,
         bearing, phase, portamento, svibAmp0, svibAmp1, rvibAmp,
         svibFreq0, svibFreq1, velocitySensitivity, panSensitivity,
         waveformAtt, waveformRel, pitchbendSensitivity;
  id ampEnv, freqEnv, waveform0, waveform1, waveformEnv;
  int wavelen, volume, velocity, modwheel, pan, pitchbend;
  void *_ugNums;
}


/*!
  @method patchTemplateFor:
  @param aNote is a (id)
  @result A (id)
  @discussion Returns a template. A non-zero for <b>svibAmp</b>and <b>rvibAmp </b> determines whether vibrato resources are allocated. 
*/
+patchTemplateFor:aNote;
   


/*!
  @method noteOnSelf:
  @param aNote is a (id)
  @result A (id)
  @discussion <i>aNote</i> is assumed to be a noteOn or noteDur.  This method triggers (or retriggers) the Note's envelopes, if any.  If this is a new phrase, all instance variables are set to default values, then the values are read from the Note.  
*/
-noteOnSelf:aNote;
 


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

#endif
