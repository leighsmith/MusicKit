////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    View showing the current layout of Snd streaming components.
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDKIT_SNDSTREAMARCHITECTUREVIEW_H_
#define __SNDKIT_SNDSTREAMARCHITECTUREVIEW_H_

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class SndAudioArchViewObject;
@class SndStreamClient;
@class SndAudioProcessorChain;

////////////////////////////////////////////////////////////////////////////////

/*!
@class SndStreamArchitectureView
@brief View showing the current layout of Snd streaming components
  (rudimentary)

  Shows the manager, mixer, clients and processors attached to each.
  User may click on any object to see their current description
  (updated every second). Object then becomes the currentObject,
  which triggers a message to an interested delegate which, for
  example, may wish to activate an editor for that object. An example
  of this behaviour may be found in <b>SndAudioProcessorInspector</b>.
*/
@interface SndStreamArchitectureView : NSView 
{
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
  @brief   NSTimer callback that forces a fresh of the view.
  
  To come
  @param      timer
  @return     self
*/
- update: (NSTimer *) timer;

/*!
  @brief   To come
  
  For internal use only
  @param      client
  @param      rect
  @return     self
*/
- drawStreamClient: (SndStreamClient *) client inRect: (NSRect) rect;

/*!
  @brief   To come
  
  For internal use only
  @param      rect
  @return     self
*/
- drawMixerInRect: (NSRect) rect;

/*!
  @brief   To come
  
  For internal use only
  @param      rect
  @return     self
*/
- drawStreamManagerInRect: (NSRect) rect;

/*!
  @brief   To come
  
  For internal use only
  @param      apc
  @param      rect
  @return     self
*/
- drawAudioProcessorChain: (SndAudioProcessorChain *) apc inRect: (NSRect) rect;

/*!
  @brief   To come  
  @param      aRect
  @param      aColor
  @return     self
*/
- drawRect: (NSRect) aRect withColor: (NSColor *) aColor;

/*!
  @brief   To come  
  @param      theEvent
*/
- (void) mouseUp: (NSEvent *) theEvent;

/*!
  @brief   To come
  @param      delegate
  @return     self
*/
- (void) setDelegate: (id) delegate;

/*!
  @brief   To come
  @return     A delegate id.
*/
- (id) delegate;

/*!
  @brief   To come  
  @return     Returns the id of the current, user selected audio architecture object.
*/
- (id) currentlySelectedAudioArchObject;

/*!
  @brief   Clears the currently selected audio architecture object to nil.
  @return     self.
*/
- clearCurrentlySelectedAudioArchObject;

@end

////////////////////////////////////////////////////////////////////////////////
// Simple informal delegate protocol
////////////////////////////////////////////////////////////////////////////////

/*! @protocol SndStreamArchitectureViewDelegateProtocol
*/
@protocol SndStreamArchitectureViewDelegateProtocol
/*!
  @brief   sent to delegate when an on-screen audio object (mixer, processor
  manager, client) is clicked by the user.
  
  
  @param      sndAudioArchDisplayObject
  @return
*/
- didSelectObject: (id) sndAudioArchDisplayObject;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
