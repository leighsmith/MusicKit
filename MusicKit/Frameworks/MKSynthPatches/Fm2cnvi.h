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
  Revision 1.5  2001/11/16 20:37:51  leighsmith
  Made images use musickit.org URL since it will be too difficult to place the image into the generated class documentation directory and too location specific to specify relative URLs to images

  Revision 1.4  2001/09/10 17:38:28  leighsmith
  Added abstracts from IntroSynthPatches.rtf

  Revision 1.3  2001/09/08 20:22:09  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

*/
//  classgroup Frequency Modulation Synthesis
/*!
  @class Fm2cnvi
  @abstract Like <b>Fm2cvi</b>, but with an additional noise modulator.
  @discussion

<b>Fm2cnvi</b> is a cascade-modulator frequency modulation MKSynthPatch, with an interpolating-oscillator as a carrier and a noise source modulating the frequency of the two wavetable modulators.  It provides for envelopes on amplitude, frequency, and a separate envelope on each modulator's FM index, as well as an envvelope on the noise source.  It also supports vibrato.   Although it does not inherit from <b>Fm2cvi</b>, it implements the same parameters, plus some of its own. 

<img src="http://www.musickit.org/Frameworks/MKSynthPatches/Images/FM2cnvi.png">

When using this MKSynthPatch in an interactive real-time context, such as playing from a MIDI keyboard, call <b>MKUseRealTimeEnvelopes()</b> before allocating the MKSynthPatch.

<h2>Parameter Interpretation</h2>

In addition to the parameters described in <b>Fm2cvi.rtfd</b>, the following parameters are supported:

<b>breathSensitivity</b> - Controls how much affect the breath controller has.  Default is 0.5.

<b>controlChange</b> -  MIDI breath controller (controller 2) attenuates the output of  the noise modulator.  The value is obtained from companion parameter, controlVal.  The range is 0:127 and the default is 127, indicating no attenuation.  The effect of this parameter depends on the parameter breathSensitivity.

<b>controlVal</b> - See controlChange

<b>noiseAmp</b> - Amplitude of noise modulator.  If a noise amplitude envelope is provided, this is the amplitude of the noise when the envelope is 1.  noiseAmp1 is a synonym for the parameter noiseAmp.  Default is 0.007.

<b>noiseAmpEnv</b> - Noise amplitude envelope.  Default is a constant value of 1.0.

<b>noiseAmp0</b> - Noise amplitude when noise envelope is at 0.0.  noiseAmp is the value when the noise envelope is at 1.0.  Default is 0.0.

<b>noiseAmpAtt</b> - Time of attack portion of noise envelope in seconds.  If this parameter is not present, the times in the envelope are used verbatim.

<b>noiseAmpRel</b> - Time of release portion of noise envelope in seconds.  If this parameter is not present, the times in the envelope are used verbatim.
*/
#ifndef __MK_Fm2cnvi_H___
#define __MK_Fm2cnvi_H___

#import <MusicKit/MKSynthPatch.h>

@interface Fm2cnvi:MKSynthPatch
{
  double amp0, amp1, ampAtt, ampRel, freq0, freq1, freqAtt, freqRel,
         bearing, phase, portamento, svibAmp0, svibAmp1, rvibAmp,
         svibFreq0, svibFreq1, bright, cRatio,
         m1Ratio, m1Ind0, m1Ind1, m1IndAtt, m1IndRel, m1Phase,
         m2Ratio, m2Ind0, m2Ind1, m2IndAtt, m2IndRel, m2Phase,
         noise0, noise1, noiseAtt, noiseRel,
         velocitySensitivity, breathSensitivity,
         panSensitivity, afterTouchSensitivity, pitchbendSensitivity;
  id ampEnv, freqEnv, m1IndEnv, m2IndEnv, noiseEnv,
     waveform, m1Waveform, m2Waveform;
  int wavelen, volume, velocity, pan, modulation, breath, aftertouch, pitchbend;
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
  @discussion <i>aNote</i> is assumed to be a noteOn or noteDur.  This method triggers (or retriggers) the MKNote's envelopes, if any.  If this is a new phrase, all instance variables are set to default values, then the values are read from the MKNote.  
*/
-noteOnSelf:aNote;

/*!
  @method noteUpdateSelf:
  @param aNote is a (id)
  @result A (id)
  @discussion <i>aNote</i> is assumed to be a noteUpdate and the receiver is assumed to be currently playing a MKNote.  Sets parameters as specified in <i>aNote.</i>
*/
-noteUpdateSelf:aNote;

/*!
  @method noteOffSelf:
  @param aNote is a (id)
  @result A (double)
  @discussion <i>aNote</i> is assumed to be a noteOff.  This method causes the MKNote's envelopes (if any) to begin its release portion and returns the time for the envelopes to finish.  Also sets any parameters present in <i>aNote.</i>
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
