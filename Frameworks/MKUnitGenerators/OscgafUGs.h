/*
  $Id$
  
  Defined In: The MusicKit
  Description:
     OscgafUG, superclass for OscgafUG (non-interpolating or "drop-sample") and 
   OscgafiUG (interpolating or "high-quality")

   - from dsp macros /usr/lib/dsp/ugsrc/oscgaf.asm and oscgafi.asm 
   (see source for details).

       OscgafUG<a><b><c><d>, where <a> is the output space, <b> is the
    amplitude input space, <c> is the increment input space, and <d> is
    the table space.
    
       OscgafUG is a class of lookup-table unit generators which includes
    patchpoint arguments for amplitude and frequency control.  That is,
    those parameters are intended to be determined by the output of some
    other unit generator, such as AsympUG.  See the example synthpatch
    FmExamp.m for an example of the use of Oscgaf.
    
       Amplitude control is straightforward.  The output of OscgafUG is
    simply the value of the lookup table times whatever comes in via the
    ampEnvInput patchpoint.  Frequency control is more complicated. The
    signal needed for freqEnvInput is not actually the frequency in Hertz, 
    but the phase increment, which is the amount the lookup table index changes
    during each sample.  This number depends on the desired frequency, the
    length of the lookup table, the sampling rate, and a constant called
    MK_OSCFREQSCALE. MK_OSCFREQSCALE is a power of two which represents
    the maximum possible increment.  Input to freqEnvInput must be divided
    by this number in order to insure that it remains in the 24-bit signal
    range.  The signal is then scaled back up by this number within
    Oscgaf, with a possible additional scaling by the incRatio (see
    below).
    
       A method called incAtFreq: has been provided which takes all the
    above factors into account and returns the increment for a given
    frequency.  The lookup table must be set first, via the -setTable:
    method, since the length of the table must be known to perform the
    calculation.  If more than one Oscgaf is to be controlled by the same
    increment envelope signal (such as in a typical FM patch), they can
    have different frequencies by using the -setIncRatio: method.  Since
    the input increment signal is scaled by MK_OSCFREQSCALE*incRatio
    within Oscgaf, the resulting frequency will be correspondingly
    changed.  The incRatio defaults to 1.0.
    
       The increment scaler can be set directly with -setIncScaler:. This
    simply sets the increment scaler to the value you provide, ignoring
    MK_OSCFREQSCALE, incRatio, etc.
    
       OscgafUG is a non-interpolating oscillator. That means that its
    fidelity depends on the size of the table (larger tables have lower
    distortion) and the highest frequency represented in the table. For
    high-quality synthesis, an interpolating version with the same methods,
    OscgafiUG, is preferable.
    However, an interpolating oscillator is also more expensive. OscgafUG
    is useful in cases where density of texture is more important than
    fidelity of individual sounds.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Oscillators and Waveform Generators
/*!
  @class OscgafUGs
  @brief <b>OscgafUGs</b> is the superclass for <b>OscgafUG</b> and <b>OscgafiUG</b> oscillators.
  
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
#ifndef __MK_OscgafUGs_H___
#define __MK_OscgafUGs_H___

#import <MusicKit/MKUnitGenerator.h>

@interface OscgafUGs: MKUnitGenerator
{
    double _reservedOscgaf1;
    double incRatio;	/* optional multiplier on frequency Scale */
    double _reservedOscgaf2;
    id _reservedOscgaf3;
    int tableLength; /* Or 0 if no table. */
}

/*!
  @param arg is an unsigned.
  @return Returns an BOOL.
  @brief Specifies that all arguments are to be optimized if possible
  except the phase.
*/
+(BOOL)shouldOptimize:(unsigned) arg;

/*!
  @brief Returns a default table length determined by the type of subclass
  and type of argument.
  @param  anObj is an id.
  @return Returns an int.
*/
+ (int) defaultTableLength: (id) anObj;

/*!
  @brief Sets increment directly to an integer as specified.

  Not normally called by the user. 
  @param  aScaler is an int.
  @return Returns an id.
*/
-setIncScaler:(int)aScaler;

/*!
  @param  aPhase is a double.
  @return Returns an id.
  @brief Sets oscillator phase in degrees.

  If wavetable has not yet been set, stores the value for <b>-runSelf</b> to use to set the phase
  later. 
*/
-setPhase:(double)aPhase;

