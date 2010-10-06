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

#import <Foundation/Foundation.h>
#import "SndError.h"
#import "SndFunctions.h"
#import "SndMuLaw.h"
#import "SndResample.h"
#import "SndAudioBuffer.h"

#define DEBUG_CHANNEL_MAPPING 0  // 1 to dump out the channel map.
#define FIXED_CHANNEL_MAPPING 1  // 1 to not do malloc's during channel mapping.
#define MAX_CHANNEL_MAPPING 32   // Maximum number of channels expected in an audio stream if not doing mallocs.

#define CONVERTFORMATERR(from, to) NSLog(@"Sorry, unsupported conversion from format %@ to %@.\n", SndFormatName((from), NO), SndFormatName((to), NO));


@implementation SndAudioBuffer(SampleConversion)

//////////////////////////////////////////////
//
// Adjust the sample rate if necessary, reading from
// the fromSound and writing into the toSound. 
// We do not directly support resampling indirect Snds.
//
//////////////////////////////////////////////
void SndChangeSampleRate(const SndFormat fromSound,
			 void *inputPtr,
			 SndFormat *toSound,
			 short *outPtr,
			 BOOL largeFilter,
			 BOOL interpolateFilter,
			 BOOL linearInterpolation)
{
    int fromChannelCount = fromSound.channelCount;
    int fromDataFormat = fromSound.dataFormat;
    double fromSampleRate = fromSound.sampleRate;
    int toChannelCount = toSound->channelCount;
    double toSampleRate = toSound->sampleRate;

    if (fromSampleRate != toSampleRate) {
	double stretchFactor = toSampleRate / fromSampleRate;
	int outFrameCount = stretchFactor * fromSound.frameCount + 1;

	/* interpolateFilter: YES = interpolate within filter.
	 * linearInterp: YES = fast mode.
	 * largeFilter: YES = use large filter.
	 * filterFile: NULL = use internal filter.
	 */
	char *filterFile = NULL;
	int outCountReal = resample(stretchFactor, outPtr, fromSound.frameCount, outFrameCount, MIN(fromChannelCount, toChannelCount),
				interpolateFilter, linearInterpolation, largeFilter, filterFile, fromSound, 0, inputPtr);

	//NSLog(@"Completed resample stretching by %lf. fromSound.frameCount = %d outFrameCount = %d outCountReal = %d\n", stretchFactor, fromSound.frameCount, outFrameCount, outCountReal);
	toSound->dataFormat = SND_FORMAT_LINEAR_16; /* this is the output format */
	toSound->channelCount = MIN(fromChannelCount, toChannelCount); /* channel count is reduced if nec */
	toSound->frameCount = outCountReal;
    }
    else {
	// here I just copy the sound data into outSound. It will have its channels expanded after this...
        if (fromDataFormat != SND_FORMAT_INDIRECT)
            memmove((char *) outPtr, (char *) inputPtr, SndDataSize(fromSound));
        else {
	    NSLog(@"SND_FORMAT_INDIRECT no longer supported\n");
        }
    }
}

