/*
  $Id$
  Defined In: The MusicKit

  Description:
    A MKSamples object is a type of MKWaveTable that uses a Snd object (from
    the SndKit) as its data.  The Snd itself can only contain sampled
    data; each sample in the Snd corresponds to an array entry in the
    MKSamples object.  The Snd object can be set directly by invoking the
    method setSound:, or you can read it from a soundfile, through the
    readSoundfile: method.
   
    Note that the MKSamples object currently does not resample (except in
    one special case, when the sound is evenly divisible by the access
    length). Except in this special case, the length of the sound must be
    the same as the length you ask for with the access methods.
   
    Note also that for use with the MusicKit oscillator unit generators,
    the length must be a power of 2 and must fit in DSP memory (1024 or
    less is a good length).

   Original Author: David A. Jaffe

   Copyright (c) 1988-1992, NeXT Computer, Inc.
   Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
   Portions Copyright (c) 1994 Stanford University.
   Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
 Modification history:

  $Log$
  Revision 1.8  2001/09/08 21:53:16  leighsmith
  Prefixed MK for UnitGenerators and SynthPatches

  Revision 1.7  2001/09/07 18:36:34  leighsmith
  adopted symbolic entity naming and corrected parameter types in doco

  Revision 1.6  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.5  2000/05/09 03:12:18  leigh
  Removed NSSound use and fully replaced with SndKit,\
   if necessary, SndKit will just become a wrapper around NSSound

  Revision 1.4  2000/04/20 21:33:12  leigh
  Added extra methods to allow processing regions of samples

  Revision 1.3  2000/03/11 01:22:19  leigh
  Now using NSSound to replace Snd. This means removing functionality until NSSound is full-featured

  Revision 1.2  1999/07/29 01:25:49  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
/*!
  @class MKSamples
  @discussion

A MKSamples object represents one complete cycle of a sound waveform as a series
of samples.  The data for a MKSamples object is established through association
with a Sound object, defined by the Sound Kit.  Two methods are provided to
create this association:

&#183;	<b>setSound:</b> takes a Sound object as an argument, copies it, and
associates the reciever with the copied Sound.

&#183;	<b>readSoundfile:</b> takes the name of a soundfile, creates a Sound
object for the data contained therein, and associates the receiver with the
newly created Sound.

The Sound object or soundfile must be one channel of 16-bit linear data
(SND_FORMAT_LINEAR_16).  The sampling rate is ignored; MKSamples objects are
designed to be used as lookup tables for oscillator MKUnitGenerators in which use
the sampling rate of the original data is of no consequence.

You can create a MKSamples object from a scorefile by quoting the name of a
soundfile within curly brackets which are themselves enclosed by square
brackets.  The object can be given a name in a waveTable statement:

<tt>waveTable mySamples = [ {"samplesFile.snd" }];</tt>

A MKSamples object that's written to a soundfile is referred to by the name of the
soundfile from which it was created.  If a Sound object is used, a soundfile is
created and the object is written to it, as explained in the method
<b>writeScorefileStream:</b>.  You should always name your MKSamples objects by
calling the <b>MKNameObject()</b> C function.

MKSamples' sister class, MKPartials, lets you define a waveform by its sine wave
components.

MKSamples objects are automatically created by the Music Kit in a number of
circumstances, such as when reading a Scorefile.  The function
<b>MKSetSamplesClass()</b> allows you to specify that your own subclass of
MKSamples be used when MKSamples objects are automatically created.   You retrieve
the MKSamples class with <b>MKGetSamplesClass()</b>.  

Note that most of the Music Kit DSP oscillators require tables to be of a length
that is a power of 2.   Note also that the length of a Sample load to the DSP is
limited by the amount of DSP memory.

MKSamples can be used in two contexts - to provide wavetables for oscillators and
to provide tables for periodic excitation table (PET) synthesis.   The access
methods inherited from the MKWaveTable class (such as <b>-dataDSP</b>) provide the
data in oscillator table format.  In this case the MKPartials <i>tableType</i>internal<i> </i>
instance varaible is set to <b>MK_oscTable</b>.   Alternatively, you can retrieve
the data in excitation table format.  To do this, use one of the methods of the form <i>accessMethod</i>AsExcitationTable<i>arguments</i>.   For example, to get the data
for the DSP with the default table length and scaling, use -<b>dataDSPAsExcitationTable</b>.
In this case the MKPartials <i>tableType </i>instance varaible is set to <b>MK_excitationTable</b>.
For symmetry, a set of methods of the form <b>dataDSPAsOscTable</b> is provided.
These methods are synonyms for the inherited methods.   

Actually, excitationTable and oscTable formats are the same when the length
requested is the same as the length of the Sound.  However, the two behave
differently when asked for a length that differs from the length of the Sound. 
For a excitationTable, samples are omitted from the end of the Sound (if the
Sound is longer) or zeros are appended to the end of  the Sound (if the Sound is
shorter.)  For an oscTable, if the requested length evenly divides the actualy
length, the Sound is downsampled by simply omitting samples.  Note that
non-integer resampling is not currently supported.

See also:  MKWaveTable, MKPartials
*/
#ifndef __MK_Samples_H___
#define __MK_Samples_H___

