/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    AmpenvfollowUG implements a sample-level simple envelope follower, which
    tracks the peaks of the signal.  It has a three arguments, the input
    patchpoint, the output patchpoint, and the release parameter.  The release
    value controls how quickly the envelope responds to amplitude changes.  It
    generally should have a value between 0.9 and 0.99.

    This version operates at the sample-level.  It is more responsive than the
    tick-level version (AmpenvfollowtUG).

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Envelope Handlers and Followers
/*!
  @class EnvFollowUG
  @abstract <b>EnvFollowUG</b> derives an amplitude envelope from an input signal.
  @discussion

EnvFollowUG is an envelope follower, that tracks the peaks of a signal.  It
converts an arbitrary signal to an envelope-like signal that is always positive
and changes relatively slowly. 

<h2>Memory Spaces</h2>

<b>DelayUG<i>ab</i></b>
<i>a</i>	output
<i>b</i>	input
*/

#import <MusicKit/MKUnitGenerator.h>

@interface EnvFollowUG : MKUnitGenerator
{
}

/*!
  @method setInput:
  @param  aPatchpoint is an id.
  @result Returns an id.
  @discussion Sets the input patchpoint to <i>aPatchpoint</i>.  Returns <b>nil</b>
              if the argument isn't a patchpoint; otherwise returns
              <b>self</b>.
*/
- setInput:(id) aPatchPoint;

/*!
  @method setOutput:
  @param  aPatchpoint is an id.
  @result Returns an id.
  @discussion Sets the output patchpoint to <i>aPatchpoint</i>.   Returns
              <b>nil</b> if the argument isn't a patchpoint; otherwise returns
              <b>self</b>.
*/
- setOutput:(id) aPatchPoint;

/*!
  @method setRelease:
  @param  (double)val is an id.
  @result Returns an id.
  @discussion Release determines how quickly the object responds to amplitude
              changes. More precisely, it is the coefficient of the one-pole
              filter that implements the envelope decay. Typical values are
              between 0.9 and 0.99.
*/
- setRelease:(double)value;

- init;
- idleSelf;
- runSelf;

@end
