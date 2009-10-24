////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    Snd methods concerned with editing (cut/paste/insertion/compacting etc).
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
#import "SndAudioBuffer.h"
#import "SndFunctions.h"

// Turn on for debugging output.
#define SND_DEBUG_LOOPING 0

@implementation Snd(Editing)

- (void) lockEditing
{
    [editingLock lock];
}

- (void) unlockEditing
{
    [editingLock unlock];
}

/*
 * If fromSound is non-fragmented, create new sound and copy appropriate samples.
 * If fragmented into a number of audio buffers:
 * 	Find the audio buffer with the start of the frame range.
 *	find 1st and last frag containing samples
 *	loop from 1st to last, creating new frag and copying appropriate samples
 */
- (Snd *) soundFromSamplesInRange: (NSRange) frameRange
{
    NSUInteger soundBufferIndex;
    SndAudioBuffer *audioBuffer;
    // TODO perhaps make this allocWithZone:, take a zone parameter and make soundFromSamplesInRange:zone: the basis of copyWithZone:.
    Snd *newSound = [[[self class] alloc] initWithFormat: [self dataFormat]
					    channelCount: [self channelCount]
						  frames: frameRange.length
					    samplingRate: [self samplingRate]];
    // The state of copying a number of audio buffers.
    enum { BEFORE_COPYING, FULL_COPY_ADDITIONAL, COPY_LAST_PARTIAL } copyState = BEFORE_COPYING;
    long startFrameOfBuffer = 0; // The frame index at the start of each audio buffer.
    NSRange rangeOfBufferToCopy = NSMakeRange(0, 0);
    SndAudioBuffer *destinationBuffer = [newSound->soundBuffers objectAtIndex: 0];
    NSRange destinationCopyRange = NSMakeRange(0, 0);

    if (frameRange.location < 0 || 
	frameRange.location > [self lengthInSampleFrames] ||
	frameRange.location + frameRange.length > [self lengthInSampleFrames]) 
	return nil;
    
    [editingLock lock];

    for(soundBufferIndex = 0; soundBufferIndex < [soundBuffers count] && copyState != COPY_LAST_PARTIAL; soundBufferIndex++) {
	audioBuffer = [soundBuffers objectAtIndex: soundBufferIndex];
	
	// If we are to copy full additional buffers to the destination.
	if(copyState == FULL_COPY_ADDITIONAL) {    // copy remaining buffers until the last is encountered
	    rangeOfBufferToCopy.location = 0;
	    // The last one will be partial.
	    if(frameRange.location + frameRange.length < startFrameOfBuffer + [audioBuffer lengthInSampleFrames]) {
		// found last buffer, copy to the end of region
		rangeOfBufferToCopy.length = (frameRange.location + frameRange.length) - startFrameOfBuffer;
		copyState = COPY_LAST_PARTIAL;
	    }
	    else {
		// copy to the end of this buffer. Stay in the copy additional full buffers state.
		rangeOfBufferToCopy.length = [audioBuffer lengthInSampleFrames] - rangeOfBufferToCopy.location; 
		copyState = FULL_COPY_ADDITIONAL;
	    }	    
	}
	// Find the audio buffer which has the start of the frame range.
	else if((frameRange.location < startFrameOfBuffer + [audioBuffer lengthInSampleFrames]) && copyState == BEFORE_COPYING) {
	    rangeOfBufferToCopy.location = frameRange.location - startFrameOfBuffer;
	    // found start, determine if the end of the range is also within the buffer.
	    if(frameRange.location + frameRange.length < startFrameOfBuffer + [audioBuffer lengthInSampleFrames]) {
		rangeOfBufferToCopy.length = frameRange.length; // yes both, copy one buffer range.
		copyState = COPY_LAST_PARTIAL;
	    }
	    else {
		// no, copy to the end of this buffer, then copy following buffers.
		rangeOfBufferToCopy.length = [audioBuffer lengthInSampleFrames] - rangeOfBufferToCopy.location;
		copyState = FULL_COPY_ADDITIONAL;
	    }
	    destinationCopyRange.location = 0;
	}
	if(copyState != BEFORE_COPYING) {
	    // copy into new audio buffer
	    destinationCopyRange.length = rangeOfBufferToCopy.length;	    // length will always be equal.
	    [destinationBuffer copyFromBuffer: audioBuffer 
			       intoFrameRange: destinationCopyRange
			       fromFrameRange: rangeOfBufferToCopy];
	    // Update for next write location.
	    destinationCopyRange.location += rangeOfBufferToCopy.length;
	}
	startFrameOfBuffer += [audioBuffer lengthInSampleFrames];
    }

    // Duplicate all other ivars
    [newSound setInfo: [self info]];
    
    newSound->priority = priority;
    [newSound setDelegate: [self delegate]];		 
    [newSound setName: [self name]];
    newSound->conversionQuality = conversionQuality;

    // TODO these should be modified to match the new sound's dimensions.
    newSound->loopWhenPlaying = loopWhenPlaying;
    newSound->loopStartIndex = loopStartIndex;
    newSound->loopEndIndex = loopEndIndex;
    
    [newSound setAudioProcessorChain: [self audioProcessorChain]];
    
    [editingLock unlock];
    
    return [newSound autorelease];    
}

