////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    Snd methods concerned with recording and playing.
//
//  Original Author: Leigh Smith
//
//  Copyright (c) 2004, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import "Snd.h"
#import "SndPlayer.h"
#import "SndAudioProcessorChain.h"

@implementation Snd(Playing)

// Begin the playback of the sound at some future time, specified in seconds, over a region of the sound.
// All other play methods are convenience wrappers around this.
- (SndPerformance *) playInFuture: (double) inSeconds 
                      beginSample: (unsigned long) begin
                      sampleCount: (unsigned long) count 
{
    unsigned long playBegin = begin;
    unsigned long playEnd = begin + count;
    
    [self compactSamples]; // in case this is a pasted sound.

    if (playBegin > [self lengthInSampleFrames] || playBegin < 0)
        playBegin = 0;
    
    if (playEnd > [self lengthInSampleFrames] || playEnd < playBegin)
        playEnd = [self lengthInSampleFrames];

    // TODO Remove status, instead derive from SndPerformance.
    status = SND_SoundPlayingPending;
    
    return [[SndPlayer defaultSndPlayer] playSnd: self 
                                  withTimeOffset: inSeconds 
                                    beginAtIndex: playBegin 
                                      endAtIndex: playEnd];
}

- (SndPerformance *) playInFuture: (double) inSeconds
           startPositionInSeconds: (double) startPos
                durationInSeconds: (double) duration
{
  double sr = [self samplingRate];
  return [self playInFuture: inSeconds
                beginSample: startPos * sr
                sampleCount: duration * sr];
}

+ (BOOL) isMuted
{
    return SNDIsMuted();
}

+ setMute:(BOOL)aFlag
{
    SNDSetMute(aFlag);
    return self;
}

// TODO See if we can make this use self playInFuture so all use of looping
// is done in playInFuture:beginSample:sampleCount:
- (SndPerformance *) playAtTimeInSeconds: (double) t withDurationInSeconds: (double) d
{
//  NSLog(@"Snd::playAtTimeInSeconds: %f", t);
  return [[SndPlayer defaultSndPlayer] playSnd: self
                               atTimeInSeconds: t
                        startPositionInSeconds: 0
                             durationInSeconds: d];  
}

- (SndPerformance *) playInFuture: (double) inSeconds 
{
    return [self playInFuture: inSeconds 
                  beginSample: 0
                  sampleCount: [self lengthInSampleFrames]];
}

- (SndPerformance *) playAtDate: (NSDate *) date
{
    return [self playInFuture: [date timeIntervalSinceNow]];
}

// Legacy method for SoundKit compatability
- play: (id) sender beginSample: (int) begin sampleCount: (int) count 
{
    // do something with sender?
    [self playInFuture: 0.0
           beginSample: begin
           sampleCount: count];
    return self;
}

// Legacy method for SoundKit compatability
- play: sender
{
    // do something with sender?
    [self playInFuture: 0.0];
    return self;
}

// Legacy method for SoundKit compatability
- (int) play
{
    [self play: self];
    return SND_ERR_NONE;
}

- record: sender
{
    NSLog(@"Not yet implemented!\n");
    // [self recordInFuture: 0.0];
    return self;
}

- (int) record
{
    [self record: self];
    return SND_ERR_NONE;
}

- (int) samplesPerformedOfPerformance: (SndPerformance *) performance;
{
    return [performance playIndex];
}

- (int) waitUntilStopped
{
    return SND_ERR_NOT_IMPLEMENTED;
}

// stop the performance
+ (void) stopPerformance: (SndPerformance *) performance inFuture: (double) inSeconds
{
    [[SndPlayer defaultSndPlayer] stopPerformance: performance inFuture: inSeconds];
}

