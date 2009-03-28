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
  @brief A MKTuningSystem object represents a musical tuning system by mapping key numbers to frequencies.
 
The method -<b>setFreq:forKeyNum:</b> establishes a
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
  @brief Creates a MKTuningSystem object and tunes it to the installed tuning system.
  
  Tuning the returned object won't affect the installed MKTuningSystem.
  @return Returns an autoreleased MKTuningSystem instance.
 */
+ (MKTuningSystem *) tuningSystem; 

/*!
  @brief Initializes receiver to 12-tone equal tempered tuning.
  @return Returns an initialized MKTuningSystem instance.
 */
- init;

/*!
  @brief Creates and returns a new MKTuningSystem as a copy of the receiver.
  @return Returns an id.
*/
- copyWithZone: (NSZone *) zone;

/*!
  @brief Sets the receiver's tuning to 12-tone equal-tempered at A = 440Hz.
*/
- (void) setTo12ToneTempered; 

/*!
  @brief Installs the receiver's tuning as the current tuning system.

  The receiver itself isn't installed, only its tuning system; subsequent
  changes to the receiver won't affect the installed system unless you
  resend the <b>install</b> message to the receiver. 
  @return Returns the receiver.
*/
- install; 

/*!
  @brief Returns the number of "keys" (tunable elements) in a tuning system.
  @return Returns the number of "keys" (tunable elements) in a tuning system.
 */
- (int) keyCount;

/*!
  @brief Return formatted pitch name given a key number

  Returns an NSString object containing the pitch name associated with the
  key number argument. The format of the string is the same as Scorefile
  pitch arguments.
  @param  keyNum is an int.
  @return Returns an NSString object containing the pitch name or an empty string
   if the key number argument  is outside its legitimate range.
  @see <b>MKWritePitchNames()</b>, <b>MKWriteKeyNumNames()</b>
*/
+ (NSString *) pitchNameForKeyNum: (int) keyNum;

/*!
  @brief Returns the installed frequency for the key number <i>aKeyNum</i>.
  
  Returns the frequency that corresponds to the given key number,
  based upon the mapping of key numbers to frequencies
  in the <i>installed tuning system</i> (see the MKTuningSystem class
  description for more information on the installed tuning system).  

  If <i>aKeyNum</i> is out of bounds (less than 0 or greater than 127), returns MK_NODVAL
  (Use MKIsNoDVal() to check for MK_NODVAL).  The value returned by this method is the same
  value as <i>aKeyNum</i>'s analogous pitch variable.
 @param  aKeyNum is a MKKeyNum.
 @return Returns a double.
*/
+ (double) freqForKeyNum: (MKKeyNum) aKeyNum; 

/*!
  @brief Returns the receiver's frequency for the key number <i>aKeyNum</i>.
  
  Returns the frequency that corresponds to the given key number,
  based upon the mapping of key numbers to frequencies
  in the <i>installed tuning system</i> (see the MKTuningSystem class
  description for more information on the instralled tuning system).  

  If <i>aKeyNum</i> is out of bounds, returns MK_NODVAL (Use MKIsNoDVal()
  to check for MK_NODVAL).
 @param  aKeyNum is a MKKeyNum.
 @return Returns a double.
*/
- (double) freqForKeyNum: (MKKeyNum) aKeyNum; 

/*!
  @brief Returns keyNum (pitch index) of closest pitch variable to the specified frequency.
  
  Returns the key number that most closely corresponds to the given frequency.  The amount of
  pitch bend needed to temper the pitch of the key number in order to match the
  actual frequency is returned by reference in <i>bendPtr</i>.  This value is
  computed using the <i>sensitivity</i> argument as the number of semitones by
  which the key number is tempered given a maximum pitch bend; in other words, you
  supply the maximum pitch bend by passing in a <i>sensitivity</i> value, and the
  function returns, in <i>bendPtr</i>, the amount of the bend that's needed.  The
  value of <i>bendPtr</i> is a 14-bit MIDI pitch bend number; you would use it to
  set the value of a MKNote's MK_pitchBend parameter (assuming that you use
  <i>sensitivity</i> as value of the MKNote's MK_pitchBendSensitivity
  parameter).

  Sensitivity is interpreted such that with a sensitivity of 1.0, 
  a pitch bend of 0 gives a maximum negative displacement of a semitone
  and a bend of 0x3fff gives a maximum positive displacement of a semitone.
  Similarly, a value of 2.0 give a whole tone displacement in either
  direction. MIDI_ZEROBEND gives no displacement. 
  @param freq The frequency in Hz.
  @param bendPtr If bendPtr is not NULL, *bendPtr is set to the bend needed to 
   get <i>freq</i> in the context of the specified pitch bend sensitivity.
  @param sensitivity The pitch bend sensitivity.
  @see <b>+freqForKeyNum:</b>.
 */
+ (MKKeyNum) keyNumForFreq: (double) freq
	       pitchBentBy: (int *) bendPtr
	   bendSensitivity: (double) sensitivity;

