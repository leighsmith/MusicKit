/*
  $Id$

  Description:
    See the header description below.

  Original Author: SKoT McDonald, <skot@tomandandy.com>, tomandandy music inc.

  Sat 10-Feb-2001, Copyright (c) 2001 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/

#import <Foundation/Foundation.h>
#import "SndKit.h"
#import "SndStreamClient.h"
#import "SndPerformance.h"

/*!
    @class      SndPlayer
    @abstract   SndPlayer is the basic sound playing, streaming synthesizer. It simply
                maintains a queue of to-be-played and playing sounds, and mixes the
                active sounds down to its output buffer.
    @discussion For further info, see the base class: SndStreamClient
*/
@interface SndPlayer : SndStreamClient
{
/*! @var            toBePlayed An array of pending SndPerformance objects */
    NSMutableArray *toBePlayed;
/*! @var            playing An array of active SndPerformance objects */
    NSMutableArray *playing;
/*! @var            playinglock Provides thread safety on the SndPerformance arrays. */
    NSLock         *playingLock; // controls access to the toBePlayed and playing arrays.
}

/*!
    @method   player
    @abstract   Factory method
    @discussion To come
    @result     A freshly initialized and autoreleased SndPlayer
*/
+ player;

/*!
    @method   playSnd:withTimeOffset:
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
    @method playSnd:withTimeOffset:endAtIndex:
    @abstract Begin playing a Snd instance at some time in the future.
    @param s The sound to start playing
    @param inSeconds The future time interval in seconds when to start playing.
    @param endIndex The last sample of the sound to play; negative signals play all
    @result The SndPerformance object assocaited with this instance of the Snd's performance
*/
- (SndPerformance *) playSnd: (Snd*) s 
              withTimeOffset: (double) inSeconds
                beginAtIndex: (long) beginAtIndex
                  endAtIndex: (long) endIndex;
                  
- (SndPerformance *) playSnd: (Snd *) s
             atTimeInSeconds: (double) playT
                beginAtIndex: (long) beginAtIndex
                  endAtIndex: (long) endAtIndex;                  

- (SndPerformance *) playSnd: (Snd *) s
             atTimeInSeconds: (double) playT
       withDurationInSeconds: (double) d;                  

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
    @method stopPerformance:inFuture:
    @abstract Stop the given performance at some time in the future.
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
    @method   processBuffers
    @abstract   Main Snd performance method.
    @discussion The user shouldn't invoke this method - it is the internal synthesis
                method. Snds are mixed down into the output stream, performance 
                positions updated, playing and tobePlayed arrays updated as required. 
*/
- (void) processBuffers;

/*!
    @method init
    @abstract Initializer
    @result   Self.
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
    @method performancesOfSnd:
    @abstract Return an array of the performances of a given sound.
    @param    snd The Snd instance to check which performances are playing or pending play.
    @result   An array containing all performance instances of a particular Snd. 
*/
- (NSArray *) performancesOfSnd: (Snd *) snd;

@end
