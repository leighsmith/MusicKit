/*
  $Id$
  Defined In: The MusicKit

  Description:
    A MKPartials object contains arrays that specify the amplitudes,
    frequency ratios, and initial phases of a set of partials.  This
    information is used to synthesize a waveform.  The synthesized data is
    referenced by the methods inherited from MKWaveTable.
    
    Ordinarily, the frequency ratios are multiplied by the base frequency
    of the MKUnitGenerator that uses the MKPartials object.  Similarly, the
    amplitude ratios defined in the MKPartials object are multiplied by the
    MKUnitGenerator's amplitude term.
    
    MKPartials objects can also deliver their data as Waveshaping tables.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 CCRMA, Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.6  2001/09/07 18:38:20  leighsmith
  adopted symbolic entity naming

  Revision 1.5  2001/09/06 21:27:47  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.4  2000/11/25 22:57:21  leigh
  Enforced ivar privacy

  Revision 1.3  2000/10/04 06:16:15  skot
  Added description selectors

  Revision 1.2  1999/07/29 01:25:48  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
/*!
  @class MKPartials
  @discussion

The MKPartials class lets you define a sound waveform by adding together a number
of sine wave components.  MKPartials are used to provide musical timbres in DSP
synthesis, primarily by the MKSynthPatch classes that provide wave table synthesis
- classes such as Wave1vi and DBWave1vi, as well as classes that provide
waveshaping synthesis - class such as Shape.  MKPartials' sister class, MKSamples,
lets you define a waveform (or waveshaping table) as a series of sound samples,
through association with a Sound object or soundfile.

Each of the sine waves in a MKPartials object is characterized by a frequency
ratio, an amplitude ratio, and an initial phase.  The frequency ratios are taken
as integer multiples of a fundamental frequency - in other words, a ratio of 1.0
is the fundamental frequency, 2.0 is twice the fundamental, 3.0 is three times
the fundamental, and so on.  The fundamental frequency itself is defined in the
frequency parameters of the MKNote objects that use the MKPartials.  The amplitude
ratios are relative to each other: A sine wave component with an amplitude ratio
of 0.5 has half the amplitude of a component with an amplitude ratio of 1.0. 
The initial phase determines the point in the sine curve at which a particular
component starts.  Phase is specified in degrees; a phase of 360.0 is the same
as a phase of 0.0.  While phase information has been found to have little
significance in the perception of timbre, it can be important in other uses. 
For example, if you're creating a waveform that's used as a sub-audio control
signal - most notably for vibrato - you will probably want to randomize or
stagger the phases of the sine waves.

All the component information for a MKPartials object is set through the
<b>setPartialCount:freqRatios:ampRatios:phases:orDefaultPhase:</b> method.  The
first argument, an <b>int</b>, is the number of sine waves in the object.  The
next three arguments are pointers to arrays of <b>double</b>s that provide
corresponding lists of frequency, amplitude, and phase information.  The
additional <b>orDefaultPhase:</b> keyword is provided in recognition of phase's
slim contribution to the scheme:  Rather than create and set an array of initial
phases, you can pass NULL to <b>phases:</b> and set all the sine wave components
to a common initial phase as the argument to <b>orDefaultPhase:</b>.  The
following example demonstrates how to create a simple, three component MKPartials
object.

<tt>
double freqs    = {1.0, 2.0, 3.0 };
double amps  = {1.0, 0.5, 0.25 };
id aPartials    = [MKPartials new];

[aPartials setPartialCount: 3
                freqRatios: freqs
                 ampRatios: amps
                    phases: NULL
            orDefaultPhase: 0.0];
</tt>

The elements in the arrays are matched by index order:  The first sine wave is
defined by the first element of <b>freqs</b> and the first element of
<b>amps</b>; the second elements of the arrays define the second sine wave; the
third elements define the third sine wave.  Since the phase array is specified
as NULL, all three sine waves are given an initial phase of 0.0.

In a scorefile, MKPartials are defined as curly-bracketed value pairs - or
triplets if you want to specify phase - and the entire MKPartials definition is
enclosed in square brackets.  If a phase value is missing, the phase of the
previous component is used; the default phase is 0.0.  You can define a MKPartials
object in-line as the value of a parameter or, more typically, in a global
<b>waveTable</b> statement.  The previous example could be defined in a
scorefile as

<tt>waveTable simpleSound = [{1.0, 1.0}{2.0, 0.5}{3.0, 0.25}];</tt>

where <b>simpleSound</b> is used to identify the object in subsequent MKNote
statements:

<tt>partName (1.0) ... waveform:simpleSound ...;</tt>

When this scorefile is read into an application, the MKPartials object will be
given the string name &ldquo;simpleSound&rdquo;.  The object itself can be
retrieved by passing this string to the <b>MKGetNamedObject()</b> C
function.

If you're creating a MKPartials object in an application and writing it to a
scorefile, you should always name the object through <b>MKNameObject()</b>. 
This allows the object to be defined once (albeit in-line, not in the header) in
a <b>waveTable</b> statement and then referred to by name in subsequent MKNotes. 
Without a name, a MKPartials object is defined in-line in every MKNote statement
that refers to it.

MKPartials objects are automatically created by the Music Kit in a number of
circumstances, such as when reading a Scorefile.  The function
<b>MKSetPartialsClass()</b> allows you to specify that your own subclass of
MKPartials be used when Partialss are automatically created.   You retrieve the
MKPartials class with <b>MKGetPartialsClass()</b>.  

MKPartials can be used in two contexts - to provide wavetables for oscillators and
to provide lookup tables for waveshaping synthesis.   The access methods
inherited from the MKWaveTable class (such as <b>-dataDSP</b>) provide the data in
oscillator table format.  In this case the MKPartials <i>tableType</i>internal<i>
</i> instance varaible is set to <b>MK_oscTable</b>.   Alternatively, you can
retrieve the data in waveshaping format.  To do this, use one of the methods of
the form <i>accessMethod</i>AsWaveshapingTable<i>arguments</i>.   For example,
to get the data for the DSP with the default table length and scaling, use
-<b>dataDSPAsWaveshapingTable</b>.  In this case the MKPartials <i>tableType
</i>instance varaible is set to <b>MK_waveshapingTable</b>.   For symmetry, a
set of methods of the form <b>dataDSPAsOscTable</b> is provided.  These methods
are synonyms for the inherited methods.   

For more information on waveshaping synthesis, see the <b>Shape</b>and
<b>Shapev</b>  SynthPatches and their documentation.   
*/
#ifndef __MK_Partials_H___
#define __MK_Partials_H___
//sb:
#import <Foundation/Foundation.h>