// dataFormat is the same going in and going out.
// This is capable of in place conversion if inPtr and outPtr are the same.
// TODO This is a good candidate for Altivec optimisation
void SndChannelDecrease(void *inPtr, 
			void *outPtr, 
			unsigned long numberOfSampleFrames, 
			int oldNumChannels, 
			int newNumChannels, 
			SndSampleFormat dataFormat, 
			short *map)
{
    int oldChannelIndex;
    int newChannelIndex;
    unsigned long frame;
    long int *sumInteger = (long int *) calloc(newNumChannels, sizeof(long int));
    float *sumFloat = (float *) calloc(newNumChannels, sizeof(float));
    double *sumDouble = (double *) calloc(newNumChannels, sizeof(double));
    int *channelSumCount = (int *) calloc(newNumChannels, sizeof(int));

    // Now determine how many old channels are to be summed for each new channel.
    for (oldChannelIndex = 0; oldChannelIndex < oldNumChannels; oldChannelIndex++) {
	channelSumCount[map[oldChannelIndex]]++;
    }
        
    for (frame = 0; frame < numberOfSampleFrames; frame++) {
	unsigned long sampleIndex = frame * oldNumChannels;
	
	// Sum old channels according to map into newNumChannels long summing array.
        for (oldChannelIndex = 0; oldChannelIndex < oldNumChannels; oldChannelIndex++) {
	    switch(dataFormat) {
	    case SND_FORMAT_LINEAR_8: /* endian ok */
		sumInteger[map[oldChannelIndex]] += ((signed char *) inPtr)[sampleIndex + oldChannelIndex];
		break;
	    case SND_FORMAT_MULAW_8: /* endian ok */
		sumInteger[map[oldChannelIndex]] += SndMuLawToLinear(((unsigned char *) inPtr)[sampleIndex + oldChannelIndex]);
		break;
	    case SND_FORMAT_LINEAR_16: /* endian ok */
		sumInteger[map[oldChannelIndex]] += ((SND_HWORD *) inPtr)[sampleIndex + oldChannelIndex];
		break;
	    case SND_FORMAT_LINEAR_24:
		// TODO Not endian ok, the shift down currently assumes big endian!
		sumInteger[map[oldChannelIndex]] += *((long int *)((signed char *) inPtr + (sampleIndex + oldChannelIndex) * 3)) >> 8;
		break;
	    case SND_FORMAT_LINEAR_32:
		sumDouble[map[oldChannelIndex]] += (long int)(((signed long int *) inPtr)[sampleIndex + oldChannelIndex]);
		break;
	    case SND_FORMAT_FLOAT:
		sumFloat[map[oldChannelIndex]] += (float)(((float *) inPtr)[sampleIndex + oldChannelIndex]);
		break;
	    case SND_FORMAT_DOUBLE:
		sumDouble[map[oldChannelIndex]] += (double)(((double *) inPtr)[sampleIndex + oldChannelIndex]);
		break;
	    default:
		NSLog(@"SndChannelDecrease: can\'t decrease channels of format %d samples\n", dataFormat);
	    }
	}
	// Divide each new channel by the number of old channels which were summed.
	for (newChannelIndex = 0; newChannelIndex < newNumChannels; newChannelIndex++) {
	    switch(dataFormat) {
	    case SND_FORMAT_LINEAR_8:
		((signed char *) outPtr)[frame * newNumChannels + newChannelIndex] = (signed char)(sumInteger[newChannelIndex] / channelSumCount[newChannelIndex]);
		sumInteger[newChannelIndex] = 0;
		break;
	    case SND_FORMAT_MULAW_8:
		((unsigned char *) outPtr)[frame * newNumChannels + newChannelIndex] = (unsigned char)SndLinearToMuLaw((short)(sumInteger[newChannelIndex] / channelSumCount[newChannelIndex]));
		sumInteger[newChannelIndex] = 0;
		break;
	    case SND_FORMAT_LINEAR_16:
		((signed short *) outPtr)[frame * newNumChannels + newChannelIndex] = (signed short)(sumInteger[newChannelIndex] / channelSumCount[newChannelIndex]);
		sumInteger[newChannelIndex] = 0;
		break;
	    case SND_FORMAT_LINEAR_32:
		((signed long int *) outPtr)[frame * newNumChannels + newChannelIndex] = (signed long int)(sumDouble[newChannelIndex] / channelSumCount[newChannelIndex]);
		sumDouble[newChannelIndex] = 0;
	    case SND_FORMAT_FLOAT:
		((float *) outPtr)[frame * newNumChannels + newChannelIndex] = (float)(sumFloat[newChannelIndex] / channelSumCount[newChannelIndex]);
		sumFloat[newChannelIndex] = 0;
		break;
	    case SND_FORMAT_DOUBLE:
		((double *) outPtr)[frame * newNumChannels + newChannelIndex] = (double)(sumDouble[newChannelIndex] / channelSumCount[newChannelIndex]);
		sumDouble[newChannelIndex] = 0;
		break;
	    default:
		NSLog(@"SndChannelDecrease: can\'t decrease channels of format %d samples\n", dataFormat);
	    }
	} // each new channel.
    }  // each frame
    free(sumInteger);
    free(sumFloat);
    free(sumDouble);
    free(channelSumCount);
}

