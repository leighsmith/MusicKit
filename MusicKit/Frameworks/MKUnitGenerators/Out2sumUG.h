/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    Out2sumUG - from dsp macro /usr/lib/dsp/ugsrc/out2sum.asm (see source for details).

   Out2sum writes its input signal to both channels of the stereo output 
   sample stream of the DSP, adding into that stream. 
   The stream is cleared before each DSP tick (each orchestra program 
   iteration). Out2sum also provides individual scaling on each output channel.
   The method setBearing: allows a convenient way to control the proportion
   of the signal sent to each channel.

   You instantiate a subclass of the form 
   Out2sumUG<a>, where <a> = space of input

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Sound Inputs and Outputs
/*!
  @class Out2sumUG
  @abstract <b>Out2sumUG</b> sends its monaural input patchpoint to a stereo output stream,
            panning the sound as indicated by its memory arguments.
  @discussion

Out2sumUG adds its input signal to the DSP's stereo output stream.  The signal
is placed (or &ldquo;imaged&rdquo;) between the two channels according to the
value set through the <b>setBearing:</b> or <b>setBearing:scale:</b> method. 
Alternatively, you can set the gain of either channel independently, through the
<b>setRightScale:</b> and <b>setLeftScale:</b> methods. 

To write to just the left or just the right channel of the stereo ouput stream,
you should use an Out1aUG or Out1bUG object, respectively.  Where the samples
that are written to the DSP output stream are ultimately sent - whether to
sound-out or to a soundfile - depends on the state of the Orchestra from which
the Out1aUG or Out1bUG object was allocated.  By default, the Orchestra sends
the samples to sound-out.

If you're building SynthPatch subclasses, you should note that every SynthPatch
object should have its own signal-output UnitGenerator; in other words, you
don't allocate just one such object and then share it amongst the various
SynthPatches.  The output signals produced by all the running Out1aUG's,
Out1bUG's, and Out2sumUG's are mixed (added) together into the DSP's output
stream.

<h2>Memory Spaces</h2>

<b>Out2sumUG<i>a</i></b>
<i>a</i>	input 
*/
#ifndef __MK_Out2sumUG_H___
#define __MK_Out2sumUG_H___

#import <MusicKit/MKUnitGenerator.h>

@interface Out2sumUG : MKUnitGenerator
{
  BOOL _reservedOut2sum1; 
  double bearingScale;
}

/*!
  @method shouldOptimize:
  @param arg is an unsigned.
  @result Returns an BOOL.
  @discussion Specifies that all arguments are to be optimized if possible.
*/
+(BOOL)shouldOptimize:(unsigned) arg;

/*!
  @method setLeftScale:
  @param  (double)value is an id.
  @result Returns <b>self</b>.
  @discussion Sets the factor by which the signal that's written to the left
              output channel is scaled.  By default, the scaler is set to a value
              that's just a tad less than 1.0.  Effective values are between 0.0
              and 1.0 (a negative <i>value</i> is the same as its absolute value,
              but with a 180 degree phase shift).  
*/
-setLeftScale:(double)val;
/* Sets scaling for left channel. */ 


/*!
  @method setRightScale:
  @param  (double)value is an id.
  @result Returns <b>self</b>.
  @discussion Sets the factor by which the signal that's written to the right
              output channel is scaled.  By default, the scaler is set to a value
              that lacks 1.0 by a speck.    Effective values are between 0.0 and
              1.0 (a negative <i>value</i> is the same as its absolute value, but
              with a 180 degree phase shift).  
*/
-setRightScale:(double)val;
/* Sets scaling for right channel. */ 


/*!
  @method setBearing:
  @param  (double)degrees is an id.
  @result Returns <b>self</b>.
  @discussion Distributes the input signal between the two output channels
              according to the value of <i>degrees</i>:  0.0 degrees is center,
              -45.0 is hard left, 45.0 is hard right.  Bearing is reflected as
              <i>degrees</i> exceeds the boundaries; thus, for example, 50.0
              degrees is the same as 40.0, 60.0 is 30.0, 90.0 is 0.0, and so on. 
              
*/
-setBearing:(double)val;
/* As a convenience, you can set both scaleA and scaleB with a single 
   message. 

   When val is 0, the signal is equally distributed between the two channels.
   When val is -45, you get the left channel, +45 you get the right channel.
   Val = 90 is the same as val = 0. */  


/*!
  @method setBearing:scale:
  @param  (double)degrees is an id.
  @param  value is a double.
  @result Returns <b>self</b>.
  @discussion This is the same as <b>setBearing:</b>, but the input signal is
              scaled by <i>value</i>, which should be between 0.0 and 1.0, before
              being distributed.  
*/
-setBearing:(double)val scale:(double)aScale;
/* Same as setBearing:, but including an overall amp scaling factor independent
   of bearing. */


/*!
  @method runSelf
  @result Returns an id.
  @discussion If bearing has not been set, sets it to 0.0.  This method is invoked
              when you send the <b>run</b> message to the object.
*/
-runSelf;
/* If bearing has not been set, sets it to 0. */


/*!
  @method idleSelf
  @result Returns an id.
  @discussion You never send this message.  It's invoked by sending the
              <b>idle</b> message to the object.   Since Out2sum has no outputs,
              it idles itself by patching its inputs to <i>zero</i>. Thus, an idle
              Out2sum makes no sound.   Note that you must send <b>setInput:</b>
              and <b>run</b> again to use the MKUnitGenerator after sending
              <b>idle</b>.
*/
-idleSelf;
/* Since Out2sum has no outputs, it idles itself by patching its inputs
   to zero. Thus, an idle Out2sum makes no sound. */ 


/*!
  @method setInput:
  @param  aPatchpoint is an id.
  @result Returns an id.
  @discussion Sets the input patchpoint to <i>aPatchpoint</i>.  Returns <b>nil</b>
              if the argument isn't a patchpoint; otherwise returns
              <b>self</b>.
*/
-setInput:aPatchPoint;
/* Sets input patch point. */
@end

#endif
