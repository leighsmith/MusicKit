/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    BiquadUG.h - Two-pole, two-zero, filter section, with gain.

    The BiquadUG unit-generator implements a two-pole, two-zero filter
    section in direct form.  The output space can only be y DSP memory.
    Therefore, only two leaf classes exist, BiquadUGx and BiquadUGy,
    corresponding to the two possible input spaces.

    The biquad transfer function is

                             -1         -2
                 1  +  b1 * z   + b2 * z
      H(z) = g * -------------------------
                             -1         -2
                 1  +  a1 * z   + a2 * z

    The biquad difference equation which implements H(z) is

     v(n) = g * x(n) - a1 * v(n-1) - a2 * v(n-2);
     y(n) =     v(n) + b1 * v(n-1) + b2 * v(n-2);

    where n denotes the current sample time, x(n) is the input signal at
    time n, y(n) is the output signal, and v(n) is an intermediate signal
    between the poles section and the zeros section.  This is the
    so-called direct-form digital filter structure, which follows
    immediately from the transfer function definiteion.  In the DSP, which
    uses fixed-point arithmetic, the so-called "transposed direct form" is
    used instead to avoid the possibility of internal overflow of v(n).
    However, the transfer function is equivalent. See Digital Signal
    Processing by A.V. Oppenheim and R.W.  Schafer (Prentice-Hall, 1975,
    p. 155) for further discussion.

    You instantiate a subclass of the form 
    BiquadUG<a><b>, where <a> = space of output and <b> = space of input.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Filters
/*!
  @class BiquadUG
  @brief <b>BiquadUG</b> is a two-pole, two-zero filter useful for adding resonances. 
  
  

The <b>BiquadUG</b> unit-generator implements a two-pole, two-zero filter
section in direct form.  The output space can only be <i>y</i> DSP memory.   
Therefore, only two leaf classes exist, <b>BiquadUGx</b> and <b>BiquadUGy</b>,
corresponding to the two possible input spaces.

The biquad transfer function is

<pre>
<tab>  -1         -2
<tab>  1  +  b1 * z   + b2 * z
<tab>H(z) = g * -------------------------
<tab>  -1         -2
<tab>  1  +  a1 * z   + a2 * z
</pre>

The biquad difference equation which implements H(z) is

<pre>
v(n) = g * x(n) - a1 * v(n-1) - a2 * v(n-2);
y(n) =  v(n) + b1 * v(n-1) + b2 * v(n-2);
</pre>

where n denotes the current sample time, x(n) is the input signal at time n,
y(n) is the output signal, and v(n) is an intermediate signal.  This is the
so-called "transposed direct form II" digital filter structure, which
avoids the possibility of internal overflow. See Digital Signal
Processing by A.V. Oppenheim and R.W. Schafer (Prentice-Hall, 1975,
p. 155) for further discussion.

<h2>Memory Spaces</h2>

<b>BiquadUG<i>ab</i></b>
<i>a</i>	output
<i>b</i>	input
*/
#ifndef __MK_BiquadUG_H___
#define __MK_BiquadUG_H___

#import <MusicKit/MKUnitGenerator.h>

@interface BiquadUG : MKUnitGenerator
{
}


/*!
  @param  aPatchPoint is an id.
  @return Returns an id.
  @brief Sets filter input.

  
*/
- setInput:(id)aPatchPoint;
 /* Sets filter input. */


/*!
  @param  aPatchPoint is an id.
  @return Returns an id.
  @brief Sets filter output.

  
*/
- setOutput:(id)aPatchPoint;
 /* Sets filter output. */


/*!
  @return Returns an id.
  @brief Clear internal filter state.

  
*/
- clear;
 /* Clear internal filter state. */

/*!
  @param  d1 is a double.
  @return Returns an id.
  @brief Sets the internal filter state of the first delayed
  sample.

  
*/
- setFirstDelayedSample:(double)d1;

/*!
  @param  d2 is a double.
  @return Returns an id.
  @brief Sets the internal filter state of the second delayed
  sample.

  
*/
- setSecondDelayedSample:(double)d2;

 /* The following four methods set the corresponding coefficients.  See
  * discussion above. 
  */

/*!
  @param  a1 is a double.
  @return Returns an id.
  @brief Sets the A1 filter coefficient.

  
*/
- setA1:(double)a1;

/*!
  @param  a2 is a double.
  @return Returns an id.
  @brief Sets the A2 filter coefficient..

  
*/
- setA2:(double)a2;

/*!
  @param  b1 is a double.
  @return Returns an id.
  @brief Sets the B1 filter coefficient..

  
*/
- setB1:(double)b1;

/*!
  @param  b2 is a double.
  @return Returns an id.
  @brief Sets the B2 filter coefficient..

  
*/
- setB2:(double)b2;


/*!
  @param  g is a double.
  @return Returns an id.
  @brief Sets gain of filter.

  
*/
- setGain:(double)g;
 /* Sets gain of filter. */

/*!
  @param arg is an unsigned.
  @return Returns an BOOL.
  @brief Specifies that all arguments are to be optimized if possible except the
  state variable.

  
*/
+(BOOL)shouldOptimize:(unsigned) arg;
 /* Specifies that all arguments are to be optimized if possible except the
  * filter state. */

 /* The following provide more convenient ways to talk to the filters. */

/*!
  @param  r is a double.
  @param  t is a double.
  @return Returns an id.
  @brief This method provides a convenient way to set the filter feedback
  coefficients.

  Sets the coefficients such as to provide the
  specified pole radius and angle.  The angle is in radians.
  
*/
- setComplexPolesRadius:(double)r angle:(double)t;
 /* Sets the coefficients such as to provide the specified pole radius and
  * angle.  The angle is in radians. */


/*!
  @param  r is a double.
  @param  t is a double.
  @return Returns an id.
  @brief This method provides a convenient way to set the filter feedforward
  coefficients.

  Sets the coefficients such as to provide the
  specified zero radius and angle.  The angle is in radians.
  
*/
- setComplexZerosRadius:(double)r angle:(double)t;
 /* Sets the coefficients such as to provide the specified zero radius and
  * angle.  The angle is in radians. */


/*!
  @param  f is a double.
  @param  b is a double.
  @return Returns an id.
  @brief This method provides a convenient way to set the filter feedback
  coefficients.

  Sets the coefficients such as to provide the
  specified center frequency and bandwidth.  The angle is in radians.
  
*/
- setComplexPolesFrequency:(double)f bandwidth:(double)b;
 /* Sets the coefficients such as to place the poles at the specified freq
  * and bandwidth. */


/*!
  @param  f is a double.
  @param  b is a double.
  @return Returns an id.
  @brief This method provides a convenient way to set the filter feedforward
  coefficients.

  Sets the coefficients such as to provide the
  specified center frequency and bandwidth.  The angle is in radians.
  
*/
- setComplexZerosFrequency:(double)f bandwidth:(double)b;
 /* Sets the coefficients such as to place the zeros at the specified freq
  * and bandwidth. */

/*!
  @param  f is a double.
  @param  t60 is a double.
  @return Returns an id.
  @brief Sets the coefficients such as to place the poles at the specified freq
  with the given t60 value.

  t60 is the time, in seconds, to decay to 
  -60 dB.              
*/
- setComplexPolesFrequency:(double)f t60:(double)t60;

@end

#endif
