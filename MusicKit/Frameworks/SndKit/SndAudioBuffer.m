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

    memcpy(&(ab->format),[snd soundStruct], sizeof(SndSoundStruct));
    {
        int samSize       = [ab multiChannelSampleSizeInBytes];
        int lengthInBytes = r.length * samSize;
        ab->format.dataSize = lengthInBytes;
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
    memcpy(&format, f, sizeof(SndSoundStruct));

    if (data != NULL && bOwnsData) {
        NSLog(@"freeing\n");
        free(data);
        data = NULL;
    }

    if (d == NULL) {
        if((data = malloc(format.dataSize)) == NULL)
            NSLog(@"Unable to malloc %d bytes\n", format.dataSize);
        memset(data, 0, format.dataSize);
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
        memset(data, 0, format.dataSize);
    else
        NSLog(@"SndAudioBuffer::zero: tried zeroing memory I didn't own!");
    return self;
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- (int) dataFormat
{
    return format.dataFormat;
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
    return format.channelCount;
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- mixWithBuffer: (SndAudioBuffer*) buff fromStart: (long) start toEnd: (long) end
{
    long l;
    
    if (end > format.dataSize / sizeof(float))
        end = format.dataSize / sizeof(float);

    l = end - start;

    
    if ([self dataFormat] == SND_FORMAT_FLOAT) {

        int selfNumChannels = format.channelCount;
        int buffNumChannels = [buff channelCount];
        int i;

        switch ([buff dataFormat]) {

// SOURCE BUFFER IS 32-BIT FLOAT

            case SND_FORMAT_FLOAT: {
                
                float *in  = (float*) [buff data];
                float *out = (float*) data;

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
                NSLog(@"SndAudioBuffer::mixWithBuffer: WARN: unsupported format - write stuff!");
        }

    }
    else {
        NSLog(@"SndAudioBuffer::mixWithBuffer: WARN: miss-matched buffer formats - write converter");
    }
    return self;
}


- mixWithBuffer: (SndAudioBuffer*) buff
{
    [self mixWithBuffer: buff fromStart: 0 toEnd: format.dataSize / sizeof(float)];
    
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
    SndAudioBuffer *to = [SndAudioBuffer audioBufferWithFormat: &format data: NULL];
    memcpy(to->data, data, format.dataSize);
    return to;
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- copyData: (SndAudioBuffer*) from
{
    if (from->format.dataSize == format.dataSize)
        memcpy(data, from->data, format.dataSize);
    else {
        NSLog(@"Buffers are different lengths - code to handle");
        // TO DO!
    }
    return self;
}

- (int) multiChannelSampleSizeInBytes
{
    long d = format.channelCount;

    switch ([self dataFormat]) {
        case SND_FORMAT_LINEAR_8:                       break;
        case SND_FORMAT_LINEAR_16: d *= sizeof(short);  break;
        case SND_FORMAT_LINEAR_24: d *= 3;              break;
        case SND_FORMAT_LINEAR_32: d *= sizeof(long);   break;
        case SND_FORMAT_DOUBLE:    d *= sizeof(double); break;
        case SND_FORMAT_FLOAT:     d *= sizeof(float);  break;
        default:
            NSLog(@"SndAudioBuffer::duration: ERR: This format not coded yet... sorry");
    }
    return d;
}

////////////////////////////////////////////////////////////////////////////////
// @lengthInSamples
////////////////////////////////////////////////////////////////////////////////

- (long) lengthInSamples
{
    return format.dataSize/ [self multiChannelSampleSizeInBytes];
}

////////////////////////////////////////////////////////////////////////////////
// @duration
////////////////////////////////////////////////////////////////////////////////

- (double) duration
{
    return (double) [self lengthInSamples] / (double) format.samplingRate;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

- (double) samplingRate
{
    return (double) format.samplingRate;
}

////////////////////////////////////////////////////////////////////////////////

@end
