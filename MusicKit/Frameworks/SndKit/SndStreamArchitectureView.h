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

////////////////////////////////////////////////////////////////////////////////

@interface SndStreamArchitectureView : NSView {
  NSTimer                   *timer;
  NSMutableArray            *displayObjectsArray;
  NSMutableAttributedString *msg;
  id                         currentSndArchObject;
  NSLock                    *objectArrayLock;
  id                         delegate;
}

- initWithFrame: (NSRect) frameRect;
- update: (NSTimer*) timer;
- (void) drawRect: (NSRect) rect;
- drawStreamClient: (SndStreamClient*) client inRect: (NSRect) rect;
- drawMixerInRect: (NSRect) rect;
- drawStreamManagerInRect: (NSRect) rect;
- drawAudioProcessorChain: (SndAudioProcessorChain*) apc inRect: (NSRect) rect;
- drawRect: (NSRect) aRect withColor: (NSColor*) aColor;
- (void) mouseUp: (NSEvent*) theEvent;
- setDelegate: (id) delegate;
- (id) delegate;

@end

@interface SndStreamArchitectureViewDelegateProtocol

- didSelectObject: (id) sndAudioArchDisplayObject;

@end

////////////////////////////////////////////////////////////////////////////////

#endif