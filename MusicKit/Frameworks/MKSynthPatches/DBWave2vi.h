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
  Revision 1.3  2001/09/08 20:22:09  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

*/
/*!
  @class DBWave2vi
  @discussion

<b>DBWave2vi</b> is a double interpolating oscillator wavetable synthesis SynthPatch with dynamic envelope-driven interpolation between the two oscillators, amplitude and frequency envelopes.    It supports the Timbre Data Base (see <b>TimbreDataBase.rtf.</b>)

Although <b>DBWave2vi</b> does not inherit from any other wavetable synthesis class, it is similar to <b>DBWave1vi</b>, except that there are two oscillators doing the synthesis.  

The Timbre Data Base is a set of spectra derived from recordings of
musical instruments and voices in various ranges.  The Data Base was
created by Michael McNabb.

The MKSynthPatches that support the Data Base are DBWave1vi,
DBWave2vi, and DBFm1vi.  ("DB" stands for "Data Base".)  Note that the
use of the Data Base is strictly optional in these instruments.  For
example, if the Data Base is not used, DBWave1vi acts just like
Wave1vi.  That is, the <b>waveform</b> parameter may be passed either
an ordinary MKWaveTable (as in Wave1vi) or a timbre string (as defined
below).

To use the Data Base, you specify a timbre as a string (such as "SA",
including the quotation marks) to the MKSynthPatch's <b>waveform</b>
parameter.  MKSynthPatches with multiple <b>waveform </b>parameters
accept multiple timbre strings.  Each timbre string represents a group
of MKWaveTables, one for approximately every whole step in the normal
range of the voice or instrument.  The MKSynthPatch selects the
MKWaveTable appropriate to the frequency.  By default, the MKWaveTable
selection is based on the parameter <b>freq1</b> (synonym for
<b>freq</b>, or MIDI <b>keynum</b>).  By prefixing a timbre string
with the zero character, e.g., "0SA", the timbre will be selected
based on the <b>freq0</b> parameter instead.

The various timbre groups have different numbers of MKWaveTables, as
given in the chart below.  Internally, the MKWaveTables for a particular
timbre group are numbered sequentially, with 1 corresponding to the
MKWaveTable for the bottom of the range of that timbre.  Specific
MKWaveTables in a timbre group can be requested by adding a numeric
suffix.  In this manner, the automatic selection based on frequencycan
be overridden.  For example, the timbre group "BA" (bass voice singing
"AH") consists of 15 timbres.  The timbre string "BA12" requests the
12th MKWaveTable, independent of the frequency.

Some of the timbres are actually recordings of the attack of an
instrument.  These are best used with the MKSynthPatch DBWave2vi,
which can interpolate between timbres.  Note also that for realism,
appropriate envelopes, attack/decay values and vibrato must be used.

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
  @param  aNote is an id.
  @result Returns an id.
  @discussion Returns a template. A non-zero for <b>svibAmp</b>and <b>rvibAmp </b> determines
              whether vibrato resources are allocated. 
*/
+patchTemplateFor:aNote;
   
/*!
  @method noteOnSelf:
  @param  aNote is an id.
  @result Returns an id.
  @discussion <i>aNote</i> is assumed to be a noteOn or noteDur.  This method triggers (or retriggers) the Note's envelopes, if any.  If this is a new phrase, all instance variables are set to default values, then the values are read from the Note.  
*/
-noteOnSelf:aNote;

/*!
  @method noteUpdateSelf:
  @param  aNote is an id.
  @result Returns a id.
  @discussion <i>aNote</i> is assumed to be a noteUpdate and the receiver is assumed to be currently playing a Note.  Sets parameters as specified in <i>aNote.</i>
*/
-noteUpdateSelf:aNote;

/*!
  @method noteOffSelf:
  @param aNote is an id.
  @result Returns a double.
  @discussion <i>aNote</i> is assumed to be a noteOff.  This method causes the Note's envelopes (if any) to begin its release portion and returns the time for the envelopes to finish.  Also sets any parameters present in <i>aNote.</i>
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
