////////////////////////////////////////////////////////////////////////////////
//
//  SndStreamArchitectureView.h
//  SndKit
//
//  Created by SKoT McDonald on Mon Dec 24 2001.
//  Copyright (c) 2001 tomandandy. All rights reserved.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDKIT_SNDSTREAMARCHITECTUREVIEW_H_
#define __SNDKIT_SNDSTREAMARCHITECTUREVIEW_H_

#import <Foundation/Foundation.h>

@class SndAudioArchViewObject;
@class SndStreamClient;
@class SndAudioProcessorChain;

////////////////////////////////////////////////////////////////////////////////

/*!
@class      SndStreamArchitectureView
@abstract
@discussion To come
*/
@interface SndStreamArchitectureView : NSView {
/*! @var timer */ 
  NSTimer *timer;
/*! @var displayObjectsArray */ 
  NSMutableArray *displayObjectsArray;
/*! @var msg */ 
  NSMutableAttributedString *msg;
/*! @var  currentSndArchObject */ 
  id      currentSndArchObject;
/*! @var  objectArrayLock */ 
  NSLock *objectArrayLock;
/*! @var delegate */ 
  id      delegate;
}

/*!
  @method     initWithFrame:
  @abstract
  @discussion
  @param      frameRect
  @result     self
*/
- initWithFrame: (NSRect) frameRect;
/*!
  @method     update:
  @abstract
  @discussion
  @param      timer
  @result     self
*/
- update: (NSTimer*) timer;
/*!
  @method     drawRect:
  @abstract
  @discussion
  @param      rect
*/
- (void) drawRect: (NSRect) rect;
/*!
  @method     drawStreamClient:inRect:
  @abstract
  @discussion
  @param      client
  @param      rect
  @result     self
*/
- drawStreamClient: (SndStreamClient*) client inRect: (NSRect) rect;
/*!
  @method     drawMixerInRect:
  @abstract
  @discussion
  @param      rect
  @result     self
*/
- drawMixerInRect: (NSRect) rect;
/*!
  @method     drawStreamManagerInRect:
  @abstract
  @discussion
  @param      rect
  @result     self
*/
- drawStreamManagerInRect: (NSRect) rect;
/*!
  @method     drawAudioProcessorChain:inRect:
  @abstract
  @discussion
  @param      apc
  @param      rect
  @result     self
*/
- drawAudioProcessorChain: (SndAudioProcessorChain*) apc inRect: (NSRect) rect;
/*!
  @method     drawRect:withColor:
  @abstract
  @discussion
  @param      aRect
  @param      aColor
  @result     self
*/
- drawRect: (NSRect) aRect withColor: (NSColor*) aColor;
/*!
  @method     mouseUp:
  @abstract
  @discussion 
  @param      theEvent
*/
- (void) mouseUp: (NSEvent*) theEvent;
/*!
  @method     setDelegate:
  @abstract
  @discussion
  @param      delegate
  @result     self
*/
- setDelegate: (id) delegate;
/*!
  @method     delegate
  @abstract
  @discussion
  @result     A delegate id.
*/
- (id) delegate;

- (id) currentlySelectedAudioArchObject;
- clearCurrentlySelectedAudioArchObject;

@end

////////////////////////////////////////////////////////////////////////////////
// Simple informal delegate protocol
////////////////////////////////////////////////////////////////////////////////

@interface SndStreamArchitectureViewDelegateProtocol
/*!
  @method     didSelectObject:
  @abstract   sent to delegate when an on-screen audio object (mixer, processor
              manager, client) is clicked by the user.
  @discussion
  @param      sndAudioArchDisplayObject
  @result
*/
- didSelectObject: (id) sndAudioArchDisplayObject;

@end

////////////////////////////////////////////////////////////////////////////////

#endif