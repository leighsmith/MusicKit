/*
 $Id$
 Defined In: The MusicKit

 Description:
   MKPartials, a subclass of MKWaveTable, accepts a set of arrays containing
   the amplitude and frequency ratios and initial phases of a set of partials
   representing a waveform.  If one of the getData methods is called
   (inherited from the MKWaveTable object), a wavetable is additively
   synthesized and returned.

   By "frequency ratios", we mean that when this object is passed to a unit
   generator, the resulting component frequencies of the waveform will be
   these numbers times the unit generator's overall frequency value.
   Similarly, the resulting component amplitudes will be the "amplitude
   ratios" times the unit generator's overall amplitude term.

 Original Author: David Jaffe

 Copyright (c) 1988-1992, NeXT Computer, Inc.
 Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
 Portions Copyright (c) 1994 Stanford University
 Portions Copyright (c) 1999-2005, The MusicKit Project.
 */
/*
 Modification history prior to commit to CVS:

 09/15/89/daj - Changed to use new fastFft.
 10/02/89/daj - Fixed scaling bug (bug 3670)
 11/20/89/daj - Enabled new fastFft (it was off!).
 03/09/90/daj - Changed getPartial:... to return 2 if last point
 (was returning a bogus enum)
 03/13/90/daj - Moved private method to category
 03/19/90/daj - Added MKGet/SetPartialsClass()
 03/21/90/daj - Added archiving.
 04/21/90/daj - Small mods to get rid of -W compiler warnings.
 08/17/90/daj - Added private ability to make amps be floats and freqs be
 ints to support the timbre data base. Note that archiving,
 copying, interpolateBetween: and other such methods are not
 supported. The likelyhood of someone calling this methods
 on a data base MKWaveTable is very low.  On the off chance that
 someone does call them, I added code to convert the object to
 normal form. However, if someone has a subclass and tries to
 access the instance vars directly, he'll get garbage. The
 likelyhood of this is so low that I'm not worrying about it.
 Finally, note that you can't mix the float/int form with the
 double/double form.  Conclusion:
 The int/float form is just a hack now. It should be cleaned
 up and made public eventually, but we're past the API freeze
 for 2.0 now.
 08/27/90/daj - Changed to zone API.
 01/25/91/daj - Added setFromSamples:.
 03/06/91/daj - Changed to use myCos(), mySin()
 08/27/91/daj - Internationalized strings.
 11/17/92/daj - Fixed bug in NORMALFORM macro
 10/4/93/daj -  Added waveshaping table support.
 5/30/99/lms -  Removed reserved variable #defines, unfreezing the instance vars
 */

#import "_musickit.h"
#import "_scorefile.h"
#import "PartialsPrivate.h"
#import "_error.h"
#import "trigonometry.h"

@implementation  MKPartials

#define NORMALFORM(_self) if ((_self)->dbMode) normalform(_self)

static void freeArray(MKPartials *self,MKPar par)
{
  if (par == MK_freq) {
    if (self->freqRatios && self->_freqArrayFreeable)
      free(self->freqRatios);
    self->freqRatios = NULL;
  }
  else if (par == MK_amp) {
    if (self->ampRatios && self->_ampArrayFreeable)
      free(self->ampRatios);
    self->ampRatios = NULL;
  }
  else if (par == MK_phase) {
    if (self->phases && self->_phaseArrayFreeable)
      free(self->phases);
    self->phases = NULL;
  }
}

static void freeArrays(MKPartials *self)
{
  freeArray(self,MK_freq);
  freeArray(self,MK_amp);
  freeArray(self,MK_phase);

  self->_ampArrayFreeable   = NO; // SKoT 4.10.2000
  self->_freqArrayFreeable  = NO;
  self->_phaseArrayFreeable = NO;
  self->partialCount        = 0;
}

