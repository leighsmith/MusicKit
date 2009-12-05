#ifndef __MK_ErrorLog_H___
#define __MK_ErrorLog_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#import <Foundation/NSObject.h>
#import <AppKit/AppKit.h>

@interface ErrorLog : NSObject
{
    IBOutlet NSTextView *msg;
    IBOutlet NSWindow   *panel;
}

- init;
- (void)buttonPressed:sender;
- (void)show;
- (void)addText:(NSString *)text;
- (BOOL)isVisible;

@end

#endif
