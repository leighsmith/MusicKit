////////////////////////////////////////////////////////////////////////////////
//
//  $Id: SndStreamInput.h 3687 2010-07-14 19:35:23Z leighsmith $
//
//  Original Author: Leigh M. Smith <leigh@leighsmith.com>
//
//  Copyright (c) 2010, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import <SndKit/SndKit.h>

// How many samples of the latency we save.

#define MAX_LATENCY_TIMES 1000

/*!
  @class SndStreamInput
  @brief Copies input streams to output streams, allowing audio processing to be applied to it.
  @discussion
    
   ATTENTION!!!
      Presumptions made to get this class off the ground quickly: The incoming
      stream is made of 32-bit floats, and the saved file is made of 16-bit ints!

*/
@interface SndStreamInput : SndStreamClient 
{
    /*! @var isReceivingInput YES when the instance is actively receiving samples from the audio hardware. */
    BOOL isReceivingInput;

    // Latency statistics.
    long outputLatencyTimes[MAX_LATENCY_TIMES];
    long inputLatencyTimes[MAX_LATENCY_TIMES];
    int latencyIndex;
}

/*! 
    @method     init
  @brief   Initialises the receiver.
    @result     Returns the initialised instance.
*/
- init;

/*! 
  @method     startReceivingInput 
  @brief   Begins recording.
  @discussion This method may be overriden in subclasses to initialise the destination of the recording.
  @result     Returns YES if able to start recording.
*/
- (BOOL) startReceivingInput;

/*! 
  @method     stopReceivingInput
  @brief   Manually stops recording.
  @discussion Immediately stops recording. Other methods can be used to stop recording after a given amount of time.
*/
- (void) stopReceivingInput;

/*!
  @method isReceivingInput
  @brief Returns whether the receiver is currently receiving audio samples.
 */
- (BOOL) isReceivingInput;

/*!
  @method averageLatencyForOutput:
  @brief Returns the average latency for either the input or output processing in samples.

  The average is computed over a maximum of the last MAX_LATENCY_TIMES processing.

  @param forOutput YES to return the latency for the output buffering, NO to return the
  latency for the input buffering.
 */
- (float) averageLatencyForOutput: (BOOL) forOutput;

@end

/*! 
 @protocol StreamInputDelegate
 @brief Protocol for a SndStreamInput delegate
 @discussion Provides methods to indicate when a stream begins and ends receiving audio input.
*/
@protocol StreamInputDelegate <SndStreamClientDelegate>

/*! 
    @method   didStartReceivingInput:sender
    @brief   Message sent to delegate just before the recording thread enters
                its processBuffers loop, indicating it is waiting for the first 
                buffer to arrive.
    @discussion Protocol method for SndStreamRecorderDelegate
    @result     self.
*/
- didStartReceivingInput: sender;

/*! 
    @method     didFinishReceivingInput:sender
    @brief   Message sent to delegate when recording has completed. This is 
                caused by either a user event stopping streaming to disk, or the 
                recording thread reaching the limit of a record-to-memory buffer, 
                and is sent after the final bytes have been delivered to their 
                destination.
    @discussion Protocol method for SndStreamRecorderDelegate
    @result     self
*/
- didFinishReceivingInput: sender;

@end
