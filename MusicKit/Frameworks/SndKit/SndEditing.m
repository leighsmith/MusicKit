////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    Snd methods concerned with editing (cut/paste/insertion/compacting etc).
//
//    TODO All static functions used to reside in SndFunctions as public functions and take SndSoundStruct parameters. They eventually
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

/*!
@function SndCompactSamples
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
static int SndCompactSamples(SndSoundStruct **s1, SndSoundStruct *s2)
{
    SndSoundStruct *fragment, *newSound, **iBlock, *oldSound = s2;
    int format, nchan, rate, newSize, infoSize, err;
    char *src, *dst;
    if (oldSound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
    if (oldSound->dataFormat != SND_FORMAT_INDIRECT)
	return SND_ERR_NONE;
    iBlock = (SndSoundStruct **)oldSound->dataLocation;
    if (!*iBlock) {
	newSound = (SndSoundStruct *)0;
    } else {
	format = (*iBlock)->dataFormat;
	nchan = oldSound->channelCount;
	rate = oldSound->samplingRate;
	infoSize = oldSound->dataSize - sizeof(SndSoundStruct) + 4;
	newSize = SndFramesToBytes(SndFrameCount(oldSound),nchan,format);
	err = SndAlloc(&newSound,newSize,format,rate,nchan,infoSize);
	if (err)
	    return SND_ERR_CANNOT_ALLOC;
	//		strcpy(newSound->info,oldSound->info);
	memmove(&(newSound->info),&(oldSound->info),
		infoSize);
	dst = (char *)newSound;
	dst += newSound->dataLocation;
	while((fragment = *iBlock++)) {
	    src = (char *)fragment;
	    src += fragment->dataLocation;
	    memmove(dst,src,fragment->dataSize);
	    dst += fragment->dataSize;
	}
    }
    *s1 = newSound;
    return SND_ERR_NONE;
}

static int SndCopySamples(SndSoundStruct **toSound, SndSoundStruct *fromSound,
                   int startSample, int sampleCount)
/*
 * what do I need to do?
 * If fromSound is non-frag, create new sound and copy appropriate samples.
 * If fragged,
 * 		create frag header
 *		find 1st and last frag containing samples
 *		loop from 1st to last, creating new frag and copying appropriate samples
 */
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
      if (SndAlloc(toSound, sampleCount * cc * SndSampleWidth(df),
                  df, sr, cc, 4) != SND_ERR_NONE) {
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
  (SndSoundStruct **)((*toSound)->dataLocation) = newssList;
  return SND_ERR_NONE;
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
  
  (SndSoundStruct **)(toSound->dataLocation) = newssList;
  return SND_ERR_NONE;
}

- (int) copySamples: (Snd *) aSnd at: (int) startSample count: (int) sampleCount
{
    int err;
    
    status = SND_SoundInitialized;
    if (!aSnd) {
        if (soundStruct) {
            err = SndFree(soundStruct);
            soundStruct = NULL;
            soundStructSize = 0;
            return err;
        }
        return SND_ERR_NONE;
    }
    if (soundStruct) {
        if (![self isEditable]) return SND_ERR_CANNOT_EDIT;
	// following condition not in the original! Therefore removed.
	//		if (![aSnd compatibleWithSound:self]) return SND_ERR_CANNOT_COPY;
        SndFree(soundStruct);
        soundStruct = NULL;
        soundStructSize = 0;
    }
    err = SndCopySamples(&soundStruct, [aSnd soundStruct],
			 startSample, sampleCount);
    if (!err) {
        if (soundStruct->dataFormat != SND_FORMAT_INDIRECT)
	    soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
        else soundStructSize = soundStruct->dataSize;		
    }
    return err;
}

