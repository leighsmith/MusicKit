////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    See the header description below.
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

#ifndef __SND_PLAYER_H__
#define __SND_PLAYER_H__

#import <Foundation/Foundation.h>
#import "SndStreamClient.h"
#import "SndPerformance.h"

/*!
@class SndPlayer
@abstract   SndPlayer is the basic sound playing, streaming synthesizer. It simply
            maintains a queue of to-be-played and playing sounds, and mixes the
            active sounds down to its output buffer.
@discussion For further info, see the base class: SndStreamClient
*/
@interface SndPlayer : SndStreamClient
{
/*! @var             toBePlayed An array of pending SndPerformance objects. */
    NSMutableArray  *toBePlayed;
/*! @var             playing An array of actively playing SndPerformance objects. */
    NSMutableArray  *playing;
/*! @var             playinglock Provides thread safety on the SndPerformance arrays.
	             It controls access to the toBePlayed and playing arrays.
 */
    NSRecursiveLock *playingLock;
/*! @var             bRemainConnectedToManager Indicates the SndPlayer disconnection behaviour
	             when no sounds remain in the pending or play arrays.
*/
    BOOL             bRemainConnectedToManager;
/*! @var             removalArray Holds those performances which will be removed after completing playback.
	             TODO I'm guessing this is an ivar rather than just a local variable to save time creating the object,
	             by reusing it? Strikes me it would be efficient to simply release the damn thing than to actually
	             empty it each time. This needs testing.
 */
    NSMutableArray  *removalArray;
/*! @var             nativelyFormattedStreamingBuffer The audio buffer used to hold audio
	             retrieved from a performance. As the name suggests, it will be in the
	             format expected by the streaming hardware.
 */
    SndAudioBuffer  *nativelyFormattedStreamingBuffer;

/*! @var             bAutoStartManager Indicates that the SndStreamManager should be automatically
	             started when playing of sounds first begins.
 */
    BOOL bAutoStartManager;
/*! @var	     preemptingPerformance Holds a performance that is causing preemption in the output queue.
	             This occurs when attempting to perform a sound immediately, causing cancellation of queued
	             streaming buffers. The cancellation of the output queue forces all currently sounding performances
	             to have their playIndexes reset <i>except</i> for the performance that caused the preemption
	             in the first place.
 */
    SndPerformance *preemptingPerformance;
}

/*!
  @method     player
  @abstract   Factory method
  @discussion To come
  @result     A freshly initialized and autoreleased SndPlayer
*/
+ player;
/*!
  @method     defaultSndplayer
  @abstract   Factory method
  @discussion To come
  @result     The default SndPlayer object
*/
+ (SndPlayer*) defaultSndPlayer;
/*!
  @method     init
  @abstract   Initializer
  @result     Self.
*/
- init;
/*!
  @method dealloc
  @abstract Destructor
*/
- (void) dealloc;
/*!
  @method description
  @abstract Produces a brief description of the SndPlayer.
  @result   NSString containing a brief description of the object
*/
- (NSString *) description;
/*!
  @method     playSnd:withTimeOffset:
  @abstract   Begin playing a Snd instance immediately.
  @param      s The sound to start playing
  @result     The SndPerformance object assocaited with this instance of the Snd's performance 
*/
- (SndPerformance *) playSnd: (Snd*) s;

/*!
  @method   playSnd:withTimeOffset:
  @abstract   Begin playing a Snd instance at some in point time in the future.
  @param      s The sound to start playing
  @param      inSeconds The future time interval in seconds when to start playing.
  @result     The SndPerformance object assocaited with this instance of the Snd's performance
*/
- (SndPerformance *) playSnd: (Snd*) s withTimeOffset: (double) inSeconds;

/*!
  @method playSnd:withTimeOffset:beginAtIndex:endAtIndex:
  @abstract Begin playing a Snd instance at some time in the future.
  @param s The sound to start playing
  @param inSeconds The future time interval in seconds when to start playing.
  @param beginIndex The first sample of the sound to play.
  @param endIndex The last sample of the sound to play.
  @result The SndPerformance object assocaited with this instance of the Snd's performance
*/
- (SndPerformance *) playSnd: (Snd*) s 
              withTimeOffset: (double) inSeconds
                beginAtIndex: (unsigned long) beginAtIndex
                  endAtIndex: (unsigned long) endIndex;

/*!
  @method playSnd:atTimeInSeconds:beginAtIndex:endAtIndex:
  @abstract Begin playing a Snd instance at some absolute stream time.
  @param s The sound to start playing
  @param playT The absolute stream time, in seconds, to start play back.
  @param beginIndex The first sample of the sound to play.
  @param endIndex The last sample of the sound to play.
  @result The SndPerformance object assocaited with this instance of the Snd's performance
*/
- (SndPerformance *) playSnd: (Snd *) s
             atTimeInSeconds: (double) playT
                beginAtIndex: (unsigned long) beginAtIndex
                  endAtIndex: (unsigned long) endAtIndex;

