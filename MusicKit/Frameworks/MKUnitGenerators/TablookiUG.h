/*
  $Id$
  
  Defined In: The MusicKit
  Description:

  Original Author: Written by Eric J. Graves at Princeton University, as a part of
                   Princeton's Music 324 (Computer Music) course (during April-May 1992,
                   taught by David Jaffe).  David Jaffe revised it in Sept. 93.

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Table Lookup
/*!
  @class TablookiUG
  @abstract <b>TablookiUG</b> does interpolated table lookup, using its input as an index into the table.
  @discussion

TablookiUG does interpolated table-lookup.   It takes its input, which is
assumed to be between -1 and 1, scales it so that -1.0 maps onto the start of
the table and 1.0 maps onto the end of the table, then does a lookup and returns
the corresponding table value.  If the computed address is not an integer,
TablookiUG does linear interpolation between table values - thus, it gives a
high-quality mapping. 

To use it in a Waveshaping context, simply use an oscillator as the input to the
TablookiUG and set the TablookiUG's table to the appropriate distortion table. 
For an example, see the Waveshape MKSynthPatch in the Music Kit's MKSynthPatch
library.

<i>Note that the table size should be odd.</i>  This gives a symetrical table. 
For example, if the table size is 101, the point at 50 represents 0, there are
50 points corresponding to negative input (0-49, inclusive) and 50 points 
corresponding to positive input (51-100, inclusive). 

<h2>Memory Spaces</h2>

<b>TablookiUG<i>abc</i></b>
<i>a</i>	output
<i>b</i>	input
<i>c</i>	lookup table memory
*/
#ifndef __MK_TablookiUG_H___
#define __MK_TablookiUG_H___

#import <MusicKit/MKUnitGenerator.h>

@interface TablookiUG : MKUnitGenerator
{
}

/*!
  @method shouldOptimize:
  @param arg is an unsigned.
  @result Returns an BOOL.
  @discussion Specifies that all arguments are to be optimized if possible.
*/
+(BOOL)shouldOptimize:(unsigned) arg;

/*!
  @method setInput:
  @param  aPatchpoint is an id.
  @result Returns an id.
  @discussion Sets the input patchpoint to <i>aPatchpoint</i>.  Returns <b>nil</b>
              if the argument isn't a patchpoint; otherwise returns
              <b>self</b>.
*/
- setInput:(id)aPatchPoint;

/*!
  @method setOutput:
  @param  aPatchpoint is an id.
  @result Returns an id.
  @discussion Sets the output patchpoint to <i>aPatchpoint</i>.   Returns
              <b>nil</b> if the argument isn't a patchpoint; otherwise returns
              <b>self</b>.
*/
- setOutput:(id)aPatchPoint;

/*!
  @method setLookupTable:
  @param  aSynthData is an id.
  @result Returns <b>self</b>.
  @discussion Sets the SynthData object used as the lookup table to
              <i>aSynthData</i>.   The table size must be odd.   If
              <i>aSynthData</i> has an even length, the top-most point is not
              used.  
*/
- setLookupTable:(id)aSynthData;

/*!
  @method idleSelf
  @result Returns an id.
  @discussion You never send this message.  It's invoked by sending the
              <b>idle</b> message to the object.  
              Sets the output patchpoint, as well as the delay memory, to 
              <i>sink</i>, thus ensuring that the object does not produce
              any output.  Note that you must send <b>setOutput:</b> and
              <b>run </b>again to use the MKUnitGenerator after sending <b>idle</b>.
*/
- idleSelf;

@end
#endif
