////////////////////////////////////////////////////////////////////////////////
//
//  SndBreakpoint.h
//  SndKit
//
//  Created by Stephen Brandon on Wed Jun 25 2001. <stephen@brandonitconsulting.co.uk>
//  Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and non-commercial
//  purposes so long as the author attribution and copyright messages remain intact and
//  accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////
#ifndef __SNDBREAKPOINT_H__
#define __SNDBREAKPOINT_H__

#import <Foundation/Foundation.h>

/*!
@class      SndBreakpoint
@abstract   A simple storage class allowing SndEnvelope breakpoint information to
            be stored in NSArrays
@discussion This class is used primarily by SndEnvelope, the default envelope class
            utilised by SndAudioFader. It is unlikely that this class should need to
            be subclassed.<BR>
            The contents of the "flags" iVar are defined in SndAudioFader.h
            (see SND_FADER_ATTACH_RAMP_RIGHT etc.). Although SndBreakpoint objects
            are not accessed directly by SndAudioFader, the information they hold
            is intrinsic to the SndEnveloping protocol (see SndEnvelope.h).
*/

@interface SndBreakpoint : NSObject
{
/*! @var flags holds flags pertaining to the state of the breakpoint, eg whether it is part of a ramp */
  int    flags;
/*! @var yVal the y value of the breakpoint, generally -1 to +1 for balance, or 0 to +1 for amplitude */
  float  yVal;
/*! @var xVal the x value of the breakpoint, a time value measured from the start of the stream */
  double xVal;
}

/*!
    @method     initWithX:y:flags
    @abstract   Convenience method for creating breakpoints.
    @param      x The x value of the breakpoint
    @param      y The y value of the breakpoint
    @param      f The flags to be associated with the breakpoint
    @result     self, a newly initialised SndBreakpoint
*/
- initWithX:(double)x y:(float)y flags:(int)f;


/*!
    @method     getFlags
    @abstract   Returns the flags associated with the breakpoint
    @result     int representing the flags associated with the breakpoint
*/
- (int)    getFlags;

/*!
    @method     getYVal
    @abstract   Returns the y value of the breakpoint
    @result     float
*/
- (float)  getYVal;

/*!
    @method     getXVal
    @abstract   Returns the x value of the breakpoint
    @result     double
*/
- (double) getXVal;

/*!
    @method     setFlags:
    @abstract   Sets new flags for the breakpoint
    @param      f The flags to be associated with the breakpoint
*/
- (void) setFlags: (int) f;

/*!
    @method     setYVal:
    @abstract   Sets new y value for the breakpoint
    @param      yVal
*/
- (void) setYVal: (float) yVal;

/*!
    @method     setXVal:
    @abstract   Sets x value for the breakpoint
    @param      xVal
*/
- (void) setXVal: (double) xVal;

/*!
    @method     compare:
    @abstract   Allows easy array sorting according to x (time) value
    @discussion Example of use: [arrayOfBreakpoints sortUsingSelector:&#64;selector(compare:)]
    @param      other another SndBreakpoint
    @return     NSComparisonResult
*/
- (NSComparisonResult) compare:(SndBreakpoint *)other;

@end

#endif