/*!
  @method playSnd:atTimeInSeconds:startPositionInSeconds:durationInSeconds:
  @abstract Begin playing a Snd instance at some absolute stream time.
  @param  s The sound to start playing
  @param  playT The absolute stream time, in seconds, to start play back.
  @param  startpos The play start position within the snd
  @param  d The duration of snd playback, in seconds 
  @result The SndPerformance object assocaited with this instance of the Snd's performance
*/
- (SndPerformance *) playSnd: (Snd *) s
             atTimeInSeconds: (double) playT
      startPositionInSeconds: (double) startpos
           durationInSeconds: (double) d;                  
/*!
  @method stopSnd:withTimeOffset:
  @abstract Stop all performances of the sound, at some point in the future.
  @param s The sound to stop.
  @param inSeconds The future time interval when to stop playing.
  @result Self.
*/
- stopSnd: (Snd*) s withTimeOffset: (double) inSeconds;
/*!
  @method stopSnd:
  @abstract Stop all performances of the sound immediately.
  @param    s The sound to stop.
  @result   Self.
*/
- stopSnd: (Snd *) s;
/*!
  @method     stopPerformance:inFuture:
  @abstract   Stop the given performance at some time in the future.
  @discussion Stop the given performance at some time in the future by adjusting it's playback ending
     (i.e sample accurate stopping for those into buzz-words). When the playback reaches the
     new endAtTime, the stop delegate message will be fired off then and the performance removed from
     the playing queue. If the request to stop precedes the start time, the performance is removed
     from the toBePlayed queue.
  @param performance The SndPerformance instance to stop.
  @param inSeconds The future time interval when to stop playing.
  @result
*/
- stopPerformance: (SndPerformance *) performance inFuture: (double) inSeconds;
/*!
  @method     pauseSnd:
  @abstract   Pause all performances of the sound immediately.
  @discussion Will pause PLAYING sound performances at their current position,
              but any PENDING sound performances will still have their
              time-to-start decremented by the SndPlayer as usual. Once the
              pending sound performances are added to the play queue, they
              will pause at their start position.
  @param      s The sound to pause.
  @result     Returns self.
*/
- pauseSnd: (Snd*) s;
/*!
  @method     processBuffers
  @abstract   Main Snd performance method.
  @discussion The user shouldn't invoke this method - it is the internal synthesis
              method. Snds are mixed down into the output stream, performance 
              positions updated, playing and tobePlayed arrays updated as required. 
*/
- (void) processBuffers;
/*!
  @method     setRemainConnectedToManager:
  @abstract   Sets the SndPlayer disconnection behaviour when no sounds
              remain in the pending or play arrays. 
  @discussion By default, the SndPlayer remains connected to the stream 
              manager, which in turn means that streaming is still active. 
              If you are only playing sounds occassionally, you may not wish 
              to incur this slight overhead. The trade off is that if 
              disconnection is set to be the behaviour, you will have a higher
              performance cost when starting the play back of a new sound in 
              the future, as new threads are brought into existance, and 
              streaming is started up.
*/
- setRemainConnectedToManager: (BOOL) b;

/*!
  @method remainConnectedToManager;
  @discussion Indicates the current setting if the SndPlayer will remain connected to
              the stream manager when no sounds are pending or playing.
  @result Returns TRUE if the SndPlayer will remain connected to the stream manager when
          no sounds are pending or playing, FALSE if it will disconnect.
*/
- (BOOL) remainConnectedToManager;
 
/*!
 @method addPerformance:
 @discussion Adds the performance to the list of those currently being played.
 @param  aPerformance A SndPerformance instance.
*/
- addPerformance: (SndPerformance*) aPerformance;

/*!
  @method     preemptQueuedStream
  @discussion Resets the playIndexes of all currently playing performances back to where
              the preemption occurs.
  @result     Returns the number of seconds that the stream has been preempted by.
*/
- (double) preemptQueuedStream;

/*!
  @method setAutoStartManager:
  @discussion Assigns whether to automatically start the SndStreamManager controlling the
              the synthesis process when a sound is first played.
  @param yesOrNo If yesOrNo is YES, the SndStreamManager will be automatically started, if NO, it will not be.
 */
- setAutoStartManager: (BOOL) yesOrNo;

/*!
  @method autoStartManager
  @discussion Returns the current state of whether the SndStreamManager will be automatically
              started when the SndPlayer is started.
  @result Returns YES if the SndStreamManager will be automatically started, NO if not.
 */
- (BOOL) autoStartManager;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
