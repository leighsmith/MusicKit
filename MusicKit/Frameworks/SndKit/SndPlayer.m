////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//
//  Sat 10-Feb-2001, Copyright (c) 2001 SndKit project
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
    tempBuffer = [[SndAudioBuffer alloc] initWithFormat:&s data:NULL];

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
  if (toBePlayed != nil) {
    [toBePlayed   release];
    toBePlayed = nil;
  }
  if (playing != nil) {
    [playing      release];
    playing = nil;
  }
  if (playingLock != nil) {
    [playingLock release];
    playingLock = nil;
  }
  if (removalArray != nil) {
    [removalArray release];
    removalArray = nil;
  }
  if (tempBuffer != nil) {
    [tempBuffer   release];
    tempBuffer = nil;
  }
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
  fprintf(stderr,"SndPlayer::description - playingLock locked\n");
#endif
  description = [NSString stringWithFormat: @"SndPlayer to be played %@, playing %@", toBePlayed, playing];
  [playingLock unlock];
#if SNDPLAYER_DEBUG
  fprintf(stderr,"SndPlayer::description - playingLock locked\n");
#endif
  return description;
}

////////////////////////////////////////////////////////////////////////////////
// _startPerformance:
//
// Start the given performance immediately by adding it to the playing list and
// firing off the delegate. We assume that any method calling this is doing the
// locking itself, hence this should not be used
// outside this class.
////////////////////////////////////////////////////////////////////////////////

- _startPerformance: (SndPerformance *) performance
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
  fprintf(stderr,"SndPlayer::stopPerformance - playingLock locked\n");
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
      if(stopAtSample < [[performance snd] sampleCount])
        [performance setEndAtIndex: stopAtSample];
    }
  }
  [playingLock unlock];
#if SNDPLAYER_DEBUG
  fprintf(stderr,"SndPlayer::stopPerformance - playingLock unlocked\n");
#endif
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// playSnd:
////////////////////////////////////////////////////////////////////////////////

- (SndPerformance *) playSnd: (Snd *) s
{
#if SNDPLAYER_DEBUG
  fprintf(stderr,"SndPlayer::playSnd (0)\n");
#endif
  return [self playSnd: s withTimeOffset: 0.0];
}

////////////////////////////////////////////////////////////////////////////////
// playSnd:withTimeOffset:
////////////////////////////////////////////////////////////////////////////////