// endian-agnostic, as all formats are cast to memory pointers and duplicated as memory regions.
// dataFormat is the same going in and going out.
// This is capable of in place conversion if inPtr and outPtr are the same.
// TODO Perhaps a good candidate for AltiVec optimisation
void SndChannelMap(void *inPtr, void *outPtr, long numberOfSampleFrames, int oldNumChannels, int newNumChannels, SndSampleFormat dataFormat, short *map)
{
    int newChanIndex;
    long frame; // TODO frames should be unsigned long, not signed, but this makes testing a decrementing index at or below zero impossible.
    int sampleWidth = SndSampleWidth(dataFormat);

#if DEBUG_CHANNEL_MAPPING
    for(newChanIndex = 0; newChanIndex < newNumChannels; newChanIndex++)
        NSLog(@"map[%d] = %d\n", newChanIndex, map[newChanIndex]);
#endif
        
    for (frame = numberOfSampleFrames - 1; frame >= 0; frame--) { /* main slog backwards through the sound */
        /* the number of new channels to create */
        for (newChanIndex = newNumChannels - 1; newChanIndex >= 0; newChanIndex--) {
            char *outFramePtr = (char *) outPtr + (frame * newNumChannels + newChanIndex) * sampleWidth;
                
            if(map[newChanIndex] < 0)
                memset(outFramePtr, 0, sampleWidth);
            else {
                char *samplePtr = (char *) inPtr + (frame * oldNumChannels + map[newChanIndex]) * sampleWidth;

                // copy the sampleWidth number of bytes into the new location, this avoids endian decisions.
                memcpy(outFramePtr, samplePtr, sampleWidth);
            }
        }
    }
}

