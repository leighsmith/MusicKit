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
  }
  return self;
}
- (void) dealloc
{
  if (cachedBuffer)
    [cachedBuffer release];
  [super dealloc];
}

- (unsigned char*) data
{
  NSLog(@"SndExpt:Don't even *think* of using the data method in experimental Snd objects!");
  return nil;
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
  SndAudioBuffer *ab = [SndAudioBuffer alloc];
  SndSoundStruct *s;
  if (bImageInMemory) {
    int samSize = SndFrameSize(soundStruct);
    void* dataPtr     = [self data] + samSize * playRegion.location;
    int lengthInBytes = playRegion.length * samSize;
    memcpy(&s,soundStruct,sizeof(SndSoundStruct));
    s->dataSize = lengthInBytes;
    [ab initWithFormat: s data: dataPtr];
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
      int bufferMultiplier = (playRegion.length/4096);
      bufferMultiplier = bufferMultiplier == 0 ? 1 : bufferMultiplier; 
      cachedBufferRange.location = (playRegion.location/4096)*4096;
      cachedBufferRange.length   = (bufferMultiplier)*readLength;
//      printf("read: %i %i\n", cachedBufferRange.location, cachedBufferRange.length);
      err = SndReadSoundfileRange([theFileName fileSystemRepresentation], &s,
                                  cachedBufferRange.location,
                                  cachedBufferRange.length, TRUE);
      [cachedBuffer initWithFormat: s data: ((char*)s) + s->dataLocation];
    }
    else {
//      printf("Hit the cache!\n");
    }
    {
      // woohoo! we are inside the cache...
      int   samSize = SndFrameSize(soundStruct);
      void* dataPtr     = [cachedBuffer data] + samSize * (playRegion.location - cachedBufferRange.location);
      int lengthInBytes = playRegion.length * samSize;
      SndSoundStruct theStruct;
      memcpy(&theStruct,soundStruct,sizeof(SndSoundStruct));
      theStruct.dataSize = lengthInBytes;
      [ab initWithFormat: &theStruct data: dataPtr];
    }

  }
  return [ab autorelease];
}

@end
