/******************************************************************************
$Id$

LEGAL:
This framework and all source code supplied with it, except where specified,
are Copyright Stephen Brandon and the University of Glasgow, 1999. You are free
to use the source code for any purpose, including commercial applications, as
long as you reproduce this notice on all such software.

Software production is complex and we cannot warrant that the Software will be
error free.  Further, we will not be liable to you if the Software is not fit
for the purpose for which you acquired it, or of satisfactory quality.

WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL
WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES OF
QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD
PARTIES RIGHTS.

If a court finds that we are liable for death or personal injury caused by our
negligence our liability shall be unlimited.

WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS
OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR
POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE
NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED
DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND CONDITIONS
OF THIS AGREEMENT.

******************************************************************************/
#ifdef GNUSTEP
#include <objc/objc.h> /* for BOOL, YES, NO, TRUE, FALSE */
#include "sounderror.h"
#include <Foundation/NSByteOrder.h>
#include "SndFunctions.h"
#include "SndResample.h"
#include <string.h>      /* for memmove   */

#else

#import <Foundation/Foundation.h>

#ifdef WIN32
#import <wtypes.h>
#import <Winsock.h>
#import <malloc.h>
#import <stdio.h>
#else
#import <libc.h>
#endif

#ifndef USE_NEXTSTEP_SOUND_IO
#import "sounderror.h"
#endif

#endif /* GNUSTEP */

#import "SndFunctions.h"
#import "SndMuLaw.h"
#import "SndResample.h"
#import "SndAudioBuffer.h"

@implementation SndAudioBuffer(SampleConversion)

int SndConvertSound(const SndSoundStruct *fromSound,
		    SndSoundStruct **toSound,
                    BOOL allocate,
		    BOOL largeFilter,
		    BOOL interpFilter,
		    BOOL fast)
{
    NSLog(@"SndConvertSound no longer implemented. I suggest rewriting the calling code to use SndAudioBuffer or Snd class conversion methods. Conversion not performed!\n");
    return SND_ERR_NOT_SOUND;
}

//////////////////////////////////////////////
//
// Adjust the sample rate if necessary, reading from
// the fromSound and writing into the toSound. The
// resample code has been modified to work with SndSoundStructs
// for both in and out, and can read fragmented sounds directly.
//
//////////////////////////////////////////////
void SndChangeSampleRate(const SndSoundStruct *fromSound,
			 SndSoundStruct *toSound,
			 BOOL largeFilter,
			 BOOL interpolateFilter,
			 BOOL linearInterpolation,
			 void *inputPtr,
			 short *outPtr)
{
    int fromChannelCount = fromSound->channelCount;
    int toChannelCount = toSound->channelCount;
    int fromDataFormat = fromSound->dataFormat;
    int fromDataSize = fromSound->dataSize;
    int fromDataLocation = fromSound->dataLocation, toDataLocation = toSound->dataLocation;
    double fromSampleRate = fromSound->samplingRate;
    double toSampleRate = toSound->samplingRate;

    if (fromDataFormat == SND_FORMAT_INDIRECT) {  // TODO this can be removed with SndSoundStruct
        fromDataFormat = ((SndSoundStruct *)(*((SndSoundStruct **) fromDataLocation)))->dataFormat;
        fromDataSize = SndSampleCount(fromSound) * fromChannelCount * SndSampleWidth(fromDataFormat);
    }

    if (fromSampleRate != toSampleRate) {
	double stretchFactor = toSampleRate / fromSampleRate;
	int inSampleCount = SndBytesToSamples(fromDataSize, fromChannelCount, fromDataFormat);
	int outSampleCount = stretchFactor * inSampleCount + 1;

	/* interpolateFilter: YES = interpolate within filter.
	 * linearInterp: YES = fast mode.
	 * largeFilter: YES = use large filter.
	 * filterFile: NULL = use internal filter.
	 */
	char *filterFile = NULL;
	int outCountReal = resample(stretchFactor, outPtr, inSampleCount, outSampleCount, MIN(fromChannelCount, toChannelCount),
				interpolateFilter, linearInterpolation, largeFilter, filterFile, fromSound, 0, inputPtr);

	// NSLog(@"Completed resample stretching by %lf. inSampleCount = %d outSampleCount = %d outCountReal = %d\n", stretchFactor, inSampleCount, outSampleCount, outCountReal);
	toSound->dataFormat = SND_FORMAT_LINEAR_16; /* this is the output format */
	toSound->channelCount = MIN(fromChannelCount, toChannelCount); /* channel count is reduced if nec */
	toSound->dataSize = outCountReal * toSound->channelCount * SndSampleWidth(SND_FORMAT_LINEAR_16);
    }
    else {
	/* here I just copy the sound data into outSound. It will have its channels expanded
	* after this...
	*/
        if (fromDataFormat != SND_FORMAT_INDIRECT)
            memmove((char *)toSound, (char *)fromSound, fromSound->dataSize + fromDataLocation);
        else {
            int count = 0, i=0;
            SndSoundStruct *theStruct;
            char *startLocation = (char *)toSound + toDataLocation;
            SndSoundStruct **ssList = (SndSoundStruct **)fromDataLocation;
            while ((theStruct = ssList[i++]) != NULL) {
                memmove(startLocation + count,
                        (char *)theStruct + theStruct->dataLocation,
                        theStruct->dataSize);
                count += theStruct->dataSize;
            }
        }
    }
}

