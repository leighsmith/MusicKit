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
#define RANGE_PARANOIA_CHECK 0


@implementation SndAudioBuffer

////////////////////////////////////////////////////////////////////////////////
// audioBufferWithFormat:data:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithFormat: (SndSoundStruct*) f data: (void*) d
{
  SndAudioBuffer *ab = [[SndAudioBuffer alloc] initWithFormat: f data: d];
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
    ab->maxByteCount = ab->byteCount = samSize * r.length;
  }
  return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// audioBufferWithFormat:duration:
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
    byteCount = maxByteCount = 0;
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// initWithBuffer:range:
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

    if (offset+length > [b lengthInBytes])
      dataLength = [b lengthInBytes] - offset;
    else
      dataLength = length;

    if (length < 0)
      NSLog(@"SndAudioBuffer::initWithBuffer:range: ERR - length (%d) < 0", length);
    [data setLength: length];
    memcpy([data mutableBytes], ptr, dataLength);
    byteCount = maxByteCount = dataLength;
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
    byteCount    = b->byteCount;
    maxByteCount = b->maxByteCount;
    [data release];
    data = [[NSMutableData alloc] initWithData: b->data];
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
    if (f->dataSize < 0)
      NSLog(@"SndAudioBuffer::initWithFormat: ERR - f->dataSize (%d) < 0", f->dataSize);


    if (d == NULL) {
      data = [[NSMutableData alloc] initWithLength: f->dataSize];
    }
    else {
      data = [[NSMutableData alloc] initWithBytes: d length: f->dataSize];
    }
    maxByteCount = byteCount = f->dataSize;
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
    byteCount = 0;
    maxByteCount = lengthInBytes;
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
  return [NSString stringWithFormat: @"SndAudioBuffer [dataLength: %i reservedDataLength: %i duration: %f dataFormat: %i samplingRate: %f channels: %i]",
    byteCount, maxByteCount, [self duration], dataFormat, samplingRate, channelCount];
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
    return ( dataFormat   == buff->dataFormat   ) &&
           ( channelCount == buff->channelCount ) &&
           ( byteCount    == buff->byteCount    );
}

////////////////////////////////////////////////////////////////////////////////
// convertDataToFormat:
////////////////////////////////////////////////////////////////////////////////

- (NSMutableData*) convertDataToFormat: (int) newDataFormat
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
            v *= (1.0 / (128.0 * 256.0));
            ((float*)newData)[i] = v;
