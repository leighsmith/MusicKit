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

//#import <objc/objc.h> /* for BOOL, YES, NO, TRUE, FALSE */

#ifndef USE_NEXTSTEP_SOUND_IO
#import "sounderror.h"
#endif

#endif /* GNUSTEP */

#import "SndFunctions.h"
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
			 BOOL interpFilter,
			 BOOL fastInterpolation,
			 void *alternativeInput,
			 short *outPtr)
{
    int inCount, outCount;
    int width;
    float factor;
    int cc1 = fromSound->channelCount;
    int cc2 = toSound->channelCount;
    int fromDataFormat = fromSound->dataFormat;
    int fromDataSize = fromSound->dataSize;
    int fromDataLocation = fromSound->dataLocation, dl2 = toSound->dataLocation;
    int fromSampleRate = fromSound->samplingRate;
    int toSampleRate = toSound->samplingRate;

    if (fromDataFormat == SND_FORMAT_INDIRECT) {
        fromDataFormat = ((SndSoundStruct *)(*((SndSoundStruct **) fromDataLocation)))->dataFormat;
        fromDataSize = SndSampleCount(fromSound) * cc1 * SndSampleWidth(fromDataFormat);
    }

    if (fromSampleRate != toSampleRate) {
	factor = toSampleRate / fromSampleRate;
	inCount = SndBytesToSamples(fromDataSize, cc1, fromDataFormat);
	width   = SndSampleWidth(fromDataFormat);

	outCount = factor * inCount + 1;

        {
            /* (BOOL)interpFilter = interpolate within filter
	    * (BOOL)linearInterp: 1 = fastmode
	    * (BOOL)largeFilter: 1 = use large filter
	    * char *filterFile: NULL = use internal
	    */
            char *filterFile = NULL;
            BOOL linearInterp = fastInterpolation;
            int outCountReal;
            outCountReal = resample(factor, outPtr, inCount, outCount, MIN(cc1,cc2),
                                    interpFilter, linearInterp, largeFilter, filterFile, fromSound, 0, alternativeInput);
            toSound->dataFormat = SND_FORMAT_LINEAR_16; /* this is the output format */
            toSound->channelCount = MIN(cc1,cc2); /* channel count is reduced if nec */
//			NSLog(@"Completed resample. OutCount = %d\n", outCountReal);
            toSound->dataSize = outCountReal * toSound->channelCount * 2; /* 2 is SND_FORMAT_LINEAR_16 */
//NO!            SndSwapHostToSound(outPtr, outPtr, outCountReal, toSound->channelCount, SND_FORMAT_LINEAR_16);
        }
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
            char *startLocation = (char *)toSound + dl2;
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
			sum += SndiMulaw(((unsigned char *) inPtr)[baseIndex + n]);
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
		    case SND_FORMAT_LINEAR_16:
			sum += ((SND_HWORD *) inPtr)[baseIndex + n];
			break;
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
		default:
		case SND_FORMAT_LINEAR_16:
		    ((signed short *) outPtr)[frame * newNumChannels + m] = (signed short)(sum / chansToSum);
		    sum = 0;
		    break;
		case SND_FORMAT_LINEAR_8:
		    ((signed char *) outPtr)[frame * newNumChannels + m] = (signed char)(sum / chansToSum);
		    sum = 0;
		    break;
		case SND_FORMAT_MULAW_8:
		    ((unsigned char *) outPtr)[frame * newNumChannels + m] = (unsigned char)SndMulaw((short)(sum / chansToSum));
		    sum = 0;
		    break;
		case SND_FORMAT_LINEAR_32:
		    ((signed long int *) outPtr)[frame * newNumChannels + m] = (signed long int)(sumDouble / chansToSum);
		    sumDouble = 0;
            }
        } /* passes through channel independent sample */
    }
}