/*!
  @param  aPatchPoint is an id.
  @return Returns an id.
  @brief Sets amplitude envelope input to specified patchPoint.

  The signal received via <i>aPatchPoint</i> serves as a multiplier on the output
  of the oscillator. 
*/
-setAmpInput: (id) aPatchPoint;

/*!
  @param  aPatchPoint is an id.
  @return Returns an id.
  @brief Set output patchPoint of the oscillator.
*/
-setOutput: (id) aPatchPoint;

/*!
  @param  aPatchPoint is an id.
  @return Returns an id.
  @brief Set frequency envelope input to specified patchPoint.

  Note that <b>OscgafUGs</b> implements a multiplicative frequency envelope. 
  The actual phase increment  is the value of the signal received via
  <i>aPatchPoint</i> multiplied by the incScaler.  To get the proper
  increment value for a certain frequency, e.g,  for use in a
  frequency envelope generator writing to the <i>incEnvInput</i>,  see
  <b> incAtFreq:</b> below. 
*/
-setIncInput: (id) aPatchPoint;
 /* Set frequency envelope input to specified patchPoint. Note that OscgafUG  
   implements a multiplicative frequency envelope. The actual phase increment 
   is the value of the signal received via aPatchPoint multiplied by the 
   IncScaler. To get the proper increment value for a certain frequency, e.g, 
   for use in a frequency envelope generator writing to the incEnvInput, 
   see "incAtFreq:" below. */

/*!
  @param  aFreq is a double.
  @return Returns a double.
  @brief Returns the phase increment for this unit generator based on aFreq.

  This value is suitable for use as the amplitude to a unit generator
  whose output is being used as the <i>incEnvInput</i> of this unit
  generator.  The lookup table must be set before sending this message.  
*/
-(double)incAtFreq:(double)aFreq;

/*!
  @param  aRatio is a double.
  @return Returns an id.
  @brief This is an alternative to the <b>-setIncScaler:</b> method.

  The ratio specified here acts as a straight multiplier on the increment
  scaler, and hence on the frequency.   For example, in an FM
  MKSynthPatch with one frequency envelope for both carrier and
  modulator,  <b>setIncRatio:</b> sent to the modulator specifies
  the frequency ratio of the modulator/carrier. The ratio defaults to 1.0. 
*/
-setIncRatio:(double)aRatio;

/*!
  @param  anObj is an id.
  @param  aLength is an int.
  @return Returns an id.
  @brief Sets the lookup table of the oscillator.

  <i>anObj</i> can be a
  MKSynthData object or a MKWaveTable (Partials or Samples).
  
  This method first releases its claim on the locally-allocated MKSynthData, if any.  (see
  below).  Then, if <i>anObj</i> is a MKSynthData object, the MKSynthData object is used
  directly.  If <i>anObj</i> is a MKWaveTable, the receiver first searches in its
  Orchestra's shared object table to see if there is already an existing MKSynthData based
  on the same MKWaveTable, of the same length, and in the required memory space.
  Otherwise, a local MKSynthData object is created and installed in the shared object
  table so that other unit generators running simultaneously may share it.  If the
  requested size is too large, because there is not sufficient DSP memory, smaller sizes
  are tried.  You can determine what size was used by sending the tableLength message.  If
  <i>anObj</i> is nil, this method simply releases the locally-allocated MKSynthData, if
  any.
  
  Note that altering the contents of a MKWaveTable will have no effect once it has been
  installed, even if you call <b>setTable:length: </b>again after modifying the
  MKWaveTable. The reason is that the Orchestra's shared data mechanism finds the
  requested object based on its <b>id</b>, rather than its contents.
  
  You should not free WaveTables used as arguments to <b>OscgafUGs</b> until the performance is over.
  
  If the table is not a power of 2, returns nil and generates the error MK_ugsPowerOf2Err. 
*/
-setTable:anObj length:(int)aLength;
 /* 
   Sets the lookup table of the oscillator.
   anObj can be a MKSynthData object or a MKWaveTable (MKPartials or MKSamples).

   First releases its claim on the locally-allocated MKSynthData, if any. 
   (see below).

   If anObj is a MKSynthData object, the MKSynthData object is used directly.

   If anObj is a MKWaveTable, the receiver first searches in its MKOrchestra's
   shared object table to see if there is already an existing MKSynthData based 
   on the same MKWaveTable, of the same length, and in the required memory
   space. Otherwise, a local MKSynthData object is created and installed in the
   shared object table so that other unit generators running simultaneously 
   may share it. (This is important since DSP memory is limited.) 
   If the requested size is too large, because there is not sufficient DSP
   memory, smaller sizes are tried. (You can determine what size was used
   by sending the tableLength message.)
   
   Note that altering the contents of a MKWaveTable will have no effect once it 
   has been installed, even if you call setTable:length: again after 
   modifying the MKWaveTable. The reason is that the Orchestra's shared data
   mechanism finds the requested object based on its id, rather than its
   contents.

   If anObj is nil, simply releases the locally-allocated MKSynthData, if any. 
   If the table is not a power of 2, returns nil and generates the error
   MK_ugsPowerOf2Err. 
 */


