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
//  Copyright (c) 2001-2002, The MusicKit Project.  All rights reserved.
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
  return [self initWithSnd:s playingAtTime:t beginAtIndex: 0 endAtIndex:[s sampleCount]];
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
    snd          = [s retain];
    playTime     = _playTime;
    deltaTime    = _deltaTime;

    startAtIndex = samplingRate * startPosition;
    playIndex    = startAtIndex;
    endAtIndex   = startAtIndex + samplingRate * duration * deltaTime;
    actualTime   = 0.0;
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
// performance would never match unless it is playing at exactly same sample.
////////////////////////////////////////////////////////////////////////////////

- (BOOL) isEqual: (id) anotherPerformance
{
  BOOL equal = ((SndPerformance *) anotherPerformance)->snd == snd &&
  ((SndPerformance *) anotherPerformance)->playTime == playTime &&
  ((SndPerformance *) anotherPerformance)->startAtIndex == startAtIndex &&
  ((SndPerformance *) anotherPerformance)->endAtIndex == endAtIndex &&
  ((SndPerformance *) anotherPerformance)->deltaTime == deltaTime ;
  // NSLog(@"checking if equal %@ vs. %@ = %s\n", self, anotherPerformance, equal ? "YES" : "NO");
  return equal;
}

////////////////////////////////////////////////////////////////////////////////
// description
////////////////////////////////////////////////////////////////////////////////