// dataFormat is the same going in and going out.
// This is capable of in place conversion if inPtr and outPtr are the same.
// TODO This is a good candidate for Altivec optimisation
void SndChannelDecrease(void *inPtr, void *outPtr, int numberOfSampleFrames, int oldNumChannels, int newNumChannels, int dataFormat)
{
    int chansToSum = oldNumChannels / newNumChannels;
    int passes = newNumChannels; /* convenience name */
    int m, n;
    unsigned int frame;
    unsigned int baseIndex;
    long int sum     = 0;
    float sumFloat   = 0;
    double sumDouble = 0;

    for (frame = 0; frame < numberOfSampleFrames; frame++) {
        for (m = 0; m < passes; m++) { /* m and n take us through 1 channel independent sample */
            baseIndex = frame * oldNumChannels + m * newNumChannels;
            /* fairly inefficient.*/
            for (n = 0; n < chansToSum; n++) {
                switch(dataFormat) {
		    case SND_FORMAT_LINEAR_8: /* endian ok */
			sum += ((signed char *) inPtr)[baseIndex + n];
			break;
		    case SND_FORMAT_MULAW_8: /* endian ok */
			sum += SndMuLawToLinear(((unsigned char *) inPtr)[baseIndex + n]);
			break;
		    case SND_FORMAT_LINEAR_16:
			sum += ((SND_HWORD *) inPtr)[baseIndex + n];
			break;
		    case SND_FORMAT_LINEAR_24:
			// TODO Not endian ok, the shift down currently assumes big endian!
			sum += *((long int *)((signed char *) inPtr + (baseIndex + n) * 3)) >> 8;
			break;
		    case SND_FORMAT_LINEAR_32:
			sumDouble += (long int)(((signed long int *) inPtr)[baseIndex + n]);
			break;
		    case SND_FORMAT_FLOAT:
			sumFloat += (float)(((float *) inPtr)[baseIndex + n]);
			break;
		    case SND_FORMAT_DOUBLE:
			sumDouble += (double)(((double *) inPtr)[baseIndex + n]);
			break;
		    default:
			NSLog(@"SndChannelDecrease: can\'t decrease channels of format %d samples\n", dataFormat);
                }
            } /* summing several channels into 1 channel */
	    
            switch(dataFormat) {
		case SND_FORMAT_FLOAT:
		    ((float *) outPtr)[frame * newNumChannels + m] = (float)(sumFloat / chansToSum);
		    sumFloat = 0;
		    break;
		case SND_FORMAT_DOUBLE:
		    ((double *) outPtr)[frame * newNumChannels + m] = (double)(sumDouble / chansToSum);
		    sumDouble = 0;
		    break;
		case SND_FORMAT_LINEAR_16:
		    ((signed short *) outPtr)[frame * newNumChannels + m] = (signed short)(sum / chansToSum);
		    sum = 0;
		    break;
		case SND_FORMAT_LINEAR_8:
		    ((signed char *) outPtr)[frame * newNumChannels + m] = (signed char)(sum / chansToSum);
		    sum = 0;
		    break;
		case SND_FORMAT_MULAW_8:
		    ((unsigned char *) outPtr)[frame * newNumChannels + m] = (unsigned char)SndLinearToMuLaw((short)(sum / chansToSum));
		    sum = 0;
		    break;
		case SND_FORMAT_LINEAR_32:
		    ((signed long int *) outPtr)[frame * newNumChannels + m] = (signed long int)(sumDouble / chansToSum);
		    sumDouble = 0;
		default:
		    NSLog(@"SndChannelDecrease: can\'t decrease channels of format %d samples\n", dataFormat);
            }
        } /* passes through channel independent sample */
    }
}

