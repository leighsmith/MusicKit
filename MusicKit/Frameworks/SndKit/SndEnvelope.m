////////////////////////////////////////////////////////////////////////////////
//
//  SndEnvelope.m
//  SndKit
//
//  Created by S Brandon on Wed Jun 25 2001. <stephen@brandonitconsulting.co.uk>
//  Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and non-
//  commercial purposes so long as the author attribution and copyright messages
//  remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import "SndEnvelope.h"

typedef double (*GetXValIMP)(id, SEL);
typedef id (*ObjAtIndexIMP)(id, SEL,int);

static SEL objAtIndexSel;
static SEL getXValSel;
static GetXValIMP    getXVal;

@implementation SndEnvelope

+ (void)initialize
{
    if (self == [SndEnvelope class]) {
        [SndEnvelope setVersion:1];
    }
    objAtIndexSel = @selector(objectAtIndex:);
    getXValSel = @selector(getXVal);
    getXVal = (GetXValIMP)[SndBreakpoint instanceMethodForSelector:getXValSel];
}

- init
{
    [super init];
    breakpoints = [[NSMutableArray alloc] init];
    return self;
}

int indexOfBreakpointAfter(double inVal, NSMutableArray *inArray)
{
    int i, count = [inArray count];
    SndBreakpoint *sb;
    ObjAtIndexIMP objAtIndex = (ObjAtIndexIMP)[inArray methodForSelector:objAtIndexSel];
    for (i = 0 ; i < count ; i++) {
        sb = objAtIndex(inArray,objAtIndexSel,i);
        if (getXVal(sb,getXValSel) > inVal)
            return i;
    }
    return -1;
}

- (int) breakpointIndexBeforeOrEqualToX:(double)xVal
{
    int r,count;
    if (!breakpoints) return -1;
    count = [breakpoints count];
    if (!count) return -1;
    r = indexOfBreakpointAfter(xVal,breakpoints);
    /* returns -1 if the 0th element is greater than the input */
    return (r == -1) ? count - 1 : r - 1 ;
}

- (int) breakpointIndexAfterX:(double)xVal
{
    return indexOfBreakpointAfter(xVal,breakpoints);
}

- (double) lookupXForBreakpoint:(int)bp
{
    int count = [breakpoints count];
    if (bp >= count) return -1;// raise exception?
    return [[breakpoints objectAtIndex:bp] getXVal];
}

- (float) lookupYForBreakpoint:(int)bp
{
    int count = [breakpoints count];
    if (bp >= count) return 0;// raise exception?
    return [[breakpoints objectAtIndex:bp] getYVal];
}

- (int) lookupFlagsForBreakpoint:(int)bp
{
    int count = [breakpoints count];
    if (bp >= count) return 0;// raise exception?
    return [[breakpoints objectAtIndex:bp] getFlags];

}

- (float)lookupYForX:(double)xVal
{
    int justAfterIndex; //,justBeforeOrEqualIndex;
    float justAfterYVal,justBeforeOrEqualYVal;
    double justAfterXVal,justBeforeOrEqualXVal;
    int count = [breakpoints count];
    float proportion;

    if (!count || !breakpoints) {
        return 0;
    }
    justAfterIndex = indexOfBreakpointAfter(xVal,breakpoints);
    /* if we've spilled off the end, assume we stay at last point */
    if (justAfterIndex == -1) {
        return [(SndBreakpoint*)[breakpoints objectAtIndex:count-1] getXVal];
    }
    /* if the point is before our first breakpoint, it's undefined, so 0 */
    if (justAfterIndex == 0) {
        return 0;
    }
    justAfterXVal =
        [(SndBreakpoint*)[breakpoints objectAtIndex:justAfterIndex] getXVal];
    justBeforeOrEqualXVal =
        [(SndBreakpoint*)[breakpoints objectAtIndex:justAfterIndex - 1] getXVal];
    justAfterYVal =
        [(SndBreakpoint*)[breakpoints objectAtIndex:justAfterIndex] getYVal];
    justBeforeOrEqualYVal =
        [(SndBreakpoint*)[breakpoints objectAtIndex:justAfterIndex - 1] getYVal];

    proportion = (xVal - justBeforeOrEqualXVal) /
        (justAfterXVal - justBeforeOrEqualXVal);
    return justBeforeOrEqualYVal + proportion *
        (justAfterYVal - justBeforeOrEqualYVal);
}

