/*
 * Copyright (c) 1999 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * "Portions Copyright (c) 1999 Apple Computer, Inc.  All Rights
 * Reserved.  This file contains Original Code and/or Modifications of
 * Original Code as defined in and that are subject to the Apple Public
 * Source License Version 1.0 (the 'License').  You may not use this file
 * except in compliance with the License.  Please obtain a copy of the
 * License at http://www.apple.com/publicsource and read it before using
 * this file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE OR NON-INFRINGEMENT.  Please see the
 * License for the specific language governing rights and limitations
 * under the License."
 * 
 * @APPLE_LICENSE_HEADER_END@
 */
/*
	SndMeter.h
	Copyright (c) 1988, 1989, 1990, NeXT, Inc.  All rights reserved.
        Modifications Copyright (c) 2001, The MusicKit project. All rights reserved.
*/

#import <AppKit/NSView.h>

@class Snd;

@interface SndMeter:NSView
{
    id sound;
    int currentSample;
    float currentValue;
    float currentPeak;
    float minValue;
    float maxValue;
    float holdTime;
    NSColor *backgroundColor;
    NSColor *foregroundColor;
    NSColor *peakColor;
    struct {
	unsigned int running:1;
	unsigned int bezeled:1;
	unsigned int shouldStop:1;
	unsigned int _reservedFlags:13;
    } smFlags;
    void *_timedEntry;
    int _valTime;
    int _peakTime;
    float _valOneAgo;
    float _valTwoAgo;
}

- (id)initWithFrame:(NSRect)frameRect;

- (id)initWithCoder:(NSCoder *)aStream;
- (void)encodeWithCoder:(NSCoder *)aStream;
- (float)holdTime;
- (void)setHoldTime:(float)seconds;
- (void)setBackgroundColor:(NSColor *)color;
- (NSColor *)backgroundColor;
- (void)setForegroundColor:(NSColor *)color;
- (NSColor *)foregroundColor;
- (void)setPeakColor:(NSColor *)color;
- (NSColor *)peakColor;
- (Snd *)sound;
- (void)setSound:(Snd *)aSound;
- (void)run:(id)sender;
- (void)stop:(id)sender;
- (BOOL)isRunning;
- (BOOL)isBezeled;
- (void)setBezeled:(BOOL)aFlag;
- (void)setFloatValue:(float)aValue;
- (float)floatValue;
- (float)peakValue;
- (float)minValue;
- (float)maxValue;
- (void)drawRect:(NSRect)rects;
- (void)drawCurrentValue;
@end