// endian-agnostic, as all formats are cast to memory pointers and duplicated as memory regions.
// dataFormat is the same going in and going out.
// This is capable of in place conversion if inPtr and outPtr are the same.
void SndChannelIncrease(void *inPtr, void *outPtr, int numberOfSampleFrames, int oldNumChannels, int newNumChannels, int dataFormat)
{
    int oldChanIndex, newChanIndex;
    int frame;
    int newChansPerOld = newNumChannels / oldNumChannels; /* multiply factor - number of new channels per original one */
    int sampleWidth = SndSampleWidth(dataFormat);

    for (frame = numberOfSampleFrames - 1; frame >= 0; frame--) { /* main slog backwards through the sound */
	for (oldChanIndex = oldNumChannels - 1; oldChanIndex >= 0; oldChanIndex--) { /* the origin channel */
	    unsigned baseIndex = frame * newNumChannels + oldChanIndex * newChansPerOld;
	    // copy the sampleWidth number of bytes into the new location, this avoid endian decisions.
	    char *samplePtr = (char *) inPtr + (frame * oldNumChannels + oldChanIndex) * sampleWidth;

	    /* the number of new channels to create */
	    for (newChanIndex = newChansPerOld - 1; newChanIndex >= 0; newChanIndex--) {
		memcpy((char *) outPtr + (baseIndex + newChanIndex) * sampleWidth, samplePtr, sampleWidth);
	    }
	}
    }
}

int SndChangeChannelCount(void *inPtr, void *outPtr, int numberOfSampleFrames, int oldNumChannels, int newNumChannels, int dataFormat)
{
    /* now check channel count -- if we need to increase the number of channels from 1 to
    * 2, or 4, we have hopefully got enough data malloced in *toSound to duplicate pairs
    * of samples.
    * Endian-wise, I simply avoid floats and doubles, re-casting as longs and long longs
    * which should side step the issue nicely.
    */
    if ((newNumChannels > oldNumChannels) && (newNumChannels % oldNumChannels == 0))
	SndChannelIncrease(inPtr, outPtr, numberOfSampleFrames, oldNumChannels, newNumChannels, dataFormat);
    else if ((oldNumChannels > newNumChannels) && (oldNumChannels % newNumChannels == 0))
	/* channel reduction will have already been done by resample routine if the sampling rate was changed */
	SndChannelDecrease(inPtr, outPtr, numberOfSampleFrames, oldNumChannels, newNumChannels, dataFormat);
    else {
	NSLog(@"Can't convert from %d to %d channels (output must be %s of input)\n", oldNumChannels, newNumChannels,
	    newNumChannels > oldNumChannels ? "multiple" : "divisor");
	return SND_ERR_UNKNOWN;
    }
    return SND_ERR_NONE;
}

//////////////////////////////////////////////////////////////
//
// SndChangeSampleType does an in-place conversion of a buffer
// of audio from any type (eg ulaw, short, int, float, double
// etc) to any other. The buffer must have enough allocated
// memory for the new sound if it the new format requires more
// memory than the old one.
// If the new format is bigger, it expands from the last sample
// to the first - if the new one is smaller, then the other way
// around.
// TODO this is probably a good candidate for Altivec optimisation.
//////////////////////////////////////////////////////////////

