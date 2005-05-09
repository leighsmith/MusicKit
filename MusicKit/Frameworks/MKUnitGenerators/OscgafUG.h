/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    OscgafUG  - from dsp macro /usr/lib/dsp/ugsrc/oscgaf.asm (see source for details).
    See documentation for OscgafUGs. 

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Oscillators and Waveform Generators
/*!
  @class OscgafUG
  @brief <b>OscgafUG</b> is similar to <b>OscgUG</b>, but supports patchpoints
  for frequency and amplitude.
  
  

<b>OscgafUGs</b> is the superclass for <b>OscgafUG</b> (non-interpolating or
"drop-sample") and <b>OscgafiUG</b> (interpolating or "high-quality")
oscillators.  They are, in turn, derived from dsp macros 
<b>/usr/local/lib/dsp/ugsrc/oscgaf.asm</b> and <b>oscgafi.asm</b>.
<b>OscgafiUG</b> and <b>OscgafUG</b> implement no methods of their own.
They get all their behavior from <b>OscgafUGs</b>.  

The fidelity of <b>OscgafUG</b> depends on the size of the table (larger tables
have lower distortion) and the highest frequency represented in the table.  For
high-quality synthesis, <b>OcgafiUG</b>, is preferable.  However,
<b>OscgafUG</b> is less expensive (in terms of DSP cycles) and is useful in
cases where density of texture is more important than  fidelity of individual
sounds.

The remainder of this discussion deals focuses on <b>OscgafUGs</b>, which
embodies the characteristics that <b>OscgafiUG</b> and <b>OscgafUG</b>
share.

<b>OscgafUGs</b> includes  patchpoint arguments for amplitude and frequency
control.  That is, those parameters are intended to be determined by the output
of some other unit generator, such as AsympUG.  See the example synthpatch
<b>/LocalDeveloper/Examples/MusicKit/exampsynthpatch/FM.m</b> for an example of
its use.
  
Amplitude control is straightforward.  The output of <b>OscgafUGs</b> is simply
the value of the lookup table times whatever comes in via the <i>ampEnvInput</i>
patchpoint.  Frequency control is more complicated. The signal needed for
<i>freqEnvInput</i> is not actually the frequency in Hertz, but the phase
increment, which is the amount the lookup table index changes during each
sample.  This number depends on the desired frequency, the length of the lookup
table, the sampling rate, and a constant called MK_OSCFREQSCALE. MK_OSCFREQSCALE
is a power of two which represents the maximum possible increment.  Input to
<i>freqEnvInput</i> must be divided  by this number in order to insure that it
remains in the 24-bit signal  range.  The signal is then scaled back up by this
number within OscgafUGs, with a possible additional scaling by the incRatio (see
below).
  
A method called <b>incAtFreq:</b> has been provided which takes all the above
factors into account and returns the increment for a given frequency.  The
lookup table must be set first, via the <b>-setTable:</b>  method, since the
length of the table must be known to perform the  calculation.  If more than one
<b>OscgafUGs</b> is to be controlled by the same  increment envelope signal
(such as in a typical FM patch), they can  have different frequencies by using
the <b>-setIncRatio: </b>method.  Since  the input increment signal is scaled by
MK_OSCFREQSCALE*incRatio within <b>OscgafUGs</b>, the resulting frequency will
be correspondingly changed.  The incRatio defaults to 1.0.
  
Alternatively, the increment scaler can be set directly with
<b>-setIncScaler:</b>. This simply sets the increment scaler to the value you
provide, ignoring MK_OSCFREQSCALE, incRatio, etc.

<h2>Memory Spaces</h2>

<b>OscgafUGs<i>abcd</i></b>
<i>a</i>	output
<i>b</i>	amplitude input
<i>c</i>	increment (derivative of freq) input
<i>d</i>	table space
*/
#ifndef __MK_OscgafUG_H___
#define __MK_OscgafUG_H___

#import "OscgafUGs.h"

@interface OscgafUG:OscgafUGs

@end

#endif
