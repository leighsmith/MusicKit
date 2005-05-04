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
#import "SndAudioBuffer.h"
#import "SndAudioProcessorChain.h"

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
    /*! @var playIndex The index where the sound will next play from (using <i>retrievePerformBuffer:</i>). */
    long  playIndex;
    /*! @var endAtIndex The index where the sound will stop <B>before</B>. This marks the sample after the last
			one to be played, the sample at endAtIndex is <B>not</B> played. */
    long    endAtIndex;
    /*! @var paused Controls whether performance of the Snd is occuring. */
    BOOL    paused;
    /*! @var audioProcessorChain Effects applied to this particular performance. */
    SndAudioProcessorChain *audioProcessorChain;

    /*! @var looping Indicates whether to loop during performance. */
    BOOL looping;
    /*! @var loopStartIndex The sample the loop begins at. This sample is included in the loop. */
    long loopStartIndex;
    /*! @var loopEndIndex The sample the loop ends at. This sample is included in the loop. */
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
  @param      beginIndex The sample index at which to start playback. This sample will be played.
  @param      endIndex The sample index at which to stop playback. This sample will not be played.
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
- (long) playIndex;

/*!
    @method     setPlayIndex:
    @abstract   Sets the sample to start playing from.
    @param      newPlayIndex The sample index that playing should begin from.
*/
- (void) setPlayIndex: (long) newPlayIndex;

/*!
  @method     rewindPlayIndexBySamples:
  @abstract   Rewinds the sample to start playing from by the supplied number of samples.
  @discussion The loop points are respected, such that rewinding a sound that is set to loop before
              it's loop start index will wrap to the end of the loop. If this isn't wanted, either temporarily
              disable looping or use <i>setPlayIndex:</i>.
  @param      numberOfSamplesToRewind The number of samples to rewind to where playing should begin from.
  @result     Returns the new play index as a convience to save calling <i>playIndex</i>.
 */
- (long) rewindPlayIndexBySamples: (long) numberOfSamplesToRewind;

/*!
  @method     endAtIndex
  @abstract   Returns the sample to stop playing at.
  @discussion This sample is not played, that is it is typically initialised with the sound length.
  @result     Returns the sample index to stop playing at.
*/
- (long) endAtIndex;

/*!
  @method     startAtIndex
  @abstract   Returns the sample to start playing at.
  @result     Returns the sample index to start playing at.
*/
- (long) startAtIndex;

/*!
    @method   setEndAtIndex:
    @abstract Sets the sample to stop playing at.
    @discussion The end at index indicates the first sample at which the playback stops, that is,
               this sample is not played.
    @param    newEndAtIndex The sample index that playing should stop before.
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
  @abstract   Sets the sample to start looping from.
  @param      loopStartIndex The sample index to start looping from.
  @discussion The loop start index may be changed while the sound is being performed and regardless of
              whether the performance is looping. This sample index is the first sample of the loop, i.e it is
              the first sample heard when the performance loops.
 */
- (void) setLoopStartIndex: (long) loopStartIndex;

/*!
  @method     loopStartIndex
  @abstract   Returns the sample to start looping from.
  @result     Returns the sample index to start looping from.
 */
- (long) loopStartIndex;

/*!
  @method     setLoopEndIndex:
  @abstract   Sets the sample at which the performance loops back to the start index
              (set using <B>setLoopStartIndex:</B>).
  @param      newLoopEndIndex The sample index at the end of the loop.
  @discussion This sample index is the last sample of the loop, i.e. it is the last sample heard
              before the performance loops, the next sample heard will be that returned by -<B>loopStartIndex</B>.
              The loop end index may be changed while the sound is being performed and regardless of
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
    @abstract Returns a string containing a brief description of the performance object.
    @result     A string containing a brief description of the performance object.
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
  @result Returns YES if the performance is currently sounding, NO if it is paused,
          has yet to be begin playing or has finished.
 */
- (BOOL) isPlaying;

/*!
  @method audioProcessorChain
  @result The audioProcessorChain associated with this performance 
*/
- (SndAudioProcessorChain *) audioProcessorChain;

/*!
  @method setAudioProcessorChain:
  @param anAudioProcessorChain
*/
- (void) setAudioProcessorChain: (SndAudioProcessorChain *) anAudioProcessorChain;

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
