/*!
  @header Fm2cvi


<b>Fm2cvi</b> is a cascade-modulator frequency modulation SynthPatch, with an interpolating-oscillator as a carrier.  It provides for envelopes on amplitude, frequency, and a separate envelope on each modulator's FM index.  It also supports vibrato.   Although it does not inherit from <b>Fm1vi</b>, it implements the same parameters, plus some of its own. 

When using this SynthPatch in an interactive real-time context, such as playing from a MIDI keyboard, call <b>MKUseRealTimeEnvelopes()</b> before allocating the SynthPatch.

<img src="Images/Fm2cvi.gif"> 
<h2>Parameter Interpretation</h2>

In addition to the parameters described in <b>Fm11vi.rtfd</b>, the following parameters are supported:

<b>afterTouch -</b>Note that <b>afterTouch</b>  applies here only to the cascade modulator's index.

<b>controlChange</b> -  MIDI pan (controller 10) has the same effect as <b>bearing</b>.  If the <b>panSensitivity</b> is 1.0, a MIDI pan value of  0 is full left and 127 is full right.  If the value of  <b>panSensitivity</b> is less than 1.0, the pan range is narrowed toward the center.  The value is set by the companion parameter, <b>controlVal</b>.  

<b>controlVal</b> - See controlChange.

<b>m2Ratio</b> - Scaler on second modulator frequency.  Defaults to 2 for Fm2cvi and Fm2cnvi.  Defaults to 1.  The resulting modulator frequency is the value of <b>m2Ratio</b> multiplied by the freq parameter.

<b>m2Ind</b> - Index of 2nd modulator.  If there's an envelope on the index of the 2nd modulator, this is the index when the envelope is at 1.  <b>m2Ind1</b> is synonym for <b>m2Ind</b>.  

<b>m2IndEnv</b> - Frequency modulation index envelope for the second modulator.  

<b>m2Ind0</b> - Modulation index for the second modulator when envelope is at 0.  m2Ind is the index when envelope is at 1.

<b>m2IndAtt</b> - Time of attack portion of second modulator index envelope in seconds.  If this parameter is not present, the times in the envelope are used verbatim.

<b>m2IndRel</b> - Time of release portion of second modulator index envelope in seconds.  If this parameter is not present, the times in the envelope are used verbatim.

<b>m2Waveform</b> - Second modulator WaveTable.  Defaults to sine.

<b>m2Phase</b> - Initial phase in degrees of modulator wavetable.  Rarely needed.  Defaults to 0.0.

<b>panSensitivity -</b> In the range 0.0:1.0.  Default is 1.0.

<b>velocity -</b> In addition to the usual amplitude scaling, velocity scales the strength of  the FM modulation.  The default velocity (64) has no effect on FM index.  


*/
#ifndef __MK_Fm2cvi_H___
#define __MK_Fm2cvi_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* 
	Fm2cvi.h 

	This class is part of the Music Kit MKSynthPatch Library.
*/
#import <MusicKit/MKSynthPatch.h>
@interface Fm2cvi:MKSynthPatch
{
  double amp0, amp1, ampAtt, ampRel, freq0, freq1, freqAtt, freqRel,
         bearing, phase, portamento, svibAmp0, svibAmp1, rvibAmp,
         svibFreq0, svibFreq1, bright, cRatio,
         m1Ratio, m1Ind0, m1Ind1, m1IndAtt, m1IndRel, m1Phase,
         m2Ratio, m2Ind0, m2Ind1, m2IndAtt, m2IndRel, m2Phase,
         velocitySensitivity, panSensitivity, afterTouchSensitivity, 
         pitchbendSensitivity;
  id ampEnv, freqEnv, m1IndEnv, m2IndEnv, waveform, m1Waveform, m2Waveform;
  int wavelen, volume, velocity, pan, modulation, aftertouch, pitchbend;
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