// Check channel count -- if we need to increase the number of channels from 1 to
// 2, or 4, we have hopefully got enough data malloced in *toSound to duplicate pairs
// of samples.
// TODO remove either fromSampleData: or toSampleData: parameter and directly read from or write to
// SndAudioBuffer's data
- (int) changeFromChannelCount: (int) oldNumChannels
                fromSampleData: (void *) inPtr
                toChannelCount: (int) newNumChannels
                  toSampleData: (void *) outPtr
                    frameCount: (unsigned int) numberOfSampleFrames
                    dataFormat: (SndSampleFormat) theDataFormat
{
#if FIXED_CHANNEL_MAPPING  // If malloc proves to be too processor heavy 
    short channelMap[MAX_CHANNEL_MAPPING];

    if(newNumChannels > MAX_CHANNEL_MAPPING)
	NSLog(@"Channels to be mixed %d exceeds maximum number of channels %d", newNumChannels, MAX_CHANNEL_MAPPING);
#else
    short *channelMap; // TODO either pass this in or use the speakerConfiguration ivar.
#endif
    
    if ((newNumChannels > oldNumChannels) && (newNumChannels % oldNumChannels == 0)) {
#if !FIXED_CHANNEL_MAPPING
        if((channelMap = malloc(newNumChannels * sizeof(short))) == NULL)
            NSLog(@"Unable to malloc channelMap for %d channels\n", newNumChannels);
#endif

	if(oldNumChannels == 2 && newNumChannels > 2) {
            unsigned int chanIndex;
                
            // TODO this is totally KLUDGED! CHANGE CHANGE!
            // We should check if we have a ivar indicating a specific speaker configuration/channel arrangement.
            // TODO Mapping onto a center channel should be done by mixing L+R down to the channel before all others.
            // Perhaps SndChannelMap should replace SndChannelIncrease/Decrease decision with a channelMap derivation 
            // and use SndChannelDecrease as a means to decrease during mapping.
            channelMap[0] = 0;
            channelMap[1] = 1;
            // [self stereoChannels: channelMap];
            // Silence the remaining channels.
            for(chanIndex = 2; chanIndex < newNumChannels; chanIndex++)
                channelMap[chanIndex] = -1;
        }
        else {
            unsigned int oldChanIndex, newChanIndex;
            unsigned int newChansPerOld = newNumChannels / oldNumChannels; /* multiply factor - number of new channels per original one */

            // create the channelMap duplicating the old index every newChansPerOld 
            for (oldChanIndex = 0; oldChanIndex < oldNumChannels; oldChanIndex++)
                for (newChanIndex = 0; newChanIndex < newChansPerOld; newChanIndex++)
                    channelMap[oldChanIndex * newChansPerOld + newChanIndex] = oldChanIndex;
        }
        SndChannelMap(inPtr, outPtr, numberOfSampleFrames, oldNumChannels, newNumChannels, format.dataFormat, channelMap);
#if !FIXED_CHANNEL_MAPPING
        free(channelMap);
#endif
    }
    else if ((oldNumChannels > newNumChannels) && (oldNumChannels % newNumChannels == 0)) {
	unsigned int oldChanIndex, newChanIndex;

#if !FIXED_CHANNEL_MAPPING
	if((channelMap = malloc(oldNumChannels * sizeof(short))) == NULL)
            NSLog(@"Unable to malloc channelMap for %d channels\n", oldNumChannels);
#endif

	// NSLog(@"channel mapping old %d to new %d\n", oldNumChannels, newNumChannels);
	// create the channelMap duplicating the new indexes in sequence
	newChanIndex = 0;
	for (oldChanIndex = 0; oldChanIndex < oldNumChannels; oldChanIndex++) {
	    channelMap[oldChanIndex] = newChanIndex++;
	    if(newChanIndex >= newNumChannels)
		newChanIndex = 0;
	    // NSLog(@"channelMap[%d] = %d\n", oldChanIndex, channelMap[oldChanIndex]);
	}
		
	/* channel reduction will have already been done by resample routine if the sampling rate was changed */
	SndChannelDecrease(inPtr, outPtr, numberOfSampleFrames, oldNumChannels, newNumChannels, theDataFormat, channelMap);
#if !FIXED_CHANNEL_MAPPING
        free(channelMap);
#endif
    }
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

int SndChangeSampleType(void *fromPtr, void *toPtr, SndSampleFormat fromDataFormat, SndSampleFormat toDataFormat, long sampleCount)
{
    long i;
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
            default:
                /* that should be all the common ones. Maybe aLaw too? */
		CONVERTFORMATERR(fromDataFormat, toDataFormat);
                return SND_ERR_BAD_FORMAT;
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
            default:
                /* that should be all the common ones. Maybe aLaw too? */
		CONVERTFORMATERR(fromDataFormat, toDataFormat);
                return SND_ERR_BAD_FORMAT;
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
            default:
                /* that should be all the common ones. Maybe aLaw too? */
		CONVERTFORMATERR(fromDataFormat, toDataFormat);
                return SND_ERR_BAD_FORMAT;
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
            default:
                /* that should be all the common ones. Maybe aLaw too? */
		CONVERTFORMATERR(fromDataFormat, toDataFormat);
                return SND_ERR_BAD_FORMAT;
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
            default:
                /* that should be all the common ones. Maybe aLaw too? */
		CONVERTFORMATERR(fromDataFormat, toDataFormat);
                return SND_ERR_BAD_FORMAT;
	    }
	    break;

	case SND_FORMAT_FLOAT:
	    switch(toDataFormat) {
	    case SND_FORMAT_DOUBLE:
		LOOP_BACKWARD_THRU_SOUND {
		    ((double *)toPtr)[i] = (double)(((float *) fromPtr)[i]);
		}
		break;
            default:
                /* that should be all the common ones. Maybe aLaw too? */
		CONVERTFORMATERR(fromDataFormat, toDataFormat);
                return SND_ERR_BAD_FORMAT;
	    }
	    break;
	    
	default:
	    /* that should be all the common ones. Maybe aLaw too? */
	    CONVERTFORMATERR(fromDataFormat, toDataFormat);
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
            default:
                /* that should be all the common ones. Maybe aLaw too? */
		CONVERTFORMATERR(fromDataFormat, toDataFormat);
                return SND_ERR_BAD_FORMAT;
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
            default:
                /* that should be all the common ones. Maybe aLaw too? */
		CONVERTFORMATERR(fromDataFormat, toDataFormat);
                return SND_ERR_BAD_FORMAT;
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
            default:
                /* that should be all the common ones. Maybe aLaw too? */
		CONVERTFORMATERR(fromDataFormat, toDataFormat);
                return SND_ERR_BAD_FORMAT;
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
            default:
                /* that should be all the common ones. Maybe aLaw too? */
		CONVERTFORMATERR(fromDataFormat, toDataFormat);
                return SND_ERR_BAD_FORMAT;
	    }
	    break;

	case SND_FORMAT_FLOAT:
	    switch(fromDataFormat) {
	    case SND_FORMAT_DOUBLE:
		LOOP_FORWARD_THRU_SOUND {
		    ((float *) toPtr)[i] = ((double *) fromPtr)[i];
		}
		break;
            default:
                /* that should be all the common ones. Maybe aLaw too? */
		CONVERTFORMATERR(fromDataFormat, toDataFormat);
                return SND_ERR_BAD_FORMAT;
	    }
	    break;

	default:
	    CONVERTFORMATERR(fromDataFormat, toDataFormat);
	    return SND_ERR_BAD_FORMAT;
	}
    }
    return SND_ERR_NONE;
}

