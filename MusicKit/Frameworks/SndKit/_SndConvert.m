/******************************************************************************
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
#include "SndFunctions.h"
#include "SndResample.h"
#include <Foundation/NSByteOrder.h>
#include <string.h>      /* for memmove   */

#else

#include <Foundation/NSByteOrder.h>
#include "SndFunctions.h"
#include "SndResample.h"

#ifndef WIN32
#import <libc.h>
#else
#import <wtypes.h>
#import <Winsock.h>
#import <malloc.h>
#import <stdio.h>
#endif

#import <objc/objc.h> /* for BOOL, YES, NO, TRUE, FALSE */

#ifndef USE_NEXTSTEP_SOUND_IO
#import "sounderror.h"
#endif

#endif /* GNUSTEP */

/*
 * Convert from one sound struct to another, where toSound defines the format the data is to be
 * converted to and provides the location for the converted sound data.
 */
int SndConvertSound(const SndSoundStruct *fromSound,
		    SndSoundStruct **toSound,
                    BOOL allocate,
		    BOOL largeFilter,
		    BOOL interpFilter,
		    BOOL fast)
{
    int channelCountFrom, channelCountTo;
    int df1,df2;
    int ds1,ds2; /* dataSize of toSound should really be 0. If it is fragmented, should I SndFree? */
    int sr1,sr2;
    int dl1;
    double factor;
    int outCount;
    int width;
    short *outPtr; /* output from resample is always 16 bit */
    int error;
        
    int allocedSize;
    
    if (!fromSound) return SND_ERR_NOT_SOUND;
    if (toSound == NULL || *toSound == NULL) return SND_ERR_NOT_SOUND;
    if (fromSound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
    if ((*toSound)->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
    
    sr1 = fromSound->samplingRate;	sr2 = (*toSound)->samplingRate;
    channelCountFrom = fromSound->channelCount;	channelCountTo = (*toSound)->channelCount;
    ds1 = fromSound->dataSize;		ds2 = (*toSound)->dataSize;
    df1 = fromSound->dataFormat;	df2 = (*toSound)->dataFormat;
    dl1 = fromSound->dataLocation;
    
    if (df2 == SND_FORMAT_INDIRECT)
        df2 = (((SndSoundStruct *)(*((SndSoundStruct **)
               ((*toSound)->dataLocation))))->dataFormat);
	       
    if (sr1 == sr2 && channelCountFrom == channelCountTo && df1 == df2)
        return SndCopySound(toSound,fromSound);
	
    if (df1 == SND_FORMAT_INDIRECT) {
        df1 = ((SndSoundStruct *)(*((SndSoundStruct **) dl1)))->dataFormat;
        ds1 = SndSampleCount(fromSound) * channelCountFrom * SndSampleWidth(df1);
    }

    if ((float)((float) channelCountTo / (float) channelCountFrom) != (int) (channelCountTo / channelCountFrom)
        && (float)((float) channelCountFrom / (float) channelCountTo) != (int) (channelCountFrom / channelCountTo)) {
        printf("Can't convert from %d to %d channels (output must be multiple or divisor of input)\n", channelCountFrom, channelCountTo);
        return SND_ERR_UNKNOWN;
    }

    SndFree(*toSound);
    factor = (double)sr2/(double)sr1;
    /* Here we allocate enough room for the new number of channels, and data
     * format, but will adjust the supposed data size to reflect the INPUT data.
     * This allows us to expand the number of channels etc. later, without having to
     * create a new sound.
     */
    allocedSize = (factor * (double)ds1 * (float)((float)channelCountTo / (float)channelCountFrom) * 
        MAX(SndSampleWidth(SND_FORMAT_LINEAR_16),
        MAX(SndSampleWidth(df1), SndSampleWidth(df2))) / (float)SndSampleWidth(df1)) + 1;

    SndAlloc(toSound, allocedSize,
		df2, sr2, channelCountTo,
		(fromSound->dataFormat != SND_FORMAT_INDIRECT) ? 
		fromSound->dataLocation - sizeof(SndSoundStruct) + 4 :
		fromSound->dataSize - sizeof(SndSoundStruct) + 4);
    
    if (channelCountFrom < channelCountTo) {
        (*toSound)->dataSize = (int)(factor * (double)ds1) + 1;
        (*toSound)->channelCount = channelCountFrom;
    }

    memmove((*toSound)->info,fromSound->info, (*toSound)->dataLocation - sizeof(SndSoundStruct) + 4);
    
    if (fromSound->dataFormat == SND_FORMAT_INDIRECT) {
        SndChangeSampleRate(fromSound, *toSound, 
			    largeFilter, 
			    interpFilter, 
			    fast, NULL, 
			    (short *)((char *)*toSound + (*toSound)->dataLocation));
    }
    else {
        SndChangeSampleRate(fromSound, *toSound, 
                            largeFilter, 
                            interpFilter, 
                            fast, (char *)fromSound + dl1, 
                            (short *)((char *)*toSound + (*toSound)->dataLocation));
    }
    /* now check channel count -- if we need to increase the number of channels from 1 to
     * 2, or 4, we have hopefully got enough data malloced in *toSound to duplicate pairs
     * of samples.
     * Endian-wise, I simply avoid floats and doubles, re-casting as longs and long longs
     * which should side step the issue nicely.
     */
    if (channelCountTo > (*toSound)->channelCount) {
        int origChans,df;
        SndGetDataPointer((*toSound), (char **)(&outPtr), &outCount, &width);
        
        origChans = (*toSound)->channelCount;
        df = (*toSound)->dataFormat;         /* if we have changed rate, always linear 16, otherwise 'real' output format */
	
        SndChannelIncrease ((void *)outPtr, outCount / origChans, origChans, channelCountTo, df );
	
        (*toSound)->channelCount = channelCountTo;
        (*toSound)->dataSize = outCount * channelCountTo * width;
	df1 = (*toSound)->dataFormat; /* because the resample routine probably changed it */
    }
    
    /* channel reduction will have already been done by resample routine if the sampling rate was changed */
    if ((*toSound)->channelCount > channelCountTo) {	
        int df = (*toSound)->dataFormat;
        int nChansIn = (*toSound)->channelCount;

        SndGetDataPointer((*toSound), (char **)(&outPtr), &outCount, &width);
	
        SndChannelDecrease ((void *)outPtr, outCount / (*toSound)->channelCount, nChansIn, channelCountTo, df );
	
        (*toSound)->channelCount = channelCountTo;
        (*toSound)->dataSize = outCount * channelCountTo * width;
	df1 = (*toSound)->dataFormat; /* because the resample routine probably changed it */
    }
    
    //////////////////////////////////////////////////////////////
    //
    // This next section does an in-place conversion of a buffer
    // of audio from any type (eg ulaw, short, int, float, double
    // etc) to any other. The buffer must have enough allocated
    // memory for the new sound if it the new format requires more
    // memory than the old one.
    // If the new format is bigger, it expands from the last sample
    // to the first - if the new one is smaller, then the other way
    // around.
    //////////////////////////////////////////////////////////////

    SndGetDataPointer(*toSound, (char **)(&outPtr), &outCount, &width);
    error = SndChangeSampleType(outPtr, outPtr, df1, df2, outCount);
    if (error ==  SND_ERR_BAD_FORMAT) {
        SndFree(*toSound);
        return error;
    }
    (*toSound)->dataFormat = df2;
    (*toSound)->dataSize = outCount * SndSampleWidth(df2);

    df1 = (*toSound)->dataFormat; /* allow for current df to have been changed by rate change */
    // printf("alloced size: %d official size: %d\n", allocedSize, (*toSound)->dataSize);
    if ((*toSound)->dataSize < allocedSize) /* only decrease space if necessary */
        *toSound = realloc(*toSound,(*toSound)->dataSize + (*toSound)->dataLocation);
    return SND_ERR_NONE;
}

void SndChannelDecrease (void *outPtr, int frames, int oldNumChannels, int newNumChannels, int df )
{
    int chansToSum = oldNumChannels / newNumChannels;
    int passes = newNumChannels; /* convenience name */
    int m,n;
    unsigned int frame;
    unsigned int baseIndex;
    long int sum     = 0;
    float sumFloat   = 0;
    double sumDouble = 0;

    for (frame = 0; frame < frames; frame++) {
        for (m = 0; m < passes; m++) { /* m and n take us through 1 channel independent sample */
            baseIndex = frame * oldNumChannels + m * newNumChannels;
            /* fairly inefficient.*/
            for (n = 0; n < chansToSum; n++) { 
                switch(df) {
                  case SND_FORMAT_LINEAR_8: /* endian ok */
                    sum += ((signed char *)outPtr)[baseIndex + n];
                    break;
                  case SND_FORMAT_MULAW_8: /* endian ok */
                    sum += SndiMulaw(((unsigned char *)outPtr)[baseIndex + n]);
                    break;
                  case SND_FORMAT_LINEAR_32:
                    sumDouble += (long int)(((signed long int *)outPtr)
                            [baseIndex + n]);
                    break;
                  case SND_FORMAT_FLOAT:
                    sumFloat += (float)(((float *)outPtr)[baseIndex + n]);
                    break;
                  case SND_FORMAT_DOUBLE:
                    sumDouble += (double)(((double *)outPtr)[baseIndex + n]);
                    break;
                  default:
                  case SND_FORMAT_LINEAR_16:
                    sum += ((SND_HWORD *)outPtr)[baseIndex + n];
                    break;
                }
            } /* summing several channels into 1 channel */
	    
            switch(df) {
              case SND_FORMAT_FLOAT:
                ((float *)outPtr)[frame * newNumChannels + m] = (float)(sumFloat / chansToSum);
		sumFloat = 0;
                break;
              case SND_FORMAT_DOUBLE:
                ((double *)outPtr)[frame * newNumChannels + m] = (double)(sumDouble / chansToSum);
		sumDouble = 0;
                break;
              default:
              case SND_FORMAT_LINEAR_16:
                ((signed short *)outPtr)[frame * newNumChannels + m] =
                        (signed short)(sum / chansToSum);
		sum = 0;
                break;
              case SND_FORMAT_LINEAR_8:
                ((signed char *)outPtr)[frame * newNumChannels + m] =
                        (signed char)(sum / chansToSum);
		sum = 0;
                break;
              case SND_FORMAT_MULAW_8:
                ((unsigned char *)outPtr)[frame * newNumChannels + m] = 
		        (unsigned char)SndMulaw((short)(sum / chansToSum));
		sum = 0;
                break;
              case SND_FORMAT_LINEAR_32:
                ((signed long int *)outPtr)[frame * newNumChannels + m] = 
                        (signed long int)(sumDouble / chansToSum);
		sumDouble = 0;
            } 
        } /* passes through channel independent sample */
    }


}

void SndChannelIncrease (void *outPtr, int frames, int oldNumChannels, int newNumChannels, int df )
/* endian-agnostic, as floats and doubles are cast to long and longlong respectively. */
{
    int c,j,k;
    int frame;
        
    k = newNumChannels / oldNumChannels; /* multiply factor - num of new channels per original one */
    switch (df) {
        case SND_FORMAT_MULAW_8:
        case SND_FORMAT_LINEAR_8:
            for (frame = frames - 1; frame >= 0 ; frame--) { /* main slog backwards through the sound */
                for (c = oldNumChannels - 1; c >= 0; c--) { /* the origin channel */
		    unsigned baseIndex = frame * newNumChannels + c * k;
		    char m = ((char *)outPtr)[frame * oldNumChannels + c];
                    for (j = k - 1; j >= 0; j--) {        /* the number of new channels to create */
                        ((char *)outPtr)[baseIndex + j] = m;
		    }
		}
	    }
	    break;
        case SND_FORMAT_LINEAR_16:
	default:
            for (frame = frames - 1; frame >= 0 ; frame--) { /* main slog backwards through the sound */
                for (c = oldNumChannels - 1; c >= 0; c--) { /* the origin channel */
		    unsigned baseIndex = frame * newNumChannels + c * k;
		    short m = ((short *)outPtr)[frame * oldNumChannels + c];
                    for (j = k - 1; j >= 0; j--) {        /* the number of new channels to create */
                        ((short *)outPtr)[baseIndex + j] = m;
		    }
		}
	    }
	    break;
        case SND_FORMAT_LINEAR_32:
        case SND_FORMAT_FLOAT: /* cast as long ints, assuming they are same size (32 bit == 4 bytes) as floats */
            for (frame = frames - 1; frame >= 0 ; frame--) { /* main slog backwards through the sound */
                for (c = oldNumChannels - 1; c >= 0; c--) { /* the origin channel */
		    unsigned baseIndex = frame * newNumChannels + c * k;
		    long int m = ((long int *)outPtr)[frame * oldNumChannels + c];
                    for (j = k - 1; j >= 0; j--) {        /* the number of new channels to create */
                        ((long int *)outPtr)[baseIndex + j] = m;
		    }
		}
            }
	    break;
        case SND_FORMAT_DOUBLE:
            for (frame = frames - 1; frame >= 0 ; frame--) { /* main slog backwards through the sound */
                for (c = oldNumChannels - 1; c >= 0; c--) { /* the origin channel */
		    unsigned baseIndex = frame * newNumChannels + c * k;
		    long long m = ((long long *)outPtr)[frame * oldNumChannels + c];
                    for (j = k - 1; j >= 0; j--) {        /* the number of new channels to create */
/* cast as long longs, assuming they are same size (64 bit == 8 bytes) as doubles */
                        ((long long *)outPtr)[baseIndex + j] = m;
		    }
		}
	    }
    }
}

int SndChangeSampleType(void *fromPtr, void *toPtr, int dfFrom, int dfTo, unsigned int sampleCount)
{
    int i;
    static double ONE_OVER_TWO_THIRTYONE = 1.0/2147483647.0f; /* ((2 ^ 31) - 1) */
    static double ONE_OVER_TWO_FIFTEEN = 1.0/32767.0f; /* 1/(2 ^ 15 - 1) */
    static double ONE_OVER_TWO_SEVEN = 1.0/127.0f; /* 1/(2 ^ 7 - 1) */

    if (dfTo > dfFrom) { /* dfTo takes up more space than dfFrom, or is at least higher quality */

#define LOOP_THRU_SOUND for (i = sampleCount - 1; i>=0; i--)

        if (dfTo == SND_FORMAT_LINEAR_8 && dfFrom == SND_FORMAT_MULAW_8) {
            LOOP_THRU_SOUND {
                ((signed char *)toPtr)[i] = (signed char)
		    ((short)SndiMulaw(((unsigned char *)fromPtr)[i]) >> 8);
            }
        }
        else if (dfTo == SND_FORMAT_LINEAR_16 && dfFrom == SND_FORMAT_MULAW_8) {
            LOOP_THRU_SOUND {
                ((signed short *)toPtr)[i] = (signed short)
                    SndiMulaw(((unsigned char *)fromPtr)[i]);
            }
        }
        else if (dfTo == SND_FORMAT_LINEAR_32 && dfFrom == SND_FORMAT_MULAW_8) {
            LOOP_THRU_SOUND {
                ((signed int *)toPtr)[i] = (signed int)
                    SndiMulaw(((unsigned char *)fromPtr)[i]) << 16;
            }
        }
        else if (dfTo == SND_FORMAT_FLOAT && dfFrom == SND_FORMAT_MULAW_8) {
            LOOP_THRU_SOUND {
                ((float *)toPtr)[i] = (float)SndiMulaw(((unsigned char *)fromPtr)[i]) * ONE_OVER_TWO_FIFTEEN;
            }
        }
        else if (dfTo == SND_FORMAT_DOUBLE && dfFrom == SND_FORMAT_MULAW_8) {
            LOOP_THRU_SOUND {
                ((double *)toPtr)[i] = (double)SndiMulaw(((unsigned char *)fromPtr)[i]) * ONE_OVER_TWO_FIFTEEN;
            }
        }

        else if (dfTo == SND_FORMAT_LINEAR_16 && dfFrom == SND_FORMAT_LINEAR_8) {
            LOOP_THRU_SOUND {
                ((signed short *)toPtr)[i] = ((char*)fromPtr)[i] << 8;
            }
        }
        else if (dfTo == SND_FORMAT_LINEAR_32 && dfFrom == SND_FORMAT_LINEAR_8) {
            LOOP_THRU_SOUND {
                ((signed int *)toPtr)[i] = (signed int)((signed char*)fromPtr)[i] << 24;
            }
        }
        else if (dfTo == SND_FORMAT_FLOAT && dfFrom == SND_FORMAT_LINEAR_8) {
            LOOP_THRU_SOUND {
                ((float *)toPtr)[i] = (float)(((char *)fromPtr)[i]) * ONE_OVER_TWO_SEVEN;
            }
        }
        else if (dfTo == SND_FORMAT_DOUBLE && dfFrom == SND_FORMAT_LINEAR_8) {
            LOOP_THRU_SOUND {
                ((double *)toPtr)[i] = (double)(((char *)fromPtr)[i]) * ONE_OVER_TWO_SEVEN;
            }
        }

        else if (dfTo == SND_FORMAT_LINEAR_32 && dfFrom == SND_FORMAT_LINEAR_16) {
            LOOP_THRU_SOUND {
                ((signed int *)toPtr)[i] = (signed int)((signed short *)fromPtr)[i] << 16;
            }
        }
        else if (dfTo == SND_FORMAT_FLOAT && dfFrom == SND_FORMAT_LINEAR_16) {
            LOOP_THRU_SOUND {
                ((float *)toPtr)[i] = (float)(((signed short *)fromPtr)[i]) * ONE_OVER_TWO_FIFTEEN;
            }
        }
        else if (dfTo == SND_FORMAT_DOUBLE && dfFrom == SND_FORMAT_LINEAR_16) {
            LOOP_THRU_SOUND {
                ((double *)toPtr)[i] = (double)((signed short *)fromPtr)[i] * ONE_OVER_TWO_FIFTEEN;
            }
        }

        else if (dfTo == SND_FORMAT_FLOAT && dfFrom == SND_FORMAT_LINEAR_32) {
            LOOP_THRU_SOUND {
                ((float *)toPtr)[i] = (float)(((signed int *)fromPtr)[i] * ONE_OVER_TWO_THIRTYONE);
            }
        }
        else if (dfTo == SND_FORMAT_DOUBLE && dfFrom == SND_FORMAT_LINEAR_32) {
            LOOP_THRU_SOUND {
                ((double *)toPtr)[i] = (double)(((signed int *)fromPtr)[i] * ONE_OVER_TWO_THIRTYONE);
            }
        }

        else if (dfTo == SND_FORMAT_DOUBLE && dfFrom == SND_FORMAT_FLOAT) {
            LOOP_THRU_SOUND {
                ((double *)toPtr)[i] = (double)(((float *)fromPtr)[i]);
            }
        }
        
        /* that should be all the common ones. Maybe aLaw too? */
        else {
            printf("Sorry, format unsupported for conversion\n");
            return SND_ERR_BAD_FORMAT;
        }

    }
    
    ////////////////////////////////
    //
    // dfTo takes up less space than dfFrom, or is lower quality,
    // so we loop forward thru sound, reducing space as we do so
    //
    ////////////////////////////////
    
    if (dfTo < dfFrom) { /* dfTo takes up less space than dfFrom, or is lower quality */

#define LOOP_FORWARD_THRU_SOUND for (i = 0 ; i < sampleCount; i++)

        if (dfFrom == SND_FORMAT_LINEAR_8 && dfTo == SND_FORMAT_MULAW_8) {
            LOOP_FORWARD_THRU_SOUND {
                ((unsigned char *)toPtr)[i] = (unsigned char)
                    SndMulaw((int)(((signed char *)fromPtr)[i]) << 8);
            }
        }
        else if (dfFrom == SND_FORMAT_LINEAR_16 && dfTo == SND_FORMAT_MULAW_8) {
            LOOP_FORWARD_THRU_SOUND {
                ((unsigned char *)toPtr)[i] = (unsigned char)
                    SndMulaw(((signed short *)fromPtr)[i]);
            }
        }
        else if (dfFrom == SND_FORMAT_LINEAR_32 && dfTo == SND_FORMAT_MULAW_8) {
            LOOP_FORWARD_THRU_SOUND {
                ((unsigned char *)toPtr)[i] = (unsigned char)
                    SndMulaw(((signed int *)fromPtr)[i] >> 16);
            }
        }
        else if (dfFrom == SND_FORMAT_FLOAT && dfTo == SND_FORMAT_MULAW_8) {
            LOOP_FORWARD_THRU_SOUND {
                ((unsigned char *)toPtr)[i] = (unsigned char)
                    SndiMulaw(((float *)fromPtr)[i] * 32767.0f);
            }
        }
        else if (dfFrom == SND_FORMAT_DOUBLE && dfTo == SND_FORMAT_MULAW_8) {
            LOOP_FORWARD_THRU_SOUND {
                ((unsigned char *)toPtr)[i] = (unsigned char)
                    SndiMulaw(((double *)fromPtr)[i] * 32767.0f);
            }
        }

        else if (dfFrom == SND_FORMAT_LINEAR_16 && dfTo == SND_FORMAT_LINEAR_8) {
            LOOP_FORWARD_THRU_SOUND {
                ((signed char*)toPtr)[i] = (((signed short *)fromPtr)[i]) >> 8;
            }
        }
        else if (dfFrom == SND_FORMAT_LINEAR_32 && dfTo == SND_FORMAT_LINEAR_8) {
            LOOP_FORWARD_THRU_SOUND {
                ((signed char *)toPtr)[i] = (int)(((signed int *)fromPtr)[i]) >> 24;
            }
        }
        else if (dfFrom == SND_FORMAT_FLOAT && dfTo == SND_FORMAT_LINEAR_8) {
            LOOP_FORWARD_THRU_SOUND {
                ((unsigned char *)toPtr)[i] = (unsigned char)
                        ((((float *)fromPtr)[i] * 127.0f));
            }
        }
        else if (dfFrom == SND_FORMAT_DOUBLE && dfTo == SND_FORMAT_LINEAR_8) {
            LOOP_FORWARD_THRU_SOUND {
                ((unsigned char *)toPtr)[i] = (unsigned char)
		        ((((double *)fromPtr)[i]) * 127.0f);
            }
        }

        else if (dfFrom == SND_FORMAT_LINEAR_32 && dfTo == SND_FORMAT_LINEAR_16) {
            LOOP_FORWARD_THRU_SOUND {
                ((signed short *)toPtr)[i] = ((signed int *)fromPtr)[i] >> 16;
            }
        }
        else if (dfFrom == SND_FORMAT_FLOAT && dfTo == SND_FORMAT_LINEAR_16) {
            LOOP_FORWARD_THRU_SOUND {
                ((signed short *)toPtr)[i] = ((float *)fromPtr)[i] * 32767;
            }
        }
        else if (dfFrom == SND_FORMAT_DOUBLE && dfTo == SND_FORMAT_LINEAR_16) {
            LOOP_FORWARD_THRU_SOUND {
                ((signed short *)toPtr)[i] = ((double *)fromPtr)[i] * 32767;
            }
        }

        else if (dfFrom == SND_FORMAT_FLOAT && dfTo == SND_FORMAT_LINEAR_32) {
            LOOP_FORWARD_THRU_SOUND {
                ((signed int *)toPtr)[i] = ((float *)fromPtr)[i] * 2147483647; /* (2 ^ 31 - 1) */
            }
        }
        else if (dfFrom == SND_FORMAT_DOUBLE && dfTo == SND_FORMAT_LINEAR_32) {
            LOOP_FORWARD_THRU_SOUND {
                ((signed int *)toPtr)[i] = ((double *)fromPtr)[i] * 2147483647; /* (2 ^ 31 - 1) */
            }
        }

        else if (dfFrom == SND_FORMAT_DOUBLE && dfTo == SND_FORMAT_FLOAT) {
            LOOP_FORWARD_THRU_SOUND {
                ((float *)toPtr)[i] = ((double *)fromPtr)[i];
            }
        }
        
        else {
            printf("Sorry, format unsupported for conversion\n");
	    return SND_ERR_BAD_FORMAT;
        }
    }
    return SND_ERR_NONE;
}
     
void SndChangeSampleRate(const SndSoundStruct *fromSound, SndSoundStruct *toSound,
                      BOOL largeFilter, BOOL interpFilter, BOOL fast, void *alternativeInput, short *outPtr)
{
//////////////////////////////////////////////
//
// Adjust the sample rate if necessary, reading from
// the fromSound and writing into the toSound. The
// resample code has been modified to work with SndSoundStructs
// for both in and out, and can read fragmented sounds directly.
//
//////////////////////////////////////////////

    int inCount, outCount;
    int width;
    float factor;
    int cc1 = fromSound->channelCount;
    int cc2 = toSound->channelCount;
    int df1 = fromSound->dataFormat;
    int ds1 = fromSound->dataSize;
    int dl1 = fromSound->dataLocation, dl2 = toSound->dataLocation;
    int sr1 = fromSound->samplingRate;
    int sr2 = toSound->samplingRate;

    if (df1 == SND_FORMAT_INDIRECT) {
        df1 = ((SndSoundStruct *)(*((SndSoundStruct **) dl1)))->dataFormat;
        ds1 = SndSampleCount(fromSound) * cc1 * SndSampleWidth(df1);
    }
    
    if (sr1 != sr2) {
      factor = sr2 / sr1;
      inCount = SndBytesToSamples(ds1, cc1, df1);
      width   = SndSampleWidth(df1);

      outCount = factor * inCount + 1;

        {
            /* (BOOL)interpFilter = interpolate within filter
             * (BOOL)linearInterp: 1 = fastmode
             * (BOOL)largeFilter: 1 = use large filter
             * char *filterFile: NULL = use internal
             */
            char *filterFile = NULL;
            BOOL linearInterp = fast;
            int outCountReal;
            outCountReal = resample(factor, outPtr, inCount, outCount, MIN(cc1,cc2),
                                    interpFilter, linearInterp, largeFilter, filterFile, fromSound, 0, alternativeInput);
            toSound->dataFormat = SND_FORMAT_LINEAR_16; /* this is the output format */
            toSound->channelCount = MIN(cc1,cc2); /* channel count is reduced if nec */
//			printf("Completed resample. OutCount = %d\n", outCountReal);
            toSound->dataSize = outCountReal * toSound->channelCount * 2; /* 2 is SND_FORMAT_LINEAR_16 */
//NO!            SndSwapHostToSound(outPtr, outPtr, outCountReal, toSound->channelCount, SND_FORMAT_LINEAR_16);
        }
    } 
    else {
	/* here I just copy the sound data into outSound. It will have its channels expanded
	 * after this...
	 */
        if (df1 != SND_FORMAT_INDIRECT)
            memmove((char *)toSound, (char *)fromSound, fromSound->dataSize + dl1);
        else {
            int count = 0, i=0;
            SndSoundStruct *theStruct;
            char *startLocation = (char *)toSound + dl2;
            SndSoundStruct **ssList = (SndSoundStruct **)dl1;
            while ((theStruct = ssList[i++]) != NULL) {
                memmove(startLocation + count,
                        (char *)theStruct + theStruct->dataLocation,
                        theStruct->dataSize);
                count += theStruct->dataSize;
            }
        }
    }
}  
