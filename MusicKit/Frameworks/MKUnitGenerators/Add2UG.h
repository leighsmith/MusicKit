/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    Add2UG  - from dsp macro /usr/lib/dsp/ugsrc/add2.asm (see source for details).
    Outputs the sum of two input signals. 

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Delays and Time-Modification Units
/*!
  @class Add2UG
  @abstract <b>Add2UG</b> adds two patchpoints.
  @discussion

Add2UG produces the sum of two input signals:
	
<i>output</i> = <i>input1</i> + <i>input2</i>

   You allocate one of the subclasses Add2UG<i>a</i><i>b</i><i>c</i>, where <i>a</i> is the output 
   space, <i>b</i> is the space of the first input and <i>c</i> is the space of the
   second input.   This unit generator is faster if <i>b</i> is x and <i>c</i> is y.

<h2>Memory Spaces</h2>

<b>Add2UG<i>abc</i></b>

<i>a	</i>output
<i>b	</i>input 1
<i>c	</i>input 2
*/
#ifndef __MK_Add2UG_H___
#define __MK_Add2UG_H___

#import <MusicKit/MKUnitGenerator.h>

@interface Add2UG:MKUnitGenerator

+(BOOL)shouldOptimize:(unsigned) arg;
/* Specifies that all arguments are to be optimized if possible */

/*!
  @method setInput1:
  @param  aPatchpoint is an id.
  @result Returns an id.
  @discussion Sets the input 1 patchpoint to <i>aPatchpoint</i>.  Returns
              <b>self</b> or <b>nil</b> if the argument isn't a
              patchpoint.
*/
-setInput1:aPatchPoint;
/* Sets input1 of adder. */


/*!
  @method setInput2:
  @param  aPatchpoint is an id.
  @result Returns an id.
  @discussion Sets the input 2 patchpoint to <i>aPatchpoint</i>.  Returns
              <b>self</b> or <b>nil</b> if the argument isn't a
              patchpoint.
*/
-setInput2:aPatchPoint;
/* Sets input2 of adder. */


/*!
  @method setOutput:
  @param  aPatchpoint is an id.
  @result Returns an id.
  @discussion Sets the output patchpoint to <i>aPatchpoint</i>.  Returns
              <b>self</b> or <b>nil</b> if the argument isn't a
              patchpoint.
*/
-setOutput:aPatchPoint;
/* Sets output of adder. */

@end

#endif