#import "MKWaveTable.h"
#import <SndKit/SndKit.h>

@interface MKSamples : MKWaveTable
{
    Snd *sound;                       /* The object's Sound object. */
    NSString *soundfile;              /* The name of the soundfile, if the Sound was set through readSoundfile:. */
    int tableType;
    int curLoc;                       /* Index into current sample in soundfile */
    double amplitude;                 /* Amplitude scaling of soundfile in fixed point */
    unsigned int startSampleLoc;      /* Starting sample to be processed */
    unsigned int lastSampleLoc;       /* Ending sample to be processed, defining the portion of sound to be used. */
}


/*!
  @method init
  @result Returns an id.
  @discussion Send this message when you create a new instance.  You can also
              invoke this method to reset a MKSamples object.  It sets the
              receiver's <b>sound</b> variable to <b>nil</b> and <b>soundfile</b>
              to NULL.  The receiver's previous Sound object, if any, is freed.  A
              subclass implementation should send <b>[super init]</b>.  Returns
              the receiver.
*/
- init;
 /* 
  * Sent automatically when the receiver is created, you can also invoke
  * this method to reset a MKSamples object.  Sets the receiver's sound
  * variable to nil and soundfile to NULL.  The receiver's previous Sound
  * object, if any, is freed.  A subclass implementation should send
  * [super init].  Returns the receiver.  */

 /* Frees the receiver and its Snd.
  */
- (void)dealloc;

/*!
  @method copy
  @result Returns an id.
  @discussion Creates and returns a new MKSamples object as a copy of the receiver. 
              The receiver's Sound is copied into the new MKSamples object.
*/
- copyWithZone:(NSZone *)zone;

/*!
  @method setSound:
  @param  aSound is an Snd.
  @result Returns an id.
  @discussion Sets the receiver's Snd to a copy of <i>aSound</i> (the receiver's
              current Snd is freed).  <i>aSound</i> must be one-channel, 16-bit
              linear data.  You shouldn't free the Snd yourself; it's
              automatically freed when the receiver is freed, initialized, or when
              a subsequent Snd is set.  Returns <b>nil</b> if <i>aSound</i> is
              in the wrong format, otherwise returns the receiver.
*/
- (BOOL)setSound:(Snd *)aSound; 

/*!
  @method readSoundfile:
  @param  aSoundfile is an NSString.
  @result Returns a BOOL.
  @discussion Creates a new Snd object, reads the data from <i>aSoundfile</i>
              into the object, and then sends <b>setSound:</b> to the receiver
              with the new Snd as the argument.  You shouldn't free the Snd
              yourself; it's automatically freed when the receiver is freed,
              initialized, or when a subsequent Snd is set.  Returns <b>NO</b>
              if the <b>setSound:</b> message returns <b>nil</b>; otherwise
              returns YES for success.
*/
- (BOOL)readSoundfile:(NSString *)aSoundfile;

/*!
  @method sound
  @result Returns an Snd.
  @discussion Returns the receiver's Snd object.
*/
- (Snd *) sound;

/*!
  @method soundfile
  @result Returns an NSString.
  @discussion Returns the name of the receiver's soundfile, or <b>nil</b> if the
              receiver's Sound wasn't set through <b>readSoundfile:</b>.  The name
              isn't copied; you shouldn't alter the returned string.
*/
- (NSString *) soundfile;

