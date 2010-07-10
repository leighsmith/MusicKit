////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
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

#ifndef __SNDAUDIOBUFFERQUEUE_H__
#define __SNDAUDIOBUFFERQUEUE_H__

#import <Foundation/Foundation.h>

@class SndAudioBuffer;

/*!
  @enum SndAudioBufferQueueType
  @constant audioBufferQueue_typeInput  
  @constant audioBufferQueue_typeOutput  
*/
typedef enum {
  audioBufferQueue_typeInput,
  audioBufferQueue_typeOutput
} SndAudioBufferQueueType;

/*!
  @class SndAudioBufferQueue
  @brief Abstraction of the producer / consumer buffer queue operation found inside
    the SndStreamClients, which have both an input and output SndAudioBufferQueue.
    Provides thread safe buffer exchange and blocking operations.
*/
@interface SndAudioBufferQueue : NSObject 
{
    /*! Array of buffers pending processing (to be consumed) */
    NSMutableArray  *pendingBuffers;
    /*! Array of processed buffers (post consumption) */
    NSMutableArray  *processedBuffers;
    /*! Lock for thread safety around pending buffers array */
    NSConditionLock *pendingBuffersLock;
    /*! Lock for thread safety around processed buffers array */
    NSConditionLock *processedBuffersLock;
    /*! Total number of buffers in the queue, both pending and processed */
    int              numBuffers;
}

/*!
  @brief   Factory method 
  @param      n Buffer queue length
  
  Creates a fresh new SndAudioBufferQueue, sets the eventual number of buffers to <em>n</em>.
  @return     An SndAudioBufferQueue
*/
+ audioBufferQueueWithLength: (int) n;

- init;
- (void) dealloc;
- (NSString*) description;

/*!
  @brief   Initializes queue for operation with a total of pending+processed buffers.
  
  Since we add and pop buffers in separate methods, if we try to add before popping, we will
	  need to use one less than the full number of buffers initialized with, such that we never
	  exceed the maximum. For example, if we initialize with 4 buffers, at best we can hold only
  3 processed buffers so we can add a pending buffer, before then popping a processed buffer.
  @param      n Number of buffers.
  @return     Returns self.
*/
- initQueueWithLength: (int) n;

/*!
  @brief
  
  Blocks the calling thread until a buffer is present for popping.
  @return     <UL><LI><b>output</b> - The next buffer to be synthesized / produced</li>
  <LI><b>input</b>  - The next input buffer to be processed</li></ul>
*/
- (SndAudioBuffer*) popNextPendingBuffer;

/*!
  @brief   Returns the next 
  
  Blocks the calling thread until a buffer is present for popping.
  @return     <UL><LI><b>output</b> - The next buffer to be consumed by the world at large</li>
  <LI><b>input</b>  - The next buffer to be filled with input material</li></ul>
*/
- (SndAudioBuffer*) popNextProcessedBuffer;

/*!
  @brief Adds buffer to the pending queue.
  @param audioBuffer Buffer to be added
  @return Returns self.
*/
- addPendingBuffer: (SndAudioBuffer*) audioBuffer;

/*!
  @brief Adds a buffer to the processed queue.
  @param audioBuffer Buffer to be added
  @return Returns self.
*/
- addProcessedBuffer: (SndAudioBuffer*) audioBuffer;

/*!
  @brief Moves all processed buffers onto the pending queue.
 */
- (void) cancelProcessedBuffers;

/*!
  @return Number of buffers in the pending queue
*/
- (int) pendingBuffersCount;

/*!
  @return Number of buffers in the processed queue
*/
- (int) processedBuffersCount;

/*!
  @brief   Frees the SndAudioBuffers within the queues.
  @return     Returns self
*/
- freeBuffers;

/*!
  @brief   Primes the SndAudioBufferQueue for streaming
  @param      type Either audioBufferQueue_typeInput or audioBufferQueue_typeOutput
  @param      buff The format of the SndAudioBuffer <em>buff</em> will be used as a template 
  for the internal queued buffers. 
  
  If prepared as an input queue, the buffers are initially placed in the processed queue; 
  otherwise the fresh buffers are placed in the pending queue. The former ensures that
  any input buffer consumers do not get empty buffers, and the latter allows buffer
  producers (eg synthesizers) to process several buffers ahead, giving them some processing
  head room in a multi-threaded environment.
  @return     Returns self.
*/
- prepareQueueAsType: (SndAudioBufferQueueType) type withBufferPrototype: (SndAudioBuffer*) buff;

/*!
  @brief Returns the total number of buffers being shuffled about betwixt pending and processed queues.
  @return Number of buffers in queues
*/
- (int) bufferCount;

@end

#endif
