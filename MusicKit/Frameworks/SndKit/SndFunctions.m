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
WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES
OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD
PARTIES RIGHTS.

If a court finds that we are liable for death or personal injury caused by our
negligence our liability shall be unlimited.

WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS
OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR
POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE
NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED
DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND
CONDITIONS OF THIS AGREEMENT.

******************************************************************************/

#ifndef GNUSTEP
# ifndef WIN32
#  import <libc.h>
# else
#  import <stdio.h>
#  import <fcntl.h>
#  import <Winsock.h>
#  import <malloc.h>
#  import <io.h>
# endif
#else
# import <fcntl.h>
#endif

#import <math.h>
#import <Foundation/Foundation.h>

#import "SndFunctions.h"
#import "SndMuLaw.h"
#import "SndResample.h"

#define SNDREADCHUNKSIZE 256*1024   // Number of st_sample_t samples to read into a buffer.
#ifdef WIN32
#define LASTCHAR        '\\'
#else
#define LASTCHAR        '/'
#endif

int SndSampleWidth(SndSampleFormat format)
{
    switch (format) {
	case SND_FORMAT_MULAW_8:
	case SND_FORMAT_LINEAR_8:
	    return 1;
	    break;
	case SND_FORMAT_EMPHASIZED:
	case SND_FORMAT_COMPRESSED:
	case SND_FORMAT_COMPRESSED_EMPHASIZED:
	case SND_FORMAT_DSP_DATA_16:
	case SND_FORMAT_LINEAR_16:
	    return 2;
	    break;
	case SND_FORMAT_LINEAR_24:
	case SND_FORMAT_DSP_DATA_24:
	    return 3;
	    break;
	case SND_FORMAT_LINEAR_32:
	case SND_FORMAT_DSP_DATA_32:
	    return 4;
	    break;
	case SND_FORMAT_FLOAT:
	    return sizeof(float);
	    break;
	case SND_FORMAT_DOUBLE:
	    return sizeof(double);
	    break;
	default: /* just in case */
	    return 2;
	    break;
    }
    /* never reaches here */
    return 2;
}

int SndFrameSize(SndFormat format)
{
    return SndSampleWidth(format.dataFormat) * format.channelCount;
}

NSString *SndFormatName(SndSampleFormat dataFormat, BOOL verbose)
{
    switch(dataFormat) {
	case SND_FORMAT_MULAW_8:
	case SND_FORMAT_MULAW_SQUELCH:
	    return @"8-bit muLaw";
	case SND_FORMAT_LINEAR_8:
	    return @"8-bit Linear";
	case SND_FORMAT_LINEAR_16:
	    return verbose ? @"16-bit Integer (2's complement, big endian)" : @"16-bit Linear";
	case SND_FORMAT_LINEAR_24:
	    return verbose ? @"24-bit Integer (2's complement, big endian)" : @"24-bit Linear";
	case SND_FORMAT_LINEAR_32:
	    return verbose ? @"32-bit Integer (2's complement, big endian)" : @"32-bit Linear";
	case SND_FORMAT_FLOAT:
	    return verbose ? @"Signed 32-bit floating point" : @"32-bit Floating Point";
	case SND_FORMAT_DOUBLE:
	    return verbose ? @"Signed 64-bit floating point" : @"64-bit Floating Point";
	case SND_FORMAT_MP3:
	    return verbose ? @"MPEG 1 Layer 3 Compressed" : @"MP3 Compressed";
	case SND_FORMAT_INDIRECT:
	    return @"Fragmented";
	default:
	    return [NSString stringWithFormat: @"Unknown format %d", dataFormat];
    }
}

double SndMaximumAmplitude(SndSampleFormat type)
{
    switch (type) {
	case SND_FORMAT_LINEAR_8:
	    return 128.0;
	case SND_FORMAT_LINEAR_24:
	case SND_FORMAT_DSP_DATA_24:
	    return 8388608.0;
	case SND_FORMAT_LINEAR_32:
	case SND_FORMAT_DSP_DATA_32:
	    return 2147483648.0;
	case SND_FORMAT_MULAW_8:
	    return 32768.0;
	case SND_FORMAT_MP3:
	case SND_FORMAT_FLOAT:
	case SND_FORMAT_DOUBLE:
	    return 1.0;
	case SND_FORMAT_LINEAR_16:
	case SND_FORMAT_EMPHASIZED:
	case SND_FORMAT_COMPRESSED:
	case SND_FORMAT_COMPRESSED_EMPHASIZED:
	case SND_FORMAT_DSP_DATA_16:
	default:
	    return 32768.0;
    }
}

// Given the data size in bytes, the number of channels and the data format, return the number of samples.
int SndBytesToFrames(int byteCount, int channelCount, SndSampleFormat dataFormat)
{
    return (int)(byteCount / (channelCount * SndSampleWidth(dataFormat)));
}

