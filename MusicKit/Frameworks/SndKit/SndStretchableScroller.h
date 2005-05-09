//
//  $Id$
//
//  Original Author: Leigh Smith and Skot McDonald.
//
//  Copyright (c) 2004, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and 
//  non-commercial purposes so long as the author attribution and copyright 
//  messages remain intact and accompany all relevant code.
//

#import <AppKit/AppKit.h>

/*!
  @class SndStretchableScroller
  @brief A subclass of NSScroller that adds two handles that allows stretching the scroller, signalling that
  the enclosed scrollable object should be resized, typically changing magnification.
 */
@interface SndStretchableScroller: NSScroller {
  /*! stretchingLeftKnob YES when the left knob is being stretched. */
  BOOL stretchingLeftKnob;
  /*! stretchingRightKnob YES when the right knob is being stretched. */
  BOOL stretchingRightKnob;
}

/*!
  @brief The new drawing method which draws the stretch icons.
 */
- (void) drawKnob;

/*!
  @brief The new mouse event method that detects and updates the scroller.
  @param theEvent An NSEvent
 */ 
- (void) mouseDown: (NSEvent *) theEvent;

@end
