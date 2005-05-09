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
  Revision 1.4  2005/05/09 15:27:43  leighsmith
  Converted headerdoc comments to doxygen comments

  Revision 1.3  2001/09/10 17:38:28  leighsmith
  Added abstracts from IntroSynthPatches.rtf

  Revision 1.2  2001/09/08 20:22:09  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

*/
//  classgroup WaveTable Synthesis
/*!
  @class DBWave1v
  @brief Like <b>Wave1v</b>, but with access to the Timbre Data Base.
  
  

<b>DBWave1vi</b> is like <b>Wave1vi</b>, but it includes support for the Music
Kit Timbre Data Base. <b>DBWave1v</b> is like <b>DBWave1vi</b>, but it uses a
non-interpolating-oscillator (lower quality, but uses less DSP computation.)  
The Timbre Data Base is a set of spectra derived from recordings of
musical instruments and voices in various ranges.  The Data Base was
created by Michael McNabb.

The MKSynthPatches that support the Data Base are DBWave1v, DBWave1vi,
DBWave2vi, and DBFm1vi.  ("DB" stands for "Data Base".)  Note that the
use of the Data Base is strictly optional in these instruments.  For
example, if the Data Base is not used, DBWave1v acts just like
Wave1v.  That is, the <b>waveform</b> parameter may be passed either
an ordinary MKWaveTable (as in Wave1v) or a timbre string (as defined
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

When using this MKSynthPatch in an interactive real-time context, such as playing
from a MIDI keyboard, call <b>MKUseRealTimeEnvelopes()</b> before allocating the
MKSynthPatch.

<h2>Parameter Interpretation</h2>

In addition to the parameters described in <b>Wave1vi.rtfd</b>, the following
parameters are supported:

<b>balanceSensitivity</b> - In the range 0.0:1.0.  Default is 1.0.

<b>controlChange</b> - MIDI balance (controller 8) interpolates between two
timbres, <b>waveform0</b> and <b>waveform1</b>.  When the companion parameter,
<b>controlVal</b> is 0 the result is <b>waveform0</b>.  When <b>controlVal</b>
is 127 (the default), the result is <b>waveform1</b>.  Values between produce a
linearly-interpolated timbre.  Setting the <b>balanceSensitivity</b> parameter
to less than 1.0 reduces the maximum proportion of <b>waveform1</b>.  Since any
change in <b>balance</b> in this SynthPatch results in a new wavetable being
sent to the DSP, there are limitations as to how quickly and smoothly it can be
done.  Frequent changes may disturb timing.  Setting <b>wavelen</b> to 128 or 64
helps.  If you are doing a great deal of wave table interpolation, you should
use <b>DBWave2vi</b>.

MIDI pan (controller 10) has the same effect as <b>bearing</b>.  If the
<b>panSensitivity</b> is 1.0, a MIDI pan value of  0 is full left and 127 is
full right.  If the value of  <b>panSensitivity</b> is less than 1.0, the pan
range is narrowed toward the center.  The value is set by the companion
parameter, <b>controlVal</b>.  

<b>controlVal</b> - See controlChange.

<b>panSensitivity -</b> In the range 0.0:1.0.  Default is 1.0.

<b>waveform0</b> - Waveform when balance is 0.  Default is a sine wave.

<b>waveform1</b> - Waveform when balance is 1.  Default is a sine wave. 
waveform1 is a synonym for waveform.
*/
#ifndef __MK_DBWave1v_H___
#define __MK_DBWave1v_H___

#import "DBWave1vi.h"
@interface DBWave1v:DBWave1vi
{
}

@end

#endif