- (void) stopInFuture: (double) inSeconds
{
    if (status == SND_SoundRecording || status == SND_SoundRecordingPaused) {
        status = SND_SoundStopped;
        [self tellDelegate: @selector(didRecord:)];	
    }
  // SKoT: I commented this out as the player may have PENDING performances to
  // deal with as well - in which case the SND won't have a playing status.
  // Basically yet another reason to move playing status stuff out of the snd obj.
//    if (status == SND_SoundPlaying || status == SND_SoundPlayingPaused) {
        [[SndPlayer defaultSndPlayer] stopSnd: self withTimeOffset: inSeconds];
//    }
}

- (void) stop: (id) sender
{
    [self stopInFuture: 0.0];
}

- (int) stop
{
    [self stop: self];
    return SND_ERR_NONE;
}

- pause: sender
{
  [performancesArrayLock lock];
  [performancesArray makeObjectsPerformSelector: @selector(pause)];
  [performancesArrayLock unlock];
  return self;
}

- (int) pause
{
  [self pause: self];
  return SND_ERR_NONE;
}

- resume: sender
{
  [performancesArrayLock lock];
  [performancesArray makeObjectsPerformSelector: @selector(resume)];
  [performancesArrayLock unlock];
  return self;
}

- (int) resume;
{
  [self resume:self];
  return SND_ERR_NONE;
}

- (BOOL) isPlayable
{
    SndSampleFormat df;
    int cc;
    double sr;
    
    if ([self lengthInSampleFrames] == 0)
	return YES; /* empty sound can be played! */
    df = [self dataFormat];
    cc = [self channelCount];
    if (cc < 1)
	return NO;
    sr = [self samplingRate];
    if(sr <= 0.0)
	return NO;
    switch (df) {
	case SND_FORMAT_MULAW_8:
	case SND_FORMAT_LINEAR_8:
	case SND_FORMAT_LINEAR_16:
	case SND_FORMAT_LINEAR_24:
	case SND_FORMAT_LINEAR_32:
	case SND_FORMAT_FLOAT:
	case SND_FORMAT_DOUBLE:
	    return YES;
	default:
	    break;
    }
    return NO;
}

- (NSArray *) performances
{
    return performancesArray;
}

- addPerformance: (SndPerformance*) p
{
    [performancesArrayLock lock];
    [performancesArray addObject: p];
    [performancesArrayLock unlock];
    return self;
}

- removePerformance: (SndPerformance*) p
{
    [performancesArrayLock lock];
    [performancesArray removeObject: p];
    [performancesArrayLock unlock];
    return self;
}

- (int) performanceCount
{
    return [performancesArray count];
}

- (void) setLoopWhenPlaying: (BOOL) yesOrNo
{
    loopWhenPlaying = yesOrNo;
}

- (BOOL) loopWhenPlaying
{
    return loopWhenPlaying;
}

- (void) setLoopStartIndex: (long) newLoopStartIndex
{
    loopStartIndex = newLoopStartIndex;
}

- (long) loopStartIndex
{
    return loopStartIndex;
}

- (void) setLoopEndIndex: (long) newLoopEndIndex
{
    loopEndIndex = newLoopEndIndex;
}

- (long) loopEndIndex
{
    return loopEndIndex;
}

- (BOOL) isPlaying
{
    // if any performances are currently playing, return YES.
    int performanceIndex;
    int performanceCount = [performancesArray count];
    
    for(performanceIndex = 0; performanceIndex < performanceCount; performanceIndex++) {
	if([[performancesArray objectAtIndex: performanceIndex] isPlaying])
	    return YES;
    }
    // 
    // performancesArrayLock
    return NO;
}

- (void) setAudioProcessorChain: (SndAudioProcessorChain *) newAudioProcessorChain
{
    [audioProcessorChain release];
    audioProcessorChain = [newAudioProcessorChain retain];
}

- (SndAudioProcessorChain *) audioProcessorChain
{
    return [[audioProcessorChain retain] autorelease];
}

