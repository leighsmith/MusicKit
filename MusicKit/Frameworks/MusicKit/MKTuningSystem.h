/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description: 
    See the Headerdoc description below.   

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University  
  Portions Copyright (c) 1999-2004, The MusicKit Project.
*/
/*!
  @class MKTuningSystem
  @discussion

A MKTuningSystem object represents a musical tuning system by mapping key numbers
to frequencies.  The method -<b>setFreq:forKeyNum:</b> establishes a
frequency/key number correspondence, defining the frequency value (in Hertz) for a
specified key number.  To tune a key number and its octaves at
the same time, invoke the method <b>setFreq:forKeyNumAndOctaves:</b>.  The
frequencies in a MKTuningSystem object don't have to increase as the key numbers
increase - you can even create a MKTuningSystem that descends in pitch as the key
numbers ascend the scale.  The <b>freqForKeyNum:</b> method retrieves the
frequency value of the argument key number.  Such values are typically used to
set the frequency of a MKNote object:

<tt>[aNote setPar: MK_freq<br>
         toDouble: [aTuningSystem freqForKeyNum: c4k]];</tt>

The MKTuningSystem class maintains a master system called the <i>installed tuning
system</i>.  By default, the installed tuning system is set to 12-tone
equal-temperament with A above middle C set to 440 Hz.  A key number that
doesn't reference a MKTuningSystem object takes its frequency value from the
installed tuning system.  The frequency value of a pitch variable is also taken
from the installed system. The difference between key numbers and pitch
variables is explained in 
<a href=http://www.musickit.org/MusicKitConcepts/musicdata.html>
the section entitled Representing Music Data</a>.
The entire map of key numbers,
pitch variables, and frequency values in the default 12-tone equal-tempered
system is given in
<a href=http://www.musickit.org/MusicKitConcepts/musictables.html>
the section entitled Music Tables</a>.

You can install a tuning system by sending the <b>install</b> message to a
MKTuningSystem object.  Keep in mind that this doesn't install the object itself,
it simply copies its key number-frequency map.  Subsequent changes to the object
won't affect the installed tuning system (unless you again send the object the
<b>install</b> message).

Note that while key numbers can also be used to define pitch for MKNotes used in
MIDI performance, the MKTuningSystem object has no affect on the precise frequency
of a MKNote sent to a MIDI instrument.  The relationship between key numbers and
frequencies on a MIDI instrument is set on the instrument itself. (An
application can, of course, use the information in a MKTuningSystem object to
configure the MIDI instrument).
*/
#ifndef __MK_TuningSystem_H___
#define __MK_TuningSystem_H___

#import <Foundation/NSObject.h>

#import "keynums.h"

@interface MKTuningSystem : NSObject
{
    /*! @var frequencies NSArray object of frequencies, indexed by keyNum. */
    NSMutableArray *frequencies; 
}

/*!
  @method tuningSystem
  @result Returns an autoreleased MKTuningSystem instance.
  @abstract Creates a MKTuningSystem object and tunes it to the installed tuning system.
  @discussion Tuning the returned object won't affect the installed MKTuningSystem.
 */
+ (MKTuningSystem *) tuningSystem; 

/*!
  @method init
  @result Returns an initialized MKTuningSystem instance.
  @discussion Initializes receiver to 12-tone equal tempered tuning. 
 */
- init;

/*!
  @method copyWithZone:
  @result Returns an id.
  @discussion Creates and returns a new MKTuningSystem as a copy of the receiver.
*/
- copyWithZone: (NSZone *) zone;

/*!
  @method setTo12ToneTempered
  @abstract Sets the receiver's tuning to 12-tone equal-tempered at A = 440Hz.
*/
- (void) setTo12ToneTempered; 

/*!
  @method install
  @result Returns an id.
  @discussion Installs the receiver's tuning as the current tuning system.  The
              receiver itself isn't installed, only its tuning system; subsequent
              changes to the receiver won't affect the installed system unless you
              resend the <b>install</b> message to the receiver.  Returns the
              receiver.
*/
- install; 

/*!
  @method keyCount
  @result Returns the number of "keys" (tunable elements) in a tuning system.
 */
- (int) keyCount;

/*!
  @method pitchNameForKeyNum:
  @abstract Returns a formatted NSString of the pitch indicated by the given key number. 
 */
+ (NSString *) pitchNameForKeyNum: (int) keyNum;

/*!
  @method freqForKeyNum:
  @param  aKeyNum is a MKKeyNum.
  @result Returns a double.
  @discussion Returns the installed frequency for the key number <i>aKeyNum</i>. 
              If <i>aKeyNum</i> is out of bounds, returns MK_NODVAL (Use MKIsNoDVal()
              to check for MK_NODVAL).  The value returned by this method is the same
              value as <i>aKeyNum</i>'s analogous pitch variable.
*/
+ (double) freqForKeyNum: (MKKeyNum) aKeyNum; 

/*!
  @method freqForKeyNum:
  @param  aKeyNum is a MKKeyNum.
  @result Returns a double.
  @discussion Returns the receiver's frequency for the key number <i>aKeyNum</i>. 
              If <i>aKeyNum</i> is out of bounds, returns MK_NODVAL (Use MKIsNoDVal()
              to check for MK_NODVAL).
*/
- (double) freqForKeyNum: (MKKeyNum) aKeyNum; 

