/*
 * $Id$
 *
 * Description: Defines a NSView subclass displaying instantaneous amplitude of sound.
 *
 * Original Author: Lee Boynton
 *
 * Substantially based on Sound Kit, Release 2.0, Copyright (c) 1988, 1989, 1990, NeXT, Inc.  All rights reserved.
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
 *
 * Portions Copyright (c) 2001-2003, The MusicKit project. All rights reserved.
 *
 * Legal Statement Covering Additions by The MusicKit Project:
 *
 *    Permission is granted to use and modify this code for commercial and
 *    non-commercial purposes so long as the author attribution and copyright
 *    messages remain intact and accompany all relevant code.
 *
 */
/* Modification History prior to commital to CVS repository:
 *
 * 10/12/90/mtm	Give up CPU more often when playing (bug #10591).
 * 10/12/90/mtm	Adjust BREAK_DELAY and timed entry period
 *			(bug #6312).
 * soundkit-25
 * =======================================================================================
 * 20 Sept 90 (wot)	Added support for SND_FORMAT_EMPHASIZED.
 *                      Made it do the same things as SND_FORMAT_LINEAR_16.
 *
 * 3/18/92 mminnick	Use sound driver peak detection.
 * 4/23/92 mminnick	Lock/unlock focus around draw in -run (bug 19540)
 * 10/7/93 aozer		NSString/NSRect kit conversion
 */

#import <AppKit/AppKit.h>

#import "Snd.h"
#import "SndMuLaw.h"
#import "SndStreamClient.h"
#import "SndMeter.h"

#define PEAK_WIDTH (3.0)

@implementation SndMeter

static float smoothValue(SndMeter *self, float aValue)
{
    float newValue;
    
    if (aValue >= self->currentPeak)
	newValue = aValue;
    else
	newValue = (2*aValue+2*self->_valOneAgo+self->_valTwoAgo)/5.0;
    self->_valTwoAgo = self->_valOneAgo;
    self->_valOneAgo = aValue;
    return (aValue > 0)? newValue : aValue;
}

// TODO this only handles muLaw encoded sound! Needs upgrading to handle all formats,
// especially 16 bit and float.
static float prepareValueForDisplay(SndMeter *self, float m)
{
    // TODO switch([self->sound dataFormat]) {
    float result;
    int val = (m > 0)? 32767.0 * m  :  0;
    int temp = (int)SndMuLawToLinear(val);
    
    temp = ~temp & 127;
    result = ((float)(temp))/128.0;
    return result;
}

static void calcValues(SndMeter *self, float *aveVal, float *peakVal)
{
    static SndStreamClient *outStream = nil;
    static SndStreamClient *inStream = nil;
    SndStreamClient *stream = nil;
    int status = [self->sound status];
    float leftPeak, rightPeak;

    *peakVal = *aveVal = 0.0;
    if (status == SND_SoundStopped || status == SND_SoundInitialized ||
	status == SND_SoundFreed || status == SND_SoundRecordingPaused ||
	status == SND_SoundPlayingPaused) {
	/*
	 * Not playing or recording, smooth last value.
	 */
	*peakVal = self->currentValue * 0.7;
    }
    else if (status == SND_SoundRecording || status == SND_SoundRecordingPending) {
	/*
	 * Recording, get the sound in stream.
	 */
	if (!inStream) {
	    inStream = [[SndStreamClient alloc] init];
	    if (inStream &&
		([inStream setDetectPeaks: YES] == nil)) {
		 [inStream release];
		 inStream = nil;
	    }
	}
	stream = inStream;
    }
    else {
	/*
	 * Playing, get the sound out stream.
	 */
	if (!outStream) {
	    outStream = [[SndStreamClient alloc] init];
	    if (outStream &&
		([outStream setDetectPeaks: YES] == nil)) {
		 [outStream release];
 		 outStream = nil;
	    }
	}
	stream = outStream;
    }
    if (stream &&
	([stream getPeakLeft: &leftPeak right: &rightPeak] != nil)) {
	*peakVal = (leftPeak + rightPeak) / 2.0;	/* stereo avg. */
	*aveVal = *peakVal;	/* always return peak as average */
    }
}

- (int) shouldBreak
{
   NSEvent *ev;
   int status = [self->sound status];

   /* Always give up the CPU when playing. */
   if (status == SND_SoundPlaying)
       return 1;
   ev = [[self window] nextEventMatchingMask: NSAnyEventMask  
	     untilDate: [NSDate date] inMode: NSDefaultRunLoopMode dequeue: NO];
   return ev != nil || !status || self->smFlags.shouldStop;
}


#define DONE_DELAY (10)
#define BREAK_DELAY (0)

