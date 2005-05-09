/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    ConstantUG  - from dsp macro /usr/lib/dsp/ugsrc/constant.asm (see source for details).

   Outputs a constant.
   
   You allocate one of the subclasses ConstantUG<a>, where <a> is the output 
   space. 

   Note that you ONLY need to use the ConstantUG if the patchpoint you're 
   writing will be overwritten by another UnitGenerator.  If you merely want
   to reference an unchanging constant, you do not need a ConstantUG; just
   allocate a SynthData and use its setToConstant: method.

   An example where the ConstantUG IS needed is in doing a reverberator.
   A global input patch point is published and the reverberator first reads
   this patchpoint, then sets it to 0 with a ConstantUG.  Then any 
   SynthPatches that write to the patchpoint add in to whatever's there.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Table Lookup
/*!
  @class ConstantUG
  @brief <b>ConstantUG </b>simply writes a constant to its output patchpoint. 
  
  

ConstantUG produces a constant value.  Since you can set the value of a
patchpoint directly through the MKSynthData method <b>setToConstant:</b>, you
rarely need instances of this class.  However, a ConstantUG object can be used
to initialize, on each tick, a constant-valued patchpoint that may have been
written to during the previous tick.  For example, you can implement additive
synthesis by creating a patch in which each oscillator reads a patchpoint, adds
its own signal into the value, and then writes the sum back to the same
patchpoint in preparation for the next oscillator.  In this case, you would use
a ConstantUG to clear the patchpoint before the first oscillator reads it.

<h2>Memory Spaces</h2>

<b>ConstantUG<i>a</i></b>
<i>a</i>	output 
*/
#ifndef __MK_ConstantUG_H___
#define __MK_ConstantUG_H___

#import <MusicKit/MKUnitGenerator.h>
@interface ConstantUG:MKUnitGenerator

/*!
  @param arg is an unsigned.
  @return Returns an BOOL.
  @brief Specifies that all arguments are to be optimized if possible.

  
*/
+(BOOL)shouldOptimize:(unsigned) arg;

-idleSelf;
/* Sets output patchpoint to sink. */


/*!
  @param  (DSPDatum)value is an id.
  @return Returns <b>self</b>.
  @brief Sets the constant value to <i>value.</i>  
*/
-setConstantDSPDatum:(DSPDatum)value;
/* Sets constant value as int. */


/*!
  @param  (double)value is an id.
  @return Returns <b>self</b>.
  @brief Sets the constant value to a DSPDatum converted from <i>value</i>.

  
  
*/
-setConstant:(double)value;
/* Sets constant value as double. */


/*!
  @param  aPatchpoint is an id.
  @return Returns an id.
  @brief Sets the output patchpoint to <i>aPatchpoint</i>.

  Returns
  <b>nil</b> if the argument isn't a patchpoint; otherwise returns
  <b>self</b>.
*/
-setOutput:aPatchPoint;
/* Sets output location. */ 

@end

#endif
