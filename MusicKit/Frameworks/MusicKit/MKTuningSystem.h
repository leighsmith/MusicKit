/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description: 
    A MKTuningSystem object represents a musical tuning system by mapping
    key numbers to frequencies.  The method setFreq:forKeyNum: defines the
    frequency value (in hertz) for a specified key number.  To tune a key
    number and its octaves at the same time, invoke the method
    setFreq:forKeyNumAndOctaves:.  The frequencies in a MKTuningSystem
    object don't have to increase as the key numbers increase -- you can
    even create a MKTuningSystem that descends in pitch as the key numbers
    ascend the scale.  The freqForKeyNum: method retrieves the frequency
    value of the argument key number.  Such values are typically used to
    set the frequency of a Note object:
   
    * #import <musickit/keynums.h>
    * [aNote setPar:MK_freq toDouble:[aTuningSystem freqForKeyNum:c4k]];
   
    The MKTuningSystem class maintains a master system called the
    installed tuning system.  By default, the installed tuning system is
    tuned to 12-tone equal-temperament with a above middle c set to 440
    Hz.  A key number that doesn't reference a MKTuningSystem object takes
    its frequency value from the installed tuning system.  The frequency
    value of a pitch variable is also taken from the installed system.
    The difference between key numbers and pitch variables is explained in
    Chapter 10, "Music."  The entire map of key numbers, pitch variables,
    and frequency values in the default 12-tone equal-tempered system is
    given in Appendix G, "Music Tables."
   
    You can install your own tuning system by sending the install
    message to a MKTuningSystem instance.  Keep in mind that this doesn't
    install the object itself, it simply copies its key number-frequency
    map.  Subsequent changes to the object won't affect the installed
    tuning system (unless you again send the object the install message).
   
    Note that while key numbers can also be used to define pitch for Notes
    used in MIDI performance, the MKTuningSystem object has no affect on the
    precise frequency of a Note sent to a MIDI instrument.  The
    relationship between key numbers and frequencies on a MIDI instrument
    is set on the instrument itself. (An application can, of course, use
    the information in a MKTuningSystem object to configure the MIDI
    instrument.)
*/
/*
  $Log$
  Revision 1.4  2000/05/13 17:17:49  leigh
  Added MKPitchNameForKeyNum()

  Revision 1.3  2000/04/25 22:08:41  leigh
  Converted from Storage to NSArray operation

  Revision 1.2  1999/07/29 01:25:52  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_TuningSystem_H___
#define __MK_TuningSystem_H___

#import <Foundation/NSObject.h>

#import "keynums.h"

/* Tuning and freq conversion */

extern double MKKeyNumToFreq(MKKeyNum keyNum);
 /* Convert keyNum to frequency using the installed tuning system.
    Returns MK_NODVAL if keyNum is out of bounds.
    (Use MKIsNoDVal() to check for MK_NODVAL.)
  */

extern MKKeyNum MKFreqToKeyNum(double freq,int *bendPtr,double sensitivity);
 /* Returns keyNum (pitch index) of closest pitch variable to the specified
    frequency . If bendPtr is not NULL, *bendPtr is set to the bend needed to 
    get freq in the context of the specified pitch bend sensitivity. 
    Sensitivity is interpreted such that with a sensitivity of 1.0, 
    a pitch bend of 0 gives a maximum negative displacement of a semitone
    and a bend of 0x3fff gives a maximum positive displacement of a semitone.
    Similarly, a value of 2.0 give a whole tone displacement in either
    direction. MIDI_ZEROBEND gives no displacement. */

extern double MKAdjustFreqWithPitchBend(double freq, int pitchBend, double sensitivity);
 /* Return the result of adjusting freq by the amount specified in
    pitchBend. PitchBend is interpreted in the context of the current
    value of sensitivity. */

extern double MKTranspose(double freq,double semiTonesUp);
 /* Transpose a frequency up by the specified number of semitones. 
    A negative value will transpose the note down. */

extern NSString *MKPitchNameForKeyNum(int keyNum);
/* Returns a formatted NSString of the pitch indicated by keyNum. */

@interface MKTuningSystem : NSObject
{
    NSMutableArray *frequencies; /* Array object of frequencies, indexed by keyNum. */
}

- init;
 /* Initializes receiver to 12-tone equal tempered tuning. */

