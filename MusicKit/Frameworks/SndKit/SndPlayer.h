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
    @baseclass  SndStreamClient
    @abstract   SndPlayer is the basic sound playing, streaming synthesizer. It simply
                maintains a queue of to-be-played and playing sounds, and mixes the
                active sounds down to its output buffer.
    @discussion For further info, see the base class: SndStreamClient
    @var        toBePlayed An array of pending SndPerformance objects
    @var        playing An array of active SndPerformance objects
    @var        playinglock Provides thread safety on the SndPerformance arrays.
*/
@interface SndPlayer : SndStreamClient
{
    NSMutableArray *toBePlayed;
    NSMutableArray *playing;
    NSLock *playingLock; // controls access to the toBePlayed and playing arrays.
}

/*!
    @method player
    @abstract Factory method
    @discussion To come
    @result
*/
+ player;

/*!
    @method playSnd:withTimeOffset:
    @abstract Begin playing a Snd instance immediately.
    @param s The sound to start playing
    @result
*/
- (SndPerformance *) playSnd: (Snd*) s;

/*!
    @method playSnd:withTimeOffset:
    @abstract Begin playing a Snd instance at some in point time in the future.
    @param s The sound to start playing
    @param inSeconds The future time interval in seconds when to start playing.
    @result
*/
- (SndPerformance *) playSnd: (Snd*) s withTimeOffset: (double) inSeconds;

/*!
    @method playSnd:withTimeOffset:endAtIndex:
    @abstract Begin playing a Snd instance at some time in the future.
    @param s The sound to start playing
    @param inSeconds The future time interval in seconds when to start playing.
    @param endIndex The last sample of the sound to play; negative signals play all
    @result
*/
- (SndPerformance *) playSnd: (Snd*) s 
              withTimeOffset: (double) inSeconds
                  endAtIndex: (double) endIndex;

/*!
    @method stopSnd:withTimeOffset:
    @abstract Stop all performances of the sound, at some point in the future.
    @param s The sound to stop.
    @param inSeconds The future time interval when to stop playing.
    @result
*/
- stopSnd: (Snd*) s withTimeOffset: (double) inSeconds;

/*!
    @method stopSnd:
    @abstract Stop all performances of the sound immediately.
    @param s The sound to stop.
    @result
*/
- stopSnd: (Snd *) s;

/*!
    @method stopPerformance:inFuture:
    @abstract Stop the given performance at some time in the future.
    @param performance The SndPerformance instance to stop.
    @param inSeconds The future time interval when to stop playing.
    @result
*/
- stopPerformance: (SndPerformance *) performance inFuture: (double) inSeconds;

/*!
    @method
    @abstract 
    @param 
    @param 
*/
- (void) processBuffers;

/*!
    @method
    @abstract 
    @param 
    @param 
    @result
*/
- init;

/*!
    @method dealloc
    @abstract Destructor
    @param 
    @param 
*/
- (void) dealloc;

/*!
    @method description
    @abstract 
    @param 
    @param 
    @result
*/
- (NSString *) description;

/*!
    @method performancesOfSnd:
    @abstract Return an array of the performances of a given sound.
    @param snd The Snd instance to check which performances are playing or pending play.
    @result
*/
- (NSArray *) performancesOfSnd: (Snd *) snd;

@end