#import <Foundation/NSObject.h>
#import "MKWaveTable.h"
#import "MKSamples.h"

@interface MKPartials : MKWaveTable 
{
    double *ampRatios;   /* Array of amplitudes. */
    double *freqRatios;  /* Array of frequencies. */
    double *phases;      /* Arrays of initial phases. */
    int partialCount;    /* Number of points in each array */
    double defaultPhase; /* Default phase. If no phase-array, this is phase */
    double minFreq;      /* Obsolete. See MKTimbre. */
    double maxFreq;      /* Obsolete. See MKTimbre. */

@private
    BOOL _ampArrayFreeable,_freqArrayFreeable,_phaseArrayFreeable;
    BOOL dbMode;
    int tableType;
}
 

/*!
  @method init
  @result Returns an id.
  @discussion Initializes the receiver.  A subclass implementation should send
              <b>[super init]</b> before performing its own initialization. 
              
*/
- init; 

 /* 
  * Returns a copy of the receiver with its own copy of arrays. 
  * See also superclass -copy.
  */
- copyWithZone:(NSZone *)zone;

  /* Frees the receiver and all its arrays. */
- (void)dealloc; 

- (NSString*) description;

/*!
  @method highestFreqRatio
  @result Returns a double.
  @discussion Returns the highest (i.e., largest absolute value) frequency ratio
              in the receiver. This can be
              useful for optimizing lookup table sizes in determining if the receiver
              will generate a waveform that will fold over.
*/
-(double)highestFreqRatio;

