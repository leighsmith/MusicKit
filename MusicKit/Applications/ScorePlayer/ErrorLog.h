#ifndef __MK_ErrorLog_H___
#define __MK_ErrorLog_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#import <objc/Object.h>
#import <AppKit/AppKit.h>

@interface ErrorLog : NSObject
{
    id	msg;
    id	panel; /* Actually this is a window. */
}

- init;
- buttonPressed:sender;
- show;
- addText:(char *)text;
- (BOOL)isVisible;

@end

#endif
