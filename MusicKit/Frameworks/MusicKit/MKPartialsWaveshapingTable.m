/*
  $Id$
  Defined In: The MusicKit

  Description:
  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.4  2003/08/04 21:14:33  leighsmith
  Changed typing of several variables and parameters to avoid warnings of mixing comparisons between signed and unsigned values.

  Revision 1.3  2000/06/09 18:05:59  leigh
  Added braces to reduce finicky compiler warnings

  Revision 1.2  1999/07/29 01:16:40  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#import "_musickit.h"
#import "PartialsPrivate.h"

@implementation MKPartials(WaveshapingTable)

- (DSPDatum *)dataDSPAsWaveshapingTableLength:(unsigned int)aLength scale:(double)aScaling
{
   if ((tableType != MK_waveshapingTable) || 
       (length != aLength) || (scaling != aScaling) || (length == 0))
     if (![self fillWaveshapingTableLength:aLength scale:aScaling])
       return NULL;
   if (!dataDSP && dataDouble) {
       _MK_MALLOC(dataDSP, DSPDatum, length);
       if (!dataDSP) return NULL;
       _MKDoubleToFix24Array (dataDouble, dataDSP, length);
   } 
   return dataDSP;
}

- (double *)dataDoubleAsWaveshapingTableLength:(unsigned int)aLength scale:(double)aScaling
{  
   if ((tableType != MK_waveshapingTable) || 
       (length != aLength) || (scaling != aScaling) || (length == 0))
     if (![self fillWaveshapingTableLength:aLength scale:aScaling])
       return NULL;
   if (!dataDouble && dataDSP) {
       _MK_MALLOC (dataDouble, double, length);
       if (!dataDouble) return NULL;
       _MKFix24ToDoubleArray (dataDSP, dataDouble, length);
   } 
   return dataDouble;
}

- (DSPDatum *)dataDSPAsWaveshapingTable
{
    return [self dataDSPAsWaveshapingTableLength:length scale:scaling];
}

- (double *)dataDoubleAsWaveshapingTable
{
    return [self dataDoubleAsWaveshapingTableLength:length scale:scaling];
}

- (DSPDatum *)dataDSPAsWaveshapingTableLength:(int)aLength
{
    return [self dataDSPAsWaveshapingTableLength:aLength scale:scaling];
}

- (double *)dataDoubleAsWaveshapingTableLength:(int)aLength
{
    return [self dataDoubleAsWaveshapingTableLength:aLength scale:scaling];
}

- (DSPDatum *)dataDSPAsWaveshapingTableScale:(double)aScaling
{
    return [self dataDSPAsWaveshapingTableLength:length scale:aScaling];
}

- (double *)dataDoubleAsWaveshapingTableScale:(double)aScaling
{
    return [self dataDoubleAsWaveshapingTableLength:length scale:aScaling];
}

/* This is PROGRAM 3 from the LeBrun article -- DAJ */
static void makeshape(double *F, double *Hk, int Lf, int Lh)
    /* Fis the resulting shaping function.  Lf is its length.
       Hk is the list of harmonic numbers.   Lh is its length.
       */
{
    int I,K;
    double X,Tn,Tn1,Tn2;
    for (I=0; I<Lf; I++) {
	X = 2 * ((double)I/(double)(Lf-1))-1; /* Map to [-1:1] */
	F[I] = 0;
	Tn = 1;   /* Initialize inductive definition */
	Tn1 = X;
	for (K=0; K<=Lh; K++) {
	    F[I] += Hk[K] * Tn;
	    Tn2 = Tn1;
	    Tn1 = Tn;
	    Tn = 2 * X * Tn1 - Tn2;
	}
    }
}

#define DEFAULT_WAVESHAPING_TABLE_LENGTH 129

#define CHEBYCHEV_ERROR \
NSLocalizedStringFromTableInBundle(@"Waveshaping harmonics must be integers.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs if an application asks for an inharmonic waveshaping partial.")

- fillWaveshapingTableLength:(unsigned int)aLength scale:(double)aScaling 
{
    double diff;
    int j,k,i;
    unsigned highestFreqRatio;  
    double *Hk;
    BOOL isEven;

    if (!ampRatios || !freqRatios || (partialCount <= 0))
      return nil;
    if (aLength == 0) {
      if (length == 0)
	aLength = DEFAULT_WAVESHAPING_TABLE_LENGTH;
      else
        aLength = length;
    }
    isEven = (aLength % 2 == 0);
    tableType = MK_waveshapingTable;
    if (!dataDouble || (length != aLength)) {
    	if (dataDouble) {
	    free(dataDouble); 
	    dataDouble = NULL;
	}
	_MK_CALLOC(dataDouble, double, aLength);
    }
    length = aLength;
    if (dataDSP) {free(dataDSP); dataDSP = NULL;} 
    /* Leave it to access method to fill dataDSP. */

    /* First figure the highest frequency ratio */
    highestFreqRatio = [self highestFreqRatio];

    /* Now allocate an array from 0 to highestFreqRatio */
    Hk = (double *)alloca((highestFreqRatio+1)*sizeof(double));
    memset(Hk,0,(highestFreqRatio+1)*sizeof(double));
    /* Now fill it with amplitudes.  */
    for (i=0; i<partialCount; i++) {
	if (ampRatios[i] == 0.0) /* Necessary--see highestFreqRatio */
	  continue;
	j = (int)freqRatios[i];
	diff = freqRatios[i]-j;
	if (ABS(diff) > .0001) /* Floating point compare */ 
	  _MKErrorf(MK_musicKitErr,CHEBYCHEV_ERROR);
	k = j % 4;   /* Perform signification algorithm described in LeBrun 
		      * The idea is that you set Hk[2], [3], [6], [7], ... to
		      * negative amplitude as a way of making the index have
		      * a bit less effect on amplitude.  It's supposed to be
		      * ad hoc, but useful. (DAJ)
		      */
	if (k == 2 || k == 3)
	  Hk[j] = -ampRatios[i];
	else
	  Hk[j] = ampRatios[i];
    }
    /* Bill Schottsteadt's version of this instrument normalizes the spectrum
     * at this point.  I'm not sure that's necessary, so I don't do it. (DAJ) 
     */
    if (isEven) 
      aLength -= 1;
    makeshape(dataDouble, Hk,aLength, highestFreqRatio);
    if (isEven) /* Copy last point in this case */
      dataDouble[length-1] = dataDouble[aLength-1];
    scaling = aScaling;
    [self _normalize];
    return self;
}

@end
