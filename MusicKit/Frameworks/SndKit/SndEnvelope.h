////////////////////////////////////////////////////////////////////////////////
//
//  SndEnvelope.h
//  SndKit
//
//  Created by stephen brandon on Mon Jun 23 2001. <stephen@brandonitconsulting.co.uk>
//  Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and 
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////
#ifndef __SNDENVELOPE_H__
#define __SNDENVELOPE_H__

#import <Foundation/Foundation.h>
#import "SndBreakpoint.h"

#define BP_NOT_FOUND (-1)

/*!
@protocol SndEnveloping
@abstract declare formal protocol for objects to be used as envelopes
@discussion This protocol describes the minimum functionality required from
              a class for it to be able to function within SndAudioFader as an
              envelope storage and lookup class. The primary implementation of
              this protocol is the SndEnvelope class, but it is intended that
              the MusicKit's MKEnvelope should noform to SndEnveloping too in
              future, by way of a category.<br>
              As the protocol is used for envelopes used in shaping audio
              streams just before audio output, implementations should be as
              fast and efficient as possible.<BR>
              An envelope in this context is a series of <i>breakpoints</i>,
              which describe points on a graph of some parameter vs. time.
              If the parameter being described is amplitude, the envelope might
              hold the following breakpoints: amplitude 0.9 at time 0.0,
              amplitude 0.5 at time 3.0, amplitude 0.6 at time 10.03.<br>
              Further to these x (time) and y (amplitude) values however,
              SndEnveloping implementations also hold information with each
              breakpoint about how that breakpoint relates or joins to its
              surrounding breakpoints. Should each y value be held static until
              the next breakpoint arrives (stepping), or should the value of
              the parameter move steadily from one point to another (ramping)?<br>
              SndEnveloping itself does not make any assumptions about these flags;
              it simply defines their existance and provides a means for them to
              be accessed by the calling object. Nevertheless, a SndEnveloping
              implementation is free to make assumptions about these flags if
              it wishes - in fact, it will need to make some decisions like this
              in order to implement -lookupYForX: for inter-breakpoint
              x-values.<br>
              SndEnveloping defines the following types for use in its
              breakpoints: x-values (time) are doubles, y-values are floats (eg
              for amplitudes of 0.0 to 1.0, or balance values from -1.0 to +1.0),
              and flags are signed integers. Breakpoint indices are signed ints,
              as they need to allow for BP_NOT_FOUND, which can returned by
              the -breakpointIndex... methods as an error value.
*/
@protocol SndEnveloping

//- (double)lookupYForXAsymptotic:(double)xVal;

/*! @method     lookupYForX:
    @abstract   Returns a y value for the given x value, according to its internal
                envelope.
    @discussion Implementations are free to implement this in any way they wish,
                but the most obvious implementation is to return a linear interpolation
                between adjacent breakpoints, if the given x vale does not correspond
                exactly with a breakpoint.
    @param      xVal (assumed positive)
    @result     float
*/
- (float)lookupYForX:(double)xVal;

/*! @method     breakpointIndexBeforeOrEqualToX:
    @abstract   Returns the index of the last breakpoint with exactly the given xVal,
                or the last breakpoint with less than the given xVal.
    @discussion Returns BP_NOT_FOUND if xVal is less than the x value of the first
                breakpoint, or if there are no breakpoints.
    @param      xVal
    @result     int
*/
- (int) breakpointIndexBeforeOrEqualToX:(double)xVal;

/*! @method     breakpointIndexAfterX:
    @abstract   Returns the index of the first breakpoint with an x value greater
                than the given xVal.
    @discussion Returns BP_NOT_FOUND if there are no breakpoints after xVal.
    @param      xVal
    @result     int
*/
- (int) breakpointIndexAfterX:(double)xVal;

/*! @method     lookupXForBreakpoint:
    @abstract   Returns the x value corresponding to the requested breakpoint.
    @discussion Behaviour is undefined (implementation specific) if the breakpoint
                does not exist. There's no point in returning BP_NOT_FOUND as that
                could be a valid x value to return.
    @param      bp
    @result     double a valid x value
*/
- (double) lookupXForBreakpoint:(int)bp;

/*! @method     lookupYForBreakpoint:
    @abstract   Returns the y value corresponding to the requested breakpoint.
    @discussion Behaviour is undefined (implementation specific) if the breakpoint
                does not exist. There's no point in returning BP_NOT_FOUND as that
                could be a valid y value to return.
    @param      bp
    @result     To come
*/
- (float) lookupYForBreakpoint:(int)bp;

/*! @method     lookupFlagsForBreakpoint:
    @abstract   Returns the flags corresponding to the requested breakpoint.
    @discussion Behaviour is undefined (implementation specific) if the breakpoint
                does not exist. There's no point in returning BP_NOT_FOUND as that
                could be a valid flags value to return.
    @param      bp
    @result     To come
*/
- (int) lookupFlagsForBreakpoint:(int)bp;

/*! @method     breakpointCount
    @abstract   Returns the number of breakpoints in the envelope
    @discussion
    @result     int the number of breakpoints in the envelope
*/
- (int) breakpointCount;

/*! @method     insertXValue:yValue:flags:
    @abstract   Creates a new breakpoint in the envelope and returns the
                new breakpoint index
    @discussion Subsequent breakpoints have their indices incremented by one
    @param      xVal
    @param      yVal
    @param      flags
    @result     returns new breakpoint index
*/
- (int) insertXValue:(double)xVal yValue:(float)yVal flags:(int)flags;