- (void) adjustLoopStart: (long *) newLoopStart 
		     end: (long *) newLoopEnd
	   afterRemoving: (long) sampleCountRemoved
	      startingAt: (long) startSample
{
    // NSLog(@"*newLoopStart %ld, *newLoopEnd %ld\n", *newLoopStart, *newLoopEnd);
    if(*newLoopEnd < startSample + sampleCountRemoved)
	*newLoopEnd = MIN(*newLoopEnd, [self lengthInSampleFrames]);
    else {
	*newLoopEnd -= sampleCountRemoved;
	if(*newLoopEnd < 0)
	    *newLoopEnd = 0;
    }
    if(*newLoopStart < startSample + sampleCountRemoved)
	// TODO Perhaps just leave it rather than moving it to startSample?
	*newLoopStart = MIN(*newLoopStart, startSample); 
    else {
	*newLoopStart -= sampleCountRemoved;
	if(*newLoopStart < 0)
	    *newLoopStart = 0;	    
    }
    // NSLog(@"after deleting *newLoopStart %ld, *newLoopEnd %ld\n", *newLoopStart, *newLoopEnd);    
}

- (void) adjustLoopStart: (long *) newLoopStart 
		     end: (long *) newLoopEnd
	     afterAdding: (long) sampleCountAdded
	      startingAt: (long) startSample
{
    long soundLength = [self lengthInSampleFrames];
    
    NSLog(@"adding %ld to *newLoopStart %ld, *newLoopEnd %ld \n", sampleCountAdded, *newLoopStart, *newLoopEnd);
    if(*newLoopEnd < startSample)
	*newLoopEnd = MIN(*newLoopEnd, soundLength);
    else {
	*newLoopEnd += sampleCountAdded;
	if(*newLoopEnd > soundLength)
	    *newLoopEnd = soundLength;
    }
    if(*newLoopStart >= startSample) {
	*newLoopStart += sampleCountAdded;
	if(*newLoopStart > soundLength)
	    *newLoopStart = soundLength;	    
    }
    NSLog(@"after adding *newLoopStart %ld, *newLoopEnd %ld, soundLength %ld\n", *newLoopStart, *newLoopEnd, soundLength);    
}

- (void) adjustLoopsAfterAdding: (BOOL) adding 
			 frames: (long) sampleCount
		     startingAt: (long) startSample
{
    int performanceIndex;
    
    // Update loop end index and in all performances.
    if(adding) {
	[self adjustLoopStart: &loopStartIndex
			  end: &loopEndIndex
		  afterAdding: sampleCount
		   startingAt: startSample];	
    }
    else {
	[self adjustLoopStart: &loopStartIndex
			  end: &loopEndIndex
		afterRemoving: sampleCount
		   startingAt: startSample];
    }
    for(performanceIndex = 0; performanceIndex < [performancesArray count]; performanceIndex++) {
	SndPerformance *performance = [performancesArray objectAtIndex: performanceIndex];
	long performanceStartLoopIndex;
	long performanceEndLoopIndex;
	
	[performancesArrayLock lock]; // TODO check this is right.
	performanceStartLoopIndex = [performance loopStartIndex];
	performanceEndLoopIndex = [performance loopEndIndex];
	if(adding) {
	    [self adjustLoopStart: &performanceStartLoopIndex
			      end: &performanceEndLoopIndex
		      afterAdding: sampleCount
		       startingAt: startSample];
	    [performance setEndAtIndex: [performance endAtIndex] + sampleCount];
	    NSLog(@"performanceEndLoopIndex %ld endIndex %ld\n", performanceEndLoopIndex, [performance endAtIndex]);
	}
	else {
	    [self adjustLoopStart: &performanceStartLoopIndex
			      end: &performanceEndLoopIndex
		    afterRemoving: sampleCount
		       startingAt: startSample];
	    [performance setEndAtIndex: [performance endAtIndex] - sampleCount];
	}
	[performance setLoopStartIndex: performanceStartLoopIndex];
	[performance setLoopEndIndex: performanceEndLoopIndex];
	[performancesArrayLock unlock];
    }
}

@end
