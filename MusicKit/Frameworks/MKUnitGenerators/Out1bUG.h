/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    Out1bUG - from dsp macro /usr/lib/dsp/ugsrc/out1b.asm (see source for details).

    Out1b writes its input signal to the mono output stream, or channel 1 (right)
    of the stereo output sample stream of the DSP, adding into that stream.
    The stream is cleared before each DSP tick (each orchestra program 
    iteration). Out1b also provides a scaling on the output channel.

    You instantiate a subclass of the form 
    Out1bUG<a>, where <a> = space of input

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Sound Inputs and Outputs
/*!
  @class Out1bUG
  @abstract <b>Out1bUG</b> simply writes its input patchpoint to the right channel.
  @discussion

Out1aUG, Out1bUG and Out1nUG provide single-channel access to the DSP's stereo
output stream.   Out1aUG writes its input signal to the left channel, Out1bUG
writes to the right channel and Out1nUG allows the channel to be set with a
method.  To write a stereo signal, it may be more convenient to use a single
Out2sumUG object rather than one of each of these.    

Where the samples that are written to the DSP output stream are ultimately sent
- whether to sound-out, to the DSP serial port, or to a soundfile - depends on
the state of the MKOrchestra from which the Out1aUG, Out1bUG or Out1nUG object was
allocated.  By default, the MKOrchestra sends the samples to sound-out.

If you're building a MKSynthPatch subclass, you should note that every MKSynthPatch
object should have its own signal-output MKUnitGenerator; in other words, you
don't allocate just one such object and then share it amongst the various
MKSynthPatches.  The output signals produced by all the running Out1aUG's,
Out1bUG's, Out1nUG's and Out2sumUG's are mixed (added) together into the DSP's
output stream.

Out1nUG additionally makes possible quadraphonic (or other multi-channel)
output, with the proper external serial port device.   Additionally, the
orchestra must be set up as follows:
	
<tt>
[anOrch setSerialSoundOut:YES];	
[anOrch setSerialPortDevice:[[<i>QuadSerialPortDevice</i> alloc] init]];	
[anOrch open];
</tt>

where <i>QuadSerialPortDevice </i>is a custom subclass of <b>DSPSerialPortDevice</b>
that overrides the <b>-outputChannelCount</b> method to return 4 and overrides the
<b>-setUpSerialPort:</b> method to send the correct settings for the particular device.

<h2>Memory Spaces</h2>

<b>Out1bUG<i>a</i></b>
<i>a</i>	input 
*/
#ifndef __MK_Out1bUG_H___
#define __MK_Out1bUG_H___

#import <MusicKit/MKUnitGenerator.h>

@interface Out1bUG : MKUnitGenerator
{
  BOOL _reservedOut1b1; 
}

/*!
  @method shouldOptimize:
  @param arg is an unsigned.
  @result Returns an BOOL.
  @discussion Specifies that all arguments are to be optimized if possible.
*/
+(BOOL)shouldOptimize:(unsigned) arg;

/*!
  @method setScale:
  @param  value is a double.
  @result Returns <b>self</b>.
  @discussion Sets the factor by which the input signal is scaled for the right channel.  By default,
              the scaler is set to 1.0.  Effective values are between 0.0 and 1.0
              (negative values are the same as their absolute values, but with a
              180 degree phase shift).  
*/
-setScale:(double) val;

/*!
  @method runSelf
  @result Returns an id.
  @discussion If scale has not been set, sets it to 1.0.  This method is invoked
              when you send the <b>run </b>message to the object.
*/
-runSelf;
/* If scaling has not been set, sets it to 1-e. */


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