/*!
  @method setPartialCount:freqRatios:ampRatios:phases:orDefaultPhase:
  @param  count is an int.
  @param  freqRats is a double *.
  @param  ampRats is a double *.
  @param  phases is a double *.
  @param  defaultPhase is a double.
  @result Returns an id.
  @discussion Defines the receiver's sine wave components.  <i>count</i> is the
              number of sine waves components; freqRats<i>,</i>ampRats, and
              <b>phases</b>  are pointers to arrays that define the frequency
              ratios, amplitude ratios, and initial phases, respectively, of the
              sine wave components (the arrays are copied into the receiver).  The
              elements of the arrays are matched by index order: The nth sine wave
              is configured from the nth element in each array.
              
              If <i>phases</i> is NULL, the value of <i>defaultPhase</i> is used as
              the initial phase for all the components.  If <i>freqRats</i> or <i>ampRats</i>
              is NULL, the corresponding extant array, if any, is unchanged.
              
              Note that this method sets the <b>length</b> instance variable to 0, forcing
              a recompute in a subsequent data array retrieval (through the <b>dataDSP:...</b>
              and <b>dataDouble:...</b> methods) as explained in the MKWaveTable class.
              
              Returns the receiver.
*/
- setPartialCount: (int) count
       freqRatios: (double *) fRatios
        ampRatios: (double *) aRatios
           phases: (double *) phases
   orDefaultPhase: (double) defaultPhase;
 /* 
   This method is used to specify the amplitude and frequency
   ratios and initial phases (in degrees) of a set of partials representing a
   waveform.  If one of the data retrieval methods is called (inherited from 
   the MKWaveTable object), a wavetable is synthesized and returned.
   The resulting waveform is guaranteed to begin and end 
   at or near the same point only if the partial ratios are integers.

   If phs is NULL, the defPhase value is used for all
   harmonics.  If aRatios or fRatios is NULL, the corresponding value is
   unchanged. The array arguments are copied. */


/*!
  @method setFromSamples:
  @param  samplesObject is an id.
  @result Returns an id.
  @discussion Sets <i>freqRatios</i>, <i>ampRatios</i>, and <i>phases</i> based on
              the data in the samplesObject.  This is done by taking an FFT of the
              data.
*/
- setFromSamples:(MKSamples *)samplesObject;
    
/*!
  @method prunePartials:
  @param  amplitudeThreshold is a double.
  @discussion Change contents to remove any partials with amplitudes below 
              specified threshold. 
*/
-prunePartials:(double)amplitudeThreshold;

/*!
  @method partialCount
  @result Returns an int.
  @discussion Returns the number of sine wave components
*/
- (int)partialCount;

/*!
  @method freqRatios
  @result Returns a double *.
  @discussion Returns a pointer to the receiver's frequency ratios array.  You
              should neither free nor alter the array.
*/
- (double *)freqRatios; 

/*!
  @method ampRatios
  @result Returns a double *.
  @discussion Returns a pointer to the receiver's amplitude ratios array.  You
              should neither free nor alter the array.
*/
- (double *)ampRatios; 

/*!
  @method defaultPhase
  @result Returns a double.
  @discussion Returns the receiver's default phase
*/
- (double)defaultPhase;

/*!
  @method phases
  @result Returns a double *.
  @discussion Returns a pointer to the receiver's phase array or NULL if none.
              You should neither free nor alter the array.
*/
- (double *)phases; 

/*!
  @method getPartial:freqRatio:ampRatio:phase:
  @param  n is an int.
  @param  fRatio is a double *.
  @param  aRatio is a double *.
  @param  phase is a double *.
  @result Returns an int.
  @discussion Returns, by reference, the frequency ratio, amplitude ratio, and
              initial phase of the <i>n</i>th sine wave component (counting from
              0).  The amplitude ratio value is scaled by the current value of the
              <b>scaling</b> instance variable inherited from MKWaveTable.
                            
              If the <i>n</i>th sine wave is the last in the
              receiver, the method returns MK_lastValue.  If <i>n</i> is out of
              bounds, - is returned.  Otherwise 0 is returned.
*/
- (int) getPartial: (int) n
         freqRatio: (double *) fRatio
          ampRatio: (double *) aRatio
             phase: (double *) phase;
 /* 
   Get specified partial by reference. n is the zero-based
   index of the partial. If the specified partial is the last value, 
   returns 2. If the specified value is out of bounds, 
   returns -1. Otherwise returns 0.
   The partial amplitude is scaled by the scaling constant.
   */