static void normalform(MKPartials *obj)
/* Assumes we've got an obj in dbMode */
{
  register int i;
  double *nFreqs,*nAmps;
  _MK_MALLOC(nFreqs,double,obj->partialCount);
  _MK_MALLOC(nAmps,double,obj->partialCount);
  for (i=0; i<obj->partialCount; i++) {
    nFreqs[i] = (double)(((short *)(obj->freqRatios))[i]);
    nAmps[i] = (double)(((float *)(obj->ampRatios))[i]);
  }
  obj->dbMode = NO;
  freeArray(obj,MK_amp);
  freeArray(obj,MK_freq);
  obj->ampRatios = nAmps;
  obj->freqRatios = nFreqs;
  obj->_freqArrayFreeable = obj->_ampArrayFreeable = YES;
}

static id theSubclass = nil;

BOOL MKSetPartialsClass(id aClass)
{
  if (!_MKInheritsFrom(aClass,[MKPartials class]))
    return NO;
  theSubclass = aClass;
  return YES;
}

id MKGetPartialsClass(void)
{
  if (!theSubclass)
    theSubclass = [MKPartials class];
  return theSubclass;
}

#define VERSION2 2

+ (void)initialize
{
  if (self != [MKPartials class])
    return;
  [MKPartials setVersion:VERSION2];//sb: suggested by Stone conversion guide (replaced self)
    return;
}

-  init
  /* Init frees the data arrays if they have been
  allocated, sets defaultPhase to 0, and calls [super init].
  This is invoked when a new object is created. */
{
  [super init];
  freeArrays(self);
  defaultPhase      = 0.0;
  dbMode            = NO;
  tableType         = MK_oscTable;

  return self;
}

// SKoT: Added 4 Oct 2000
- (NSString*) description
{
  NSString *s = [NSString localizedStringWithFormat: @"MKPartial with %i partials: [", partialCount];

  if (partialCount > 0) {
    // If all is well, output partial parameter triples...
    if (freqRatios != NULL && ampRatios != NULL) {
      int i;
      for (i = 0; i < partialCount; i++) {
        float ph = phases == NULL ? 0.0f : phases[i];
        s = [s stringByAppendingString:
          [NSString localizedStringWithFormat: @"{%.2f,%.2f,%.2f}",freqRatios[i], ampRatios[i], ph]];
      }
    }
    // ...otherwise engage in gratuitous debug assistance.
    else if (freqRatios == NULL && ampRatios == NULL)
      s = [s stringByAppendingString: @"ampRatios and freqRatios are NULL"];
    else if (freqRatios == NULL)
      s = [s stringByAppendingString: @"freqRatios is NULL"];
    else if (ampRatios == NULL)
      s = [s stringByAppendingString: @"ampRatios is NULL"];
  }
  s = [s stringByAppendingString: @"]"];
  return s;
}

static void putArray(int partialCount,NSCoder *aTypedStream,double *arr) /*sb: originally converted as NSArchiver, not NSCoder */
{
  BOOL aBool;
  if (arr) {
    aBool = YES;
    [aTypedStream encodeValueOfObjCType:"c" at:&aBool];
    [aTypedStream encodeArrayOfObjCType:"d" count:partialCount at:arr];
  } else {
    aBool = NO;
    [aTypedStream encodeValueOfObjCType:"c" at:&aBool];
  }
}

static void getArray(int partialCount,NSCoder *aTypedStream,BOOL *aBool, /*sb: originally converted as NSArchiver, not NSCoder */
double **arrPtr)
{
  [aTypedStream decodeValueOfObjCType:"c" at:aBool];
  if (*aBool) {
    double *arr; /* We do it like this because read: can be called
    multiple times. */
    _MK_MALLOC(arr,double,partialCount);
    [aTypedStream decodeArrayOfObjCType:"d" count:partialCount at:arr];
    if (!*arrPtr)
      *arrPtr = arr;
    else {
      free(arr);
      arr = NULL;
    }
  }
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  NORMALFORM(self);
  [aCoder encodeValuesOfObjCTypes: "iddd", &partialCount, &defaultPhase, &minFreq, &maxFreq];
  putArray(partialCount, aCoder, ampRatios);
  putArray(partialCount, aCoder, freqRatios);
  putArray(partialCount, aCoder, phases);
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if ([aDecoder versionForClassName: @"MKPartials"] == VERSION2) {
    [aDecoder decodeValuesOfObjCTypes: "iddd", &partialCount, &defaultPhase, &minFreq, &maxFreq];
    getArray(partialCount, aDecoder, &_ampArrayFreeable, &ampRatios);
    getArray(partialCount, aDecoder, &_freqArrayFreeable, &freqRatios);
    getArray(partialCount, aDecoder, &_phaseArrayFreeable, &phases);
  }
  return self;
}

