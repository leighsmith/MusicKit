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
@abstract
@discussion
*/

@interface SndBreakpoint : NSObject
{
  int    flags;
  float  yVal;
  double xVal;
}

- initWithX:(double)x y:(float)y flags:(int)f;

- (int)    getFlags;
- (float)  getYVal;
- (double) getXVal;

- (void) setFlags: (int) f;
- (void) setYVal: (float) yVal;
- (void) setXVal: (double) xVal;

/* allow easy array sorting */
- (NSComparisonResult) compare:(SndBreakpoint *)other;

@end

#endif