/*!
  @method writeScorefileStream:
  @param  aStream is a NSMutableData.
  @result Returns an id.
  @discussion Writes the receiver in scorefile format on the specified stream. 
              Returns <b>nil</b> if ampRatios or freqRatios is NULL, otherwise
              returns the receiver.
*/
-writeScorefileStream:(NSMutableData *)aStream;

  /* 
     You never send this message directly. It's invoked by 
     NXWriteRootObject() */
- (void)encodeWithCoder:(NSCoder *)aCoder;

  /* 
     Note that -init is not sent to newly unarchived objects.
     You never send this message directly. It's invoked by NXReadObject() */
- (id)initWithCoder:(NSCoder *)aDecoder;

  /* The following methods are obsolete.  See MKTimbre. */
-setFreqRangeLow:(double)freq1 high:(double)freq2;
-(double)minFreq;
-(double)maxFreq;
-(BOOL)freqWithinRange:(double)freq;


/*!
  @method tableType
  @result Returns an int.
  @discussion Returns the tableType of the currently-cached data, if any. 
              Either MK_oscTable or MK_waveshapingTable.
              If none, returns the default, MK_oscTable.
*/
-(int)tableType;

@end

@interface MKPartials(OscTable)

 /* The following methods are minor variations of 
    dataDoubleAsOscTableScaling:length: and
    dataDSPAsOscTableScaling:length: and are implemented in terms 
    of them. They use default or previously specified length, scaling or both. 

    Same as corresponding superclass methods.
*/
    
/*!
  @method dataDSPAsOscTable
  @result Returns a DSPDatum *.
  @discussion These methods provide data in <b>MK_oscTable</b> format.   They are
              identical to the superclass versions (without the "OscTable" in
              their name).  For example, <b>dataDSPAsOscTable</b>is the same as
              WaveTable's <b>dataDSP</b> .   
*/
- (DSPDatum *) dataDSPAsOscTable;

/*!
  @method dataDSPAsOscTableLength:
  @param  aLength is an int.
  @result Returns a DSPDatum *.
  @discussion These methods provide data in <b>MK_oscTable</b> format.   They are
              identical to the superclass versions (without the "OscTable" in
              their name).  For example, <b>dataDSPAsOscTable</b>is the same as
              WaveTable's <b>dataDSP</b> .   

              Returns a waveshaping table as an array of DSPDatums, recomputing 
              the data if necessary at the requested scaling and length. If the 
              subclass has no data, returns NULL. The data should neither be modified
              nor freed by the sender. 

              Same as dataDSPLength:
*/
- (DSPDatum *) dataDSPAsOscTableLength:(int)aLength;

/*!
  @method dataDoubleAsOscTable
  @result Returns a double *.
  @discussion These methods provide data in <b>MK_oscTable</b> format.   They are
              identical to the superclass versions (without the "OscTable" in
              their name).  For example, <b>dataDSPAsOscTable</b>is the same as
              WaveTable's <b>dataDSP</b> .   
*/
- (double *)   dataDoubleAsOscTable;

/*!
  @method dataDoubleAsOscTableLength:
  @param  aLength is an int.
  @result Returns a double *.
  @discussion These methods provide data in <b>MK_oscTable</b> format.   They are
              identical to the superclass versions (without the "OscTable" in
              their name).  For example, <b>dataDSPAsOscTable</b>is the same as
              WaveTable's <b>dataDSP</b> .   

              Returns a waveshaping table as an array of doubles, recomputing 
              the data if necessary at the requested scaling and length. If the 
              subclass has no data, returns NULL. The data should neither be modified
              nor freed by the sender. 

              Same as dataDoubleLength:
*/
- (double *)   dataDoubleAsOscTableLength:(int)aLength;

