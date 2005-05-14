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
@brief  Holds the state associated with each sounding (or soon to be) Snd.

  This differs from a Snd instance itself, since we can have multiple overlapping
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
  @brief   Create and return an autoreleased instance of SndPerformance with a sound
  and a time to begin playing. Convenience method to
  performanceOfSnd:playingAtTime:endAtIndex
  @param     s The sound to be played
  @param     seconds Time in seconds to start playing the sound
  @return    Returns the newly created instance if able to initialise, nil if unable.
*/
+ (SndPerformance *) performanceOfSnd: (Snd *) s playingAtTime: (double) seconds;

/*!
  @brief   Create and return an autoreleased instance of SndPerformance with a sound
  and a time to begin playing.
  @param      s The sound to be played
  @param      seconds Time in seconds to start playing the sound
  @param      beginIndex The sample index at which to start playback. This sample will be played.
  @param      endIndex The sample index at which to stop playback. This sample will not be played.
  @return     Returns the newly created instance if able to initialise, nil if unable.
*/
+ (SndPerformance *) performanceOfSnd: (Snd *) s 
                        playingAtTime: (double) seconds
                         beginAtIndex: (long) beginIndex
                           endAtIndex: (long) endIndex;
/*!
  @brief   Initialise a performance with a sound and a time to begin playing.
  
  Convenience method to initWithSnd:playingAtTime:endAtIndex:
  @param      s The sound to be played
  @param      seconds Time in seconds to start playing the sound
  @return     Returns self if able to initialise, nil if unable.
*/
- initWithSnd: (Snd *) s playingAtTime: (double) seconds;

/*!
  @brief   Initialise a performance with a sound and a time to begin playing,
  and the index of the first and last samples of the sound to play.
  @param      s The sound to be played
  @param      seconds Time in seconds to start playing the sound
  @param      beginIndex The sample index at which to start playback
  @param      endIndex The sample index at which to stop playback
  @return     Returns self if able to initialise, nil if unable.
*/
- initWithSnd: (Snd *) s
playingAtTime: (double) seconds
 beginAtIndex: (long) beginIndex
   endAtIndex: (long) endIndex;

/*!
  @brief   Initialise a performance with a sound and a time to begin playing,
  and the index of the last sample of the sound to play.
  @param      s The Snd instance to begin playing.
  @param      playTime The time to begin playback.
  @param      startPosition The sample index at which to begin playback.
  @param      duration The duration in seconds of the Snd instance to play.
  @param      deltaTime TBD.
  @return     Returns self if able to initialise, nil if unable.
 */
- initWithSnd: (Snd *) s
playingAtTime: (double) playTime
startPosition: (double) startPosition
     duration: (double) duration
    deltaTime: (double) deltaTime;

/*!
  @brief   Returns the Snd instance being played in this performance.
  @return     Returns the Snd instance being played in this performance.
*/
- (Snd *) snd;

/*!
  @brief   Returns the time the sound is to begin playing.
  @return     Returns the time interval in seconds from the current time the sound is to begin playing.
*/
- (double) playTime;

/*!
  @brief Sets the time interval in seconds from the current time the sound is to begin playing.
  */
- setPlayTime: (double) t;

- (double) deltaTime;
- (void) setDeltaTime: (double) _deltaTime;


/*!
  @brief   Returns the sample to start playing from.
  @return     Returns the sample index to start playing from.
*/
- (long) playIndex;

/*!
  @brief   Sets the sample to start playing from.
  @param      newPlayIndex The sample index that playing should begin from.
*/
- (void) setPlayIndex: (long) newPlayIndex;

/*!
  @brief   Rewinds the sample to start playing from by the supplied number of samples.
  
  The loop points are respected, such that rewinding a sound that is set to loop before
  it's loop start index will wrap to the end of the loop. If this isn't wanted, either temporarily
  disable looping or use <i>setPlayIndex:</i>.
  @param      numberOfSamplesToRewind The number of samples to rewind to where playing should begin from.
  @return     Returns the new play index as a convience to save calling <i>playIndex</i>.
 */
- (long) rewindPlayIndexBySamples: (long) numberOfSamplesToRewind;

/*!
  @brief   Returns the sample to stop playing at.
  
  This sample is not played, that is it is typically initialised with the sound length.
  @return     Returns the sample index to stop playing at.
*/
- (long) endAtIndex;