int SndChangeSampleType(void *fromPtr, void *toPtr, int fromDataFormat, int toDataFormat, unsigned int sampleCount)
{
    int i;
    static double ONE_OVER_TWO_THIRTYONE   = 1.0/2147483647.0f; /* 1/((2 ^ 31) - 1) */
    static double ONE_OVER_TWO_TWENTYTHREE = 1.0/8388607.0f;    /* 1/((2 ^ 23) - 1) */
    static double ONE_OVER_TWO_FIFTEEN     = 1.0/32767.0f;      /* 1/((2 ^ 15) - 1) */
    static double ONE_OVER_TWO_SEVEN       = 1.0/127.0f;        /* 1/((2 ^  7) - 1) */

#define LOOP_BACKWARD_THRU_SOUND for (i = sampleCount - 1; i >= 0; i--)
#define LOOP_FORWARD_THRU_SOUND for (i = 0; i < sampleCount; i++)
    
    if (toDataFormat > fromDataFormat) {
	/* toDataFormat takes up more space than fromDataFormat, or is at least higher quality */

	switch(fromDataFormat) {
	case SND_FORMAT_MULAW_8:
	    switch(toDataFormat) {
	    case SND_FORMAT_LINEAR_8:
		LOOP_BACKWARD_THRU_SOUND {
		    ((signed char *)toPtr)[i] = (signed char)
		    ((short)SndMuLawToLinear(((unsigned char *)fromPtr)[i]) >> 8);
		}
		break;
	    case SND_FORMAT_LINEAR_16:
		LOOP_BACKWARD_THRU_SOUND {
		    ((signed short *)toPtr)[i] = (signed short)
		    SndMuLawToLinear(((unsigned char *)fromPtr)[i]);
		}
		break;
	    case SND_FORMAT_LINEAR_32:
		LOOP_BACKWARD_THRU_SOUND {
		    ((signed int *)toPtr)[i] = (signed int)
		    SndMuLawToLinear(((unsigned char *)fromPtr)[i]) << 16;
		}
		break;
	    case SND_FORMAT_FLOAT:
		LOOP_BACKWARD_THRU_SOUND {
		    ((float *)toPtr)[i] = (float)SndMuLawToLinear(((unsigned char *)fromPtr)[i]) * ONE_OVER_TWO_FIFTEEN;
		}
		break;
	    case SND_FORMAT_DOUBLE:
		LOOP_BACKWARD_THRU_SOUND {
		    ((double *)toPtr)[i] = (double)SndMuLawToLinear(((unsigned char *)fromPtr)[i]) * ONE_OVER_TWO_FIFTEEN;
		}
		break;
	    }
	    break;
	    
	case SND_FORMAT_LINEAR_8:
	    switch(toDataFormat) {
	    case SND_FORMAT_LINEAR_16:
		LOOP_BACKWARD_THRU_SOUND {
		    ((signed short *) toPtr)[i] = ((char*) fromPtr)[i] << 8;
		}
		break;
	    case SND_FORMAT_LINEAR_32:
		LOOP_BACKWARD_THRU_SOUND {
		    ((signed int *) toPtr)[i] = (signed int)((signed char*) fromPtr)[i] << 24;
		}
		break;
	    case SND_FORMAT_FLOAT:
		LOOP_BACKWARD_THRU_SOUND {
		    ((float *) toPtr)[i] = (float)(((char *) fromPtr)[i]) * ONE_OVER_TWO_SEVEN;
		}
		break;
	    case SND_FORMAT_DOUBLE:
		LOOP_BACKWARD_THRU_SOUND {
		    ((double *) toPtr)[i] = (double)(((char *) fromPtr)[i]) * ONE_OVER_TWO_SEVEN;
		}
		break;
	    }
	    break;

	case SND_FORMAT_LINEAR_16:
	    switch(toDataFormat) {
	    case SND_FORMAT_LINEAR_32:
		LOOP_BACKWARD_THRU_SOUND {
		    ((signed int *)toPtr)[i] = (signed int)((signed short *) fromPtr)[i] << 16;
		}
		break;
	    case SND_FORMAT_FLOAT:
		LOOP_BACKWARD_THRU_SOUND {
		    ((float *)toPtr)[i] = (float)(((signed short *) fromPtr)[i]) * ONE_OVER_TWO_FIFTEEN;
		}
		break;
	    case SND_FORMAT_DOUBLE:
		LOOP_BACKWARD_THRU_SOUND {
		    ((double *)toPtr)[i] = (double)((signed short *) fromPtr)[i] * ONE_OVER_TWO_FIFTEEN;
		}
		break;
	    }
	    break;

	// TODO Since 24 bit is an evil odd byte count format, these conversions are currently big endian only.
	case SND_FORMAT_LINEAR_24:
	    switch(toDataFormat) {
	    case SND_FORMAT_LINEAR_32:
		LOOP_BACKWARD_THRU_SOUND {
		    ((signed int *)toPtr)[i] = (signed int)(*((signed short *) ((char *) fromPtr + i * 3)) << 8);
		}
		break;		    
	    case SND_FORMAT_FLOAT:
		LOOP_BACKWARD_THRU_SOUND {
		    ((float *)toPtr)[i] = (float) ((*((signed int *)((char *) fromPtr + i * 3)) >> 8) * ONE_OVER_TWO_TWENTYTHREE);
		}
		break;
	    case SND_FORMAT_DOUBLE:
		LOOP_BACKWARD_THRU_SOUND {
		    ((double *)toPtr)[i] = (double)((*((signed int *)((char *) fromPtr + i * 3)) >> 8) * ONE_OVER_TWO_TWENTYTHREE);
		}
		break;
	    }
	    break;
	    
	case SND_FORMAT_LINEAR_32:
	    switch(toDataFormat) {
	    case SND_FORMAT_FLOAT:
		LOOP_BACKWARD_THRU_SOUND {
		    ((float *)toPtr)[i] = (float)(((signed int *) fromPtr)[i] * ONE_OVER_TWO_THIRTYONE);
		}
		break;
	    case SND_FORMAT_DOUBLE:
		LOOP_BACKWARD_THRU_SOUND {
		    ((double *)toPtr)[i] = (double)(((signed int *) fromPtr)[i] * ONE_OVER_TWO_THIRTYONE);
		}
		break;
	    }
	    break;

	case SND_FORMAT_FLOAT:
	    switch(toDataFormat) {
	    case SND_FORMAT_DOUBLE:
		LOOP_BACKWARD_THRU_SOUND {
		    ((double *)toPtr)[i] = (double)(((float *) fromPtr)[i]);
		}
		break;
	    }
	    break;
	    
	default:
	    /* that should be all the common ones. Maybe aLaw too? */
            NSLog(@"Sorry, conversion from format %d unsupported, in attempting to convert to %d format.\n", fromDataFormat, toDataFormat);
            return SND_ERR_BAD_FORMAT;
        }
    }

    ////////////////////////////////
    //
    // toDataFormat takes up less space than fromDataFormat, or is lower quality,
    // so we loop forward thru sound, reducing space as we do so
    //
    ////////////////////////////////

    if (toDataFormat < fromDataFormat) {
	/* toDataFormat takes up less space than fromDataFormat, or is lower quality */

	switch(toDataFormat) {
	case SND_FORMAT_MULAW_8:
	    switch(fromDataFormat) {
	    case SND_FORMAT_LINEAR_8:
		LOOP_FORWARD_THRU_SOUND {
		    ((unsigned char *)toPtr)[i] = (unsigned char) SndLinearToMuLaw((int)(((signed char *) fromPtr)[i]) << 8);
		}
		break;
	    case SND_FORMAT_LINEAR_16:
		LOOP_FORWARD_THRU_SOUND {
		    ((unsigned char *)toPtr)[i] = (unsigned char) SndLinearToMuLaw(((signed short *) fromPtr)[i]);
		}
		break;
	    case SND_FORMAT_LINEAR_32:
		LOOP_FORWARD_THRU_SOUND {
		    ((unsigned char *)toPtr)[i] = (unsigned char) SndLinearToMuLaw(((signed int *) fromPtr)[i] >> 16);
		}
		break;
	    case SND_FORMAT_FLOAT:
		LOOP_FORWARD_THRU_SOUND {
		    ((unsigned char *)toPtr)[i] = (unsigned char) SndMuLawToLinear(((float *) fromPtr)[i] * 32767.0f);
		}
		break;
	    case SND_FORMAT_DOUBLE:
		LOOP_FORWARD_THRU_SOUND {
		    ((unsigned char *)toPtr)[i] = (unsigned char) SndMuLawToLinear(((double *) fromPtr)[i] * 32767.0f);
		}
		break;
	    }
	    break;

	case SND_FORMAT_LINEAR_8:
	    switch(fromDataFormat) {
	    case SND_FORMAT_LINEAR_16:
		LOOP_FORWARD_THRU_SOUND {
		    ((signed char*) toPtr)[i] = (((signed short *) fromPtr)[i]) >> 8;
		}
		break;
	    case SND_FORMAT_LINEAR_32:
		LOOP_FORWARD_THRU_SOUND {
		    ((signed char *) toPtr)[i] = (int)(((signed int *) fromPtr)[i]) >> 24;
		}
		break;
	    case SND_FORMAT_FLOAT:
		LOOP_FORWARD_THRU_SOUND {
		    ((unsigned char *) toPtr)[i] = (unsigned char)((((float *) fromPtr)[i] * 127.0f));
		}
		break;
	    case SND_FORMAT_DOUBLE:
		LOOP_FORWARD_THRU_SOUND {
		    ((unsigned char *) toPtr)[i] = (unsigned char)((((double *) fromPtr)[i]) * 127.0f);
		}
		break;
	    }
	    break;

	case SND_FORMAT_LINEAR_16:
	    switch(fromDataFormat) {
	    case SND_FORMAT_LINEAR_32:
		LOOP_FORWARD_THRU_SOUND {
		    ((signed short *)toPtr)[i] = ((signed int *) fromPtr)[i] >> 16;
		}
		break;
	    case SND_FORMAT_FLOAT:
		LOOP_FORWARD_THRU_SOUND {
		    ((signed short *) toPtr)[i] = ((float *) fromPtr)[i] * 32767;
		}
		break;
	    case SND_FORMAT_DOUBLE:
		LOOP_FORWARD_THRU_SOUND {
		    ((signed short *) toPtr)[i] = ((double *) fromPtr)[i] * 32767;
		}
		break;
	    }
	    break;

	case SND_FORMAT_LINEAR_32:
	    switch(fromDataFormat) {
	    case SND_FORMAT_FLOAT:
		LOOP_FORWARD_THRU_SOUND {
		    ((signed int *) toPtr)[i] = ((float *) fromPtr)[i] * 2147483647; /* (2 ^ 31 - 1) */
		}
		break;
	    case SND_FORMAT_DOUBLE:
		LOOP_FORWARD_THRU_SOUND {
		    ((signed int *) toPtr)[i] = ((double *) fromPtr)[i] * 2147483647; /* (2 ^ 31 - 1) */
		}
		break;
	    }
	    break;

	case SND_FORMAT_FLOAT:
	    switch(fromDataFormat) {
	    case SND_FORMAT_DOUBLE:
		LOOP_FORWARD_THRU_SOUND {
		    ((float *) toPtr)[i] = ((double *) fromPtr)[i];
		}
		break;
	    }
	    break;

	default:
	    NSLog(@"Sorry, conversion to format %d unsupported, in attempting to convert from %d format.\n", toDataFormat, fromDataFormat);
	    return SND_ERR_BAD_FORMAT;
	}
    }
    return SND_ERR_NONE;
}

