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

@implementation SndAudioBuffer

////////////////////////////////////////////////////////////////////////////////
// 
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithFormat: (SndSoundStruct*) f data: (void*) d
{
    SndAudioBuffer *ab = [[SndAudioBuffer alloc] init];
    [ab initWithFormat: f data: NULL];    
    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWrapperAroundSNDStreamBuffer: (SNDStreamBuffer*) cBuff
{
    SndAudioBuffer *ab = [[SndAudioBuffer alloc] init];
    [ab initWithFormat: &(cBuff->streamFormat) data: cBuff->streamData];
    ab->bOwnsData = FALSE;
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
    }
    ab->bOwnsData = FALSE;

    return [ab autorelease];
}

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

- zero
{
    if (bOwnsData)
        memset(data, 0, formatSnd.dataSize);
    else
        NSLog(@"SndAudioBuffer::zero: tried zeroing memory I didn't own!");
    return self;
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
//
////////////////////////////////////////////////////////////////////////////////

- mixWithBuffer: (SndAudioBuffer*) buff fromStart: (long) start toEnd: (long) end
{
    long l;
    
    // SndPrintStruct(&formatSnd); // for checking the formatSnd is valid
    
    if (end > formatSnd.dataSize / sizeof(float))
        end = formatSnd.dataSize / sizeof(float);

    l = end - start;
    
    if ([self dataFormat] == SND_FORMAT_FLOAT) {

        int selfNumChannels = formatSnd.channelCount;
        int buffNumChannels = [buff channelCount];
        int i;

        switch ([buff dataFormat]) {

// SOURCE BUFFER IS 32-BIT FLOAT

            case SND_FORMAT_FLOAT: {
                
                float *in  = (float*) [buff data];
                float *out = (float*) data;

//                NSLog(@"Mixing client output buffer with main output buff, (%f)",in[100]);

                if (selfNumChannels == buffNumChannels) {
                    for (i = 0; i < l; i++) {
                        out[i+start] += in[i]; // interleaving automatically taken care of!
                    }
                }
                else if (selfNumChannels == 2) {
                    switch (buffNumChannels) {
                        case 1:
                            for (i = 0; i < l; i++) {
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
                            for (i = 0; i < l; i++) {
                                out[i+start] += in[i*2]; // copy left channel into output buffer
                            }
                            break;
                        default:
                            NSLog(@"Mix buffer - not format handled (yet)");
                    }
                }
            }
                break;

// SOURCE BUFFER IS 16-BIT
                
            case SND_FORMAT_LINEAR_16: {
                
                short *in  = (short*) [buff data];
                float *out = (float*) data, f;

                if (selfNumChannels == buffNumChannels) {

                    for (i = 0; i < l; i++) {
                        f = (float) in[i] / 32768.0f;
                        out[i+start] += f; // interleaving automatically taken care of!
                    }
                }
                else if (buffNumChannels == 1)  {
                    for (i = 0; i < l; i++) {
                        f = (float) in[i] / 32768.0f;
                        out[i*2+start]   += f; // interleaving automatically taken care of!
                        out[i*2+start+1] += f; // interleaving automatically taken care of!
                    }
                }
                else if (buffNumChannels == 2)  {
                    for (i = 0; i < l; i++) {
                        f = (float) in[i*2] / 32768.0f;
                        out[i+start] += f; // interleaving automatically taken care of!
                    }
                }
            }
                break;
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
    
    [self mixWithBuffer: buff fromStart: 0 toEnd: formatSnd.dataSize / sizeof(float)];
    
    // TO DO!
    // 1. Ensure buff is in same format as self, if not
    //  CONVERT INTO A LOCAL COPY!! (don't convert buff)

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
    if (from->formatSnd.dataSize == formatSnd.dataSize)
        memcpy(data, from->data, formatSnd.dataSize);
    else {
        NSLog(@"Buffers are different lengths - need code to handle this case!");
        // TO DO!
    }
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

@end