long SndFramesToBytes(long frameCount, int channelCount, SndSampleFormat dataFormat)
{
    return (long)(frameCount * channelCount * SndSampleWidth(dataFormat));
}

long SndDataSize(SndFormat format)
{
    return SndFramesToBytes(format.frameCount, format.channelCount, format.dataFormat);
}

SndFormat SndFormatOfSNDStreamBuffer(SNDStreamBuffer *streamBuffer)
{
    SndFormat format = {
        streamBuffer->dataFormat,
        streamBuffer->frameCount,
        streamBuffer->channelCount,
        streamBuffer->sampleRate
    };
    
    return format;
}

float SndConvertDecibelsToLinear(float db)
{
    return (float) pow(10.0, (double) db / 20.0);
}

float SndConvertLinearToDecibels(float lin)
{
    return (float) (20.0 * log10((double) lin));
}

// TODO marked for demolition. Remove when SndSoundStruct is no longer a Snd ivar.
// Replace with the SndFormat frameCount field.
int SndFrameCount(const SndSoundStruct *sound)
{
    SndSoundStruct **ssList;
    SndSoundStruct *theStruct;
    int count = 0, i = 0;
    SndSampleFormat df;
    
    if (!sound) return SND_ERR_NOT_SOUND;
    if (sound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
    df = sound->dataFormat;
    if (df != SND_FORMAT_INDIRECT) /* simple case */
	return SndBytesToFrames(sound->dataSize, sound->channelCount, df);
    /* more complicated */
    ssList = (SndSoundStruct **)sound->dataLocation;
    if (ssList[0]) df = ssList[0]->dataFormat;
    else return 0; /* fragged sound with no frags! */
    while ((theStruct = ssList[i++]) != NULL)
	count += theStruct->dataSize;
    return SndBytesToFrames(count, sound->channelCount, df);
}

NSString *SndFormatDescription(SndFormat format)
{
    return [NSString stringWithFormat: @"(frames: %li duration: %fs dataFormat: %@ samplingRate: %.2f channels: %i)",
	format.frameCount, format.frameCount / format.sampleRate, SndFormatName(format.dataFormat, NO), format.sampleRate, format.channelCount];
}

// TODO marked for demolition. Remove when SndSoundStruct is no longer a Snd ivar.
NSString *SndStructDescription(SndSoundStruct *s)
{
    if(s != NULL) {
	SndFormat f;
	
	f.sampleRate = s->samplingRate;
	f.dataFormat = s->dataFormat;
	f.channelCount = s->channelCount;
	f.frameCount = SndFrameCount(s);
        NSString *message = [NSString stringWithFormat: @"%s location:%d size:%d %@ info:%s\n",
	   (s->magic != SND_MAGIC) ? "(no SND_MAGIC)" : "SND_MAGIC",
	    s->dataLocation, s->dataSize, SndFormatDescription(f), s->info];
        return message;
    }
    else {
        return @"(NULL SndSoundStruct)";
    }
}

// TODO marked for demolition.
void SndPrintStruct(SndSoundStruct *s)
{
    puts([SndStructDescription(s) cString]);
}

int SndPrintFrags(SndSoundStruct *sound)
{
    SndSoundStruct **ssList;
    SndSoundStruct *theStruct;
    int count = 0, i = 0;
    SndSampleFormat df;
    
    if (!sound) return SND_ERR_NOT_SOUND;
    if (sound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
    df = sound->dataFormat;
    if (df != SND_FORMAT_INDIRECT) {
	NSLog(@"not fragmented\n");
	return SND_ERR_NONE;
    }
    /* more complicated */
    ssList = (SndSoundStruct **)sound->dataLocation;
    df = ssList[0]->dataFormat;
    while ((theStruct = ssList[i++]) != NULL) {
	NSLog(@"**** Frag %d: starts at byte %d\n",i-1,count);
	count += theStruct->dataSize;
	NSLog(@"...ends at byte: %d\n",count-theStruct->channelCount*SndSampleWidth(df));
	NSLog(@"channels: %d sample frames: %d samples in tot: %d\n",
	      theStruct->channelCount, theStruct->dataSize/theStruct->channelCount/SndSampleWidth(df),
	      theStruct->dataSize/theStruct->channelCount);
    }
    return SND_ERR_NONE;
}

int SndFree(SndSoundStruct *sound)
{
    SndSoundStruct **ssList;
    SndSoundStruct *theStruct;
    int i = 0;
    
    if (!sound) return SND_ERR_NOT_SOUND;
    if (sound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
    /* simple case: */
    if (sound->dataFormat != SND_FORMAT_INDIRECT) {
	free(sound);
	return SND_ERR_NONE;
    }
    /* more complicated */
    ssList = (SndSoundStruct **)sound->dataLocation;
    while ((theStruct = ssList[i++]) != NULL)
	free(theStruct);
    free(ssList);
    free(sound);
    return SND_ERR_NONE;
}

int SndAlloc(SndSoundStruct **sound, int dataSize, SndSampleFormat dataFormat,
             int samplingRate, int channelCount, int infoSize)
{
    int headerSize = 0;
    int extraInfoBytes;
    
    if (samplingRate < 0) return SND_ERR_BAD_RATE;
    if (channelCount < 1 || channelCount > 16) return SND_ERR_BAD_CHANNEL;
    if (dataSize < 0) return SND_ERR_BAD_SIZE;
    if (infoSize > 16384 || infoSize < 0) return SND_ERR_INFO_TOO_BIG;
    if (dataFormat > SND_FORMAT_DELTA_MULAW_8) return SND_ERR_BAD_FORMAT;
    
    if (infoSize < 4) infoSize = 4;
    extraInfoBytes = infoSize & 3;
    if (extraInfoBytes) extraInfoBytes = 4 - extraInfoBytes;
    headerSize = sizeof(SndSoundStruct) + infoSize + extraInfoBytes - 4;
    /* normal size of header includes 4 info bytes, so I subtract here */
    
    *sound = calloc(headerSize + dataSize, sizeof(char));
    if (!*sound) return SND_ERR_CANNOT_ALLOC;
    
    (*sound)->magic = SND_MAGIC;
    (*sound)->dataLocation = headerSize;
    (*sound)->dataSize = dataSize;
    (*sound)->dataFormat = dataFormat;
    (*sound)->samplingRate = samplingRate;
    (*sound)->channelCount = channelCount;
    return SND_ERR_NONE;
}

short SndiMulaw(unsigned char mulawValue)
{
    return (short) SndMuLawToLinear(mulawValue);
}

int SndSwapBigEndianSoundToHost(void *dest, void *src, int sampleCount, int channelCount, SndSampleFormat dataFormat)
{
#ifdef __BIG_ENDIAN__
    return SND_ERR_NONE;
#else
    int numBytes = SndSampleWidth(dataFormat);
    int i;
    int samples = sampleCount * channelCount;
    if (numBytes == 1) return SND_ERR_NONE;
    if (numBytes == 2) {
	for (i = 0 ; i < samples; i++) {
	    ((signed short *)dest)[i] = (signed short)ntohs(((signed short *)src)[i]);
	}
	return SND_ERR_NONE;
    }
    if (dataFormat == SND_FORMAT_FLOAT) {
	for (i = 0 ; i < samples; i++) {
	    SndSwappedFloat toSwap = ((SndSwappedFloat *)src)[i];
	    ((float *)dest)[i] = (float)SndSwapSwappedFloatToHost(toSwap);
	}
	return SND_ERR_NONE;
    }
    if (dataFormat == SND_FORMAT_DOUBLE) {
	for (i = 0 ; i < samples; i++) {
	    SndSwappedDouble toSwap = ((SndSwappedDouble *)src)[i];
	    ((double *)dest)[i] = (double)SndSwapSwappedDoubleToHost(toSwap);
	}
	return SND_ERR_NONE;
    }
    NSLog(@"SndSoundSwap: format not currently supported, sorry.\n");
    return SND_ERR_BAD_FORMAT;
#endif
}

int SndSwapHostToBigEndianSound(void *dest, void *src, int sampleCount, int channelCount, SndSampleFormat dataFormat)
{
#ifdef __BIG_ENDIAN__
    return SND_ERR_NONE;
#else
    int numBytes = SndSampleWidth(dataFormat);
    int i;
    int samples = sampleCount * channelCount;
    if (numBytes == 1) return SND_ERR_NONE;
    if (numBytes == 2) {
	for (i = 0 ; i < samples; i++) {
	    ((signed short *)dest)[i] = (signed short)htons(((signed short *)src)[i]);
	}
	return SND_ERR_NONE;
    }
    if (dataFormat == SND_FORMAT_FLOAT) {
	for (i = 0 ; i < samples; i++) {
	    ((SndSwappedFloat *)dest)[i] =
	    (SndSwappedFloat)SndSwapHostToSwappedFloat(((float *)src)[i]);
	}
	return SND_ERR_NONE;
    }
    if (dataFormat == SND_FORMAT_DOUBLE) {
	for (i = 0 ; i < samples; i++) {
	    ((SndSwappedDouble *)dest)[i] =
	    (SndSwappedDouble)SndSwapHostToSwappedDouble(((double *)src)[i]);
	}
	return SND_ERR_NONE;
    }
    NSLog(@"SndSoundSwap: format not currently supported, sorry.\n");
    return SND_ERR_BAD_FORMAT;
    
#endif
    
}
