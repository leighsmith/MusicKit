/*
  $Id$
  Defined In: The MusicKit

  Description:
    See discussion below.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University  
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*!
  @class MKWaveTable
  @brief A MKWaveTable represents a single period of a sound waveform as a series of samples. 
 
MKWaveTable is an abstract class that's succeeded by two inheriting
classes:  MKSamples and MKPartials.  The MKSamples subclass lets you define a
MKWaveTable through association with a Sound object or soundfile; MKPartials lets
you build a waveform by adding sine wave components.  If you're interested in
using Wavetables to create a library of timbres you should refer to the
descriptions of the MKSamples and MKPartials subclasses.  Detailed familiarity with
the MKWaveTable class, in this case, isn't necessary.

MKWaveTable objects are designed to be used as <i>lookup tables</i> for oscillator
MKUnitGenerators such as OscgafiUG.  When it's instructed to run, the oscillator
downloads the WaveTable's data to a portion of memory on the DSP and then cycles
over the data to generate a timbre that's defined by the shape of the waveform
that the data represents.  To assist this process, a MKWaveTable object maintains
two separate arrays of data pointed to by the <b>dataDSP</b> and
<b>dataDouble</b> 

A MKWaveTable contain an array of data that's used by a MKUnitGenerator
object as a lookup table.  The Music Kit provides two subclasses of
this absract class: MKPartials, and MKSamples.

Access to the data is through one of the data: methods.  The method
used depends on the data type needed (type DSPDatum (i.e., for the
DSP) or type double), the scaling needed and the length of the array
needed.  If necessary, the subclass is called upon to recompute the
data.  These methods do not copy the data. Thus, the caller should not
free or alter the array of data. The need to recompute is recognized
on the basis of whether the length or scaling instance variables have
changed.  The subclass can signal that a recomputation is needed by
setting length to 0.
  
The computation of the data is handled by the subclass method
fillTableLength:scale:.

Subclasses provided by the MusicKit are:

<UL>
 <LI>MKPartials computes a MKWaveTable given an arrays of harmonic amplitudes,
 frequency ratios, and phases.</LI>

 <LI>MKSamples stores a MKWaveTable of existing samples read in from a Sound
 object or soundfile.</LI>
</UL>
 
The MKWaveTable class caches multiple formats for the data. This is
useful because it is expensive to recompute the data.
Access to the data is through one of the "data" methods (-dataDSP, -dataDouble, etc.).
The method used depends on the data type needed (type DSPDatum for the DSP
or type double), the scaling needed, and the length of the array needed.
The caller should not free nor alter the array of data.

If necessary, the subclass is called upon to recompute the data.
The computation of the data is handled by the subclass method
fillTableLength:scale:.
 
*/
#ifndef __MK_WaveTable_H___
#define __MK_WaveTable_H___

#import <Foundation/NSObject.h>
//sb:
#import "dsp_types.h" /* for DSPDatum */

@interface MKWaveTable : NSObject
{
    unsigned int length;    /* Non-0 if a data table exists, 0 otherwise */
    double scaling;         /* 0.0 = normalization scaling */
    DSPDatum *dataDSP;      /* Loaded or computed 24-bit signed data */
    double *dataDouble;     /* Loaded or computed floating-point data */
}

/*!
  @brief Creates and returns a new MKWaveTable as a copy of the receiver.

  @return Returns an id.
*/
- copyWithZone: (NSZone *) zone;

/*!
  @brief Initializes the receiver.

  This method should be invoked when a new
  MKWaveTable is created.  You can also use it to reset, or empty, an
  existing object.  If you override this method in a subclass, you
  should include <b>[super init]</b> in the implementation.  Returns
  the receiver.
  @return Returns an id.
*/
- init;

/*!
  @brief dealloc frees dataDSP and dataDouble then sends [super free].
    
  It also removes the name, if any, from the MusicKit name table. 
 */
- (void)dealloc;

/*!
  @return Returns an int.
  @brief Returns the length, in elements, of the data arrays (the two arrays
  should always contain the same number of elements).

  A return value
  of 0 indicates that the arrays haven't been filled, or that the data
  needs to be recomputed.
*/
- (unsigned int)length;
 /* Length returns the length in samples of the data buffers.  If it is 0,
    neither the DSPDatum or real buffer has been allocated. */


/*!
  @return Returns a double.
  @brief Returns the factor by which the values (sample amplitues) in the
  data arrays are scaled.

  A return value of 0.0, the default,
  indicates that the values are normalized, or scaled to fit perfectly
  within the range -1.0 to 1.0.
*/
- (double)scaling; 
 /* Scaling returns the current scaling of the data buffers.  If it is 0,
    normalization scaling is specified. Normalization is the default. */


/*!
  @param  aLength is an int.
  @param  aScaling is a double.
  @return Returns a DSPDatum *. Returns the wavetable as an array of DSPDatums, recomputing
  the data if necessary at the requested scaling and length. If the
  subclass has no data, returns NULL. The data should neither be modified
  nor freed by the sender.
 @brief Returns a pointer to the receiver's <b>dataDSP</b> array,
  recomputing the data if necessary (as defined in the class
  description).

  The array is sized and scaled according to the
  arguments and the <b>length</b> and <b>scaling</b> instance
  variables are set to these values.  If the receiver can't fill the
  array, NULL is returned.  You should neither modify nor free the
  data returned by this method.
*/
- (DSPDatum *) dataDSPLength: (unsigned int) aLength scale: (double) aScaling;
 