/*!
  @method fillOscTableLength:scale:
  @param  aLength is an int.
  @param  aScaling is a double.
  @result Returns an id.
  @discussion Same as <b>fillTableLength:scale:</b>.   Provided for
              symmetry. Computes the wavetable by taking the inverse FFT
              of the freq/amp/phase arrays. Returns self, or nil if an error is found. If 
              scaling is 0.0, the waveform is normalized. This method is sent
              automatically if necessary by the various data-retreival methods 
              (inherited from the MKWaveTable class).
              The resulting waveform is guaranteed to begin and end 
              at or near the same point only if the partial ratios are integers.
              Currently, only lengths that are a power of 2 are allowed.  
*/
- fillOscTableLength:(int)aLength scale:(double)aScaling ;

/*!
  @method fillTableLength:scale:
  @param  aLength is an int.
  @param  aScaling is a double.
  @result Returns an id.
  @discussion Computes the sampled waveform from the sine wave components in
              <b>MK_oscTable</b> format, by doing an inverse FFT.
              
              This method is invoked automatically by the data retrieval methods
              inherited from the MKWaveTable class - you needn't invoke this method
              yourself.  Returns the receiver, or <b>nil</b> if an error occurs.
              Also sets the <i>tableType</i> internal instance variable to <b>MK_oscTable</b>.
              
              <i>Note that currently, only power-of-2 lengths are supported for oscTable format.</i>
*/
- fillTableLength:(int)aLength scale:(double)aScaling;

@end

@interface MKPartials(WaveshapingTable)

 /* The following methods are minor variations of 
    dataDoubleAsWaveshapingTableScaling:length: and
    dataDSPAsWaveshapingTableScaling:length: and are implemented in terms 
    of them. They use default or previously specified length, scaling or both. 
    */
/*!
  @method dataDSPAsWaveshapingTable
  @result Returns a DSPDatum *.
  @discussion These methods are similar to the superclass versions (without the
              "WaveshapingTable" in their name), except that they specify that the
              table to be computed should be in <b>MK_waveshapingTable</b> format.
              For example, <b>dataDSPAsWaveshapingTable</b> looks to see if the
              currently-cached data is of the type <b>MK_waveshapingTable</b> and
              is of the default length and scaling.  If so, that data is returned.
              If not, it is recomputed.   
*/
- (DSPDatum *) dataDSPAsWaveshapingTable;
/*!
  @method dataDSPAsWaveshapingTable
  @param  aLength is an int.
  @result Returns a DSPDatum *.
  @discussion These methods are similar to the superclass versions (without the
              "WaveshapingTable" in their name), except that they specify that the
              table to be computed should be in <b>MK_waveshapingTable</b> format.
              For example, <b>dataDSPAsWaveshapingTable</b> looks to see if the
              currently-cached data is of the type <b>MK_waveshapingTable</b> and
              is of the default length and scaling.  If so, that data is returned.
              If not, it is recomputed.   
*/
- (DSPDatum *) dataDSPAsWaveshapingTableLength:(int)aLength;
/*!
  @method dataDSPAsWaveshapingTable
  @param  aScaling is a double.
  @result Returns a DSPDatum *.
  @discussion These methods are similar to the superclass versions (without the
              "WaveshapingTable" in their name), except that they specify that the
              table to be computed should be in <b>MK_waveshapingTable</b> format.
              For example, <b>dataDSPAsWaveshapingTable</b> looks to see if the
              currently-cached data is of the type <b>MK_waveshapingTable</b> and
              is of the default length and scaling.  If so, that data is returned.
              If not, it is recomputed.   
*/
- (DSPDatum *) dataDSPAsWaveshapingTableScale:(double)aScaling;

/*!
  @method dataDSPAsWaveshapingTable
  @param  aLength is an int.
  @param  aScaling is a double.
  @result Returns a DSPDatum *.
  @discussion These methods are similar to the superclass versions (without the
              "WaveshapingTable" in their name), except that they specify that the
              table to be computed should be in <b>MK_waveshapingTable</b> format.
              For example, <b>dataDSPAsWaveshapingTable</b> looks to see if the
              currently-cached data is of the type <b>MK_waveshapingTable</b> and
              is of the default length and scaling.  If so, that data is returned.
              If not, it is recomputed.
              
              Returns a waveshaping table as an array of DSPDatums, recomputing 
              the data if necessary at the requested scaling and length. If the 
              subclass has no data, returns NULL. The data should neither be modified
              nor freed by the sender.
*/
- (DSPDatum *) dataDSPAsWaveshapingTableLength:(int)aLength scale:(double)aScaling;
 