/*!
  @method keyNumForFreq:pitchBentBy:bendSensitivity:
  @abstract Returns keyNum (pitch index) of closest pitch variable to the specified frequency.
  @param freq The frequency in Hz.
  @param bendPtr If bendPtr is not NULL, *bendPtr is set to the bend needed to 
    get <i>freq</i> in the context of the specified pitch bend sensitivity.
  @param sensitivity The pitch bend sensitivity.
  @discussion Sensitivity is interpreted such that with a sensitivity of 1.0, 
    a pitch bend of 0 gives a maximum negative displacement of a semitone
    and a bend of 0x3fff gives a maximum positive displacement of a semitone.
    Similarly, a value of 2.0 give a whole tone displacement in either
    direction. MIDI_ZEROBEND gives no displacement. 
 */
+ (MKKeyNum) keyNumForFreq: (double) freq
	       pitchBentBy: (int *) bendPtr
	   bendSensitivity: (double) sensitivity;

/*!
  @method setKeyNum:toFreq:
  @param  aKeyNum is a MKKeyNum.
  @param  freq is a double.
  @result Returns an id.
  @discussion Tunes the receiver's <i>aKeyNum</i> key number to <i>freq</i> and
              returns the receiver.  If <i>aKeyNum</i> is out of bounds, returns
              MK_NODVAL (Use MKIsNoDVal() to check for MK_NODVAL).
*/
- setKeyNum: (MKKeyNum) aKeyNum toFreq: (double) freq;

/*!
  @method setKeyNum:toFreq:
  @param  aKeyNum is a MKKeyNum.
  @param  freq is a double.
  @result Returns an id.
  @discussion Tunes the installed tuning system's <i>aKeyNum</i> key number to
              <i>freq</i> and returns the receiver.  If <i>aKeyNum</i> is out of
              bounds, returns MK_NODVAL (Use MKIsNoDVal() to check for MK_NODVAL).
              
              <b>Note:</b>  If you're making several changes to the installed
              tuning system, it's more efficient to make the changes in an MKTuningSystem
              instance and then send it the install message than it is to repeatedly
              invoke this method.
*/
+ setKeyNum: (MKKeyNum) aKeyNum toFreq: (double) freq; 

/*!
  @method setKeyNumAndOctaves:toFreq:
  @param  aKeyNum is a MKKeyNum.
  @param  freq is a double.
  @result Returns an id.
  @discussion Tunes all the receiver's key numbers with the same pitch class as
              <i>aKeyNum</i> to octaves of <i>freq</i> such that <i>aKeyNum</i> is
              tuned to <i>freq</i>.  Returns the receiver or <b>nil</b> if aKeyNum
              is out of bounds.
*/
- setKeyNumAndOctaves: (MKKeyNum) aKeyNum toFreq: (double) freq;

/*!
  @method setKeyNumAndOctaves:toFreq:
  @param  aKeyNum is a MKKeyNum.
  @param  freq is a double.
  @result Returns an id.
  @discussion Tunes the key numbers in the installed tuning system that are the
              same pitch class as <i>aKeyNum</i> to octaves of <i>freq</i> such
              that <i>aKeyNum</i> is tuned to <i>freq</i>.  Returns the receiver
              or <b>nil</b> if aKeyNum is out of bounds.
              
              <b>Note:</b>  If you're making several changes to the installed
              tuning system, it's more efficient to make the changes in a MKTuningSystem
              instance and then send it the install message than it is to repeatedly
              invoke this method.
*/
+ setKeyNumAndOctaves: (MKKeyNum) aKeyNum toFreq: (double) freq;

/*!
  @method transpose:
  @param  semitones is a double.
  @discussion Transposes the installed tuning system by <i>semitones</i>
              half-steps.  (The half-step used here is 12-tone equal-tempered.) 
              If <i>semitones</i> is positive, the transposition is up, if it's
              negative, the transposition is down.  <i>semitones</i> can be any
              <b>double</b> value, thus you can transpose the tuning system by
              increments smaller than a half-step.
 */
+ (void) transpose: (double) semitones; 

#if 0
 /* some versions of gcc can't deal properly with class methods that have
  * the same name as instance methods in other classes. So I have renamed
  * this one because of a conflict with NSResponder:-transpose
  */
+ (void)_transpose:(double)semitones;
#endif

/*!
  @method transpose:
  @param  semitones is a double.
  @discussion Transposes the receiver by <i>semitones</i> half-steps (the
              half-step used here is 12-tone equal-tempered). If <i>semitones</i>
              is positive, the transposition is up, if it's negative, the
              transposition is down.  <i>semitones</i> can be any <b>double</b>
              value, thus you can transpose the receiver by increments smaller
              than a half-step.  
*/
- (void) transpose: (double) semitones; 

/*!
  @method findPitchVar:
  @abstract Returns keyNum corresponding to the specified pitch variable or MAXINT if none. 
 */
+ (int) findPitchVar: (id) aVar;

@end

/* Functions for tuning and frequency conversion */

/*!
  @function MKTranspose
  @abstract Transpose a frequency up by the specified number of semitones. 
  @param freq Starting frequency in Hz.
  @param semiTonesUp The number of 12 tone equal tempered semitones to transpose freq upwards.
                     A negative value will transpose the note down.
 */
double MKTranspose(double freq, double semiTonesUp);

/*!
  @function MKAdjustFreqWithPitchBend
  @abstract Return the result of adjusting freq by the amount specified in pitchBend. 
  @discussion PitchBend is interpreted in the context of the current value of sensitivity. 
  @param freq A Frequency in Hertz.
  @param pitchBend A MIDI pitch bend value, interpreted according to sensitivity.
  @param sensitivity Sensitivity is in semitones.
  @result Returns the new frequency in Hertz.
 */
double MKAdjustFreqWithPitchBend(double freq, int pitchBend, double sensitivity);

#endif
