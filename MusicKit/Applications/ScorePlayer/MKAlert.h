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
    NSCoord buttonHeight, buttonSpacing;
    NSSize defaultPanelSize;
}

+ new;
- init;

- buttonPressed:sender;

int mkRunAlertPanel(const char *title, const char *s, const char *first, const char *second, const char *third);

@end

#endif