- convertToSampleFormat: (SndSampleFormat) toDataFormat
{
    if (format.dataFormat != toDataFormat) {
	long numOfSamples = [self lengthInSampleFrames] * [self channelCount];
	NSMutableData *toData = [NSMutableData dataWithLength: numOfSamples * SndSampleWidth(toDataFormat)];
	void *fromDataPtr = [data mutableBytes];
	void *toDataPtr = [toData mutableBytes];
	int error = SndChangeSampleType(fromDataPtr, toDataPtr, format.dataFormat, toDataFormat, numOfSamples);

	if (error == SND_ERR_BAD_FORMAT)
	    return nil;
	
	[data release];
	data = [toData retain];
	format.dataFormat = toDataFormat;
	// NSLog(@"convert: %@", self);
    }
    return self;
}

- convertToSampleFormat: (SndSampleFormat) toDataFormat
	   channelCount: (int) toChannelCount
{
    if(format.channelCount != toChannelCount) {
	unsigned int sampleFrames = [self lengthInSampleFrames];
	long toNumOfSamples = sampleFrames * toChannelCount;
	NSMutableData *toData = [NSMutableData dataWithLength: toNumOfSamples * SndSampleWidth(format.dataFormat)];
	void *fromDataPtr = [data mutableBytes];
	void *toDataPtr = [toData mutableBytes];
        int error = [self changeFromChannelCount: format.channelCount
                                  fromSampleData: fromDataPtr
                                  toChannelCount: toChannelCount
                                    toSampleData: toDataPtr
                                      frameCount: sampleFrames
                                      dataFormat: format.dataFormat];

	if(error != SND_ERR_NONE)
	    return nil;
	
	[data release];
	data = [toData retain];
	format.channelCount = toChannelCount;
    }    
    return [self convertToSampleFormat: toDataFormat];
}