- (int) compactSamples
{
    if (![self isEditable]) 
	return SND_ERR_CANNOT_EDIT;

    if([self needsCompacting]) {
	Snd *newCompactedSnd = [self soundFromSamplesInRange: NSMakeRange(0, [self lengthInSampleFrames])];

	// Replace the soundBuffers with the array containing the single compacted one.
	[editingLock lock];
	[soundBuffers removeAllObjects];
	[soundBuffers addObjectsFromArray: [newCompactedSnd audioBuffers]];
	[editingLock unlock];
    }
    return SND_ERR_NONE;
}

- (BOOL) needsCompacting
{
    return [soundBuffers count] > 1;
}

- (int) deleteSamplesInRange: (NSRange) frameRange
{
    NSUInteger soundBufferIndex;
    SndAudioBuffer *audioBuffer;
    // The state of copying a number of audio buffers.
    enum { BEFORE_DELETING, FULL_DELETE_ADDITIONAL, DELETE_LAST_PARTIAL } deleteState = BEFORE_DELETING;
    long startFrameOfBuffer = 0; // The frame index at the start of each audio buffer.
    NSRange rangeOfBufferToPreserve = NSMakeRange(0, 0);
    SndAudioBuffer *preservedBuffer;
    
    if (frameRange.location < 0 || 
	frameRange.location > [self lengthInSampleFrames] ||
	frameRange.location + frameRange.length > [self lengthInSampleFrames]) 
	return SND_ERR_BAD_SIZE;
    if (!frameRange.length) 
	return SND_ERR_NONE;
    
    // we need to lock the whole method since we refer to a number of variables that would cause problems if not locked.
    [editingLock lock]; 
    
    for(soundBufferIndex = 0; soundBufferIndex < [soundBuffers count] && deleteState != DELETE_LAST_PARTIAL; soundBufferIndex++) {
	audioBuffer = [[soundBuffers objectAtIndex: soundBufferIndex] retain]; // retain since we replace or remove it.
	
	// Find the audio buffer which has the start of the frame range.
	if((frameRange.location < startFrameOfBuffer + [audioBuffer lengthInSampleFrames]) && deleteState == BEFORE_DELETING) {
	    rangeOfBufferToPreserve.location = 0;
	    rangeOfBufferToPreserve.length = frameRange.location - startFrameOfBuffer;
	    if(rangeOfBufferToPreserve.length != 0) {
		// There is leading audio to preserve, delete (possibly to the end of this buffer), by replacing audioBuffer 
		// with one new audio buffer.
		preservedBuffer = [[SndAudioBuffer alloc] initWithBuffer: audioBuffer range: rangeOfBufferToPreserve];
		[soundBuffers replaceObjectAtIndex: soundBufferIndex withObject: preservedBuffer];
		[preservedBuffer release];
		// then delete following buffers until a partial buffer.
		deleteState = FULL_DELETE_ADDITIONAL;
	    }
	    else {
		// no leading audio to preserve, just remove the buffer from the list completely. 
		// If we are actually deleting the start of the buffer, we will add the preserved region below.
		[soundBuffers removeObjectAtIndex: soundBufferIndex];
		// update the soundBufferIndex once we remove the object
		soundBufferIndex--;
		// then delete following buffers until a partial buffer.
		deleteState = FULL_DELETE_ADDITIONAL;
	    }
	    // determine if the end of the delete range is also within the buffer.
	    if(frameRange.location + frameRange.length < startFrameOfBuffer + [audioBuffer lengthInSampleFrames]) {
		// yes both, should add a second audioBuffer.
		rangeOfBufferToPreserve.location = frameRange.location + frameRange.length - startFrameOfBuffer;
		rangeOfBufferToPreserve.length = [audioBuffer lengthInSampleFrames] - rangeOfBufferToPreserve.location;
		preservedBuffer = [[SndAudioBuffer alloc] initWithBuffer: audioBuffer range: rangeOfBufferToPreserve];
		[soundBuffers insertObject: preservedBuffer atIndex: soundBufferIndex + 1];
		[preservedBuffer release];
		deleteState = DELETE_LAST_PARTIAL; // move to the terminal state.
	    }
	}
	// If we are to delete full additional buffers to the destination.
	else if(deleteState == FULL_DELETE_ADDITIONAL) {    // delete remaining buffers until the last is encountered
	    if(frameRange.location + frameRange.length < startFrameOfBuffer + [audioBuffer lengthInSampleFrames]) {
		// should replace audioBuffer with two new audio buffers:
		rangeOfBufferToPreserve.location = frameRange.location + frameRange.length - startFrameOfBuffer;
		rangeOfBufferToPreserve.length = [audioBuffer lengthInSampleFrames] - rangeOfBufferToPreserve.location;
		preservedBuffer = [[SndAudioBuffer alloc] initWithBuffer: audioBuffer range: rangeOfBufferToPreserve];		
		[soundBuffers replaceObjectAtIndex: soundBufferIndex withObject: preservedBuffer];
		[preservedBuffer release];
		deleteState = DELETE_LAST_PARTIAL;
	    }
	    else {
		// Just remove the buffer from the list completely.
		[soundBuffers removeObjectAtIndex: soundBufferIndex];
		// update the soundBufferIndex once we remove the object
		soundBufferIndex--;
		// stay in the deleting multiple buffers state.
	    }
	}
	startFrameOfBuffer += [audioBuffer lengthInSampleFrames];
	[audioBuffer release]; // remove the retain since we've finished with it.
    }
    
    soundFormat.frameCount -= frameRange.length;
    // Update loop end index and in all performances.
    [self adjustLoopsAfterAdding: NO frames: frameRange.length startingAt: frameRange.location];
    
    [editingLock unlock];
    return SND_ERR_NONE;
}