- copyWithZone:(NSZone *)zone
  /* Returns a copy of the receiver with its own copy of arrays. */
{
  MKPartials *newObj = [super copyWithZone:zone];
  NORMALFORM(self);
  newObj->ampRatios = NULL;
  newObj->freqRatios = NULL;
  newObj->phases = NULL;
  [newObj setPartialCount:partialCount freqRatios:freqRatios
                ampRatios:ampRatios phases:phases orDefaultPhase:defaultPhase];
  return newObj;
}

- (void)dealloc
  /* Frees the instance object and all its arrays. */
{
  freeArrays(self);
  [super dealloc];
}

- (NSUInteger) hash
{
//trivial hash
  double p = 0;
  if (phases && partialCount) {
    p = phases[0];
  }
  return partialCount + 256.0f * defaultPhase +
    (partialCount ? 10000.0f * (ampRatios[0] + freqRatios[0] + p) : 0);
}

- (BOOL) isEqual: (MKPartials*)anObject
{
    double *otherAmpRatios,*otherFreqRatios,*otherPhases;
    if (!anObject)                           return NO;
    if (self == anObject)                    return YES;
    if ([self class] != [anObject class])    return NO;
    if ([self hash] != [anObject hash])      return NO;
    if (partialCount != [anObject partialCount])       return NO;
    if (defaultPhase != [anObject defaultPhase])       return NO;

    otherAmpRatios  = [anObject ampRatios];
    otherFreqRatios = [anObject freqRatios];
    otherPhases     = [anObject phases];
    
    if ((freqRatios == otherFreqRatios) && 
        (ampRatios == otherAmpRatios)   && 
	(phases == otherPhases))          {
      return YES;
    }
    // phases can be pointers, or null.
    if (((phases == NULL) && (otherPhases != NULL)) ||
       ((phases != NULL) && (otherPhases == NULL))) {
      return NO;
    }
    if (memcmp(freqRatios,otherFreqRatios,partialCount*sizeof(double))) {
      return NO;
    }
    if (memcmp(ampRatios,otherAmpRatios,partialCount*sizeof(double))) {
      return NO;
    }
    if (phases && otherPhases) {
      if (memcmp(phases,otherPhases,partialCount*sizeof(double))) {
        return NO;
      }
    }
    return YES;
}

- setPartialCount:	(int)howMany
       freqRatios: (double *)fRatios
        ampRatios: (double *)aRatios
           phases: (double *)phs
   orDefaultPhase:   (double)defPhase
  /* This method is used to specify the amplitude and frequency
  ratios and initial phases of a set of partials representing a
  waveform.  If one of the getData methods is called (inherited from
                                                      the Wave object), a wavetable is additively synthesized and returned.
  In this case, the frequency ratios must not have fractional parts.

  The initial phases are specified in degrees.
  If phs is NULL, the defPhase value is used for all harmonics.
  If aRatios or fRatios is NULL, the corresponding value is
  unchanged. The array arguments are copied. */
{
  if (fRatios) {
    freeArray(self,MK_freq);
    if (howMany) {
      _MK_MALLOC(freqRatios,double,howMany);
      memmove(freqRatios, fRatios, howMany * sizeof(double));
      _freqArrayFreeable = YES;
    } else _freqArrayFreeable = NO;
  }
  if (aRatios) {
    freeArray(self,MK_amp);
    if (howMany) {
      _MK_MALLOC(ampRatios,double,howMany);
      memmove(ampRatios, aRatios, howMany * sizeof(double));
      _ampArrayFreeable = YES;
    } else _ampArrayFreeable = NO;
  }
  if (phs == NULL)
    defaultPhase = defPhase;
  else {
    freeArray(self,MK_phase);
    if (howMany) {
      _MK_MALLOC(phases,double,howMany);
      memmove(phases, phs, howMany * sizeof(double));
      _phaseArrayFreeable = YES;
    } else _phaseArrayFreeable = NO;
  }
  partialCount = howMany;
  length = 0;   /* This ensures a recomputation of the tables. */
  dbMode = NO;
  return self;
}

