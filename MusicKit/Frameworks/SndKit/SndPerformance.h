////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//    
//  Original Author: Leigh Smith, <leigh@tomandandy.com>
//  Further work: SKoT McDonald, <skot@tomandandy.com>
//
//  Copyright (c) 2001-2002, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and 
//  non-commercial purposes so long as the author attribution and copyright 
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SND_PERFORMANCE_H__
#define __SND_PERFORMANCE_H__

#import <Foundation/Foundation.h>
#import "Snd.h"

/*!
@class SndPerformance
@abstract   Holds the state associated with each sounding (or soon to be) Snd.
@discussion This differs from a Snd instance itself, since we can have multiple overlapping
            simultaneous performances of the same (potentially huge) Snd, some looping, others not.
            We need some way of indicating to the delegate exactly which performance has completed,
            hence this class.
*/
@interface SndPerformance : NSObject
{
/*! @var snd The sound being performed*/
    Snd    *snd;
/*! @var playTime */
    double  playTime;
/*! @var startIndex */
    long    startAtIndex;
/*! @var playIndex */
    double  playIndex;
/*! @var endAtIndex */
    long    endAtIndex;
/*! @var paused */
    BOOL    paused;
/*! @var audioProcessorChain */
    SndAudioProcessorChain *audioProcessorChain;

/*! @var looping Indicates whether to loop during performance. */
    BOOL looping;
/*! @var loopStartIndex The sample the loop begins at. */
    long loopStartIndex;
/*! @var loopEndIndex The sample the loop ends at. */
    long loopEndIndex;

    // ivars for variable speed playback - TODO needs fixing and documenting
    double  deltaTime;

    double  actualTime;
}

/*!
  @method     performanceOfSnd:playingAtTime:
  @abstract   Create and return an autoreleased instance of SndPerformance with a sound
              and a time to begin playing. Convenience method to
              performanceOfSnd:playingAtTime:endAtIndex
   @param     s The sound to be played
   @param     seconds Time in seconds to start playing the sound
   @result    Returns the newly created instance if able to initialise, nil if unable.
*/
+ (SndPerformance *) performanceOfSnd: (Snd *) s playingAtTime: (double) seconds;

/*!
  @method     performanceOfSnd:playingAtTime:beginAtIndex:endAtIndex:
  @abstract   Create and return an autoreleased instance of SndPerformance with a sound
              and a time to begin playing.
  @param      s The sound to be played
  @param      seconds Time in seconds to start playing the sound
  @param      beginIndex The sample index at which to start playback
  @param      endIndex The sample index at which to stop playback
  @result     Returns the newly created instance if able to initialise, nil if unable.
*/
+ (SndPerformance *) performanceOfSnd: (Snd *) s 
                        playingAtTime: (double) seconds
                         beginAtIndex: (long) beginIndex
                           endAtIndex: (long) endIndex;
/*!
    @method     initWithSnd:playingAtTime:
    @abstract   Initialise a performance with a sound and a time to begin playing.
    @discussion Convenience method to initWithSnd:playingAtTime:endAtIndex:
    @param      s The sound to be played
    @param      seconds Time in seconds to start playing the sound
    @result     Returns self if able to initialise, nil if unable.
*/
- initWithSnd: (Snd *) s playingAtTime: (double) t;

/*!
    @method     initWithSnd:playingAtTime:beginAtIndex:endAtIndex:
    @abstract   Initialise a performance with a sound and a time to begin playing,
                and the index of the first and last samples of the sound to play.
    @param      seconds Time in seconds to start playing the sound
    @param      beginIndex The sample index at which to start playback
    @param      endIndex The sample index at which to stop playback
    @result     Returns self if able to initialise, nil if unable.
*/
- initWithSnd: (Snd *) s
playingAtTime: (double) seconds
 beginAtIndex: (long) beginIndex
   endAtIndex: (long) endIndex;

/*!
  @method   initWithSnd:playingAtTime:startPosition:duration:deltaTime:
  @abstract   Initialise a performance with a sound and a time to begin playing,
              and the index of the last sample of the sound to play.
  @param      t The time to begin playback
  @param      endIndex The sample index at which to stop playback
  @result     Returns self if able to initialise, nil if unable.
 */
- initWithSnd: (Snd *) s
playingAtTime: (double) playTime
startPosition: (double) startPosition
     duration: (double) duration
    deltaTime: (double) deltaTime;

/*!
    @method   snd
    @abstract   Returns the Snd instance being played in this performance.
    @result     Returns the Snd instance being played in this performance.
*/
- (Snd *) snd;

/*!
  @method   playTime
  @abstract   Returns the time the sound is to begin playing.
  @result     Returns the time interval in seconds from the current time the sound is to begin playing.
*/
- (double) playTime;

/*!
  @method   setPlayTime:
  @abstract Sets the time interval in seconds from the current time the sound is to begin playing.
  */
