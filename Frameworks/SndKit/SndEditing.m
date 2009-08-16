////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    Snd methods concerned with editing (cut/paste/insertion/compacting etc).
//
//    TODO All static functions that used to reside in SndFunctions as public functions and take SndSoundStruct parameters. They eventually
//    need to be merged into the methods that use them, removing SndSoundStruct use entirely. This needs to be done
//    in the context of an array of SndAudioBuffers replacing fragmented SndSoundStructs.
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

/*!
@function _SndCopyFragBytes
 @abstract To come
 @discussion
 _SndCopyFragBytes Does the same as _SndCopyFrag, but used for `partial' frags
 that occur whenyou insert or delete data from a SndStruct.
 If byteCount == -1, uses all data from startByte to end of frag.
 Does not make copy of fragged sound. Info string should therefore be only 4 bytes,
 but this takes account of longer info strings if they exist.
 @param fromSoundFrag
 @param startByte
 @param byteCount
 @result
 */
static SndSoundStruct * _SndCopyFragBytes(SndSoundStruct *fromSoundFrag, int startByte, int byteCount)
/* Does the same as _SndCopyFrag, but used for `partial' frags that occur when you insert or
* delete data from a SndStruct.
* If byteCount == -1, uses all data from startByte to end of frag.
* Does not make copy of fragged sound. Info string should therefore be only 4 bytes,
* but this takes account of longer info strings if they exist.
*/
{
    SndSoundStruct *newStruct;
    int infoSize;
    int ds;
    
    if (!fromSoundFrag) return NULL;
    ds = fromSoundFrag->dataSize;
    if (byteCount == -1) byteCount = ds - startByte;
    if (startByte + byteCount > ds) return NULL;
    infoSize = fromSoundFrag->dataLocation - sizeof(SndSoundStruct) + 4;
    if (fromSoundFrag->dataFormat == SND_FORMAT_INDIRECT) return NULL;
    if (SndAlloc(&newStruct, byteCount, fromSoundFrag->dataFormat,
		 fromSoundFrag->samplingRate, fromSoundFrag->channelCount, infoSize))
	return NULL;
    memmove(&(newStruct->info),&(fromSoundFrag->info), infoSize);
    memmove((char *)newStruct + newStruct->dataLocation,
	    (char *)fromSoundFrag + fromSoundFrag->dataLocation + startByte,
	    byteCount);
    return newStruct;
}

SndSoundStruct * _SndCopyFrag(const SndSoundStruct *fromSoundFrag)
/* will not make copy of fragged sound. Info string should therefore be only 4 bytes,
* but this takes account of longer info strings if they exist.
*/
{
    SndSoundStruct *newStruct;
    int infoSize;
    
    if (!fromSoundFrag) return NULL;
    infoSize = fromSoundFrag->dataLocation - sizeof(SndSoundStruct) + 4;
    if (fromSoundFrag->dataFormat == SND_FORMAT_INDIRECT) return NULL;
    if (SndAlloc(&newStruct, fromSoundFrag->dataSize, fromSoundFrag->dataFormat,
		 fromSoundFrag->samplingRate, fromSoundFrag->channelCount, infoSize))
	return NULL;
    memmove(&(newStruct->info),&(fromSoundFrag->info), infoSize);
    memmove((char *)newStruct + newStruct->dataLocation,
	    (char *)fromSoundFrag + fromSoundFrag->dataLocation,
	    fromSoundFrag->dataSize);
    return newStruct;
}