/* returns new breakpoint index */
- (int) insertXValue:(double)xVal yValue:(float)yVal flags:(int)flags;
{
    int i,count;
//    double max=0.0;
    double tempMax;
    SndBreakpoint *sb;
    ObjAtIndexIMP objAtIndex;

    if (!breakpoints) {
        breakpoints = [[NSMutableArray alloc] init];
    }
    objAtIndex = (ObjAtIndexIMP)[breakpoints methodForSelector:objAtIndexSel];
    count = [breakpoints count];
    for (i = 0 ; i < count ; i++) {
        sb = objAtIndex(breakpoints,objAtIndexSel,i);
        tempMax = getXVal(sb,getXValSel);
        /* if there are other breakpoints with same x value, place this one after them */
        if (tempMax > xVal) {
            break;
        }
    }
    i = [self insertXValue:xVal yValue:yVal flags:flags atBreakpoint:i];
    return i;

}

/* returns new breakpoint index */
- (int) insertXValue:(double)xVal yValue:(float)yVal flags:(int)flags atBreakpoint:(int)bp
{
//    int i;
    int count;
    SndBreakpoint *newBreakpoint;

    if (!breakpoints) {
        breakpoints = [[NSMutableArray alloc] init];
    }
    count = [breakpoints count];
    newBreakpoint = [[SndBreakpoint alloc] initWithX:xVal y:yVal flags:flags];
    if (bp >= count) {
        [breakpoints addObject:newBreakpoint];
        [newBreakpoint release]; /* let the array hold the release */
        return count;
    }
    [breakpoints insertObject:newBreakpoint atIndex:bp];
    [newBreakpoint release];
    return bp;
}

- (BOOL) removeBreakpoint:(int)aBreakpoint
{
    int count;
    if (!breakpoints) return NO;
    count = [breakpoints count];
    if (aBreakpoint >= count) return NO;
    [breakpoints removeObjectAtIndex:aBreakpoint];
    return YES;
}

- (BOOL) removeBreakpointsBefore:(int)aBreakpoint
{
//    int i;
    int count;
    NSRange delRange;
    /* no point removing all breakpoints before breakpoint 0 */
    if (!breakpoints || aBreakpoint < 1) return NO;
    count = [breakpoints count];
    if (!count) return NO;
    if (aBreakpoint >= count) {
        [breakpoints removeAllObjects];
        return YES;
    }
    delRange.location = 0;
    delRange.length = aBreakpoint - 1;
    [breakpoints removeObjectsInRange:delRange];
    return YES;
}

- (BOOL) removeBreakpointsAfter:(int)aBreakpoint
{
//    int i;
    int count;
    NSRange delRange;
    if (!breakpoints) return NO;
    count = [breakpoints count];
    if (!count) return NO;
    /* no point removing everything after the last object */
    if (aBreakpoint >= count - 1) return NO;
    delRange.location = (aBreakpoint >= 0) ? aBreakpoint + 1: 0;
    delRange.length = count - delRange.location;
    [breakpoints removeObjectsInRange:delRange];
    return YES;
}

- (BOOL) replaceXValue:(double)xVal yValue:(float)yVal flags:(int)flags atBreakpoint:(int)bp
{
    int count;
    SndBreakpoint *newBreakpoint;
    if (!breakpoints) return NO;
    count = [breakpoints count];
    if (bp >= count) return NO;
    newBreakpoint = [[SndBreakpoint alloc] initWithX:xVal y:yVal flags:flags];
    [breakpoints replaceObjectAtIndex:bp withObject:newBreakpoint];
    [newBreakpoint release];
    return YES;
}
- (int) breakpointCount
{
    if (!breakpoints) return 0;
    return [breakpoints count];
}
- (void) dealloc
{
    [breakpoints release];
    [super dealloc];
}


@end

