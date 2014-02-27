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

#import "SndAudioBuffer.h"
#import "SndAudioFader.h"
#import "SndAudioProcessor.h"
#import "SndAudioProcessorChain.h"

@implementation SndAudioProcessorChain

////////////////////////////////////////////////////////////////////////////////
// audioProcessorChain
////////////////////////////////////////////////////////////////////////////////

+ audioProcessorChain
{
    SndAudioProcessorChain *pSAPC = [[SndAudioProcessorChain alloc] init];
    return [pSAPC autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
    [super init];
    if (audioProcessorArray == nil)
        audioProcessorArray = [[NSMutableArray arrayWithCapacity: 2] retain];
    bypassProcessing = FALSE;
    nowTime = 0.0;
    postFader = [[SndAudioFader alloc] init];
    [postFader setActive: YES]; // By default, our post effects fader is active.
    [postFader setAudioProcessorChain: self];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc;
{
    [audioProcessorArray release];
    [processorOutputBuffer release];
    [postFader release];
    [super dealloc];
}

- copyWithZone: (NSZone *) zone
{
    SndAudioProcessorChain *newSAPC = [[[self class] allocWithZone: zone] init];
    unsigned int processorIndex;
    
    // Do deep copy of all elements of the array
    for(processorIndex = 0; processorIndex < [audioProcessorArray count]; processorIndex++)
	[newSAPC->audioProcessorArray addObject: [[[audioProcessorArray objectAtIndex: processorIndex] copy] autorelease]];
    [newSAPC->postFader release];
    newSAPC->postFader = [postFader copy];

    newSAPC->nowTime = [self nowTime];
    [newSAPC setBypassProcessors: [self isBypassingFX]];
    
    return newSAPC; // don't release, copy is supposed to retain.
}

- writeScorefileStream: (NSMutableData *) aStream
{
    unsigned int audioProcessorIndex;
    
    for(audioProcessorIndex = 0; audioProcessorIndex < [audioProcessorArray count]; audioProcessorIndex++) {
	SndAudioProcessor *audioProcessor = [audioProcessorArray objectAtIndex: audioProcessorIndex];
	NSString *processorName = [NSString stringWithFormat: @"%@%s", [audioProcessor name], audioProcessorIndex == [audioProcessorArray count] - 1 ? "" : ","];

	[aStream appendData: [processorName dataUsingEncoding: NSNEXTSTEPStringEncoding]];
    }
    return self;
}

- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ %@ audioProcessors: %@, postFader %@\n", 
	[super description], bypassProcessing ? @"(bypassed)" : @"(active)", audioProcessorArray, postFader];
}

////////////////////////////////////////////////////////////////////////////////
// addAudioProcessor
////////////////////////////////////////////////////////////////////////////////

- (void) addAudioProcessor: (SndAudioProcessor *) proc
{
    [audioProcessorArray addObject: proc];
    [proc setAudioProcessorChain: self];
}

////////////////////////////////////////////////////////////////////////////////
// insertAudioProcessor:atIndex:
////////////////////////////////////////////////////////////////////////////////

- (void) insertAudioProcessor: (SndAudioProcessor *) proc
		      atIndex: (int) processorIndex
{
    [audioProcessorArray insertObject: proc atIndex: processorIndex];
    [proc setAudioProcessorChain: self];
}


////////////////////////////////////////////////////////////////////////////////
// removeAudioProcessor
////////////////////////////////////////////////////////////////////////////////

- (void) removeAudioProcessor: (SndAudioProcessor *) proc
{
    //NSLog(@"Removing %@\n", proc);
    [audioProcessorArray removeObject: proc];
    //NSLog(@"Removed it\n");
}

////////////////////////////////////////////////////////////////////////////////
// removeAudioProcessorAtIndex:
////////////////////////////////////////////////////////////////////////////////

- (void) removeAudioProcessorAtIndex: (int) index
{
    [audioProcessorArray removeObjectAtIndex: index];
}

////////////////////////////////////////////////////////////////////////////////
// processorAtIndex
////////////////////////////////////////////////////////////////////////////////

- (SndAudioProcessor *) processorAtIndex: (int) index
{
    return [audioProcessorArray objectAtIndex: index];
}