#ifndef ABS
#define ABS(_x) ((_x >= 0) ? _x : - _x )
#endif

-interpolateBetween:partials1 :partials2 ratio:(double)value
  /* Assign frequencies and amplitudes to the receiver by interpolating
  between the values in partials1 and partials2. If value is 0,
  you get the values in partials1. If value is 1, you get the values
  in partials2. If either partials1 or partials2 has no amplitude array or
  no frequency array, the receiver is not affected and nil is returned.
  The phases of partials1 and partials2 are not used and the phases
  of the receiver, if any, are discarded. */
{
  double *freqs1 = [partials1 freqRatios];
  double *freqs2 = [partials2 freqRatios];
  double *amps1 = [partials1 ampRatios];
  double *amps2 = [partials2 ampRatios];
  int np1 = [partials1 partialCount];
  int np2 = [partials2 partialCount];
  double *end1 = freqs1 + np1;
  double *end2 = freqs2 + np2;
  double *freqs;
  double *amps;
  if (!(freqs1 && freqs2 && amps1 && amps2))
    return nil;
  freeArrays(self);
  _phaseArrayFreeable = NO;
  partialCount = np1 + np2; /* Worst case partial count. */
  _MK_MALLOC(freqRatios,double,partialCount);
  _MK_MALLOC(ampRatios,double,partialCount);
  _freqArrayFreeable = YES;
  _ampArrayFreeable = YES;
  freqs = freqRatios;
  amps = ampRatios;
  while ((freqs1 < end1) || (freqs2 < end2)) {
    if ((freqs1 < end1) && (freqs2 < end2) &&
        (ABS(*freqs1 - *freqs2) < .001)) { /* The same freq ratio? */
        *freqs++ = *freqs1++;
        freqs2++;
        *amps++ = *amps1 + (*amps2++ - *amps1) * value;
        amps1++;
    }
else if ((freqs1 < end1) &&
         ((freqs2 == end2) || (*freqs1 < *freqs2))) {
  *freqs++ = *freqs1++;
  *amps++ = *amps1++ * (1 - value);
}
else {
  *freqs++ = *freqs2++;
  *amps++ = *amps2++ * value;
}
  }
partialCount = freqs - freqRatios;
length = 0;   /* This ensures a recomputation of the tables. */
return self;
}

- (int)partialCount
  /* Returns the number of values in the harmonic data arrays. */
{
  return partialCount;
}

- (double)defaultPhase
  /* Returns phase constant. */
{
  return defaultPhase;
}

- (double *)freqRatios
  /* Returns the frequency ratios array directly, without copying it. */
{
  NORMALFORM(self);
  return freqRatios;
}

- (double *)ampRatios
  /* Returns the amplitude ratios array directly, without copying it nor
  scaling it. */
{
  NORMALFORM(self);
  return ampRatios;
}

- (double *)phases
  /* Returns the initial phases array directly, without copying it. */
{
  return phases;
}

- (int) getPartial: (int)n
         freqRatio: (double *)fRatio
          ampRatio: (double *)aRatio
             phase: (double *)phs
  /* Get Nth value.
  If the value is the last value, returns 2.
  If the value is out of bounds, returns -1. Otherwise returns 0.
  The value is scaled by the scale constant, if non-zero.
  */
{
  NORMALFORM(self);
  if ((n < 0 || n >= partialCount) || (!freqRatios) || (!ampRatios))
    return -1;
  *aRatio = ampRatios[n] * (scaling ? scaling : 1.0);
  *fRatio = freqRatios[n];
  if (phases == NULL)
    *phs = defaultPhase;
  else
    *phs = phases[n];
  return ((n == partialCount-1) ? 2 : 0);
}