/*!
  @param  aLength is an int.
  @param  aScaling is a double.
  @return Returns a double *. Returns the MKWaveTable as an array of doubles, recomputing
  the data if necessary at the requested scaling and length. If the
  subclass has no data, returns NULL. The data should neither be modified
  nor freed by the sender.
  @brief Returns a pointer to the receiver's <b>dataDouble</b> array,
  recomputing the data if necessary (as defined in the class
  description).

  The array is sized and scaled according to the
  arguments and the <b>length</b> and <b>scaling</b> instance
  variables are set to these values.  If the array cna't be filled,
  NULL is returned.  You should neither modify nor free the data
  returned by this method.
*/
- (double *) dataDoubleLength: (unsigned int) aLength scale: (double) aScaling;
 
 /* The following methods are minor variations of 
    dataDSPScaling:length: and are implemented in terms of it. 
    They use default or previously specified length, scaling or both.  */

/*!
  @return Returns a DSPDatum *.
  @brief Returns a pointer to the receiver's <b>dataDSP</b> array.

  
  Implemented as an invocation of <b>dataDSPLength:scale:</b>, with
  the <b>length</b> and <b>scaling</b> instance variables as
  arguments.
*/
- (DSPDatum *) dataDSP;

/*!
  @param  aLength is an int.
  @return Returns a DSPDatum *.
  @brief Returns a pointer to the receiver's <b>dataDSP</b> array.

  
  Implemented as an invocation of <b>dataDSPLength:scale:</b>, with
  <i>aLength</i> and the <b>scaling</b> instance variable as
  arguments.
*/
- (DSPDatum *) dataDSPLength:(int)aLength;

/*!
  @param  aScaling is a double.
  @return Returns a DSPDatum *.
  @brief Returns a pointer to the receiver's <b>dataDSP</b> array.

  
  Implemented as an invocation of <b>dataDSPLength:scale:</b>, with
  the <b>length</b> instance variable and <i>aScaling</i> as
  arguments.
*/
- (DSPDatum *) dataDSPScale:(double)aScaling;

 /* The following methods are minor variations of 
    dataDoubleScaling:length: and are implemented in terms of it. 
    They use default or previously specified length, scaling or both.  */

/*!
  @return Returns a double *.
  @brief Returns a pointer to the receiver's <b>dataDouble</b> array.

  
  Implemented as an invocation of <b>dataDoubleLength:scale:</b>, with
  the <b>length</b> and <b>scaling</b> instance variables as
  arguments.
*/
- (double *)   dataDouble;

/*!
  @param  aLength is an int.
  @return Returns a double *.
  @brief Returns a pointer to the receiver's <b>dataDouble</b> array.

  
  Implemented as an invocation of <b>dataDoubleLength:scale:</b>, with
  <i>aLength</i> and the <b>scaling</b> instance variable as
  arguments.
*/
- (double *)   dataDoubleLength:(int)aLength;

/*!
  @param  aScaling is a double.
  @return Returns a double *.
  @brief Returns a pointer to the receiver's <b>dataDouble</b> array.

  
  Implemented as an invocation of <b>dataDoubleLength:scale:</b>, with
  the <b>length</b> instance variable and <i>aScaling</i> as
  arguments.
*/
- (double *)   dataDoubleScale:(double)aScaling;


/*!
  @param  aLength is an int.
  @param  aScaling is a double.
  @return Returns an id.
  @brief Computes the receiver's data, sizing and scaling according to the
  arguments.

  This is a subclass responsibility method; a subclass can
  implement the method to fill the <b>dataDSP</b> array, the
  <b>dataDouble</b> array, or both.  If only one of the arrays is
  computed and filled, the other should be freed and its pointer set
  to NULL.  If the data can't be computed, both arrays should be freed
  and <b>nil</b> returned.  Otherwise, the receiver should be
  returned.
  
  Note that the <i>scaling</i> and <i>length</i> instance variables must be set by the subclass' <b>fillTableLength:scale:</b>method.
*/
- fillTableLength:(int)aLength scale:(double)aScaling ;
 /* This method is a subclass responsibility. It must do the following:

   This method computes the data. It allocates or reuses either (or 
   both) of the data arrays with the specified length and fills it with data, 
   appropriately scaled. 

   If only one of data arrays is computed, frees the other and sets
   its pointer to NULL. If data cannot be computed, 
   returns nil with both buffers freed and set to NULL. 

   Note that the scaling and length instance variables must be set by the 
   subclass' fillTableLength: method. 
 */

  /* 
     Archives itself by writing its name (using MKGetObjectName()), if any.
     All other data archiving is left to the subclass. 
     */
- (void)encodeWithCoder:(NSCoder *)aCoder;

  /* 
     Archives itself by reading its name, if any, and naming the
     object using MKGetObjectName(). 
     Note that -init is not sent to newly unarchived objects.
     */
- (id)initWithCoder:(NSCoder *)aDecoder;

@end



#endif