- convertToSampleFormat: (SndSampleFormat) toDataFormat
	   channelCount: (int) toChannelCount
	   samplingRate: (double) toSampleRate
	 useLargeFilter: (BOOL) largeFilter
      interpolateFilter: (BOOL) interpFilter
 useLinearInterpolation: (BOOL) fastInterpolation
{
    if (format.sampleRate != toSampleRate) {
	double stretchFactor = toSampleRate / format.sampleRate;
	long sampleFrames = [self lengthInSampleFrames];
	long numOfSamples = sampleFrames * format.channelCount;
	NSMutableData *toData = [NSMutableData dataWithLength: numOfSamples * stretchFactor * SndSampleWidth(SND_FORMAT_LINEAR_16)];
	void *fromDataPtr = [data mutableBytes];
	void *toDataPtr = [toData mutableBytes];
	SndFormat toSoundFormat = { SND_FORMAT_LINEAR_16, 0, format.channelCount, toSampleRate };
	SndFormat fromSoundFormat = { format.dataFormat, sampleFrames, format.channelCount, format.sampleRate }; 

	SndChangeSampleRate(fromSoundFormat, fromDataPtr, &toSoundFormat, (short *) toDataPtr, largeFilter, interpFilter, fastInterpolation);

	// replace the old data with the new sample rate converted data.
	[data release];
	data = [toData retain];

	// assign dataFormat here in case we don't do any conversion using SndChangeSampleType() below.
	format.dataFormat = toSoundFormat.dataFormat;
	format.sampleRate = toSoundFormat.sampleRate; // reassign it in case SndChangeSampleRate modifies the rate.
	format.frameCount = toSoundFormat.frameCount; // The resampling will produce a different number of frames.
    }
    
    // The sample rate converted sample data is now ready for channel/format conversion
    return [self convertToSampleFormat: toDataFormat channelCount: toChannelCount];
}

- (long) convertBytes: (void *) fromDataPtr
       intoFrameRange: (NSRange) bufferFrameRange
           fromFormat: (SndSampleFormat) fromDataFormat
	 channelCount: (int) fromChannelCount
         samplingRate: (double) fromSampleRate
{
    int toChannelCount = [self channelCount];
    int toDataFormat = [self dataFormat];
    double toSampleRate = [self samplingRate];
    void *toDataPtr = [self bytes] + bufferFrameRange.location * [self frameSizeInBytes];
    unsigned long toSampleFrames = bufferFrameRange.length;
    // unless we convert sample rates we read and write the same number of frames.
    long fromSampleFrames = toSampleFrames;
    unsigned long lastModifiedFrame;
    int error;

    if(fromSampleRate != toSampleRate) {
	// do sampling rate conversion
	BOOL largeFilter = NO, interpFilter = YES, linearInterpolation = NO;
	double stretchFactor = toSampleRate / fromSampleRate;
	SndFormat fromSoundFormat;
	// If we change rate, output format is always linear 16 (due to resample()).
	// TODO, resample needs to be modified so that conversions are in SND_FORMAT_FLOAT.
	// We keep the channel count the same, since we will do channel conversion later.
	// We would only benefit doing the conversion here if we converting down to a mono source (nowdays unlikely)
	// or from multi-channel to stereo.
	SndFormat toSoundFormat = { SND_FORMAT_LINEAR_16, 0, fromChannelCount, toSampleRate };

	fromSampleFrames = toSampleFrames / stretchFactor;  // adjust the number of frames to consume.
	//NSLog(@"convertBytes: from format %d channels %d sample rate %lf frames %ld, to %@\n",
	//    fromDataFormat, fromChannelCount, fromSampleRate, fromSampleFrames, self);
	
	fromSoundFormat.dataFormat = fromDataFormat;
	fromSoundFormat.frameCount = fromSampleFrames;
	fromSoundFormat.channelCount = fromChannelCount;
	fromSoundFormat.sampleRate = fromSampleRate;
	
	SndChangeSampleRate(fromSoundFormat, fromDataPtr, &toSoundFormat, (short *) toDataPtr, largeFilter, interpFilter, linearInterpolation);
	
	// assign dataFormat here in case we don't do any conversion using SndChangeSampleType() below.
	fromDataFormat = format.dataFormat = toSoundFormat.dataFormat;

	// replace the old data with the new sample rate converted data.
	fromDataPtr = toDataPtr; // This will then do the channel count conversion in place, which is ok by -changeFromChannelCount:.
#if 0
	channelCount = toSoundFormat.channelCount;  // set the channel so we can describe the modified buffer.
	NSLog(@"convertBytes: now %@\n", self);
	channelCount = toChannelCount;
#endif
    }

    if(fromChannelCount != toChannelCount) {
        error = [self changeFromChannelCount: fromChannelCount
                              fromSampleData: fromDataPtr
                              toChannelCount: toChannelCount
                                toSampleData: toDataPtr
                                  frameCount: toSampleFrames
                                  dataFormat: fromDataFormat];

	if(error != SND_ERR_NONE)
	    return 0;
	
	fromDataPtr = toDataPtr; // This will then do the sample type conversion in place, which is ok by SndChangeSampleType().
    }

    if(fromDataFormat != toDataFormat) {
	// NSLog(@"convertBytes: converting from format %d to format %d frames %ld\n", fromDataFormat, toDataFormat, toSampleFrames, self);

	error = SndChangeSampleType(fromDataPtr, toDataPtr, fromDataFormat, toDataFormat, toSampleFrames * toChannelCount);

	if(error != SND_ERR_NONE)
	    return 0;
	
	// Reassign dataFormat in case it was changed by the sample rate changing code.
	format.dataFormat = toDataFormat;
    }
    lastModifiedFrame = (bufferFrameRange.location + bufferFrameRange.length);
    format.frameCount = MAX(lastModifiedFrame, format.frameCount);   // extend the frame count if we modify a greater region.

    // NSLog(@"Final converted buffer %@\n", self);
    
    return fromSampleFrames;
}

