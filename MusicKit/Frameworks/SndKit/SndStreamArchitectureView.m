////////////////////////////////////////////////////////////////////////////////
//
//  SndStreamArchitectureView.m
//  SndKit
//
//  Created by SKoT McDonald on Mon Dec 24 2001.
//  Copyright (c) 2001 tomandandy. All rights reserved.
//
////////////////////////////////////////////////////////////////////////////////

#import "SndStreamManager.h"
#import "SndStreamArchitectureView.h"

//////////////////////////////////////////////////////////////////////////////// 
// SndAudioArchViewObject
////////////////////////////////////////////////////////////////////////////////

@class SndAudioArchViewObject;

@interface SndAudioArchViewObject : NSObject
{
  NSRect rect;
  id     sndAudioArchObject;
}
- initWithRect: (NSRect) r andSndAudioArchObject: (id) object;
- (void) dealloc;
- (NSRect) rect;
- (id) sndAudioArchObject;

@end

@implementation SndAudioArchViewObject

- initWithRect: (NSRect) r andSndAudioArchObject: (id) object
{
  [super init];
  rect = r;
  if (sndAudioArchObject != nil)
    [sndAudioArchObject release];  
  sndAudioArchObject = [object retain];
  return self;
}

- (void) dealloc
{
  if (sndAudioArchObject != nil)
    [sndAudioArchObject release];    
}

- (NSRect) rect
{
  return rect;
}

- (id) sndAudioArchObject
{
  return [[sndAudioArchObject retain] autorelease];
}

@end

////////////////////////////////////////////////////////////////////////////////
// SndStreamArchitectureView
////////////////////////////////////////////////////////////////////////////////

@implementation SndStreamArchitectureView

////////////////////////////////////////////////////////////////////////////////
// initWithFrame:
////////////////////////////////////////////////////////////////////////////////

