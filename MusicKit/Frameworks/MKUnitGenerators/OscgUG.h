/*
  $Id$
  Defined In: This class is part of the Music Kit UnitGenerator Library.

  Description:
    Simple oscillator with no envelopes.

    OscgUG  - from dsp macro /usr/lib/dsp/ugsrc/oscg.asm (see source for details).

    OscgUG<a><b>, where <a> is output space and <b> is table space.

    This is a non-interpolating oscillator. That means that its fidelity
    depends on the size of the table (larger tables have lower distortion)
    and the highest frequency represented in the table. For high-quality
    synthesis, an interpolating oscillator is preferable. However, an
    interpolating oscillator is also more expensive. OscgUG is useful
    in cases where density of texture is more important than fidelity of
    individual sounds.

    The wavetable length must be a power of 2.
    The wavetable increment must be nonnegative.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
// classgroup Oscillators and Waveform Generators
/*!
  @class OscgUG
  @abstract <b>OscgUG</b> is the basic oscillator and supports amplitude and frequency as memory arguments.
  @discussion

This is a non-interpolating oscillator. That means that its fidelity depends on
the size of the table (larger tables have lower distortion) and the highest
frequency represented in the table.  For high-quality synthesis, an
interpolating oscillator, such as OscgafiUG is preferable.  However, an
interpolating oscillator is also more expensive, in terms of DSP cycles.  OscgUG
is useful in cases where density of texture is more important than fidelity of
individual sounds.
   
Restrictions:  The wavetable length must be a power of 2. The wavetable
increment must be nonnegative.

<h2>Memory Spaces</h2>

<b>OscgUG<i>ab</i></b>
<i>a</i>	output
<i>b</i>	table space
*/
/*
  Modification history:
  $Log$
  Revision 1.4  2001/09/15 17:12:07  leighsmith
  Merged RTF class documentation into headerdoc comments

  Revision 1.3  2000/09/14 18:02:45  leigh
  Doco cleanups

*/
#ifndef __MK_OscgUG_H___
#define __MK_OscgUG_H___

#import <MusicKit/MKUnitGenerator.h>

@interface OscgUG:MKUnitGenerator
{
    double _reservedOscg1;
    double _reservedOscg2;
    double _reservedOscg3;
    id _reservedOscg4;
    int tableLength;          /* Or 0 if no table. */
}

/*!
  @method shouldOptimize:
  @param arg is an unsigned.
  @result Returns an BOOL.
  @discussion Specifies that all arguments are to be optimized if possible
              except the phase.
*/
+(BOOL)shouldOptimize:(unsigned) arg;

-setInc:(int)anInc;
/* Sets increment as an integer as specified. */

/*!
  @method setFreq:
  @param  aFreq is a double.
  @result Returns an id.
  @discussion Sets oscillator frequency in Hz. If wavetable has not yet been set,
              stores the value for runSelf to use to set the frequency later.
*/
-setFreq:(double)aFreq;

/*!
  @method setAmp:
  @param  aAmp is a double.
  @result Returns an id.
  @discussion Sets amplitude as specifed.
*/
-setAmp:(double)aAmp;
/* Sets amplitude as specified. */


/*!
  @method setPhase:
  @param  aPhase is a double.
  @result Returns an id.
  @discussion Sets oscillator phase in degrees. If wavetable has not yet been set,
              stores the value for <b>-runSelf</b> to use to set the phase later.
              
*/
-setPhase:(double)aPhase;
/* Sets oscillator phase in degrees. If wavetable has not yet been set,
   stores the value for runSelf to use to set the phase later. */



/*!
  @method runSelf
  @result Returns an id.
  @discussion You never send this message.  It's invoked by sending the <b>run</b>
              message to the object.    Sets the oscillator phase if
              <b>setPhase:</b> was called before the WaveTable was set.  Sets
              frequency to the last value set with <b>setFreq:</b>.  If WaveTable
              has not been set, and table space is Y, sets table to DSP SINE
              ROM.
*/
-runSelf;
/* Sets oscillator phase if -setPhase: was called before lookup table was 
   set, and sets oscillator frequency to the last value set with setFreq:.
   If wavetable has not been set, and table space is Y, uses DSP SINE ROM. */


/*!
  @method idleSelf
  @result Returns an id.
  @discussion You never send this message.  It's invoked by sending the
              <b>idle</b> message to the object.  
              Sets the output patchpoint to <i>sink</i> (thus ensuring that
              the object does not produce any output) and deallocates any 
              MKWaveTable memory that the object had allocated .  Note that you must
              send <b>setOutput:</b> and <b>run</b> again to use the object after sending <b>idle</b>.
*/
-idleSelf;
/* Deallocates local wave table memory, if any, and patches output to Sink. */


/*!
  @method setOutput:
  @param  aPatchPoint is an id.
  @result Returns an id.
  @discussion Set output patchPoint of the oscillator. 
*/
-setOutput:aPatchPoint;
/* Sets output location. */


