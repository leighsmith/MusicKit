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

@implementation SndExpt

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
  self = [super init];
  if (self) {
    bImageInMemory = FALSE;
    cachedBuffer = [SndAudioBuffer new];
    cacheLock    = [NSLock new];
  }
  return self;
}

- (void) dealloc
{
  if (cachedBuffer)
    [cachedBuffer release];
  if (cacheLock)
    [cacheLock release];
  if (cacheStruct)
    free(cacheStruct);
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
// audioBufferForSamplesInRange:
////////////////////////////////////////////////////////////////////////////////

- (SndAudioBuffer*) audioBufferForSamplesInRange: (NSRange) playRegion
{
  SndAudioBuffer *ab = nil;
  [cacheLock lock];
  {
    int samSize = SndFrameSize(soundStruct);
    int lengthInBytes = playRegion.length * samSize;
    void* dataPtr = NULL;
    ab = [SndAudioBuffer new];

    if (bImageInMemory) {
      SndSoundStruct *s;
      dataPtr = [self data] + samSize * playRegion.location;
      memcpy(&s,soundStruct,sizeof(SndSoundStruct));
      s->dataSize = lengthInBytes;
      [ab initWithFormat: s data: nil];
      memcpy([ab bytes], dataPtr, lengthInBytes);
    }
    else {

      int err;
      int cStart = cachedBufferRange.location;
      int cEnd   = cachedBufferRange.location + cachedBufferRange.length;

      if (cachedBuffer == nil ||
          !(cStart <= playRegion.location &&
            cEnd   >= playRegion.location + playRegion.length)) {
        // OK, ve must read in der cache...
        int readLength = (4096*16);
        int bufferMultiplier = ((playRegion.length + 4095)/4096);
        bufferMultiplier = bufferMultiplier == 0 ? 1 : bufferMultiplier;
        cachedBufferRange.location = (playRegion.location/4096)*4096;
        cachedBufferRange.length   = (bufferMultiplier)*readLength;
        //      printf("read: %i %i\n", cachedBufferRange.location, cachedBufferRange.length);


        // Argh, the stoopid things we have to do because of the SndSoundStruct....
        
        if (cacheStruct)
          free(cacheStruct);
        cacheStruct = NULL; 
        
        err = SndReadSoundfileRange([theFileName fileSystemRepresentation], &cacheStruct,
                                    cachedBufferRange.location,
                                    cachedBufferRange.length, TRUE);
        if (cacheStruct) {
          if (cachedBuffer == nil)
            cachedBuffer = [SndAudioBuffer alloc];
          [cachedBuffer initWithFormat: cacheStruct data: ((char*)cacheStruct) + cacheStruct->dataLocation];
          [cachedBuffer convertToFormat: SND_FORMAT_FLOAT];
        }
      }
      else {
        //      printf("Hit the cache!\n");
      }
      if (cacheStruct)
      {
        // woohoo! we are inside the cache...
        NSRange relativeRange = playRegion;
        relativeRange.location = playRegion.location - cachedBufferRange.location;
        [ab initWithBuffer: cachedBuffer range: relativeRange];
      }
    }
  }
  [cacheLock unlock];
  return [ab autorelease];
}

- (NSString*) filename
{
  return [[theFileName retain] autorelease];
}

@end
