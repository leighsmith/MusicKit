/*
 * FILE: resample.h
 *
 * The configuration constants below govern
 * the number of bits in the input sample and filter coefficients, the 
 * number of bits to the right of the binary-point for fixed-point math, etc.
 *
 */
#include "SndStdefs.h"
#include "SndFunctions.h"
#include "SndKitDefines.h"

/* Conversion constants */
#define Nhc       8
#define Na        7
#define Np       (Nhc+Na)
#define Npc      (1<<Nhc)
#define Amask    ((1<<Na)-1)
#define Pmask    ((1<<Np)-1)
#define Nh       16
#define Nb       16
#define Nhxn     14
#define Nhg      (Nh-Nhxn)
#define NLpScl   13

/*! @header <p>
Description of constants:
</p><p>
 <b>Npc</b> - is the number of look-up values available for the lowpass filter
    between the beginning of its impulse response and the "cutoff time"
    of the filter.  The cutoff time is defined as the reciprocal of the
    lowpass-filter cut off frequence in Hz.  For example, if the
    lowpass filter were a sinc function, Npc would be the index of the
    impulse-response lookup-table corresponding to the first zero-
    crossing of the sinc function.  (The inverse first zero-crossing
    time of a sinc function equals its nominal cutoff frequency in Hz.)
    Npc must be a power of 2 due to the details of the current
    implementation. The default value of 512 is sufficiently high that
    using linear interpolation to fill in between the table entries
    gives approximately 16-bit accuracy in filter coefficients.
</p><p>
 <b>Nhc</b> - is log base 2 of Npc.
</p><p>
 <b>Na</b> - is the number of bits devoted to linear interpolation of the
    filter coefficients.
</p><p>
 <b>Np</b> - is Na + Nhc, the number of bits to the right of the binary point
    in the integer "time" variable. To the left of the point, it indexes
    the input array (X), and to the right, it is interpreted as a number
    between 0 and 1 sample of the input X.  Np must be less than 16 in
    this implementation.
</p><p>
 <b>Nh</b> - is the number of bits in the filter coefficients. The sum of Nh and
    the number of bits in the input data (typically 16) cannot exceed 32.
    Thus Nh should be 16.  The largest filter coefficient should nearly
    fill 16 bits (32767).
</p><p>
 <b>Nb</b> - is the number of bits in the input data. The sum of Nb and Nh cannot
    exceed 32.
</p><p>
 <b>Nhxn</b> - is the number of bits to right shift after multiplying each input
    sample times a filter coefficient. It can be as great as Nh and as
    small as 0. Nhxn = Nh-2 gives 2 guard bits in the multiply-add
    accumulation.  If Nhxn=0, the accumulation will soon overflow 32 bits.
</p><p>
 <b>Nhg</b> - is the number of guard bits in mpy-add accumulation (equal to Nh-Nhxn)
</p><p>
 <b>NLpScl</b> - is the number of bits allocated to the unity-gain normalization
    factor.  The output of the lowpass filter is multiplied by LpScl and
    then right-shifted NLpScl bits. To avoid overflow, we must have 
    Nb+Nhg+NLpScl < 32.
</p>
*/

/*!
@function resample
 @abstract To come
 @discussion To come
 @param factor 		   factor = Sndout/Sndin 
 @param outPtr		   output data pointer 
 @param inCount		   number of input samples to convert 
 @param outCount		 number of output samples to compute
 @param nChans			 number of sound channels (1 or 2) 
 @param interpFilt	 TRUE means interpolate filter coeffs 
 @param fastMode		 0 = highest quality, slowest speed 
 @param largeFilter	 TRUE means use 65-tap FIR filter 
 @param filterFile	 NULL for internal filter, else filename 
 @param inSnd	       for data format etc 
 @param resampleFrom		 The sample number within the sound to begin the resampling from 
 @result The number of output samples returned
 */

SNDKIT_API int resample(	
    double factor,		
    SND_HWORD *outPtr,
    int  inCount,		
    int  outCount,		
    int  nChans,			
    BOOL interpFilt,
    int  fastMode,		
    BOOL largeFilter,
    char *filterFile,
    const SndSoundStruct *inSnd,
    int  resampleFrom		
);