/*!
  @method dataDoubleAsWaveshapingTable
  @result Returns a double *.
  @discussion These methods are similar to the superclass versions (without the
              "WaveshapingTable" in their name), except that they specify that the
              table to be computed should be in <b>MK_waveshapingTable</b> format.
              For example, <b>dataDSPAsWaveshapingTable</b> looks to see if the
              currently-cached data is of the type <b>MK_waveshapingTable</b> and
              is of the default length and scaling.  If so, that data is returned.
              If not, it is recomputed.   
*/
- (double *)   dataDoubleAsWaveshapingTable;

/*!
  @method dataDoubleAsWaveshapingTable
  @param  aLength is an int.
  @result Returns a double *.
  @discussion These methods are similar to the superclass versions (without the
              "WaveshapingTable" in their name), except that they specify that the
              table to be computed should be in <b>MK_waveshapingTable</b> format.
              For example, <b>dataDSPAsWaveshapingTable</b> looks to see if the
              currently-cached data is of the type <b>MK_waveshapingTable</b> and
              is of the default length and scaling.  If so, that data is returned.
              If not, it is recomputed.   
*/
- (double *)   dataDoubleAsWaveshapingTableLength:(int)aLength;

/*!
  @method dataDoubleAsWaveshapingTable
  @param  aScaling is a double.
  @result Returns a double *.
  @discussion These methods are similar to the superclass versions (without the
              "WaveshapingTable" in their name), except that they specify that the
              table to be computed should be in <b>MK_waveshapingTable</b> format.
              For example, <b>dataDSPAsWaveshapingTable</b> looks to see if the
              currently-cached data is of the type <b>MK_waveshapingTable</b> and
              is of the default length and scaling.  If so, that data is returned.
              If not, it is recomputed.   
*/
- (double *)   dataDoubleAsWaveshapingTableScale:(double)aScaling;

/*!
  @method dataDoubleAsWaveshapingTable
  @param  aLength is an int.
  @param  aScaling is a double.
  @result Returns a double *.
  @discussion These methods are similar to the superclass versions (without the
              "WaveshapingTable" in their name), except that they specify that the
              table to be computed should be in <b>MK_waveshapingTable</b> format.
              For example, <b>dataDSPAsWaveshapingTable</b> looks to see if the
              currently-cached data is of the type <b>MK_waveshapingTable</b> and
              is of the default length and scaling.  If so, that data is returned.
              If not, it is recomputed.
              
              Returns a waveshaping table as an array of doubles, recomputing 
              the data if necessary at the requested scaling and length. If the 
              subclass has no data, returns NULL. The data should neither be modified
              nor freed by the sender.
*/
- (double *)   dataDoubleAsWaveshapingTableLength:(int)aLength scale:(double)aScaling; 

/*!
  @method fillWaveshapingTableLength:scale:
  @param  aLength is an int.
  @param  aScaling is a double.
  @result Returns an id.
  @discussion Computes the sampled waveform from the sine wave components in
              <b>MK_waveshapingTable</b> format, by doing a recursive Chebychev
              polynomial expansion.
              
              If scaling is 0.0, the 
              table is normalized. This method is invoked automatically by the
              data retrieval methods such as <b>dataDSPAsWaveshapingTable</b> -
              you needn't invoke this method yourself.
              Returns the receiver, or <b>nil</b> if an error occurs.   Also sets the
              <i>tableType</i> internal instance variable to <b>MK_waveshapingTable</b>.
              For best results, use an odd length.
*/
- fillWaveshapingTableLength:(int)aLength scale:(double)aScaling;
 /* Computes the waveshaping table from the current freq/amp/phase arrays.
    Does the LeBrun "signification" algorithm on the result.
  */

@end

#endif