/*!
  @method setTable:length:
  @param  anObj is an id.
  @param  aLength is an int.
  @result Returns an id.
  @discussion Sets the lookup table of the oscillator.  <i>anObj</i> can be a
              SynthData object or a WaveTable (Partials or Samples).
              
              This method first releases its claim on the locally-allocated SynthData, if any.  (see below).   Then, if <i>anObj</i> is a SynthData object, the SynthData object is used directly.   If <i>anObj</i> is a WaveTable, the receiver first searches in its Orchestra's shared object table to see if there is already an existing SynthData based  on the same WaveTable, of the same length, and in the required memory  space.  Otherwise, a local SynthData object is created and installed in the shared object table so that other unit generators running simultaneously  may share it.   If the requested size is too large, because there is not sufficient DSP memory, smaller sizes are tried.  You can determine what size was used by sending the tableLength message.  If <i>anObj</i> is nil, this method simply releases the locally-allocated SynthData, if any.   
                 
              Note that altering the contents of a WaveTable will have no effect once it  has been installed, even if you call <b>setTable:length:</b> again after  modifying the WaveTable. The reason is that the Orchestra's shared data  mechanism finds the requested object based on its <b>id</b>, rather than its contents.
              
              You should not free WaveTables used as arguments to OscgUG until the performance is over.
              
              If the table is not a power of 2, returns nil and generates the error MK_ugsPowerOf2Err. 
*/
-setTable:anObj length:(int)aLength;
/* 
   Sets the lookup table of the oscillator.
   anObj can be a SynthData object or a WaveTable (Partials or Samples).

   First releases its claim on the locally-allocated SynthData, if any. 
   (see below).

   If anObj is a SynthData object, the SynthData object is used directly.

   If anObj is a WaveTable, the receiver first searches in its Orchestra's
   shared object table to see if there is already an existing SynthData based 
   on the same WaveTable, of the same length, and in the required memory
   space. Otherwise, a local SynthData object is created and installed in the
   shared object table so that other unit generators running simultaneously 
   may share it. (This is important since DSP memory is limited.) 
   If the requested size is too large, because there is not sufficient DSP
   memory, smaller sizes are tried. (You can determine what size was used
   by sending the tableLength message.)
   
   Note that altering the contents of a WaveTable will have no effect once it 
   has been installed, even if you call setTable:length: again after 
   modifying the WaveTable. The reason is that the Orchestra's shared data
   mechanism finds the requested object based on its id, rather than its
   contents.

   If anObj is nil, simply releases the locally-allocated SynthData, if any. 
   If the table is not a power of 2, returns nil and generates the error
   MK_ugsPowerOf2Err. 
*/


/*!
  @method setTable:
  @param  anObj is an id.
  @result Returns an id.
  @discussion Like <b>setTable:length:</b>, but uses a default length.
              
*/
-setTable:anObj;
/* Like setTable:length, but uses a default length. */


/*!
  @method setTableToSineROM
  @result Returns an id.
  @discussion Sets the lookup table to the DSP sine ROM, if address space is Y.  
              Otherwise generates an error.   Deallocates local wave table, if
              any.
*/
-setTableToSineROM;
/* Sets the lookup table to the DSP sine ROM, if address space is Y. 
   Otherwise generates an error. Deallocates local wave table, if any.
*/


/*!
  @method setTable:length:defaultToSineROM:
  @param  anObj is an id.
  @param  aLength is an int.
  @param  yesOrNo is a BOOL.
  @result Returns an id.
  @discussion This method is provided as a convenience.  It tries to do 'the right
              thing' in cases where the table cannot be allocated.
              
              
              If the table can be allocated, it behaves like <b>setTable:length:</b>. If the table cannot be allocated, and the table memory space of the receiver is Y, sends <b>[self setTableToSineROM].</b> 
                 
              A common use of this method is to pass YES as the argument <i>yesOrNo</i> only if the MKSynthPatch is beginning a new phrase (the assumtion is that it is better to keep the old wavetable than to use the sine ROM in this case).  Another use of this method is to specifically request the sine ROM by passing <b>nil</b> as <i>anObj</i>.  If the sine ROM is used, the <i>aLength</i> argument is ignored.
                 
              If <i>anObj</i> is not <b>nil</b> and the sine ROM is used, generates the error <b>MK_spsSineROMSubstitutionErr</b>. If <i>yesOrNo</i> is YES but the receiver's table memory space is X, the error <b>MK_spsCantGetMemoryErr</b>  is generated.
*/
-setTable:anObj length:(int)aLength defaultToSineROM:(BOOL)yesOrNo;
/* This method is provided as a convenience. It tries to do 'the right thing'
   in cases where the table cannot be allocated. 

   It functions like setTable:length:, but it defaults to the sine ROM in the 
   DSP if sineROMDefaultOK is YES, the DSP memory for anObj cannot be 
   allocated, and the table memory space of the receiver is Y.
   
   A common use of this method is to pass YES only if the SynthPatch is
   beginning a new phrase (the assumtion is that it is better to keep the
   old wavetable than to use the sine ROM in this case).
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
  @method setTable:defaultToSineROM:
  @param  anObj is an id.
  @param  yesOrNo is a BOOL.
  @result Returns an id.
  @discussion Like <b>setTable:length:defaultToSineROM:</b>, but uses a default
              length. 
*/
-setTable:anObj defaultToSineROM:(BOOL)yesOrNo;
/* Like setTable:length:defaultToSineROM, but uses a default length. */

/*!
  @method tableLength
  @result Returns an unsigned int.
  @discussion Returns the length of the assigned table or 0 if no table is assigned.
*/
-(unsigned)tableLength;

@end

#endif
