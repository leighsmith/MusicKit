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

typedef enum {
  audioBufferQueue_typeInput,
  audioBufferQueue_typeOutput
} AudioBufferQueueType;

@interface SndAudioBufferQueue : NSObject {
    NSMutableArray  *pendingBuffers;
    NSMutableArray  *processedBuffers;
    NSConditionLock *pendingBuffersLock;
    NSConditionLock *processedBuffersLock;
    int              numBuffers;
}

+ audioBufferQueueWithLength: (int) n;
- init;
- initQueueWithLength: (int) n;
- (void) dealloc;
- (NSString*) description;

- (SndAudioBuffer*) popNextPendingBuffer;
- (SndAudioBuffer*) popNextProcessedBuffer;
- addPendingBuffer: (SndAudioBuffer*) audioBuffer;
- addProcessedBuffer: (SndAudioBuffer*) audioBuffer;
- (int) pendingBuffersCount;
- (int) processedBuffersCount;

- freeBuffers;
- prepareQueueAsType: (AudioBufferQueueType) type withBufferPrototype: (SndAudioBuffer*) buff;
- (int) bufferCount;


@end

#endif
