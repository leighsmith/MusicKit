////////////////////////////////////////////////////////////////////////////////
//
//  SndMP3.m
//  SndKit
//
//  Created by SKoT McDonald on Tue Apr 16 2002.
//  Copyright (c) 2002 SndKit. All rights reserved.
//
//  Super experimental - to be folded back into Snd eventually, but we want
//  mp3 power NOW!
//
//  TODO: - This is only good for 44.1 stereo MP3s at the moment.
//        - need to dynamically unpack bitstream to lienar on as-needed basis
//          (support on-the-fly fillAudioBuffer type action), currently we
//          decode on loading
//        - Seek support - the frame header table is constructed and ready to go.
//
////////////////////////////////////////////////////////////////////////////////

#import "SndMP3.h"
#import <lame/lame.h>

#define SNDMP3_DEBUG_READING 0

#define MP3_BITRATE_BAD  -1
#define MP3_BITRATE_FREE -2
#define MP3_BITRATEINDEX_BAD  0
#define MP3_BITRATEINDEX_FREE 15

@implementation SndMP3

+ (NSArray *) soundFileExtensions
{
    return [[super soundFileExtensions] arrayByAddingObject: @"mp3"];
}

static int bitrateLookupTable[16][6] = {
  { MP3_BITRATE_BAD, MP3_BITRATE_BAD, MP3_BITRATE_BAD, MP3_BITRATE_BAD, MP3_BITRATE_BAD, MP3_BITRATE_BAD },
  {  32,  32,  32,  32,   8,   8 },
  {  64,  48,  40,  48,  16,  16 },
  {  96,  56,  48,  56,  24,  24 },
  { 128,  64,  56,  64,  32,  32 },
  { 160,  80,  64,  80,  40,  40 },
  { 192,  96,  80,  96,  48,  48 },
  { 224, 112,  96, 112,  56,  56 },
  { 256, 128, 112, 128,  64,  64 },
  { 288, 160, 128, 144,  80,  80 },
  { 320, 192, 160, 160,  96,  96 },
  { 352, 224, 192, 176, 112, 112 },
  { 384, 256, 224, 192, 128, 128 },
  { 416, 320, 256, 224, 144, 144 },
  { 448, 384, 320, 256, 160, 160 },
  { MP3_BITRATE_FREE, MP3_BITRATE_FREE, MP3_BITRATE_FREE, MP3_BITRATE_FREE, MP3_BITRATE_FREE, MP3_BITRATE_FREE }
};


