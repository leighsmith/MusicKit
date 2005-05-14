/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    (See discussion below)

  Original Author: Eric J. Graves and David A. Jaffe

  Copyright (c) 1992 Eric J. Graves & Stanford University.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.5  2005/05/14 03:23:05  leighsmith
  Clean up of parameter names to correct doxygen warnings

  Revision 1.4  2005/05/09 15:27:44  leighsmith
  Converted headerdoc comments to doxygen comments

  Revision 1.3  2001/09/10 17:38:28  leighsmith
  Added abstracts from IntroSynthPatches.rtf

  Revision 1.2  2001/09/08 20:22:09  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

*/
//  classgroup Waveshaping (a.k.a. Nonlinear Distortion) Synthesis
/*!
  @class Shapev
  @brief Same as <b>Shape</b> but with periodic and random vibrato.
  
  

<b>Shapev</b> is like <b>Shape</b>, but it includes periodic and random
vibrato.

When using this MKSynthPatch in an interactive real-time context, such as playing
from a MIDI keyboard, call <b>MKUseRealTimeEnvelopes()</b> before allocating the
MKSynthPatch.

<h2>Parameter Interpretation</h2>

In addition to the parameters described in <b>Shape.rtfd</b>, the following
parameters are supported:

<b>controlChange</b> - MIDI modulation wheel (controller 1) interpolates
simultaneously between <b>svibAmp0</b> and <b>svibAmp</b>, and <b>svibFreq0</b>
and <b>svibFreq</b>.  The default value (127) results in svibFreq and svibAmp. 
The value is given by the companion parameter controlVal. In the range
0:127.

<b>controlVal</b> - See controlChange.

<b>svibFreq</b> - Sinusoidal vibrato rate in hz.  Default is
0.0.

<b>svibAmp</b> - Sinusoidal vibrato amplitude as a percentage of the fundamental
frequency.  In the range 0.0:1.0.  Default is 0.0.

<b>svibFreq0</b> - See <b>controlChange</b>.  Default is 0.0.

<b>svibAmp0</b> - See <b>controlChange.</b>  Default is 0.0.

<b>rvibAmp</b> - Random vibrato amplitude as roughly a percentage of the
fundamental frequency.  In the range 0.0:1.0.  Default is 0.0.

<b>vibWaveform</b> - WaveTable object that specifies shape of vibrato.

*/
#ifndef __MK_Shapev_H___
#define __MK_Shapev_H___

#import "Shape.h"
#import <MusicKit/MKWaveTable.h>

@interface Shapev:Shape
{
    MKWaveTable *vibWaveform; /* Waveform used for vibrato. */
    double svibAmp0;  /* Vibrato, on a scale of 0 to 1, when modWheel is 0. */
    double svibAmp1;  /* Vibrato, on a scale of 0 to 1, when modWheel is 127.*/
    double svibFreq0; /* Vibrato freq in Hz. when modWheel is 0. */
    double svibFreq1; /* Vibrato freq in Hz. when modWheel is 1. */
    double rvibAmp;   /* Random vibrato. On a scale of 0 to 1. */
    int modWheel;     /* MIDI modWheel. Controls vibrato frequency and amp */
    id svib,nvib,onep,add;
}

/*!
  @param  aNote is an id.
  @return Returns an id.
  @brief Returns a template.

  A non-zero for <b>svibAmp</b>and <b>rvibAmp </b>
  determines whether vibrato resources are allocated.
*/
+ patchTemplateFor: (MKNote *) aNote;

@end

#endif
