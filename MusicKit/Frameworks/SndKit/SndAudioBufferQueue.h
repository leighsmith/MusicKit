//
//  SndAudioBufferQueue.h
//  SndKit
//
//  Created by skot on Wed Aug 29 2001.
//  Copyright (c) 2001 __CompanyName__. All rights reserved.
//

#ifndef __SNDAUDIOBUFFERQUEUE_H__
#define __SNDAUDIOBUFFERQUEUE_H__

#import <Foundation/Foundation.h>

@class SndAudioBuffer;

/*!
    @enum     AudioBufferQueueType
    @constant audioBufferQueue_typeInput  
    @constant audioBufferQueue_typeOutput  
*/
typedef enum {
  audioBufferQueue_typeInput,
  audioBufferQueue_typeOutput
} AudioBufferQueueType;

/*!
    @class      SndAudioBufferQueue
    @abstract   Abstraction of the producer / consumer buffer queue operation found inside
                the SndStreamClients, which have both an input and output SndAudioBufferQueue.
                Provides thread safe buffer exchange and blocking operations.
*/
@interface SndAudioBufferQueue : NSObject {
/*! @var pendingBuffers Array of buffers pending processing (to be consumed)*/
    NSMutableArray  *pendingBuffers;
/*! @var processedBuffers Array of processed buffers (post consumption) */
    NSMutableArray  *processedBuffers;
/*! @var pendingBuffersLock Lock for thread safety around pending buffers array */
#ifndef __MINGW32__
    NSConditionLock *pendingBuffersLock;
/*! @var processedBuffersLock Lock for thread safety around processed buffers array */
    NSConditionLock *processedBuffersLock;
/*! @var numBuffers Total number of buffers in the queue, both pending and processed */
#else
    SndConditionLock *pendingBuffersLock;
    SndConditionLock *processedBuffersLock;
#endif
    int              numBuffers;
}

/*!
  @method     audioBufferQueueWithLength:
  @abstract   Factory method 
  @param      n Buffer queue length
  @discussion Creates a fresh new SndAudioBufferQueue, sets the eventual number of buffers to <em>n</em>.
  @result     An SndAudioBufferQueue
*/
+ audioBufferQueueWithLength: (int) n;

- init;
- (void) dealloc;
- (NSString*) description;

/*!
  @method     initQueueWithLength:
  @abstract   Initializes queue for operation with n buffers
  @param      n Number of buffers 
  @result     self
*/
- initQueueWithLength: (int) n;

/*!
  @method popNextPendingBuffer
  @abstract
  @discussion Blocks the calling thread until a buffer is present for popping.
  @result     <UL><LI><b>output</b> - The next buffer to be synthesized / produced</li>
                  <LI><b>input</b>  - The next input buffer to be processed</li></ul>
*/
- (SndAudioBuffer*) popNextPendingBuffer;

/*!
  @method     popNextProcessedBuffer
  @abstract   Returns the next 
  @discussion Blocks the calling thread until a buffer is present for popping.
  @result     <UL><LI><b>output</b> - The next buffer to be consumed by the world at large</li>
                  <LI><b>input</b>  - The next buffer to be filled with input material</li></ul>
*/
- (SndAudioBuffer*) popNextProcessedBuffer;

/*!
  @method addPendingBuffer:
  @abstract Adds buffer to the pending queue.
  @param audioBuffer Buffer to be added
  @result self
*/
- addPendingBuffer: (SndAudioBuffer*) audioBuffer;

/*!
  @method addProcessedBuffer:
  @abstract Adds a buffer to the processed queue.
  @param audioBuffer Buffer to be added
  @result self
*/
- addProcessedBuffer: (SndAudioBuffer*) audioBuffer;

/*!
  @method pendingBuffersCount
  @result Number of buffers in the pending queue
*/
- (int) pendingBuffersCount;

/*!
  @method processedBuffersCount
  @result Number of buffers in the processed queue
*/
- (int) processedBuffersCount;

/*!
  @method     freeBuffers
  @abstract   Frees the SndAudioBuffers within the queues.
  @result     self
*/
- freeBuffers;

/*!
  @method     prepareQueueAsType:withBufferPrototype:
  @abstract   Primes the SndAudioBufferQueue for streaming
  @param      type Either audioBufferQueue_typeInput or audioBufferQueue_typeOutput
  @param      buff The format of the SndAudioBuffer <em>buff</em> will be used as a template 
              for the internal queued buffers. 
  @discussion If prepared as an input queue, the buffers are initially placed in the processed queue; 
              otherwise the fresh buffers are placed in the pending queue. The former ensures that
              any input buffer consumers do not get empty buffers, and the latter allows buffer
              producers (eg synthesizers) to process several buffers ahead, giving them some  processing
              head room in a multi-threaded environment.
  @result     Self.
*/
- prepareQueueAsType: (AudioBufferQueueType) type withBufferPrototype: (SndAudioBuffer*) buff;

/*!
  @method bufferCount
  @abstract Returns the total number of buffers being shuffled about betwixt pending and processed queues.
  @result Number of buffers in queues
*/
- (int) bufferCount;

@end

#endif