- copyWithZone:(NSZone *)zone;
 /* Copies object and arrays. */

-copy;
 /* Same as [self copyFromZone:[self zone]]; */

- (void)dealloc;
 /* Frees object and internal storage. */

- setTo12ToneTempered; 
 /* Sets the receiver's tuning to 12-tone equal-tempered. */

- install; 
 /* 
  * Installs the receiver's tuning as the current tuning system.  The
  * receiver itself isn't installed, only its tuning system; subsequent
  * changes to the receiver won't affect the installed system unless you
  * resend the install message to the receiver.  Returns the receiver.
  */

- initFromInstalledTuningSystem;
 /* Initializes a new MKTuningSystem object to the installed tuning system. */

+(double) freqForKeyNum:(MKKeyNum )aKeyNum; 
 /* 
  * Returns the installed frequency for the key number aKeyNum.  If
  * aKeyNum is out of bounds, returns MK_NODVAL.  
  * (Use MKIsNoDVal() to check for MK_NODVAL.)
  * The value returned by this method is the same value as aKeyNum's 
  * analogous pitch variable.
  */

-(double) freqForKeyNum:(MKKeyNum )aKeyNum; 
 /* 
  * Returns the receiver's frequency for the key number aKeyNum.  If
  * aKeyNum is out of bounds, returns MK_NODVAL.
  * (Use MKIsNoDVal() to check for MK_NODVAL.)
  */

- setKeyNum:(MKKeyNum )aKeyNum toFreq:(double)freq;
 /* 
  * Tunes the receiver's aKeyNum key number to freq and returns the
  * receiver.  If aKeyNum is out of bounds, returns MK_NODVAL.
  * (Use MKIsNoDVal() to check for MK_NODVAL.)
  */

+ setKeyNum:(MKKeyNum )aKeyNum toFreq:(double)freq; 
 /* 
  * Tunes the installed tuning system's aKeyNum key number to freq and
  * returns the receiver.  If aKeyNum is out of bounds, returns MK_NODVAL.
  * (Use MKIsNoDVal() to check for MK_NODVAL.)
  * 
  * Note: If you're making several changes to the installed tuning
  * system, it's more efficient to make the changes in a MKTuningSystem
  * instance and then send it the install message than it is to repeatedly
  * invoke this method.
  */

- setKeyNumAndOctaves:(MKKeyNum )aKeyNum toFreq:(double)freq;
 /* 
  * Tunes all the receiver's key numbers with the same pitch class as
  * aKeyNum to octaves of freq such that aKeyNum is tuned to freq.
  * Returns the receiver or nil if aKeyNum is out of bounds.
  */

+ setKeyNumAndOctaves:(MKKeyNum )aKeyNum toFreq:(double)freq;
 /* 
  * Tunes the key numbers in the installed tuning system that are the same
  * pitch class as aKeyNum to octaves of freq such that aKeyNum is tuned
  * to freq.  Returns the receiver or nil if aKeyNum is out of bounds.
  * 
  * Note: If you're making several changes to the installed tuning system,
  * it's more efficient to make the changes in a MKTuningSystem instance and
  * then send it the install message than it is to repeatedly invoke this
  * method.
  */

+ transpose:(double)semitones; 
 /* 
  * Transposes the installed tuning system by semitones half-steps.  (The
  * half-step used here is 12-tone equal-tempered.)  If semitones is
  * positive, the transposition is up, if it's negative, the transposition
  * is down.  semitones can be any double value, thus you can transpose
  * the tuning system by increments smaller than a half-step.  Returns the
  * receiver.
  */

- transpose:(double)semitones; 
 /* 
  * Transposes the receiver by semitones half-steps.  (The half-step used
  * here is 12-tone equal-tempered.)  If semitones is positive, the
  * transposition is up, if it's negative, the transposition is down.
  * semitones can be any double value, thus you can transpose the receiver
  * by increments smaller than a half-step.  Returns the receiver.
  */

- (void)encodeWithCoder:(NSCoder *)aCoder;
 /* Writes receiver to archive file. */ 
- (id)initWithCoder:(NSCoder *)aDecoder;
 /* Reads receiver from archive file. */ 

 /* Obsolete */
+ installedTuningSystem; 
+ new; 

@end

#endif
