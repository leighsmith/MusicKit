////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    Holds the state associated with each sounding (or soon to be) Snd.
//    This differs from a Snd instance itself, since we can have multiple overlapping
//    performances of the same Snd. We need some way of indicating to the delegate
//    exactly which performance has completed.
//
//  Original Author: Leigh Smith, <leigh@tomandandy.com>
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import "SndPlayer.h"
#import "SndPerformance.h"

#define SNDPERFORMANCE_DEBUG_RETRIEVE_BUFFER 0

@implementation SndPerformance

////////////////////////////////////////////////////////////////////////////////
// performanceOfSnd:playingAtTime:
////////////////////////////////////////////////////////////////////////////////

+ (SndPerformance *) performanceOfSnd: (Snd *) s
                        playingAtTime: (double) t;
{
  return [[[SndPerformance alloc] initWithSnd: s playingAtTime: t] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// performanceOfSnd:playingAtTime:beginAtIndex:endAtIndex:
////////////////////////////////////////////////////////////////////////////////

+ (SndPerformance *) performanceOfSnd: (Snd *) s
                        playingAtTime: (double) t
                         beginAtIndex: (long) beginIndex
                           endAtIndex: (long) endIndex
{
  return [[[SndPerformance alloc] initWithSnd: s
                                playingAtTime: t
                                 beginAtIndex: beginIndex
                                   endAtIndex: endIndex] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// initWithSnd:playingAtTime:
////////////////////////////////////////////////////////////////////////////////

- initWithSnd: (Snd *) s playingAtTime: (double) t
{
  if (!snd) {
    return nil;
  }
  return [self initWithSnd: s playingAtTime: t beginAtIndex: 0 endAtIndex: [s lengthInSampleFrames]];
}

////////////////////////////////////////////////////////////////////////////////
// initWithSnd:playingAtTime:beginAtIndex:endAtIndex:
////////////////////////////////////////////////////////////////////////////////

- initWithSnd: (Snd *) s
playingAtTime: (double) t
 beginAtIndex: (long) beginIndex
   endAtIndex: (long) endIndex
{
    self = [super init];
    if (self) {
	snd          = [s retain];
	playTime     = t;
	startAtIndex = beginIndex;
	playIndex    = beginIndex;
	endAtIndex   = endIndex;
	deltaTime    = 1.0;
	actualTime   = 0.0;
	// Prime the loop behaviour during performance from the Snd's settings.
	// It is possible to change the loop behaviour of the performance during play.
	[self setLoopStartIndex: [s loopStartIndex]];
	[self setLoopEndIndex: [s loopEndIndex]];
	[self setLooping: [s loopWhenPlaying]];
    }
    return self;
}

- initWithSnd: (Snd *) s
playingAtTime: (double) _playTime
startPosition: (double) startPosition
     duration: (double) duration
    deltaTime: (double) _deltaTime;
{
    self = [super init];
    if (self) {
	double samplingRate = [s samplingRate];
	
	[self initWithSnd: s
	    playingAtTime: _playTime
	     beginAtIndex: (long) (samplingRate * startPosition)
	       endAtIndex: (long) (startAtIndex + samplingRate * duration * deltaTime)];

	deltaTime = _deltaTime;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
  if (snd)
    [snd release];
  snd = nil;
  if (audioProcessorChain)
    [audioProcessorChain release];
  audioProcessorChain = nil;
  [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// copyWithZone:
//
// Copies receiver, including its Snd reference, play time and index.
////////////////////////////////////////////////////////////////////////////////

- copyWithZone: (NSZone *) zone
{
  SndPerformance *newPerformance = [[SndPerformance allocWithZone: zone] init];

  // We do a lightweight copy since this is just a reference to the Snd anyway.
  newPerformance->snd          = [snd retain];
  newPerformance->playTime     = playTime;
  newPerformance->playIndex    = playIndex;
  newPerformance->startAtIndex = startAtIndex;
  newPerformance->endAtIndex   = endAtIndex;
  newPerformance->deltaTime    = deltaTime;
  return newPerformance; // no need to autorelease (by definition, "copy" is retained)
}

////////////////////////////////////////////////////////////////////////////////
// isEqual:
//
// We consider the performances to be equal if they are the same sound and start
// at the same time. The reason we don't consider the playIndex is because a
// performance would never match unless it is playing at exactly the same sample.
////////////////////////////////////////////////////////////////////////////////

- (BOOL) isEqual: (id) anotherPerformance
{
  BOOL equal = ((SndPerformance *) anotherPerformance)->snd == snd && // TODO [((SndPerformance *) anotherPerformance)->snd isEqual: snd]
  ((SndPerformance *) anotherPerformance)->playTime == playTime &&
  ((SndPerformance *) anotherPerformance)->startAtIndex == startAtIndex &&
  ((SndPerformance *) anotherPerformance)->endAtIndex == endAtIndex &&
  ((SndPerformance *) anotherPerformance)->deltaTime == deltaTime ;
  // NSLog(@"checking if equal %@ vs. %@ = %s\n", self, anotherPerformance, equal ? "YES" : "NO");
  return equal;
}

- (unsigned) hash
{
    return [snd hash] + (unsigned) playTime * 256 + (unsigned) startAtIndex * 512 + (unsigned) endAtIndex * 1024 + (unsigned) deltaTime * 2048;
}

////////////////////////////////////////////////////////////////////////////////
// description
////////////////////////////////////////////////////////////////////////////////

- (NSString *) description
{
    NSString *loopDescription = looping ? [NSString stringWithFormat: @"looping between %ld and %ld",
	loopStartIndex, loopEndIndex] : @"";

    return [NSString stringWithFormat: @"%@ playing (%@) at %f, from %ld, to %ld %@", [super description],
	snd, playTime, startAtIndex, endAtIndex, loopDescription];
}

////////////////////////////////////////////////////////////////////////////////
// snd
////////////////////////////////////////////////////////////////////////////////

- (Snd*) snd
{
  return [[snd retain] autorelease];
}

- (double) deltaTime
{
  return deltaTime;
}

- (void) setDeltaTime: (double) _deltaTime
{
  deltaTime = _deltaTime;
}

////////////////////////////////////////////////////////////////////////////////
// playTime
////////////////////////////////////////////////////////////////////////////////

- (double) playTime
{
  return playTime;
}

- setPlayTime: (double) t
{
  playTime = t;
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// playIndex
////////////////////////////////////////////////////////////////////////////////

- (long) playIndex
{
  return playIndex;
}

////////////////////////////////////////////////////////////////////////////////
// setPlayIndex:
////////////////////////////////////////////////////////////////////////////////

- (void) setPlayIndex: (long) newPlayIndex
{
    // If we are going to move the play index after the end index, allow that,
    // but adjust the end index in order to stay legal.
    if(newPlayIndex > endAtIndex)
		endAtIndex = newPlayIndex;
    playIndex = newPlayIndex;
}

////////////////////////////////////////////////////////////////////////////////
// rewindPlayIndexBySamples:
////////////////////////////////////////////////////////////////////////////////

- (long) rewindPlayIndexBySamples: (long) numberOfSamplesToRewind
{
    long distanceFromLoopStart = playIndex - loopStartIndex;
    
    // check if we need to wrap around the loop start index if we are looping and we have entered the loop.
    if(looping && distanceFromLoopStart > 0 && distanceFromLoopStart < numberOfSamplesToRewind)
		playIndex = loopEndIndex - (numberOfSamplesToRewind - distanceFromLoopStart);
    else
		playIndex -= numberOfSamplesToRewind;
    return playIndex;
}

////////////////////////////////////////////////////////////////////////////////
// endAtIndex
////////////////////////////////////////////////////////////////////////////////

- (long) endAtIndex   {  return endAtIndex; }
- (long) startAtIndex {  return playIndex;  }

////////////////////////////////////////////////////////////////////////////////
// setEndAtIndex:
////////////////////////////////////////////////////////////////////////////////

- (void) setEndAtIndex: (long) newEndAtIndex
{
    // If we are going to move the end index before the start, allow that,
    // but adjust the start index in order to stay legal.
    if(newEndAtIndex < playIndex)
	playIndex = newEndAtIndex;
    endAtIndex = newEndAtIndex; 
}

////////////////////////////////////////////////////////////////////////////////
// stopInFuture:
////////////////////////////////////////////////////////////////////////////////

- (void) stopInFuture: (double) inSeconds
{
  if (paused)
    [self stopNow];
  else
    [[SndPlayer defaultSndPlayer] stopPerformance: self inFuture: inSeconds];
}

- (void) stopNow
{
  paused = NO;
  playIndex = endAtIndex;
  looping = NO;   // We set the looping off so we don't miss the stop condition.
}

////////////////////////////////////////////////////////////////////////////////
// Pausing stuff.
////////////////////////////////////////////////////////////////////////////////

- (BOOL) isPaused { return paused; };
- setPaused: (BOOL) b  { paused = b; return self; }
- pause  { paused = YES; return self; }
- resume { paused = NO;  return self; }

- (BOOL) isPlaying
{
    return ![self isPaused] && ![self atEndOfPerformance];
}

////////////////////////////////////////////////////////////////////////////////
// AudioProcessorChain stuff
////////////////////////////////////////////////////////////////////////////////

- (SndAudioProcessorChain *) audioProcessorChain
{
    return [[audioProcessorChain retain] autorelease];
}

- setAudioProcessorChain: (SndAudioProcessorChain *) anAudioProcessorChain
{
    if (audioProcessorChain)
	[audioProcessorChain release];
    audioProcessorChain = [anAudioProcessorChain retain];
    return self;
}

// Fills the given buffer with sound data, reading from the playIndex up until endAtIndex
// (which allows us to play a sub-section of a sound). playIndex is updated, and looping is
// respected.
- (long) retrievePerformBuffer: (SndAudioBuffer *) bufferToFill ofLength: (long) buffLength
{
    long fillBufferToLength = buffLength;
    // long framesUntilEndOfLoop = loopEndIndex - playIndex + 1;
    // Determine number of frames in the loop, checking for resampling shortening that number.
    double stretchFactor = [bufferToFill samplingRate] / [snd samplingRate];
    long framesUntilEndOfLoop = (loopEndIndex - playIndex + 1) * (stretchFactor < 1.0 ? stretchFactor : 1.0);
    BOOL atEndOfLoop = looping && (buffLength >= framesUntilEndOfLoop);
    // numOfSamplesFilled and numOfSamplesRead can differ if we resample in fillAudioBuffer.
    long numOfSamplesFilled = 0;
    long numOfSamplesRead = 0;
    // specifies to fillAudioBuffer: and insertIntoAudioBuffer: the range of Snd samples permissible to read from.
    NSRange samplesToReadRange;
    
    if (atEndOfLoop) {	// retrieve up to the end of the loop
	fillBufferToLength = framesUntilEndOfLoop;
    }
    // specify the final boundary in the Snd fillAudioBuffer: can not read beyond.
    samplesToReadRange.location = playIndex;
    samplesToReadRange.length = looping ? framesUntilEndOfLoop : endAtIndex - playIndex;
    
#if SNDPERFORMANCE_DEBUG_RETRIEVE_BUFFER
    NSLog(@"[SndPerformance][SYNTH THREAD] playIndex = %ld, endAtIndex = %ld, buffer length = %d, fill buffer to length = %d, framesUntilEndOfLoop = %ld\n",
	  playIndex, endAtIndex, buffLength, fillBufferToLength, framesUntilEndOfLoop);
#endif
    
    // Negative or zero buffer length means the endAtIndex was moved before or to the current playIndex,
    // so we should skip any mixing and stop.
    // Nowdays, with better checking on the updates of endAtIndex and playIndex this should never occur,
    // so this check is probably redundant, but hey, it adds robustness which translates into saving someones
    // ears from hearing noise.
    if (playIndex >= 0 && buffLength > 0 && fillBufferToLength > 0) {
	// NSLog(@"bufferToFill dataFormat before processing 1 %d\n", [bufferToFill dataFormat]);
	numOfSamplesRead = [snd fillAudioBuffer: bufferToFill
				       toLength: fillBufferToLength
				 samplesInRange: samplesToReadRange];
	numOfSamplesFilled = fillBufferToLength;
#if 0
	{
	    //NSLog(@"bufferToFill %@, numOfSamplesFilled = %ld, numOfSamplesRead = %ld\n",
	    //    bufferToFill, numOfSamplesFilled, numOfSamplesRead);
	    long i;
	    for (i = 0; i < numOfSamplesFilled; i++)
		NSLog(@"%f\n", [bufferToFill sampleAtFrameIndex: i channel: 0]);
	}
#endif
	
	if(atEndOfLoop) {
	    // If we are at the end of the loop, copy in zero or more (when the loop is small) loop regions 
	    // then any remaining beginning of the loop.
	    int loopLength = loopEndIndex - loopStartIndex + 1;
	    long fillBufferFrom = fillBufferToLength;
	    long remainingLengthToFillWithLoop = buffLength - fillBufferFrom;
	    
	    // Reset playIndex to the start of the loop. We do this before the loop in case we do no loops,
	    // in the singular case that the loop ends at the end of a buffer, requiring no insertion of loop
	    // regions for this buffer.
	    playIndex = loopStartIndex;   
	    while(remainingLengthToFillWithLoop > 0 && loopLength > 0) {
		NSRange loopRegion;
		
		// give the range of Snd samples permissible to read from.
		samplesToReadRange.location = loopStartIndex;
		samplesToReadRange.length = loopLength;
		// give the range to fill in the buffer
		loopRegion.location = fillBufferFrom;
		loopRegion.length = MIN(remainingLengthToFillWithLoop, loopLength);
		
		numOfSamplesRead = [snd insertIntoAudioBuffer: bufferToFill
					       intoFrameRange: loopRegion
					       samplesInRange: samplesToReadRange];
#if SNDPERFORMANCE_DEBUG_RETRIEVE_BUFFER
		{
		    long i;
		    
		    NSLog(@"%@ loopRegion.location = %ld, loopRegion.length = %ld, playIndex = %ld, fillBufferFrom = %d, remainingLengthToFillWithLoop = %d\n",
			  bufferToFill, loopRegion.location, loopRegion.length, playIndex, fillBufferFrom, remainingLengthToFillWithLoop);
		    for (i = fillBufferFrom - 5; i < fillBufferFrom + 5; i++)
			NSLog(@"buffer[%ld] = %e\n", i, [bufferToFill sampleAtFrameIndex: i channel: 0]);
		}
#endif
		numOfSamplesFilled += loopRegion.length;
		playIndex += numOfSamplesRead;
		fillBufferFrom += loopRegion.length; 
		remainingLengthToFillWithLoop -= loopRegion.length;
	    }
	}
	else
	    playIndex += numOfSamplesRead;  // Update the read index accounting for change from resampling.
	
	actualTime += [bufferToFill duration];
	if (audioProcessorChain != nil) {
	    // NSLog(@"time: %f\n", relativePlayTime);
	    [audioProcessorChain processBuffer: bufferToFill forTime: actualTime];
	}
	
#if SNDPERFORMANCE_DEBUG_RETRIEVE_BUFFER
	NSLog(@"[SndPerformance][SYNTH THREAD] will mix buffer from %d to %d, old playIndex %d for %d, val at start = %f\n",
	      0, fillBufferToLength, samplesToReadRange.location, numOfSamplesFilled,
	      (((short *) [snd data])[samplesToReadRange.location]) / (float) 32768);
#endif
    }
    else
	playIndex += buffLength;  // If there is a problem, push the playIndex forward, we may improve...somehow...
    
    //NSLog(@"retrieved numOfSamplesFilled = %ld\n", numOfSamplesFilled);
    return numOfSamplesFilled;
}

- (BOOL) atEndOfPerformance
{
    // Since endAtIndex specifies the first sample NOT played, if playIndex equals it or exceeds it, we have
    // reached the end.
    return playIndex >= endAtIndex;
}

////////////////////////////////////////////////////////////////////////////////

- (void) setLooping: (BOOL) yesOrNo
{
    looping = yesOrNo;
}

- (BOOL) looping
{
    return looping;
}

- (void) setLoopStartIndex: (long) newLoopStartIndex
{
    loopStartIndex = newLoopStartIndex;
}

- (long) loopStartIndex
{
    return loopStartIndex;
}

- (void) setLoopEndIndex: (long) newLoopEndIndex
{
    loopEndIndex = newLoopEndIndex;
}

- (long) loopEndIndex
{
    return loopEndIndex;
}

////////////////////////////////////////////////////////////////////////////////

@end