- (int) compactSamples
{
    SndSoundStruct *newStruct;
    int err;
    
    if (![self isEditable]) return SND_ERR_CANNOT_EDIT;
    if (!soundStruct) return SND_ERR_NOT_SOUND;
    if (soundStruct->dataFormat != SND_FORMAT_INDIRECT) return SND_ERR_NONE;
    if ((err = SndCompactSamples(&newStruct, soundStruct))) return err;
    if ((err = SndFree(soundStruct))) return err;
    soundStruct = newStruct;
    soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
    return SND_ERR_NONE;
}

- (BOOL) needsCompacting
{
    if (!soundStruct) return NO;
    return (soundStruct->dataFormat == SND_FORMAT_INDIRECT);
}

- (void) adjustLoopStart: (long *) newLoopStart 
		     end: (long *) newLoopEnd
	   afterRemoving: (long) sampleCountRemoved
	      startingAt: (long) startSample
{
    NSLog(@"*newLoopStart %ld, *newLoopEnd %ld\n", *newLoopStart, *newLoopEnd);
    if(*newLoopEnd < startSample + sampleCountRemoved)
	*newLoopEnd = MIN(*newLoopEnd, [self lengthInSampleFrames]);
    else {
	*newLoopEnd = *newLoopEnd - sampleCountRemoved;
	if(*newLoopEnd < 0)
	    *newLoopEnd = 0;
    }
    if(*newLoopStart < startSample + sampleCountRemoved)
	// TODO Perhaps just leave it rather than moving it to startSample?
	*newLoopStart = MIN(*newLoopStart, startSample); 
    else {
	*newLoopStart = *newLoopStart - sampleCountRemoved;
	if(*newLoopStart < 0)
	    *newLoopStart = 0;	    
    }
    NSLog(@"after deleting *newLoopStart %ld, *newLoopEnd %ld\n", *newLoopStart, *newLoopEnd);    
}

#if 0
- (void) adjustAllLoopsAfterRemoving: (long) sampleCountRemoved startingAt: (long) startSample
{
    int performanceIndex;
    
    [self adjustLoopStart: &loopStartIndex
		      end: &loopEndIndex
	    afterRemoving: sampleCountRemoved
	       startingAt: startSample];	
    [performanceArrayLock lock]; // TODO check this is right.
    for(performanceIndex = 0; performanceIndex < [performanceArray count]; performanceIndex++) {
	SndPerformance *performance = [performanceArray objectAtIndex: performanceIndex];
	long performanceStartLoopIndex = [performance loopStartIndex];
	long performanceEndLoopIndex = [performance loopEndIndex];
	
	adjustLoopPoints(&performanceStartLoopIndex, &performanceEndLoopIndex, startSample, sampleCountRemoved);
	[performance setLoopStartIndex: performanceStartLoopIndex];
	[performance setLoopEndIndex: performanceEndLoopIndex];
    }
    [performanceArrayLock unlock];

}
#endif


