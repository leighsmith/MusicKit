////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    See header file description.
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
#import "SndPlayer.h"
#import "SndStreamManager.h"
#import "SndPerformance.h"
#import "SndAudioFader.h"

#define SNDPLAYER_DEBUG                          0
#define SNDPLAYER_DEBUG_SYNTHTHREAD_LOCKS        0
#define SNDPLAYER_DEBUG_SYNTHTHREAD_SNDPOSITIONS 0

////////////////////////////////////////////////////////////////////////////////
//  SndPlayer
////////////////////////////////////////////////////////////////////////////////

static SndPlayer *defaultSndPlayer;

@implementation SndPlayer

////////////////////////////////////////////////////////////////////////////////
// player
////////////////////////////////////////////////////////////////////////////////

+ player
{
  return [[SndPlayer new] autorelease];
}

+ (SndPlayer*) defaultSndPlayer
{
  if (defaultSndPlayer == nil) {
    defaultSndPlayer = [SndPlayer new];
  }
  return [[defaultSndPlayer retain] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
  self = [super init];
  if (self) {
    SndSoundStruct s;
      
    SNDStreamNativeFormat(&s); /* get maximum length for processing buffer */

    nativelyFormattedStreamingBuffer = [[SndAudioBuffer alloc] initWithFormat: &s data: NULL];
    
    bRemainConnectedToManager = TRUE;
    bAutoStartManager = TRUE;
    if (toBePlayed == nil)
      toBePlayed = [[NSMutableArray alloc] initWithCapacity: 10];
    else
      [toBePlayed removeAllObjects];

    if (playing == nil)
      playing = [[NSMutableArray alloc] initWithCapacity: 10];
    else
      [playing removeAllObjects];

    if (playingLock == nil)
      playingLock  = [NSRecursiveLock new];  // controls adding and removing sounds from the playing list.
    if (removalArray == nil)
      removalArray = [NSMutableArray new];

    [self setClientName: @"SndPlayer"];
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
    [toBePlayed release];
    toBePlayed = nil;
    [playing release];
    playing = nil;
    [playingLock release];
    playingLock = nil;
    [removalArray release];
    removalArray = nil;
    [nativelyFormattedStreamingBuffer release];
    nativelyFormattedStreamingBuffer = nil;
    [preemptingPerformance release];
    preemptingPerformance = nil;
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// description
////////////////////////////////////////////////////////////////////////////////

- (NSString*) description
{
  NSString *description;
  [playingLock lock];
#if SNDPLAYER_DEBUG
  NSLog(@"SndPlayer::description - playingLock locked\n");
#endif
  description = [NSString stringWithFormat: @"%@ to be played %@, playing %@", [super description], toBePlayed, playing];
  [playingLock unlock];
#if SNDPLAYER_DEBUG
  NSLog(@"SndPlayer::description - playingLock locked\n");
#endif
  return description;
}

////////////////////////////////////////////////////////////////////////////////
// startPerformance:
//
// Start the given performance immediately by adding it to the playing list and
// firing off the delegate. We assume that any method calling this is doing the
// locking itself, hence this should not be used outside this class.
////////////////////////////////////////////////////////////////////////////////

- startPerformance: (SndPerformance *) performance
{
  Snd *snd = [performance snd];
  [playing addObject: performance];
  // The delay between receiving this delegate and when the audio is actually played
  // is an extra buffer, therefore: delay == buffLength/sampleRate after the delegate
  // message has been received.

  [snd _setStatus:SND_SoundPlaying];
  //    [[performance snd] tellDelegate: @selector(willPlay:duringPerformance:)
  //                  duringPerformance: performance];
  [manager sendMessageInMainThreadToTarget: snd
                                       sel: @selector(tellDelegateString:duringPerformance:)
                                      arg1: @"willPlay:duringPerformance:"
                                      arg2: performance];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// stopPerformance:inFuture:
////////////////////////////////////////////////////////////////////////////////

- stopPerformance: (SndPerformance *) performance inFuture: (double) inSeconds
{
  double whenToStop;
  double beginPlayTime;
  long   stopAtSample;

  if(![self isActive]) {
    [[SndStreamManager defaultStreamManager] addClient: self];
  }
  [playingLock lock];
#if SNDPLAYER_DEBUG
  NSLog(@"SndPlayer::stopPerformance - playingLock locked\n");
#endif

  whenToStop = [self streamTime] + inSeconds;
  beginPlayTime = [performance playTime]; // in seconds
  if(whenToStop < beginPlayTime) {
    // stop before we even begin, delete the performance from the toBePlayed queue
    [toBePlayed removeObject: performance];
  }
  else {
    if ([performance isPaused] || inSeconds == 0.0) {
      [performance stopNow];
    }
    else {
      stopAtSample = (whenToStop - beginPlayTime) * [[performance snd] samplingRate];
      // NSLog(@"stopping at sample %ld\n", stopAtSample);
      // check stopAtSample since it could be beyond the length of the sound.
      // If so, leave it stop at the end of the sound.
      if(stopAtSample < [[performance snd] lengthInSampleFrames])
        [performance setEndAtIndex: stopAtSample];
    }
  }
  [playingLock unlock];
#if SNDPLAYER_DEBUG
  NSLog(@"SndPlayer::stopPerformance - playingLock unlocked\n");
#endif
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// playSnd:
////////////////////////////////////////////////////////////////////////////////

- (SndPerformance *) playSnd: (Snd *) s
{
#if SNDPLAYER_DEBUG
  NSLog(@"SndPlayer::playSnd (0)\n");
#endif
  return [self playSnd: s withTimeOffset: 0.0];
}

////////////////////////////////////////////////////////////////////////////////
// playSnd:withTimeOffset:
////////////////////////////////////////////////////////////////////////////////

- (SndPerformance *) playSnd: (Snd *) s withTimeOffset: (double) dt
{
#if SNDPLAYER_DEBUG
  NSLog(@"SndPlayer::playSnd (1) withTimeOffset: %f\n",dt);
#endif
  return [self playSnd: s withTimeOffset: dt beginAtIndex: 0 endAtIndex: -1];
}

////////////////////////////////////////////////////////////////////////////////
// playSnd:withTimeOffset:endAtIndex:
////////////////////////////////////////////////////////////////////////////////

- (SndPerformance *) playSnd: (Snd *) s
              withTimeOffset: (double) dt
                beginAtIndex: (long) beginAtIndex
                  endAtIndex: (long) endAtIndex
{
  SndPerformance *perf;
  double playT;

  if(![self isActive])
    [[SndStreamManager defaultStreamManager] addClient: self];

  playT = (dt < 0.0) ? [self streamTime] : [self streamTime] + dt;

#if SNDPLAYER_DEBUG
  NSLog(@"SndPlayer::playSnd (2) withTimeOffset:%f begin:%li end:%li playT:%f clientNowTime:%f\n",
          dt, beginAtIndex, endAtIndex, playT, clientNowTime);
#endif
  perf = [self playSnd: s
       atTimeInSeconds: playT
          beginAtIndex: beginAtIndex
	    endAtIndex: endAtIndex];
  return perf;
}

////////////////////////////////////////////////////////////////////////////////
// playSnd:atTimeInSeconds:withDurationInSeconds:startPositionInSeconds:durationInSeconds:
////////////////////////////////////////////////////////////////////////////////

- (SndPerformance *) playSnd: (Snd *) s
             atTimeInSeconds: (double) t
      startPositionInSeconds: (double) startPos
           durationInSeconds: (double) d
{
  long endIndex   = -1;
  long startIndex = 0;

  if (startPos > 0)
    startIndex =  startPos * [s samplingRate];
  if (d > 0)
    endIndex   =  startIndex + d * [s samplingRate];

#if SNDPLAYER_DEBUG
  NSLog(@"SndPlayer::playSnd (3) atTimeInSeconds:%f begin:%li end:%li\n",
          t,startIndex,endIndex);
#endif
  return [self playSnd: s
       atTimeInSeconds: t
          beginAtIndex: startIndex
            endAtIndex: endIndex];
}

////////////////////////////////////////////////////////////////////////////////
// playSnd:atTimeInSeconds:beginAtIndex:endAtIndex:
////////////////////////////////////////////////////////////////////////////////

- (SndPerformance *) playSnd: (Snd *) sound
             atTimeInSeconds: (double) playTime
                beginAtIndex: (long) beginAtIndex
                  endAtIndex: (long) endAtIndex
{
    SndPerformance *thePerformance;

    if(endAtIndex > [sound lengthInSampleFrames]) {
	endAtIndex = [sound lengthInSampleFrames];	// Ensure the end of play can't exceed the sound data
    }
    if(endAtIndex == -1) {
	endAtIndex = [sound lengthInSampleFrames];	// Ensure the end of play can't exceed the sound data
    }
    if (beginAtIndex > endAtIndex) {
#if SNDPLAYER_DEBUG
	NSLog(@"SndPlayer::playSnd:atTimeInSeconds:beginAtIndex:endAtIndex: - WARNING: beginAtIndex > endAtIndex - ignoring play cmd");
#endif
	return nil;
    }
    if(beginAtIndex < 0) {
	beginAtIndex = 0;	// Ensure the end of play can't exceed the sound data
    }
    if(![self isActive]) {
	[[SndStreamManager defaultStreamManager] addClient: self];
    }
#if SNDPLAYER_DEBUG
    NSLog(@"SndPlayer::playSnd (4) - atStreamTime:%f beginAtIndex:%li endAtIndex:%li clientTime:%f streamTime:%f\n",
          playTime, beginAtIndex, endAtIndex, clientNowTime, [manager nowTime]);
#endif
    thePerformance = [SndPerformance performanceOfSnd: sound
					playingAtTime: playTime
					 beginAtIndex: beginAtIndex
					   endAtIndex: endAtIndex];
    
    if([sound useVolumeWhenPlaying] || [sound useBalanceWhenPlaying]) {
	// Set the initial volume and balance of the performance from the sound.
	// Do balance and volume modification of each performance using its processor chain postFader SndAudioFader
	SndAudioProcessorChain *performanceAudioProcessorChain = [SndAudioProcessorChain audioProcessorChain];
	SndAudioFader *performanceAudioFader;    
    
	[thePerformance setAudioProcessorChain: performanceAudioProcessorChain];
	performanceAudioFader = [performanceAudioProcessorChain postFader];
	if([sound useVolumeWhenPlaying])
	    [performanceAudioFader setAmp: [sound getAllChannelsVolume] clearingEnvelope: NO];
	if([sound useBalanceWhenPlaying])
	    [performanceAudioFader setBalance: [sound balance] clearingEnvelope: NO];
    }

    // Save the performance so we know which performance not to reset playIndexes for.
    // All other performances have their playIndexes reset when preempted.
    [preemptingPerformance release];
    preemptingPerformance = [thePerformance retain];
    
    // we need to add the performance before we preempt the queued stream so that the new performance will be mixed in.
    [self addPerformance: thePerformance];

    // If we are attempting to play the sound immediately, i.e that the playTime precedes the stream time,
    // force the stream to update so we hear the new sounds begin playing immediately,
    // rather than after the lag from playing out any processed buffers waiting to play.
    if(playTime <= [manager nowTime])
	[self preemptQueuedStream];

    return thePerformance;
}

- (double) preemptQueuedStream
{
    // The playIndexes need to be reset before the super class' preemption occurs (so that mixing will correctly be using
    // backtracked performances, other than the newly added performance).
    int numberPlaying;
    int performanceIndex;
    double preemptionInSeconds;
    // So we need to know how long to preempt the playIndexes from, since that is dependent on the super class.
    long preemptionInSamples = [self outputLatencyInSamples];
    
    // We need to update the playIndexes of all the playing performances (but not the performance just added).
    [playingLock lock];
    numberPlaying = [playing count];

    // From the preemption time in seconds, determine the new playIndex for each performance.
    for(performanceIndex = 0; performanceIndex < numberPlaying; performanceIndex++) {
	SndPerformance *performance = [playing objectAtIndex: performanceIndex];
	
	// We need to know which performance has just been added so we don't modify the playIndex of that one.
	if(![performance isEqual: preemptingPerformance]) {
#if SNDPLAYER_DEBUG
	    NSLog(@"preemptionInSamples %ld performance %d playIndex %ld\n",
		preemptionInSamples, performanceIndex, [performance playIndex]);
#endif
	    [performance rewindPlayIndexBySamples: preemptionInSamples];
	}
    }
    [playingLock unlock];

    // The adjustments to the queue of streaming buffers and the clientNowTime is performed in the super class once the playing
    // performances have had their playIndexes updated.
    preemptionInSeconds = [super preemptQueuedStream];

    return preemptionInSeconds;
}

////////////////////////////////////////////////////////////////////////////////
// addPerformance:
////////////////////////////////////////////////////////////////////////////////

- addPerformance: (SndPerformance*) aPerformance
{
    if(![self isActive] && bAutoStartManager) {
	[[SndStreamManager defaultStreamManager] addClient: self];
    }
    [[aPerformance snd] addPerformance: aPerformance];

    if ([aPerformance playTime] <= clientNowTime) {  // play now!
	double streamTime = [self isActive] ? [self streamTime] : 0;

#if SNDPLAYER_DEBUG
	NSLog(@"aPerformance playTime = %lf, streamTime = %lf\n", [aPerformance playTime], streamTime);
#endif
	[aPerformance setPlayTime: streamTime];
	
	[playingLock lock];
#if SNDPLAYER_DEBUG
	NSLog(@"SndPlayer::playSnd(4) playing got lock, starting performance...\n");
#endif
	[self startPerformance: aPerformance];
	[playingLock unlock];
#if SNDPLAYER_DEBUG
	NSLog(@"SndPlayer::playSnd(4) playing unlocked...\n");
#endif
    }
    else {
	// play later - we must insert the performance into the toBePlayed queue in time order
	int i, numToBePlayed, insertIndex;
	double playT = [aPerformance playTime];

	[playingLock lock];
#if SNDPLAYER_DEBUG
	NSLog(@"SndPlayer::playSnd(4) playing lock...\n");
#endif
	numToBePlayed = [toBePlayed count];
	insertIndex = numToBePlayed;
	for (i = 0; i < numToBePlayed; i++) {
	    SndPerformance *thisPerf = [toBePlayed objectAtIndex: i];
	    if ([thisPerf playTime] > playT) {
		insertIndex = i;
		break;
	    }
	}
	[toBePlayed insertObject: aPerformance atIndex: i];
	[playingLock unlock];
#if SNDPLAYER_DEBUG
	NSLog(@"SndPlayer::playSnd(4) playing unlock...\n");
#endif
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// stopSnd:withTimeOffset:
//
// stop all performances of the sound, at some point in the future.
//
// TODO: Need a lock around the toBePlayed array!!
////////////////////////////////////////////////////////////////////////////////

- stopSnd: (Snd *) s withTimeOffset: (double) inSeconds
{
  NSArray *performancesToStop = [s performances];
  NSMutableArray *pendingToRemove = [[NSMutableArray alloc] init];
  int i, count = [performancesToStop count];

  for (i = 0; i < count; i++) {
    SndPerformance *thePerf = [performancesToStop objectAtIndex: i];
    [self stopPerformance: thePerf inFuture: inSeconds];
  }

  count = [toBePlayed count];

  //  printf("There are %i pending...\n",count);
  for (i = 0; i < count; i++) {
    SndPerformance *thePerf = [toBePlayed objectAtIndex: i];
    if (s == [thePerf snd])
      [pendingToRemove addObject: thePerf];
  }
  //  printf("Found %i pending - killed \n",[pendingToRemove count]);
  // [playingLock lock];
  [toBePlayed removeObjectsInArray: pendingToRemove];
  // [playingLock unlock];
  [pendingToRemove release];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// stopSnd
// stop all performances of the sound immediately.
////////////////////////////////////////////////////////////////////////////////

- stopSnd: (Snd *) s
{
  return [self stopSnd: s withTimeOffset: 0.0];
}

////////////////////////////////////////////////////////////////////////////////
// pauseSnd
// pause ALL performances of the sound immediately.
////////////////////////////////////////////////////////////////////////////////

- pauseSnd: (Snd*) s
{
  NSArray *performancesToPause = [s performances];
  int i, count = [performancesToPause count];

  for (i = 0; i < count; i++) {
    SndPerformance *thePerf = [performancesToPause objectAtIndex: i];
    [thePerf setPaused: YES];
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// processBuffers
//
// This is the big cheese, the main enchilada.
//
// nowTime must be the CLIENT now time as this is a process-head capable
// thread - our client's synthesis sense of time is ahead of the manager's
// closer-to-absolute sense of time.
////////////////////////////////////////////////////////////////////////////////

- (void) processBuffers
{
    SndAudioBuffer *currentSynthOutputBuffer = [self synthOutputBuffer];
    int    numberPlaying;
    int    i;

    [playingLock lock];
#if SNDPLAYER_DEBUG_SYNTHTHREAD_LOCKS
    NSLog(@"[SndPlayer][SYNTH THREAD] playing lock...\n");
#endif
    
    // Are any of the 'toBePlayed' samples gonna fire off during this buffer?
    // If so, add 'em to the play array
    {
	double bufferDur     = [currentSynthOutputBuffer duration];
	double bufferEndTime = [self synthesisTime] + bufferDur;
	int numberToBePlayed = [toBePlayed count];
	for (i = 0; i < numberToBePlayed; i++) {
	    SndPerformance *performance = [toBePlayed objectAtIndex: i];
	    if ([performance playTime] < bufferEndTime) {
		float timeOffset  = ([performance playTime] - [self synthesisTime]);
		long thePlayIndex = [performance playIndex] - [[performance snd] samplingRate] * timeOffset;
		[removalArray addObject: performance];
		[performance setPlayIndex: thePlayIndex];
		[self startPerformance: performance];
	    }
	}
	[toBePlayed removeObjectsInArray: removalArray];
	[removalArray removeAllObjects];
    }

#if SNDPLAYER_DEBUG_SYNTHTHREAD_LOCKS
    NSLog(@"[SndPlayer][SYNTH THREAD] playing zone...\n");
#endif
    // The playing-sounds-mixing-zone.

    numberPlaying = [playing count];

    if (numberPlaying > 0) {
        long synthOutputBufferLength = [currentSynthOutputBuffer lengthInSampleFrames];
	
	for (i = 0; i < numberPlaying; i++) {
	    SndPerformance *performance = [playing objectAtIndex: i];
            Snd *snd = [performance snd];

	    if ([performance isPaused])
		continue;

	    // Ensure we have the buffer set big enough to accept what we want to read. This needs doing since
	    // at the end of a sound, the dataLength will be set shorter than the output buffer length.
	    [nativelyFormattedStreamingBuffer setLengthInSampleFrames: synthOutputBufferLength]; 
	    synthOutputBufferLength = [performance retrievePerformBuffer: nativelyFormattedStreamingBuffer
								ofLength: synthOutputBufferLength];
#if SNDPLAYER_DEBUG
	    NSLog(@"[SndPlayer] retrieved from performance %d, buffer %@ at clock %ld\n", i, nativelyFormattedStreamingBuffer, clock());
#endif
	    [currentSynthOutputBuffer mixWithBuffer: nativelyFormattedStreamingBuffer
					  fromStart: 0
					      toEnd: synthOutputBufferLength
					  canExpand: YES];
	    
            // When at the end of sounds, signal the delegate and remove the performance.
	    if ([performance atEndOfPerformance] == YES) {
		[removalArray addObject: performance];
		[snd removePerformance: performance];

		/* Check thru all performances, and if this one was the last
		 * one using this snd, we set the snd to SND_SoundStopped
		 */
		if ([snd performanceCount] == 0) {
		    [snd _setStatus: SND_SoundStopped];
		}

		/* Multithreaded delegate messaging. Note that the arguments HAVE to be objects -
		 * hence arg1 here is not a SEL as one would expect but an NSString, and we convert to a SEL in the Snd object.
		 * Note also that the messages received in the main thread are asynchronous, being
		 * received in the NSRunLoop in the same way that keyboard, mouse or GUI actions are
		 * received.
		 */
#if SNDPLAYER_DEBUG_SYNTHTHREAD_LOCKS
		NSLog(@"[SndPlayer][SYNTH THREAD] sending delegate message...\n");
#endif
		[manager sendMessageInMainThreadToTarget: snd
						     sel: @selector(tellDelegateString:duringPerformance:)
						    arg1: @"didPlay:duringPerformance:"
						    arg2: performance];
	    }
	}
#if SNDPLAYER_DEBUG_SYNTHTHREAD_LOCKS
	NSLog(@"[SndPlayer][SYNTH THREAD] playing remove...\n");
#endif
	if ([removalArray count] > 0) {
	    [playing removeObjectsInArray: removalArray];
	    if ([toBePlayed count] == 0 && [playing count] == 0) {
		if (!bRemainConnectedToManager) {
		    active = FALSE;
#if SNDPLAYER_DEBUG_SYNTHTHREAD_SNDPOSITIONS
		    NSLog(@"[SndPlayer][SYNTH THREAD] Setting inactive...\n");
#endif
		}
		else {
#if SNDPLAYER_DEBUG_SYNTHTHREAD_SNDPOSITIONS
		    NSLog(@"[SndPlayer][SYNTH THREAD] remaining active...\n");
#endif
		}
	    }
	}
    }
#if SNDPLAYER_DEBUG
    NSLog(@"[SndPlayer] synthOutputBuffer: %@\n", currentSynthOutputBuffer);
#endif

    [playingLock unlock];
#if SNDPLAYER_DEBUG_SYNTHTHREAD_LOCKS
    NSLog(@"[SndPlayer][SYNTH THREAD] playing unlock...\n");
#endif

}

////////////////////////////////////////////////////////////////////////////////
// setRemainConnectedToManager:
////////////////////////////////////////////////////////////////////////////////

- setRemainConnectedToManager: (BOOL) b
{
    bRemainConnectedToManager = b;
    return self;
}

- (BOOL) remainConnectedToManager
{
    return bRemainConnectedToManager;
}

- (BOOL) autoStartManager
{
    return bAutoStartManager;
}

- setAutoStartManager: (BOOL) b
{
    bAutoStartManager = b;
    return self;
}

////////////////////////////////////////////////////////////////////////////////

@end
