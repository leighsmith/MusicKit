/* AmpenvfollowUG implements a sample-level simple envelope follower, which
 * tracks the peaks of the signal.  It has a three arguments, the input
 * patchpoint, the output patchpoint, and the release parameter.  The release
 * value controls how quickly the envelope responds to amplitude changes.  It
 * generally should have a value between 0.9 and 0.99.
 *
 * This version operates at the sample-level.  It is more responsive than the
 * tick-level version (AmpenvfollowtUG).
 */

#import <MusicKit/MKUnitGenerator.h>

@interface EnvFollowUG : MKUnitGenerator
{
}

- setInput:(id) aPatchPoint;
- setOutput:(id) aPatchPoint;
- setRelease:(double)value;
- init;
- idleSelf;
- runSelf;


@end