/*!
  @method writeScorefileStream:
  @param  aStream is a NSMutableData.
  @result Returns an id.
  @discussion Writes the receiver in scorefile format.  Writes the receiver in
              scorefile format to the stream <i>aStream</i>.  If the Sound wasn't
              set from a soundfile, a soundfile with the unique name
              &ldquo;samples<i>Number</i>.snd&rdquo; (where <i>Number</i> is added
              only if needed), is created and the Sound is written to it.  The
              object remembers if its Sound has been written to a soundfile.  If
              the receiver couldn't be written to the stream, returns <b>nil</b>,
              otherwise returns the receiver.
*/
- writeScorefileStream:(NSMutableData *)aStream;
 /* 
  * Writes the receiver in scorefile format to the stream aStream.  A
  * MKSamples object is written by the name of the soundfile from which its
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

  /* 
     Archives object by archiving filename and sound object. Note that the
     sound object is archived whether it was created from readSoundfile:
     or from setSound:. We assume that the sound, even if it comes from
     an external source, is an intrinsic part of the object. 
     You never send this message directly.  */
- (void)encodeWithCoder:(NSCoder *)aCoder;

  /* 
     Note that -init is not sent to newly unarchived objects.
     You never send this message directly.  */
- (id)initWithCoder:(NSCoder *)aDecoder;


/*!
  @method tableType
  @result Returns an int.
  @discussion Returns the tableType of the currently-cached data, if any,
              either MK_oscTable or MK_excitationTable.  If
              none, returns the default, MK_oscTable.
*/
-(int)tableType;

- (void) setProcessingStartSample: (unsigned int) sampleNum;
    /* assigns the starting sample to begin some (arbitary) processing from */

- (unsigned int) processingStartSample;
    /* returns the sample used to begin some (arbitary) processing from */

- (void) setProcessingEndSample: (unsigned int) sampleNum;
    /* assigns the sample to end some (arbitary) processing at */

- (unsigned int) processingEndSample;
    /* returns the sample to end some (arbitary) processing at */

- (unsigned int) currentSample;
    /* returns the current sample being used to perform processing */

- (void) setCurrentSample: (unsigned int) sampleNum;
    /* assigns the current sample to perform processing at */

- (double) amplitude;
    /* returns the amplitude scaling */

- (void) setAmplitude: (double) amp;
    /* assigns an amplitude scaling */

- _fillTableLength:(int)aLength scale:(double)aScaling ;
 /* Private method that supports both OscTable and ExcitationTable */

@end

@interface MKSamples(OscTable)

/*!
  @method dataDSPAsOscTableLength:
  @param  aLength is an int.
  @result Returns a DSPDatum *.
  @discussion These methods provide data in <b>MK_oscTable</b> format.   They are
              identical to the superclass versions (without the "OscTable" in
              their name).  For example, <b>dataDSPAsOscTable</b>is the same as
              WaveTable's <b>dataDSP</b>.
              
              Returns a waveshaping table as an array of DSPDatums, recomputing 
              the data if necessary at the requested scaling and length. If the 
              subclass has no data, returns NULL. The data should neither be modified
              nor freed by the sender. 

              Same as dataDSPLength:   
*/
- (DSPDatum *) dataDSPAsOscTableLength:(int)aLength;
 
/*!
  @method dataDoubleAsOscTableLength:
  @param  aLength is an int.
  @result Returns a double *.
  @discussion These methods provide data in <b>MK_oscTable</b> format.   They are
              identical to the superclass versions (without the "OscTable" in
              their name).  For example, <b>dataDSPAsOscTable</b>is the same as
              WaveTable's <b>dataDSP</b>.
              
              Returns a waveshaping table as an array of doubles, recomputing 
              the data if necessary at the requested scaling and length. If the 
              subclass has no data, returns NULL. The data should neither be modified
              nor freed by the sender. 

              Same as dataDoubleLength:
*/
- (double *)dataDoubleAsOscTableLength:(int)aLength;
 
 /* The following methods are minor variations of 
    dataDoubleAsOscTableScaling:length: and
    dataDSPAsOscTableScaling:length: and are implemented in terms 
    of them. They use default or previously specified length, scaling or both. 

    Same as corresponding superclass methods.
*/
/*!
  @method dataDSPAsOscTableLength:
  @result Returns a DSPDatum *.
  @discussion These methods provide data in <b>MK_oscTable</b> format.   They are
              identical to the superclass versions (without the "OscTable" in
              their name).  For example, <b>dataDSPAsOscTable</b>is the same as
              WaveTable's <b>dataDSP</b>.
*/              
- (DSPDatum *) dataDSPAsOscTable;

