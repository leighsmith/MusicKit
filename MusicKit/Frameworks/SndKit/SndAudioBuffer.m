////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    In memory audio buffer. See SndAudioBuffer.h for description.
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
// audioBufferWithSoundStruct:data:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithSoundStruct: (SndSoundStruct*) f data: (void*) d
{
    SndAudioBuffer *ab = [[SndAudioBuffer alloc] initWithSoundStruct: f data: d];
    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// audioBufferWithFormat:data:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithFormat: (SndFormat *) newFormat data: (void *) sampleData
{
    SndAudioBuffer *ab = [[SndAudioBuffer alloc] initWithFormat: newFormat data: sampleData];
    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// audioBufferWrapperAroundSNDStreamBuffer:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithSNDStreamBuffer: (SNDStreamBuffer *) streamBuffer
{
    // Repack the format parameters from the stream buffer into a SndFormat structure.
    SndFormat streamFormat = SndFormatOfSNDStreamBuffer(streamBuffer);

    SndAudioBuffer *ab = [[SndAudioBuffer alloc] initWithFormat: &streamFormat
    							   data: streamBuffer->streamData];
    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// audioBufferWithSnd:inRange:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithSnd: (Snd *) snd inRange: (NSRange) r
{
    SndAudioBuffer *ab = [[SndAudioBuffer alloc] init];
    int frameSizeInBytes;
    
    // PUT THIS IN AN INIT FN!!!!
    ab->format.dataFormat   = [snd dataFormat];
    ab->format.channelCount = [snd channelCount];
    ab->format.sampleRate = [snd samplingRate];
    frameSizeInBytes  = [ab frameSizeInBytes];
    if (ab->data != nil)
	[ab->data release];
    ab->byteCount = frameSizeInBytes * (r.length + r.location);
    ab->data = [[NSMutableData dataWithBytes: [snd data] + r.location * frameSizeInBytes
                                      length: ab->byteCount] retain];
    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// audioBufferWithFormat:duration:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithFormat: (SndFormat *) f duration: (double) timeInSec
{
    SndAudioBuffer *ab = [SndAudioBuffer alloc];

    [ab initWithDataFormat: f->dataFormat
              channelCount: f->channelCount
              samplingRate: f->sampleRate
                  duration: timeInSec];

    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// audioBufferWithDataFormat:channelCount:samplingRate:duration:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithDataFormat: (SndSampleFormat) newDataFormat
               channelCount: (int) newChannelCount
               samplingRate: (double) newSamplingRate
                   duration: (double) time;
{
    SndAudioBuffer *ab = [SndAudioBuffer alloc];

    [ab initWithDataFormat: newDataFormat
              channelCount: newChannelCount
              samplingRate: newSamplingRate
                  duration: time];

    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
  self = [super init];
  if (self) {
    format.sampleRate   = 44100.0;
    format.dataFormat   = SND_FORMAT_LINEAR_16;
    format.channelCount = 2;
    if (data != nil)
      [data release];
    data = [[NSMutableData alloc] init];
    byteCount = 0;
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// initWithBuffer:range:
////////////////////////////////////////////////////////////////////////////////

- initWithBuffer: (SndAudioBuffer *) b
           range: (NSRange) r
{
  self = [self init];
  if (self) {
    void *ptr = NULL;
    int frameSize  = 0, length, offset;
    int dataLength = 0;
    
    format = b->format;
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
    byteCount = dataLength;
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// initWithBuffer:
////////////////////////////////////////////////////////////////////////////////

- initWithBuffer: (SndAudioBuffer *) b
{
    self = [self init];
    if (self) {
        format = b->format;
        byteCount = b->byteCount;
        [data release];
        data = [[NSMutableData alloc] initWithData: b->data];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// initWithSoundStruct:data:
////////////////////////////////////////////////////////////////////////////////

- initWithSoundStruct: (SndSoundStruct *) f data: (void *) d
{
  self = [super init];
  if (self) {
    format.sampleRate = f->samplingRate;
    format.channelCount = f->channelCount;
    format.dataFormat   = f->dataFormat;

    if (data != nil)
      [data release];
    if (f->dataSize < 0)
      NSLog(@"SndAudioBuffer::initWithSoundStruct: ERR - f->dataSize (%d) < 0", f->dataSize);


    if (d == NULL) {
      data = [[NSMutableData alloc] initWithLength: f->dataSize];
    }
    else {
      data = [[NSMutableData alloc] initWithBytes: d length: f->dataSize];
    }
    byteCount = f->dataSize;
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// initWithFormat:data:
////////////////////////////////////////////////////////////////////////////////

- initWithFormat: (SndFormat *) newFormat data: (void *) sampleData
{
    self = [super init];
    if (self) {
        format = *newFormat;

        if (data != nil)
            [data release];
            
        byteCount = SndDataSize(*newFormat);

        if (byteCount < 0)
            NSLog(@"SndAudioBuffer::initWithFormat: ERR - format byteCount (%d) < 0", byteCount);

        if (sampleData == NULL) {
            data = [[NSMutableData alloc] initWithLength: byteCount];
        }
        else {
            data = [[NSMutableData alloc] initWithBytes: sampleData length: byteCount];
        }
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- initWithDataFormat: (SndSampleFormat) newDataFormat
        channelCount: (int) newChannelCount
        samplingRate: (double) newSamplingRate
            duration: (double) time
{
    self = [super init];
    if (self) {
	byteCount = (SndSampleWidth(newDataFormat) * newChannelCount) * (int)(time * newSamplingRate);
	format.sampleRate   = newSamplingRate;
	format.channelCount = newChannelCount;
	format.dataFormat   = newDataFormat;
	if (data != nil)
	    [data release];
	data = [[NSMutableData alloc] initWithLength: byteCount];
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

- (NSString *) description
{
    float sampleMin, sampleMax;
    
    [self findMin: &sampleMin max: &sampleMax];
    return [NSString stringWithFormat: @"%@ (dataLength: %i duration: %f dataFormat: %@ samplingRate: %.2f channels: %i min: %.2f, max: %.2f)",
        [super description], byteCount, [self duration],
        SndFormatName(format.dataFormat, NO), format.sampleRate, format.channelCount, sampleMin, sampleMax];
}

////////////////////////////////////////////////////////////////////////////////
// zeroFrameRange:
////////////////////////////////////////////////////////////////////////////////

- zeroFrameRange: (NSRange) frameRange
{
    int frameSize = [self frameSizeInBytes];
    
    // TODO this assumes all bytes per sample need to be set to zero to create a zero valued sample.
    memset([data mutableBytes] + frameRange.location * frameSize, 0, frameRange.length * frameSize);
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// zero
////////////////////////////////////////////////////////////////////////////////

- zero
{
    // We could be more conservative and call zeroFrameRange, but in the interests of efficiency of calculating
    // the range, we just blank the whole thing. This will only be inefficient if the lengthInSampleFrames is
    // less than the data length.
    memset([data mutableBytes], 0, [data length]);
    return self;
}

    
////////////////////////////////////////////////////////////////////////////////
// micro accessors
////////////////////////////////////////////////////////////////////////////////

- (SndSampleFormat) dataFormat { return format.dataFormat;   }
- (NSData *) data              { return [[data retain] autorelease]; }
- (void *) bytes               { return [data mutableBytes]; }
- (int) channelCount           { return format.channelCount; }
- (double) samplingRate        { return format.sampleRate; }

  ////////////////////////////////////////////////////////////////////////////////
  // duration
  ////////////////////////////////////////////////////////////////////////////////

- (double) duration
{
    return (double) [self lengthInSampleFrames] / format.sampleRate;
}

////////////////////////////////////////////////////////////////////////////////
// hasSameFormatAsBuffer:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) hasSameFormatAsBuffer: (SndAudioBuffer *) buff
{
    if (buff == nil)
        return FALSE;
    else
        return ( format.dataFormat   == buff->format.dataFormat   ) &&
               ( format.channelCount == buff->format.channelCount ) &&
               ( byteCount           == buff->byteCount    );
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

- (long) mixWithBuffer: (SndAudioBuffer *) buff
	     fromStart: (unsigned long) startFrame
		 toEnd: (unsigned long) endFrame
	     canExpand: (BOOL) canExpandInPlace
{
    unsigned long lengthInSampleFrames = [self lengthInSampleFrames];
    unsigned long incomingLengthInSampleFrames = [buff lengthInSampleFrames];
    int selfDataFormat = [self dataFormat];
    int buffDataFormat = [buff dataFormat];
    long frameCount;
    long lengthInSamples;
    int selfNumChannels = [self channelCount];
    int buffNumChannels = [buff channelCount];
    float *in = NULL;
    float *out = (float *) [data bytes];
    SndAudioBuffer *convertedBuffer = nil;
    
    if (startFrame > lengthInSampleFrames)
	NSLog(@"mixWithBuffer: startFrame %i is > length %i", startFrame, lengthInSampleFrames);
    else if (endFrame > lengthInSampleFrames) {
	NSLog(@"mixWithBuffer: endFrame %i is > length %i - truncating", endFrame, lengthInSampleFrames);
	endFrame = lengthInSampleFrames;
    }

    if (endFrame > byteCount / sizeof(float))
	endFrame = byteCount / sizeof(float);
    frameCount = MIN(incomingLengthInSampleFrames, endFrame - startFrame);
    lengthInSamples = frameCount * buffNumChannels; // number of samples for all channels.

    // Check whether we need to convert formats of buffers
    if (buffDataFormat != selfDataFormat) {
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
	NSLog(@"mixWithBuffer: had to convert from format %d, channels %d to format %d, channels = %d\n", 
            buffDataFormat, buffNumChannels, selfDataFormat, selfNumChannels);
#endif
    }
    else {
	in = [buff bytes];
#if DEBUG_MIXING
	NSLog(@"mixWithBuffer: no conversion mixing.");
#endif
    }
    out += startFrame * buffNumChannels;
    // TODO we need a universal altivec mixer for all sample formats.
    if(selfDataFormat == SND_FORMAT_FLOAT) {
#ifdef __VEC__
	/* TODO need to do extra check to ensure altivec is supported at runtime */
	vadd(in, 1, out, 1, out, 1, lengthInSamples);
#else
	int i;
	
	for (i = 0; i < lengthInSamples; i++) {
	    out[i] += in[i]; // interleaving automatically taken care of!
	}
#endif
#if DEBUG_MIXING
	NSLog(@"out[0]: %f   lengthInSamples:%li\n", out[0], lengthInSamples);
#endif
    }
    else {
	NSLog(@"mixWithBuffer: attempting to mix into buffer of unsupported format %d\n", selfDataFormat);
    }
    if (convertedBuffer)
	[convertedBuffer release];

    return frameCount;
}

////////////////////////////////////////////////////////////////////////////////
// mixWithBuffer:
////////////////////////////////////////////////////////////////////////////////

- (long) mixWithBuffer: (SndAudioBuffer *) buff
{
    // NSLog(@"mix %@ with new buffer: %@\n", self, buff);

    return [self mixWithBuffer: buff 
	             fromStart: 0 
                         toEnd: [self lengthInSampleFrames]
                     canExpand: NO];
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

- copyData: (SndAudioBuffer *) from
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

- copyBytes: (void *) bytes intoRange: (NSRange) bytesRange format: (SndFormat) newFormat
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
    format = newFormat;
    byteCount    = bytesRange.location + bytesRange.length;
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// copyBytes:count:format:
////////////////////////////////////////////////////////////////////////////////

- copyBytes: (void *) bytes count: (unsigned int) count format: (SndFormat) newFormat
{
  return [self copyBytes: bytes intoRange: NSMakeRange(0, count) format: newFormat];
}

////////////////////////////////////////////////////////////////////////////////
// copyFromBuffer:intoRange:
////////////////////////////////////////////////////////////////////////////////

- copyFromBuffer: (SndAudioBuffer *) fromBuffer intoRange: (NSRange) rangeInSamples
{
    if([self hasSameFormatAsBuffer: fromBuffer]) {
	long   sampleSize;
	NSRange rangeInBytes;
	
	// sampleSize = SndFrameSize(format); // TODO when SndFrameSize takes SndFormat parameter, not SndSoundStruct.
        sampleSize = SndFramesToBytes(1, format.channelCount, format.dataFormat);

	rangeInBytes.location = rangeInSamples.location * sampleSize;
	rangeInBytes.length = rangeInSamples.length * sampleSize;
	return [self copyBytes: [fromBuffer bytes] intoRange: rangeInBytes format: format];
    }
    return nil;
}

////////////////////////////////////////////////////////////////////////////////
// frameSizeInBytes
////////////////////////////////////////////////////////////////////////////////

- (int) frameSizeInBytes
{
  return format.channelCount * SndSampleWidth(format.dataFormat);
}

////////////////////////////////////////////////////////////////////////////////
// lengthInSampleFrames
////////////////////////////////////////////////////////////////////////////////

- (unsigned long) lengthInSampleFrames
{
  return byteCount / [self frameSizeInBytes];
}

////////////////////////////////////////////////////////////////////////////////
// setLengthInSampleFrames
////////////////////////////////////////////////////////////////////////////////

- setLengthInSampleFrames: (unsigned long) newSampleFrameCount
{
    long frameSizeInBytes = [self frameSizeInBytes];
    unsigned long oldLengthInBytes = byteCount;
    unsigned long newLengthInBytes = frameSizeInBytes * newSampleFrameCount;

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
	    byteCount = newLengthInBytes;
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

- (void) findMin: (float *) pMin max: (float *) pMax
{
    int i, samplesInBuffer = [self lengthInSampleFrames] * format.channelCount;
    const void *samplePtr = [data bytes];
    *pMin = 0.0;
    *pMax = 0.0;

    // Check all channels
    for (i = 0; i < samplesInBuffer; i++) {
	float sample = 0.0;

	switch(format.dataFormat) {
	case SND_FORMAT_FLOAT:
	    sample = ((float *) samplePtr)[i];
	    break;
	case SND_FORMAT_LINEAR_16:
	    sample = ((short *) samplePtr)[i];
	    break;
	default:
	    NSLog(@"findMin:max: unsupported format %d\n", format.dataFormat);
	}
	
	if (sample < *pMin)
	    *pMin = sample;
	else if (sample > *pMax)
	    *pMax = sample;
    }
}

- (float) sampleAtFrameIndex: (unsigned long) frameIndex channel: (int) channel
{
    unsigned long sampleIndex = frameIndex * format.channelCount + channel;
    const void *samplePtr = [data bytes];
    float sample = 0.0;

    if(frameIndex < 0 || frameIndex >= [self lengthInSampleFrames]) {
	NSLog(@"frameIndex %ld out of range [0,%ld]\n", frameIndex, [self lengthInSampleFrames]);
	return 0.0;
    }
    if(channel < 0 || channel >= format.channelCount) {
	NSLog(@"channel %d out of range [0,%d]\n", channel, format.channelCount);
	return 0.0;
    }
    switch(format.dataFormat) {
	case SND_FORMAT_FLOAT:
	    sample = ((float *) samplePtr)[sampleIndex];
	    break;
	case SND_FORMAT_LINEAR_16:
	    sample = ((short *) samplePtr)[sampleIndex];
	    break;
	default:
	    NSLog(@"sampleAtFrameIndex:channel: unsupported format %d\n", format.dataFormat);
    }
    return sample;
}

@end