/*!
  @brief   Returns the sample to start playing at.
  @return     Returns the sample index to start playing at.
*/
- (long) startAtIndex;

/*!
  @brief Sets the sample to stop playing at.
  
  The end at index indicates the first sample at which the playback stops, that is,
  this sample is not played.
  @param    newEndAtIndex The sample index that playing should stop before.
*/
- (void) setEndAtIndex: (long) newEndAtIndex;

/*!
  @brief   Sets looping during performance on or off.
  @param      yesOrNo Sets looping during performance on or off.
 */
- (void) setLooping: (BOOL) yesOrNo;

/*!
  @brief   Returns whether this performance loops.
  @return     Returns whether this performance loops.
 */
-  (BOOL) looping;

/*!
  @brief   Sets the sample to start looping from.
  @param      loopStartIndex The sample index to start looping from.
  
  The loop start index may be changed while the sound is being performed and regardless of
  whether the performance is looping. This sample index is the first sample of the loop, i.e it is
  the first sample heard when the performance loops.
 */
- (void) setLoopStartIndex: (long) loopStartIndex;

/*!
  @brief   Returns the sample to start looping from.
  @return     Returns the sample index to start looping from.
 */
- (long) loopStartIndex;

/*!
  @brief   Sets the sample at which the performance loops back to the start index
  (set using <B>setLoopStartIndex:</B>).
  @param      newLoopEndIndex The sample index at the end of the loop.
  
  This sample index is the last sample of the loop, i.e. it is the last sample heard
  before the performance loops, the next sample heard will be that returned by -<B>loopStartIndex</B>.
  The loop end index may be changed while the sound is being performed and regardless of
  whether the performance is looping.
 */
- (void) setLoopEndIndex: (long) newLoopEndIndex;

/*!
  @brief   Returns the sample index at the end of the loop.
  @return     Returns the sample index ending the loop.
 */
- (long) loopEndIndex;

/*!
  @brief   Stop the currently playing performance at some time in the future.
  @param      inSeconds The time interval when to stop the performance.
*/
- (void) stopInFuture: (double) inSeconds;

/*!
  @brief Stops the performance immediately.
*/
- (void) stopNow;

/*!
  @brief Compares two performances.
  @param      anotherPerformance
*/
- (BOOL) isEqual: (id) anotherPerformance;

/*!
  @brief   Destructor
*/
- (void) dealloc;

/*!
  @brief Returns a string containing a brief description of the performance object.
  @return     A string containing a brief description of the performance object.
*/
- (NSString *) description;

/*!
  @return   Boolean - YES/TRUE if the performance is paused
*/
- (BOOL) isPaused;

/*!
  @param    b a flag to signal whether or not the performance is paused.
  @return   self
*/
- setPaused: (BOOL) b;

/*!
  @brief Pauses a performance
*/
- pause;

/*!
  @brief Resumes a paused performance
*/
- resume;

/*!
  @brief Indicates whether the current performance is actually sounding.
  @return Returns YES if the performance is currently sounding, NO if it is paused,
  has yet to be begin playing or has finished.
 */
- (BOOL) isPlaying;

/*!
  @return The audioProcessorChain associated with this performance 
*/
- (SndAudioProcessorChain *) audioProcessorChain;

/*!
  @param anAudioProcessorChain
*/
- (void) setAudioProcessorChain: (SndAudioProcessorChain *) anAudioProcessorChain;

/*!
  @param bufferToFill A SndAudioBuffer that will be filled with samples.
  @param buffLength The intended number of samples TODO or bytes? to retrieve.
  @return Returns the final buffer length, which may be less than the requested amount in the case of
	  a premature stop, or simply reaching the end of the data. 
  @brief Fills the given buffer with sound data, reading from the playIndex up until endAtIndex
  	      (which allows us to play a sub-section of a sound).

  playIndex is updated, and looping is
  respected. In the case of the end of the sound being encountered, a smaller buffer will
  be filled, and the smaller size is returned.
 */
- (long) retrievePerformBuffer: (SndAudioBuffer *) bufferToFill ofLength: (long) buffLength;

/*!
  @brief Tests if the play index has reached the end index, indicating that the performance
  has completed.

  
 */
- (BOOL) atEndOfPerformance;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
