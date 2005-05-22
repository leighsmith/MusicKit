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
#import <AppKit/AppKit.h>

@class Snd;

/*!
  @class SndMeter
  @brief Not ready for operation just yet!
  
  

A SndMeter is a view that displays the amplitude level of a sound as
it's being recorded or played back. There are two working parts to the
meter: A continuously-updated &#ldquo;running bar&#rdquo; that lengthens
ands shrinks to depict the current amplitude level, and a &#ldquo;peak
bubble&#rdquo; that displays and holds the greatest amplitude that was
detected within the last few samples. An optional bezeled border is
drawn around the object's frame.

To use a SndMeter, you must first associate it with a Snd object,
through the <b>setSound:</b> method, and then send the SndMeter a
<b>run:</b> message. To stop the meter's display, you send the object
a <b>stop:</b> message. Neither <b>run:</b>nor <b>stop:</b> affect the
performance of the meter's sound.

You can retrieve a SndMeter's running and peak values through the
<b>floatValue</b> and <b>peakValue</b> methods. The values that these
methods return are valid only while the SndMeter is running. A
SndMeter also keeps track of the minimum and maximum amplitude over
the duration of a run; these can be retrieved through <b>minValue</b>
and <b>maxValue</b>. All SndMeter amplitude levels are normalized to
fit between 0.0 (inaudible) and 1.0 (maximum amplitude).
*/

