/*
  $Id$

  Description:
    Holds the state associated with each sounding (or soon to be) Snd.
    This differs from a Snd instance itself, since we can have multiple overlapping
    performances of the same (potentially huge) Snd. We need some way of indicating
    to the delegate exactly which performance has completed.
    
  Original Author: Leigh Smith, <leigh@tomandandy.com>, tomandandy music inc.

  Sat 28-Feb-2001, Copyright (c) 2001 tomandandy music inc. All rights reserved.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/
#ifndef __SND_PERFORMANCE_H__
#define __SND_PERFORMANCE_H__

#import <Foundation/Foundation.h>
#import "Snd.h"

@interface SndPerformance : NSObject
{
    Snd *snd;
    double playTime;
    long playIndex;
    long endAtIndex;
    // TODO playState should be here, not Snd.
}

/*!
    @method performanceOfSnd:playingAtTime:
    @abstract Create and return an autoreleased instance of SndPerformance with a sound
              and a time to begin playing. Convenience method to
              performanceOfSnd:playingAtTime:endAtIndex
    @result Returns the newly created instance if able to initialise, nil if unable.
*/
+ (SndPerformance *) performanceOfSnd: (Snd *) s playingAtTime: (double) seconds;

/*!
    @method performanceOfSnd:playingAtTime:endAtIndex:
    @abstract Create and return an autoreleased instance of SndPerformance with a sound
              and a time to begin playing.
    @result Returns the newly created instance if able to initialise, nil if unable.
*/
+ (SndPerformance *) performanceOfSnd: (Snd *) s 
                        playingAtTime: (double) seconds
			   endAtIndex: (long) endIndex;

/*!
    @method initWithSnd:playingAtTime:
    @abstract Initialise a performance with a sound and a time to begin playing.
              Convenience method to initWithSnd:playingAtTime:endAtIndex:
    @result Returns self if able to initialise, nil if unable.
*/
- initWithSnd: (Snd *) s playingAtTime: (double) t;

/*!
    @method initWithSnd:playingAtTime:endAtIndex:
    @abstract Initialise a performance with a sound and a time to begin playing,
              and the index of the last sample of the sound to play.
    @result Returns self if able to initialise, nil if unable.
*/
- initWithSnd: (Snd *) s playingAtTime: (double) t endAtIndex: (long) endIndex;

/*!
    @method snd
    @abstract Returns the Snd instance being played in this performance.
    @result Returns the Snd instance being played in this performance.
*/
- (Snd *) snd;

/*!
    @method playTime
    @abstract Returns the time the sound is to begin playing.
    @result Returns the time interval in seconds from the current time the sound is to begin playing.
*/
- (double) playTime;

/*!
    @method playIndex
    @abstract Returns the sample to start playing from.
    @result Returns the sample index to start playing from.
*/
- (long) playIndex;

/*!
    @method setPlayIndex:
    @abstract Sets the sample to start playing from.
    @param newPlayIndex The sample index that playing should begin from.
*/
- (void) setPlayIndex: (long) newPlayIndex;

/*!
    @method endAtIndex
    @abstract Returns the sample to stop playing at.
    @result Returns the sample index to stop playing at.
*/
- (long) endAtIndex;

/*!
    @method setEndAtIndex:
    @abstract Sets the sample to stop playing at.
    @param newEndAtIndex The sample index that playing should stop after.
*/
- (void) setEndAtIndex: (long) newEndAtIndex;

/*!
    @method stopInFuture:
    @abstract Stop the currently playing performance at some time in the future.
    @param inSeconds The time interval when to stop the performance.
*/
- (void) stopInFuture: (double) inSeconds;

/*!
    @method stopInFuture:
    @abstract Stop the currently playing performance at some time in the future.
    @param inSeconds The time interval when to stop the performance.
*/
- (BOOL) isEqual: (id) anotherPerformance;
/*!
    @method stopInFuture:
    @abstract Stop the currently playing performance at some time in the future.
    @param inSeconds The time interval when to stop the performance.
*/
- (void) dealloc;

/*!
    @method description
    @abstract 
    @result
*/
- (NSString *) description;

@end

#endif
