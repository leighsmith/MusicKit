/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:25:48  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_Partials_H___
#define __MK_Partials_H___
//sb:
#import <Foundation/Foundation.h>

#import <Foundation/NSObject.h>
#import "MKWaveTable.h"
#import "MKSamples.h"

@interface MKPartials : MKWaveTable 
/* 
 * 
 * A Partials object contains arrays that specify the amplitudes,
 * frequency ratios, and initial phases of a set of partials.  This
 * information is used to synthesize a waveform.  The synthesized data is
 * referenced by the methods inherited from WaveTable.
 * 
 * Ordinarily, the frequency ratios are multiplied by the base frequency
 * of the UnitGenerator that uses the Partials object.  Similarly, the
 * amplitude ratios defined in the Partials object are multiplied by the
 * UnitGenerator's amplitude term.
 * 
 * Partials objects can also deliver their data as Waveshaping tables.
 */
{
    double *ampRatios;   /* Array of amplitudes. */
    double *freqRatios;  /* Array of frequencies. */
    double *phases;      /* Arrays of initial phases. */
    int partialCount;    /* Number of points in each array */
    double defaultPhase; /* Default phase. If no phase-array, this is phase */
    double minFreq;      /* Obsolete. See Timbre. */
    double maxFreq;      /* Obsolete. See Timbre. */
    /* The following for internal use only */
    BOOL _ampArrayFreeable,_freqArrayFreeable,_phaseArrayFreeable;
    BOOL dbMode;
    int tableType;
}
 
- init; 
 /* 
  * Inits the receiver.  You never invoke this method directly.  A
  * subclass implementation should send [super init] before
  * performing its own initialization.  The return value is ignored.  */

- copyWithZone:(NSZone *)zone;
 /* 
  * Returns a copy of the receiver with its own copy of arrays. 
  * See also superclass -copy.
  */

- (void)dealloc; 
  /* Frees the receiver and all its arrays. */

-(double)highestFreqRatio;
  /* Returns the highest (i.e., largest absolute value) freqRatio.  
     Useful for optimizing lookup table sizes. */

- setPartialCount:(int)count freqRatios: (double *)fRatios ampRatios: (double *)aRatios phases: (double *)phases orDefaultPhase: (double)defaultPhase;
 /* 
   This method is used to specify the amplitude and frequency
   ratios and initial phases (in degrees) of a set of partials representing a
   waveform.  If one of the data retrieval methods is called (inherited from 
   the WaveTable object), a wavetable is synthesized and returned.
   The resulting waveform is guaranteed to begin and end 
   at or near the same point only if the partial ratios are integers.

   If phs is NULL, the defPhase value is used for all
   harmonics.  If aRatios or fRatios is NULL, the corresponding value is
   unchanged. The array arguments are copied. */

- setFromSamples:(MKSamples *)samplesObject;
    /* Sets freqRatios, ampRatios, and phases based on the data in the
       samplesObject.  This is done by taking an FFT of the data.
    */
    
-prunePartials:(double)amplitudeThreshold;
    /* Change contents to remove any partials with amplitudes below 
       specified threshold. */

- (int)partialCount;
 /* Returns the number of partials.
   */

- (double *)freqRatios; 
 /* 
   Returns the frequency ratios array directly, without copying it. */

- (double *)ampRatios; 
 /* 
   Returns the amplitude ratios array directly, without copying it nor 
   scaling it. */

- (double)defaultPhase;
 /* Returns the defaultPhase. */
- (double *)phases; 
 /* Returns phase array or NULL if none */

- (int) getPartial:(int)n freqRatio: (double *)fRatio ampRatio:(double *)aRatio
phase: (double *)phase;
 /* 
   Get specified partial by reference. n is the zero-based
   index of the partial. If the specified partial is the last value, 
   returns 2. If the specified value is out of bounds, 
   returns -1. Otherwise returns 0.
   The partial amplitude is scaled by the scaling constant.
   */

-writeScorefileStream:(NSMutableData *)aStream;
 /* 
   Writes the receiver in scorefile format on the specified stream.
   Returns nil if ampRatios or freqRatios is NULL, otherwise self. */

- (void)encodeWithCoder:(NSCoder *)aCoder;
  /* 
     You never send this message directly. It's invoked by 
     NXWriteRootObject() */