- (void) animate_self: (id) /* _NSSKTimedEntry */ timedEntry
		 when: (double) now
{
    static int stopDelay = DONE_DELAY;
    int breakDelay = BREAK_DELAY;
    float aveVal, peakVal;

    [self lockFocus];
    if ([self->sound status] && !self->smFlags.shouldStop)
	stopDelay = DONE_DELAY;
    else
	stopDelay--;
    if (!stopDelay) {
	[self setFloatValue:-1.0];
	[self drawCurrentValue];
	[[self window] flushWindow];
//	_NSSKRemoveTimedEntry((_NSSKTimedEntry) self->_timedEntry);
	self->_timedEntry = 0;
	self->smFlags.running = NO;
	stopDelay = DONE_DELAY;
    } else {
	while(1) {
	    if (self->sound) {
		calcValues(self, &aveVal, &peakVal);
		if (aveVal < self->minValue) self->minValue = aveVal;
		if (aveVal > self->maxValue) self->maxValue = aveVal;
	    }
	    else
		self->minValue = self->maxValue = aveVal = peakVal = 0.0;
	    [self setFloatValue:peakVal];
	    [self drawCurrentValue];
	    [[self window] flushWindow];
//	    PSWait();
	    if (!breakDelay)
		break;
	    else if ([self shouldBreak])
		breakDelay--;
	}
    }
    [self unlockFocus];
}

/**********************************************************************
 *
 * Exports
 *
 */

+ (void)initialize {
    if (self == [SndMeter class]) {
	[SndMeter setVersion:1];
    }
}

- (id)initWithFrame:(NSRect)frameRect {
    [super initWithFrame:frameRect];
    holdTime = 0.7; // in seconds
    [self setBackgroundColor:[NSColor darkGrayColor]];
    [self setForegroundColor:[NSColor lightGrayColor]];
    [self setPeakColor:[NSColor whiteColor]];
    smFlags.bezeled = YES;
    return self;
}

- (float)floatValue { return currentValue; }
- (float)peakValue { return currentPeak; }
- (float)minValue { return minValue; }
- (float)maxValue { return maxValue; }

- (void)setHoldTime:(float)seconds { holdTime = seconds;
}
- (float)holdTime { return holdTime; }

- (void)setBackgroundColor:(NSColor *)color;
{
    [backgroundColor autorelease];
    backgroundColor = [color copyWithZone:[self zone]];
    [self setNeedsDisplay:YES];
}

- (NSColor *)backgroundColor
{
    return backgroundColor;
}

- (void)setForegroundColor:(NSColor *)color;
{
    [foregroundColor autorelease];
    foregroundColor = [color copyWithZone:[self zone]];
    [self setNeedsDisplay:YES];
}

- (NSColor *)foregroundColor;
{
    return foregroundColor;
}

- (void)setPeakColor:(NSColor *)color;
{
    [peakColor autorelease];
    peakColor = [color copyWithZone:[self zone]];
    [self setNeedsDisplay:YES];
}

- (NSColor *)peakColor;
{
    return peakColor;
}

- (Snd *)sound { return sound; }
- (void) setSound:(Snd*) aSound { sound = aSound; }

- (void)run:sender
{
    if (!smFlags.running && !_timedEntry && sound) {
	float aveVal, peakVal;
	smFlags.running = YES;
	minValue = 1.0;
	maxValue = 0.0;
	currentSample = 0;
	if (sound) {
	    calcValues(self, &aveVal, &peakVal);
	    if (aveVal < minValue) minValue = aveVal;
	    if (aveVal > maxValue) maxValue = aveVal;
	} else
	    minValue = maxValue = aveVal = peakVal = 0.0;
	[self setFloatValue:peakVal];
	[self lockFocus];
	[self drawCurrentValue];
	[self unlockFocus];
	[[self window] flushWindow];
//	PSWait();
//	_timedEntry = (void *) _NSSKAddTimedEntry(0.05, 
//		    (_NSSKTimedEntryProc)animate_self, self,NSBaseThreshhold);
    }
    smFlags.shouldStop = NO;
}

- (void)stop:(id)sender
{
    if (smFlags.running) {
	smFlags.shouldStop = YES;
    }
}

- (BOOL)isRunning
{
    return smFlags.running;
}

- (BOOL)isBezeled
{
    return smFlags.bezeled;
}

- (void)setBezeled:(BOOL)aFlag
{
    smFlags.bezeled = aFlag? YES : NO;
    [self setNeedsDisplay:YES];
}