- convertToFormat: (int) toDataFormat
{
    if (dataFormat != toDataFormat) {
	long dataItems = [self lengthInSampleFrames] * [self channelCount];
	NSMutableData *toData = [NSMutableData dataWithLength: dataItems * SndSampleWidth(toDataFormat)];
	void *fromDataPtr = [data mutableBytes];
	void *toDataPtr = [toData mutableBytes];
	int error = SndChangeSampleType(fromDataPtr, toDataPtr, dataFormat, toDataFormat, dataItems);

	if (error == SND_ERR_BAD_FORMAT)
	    return nil;
	
	[data release];
	data = [toData retain];
	byteCount = maxByteCount = [toData length];
	dataFormat = toDataFormat;
	// NSLog(@"convert: %@", self);
    }
    return self;
}

- convertToFormat: (int) toDataFormat
     channelCount: (int) toChannelCount
{
    if(channelCount != toChannelCount) {
	int sampleFrames = [self lengthInSampleFrames];
	long dataItems = sampleFrames * toChannelCount;
	NSMutableData *toData = [NSMutableData dataWithLength: dataItems * SndSampleWidth(dataFormat)];
	void *fromDataPtr = [data mutableBytes];
	void *toDataPtr = [toData mutableBytes];
	int error = SndChangeChannelCount(fromDataPtr, toDataPtr, sampleFrames, channelCount, toChannelCount, dataFormat);

	if(error != SND_ERR_NONE)
	    return nil;
	
	[data release];
	data = [toData retain];
	byteCount = maxByteCount = [toData length];
	channelCount = toChannelCount;
    }    
    return [self convertToFormat: toDataFormat];
}