////////////////////////////////////////////////////////////////////////////////
// removeAllProcessors
////////////////////////////////////////////////////////////////////////////////

- (void) removeAllProcessors
{
    [audioProcessorArray removeAllObjects];
}

- (SndFormat) format
{
    // if we ask for the format before anything has been processed, it is slightly better to give a default
    // format than a bogus one.
    if (processorOutputBuffer == nil) {
        processorOutputBuffer = [[SndAudioBuffer alloc] init];
    }
    return [processorOutputBuffer format];
}

////////////////////////////////////////////////////////////////////////////////
// processBuffer:forTime:
////////////////////////////////////////////////////////////////////////////////

- processBuffer: (SndAudioBuffer *) buff forTime: (double) t
{
    int audioProcessorIndex, audioProcessorCount = [audioProcessorArray count];
    if (bypassProcessing)
        return self;

    nowTime = t;
    
    // make sure temp buffer is in same format and size as buff too.
    if (processorOutputBuffer == nil) {
        processorOutputBuffer = [[SndAudioBuffer alloc] initWithBuffer: buff];
    }
    else if(![processorOutputBuffer hasSameFormatAsBuffer: buff]) {
	[processorOutputBuffer release];
	processorOutputBuffer = [[SndAudioBuffer alloc] initWithBuffer: buff];
    }

    // TODO inputBuffer = buff; outputBuffer = processorOutputBuffer;
    for (audioProcessorIndex = 0; audioProcessorIndex < audioProcessorCount; audioProcessorIndex++) {
	SndAudioProcessor *proc = [audioProcessorArray objectAtIndex: audioProcessorIndex];
	
	if ([proc isActive]) {
	    // TODO [proc processReplacingInputBuffer: inputBuffer outputBuffer: outputBuffer]
	    if ([proc processReplacingInputBuffer: buff
				     outputBuffer: processorOutputBuffer]) {
		// TODO rather than copying between each stage of the chain, just swap input and output buffers
		// tempBuffer = (inputBuffer == buff) ? secondOutputBuffer : inputBuffer
		// inputBuffer = outputBuffer
		// outputBuffer = tempBuffer
		//
		// NSLog(@"buff %@\n", buff);
		[buff copyDataFromBuffer: processorOutputBuffer];
		// NSLog(@"after buff %@\n", buff);
	    }
	}
    }
    if ([postFader isActive]) {
	// TODO [proc processReplacingInputBuffer: inputBuffer outputBuffer: outputBuffer]
	if ([postFader processReplacingInputBuffer: buff
				      outputBuffer: processorOutputBuffer]) {
	    [buff copyDataFromBuffer: processorOutputBuffer];
	}
	// NSLog(@"fader after buff %@\n", buff);
    }
    // TODO Do a final copy, could make this conditional on at least one processor in the chain needing to replace.
    // TODO [buff copyDataFromBuffer: outputBuffer];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// processorCount
////////////////////////////////////////////////////////////////////////////////

- (int) processorCount
{
    return [audioProcessorArray count];
}

////////////////////////////////////////////////////////////////////////////////
// processorArray
////////////////////////////////////////////////////////////////////////////////

- (NSArray *) processorArray
{
    return audioProcessorArray;
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- (BOOL) isBypassingFX
{
    return bypassProcessing;
}

////////////////////////////////////////////////////////////////////////////////
// setBypass
////////////////////////////////////////////////////////////////////////////////

- (void) setBypassProcessors: (BOOL) b
{
    bypassProcessing = b;
}

////////////////////////////////////////////////////////////////////////////////
// postFader
////////////////////////////////////////////////////////////////////////////////

- (SndAudioFader *) postFader
{
    return [[(id)postFader retain] autorelease];
}

- (void) setPostFader: (SndAudioFader *) newPostFader
{
    [postFader release];
    postFader = [newPostFader retain];
}

////////////////////////////////////////////////////////////////////////////////
// nowTime
////////////////////////////////////////////////////////////////////////////////

- (double) nowTime
{
    return nowTime;
}

////////////////////////////////////////////////////////////////////////////////

@end
