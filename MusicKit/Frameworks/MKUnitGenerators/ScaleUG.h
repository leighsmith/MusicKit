/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    ScaleUG - from dsp macro /usr/lib/dsp/ugsrc/scale.asm (see source for details).

    You instantiate a subclass of the form 
    ScaleUG<a><b>, where <a> = space of output and <b> = space of input.

    The scale unit-generator simply copies one signal vector over to
    another, multiplying by a scale factor.  The output patchpoint can 
    be the same as the input patchpoint.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Patchpoint Arithmetic
/*!
  @class ScaleUG
  @abstract <b>ScaleUG</b> multiplies a patchpoint by a value that is specified in its memory argument.  
  @discussion

ScaleUG multiplies its input by a constant scaler:
	
<i>output</i> = <i>input1</i> * <i>scaler</i>

<h2>Memory Spaces</h2>

<b>ScaleUG<i>ab</i></b>
<i>a</i>	output 
<i>b</i>	input 
*/
#ifndef __MK_ScaleUG_H___
#define __MK_ScaleUG_H___

#import <MusicKit/MKUnitGenerator.h>

@interface ScaleUG: MKUnitGenerator

/*!
  @method setInput:
  @param  aPatchpoint is an id.
  @result Returns an id.
  @discussion Sets the input patchpoint to <i>aPatchpoint</i>.  Returns <b>nil</b>
              if the argument isn't a patchpoint; otherwise returns
              <b>self</b>.
*/
-setInput:aPatchPoint;
/* Sets input patchpoint. */


/*!
  @method setOutput:
  @param  aPatchpoint is an id.
  @result Returns an id.
  @discussion Sets the output patchpoint to <i>aPatchpoint</i>.  Returns
              <b>nil</b> if the argument isn't a patchpoint; otherwise returns
              <b>self</b>.
*/
-setOutput:aPatchPoint;
/* Sets output patchpoint. */


/*!
  @method setScale:
  @param  (double)value is an id.
  @result Returns <b>self</b>.
  @discussion Sets the constant scaler.  Effective values are between 0.0 and 1.0
              (a negative scaler is the same as its absolute value, but with a 180
              degree phase shift).  
*/
-setScale:(double)val;
/* Sets scale factor. */

/*!
  @method shouldOptimize:
  @param arg is an unsigned.
  @result Returns an BOOL.
  @discussion Specifies that all arguments are to be optimized if possible.
*/
+(BOOL)shouldOptimize:(unsigned) arg;
/* Specifies that all arguments are to be optimized if possible. */

@end

#endif