- convertToFormat: (int) toDataFormat
     channelCount: (int) toChannelCount
     samplingRate: (double) toSampleRate
   useLargeFilter: (BOOL) largeFilter
interpolateFilter: (BOOL) interpFilter
useLinearInterpolation: (BOOL) fastInterpolation
{
    if (samplingRate != toSampleRate) {
	double stretchFactor = toSampleRate / samplingRate;
	long sampleFrames = [self lengthInSampleFrames];
	long dataItems = sampleFrames * channelCount;
	NSMutableData *toData = [NSMutableData dataWithLength: dataItems * stretchFactor * SndSampleWidth(SND_FORMAT_LINEAR_16)];
	void *fromDataPtr = [data mutableBytes];
	void *toDataPtr = [toData mutableBytes];
	SndSoundStruct *toSoundStruct;
	SndSoundStruct *fromSoundStruct; 

	// This is just used for now until we replace SndSoundStructs with direct parameter passing to SndChangeSampleRate().
	SndAlloc(&fromSoundStruct, 0, dataFormat, samplingRate, channelCount, 4);
	SndAlloc(&toSoundStruct, 0, SND_FORMAT_LINEAR_16, toSampleRate, channelCount, 4);

	// We only use the fromSound, toSound parameters to transport the data formats, channel counts and sampling rates.
	// The memory pointers are passed in the last two parameters.
	SndChangeSampleRate(fromSoundStruct, toSoundStruct, largeFilter, interpFilter, fastInterpolation, fromDataPtr, (short *) toDataPtr);

	// if we have changed rate, output format is always linear 16, otherwise we use the originally specified output format.
	dataFormat = SND_FORMAT_LINEAR_16;

	// replace the old data with the new sample rate converted data.
	[data release];
	data = [toData retain];
	samplingRate = toSampleRate;
	byteCount = maxByteCount = [toData length];  // assign this here in case we don't do any conversion in convertToFormat:channelCount:
    }
    
    // The sample rate converted sample data is now ready for channel/format conversion
    return [self convertToFormat: toDataFormat channelCount: toChannelCount];
}

