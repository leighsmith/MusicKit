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
//  Sat 28-Feb-2001, Copyright (c) 2001 SndKit project All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import "SndPlayer.h"
#import "SndPerformance.h"

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
     playTime: (double) _playTime
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
    endAtIndex   = startAtIndex + samplingRate * duration / deltaTime;
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

- processBuffer: (SndAudioBuffer*) aBuffer
{
  actualTime +=  [aBuffer duration];
  if (audioProcessorChain != nil) {
//printf("time: %f\n",relativePlayTime);
    [audioProcessorChain processBuffer: aBuffer forTime: actualTime];
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////

@end