/*!
  @method dataDoubleAsOscTableLength:
  @result Returns a double *.
  @discussion These methods provide data in <b>MK_oscTable</b> format.   They are
              identical to the superclass versions (without the "OscTable" in
              their name).  For example, <b>dataDSPAsOscTable</b>is the same as
              WaveTable's <b>dataDSP</b>.              
*/
- (double *)   dataDoubleAsOscTable;


/*!
  @method fillOscTableLength:scale:
  @param  aLength is an int.
  @param  aScaling is a double.
  @result Returns an id.
  @discussion Same as <b>fillTableLength:scale:</b>.   Provided for
              symmetry.
*/
- fillOscTableLength:(int)aLength scale:(double)aScaling ;
 /* 
   Computes the wavetable by copying the samples from the Sound.
   If scaling is 0.0, the waveform is normalized. This method is sent
   automatically if necessary by the various data-retreival methods 
   (inherited from the MKWaveTable class).  If aLength is not the
   same as the length of the data, sees if the length of the data
   is evenly divided by aLength.  If so, downsamples the data.
   Otherwise, generates a Music Kit error: MK_samplesNoResampleErr.
*/


/*!
  @method fillTableLength:scale:
  @param  aLength is an int.
  @param  aScaling is a double.
  @result Returns an id.
  @discussion Copies <i>aLength</i> samples from the receiver's Sound into the
              <b>dataDSP</b> array (inherited from MKWaveTable) and scales the
              copied data by multiplying it by <i>aScaling</i>.  If
              <i>aScaling</i> is 0.0, the data is scaled to fit perfectly within
              the range -.0 to 1.0.   Uses <b>oscTable</b> format.
              
              If <i>aLength</i> is different from the length of the Sound or soundfile, the sound is resampled.  (Note that currently only downsampling by a power of 2 is supported.)   
              
              The <b>dataDouble</b> array (also from MKWaveTable) is reset.  You ordinarily don't invoke this method; it's invoked from methods defined in MKWaveTable.  Returns self or <b>nil</b> if there's a problem.
*/
- fillTableLength:(int)aLength scale:(double)aScaling ;
 /* Same as fillOscTableLength:scale: */

@end

@interface MKSamples(ExcitationTable)

/*!
  @method dataDSPAsExcitationTableLength:scale:
  @param  aLength is an int.
  @param  aScaling is a double.
  @discussion These methods are similar to the superclass versions (without the
              "<b>ExcitationTable</b>" in their name), except that they specify
              that the table to be computed should be in <b>MK_excitationTable</b>
              format.   For example, <b>dataDSPAsExcitationTable</b> looks to see
              if the currently-cached data is of the type <b>MK_excitationTable</b>
              and is of the default length and scaling.  If so, that data is returned.
              If not, it is recomputed.
              
              Returns a Excitation table as an array of DSPDatums, recomputing 
              the data if necessary at the requested scaling and length. If the 
              subclass has no data, returns NULL. The data should neither be modified
              nor freed by the sender.
*/
- (DSPDatum *) dataDSPAsExcitationTableLength:(int)aLength scale:(double)aScaling;
 
/*!
  @method dataDoubleAsExcitationTableLength:scale:
  @param  aLength is an int.
  @param  aScaling is a double.
  @discussion These methods are similar to the superclass versions (without the
              "<b>ExcitationTable</b>" in their name), except that they specify
              that the table to be computed should be in <b>MK_excitationTable</b>
              format.   For example, <b>dataDSPAsExcitationTable</b> looks to see
              if the currently-cached data is of the type <b>MK_excitationTable</b>
              and is of the default length and scaling.  If so, that data is returned.
              If not, it is recomputed.
              
              Returns a Excitation table as an array of doubles, recomputing 
              the data if necessary at the requested scaling and length. If the 
              subclass has no data, returns NULL. The data should neither be modified
              nor freed by the sender.
*/
- (double *)dataDoubleAsExcitationTableLength:(int)aLength scale:(double)aScaling;
 
 /* The following methods are minor variations of 
    dataDoubleAsExcitationTableScaling:length: and
    dataDSPAsExcitationTableScaling:length: and are implemented in terms 
    of them. They use default or previously specified length, scaling or both. 
    */