- (NSString *) description
{
  return [NSString stringWithFormat: @"%@, playing at %f, from %ld, to %ld", snd, playTime, startAtIndex, endAtIndex];
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

- (double) playIndex
{
  return playIndex;
}

////////////////////////////////////////////////////////////////////////////////
// setPlayIndex:
////////////////////////////////////////////////////////////////////////////////

- (void) setPlayIndex: (double) newPlayIndex
{
    // If we are going to move the play index after the end index, allow that,
    // but adjust the end index in order to stay legal.
    if(newPlayIndex > endAtIndex)
	endAtIndex = newPlayIndex;
    playIndex = newPlayIndex;
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


////////////////////////////////////////////////////////////////////////////////
// AudioProcessorChain stuff
////////////////////////////////////////////////////////////////////////////////

- (SndAudioProcessorChain*) audioProcessorChain
{
  return [[audioProcessorChain retain] autorelease];
}

- setAudioProcessorChain: (SndAudioProcessorChain*) anAudioProcessorChain
{
  if (audioProcessorChain)
    [audioProcessorChain release];
  audioProcessorChain = [anAudioProcessorChain retain];
  return self;
}

// Fills the given buffer with sound data, reading from the playIndex up until endAtIndex
// (which allows us to play a sub-section of a sound). playIndex is updated, and looping is
// respected.
- (long) retrieveAPerformBuffer: (SndAudioBuffer *) bufferToFill ofLength: (long) buffLength
{
    // deltaTime may be a misnomer, it is a multiple of buffers
    double  stretchedBufferLength = deltaTime * buffLength;
    // NSRange retrieveRegion = {playIndex, stretchedBufferLength + MAX(2, deltaTime)};
    NSRange retrieveRegion = {playIndex, stretchedBufferLength};
    BOOL atEndOfLoop = looping && retrieveRegion.length > loopEndIndex - playIndex;

    if (atEndOfLoop) {	// retrieve up to the end of the loop
	retrieveRegion.length = loopEndIndex - playIndex;
    }
    else if (retrieveRegion.length > endAtIndex - playIndex) {
	buffLength = (endAtIndex - playIndex) / deltaTime;
	// retrieveRegion.length = buffLength * deltaTime + MAX(2, deltaTime);
	retrieveRegion.length = buffLength * deltaTime;
    }
    if (playIndex > -stretchedBufferLength) {
	if (playIndex < 0) {
	    retrieveRegion.length += playIndex;
	    retrieveRegion.location = 0;
	}
#if SNDPERFORMANCE_DEBUG_RETRIEVE_BUFFER
	NSLog(@"[SndPerformance][SYNTH THREAD] playIndex = %.2f, endAtIndex = %ld, retrieve region location = %d, length = %d\n",
              playIndex, endAtIndex, retrieveRegion.location, retrieveRegion.length);
#endif
	// Negative or zero buffer length means the endAtIndex was moved before or to the current playIndex,
	// so we should skip any mixing and stop.
	// Nowdays, with better checking on the updates of endAtIndex and playIndex this should never occur, so this check is probably redundant.
	if (buffLength > 0) {
#if SNDPERFORMANCE_DEBUG_RETRIEVE_BUFFER
	    int start = 0;
	    int end = buffLength;
#endif

	    if (deltaTime == 1.0) {
		// NSLog(@"bufferToFill dataFormat before processing 1 %d\n", [bufferToFill dataFormat]);
		[snd fillAudioBuffer: bufferToFill withSamplesInRange: retrieveRegion];
		// NSLog(@"bufferToFill dataFormat before processing 2 %d\n", [bufferToFill dataFormat]);
	    }
	    else {
		SndAudioBuffer *aBuffer = [[bufferToFill copy] setLengthInSampleFrames: retrieveRegion.length];
		double offset = playIndex - (long)playIndex;
		[snd fillAudioBuffer: aBuffer withSamplesInRange: retrieveRegion];

		[SndAudioBuffer resampleByLinearInterpolation: aBuffer
							 dest: bufferToFill
						       factor: deltaTime
						       offset: offset];
		[aBuffer release];
	    }


	    if(atEndOfLoop) {
		// If we are at the end of the loop, copy in zero or more loop regions (when the loop is small)
		// then any remaining beginning of the loop.
		int loopLength = loopEndIndex - loopStartIndex;
		long fillFrom = retrieveRegion.length;
		long bufferLengthToFill = buffLength - fillFrom;

		while(bufferLengthToFill > 0 && loopLength > 0) {
		    NSRange loopRegion;

		    loopRegion.location = loopStartIndex;
		    loopRegion.length = (bufferLengthToFill > loopLength) ? loopLength : bufferLengthToFill;
		    [snd insertIntoAudioBuffer: bufferToFill startingAt: fillFrom samplesInRange: loopRegion];
		    playIndex = loopRegion.location + loopRegion.length;
		    fillFrom += loopRegion.length; 
		    bufferLengthToFill -= loopRegion.length;
#if SNDPERFORMANCE_DEBUG_RETRIEVE_BUFFER
		    NSLog(@"playIndex = %.2f, fillFrom = %d, bufferLengthToFill = %d\n", playIndex, fillFrom, bufferLengthToFill);
#endif
		}
	    }
	    else
		playIndex += retrieveRegion.length;

	    /*
	    if (playIndex < 0) {
		start = -playIndex;
		start %= buffLength;
	    }
	    */
	    
	    // if (end / deltaTime >  playIndex - endAtIndex)  end = (endAtIndex - playIndex) / deltaTime;
		
	    actualTime +=  [bufferToFill duration];
	    if (audioProcessorChain != nil) {
                 // printf("time: %f\n",relativePlayTime);
		[audioProcessorChain processBuffer: bufferToFill forTime: actualTime];
	    }

#if SNDPERFORMANCE_DEBUG_RETRIEVE_BUFFER
	    NSLog(@"[SndPerformance][SYNTH THREAD] will mix buffer from %d to %d, retrieveRegion %d for %d, val at start = %f\n",
	          start, end, retrieveRegion.location, retrieveRegion.length,
	          (((short *) [snd data])[retrieveRegion.location]) / (float) 32768);
#endif
	}
    }
    else
	playIndex += stretchedBufferLength;
    return buffLength;
}

- (BOOL) atEndOfPerformance
{
    return playIndex >= endAtIndex - 1.0;
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