- (SndPerformance *) playSnd: (Snd *) s withTimeOffset: (double) dt
{
#if SNDPLAYER_DEBUG
  fprintf(stderr,"SndPlayer::playSnd (1) withTimeOffset: %f\n",dt);
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

  playT = (dt < 0.0) ? 0.0 : [self streamTime] + dt;

#if SNDPLAYER_DEBUG
  fprintf(stderr,"SndPlayer::playSnd (2) withTimeOffset:%f begin:%li end:%li playT:%f clientNowTime:%f \n",
          dt,beginAtIndex,endAtIndex, playT,clientNowTime);
#endif
  perf = [self playSnd: s atTimeInSeconds: playT
          beginAtIndex: beginAtIndex endAtIndex: endAtIndex];
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
  fprintf(stderr,"SndPlayer::playSnd (3) atTimeInSeconds:%f begin:%li end:%li\n",
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

- (SndPerformance *) playSnd: (Snd *) s
             atTimeInSeconds: (double) playT
                beginAtIndex: (long) beginAtIndex
                  endAtIndex: (long) endAtIndex
{
  SndPerformance *thePerformance;

  if(endAtIndex > [s sampleCount]) {
    endAtIndex = [s sampleCount];	// Ensure the end of play can't exceed the sound data
  }
  if(endAtIndex == -1) {
    endAtIndex = [s sampleCount];	// Ensure the end of play can't exceed the sound data
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
  fprintf(stderr,"SndPlayer::PlaySnd (4) - atStreamTime:%f beginAtIndex:%li endAtIndex:%li clientTime:%f streamTime:%f\n",
          playT, beginAtIndex, endAtIndex, clientNowTime, [manager nowTime]);
#endif
  thePerformance = [SndPerformance performanceOfSnd: s
                                      playingAtTime: playT
                                       beginAtIndex: beginAtIndex
                                         endAtIndex: endAtIndex];
  [self addPerformance: thePerformance];
  return thePerformance;
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
    [aPerformance setPlayTime: streamTime];

    [playingLock lock];
#if SNDPLAYER_DEBUG
    fprintf(stderr,"SndPlayer::playSnd(4) playing lock...\n");
#endif
    [self _startPerformance: aPerformance];
    [playingLock unlock];
#if SNDPLAYER_DEBUG
    fprintf(stderr,"SndPlayer::playSnd(4) playing unlock...\n");
#endif
  }
  else {            // play later - we must insert the performance in Time Order
    int i, numToBePlayed, insertIndex;
    double playT = [aPerformance playTime];

    [playingLock lock];
#if SNDPLAYER_DEBUG
    fprintf(stderr,"SndPlayer::playSnd(4) playing lock...\n");
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
    fprintf(stderr,"SndPlayer::playSnd(4) playing unlock...\n");
#endif
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// stopSnd:withTimeOffset:
//
// stop all performances of the sound, at some point in the future.
//
// TODO: Need a lock around the tobePlayed array!!
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
  [toBePlayed removeObjectsInArray: pendingToRemove];
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
// This is the big cheese, the main enchilata.
//
// nowTime must be the CLIENT now time as this is a process-head capable
// thread - our client's synthesis sense of time is ahead of the manager's
// closer-to-absolute sense of time.
////////////////////////////////////////////////////////////////////////////////

- (void) processBuffers
{
  SndAudioBuffer* ab  = [self synthOutputBuffer];
  int    numberPlaying;
  int    i;

  [playingLock lock];
#if SNDPLAYER_DEBUG_SYNTHTHREAD_LOCKS
  fprintf(stderr,"[SndPlayer][SYNTH THREAD] playing lock...\n");
#endif

  // Are any of the 'toBePlayed' samples gonna fire off during this buffer?
  // If so, add 'em to the play array
  {
    double bufferDur     = [ab duration];
    double bufferEndTime = [self synthesisTime] + bufferDur;
    int numberToBePlayed = [toBePlayed count];
    for (i = 0; i < numberToBePlayed; i++) {
      SndPerformance *performance = [toBePlayed objectAtIndex: i];
      if ([performance playTime] < bufferEndTime) {
        float timeOffset  = ([performance playTime] - [self synthesisTime]);
        long thePlayIndex = [performance playIndex] - [[performance snd] samplingRate] * timeOffset;
        [removalArray addObject: performance];
        [performance setPlayIndex: thePlayIndex];
        [self _startPerformance: performance];
      }
    }
    [toBePlayed removeObjectsInArray: removalArray];
    [removalArray removeAllObjects];
  }

#if SNDPLAYER_DEBUG_SYNTHTHREAD_LOCKS
  fprintf(stderr,"[SndPlayer][SYNTH THREAD] playing zone...\n");
#endif
  // The playing-sounds-mixing-zone.

  numberPlaying = [playing count];

  if (numberPlaying > 0) {
    int buffLength = [ab lengthInSampleFrames];

    for (i = 0; i < numberPlaying; i++) {
      SndPerformance *performance = [playing objectAtIndex: i];
      Snd    *snd          = [performance snd];
      double  startIndex   = [performance playIndex];
      double  endAtIndex   = [performance endAtIndex];  // allows us to play a sub-section of a sound.
      double  deltaTime    = [performance deltaTime];
      double  stretchedBufferLength = deltaTime * buffLength;
      NSRange playRegion   = {startIndex, stretchedBufferLength + MAX(2, deltaTime)};

      if ([performance isPaused])
        continue;

      if (playRegion.length > endAtIndex - startIndex) {
        buffLength = (endAtIndex - startIndex) / deltaTime;
        playRegion.length = (buffLength) * deltaTime + MAX(2, deltaTime);
      }
      if (startIndex > -stretchedBufferLength) {
        if (startIndex < 0) {
          playRegion.length += startIndex;
          playRegion.location = 0;
        }
#if SNDPLAYER_DEBUG_SYNTHTHREAD_SNDPOSITIONS
        NSLog(@"[SndPlayer][SYNTH THREAD] startIndex = %.2f, endAtIndex = %.2f,  location = %d, length = %d\n",
              startIndex, endAtIndex, playRegion.location, playRegion.length);
#endif
      // Negative buffer length means the endAtIndex was moved before the current playIndex, so we should skip any mixing and stop.
        if (buffLength > 0) {
          int start = 0, end = buffLength;

          if (deltaTime == 1.0) {
            [snd fillAudioBuffer:tempBuffer withSamplesInRange: playRegion];
          }
          else {
            SndAudioBuffer *aBuffer = [[tempBuffer copy] setLengthInSampleFrames: playRegion.length];
            double offset = startIndex - (long)startIndex;
            [snd fillAudioBuffer:aBuffer withSamplesInRange:playRegion];

            [SndAudioBuffer resampleByLinearInterpolation: aBuffer
                                                     dest: tempBuffer
                                                   factor: deltaTime
                                                   offset: offset];

            [aBuffer release];
          }

          if (startIndex < 0) {
            start = -startIndex;
            start %= buffLength;
          }
          //          if (end / deltaTime >  startIndex - endAtIndex)  end = (endAtIndex - startIndex) / deltaTime;

#if SNDPLAYER_DEBUG_SYNTHTHREAD_SNDPOSITIONS
          NSLog(@"[SndPlayer][SYNTH THREAD] calling mixWithBuffer from SndPlayer processBuffers start = %ld, end = %ld\n", start, end);
#endif
          [performance processBuffer: tempBuffer];
          [ab mixWithBuffer: tempBuffer fromStart: start toEnd: end canExpand:YES];
#if SNDPLAYER_DEBUG_SYNTHTHREAD_SNDPOSITIONS
          NSLog(@"[SndPlayer][SYNTH THREAD] mixing buffer from %d to %d, playregion %d for %d, val at start = %f\n",
                start, end, playRegion.location, playRegion.length,
                (((short *)[snd data])[playRegion.location])/(float)32768);
#endif
        }
      }
      startIndex += stretchedBufferLength;
      [performance setPlayIndex: startIndex];
      
      // When at the end of sounds, signal the delegate and remove the performance.
      if (startIndex >= endAtIndex - 1.0) {
        [removalArray addObject: performance];
        [snd removePerformance: performance];

        /* sbrandon Nov 2001: now check thru all performances, and if this one was the last
          * one using this snd, we set the snd to SND_SoundStopped
          */
        if ([snd performanceCount] == 0) {
          [snd _setStatus: SND_SoundStopped];
        }

        /* sbrandon Nov 2001: re-instated delegate messaging, but fixed it up for multithreaded
          * use. Note that the arguments HAVE to be objects - hence arg1 here is not a SEL as one
          * would expect but an NSString, and we convert to a SEL in the Snd object.
          * Note also that the messages received in the main thread are asynchronous, being
          * received in the NSRunLoop in the same way that keyboard, mouse or GUI actions are
          * received.
          */
#if SNDPLAYER_DEBUG_SYNTHTHREAD_LOCKS
        fprintf(stderr,"[SndPlayer][SYNTH THREAD] sending delegate message...\n");
#endif
        [manager sendMessageInMainThreadToTarget: snd
                                             sel: @selector(tellDelegateString:duringPerformance:)
                                            arg1: @"didPlay:duringPerformance:"
                                            arg2: performance];
      }
    }
#if SNDPLAYER_DEBUG_SYNTHTHREAD_LOCKS
    fprintf(stderr,"[SndPlayer][SYNTH THREAD] playing remove...\n");
#endif
    if ([removalArray count] > 0) {
      [playing removeObjectsInArray: removalArray];
      if ([toBePlayed count] == 0 && [playing count] == 0) {
        if (!bRemainConnectedToManager) {
          active = FALSE;
#if SNDPLAYER_DEBUG_SYNTHTHREAD_SNDPOSITIONS
          fprintf(stderr,"[SndPlayer][SYNTH THREAD] Setting inactive...\n");
#endif
        }
        else {
#if SNDPLAYER_DEBUG_SYNTHTHREAD_SNDPOSITIONS
          fprintf(stderr,"[SndPlayer][SYNTH THREAD] remaining active...\n");
#endif
        }
      }
    }
  }
#if SNDPLAYER_DEBUG  
  {
    float min, max;
    [ab findMin: &min max: &max];
    printf("SndPlayer: min: %5.3f max: %5.3f\n",min, max);
  }
#endif
  
[playingLock unlock];
#if SNDPLAYER_DEBUG_SYNTHTHREAD_LOCKS
  fprintf(stderr,"[SndPlayer][SYNTH THREAD] playing unlock...\n");
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
