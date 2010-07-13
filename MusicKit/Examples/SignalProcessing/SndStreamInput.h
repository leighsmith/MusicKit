////////////////////////////////////////////////////////////////////////////////
//
//  $Id: SndStreamRecorder.h,v 1.16 2005/04/04 03:28:43 leighsmith Exp $
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

#import <Foundation/Foundation.h>
#import <SndKit/SndKit.h>

// How many samples of the latency we save.

#define MAX_LATENCY_TIMES 1000

/*!
  @class SndStreamInput
  @abstract Copies input streams to output streams, allowing audio processing to be applied to it.
  @discussion
    
So should there be multiple StreamRecorders attached to the input stream, or a single SndStreamInput which mixes
multiple instances of a subclass providing audio processor chains. Probably unnecessary.


    ATTENTION!!!
      Presumptions made to get this class off the ground quickly: The incoming
      stream is made of 32-bit floats, and the saved file is made of 16-bit ints!

    BIG TODO: general purpose format stuff 

      Using the client currently requires an explicit connect-to-stream manager
      call:
 
    SndStreamRecorder *rec = [SndStreamRecorder inputStreamPlayer];
    [[SndStreamManager defaultStreamManager] addClient: rec];
 
    then either...
 
    [rec startReceivingInputToFile: "/tmp/incomingsound.snd"];
    (time passes...)
    [rec stopReceivingInput];
 
    or:

    [rec prepareForReceivingInput: 10.5]; //record for 10.5 seonds
    [rec startReceivingInput];

    TODO:
    - Obviously the big todo here is to get general purpose stream and file
      or format conversion happening!
    - Also, output is currently buffered + written (in stream-to-file mode) in
      44100-frame chunks; this should be more general.
*/
@interface SndStreamInput : SndStreamClient 
{
    /*! @var isReceivingInput YES when the instance is actively receiving samles from the audio hardware. */
    BOOL isReceivingInput;

    // Latency statistics.
    long outputLatencyTimes[MAX_LATENCY_TIMES];
    long inputLatencyTimes[MAX_LATENCY_TIMES];
    int latencyIndex;
}

/*! 
    @method     init
    @abstract   Initialises the receiver.
    @result     Returns the initialised instance.
*/
- init;

/*! 
  @method     startReceivingInput 
  @abstract   Begins recording.
  @discussion This method may be overriden in subclasses to initialise the destination of the recording.
  @result     Returns YES if able to start recording.
*/
- (BOOL) startReceivingInput;

/*! 
  @method     stopReceivingInput
  @abstract   Manually stops recording.
  @discussion Immediately stops recording. Other methods can be used to stop recording after a given amount of time.
*/
- (void) stopReceivingInput;

/*!
  @method isReceivingInput
  @abstract Returns whether the receiver is currently receiving audio samples.
 */
- (BOOL) isReceivingInput;

/*!
  @method averageLatencyForOutput:
  @abstract Returns the average latency for either the input or output processing.

  The average is computed over a maximum of the last MAX_LATENCY_TIMES processing.

  @param forOutput YES to return the latency for the output buffering, NO to return the
  latency for the input buffering.
 */
- (float) averageLatencyForOutput: (BOOL) forOutput;

@end

/*! 
 @protocol StreamRecorderDelegate
 @abstract Protocol for a SndStreamInput delegate
 @discussion To come.
*/
@protocol StreamRecorderDelegate <SndStreamClientDelegate>

/*! 
    @method   didStartReceivingInput:sender
    @abstract   Message sent to delegate just before the recording thread enters
                its processBuffers loop, indicating it is waiting for the first 
                buffer to arrive.
    @discussion Protocol method for SndStreamRecorderDelegate
    @result     self.
*/
- didStartReceivingInput: sender;

/*! 
    @method     didFinishReceivingInput:sender
    @abstract   Message sent to delegate when recording has completed. This is 
                caused by either a user event stopping streaming to disk, or the 
                recording thread reaching the limit of a record-to-memory buffer, 
                and is sent after the final bytes have been delivered to their 
                destination.
    @discussion Protocol method for SndStreamRecorderDelegate
    @result     self
*/
- didFinishReceivingInput: sender;

@end
