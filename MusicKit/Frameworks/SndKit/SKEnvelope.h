////////////////////////////////////////////////////////////////////////////////
//
//  SKEnvelope.h
//  SndKit
//
//  Created by stephen brandon on Mon Jun 23 2001. <stephen@brandonitconsulting.co.uk>
//  Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and non-commercial
//  purposes so long as the author attribution and copyright messages remain intact and
//  accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////
#ifndef __SKENVELOPE_H__
#define __SKENVELOPE_H__

#import <Foundation/Foundation.h>
#import "SKBreakpoint.h"

/*
 * declare formal protocol for objects to be used as envelopes
 */
@protocol SKEnveloping
- (float)lookupYForX:(double)xVal;
//- (double)lookupYForXAsymptotic:(double)xVal;

- (int) breakpointIndexBeforeOrEqualToX:(double)xVal;
- (int) breakpointIndexAfterX:(double)xVal;
- (double) lookupXForBreakpoint:(int)bp;
- (float) lookupYForBreakpoint:(int)bp;
- (int) lookupFlagsForBreakpoint:(int)bp;
- (int) breakpointCount;

/* returns new breakpoint index */
- (int) insertXValue:(double)xVal yValue:(float)yVal flags:(int)flags;
- (int) insertXValue:(double)xVal yValue:(float)yVal flags:(int)flags atBreakpoint:(int)bp;
- (BOOL) removeBreakpoint:(int)aBreakpoint;
- (BOOL) removeBreakpointsBefore:(int)aBreakpoint;
- (BOOL) removeBreakpointsAfter:(int)aBreakpoint;
- (BOOL) replaceXValue:(double)xVal yValue:(float)yVal flags:(int)flags atBreakpoint:(int)bp;

@end

@interface SKEnvelope : NSObject <SKEnveloping>
{
  NSLock *lock; // locks changes to the envelope objects
  NSMutableArray *breakpoints; /* SKBreakpoint objects */
}

- (int) breakpointIndexBeforeOrEqualToX:(double)xVal;
- (int) breakpointIndexAfterX:(double)xVal;
- (float) lookupYForBreakpoint:(int)bp;
/* returns new breakpoint index */
- (int) insertXValue:(double)xVal yValue:(float)yVal flags:(int)flags;
- (int) insertXValue:(double)xVal yValue:(float)yVal flags:(int)flags atBreakpoint:(int)bp;
- (BOOL) removeBreakpoint:(int)aBreakpoint;
- (BOOL) removeBreakpointsBefore:(int)aBreakpoint;
- (BOOL) removeBreakpointsAfter:(int)aBreakpoint;
- (BOOL) replaceXValue:(double)xVal yValue:(float)yVal flags:(int)flags atBreakpoint:(int)bp;

- (void) dealloc;

@end

#endif

