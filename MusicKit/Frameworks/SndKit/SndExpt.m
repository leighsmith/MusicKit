////////////////////////////////////////////////////////////////////////////////
//
//  SndExpt.m
//  SndKit
//
//  Created by SKoT McDonald on Fri Jan 18 2002.
//  Copyright (c) 2002 tomandandy. All rights reserved.
//
//  This class is to be regarded as HIGHLY EXPERIMENTAL.
//  Don't use it for general Snd use!!!
//
//  Current experimental activity - stream from disk behaviour.
//  Should be safe to use for playback ONLY!!
//
////////////////////////////////////////////////////////////////////////////////

#import "SndExpt.h"
#import "SndAudioBuffer.h"
#import "sounderror.h"
#import "SndFunctions.h"

#define SERVER_DEBUG 0

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
    readAheadLock   = [NSConditionLock new];
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
  // check its seekable, by checking its POSIX regular.
  fileAttributeDictionary = [fileManager fileAttributesAtPath: filename traverseLink: YES];
  if([fileAttributeDictionary objectForKey: NSFileType] != NSFileTypeRegular)
    return SND_ERR_CANNOT_OPEN;

  if (bImageInMemory) {
    err = SndReadSoundfileRange([filename fileSystemRepresentation], &soundStruct, startFrame, frameCount, TRUE);
  }
  else {
    if (theFileName)
      [theFileName release];
    theFileName = [filename  copy];
    err = SndReadHeader([filename fileSystemRepresentation], &soundStruct, NULL);
    //    NSLog([self description]);
  }
  // SndPrintStruct(soundStruct);
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
  theFileName = [filename copy];
  bImageInMemory = FALSE;
  r = SndReadHeader([theFileName fileSystemRepresentation], &soundStruct, NULL);
  //  NSLog([self description]);
  return r;
}

////////////////////////////////////////////////////////////////////////////////
// fillAudioBuffer:withSamplesInRange:
////////////////////////////////////////////////////////////////////////////////

- (void) fillAudioBuffer: (SndAudioBuffer*) anAudioBuffer withSamplesInRange: (NSRange) playRegion
{
  [cacheLock lock];

  if (bImageInMemory) {
    [super fillAudioBuffer: anAudioBuffer withSamplesInRange: playRegion];
  }
  else {
    long sampleCount = [self sampleCount];
    int readLength = (4096*16);
    int bufferMultiplier = ((playRegion.length + 4095)/4096);
    bufferMultiplier = bufferMultiplier == 0 ? 1 : bufferMultiplier;

    if (cachedBufferRange.location >= playRegion.location ||
        readAheadRange.location + readAheadRange.length <= playRegion.location + playRegion.length) {
      // damn, our play region is outside our cache zone. Throw ze buffers away!
      if (cachedBuffer != nil)
        [cachedBuffer release];
      cachedBuffer = nil;
      if (readAheadBuffer != nil)
        [readAheadBuffer release];
      readAheadBuffer = nil;
    }

    if (cachedBuffer == nil) {
      cachedBufferRange.location = (playRegion.location / 4096) * 4096;
      cachedBufferRange.length   = (bufferMultiplier) * readLength;
            
      cachedBuffer = [[SndExptAudioBufferServer readRange: cachedBufferRange
                                              ofSoundFile: theFileName] retain];
      if (readAheadBuffer != nil)
        [readAheadBuffer release];
      readAheadBuffer = nil;
      
      readAheadRange           = cachedBufferRange;
      readAheadRange.location += cachedBufferRange.length - playRegion.length * 4;
      if (readAheadRange.location + readAheadRange.length > sampleCount)
        readAheadRange.length = sampleCount - readAheadRange.location;
      
      [self requestNextBufferWithRange: readAheadRange];
#if SERVER_DEBUG      
      NSLog(@"Requesting (1) Buffer with range: [%i, %i]",readAheadRange.location, readAheadRange.length);
#endif      
    }
    
    if (playRegion.location >= readAheadRange.location &&
        playRegion.location + playRegion.length <= readAheadRange.location + readAheadRange.length) {
      // we have moved into the readAheadCache - swap the buffers and request the next...
      [readAheadLock lock];
      if (cachedBuffer != nil)
        [cachedBuffer release];
      cachedBuffer = readAheadBuffer;
      cachedBufferRange = readAheadRange;

      readAheadRange.location += readAheadRange.length - playRegion.length * 4;
      if (readAheadRange.location + readAheadRange.length > sampleCount)
        readAheadRange.length = sampleCount - readAheadRange.location;
      
      readAheadBuffer = nil;
      [self requestNextBufferWithRange: readAheadRange];      
      [readAheadLock unlock];
#if SERVER_DEBUG            
      NSLog(@"Requesting (2) Buffer with range: [%i, %i]",readAheadRange.location, readAheadRange.length);
      NSLog(@"Swapped in Buffer with range: [%i, %i]",cachedBufferRange.location, cachedBufferRange.length);
#endif
    }
    if (cachedBuffer != nil) {
      // woohoo! we are inside the cache...
      NSRange relativeRange = playRegion;
      relativeRange.location = playRegion.location - cachedBufferRange.location;
      [anAudioBuffer initWithBuffer: cachedBuffer range: relativeRange];
    }
  }
  [cacheLock unlock];
}

////////////////////////////////////////////////////////////////////////////////
// audioBufferForSamplesInRange:
////////////////////////////////////////////////////////////////////////////////

- (SndAudioBuffer*) audioBufferForSamplesInRange: (NSRange) playRegion
{
  SndAudioBuffer *ab = [SndAudioBuffer new];
  [self fillAudioBuffer: ab withSamplesInRange: playRegion];
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
  [readAheadLock unlock];
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

  SndReadSoundfileRange([theFileName fileSystemRepresentation], &soundStruct,
                        range.location,
                        range.length, TRUE);
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
  NSLog(@"Added job");
#endif  
  return self;
}

- (void) doJob: (SndExptAudioBufferServerJob*) aJob
{
  SndExpt *snd = [aJob snd];
  SndAudioBuffer *aBuffer = [SndExptAudioBufferServer readRange: [aJob range]
                                                    ofSoundFile: [snd filename]];

  [snd receiveRequestedBuffer: aBuffer];
  [aJob release];
#if SERVER_DEBUG              
  NSLog(@"Completed job");
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