/*!
  @brief Tunes the receiver's <i>aKeyNum</i> key number to <i>freq</i> and
  returns the receiver.

  If <i>aKeyNum</i> is out of bounds, returns
  MK_NODVAL (Use MKIsNoDVal() to check for MK_NODVAL).
 @param  aKeyNum is a MKKeyNum.
 @param  freq is a double.
 @return Returns an id.
 */
- setKeyNum: (MKKeyNum) aKeyNum toFreq: (double) freq;

/*!
  @brief Tunes the installed tuning system's <i>aKeyNum</i> key number to
  <i>freq</i> and returns the receiver.

  If <i>aKeyNum</i> is out of
  bounds, returns MK_NODVAL (Use MKIsNoDVal() to check for MK_NODVAL).
  
  <b>Note:</b>  If you're making several changes to the installed
  tuning system, it's more efficient to make the changes in an MKTuningSystem
  instance and then send it the install message than it is to repeatedly
  invoke this method.
 @param  aKeyNum is a MKKeyNum.
 @param  freq is a double.
 @return Returns an id.
 */
+ setKeyNum: (MKKeyNum) aKeyNum toFreq: (double) freq; 

/*!
  @brief Tunes all the receiver's key numbers with the same pitch class as
  <i>aKeyNum</i> to octaves of <i>freq</i> such that <i>aKeyNum</i> is
  tuned to <i>freq</i>.

  Returns the receiver or <b>nil</b> if aKeyNum is out of bounds.
 @param  aKeyNum is a MKKeyNum.
 @param  freq is a double.
 @return Returns an id.
 */
- setKeyNumAndOctaves: (MKKeyNum) aKeyNum toFreq: (double) freq;

/*!
  @brief Tunes the key numbers in the installed tuning system that are the
  same pitch class as <i>aKeyNum</i> to octaves of <i>freq</i> such
  that <i>aKeyNum</i> is tuned to <i>freq</i>.

  Returns the receiver
  or <b>nil</b> if aKeyNum is out of bounds.
  
  <b>Note:</b>  If you're making several changes to the installed
  tuning system, it's more efficient to make the changes in a MKTuningSystem
  instance and then send it the install message than it is to repeatedly
  invoke this method.
 @param  aKeyNum is a MKKeyNum.
 @param  freq is a double.
 @return Returns an id.
 */
+ setKeyNumAndOctaves: (MKKeyNum) aKeyNum toFreq: (double) freq;

/*!
  @brief Transposes the installed tuning system by <i>semitones</i>
  half-steps.

  (The half-step used here is 12-tone equal-tempered.) 
  If <i>semitones</i> is positive, the transposition is up, if it's
  negative, the transposition is down.  <i>semitones</i> can be any
  <b>double</b> value, thus you can transpose the tuning system by
  increments smaller than a half-step.
 @param  semitones is a double.
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
  @brief Transposes the receiver by <i>semitones</i> half-steps (the
  half-step used here is 12-tone equal-tempered).

  If <i>semitones</i>
  is positive, the transposition is up, if it's negative, the
  transposition is down.  <i>semitones</i> can be any <b>double</b>
  value, thus you can transpose the receiver by increments smaller
  than a half-step.  
 @param  semitones is a double.
*/
- (void) transpose: (double) semitones; 

/*!
  @brief Returns keyNum corresponding to the specified pitch variable or MAXINT if none. 
 */
+ (int) findPitchVar: (id) aVar;

@end

/* Functions for tuning and frequency conversion */

/*!
  @brief Transpose a frequency up by the specified number of semitones. 

  <b>MKTranspose()</b> returns the frequency that results from
  transposing <i>freq</i> by the specified number of semitones.  A
  negative <i>semitones</i> value transposes down; a fractional value can
  be used to transpose by less than a semitone.  The transposition
  afforded by this function is always in twelve-tone equal-temperament,
  regardless of the installed tuning system, as computed by the formula
     
   	result = <i>freq</i> * 2 <i>semitones</i> / 12.0 
   
  @param freq Starting frequency in Hz.
  @param semiTonesUp The number of 12 tone equal tempered semitones to transpose freq upwards.
  A negative value will transpose the note down.
  @return Returns a double.
  @see <b>+freqForKeyNum:</b>.
*/
double MKTranspose(double freq, double semiTonesUp);

/*!
  @brief Return the result of adjusting freq by the amount specified in pitchBend. 
  
  <b>MKAdjustFreqWithPitchBend()</b> returns the frequency that results
  when <i>freq</i> is tempered by <i>pitchBend</i> worth of
  <i>sensitivity</i> semitones, where <i>pitchBend</i> is, again, a 14-bit
  MIDI pitch bend number. 

  PitchBend is interpreted in the context of the current value of sensitivity. 
  @param freq A Frequency in Hertz.
  @param pitchBend A MIDI pitch bend value, interpreted according to sensitivity.
  @param sensitivity Sensitivity is in semitones.
  @return Returns the new frequency in Hertz.
  @see MKKeyNumToFreq().
 */
double MKAdjustFreqWithPitchBend(double freq, int pitchBend, double sensitivity);

#endif
