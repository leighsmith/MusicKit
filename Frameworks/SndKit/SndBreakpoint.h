////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Created by Stephen Brandon on Wed Jun 25 2001. <stephen@brandonitconsulting.co.uk>
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
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
@class SndBreakpoint
@brief  A simple storage class allowing SndEnvelope breakpoint information to
  be stored in NSArrays

  This class is used primarily by SndEnvelope, the default envelope class
  utilised by SndAudioFader. It is unlikely that this class should need to
  be subclassed.<BR>
  The contents of the "flags" iVar are defined in SndAudioFader.h
  (see SND_FADER_ATTACH_RAMP_RIGHT etc.). Although SndBreakpoint objects
  are not accessed directly by SndAudioFader, the information they hold
  is intrinsic to the SndEnveloping protocol (see SndEnvelope.h).
*/

@interface SndBreakpoint : NSObject
{
/*! holds flags pertaining to the state of the breakpoint, eg whether it is part of a ramp */
  int    flags;
/*! the y value of the breakpoint, generally -1 to +1 for balance, or 0 to +1 for amplitude */
  float  yVal;
/*! the x value of the breakpoint, a time value measured from the start of the stream */
  double xVal;
}

/*!
  @brief   Convenience method for creating breakpoints.
  @param      x The x value of the breakpoint
  @param      y The y value of the breakpoint
  @param      f The flags to be associated with the breakpoint
  @return     self, a newly initialised SndBreakpoint
*/
- initWithX:(double)x y:(float)y flags:(int)f;


/*!
  @brief   Returns the flags associated with the breakpoint
  @return     int representing the flags associated with the breakpoint
*/
- (int)    getFlags;

/*!
  @brief   Returns the y value of the breakpoint
  @return     float
*/
- (float)  getYVal;

/*!
  @brief   Returns the x value of the breakpoint
  @return     double
*/
- (double) getXVal;

/*!
  @brief   Sets new flags for the breakpoint
  @param      f The flags to be associated with the breakpoint
*/
- (void) setFlags: (int) f;

/*!
  @brief   Sets new y value for the breakpoint
  @param      yVal
*/
- (void) setYVal: (float) yVal;

/*!
  @brief   Sets x value for the breakpoint
  @param      xVal
*/
- (void) setXVal: (double) xVal;

/*!
  @brief   Allows easy array sorting according to x (time) value
  
  Example of use: <tt>[arrayOfBreakpoints sortUsingSelector: \@selector(compare:)]</tt>
  @param      other another SndBreakpoint
  @return     NSComparisonResult
*/
- (NSComparisonResult) compare: (SndBreakpoint *) other;

@end

#endif