-writeScorefileStream:(NSMutableData *)aStream
/* Writes on aStream the following:
{1.0, 0.3, 0.0}{2.0,.1,0.0}{3.0,.01,0.0}
  Returns nil if ampRatios or freqRatios is NULL, otherwise self. */
{
  int i;
  double *aRatios,*fRatios,*phs;

  NORMALFORM(self);
  if ((freqRatios == NULL) || (ampRatios == NULL)) {
    [aStream appendData:[@"{1.0,0,0}" dataUsingEncoding:NSNEXTSTEPStringEncoding]];
    return nil;
  }
  i = 0;
  fRatios = freqRatios;
  aRatios = ampRatios;
  phs = phases;
  while (i < partialCount) {
    if (phs == NULL)
      if (i == 0)
        [aStream appendData:[[NSString stringWithFormat:@"{%.5f,%.5f,%.5f}", *fRatios++,*aRatios++,
          defaultPhase] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
      else
        [aStream appendData:[[NSString stringWithFormat:@"{%.5f, %.5f}", *fRatios++,*aRatios++] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
    else [aStream appendData:[[NSString stringWithFormat:@"{%.5f, %.5f,%.5f}", *fRatios++,*aRatios++,
      *phs++] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
#       if _MK_LINEBREAKS
    if ((++i % 5 == 0) && i < partialCount)
      [aStream appendData:[@"\n\t" dataUsingEncoding:NSNEXTSTEPStringEncoding]];
#       else
    i++;
#       endif
  }
  return self;
}


-setFreqRangeLow:(double)freq1 high:(double)freq2
  /* Sets the frequency range associated with this timbre. */
{
  minFreq = freq1;
  maxFreq = freq2;
  return self;
}

-(double)maxFreq
  /* Returns the maximum fundamental frequency at which this timbre is
  ordinarily used. */
{
  return maxFreq;
}

-(double)minFreq
  /* Returns the minimum fundamental frequency at which this timbre is
  ordinarily used. */
{
  return minFreq;
}

-(BOOL)freqWithinRange:(double)freq
  /* Returns YES if freq is within the range of fundamental frequencies
  ordinarily associated with this timbre. */
{
  return ((minFreq <= freq) && (freq <= maxFreq));
}

-(double)highestFreqRatio
  /* Returns the highest (i.e., largest absolute value) freqRatio.
  Useful for optimizing lookup table sizes. */
{
  int i;
  double ratio, maxRatio = 0;
  for (i=0; i<partialCount; i++) {
    if (((ratio = ABS(freqRatios[i])) > maxRatio) && (ampRatios[i] != 0.0))
      maxRatio = ratio;
  }
  return maxRatio;
}

static BOOL isPowerOfTwo(int n)
/* Query whether n is a pure power of 2 */
{
    while (n > 1) {
	if (n % 2) break;
	n >>= 1;
    }
    return (n == 1);
}

#define POWERS_OF_2_ERROR \
NSLocalizedStringFromTableInBundle(@"MKPartials object currently supports table sizes of powers of 2 only.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs if an application asks for a MKWaveTable size tha is not a power of 2. This error is rarely if ever seen by the user.")


#define DEFAULT_OSC_TABLE_LENGTH 256
#define DEG_TO_RADIANS(_degrees) ((_degrees) * ((M_PI*2)/360.0))
#define RADIANS_TO_DEG(_radians) ((_radians) * (360.0/(M_PI*2)))

// #import "fastFFT.c"

/* Sets three arrays based on FFT of the supplied samples object. */
- setFromSamples: (MKSamples *) samplesObject
{
    double *arr;
    double real,imaginary;
    int i;
    double *theSamples = [samplesObject dataDouble];
    double oneOverN;
    int howMany = [samplesObject length]; /* Must be after dataDouble message */
    int halfHowMany = howMany / 2;

    if (!isPowerOfTwo(howMany)) {
	MKErrorCode(MK_musicKitErr, POWERS_OF_2_ERROR);
	/*** FIXME ***/
	return nil;
    }
    /* Now reset everything */
    freeArrays(self);
    _freqArrayFreeable = YES;
    _ampArrayFreeable = YES;
    _phaseArrayFreeable = YES;
    dbMode = NO;

    /* Now proceed with the FFT */
    _MK_MALLOC(arr, double, howMany);              /* For FFT */
    memmove(arr, theSamples, howMany * sizeof(double));
    fft_real_to_hermitian(arr, howMany);
    _MK_MALLOC(ampRatios, double, halfHowMany);
    _MK_MALLOC(phases, double, halfHowMany);
    oneOverN = 1.0 / halfHowMany;
    ampRatios[0] = arr[0] * oneOverN;
    phases[0] = 0;
    for (i = 1; i < halfHowMany; i++) {
	real = arr[i];
	imaginary = arr[howMany - i];
	ampRatios[i] = sqrt(real * real + imaginary * imaginary) * oneOverN;
	phases[i] = RADIANS_TO_DEG(atan2(imaginary, real)) + 90;
	/* MKPartials is a sum of sines, not cosines, so add 90 degrees. */
    }
    _MK_MALLOC(freqRatios, double, halfHowMany);
    for (arr = freqRatios, i = 0; i < halfHowMany; i++)
	*arr++ = i;
    partialCount = halfHowMany;
    length = 0;   /* This ensures a recomputation of the tables. */
    return self;
}

/* Change contents to remove any partials with amplitudes below
   specified threshold. */
- prunePartials: (double) amplitudeThreshold
{
    int i, j;
    double *freqRatiosNew, *ampRatiosNew, *phasesNew = NULL;

    if (!ampRatios || !freqRatios || (partialCount <= 0))
	return nil;
    _MK_MALLOC(freqRatiosNew, double, partialCount);
    _MK_MALLOC(ampRatiosNew, double, partialCount);
    if (phases)
	_MK_MALLOC(phasesNew, double, partialCount);
    for (i = 0, j = 0; i < partialCount; i++) {
	if (ampRatios[i] > amplitudeThreshold) {
	    ampRatiosNew[j] = ampRatios[i];
	    freqRatiosNew[j] = freqRatios[i];
	    if (phases)
		phasesNew[j] = phases[i];
	    j++;
	}
    }
    partialCount = j;
    if (partialCount) {
	_MK_REALLOC(freqRatiosNew, double, partialCount);
	_MK_REALLOC(ampRatiosNew, double, partialCount);
	if (phases)
	    _MK_REALLOC(phasesNew, double, partialCount);
	else 
	    phasesNew = NULL;
    }
    freeArrays(self);
    freqRatios = freqRatiosNew;
    ampRatios = ampRatiosNew;
    _freqArrayFreeable = _ampArrayFreeable = YES;
    if (phasesNew) {
	phases = phasesNew;
	_phaseArrayFreeable = YES;
    }
    dbMode = NO;
    length = 0;   /* This ensures a recomputation of the tables. */
    return self;
}

- (int) tableType
{
    return tableType;
}

@end

@implementation MKPartials(OscTable)

- fillOscTableLength: (int) aLength scale: (double) aScaling
{
  return [self fillTableLength: aLength scale: aScaling];
}

/* Computes the wavetable from the data provided by the
   setN: method.  Returns self, or nil if an error is found. If
   scaling is 0.0, the waveform is normalized. This method is sent
  automatically if necessary by the various getData: methods
  (inherited from the Wave class) used to access the resulting
  wavetable. 
*/
- fillTableLength: (unsigned int) aLength scale: (double) aScaling
{
    int i;
    double cosPhase = 0; /* Initialize to shut up compiler warnings */
    double sinPhase = 0;
    double tmp;
    int indexVal, halfLength;
    tableType = MK_oscTable;

    if (!ampRatios || !freqRatios || (partialCount <= 0))
	return nil;
    if (aLength == 0) {
	if (length == 0)
	    aLength = DEFAULT_OSC_TABLE_LENGTH;
	else
	    aLength = length;
    }
    if (!isPowerOfTwo(aLength)) {
	MKErrorCode(MK_musicKitErr, POWERS_OF_2_ERROR);
	/*** FIXME ***/
	return nil;
    }
    if (!dataDouble || (length != aLength)) {
	if (dataDouble) {
	    free(dataDouble);
	    dataDouble = NULL;
	}
	_MK_CALLOC(dataDouble, double, aLength);
    }
    length = aLength;
    if (dataDSP) {free(dataDSP); dataDSP = NULL;}
    halfLength = length / 2;
    memset(dataDouble, 0, length * sizeof(double));
    if (!phases) {
	cosPhase = MKCosine(DEG_TO_RADIANS(defaultPhase)-M_PI_2);
	sinPhase = MKSine(DEG_TO_RADIANS(defaultPhase)-M_PI_2);
	/* We subtract M_PI_2 so that a zero phase means sine and a PI/2
	   phase means cosine. */
    }
    if (dbMode) {
	for (i = 0; i < partialCount; i++) {
	    indexVal = ((short *)freqRatios)[i];
	    if (indexVal == 0) {
		/* Value at n=0 must be real */
		dataDouble[indexVal] = ((float *)ampRatios)[i] * halfLength;
		dataDouble[length - indexVal] = 0;
	    } 
	    else if (indexVal < halfLength) {
		if (phases) {
		    tmp = DEG_TO_RADIANS(phases[i]) - M_PI_2;
		    cosPhase = MKCosine(tmp);
		    sinPhase = MKSine(tmp);
		}
		tmp = ((float *)ampRatios)[i] * halfLength;
		dataDouble[indexVal] = tmp * cosPhase;
		dataDouble[length - indexVal] = tmp * sinPhase;
	    }
	}
    }
    else {
	for (i = 0; i < partialCount; i++) {
	    indexVal = freqRatios[i];
	    if (indexVal == 0) {
		/* Value at n=0 must be real */
		dataDouble[indexVal] = ampRatios[i] * halfLength;
		dataDouble[length - indexVal] = 0;
	    } 
	    else if (indexVal < halfLength) {
		if (phases) {
		    tmp = DEG_TO_RADIANS(phases[i])-M_PI_2;
		    cosPhase = MKCosine(tmp);
		    sinPhase = MKSine(tmp);
		}
		tmp = ampRatios[i] * halfLength;
		dataDouble[indexVal] = tmp * cosPhase;
		dataDouble[length - indexVal] = tmp *  sinPhase;
	    }
	}
    }
    fftinv_hermitian_to_real(dataDouble,length);
    scaling = aScaling;
    [self _normalize];

    return self;
}

- (DSPDatum *) dataDSPLength: (unsigned int) aLength scale: (double) aScaling
  /* Returns the MKWaveTable as an array of DSPDatums, recomputing
  the data if necessary at the requested scaling and length. If the
  subclass has no data, returns NULL. The data should neither be modified
  nor freed by the sender. */
{
    if ((tableType != MK_oscTable) ||
	(length != aLength) || (scaling != aScaling) || (length == 0))
	if (![self fillTableLength:aLength scale:aScaling])
	    return NULL;
    if (!dataDSP && dataDouble) {
	_MK_MALLOC(dataDSP, DSPDatum, length);
	if (!dataDSP) return NULL;
	_MKDoubleToFix24Array (dataDouble, dataDSP, length);
    }
    return dataDSP;
}

/* Returns the MKWaveTable as an array of doubles, recomputing
   the data if necessary at the requested scaling and length. If the
   subclass has no data, returns NULL. The data should neither be modified
   nor freed by the sender. 
 */
- (double *) dataDoubleLength: (unsigned int) aLength scale: (double) aScaling
{
    if ((tableType != MK_oscTable) ||
	(length != aLength) || (scaling != aScaling) || (length == 0))
	if (![self fillTableLength:aLength scale:aScaling])
	    return NULL;
    if (!dataDouble && dataDSP) {
	_MK_MALLOC (dataDouble, double, length);
	if (!dataDouble) return NULL;
	_MKFix24ToDoubleArray (dataDSP, dataDouble, length);
    }
    return dataDouble;
}

- (DSPDatum *) dataDSPAsOscTableLength: (int) aLength;
{
    return [self dataDSPLength: aLength];
}

- (double *) dataDoubleAsOscTableLength: (int) aLength;
{
    return [self dataDoubleLength: aLength];
}

- (DSPDatum *) dataDSPAsOscTableScale: (double) aScaling;
{
    return [self dataDSPScale: aScaling];
}

- (double *) dataDoubleAsOscTableScale: (double) aScaling;
{
    return [self dataDoubleScale: aScaling];
}

- (double *) dataDoubleAsOscTable
{
    return [self dataDouble];
}

- (DSPDatum *) dataDSPAsOscTable
{
    return [self dataDSP];
}

@end

@implementation MKPartials(Private)

/* Writes on aStream the following:
  {1.0, 0.3, 0.0}{2.0,.1,0.0}{3.0,.01,0.0}
  Returns nil if ampRatios or freqRatios is NULL, otherwise self. 
*/
- writeBinaryScorefileStream: (NSMutableData *) aStream
{
    int i;
    double *aRatios, *fRatios, *phs;
    
    _MKWriteChar(aStream, '\0'); /* Marks it as a partials rather than samples */
    if ((freqRatios == NULL) || (ampRatios == NULL)) {
	_MKWriteChar(aStream, '\2');
	_MKWriteDouble(aStream, 1.0);
	_MKWriteDouble(aStream, 1.0);
	return nil;
    }
    i = 0;
    fRatios = freqRatios;
    aRatios = ampRatios;
    phs = phases;
    while (i < partialCount) {
	if (phs == NULL) {
	    _MKWriteChar(aStream,(i == 0) ? '\3' : '\2');
	    _MKWriteDouble(aStream,*fRatios++);
	    _MKWriteDouble(aStream,*aRatios++);
	    if (i == 0)
		_MKWriteDouble(aStream,defaultPhase);
	}
	else {
	    _MKWriteChar(aStream,'\3');
	    _MKWriteDouble(aStream,*fRatios++);
	    _MKWriteDouble(aStream,*aRatios++);
	    _MKWriteDouble(aStream,*phs++);
	}
	i++;
    }
    _MKWriteChar(aStream,'\0');
    return self;
}

/* Same as setPartialCount:freqRatios:ampRatios:phases:orDefaultPhase
  except that the array arguments are not copied or freed. */
- _setPartialNoCopyCount: (int)howMany
              freqRatios: (short *)fRatios
               ampRatios: (float *)aRatios
                  phases: (double *)phs
          orDefaultPhase: (double)defPhase
{
    if (fRatios) {
	freeArray(self,MK_freq);
	freqRatios = (double *)fRatios;
	_freqArrayFreeable = NO;
    }
    if (aRatios) {
	freeArray(self,MK_amp);
	ampRatios = (double *)aRatios;
	_ampArrayFreeable = NO;
    }
    if (phs == NULL)
	defaultPhase = defPhase;
    else {
	freeArray(self,MK_phase);
	phases = phs;
	_phaseArrayFreeable = NO;
    }
    partialCount = howMany;
    length = 0;   /* This ensures a recomputation of the tables. */
    dbMode = YES;
    return self;
}

- _normalize
{
    register double *dataEnd,*dataPtr;
    double tmp;
    double aScaling = scaling;
    
    if (scaling == 0.0) { /* Figure out normalization */
	for (dataPtr = dataDouble, dataEnd = dataDouble + length; dataPtr < dataEnd; dataPtr++) {
	    if ((tmp = ABS(*dataPtr)) > aScaling)
		aScaling = tmp;
	}
	aScaling = 1.0/aScaling;
    }
    if (aScaling != 1.0) {
	for (dataPtr = dataDouble, dataEnd = dataDouble + length; dataPtr < dataEnd; dataPtr++)
	    *dataPtr = *dataPtr * aScaling;
    }
    return self;
}

@end