- (int) deleteSamples
{
    NSRange entireSound = { 0, [self lengthInSampleFrames] };
    
    return [self deleteSamplesInRange: entireSound];
}

// Find the audio buffer in soundBuffers that contains startFrame, calculate the offset into that buffer.
// Split that audio buffer into two audio buffers.
// Remove the selected audio buffer from soundBuffers.
// Insert the first subdivided audio buffer, the soundBuffers of fromSnd, followed by the second subdivided audio buffer.
- (int) insertSamples: (Snd *) fromSnd at: (int) startFrame
{
    NSUInteger soundBufferIndex;
    long fromFrameCount = [fromSnd lengthInSampleFrames];
    SndAudioBuffer *audioBuffer;
    long startFrameOfBuffer = 0; // The frame index at the start of each audio buffer.
    
    if (!fromSnd)
        return SND_ERR_NONE;

    [editingLock lock];
    
    // check if the startFrame is at the end of all the buffers, if so, append.
    if(startFrame >= [self lengthInSampleFrames]) {
	[soundBuffers addObjectsFromArray: fromSnd->soundBuffers];
    }
    else {
	// Find the audio buffer in soundBuffers that contains startFrame, calculate the offset into that buffer.
	for(soundBufferIndex = 0; soundBufferIndex < [soundBuffers count]; soundBufferIndex++) {
	    audioBuffer = [soundBuffers objectAtIndex: soundBufferIndex];
	    
	    // Check if we fluke the insertion point on a buffer boundary. In that case, just insert the audio buffers.
	    if(startFrame == startFrameOfBuffer) {	    // Insert the soundBuffers of fromSnd.
		NSIndexSet *bufferInsertion = [NSIndexSet indexSetWithIndex: soundBufferIndex];
		
		[soundBuffers insertObjects: fromSnd->soundBuffers atIndexes: bufferInsertion];
		break;
	    }
	    else if(startFrame < startFrameOfBuffer + [audioBuffer lengthInSampleFrames]) {
		long divisionFrame = startFrame - startFrameOfBuffer; // mark where we split the buffer.
		long secondBufferLength = [audioBuffer lengthInSampleFrames] - divisionFrame;
		// Split that audio buffer into two audio buffers.
		SndAudioBuffer *firstSubdividedBuffer = [[SndAudioBuffer alloc] initWithBuffer: audioBuffer range: NSMakeRange(0, divisionFrame)];
		SndAudioBuffer *secondSubdividedBuffer = [[SndAudioBuffer alloc] initWithBuffer: audioBuffer range: NSMakeRange(divisionFrame, secondBufferLength)];
		NSIndexSet *insertAllBuffers = [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(soundBufferIndex + 1, [fromSnd->soundBuffers count])];

		// Replace the selected audio buffer from soundBuffers with the first subdivided audio buffer.
		[soundBuffers replaceObjectAtIndex: soundBufferIndex withObject: firstSubdividedBuffer];
		// Insert the soundBuffers of fromSnd, followed by the second subdivided audio buffer.
		[soundBuffers insertObjects: fromSnd->soundBuffers atIndexes: insertAllBuffers];
		[soundBuffers insertObject: secondSubdividedBuffer atIndex: [insertAllBuffers lastIndex] + 1];
		break;
	    }
	    startFrameOfBuffer += [audioBuffer lengthInSampleFrames];
	}	
    }
    soundFormat.frameCount += fromFrameCount;

    // Update loop end index and in all performances.
    [self adjustLoopsAfterAdding: YES frames: fromFrameCount startingAt: startFrame];

    [editingLock unlock];
    return SND_ERR_NONE;
}