/*! @method     insertXValue:yValue:flags:atBreakpoint:
    @abstract   Creates a new breakpoint with the given data, and inserts it in
                the envelope at the specified location
    @discussion If you know in advance that a given breakpoint should be slotted
                in at a given index, use this method instead of -insertXValue:yValue:flags:,
                as this avoids unecessary walking through the breakpoints.
                Implementations are not obligated to actually use the given
                breakpoint, but must return the actual index used.
    @param      xVal
    @param      yVal
    @param      flags
    @param      bp
    @result     int the index of the inserted breakpoint
*/
- (int) insertXValue:(double)xVal yValue:(float)yVal flags:(int)flags atBreakpoint:(int)bp;

/*! @method     removeBreakpoint:
    @abstract   Removes the breakpoint at the specified index
    @discussion
    @param      bp
    @result     BOOL whether or not a breakpoint was removed
*/
- (BOOL) removeBreakpoint:(int)bp;

/*! @method     removeBreakpointsBefore:
    @abstract   Removes all breakpoints with index less than (not including) the
                index specified
    @discussion
    @param      aBreakpoint
    @result     BOOL whether or not any breakpoints were removed
*/
- (BOOL) removeBreakpointsBefore:(int)bp;

/*! @method     removeBreakpointsAfter:
    @abstract   Removes all breakpoints with index greater than (not including) the
                index specified
    @discussion
    @param      bp
    @result     BOOL whether or not any breakpoints were removed
*/
- (BOOL) removeBreakpointsAfter:(int)aBreakpoint;

/*! @method     replaceXValue:yValue:flags:atBreakpoint:
    @abstract   Changes the values at a specified breakpoint
    @discussion If you just want to change one value, you'll need to request all
                the other values from the specified breakpoint first, then call
                this method.
    @param      xVal
    @param      yVal
    @param      flags
    @param      bp
    @result     BOOL whether or not the operation was successful
*/
- (BOOL) replaceXValue:(double)xVal yValue:(float)yVal flags:(int)flags atBreakpoint:(int)bp;

@end

/*!
@class SndEnvelope
@abstract Provide enveloping data for audio streams
@discussion SndEnvelope is the reference implementation of the SndEnveloping protocol,
            and the default class used by SndAudioFader for the real time shaping
            of audio streams.<BR>
            One of the primary aims of this class is <b>speed</b>, so the access to
            the underlying arrays of SndBreakpoints has been optimised with the use
            of selector caching.<BR>
            For full documentation, see the documentation for the SndEnveloping protocol.
*/
@interface SndEnvelope : NSObject <SndEnveloping>
{
/*! @var lock locks changes to the envelope objects */
  NSLock *lock;  
/*! @var breakpoints SndBreakpoint objects */
  NSMutableArray *breakpoints; 
}

/*! @method     breakpointIndexBeforeOrEqualToX:
    @abstract   Returns the index of the first breakpoint with an x value greater
                than the given xVal
    @discussion See the SndEnveloping protocol
    @param      See the SndEnveloping protocol
    @result     See the SndEnveloping protocol
*/
- (int) breakpointIndexBeforeOrEqualToX:(double)xVal;

/*! @method     breakpointIndexAfterX:
    @abstract   Returns the x value corresponding to the requested breakpoint
    @discussion See the SndEnveloping protocol
    @param      See the SndEnveloping protocol
    @result     See the SndEnveloping protocol
*/
- (int) breakpointIndexAfterX:(double)xVal;

/*! @method     lookupYForBreakpoint:
    @abstract   Returns the y value corresponding to the requested breakpoint
    @discussion See the SndEnveloping protocol
    @param      See the SndEnveloping protocol
    @result     See the SndEnveloping protocol
*/
- (float) lookupYForBreakpoint:(int)bp;

/*! @method     insertXValue:yValue:flags:
    @abstract   Creates a new breakpoint in the envelope and returns the
                new breakpoint index
    @discussion See the SndEnveloping protocol
    @param      xVal
    @param      yVal
    @param      flags
    @result     Returns new breakpoint index
*/
- (int) insertXValue:(double)xVal yValue:(float)yVal flags:(int)flags;

/*! @method     insertXValue:yValue:flags:atBreakpoint:
    @abstract   Creates a new breakpoint with the given data, and inserts it in
                the envelope at the specified location
    @discussion See the SndEnveloping protocol
    @param      xVal
    @param      yVal
    @param      flags
    @param      bp
    @result     See the SndEnveloping protocol
*/
- (int) insertXValue:(double)xVal yValue:(float)yVal flags:(int)flags atBreakpoint:(int)bp;

/*! @method     removeBreakpoint:
    @abstract   Removes the breakpoint at the specified index
    @discussion See the SndEnveloping protocol
    @param      aBreakpoint
    @result     See the SndEnveloping protocol
*/
- (BOOL) removeBreakpoint:(int)aBreakpoint;

/*! @method     removeBreakpointsBefore:
    @abstract   Removes all breakpoints with index less than (not including) the
                index specified
    @discussion See the SndEnveloping protocol
    @param      aBreakpoint
    @result     See the SndEnveloping protocol
*/
- (BOOL) removeBreakpointsBefore:(int)aBreakpoint;

/*! @method     removeBreakpointsAfter:
    @abstract   Removes all breakpoints with index greater than (not including) the
                index specified
    @discussion See the SndEnveloping protocol
    @param      aBreakpoint
    @result     See the SndEnveloping protocol
*/
- (BOOL) removeBreakpointsAfter:(int)aBreakpoint;

/*! @method     replaceXValue:yValue:flags:atBreakpoint:
    @abstract   Changes the values at a specified breakpoint
    @discussion See the SndEnveloping protocol
    @param      xVal 
    @param      yVal
    @param      flags
    @param      bp
    @result     See the SndEnveloping protocol
*/
- (BOOL) replaceXValue:(double)xVal yValue:(float)yVal flags:(int)flags atBreakpoint:(int)bp;

@end

////////////////////////////////////////////////////////////////////////////////

#endif

