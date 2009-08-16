/*
 $Id$  

 Description:
   This is just like Alert.m (in the AppKit) but it sets the font to Courier
   to make MusicKit errors format correctly.  SIGH!!!
 
 Copyright (c) 1988-1992, NeXT Computer, Inc.
 Portions Copyright (c) 1999-2004 The MusicKit Project 
*/
#ifndef __MK_MKAlert_H___
#define __MK_MKAlert_H___

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface MKAlert: NSObject
{
    IBOutlet NSTextField *msg;
    IBOutlet NSPanel *panel;
    IBOutlet NSTextField *title;
    IBOutlet NSButton *panelIconButton;
    id  first,second,third;
//    NSCoord buttonHeight, buttonSpacing;
    NSSize defaultPanelSize;
}

- init;

- (void) buttonPressed: sender;

- (void) setIcon: (NSImage *) icon;

- (void) setMessageText: (NSString *) message;

@end

int mkRunAlertPanel(NSString *title, NSString *s, NSString *first, NSString *second, NSString *third);

#endif
