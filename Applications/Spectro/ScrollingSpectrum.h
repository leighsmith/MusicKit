/*
 $Id$
 
 Part of Spectro.app
 Modifications Copyright (c) 2003 The MusicKit Project, All Rights Reserved.
 
 Legal Statement Covering Additions by The MusicKit Project:
 
 Permission is granted to use and modify this code for commercial and
 non-commercial purposes so long as the author attribution and copyright
 messages remain intact and accompany all relevant code.
 
 */
#import <AppKit/AppKit.h>

@interface ScrollingSpectrum: NSScrollView
{
    id spectrumView;
    id delegate;
    double dataFactor;
}

- initWithFrame: (NSRect) theFrame;

/* Methods to set up the object: */
- (void) setDelegate: (id) anObject;
- setSpectrumView: anObject;

/* Methods to retrieve information about the object: */
- delegate;
- spectrumView;

/* Methods to get data information about the display */
- getWindowPoints: (float *) stptr andSize: (float *) sizptr;

/* Methods to set display and selection by timings */
- setWindowStart: (int) startpoint;
- setDisplayPoints: (float) points;

/* Method to replace normal ScrollView methods: */
- (void)reflectScrolledClipView: (NSClipView *) sender;

@end