/* Returns the base address of the block the sample resides in,
 * with appropriate indices for the last sample the block holds.
 * Indices count from 0 so they can be utilised directly.
 */
- (void *) fragmentOfFrame: (unsigned long) frame 
	   indexInFragment: (unsigned long *) currentFrame 
	    fragmentLength: (unsigned long *) fragmentLength
		dataFormat: (SndSampleFormat *) dataFormat
{
    char *fragmentPtr;
    
    [editingLock lock];
    
    // NSLog(@"length @ start of fragmentOfFrame %ld\n", [self lengthInSampleFrames]);

    *dataFormat = [self dataFormat];
    if (*dataFormat != SND_FORMAT_INDIRECT) {
	*fragmentLength = [self lengthInSampleFrames];
	*currentFrame = frame < *fragmentLength ? frame : *fragmentLength - 1;
	fragmentPtr = [self bytes];
    }
    else {
	NSUInteger soundBufferIndex;
	int i = 0;
	unsigned long count = 0, oldCount = 0;
	
	for(soundBufferIndex = 0; soundBufferIndex < [soundBuffers count]; soundBufferIndex++) {
	    SndAudioBuffer *audioBuffer = [soundBuffers objectAtIndex: soundBufferIndex];
	    unsigned long numberOfFramesInFragment = [audioBuffer lengthInSampleFrames];
	    
	    count += numberOfFramesInFragment;
	    if (count > frame) {
		*fragmentLength = numberOfFramesInFragment;
		*currentFrame = frame - oldCount;
		fragmentPtr = [audioBuffer bytes];
		[editingLock unlock];
		return fragmentPtr; 
	    }
	    oldCount = count;
	}
	NSLog(@"Looking for %ld, Ran through entire fragment list %d long, count %d, length now %ld\n",
	      frame, i, count, [self lengthInSampleFrames]);
	*currentFrame = 0;
	*fragmentLength = 0;
	fragmentPtr = NULL;
    }
    [editingLock unlock];
    return fragmentPtr; 
}

