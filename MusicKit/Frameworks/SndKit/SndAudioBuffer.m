/*
  $Id$

  Description:

  Original Author: SKoT McDonald, <skot@tomandandy.com>, tomandandy music inc.

  12 Feb 2001, Copyright (c) 2001 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/
#import "SndAudioBuffer.h"

#ifdef __VEC__
#import <vecLib/vecLib.h>
#endif

@implementation SndAudioBuffer

////////////////////////////////////////////////////////////////////////////////
// 
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithFormat: (SndSoundStruct*) f data: (void*) d
{
    SndAudioBuffer *ab = [[SndAudioBuffer alloc] init];
    [ab initWithFormat: f data: d];    
    //NSLog(@"SndAudioBuffer audiobufferwithformat: format: %d, dataSize: %d, samplingRate: %d, channelCount: %d\n",
    //    ab->formatSnd.dataFormat, ab->formatSnd.dataSize, ab->formatSnd.samplingRate, ab->formatSnd.channelCount);
    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWrapperAroundSNDStreamBuffer: (SNDStreamBuffer*) cBuff
{
    SndAudioBuffer *ab = [[SndAudioBuffer alloc] init];
    ab->bOwnsData = FALSE;
    [ab initWithFormat: &(cBuff->streamFormat) data: cBuff->streamData];
    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithSndSeg: (Snd*) snd range: (NSRange) r
{
    SndAudioBuffer *ab = [[SndAudioBuffer alloc] init];

    // PUT THIS IN AN INIT FN!!!!

    memcpy(&(ab->formatSnd),[snd soundStruct], sizeof(SndSoundStruct));
    {
        int samSize       = [ab multiChannelSampleSizeInBytes];
        int lengthInBytes = r.length * samSize;
        ab->formatSnd.dataSize = lengthInBytes;
        ab->data  = [snd data] + samSize * r.location;
	//NSLog(@"SndAudioBuffer: creating wrapper with samSize %d, lengthInBytes %d, offset %d\n",
        //    samSize,lengthInBytes,samSize * r.location);
	//NSLog(@"SndAudioBuffer: format: %d, dataSize: %d, samplingRate: %d, channelCount: %d\n",
	//    ab->formatSnd.dataFormat, ab->formatSnd.dataSize, ab->formatSnd.samplingRate, ab->formatSnd.channelCount);
    }
    ab->bOwnsData = FALSE;

    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// audioBufferWithFormat:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithFormat: (SndSoundStruct*) f duration: (double) timeInSec
{
    SndAudioBuffer *ab = [[SndAudioBuffer alloc] init];
    long oldLength = f->dataSize;
    long samWidth = SndSampleWidth(f->dataFormat);
    f->dataSize = (f->channelCount) * 
                  samWidth *
                  (long)((f->samplingRate) * timeInSec);
                          
    [ab initWithFormat: f data: NULL];
    f->dataSize = oldLength;
    
    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
    if (bOwnsData)
        free(data);
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- initWithFormat: (SndSoundStruct*) f data: (void*) d
{
    memcpy(&formatSnd, f, sizeof(SndSoundStruct));

    if (data != NULL && bOwnsData) {
        // NSLog(@"freeing\n");
        free(data);
        data = NULL;
    }

    if (d == NULL) {
        if((data = malloc(formatSnd.dataSize)) == NULL)
            NSLog(@"Unable to malloc %d bytes\n", formatSnd.dataSize);
        memset(data, 0, formatSnd.dataSize);
        bOwnsData = TRUE;
    }
    else {
        data = d;
        bOwnsData = FALSE;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// zero
////////////////////////////////////////////////////////////////////////////////

- zero
{
    if (bOwnsData)
        memset(data, 0, formatSnd.dataSize);
    else
        NSLog(@"SndAudioBuffer::zero: tried zeroing memory I didn't own!");
    return self;
}

- (void) zeroForeignBuffer
{
    memset(data, 0, formatSnd.dataSize);
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- (int) dataFormat
{
    return formatSnd.dataFormat;
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- (void*) data
{
    return data;
}

- (int) channelCount
{
    return formatSnd.channelCount;
}

////////////////////////////////////////////////////////////////////////////////
// Note: This is only an interim proof of concept implementation and doesn't manage all 
// combinations of formats. Instead of adding extra formats, this code should be
// changed to use a version of SndConvertSoundInternal() that has been suitably modified
// to accept presupplied buffers (SndConvertSoundInternal currently allocates them itself).
////////////////////////////////////////////////////////////////////////////////

- mixWithBuffer: (SndAudioBuffer*) buff fromStart: (long) start toEnd: (long) end
{
    long frameCount;
    
    // SndPrintStruct(&formatSnd); // for checking the formatSnd is valid

    if (end > formatSnd.dataSize / sizeof(float))
        end = formatSnd.dataSize / sizeof(float);

    frameCount = end - start;
    
    if ([self dataFormat] == SND_FORMAT_FLOAT) {

        int selfNumChannels = formatSnd.channelCount;
        int buffNumChannels = [buff channelCount];
        int i;

        switch ([buff dataFormat]) {

// SOURCE BUFFER IS 32-BIT FLOAT

            case SND_FORMAT_FLOAT: {
                
                float *in  = (float*) [buff data];
                float *out = (float*) data;

                if (selfNumChannels == buffNumChannels) {
#ifdef __VEC__
/* FIXME need to do extra check to ensure altivec is supported at runtime */
                    vadd(in, 1,out+start,1,out+start,1,frameCount * buffNumChannels);