@interface SndMeter: NSView
{
    Snd *sound;
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

/*!
  @param  frameRect is a NSRect.
  @return Returns an id.
  @brief  Initializes the SndMeter, fitting its graphic components within
  <i>frameRect</i>.

  The object's attributes are initialized as follows:

<table border=1 cellspacing=2 cellpadding=0 align=center>
 <b>Attribute</b>	<b>Value</b><br>
<tr>
 <td>Peak hold time</td>
 <td>0.7 seconds</td>
</tr>
<tr>
 <td>Background gray</td>
 <td>[NSColor darkGrayColor]</td>
</tr>
 <td>Running bar gray</td>
 <td>[NSColor lightGrayColor]</td>
</tr>
<tr>
 <td>Peak bubble gray</td>
 <td>[NSColor whiteColor]</td>
</tr>
 <td>Border</td>
 <td>bezeled</td>
</tr>
</table>
 
*/
- (id) initWithFrame: (NSRect) frameRect;

- (id) initWithCoder: (NSCoder *) aStream;
- (void) encodeWithCoder: (NSCoder *) aStream;

/*!
  @brief  Returns the SndMeter's hold time - the amount of time during
  which a peak amplitude is detected and displayed by the peak bubble - in seconds.

  The default is 0.7 seconds.
  @return Returns a float.
*/
- (float) holdTime;

/*!
  @brief Sets the SndMeter's peak value hold time in seconds.

  This is the amount of time during which peak amplitudes are detected and held by
  the peak bubble.
  @param  seconds is a float.
  @return Returns an id.
*/
- (void) setHoldTime: (float) seconds;

/*!
  @brief  Sets the SndMeter's background color.

  The default is NSColor's <b>darkGrayColor</b>.
  @param  aColor is a NSColor instance.
*/
- (void) setBackgroundColor: (NSColor *) aColor;

/*!
  @brief  Returns the SndMeter's background color.

  The default background color is NSColor's <b>darkGrayColor</b>.
  @return Returns a NSColor instance.
*/
- (NSColor *) backgroundColor;

/*!
  @brief  Sets the SndMeter's running bar color.

  The default is NSColor's <b>lightGrayColor</b>.
  @param  aColor is a NSColor instance.
*/
- (void) setForegroundColor: (NSColor *) aColor;

/*!
  @brief  Returns the color of the running bar.

  The default foreground color is NSColor's <b>lightGrayColor</b>.
  @return Returns a NSColor instance.
*/
- (NSColor *) foregroundColor;

/*!
  @brief Sets the SndMeter's peak bubble color.

  The default is NSColor's <b>whiteColor</b>.
  @param  aColor is a NSColor instance.
*/
- (void) setPeakColor: (NSColor *) aColor;

/*!
  @brief  Returns the SndMeter's peak bubble gray.

  The default is NSColor's <b>whiteColor</b>.
  @return Returns a NSColor instance.
*/
- (NSColor *) peakColor;

/*!
  @brief Returns the Snd object that the SndMeter is metering.
  @return Returns a Snd instance.  
*/
- (Snd *) sound;

/*!
  @brief  Sets the SndMeter's Snd object.
  @param  aSound is a Snd instance.
*/
- (void) setSound: (Snd *) aSound;

/*!
  @brief  Starts the SndMeter running.

  The SndMeter object must have a
  Snd object associated with it for this method to have an effect.
  Note that this method only affects the state of the SndMeter - it
  doesn't trigger any activity in the Snd.
  @param  sender is an id.
*/
- (void) run: (id) sender;

/*!
  @brief  Stops the SndMeter's metering activity.

  Note that this method only affects the state of the SndMeter 
  - it doesn't trigger any activity in the Snd.
  @param  sender is an id.
*/
- (void) stop: (id) sender;

/*!
  @brief  Returns YES if the SndMeter is currently running; otherwise, returns NO.

  The SndMeter's status doesn't depend on the activity of its Snd object.
  @return Returns a BOOL.
*/
- (BOOL) isRunning;

/*!
  @brief Returns YES (the default) if the SndMeter has a border; otherwise, returns NO.

  Note that the SndMeter class doesn't provide a method to change the type of border - 
  it can display a bezeled border or none at all.
  @return Returns a BOOL.
*/
- (BOOL) isBezeled;

/*!
  @brief  If <i>aFlag</i> is YES, a bezeled border is drawn around the SndMeter.

  If <i>aFlag</i> is NO and the SndMeter has a frame, the frame is removed.
  @param  aFlag is a BOOL.
*/
- (void) setBezeled: (BOOL) aFlag;

/*!
  @brief  Sets the current running value to <i>aValue</i>.

  You never invoke this method directly; it's invoked automatically
  when the SndMeter is running. However, you can reimplement this
  method in a subclass of SndMeter. 
  @param  aValue is a float.
*/
- (void) setFloatValue: (float) aValue;

/*!
  @brief  Returns the current running amplitude value as a floating-point
  number between 0.0 and 1.0.

  This is the amplitude level that's displayed by the running bar.
  @return Returns a float.
*/
- (float) floatValue;

/*!
  @brief  Returns the most recently detected peak value as a floating-point
  number between 0.0 and 1.0.

  This is the amplitude level that's displayed by the peak bubble.
  @return Returns a float.
*/
- (float) peakValue;

/*!
  @brief  Returns the minimum running value so far.

  You can invoke this method after you stop this SndMeter to retrieve the overall
  minimum value for the previous performance. The minimum value is
  cleared when you restart the SndMeter.
  @return Returns a float.
*/
- (float) minValue;

/*!
  @brief  Returns the maximum running value so far.

  You can invoke this method after you stop this SndMeter to retrieve the overall
  maximum value for the previous performance. The maximum value is
  cleared when you restart the SndMeter.
  @return Returns a float.
*/
- (float) maxValue;

/*!
  @brief  Draws all the components of the SndMeter (frame, running bar, and
  peak bubble).

  You never invoke this method directly; however, you can override it in a
  subclass to change the way the components are displayed. 
  @param  rects is a NSRect.
*/
- (void) drawRect: (NSRect) rects;

/*!
  @brief  Draws the SndMeter's running bar and peak bubble.

  You never invoke this method directly; it's invoked automatically while the
  SndMeter is running. You can override this method to change the
  look of the running bar and peak bubble.
*/
- (void) drawCurrentValue;

@end