- (void) setFloatValue: (float) aValue
{
//    struct tsval foo;
    // double peakDelay;

    if (aValue < 0.0)
	currentValue = currentPeak = aValue;
    else if (aValue > 1.0)
	currentValue = 1.0;
    else
	currentValue = aValue;
//    kern_timestamp(&foo);
//    _valTime = foo.low_val;
//    peakDelay = ((float)(foo.low_val - _peakTime))/1000000.0;
//    if (currentValue > currentPeak || peakDelay > holdTime) {
    if (currentValue > currentPeak) {
	currentPeak = currentValue;
//	_peakTime = foo.low_val;
    }
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rects
{
    NSRect temp = [self bounds];
    if (smFlags.bezeled) {
	NSDrawGrayBezel(temp, temp);	/* This second rect should really be NULL... */
	temp = NSInsetRect(temp, 2.0, 2.0);
    }
    [backgroundColor set];
    NSRectFill(temp);
    [self drawCurrentValue];
}

- (void) drawCurrentValue
{
    float valueOffset, peakOffset;
    NSRect bounds = [self bounds];
    float displayValue = prepareValueForDisplay(self, smoothValue(self, currentValue));
    float displayPeak = prepareValueForDisplay(self, currentPeak);
    // float x, y, w, h;
    NSRect meterRect;

    meterRect.origin.x = bounds.origin.x + 5.0;
    meterRect.origin.y = bounds.origin.y + 5.0;
    meterRect.size.width = bounds.size.width - 9.0;
    meterRect.size.height = bounds.size.height - 9.0;
    
    valueOffset = (meterRect.size.width - PEAK_WIDTH) * displayValue;
    peakOffset  = (meterRect.size.width - PEAK_WIDTH) * displayPeak;
    if (peakOffset > 0.0) {
	NSRect peakRect;

	if (valueOffset > 0.0) {
	    NSRect foregroundRect;
	    NSRect backgroundRect;

	    [foregroundColor set];
	    // PSrectfill(x,y,valueOffset,h);
	    foregroundRect.origin.x = meterRect.origin.x;
	    foregroundRect.origin.y = meterRect.origin.y;
	    foregroundRect.size.width = valueOffset;
	    foregroundRect.size.height = meterRect.size.height;	    
	    NSRectFill(foregroundRect);
	    
	    [backgroundColor set];
	    // PSrectfill(x+valueOffset,y,w-valueOffset,h);
	    backgroundRect.origin.x = meterRect.origin.x + valueOffset;
	    backgroundRect.origin.y = meterRect.origin.y;
	    backgroundRect.size.width = meterRect.size.width - valueOffset;
	    backgroundRect.size.height = meterRect.size.height;
	    NSRectFill(backgroundRect);
	}
	else { // if no value, just colour with the background colour.
	    [backgroundColor set];
	    // PSrectfill(x,y,w,h);
	    NSRectFill(meterRect);
	}
	[peakColor set];
	// PSrectfill(x+peakOffset,y,PEAK_WIDTH,h);
	peakRect.origin.x = meterRect.origin.x + peakOffset;
	peakRect.origin.y = meterRect.origin.y;
	peakRect.size.width = PEAK_WIDTH;
	peakRect.size.height = meterRect.size.height;
	NSRectFill(peakRect);
    }
    else {
	[backgroundColor set];
	//PSrectfill(x,y,w,h);
	NSRectFill(meterRect);
    }
}

- (void)encodeWithCoder:(NSCoder *)stream {
    [super encodeWithCoder:stream];
    [stream encodeValuesOfObjCTypes:"@fffff@@@s",&sound,&currentValue,
    			&currentPeak, &minValue, &maxValue,
			&holdTime, &backgroundColor, &foregroundColor, &peakColor,
			&smFlags];

}

- (id)initWithCoder:(NSCoder *)stream {
    int version;
    self = [super initWithCoder:stream];
    version = [stream versionForClassName:@"SndMeter"];
    if (version == 0) {
	float backgroundGray, foregroundGray, peakGray;
	[stream decodeValuesOfObjCTypes:"@ffffffffs",&sound,&currentValue,
			    &currentPeak, &minValue, &maxValue,
			    &holdTime, &backgroundGray, &foregroundGray,&peakGray,
			    &smFlags];
	[self setBackgroundColor:[NSColor colorWithCalibratedWhite:backgroundGray alpha:1.0]];
	[self setForegroundColor:[NSColor colorWithCalibratedWhite:foregroundGray alpha:1.0]];
	[self setPeakColor:[NSColor colorWithCalibratedWhite:peakGray alpha:1.0]];
    } else if (version >= 1) {
	[stream decodeValuesOfObjCTypes:"@fffff@@@s",&sound,&currentValue,
			    &currentPeak, &minValue, &maxValue,
			    &holdTime, &backgroundColor, &foregroundColor, &peakColor,
			    &smFlags];
    }
    smFlags.running = NO;
    _valTime = _peakTime = currentSample = 0;
    _valOneAgo = _valTwoAgo = 0.0;
    return self;

}

- (void)dealloc {
    [backgroundColor release];
    [foregroundColor release];
    [peakColor release];
    [super dealloc];
}

@end