- convertBytes: (void *) fromDataPtr
     intoRange: (NSRange) bufferByteRange
    fromFormat: (int) fromDataFormat
      channels: (int) fromChannelCount
  samplingRate: (double) fromSampleRate
{
    int toChannelCount = [self channelCount];
    int toDataFormat = [self dataFormat];
    double toSampleRate = [self samplingRate];
    void *toDataPtr = [self bytes] + bufferByteRange.location;
    long sampleFrames = bufferByteRange.length / [self frameSizeInBytes];
    int error;

    if(fromSampleRate != toSampleRate) {
	// do sampling rate conversion
	BOOL largeFilter = NO, interpFilter = YES, linearInterpolation = NO;
	double stretchFactor = toSampleRate / fromSampleRate;
	long dataItems = (sampleFrames / stretchFactor) * channelCount;
	SndSoundStruct *toSoundStruct;
	SndSoundStruct *fromSoundStruct;

	// NSLog(@"convertBytes: from format %d channels %d sample rate %lf, to %@\n", fromDataFormat, fromChannelCount, fromSampleRate, self);

	// This is just used for now until we replace SndSoundStructs with direct parameter passing to SndChangeSampleRate().
	SndAlloc(&fromSoundStruct, 0, fromDataFormat, fromSampleRate, fromChannelCount, 4);
	fromSoundStruct->dataSize = dataItems * SndSampleWidth(fromDataFormat);
	SndAlloc(&toSoundStruct, 0, SND_FORMAT_LINEAR_16, toSampleRate, toChannelCount, 4);
	
	// We only use the fromSound, toSound parameters to transport the data formats, channel counts and sampling rates.
	// The memory pointers are passed in the last two parameters.
	// SndChangeSampleRate(fromDataPtr, (short *) toDataPtr, numSampleFrames, fromDataFormat, fromChannelCount, fromSampleRate, toSampleRate, largeFilter, interpFilter, linearInterpolation);
	SndChangeSampleRate(fromSoundStruct, toSoundStruct, largeFilter, interpFilter, linearInterpolation, fromDataPtr, (short *) toDataPtr);
	
	// if we have changed rate, output format is always linear 16, otherwise we use the originally specified output format.
	dataFormat = toSoundStruct->dataFormat;
	
	// replace the old data with the new sample rate converted data.
	byteCount = toSoundStruct->dataSize;  // assign this here in case we don't do any conversion in convertToFormat:channelCount:
	fromDataPtr = toDataPtr; // This will then do the channel count conversion in place, which is ok by SndChangeChannelCount().
	// channelCount = toSoundStruct->channelCount;
	// NSLog(@"convertBytes: now %@\n", self);
	// channelCount = toChannelCount;
    }

    if(fromChannelCount != toChannelCount) {
	error = SndChangeChannelCount(fromDataPtr, toDataPtr, sampleFrames, fromChannelCount, toChannelCount, fromDataFormat);

	if(error != SND_ERR_NONE)
	    return nil;
	
	fromDataPtr = toDataPtr; // This will then do the sample type conversion in place, which is ok by SndChangeSampleType().
    }

    if(fromDataFormat != toDataFormat) {
	error = SndChangeSampleType(fromDataPtr, toDataPtr, fromDataFormat, toDataFormat, sampleFrames * toChannelCount);

	if(error != SND_ERR_NONE)
	    return nil;
    }
    if(bufferByteRange.location + bufferByteRange.length > byteCount)
	byteCount = bufferByteRange.location + bufferByteRange.length;
    
    return self;
}

