////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    This class is to be regarded as HIGHLY EXPERIMENTAL.
//    Don't use it for general Snd use!!!
//
//    Current experimental activity - stream from disk behaviour.
//    Should be safe to use for playback ONLY!!
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//
//  Copyright (c) 2002, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import "SndExpt.h"
#import "SndAudioBuffer.h"
#import "SndError.h"
#import "SndFunctions.h"

#define SERVER_DEBUG 0

#define HAS_DATA 1
#define HAS_NO_DATA  2

@implementation SndExpt

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
  self = [super init];
  if (self) {
    bImageInMemory  = FALSE;
    cachedBuffer    = [SndAudioBuffer new];
    cacheLock       = [NSLock new];
    readAheadLock   = [[NSConditionLock alloc] initWithCondition: HAS_NO_DATA];
    readAheadBuffer = nil;
  }
  return self;
}

- (void) dealloc
{
  if (cachedBuffer)
    [cachedBuffer release];
  if (cacheLock)
    [cacheLock release];
  if (readAheadBuffer)
    [readAheadBuffer release];
  if (readAheadLock)
    [readAheadLock release];
  [super dealloc];
}

- (unsigned char*) data
{
  NSLog(@"SndExpt:Don't even *think* of using the data method in experimental Snd objects!");
  return NULL;
}