- convertToFormat: (SndFormat) newFormat
{
    return [self convertToSampleFormat: newFormat.dataFormat
			  channelCount: newFormat.channelCount
			  samplingRate: newFormat.sampleRate
			useLargeFilter: YES
		     interpolateFilter: YES
		useLinearInterpolation: NO];
}

// Create a new buffer of the same number of samples as the receiver
// converted to the new format, sampling rate and channel count.
// returns the new buffer instance.
- (SndAudioBuffer *) audioBufferConvertedToFormat: (SndSampleFormat) toDataFormat
				     channelCount: (int) toChannelCount
				     samplingRate: (double) toSamplingRate
{
    unsigned int sampleFrames = [self lengthInSampleFrames];
    // We do the channel conversion with the current data format, then convert the format afterwards.
    SndAudioBuffer *newBuffer = [SndAudioBuffer audioBufferWithDataFormat: format.dataFormat
							     channelCount: toChannelCount
							     samplingRate: toSamplingRate
							       frameCount: sampleFrames];
    void *fromDataPtr = [data mutableBytes];
    void *toDataPtr = [newBuffer bytes];
    BOOL convertedSomething = NO;

    // TODO need to do sample conversion.
    if(format.sampleRate != toSamplingRate) {
	// TODO should do sampling rate conversion
	NSLog(@"Sampling rate conversion %lf to %lf not done! Needs implementation.\n", format.sampleRate, toSamplingRate);
    }
    
    // do conversion into the new data buffer.
    if(format.channelCount != toChannelCount) {
	int error = [self changeFromChannelCount: format.channelCount
				  fromSampleData: fromDataPtr
				  toChannelCount: toChannelCount
				    toSampleData: toDataPtr
				      frameCount: sampleFrames
				      dataFormat: format.dataFormat];

	if(error != SND_ERR_NONE) {
	    NSLog(@"Unable to convert from %d channels to %d channels", format.channelCount, toChannelCount);
	    return nil;
	}
	convertedSomething = YES;
    }

    if(!convertedSomething) {
	[newBuffer copyDataFromBuffer: self];
    }
    
    // newBuffer is already autoreleased but we retain and autorelease it again so that the current thread
    // will autorelease it. Convert the data format if necessary.
    return [[[newBuffer convertToSampleFormat: toDataFormat] retain] autorelease];
}

@end