/*!
  @brief Like <b>setTable:length:</b>, but uses a default length.
  @param  anObj is an id.
  @return Returns an id.
*/
- setTable: (id) anObj;

/*!
  @return Returns an id.
  @brief Sets the lookup table to the DSP sine ROM, if address space is Y.

  Otherwise generates an error. Deallocates local wave table, if any.
*/
-setTableToSineROM;

/*!
  @param  anObj is an id.
  @param  aLength is an int.
  @param  yesOrNo is a BOOL.
  @return Returns an id.
  @brief This method is provided as a convenience.

  It tries to do 'the right thing' in cases where the table cannot be allocated.
  
  
  If the table can be allocated, it behaves like <b>setTable:length:</b>. If the table
  cannot be allocated, and the table memory space of the receiver is Y, sends <b>[self
  setTableToSineROM].</b>
  
  A common use of this method is to pass YES as the argument <i>yesOrNo</i> only if the
  MKSynthPatch is beginning a new phrase (the assumtion is that it is better to keep the
  old wavetable than to use the sine ROM in this case).  Another use of this method is to
  specifically request the sine ROM by passing <b>nil</b> as <i>anObj</i>.  If the sine
  ROM is used, the <i>aLength</i> argument is ignored.
  
  If <i>anObj</i> is not <b>nil</b> and the sine ROM is used, generates the error
  <b>MK_spsSineROMSubstitutionErr</b>. If <i>yesOrNo</i> is YES but the receiver's table
  memory space is X, the error <b>MK_spsCantGetMemoryErr</b> is generated.  
*/

-setTable:anObj length:(int)aLength defaultToSineROM:(BOOL)yesOrNo;
 /* This method is provided as a convenience. It tries to do 'the right thing'
   in cases where the table cannot be allocated. 

   If the table can be allocated, it behaves like setTable:length:. If the
   table cannot be allocated, and the table memory space of the receiver is Y,
   sends [self setTableToSineROM]. 
   
   A common use of this method is to pass YES as the argument defaultToSineROM
   only if the SynthPatch is beginning a new phrase (the assumtion is that it 
   is better to keep the old wavetable than to use the sine ROM in this case).
   Another use of this method is to specifically request the sine ROM by 
   passing nil as anObj. If the sine ROM is used, the aLength argument is
   ignored.
   
   Errors:
   If anObj is not nil and the sine ROM is used, generates the error 
   MK_spsSineROMSubstitutionErr. If sineROMDefaultOK is YES but the 
   receiver's table memory space is X, the error MK_spsCantGetMemoryErr 
   is generated.
 */   


/*!
  @param  anObj is an id.
  @param  yesOrNo is a BOOL.
  @return Returns an id.
  @brief Like <b>setTable:length:defaultToSineROM:</b>, but uses a default length.
*/
-setTable: anObj defaultToSineROM:(BOOL)yesOrNo;

/*!
  @return Returns an unsigned int.
  @brief Returns the length of the assigned table 0 if no table is assigned.
*/
- (unsigned) tableLength;

/*!
  @return Returns a double.
  @brief Returns incRatio.
*/
-(double)incRatio;

/*!
  @return Returns an id.
  @brief Invoked by <b>run </b>method.

  Sets phase if  -<b>setPhase:</b> was called before lookup table was set,
  and sets increment scaler if not already set by a call to <b>-setIncRatio:</b>.
  If wavetable has not been set, and table space is Y, uses DSP sine ROM.
*/
-runSelf;

/*!
  @return Returns an id.
  @brief Deallocates local wave table memory, if any, and patches output to Sink.
*/
-idleSelf;

@end

#endif