#else
                    for (i = 0; i < frameCount * buffNumChannels; i++) {
                        out[i+start] += in[i]; // interleaving automatically taken care of!
                    }
#endif
                }
                else if (selfNumChannels == 2) {
                    switch (buffNumChannels) {
                        case 1:
                            for (i = 0; i < frameCount; i++) {
                                out[i+start]   += in[i]; // interleaving automatically taken care of!
                                out[i*2+start] += in[i]; // interleaving automatically taken care of!
                            }
                            break;
                        default:
                            NSLog(@"Mix buffer - not format handled (yet)");
                    }
                }
                else if (selfNumChannels == 1) {
                    switch (buffNumChannels) {
                        case 2:
                            for (i = 0; i < frameCount; i++) {
                                out[i+start] += in[i*2]; // copy left channel into output buffer
                            }
                            break;
                        default:
                            NSLog(@"Mix buffer - not format handled (yet)");
                    }
                }
                break;
            }

// SOURCE BUFFER IS 16-BIT
                
            case SND_FORMAT_LINEAR_16: {
                
                short *in  = (short*) [buff data];
                float *out = (float*) data, f;
                start = start * selfNumChannels;

                if (selfNumChannels == buffNumChannels) {
                    for (i = 0; i < frameCount * buffNumChannels; i++) {
                        f = (float) in[i] / 32768.0f;
                        out[i+start] += f; // interleaving automatically taken care of!
                    }
                }
                else if (buffNumChannels == 1)  {
                    for (i = 0; i < frameCount; i++) {
                        f = (float) in[i] / 32768.0f;
                        out[i*2+start]   += f; // interleaving automatically taken care of!
                        out[i*2+start+1] += f; // interleaving automatically taken care of!
                    }
                }
                else if (buffNumChannels == 2)  {
                    for (i = 0; i < frameCount; i++) {
                        f = (float) in[i*2] / 32768.0f;
                        out[i+start] += f; // interleaving automatically taken care of!
                    }
                }
                break;
            }
            default:
                NSLog(@"SndAudioBuffer::mixWithBuffer: WARN: unsupported format %d", [buff dataFormat]);
        }

    }
    else {
        NSLog(@"SndAudioBuffer::mixWithBuffer: WARN: miss-matched buffer formats - write converter");
    }
    return self;
}


- mixWithBuffer: (SndAudioBuffer*) buff
{
    // NSLog(@"buffer = %x\n", buff);
    // NSLog(@"buffer to mix: %s", SndStructDescription(&(buff->formatSnd)));
    
    [self mixWithBuffer: buff fromStart: 0 toEnd: formatSnd.dataSize / [self multiChannelSampleSizeInBytes]];
    
    return self;
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- copy
{
    SndAudioBuffer *to = [SndAudioBuffer audioBufferWithFormat: &formatSnd data: NULL];
    memcpy(to->data, data, formatSnd.dataSize);
    return to;
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- copyData: (SndAudioBuffer*) from
{
    if (from != nil) {
      if (from->formatSnd.dataSize == formatSnd.dataSize)
        memcpy(data, from->data, formatSnd.dataSize);
      else {
        NSLog(@"Buffers are different lengths - need code to handle this case!");
        // TO DO!
      }
    }
    else
        NSLog(@"AudioBuffer::copyData: ERR: param 'from' is nil!");
    return self;
}

- (int) multiChannelSampleSizeInBytes
{
    return formatSnd.channelCount * SndSampleWidth([self dataFormat]);
}

////////////////////////////////////////////////////////////////////////////////
// @lengthInSamples
////////////////////////////////////////////////////////////////////////////////

- (long) lengthInSamples
{
    return formatSnd.dataSize / [self multiChannelSampleSizeInBytes];
}

- (long) lengthInBytes
{
  return formatSnd.dataSize;
}

////////////////////////////////////////////////////////////////////////////////
// @duration
////////////////////////////////////////////////////////////////////////////////

- (double) duration
{
    return (double) [self lengthInSamples] / (double) formatSnd.samplingRate;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

- (double) samplingRate
{
    return (double) formatSnd.samplingRate;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

- (SndSoundStruct*) format
{
  return &formatSnd;
}


////////////////////////////////////////////////////////////////////////////////

@end