#if RANGE_PARANOIA_CHECK
            if (v > 1.0 || v < -1.0) {
              printf("Weird value!\n");
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

- convertToFormat: (int) sndFormatCode
{
  if (dataFormat != sndFormatCode) {
    NSMutableData *newData = [self convertDataToFormat: sndFormatCode];
    [data release];
    data = [newData retain];
    dataFormat = sndFormatCode;
    //    NSLog(@"convert: %@", [self description]);
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// mixWithBuffer:fromStart:toEnd:canExpand
//
// Note: This is only an interim proof of concept implementation and doesn't
// manage all combinations of formats. Instead of adding extra formats, this
// code should be changed to use a version of SndConvertSoundInternal() that
// has been suitably modified to accept presupplied buffers.
//  (SndConvertSoundInternal currently allocates them itself).
////////////////////////////////////////////////////////////////////////////////

- mixWithBuffer: (SndAudioBuffer*) buff
      fromStart: (long) start
          toEnd: (long) end
      canExpand: (BOOL) exp
{
  long lengthInSampleFrames = [self lengthInSampleFrames];
  long incomingLengthInSampleFrames = [buff lengthInSampleFrames];

  if (start > lengthInSampleFrames)
    NSLog(@"mixWithBuffer: start %i is > length %i",start,lengthInSampleFrames);
  else if (end > lengthInSampleFrames) {
    NSLog(@"mixWithBuffer: end %i is > length %i - truncating",end,lengthInSampleFrames);
    end = lengthInSampleFrames;
  }
  if ([self dataFormat] == SND_FORMAT_FLOAT) {

    long   frameCount;
    int    selfNumChannels = channelCount;
    int    buffNumChannels = [buff channelCount];
    int    i;
    float *in = NULL;
    float *out = (float*) [data bytes];
    NSMutableData *convertData = nil;
    float *convertBuffer = NULL;

    if (end > byteCount / sizeof(float))
      end = byteCount / sizeof(float);
    frameCount = MIN(incomingLengthInSampleFrames, end - start);

    if  ([buff dataFormat] != SND_FORMAT_FLOAT) {
      if (exp) { /* expand in place - saves allocating new buffer/data object */
        SndChangeSampleType([buff bytes], [buff dataFormat],
                            SND_FORMAT_FLOAT, buffNumChannels * frameCount);
        in = [buff bytes];
      } else {
        convertData = [[buff convertDataToFormat: SND_FORMAT_FLOAT] retain];
        convertBuffer = [convertData mutableBytes];
        in  = convertBuffer;
      }
#if DEBUG_MIXING
      {
        printf("mixbuffer: had to convert to float, nChannels = %d\n",buffNumChannels);
      }
#endif
    }
    else {
      in = [buff bytes];
      //      NSLog(@"no conversion");
    }

    if (selfNumChannels > 2 || buffNumChannels > 2) {
      NSLog(@"Mix buffer - channels > 2 not handled (yet)");
    }
    else if (selfNumChannels == buffNumChannels) {
      unsigned maxI = frameCount * buffNumChannels;
      out += start*buffNumChannels;
#ifdef __VEC__
      /* FIXME need to do extra check to ensure altivec is supported at runtime */
      vadd(in, 1,out,1,out,1,maxI);
#else
      for (i = 0; i < maxI; i++) {
        out[i] += in[i]; // interleaving automatically taken care of!
      }
#if DEBUG_MIXING
      {
        printf("out[0]: %f   maxpos:%li\n",out[0],frameCount * buffNumChannels);
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

  [self mixWithBuffer: buff fromStart: 0 toEnd: [self lengthInSampleFrames] canExpand:NO];
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
    if (from->byteCount == byteCount)
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
// copyBytes:count:
////////////////////////////////////////////////////////////////////////////////

- copyBytes: (char*) bytes count:(unsigned int)count format:(SndSoundStruct *)f
{
  if (!bytes) {
    NSLog(@"AudioBuffer::copyData: ERR: param 'from' is nil!");
    return nil;
  }
  [data replaceBytesInRange:NSMakeRange(0,count) withBytes:(const void *)bytes];
  dataFormat   = f->dataFormat;
  channelCount = f->channelCount;
  samplingRate = f->samplingRate;
  byteCount    = count;
  maxByteCount = [data length];
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
// lengthInSampleFrames
////////////////////////////////////////////////////////////////////////////////

- (long) lengthInSampleFrames
{
  return byteCount / [self frameSizeInBytes];
}

////////////////////////////////////////////////////////////////////////////////
// setLengthInSampleFrames
////////////////////////////////////////////////////////////////////////////////

- setLengthInSampleFrames: (long) newSampleFrameCount
{
  long frameSizeInBytes = [self frameSizeInBytes];
  long oldLengthInBytes = byteCount;
  long newLengthInBytes = frameSizeInBytes * newSampleFrameCount;

  if (newSampleFrameCount < 0) {
    NSLog(@"SndAudioBuffer::setLengthInSampleFrames: newSampleFrameCount (%ld) < 0!", newSampleFrameCount);
  }
  
  if (byteCount > newLengthInBytes)
    byteCount = newLengthInBytes;
  else {
    [data setLength: newLengthInBytes];
    memset([data mutableBytes] + oldLengthInBytes, 0, newLengthInBytes - oldLengthInBytes);
    byteCount = maxByteCount = newLengthInBytes;
  }

  return self;
}

////////////////////////////////////////////////////////////////////////////////
// lengthInBytes
////////////////////////////////////////////////////////////////////////////////

- (long) lengthInBytes
{
  return byteCount;
}

////////////////////////////////////////////////////////////////////////////////

@end