- (id)initWithCoder:(NSCoder *)aDecoder;
  /* 
     Note that -init is not sent to newly unarchived objects.
     You never send this message directly. It's invoked by NXReadObject() */

  /* The following methods are obsolete.  See MKTimbre. */
-setFreqRangeLow:(double)freq1 high:(double)freq2;
-(double)minFreq;
-(double)maxFreq;
-(BOOL)freqWithinRange:(double)freq;

-(int)tableType;
/* Returns type of currently cached data.  One of MK_oscTable or 
 * MK_waveshapingTable.
 */
@end

@interface MKPartials(OscTable)

- (DSPDatum *) dataDSPAsOscTableLength:(int)aLength;
 /* Returns a waveshaping table as an array of DSPDatums, recomputing 
    the data if necessary at the requested scaling and length. If the 
    subclass has no data, returns NULL. The data should neither be modified
    nor freed by the sender. 

    Same as dataDSPLength: */
 
- (double *)dataDoubleAsOscTableLength:(int)aLength;
 /* Returns a waveshaping table as an array of doubles, recomputing 
    the data if necessary at the requested scaling and length. If the 
    subclass has no data, returns NULL. The data should neither be modified
    nor freed by the sender. 

    Same as dataDoubleLength: */
 
 /* The following methods are minor variations of 
    dataDoubleAsOscTableScaling:length: and
    dataDSPAsOscTableScaling:length: and are implemented in terms 
    of them. They use default or previously specified length, scaling or both. 

    Same as corresponding superclass methods.
    */
- (DSPDatum *) dataDSPAsOscTable;
- (DSPDatum *) dataDSPAsOscTableLength:(int)aLength;
- (double *)   dataDoubleAsOscTable;
- (double *)   dataDoubleAsOscTableLength:(int)aLength;

- fillOscTableLength:(int)aLength scale:(double)aScaling ;
 /* 
   Computes the wavetable by taking the inverse FFT of the freq/amp/phase
   arrays. Returns self, or nil if an error is found. If 
   scaling is 0.0, the waveform is normalized. This method is sent
   automatically if necessary by the various data-retreival methods 
   (inherited from the WaveTable class).
   The resulting waveform is guaranteed to begin and end 
   at or near the same point only if the partial ratios are integers.
   Currently, only lengths that are a power of 2 are allowed.  

*/

- fillTableLength:(int)aLength scale:(double)aScaling ;
 /* Same as fillOscTableLength:scale: */

@end

@interface MKPartials(WaveshapingTable)

- (DSPDatum *) dataDSPAsWaveshapingTableLength:(int)aLength scale:(double)aScaling;
 /* Returns a waveshaping table as an array of DSPDatums, recomputing 
    the data if necessary at the requested scaling and length. If the 
    subclass has no data, returns NULL. The data should neither be modified
    nor freed by the sender. */
 
- (double *)dataDoubleAsWaveshapingTableLength:(int)aLength scale:(double)aScaling;
 /* Returns a waveshaping table as an array of doubles, recomputing 
    the data if necessary at the requested scaling and length. If the 
    subclass has no data, returns NULL. The data should neither be modified
    nor freed by the sender. */
 
 /* The following methods are minor variations of 
    dataDoubleAsWaveshapingTableScaling:length: and
    dataDSPAsWaveshapingTableScaling:length: and are implemented in terms 
    of them. They use default or previously specified length, scaling or both. 
    */
- (DSPDatum *) dataDSPAsWaveshapingTable;
- (DSPDatum *) dataDSPAsWaveshapingTableLength:(int)aLength;
- (DSPDatum *) dataDSPAsWaveshapingTableScale:(double)aScaling;
- (double *)   dataDoubleAsWaveshapingTable;
- (double *)   dataDoubleAsWaveshapingTableLength:(int)aLength;
- (double *)   dataDoubleAsWaveshapingTableScale:(double)aScaling;

- fillWaveshapingTableLength:(int)aLength scale:(double)aScaling;
 /* Computes the waveshaping table from the current freq/amp/phase arrays.
    Does the LeBrun "signification" algorithm on the result.

    Returns self, or nil if an error is found. If scaling is 0.0, the 
    table is normalized. This method is sent automatically if necessary by 
    the various data-retreival methods. 

    aLength works best if it is odd.
  */

@end

#endif
