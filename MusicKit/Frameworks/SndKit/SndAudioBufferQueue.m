////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioBufferQueue.m
//  SndKit
//
//  Created by SKoT McDonald on Wed Aug 29 2001.
//  Copyright (c) 2001 tomandandy. All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and 
//  non-commercial purposes so long as the author attribution and copyright 
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////


#import "SndAudioBuffer.h"
#import "SndAudioBufferQueue.h"

enum {
    ABQ_noData,
    ABQ_hasData
};

#ifdef __MINGW32__
# define NSConditionLock SndConditionLock
#endif

@implementation SndAudioBufferQueue

////////////////////////////////////////////////////////////////////////////////
// audioBufferQueueWithLength:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferQueueWithLength: (int) n
{
    return [[[self alloc] initQueueWithLength: 4] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
    self = [self initQueueWithLength: 4];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// initQueueWithLength:
////////////////////////////////////////////////////////////////////////////////

- initQueueWithLength: (int) n
{
    self = [super init];
    numBuffers = n;
    if (pendingBuffersLock == nil) {
        pendingBuffersLock   = [[NSConditionLock alloc] initWithCondition: ABQ_noData];
        processedBuffersLock = [[NSConditionLock alloc] initWithCondition: ABQ_noData];
        pendingBuffers       = [[NSMutableArray arrayWithCapacity: numBuffers] retain];
        processedBuffers     = [[NSMutableArray arrayWithCapacity: numBuffers] retain];
        
        [processedBuffersLock lock];
        [processedBuffersLock unlockWithCondition: ABQ_noData];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
    [pendingBuffersLock   release];
    [processedBuffersLock release];
    [pendingBuffers       release];
    [processedBuffers     release];
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// description
////////////////////////////////////////////////////////////////////////////////

- (NSString*) description
{
    return [NSString stringWithFormat: @"SndAudioBufferQueue numBuffers:%i pending:%i processed:%i", 
            numBuffers, [pendingBuffers count], [processedBuffers count]];
}

////////////////////////////////////////////////////////////////////////////////
// popNextPendingBuffer
////////////////////////////////////////////////////////////////////////////////

- (SndAudioBuffer*) popNextPendingBuffer
{
    SndAudioBuffer *ab = nil;
    [pendingBuffersLock lockWhenCondition: ABQ_hasData];
    ab = [[pendingBuffers objectAtIndex: 0] retain];
    [pendingBuffers removeObjectAtIndex: 0];
    [pendingBuffersLock unlockWithCondition: ([pendingBuffers count] > 0 ? ABQ_hasData : ABQ_noData)];
    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// popNextProcessedBuffer
////////////////////////////////////////////////////////////////////////////////

- (SndAudioBuffer*) popNextProcessedBuffer
{
    SndAudioBuffer *ab = nil;
    [processedBuffersLock lockWhenCondition: ABQ_hasData];
    ab = [[processedBuffers objectAtIndex: 0] retain];
    [processedBuffers removeObjectAtIndex: 0];
    [processedBuffersLock unlockWithCondition: ([processedBuffers count] > 0 ? ABQ_hasData : ABQ_noData)];
    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// addPendingBuffer:
////////////////////////////////////////////////////////////////////////////////

- addPendingBuffer: (SndAudioBuffer*) audioBuffer
{
    if (audioBuffer == nil)
        NSLog(@"SndAudioBufferQueue::addPendingBuffer - audioBuffer is nil!");
    else {
        [pendingBuffersLock lock];
        [pendingBuffers addObject: audioBuffer];
        [pendingBuffersLock unlockWithCondition: ABQ_hasData];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// addProcessedBuffer:
////////////////////////////////////////////////////////////////////////////////

- addProcessedBuffer: (SndAudioBuffer*) audioBuffer
{
    if (audioBuffer == nil)
        NSLog(@"SndAudioBufferQueue::addProcessedBuffer - audioBuffer is nil!");
    else {
        [processedBuffersLock lock];
        [processedBuffers addObject: audioBuffer];
        [processedBuffersLock unlockWithCondition: ABQ_hasData];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// pendingBuffersCount
////////////////////////////////////////////////////////////////////////////////

- (int) pendingBuffersCount
{
    return [pendingBuffers count];
}

////////////////////////////////////////////////////////////////////////////////
// processedBuffersCount
////////////////////////////////////////////////////////////////////////////////

- (int) processedBuffersCount
{
    return [processedBuffers count];
}

////////////////////////////////////////////////////////////////////////////////
// bufferCount
////////////////////////////////////////////////////////////////////////////////

- (int) bufferCount
{
  return numBuffers;
}

////////////////////////////////////////////////////////////////////////////////
// freeBuffers
////////////////////////////////////////////////////////////////////////////////

- freeBuffers
{
  [pendingBuffers   removeAllObjects];
  [processedBuffers removeAllObjects];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// prepareQueueAsType:withBufferPrototype:
////////////////////////////////////////////////////////////////////////////////

- prepareQueueAsType: (AudioBufferQueueType) type withBufferPrototype: (SndAudioBuffer*) buff
{
    if (buff == nil) {
        NSLog(@"SndAudioBufferQueue::prepareQueueAsType - ERROR: buff is nil!\n");
        return self;
    }
    switch (type)
    {
    case audioBufferQueue_typeInput:
        {
            int i;
            [pendingBuffersLock lock];
            [pendingBuffersLock unlockWithCondition: ABQ_noData];            
            [processedBuffersLock lock];
            for (i = 0; i < numBuffers; i++) 
              [processedBuffers addObject: [buff copy]];
            [processedBuffersLock unlockWithCondition: ABQ_hasData];
        }
        break;

    case audioBufferQueue_typeOutput:
        {
            int i;
            [processedBuffersLock lock];
            [processedBuffersLock unlockWithCondition: ABQ_noData];            
            [pendingBuffersLock lock];
            for (i = 0; i < numBuffers - 1; i++)  
              [pendingBuffers addObject: [buff copy]];
            [pendingBuffersLock unlockWithCondition: ABQ_hasData];
        }
        break;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////

@end