int find_mp3_frame_headers(NSData* mp3Data, long **ppFrameLocations, long *frameLocationsCount)
{
  int layer, bitrateIndex, version, bitrate, samplesPerFrame = 1152;
  int frameSize, samplingRate = 44100;
  float framesPerSecond;
  const unsigned char *pData = [mp3Data bytes];
  long mp3Length = [mp3Data length];

  long maxFrameLocationsCount = 512;

  *frameLocationsCount = 0;

  if (*ppFrameLocations)
    free(*ppFrameLocations);

  *ppFrameLocations = (long*) malloc(sizeof(long) * maxFrameLocationsCount);
  
/*
  if (frameHeader >> 21 & 0x07FF)
    printf("frame sync is ok\n");
  else
    printf("bad frame sync\n");

  printf("version: ");
  switch (frameHeader >> 19 & 0x03) {
    case 0: printf("MPEG 2.5\n"); break;
    case 1: printf("reserved\n"); break;
    case 2: printf("MPEG v2\n"); version = 2; samplesPerFrame = 576; break;
    case 3: printf("MPEG v1\n"); version = 1; break;
  }
  layer =  4 - (frameHeader >> 17) & 0x03;
  switch (layer) {
    case 3: printf("Layer 3\n"); break;
    case 2: printf("Layer 2\n"); break;
    case 1: printf("Layer 1\n"); break;
    case 0:
    default:
      printf("reserved\n");
  }
  printf("Protected by CRC: %s\n", frameHeader >> 16 & 0x1 ? "no" : "yes");

  bitrateIndex = (frameHeader >> 12) & 0xF;
  bitrate = bitrateLookupTable[bitrateIndex][(version-1)*3 + layer-1];
  printf("Bitrate: %i (index: %i)\n", bitrate, bitrateIndex);

  printf("Sampling frequency index: %i\n", (frameHeader >> 10) & 0x3);
  printf("Padding: %s\n", (frameHeader >> 9) & 0x1 ? "yes" : "no");
  printf("Channel Mode: %i\n", (frameHeader >> 6) & 0x3);
  printf("Mode extension: %i\n", (frameHeader >> 4) & 0x3);
  printf("Copyright: %s\n", (frameHeader >> 3) & 0x1 ? "yes" : "no");
  printf("Original: %s\n", (frameHeader >> 2) & 0x1 ? "yes" : "no");
  printf("Emphasis: %i\n", frameHeader & 0x3);

  printf("Samples per frame: %i\n",samplesPerFrame);
  framesPerSecond = (float) samplingRate / (float) samplesPerFrame;
  printf("FramesPerSecond: %f\n", framesPerSecond);
  frameSize = bitrate * 125 / framesPerSecond; // 125 = 100 / 8
  printf("FrameSize: %i\n", frameSize);
*/
  // ok, we are going looking for frame headers:
  //if (0)
  {
    long  position = 0;
//    float time;
    unsigned long  frameHeader;
//    unsigned char *pCh = (unsigned char*) &frameHeader;

    while (position < mp3Length) {
      while (pData[position] != (unsigned char) 0xFF && (position < mp3Length)) {
        position++;
      }
      if (position < mp3Length-1 && (pData[position+1] & 0xE0) == 0xE0) {
        frameHeader = (pData[position] << 24) + (pData[position+1] << 16) + (pData[position+2] << 8) + pData[position+3];
        position += 4;
        

        if (((frameHeader >> 24) & 0xE0) == 0xE0) {
//          if (frameCount == 0) { //

            switch (frameHeader >> 19 & 0x03) {
              case 0: //printf("MPEG 2.5\n");
                break;
              case 1: //printf("reserved\n");
                break;
              case 2: //printf("MPEG v2\n");
                version = 2;
                samplesPerFrame = 576;
                break;
              case 3: // printf("MPEG v1\n");
                version = 1;
                samplesPerFrame = 1152;
                break;
            }
            layer =  4 - ((frameHeader >> 17) & 0x03);
            bitrateIndex = (frameHeader >> 12) & 0x0F;
            if (bitrateIndex != MP3_BITRATEINDEX_FREE) // free
              bitrate = bitrateLookupTable[bitrateIndex][(version-1)*3 + layer-1];
            framesPerSecond = (float) samplingRate / (float) samplesPerFrame;
            frameSize = bitrate * 125 / framesPerSecond; // 125 = 100 / 8
//          }

//          time = (float) (*frameLocationsCount) * samplesPerFrame / (float) samplingRate;
//          printf("[Frame: %li] Header found at: %li  (t:%.2f sam:%li)\n",
//                 (*frameLocationsCount), position - 4, time, ((*frameLocationsCount) - 1) * samplesPerFrame);

          if ((*frameLocationsCount) == maxFrameLocationsCount) {
            maxFrameLocationsCount <<= 1;
            (*ppFrameLocations) = (long*) realloc((*ppFrameLocations), sizeof(long) * maxFrameLocationsCount);
          }
          (*ppFrameLocations)[(*frameLocationsCount)] = position;
          (*frameLocationsCount)++;
          position += frameSize - 4;
        }
      }
      else
        position++;
    }
  }
  // condense allocated memory to just the frame locations found...
  *ppFrameLocations = (long*) realloc((*ppFrameLocations), sizeof(long) * (*frameLocationsCount));
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Snd overrides required for simple playback operation
////////////////////////////////////////////////////////////////////////////////

- init
{
  self = [super init];
  if (self) {
    frameLocations = NULL;
    frameLocationsCount = 0;
  }
  return self;
}

- (int) sampleCount
{
  return [pcmData length] / (sizeof(short) * 2);
}

- (double) duration
{
  return [self sampleCount] / [self samplingRate];
}

- (double) samplingRate
{
  return 44100.0;
}

- (int) channelCount
{
  return 2;
}

- (void) dealloc
{
  if (mp3Data) {
    [mp3Data release];
    mp3Data = nil;
  }
  if (pcmData) {
    [pcmData release];
    pcmData = nil;
  }
  [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// readSoundfile:
////////////////////////////////////////////////////////////////////////////////

- (int) readSoundfile: (NSString*) filename
{
  int growSize = 44100 * 4;
  int pcmSize  = growSize;
//  NSDate *startDate = [NSDate date];
  
  if (mp3Data) {
    [mp3Data release];
    mp3Data = nil;
  }
  if (pcmData) {
    [pcmData release];
    pcmData = nil;
  }
  lame_decode_init();  
  mp3Data = [[NSData alloc] initWithContentsOfMappedFile: filename]; // ho-ho, memory mapping! :)

  find_mp3_frame_headers(mp3Data, &frameLocations, &frameLocationsCount);

#if SNDMP3_DEBUG_READING
  printf("Found %li frames\n", frameLocationsCount);
#endif  
  pcmData = [[NSMutableData alloc] initWithLength: pcmSize * sizeof(short) * 2];
  {
    short pcm_l[10000], pcm_r[10000]; // conversion buffers
    long mp3DataPos    = 0;
    long mp3DataLength = [mp3Data length];
//    long length = 0;
    long sams_created = 0;
    long sams_created_total = 0;
    unsigned char* mp3DataBytes = (unsigned char*) [mp3Data bytes];
//    long frameID = 0;

    while (mp3DataPos < mp3DataLength || sams_created > 0) {
      int mp3FeedAmount = 417;
      if (mp3DataPos + mp3FeedAmount > mp3DataLength)
        mp3FeedAmount = mp3DataLength - mp3DataPos;
      
      sams_created = lame_decode1(mp3DataBytes + mp3DataPos, mp3FeedAmount, pcm_l, pcm_r);
      mp3DataPos += mp3FeedAmount;

      if (sams_created > 0) {
        while (sams_created_total + sams_created > pcmSize) {
          pcmSize += growSize;
          [pcmData setLength: pcmSize * sizeof(short) * 2];
        }
        {
          short *pData = [pcmData mutableBytes]; // get fresh pointer in case resize moved our data
          long i, pos = sams_created_total * 2;

          for (i = 0; i < sams_created; i++) {
            pData[pos++] = pcm_l[i];
            pData[pos++] = pcm_r[i];
          }
        }
      }
      sams_created_total += sams_created;
    }
    [pcmData setLength: sams_created_total * sizeof(short) * 2];
#if SNDMP3_DEBUG_READING
    printf("Translated %li samples   pcmdata length: %i  time: %f\n",
           sams_created_total, [pcmData length], -[startDate timeIntervalSinceNow]);
#endif
  }
  return SND_ERR_NONE;
}

////////////////////////////////////////////////////////////////////////////////
// fillAudioBuffer:withSamplesInRange:
////////////////////////////////////////////////////////////////////////////////

- (void) fillAudioBuffer: (SndAudioBuffer*) anAudioBuffer withSamplesInRange: (NSRange) playRegion
{
// This version of fillAudioBuffer assumes that the entire MP3 has been decoded
// into memory.
#if 1  
  int buffChans = [anAudioBuffer channelCount];
  const short *pData = [pcmData bytes];
  
  switch ([anAudioBuffer dataFormat]) {
    case SND_FORMAT_FLOAT:
      {
        float *pBuff = [anAudioBuffer bytes];
        if (buffChans == 2) {
          int i, c = MIN(playRegion.location + playRegion.length, [pcmData length] / 4) - playRegion.location;
          pData += playRegion.location * 2;
          for (i = 0; i < c * 2; i += 2) {
            pBuff[i]   = (float)pData[i]   / 32768.0;
            pBuff[i+1] = (float)pData[i+1] / 32768.0;
          }
        }
        else
          NSLog(@"SndMP3::fillAudioBuffer - Urk 1");
      }
      break;
    default:
      NSLog(@"SndMP3::fillAudioBuffer - Urk 2");
  }
#endif

#if 0
  
  /* TO DO */ 
  
  int startFrameID = floor(playRegion.location / 1152.0);
  int startSamplePosition = startFrameID * 1152;
  int endFrameID   = floor(playRegion.location + playRegion.length / 1152.0);
  int endSamplePosition = (endFrameID + 1) * 1152;
  int currentFrameID = startFrameID;

  short decode_pcm_l[10000];
  short decode_pcm_r[10000];

  const short *pData = [pcmData bytes];
  float *pBuff = [anAudioBuffer bytes];
  long   samsCreated      = 0;
  long   totalSamsCreated = 0;
  
  /*
  while (totalSamsCreated < playRegion.length) {
    long decodePos        = frameLocations[currentFrameID];
    long decodeFeedAmount = frameLocations[currentFrameID + 1] - frameLocations[currentFrameID];

    sams_created = lame_decode1(mp3DataBytes + decodePos, decodeFeedAmount, pcm_l, pcm_r);

    if (sams_created > 0) {
      totalSamsCreated ;
    }
    currentFrameID++;
  }
  */

#endif  
}

- (SndAudioBuffer*) audioBufferForSamplesInRange: (NSRange) r
{
  SndAudioBuffer *ab  = [SndAudioBuffer alloc];
//  int   samSize       = 4; // hardcoded for 16 bit, 2 chans
//  SndSoundStruct s;

  [ab initWithFormat: SND_FORMAT_FLOAT
        channelCount: 2
        samplingRate: 44100
            duration: r.length / 44100.0];

  [self fillAudioBuffer: ab withSamplesInRange: r];

  return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////

@end
