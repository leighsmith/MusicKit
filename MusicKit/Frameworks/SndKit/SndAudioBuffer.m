////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import "SndAudioBuffer.h"

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
// audioBufferWithSnd:range:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithSnd: (Snd*) snd inRange: (NSRange) r
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

+ audioBufferWithFormat: (int) newDataFormat
           channelCount: (int) newChannelCount
           samplingRate: (double) newSamplingRate
               duration: (double) time;
{
  SndAudioBuffer *ab = [SndAudioBuffer alloc];

  [ab initWithFormat: (int) newDataFormat
        channelCount: (int) newChannelCount
        samplingRate: (double) newSamplingRate
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
      NSLog(@"SndAudioBuffer::initWithBuffer:range: ERR - length (%d) < 0! frameSize = %d, range.length = %d", length, frameSize, r.length);
        
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

- initWithFormat: (int) newDataFormat
    channelCount: (int) newChannelCount
    samplingRate: (double) newSamplingRate
        duration: (double) time
{
    self = [super init];
    if (self) {
	byteCount = (SndSampleWidth(newDataFormat) * newChannelCount) * (int)(time * newSamplingRate);
	samplingRate = newSamplingRate;
	channelCount = newChannelCount;
	dataFormat   = newDataFormat;
	if (data != nil)
	    [data release];
	data = [[NSMutableData alloc] initWithLength: byteCount];
	maxByteCount = byteCount;
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
    float sampleMin, sampleMax;
    
    [self findMin: &sampleMin max: &sampleMax];
    return [NSString stringWithFormat: @"%@ (dataLength: %i reservedDataLength: %i duration: %f dataFormat: %i samplingRate: %.2f channels: %i min: %.2f, max: %.2f)",
      [super description], byteCount, maxByteCount, [self duration], dataFormat, samplingRate, channelCount, sampleMin, sampleMax];
}

////////////////////////////////////////////////////////////////////////////////
// zero
////////////////////////////////////////////////////////////////////////////////

- zero
{
    // TODO this assumes all bytes per sample need to be set to zero to create a zero valued sample.
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
// mixWithBuffer:fromStart:toEnd:canExpand
//
// Note: This is only an interim proof of concept implementation and doesn't
// manage all combinations of formats. Instead of adding extra formats, this
// code should be changed to use a version of SndConvertSound() that
// has been suitably modified to accept presupplied buffers.
//  (SndConvertSound() currently allocates them itself).
////////////////////////////////////////////////////////////////////////////////

- mixWithBuffer: (SndAudioBuffer*) buff
      fromStart: (long) start
          toEnd: (long) end
      canExpand: (BOOL) canExpandInPlace
{
    long lengthInSampleFrames = [self lengthInSampleFrames];
    long incomingLengthInSampleFrames = [buff lengthInSampleFrames];
    int selfDataFormat = [self dataFormat];
    int buffDataFormat = [buff dataFormat];
    long frameCount;
    long lengthInSamples;
    int selfNumChannels = channelCount;
    int buffNumChannels = [buff channelCount];
    float *in = NULL;
    float *out = (float *) [data bytes];
    SndAudioBuffer *convertedBuffer = nil;
    
    if (start > lengthInSampleFrames)
	NSLog(@"mixWithBuffer: start %i is > length %i", start, lengthInSampleFrames);
    else if (end > lengthInSampleFrames) {
	NSLog(@"mixWithBuffer: end %i is > length %i - truncating", end, lengthInSampleFrames);
	end = lengthInSampleFrames;
    }

    if (end > byteCount / sizeof(float))
	end = byteCount / sizeof(float);
    frameCount = MIN(incomingLengthInSampleFrames, end - start);
    lengthInSamples = frameCount * buffNumChannels; // number of samples for all channels.

    if  (buffDataFormat != selfDataFormat) {
	if (canExpandInPlace && selfNumChannels == buffNumChannels) { /* expand in place - saves allocating new buffer/data object */
	    SndChangeSampleType([buff bytes], [buff bytes], buffDataFormat, selfDataFormat, lengthInSamples);
	    in = [buff bytes];
	}
	else {
	    convertedBuffer = [[buff audioBufferConvertedToFormat: selfDataFormat
						     channelCount: selfNumChannels
						     samplingRate: [self samplingRate]] retain];
	    in = [convertedBuffer bytes];
	}
#if DEBUG_MIXING
	NSLog(@"mixbuffer: had to convert to format %d, nChannels = %d\n", selfDataFormat, buffNumChannels);
#endif
    }
    else {
	in = [buff bytes];
#if DEBUG_MIXING
	NSLog(@"mixbuffer: no conversion mixing.");
#endif
    }
    out += start * buffNumChannels;
    // TODO we need a universal altivec mixer for all sample formats.
    if(selfDataFormat == SND_FORMAT_FLOAT) {
#ifdef __VEC__
	/* FIXME need to do extra check to ensure altivec is supported at runtime */
	vadd(in, 1, out, 1, out, 1, lengthInSamples);
#else
	for (i = 0; i < lengthInSamples; i++) {
	    out[i] += in[i]; // interleaving automatically taken care of!
	}
#endif
#if DEBUG_MIXING
	NSLog(@"out[0]: %f   maxpos:%li\n", out[0], lengthInSamples);
#endif
    }
    if (convertedBuffer)
	[convertedBuffer release];

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
  return dest; // copy returns a retained object according to NSObject spec
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
// copyBytes:intoRange:format:
////////////////////////////////////////////////////////////////////////////////

- copyBytes: (char*) bytes intoRange: (NSRange) bytesRange format: (SndSoundStruct *) f
{
    if (!bytes) {
	NSLog(@"AudioBuffer::copyBytes:intoRange:format: ERR: param 'from' is nil!");
	return nil;
    }
    if (bytesRange.location < 0) {
	NSLog(@"AudioBuffer::copyBytes:intoRange:format: ERR: param 'bytesRange' invalid location");
	return nil;
    }
    [data replaceBytesInRange: bytesRange withBytes: (const void *) bytes];
    dataFormat   = f->dataFormat;
    channelCount = f->channelCount;
    samplingRate = f->samplingRate;
    byteCount    = bytesRange.length;
    maxByteCount = [data length];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// copyBytes:count:format:
////////////////////////////////////////////////////////////////////////////////

- copyBytes: (char*) bytes count: (unsigned int) count format: (SndSoundStruct *) f
{
  return [self copyBytes: bytes intoRange: NSMakeRange(0, count) format: f];
}

////////////////////////////////////////////////////////////////////////////////
// copyFromBuffer:intoRange:
////////////////////////////////////////////////////////////////////////////////

- copyFromBuffer: (SndAudioBuffer *) fromBuffer intoRange: (NSRange) rangeInSamples
{
    if([self hasSameFormatAsBuffer: fromBuffer]) {
	SndSoundStruct f;
	int   sampleSize;
	NSRange rangeInBytes;
	
	f.dataFormat = dataFormat;
	f.channelCount = channelCount;
	f.samplingRate = samplingRate;
	sampleSize = SndFrameSize(&f);
	rangeInBytes.location = rangeInSamples.location * sampleSize;
	rangeInBytes.length = rangeInSamples.length * sampleSize;
	return [self copyBytes: [fromBuffer bytes] intoRange: rangeInBytes format: &f];
    }
    return nil;
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
  else {
    if (byteCount > newLengthInBytes)
      byteCount = newLengthInBytes;
    else {
      [data setLength: newLengthInBytes];
      if (oldLengthInBytes < newLengthInBytes) {
        NSRange r = {oldLengthInBytes, newLengthInBytes - oldLengthInBytes};
        [data resetBytesInRange: r];
      }
      byteCount = maxByteCount = newLengthInBytes;
    }
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

- (void) findMin:(float*) pMin max:(float*) pMax
{
  int i, c = [self lengthInSampleFrames] * channelCount;
  const float *pE = [data bytes];
  *pMin = 0.0;
  *pMax = 0.0;

  for (i = 0; i < c; i += channelCount){
    if (pE[i] < *pMin)
      *pMin = pE[i];
    else if (pE[i] > *pMax)
      *pMax = pE[i];
  }
}

@end
