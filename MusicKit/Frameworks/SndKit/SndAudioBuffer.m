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

#define DEBUG_MIXING 0

@implementation SndAudioBuffer

////////////////////////////////////////////////////////////////////////////////
// audioBufferWithFormat:data:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithFormat: (SndSoundStruct*) f data: (void*) d
{
  SndAudioBuffer *ab = [[SndAudioBuffer alloc] initWithFormat: f data: d];
  //NSLog(@"SndAudioBuffer audiobufferwithformat: format: %d, dataSize: %d, samplingRate: %d, channelCount: %d\n",
  //    ab->formatSnd.dataFormat, ab->formatSnd.dataSize, ab->formatSnd.samplingRate, ab->formatSnd.channelCount);
  return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// audioBufferWrapperAroundSNDStreamBuffer:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWrapperAroundSNDStreamBuffer: (SNDStreamBuffer*) cBuff
{
  SndAudioBuffer *ab = [[SndAudioBuffer alloc] initWithFormat: &(cBuff->streamFormat)
                                                         data: cBuff->streamData];
  return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// audioBufferWithSndSeg:range:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithSndSeg: (Snd*) snd range: (NSRange) r
{
  SndAudioBuffer *ab = [[SndAudioBuffer alloc] init];

  // PUT THIS IN AN INIT FN!!!!
  ab->dataFormat   = [snd dataFormat];
  ab->channelCount = [snd channelCount];
  ab->samplingRate = [snd samplingRate];
  {
    int samSize  = [ab frameSizeInBytes];
    ab->data     = [NSMutableData dataWithBytesNoCopy: samSize * r.location + [snd data]  
                                               length: samSize * r.length];
  }
  return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// audioBufferWithFormat:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithFormat: (SndSoundStruct*) f duration: (double) timeInSec
{
  SndAudioBuffer *ab = [SndAudioBuffer alloc];
  
  [ab initWithFormat: f->dataFormat
        channelCount: f->channelCount
        samplingRate: f->samplingRate
            duration: timeInSec];

  return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// audioBufferWithFormat:channelCount:samplingRate:duration:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithFormat: (int) _dataFormat
           channelCount: (int) _channelCount
           samplingRate: (double) _samplingRate
               duration: (double) time;
{
  SndAudioBuffer *ab = [SndAudioBuffer alloc];
  
  [ab initWithFormat: (int) _dataFormat
        channelCount: (int) _channelCount
        samplingRate: (double) _samplingRate
            duration: (double) time];
    
  return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
  self = [super init];
  if (self) {
    samplingRate = 44100;
    dataFormat   = SND_FORMAT_LINEAR_16;
    channelCount = 2;    
    if (data != nil)
      [data release];
    data = [[NSMutableData alloc] init];
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- initWithBuffer: (SndAudioBuffer*) b
           range: (NSRange) r
{
  self = [self init];
  if (self) {
    void *ptr = NULL;
    int frameSize  = 0, length, offset;
    int dataLength = 0;
    samplingRate = b->samplingRate;
    channelCount = b->channelCount;
    dataFormat   = b->dataFormat;
    
    frameSize    = [self frameSizeInBytes];
    ptr = [b bytes] + frameSize * r.location;
    length = frameSize * r.length;
    offset = frameSize * r.location;
    if (data != nil)
      [data release];

    if (offset+length > [[b data] length]) 
      dataLength = [[b data] length] - offset;
    else
      dataLength = length;

    data = [[NSMutableData alloc] initWithLength: length];
    memcpy([data mutableBytes], ptr, dataLength);
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// initWithBuffer:
////////////////////////////////////////////////////////////////////////////////

- initWithBuffer: (SndAudioBuffer*) b
{
  self = [self init];
  if (self) {
    samplingRate = b->samplingRate;
    channelCount = b->channelCount;
    dataFormat   = b->dataFormat;
    if (data)
      [data release];
    data = [[NSMutableData alloc] initWithData: [b data]];
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// initWithFormat:data:
////////////////////////////////////////////////////////////////////////////////

- initWithFormat: (SndSoundStruct*) f data: (void*) d
{
  self = [super init];
  if (self) {
    samplingRate = f->samplingRate;
    channelCount = f->channelCount;
    dataFormat   = f->dataFormat;

    if (data != nil)
      [data release];

    if (d == NULL)
      data = [[NSMutableData alloc] initWithLength: f->dataSize];
    else 
      data = [[NSMutableData alloc] initWithBytes: d length: f->dataSize];
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- initWithFormat: (int) _dataFormat
    channelCount: (int) _channelCount
    samplingRate: (double) _samplingRate
        duration: (double) time
{
  self = [super init];
  if (self) {
    long lengthInBytes = (SndSampleWidth(_dataFormat) * _channelCount) * (int)(time * _samplingRate);
    samplingRate = _samplingRate;
    channelCount = _channelCount;
    dataFormat   = _dataFormat;
    if (data != nil)
      [data release];
    data = [[NSMutableData alloc] initWithLength: lengthInBytes];
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
  [data release];
  [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// description
////////////////////////////////////////////////////////////////////////////////

- (NSString*) description
{
  return [NSString stringWithFormat: @"SndAudioBuffer [dataSize: %i dataFormat: %i samplingRate: %i channels: %i]",
    [data length], dataFormat, samplingRate, channelCount];
}

////////////////////////////////////////////////////////////////////////////////
// zero
////////////////////////////////////////////////////////////////////////////////

- zero
{
  memset([data mutableBytes], 0, [data length]);
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// zeroForeignBuffer
////////////////////////////////////////////////////////////////////////////////

- (void) zeroForeignBuffer
{
  memset([data mutableBytes], 0, [data length]);
}

////////////////////////////////////////////////////////////////////////////////
// micro accessors
////////////////////////////////////////////////////////////////////////////////

- (int) dataFormat      { return dataFormat;   }
- (NSData*) data        { return [[data retain] autorelease]; }
- (void*) bytes         { return [data mutableBytes]; }
- (int) channelCount    { return channelCount; }
- (double) samplingRate { return samplingRate; }

////////////////////////////////////////////////////////////////////////////////
// duration
////////////////////////////////////////////////////////////////////////////////

- (double) duration
{
  return (double) [self lengthInSampleFrames] / samplingRate;
}

////////////////////////////////////////////////////////////////////////////////
// hasSameFormatAsBuffer:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) hasSameFormatAsBuffer: (SndAudioBuffer*) buff
{
  if (buff == nil)
    return FALSE;
  else
    return (dataFormat    == buff->dataFormat  ) &&
           (channelCount  == buff->channelCount) &&
           ([data length] == [buff->data length]);
}

////////////////////////////////////////////////////////////////////////////////
// convertDataToFormat:
////////////////////////////////////////////////////////////////////////////////

- (NSMutableData*) convertDataToFormat: (int) newDataFormat
{
  long  dataItems   = [self lengthInSampleFrames] * [self channelCount];
  long  i;
  NSMutableData *nData = [NSMutableData dataWithLength: dataItems * SndSampleWidth(newDataFormat)];
  void *newData = [nData mutableBytes];
  
  if (newDataFormat == dataFormat)
    return data;

//  newDataSize = dataItems * SndSampleWidth(newDataFormat);
//  newData = (char*) malloc(newDataSize);

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
            ((float*)newData)[i] = (float)(v / (128.0 * 256.0));
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

- convertToFormat: (int) sndFormatCode
{
  if (dataFormat != SND_FORMAT_FLOAT) {
    NSMutableData *newData = [self convertDataToFormat: SND_FORMAT_FLOAT];
    [data release];
    data = [newData retain];
    dataFormat = sndFormatCode;
//    NSLog(@"convert: %@", [self description]);
  }
  return self;
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
  // SndPrintStruct(&formatSnd); // for checking the formatSnd is valid

  

  if ([self dataFormat] == SND_FORMAT_FLOAT) {
    
    long   frameCount;    
    int    selfNumChannels = channelCount;
    int    buffNumChannels = [buff channelCount];
    int    i;
    float *in = NULL;
    float *out = (float*) [data bytes];
    NSMutableData *convertData = nil;
    float *convertBuffer = NULL;
    long   dataSize = [data length];

    if (end > dataSize / sizeof(float))
      end = dataSize / sizeof(float);
    frameCount = end - start;

    if  ([buff dataFormat] != SND_FORMAT_FLOAT) {
      convertData = [[buff convertDataToFormat: SND_FORMAT_FLOAT] retain];
      convertBuffer = [convertData mutableBytes];
      in  = convertBuffer;
    }
    else
      in = [buff bytes];

    if (selfNumChannels > 2 || buffNumChannels > 2) {
      NSLog(@"Mix buffer - channels > 2 not handled (yet)");
    }
    else if (selfNumChannels == buffNumChannels) {
#ifdef __VEC__
      /* FIXME need to do extra check to ensure altivec is supported at runtime */
      vadd(in, 1,out+start,1,out+start,1,frameCount * buffNumChannels);
#else
      for (i = 0; i < frameCount * buffNumChannels; i++) {
        out[i+start] += in[i]; // interleaving automatically taken care of!
      }
#if DEBUG_MIXING
      {
        printf("out[0]: %f   maxpos:%li\n",out[start],frameCount * buffNumChannels);
      }
#endif     
#endif
    }
    else if (selfNumChannels == 2) {
#ifdef __VEC__
      vadd(in, 1,out+start,2,out+start,2,frameCount);     // LEFT
      vadd(in, 1,out+start+1,2,out+start+1,2,frameCount); // RIGHT
#else
      for (i = 0; i < frameCount; i++) {
        register int pos = (i<<1)+start;
        out[pos]   += in[i];
        out[pos+1] += in[i];
      }
#endif
    }
    else if (selfNumChannels == 1) {
#ifdef __VEC__
      vadd(in, 2,out+start,1,out+start,1,frameCount);     // LEFT
#else
      for (i = 0; i < frameCount; i++) {
        out[i+start] += in[i<<1]; // copy left channel into output buffer
      }
#endif
    }
    if (convertData)
      [convertData release]; 
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

  [self mixWithBuffer: buff fromStart: 0 toEnd: [self lengthInSampleFrames]];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// copy
////////////////////////////////////////////////////////////////////////////////

- copy
{
  SndAudioBuffer *dest = [[SndAudioBuffer alloc] initWithBuffer: self];
  return [dest autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// copyData:
////////////////////////////////////////////////////////////////////////////////

- copyData: (SndAudioBuffer*) from
{
  if (from != nil) {
    if ([from->data length] == [data length])
      [data setData: from->data];
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
  return channelCount * SndSampleWidth(dataFormat);
}

////////////////////////////////////////////////////////////////////////////////
// lengthInSamples
////////////////////////////////////////////////////////////////////////////////

- (long) lengthInSampleFrames
{
  return [data length] / [self frameSizeInBytes];
}

////////////////////////////////////////////////////////////////////////////////
// lengthInBytes
////////////////////////////////////////////////////////////////////////////////

- (long) lengthInBytes
{
  return [data length];
}

////////////////////////////////////////////////////////////////////////////////

@end
