////////////////////////////////////////////////////////////////////////////////
//
//  SndEnvelope.h
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
#ifndef __SNDENVELOPE_H__
#define __SNDENVELOPE_H__

#import <Foundation/Foundation.h>
#import "SndBreakpoint.h"

#define BP_NOT_FOUND (-1)

/*!
  @protocol   SndEnveloping
  @abstract   declare formal protocol for objects to be used as envelopes
  @discussion To come
*/
@protocol SndEnveloping

//- (double)lookupYForXAsymptotic:(double)xVal;

/*! @method     lookupYForX:
    @abstract   To come
    @discussion To come
    @param      xVal
    @result     To come
*/
- (float)lookupYForX:(double)xVal;
/*! @method     breakpointIndexBeforeOrEqualToX:
    @abstract   To come
    @discussion To come
    @param      xVal
    @result     To come
*/
- (int) breakpointIndexBeforeOrEqualToX:(double)xVal;
/*! @method     breakpointIndexAfterX:
    @abstract   To come
    @discussion To come
    @param      xVal
    @result     To come
*/
- (int) breakpointIndexAfterX:(double)xVal;
/*! @method     lookupXForBreakpoint:
    @abstract   To come
    @discussion To come
    @param      bp
    @result     To come
*/
- (double) lookupXForBreakpoint:(int)bp;
/*! @method     lookupYForBreakpoint:
    @abstract   To come
    @discussion To come
    @param      bp
    @result     To come
*/
- (float) lookupYForBreakpoint:(int)bp;
/*! @method     lookupFlagsForBreakpoint:
    @abstract   To come
    @discussion To come
    @param      bp
    @result     To come
*/
- (int) lookupFlagsForBreakpoint:(int)bp;
/*! @method     breakpointCount
    @abstract   To come
    @discussion To come
    @result     To come
*/
- (int) breakpointCount;
/*! @method     insertXValue:yValue:flags:
    @abstract   To come
    @discussion To come
    @param      xVal
    @param      yVal
    @param      flags
    @result     returns new breakpoint index
*/
- (int) insertXValue:(double)xVal yValue:(float)yVal flags:(int)flags;
/*! @method     insertXValue:yValue:flags:atBreakpoint:
    @abstract   To come
    @discussion To come
    @param      xVal
    @param      yVal
    @param      flags
    @param      bp
    @result     To come
*/
- (int) insertXValue:(double)xVal yValue:(float)yVal flags:(int)flags atBreakpoint:(int)bp;
/*! @method     removeBreakpoint:
    @abstract   To come
    @discussion To come
    @param      aBreakpoint
    @result     To come
*/
- (BOOL) removeBreakpoint:(int)aBreakpoint;
/*! @method     removeBreakpointsBefore:
    @abstract   To come
    @discussion To come
    @param      aBreakpoint
    @result     To come
*/
- (BOOL) removeBreakpointsBefore:(int)aBreakpoint;
/*! @method     removeBreakpointsAfter:
    @abstract   To come
    @discussion To come
    @param      aBreakpoint
    @result     To come
*/
- (BOOL) removeBreakpointsAfter:(int)aBreakpoint;
/*! @method     replaceXValue:yValue:flags:atBreakpoint:
    @abstract   To come
    @discussion To come
    @param      xVal
    @param      yVal
    @param      flags
    @param      bp
    @result     To come
*/
- (BOOL) replaceXValue:(double)xVal yValue:(float)yVal flags:(int)flags atBreakpoint:(int)bp;

@end

/*!
@class      SndEnvelope
@abstract   To come
@discussion To come
*/
@interface SndEnvelope : NSObject <SndEnveloping>
{
/*! @var lock locks changes to the envelope objects */
  NSLock *lock;  
/*! @var breakpoints SndBreakpoint objects */
  NSMutableArray *breakpoints; 
}

/*! @method     
    @abstract   To come
    @discussion To come
    @param      
    @result     To come
*/
- (int) breakpointIndexBeforeOrEqualToX:(double)xVal;
/*! @method     
    @abstract   To come
    @discussion To come
    @param      
    @result     To come
*/
- (int) breakpointIndexAfterX:(double)xVal;
/*! @method     
    @abstract   To come
    @discussion To come
    @param      
    @result     To come
*/
- (float) lookupYForBreakpoint:(int)bp;
/*! @method     insertXValue:yValue:flags:
    @abstract   To come
    @discussion To come
    @param      xVal
    @param      yVal
    @param      flags
    @result     Returns new breakpoint index
*/
- (int) insertXValue:(double)xVal yValue:(float)yVal flags:(int)flags;
/*! @method     insertXValue:yValue:flags:atBreakpoint:
    @abstract   To come
    @discussion To come
    @param      xVal
    @param      yVal
    @param      flags
    @param      bp
    @result     To come
*/
- (int) insertXValue:(double)xVal yValue:(float)yVal flags:(int)flags atBreakpoint:(int)bp;
/*! @method     removeBreakpoint:
    @abstract   To come
    @discussion To come
    @param      aBreakpoint
    @result     To come
*/
- (BOOL) removeBreakpoint:(int)aBreakpoint;
/*! @method     removeBreakpointsBefore:
    @abstract   To come
    @discussion To come
    @param      aBreakpoint
    @result     To come
*/
- (BOOL) removeBreakpointsBefore:(int)aBreakpoint;
/*! @method     removeBreakpointsAfter:
    @abstract   To come
    @discussion To come
    @param      aBreakpoint
    @result     To come
*/
- (BOOL) removeBreakpointsAfter:(int)aBreakpoint;
/*! @method     replaceXValue:yValue:flags:atBreakpoint:
    @abstract   To come
    @discussion To come
    @param      xVal 
    @param      yVal
    @param      flags
    @param      bp
    @result     To come
*/
- (BOOL) replaceXValue:(double)xVal yValue:(float)yVal flags:(int)flags atBreakpoint:(int)bp;
/*! @method     dealloc
    @abstract   To come
    @discussion To come
*/
- (void) dealloc;

@end

#endif