// TODO move this function inside deleteSamplesAt:count: 
static int SndDeleteSamples(SndSoundStruct *sound, int startSample, int sampleCount)
{
    SndSoundStruct **ssList,**newssList;
    SndSoundStruct *theStruct,*newStruct;
    int i = 0, ssPointer = 0;
    int cc;
    SndSampleFormat df,olddf=0;
    int ds;
    int sr;
    int numBytes;
    int lastSample = startSample + sampleCount - 1;
    int firstFrag = -1, lastFrag = -1;
    int numFromFrags = 0;
    int numFrags;
    int count = 0;
    int startOffset=0, startLength = 0, endLength = 0;
    
    if (!sound) return SND_ERR_NOT_SOUND;
    if (sound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
    if (startSample < 0 || startSample > SndFrameCount(sound)
	|| startSample + sampleCount > SndFrameCount(sound)) return SND_ERR_BAD_SIZE;
    if (!sampleCount) return SND_ERR_NONE;
    
    cc = sound->channelCount;
    df = sound->dataFormat;
    ds = sound->dataSize; /* ie size of header including info string; or data */
    sr = sound->samplingRate;
    
    if (df == SND_FORMAT_INDIRECT) {
	olddf = ((SndSoundStruct *)(*((SndSoundStruct **)
				      (sound->dataLocation))))->dataFormat;
	numBytes = SndSampleWidth(((SndSoundStruct *)(*((SndSoundStruct **)
							(sound->dataLocation))))->dataFormat);
    }
    else numBytes = SndSampleWidth(df);
    
    if (df != SND_FORMAT_INDIRECT) {
	char *firstByteToMove = (char *)sound + sound->dataLocation +
	(startSample + sampleCount) * cc * numBytes;
	int numBytesToMove = ds - (startSample + sampleCount) * cc * numBytes;
	char *moveToHere = (char *)sound + sound->dataLocation + startSample * cc * numBytes;
	if (numBytesToMove) memmove(moveToHere, firstByteToMove, numBytesToMove);
	sound = realloc(sound, ds + sound->dataLocation - (sampleCount * cc * numBytes));
	sound->dataSize -= (sampleCount * cc * numBytes);
	return SND_ERR_NONE;
    }
    /* find 1st and last frag containing data to be deleted */
    ssList = (SndSoundStruct **)sound->dataLocation;
    while ((theStruct = ssList[i++]) != NULL) {
	int thisCount = (theStruct->dataSize / cc / numBytes);
	if (startSample >= count && startSample < (count + thisCount)) {
	    firstFrag = i - 1;
	    startOffset = (startSample - count) * cc * numBytes;
	    startLength = theStruct->dataSize - startOffset;
	}
	if (lastSample >= count && lastSample < (count + thisCount))
	{lastFrag = i - 1; endLength = (lastSample - count + 1) * cc * numBytes; }
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
    /* TODO an excellent optimisation here would be to work out which part of the sound is
	* larger (the 1st remaining part of the frag, or the last remaining part), and instead of
	* copying it, just shuffle the data down the frag, and realloc it. This would save having to
	* malloc a totally new block of memory. In fact, where firstFrag != lastFrag, this should
	* be done for both halves.
	*/
    if (startOffset > 0) {
	if (!(newStruct = _SndCopyFragBytes(ssList[firstFrag], 0, startOffset))) {
	    /* we don't free members of the list here, since they are still part of the
	    * original sound (i.e. we are only holding copies of the pointers)
	    */
	    free(newssList);
	    return SND_ERR_CANNOT_ALLOC;
	}
	newssList[ssPointer++] = newStruct;
    }
    if (endLength < ssList[lastFrag]->dataSize) {
	if (!(newStruct = _SndCopyFragBytes(ssList[lastFrag], endLength, -1))) {
	    /* we don't free members of the list here, since they are still part of the
	    * original sound (i.e. we are only holding copies of the pointers
			      */
	    if (startOffset > 0) free(newssList[ssPointer - 1]);
	    free(newssList);
	    return SND_ERR_CANNOT_ALLOC;
    }
	newssList[ssPointer++] = newStruct;
  }
    free(ssList[firstFrag]);
    if (firstFrag != lastFrag) free(ssList[lastFrag]);
    /* now we do all the rest of the list, as pointers only */
    for (i = lastFrag + 1; i<numFromFrags; i++) {
	newssList[ssPointer++] = ssList[i];
    }
    newssList[ssPointer++] = NULL;
    free(ssList); /* old list */
    if (newssList[0]) (SndSoundStruct **)(sound->dataLocation) = newssList;
    else { /* we have deleted all samples. Free new list. Check dataLocation. */
	free(newssList);
	sound->dataFormat = olddf;
	sound->dataLocation = sound->dataSize; /* size was temporarily held in dataSize */
	sound->dataSize = 0;
    }
    return SND_ERR_NONE;
}

- (int) deleteSamplesAt: (long) startSample count: (long) sampleCount
{
    int err = SndDeleteSamples(soundStruct, startSample, sampleCount);
    
    if (!err) {
        if (soundStruct->dataFormat != SND_FORMAT_INDIRECT)
            soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
        else
	    soundStructSize = soundStruct->dataSize;
	// Update loop end index and in all performances.
	[self adjustLoopStart: &loopStartIndex
			  end: &loopEndIndex
		afterRemoving: sampleCount
		   startingAt: startSample];	
	// [self adjustAllLoopsAfterRemoving: sampleCountRemoved startingAt: startSample];
	
    }
    return err;
}

- (int) deleteSamples
{
    return [self deleteSamplesAt: 0 count: [self lengthInSampleFrames]];
}

- (int) insertSamples: (Snd *) aSnd at: (int) startSample
{
    int err;
    SndSoundStruct *fromSound;
    
    if (!aSnd)
        return SND_ERR_NONE;
    if (!(fromSound = [aSnd soundStruct]))
        return SND_ERR_NONE;
    err = SndInsertSamples(soundStruct, fromSound, startSample);
    if (!err) {
        if (soundStruct->dataFormat != SND_FORMAT_INDIRECT)
            soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
        else
            soundStructSize = soundStruct->dataSize;		
    }
    return err;
}

- (long) insertIntoAudioBuffer: (SndAudioBuffer *) buff
		intoFrameRange: (NSRange) bufferFrameRange
	        samplesInRange: (NSRange) sndFrameRange
{
    void  *sndDataPtr = [self data] + sndFrameRange.location * SndFrameSize(soundFormat);
    double stretchFactor = [buff samplingRate] / [self samplingRate];

    //NSLog(@"bufferFrameRange [%ld, %ld] sndFrameRange [%ld,%ld]\n",
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
    
    if(![self hasSameFormatAsBuffer: buff]) { // If not the same, do a data conversion.
	// The number of frames returned as read could be more or less than bufferFrameRange.length if resampling occurs.
	long framesRead = [buff convertBytes: sndDataPtr
			      intoFrameRange: bufferFrameRange
			          fromFormat: [self dataFormat]
				channelCount: [self channelCount]
			        samplingRate: [self samplingRate]];
	
	//NSLog(@"buffer to fill %@ mismatched to %@, converted, read %ld\n", buff, self, framesRead);
	return framesRead;  // framesRead depends on resampling.
    }
    else {
	// Matching sound buffer formats, so we can just do a copy.
	int buffFrameSize = [buff frameSizeInBytes];
	NSRange bufferByteRange = { bufferFrameRange.location * buffFrameSize, bufferFrameRange.length * buffFrameSize };
        SndFormat sndFormat;
	
        sndFormat.channelCount = soundStruct->channelCount;
        sndFormat.dataFormat = soundStruct->dataFormat;
        sndFormat.sampleRate = soundStruct->samplingRate;
	// NSLog(@"channel count of sound = %d, of buffer = %d\n", soundStruct->channelCount, [buff channelCount]);
	[buff copyBytes: sndDataPtr intoRange: bufferByteRange format: sndFormat];
	return bufferFrameRange.length;
    }
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

    bufferRange.location = 0;
    bufferRange.length = fillLength; // TODO this may become [buff lengthInSamples] if we remove toLength: parameter.
    
    return [self insertIntoAudioBuffer: buff
			intoFrameRange: bufferRange
		        samplesInRange: readFromSndSample];
}

- (long) insertAudioBuffer: (SndAudioBuffer *) buffer
	    intoFrameRange: (NSRange) writeIntoSndFrameRange
{    
    if(![self hasSameFormatAsBuffer: buffer]) { // If not the same, do a data conversion.
	NSLog(@"mismatched buffer %@ and snd %@ formats, format conversion needs implementation\n", buffer, self);
    }

    memcpy([self data] + writeIntoSndFrameRange.location, [buffer bytes], writeIntoSndFrameRange.length);
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
	
	if(SndInsertSamples([self soundStruct], [fromSound soundStruct], [self lengthInSampleFrames]) != SND_ERR_NONE) {
	    NSLog(@"appendAudioBuffer: Unable to insert samples\n");
	    return 0;
	}
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
