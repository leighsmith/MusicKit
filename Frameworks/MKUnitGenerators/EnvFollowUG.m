/* EnvFollowUG implements a sample-level simple envelope follower, which
 * tracks the peaks of the signal.  It has a three arguments, the input
 * patchpoint, the output patchpoint, and the release parameter.  The release
 * value controls how quickly the envelope responds to amplitude changes.  It
 * generally should have a value between 0.9 and 0.99.
 *
 * This version operates at the sample-level.  It is more responsive than the
 * tick-level version (EnvFollowtUG).
 */

#import "EnvFollowUG.h"

@implementation EnvFollowUG:MKUnitGenerator
{
}

enum args {
    ainp, s, aout, rel
};

#import "envFollowUGInclude.m"

- setInput:(id) aPatchPoint
{
    return[self setAddressArg:ainp to:aPatchPoint];
}

- setOutput:(id) aPatchPoint
{
    return[self setAddressArg:aout to:aPatchPoint];
}

- setRelease:(double)value
{
    return MKSetUGDatumArg(self, rel, DSPDoubleToFix24(value));
}

- init
{
    if (![super init])
	return nil;
    /* Initialize instance variables here */
    return self;
}

- idleSelf
{
    [self setAddressArgToSink:aout];
    return self;
}

- runSelf
{
    return self;
}

@end