// Handles fragmented and non-fragmented sounds.
- (long) insertIntoAudioBuffer: (SndAudioBuffer *) buff
		intoFrameRange: (NSRange) bufferFrameRange
	        samplesInRange: (NSRange) sndFrameRange
{
    unsigned long frameIndexWithinFragment;
    SndSampleFormat retrievedDataFormat;
    NSRange bufferFragment;
    unsigned int framesFilled = 0;
    unsigned int buffFrameSize = [buff frameSizeInBytes];
    unsigned int sndFrameSize = SndFrameSize(soundFormat);
    void  *sndDataPtr;
    double stretchFactor;
    BOOL sameFormat;

    // lock the filling of the entire buffer. This may be a bit too heavy, but given typical buffer lengths
    // and that this is protecting an edit operation (relatively infrequent), we should be ok.
    [editingLock lock]; 
    
    sndDataPtr = [self bytes] + sndFrameRange.location * sndFrameSize;
    stretchFactor = [buff samplingRate] / [self samplingRate];
    sameFormat = [self hasSameFormatAsBuffer: buff];
    
    // NSLog(@"insertIntoAudioBuffer: bufferFrameRange [%ld, %ld] sndFrameRange [%ld,%ld]\n",
    //	  bufferFrameRange.location, bufferFrameRange.location + bufferFrameRange.length,
    //	  sndFrameRange.location, sndFrameRange.location + sndFrameRange.length);
    
    // Check if the number of frames to fill into the buffer will exceed the number of frames in the sound
    // remaining to be played (including when downsampling). If so, reduce the number to fill into the buffer,
    // pad the remainder of the buffer range with zeros. This will only occur at the end of a sound.

    if((bufferFrameRange.length / stretchFactor) > sndFrameRange.length) {
	long originalBufferFrameLength = bufferFrameRange.length;
	NSRange toZero;
	
	bufferFrameRange.length = sndFrameRange.length * stretchFactor;
	//NSLog(@"shortened buffer length to %ld\n", bufferFrameRange.length);
	toZero.location = bufferFrameRange.length;
	toZero.length = originalBufferFrameLength - bufferFrameRange.length;
	[buff zeroFrameRange: toZero];
    }
    
    // When retrieving from a fragmented sound, we fetch one or more fragments to fill the buffer.
    bufferFragment.location = bufferFrameRange.location;

    while(framesFilled < bufferFrameRange.length) { // iterate over the number of fragments the buffer filling spans
	unsigned long fragmentLength;
	unsigned int sndFragmentRemaining;
	void *sndFragmentPtr = [self fragmentOfFrame: sndFrameRange.location 
				     indexInFragment: &frameIndexWithinFragment 
				      fragmentLength: &fragmentLength
					  dataFormat: &retrievedDataFormat];
		
	sndFragmentRemaining = fragmentLength - frameIndexWithinFragment;
	sndDataPtr = sndFragmentPtr + frameIndexWithinFragment * sndFrameSize;
	
	if(sndFragmentRemaining < bufferFrameRange.length - framesFilled)
	    bufferFragment.length = sndFragmentRemaining;
	else
	    bufferFragment.length = bufferFrameRange.length - framesFilled;
	
	if(bufferFragment.length == 0)
	    NSLog(@"bufferFragment == 0, sndDataPtr == %p sndFragmentPtr == %p frameIndexWithinFragment %d fragmentLength %d\n", 
		  sndDataPtr, sndFragmentPtr, frameIndexWithinFragment, fragmentLength);
	
	// Matching sound and buffer formats, so we can just do a copy.
	if(sameFormat) {
	    NSRange bufferByteRange;

	    bufferByteRange.location = bufferFragment.location * buffFrameSize;
	    bufferByteRange.length = bufferFragment.length * buffFrameSize;
	    [buff copyBytes: sndDataPtr intoRange: bufferByteRange format: soundFormat];
	    // framesFilled += bufferFragment.length;
	}
	else { // If not the same, do a data conversion.
	    // The number of frames returned as read could be more or less than bufferFrameRange.length if resampling occurs.
	    // long framesRead = [buff convertBytes: sndDataPtr
	    [buff convertBytes: sndDataPtr
		intoFrameRange: bufferFragment
		    fromFormat: [self dataFormat]
		  channelCount: [self channelCount]
		  samplingRate: [self samplingRate]];
	    
	    //NSLog(@"buffer to fill %@ mismatched to %@, converted, read %ld\n", buff, self, framesRead);
	    // bufferFragment.length = framesRead;  // framesRead depends on resampling.
	}
	
	bufferFragment.location += bufferFragment.length;
	sndFrameRange.location += bufferFragment.length;
	framesFilled += bufferFragment.length;
    }

    [editingLock unlock];

    return bufferFrameRange.length; // framesFilled
}