// endian-agnostic, as floats and doubles are cast to long and longlong respectively.
// dataFormat is the same going in and going out.
// This is capable of in place conversion if inPtr and outPtr are the same.
void SndChannelIncrease(void *inPtr, void *outPtr, int numberOfSampleFrames, int oldNumChannels, int newNumChannels, int dataFormat)
{
    int oldChanIndex, newChanIndex;
    int frame;
    int newChansPerOld = newNumChannels / oldNumChannels; /* multiply factor - number of new channels per original one */

    switch (dataFormat) {
    case SND_FORMAT_MULAW_8:
    case SND_FORMAT_LINEAR_8:
	for (frame = numberOfSampleFrames - 1; frame >= 0; frame--) { /* main slog backwards through the sound */
	    for (oldChanIndex = oldNumChannels - 1; oldChanIndex >= 0; oldChanIndex--) { /* the origin channel */
		unsigned baseIndex = frame * newNumChannels + oldChanIndex * newChansPerOld;
		char sample = ((char *)inPtr)[frame * oldNumChannels + oldChanIndex];

		/* the number of new channels to create */
		for (newChanIndex = newChansPerOld - 1; newChanIndex >= 0; newChanIndex--) {
		    ((char *)outPtr)[baseIndex + newChanIndex] = sample;
		}
	    }
	}
	break;
    case SND_FORMAT_LINEAR_16:
    default:
	for (frame = numberOfSampleFrames - 1; frame >= 0; frame--) { /* main slog backwards through the sound */
	    for (oldChanIndex = oldNumChannels - 1; oldChanIndex >= 0; oldChanIndex--) { /* the origin channel */
		unsigned baseIndex = frame * newNumChannels + oldChanIndex * newChansPerOld;
		short sample = ((short *)inPtr)[frame * oldNumChannels + oldChanIndex];
    
		/* the number of new channels to create */
		for (newChanIndex = newChansPerOld - 1; newChanIndex >= 0; newChanIndex--) {
		    ((short *)outPtr)[baseIndex + newChanIndex] = sample;
		}
	    }
	}
	break;
    case SND_FORMAT_LINEAR_32:
    case SND_FORMAT_FLOAT: /* cast as long ints, assuming they are same size (32 bit == 4 bytes) as floats */
	for (frame = numberOfSampleFrames - 1; frame >= 0; frame--) { /* main slog backwards through the sound */
	    for (oldChanIndex = oldNumChannels - 1; oldChanIndex >= 0; oldChanIndex--) { /* the origin channel */
		unsigned baseIndex = frame * newNumChannels + oldChanIndex * newChansPerOld;
		long int sample = ((long int *)inPtr)[frame * oldNumChannels + oldChanIndex];
    
		/* the number of new channels to create */
		for (newChanIndex = newChansPerOld - 1; newChanIndex >= 0; newChanIndex--) {
		    ((long int *)outPtr)[baseIndex + newChanIndex] = sample;
		}
	    }
	}
	break;
    case SND_FORMAT_DOUBLE:
	for (frame = numberOfSampleFrames - 1; frame >= 0; frame--) { /* main slog backwards through the sound */
	    for (oldChanIndex = oldNumChannels - 1; oldChanIndex >= 0; oldChanIndex--) { /* the origin channel */
		unsigned baseIndex = frame * newNumChannels + oldChanIndex * newChansPerOld;
		long long sample = ((long long *)inPtr)[frame * oldNumChannels + oldChanIndex];
    
		/* the number of new channels to create */
		for (newChanIndex = newChansPerOld - 1; newChanIndex >= 0; newChanIndex--) {
		    /* cast as long longs, assuming they are same size (64 bit == 8 bytes) as doubles */
		    ((long long *)outPtr)[baseIndex + newChanIndex] = sample;
		}
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
    if (newNumChannels > oldNumChannels) {
	if(newNumChannels % oldNumChannels == 0) {
	    SndChannelIncrease(inPtr, outPtr, numberOfSampleFrames, oldNumChannels, newNumChannels, dataFormat);
	}
	else {
	    NSLog(@"Can't convert from %d to %d channels (output must be multiple of input)\n", oldNumChannels, newNumChannels);
	    return SND_ERR_UNKNOWN;
	}
    }
    
    /* channel reduction will have already been done by resample routine if the sampling rate was changed */
    if (oldNumChannels > newNumChannels) {
	if(oldNumChannels % newNumChannels == 0) {
	    SndChannelDecrease(inPtr, outPtr, numberOfSampleFrames, oldNumChannels, newNumChannels, dataFormat);
	}
	else {
	    NSLog(@"Can't convert from %d to %d channels (output must be divisor of input)\n", oldNumChannels, newNumChannels);
	    return SND_ERR_UNKNOWN;
	}
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
//////////////////////////////////////////////////////////////

int SndChangeSampleType(void *fromPtr, void *toPtr, int fromDataFormat, int toDataFormat, unsigned int sampleCount)
{
    int i;
    static double ONE_OVER_TWO_THIRTYONE = 1.0/2147483647.0f; /* ((2 ^ 31) - 1) */
    static double ONE_OVER_TWO_FIFTEEN = 1.0/32767.0f; /* 1/(2 ^ 15 - 1) */
    static double ONE_OVER_TWO_SEVEN = 1.0/127.0f; /* 1/(2 ^ 7 - 1) */

    if (toDataFormat > fromDataFormat) { /* toDataFormat takes up more space than fromDataFormat, or is at least higher quality */

#define LOOP_THRU_SOUND for (i = sampleCount - 1; i >= 0; i--)

        if (toDataFormat == SND_FORMAT_LINEAR_8 && fromDataFormat == SND_FORMAT_MULAW_8) {
            LOOP_THRU_SOUND {
                ((signed char *)toPtr)[i] = (signed char)
		((short)SndiMulaw(((unsigned char *)fromPtr)[i]) >> 8);
            }
        }
        else if (toDataFormat == SND_FORMAT_LINEAR_16 && fromDataFormat == SND_FORMAT_MULAW_8) {
            LOOP_THRU_SOUND {
                ((signed short *)toPtr)[i] = (signed short)
		SndiMulaw(((unsigned char *)fromPtr)[i]);
            }
        }
        else if (toDataFormat == SND_FORMAT_LINEAR_32 && fromDataFormat == SND_FORMAT_MULAW_8) {
            LOOP_THRU_SOUND {
                ((signed int *)toPtr)[i] = (signed int)
		SndiMulaw(((unsigned char *)fromPtr)[i]) << 16;
            }
        }
        else if (toDataFormat == SND_FORMAT_FLOAT && fromDataFormat == SND_FORMAT_MULAW_8) {
            LOOP_THRU_SOUND {
                ((float *)toPtr)[i] = (float)SndiMulaw(((unsigned char *)fromPtr)[i]) * ONE_OVER_TWO_FIFTEEN;
            }
        }
        else if (toDataFormat == SND_FORMAT_DOUBLE && fromDataFormat == SND_FORMAT_MULAW_8) {
            LOOP_THRU_SOUND {
                ((double *)toPtr)[i] = (double)SndiMulaw(((unsigned char *)fromPtr)[i]) * ONE_OVER_TWO_FIFTEEN;
            }
        }

        else if (toDataFormat == SND_FORMAT_LINEAR_16 && fromDataFormat == SND_FORMAT_LINEAR_8) {
            LOOP_THRU_SOUND {
                ((signed short *)toPtr)[i] = ((char*)fromPtr)[i] << 8;
            }
        }
        else if (toDataFormat == SND_FORMAT_LINEAR_32 && fromDataFormat == SND_FORMAT_LINEAR_8) {
            LOOP_THRU_SOUND {
                ((signed int *)toPtr)[i] = (signed int)((signed char*)fromPtr)[i] << 24;
            }
        }
        else if (toDataFormat == SND_FORMAT_FLOAT && fromDataFormat == SND_FORMAT_LINEAR_8) {
            LOOP_THRU_SOUND {
                ((float *)toPtr)[i] = (float)(((char *)fromPtr)[i]) * ONE_OVER_TWO_SEVEN;
            }
        }
        else if (toDataFormat == SND_FORMAT_DOUBLE && fromDataFormat == SND_FORMAT_LINEAR_8) {
            LOOP_THRU_SOUND {
                ((double *)toPtr)[i] = (double)(((char *)fromPtr)[i]) * ONE_OVER_TWO_SEVEN;
            }
        }

        else if (toDataFormat == SND_FORMAT_LINEAR_32 && fromDataFormat == SND_FORMAT_LINEAR_16) {
            LOOP_THRU_SOUND {
                ((signed int *)toPtr)[i] = (signed int)((signed short *)fromPtr)[i] << 16;
            }
        }
        else if (toDataFormat == SND_FORMAT_FLOAT && fromDataFormat == SND_FORMAT_LINEAR_16) {
            LOOP_THRU_SOUND {
                ((float *)toPtr)[i] = (float)(((signed short *)fromPtr)[i]) * ONE_OVER_TWO_FIFTEEN;
            }
        }
        else if (toDataFormat == SND_FORMAT_DOUBLE && fromDataFormat == SND_FORMAT_LINEAR_16) {
            LOOP_THRU_SOUND {
                ((double *)toPtr)[i] = (double)((signed short *)fromPtr)[i] * ONE_OVER_TWO_FIFTEEN;
            }
        }

        else if (toDataFormat == SND_FORMAT_FLOAT && fromDataFormat == SND_FORMAT_LINEAR_32) {
            LOOP_THRU_SOUND {
                ((float *)toPtr)[i] = (float)(((signed int *)fromPtr)[i] * ONE_OVER_TWO_THIRTYONE);
            }
        }
        else if (toDataFormat == SND_FORMAT_DOUBLE && fromDataFormat == SND_FORMAT_LINEAR_32) {
            LOOP_THRU_SOUND {
                ((double *)toPtr)[i] = (double)(((signed int *)fromPtr)[i] * ONE_OVER_TWO_THIRTYONE);
            }
        }

        else if (toDataFormat == SND_FORMAT_DOUBLE && fromDataFormat == SND_FORMAT_FLOAT) {
            LOOP_THRU_SOUND {
                ((double *)toPtr)[i] = (double)(((float *)fromPtr)[i]);
            }
        }

        /* that should be all the common ones. Maybe aLaw too? */
        else {
            NSLog(@"Sorry, format unsupported for conversion\n");
            return SND_ERR_BAD_FORMAT;
        }

    }

    ////////////////////////////////
    //
    // toDataFormat takes up less space than fromDataFormat, or is lower quality,
    // so we loop forward thru sound, reducing space as we do so
    //
    ////////////////////////////////

    if (toDataFormat < fromDataFormat) { /* toDataFormat takes up less space than fromDataFormat, or is lower quality */

#define LOOP_FORWARD_THRU_SOUND for (i = 0; i < sampleCount; i++)

	if (fromDataFormat == SND_FORMAT_LINEAR_8 && toDataFormat == SND_FORMAT_MULAW_8) {
	    LOOP_FORWARD_THRU_SOUND {
		((unsigned char *)toPtr)[i] = (unsigned char)
		SndMulaw((int)(((signed char *)fromPtr)[i]) << 8);
	    }
	}
	else if (fromDataFormat == SND_FORMAT_LINEAR_16 && toDataFormat == SND_FORMAT_MULAW_8) {
	    LOOP_FORWARD_THRU_SOUND {
		((unsigned char *)toPtr)[i] = (unsigned char)
		SndMulaw(((signed short *)fromPtr)[i]);
	    }
	}
	else if (fromDataFormat == SND_FORMAT_LINEAR_32 && toDataFormat == SND_FORMAT_MULAW_8) {
	    LOOP_FORWARD_THRU_SOUND {
		((unsigned char *)toPtr)[i] = (unsigned char)
		SndMulaw(((signed int *)fromPtr)[i] >> 16);
	    }
	}
	else if (fromDataFormat == SND_FORMAT_FLOAT && toDataFormat == SND_FORMAT_MULAW_8) {
	    LOOP_FORWARD_THRU_SOUND {
		((unsigned char *)toPtr)[i] = (unsigned char)
		SndiMulaw(((float *)fromPtr)[i] * 32767.0f);
	    }
	}
	else if (fromDataFormat == SND_FORMAT_DOUBLE && toDataFormat == SND_FORMAT_MULAW_8) {
	    LOOP_FORWARD_THRU_SOUND {
		((unsigned char *)toPtr)[i] = (unsigned char)
		SndiMulaw(((double *)fromPtr)[i] * 32767.0f);
	    }
	}
	
	else if (fromDataFormat == SND_FORMAT_LINEAR_16 && toDataFormat == SND_FORMAT_LINEAR_8) {
	    LOOP_FORWARD_THRU_SOUND {
		((signed char*)toPtr)[i] = (((signed short *)fromPtr)[i]) >> 8;
	    }
	}
	else if (fromDataFormat == SND_FORMAT_LINEAR_32 && toDataFormat == SND_FORMAT_LINEAR_8) {
	    LOOP_FORWARD_THRU_SOUND {
		((signed char *)toPtr)[i] = (int)(((signed int *)fromPtr)[i]) >> 24;
	    }
	}
	else if (fromDataFormat == SND_FORMAT_FLOAT && toDataFormat == SND_FORMAT_LINEAR_8) {
	    LOOP_FORWARD_THRU_SOUND {
		((unsigned char *)toPtr)[i] = (unsigned char)
		((((float *)fromPtr)[i] * 127.0f));
	    }
	}
	else if (fromDataFormat == SND_FORMAT_DOUBLE && toDataFormat == SND_FORMAT_LINEAR_8) {
	    LOOP_FORWARD_THRU_SOUND {
		((unsigned char *)toPtr)[i] = (unsigned char)
		((((double *)fromPtr)[i]) * 127.0f);
	    }
	}
	
	else if (fromDataFormat == SND_FORMAT_LINEAR_32 && toDataFormat == SND_FORMAT_LINEAR_16) {
	    LOOP_FORWARD_THRU_SOUND {
		((signed short *)toPtr)[i] = ((signed int *)fromPtr)[i] >> 16;
	    }
	}
	else if (fromDataFormat == SND_FORMAT_FLOAT && toDataFormat == SND_FORMAT_LINEAR_16) {
	    LOOP_FORWARD_THRU_SOUND {
		((signed short *)toPtr)[i] = ((float *)fromPtr)[i] * 32767;
	    }
	}
	else if (fromDataFormat == SND_FORMAT_DOUBLE && toDataFormat == SND_FORMAT_LINEAR_16) {
	    LOOP_FORWARD_THRU_SOUND {
		((signed short *)toPtr)[i] = ((double *)fromPtr)[i] * 32767;
	    }
	}
	
	else if (fromDataFormat == SND_FORMAT_FLOAT && toDataFormat == SND_FORMAT_LINEAR_32) {
	    LOOP_FORWARD_THRU_SOUND {
		((signed int *)toPtr)[i] = ((float *)fromPtr)[i] * 2147483647; /* (2 ^ 31 - 1) */
	    }
	}
	else if (fromDataFormat == SND_FORMAT_DOUBLE && toDataFormat == SND_FORMAT_LINEAR_32) {
	    LOOP_FORWARD_THRU_SOUND {
		((signed int *)toPtr)[i] = ((double *)fromPtr)[i] * 2147483647; /* (2 ^ 31 - 1) */
	    }
	}
	
	else if (fromDataFormat == SND_FORMAT_DOUBLE && toDataFormat == SND_FORMAT_FLOAT) {
	    LOOP_FORWARD_THRU_SOUND {
		((float *)toPtr)[i] = ((double *)fromPtr)[i];
	    }
	}
	
	else {
	    NSLog(@"Sorry, format unsupported for conversion\n");
	    return SND_ERR_BAD_FORMAT;
	}
    }
    return SND_ERR_NONE;
}

////////////////////////////////////////////////////////////////////////////////
// dataConvertedToFormat:
////////////////////////////////////////////////////////////////////////////////

- (NSMutableData*) dataConvertedToFormat: (int) newDataFormat
{
    long  dataItems;
    long  i;
    NSMutableData *nData;
    void *newData;

    if (newDataFormat == dataFormat)
	return data;

    dataItems   = [self lengthInSampleFrames] * [self channelCount];
    nData       = [NSMutableData dataWithLength: dataItems * SndSampleWidth(newDataFormat)];
    newData     = [nData mutableBytes];
    byteCount   = maxByteCount = [nData length];


    switch (dataFormat) {

	case SND_FORMAT_LINEAR_8: {
	    char *pData = [data mutableBytes];
	    switch (newDataFormat) {
		case SND_FORMAT_LINEAR_16:
		    for (i=0;i<dataItems;i++) {
			short v = pData[i];
			((short*)newData)[i] = v << 8;
		    }
		    break;
		case SND_FORMAT_LINEAR_32:
		    for (i=0;i<dataItems;i++) {
			long v = pData[i];
			((long*)newData)[i] = v << 24;
		    }
		    break;
		case SND_FORMAT_FLOAT:
		    for (i = 0;i<dataItems;i++) {
			float v = pData[i];
			((float*)newData)[i] = v / 128.0;
		    }
		    break;
		case SND_FORMAT_DOUBLE:
		    for (i = 0;i < dataItems;i++) {
			double v = pData[i];
			((double*)newData)[i] = v / 128.0;
		    }
		    break;
	    }
	}
	    break;

	case SND_FORMAT_LINEAR_16: {
	    short *pData = [data mutableBytes];
	    switch (newDataFormat) {
		case SND_FORMAT_LINEAR_8:
		    for (i=0;i<dataItems;i++) {
			short v = pData[i];
			((char*)newData)[i] = v >> 8;
		    }
		    break;
		case SND_FORMAT_LINEAR_32:
		    for (i=0;i<dataItems;i++) {
			long v = pData[i];
			((long*)newData)[i] = v >> 24;
		    }
		    break;
		case SND_FORMAT_FLOAT:
		    for (i=0;i<dataItems;i++) {
			float v = pData[i];
			v *= (1.0 / (128.0 * 256.0));
			((float*)newData)[i] = v;
#if RANGE_PARANOIA_CHECK
			if (v > 1.0 || v < -1.0) {
			    NSLog(@"Weird value!\n");
			}
#endif
		    }
		    break;
		case SND_FORMAT_DOUBLE:
		    for (i = 0; i < dataItems;i++) {
			double v = pData[i];
			((double*)newData)[i] = (double)(v / (128.0 * 256.0));
		    }
		    break;
	    }
	}
	    break;

	case SND_FORMAT_LINEAR_32: {
	    long* pData = [data mutableBytes];
	    switch (newDataFormat) {
		case SND_FORMAT_LINEAR_8:
		    for (i=0;i<dataItems;i++) {
			long v = pData[i];
			((char*)newData)[i] = (char)(v >> 24);
		    }
		    break;
		case SND_FORMAT_LINEAR_16:
		    for (i=0;i<dataItems;i++) {
			long v = pData[i];
			((short*)newData)[i] = (short)(v >> 8);
		    }
		    break;
		case SND_FORMAT_FLOAT:
		    for (i=0;i<dataItems;i++) {
			double v = pData[i];
			((float*)newData)[i] = (float)(v / (128.0 * 256.0 * 256.0 * 256.0));
		    }
		    break;
		case SND_FORMAT_DOUBLE:
		    for (i=0;i<dataItems;i++) {
			double v = pData[i];
			((double*)newData)[i] = (double)(v / (128.0 * 256.0 * 256.0 * 256.0));
		    }
		    break;
	    }
	    break;
	}
	case SND_FORMAT_FLOAT: {
	    float *pData = [data mutableBytes];
	    switch (newDataFormat) {
		case SND_FORMAT_LINEAR_8:
		    for (i=0;i<dataItems;i++) {
			float v = pData[i];
			((char*)newData)[i] = (char)(v * 128.0);
		    }
		    break;
		case SND_FORMAT_LINEAR_16:
		    for (i=0;i<dataItems;i++) {
			float v = pData[i];
			((short*)newData)[i] = (short)(v * 128.0 * 256.0);
		    }
		    break;
		case SND_FORMAT_LINEAR_32:
		    for (i=0;i<dataItems;i++) {
			float v = pData[i];
			((long*)newData)[i] = (long)(v * 128.0 * 256.0 * 256.0 * 256.0);
		    }
		    break;
		case SND_FORMAT_DOUBLE:
		    for (i=0;i<dataItems;i++) {
			float v = pData[i];
			((double*)newData)[i] = (double) v;
		    }
		    break;
	    }
	    break;
	}
	case SND_FORMAT_DOUBLE: {
	    double *pData = [data mutableBytes];
	    switch (newDataFormat) {
		case SND_FORMAT_LINEAR_8:
		    for (i = 0; i < dataItems; i++) {
			double v = pData[i];
			((char*)newData)[i] = (char)(v * 128.0);
		    }
		    break;
		case SND_FORMAT_LINEAR_16:
		    for (i = 0; i < dataItems; i++) {
			double v = pData[i];
			((short*)newData)[i] = (short)(v * (128.0 * 256.0));
		    }
		    break;
		case SND_FORMAT_LINEAR_32:
		    for (i = 0; i < dataItems; i++) {
			double v = pData[i];
			((long*)newData)[i] = (long)(v * (128.0 * 256.0 * 256.0 * 256.0));
		    }
		    break;
		case SND_FORMAT_FLOAT:
		    for (i = 0; i < dataItems; i++) {
			double v = pData[i];
			((float*)newData)[i] = (float)(v);
		    }
		    break;
	    }
	}
	    break;
    }
    
  //  if (bOwnsData)
  //    free(data);
  //  data = newData;
  //  bOwnsData = TRUE;
  //  formatSnd.dataFormat = newDataFormat;
  //  formatSnd.dataSize   = newDataSize;

    return nData;
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
    int fromChannelCount = channelCount;
    int fromDataFormat = dataFormat;

    if(fromChannelCount != toChannelCount) {
	int sampleFrames = [self lengthInSampleFrames];
	long dataItems = sampleFrames * toChannelCount;
	NSMutableData *toData = [NSMutableData dataWithLength: dataItems * SndSampleWidth(fromDataFormat)];
	void *fromDataPtr = [data mutableBytes];
	void *toDataPtr = [toData mutableBytes];
	int error = SndChangeChannelCount(fromDataPtr, toDataPtr, sampleFrames, fromChannelCount, toChannelCount, fromDataFormat);

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
useFastInterpolation: (BOOL) fastInterpolation
{
    int fromChannelCount;
    int fromDataFormat;
    double fromSampleRate;
    int fromDataSize;
    void *fromDataLocation;
    short *outPtr; /* output from resample is always 16 bit */

    int allocedSize;
    
    fromSampleRate = samplingRate;
    fromChannelCount = channelCount;
    fromDataFormat = dataFormat;
    fromDataLocation = [data mutableBytes];
    fromDataSize = byteCount;

    if (fromSampleRate != toSampleRate) {
#if 0 // disabled until we get this working
	double factor;

	SndFree(*toSound);
	factor = toSampleRate / fromSampleRate;
	/* Here we allocate enough room for the new number of channels, and data
	    * format, but will adjust the supposed data size to reflect the INPUT data.
	    * This allows us to expand the number of channels etc. later, without having to
	    * create a new sound.
	    */
	allocedSize = (factor * (double)fromDataSize * (float)((float)toChannelCount / (float)fromChannelCount) *
		MAX(SndSampleWidth(SND_FORMAT_LINEAR_16),
      MAX(SndSampleWidth(fromDataFormat), SndSampleWidth(toDataFormat))) / (float)SndSampleWidth(fromDataFormat)) + 1;

	SndAlloc(toSound, allocedSize,
	  toDataFormat, toSampleRate, toChannelCount,
	  (fromSound->dataFormat != SND_FORMAT_INDIRECT) ?
	  fromSound->dataLocation - sizeof(SndSoundStruct) + 4 :
	  fromSound->dataSize - sizeof(SndSoundStruct) + 4);

	if (fromChannelCount < toChannelCount) {
	    (*toSound)->dataSize = (int)(factor * (double)fromDataSize) + 1;
	    (*toSound)->channelCount = fromChannelCount;
	}
	
	// TODO Convert this to - changeSampleRate: channelCount: format: largeFilter: interpolateFilter: linearInterpolation:
	// assign the samplingRate within that method.
	SndChangeSampleRate(fromSound, *toSound,
		     largeFilter,
		     interpFilter,
		     fastInterpolation, fromDataLocation,
		     (short *)((char *)*toSound + (*toSound)->dataLocation));

	samplingRate = toSamplingRate;
	// channelCount may change, and dataFormat may change.
	/* if we have changed rate, output format is always linear 16, otherwise use the originally specified output format */
	// TODO replace the old data with the new sample rate converted data.
#endif
    }
    
    // The sample rate converted sample data is now ready for channel/format conversion
    return [self convertToFormat: toDataFormat channelCount: toChannelCount];
}

- convertBytes: (void *) fromDataPtr
     intoRange: (NSRange) bufferByteRange
    fromFormat: (int) fromDataFormat
      channels: (int) fromChannelCount
  samplingRate: (double) fromSamplingRate
{
    int toChannelCount = [self channelCount];
    int toDataFormat = [self dataFormat];
    void *toDataPtr = [self bytes] + bufferByteRange.location;
    long sampleFrames = bufferByteRange.length / [self frameSizeInBytes];
    int error;

    if(fromSamplingRate != [self samplingRate]) {
	// TODO should do sampling rate conversion
	NSLog(@"Sampling rate conversion not done! Needs implementation.\n");
    }

    if(fromChannelCount != toChannelCount) {
	error = SndChangeChannelCount(fromDataPtr, toDataPtr, sampleFrames, fromChannelCount, toChannelCount, fromDataFormat);

	if(error != SND_ERR_NONE)
	    return nil;
	
	fromDataPtr = toDataPtr; // This will then do the sample type conversion in place, which is ok by SndChangeSampleType.
    }

    if(fromDataFormat != toDataFormat) {
	error = SndChangeSampleType(fromDataPtr, toDataPtr, fromDataFormat, toDataFormat, sampleFrames * toChannelCount);

	if(error != SND_ERR_NONE)
	    return nil;
	
	// byteCount = maxCount = // do we need to do this? Only if the buffer range differs. TODO
    }
    
    return self;
}

// Create a new buffer of the same number of samples as the receiver
// converted to the new format, sampling rate and channel count.
// returns the new buffer instance.
- (SndAudioBuffer *) audioBufferConvertedToFormat: (int) format
				     samplingRate: (double) aRate
				     channelCount: (int) aChannelCount
{
    SndAudioBuffer *newBuffer = [[SndAudioBuffer alloc] init];
    // do conversion into new memory
    return [newBuffer autorelease];
}

@end