////////////////////////////////////////////////////////////////////////////////
//
//  SndBreakpoint.m
//  SndKit
//
//  Created by S Brandon on Mon Jun 23 2001. <stephen@brandonitconsulting.co.uk>
//  Copyright (c) 2001 SndKit project
//
//  Permission is granted to use and modify this code for commercial and non-
//  commercial purposes so long as the author attribution and copyright messages
//  remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import "SndBreakpoint.h"

@implementation SndBreakpoint

- initWithX:(double)x y:(float)y flags:(int)f
{
    [super init];
    flags = f;
    xVal = x;
    yVal = y;
    return self;
}

- init
{
    [super init];
    flags = 0;
    xVal = 0;
    yVal = 0;
    return self;
}

- (int)    getFlags { return flags; }
- (float)  getYVal  { return yVal; }
- (double) getXVal  { return xVal; }

- (void) setFlags: (int) f   { flags = f; }
- (void) setYVal: (float) y  { yVal = y; }
- (void) setXVal: (double) x { xVal = x; }

/* allow easy array sorting */
- (NSComparisonResult) compare:(SndBreakpoint *)other
{
    double otherValue, myValue;
    if (other == self) return NSOrderedSame;
    if (other == nil) {
        [NSException raise:NSInvalidArgumentException
                    format:@"nil argument for compare:"];
    }
    myValue = xVal;
    otherValue = [other getXVal];
    
    if ( myValue == otherValue ) {
        return NSOrderedSame;
    }
    if (myValue < otherValue ) {
        return NSOrderedAscending;
    }
    return NSOrderedDescending;
}
@end

