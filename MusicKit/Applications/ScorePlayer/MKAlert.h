#ifndef __MK_MKAlert_H___
#define __MK_MKAlert_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
	Alert.h
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface MKAlert : NSObject
{
    id	msg;
    id	panel;
    id	title;
    id  first,second,third;
//    NSCoord buttonHeight, buttonSpacing;
    NSSize defaultPanelSize;
}

+ new;
- init;

- (void)buttonPressed:sender;

int mkRunAlertPanel(NSString *title, NSString *s, NSString *first, NSString *second, NSString *third);

@end

#endif
