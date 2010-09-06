////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and non-commercial
//  purposes so long as the author attribution and copyright messages remain intact and
//  accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDAUDIOPROCESSORCHAIN_H__
#define __SNDAUDIOPROCESSORCHAIN_H__

#import <Foundation/Foundation.h>

@class SndAudioBuffer;
@class SndAudioProcessor;
@class SndAudioFader;

/*!
  @class SndAudioProcessorChain
  @brief Holds a collection of serially "chained" SndAudioProcessors with a final SndAudioFader at the end of the chain.
  
  To come
*/
@interface SndAudioProcessorChain : NSObject
{
/*! audioProcessorArray The array (chain) of SndAudioProcessors */
    NSMutableArray *audioProcessorArray;
/*! bypassProcessing YES disables processing. */
    BOOL   bypassProcessing;
/*! processorOutputBuffer A buffer used to hold the result of one SndAudioProcessor */
    SndAudioBuffer *processorOutputBuffer; 
/*! postFader A SndAudioFader which modifies the chain of effects volume and pan, effectively it is an "FX return" control */
    SndAudioFader *postFader;
/*! nowTime Time of processing a buffer in seconds. */
    double nowTime;
}

/*!
  @brief   Factory method.
  @return     A freshly initialized, autoreleased SndAudioProcessorChain.
*/
+ audioProcessorChain;

/*!
  @brief   Initializes SndAudioProcessorChain instance.
  
  Creates an active SndAudioFader instance as the post effects fader.
  @return     Self
*/
- init;

/*!
  @brief   Adds an SndAudioProcessor to the end of the effects chain.
  
  @param      proc The SndAudioProcessor to be added to the effects chain
  @return     Self
*/
- addAudioProcessor: (SndAudioProcessor*) proc;

/*!
  @brief   Inserts an SndAudioProcessor into the effects chain at a specific location.
  
  
  @param      newAudioProcessor The SndAudioProcessor to be added to the effects chain.
  @param      processorIndex The location in the effects chain to insert the SndAudioProcessor.
  @return     Returns self
*/
- insertAudioProcessor: (SndAudioProcessor *) newAudioProcessor
	       atIndex: (int) processorIndex;

/*!
  @brief   Removes an SndAudioProcesor from the effects chain
  
  
  @param      proc SndAudioProcessor to be removed from the effects chain
  @return     self
*/
- removeAudioProcessor: (SndAudioProcessor*) proc;

/*!
  @brief   Removes an SndAudioProcesor from the effects chain
  
  @param      index The base 0 entry in effects chain to remove.
  @return     self
 */
- removeAudioProcessorAtIndex: (int) index;

/*!
  @brief   Get the processor at a certain index.
  
  @param      index Base zero reference to the SndAudioProcessor required.
  @return     Returns an autoreleased SndAudioProcessor.
*/
- (SndAudioProcessor *) processorAtIndex: (int) index;

/*!
  @brief   Removes all processors from the processor chain.
  @return     Returns self.
*/
- removeAllProcessors;

/*!
  @brief   Process the provided audio buffer with the chain of SndAudioProcessors.
  
  The t parameter tells the processor chain at what time
  the buffer is destined to start to be played. This
  matches up with the time the SndStreamClients were given
  for generating this same buffer.
  @param      buff A SndAudioBuffer instance of valid sound data.
  @param      timeInSeconds The time in seconds the buffer is intended to be played.
  @return     Returns self.
*/
- processBuffer: (SndAudioBuffer *) buff forTime: (double) timeInSeconds;

/*!
  @brief   Returns the number of processors in the audio processor chain.
  @return     number of processors in the processor chain.
*/
- (int) processorCount; 

/*!
  @brief   Returns an array of SndAudioProcessors in this chain.
  
  Provided for speed, so it returns a shallow copy of the SndAudioProcessor instances.
  @return     NSArray containing the processors (in processing order).
*/
- (NSArray *) processorArray;

/*!
  @brief Return the state of the effects chain bypass.
 
  @return     YES is effects chain is being bypassed
*/
- (BOOL) isBypassingFX;

/*!
  @brief Sets the audio processor chain to be bypassed or not.
  
  @param      bypassEffectsChain Bypass flag - YES to enable bypassing the effects processing.
*/
- (void) setBypassProcessors: (BOOL) bypassEffectsChain;

/*!
  @brief   Returns the SndAudioFader which is the last effect at the end of this SndAudioProcessorChain instance.
  
  @return     id of the postFader object at the end of the chain
*/
- (SndAudioFader *) postFader;

/*!
  @brief   Assigns the SndAudioFader which is the last effect at the end of this SndAudioProcessorChain instance.
  
  There is a default post-send fader which is usually sufficient. This method is only necessary to use
  if a ganged fading of several playing streams is required. 
  @param     newPostFader A SndAudioFader instance to become the postFader object at the end of the chain.
 */
- (void) setPostFader: (SndAudioFader *) newPostFader;

/*!
  @brief   Returns the time the buffer is to be played.
  
  @return     Returns a double Indicating the play start time of the buffer being
  processed in seconds.
*/
- (double) nowTime;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
