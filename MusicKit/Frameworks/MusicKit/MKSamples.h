/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit

  Description:
    A Samples object is a type of WaveTable that uses a NSSound object (from
    the AppKit) as its data.  The Sound itself can only contain sampled
    data; each sample in the Sound corresponds to an array entry in the
    Samples object.  The Sound object can be set directly by invoking the
    method setSound:, or you can read it from a soundfile, through the
    readSoundfile: method.
   
    Note that the Samples object currently does not resample (except in
    one special case, when the sound is evenly divisible by the access
    length). Except in this special case, the length of the sound must be
    the same as the length you ask for with the access methods.
   
    Note also that for use with the Music Kit oscillator unit generators,
    the length must be a power of 2 and must fit in DSP memory (1024 or
    less is a good length).

   Original Author: David Jaffe

   Copyright (c) 1988-1992, NeXT Computer, Inc.
   Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
   Portions Copyright (c) 1994 Stanford University
*/
/*
 Modification history:

  $Log$
  Revision 1.3  2000/03/11 01:22:19  leigh
  Now using NSSound to replace Snd. This means removing functionality until NSSound is full-featured

  Revision 1.2  1999/07/29 01:25:49  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_Samples_H___
#define __MK_Samples_H___

#import "MKWaveTable.h"
#import <AppKit/NSSound.h>

@interface MKSamples : MKWaveTable
{
    NSSound *sound;        /* The object's Sound object. */ 
    NSString *soundfile;   /* The name of the soundfile, if the Sound was set through readSoundfile:. */
    int tableType;
}

- init;
 /* 
  * Sent automatically when the receiver is created, you can also invoke
  * this method to reset a Samples object.  Sets the receiver's sound
  * variable to nil and soundfile to NULL.  The receiver's previous Sound
  * object, if any, is freed.  A subclass implementation should send
  * [super init].  Returns the receiver.  */

- (void)dealloc;
 /* Frees the receiver and its Sound.
  */

- copyWithZone:(NSZone *)zone;
 /* 
  * Creates and returns a new Samples object as a copy of the receiver.  The 
  * receiver's Sound is copied into the new Samples.
  * See also superclass -copy.
  */

- (BOOL)setSound:(NSSound *)aSound; 
 /* 
  * Sets the receiver's Sound to a copy of aSound (the receiver's current
  * Sound is freed).  aSound must be one-channel, 16-bit linear data.  You
  * shouldn't free the Sound yourself; it's automatically freed when the
  * receiver is freed, initialized, or when a subsequent Sound is set.
  * Returns nil if aSound is in the wrong format, otherwise frees the
  * receiver.  */

- (int)readSoundfile:(NSString *)aSoundfile;
 /* 
  * Creates a new Sound object, reads the data from aSoundfile into the
  * object, and then sends setSound: to the receiver with the new Sound as
  * the argument.  You shouldn't free the Sound yourself; it's
  * automatically freed when the receiver is freed, initialized, or when a
  * subsequent Sound is set.  Returns nil if the setSound: message returns
  * nil; otherwise returns the receiver.  */
 /*sb: now conforms to the Sound specification, and returns an int. 0 instead
  * of nil, 1 otherwise (success)
  */

- sound;
 /* Returns the receiver's Sound object. */

- (NSString *) soundfile;
 /* 
  * Returns the name of the receiver's soundfile, or NULL if the
  * receiver's Sound wasn't set through readSoundfile:.  The name isn't
  * copied; you shouldn't alter the returned string.  */

- writeScorefileStream:(NSMutableData *)aStream;
 /* 
  * Writes the receiver in scorefile format to the stream aStream.  A
  * Samples object is written by the name of the soundfile from which its
  * Sound was read, surrounded by braces:
  * 
  *   { "soundfileName" }
  * 
  * If the Sound wasn't set from a soundfile, a soundfile with the
  * unique name "samplesNumber.snd" (where number is added only if
  * needed), is created and the Sound is written to it.  The object
  * remembers if its Sound has been written to a soundfile.  If the
  * receiver couldn't be written to the stream, returns nil, otherwise
  * returns the receiver.
  * 
  */

- (void)encodeWithCoder:(NSCoder *)aCoder;
  /* 
     Archives object by archiving filename and sound object. Note that the
     sound object is archived whether it was created from readSoundfile:
     or from setSound:. We assume that the sound, even if it comes from
     an external source, is an intrinsic part of the object. 
     You never send this message directly.  */

- (id)initWithCoder:(NSCoder *)aDecoder;
  /* 
     Note that -init is not sent to newly unarchived objects.
     You never send this message directly.  */

-(int)tableType;
/* Returns type of currently cached data.  One of MK_oscTable or 
 * MK_excitationTable.
 */

- _fillTableLength:(int)aLength scale:(double)aScaling ;
 /* Private method that supports both OscTable and ExcitationTable */

@end

@interface MKSamples(OscTable)

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
   Computes the wavetable by copying the samples from the Sound.
   If scaling is 0.0, the waveform is normalized. This method is sent
   automatically if necessary by the various data-retreival methods 
   (inherited from the WaveTable class).  If aLength is not the
   same as the length of the data, sees if the length of the data
   is evenly divided by aLength.  If so, downsamples the data.
   Otherwise, generates a Music Kit error: MK_samplesNoResampleErr.
*/

- fillTableLength:(int)aLength scale:(double)aScaling ;
 /* Same as fillOscTableLength:scale: */

@end

@interface MKSamples(ExcitationTable)

- (DSPDatum *) dataDSPAsExcitationTableLength:(int)aLength scale:(double)aScaling;
 /* Returns a Excitation table as an array of DSPDatums, recomputing 
    the data if necessary at the requested scaling and length. If the 
    subclass has no data, returns NULL. The data should neither be modified
    nor freed by the sender. */
 
- (double *)dataDoubleAsExcitationTableLength:(int)aLength scale:(double)aScaling;
 /* Returns a Excitation table as an array of doubles, recomputing 
    the data if necessary at the requested scaling and length. If the 
    subclass has no data, returns NULL. The data should neither be modified
    nor freed by the sender. */
 
 /* The following methods are minor variations of 
    dataDoubleAsExcitationTableScaling:length: and
    dataDSPAsExcitationTableScaling:length: and are implemented in terms 
    of them. They use default or previously specified length, scaling or both. 
    */
- (DSPDatum *) dataDSPAsExcitationTable;
- (DSPDatum *) dataDSPAsExcitationTableLength:(int)aLength;
- (DSPDatum *) dataDSPAsExcitationTableScale:(double)aScaling;
- (double *)   dataDoubleAsExcitationTable;
- (double *)   dataDoubleAsExcitationTableLength:(int)aLength;
- (double *)   dataDoubleAsExcitationTableScale:(double)aScaling;

- fillExcitationTableLength:(int)aLength scale:(double)aScaling;
 /* Computes the wavetable by copying the samples from the Sound.
   If scaling is 0.0, the waveform is normalized. This method is sent
   automatically if necessary by the various data-retreival methods 
   (inherited from the WaveTable class).  If aLength is not the
   same as the length of the data, truncates or extends the sound.
  */

@end


#endif