- (long) insertIntoAudioBuffer: (SndAudioBuffer *) bufferToFill
		intoFrameRange: (NSRange) bufferFrameRange
	        samplesInRange: (NSRange) sndFrameRange
		       looping: (BOOL) isLooping
		loopStartIndex: (long) thisLoopStartIndex
		  loopEndIndex: (long) thisLoopEndIndex
{
    long fillBufferToLength = bufferFrameRange.length;
    // long framesUntilEndOfLoop = loopEndIndex - sndFrameRange.location + 1;
    // Determine number of frames in the loop, checking for resampling shortening that number.
    double stretchFactor = [bufferToFill samplingRate] / [self samplingRate];
    long framesUntilEndOfLoop = (thisLoopEndIndex - sndFrameRange.location + 1) * (stretchFactor < 1.0 ? stretchFactor : 1.0);
    BOOL atEndOfLoop = isLooping && (bufferFrameRange.length >= framesUntilEndOfLoop);
    // numOfSamplesFilled and numOfSamplesRead can differ if we resample in fillAudioBuffer.
    long numOfSamplesFilled = 0;
    long numOfSamplesRead = 0;
    // specifies to fillAudioBuffer: and insertIntoAudioBuffer: the range of Snd samples permissible to read from.
    NSRange samplesToReadRange;
    
    if (atEndOfLoop) {	// retrieve up to the end of the loop
	fillBufferToLength = framesUntilEndOfLoop;
    }
    // specify the final boundary in the Snd fillAudioBuffer: can not read beyond.
    samplesToReadRange.location = sndFrameRange.location;
    samplesToReadRange.length = isLooping ? framesUntilEndOfLoop : sndFrameRange.length;
    
#if SND_DEBUG_LOOPING
    NSLog(@"[Snd][SYNTH THREAD] sndFrameRange.location = %ld, sndFrameRange.length = %ld, buffer length = %d, fill buffer to length = %d, framesUntilEndOfLoop = %ld\n",
	  sndFrameRange.location, sndFrameRange.length, bufferFrameRange.length, fillBufferToLength, framesUntilEndOfLoop);
#endif
    
    // Negative or zero buffer length means the endAtIndex was moved before or to the current sndFrameRange.location,
    // so we should skip any mixing and stop.
    // Nowdays, with better checking on the updates of sndFrameRange.length and sndFrameRange.location this should never occur,
    // so this check is probably redundant, but hey, it adds robustness which translates into saving someones
    // ears from hearing noise.
    if (sndFrameRange.location >= 0 && bufferFrameRange.length > 0 && fillBufferToLength > 0) {
	// NSLog(@"bufferToFill dataFormat before processing 1 %d\n", [bufferToFill dataFormat]);
	numOfSamplesRead = [self fillAudioBuffer: bufferToFill
					toLength: fillBufferToLength
				  samplesInRange: samplesToReadRange];
	numOfSamplesFilled = fillBufferToLength;
#if SND_DEBUG_LOOPING
	{
	    //NSLog(@"bufferToFill %@, numOfSamplesFilled = %ld, numOfSamplesRead = %ld\n",
	    //    bufferToFill, numOfSamplesFilled, numOfSamplesRead);
	    long i;
	    for (i = 0; i < numOfSamplesFilled; i++)
		NSLog(@"%f\n", [bufferToFill sampleAtFrameIndex: i channel: 0]);
	}
#endif
	
	if(atEndOfLoop) {
	    // If we are at the end of the loop, copy in zero or more (when the loop is small) loop regions 
	    // then any remaining beginning of the loop.
	    int loopLength = thisLoopEndIndex - thisLoopStartIndex + 1;
	    long fillBufferFrom = fillBufferToLength;
	    long remainingLengthToFillWithLoop = bufferFrameRange.length - fillBufferFrom;
	    
	    // Reset sndFrameRange.location to the start of the loop. We do this before the loop in case we do no loops,
	    // in the singular case that the loop ends at the end of a buffer, requiring no insertion of loop
	    // regions for this buffer.
	    sndFrameRange.location = thisLoopStartIndex;   
	    while(remainingLengthToFillWithLoop > 0 && loopLength > 0) {
		NSRange loopRegion;
		
		// give the range of Snd samples permissible to read from.
		samplesToReadRange.location = thisLoopStartIndex;
		samplesToReadRange.length = loopLength;
		// give the range to fill in the buffer
		loopRegion.location = fillBufferFrom;
		loopRegion.length = MIN(remainingLengthToFillWithLoop, loopLength);
		
		numOfSamplesRead = [self insertIntoAudioBuffer: bufferToFill
						intoFrameRange: loopRegion
						samplesInRange: samplesToReadRange];
#if SND_DEBUG_LOOPING
		{
		    long i;
		    
		    NSLog(@"%@ loopRegion.location = %ld, loopRegion.length = %ld, sndFrameRange.location = %ld, fillBufferFrom = %d, remainingLengthToFillWithLoop = %d\n",
			  bufferToFill, loopRegion.location, loopRegion.length, sndFrameRange.location, fillBufferFrom, remainingLengthToFillWithLoop);
		    for (i = fillBufferFrom - 5; i < fillBufferFrom + 5; i++)
			NSLog(@"buffer[%ld] = %e\n", i, [bufferToFill sampleAtFrameIndex: i channel: 0]);
		}
#endif
		numOfSamplesFilled += loopRegion.length;
		sndFrameRange.location += numOfSamplesRead;
		fillBufferFrom += loopRegion.length; 
		remainingLengthToFillWithLoop -= loopRegion.length;
	    }
	}
	else
	    sndFrameRange.location += numOfSamplesRead;  // Update the read index accounting for change from resampling.
		
#if SND_DEBUG_LOOPING
	NSLog(@"[Snd][SYNTH THREAD] will mix buffer from %d to %d, old sndFrameRange.location %d for %d, val at start = %f\n",
	      0, fillBufferToLength, samplesToReadRange.location, numOfSamplesFilled,
	      (((short *) [self data])[samplesToReadRange.location]) / (float) 32768);
#endif
    }
    else
	sndFrameRange.location += bufferFrameRange.length;  // If there is a problem, push the sndFrameRange.location forward, we may improve...somehow...
    
    //NSLog(@"retrieved numOfSamplesFilled = %ld\n", numOfSamplesFilled);
    return numOfSamplesFilled;    
}