/*!
  @method dataDSPAsExcitationTable
  @result Returns a DSPDatum *.
  @discussion These methods are similar to the superclass versions (without the
              "<b>ExcitationTable</b>" in their name), except that they specify
              that the table to be computed should be in <b>MK_excitationTable</b>
              format.   For example, <b>dataDSPAsExcitationTable</b> looks to see
              if the currently-cached data is of the type <b>MK_excitationTable</b>
              and is of the default length and scaling.  If so, that data is returned.
              If not, it is recomputed.   
*/
- (DSPDatum *) dataDSPAsExcitationTable;

/*!
  @method dataDSPAsExcitationTableLength:
  @param  aLength is an int.
  @result Returns a DSPDatum *.
  @discussion These methods are similar to the superclass versions (without the
              "<b>ExcitationTable</b>" in their name), except that they specify
              that the table to be computed should be in <b>MK_excitationTable</b>
              format.   For example, <b>dataDSPAsExcitationTable</b> looks to see
              if the currently-cached data is of the type <b>MK_excitationTable</b>
              and is of the default length and scaling.  If so, that data is returned.
              If not, it is recomputed.   
*/
- (DSPDatum *) dataDSPAsExcitationTableLength:(int)aLength;

/*!
  @method dataDSPAsExcitationTableScale:
  @param  aScaling is a double.
  @result Returns a DSPDatum *.
  @discussion These methods are similar to the superclass versions (without the
              "<b>ExcitationTable</b>" in their name), except that they specify
              that the table to be computed should be in <b>MK_excitationTable</b>
              format.   For example, <b>dataDSPAsExcitationTable</b> looks to see
              if the currently-cached data is of the type <b>MK_excitationTable</b>
              and is of the default length and scaling.  If so, that data is returned.
              If not, it is recomputed.   
*/
- (DSPDatum *) dataDSPAsExcitationTableScale:(double)aScaling;

/*!
  @method dataDSPAsExcitationTable
  @result Returns a double *.
  @discussion These methods are similar to the superclass versions (without the
              "<b>ExcitationTable</b>" in their name), except that they specify
              that the table to be computed should be in <b>MK_excitationTable</b>
              format.   For example, <b>dataDSPAsExcitationTable</b> looks to see
              if the currently-cached data is of the type <b>MK_excitationTable</b>
              and is of the default length and scaling.  If so, that data is returned.
              If not, it is recomputed.   
*/
- (double *)   dataDoubleAsExcitationTable;

/*!
  @method dataDoubleAsExcitationTableLength:
  @param  aLength is an int.
  @result Returns a double *.
  @discussion These methods are similar to the superclass versions (without the
              "<b>ExcitationTable</b>" in their name), except that they specify
              that the table to be computed should be in <b>MK_excitationTable</b>
              format.   For example, <b>dataDSPAsExcitationTable</b> looks to see
              if the currently-cached data is of the type <b>MK_excitationTable</b>
              and is of the default length and scaling.  If so, that data is returned.
              If not, it is recomputed.   
*/
- (double *)   dataDoubleAsExcitationTableLength:(int)aLength;

/*!
  @method dataDoubleAsExcitationTableScale:
  @param  aScaling is a double.
  @result Returns a double *.
  @discussion These methods are similar to the superclass versions (without the
              "<b>ExcitationTable</b>" in their name), except that they specify
              that the table to be computed should be in <b>MK_excitationTable</b>
              format.   For example, <b>dataDSPAsExcitationTable</b> looks to see
              if the currently-cached data is of the type <b>MK_excitationTable</b>
              and is of the default length and scaling.  If so, that data is returned.
              If not, it is recomputed.   
*/
- (double *)   dataDoubleAsExcitationTableScale:(double)aScaling;


/*!
  @method fillExcitationTableLength:scale:
  @param  aLength is an int.
  @param  aScaling is a double.
  @result Returns an id.
  @discussion Computes the sampled waveform from the sine wave components in
              <b>MK_excitationTable</b> format, by doing a recursive Chebychev
              polynomial expansion. If scaling is 0.0, the waveform is normalized.
              
              This method is invoked automatically by the data retrieval methods
              (inherited from the MKWaveTable class) such as
              <b>dataDSPAsExcitationTable</b> - you needn't invoke this method yourself.
              Returns the receiver, or <b>nil</b> if an error occurs.   Also sets the
              <i>tableType</i>internal instance variable to <b>MK_excitationTable</b>.
              If aLength is not the same as the length of the data, truncates or extends
              the sound. For best results, use an odd length.
*/
- fillExcitationTableLength:(int)aLength scale:(double)aScaling;

@end


#endif