- initWithFrame: (NSRect) frameRect
{
  self = [super initWithFrame: frameRect];

  objectArrayLock = [[NSLock alloc] init];

  currentSndArchObject = nil;
  timer = [NSTimer scheduledTimerWithTimeInterval: 1
                                  target: self
                                         selector: @selector(update:)
                                userInfo: nil
                                 repeats: TRUE];

  if (displayObjectsArray != nil)
    [displayObjectsArray removeAllObjects];
  else
    displayObjectsArray = [[NSMutableArray alloc] init];

  msg = [[NSMutableAttributedString alloc] initWithString: @"Ready."];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
  [displayObjectsArray release];
  if (currentSndArchObject != nil)
    [currentSndArchObject release];
  [objectArrayLock release];

  [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// update:
////////////////////////////////////////////////////////////////////////////////

- update: (NSTimer*) timer
{
  [self setNeedsDisplay: TRUE];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// drawRect:
////////////////////////////////////////////////////////////////////////////////

- (void) drawRect: (NSRect) rect
{
  [objectArrayLock lock];

  NSEraseRect([self bounds]);

  // Frame the rect
  [self drawRect: rect withColor: [NSColor blackColor]];
  [displayObjectsArray removeAllObjects];

  // Draw the root node
  {
    NSRect mr, xr;
    
    xr.origin.x    = rect.size.width  * 3 / 7;
    xr.origin.y    = rect.size.height * 2 / 7;
    xr.size.width  = rect.size.width / 7;
    xr.size.height = rect.size.height / 7;
    [self drawMixerInRect: xr];
    {
      id theSndArchObj = [[SndStreamManager defaultStreamManager] mixer];
      id theDisplayObj = [[SndAudioArchViewObject alloc] initWithRect: xr andSndAudioArchObject: theSndArchObj];
      [displayObjectsArray addObject: theDisplayObj];
    }

    mr = xr;
    mr.origin.y = rect.size.height * 1 / 7;
    [self drawStreamManagerInRect: mr];
    {
      id theSndArchObj = [SndStreamManager defaultStreamManager];
      id theDisplayObj = [[SndAudioArchViewObject alloc] initWithRect: mr andSndAudioArchObject: theSndArchObj];
      [displayObjectsArray addObject: theDisplayObj];
    }
    
    {
      // Draw each of the stream clients
      SndStreamMixer *mixer   = [[SndStreamManager defaultStreamManager] mixer];
      int c = [mixer clientCount], i;
      for (i=0;i<c;i++) {
        NSRect cr;
        cr.size.width  = rect.size.width / 7;
        cr.size.height = rect.size.height/ 7;
        cr.origin.x    = rect.size.width * (i+1)/(c+1) - cr.size.width/2;
        cr.origin.y    = rect.size.height * 5 / 7;
        {
          id theSndArchObj = [mixer clientAtIndex: i];
          id theDisplayObj = [[SndAudioArchViewObject alloc] initWithRect: cr andSndAudioArchObject: theSndArchObj];
          [self drawStreamClient: theSndArchObj inRect: cr];
          [displayObjectsArray addObject: theDisplayObj];
        }
        
        {
          NSBezierPath *userPath  = [NSBezierPath bezierPath]; // user path for drawing segments
          NSPoint p1 = xr.origin;
          [[NSColor redColor] set];
          p1.y += xr.size.height;
          p1.x += xr.size.width / 2;
          [userPath moveToPoint: p1];
          p1 = cr.origin;
          p1.x += cr.size.width/2;
          [userPath lineToPoint: p1];
          [userPath stroke];
        }
        {
          NSPoint p = {5,10};
          if (currentSndArchObject == nil)
            [msg initWithString: @"Ready"];
          else
            [msg initWithString: [currentSndArchObject description]];
          [msg drawAtPoint: p];
        }
      }
    }
  }
  [objectArrayLock unlock];  
}

////////////////////////////////////////////////////////////////////////////////
// drawStreamClient:atOrigin:
////////////////////////////////////////////////////////////////////////////////

- drawStreamClient: (SndStreamClient*) client inRect: (NSRect) rect
{
  NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString: [client clientName]];
  NSRange r = {0, [s length]};
  [self drawRect: rect withColor: [NSColor blackColor]];
  [s setAlignment: NSCenterTextAlignment range: r];
  [s drawInRect: rect];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// drawRootNodeAtOrigin:
////////////////////////////////////////////////////////////////////////////////

- drawMixerInRect: (NSRect) rect
{
  NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString: @"Mixer"];
  NSRange r = {0, [s length]};
  [self drawRect: rect withColor: [NSColor blackColor]];
  [s setAlignment: NSCenterTextAlignment range: r];
  [s drawInRect: rect];
  {
    SndStreamMixer *mixer = [[SndStreamManager defaultStreamManager] mixer];
    SndAudioProcessorChain *apc = [mixer audioProcessorChain];
    NSRect r = rect;
    r.origin.x += rect.size.width + 10;
    [self drawAudioProcessorChain: apc inRect: r];
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// drawRootNodeAtOrigin:
////////////////////////////////////////////////////////////////////////////////

- drawStreamManagerInRect: (NSRect) rect
{
  NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString: @"Manager"];
  NSRange r = {0, [s length]};
  [self drawRect: rect withColor: [NSColor blackColor]];
  [s setAlignment: NSCenterTextAlignment range: r];
  [s drawInRect: rect];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// 
////////////////////////////////////////////////////////////////////////////////

- drawAudioProcessorChain: (SndAudioProcessorChain*) apc inRect: (NSRect) rect
{
  int c = [apc processorCount], i;
  for (i = 0; i < c; i++) {
    SndAudioProcessor           *ap = [apc processorAtIndex: i];
    NSMutableAttributedString *name = [[NSMutableAttributedString alloc] initWithString: [ap name]];
    NSRange                       r = {0, [name length]};
    NSRect              theProcRect = rect;
    
    theProcRect.origin.y    += rect.size.height;
    theProcRect.origin.y    -= 14 * (i + 1);
    theProcRect.size.height  = 14;
    {
      NSColor *clr = [ap isActive] ? [NSColor redColor] : [NSColor blueColor];

      id theDisplayObj = [[SndAudioArchViewObject alloc] initWithRect: theProcRect andSndAudioArchObject: ap];
      [displayObjectsArray addObject: theDisplayObj];
      
      [self drawRect: theProcRect withColor: [NSColor blackColor]];
      [name addAttribute: NSForegroundColorAttributeName value: clr range: r];
      [name setAlignment: NSCenterTextAlignment range: r];
      [name drawInRect: theProcRect];

    }
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// drawRect:withColor:
////////////////////////////////////////////////////////////////////////////////

- drawRect: (NSRect) aRect withColor: (NSColor*) aColor
{
  NSBezierPath *userPath  = [NSBezierPath bezierPath]; // user path for drawing segments
  NSPoint p1 = aRect.origin;
  [aColor set];

  [userPath moveToPoint: p1];
  p1.x += aRect.size.width;
  [userPath lineToPoint: p1];
  p1.y += aRect.size.height;
  [userPath lineToPoint: p1];
  p1.x = aRect.origin.x;
  [userPath lineToPoint: p1];
  p1.y = aRect.origin.y;
  [userPath lineToPoint: p1];
  [userPath stroke];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

- (void) mouseUp: (NSEvent*) theEvent
{
  int i, c;
  NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];

  [objectArrayLock lock];
  c = [displayObjectsArray count];
  if (currentSndArchObject != nil)
    [currentSndArchObject release];
  for (i = 0; i < c; i++) {
    SndAudioArchViewObject *theObj = [displayObjectsArray objectAtIndex: i];
    NSRect r = [theObj rect];
    if (mouseLoc.x >= r.origin.x && mouseLoc.y >= r.origin.y &&
        mouseLoc.x <= r.origin.x + r.size.width && mouseLoc.y <= r.origin.y + r.size.height) {
      currentSndArchObject = [[theObj sndAudioArchObject] retain];
      if (delegate != nil && [delegate respondsToSelector: @selector(didSelectObject:)])
        [delegate didSelectObject: [theObj sndAudioArchObject]];
      break;
    }
  }
  [objectArrayLock unlock];
  [self setNeedsDisplay: TRUE];  
}

/////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- setDelegate: (id) d
{
  if (delegate)
    [delegate release];
  delegate = [d retain];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- (id) delegate
{
  return delegate;
}

////////////////////////////////////////////////////////////////////////////////

@end