- (int) dataSize
{
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// readSoundfile:startFrame:frameCount:
////////////////////////////////////////////////////////////////////////////////

- (int)readSoundfile:(NSString *)filename startFrame: (int) startFrame frameCount: (int) frameCount
{
  int err;
  NSDictionary *fileAttributeDictionary;
  NSFileManager *fileManager = [NSFileManager defaultManager];

  if (soundStruct)
    SndFree(soundStruct);
  if (name) {
    [name release];
    name = nil;
  }

  if (![[NSFileManager defaultManager] fileExistsAtPath: filename]) {
    //      NSLog(@"Snd::readSoundfile: sound file %@ doesn't exist",filename);
    return SND_ERR_CANNOT_OPEN;
  }
  
  // check its seekable, by checking its POSIX regular.
  fileAttributeDictionary = [fileManager fileAttributesAtPath: filename traverseLink: YES];
  if([fileAttributeDictionary objectForKey: NSFileType] != NSFileTypeRegular)
    return SND_ERR_CANNOT_OPEN;

  if (bImageInMemory) {
    err = SndReadSoundfileRange(filename, &soundStruct, startFrame, frameCount, TRUE);
  }
  else {
    if (theFileName)
      [theFileName release];
    theFileName = [filename  copy];
    err = SndReadHeader(filename, &soundStruct, NULL);
    //    NSLog([self description]);
  }
    // NSLog(@"%@\n", SndStructDescription(soundStruct));
  if (!err)
    soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
  return err;
}

////////////////////////////////////////////////////////////////////////////////
// readSoundfile:
////////////////////////////////////////////////////////////////////////////////

- (int) readSoundfile: (NSString*) filename
{
  int r;
  if (theFileName)
    [theFileName release];

  if (![[NSFileManager defaultManager] fileExistsAtPath: filename]) {
    //      NSLog(@"Snd::readSoundfile: sound file %@ doesn't exist",filename);
    return SND_ERR_CANNOT_OPEN;
  }
  theFileName = [filename copy];
  bImageInMemory = FALSE;
  r = SndReadHeader(theFileName, &soundStruct, NULL);
  //  NSLog([self description]);
  return r;
}

BOOL subRangeIsInsideSuperRange(NSRange subR, NSRange superR)
{
  return (subR.location >= superR.location &&
          subR.location + subR.length <= superR.location + superR.length);
}

////////////////////////////////////////////////////////////////////////////////
// fillAudioBuffer:toLength:samplesInRange:
////////////////////////////////////////////////////////////////////////////////

- (long) fillAudioBuffer: (SndAudioBuffer *) anAudioBuffer
		toLength: (long) fillLength
          samplesInRange: (NSRange) sndReadingRange;
{
    // TODO this is a kludge which assumes the region read from and copied to is the same number
    // of samples which isn't strictly true if there is resampling occuring.
    // Anyway, this all should be replaced with insertIntoAudioBuffer:inFrameRange:samplesStartingFrom:
    NSRange playRegion = { sndReadingRange.location, fillLength };
    
    [cacheLock lock];

    if (bImageInMemory) {
	[super fillAudioBuffer: anAudioBuffer
		      toLength: fillLength
	        samplesInRange: sndReadingRange];
    }
    else {
	unsigned long lengthInSampleFrames = [self lengthInSampleFrames];
	int readLength = (4096*16);
	int bufferMultiplier = ((playRegion.length + 4095)/4096);
	int bufferSize;
	bufferMultiplier = bufferMultiplier == 0 ? 1 : bufferMultiplier;
	bufferSize = readLength * bufferMultiplier;

	if (cachedBufferRange.location >= playRegion.location ||
     readAheadRange.location + readAheadRange.length <= playRegion.location + playRegion.length) {
	    [readAheadLock lock];
      // damn, our play region is outside our cache zone. Throw ze buffers away!
#if SERVER_DEBUG
	    NSLog(@"Jettisoning Buffer with location: %i play region %i", cachedBufferRange.location, playRegion.location);
#endif
	    if (cachedBuffer != nil)
		[cachedBuffer release];
	    cachedBuffer = nil;
	    if (readAheadBuffer != nil)
		[readAheadBuffer release];
	    readAheadBuffer = nil;
	    readAheadRange.location = 0;
	    cachedBufferRange.location = 0;
	    [readAheadLock unlock];
	}

	if (cachedBuffer == nil) {
	    unsigned long newLocation = 0;
	    [readAheadLock lock];
	    cachedBufferRange.location = (playRegion.location / 4096) * 4096;
	    cachedBufferRange.length   = bufferSize;

	    cachedBuffer = [[SndExptAudioBufferServer readRange: cachedBufferRange
					     ofSoundFile: theFileName] retain];
	    if (readAheadBuffer != nil)
		[readAheadBuffer release];
	    readAheadBuffer = nil;

	    newLocation = cachedBufferRange.location + bufferSize - playRegion.length * 4;

	    if (newLocation < lengthInSampleFrames) {
		readAheadRange.location = newLocation;
		readAheadRange.length   = bufferSize;
		if (readAheadRange.location + readAheadRange.length > lengthInSampleFrames)
		    readAheadRange.length = lengthInSampleFrames - readAheadRange.location;
		[self requestNextBufferWithRange: readAheadRange];
#if SERVER_DEBUG
		NSLog(@"Requesting (1) Buffer with range: [%i, %i] sndlength: %i",readAheadRange.location, readAheadRange.length,lengthInSampleFrames);
#endif
	    }
	    [readAheadLock unlock];
	}

	if (readAheadBuffer != nil &&
	    subRangeIsInsideSuperRange (playRegion, readAheadRange) &&
	    playRegion.location + playRegion.length < lengthInSampleFrames) {
	    // we have moved into the readAheadCache - swap the buffers and request the next...
	    unsigned long newLocation = 0;

	    [readAheadLock lock];
	    if (cachedBuffer != nil)
		[cachedBuffer release];
	    cachedBuffer = readAheadBuffer;
	    cachedBufferRange = readAheadRange;
	    readAheadBuffer = nil;

	    newLocation = cachedBufferRange.location + bufferSize - playRegion.length * 4;
	    if (newLocation < lengthInSampleFrames) {
		readAheadRange.location = newLocation;
		readAheadRange.length   = bufferSize;
		if (readAheadRange.location + readAheadRange.length > lengthInSampleFrames)
		    readAheadRange.length = lengthInSampleFrames - readAheadRange.location;

		[self requestNextBufferWithRange: readAheadRange];
#if SERVER_DEBUG
		NSLog(@"Requesting (2) Buffer with range: [%i, %i] sndLength: %i",readAheadRange.location, readAheadRange.length,lengthInSampleFrames);
		NSLog(@"Swapped in Buffer with range: [%i, %i]",cachedBufferRange.location, cachedBufferRange.length);
#endif
	    }
	    [readAheadLock unlockWithCondition: HAS_NO_DATA];
	}

	if (cachedBuffer != nil) {
	    if (subRangeIsInsideSuperRange (playRegion, cachedBufferRange)) {
        // woohoo! we are inside the cache...
		NSRange relativeRange = playRegion;
#if SERVER_DEBUG
		NSLog(@"Processing %@", [self filename]);
		NSLog(@"Inside the cache (3) relativeRange: [%i, %i] playRegion: [%i, %i]", relativeRange.location, relativeRange.length,
	playRegion.location, playRegion.length);
		NSLog(@"cachedBufferRange: [%i, %i]",cachedBufferRange.location, cachedBufferRange.length);
#endif
		relativeRange.location = playRegion.location - cachedBufferRange.location;
		if (relativeRange.location + relativeRange.length > cachedBufferRange.length )
		    relativeRange.length = cachedBufferRange.length - relativeRange.location;
		[anAudioBuffer initWithBuffer: cachedBuffer range: relativeRange];
		if ([anAudioBuffer lengthInSampleFrames] < playRegion.length)
		    [anAudioBuffer setLengthInSampleFrames: playRegion.length];
	    }
	    else {
#if SERVER_DEBUG
		NSLog(@"SndExpt::fillAudioBuffer - weird case - doing direct read");
#endif
		[anAudioBuffer initWithBuffer: [SndExptAudioBufferServer readRange: playRegion
							 ofSoundFile: theFileName]];
	    }
	}
    }
    [cacheLock unlock];
    return playRegion.length;
}

////////////////////////////////////////////////////////////////////////////////
// audioBufferForSamplesInRange:
////////////////////////////////////////////////////////////////////////////////

- (SndAudioBuffer*) audioBufferForSamplesInRange: (NSRange) playRegion
{
  SndAudioBuffer *ab = [SndAudioBuffer new];
  [self fillAudioBuffer: ab toLength: playRegion.length samplesInRange: playRegion];
  return [ab autorelease];
}

- (NSString*) filename
{
  return [[theFileName retain] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- requestNextBufferWithRange: (NSRange) range
{
  SndExptAudioBufferServerJob *aJob;
  aJob = [SndExptAudioBufferServerJob alloc];
  [aJob initWithSndExpt: self bufferRange: range];
  [[SndExptAudioBufferServer defaultServer] addJob: aJob];
  return self;
}

- receiveRequestedBuffer: (SndAudioBuffer*) aBuffer
{
  [readAheadLock lock];
  if (readAheadBuffer != nil)
    [readAheadBuffer release];
  readAheadBuffer = [aBuffer retain];
  [readAheadLock unlockWithCondition: HAS_DATA];
#if SERVER_DEBUG              
  NSLog(@"Received Buffer with range: [%i, %i]",readAheadRange.location, readAheadRange.length);
#endif      
  return self;
}

@end

////////////////////////////////////////////////////////////////////////////////
// SndExptAudioBufferServer
////////////////////////////////////////////////////////////////////////////////

#define SERVER_NO_JOBS  0
#define SERVER_HAS_JOBS 1

static SndExptAudioBufferServer *defaultServer = nil;

@implementation SndExptAudioBufferServer

+ (void) initialize
{
  defaultServer = [SndExptAudioBufferServer new];
}

+ defaultServer
{
  return defaultServer;
}

+ (SndAudioBuffer*) readRange: (NSRange) range ofSoundFile: (NSString*) theFileName
{
  SndAudioBuffer *aBuffer = nil;
  SndSoundStruct *soundStruct = NULL;

  SndReadSoundfileRange(theFileName, &soundStruct, range.location, range.length, TRUE);
  if (soundStruct) {
    aBuffer = [SndAudioBuffer alloc];
    [aBuffer initWithFormat: soundStruct data: ((char*)soundStruct) + soundStruct->dataLocation];
    [aBuffer convertToFormat: SND_FORMAT_FLOAT];
    free(soundStruct);
    return [aBuffer autorelease];
  }
  else
    return nil;
}

- init
{
  self = [super init];
  if (self) {
    bGo = TRUE;
    pendingJobsArrayLock = [NSConditionLock new];
    pendingJobsArray     = [NSMutableArray  new];
    [NSThread detachNewThreadSelector: @selector(serverThread)
                             toTarget: self
                           withObject: nil];
  }
  return self;
}

- (void) dealloc
{
  if (pendingJobsArrayLock != nil)
    [pendingJobsArrayLock release];
  if (pendingJobsArray != nil)
    [pendingJobsArray release];
}


- addJob: (SndExptAudioBufferServerJob*) aJob
{
  [pendingJobsArrayLock lock];
  [pendingJobsArray addObject: aJob];
  [pendingJobsArrayLock unlockWithCondition: SERVER_HAS_JOBS];
#if SERVER_DEBUG              
  NSLog(@"Added job for %@", [[aJob snd] filename]);
#endif  
  return self;
}

- (void) doJob: (SndExptAudioBufferServerJob*) aJob
{
  SndExpt *snd = [aJob snd];
  NSRange r = [aJob range];
  unsigned long requestedLength = r.length;
  unsigned long lengthInSampleFrames = [snd lengthInSampleFrames];
  SndAudioBuffer *aBuffer = nil;

  if (r.location + r.length > [snd lengthInSampleFrames])
    r.length = lengthInSampleFrames - r.location;
    
  aBuffer = [SndExptAudioBufferServer readRange: [aJob range]
                              ofSoundFile: [snd filename]];
  
  if ([aBuffer lengthInSampleFrames] < requestedLength)
      [aBuffer setLengthInSampleFrames: requestedLength];

  [snd receiveRequestedBuffer: aBuffer];
  [aJob release];
#if SERVER_DEBUG              
  NSLog(@"Completed job for %@", [[aJob snd] filename]);
#endif  
}

- (void) serverThread
{
  while (bGo) {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow: 1.0];
    
    if (![pendingJobsArrayLock lockWhenCondition: SERVER_HAS_JOBS beforeDate: date])
      continue;

    if ([pendingJobsArray count] == 0)
      continue;
    
    activeJob = [[pendingJobsArray objectAtIndex: 0] retain];
    [pendingJobsArray removeObject: activeJob];

    if ([pendingJobsArray count] > 0)
      [pendingJobsArrayLock unlockWithCondition: SERVER_HAS_JOBS];
    else
      [pendingJobsArrayLock unlockWithCondition: SERVER_NO_JOBS];

    if (activeJob != nil)
      [self doJob: activeJob];
    [pool release];
  }
  [NSThread exit];
}

@end

////////////////////////////////////////////////////////////////////////////////
// SndExptAudioBufferServerJob
////////////////////////////////////////////////////////////////////////////////

@implementation SndExptAudioBufferServerJob 

- initWithSndExpt: (SndExpt*) sndExpt bufferRange: (NSRange) range
{
  self = [super init];
  if (self) {
    clientSndExpt    = [sndExpt retain];
    audioBufferRange = range;
    audioBuffer      = nil;
  }
  return self;
}

- (void) dealloc
{
  if (clientSndExpt)
    [clientSndExpt release];
  if (audioBuffer)
    [audioBuffer release];
}

- (SndExpt*) snd            {  return [[clientSndExpt retain] autorelease];    }
- (NSRange) range           {  return audioBufferRange;                        }
- (SndAudioBuffer*) buffer  {  return [[audioBuffer retain] autorelease];  }

@end

////////////////////////////////////////////////////////////////////////////////