static int SndInsertSamples(SndSoundStruct *toSound, const SndSoundStruct *fromSound, int startSample)
/*
 * The harder case here is when toSound is already fragmented. In this case, simply add
 * another frag at the appropriate place in ssList (if startSample lies on frag boundary)
 * or (more likely) add frag at appropriate place in list, add SECOND frag after that one
 * containing the rest of the `sliced' frag. Then adjust the first sliced frag (realloc).
 *
 * If not fragmented already, create 2 or 3 frags. If the startSample was at pos 0
 * or after the last sample, then the 2 SndStructs just go after each other. If startSample
 * sliced the original sound, need to reslice/realloc as above.
 */
{
  SndSoundStruct **ssList = NULL,**newssList = NULL,**oldNewssList = NULL;
  SndSoundStruct *theStruct,*newStruct;
  int i = 0, ssPointer = 0;
  int cc;
  SndSampleFormat df,ndf;
  int ds;
  int sr;
  int numBytes;
  int numFromFrags = 0, numToFrags = 0;
  int insertFrag = -1;
  int insertFragOffset = 0;
  int insertFragCounter = 0;
  int numFrags = 0;
  int firstFragToFree = -1, firstOfCopiedListToFree = -1;

  if (!fromSound) return SND_ERR_NOT_SOUND;
  if (fromSound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
  if (!toSound) return SND_ERR_NOT_SOUND;
  if (toSound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
  if (startSample < 0 || startSample > SndFrameCount(toSound)) return SND_ERR_BAD_SIZE;

  cc = fromSound->channelCount;
  df = fromSound->dataFormat;
  ds = fromSound->dataSize; /* ie size of header including info string; or data */
  sr = fromSound->samplingRate;
  ndf = toSound->dataFormat;

  if (df == SND_FORMAT_INDIRECT) { /* count the num of frags in "from" sound */
    numBytes = SndSampleWidth(((SndSoundStruct *)(*((SndSoundStruct **)
                                                    (fromSound->dataLocation))))->dataFormat);
    ssList = (SndSoundStruct **)fromSound->dataLocation;
    while ((theStruct = ssList[numFromFrags++]) != NULL);
    numFromFrags--;
    /* numFromFrags is the number of frags */
  }
  else numBytes = SndSampleWidth(df);
  if (ndf == SND_FORMAT_INDIRECT) { /* count the num of frags in "to" sound */
  oldNewssList = (SndSoundStruct **)toSound->dataLocation;
  while ((theStruct = oldNewssList[numToFrags++]) != NULL) {
    int thisCount = (theStruct->dataSize / cc / numBytes);
    if (startSample >= insertFragCounter && startSample < (insertFragCounter + thisCount)) {
        insertFrag = numToFrags - 1;
        insertFragOffset = (startSample - insertFragCounter) * cc * numBytes;
    }
    insertFragCounter += thisCount;
  }
  numToFrags--;
  if (insertFrag == -1) insertFrag = numToFrags; /* stick new data after last frag */
  /* numToFrags is the number of frags */
  /* NOW I know the frag that the insertion begins in, and the sample number within it.*/
  }

  /* need to do frag of original sound if not already fragged. Will require realloc of fromSound,
  * creation of list etc.
  */

  /* In order to make this work with fragged 'toSound', I need to be able to copy
   * the start and end portions as multi-frags, not just as flat data. Hmmm.
   * To do this, I need to be able to split the frag that the startFrag
   * starts and ends in.
   */
  if (ndf != SND_FORMAT_INDIRECT) {
    if (startSample == 0) {
      numFrags = numFromFrags ? numFromFrags + 1 : 2;
    }
    else if (startSample == SndFrameCount(toSound) + 1) {
        numFrags = numFromFrags ? numFromFrags + 1 : 2;
    }
    else numFrags = numFromFrags ? numFromFrags + 2 : 3;
  }

  /* now add number of frags in toSound */
  if (ndf == SND_FORMAT_INDIRECT) {
      numFrags = numFromFrags ? numFromFrags : 1;
      if (insertFragOffset == 0 || startSample == SndFrameCount(toSound) + 1) {
          numFrags += numToFrags;
      }
      else numFrags += (numToFrags + 1);
  }
  //fprintf(stderr,
  //  "numFromFrags: %d numToFrags: %d insertFragOffset %d startSample %d insertFrag %d\n",
  //   numFromFrags, numToFrags, insertFragOffset, startSample, insertFrag);

  if (!(newssList = malloc((numFrags + 1) * sizeof(SndSoundStruct *)))) {
      return SND_ERR_CANNOT_ALLOC;
  }
  newssList[numFrags] = NULL;
  /* stick all sound pre-insert into 1st frag... */
  if (startSample > 0 && ndf != SND_FORMAT_INDIRECT) {
      if (!(newStruct = _SndCopyFragBytes(toSound, 0, startSample * cc * numBytes))) {
          free(newssList);
          return SND_ERR_CANNOT_ALLOC;
      }
      newssList[ssPointer++] = newStruct;
  }
  if (ndf == SND_FORMAT_INDIRECT) {
   /* if insertFrag > 0, we copy pointers to all frags < insertFrag.
    * then, if insertFragOffset > 0, we copy first part of sliced frag
    */
    for (i = 0; i<insertFrag; i++) {
        newssList[ssPointer++] = oldNewssList[i];
    }
    if (insertFragOffset > 0) {
        if (!(newStruct = _SndCopyFragBytes(oldNewssList[insertFrag],0, insertFragOffset))) {
            /* don't have to free earlier frags, as they are only pointers */
            free(newssList);
            return SND_ERR_CANNOT_ALLOC;
        }
        firstFragToFree = ssPointer;
        newssList[ssPointer++] = newStruct;
    }
  }
  /* now copy all the fromSound, or its frags if necessary */
  if (df != SND_FORMAT_INDIRECT) {
      if (!(newStruct = _SndCopyFrag(fromSound))) {
          if (ssPointer > 0) free(newssList[0]);
          free(newssList);
          return SND_ERR_CANNOT_ALLOC;
      }
      newssList[ssPointer++] = newStruct;
  }
  else {
      firstOfCopiedListToFree = ssPointer;/* remember this value so we can free if nec */
      for (i = 0; i < numFromFrags;i++){
          if (!(newStruct = _SndCopyFrag(ssList[i]))) {
              for (i = firstOfCopiedListToFree; i<ssPointer;i++) {
                  free (newssList[i]);
              }
              if (firstFragToFree != -1) free(newssList[firstFragToFree]);
              free(newssList);
              return SND_ERR_CANNOT_ALLOC;
          }
          newssList[ssPointer++] = newStruct;
      }
  }

  /* now copy last bit of original sound into last frag */

  if ((startSample < SndFrameCount(toSound) + 1) && ndf != SND_FORMAT_INDIRECT) {
      if (!(newStruct = _SndCopyFragBytes(toSound, startSample * cc * numBytes,-1))) {
          for(i = 0;i<ssPointer;i++) {
              free (newssList[i]);
          }
          if (firstFragToFree != -1) free(newssList[firstFragToFree]);
          free(newssList);
          return SND_ERR_CANNOT_ALLOC;
      }
      newssList[ssPointer++] = newStruct;
  }

  if (ndf == SND_FORMAT_INDIRECT) {
      /* now copy in remainder of sliced frag (if nec), then further frags
       * from toSound into list (just pointers)
       */
      if (insertFragOffset > 0) {
          if (!(newStruct = _SndCopyFragBytes(oldNewssList[insertFrag], insertFragOffset, -1))) {
              for (i = firstOfCopiedListToFree;i<ssPointer;i++) {
                  free (newssList[i]);
              }
              if (firstFragToFree != -1) free(newssList[firstFragToFree]);
              free(newssList);
              return SND_ERR_CANNOT_ALLOC;
          }
          newssList[ssPointer++] = newStruct;
          free(oldNewssList[insertFrag]);/* this was the one that was sliced,
                                          * and we have copied it, so we free */
          insertFrag++; /* step up to next complete frag to copy references to new list */
      }
      for (i = insertFrag; i<numToFrags; i++) {
          newssList[ssPointer++] = oldNewssList[i];
      }

  }
  if (ndf != SND_FORMAT_INDIRECT) {
      toSound = realloc(toSound,toSound->dataLocation);
      toSound->dataSize = toSound->dataLocation; /* now holds info size only */
      toSound->dataFormat = SND_FORMAT_INDIRECT;
  }
  else free(oldNewssList);
  
  toSound->dataLocation = (int) newssList;
  return SND_ERR_NONE;
}

/*
 * what do I need to do?
 * If fromSound is non-frag, create new sound and copy appropriate samples.
 * If fragged,
 * 		create frag header
 *		find 1st and last frag containing samples
 *		loop from 1st to last, creating new frag and copying appropriate samples
 */
static int SndCopySamples(SndSoundStruct **toSound, SndSoundStruct *fromSound,
			  int startSample, int sampleCount)
{
    SndSoundStruct **ssList = NULL,**newssList;
    SndSoundStruct *theStruct,*newStruct;
    int i = 0, ssPointer = 0;
    int cc;
    SndSampleFormat df,originalFormat;
    int ds;
    int sr;
    int numBytes;
    int lastSample = startSample + sampleCount - 1;
    int firstFrag = -1, lastFrag = -1;
    int count = 0;
    int startOffset = 0, startLength = 0, endLength = 0;
    BOOL fromOneFrag = NO;
    
    if (!fromSound) return SND_ERR_NOT_SOUND;
    if (fromSound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
    if (lastSample > SndFrameCount(fromSound)) return SND_ERR_BAD_SIZE;
    if (sampleCount < 1) return SND_ERR_BAD_SIZE;
    
    cc = fromSound->channelCount;
    originalFormat = df = fromSound->dataFormat;
    ds = fromSound->dataSize; /* ie size of header including info string; or data */
    sr = fromSound->samplingRate;
    
    if (df == SND_FORMAT_INDIRECT) { /* check to see if samples lie within 1 frag */
	/* find 1st and last frag */
	df = ((SndSoundStruct *)(*((SndSoundStruct **)
				   (fromSound->dataLocation))))->dataFormat;
	numBytes = SndSampleWidth(df);
	ssList = (SndSoundStruct **)fromSound->dataLocation;
	while ((theStruct = ssList[i++]) != NULL) {
	    int thisCount = (theStruct->dataSize / cc / numBytes);
	    if (startSample >= count && startSample < (count + thisCount))
	    {
		firstFrag = i - 1;
		startOffset = (startSample - count) * cc * numBytes;
		startLength = theStruct->dataSize - startOffset;
	    }
	    if (lastSample >= count && lastSample < (count + thisCount))
	    {lastFrag = i - 1; endLength = (lastSample - count + 1) * cc * numBytes; }
	    count += thisCount;
	}
	i--;
	if (firstFrag == lastFrag) {
	    fromSound = ssList[firstFrag];
	    fromOneFrag = YES;
	}
    }

    if (originalFormat != SND_FORMAT_INDIRECT || fromOneFrag) {  /* simple case... */
	if (SndAlloc(toSound, sampleCount * cc * SndSampleWidth(df), df, sr, cc, 4) != SND_ERR_NONE) {
	    return SND_ERR_CANNOT_ALLOC;
	}
	memmove((char *)(*toSound)   + (*toSound)->dataLocation,
		(char *)fromSound + fromSound->dataLocation +
		(fromOneFrag ? startOffset : startSample * cc * SndSampleWidth(df)),
		sampleCount * cc * SndSampleWidth(df));
	return SND_ERR_NONE;
    }
    /* complicated case (fragged) */

    if (lastFrag == -1 || firstFrag == -1) return SND_ERR_BAD_SIZE; /* should not really happen I don't think */
    /* allocate main header */
    if (SndAlloc(toSound, 0, df, sr, cc, 4) != SND_ERR_NONE) {
	return SND_ERR_CANNOT_ALLOC;
    }
    (*toSound)->dataSize = sizeof(SndSoundStruct);/* we don't copy any header info */
    (*toSound)->dataFormat = SND_FORMAT_INDIRECT;
    /* allocate ssList */
    /* i is the number of frags */
    if (!(newssList = malloc((lastFrag - firstFrag + 2) * sizeof(SndSoundStruct *)))) {
	free (*toSound);
	return SND_ERR_CANNOT_ALLOC;
    }
    newssList[lastFrag - firstFrag + 1] = NULL; /* do the last one now... */

    for (ssPointer = firstFrag; ssPointer <= lastFrag; ssPointer++) {
	int charOffset = 0, charLength;
	theStruct = ssList[ssPointer];
	charLength = theStruct->dataSize;
	if (firstFrag == lastFrag) {
	    charOffset = startOffset;
	    charLength = endLength - startOffset;
	}
	else if (ssPointer == firstFrag) {
	    charOffset = startOffset;
	    charLength = startLength;
	}
	else if (ssPointer == lastFrag) {
	    charLength = endLength;
	}
	
	if (SndAlloc(&newStruct, charLength, theStruct->dataFormat,
		     theStruct->samplingRate,theStruct->channelCount, 4)) {
	    free (*toSound);
	    for (i = 0; i < ssPointer; i++) {
		free (newssList[i]);
	    }
	    return SND_ERR_CANNOT_ALLOC;
	}
	memmove((char *)newStruct + newStruct->dataLocation,
		(char *)theStruct + theStruct->dataLocation + charOffset,
		charLength);
	newssList[ssPointer - firstFrag] = newStruct;
    }
    (*toSound)->dataLocation = (int) newssList;
    return SND_ERR_NONE;
}

- (Snd *) soundFromSamplesInRange: (NSRange) frameRange
{
    // TODO perhaps make this allocWithZone:, take a zone parameter and make soundFromSamplesInRange:zone: the basis of copyWithZone:.
    Snd *newSound = [[[self class] alloc] initWithFormat: [self dataFormat]
					    channelCount: [self channelCount]
						  frames: frameRange.length
					    samplingRate: [self samplingRate]];
    int err;
    
    if (newSound->soundStruct) {
        err = SndFree(newSound->soundStruct);
        newSound->soundStruct = NULL;
        newSound->soundStructSize = 0;
        if (err)
	    return nil;
    }

    err = SndCopySamples(&(newSound->soundStruct), soundStruct, frameRange.location, frameRange.length);
    if (!err) {
	if (newSound->soundStruct->dataFormat != SND_FORMAT_INDIRECT)
	    newSound->soundStructSize = newSound->soundStruct->dataLocation + newSound->soundStruct->dataSize;
	else
	    newSound->soundStructSize = newSound->soundStruct->dataSize;		
	
	// Duplicate all other ivars
	newSound->soundFormat = soundFormat;
	[newSound setInfo: [self info]];
	
	newSound->priority = priority;		 
	[newSound setDelegate: [self delegate]];		 
	[newSound setName: [self name]];
	newSound->conversionQuality = conversionQuality;
        
	newSound->loopWhenPlaying = loopWhenPlaying;
	newSound->loopStartIndex = loopStartIndex;
	newSound->loopEndIndex = loopEndIndex;
	
	[newSound setAudioProcessorChain: [self audioProcessorChain]];
    }
    return [newSound autorelease];    
}

/*!
@method compactSamples
 @abstract To come
 @discussion
 There's a wee bit of a problem when compacting sounds. That is the info
 string. When a sound isn't fragmented, the size of the info string is held
 in "dataLocation" by virtue of the fact that the info will always
 directly precede the dataLocation. When a sound is fragmented though,
 dataLocation is taken over for use as a pointer to the list of fragments.
 What NeXTSTEP does is to then set the dataSize of the main SNDSoundStruct
 to 8192 -- a page of VM. Therefore, there is no longer any explicit
 record of how long the info string was. When the sound is compacted, bytes
 seem to be read off the main SNDSoundStruct until a NULL is reached, and
 that is assumed to be the end of the info string.
 Therefore I am doing things differently. In a fragmented sound, dataSize
 will be the length of the SndSoundStruct INCLUDING the info string, and
 adjusted to the upper 4-byte boundary.
 
 @param toSound
 @param fromSound
 @result
 */
- (int) compactSamples
{
    SndSoundStruct *newStruct, *fragment, **iBlock;
    int format, nchan, rate, newSize, infoSize, err;
    char *src, *dst;
    
    if (!soundStruct) return SND_ERR_NOT_SOUND;
    if (soundStruct->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
    if (soundStruct->dataFormat != SND_FORMAT_INDIRECT) return SND_ERR_NONE;
    if (![self isEditable]) return SND_ERR_CANNOT_EDIT;

    iBlock = (SndSoundStruct **) soundStruct->dataLocation;
    if (!*iBlock) {
	return SND_ERR_NOT_SOUND;
    } 
    else {
	format = (*iBlock)->dataFormat;
	nchan = soundFormat.channelCount;
	rate = soundStruct->samplingRate;
	infoSize = soundStruct->dataSize - sizeof(SndSoundStruct) + 4;
	newSize = SndFramesToBytes(SndFrameCount(soundStruct), nchan, format);
	err = SndAlloc(&newStruct, newSize, format, rate, nchan, infoSize);
	if (err) {
	    if ((err = SndFree(soundStruct)))
		return SND_ERR_CANNOT_FREE;
	    return SND_ERR_CANNOT_ALLOC;
	}
	// strcpy(newStruct->info, soundStruct->info);
	memmove(&(newStruct->info), &(soundStruct->info), infoSize);
	dst = (char *) newStruct;
	dst += newStruct->dataLocation;
	while((fragment = *iBlock++)) {
	    src = (char *) fragment;
	    src += fragment->dataLocation;
	    memmove(dst, src, fragment->dataSize);
	    dst += fragment->dataSize;
	}
    }    
    
    [editingLock lock];
    soundStruct = newStruct;
    soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
    [editingLock unlock];
    return SND_ERR_NONE;
}

- (BOOL) needsCompacting
{
    if (!soundStruct) return NO;
    return (soundStruct->dataFormat == SND_FORMAT_INDIRECT);
}

- (int) deleteSamplesInRange: (NSRange) frameRange
{
    int cc;
    SndSampleFormat df,olddf=0;
    int ds;
    int numBytes;
    
    if (!soundStruct) return SND_ERR_NOT_SOUND;
    if (soundStruct->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
    if (frameRange.location < 0 || frameRange.location > SndFrameCount(soundStruct)
	|| frameRange.location + frameRange.length > SndFrameCount(soundStruct)) return SND_ERR_BAD_SIZE;
    if (!frameRange.length) return SND_ERR_NONE;
    
    // TODO we need to lock the whole method since we refer to a number of variable that would cause problems if not locked.
    // TODO ideally we could surround critical regions only.
    [editingLock lock]; 
    
    cc = soundFormat.channelCount;
    df = soundStruct->dataFormat;
    ds = soundStruct->dataSize; /* ie size of header including info string; or data */
    
    if (df != SND_FORMAT_INDIRECT) {
	char *firstByteToMove;
	int numBytesToMove;
	char *moveToHere;
	int frameWidth = SndFrameSize(soundFormat);
	
	firstByteToMove = (char *) soundStruct + soundStruct->dataLocation + (frameRange.location + frameRange.length) * frameWidth;
	numBytesToMove = ds - (frameRange.location + frameRange.length) * frameWidth;
	moveToHere = (char *) soundStruct + soundStruct->dataLocation + frameRange.location * frameWidth;
	
	if (numBytesToMove) memmove(moveToHere, firstByteToMove, numBytesToMove);
	soundStruct = realloc(soundStruct, ds + soundStruct->dataLocation - (frameRange.length * frameWidth));
	soundStruct->dataSize -= (frameRange.length * frameWidth);
	soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
    }
    else { // Deleting from an indirect sound
	SndSoundStruct **ssList,**newssList;
	SndSoundStruct *theStruct,*newStruct;
	int i = 0, ssPointer = 0;
	int lastSample = frameRange.location + frameRange.length - 1;
	int firstFrag = -1, lastFrag = -1;
	int numFromFrags = 0;
	int numFrags;
	int startOffset=0, startLength = 0, endLength = 0;
	int count = 0;
	
	olddf = [self dataFormat];
	numBytes = SndSampleWidth(olddf);
	/* find 1st and last frag containing data to be deleted */
	ssList = (SndSoundStruct **) soundStruct->dataLocation;
	while ((theStruct = ssList[i++]) != NULL) {
	    int thisCount = (theStruct->dataSize / cc / numBytes);
	    
	    if (frameRange.location >= count && frameRange.location < (count + thisCount)) {
		firstFrag = i - 1;
		startOffset = (frameRange.location - count) * cc * numBytes;
		startLength = theStruct->dataSize - startOffset;
	    }
	    if (lastSample >= count && lastSample < (count + thisCount)) {
		lastFrag = i - 1;
		endLength = (lastSample - count + 1) * cc * numBytes; 
	    }
	    count += thisCount;
	}
	numFromFrags = i - 1;
	/* We have firstFrag and lastFrag, which may be equal.
	    * First, copy all frags before firstFrag.
	    * If startOffset == 0 and firstFrag < lastFrag, we can delete (ignore) all frags
	    * from firstFrag to lastFrag.
	    * If firstFrag == lastFrag, we must be careful to ignore only that data which is between
	    * the start and end point.
	    * Then copy all frags following endFrag.
	    */
	/* The following may overestimate the number of frags by 2, iff firstFrag == lastFrag.
	    * This does not really matter, as it's just a list of pointers, and usually not a big
	    * one at that.
	    */
	numFrags = numFromFrags - (lastFrag - firstFrag + 1) + 2;
	if (!(newssList = malloc((numFrags + 1) * sizeof(SndSoundStruct *)))) {
	    return SND_ERR_CANNOT_ALLOC;
	}
	
	for (i = 0; i<firstFrag; i++) {
	    newssList[ssPointer++] = ssList[i];
	}
	/* copy first part of 1st affected frag (the non-deleted part) */
	/* TODO an excellent optimisation here would be to work out which part of the soundStruct is
	    * larger (the 1st remaining part of the frag, or the last remaining part), and instead of
	    * copying it, just shuffle the data down the frag, and realloc it. This would save having to
	    * malloc a totally new block of memory. In fact, where firstFrag != lastFrag, this should
	    * be done for both halves.
	    */
	if (startOffset > 0) {
	    if (!(newStruct = _SndCopyFragBytes(ssList[firstFrag], 0, startOffset))) {
	    // we don't free members of the list here, since they are still part of the
	    // original sound (i.e. we are only holding copies of the pointers)
		free(newssList);
		return SND_ERR_CANNOT_ALLOC;
	    }
	    newssList[ssPointer++] = newStruct;
	}
	if (endLength < ssList[lastFrag]->dataSize) {
	    if (!(newStruct = _SndCopyFragBytes(ssList[lastFrag], endLength, -1))) {
		// we don't free members of the list here, since they are still part of the
		// original sound (i.e. we are only holding copies of the pointers
		if (startOffset > 0) 
		    free(newssList[ssPointer - 1]);
		free(newssList);
		return SND_ERR_CANNOT_ALLOC;
	    }
	    newssList[ssPointer++] = newStruct;
	}
	free(ssList[firstFrag]);
	if (firstFrag != lastFrag) 
	    free(ssList[lastFrag]);
	/* now we do all the rest of the list, as pointers only */
	for (i = lastFrag + 1; i < numFromFrags; i++) {
	    newssList[ssPointer++] = ssList[i];
	}
	newssList[ssPointer++] = NULL;
	free(ssList); /* old list */
	if (newssList[0]) 
	    soundStruct->dataLocation = (int) newssList;
	else { /* we have deleted all samples. Free new list. Check dataLocation. */
	    free(newssList);
	    soundStruct->dataFormat = olddf;
	    soundStruct->dataLocation = soundStruct->dataSize; /* size was temporarily held in dataSize */
	    soundStruct->dataSize = 0;
	}
	soundStructSize = soundStruct->dataSize;
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

- (int) insertSamples: (Snd *) aSnd at: (int) startSample
{
    int err;
    SndSoundStruct *fromSound;
    unsigned sampleCount = [aSnd lengthInSampleFrames];
    
    if (!aSnd)
        return SND_ERR_NONE;
    if (!(fromSound = [aSnd soundStruct]))
        return SND_ERR_NONE;
    [editingLock lock];
    err = SndInsertSamples(soundStruct, fromSound, startSample);
    if (!err) {
        if (soundStruct->dataFormat != SND_FORMAT_INDIRECT)
            soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
        else
            soundStructSize = soundStruct->dataSize;
	
	soundFormat.frameCount += sampleCount;

	// Update loop end index and in all performances.
	[self adjustLoopsAfterAdding: YES frames: sampleCount startingAt: startSample];
    }
    [editingLock unlock];
    return err;
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
    if (soundStruct->dataFormat != SND_FORMAT_INDIRECT) {
	*fragmentLength = [self lengthInSampleFrames];
	*currentFrame = frame < *fragmentLength ? frame : *fragmentLength - 1;
	fragmentPtr = [self data];
    }
    else {
	int frameSize = SndFrameSize(soundFormat);
	SndSoundStruct **ssList;
	SndSoundStruct *theStruct;
	int i = 0;
	unsigned long count = 0, oldCount = 0;
	
	ssList = (SndSoundStruct **)([self soundStruct]->dataLocation);
	while ((theStruct = ssList[i++]) != NULL) {
	    unsigned long numberOfFramesInFragment = (theStruct->dataSize) / frameSize;
	    
	    if(theStruct->magic != SND_MAGIC) {
		NSLog(@"Assertion failed, found non-magic numbered fragment # %d\n", i);
		break;
	    }
	    count += numberOfFramesInFragment;
	    if (count > frame) {
		*fragmentLength = numberOfFramesInFragment;
		*currentFrame = frame - oldCount;
		fragmentPtr = (char *) theStruct + theStruct->dataLocation;
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
    
    sndDataPtr = [self data] + sndFrameRange.location * sndFrameSize;
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
    memcpy([self data] + writeIntoSndFrameRange.location, [buffer bytes], writeIntoSndFrameRange.length);
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
	Snd *fromSound = [[Snd alloc] initWithAudioBuffer: buffer];
	
	[editingLock lock];
	if(SndInsertSamples([self soundStruct], [fromSound soundStruct], [self lengthInSampleFrames]) != SND_ERR_NONE) {
	    NSLog(@"appendAudioBuffer: Unable to insert samples\n");
	    return 0;
	}
	[editingLock unlock];
	[fromSound release];
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

@end
