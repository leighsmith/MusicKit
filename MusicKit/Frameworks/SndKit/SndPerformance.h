////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
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
            hence this class. A SndPerformance also has an SndAudioProcessorChain enabling each performance
            of a sound to be signal processed, including volume fading, panning etc using the audio
            processor chain "postFader" SndAudioFader.
*/
@interface SndPerformance : NSObject
{
/*! @var snd The sound being performed. */
    Snd    *snd;
/*! @var playTime The time when to initiate playing. */
    double  playTime;
/*! @var startIndex The index where the sound will begin playing from at the start of a sound performance. */
    long    startAtIndex;
/*! @var playIndex The index where the sound will next play from (using <i>retrievePerformBuffer:</i>).
                   TODO why is the playIndex a double rather than a long? */
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
    @method     playIndex
    @abstract   Returns the sample to start playing from.
    @result     Returns the sample index to start playing from.
*/
- (double) playIndex;

/*!
    @method     setPlayIndex:
    @abstract   Sets the sample to start playing from.
    @param      newPlayIndex The sample index that playing should begin from.
*/
- (void) setPlayIndex: (double) newPlayIndex;

/*!
  @method     rewindPlayIndexBySamples:
  @abstract   Rewinds the sample to start playing from by the supplied number of samples.
  @discussion The loop points are respected, such that rewinding a sound that is set to loop before
              it's loop start index will wrap to the end of the loop. If this isn't wanted, either temporarily
              disable looping or use <i>setPlayIndex:</i>.
  @param      numberOfSamplesToRewind The number of samples to rewind to where playing should begin from.
  @result     Returns the new play index as a convience to save calling <i>playIndex</i>.
 */
- (double) rewindPlayIndexBySamples: (long) numberOfSamplesToRewind;

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
    @abstract Stops the performance immediately.
*/
- (void) stopNow;

/*!
    @method   isEqual:
    @abstract Compares two performances.
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
  @abstract Pauses a performance
*/
- pause;

/*!
  @method   resume
  @abstract Resumes a paused performance
*/
- resume;

/*!
  @method isPlaying
  @abstract Indicates whether the current performance is actually sounding.
  @result Returns YES if the performance is currently sounding, NO if it is paused, has yet to be begin playing or has finished.
 */
- (BOOL) isPlaying;

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
  @method retrievePerformBuffer:ofLength:
  @param bufferToFill A SndAudioBuffer that will be filled with samples.
  @param buffLength The intended number of samples TODO or bytes? to retrieve.
  @result Returns the final buffer length, which may be less than the requested amount in the case of
	  a premature stop, or simply reaching the end of the data. 
  @discussion Fills the given buffer with sound data, reading from the playIndex up until endAtIndex
  	      (which allows us to play a sub-section of a sound). playIndex is updated, and looping is
              respected. In the case of the end of the sound being encountered, a smaller buffer will
              be filled, and the smaller size is returned.
 */
- (long) retrievePerformBuffer: (SndAudioBuffer *) bufferToFill ofLength: (long) buffLength;

/*!
  @method atEndOfPerformance
  @discussion Tests if the play index has reached the end index, indicating that the performance
              has completed.
 */
- (BOOL) atEndOfPerformance;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
