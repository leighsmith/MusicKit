////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>, tomandandy music inc.
//
//  12 Feb 2001, Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import "SndAudioBuffer.h"
#import "SndFunctions.h"
// altivec support...
#ifdef __VEC__
#import <vecLib/vecLib.h>
#endif

@implementation SndAudioBuffer

////////////////////////////////////////////////////////////////////////////////
// audioBufferWithFormat:data:
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
// audioBufferWrapperAroundSNDStreamBuffer:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWrapperAroundSNDStreamBuffer: (SNDStreamBuffer*) cBuff
{
  SndAudioBuffer *ab = [[SndAudioBuffer alloc] init];
  ab->bOwnsData = FALSE;
  [ab initWithFormat: &(cBuff->streamFormat) data: cBuff->streamData];
  return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// audioBufferWithSndSeg:range:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithSndSeg: (Snd*) snd range: (NSRange) r
{
  SndAudioBuffer *ab = [[SndAudioBuffer alloc] init];

  // PUT THIS IN AN INIT FN!!!!
  memcpy(&(ab->formatSnd),[snd soundStruct], sizeof(SndSoundStruct));
  {
    int samSize       = [ab frameSizeInBytes];
    int lengthInBytes = r.length * samSize;
    ab->formatSnd.dataSize = lengthInBytes;
    ab->data  = [snd data] + samSize * r.location;
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
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
  self = [super init];
  if (self) {
    memset(&formatSnd, 0, sizeof(SndSoundStruct));
    if (data != NULL && bOwnsData) {
      free(data);
      data = NULL;
    }
    bOwnsData = TRUE;
    data = NULL;
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// initWithFormat:data:
////////////////////////////////////////////////////////////////////////////////

- initWithFormat: (SndSoundStruct*) f data: (void*) d
{
  [self init];
  memcpy(&formatSnd, f, sizeof(SndSoundStruct));

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
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
  if (bOwnsData)
    free(data);
  [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// description
////////////////////////////////////////////////////////////////////////////////

- (NSString*) description
{
  return [NSString stringWithFormat: @"SndAudioBuffer [dataSize: %i dataFormat: %i samplingRate: %i channels: %i]",
    formatSnd.dataSize, formatSnd.dataFormat, formatSnd.samplingRate, formatSnd.channelCount];
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

////////////////////////////////////////////////////////////////////////////////
// zeroForeignBuffer
////////////////////////////////////////////////////////////////////////////////

- (void) zeroForeignBuffer
{
  memset(data, 0, formatSnd.dataSize);
}

////////////////////////////////////////////////////////////////////////////////
// micro accessors
////////////////////////////////////////////////////////////////////////////////

- (int) dataFormat      { return formatSnd.dataFormat;   }
- (void*) data          { return data;                   }
- (int) channelCount    { return formatSnd.channelCount; }
- (double) samplingRate { return (double) formatSnd.samplingRate; }

////////////////////////////////////////////////////////////////////////////////
// duration
////////////////////////////////////////////////////////////////////////////////

- (double) duration
{
  return (double) [self lengthInSamples] / [self samplingRate];
}

////////////////////////////////////////////////////////////////////////////////
// hasSameFormatAsBuffer:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) hasSameFormatAsBuffer: (SndAudioBuffer*) buff
{
  if (buff == nil)
    return FALSE;
  else
    return (formatSnd.dataFormat   == buff->formatSnd.dataFormat  ) &&
      (formatSnd.channelCount == buff->formatSnd.channelCount) &&
      (formatSnd.dataSize     == buff->formatSnd.dataSize    );
}

////////////////////////////////////////////////////////////////////////////////
// convertDataToFormat:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) convertDataToFormat: (int) newDataFormat resultBuffer: (void*) newData
{
//  void *newData = NULL;
//  long  newDataSize;
  long  dataItems, i;
  
  if (newDataFormat == formatSnd.dataFormat)
    return TRUE;

  dataItems   = formatSnd.dataSize / SndSampleWidth(formatSnd.dataFormat);
//  newDataSize = dataItems * SndSampleWidth(newDataFormat);
//  newData = (char*) malloc(newDataSize);

  switch (formatSnd.dataFormat) {
    
    case SND_FORMAT_LINEAR_8:
      
      switch (newDataFormat) {
        case SND_FORMAT_LINEAR_16:
          for (i=0;i<dataItems;i++) {
            short v = ((char*)data)[i];
            ((short*)newData)[i] = v << 8;
          }
          break;
        case SND_FORMAT_LINEAR_32:
          for (i=0;i<dataItems;i++) {
            long v = ((char*)data)[i];
            ((long*)newData)[i] = v << 24;
          }
          break;
        case SND_FORMAT_FLOAT:
          for (i = 0;i<dataItems;i++) {
            float v = ((char*)data)[i];
            ((float*)newData)[i] = v / 128.0;
          }
          break;
        case SND_FORMAT_DOUBLE:
          for (i = 0;i<dataItems;i++) {
            double v = ((char*)data)[i];
            ((double*)newData)[i] = v / 128.0;
          }
          break;
      }
      break;

    case SND_FORMAT_LINEAR_16: 

      switch (newDataFormat) {
        case SND_FORMAT_LINEAR_8:
          for (i=0;i<dataItems;i++) {
            short v = ((short*)data)[i];
            ((char*)newData)[i] = v >> 8;
          }
          break;
        case SND_FORMAT_LINEAR_32:
          for (i=0;i<dataItems;i++) {
            long v = ((short*)data)[i];
            ((long*)newData)[i] = v >> 24;
          }
          break;
        case SND_FORMAT_FLOAT:
          for (i=0;i<dataItems;i++) {
            float v = ((short*)data)[i];
            ((float*)newData)[i] = (float)(v / (128.0 * 256.0));
          }
          break;
        case SND_FORMAT_DOUBLE:
          for (i = 0; i < dataItems;i++) {
            double v = ((short*)data)[i];
            ((double*)newData)[i] = (double)(v / (128.0 * 256.0));
          }
          break;
      }
      break;
      
    case SND_FORMAT_LINEAR_32:
      
      switch (newDataFormat) {
        case SND_FORMAT_LINEAR_8:
          for (i=0;i<dataItems;i++) {
            long v = ((long*)data)[i];
            ((char*)newData)[i] = (char)(v >> 24);
          }
          break;
        case SND_FORMAT_LINEAR_16:
          for (i=0;i<dataItems;i++) {
            long v = ((long*)data)[i];
            ((short*)newData)[i] = (short)(v >> 8);
          }
          break;
        case SND_FORMAT_FLOAT:
          for (i=0;i<dataItems;i++) {
            double v = ((long*)data)[i];
            ((float*)newData)[i] = (float)(v / (128.0 * 256.0 * 256.0 * 256.0));
          }
          break;
        case SND_FORMAT_DOUBLE:
          for (i=0;i<dataItems;i++) {
            double v = ((long*)data)[i];
            ((double*)newData)[i] = (double)(v / (128.0 * 256.0 * 256.0 * 256.0));
          }
          break;
      }
      break;
      
    case SND_FORMAT_FLOAT:
      
      switch (newDataFormat) {
        case SND_FORMAT_LINEAR_8:
          for (i=0;i<dataItems;i++) {
            float v = ((float*)data)[i];
            ((char*)newData)[i] = (char)(v * 128.0);
          }          
          break;
        case SND_FORMAT_LINEAR_16:
          for (i=0;i<dataItems;i++) {
            float v = ((float*)data)[i];
            ((short*)newData)[i] = (short)(v * 128.0 * 256.0);
          }
          break;
        case SND_FORMAT_LINEAR_32:
          for (i=0;i<dataItems;i++) {
            float v = ((float*)data)[i];
            ((long*)newData)[i] = (long)(v * 128.0 * 256.0 * 256.0 * 256.0);
          }          
          break;
        case SND_FORMAT_DOUBLE:
          for (i=0;i<dataItems;i++) {
            float v = ((float*)data)[i];
            ((double*)newData)[i] = (double) v;
          }
          break;
      }
      break;
      
    case SND_FORMAT_DOUBLE:
      
      switch (newDataFormat) {
        case SND_FORMAT_LINEAR_8:
          for (i = 0; i < dataItems; i++) {
            double v = ((double*)data)[i];
            ((char*)newData)[i] = (char)(v * 128.0);
          }
          break;
        case SND_FORMAT_LINEAR_16:
          for (i = 0; i < dataItems; i++) {
            double v = ((double*)data)[i];
            ((short*)newData)[i] = (short)(v * (128.0 * 256.0));
          }
          break;
        case SND_FORMAT_LINEAR_32:
          for (i = 0; i < dataItems; i++) {
            double v = ((double*)data)[i];
            ((long*)newData)[i] = (long)(v * (128.0 * 256.0 * 256.0 * 256.0));
          }
          break;
        case SND_FORMAT_FLOAT:
          for (i = 0; i < dataItems; i++) {
            double v = ((double*)data)[i];
            ((float*)newData)[i] = (float)(v);
          }
          break;
      }
      break;
  }

//  if (bOwnsData)
//    free(data);
//  data = newData;
//  bOwnsData = TRUE;
//  formatSnd.dataFormat = newDataFormat;
//  formatSnd.dataSize   = newDataSize;
  
  return TRUE;
}


////////////////////////////////////////////////////////////////////////////////
// mixWithBuffer:fromStart:toEnd:
//
// Note: This is only an interim proof of concept implementation and doesn't
// manage all combinations of formats. Instead of adding extra formats, this
// code should be changed to use a version of SndConvertSoundInternal() that
// has been suitably modified to accept presupplied buffers.
//  (SndConvertSoundInternal currently allocates them itself).
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
                register int pos = (i<<1)+start;
                out[pos]   += in[i];
                out[pos+1] += in[i];
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
                out[i+start] += in[i<<1]; // copy left channel into output buffer
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
            register int pos = (i<<1)+start;
            f = (float) in[i] / 32768.0f;
            out[pos]   += f; // interleaving automatically taken care of!
            out[pos+1] += f; // interleaving automatically taken care of!
          }
        }
        else if (buffNumChannels == 2)  {
          for (i = 0; i < frameCount; i++) {
            f = (float) in[i<<1] / 32768.0f;
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

////////////////////////////////////////////////////////////////////////////////
// mixWithBuffer:
////////////////////////////////////////////////////////////////////////////////

- mixWithBuffer: (SndAudioBuffer*) buff
{
  // NSLog(@"buffer = %x\n", buff);
  // NSLog(@"buffer to mix: %s", SndStructDescription(&(buff->formatSnd)));

  [self mixWithBuffer: buff fromStart: 0 toEnd: [self lengthInSamples]];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// copy
////////////////////////////////////////////////////////////////////////////////

- copy
{
  SndAudioBuffer *to = [SndAudioBuffer audioBufferWithFormat: &formatSnd data: NULL];
  memcpy(to->data, data, formatSnd.dataSize);
  return to;
}

////////////////////////////////////////////////////////////////////////////////
// copyData:
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

////////////////////////////////////////////////////////////////////////////////
// frameSizeInBytes
////////////////////////////////////////////////////////////////////////////////

- (int) frameSizeInBytes
{
  return formatSnd.channelCount * SndSampleWidth([self dataFormat]);
}

////////////////////////////////////////////////////////////////////////////////
// lengthInSamples
////////////////////////////////////////////////////////////////////////////////

- (long) lengthInSamples
{
  return formatSnd.dataSize / [self frameSizeInBytes];
}

////////////////////////////////////////////////////////////////////////////////
// lengthInBytes
////////////////////////////////////////////////////////////////////////////////

- (long) lengthInBytes
{
  return formatSnd.dataSize;
}

////////////////////////////////////////////////////////////////////////////////
// format
////////////////////////////////////////////////////////////////////////////////

- (SndSoundStruct*) format
{
  return &formatSnd;
}

- setOwnsData: (BOOL) b
{
  bOwnsData = b;
  return self;
}

////////////////////////////////////////////////////////////////////////////////

@end