// Create a new buffer of the same number of samples as the receiver
// converted to the new format, sampling rate and channel count.
// returns the new buffer instance.
- (SndAudioBuffer *) audioBufferConvertedToFormat: (int) toDataFormat
				     channelCount: (int) toChannelCount
				     samplingRate: (double) toSamplingRate
{
    SndAudioBuffer *newBuffer = [SndAudioBuffer audioBufferWithFormat: toDataFormat
							 channelCount: toChannelCount
							 samplingRate: toSamplingRate
							     duration: [self duration]];
    int sampleFrames = [self lengthInSampleFrames];
    long dataItems = sampleFrames * toChannelCount;
    void *fromDataPtr = [data mutableBytes];
    void *toDataPtr = [newBuffer bytes];
    int error;

    // TODO need to do sample conversion.
    if(samplingRate != toSamplingRate) {
	// TODO should do sampling rate conversion
	NSLog(@"Sampling rate conversion %lf to %lf not done! Needs implementation.\n", samplingRate, toSamplingRate);
    }
    
    // do conversion into the new data buffer.
    if(channelCount != toChannelCount) {
	error = SndChangeChannelCount(fromDataPtr, toDataPtr, sampleFrames, channelCount, toChannelCount, dataFormat);

	if(error != SND_ERR_NONE)
	    return nil;

	fromDataPtr = toDataPtr; // This will then do the sample type conversion in place, which is ok by SndChangeSampleType.
    }

    if(dataFormat != toDataFormat) {
	error = SndChangeSampleType(fromDataPtr, toDataPtr, dataFormat, toDataFormat, dataItems);

	if(error != SND_ERR_NONE)
	    return nil;
    }
    
    return newBuffer;
}

@end
