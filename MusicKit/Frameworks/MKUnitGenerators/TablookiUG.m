#import <MusicKit/MusicKit.h>
#import "_exportedPrivateMusickit.h"
#import "TablookiUG.h"

@implementation TablookiUG:MKUnitGenerator
/* Interpolated Table lookup.
	You instantiate a subclass of the form 
	TablookUG<a><b><c>, where 
	<a> = space of output
	<b> = space of input
	<c> = space of table
*/	
{
}

enum args { ainv, atablook, halflen, aout };

#import "tablookiUGInclude.m"

+(BOOL)shouldOptimize:(unsigned) arg
{
    return YES;
}

- setInput:(id)aPatchPoint {
	return [self setAddressArg:ainv to:aPatchPoint];
}

- setOutput:(id)aPatchPoint {
	return [self setAddressArg:aout to:aPatchPoint];
}

- setLookupTable:(id)aSynthData {
    int length;
    if (!aSynthData)
      return self;
    length = [aSynthData length];
    if (length % 2 == 0) /* It's even */
      length--;
    [self setAddressArg:atablook to:aSynthData];
    return [self setDatumArg:halflen to:(length-1)/2];
}

- idleSelf {
	[self setAddressArgToSink:aout];
	return self;
}

@end