- (long) fillAudioBuffer: (SndAudioBuffer *) buff
		toLength: (long) fillLength
          samplesInRange: (NSRange) readFromSndSample
{
    NSRange bufferRange;
    long framesInserted;
    
    [editingLock lock];
    bufferRange.location = 0;
    bufferRange.length = fillLength; // TODO this may become [buff lengthInSamples] if we remove toLength: parameter.
    
    // NSLog(@"fillAudioBuffer: intoFrameRange: %ld %ld samplesInRange: %ld %ld, length of snd %ld", 
    // bufferRange.location, bufferRange.length, readFromSndSample.location, readFromSndSample.length, [self lengthInSampleFrames]);
    framesInserted = [self insertIntoAudioBuffer: buff
				  intoFrameRange: bufferRange
				  samplesInRange: readFromSndSample];
    [editingLock unlock];
    return framesInserted;
}

- (long) insertAudioBuffer: (SndAudioBuffer *) buffer
	    intoFrameRange: (NSRange) writeIntoSndFrameRange
{    
    if(![self hasSameFormatAsBuffer: buffer]) { // If not the same, do a data conversion.
	NSLog(@"mismatched buffer %@ and snd %@ formats, format conversion needs implementation\n", buffer, self);
    }

    [editingLock lock];
    memcpy([self bytes] + writeIntoSndFrameRange.location, [buffer bytes], writeIntoSndFrameRange.length);
    [editingLock unlock];
    return [self lengthInSampleFrames];
}