- setPlayTime: (double) t;

- (double) deltaTime;
- (void) setDeltaTime: (double) _deltaTime;


/*!
    @method   playIndex
    @abstract   Returns the sample to start playing from.
    @result     Returns the sample index to start playing from.
*/
- (double) playIndex;

/*!
    @method   setPlayIndex:
    @abstract   Sets the sample to start playing from.
    @param      newPlayIndex The sample index that playing should begin from.
*/
- (void) setPlayIndex: (double) newPlayIndex;

/*!
    @method   endAtIndex
    @abstract   Returns the sample to stop playing at.
    @result     Returns the sample index to stop playing at.
*/
- (long) endAtIndex;

/*!
  @method   startAtIndex
  @abstract   Returns the sample to start playing at.
  @result     Returns the sample index to start playing at.
*/
- (long) startAtIndex;

/*!
    @method   setEndAtIndex:
    @abstract Sets the sample to stop playing at.
    @param    newEndAtIndex The sample index that playing should stop after.
*/
- (void) setEndAtIndex: (long) newEndAtIndex;

/*!
  @method     setLooping:
  @abstract   Sets looping during performance on or off.
  @param      yesOrNo Sets looping during performance on or off.
 */
- (void) setLooping: (BOOL) yesOrNo;

/*!
  @method     looping
  @abstract   Returns whether this performance loops.
  @result     Returns whether this performance loops.
 */
-  (BOOL) looping;

/*!
  @method     setLoopStartIndex:
  @abstract   Sets the sample to stop playing at.
  @param      newEndAtIndex The sample index that playing should stop after.
  @discussion The loop start index may be changed while the sound is being performed and regardless of
              whether the performance is looping.
 */
- (void) setLoopStartIndex: (long) loopStartIndex;

/*!
  @method     loopStartIndex
  @abstract   Returns the sample to start playing at.
  @result     Returns the sample index to start playing at.
 */
- (long) loopStartIndex;

/*!
  @method     setLoopEndIndex:
  @abstract   Sets the sample at which the performance loops back to the start index (set using setLoopStartIndex:).
  @param      newLoopEndIndex The sample index at the end of the loop.
  @discussion The loop end index may be changed while the sound is being performed and regardless of
              whether the performance is looping.
 */
- (void) setLoopEndIndex: (long) newLoopEndIndex;

/*!
  @method     loopEndIndex
  @abstract   Returns the sample index at the end of the loop.
  @result     Returns the sample index ending the loop.
 */
- (long) loopEndIndex;

/*!
    @method   stopInFuture:
    @abstract   Stop the currently playing performance at some time in the future.
    @param      inSeconds The time interval when to stop the performance.
*/
- (void) stopInFuture: (double) inSeconds;

/*!
    @method stopNow
*/
- (void) stopNow;

/*!
    @method   isEqual:
    @abstract 
    @param      anotherPerformance
*/
- (BOOL) isEqual: (id) anotherPerformance;

/*!
    @method   dealloc
    @abstract   Destructor
*/
- (void) dealloc;

/*!
    @method   description
    @abstract 
    @result     A string containing a brief description of the performance object
*/
- (NSString *) description;

/*!
  @method   isPaused
  @result   Boolean - YES/TRUE if the performance is paused
*/
- (BOOL) isPaused;

/*!
  @method   setPaused
  @param    b a flag to signal whether or not the performance is paused.
  @result   self
*/
- setPaused: (BOOL) b;

/*!
  @method   pause
  @abstract pauses a performance
*/
- pause;

/*!
  @method   resume
  @abstract resumes a paused performance
*/
- resume;

/*!
  @method audioProcessorChain
  @result The audioProcessorChain associated with this performance 
*/
- (SndAudioProcessorChain*) audioProcessorChain;

/*!
  @method setAudioProcessorChain:
  @param anAudioProcessorChain
*/
- setAudioProcessorChain: (SndAudioProcessorChain*) anAudioProcessorChain;

/*!
  @method retrieveAPerformBuffer:ofLength:
  @param bufferToFill A SndAudioBuffer that will be filled with samples.
  @param buffLength
  @result Returns the final buffer length, which may be less than the requested amount in the case of a premature stop, or simply reaching the end of the data. 
  @discussion Fills the given buffer with sound data, reading from the playIndex up until endAtIndex
  	      (which allows us to play a sub-section of a sound). playIndex is updated, and looping is
              respected. In the case of the end of the sound being encountered, a smaller buffer will be filled, and the smaller size is returned.
 */
- (long) retrieveAPerformBuffer: (SndAudioBuffer *) bufferToFill ofLength: (long) buffLength;

/*!
  @method atEndOfPerformance
  @discussion Tests if the play index has reached the end index, indicating that the performance
              has completed.
 */
- (BOOL) atEndOfPerformance;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