- (long) appendAudioBuffer: (SndAudioBuffer *) buffer
{    
    // If not the same, do a data conversion.
    if(![self hasSameFormatAsBuffer: buffer]) {
	NSLog(@"mismatched buffer %@ and snd %@ formats, format conversion needs implementation\n", buffer, self);
    }
    else {
	[editingLock lock];
	[soundBuffers addObject: [buffer copy]];
	soundFormat.frameCount += [buffer lengthInSampleFrames];
	[editingLock unlock];
    }
    return [self lengthInSampleFrames];
}

- (SndAudioBuffer *) audioBufferForSamplesInRange: (NSRange) sndFrameRange
					  looping: (BOOL) isLooping
{
    SndAudioBuffer *newAudioBuffer  = [SndAudioBuffer audioBufferWithDataFormat: soundFormat.dataFormat
								   channelCount: soundFormat.channelCount
								   samplingRate: soundFormat.sampleRate
								     frameCount: sndFrameRange.length];
    NSRange bufferFrameRange = { 0, sndFrameRange.length };
    
    [self insertIntoAudioBuffer: newAudioBuffer
		 intoFrameRange: bufferFrameRange
		 samplesInRange: sndFrameRange
			looping: isLooping
		 loopStartIndex: loopStartIndex
		   loopEndIndex: loopEndIndex];
    return newAudioBuffer;
}

- (SndAudioBuffer *) audioBufferForSamplesInRange: (NSRange) sndFrameRange
{
    return [self audioBufferForSamplesInRange: sndFrameRange looping: NO];
}

- (NSArray *) audioBuffers
{
    return [NSArray arrayWithArray: soundBuffers];
}

@end
